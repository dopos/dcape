/*
  Tables for stored proc documenting

*/

-- -----------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS tag(
  code       TEXT PRIMARY KEY
, alias_for  TEXT
, data       TEXT
, updated_at TIMESTAMP(0) NOT NULL DEFAULT CURRENT_TIMESTAMP
);
COMMENT ON TABLE tag IS 'Config tag';

-- -----------------------------------------------------------------------------
/*
  TODO: variable per row store

CREATE TABLE IF NOT EXISTS tag_var(
  code  TEXT REFERENCES tag ON DELETE CASCADE
, var   TEXT
, sort  INTEGER NOT NULL DEFAULT 0
, value TEXT
, anno  TEXT
, CONSTRAINT tag_var_pkey PRIMARY KEY (code, var)
);
COMMENT ON TABLE tag_var IS 'Config tag variables';
*/
-- -----------------------------------------------------------------------------
