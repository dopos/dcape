
SET vars.domain TO :'ACME_DOMAIN';
SET vars.ns TO :'ACME_NS';
SET vars.admin TO :'NS_ADMIN';

DO $_$
DECLARE
  v_domain    text := current_setting('vars.domain'); -- domain name
  v_ns        text := current_setting('vars.ns');     -- master DNS host
  v_ns_admin  text := current_setting('vars.admin');  -- master DNS admin email
  v_key       text := '00';                           -- zone serial suffix

  v_domain_id integer; -- internal domain id
  v_stamp     text;    -- zone timestamp
  v_soa       text;    -- zone SOA

BEGIN

  IF v_domain = '' THEN
    RAISE NOTICE 'ACME_DOMAIN is not set. Skipping acme zone setup';
    RETURN;
  END IF;

  RAISE NOTICE 'Setup acme zone % for nameserver %',v_domain,v_ns;

  SELECT INTO v_domain_id id FROM domains WHERE name = v_domain;
  IF FOUND THEN
    -- no any changes needed after creation
    RAISE NOTICE 'Zone already exists. Skipping';
    RETURN;
  END IF;

  INSERT INTO domains (name, type) VALUES
    (v_domain, 'NATIVE')
  RETURNING id INTO v_domain_id
  ;

  INSERT INTO domainmetadata(domain_id, kind, content) VALUES
    (v_domain_id, 'SOA-EDIT-API', 'INCREASE')
  ;

  v_stamp := to_char(current_timestamp, 'YYYYMMDD') || v_key;
  v_soa := concat_ws(' ', v_ns, v_ns_admin, v_stamp, '10800 3600 604800 1800');

  INSERT INTO records (domain_id, name, ttl, type, prio, content) VALUES 
    (v_domain_id, v_domain, 60,  'SOA', 0, v_soa)
  , (v_domain_id, v_domain, 1800, 'NS', 0, v_ns)
  ;
END;
$_$;
