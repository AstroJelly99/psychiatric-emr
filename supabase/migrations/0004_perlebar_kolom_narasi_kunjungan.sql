-- =====================================================================
-- 0004_perlebar_kolom_narasi_kunjungan.sql
-- Prasyarat: 0001_init.sql sudah dijalankan.
--
-- BUG: dokter mengisi field kunjungan (mis. Terapi) dengan catatan klinis
-- wajar ("minum sertraline ... tapi kalau minum X, pagi nyaman, tidur
-- malam cukup...", 219 karakter) dan mendapat dialog generik "Terjadi
-- Kesalahan / Coba ulangi lagi" tanpa penjelasan.
--
-- AKAR MASALAH: kolom narasi klinis di master_kunjungan dibatasi
-- varchar(200) (field utama) / varchar(100) (field pemeriksaan mental).
-- Postgres menolak INSERT/UPDATE begitu isinya lebih panjang dari batas
-- itu ("value too long for type character varying"); KunjunganProvider
-- menangkap exception apa pun dan cuma mengembalikan `success = false`,
-- jadi pesan aslinya tidak pernah sampai ke layar.
--
-- Field yang TIDAK ikut dilebarkan dengan sengaja: tekanan_darah, suhu,
-- skala_nyeri, nadi, respiration_rate — semuanya nilai pendek terstruktur
-- (mis. "120/80 mmHg", "36.5 °C", "80 x/menit"), bukan narasi bebas, dan
-- tidak ada laporan bug untuk field-field ini.
-- =====================================================================

begin;

alter table public.master_kunjungan
  alter column keluhan_utama             type text,
  alter column riwayat_penyakit_sekarang type text,
  alter column riwayat_penyakit_dahulu   type text,
  alter column riwayat_penyakit_keluarga type text,
  alter column pemeriksaan_fisik         type text,
  alter column diagnosis                 type text,
  alter column terapi                    type text,
  alter column note                      type text,
  alter column deskripsi_umum            type text,
  alter column kontak                    type text,
  alter column kesadaran                 type text,
  alter column orientasi                 type text,
  alter column memori                    type text,
  alter column konsentrasi               type text,
  alter column mood                      type text,
  alter column proses_berpikir           type text,
  alter column persepsi                  type text,
  alter column kemauan                   type text,
  alter column psikomotor                type text,
  alter column intelegensi               type text;

commit;
