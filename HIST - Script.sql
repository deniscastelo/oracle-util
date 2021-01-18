DECLARE

  vTabela      VARCHAR2(4000) := UPPER(:TABLE_NAME);
  vSchema      VARCHAR2(4000) := UPPER(:SCHEMA_NAME);
  vColumn      VARCHAR2(4000);
  vMaxColumnId NUMBER;

  --Check variables--
  vError            BOOLEAN := FALSE;
  vCountExistsTable NUMBER;

BEGIN

  DBMS_OUTPUT.ENABLE(10000000);

  SELECT COUNT(1)
    INTO vCountExistsTable
    FROM ALL_TABLES
   WHERE TABLE_NAME = vTabela
     AND (OWNER = vSchema OR vSchema IS NULL);

  IF vCountExistsTable = 0 THEN
  
    DBMS_OUTPUT.PUT_LINE('TABELA NÃO EXISTE');
  
  ELSIF vCountExistsTable > 1 AND vSchema IS NULL THEN
  
    DBMS_OUTPUT.PUT_LINE('EXISTEM 2 TABELAS COM ESSE NOME, FAVOR INFORMAR O SCHEMA');
  
  END IF;

  IF NOT vError THEN
  
    DBMS_OUTPUT.PUT_LINE('--------------');
    DBMS_OUTPUT.PUT_LINE('--TABLE_HIST--');
    DBMS_OUTPUT.PUT_LINE('--------------');
    DBMS_OUTPUT.PUT_LINE('');
  
    DBMS_OUTPUT.PUT_LINE('CREATE TABLE ' || vTabela || '_HIST (');
  
    SELECT MAX(COLUMN_ID)
      INTO vMaxColumnId
      FROM ALL_TAB_COLUMNS
     WHERE TABLE_NAME = vTabela;
  
    FOR I IN (SELECT *
                FROM ALL_TAB_COLUMNS
               WHERE TABLE_NAME = vTabela
               ORDER BY COLUMN_ID) LOOP
    
      vColumn := REGEXP_REPLACE(I.COLUMN_NAME, '([A-Z]+)(_\w+)', '\1H\2');
    
      IF I.DATA_TYPE = 'NUMBER' AND I.DATA_PRECISION IS NOT NULL THEN
      
        vColumn := vColumn || '(' || I.DATA_PRECISION;
      
        IF I.DATA_SCALE IS NOT NULL AND I.DATA_SCALE != 0 THEN
        
          vColumn := vColumn || ',' || I.DATA_SCALE;
        
        END IF;
      
        vColumn := vColumn || ')';
      
      ELSIF I.DATA_LENGTH IS NOT NULL THEN
      
        vColumn := vColumn || '(' || I.DATA_LENGTH || ')';
      
      END IF;
    
      IF I.COLUMN_ID != vMaxColumnId THEN
      
        vColumn := vColumn || ',';
      
      END IF;
    
      DBMS_OUTPUT.PUT_LINE(vColumn);
    
    END LOOP;
  
    DBMS_OUTPUT.PUT_LINE(');');
  
    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE('-----------');
    DBMS_OUTPUT.PUT_LINE('--TRIGGER--');
    DBMS_OUTPUT.PUT_LINE('-----------');
    DBMS_OUTPUT.PUT_LINE('');
  
    DBMS_OUTPUT.PUT_LINE('CREATE OR REPLACE TRIGGER T_D_' || vTabela);
    DBMS_OUTPUT.PUT_LINE('BEFORE DELETE ON ' || vTabela);
    DBMS_OUTPUT.PUT_LINE('FOR EACH ROW');
    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE('BEGIN');
    DBMS_OUTPUT.PUT_LINE('');
  
    DBMS_OUTPUT.PUT_LINE('INSERT INTO ' || vTabela || '_HIST (');
  
    FOR I IN (SELECT *
                FROM ALL_TAB_COLUMNS
               WHERE TABLE_NAME = vTabela
               ORDER BY COLUMN_ID) LOOP
    
      vColumn := REGEXP_REPLACE(I.COLUMN_NAME, '([A-Z]+)(_\w+)', '\1H\2');
    
      IF I.COLUMN_ID != vMaxColumnId THEN
      
        vColumn := vColumn || ',';
      
      ELSE
      
        vColumn := vColumn || ')';
      
      END IF;
    
      DBMS_OUTPUT.PUT_LINE(vColumn);
    
    END LOOP;
  
    DBMS_OUTPUT.PUT_LINE('VALUES');
    DBMS_OUTPUT.PUT_LINE('(');
  
    FOR I IN (SELECT *
                FROM ALL_TAB_COLUMNS
               WHERE TABLE_NAME = vTabela
               ORDER BY COLUMN_ID) LOOP
    
      vColumn := ':OLD.' || I.COLUMN_NAME;
    
      IF I.COLUMN_ID != vMaxColumnId THEN
      
        vColumn := vColumn || ',';
      
      ELSE
      
        vColumn := vColumn || ');';
      
      END IF;
    
      DBMS_OUTPUT.PUT_LINE(vColumn);
    
    END LOOP;
    
    DBMS_OUTPUT.PUT_LINE(''); 
    DBMS_OUTPUT.PUT_LINE('END;');
  
  END IF;

END;
