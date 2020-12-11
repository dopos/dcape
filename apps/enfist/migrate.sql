/*

    Migration from pgrpc to pomasql

  This code moves enfist data from env.tag to pers.enfist_tag
  and removes all of pgrpc code, so it will do nothing on second run

*/

DO $_$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM information_schema.schemata WHERE schema_name = 'env') THEN
      -- skip migration
      RETURN;
    END IF;

    -- code from enfist/11_schema.sql
    CREATE SCHEMA IF NOT EXISTS pers;

    -- code from enfist/20_tag_once.sql
    CREATE TABLE IF NOT EXISTS pers.enfist_tag(
      code       TEXT PRIMARY KEY
    , alias_for  TEXT REFERENCES pers.enfist_tag(code)
    , data       TEXT
    , updated_at TIMESTAMP(0) NOT NULL DEFAULT CURRENT_TIMESTAMP
    );

    -- migrate data
    INSERT INTO pers.enfist_tag SELECT * FROM env.tag;
    -- drop pgrpc code
    DROP SCHEMA env CASCADE;
    DROP SCHEMA rpc CASCADE;

END$_$;
