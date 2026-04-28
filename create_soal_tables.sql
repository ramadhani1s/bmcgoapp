-- Create tryout_soal table
CREATE TABLE IF NOT EXISTS tryout_soal (
    id SERIAL PRIMARY KEY,
    kompetisi_id INTEGER NOT NULL REFERENCES tryout(id) ON DELETE CASCADE,
    pertanyaan TEXT NOT NULL,
    pilihan_a TEXT,
    pilihan_b TEXT,
    pilihan_c TEXT,
    pilihan_d TEXT,
    pilihan_e TEXT,
    jawaban VARCHAR(1) NOT NULL,
    pembahasan TEXT,
    kategori VARCHAR(255),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create olimpiade_soal table
CREATE TABLE IF NOT EXISTS olimpiade_soal (
    id SERIAL PRIMARY KEY,
    kompetisi_id INTEGER NOT NULL REFERENCES olimpiade(id) ON DELETE CASCADE,
    pertanyaan TEXT NOT NULL,
    pilihan_a TEXT,
    pilihan_b TEXT,
    pilihan_c TEXT,
    pilihan_d TEXT,
    pilihan_e TEXT,
    jawaban VARCHAR(1) NOT NULL,
    pembahasan TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create indexes for better query performance
CREATE INDEX IF NOT EXISTS idx_tryout_soal_kompetisi_id ON tryout_soal(kompetisi_id);
CREATE INDEX IF NOT EXISTS idx_tryout_soal_kategori ON tryout_soal(kategori);
CREATE INDEX IF NOT EXISTS idx_olimpiade_soal_kompetisi_id ON olimpiade_soal(kompetisi_id);
