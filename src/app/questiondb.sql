CREATE TABLE questions (
	template_id TEXT PRIMARY KEY,
	topic TEXT NOT NULL,
	difficulty_tier TEXT NOT NULL,
    stem TEXT NOT NULL,
    authoring_notes TEXT,
    is_modeling INTEGER NOT NULL
);

CREATE TABLE guards (
    template_id TEXT NOT NULL REFERENCES questions (template_id),
    ordinal INTEGER NOT NULL,
    expression TEXT NOT NULL,
    PRIMARY KEY (template_id, ordinal)
);

CREATE TABLE distractors (
    template_id TEXT NOT NULL REFERENCES questions (template_id),
    ordinal INTEGER NOT NULL,
    expression TEXT NOT NULL,
    trap TEXT NOT NULL,
    PRIMARY KEY (template_id, ordinal)
);

CREATE TABLE difficulty_levers (
    template_id TEXT NOT NULL REFERENCES questions (template_id),
    lever_key TEXT NOT NULL,
    lever TEXT NOT NULL
);

CREATE TABLE parameters (
    template_id TEXT NOT NULL REFERENCES questions (template_id),
    param_name TEXT NOT NULL,
    param_type TEXT NOT NULL,
    lo INTEGER NOT NULL,
    hi INTEGER NOT NULL
);

CREATE TABLE derived (
    template_id TEXT NOT NULL REFERENCES questions (template_id),
    ordinal INTEGER NOT NULL,
    derived_name TEXT NOT NULL,
    expression TEXT NOT NULL,
    PRIMARY KEY (template_id, ordinal)
);

CREATE TABLE cosmetic_slot_entries (
    template_id TEXT NOT NULL,
    slot_key TEXT NOT NULL,
    ordinal INTEGER NOT NULL,
    slot_entry TEXT NOT NULL,
    FOREIGN KEY (template_id) REFERENCES questions (template_id),
    PRIMARY KEY (template_id, slot_key, ordinal)
);