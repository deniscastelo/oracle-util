PROCEDURE P_WRITE_FILE(P_CLOB     IN CLOB,
                       P_FILENAME IN VARCHAR2,
                       P_DIR      IN VARCHAR2) IS

  vFile   UTL_FILE.FILE_TYPE;
  vBuffer VARCHAR2(32767);
  vAmount BINARY_INTEGER := 10000;
  vPos    INTEGER := 1;

BEGIN

  vFile := UTL_FILE.FOPEN(P_DIR, P_FILENAME, 'W', 32767);

  LOOP
  
    DBMS_LOB.READ(P_CLOB, vAmount, vPos, vBuffer);
    UTL_FILE.PUT(vFile, vBuffer);
    UTL_FILE.FFLUSH(vFile);
    vPos := vPos + vAmount;
  
  END LOOP;

EXCEPTION
  WHEN NO_DATA_FOUND THEN
  
    IF UTL_FILE.IS_OPEN(vFile) THEN
    
      UTL_FILE.FCLOSE(vFile);
    
    END IF;
  
END P_WRITE_FILE;