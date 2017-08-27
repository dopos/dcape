SELECT env.tag_set('test', E'#anno1\nvar1=val1\n#anno2\nvar2="val 2"');

SELECT env.tag_vars('test');

SELECT code, alias_for, data, (updated_at IS NOT NULL) AS is_logged FROM env.tag('test');

SELECT env.tag_del('test');

-- Returns FALSE = tag not found
SELECT env.tag_del('test');

SELECT * FROM rpc.index() WHERE code LIKE 'tag%' ORDER BY code;