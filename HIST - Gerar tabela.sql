SELECT 'CREATE TABLE ' || '&TABLE_NAME' || '_HIST (' SCRIPT
  FROM DUAL
UNION ALL
SELECT SCRIPT
  FROM (SELECT SUBSTR(COLUMN_NAME, 1, 3) || 'H' ||
               SUBSTR(COLUMN_NAME, 4, 90) || ' ' || data_type || CASE
                 WHEN DATA_LENGTH = '22' AND
                      (DATA_SCALE IS NULL OR DATA_SCALE = 0) AND
                      data_type = 'NUMBER' THEN
                  NULL
                 WHEN DATA_TYPE = 'CLOB' THEN NULL
                 WHEN DATA_TYPE = 'DATE' THEN
                  NULL
                 WHEN DATA_LENGTH IS NOT NULL THEN
                  '(' || DATA_LENGTH || CASE
                    WHEN DATA_SCALE IS NOT NULL THEN
                     ',' || DATA_SCALE
                    ELSE
                     NULL
                  END || ')'
                 ELSE
                  NULL
               END || ' ' || CASE
                 WHEN nullable = 'Y' THEN
                  'NOT NULL'
               END || CASE
                 WHEN COLUMN_ID =
                      (SELECT MAX(COLUMN_ID)
                         FROM ALL_TAB_COLUMNS
                        WHERE OWNER = '&SCHEMA'
                          AND TABLE_NAME = '&TABLE_NAME') THEN
                  NULL
                 ELSE
                  ','
               END SCRIPT
          FROM ALL_TAB_COLUMNS
         WHERE OWNER = '&SCHEMA'
           AND TABLE_NAME = '&TABLE_NAME'
         ORDER BY TABLE_NAME ASC, COLUMN_ID ASC)
UNION ALL
SELECT ');'
  FROM DUAL;