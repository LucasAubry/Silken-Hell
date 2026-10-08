-- Add isolated hardcore rankings and the seven-boss Sanctuary run.
-- Preserve all historical records, including legacy single-boss challenges.
CREATE TABLE runs_v10 (
 id TEXT PRIMARY KEY, owner TEXT NOT NULL, world INTEGER NOT NULL CHECK(world IN (1,2,3,4,5,6,7,8,9,10,11,12,13,14)),
 name TEXT NOT NULL, country TEXT NOT NULL, started_at INTEGER NOT NULL,
 level INTEGER NOT NULL DEFAULT 0, elapsed_ms INTEGER NOT NULL DEFAULT 0, deaths INTEGER NOT NULL DEFAULT 0,
 skin INTEGER NOT NULL DEFAULT 1 CHECK(skin BETWEEN 1 AND 22),
 hardcore INTEGER NOT NULL DEFAULT 0 CHECK(hardcore IN (0,1))
);
INSERT INTO runs_v10 SELECT *,0 FROM runs;
DROP TABLE runs;
ALTER TABLE runs_v10 RENAME TO runs;
CREATE INDEX runs_owner_started ON runs(owner,started_at);
CREATE TABLE scores_v10 (
 run_id TEXT PRIMARY KEY, owner TEXT NOT NULL, world INTEGER NOT NULL CHECK(world IN (1,2,3,4,5,6,7,8,9,10,11,12,13,14)),
 name TEXT NOT NULL, country TEXT NOT NULL, elapsed_ms INTEGER NOT NULL, deaths INTEGER NOT NULL,
 completed_at INTEGER NOT NULL, skin INTEGER NOT NULL DEFAULT 1 CHECK(skin BETWEEN 1 AND 22),
 hardcore INTEGER NOT NULL DEFAULT 0 CHECK(hardcore IN (0,1))
);
INSERT INTO scores_v10 SELECT *,0 FROM scores;
DROP TABLE scores;
ALTER TABLE scores_v10 RENAME TO scores;
CREATE INDEX scores_world_time ON scores(world,hardcore,elapsed_ms,deaths);
CREATE INDEX scores_country_time ON scores(world,hardcore,country,elapsed_ms,deaths);
CREATE INDEX scores_owner_world ON scores(owner,world);
