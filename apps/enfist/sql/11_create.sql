/*

  Create database schema

*/
-- -----------------------------------------------------------------------------

CREATE SCHEMA IF NOT EXISTS env;
COMMENT ON SCHEMA env IS 'env file storage';

SET SEARCH_PATH = 'env', 'public';
-- -----------------------------------------------------------------------------
