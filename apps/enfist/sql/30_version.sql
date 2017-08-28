/*
  Check lib version
  Raise exception if version in db larger than code version

*/

DO $$
  BEGIN
    IF EXISTS(SELECT 1 FROM pg_proc p JOIN pg_namespace n on n.oid = p.pronamespace WHERE n.nspname = 'env' AND p.proname = 'version') THEN
      IF env.version() > 1.0 THEN
        RAISE EXCEPTION 'Newest lib version (%) loaded already', env.version();
      END IF;
    END IF;
  END;
$$;
-- -----------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION version() RETURNS DECIMAL IMMUTABLE LANGUAGE 'sql' AS
$_$
  SELECT 1.0;
$_$;
