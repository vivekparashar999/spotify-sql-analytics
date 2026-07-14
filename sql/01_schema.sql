-- =====================================================================
-- Spotify + YouTube Track Analytics — Schema
-- Engine: PostgreSQL 15
-- Source: Kaggle "Spotify and YouTube" dataset (~20.6K tracks, 24 columns)
-- =====================================================================

DROP TABLE IF EXISTS spotify;

CREATE TABLE spotify (
    artist            VARCHAR(255),
    track             VARCHAR(255),
    album             VARCHAR(255),
    album_type        VARCHAR(50),      -- 'album' | 'single' | 'compilation'

    -- Spotify audio features (0..1 unless noted)
    danceability      FLOAT,
    energy            FLOAT,
    loudness          FLOAT,            -- dB, negative
    speechiness       FLOAT,
    acousticness      FLOAT,
    instrumentalness  FLOAT,
    liveness          FLOAT,
    valence           FLOAT,
    tempo             FLOAT,            -- BPM
    duration_min      FLOAT,

    -- YouTube engagement
    title             VARCHAR(255),     -- YouTube video title
    channel           VARCHAR(255),
    views             FLOAT,
    likes             BIGINT,
    comments          BIGINT,
    licensed          BOOLEAN,
    official_video    BOOLEAN,

    -- Cross-platform
    stream            BIGINT,           -- Spotify stream count
    energy_liveness   FLOAT,
    most_played_on    VARCHAR(50)       -- 'Spotify' | 'Youtube'
);

-- ---------------------------------------------------------------------
-- Data quality checks run before analysis
-- ---------------------------------------------------------------------

-- Row count
SELECT COUNT(*) AS total_rows FROM spotify;

-- Distinct entity counts (sanity: tracks < rows means duplicates across platforms)
SELECT
    COUNT(DISTINCT artist) AS artists,
    COUNT(DISTINCT album)  AS albums,
    COUNT(DISTINCT track)  AS tracks
FROM spotify;

-- Range check: duration must be positive
SELECT MIN(duration_min) AS min_dur, MAX(duration_min) AS max_dur FROM spotify;

-- Invalid rows: zero-duration tracks are corrupt records — remove before analysis
SELECT COUNT(*) AS zero_duration_rows FROM spotify WHERE duration_min = 0;

DELETE FROM spotify WHERE duration_min = 0;

-- Categorical sanity: which platform dominates
SELECT most_played_on, COUNT(*) AS n
FROM spotify
GROUP BY most_played_on
ORDER BY n DESC;
