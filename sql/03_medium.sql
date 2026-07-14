-- =====================================================================
-- TIER 2 — Multi-column grouping, conditional aggregation, subqueries
-- =====================================================================

-- Q6. Calculate the average danceability of tracks in each album.
SELECT album, AVG(danceability) AS avg_danceability
FROM spotify
GROUP BY 1
ORDER BY 2 DESC;


-- Q7. Find the top 5 tracks with the highest energy values.
SELECT track, MAX(energy) AS energy
FROM spotify
GROUP BY 1
ORDER BY 2 DESC
LIMIT 5;


-- Q8. List all tracks along with their views and likes where official_video = TRUE.
SELECT track, SUM(views) AS total_views, SUM(likes) AS total_likes
FROM spotify
WHERE official_video = TRUE
GROUP BY 1
ORDER BY 2 DESC;


-- Q9. For each album, calculate the total views of all associated tracks.
SELECT album, track, SUM(views) AS total_views
FROM spotify
GROUP BY 1, 2
ORDER BY 3 DESC;


-- Q10. Retrieve the track names that have been streamed on Spotify more than on YouTube.
-- Conditional aggregation (CASE inside SUM) pivots the platform rows into two columns.
-- COALESCE turns the "no rows matched" NULL into 0 so the comparison is well-defined.
-- The streamed_on_youtube <> 0 guard drops tracks that never appeared on YouTube at all —
-- otherwise every Spotify-only track would trivially satisfy the condition.
SELECT * FROM (
    SELECT
        track,
        COALESCE(SUM(CASE WHEN most_played_on = 'Spotify' THEN stream END), 0) AS streamed_on_spotify,
        COALESCE(SUM(CASE WHEN most_played_on = 'Youtube'  THEN stream END), 0) AS streamed_on_youtube
    FROM spotify
    GROUP BY 1
) AS t1
WHERE streamed_on_spotify > streamed_on_youtube
  AND streamed_on_youtube <> 0;
