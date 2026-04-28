-- ===================================================
-- CREATE TABLES FOR TRY OUT AND OLIMPIADE SOAL
-- ===================================================

-- CREATE TABLE tryout_soal if not exists
CREATE TABLE IF NOT EXISTS tryout_soal (
    id SERIAL PRIMARY KEY,
    kompetisi_id INTEGER NOT NULL,
    pertanyaan TEXT,
    pilihan_a TEXT,
    pilihan_b TEXT,
    pilihan_c TEXT,
    pilihan_d TEXT,
    pilihan_e TEXT,
    jawaban VARCHAR(1),
    pembahasan TEXT,
    kategori VARCHAR(255),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (kompetisi_id) REFERENCES tryout(id) ON DELETE CASCADE
);

-- CREATE TABLE olimpiade_soal if not exists
CREATE TABLE IF NOT EXISTS olimpiade_soal (
    id SERIAL PRIMARY KEY,
    kompetisi_id INTEGER NOT NULL,
    pertanyaan TEXT,
    pilihan_a TEXT,
    pilihan_b TEXT,
    pilihan_c TEXT,
    pilihan_d TEXT,
    pilihan_e TEXT,
    jawaban VARCHAR(1),
    pembahasan TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (kompetisi_id) REFERENCES olimpiade(id) ON DELETE CASCADE
);

-- UPDATE soal_latihan table to add pembahasan column if it doesn't exist
ALTER TABLE soal_latihan
ADD COLUMN IF NOT EXISTS pembahasan TEXT DEFAULT '';

-- Create indexes for better query performance
CREATE INDEX IF NOT EXISTS idx_tryout_soal_kompetisi_id ON tryout_soal(kompetisi_id);
CREATE INDEX IF NOT EXISTS idx_olimpiade_soal_kompetisi_id ON olimpiade_soal(kompetisi_id);
