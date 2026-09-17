CREATE TABLE IF NOT EXISTS workshop_maps (
 id TEXT PRIMARY KEY, owner TEXT NOT NULL, title TEXT NOT NULL, author TEXT NOT NULL,
 world INTEGER NOT NULL, layout TEXT NOT NULL, created_at INTEGER NOT NULL, updated_at INTEGER NOT NULL
);
CREATE INDEX IF NOT EXISTS workshop_owner ON workshop_maps(owner, created_at);
CREATE TABLE IF NOT EXISTS workshop_stars (
 map_id TEXT NOT NULL REFERENCES workshop_maps(id) ON DELETE CASCADE,
 owner TEXT NOT NULL, created_at INTEGER NOT NULL,
 PRIMARY KEY(map_id, owner)
);
