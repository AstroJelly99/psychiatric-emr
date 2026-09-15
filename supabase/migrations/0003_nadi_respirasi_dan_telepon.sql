-- =====================================================================
-- 0003_nadi_respirasi_dan_telepon.sql
-- Prasyarat: 0001_init.sql sudah dijalankan.
--
-- Dua perubahan tidak berhubungan tapi digabung satu migrasi kecil:
--
--   1. master_kunjungan.nadi, master_kunjungan.respiration_rate (baru)
--      Opsional (nullable) menyamai deskripsi_umum dkk — form vital sign
--      lama (tekanan_darah, suhu, skala_nyeri) semuanya NOT NULL karena
--      dibuat dulu sebelum ada pola field opsional; dua kolom baru ini
--      SENGAJA nullable supaya kunjungan lama (dan form yang belum diisi
--      dokter) tidak pernah gagal insert/update gara-gara kolom kosong.
--
--   2. master_pasien.patient_phone: varchar(20) -> varchar(200)
--      Field ini sekarang menampung lebih dari satu nomor (pasien, ayah,
--      ibu, dst, satu baris per nomor) — 20 karakter cuma cukup untuk
--      satu nomor pendek. Tanpa pelebaran ini, isi dari textarea baru di
--      form pasien akan ditolak Postgres (value too long for varchar(20))
--      persis error "data tidak masuk" yang ingin dihindari.
-- =====================================================================

begin;

alter table public.master_kunjungan
  add column nadi               varchar(20),
  add column respiration_rate   varchar(20);

alter table public.master_pasien
  alter column patient_phone type varchar(200);

commit;
