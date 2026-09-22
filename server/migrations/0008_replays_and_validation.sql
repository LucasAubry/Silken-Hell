CREATE TABLE run_replays(run_id TEXT PRIMARY KEY,owner TEXT NOT NULL,payload TEXT NOT NULL,created_at INTEGER NOT NULL);
CREATE TABLE workshop_validations(id TEXT PRIMARY KEY,owner TEXT NOT NULL,layout_hash TEXT NOT NULL,created_at INTEGER NOT NULL);
CREATE INDEX workshop_validation_owner ON workshop_validations(owner,created_at);
