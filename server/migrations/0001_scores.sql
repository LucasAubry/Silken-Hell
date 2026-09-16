CREATE TABLE IF NOT EXISTS runs (
  id TEXT PRIMARY KEY,
  owner TEXT NOT NULL,
  world INTEGER NOT NULL CHECK(world IN (1,2)),
  name TEXT NOT NULL,
  country TEXT NOT NULL,
  started_at INTEGER NOT NULL,
  level INTEGER NOT NULL DEFAULT 0,
  elapsed_ms INTEGER NOT NULL DEFAULT 0,
  deaths INTEGER NOT NULL DEFAULT 0
);
CREATE INDEX IF NOT EXISTS runs_owner_started ON runs(owner, started_at);
CREATE TABLE IF NOT EXISTS scores (
  run_id TEXT PRIMARY KEY,
  owner TEXT NOT NULL,
  world INTEGER NOT NULL CHECK(world IN (1,2)),
  name TEXT NOT NULL,
  country TEXT NOT NULL,
  elapsed_ms INTEGER NOT NULL,
  deaths INTEGER NOT NULL,
  completed_at INTEGER NOT NULL
);
CREATE INDEX IF NOT EXISTS scores_world_time ON scores(world, elapsed_ms, deaths);
CREATE INDEX IF NOT EXISTS scores_country_time ON scores(world, country, elapsed_ms, deaths);
CREATE INDEX IF NOT EXISTS scores_owner_world ON scores(owner, world);
