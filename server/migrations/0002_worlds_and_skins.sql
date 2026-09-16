-- Preserve every existing run and score while opening the new playable worlds.
CREATE TABLE runs_v2 (
 id TEXT PRIMARY KEY, owner TEXT NOT NULL, world INTEGER NOT NULL CHECK(world IN (1,2,4,5,6)),
 name TEXT NOT NULL, country TEXT NOT NULL, started_at INTEGER NOT NULL,
 level INTEGER NOT NULL DEFAULT 0, elapsed_ms INTEGER NOT NULL DEFAULT 0, deaths INTEGER NOT NULL DEFAULT 0,
 skin INTEGER NOT NULL DEFAULT 1 CHECK(skin BETWEEN 1 AND 5)
);
INSERT INTO runs_v2 SELECT *,1 FROM runs;
DROP TABLE runs;
ALTER TABLE runs_v2 RENAME TO runs;
CREATE INDEX runs_owner_started ON runs(owner,started_at);
CREATE TABLE scores_v2 (
 run_id TEXT PRIMARY KEY, owner TEXT NOT NULL, world INTEGER NOT NULL CHECK(world IN (1,2,4,5,6)),
 name TEXT NOT NULL, country TEXT NOT NULL, elapsed_ms INTEGER NOT NULL, deaths INTEGER NOT NULL,
 completed_at INTEGER NOT NULL, skin INTEGER NOT NULL DEFAULT 1 CHECK(skin BETWEEN 1 AND 5)
);
INSERT INTO scores_v2 SELECT *,1 FROM scores;
DROP TABLE scores;
ALTER TABLE scores_v2 RENAME TO scores;
CREATE INDEX scores_world_time ON scores(world,elapsed_ms,deaths);
CREATE INDEX scores_country_time ON scores(world,country,elapsed_ms,deaths);
CREATE INDEX scores_owner_world ON scores(owner,world);
