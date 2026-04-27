-- CREATE TABLE PAKET LES (NEW SCHEMA)
CREATE TABLE paket_les (
    id SERIAL PRIMARY KEY,
    nama_paket VARCHAR(100) NOT NULL,
    harga_awal BIGINT NOT NULL,
    diskon INT DEFAULT 0,
    tanggal_mulai_promo DATE,
    tanggal_selesai_promo DATE,
    deskripsi TEXT,
    durasi INT,
    status VARCHAR(50) DEFAULT 'aktif',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- CREATE INDEX untuk performance
CREATE INDEX idx_paket_les_status ON paket_les (status);

-- SELECT UNTUK MOBILE APP (menampilkan paket seperti image yang Anda kirim)
SELECT 
    id,
    nama_paket,
    harga_awal,
    diskon,
    tanggal_mulai_promo,
    tanggal_selesai_promo,
    deskripsi,
    durasi,
    status,
    created_at,
    -- Calculate harga promo
    CASE 
        WHEN diskon > 0 THEN ROUND(harga_awal * (100 - diskon) / 100.0)
        ELSE harga_awal
    END AS harga_promo
FROM paket_les
WHERE status = 'aktif'
ORDER BY created_at DESC;

-- SAMPLE QUERY untuk stats dashboard (admin)
SELECT 
    COUNT(*) AS total_paket,
    SUM(CASE WHEN status = 'aktif' THEN 1 ELSE 0 END) AS paket_aktif
FROM paket_les;

-- SAMPLE QUERY dengan filter
SELECT *
FROM paket_les
WHERE status = 'aktif'
  AND nama_paket ILIKE '%10%' -- search
ORDER BY created_at DESC;

-- INSERT SAMPLE DATA
INSERT INTO paket_les (
    nama_paket, 
    harga_awal, 
    diskon, 
    tanggal_mulai_promo, 
    tanggal_selesai_promo,
    deskripsi, 
    durasi, 
    status
) VALUES 
(
    'Kelas 10 SMA - 1 Semester',
    4250000,
    5,
    '2026-01-15',
    '2026-01-31',
    'Paket bimbingan intensif untuk kelas 10 SMA selama 1 semester. Materi lengkap dan mentor berpengalaman.',
    120,
    'aktif'
),
(
    'Kelas 10 SMA - 3 Semester',
    13500000,
    0,
    '2026-01-01',
    '2026-12-31',
    'Paket bimbingan komprehensif untuk kelas 10 SMA selama 3 semester akademik. Mencakup semua materi pelajaran.',
    120,
    'aktif'
),
(
    'Kelas 11 SMA - 1 Semester',
    5000000,
    25,
    '2026-01-01',
    '2026-01-31',
    'Persiapan matang untuk kelas 11 dengan fokus pada pendalaman materi.',
    120,
    'aktif'
);
