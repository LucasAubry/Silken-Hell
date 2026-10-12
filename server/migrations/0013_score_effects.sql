-- Keep cosmetic switches with each run after temporary run metadata is removed.
ALTER TABLE runs ADD COLUMN effects TEXT NOT NULL DEFAULT '{}';
ALTER TABLE scores ADD COLUMN effects TEXT NOT NULL DEFAULT '{}';

-- Older replays already recorded these switches; recover only known appearances.
UPDATE scores SET effects=(SELECT json_extract(payload,'$.effects') FROM run_replays WHERE run_id=scores.run_id)
WHERE EXISTS(SELECT 1 FROM run_replays WHERE run_id=scores.run_id AND json_valid(payload) AND json_type(payload,'$.effects')='object');
