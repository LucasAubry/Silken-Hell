-- Immutable proof of runs that reached the worldwide #1 position in a biome.
-- Copy score fields so the souvenir does not depend on a current leaderboard.
CREATE TABLE top_one_history (
 run_id TEXT PRIMARY KEY, owner TEXT NOT NULL,
 world INTEGER NOT NULL CHECK(world BETWEEN 1 AND 7),
 hardcore INTEGER NOT NULL CHECK(hardcore IN (0,1)),
 name TEXT NOT NULL, elapsed_ms INTEGER NOT NULL, deaths INTEGER NOT NULL,
 skin INTEGER NOT NULL, achieved_at INTEGER NOT NULL
);
CREATE INDEX top_one_owner_date ON top_one_history(owner,achieved_at DESC,run_id);
CREATE INDEX scores_top_one_order ON scores(world,hardcore,(elapsed_ms+deaths*(1000.0/3)),deaths,completed_at,run_id);

-- Reconstruct earlier records from retained scores and their publication dates.
INSERT INTO top_one_history
SELECT s.run_id,s.owner,s.world,s.hardcore,s.name,s.elapsed_ms,s.deaths,s.skin,s.completed_at
FROM scores s WHERE s.world BETWEEN 1 AND 7 AND NOT EXISTS (
 SELECT 1 FROM scores p WHERE p.world=s.world AND p.hardcore=s.hardcore
 AND (p.completed_at,p.run_id)<(s.completed_at,s.run_id)
 AND (p.elapsed_ms+p.deaths*(1000.0/3),p.deaths,p.completed_at,p.run_id)
     <(s.elapsed_ms+s.deaths*(1000.0/3),s.deaths,s.completed_at,s.run_id)
);

-- Runs and their record proof are committed together, including concurrent uploads.
CREATE TRIGGER scores_top_one AFTER INSERT ON scores
WHEN NEW.world BETWEEN 1 AND 7
BEGIN
 INSERT OR IGNORE INTO top_one_history
 SELECT NEW.run_id,NEW.owner,NEW.world,NEW.hardcore,NEW.name,NEW.elapsed_ms,NEW.deaths,NEW.skin,NEW.completed_at
 WHERE NOT EXISTS (
  SELECT 1 FROM scores p WHERE p.world=NEW.world AND p.hardcore=NEW.hardcore
  AND (p.elapsed_ms+p.deaths*(1000.0/3),p.deaths,p.completed_at,p.run_id)
      <(NEW.elapsed_ms+NEW.deaths*(1000.0/3),NEW.deaths,NEW.completed_at,NEW.run_id)
 );
END;
