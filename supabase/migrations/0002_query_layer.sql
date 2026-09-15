-- =====================================================================
-- 0002_query_layer.sql — VIEW/RPC untuk query yang tidak bisa (atau tidak
-- sebaiknya) dijalankan lewat query builder PostgREST.
-- Prasyarat: 0001_init.sql sudah dijalankan.
--
-- Isi file ini persis mengikuti kolom "Rencana di Supabase" pada bagian 1
-- MIGRATION_PLAN.md, plus perbaikan dashboard sesuai keputusan Anda:
--
--   dashboard_stats()                 <- dashboard.dart (ganti getAll(limit:5000))
--   check_multiple_interactions()     <- ObatRepo.checkMultipleInteractions
--   find_interactions_by_drug_names() <- drug_interaction_provider:1089
--   resolve_drug_names()              <- drug_interaction_provider:1056 (N+1)
--   save_asesmen_psikologis()         <- create/asesmen_section provider (atomicity)
--
-- Tidak ada file .dart yang diubah di file ini. Penyesuaian repo Dart
-- adalah langkah berikutnya.
--
-- KEAMANAN — dua hal yang berlaku untuk SEMUA function di bawah:
--   1. Semuanya SECURITY INVOKER (default). Artinya RLS tetap berlaku atas
--      nama pemanggil; function ini TIDAK menjadi pintu belakang yang
--      melewati policy di 0001_init.sql.
--   2. Postgres memberi EXECUTE ke PUBLIC secara default untuk setiap
--      function baru. Itu harus dicabut. anon key ada di dalam .exe, jadi
--      function yang lupa di-revoke = RPC yang bisa dipanggil siapa pun
--      dari internet. Lihat blok GRANT di bagian akhir file.
-- =====================================================================

begin;

-- ---------------------------------------------------------------------
-- 1. INDEX TAMBAHAN
-- ---------------------------------------------------------------------
-- Satu-satunya index baru di luar schema.sql. Kode memakai pola
-- `LOWER(nama_obat) = LOWER(?)` di tiga tempat; `idx_nama_obat` dari
-- 0001 tidak bisa dipakai untuk itu karena ekspresinya berbeda.
create index idx_nama_obat_lower on public.master_obat (lower(nama_obat));

-- CATATAN sengaja TIDAK menambah index untuk dashboard_stats(): agregasinya
-- memang harus membaca semua baris aktif, jadi index tidak akan terpakai.
-- Keuntungan RPC ini bukan index, tapi bahwa yang menyeberangi internet
-- tinggal satu objek JSON kecil, bukan 5000 baris × 30 kolom.

-- ---------------------------------------------------------------------
-- 2. dashboard_stats()
-- ---------------------------------------------------------------------
-- Menggantikan seluruh isi _loadDashboardData() di dashboard.dart:60-141,
-- yang sekarang menarik PasienRepo.getAll() + KunjunganRepo.getAll(limit:5000)
-- lalu menghitung semuanya di Dart.
--
-- p_today WAJIB dikirim dari aplikasi (DateTime.now() lokal), bukan memakai
-- current_date server. Server Supabase berjalan di UTC; kalau "hari ini"
-- ditentukan di server, jumlah kunjungan hari ini akan salah selama 7 jam
-- setiap hari untuk klinik di WIB. Default current_date hanya jaring
-- pengaman kalau parameternya lupa dikirim.
--
-- Kesetaraan dengan logika Dart yang diganti:
--   * umur  = extract(year from age(...)) — sama dengan _calculateAge()
--   * bucket usia: <=17, 18-30, 31-45, 46-60, >60 (identik)
--   * "hari ini/minggu/bulan/tahun" = `>= awal periode`. Di Dart ditulis
--     sebagai isAfter(awal - 1 hari) atas nilai date, artinya sama persis —
--     termasuk ikut menghitung kunjungan bertanggal masa depan.
--   * minggu dimulai Senin (Dart: weekday-1; Postgres: date_trunc('week')).
--   * label bulan dikembalikan sebagai 'YYYY-MM', bukan 'Agu 2026'.
--     Pemformatan nama bulan tetap di Dart supaya locale id_ID tidak
--     berpindah ke server.
create or replace function public.dashboard_stats(p_today date default current_date)
returns jsonb
language sql
stable
set search_path = public, pg_temp
as $$
  with p as (
    select
      patient_gender,
      extract(year from age(p_today::timestamp, patient_birthdate::timestamp))::int as umur
    from master_pasien
    where is_active
  ),
  pasien_stats as (
    select
      count(*)::int                                        as total_pasien,
      (count(*) filter (where patient_gender = 'L'))::int   as pasien_laki_laki,
      (count(*) filter (where patient_gender = 'P'))::int   as pasien_perempuan,
      (count(*) filter (where umur <= 17))::int             as usia_0_17,
      (count(*) filter (where umur between 18 and 30))::int as usia_18_30,
      (count(*) filter (where umur between 31 and 45))::int as usia_31_45,
      (count(*) filter (where umur between 46 and 60))::int as usia_46_60,
      (count(*) filter (where umur > 60))::int              as usia_60_plus
    from p
  ),
  k as (
    select tanggal_kunjungan, diagnosis
    from master_kunjungan
    where is_active
  ),
  kunjungan_stats as (
    select
      count(*)::int as total_kunjungan,
      (count(*) filter (
        where tanggal_kunjungan >= p_today
      ))::int as hari_ini,
      (count(*) filter (
        where tanggal_kunjungan >= date_trunc('week', p_today::timestamp)::date
      ))::int as minggu_ini,
      (count(*) filter (
        where tanggal_kunjungan >= date_trunc('month', p_today::timestamp)::date
      ))::int as bulan_ini,
      (count(*) filter (
        where tanggal_kunjungan >= date_trunc('year', p_today::timestamp)::date
      ))::int as tahun_ini
    from k
  ),
  per_bulan as (
    select
      to_char(m, 'YYYY-MM') as bulan,
      (
        select count(*)::int
        from k
        where k.tanggal_kunjungan >= m::date
          and k.tanggal_kunjungan <  (m + interval '1 month')::date
      ) as jumlah
    from generate_series(
           date_trunc('month', p_today::timestamp) - interval '5 months',
           date_trunc('month', p_today::timestamp),
           interval '1 month'
         ) as m
  ),
  diagnosis_top as (
    select diagnosis, count(*)::int as jumlah
    from k
    where diagnosis <> ''
    group by diagnosis
    order by count(*) desc, diagnosis
    limit 5
  )
  select jsonb_build_object(
    'as_of',     p_today,
    'pasien',    (select to_jsonb(pasien_stats)    from pasien_stats),
    'kunjungan', (select to_jsonb(kunjungan_stats) from kunjungan_stats),
    'kunjungan_per_bulan', (
      select coalesce(jsonb_agg(to_jsonb(per_bulan) order by per_bulan.bulan), '[]'::jsonb)
      from per_bulan
    ),
    'diagnosis_top5', (
      select coalesce(jsonb_agg(to_jsonb(diagnosis_top) order by diagnosis_top.jumlah desc), '[]'::jsonb)
      from diagnosis_top
    )
  );
$$;

comment on function public.dashboard_stats(date) is
  'Statistik dashboard dalam satu round-trip. p_today harus tanggal lokal klien (WIB), bukan tanggal server (UTC).';

-- ---------------------------------------------------------------------
-- 3. check_multiple_interactions()
-- ---------------------------------------------------------------------
-- Menggantikan ObatRepo.checkMultipleInteractions, yang membangun
-- `(obat_id_1 = ? AND obat_id_2 = ?) OR ...` untuk setiap pasangan lewat
-- string concat — bentuk yang tidak punya padanan di query builder.
--
-- Enumerasi pasangan tidak diperlukan lagi: karena unique_drug_pair +
-- _sortObatIds() menjamin setiap baris menyimpan pasangan terurut, "baris
-- yang kedua obatnya ada di dalam daftar" sudah persis sama artinya dengan
-- "baris yang cocok dengan salah satu pasangan". Hasilnya identik dengan
-- versi lama, tanpa n² placeholder.
create or replace function public.check_multiple_interactions(p_obat_ids uuid[])
returns table (
  interaction_id      uuid,
  obat_id_1           uuid,
  obat_id_2           uuid,
  nama_obat_1         varchar(100),
  nama_obat_2         varchar(100),
  severity_level      public.severity_level,
  deskripsi_interaksi text,
  is_active           boolean,
  create_date         timestamptz,
  created_by          varchar(50),
  modify_date         timestamptz,
  modified_by         varchar(50)
)
language sql
stable
set search_path = public, pg_temp
as $$
  select
    di.interaction_id,
    di.obat_id_1,
    di.obat_id_2,
    mo1.nama_obat,
    mo2.nama_obat,
    di.severity_level,
    di.deskripsi_interaksi,
    di.is_active,
    di.create_date,
    di.created_by,
    di.modify_date,
    di.modified_by
  from drug_interaction di
  left join master_obat mo1 on mo1.obat_id = di.obat_id_1
  left join master_obat mo2 on mo2.obat_id = di.obat_id_2
  where di.is_active
    and di.obat_id_1 = any(p_obat_ids)
    and di.obat_id_2 = any(p_obat_ids)
  order by di.severity_level desc;
$$;

-- ---------------------------------------------------------------------
-- 4. resolve_drug_names()
-- ---------------------------------------------------------------------
-- Menggantikan loop di drug_interaction_provider.dart:1052-1067 yang
-- menjalankan SATU query per obat (`LOWER(nama_obat) = LOWER(?) LIMIT 1`).
-- Di localhost pola ini ~1 ms per obat; lewat internet 100-300 ms per obat.
-- Sekarang jadi satu round-trip untuk semua nama.
--
-- Mengembalikan nama kanonik seperti tersimpan di master_obat (bukan input
-- pemanggil), karena kode di hilir membandingkan nama hasil resolve dengan
-- nama pada baris interaksi.
--
-- CATATAN: versi lama tidak menyaring is_active, jadi obat yang sudah
-- di-soft-delete pun ikut cocok. Perilaku itu dipertahankan di sini supaya
-- migrasi tidak diam-diam mengubah hasil pengecekan interaksi; kalau memang
-- seharusnya menyaring, itu perbaikan tersendiri.
create or replace function public.resolve_drug_names(p_names text[])
returns table (
  input_name text,
  nama_obat  varchar(100)
)
language sql
stable
set search_path = public, pg_temp
as $$
  select distinct on (n.nama) n.nama, mo.nama_obat
  from unnest(p_names) as n(nama)
  join master_obat mo on lower(mo.nama_obat) = lower(trim(n.nama))
  order by n.nama, mo.nama_obat;
$$;

-- ---------------------------------------------------------------------
-- 5. find_interactions_by_drug_names()
-- ---------------------------------------------------------------------
-- Menggantikan query di drug_interaction_provider.dart:1089, yang membangun
-- `(LOWER(mo1.nama_obat) = LOWER(?) OR LOWER(mo2.nama_obat) = LOWER(?)) OR ...`
-- lewat string concat.
--
-- Nama kolom hasil sengaja dipertahankan `obat1_name` / `obat2_name`
-- (bukan `nama_obat_1` seperti di function nomor 3), karena kode pemanggil
-- di baris 1111-1112 membaca nama itu. Dua penamaan berbeda ini memang sudah
-- ada di kode sekarang.
--
-- Perhatikan: sama seperti versi lama, baris ikut terambil bila CUKUP SATU
-- dari dua obatnya ada di daftar. Penyaringan pasangan yang sebenarnya
-- dilakukan di Dart (baris 1124-1142), jadi jangan diperketat di sini.
create or replace function public.find_interactions_by_drug_names(p_names text[])
returns table (
  interaction_id      uuid,
  obat_id_1           uuid,
  obat_id_2           uuid,
  obat1_name          varchar(100),
  obat2_name          varchar(100),
  severity_level      public.severity_level,
  deskripsi_interaksi text,
  is_active           boolean,
  create_date         timestamptz,
  created_by          varchar(50),
  modify_date         timestamptz,
  modified_by         varchar(50)
)
language sql
stable
set search_path = public, pg_temp
as $$
  with lowered as (
    select lower(trim(n)) as nama from unnest(p_names) as n
  )
  select
    di.interaction_id,
    di.obat_id_1,
    di.obat_id_2,
    mo1.nama_obat,
    mo2.nama_obat,
    di.severity_level,
    di.deskripsi_interaksi,
    di.is_active,
    di.create_date,
    di.created_by,
    di.modify_date,
    di.modified_by
  from drug_interaction di
  join master_obat mo1 on mo1.obat_id = di.obat_id_1
  join master_obat mo2 on mo2.obat_id = di.obat_id_2
  where di.is_active
    and (
      lower(mo1.nama_obat) in (select nama from lowered)
      or
      lower(mo2.nama_obat) in (select nama from lowered)
    );
$$;

-- ---------------------------------------------------------------------
-- 6. save_asesmen_psikologis()
-- ---------------------------------------------------------------------
-- Menutup lubang atomicity yang sudah ada sejak versi MySQL:
-- create_asesmen_psikologis_provider.dart:290-303 dan
-- asesmen_section_provider.dart:215-228 melakukan 1 INSERT master diikuti
-- N INSERT item sebagai perintah terpisah, tanpa transaksi
-- (DatabaseHelper.transactionQuery tidak pernah dipanggil dari mana pun).
-- Kalau putus di tengah, asesmen tersimpan dengan sebagian item saja —
-- dan skor total tidak lagi cocok dengan item yang tersimpan.
-- Di localhost risikonya kecil; lewat internet jauh lebih besar.
--
-- Function ini menulis keduanya dalam satu transaksi: semua masuk, atau
-- tidak ada yang masuk sama sekali.
--
-- p_items berbentuk: [{"instrumen_item_id": "<uuid>", "skor": 3}, ...]
-- p_tanggal_asesmen wajib non-NULL (kolomnya NOT NULL — lihat bagian 2
-- MIGRATION_PLAN.md; ini kasus yang di MySQL lolos diam-diam).
create or replace function public.save_asesmen_psikologis(
  p_asesmen_id         uuid,
  p_jenis_asesmen      varchar(100),
  p_skor_total         integer,
  p_hasil_interpretasi varchar(200),
  p_pasien_id          uuid,
  p_kunjungan_id       uuid,
  p_instrumen_id       uuid,
  p_tanggal_asesmen    timestamptz,
  p_created_by         varchar(50),
  p_create_date        timestamptz,
  p_items              jsonb
)
returns uuid
language plpgsql
set search_path = public, pg_temp
as $$
begin
  if p_items is null or jsonb_typeof(p_items) <> 'array' then
    raise exception 'p_items harus berupa array JSON, bukan %', jsonb_typeof(p_items);
  end if;

  insert into master_asesmen_psikologis (
    asesmen_id, jenis_asesmen, skor_total, hasil_interpretasi,
    pasien_id, kunjungan_id, instrumen_id, tanggal_asesmen,
    is_active, create_date, created_by
  ) values (
    p_asesmen_id, p_jenis_asesmen, p_skor_total, p_hasil_interpretasi,
    p_pasien_id, p_kunjungan_id, p_instrumen_id, p_tanggal_asesmen,
    true, p_create_date, p_created_by
  );

  insert into item_asesmen_psikologis (
    skor, asesmen_id, instrumen_item_id, is_active, create_date, created_by
  )
  select
    (item->>'skor')::int,
    p_asesmen_id,
    (item->>'instrumen_item_id')::uuid,
    true,
    p_create_date,
    p_created_by
  from jsonb_array_elements(p_items) as item;

  return p_asesmen_id;
end;
$$;

-- ---------------------------------------------------------------------
-- 7. GRANT / REVOKE
-- ---------------------------------------------------------------------
-- Postgres memberi EXECUTE ke PUBLIC untuk setiap function baru, dan PUBLIC
-- mencakup role `anon`. Karena anon key ikut ter-bundle di .exe, EXECUTE
-- untuk anon berarti siapa pun yang mengekstrak key itu bisa memanggil RPC
-- ini dari internet. Jadi dicabut dulu, baru diberikan ke `authenticated`.
--
-- Catatan: RLS tetap menjadi lapisan pertahanan kedua — semua function di
-- sini SECURITY INVOKER, jadi meskipun EXECUTE bocor, tabelnya tetap
-- tertutup untuk anon. Revoke ini membuat lapisan pertamanya juga rapat.

revoke execute on function public.dashboard_stats(date)                      from public, anon;
revoke execute on function public.check_multiple_interactions(uuid[])        from public, anon;
revoke execute on function public.resolve_drug_names(text[])                 from public, anon;
revoke execute on function public.find_interactions_by_drug_names(text[])    from public, anon;
revoke execute on function public.save_asesmen_psikologis(
  uuid, varchar, integer, varchar, uuid, uuid, uuid, timestamptz, varchar, timestamptz, jsonb
) from public, anon;

grant execute on function public.dashboard_stats(date)                       to authenticated;
grant execute on function public.check_multiple_interactions(uuid[])         to authenticated;
grant execute on function public.resolve_drug_names(text[])                  to authenticated;
grant execute on function public.find_interactions_by_drug_names(text[])     to authenticated;
grant execute on function public.save_asesmen_psikologis(
  uuid, varchar, integer, varchar, uuid, uuid, uuid, timestamptz, varchar, timestamptz, jsonb
) to authenticated;

commit;

-- =====================================================================
-- YANG SENGAJA TIDAK DIBUATKAN RPC
-- =====================================================================
-- Sisa query di bagian 1 MIGRATION_PLAN.md semuanya bisa dinyatakan dengan
-- query builder, jadi tidak perlu function:
--
--   * AsesmenPsikologisRepo.search — `DATE(create_date) >= d` menjadi
--     .gte('create_date', d) dan .lt('create_date', d + 1 hari).
--   * InterpretationRuleRepo.getInterpretation — `? BETWEEN min AND max`
--     menjadi .lte('min_score', skor).gte('max_score', skor).
--   * Semua JOIN drug_interaction -> master_obat menjadi embedded select
--     dengan alias FK: select('*, mo1:obat_id_1(nama_obat), mo2:obat_id_2(nama_obat)').
--   * N+1 InstrumenItemRepo.getById (manage_asesmen_psikologis_provider:293,
--     asesmen_section_provider:279) cukup diganti satu .in_('instrumen_item_id', ids).
--   * Semua COUNT(*) menjadi .select('*', head: true, count: 'exact').
--
-- Autocomplete obat (helper.dart:462, drug_interaction_dialog.dart:908) juga
-- tetap query builder, tapi `SELECT DISTINCT` tidak punya padanan di
-- PostgREST — dedup dilakukan di Dart. Amannya karena sudah ada LIMIT 10.
-- =====================================================================
