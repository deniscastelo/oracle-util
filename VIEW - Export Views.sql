DECLARE

  vResult CLOB := NULL;

BEGIN

  DBMS_OUTPUT.ENABLE(10000000);

  FOR I IN (SELECT DBMS_METADATA.GET_DDL('VIEW', VIEW_NAME) DDL_VIEW,
                   VIEW_NAME
              FROM ALL_VIEWS
             WHERE VIEW_NAME IN
                   (SELECT OBJECT_NAME
                      FROM DBA_OBJECTS a
                     WHERE OWNER = SYS_CONTEXT('USERENV', 'CURRENT_SCHEMA')
                       AND OBJECT_TYPE = 'VIEW'
                       AND TRUNC(LAST_DDL_TIME) >=
                           TRUNC(TO_DATE('01/03/2020', 'DD/MM/YYYY')))) LOOP
  
    vResult := I.DDL_VIEW || ';' || CHR(13);
  
    WHILE vResult LIKE '%' || CHR(13) || CHR(13) || '%' OR
          vResult LIKE '%' || CHR(10) || CHR(10) || '%' LOOP
    
      vResult := REPLACE(vResult, CHR(13) || CHR(13), CHR(13));
      vResult := REPLACE(vResult, CHR(10) || CHR(10), CHR(10));
    
    END LOOP;
  
    DBMS_OUTPUT.PUT_LINE(vResult);
  
    DBMS_OUTPUT.PUT_LINE('-------' || CHR(13));
  
  END LOOP;

END;
