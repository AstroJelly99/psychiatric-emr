-- =====================================================================
-- 0001_init.sql — emr_system2 (MariaDB 10.4) -> PostgreSQL / Supabase
-- Project: skripsi-emr
-- Sumber kebenaran struktur: emr_system2 (8).sql (mysqldump --no-data)
-- Diverifikasi silang dengan lib/data/models/ dan lib/data/repositories/
--
-- Urutan: extension -> enum type -> tabel (urut dependensi FK) -> index
--         -> RLS enable -> policy.
--
-- Konversi dialek yang diterapkan (eksplisit):
--   tinyint(1) is_active 0/1   -> boolean
--   datetime                   -> timestamptz
--   date                       -> date (tetap)
--   char(36) untuk id          -> uuid
--   char/varchar non-id        -> varchar(N) (panjang dipertahankan)
--   text                       -> text
--   int(11) AUTO_INCREMENT     -> integer generated always as identity
--   enum(...) MySQL            -> CREATE TYPE ... AS ENUM (lihat catatan
--                                 di bawah soal ORDER BY severity_level)
--   ENGINE/CHARSET/COLLATE     -> dihapus (tidak ada padanannya)
--
-- Konversi dialek yang HARUS dilakukan di sisi Dart (langkah berikutnya,
-- tidak ada file .dart yang disentuh di langkah ini):
--   IFNULL              -> COALESCE      (tidak ditemukan di kode saat ini)
--   CONCAT              -> concat / ||   (tidak ditemukan di kode saat ini)
--   LIMIT x, y          -> LIMIT y OFFSET x (kode sudah pakai LIMIT ? OFFSET ?)
--   DATE_FORMAT         -> to_char       (tidak ditemukan di kode saat ini)
--   LAST_INSERT_ID      -> RETURNING     (tidak ditemukan di kode saat ini;
--                          item_asesmen_psikologis.item_id di-insert tanpa
--                          pernah membaca id hasil insert)
--   DATE(create_date)   -> create_date::date  (AsesmenPsikologisRepo.search)
--   LIKE                -> ILIKE          (lihat MIGRATION_PLAN.md bagian 3)
-- =====================================================================

begin;

-- ---------------------------------------------------------------------
-- 1. EXTENSION
-- ---------------------------------------------------------------------
-- gen_random_uuid() sudah built-in di PG13+, pgcrypto disiapkan supaya
-- DEFAULT gen_random_uuid() bisa ditambahkan nanti bila diinginkan.
-- Saat ini SEMUA uuid digenerate di sisi Dart (package uuid, Uuid().v4()),
-- jadi tidak ada kolom yang diberi DEFAULT — sengaja, supaya perilaku
-- identik dengan MySQL.
create extension if not exists pgcrypto with schema extensions;

-- ---------------------------------------------------------------------
-- 1b. ENUM TYPE
-- ---------------------------------------------------------------------
-- PENTING: dibuat sebagai native enum, BUKAN varchar + CHECK.
-- ObatRepo.getInteractionsByObatId / getAllInteractions / checkMultipleInteractions
-- memakai `ORDER BY di.severity_level DESC`. Di MySQL, ENUM diurutkan
-- berdasarkan urutan deklarasi (MINOR < MODERATE < MAJOR < CONTRAINDICATED),
-- sehingga DESC = paling berbahaya di atas. Native enum Postgres juga
-- mengurutkan berdasarkan urutan deklarasi, jadi urutan deklarasi di bawah
-- HARUS sama persis dengan MySQL. Kalau kolom ini dijadikan text/varchar,
-- ORDER BY berubah jadi alfabetis (MODERATE > MINOR > MAJOR > CONTRAINDICATED)
-- dan daftar interaksi akan tampil dengan urutan keparahan yang salah.
create type public.severity_level as enum (
  'MINOR',
  'MODERATE',
  'MAJOR',
  'CONTRAINDICATED'
);

-- ---------------------------------------------------------------------
-- 2. TABEL (urut sesuai dependensi FK)
-- ---------------------------------------------------------------------

-- 2.1 master_pasien — tidak punya dependensi
create table public.master_pasien (
  pasien_id         uuid          not null,
  patient_name      varchar(100)  not null,
  patient_address   varchar(200)  not null,
  patient_gender    varchar(20)   not null,
  patient_birthdate date          not null,
  patient_phone     varchar(20)   not null,
  patient_allergy   varchar(200)  not null,
  is_active         boolean       not null,
  create_date       timestamptz   not null,
  created_by        varchar(50)   not null,
  modify_date       timestamptz,
  modified_by       varchar(50),
  constraint master_pasien_pkey primary key (pasien_id)
);

-- 2.2 master_user -> auth.users
--
-- Ini satu-satunya tabel yang sengaja MENYIMPANG dari schema.sql, sesuai
-- keputusan Anda memakai Supabase Auth asli (opsi a):
--
--   * kolom `password varchar(200)` DIHAPUS. Kredensial pindah ke
--     auth.users; menyimpan plaintext di tabel yang bisa dibaca semua
--     role `authenticated` berarti user mana pun bisa membaca password
--     rekan kerjanya.
--   * `user_id` sekarang FK ke auth.users(id). Jadi master_user berubah
--     peran menjadi tabel profil/role, bukan lagi tabel kredensial.
--
-- Alur akun yang sudah diputuskan (2026-07-28):
--   - Akun dibuat MANUAL lewat Supabase Dashboard (Authentication > Users),
--     bukan dari aplikasi. Ini disengaja: membuat user dari .exe butuh
--     service_role key, dan service_role key melewati RLS sepenuhnya —
--     tidak boleh ikut ter-bundle di binary yang didistribusi.
--     Konsekuensinya `UserRepo.insert` tidak lagi bisa membuat akun; halaman
--     "Manage User" hanya bisa membaca dan mengubah profil/role.
--   - Password lama TIDAK dibawa. Dokter mendapat password baru saat cutover.
--   - Login di UI tetap memakai field "username". Aplikasi memetakannya jadi
--     email sintetis `<username>@klinik.local` sebelum dikirim ke
--     signInWithPassword(). Jadi email yang didaftarkan di Dashboard harus
--     mengikuti format itu persis. Catatan: domain .local tidak bisa
--     menerima email sungguhan, jadi reset password lewat email tidak akan
--     berfungsi — reset dilakukan manual dari Dashboard.
--   - user_id lama dari MySQL TIDAK bisa dipertahankan (Supabase tidak
--     mengizinkan menentukan id saat membuat user). Aman, karena tidak ada
--     tabel lain yang mereferensi user_id — created_by/modified_by tetap
--     varchar bebas, sesuai keputusan Anda.
--     Isi master_user.user_id dengan id dari auth.users setelah akun dibuat.
create table public.master_user (
  user_id     uuid          not null,
  username    varchar(100)  not null,
  name        varchar(200)  not null,
  role        varchar(50)   not null,
  is_active   boolean       not null,
  create_date timestamptz   not null,
  created_by  varchar(50)   not null,
  modify_date timestamptz,
  modified_by varchar(50),
  constraint master_user_pkey primary key (user_id),
  constraint fk_master_user_auth_user foreign key (user_id)
    references auth.users (id) on delete cascade
);

-- 2.3 master_obat — tidak punya dependensi
create table public.master_obat (
  obat_id      uuid          not null,
  nama_obat    varchar(100)  not null,
  nama_generik varchar(100),
  kategori     varchar(100)  not null,
  deskripsi    text,
  is_active    boolean       not null default true,
  create_date  timestamptz   not null,
  created_by   varchar(50)   not null,
  modify_date  timestamptz,
  modified_by  varchar(50),
  constraint master_obat_pkey primary key (obat_id)
);

-- 2.4 master_instrumen — tidak punya dependensi
create table public.master_instrumen (
  instrumen_id   uuid          not null,
  versi          varchar(200)  not null,
  nama_instrumen varchar(100)  not null,
  deskripsi      varchar(100)  not null,
  is_active      boolean       not null,
  create_date    timestamptz   not null,
  created_by     varchar(50)   not null,
  modify_date    timestamptz,
  modified_by    varchar(50),
  constraint master_instrumen_pkey primary key (instrumen_id)
);

-- 2.5 master_kunjungan -> master_pasien
create table public.master_kunjungan (
  kunjungan_id              uuid          not null,
  tanggal_kunjungan         date          not null,
  keluhan_utama             varchar(200)  not null,
  riwayat_penyakit_sekarang varchar(200)  not null,
  riwayat_penyakit_dahulu   varchar(200)  not null,
  riwayat_penyakit_keluarga varchar(200)  not null,
  pemeriksaan_fisik         varchar(200)  not null,
  tekanan_darah             varchar(20)   not null,
  suhu                      varchar(10)   not null,
  skala_nyeri               varchar(100)  not null,
  deskripsi_umum            varchar(200),
  kontak                    varchar(100),
  kesadaran                 varchar(100),
  orientasi                 varchar(100),
  memori                    varchar(100),
  konsentrasi               varchar(100),
  mood                      varchar(100),
  proses_berpikir           varchar(100),
  persepsi                  varchar(100),
  kemauan                   varchar(100),
  psikomotor                varchar(100),
  intelegensi               varchar(100),
  diagnosis                 varchar(200)  not null,
  terapi                    varchar(200)  not null,
  note                      varchar(200),
  pasien_id                 uuid          not null,
  is_active                 boolean       not null,
  create_date               timestamptz   not null,
  created_by                varchar(50)   not null,
  modify_date               timestamptz,
  modified_by               varchar(50),
  constraint master_kunjungan_pkey primary key (kunjungan_id),
  constraint fk_kunjungan_pasien foreign key (pasien_id)
    references public.master_pasien (pasien_id)
);

-- 2.6 master_instrumen_item -> master_instrumen
create table public.master_instrumen_item (
  instrumen_item_id uuid          not null,
  instrumen_id      uuid          not null,
  pertanyaan        varchar(200)  not null,
  teks_pertanyaan   varchar(200)  not null,
  nomer_item        integer       not null,
  kategori_skoring  varchar(200)  not null,
  is_active         boolean       not null,
  create_date       timestamptz   not null,
  created_by        varchar(50)   not null,
  modify_date       timestamptz,
  modified_by       varchar(50),
  constraint master_instrumen_item_pkey primary key (instrumen_item_id),
  constraint fk_instrumen_item_instrumen foreign key (instrumen_id)
    references public.master_instrumen (instrumen_id)
    on delete cascade on update cascade
);

-- 2.7 instrumen_interpretation_rules -> master_instrumen
create table public.instrumen_interpretation_rules (
  rule_id              uuid          not null,
  instrumen_id         uuid          not null,
  min_score            integer       not null,
  max_score            integer       not null,
  interpretation_label varchar(100)  not null,
  rule_order           integer       not null,
  is_active            boolean       not null default true,
  create_date          timestamptz   not null,
  created_by           varchar(50)   not null,
  modify_date          timestamptz,
  modified_by          varchar(50),
  constraint instrumen_interpretation_rules_pkey primary key (rule_id),
  constraint instrumen_interpretation_rules_ibfk_1 foreign key (instrumen_id)
    references public.master_instrumen (instrumen_id)
    on delete cascade
);

-- 2.8 master_resep -> master_pasien, master_kunjungan
create table public.master_resep (
  resep_id      uuid           not null,
  tanggal_resep date           not null,
  catatan       varchar(2000),
  pasien_id     uuid           not null,
  kunjungan_id  uuid           not null,
  is_active     boolean        not null,
  create_date   timestamptz    not null,
  created_by    varchar(50)    not null,
  modify_date   timestamptz,
  modified_by   varchar(50),
  constraint master_resep_pkey primary key (resep_id),
  constraint fk_resep_pasien foreign key (pasien_id)
    references public.master_pasien (pasien_id),
  constraint fk_resep_kunjungan foreign key (kunjungan_id)
    references public.master_kunjungan (kunjungan_id)
);

-- 2.9 master_asesmen_psikologis -> master_pasien, master_kunjungan, master_instrumen
create table public.master_asesmen_psikologis (
  asesmen_id         uuid          not null,
  jenis_asesmen      varchar(100)  not null,
  skor_total         integer       not null,
  hasil_interpretasi varchar(200)  not null,
  pasien_id          uuid          not null,
  kunjungan_id       uuid          not null,
  instrumen_id       uuid          not null,
  is_active          boolean       not null,
  create_date        timestamptz   not null,
  created_by         varchar(50)   not null,
  modify_date        timestamptz,
  modified_by        varchar(50),
  -- NOT NULL dipertahankan sesuai schema.sql, TAPI AsesmenPsikologisModel
  -- mendeklarasikan `DateTime? tanggalAsesmen` (nullable) dan
  -- AsesmenPsikologisRepo.insert mengirim nilainya apa adanya.
  -- Di MySQL, NULL ke kolom NOT NULL datetime diam-diam jadi
  -- '0000-00-00 00:00:00' (mode non-strict); di Postgres akan ERROR.
  -- Lihat MIGRATION_PLAN.md bagian 2.
  tanggal_asesmen    timestamptz   not null,
  constraint master_asesmen_psikologis_pkey primary key (asesmen_id),
  constraint fk_asesmen_pasien foreign key (pasien_id)
    references public.master_pasien (pasien_id),
  constraint fk_asesmen_kunjungan foreign key (kunjungan_id)
    references public.master_kunjungan (kunjungan_id),
  constraint fk_asesmen_instrumen foreign key (instrumen_id)
    references public.master_instrumen (instrumen_id)
);

-- 2.10 item_asesmen_psikologis -> master_asesmen_psikologis, master_instrumen_item
-- item_id: int(11) AUTO_INCREMENT -> generated always as identity.
-- Aman karena ItemAsesmenPsikologisRepo.insert tidak pernah menyertakan
-- kolom item_id di daftar INSERT.
create table public.item_asesmen_psikologis (
  item_id           integer     not null generated always as identity,
  skor              integer     not null,
  asesmen_id        uuid        not null,
  instrumen_item_id uuid        not null,
  is_active         boolean     not null,
  create_date       timestamptz not null,
  created_by        varchar(50) not null,
  modify_date       timestamptz,
  modified_by       varchar(50),
  constraint item_asesmen_psikologis_pkey primary key (item_id),
  constraint fk_itemasesmen_asesmen foreign key (asesmen_id)
    references public.master_asesmen_psikologis (asesmen_id),
  constraint fk_itemasesmen_instrumenitem foreign key (instrumen_item_id)
    references public.master_instrumen_item (instrumen_item_id)
);

-- 2.11 drug_interaction -> master_obat (x2)
create table public.drug_interaction (
  interaction_id      uuid                  not null,
  obat_id_1           uuid                  not null,
  obat_id_2           uuid                  not null,
  severity_level      public.severity_level not null,
  deskripsi_interaksi text                  not null,
  is_active           boolean               not null default true,
  create_date         timestamptz           not null,
  created_by          varchar(50)           not null,
  modify_date         timestamptz,
  modified_by         varchar(50),
  constraint drug_interaction_pkey primary key (interaction_id),
  -- unique_drug_pair: ObatRepo._sortObatIds() menjamin obat_id_1 < obat_id_2
  -- sebelum insert/update, jadi constraint ini benar-benar mencegah duplikat
  -- pasangan. CATATAN: urutan sort di Dart adalah sort STRING atas
  -- representasi uuid, bukan sort tipe uuid Postgres. Untuk uuid lowercase
  -- kanonik keduanya menghasilkan urutan yang sama.
  constraint unique_drug_pair unique (obat_id_1, obat_id_2),
  constraint fk_drug_interaction_obat1 foreign key (obat_id_1)
    references public.master_obat (obat_id),
  constraint fk_drug_interaction_obat2 foreign key (obat_id_2)
    references public.master_obat (obat_id)
);

-- ---------------------------------------------------------------------
-- 3. INDEX
-- ---------------------------------------------------------------------
-- Semua secondary index dari schema.sql dipertahankan 1:1.
-- Perbedaan penting vs MySQL: MySQL/InnoDB membuat index otomatis untuk
-- setiap kolom FK, Postgres TIDAK. Jadi index di bawah bukan sekadar
-- kosmetik — tanpa ini, setiap getByPasienId / getByInstrumenId /
-- getByAsesmenId berubah jadi seq scan.
-- PK dan UNIQUE sudah otomatis punya index, tidak diulang di sini.

-- drug_interaction
create index idx_obat1    on public.drug_interaction (obat_id_1);
create index idx_obat2    on public.drug_interaction (obat_id_2);
create index idx_severity on public.drug_interaction (severity_level);

-- instrumen_interpretation_rules
create index idx_instrumen on public.instrumen_interpretation_rules (instrumen_id);
create index idx_active    on public.instrumen_interpretation_rules (is_active);

-- item_asesmen_psikologis
create index fk_itemasesmen_asesmen       on public.item_asesmen_psikologis (asesmen_id);
create index fk_itemasesmen_instrumenitem on public.item_asesmen_psikologis (instrumen_item_id);

-- master_asesmen_psikologis
create index fk_asesmen_pasien    on public.master_asesmen_psikologis (pasien_id);
create index fk_asesmen_kunjungan on public.master_asesmen_psikologis (kunjungan_id);
create index fk_asesmen_instrumen on public.master_asesmen_psikologis (instrumen_id);

-- master_instrumen_item
create index fk_instrumen_item_instrumen on public.master_instrumen_item (instrumen_id);

-- master_kunjungan
create index fk_kunjungan_pasien on public.master_kunjungan (pasien_id);

-- master_obat
create index idx_nama_obat    on public.master_obat (nama_obat);
create index idx_nama_generik on public.master_obat (nama_generik);

-- master_resep
create index fk_resep_pasien    on public.master_resep (pasien_id);
create index fk_resep_kunjungan on public.master_resep (kunjungan_id);

-- ---------------------------------------------------------------------
-- 4. RLS ENABLE
-- ---------------------------------------------------------------------
-- Diaktifkan di SEMUA tabel tanpa kecuali. anon key ikut ter-bundle di
-- dalam .exe yang didistribusi ke komputer klinik dan bisa diekstrak dari
-- binary, jadi RLS adalah satu-satunya lapisan keamanan yang ada.
-- `force row level security` ditambahkan supaya pemilik tabel pun tetap
-- tunduk pada policy.
alter table public.master_pasien                  enable row level security;
alter table public.master_user                    enable row level security;
alter table public.master_obat                    enable row level security;
alter table public.master_instrumen               enable row level security;
alter table public.master_kunjungan               enable row level security;
alter table public.master_instrumen_item          enable row level security;
alter table public.instrumen_interpretation_rules enable row level security;
alter table public.master_resep                   enable row level security;
alter table public.master_asesmen_psikologis      enable row level security;
alter table public.item_asesmen_psikologis        enable row level security;
alter table public.drug_interaction               enable row level security;

alter table public.master_pasien                  force row level security;
alter table public.master_user                    force row level security;
alter table public.master_obat                    force row level security;
alter table public.master_instrumen               force row level security;
alter table public.master_kunjungan               force row level security;
alter table public.master_instrumen_item          force row level security;
alter table public.instrumen_interpretation_rules force row level security;
alter table public.master_resep                   force row level security;
alter table public.master_asesmen_psikologis      force row level security;
alter table public.item_asesmen_psikologis        force row level security;
alter table public.drug_interaction               force row level security;

-- Defense in depth: cabut grant tabel dari role anon. RLS tanpa policy
-- sudah cukup untuk memblokir, tapi revoke ini membuat kebocoran tidak
-- mungkin terjadi hanya gara-gara seseorang tanpa sengaja menambahkan
-- policy `to public` di kemudian hari.
revoke all on public.master_pasien                  from anon;
revoke all on public.master_user                    from anon;
revoke all on public.master_obat                    from anon;
revoke all on public.master_instrumen               from anon;
revoke all on public.master_kunjungan               from anon;
revoke all on public.master_instrumen_item          from anon;
revoke all on public.instrumen_interpretation_rules from anon;
revoke all on public.master_resep                   from anon;
revoke all on public.master_asesmen_psikologis      from anon;
revoke all on public.item_asesmen_psikologis        from anon;
revoke all on public.drug_interaction               from anon;

-- ---------------------------------------------------------------------
-- 5. POLICY
-- ---------------------------------------------------------------------
-- Satu policy `for all` per tabel, HANYA untuk role `authenticated`.
-- TIDAK ADA satu pun policy untuk role `anon` — ini disengaja dan tidak
-- boleh ditambahkan.
--
-- Keputusan 2026-07-28: policy ini TIDAK dipecah per-role, karena hanya ada
-- satu pengguna (dokter). Jadi "authenticated" praktis berarti "dokter itu",
-- dan membedakan hak akses antar-role tidak ada gunanya sekarang.
--
-- Yang tetap perlu diingat kalau suatu saat ada akun kedua: policy ini
-- memberi akses penuh ke seluruh rekam medis kepada siapa pun yang punya
-- sesi valid, termasuk hak mengubah kolom `role` milik akun lain. Menambah
-- staf = saatnya memecah policy per-role, bukan sekadar menambah user.

create policy authenticated_all on public.master_pasien
  for all to authenticated using (true) with check (true);

create policy authenticated_all on public.master_user
  for all to authenticated using (true) with check (true);

create policy authenticated_all on public.master_obat
  for all to authenticated using (true) with check (true);

create policy authenticated_all on public.master_instrumen
  for all to authenticated using (true) with check (true);

create policy authenticated_all on public.master_kunjungan
  for all to authenticated using (true) with check (true);

create policy authenticated_all on public.master_instrumen_item
  for all to authenticated using (true) with check (true);

create policy authenticated_all on public.instrumen_interpretation_rules
  for all to authenticated using (true) with check (true);

create policy authenticated_all on public.master_resep
  for all to authenticated using (true) with check (true);

create policy authenticated_all on public.master_asesmen_psikologis
  for all to authenticated using (true) with check (true);

create policy authenticated_all on public.item_asesmen_psikologis
  for all to authenticated using (true) with check (true);

create policy authenticated_all on public.drug_interaction
  for all to authenticated using (true) with check (true);

commit;

-- =====================================================================
-- CATATAN — TABEL YANG SENGAJA TIDAK DIBUAT
-- =====================================================================
-- `resep_item` dan `master_rule_ddi` dipakai kode Dart tapi tidak ada di
-- schema.sql. Keputusan Anda (2026-07-28): keduanya DIBUANG, tidak dibuat
-- di Postgres.
--
-- Artinya di langkah berikutnya file-file ini menjadi dead code dan harus
-- ikut dihapus, bukan diport:
--   lib/data/repositories/resep_item_repo.dart
--   lib/data/models/resep_item_model.dart
--   lib/data/repositories/rule_ddi_repo.dart
--   lib/data/models/rule_ddi_model.dart
--
-- Ikutannya: resep di aplikasi hanya menyimpan header (tanggal + catatan
-- bebas), tanpa baris obat terstruktur. Pemeriksaan interaksi obat tetap
-- jalan lewat `drug_interaction`, tapi tidak ada relasi antara resep dan
-- obat yang diresepkan — jadi interaksi tidak bisa dicek otomatis dari
-- isi sebuah resep. Ini bukan regresi migrasi (kondisinya sudah begitu di
-- MySQL sekarang), tapi patut dicatat sebagai batasan sistem.
-- =====================================================================
