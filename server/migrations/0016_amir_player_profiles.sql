-- Add Amir (27), preserving historical scores, replays and trophy records.
CREATE TABLE runs_v16 (
 id TEXT PRIMARY KEY, owner TEXT NOT NULL, world INTEGER NOT NULL CHECK(world IN (1,2,3,4,5,6,7,8,9,10,11,12,13,14)),
 name TEXT NOT NULL, country TEXT NOT NULL, started_at INTEGER NOT NULL,
 level INTEGER NOT NULL DEFAULT 0, elapsed_ms INTEGER NOT NULL DEFAULT 0, deaths INTEGER NOT NULL DEFAULT 0,
 skin INTEGER NOT NULL DEFAULT 1 CHECK(skin BETWEEN 1 AND 27),
 hardcore INTEGER NOT NULL DEFAULT 0 CHECK(hardcore IN (0,1)),
 effects TEXT NOT NULL DEFAULT '{}'
);
INSERT INTO runs_v16 SELECT * FROM runs;
DROP TABLE runs;
ALTER TABLE runs_v16 RENAME TO runs;
CREATE INDEX runs_owner_started ON runs(owner,started_at);

CREATE TABLE scores_v16 (
 run_id TEXT PRIMARY KEY, owner TEXT NOT NULL, world INTEGER NOT NULL CHECK(world IN (1,2,3,4,5,6,7,8,9,10,11,12,13,14)),
 name TEXT NOT NULL, country TEXT NOT NULL, elapsed_ms INTEGER NOT NULL, deaths INTEGER NOT NULL,
 completed_at INTEGER NOT NULL, skin INTEGER NOT NULL DEFAULT 1 CHECK(skin BETWEEN 1 AND 27),
 hardcore INTEGER NOT NULL DEFAULT 0 CHECK(hardcore IN (0,1)),
 effects TEXT NOT NULL DEFAULT '{}'
);
INSERT INTO scores_v16 SELECT * FROM scores;
DROP TABLE scores;
ALTER TABLE scores_v16 RENAME TO scores;
CREATE INDEX scores_world_time ON scores(world,hardcore,elapsed_ms,deaths);
CREATE INDEX scores_country_time ON scores(world,hardcore,country,elapsed_ms,deaths);
CREATE INDEX scores_owner_world ON scores(owner,world);
CREATE INDEX scores_top_one_order ON scores(world,hardcore,(elapsed_ms+deaths*(1000.0/3)),deaths,completed_at,run_id);

-- Existing top-one history and replays remain intact; restore score publication.
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

CREATE TABLE player_profiles (owner TEXT PRIMARY KEY, payload TEXT NOT NULL, updated_at INTEGER NOT NULL);
