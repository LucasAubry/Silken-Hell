CREATE TABLE workshop_sessions (
 id TEXT PRIMARY KEY, map_id TEXT NOT NULL REFERENCES workshop_maps(id) ON DELETE CASCADE,
 owner TEXT NOT NULL, version INTEGER NOT NULL, deaths INTEGER NOT NULL DEFAULT 0,
 completed INTEGER NOT NULL DEFAULT 0, elapsed REAL NOT NULL DEFAULT 0,
 hotspots TEXT NOT NULL DEFAULT '{}', updated_at INTEGER NOT NULL
);
CREATE INDEX workshop_sessions_map ON workshop_sessions(map_id,version);
DELETE FROM workshop_stars WHERE EXISTS (SELECT 1 FROM workshop_maps m WHERE m.id=map_id AND m.owner=workshop_stars.owner);
