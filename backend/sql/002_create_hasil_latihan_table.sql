-- Create hasil_latihan table (if not exists)
-- This table stores completed practice quiz results per student
CREATE TABLE IF NOT EXISTS hasil_latihan (
    id         SERIAL PRIMARY KEY,
    siswa_id   INTEGER NOT NULL,
    materi_id  INTEGER NOT NULL,
    latihan_title VARCHAR(255) NOT NULL DEFAULT 'Latihan Soal',
    skor       INTEGER NOT NULL DEFAULT 0,
    total_soal INTEGER NOT NULL DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (siswa_id, materi_id, latihan_title)
);

-- Add index for performance
CREATE INDEX IF NOT EXISTS idx_hasil_latihan_siswa ON hasil_latihan(siswa_id);

-- Add durasi column to olimpiade table if it doesn't exist
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'olimpiade' AND column_name = 'durasi'
    ) THEN
        ALTER TABLE olimpiade ADD COLUMN durasi INTEGER NOT NULL DEFAULT 120;
    END IF;
END $$;
