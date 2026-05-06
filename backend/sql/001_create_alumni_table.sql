-- Create alumni table
CREATE TABLE IF NOT EXISTS alumni (
    id SERIAL PRIMARY KEY,
    nama VARCHAR(255) NOT NULL,
    universitas VARCHAR(255),
    jurusan VARCHAR(255),
    angkatan INTEGER NOT NULL DEFAULT 2024,
    status VARCHAR(50) NOT NULL DEFAULT 'Aktif',
    email VARCHAR(255),
    no_telepon VARCHAR(20),
    alamat TEXT,
    -- fields used by current backend handlers
    sekolah VARCHAR(255),
    tahun_lulus INTEGER,
    prestasi TEXT,
    foto VARCHAR(1024),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create indexes for better query performance
CREATE INDEX IF NOT EXISTS idx_alumni_angkatan ON alumni(angkatan);
CREATE INDEX IF NOT EXISTS idx_alumni_status ON alumni(status);
CREATE INDEX IF NOT EXISTS idx_alumni_nama ON alumni(nama);
