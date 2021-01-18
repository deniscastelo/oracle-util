DECLARE

  --Options
  vTabela              VARCHAR2(4000) := UPPER(:TABLE_NAME);
  vSchema              VARCHAR2(4000) := UPPER(:SCHEMA_NAME);
  vPrimaryKey          VARCHAR2(4000) := :PRIMARY_KEY_COLUMN;
  vHistTable           BOOLEAN := TRUE;
  vDeleteTrigger       BOOLEAN := TRUE;
  vInsertUpdateTrigger BOOLEAN := TRUE;

  --Script Variables--
  vColumn      VARCHAR2(4000);
  vColumnId    VARCHAR2(4000) := vPrimaryKey;
  vPrefix      VARCHAR2(4000);
  vMaxColumnId NUMBER;

  --Check variables--
  vError            BOOLEAN := FALSE;
  vCountExistsTable NUMBER;
  vCountOneId       NUMBER;

BEGIN

  DBMS_OUTPUT.ENABLE(10000000);

  SELECT COUNT(1)
    INTO vCountExistsTable
    FROM ALL_TABLES
   WHERE TABLE_NAME = vTabela
     AND (OWNER = vSchema OR vSchema IS NULL);

  IF vCountExistsTable = 0 THEN
  
    DBMS_OUTPUT.PUT_LINE('TABELA NÃO EXISTE');
    vError := TRUE;
  
  ELSIF vCountExistsTable > 1 AND vSchema IS NULL THEN
  
    DBMS_OUTPUT.PUT_LINE('EXISTEM 2 TABELAS COM ESSE NOME, FAVOR INFORMAR O SCHEMA');
    vError := TRUE;
  
  END IF;

  IF NOT vError THEN
  
    SELECT MAX(COLUMN_ID)
      INTO vMaxColumnId
      FROM ALL_TAB_COLUMNS
     WHERE TABLE_NAME = vTabela;
  
    SELECT COUNT(1)
      INTO vCountOneId
      FROM ALL_TAB_COLUMNS
     WHERE TABLE_NAME = vTabela
       AND REGEXP_LIKE(COLUMN_NAME, '^[A-Z]+_ID$');
  
    IF vCountOneId = 1 AND vColumnId IS NULL THEN
    
      SELECT COLUMN_NAME
        INTO vColumnId
        FROM ALL_TAB_COLUMNS
       WHERE TABLE_NAME = vTabela
         AND REGEXP_LIKE(COLUMN_NAME, '^[A-Z]+_ID$');
    
    END IF;
  
    IF vHistTable THEN
    
      DBMS_OUTPUT.PUT_LINE('--------------');
      DBMS_OUTPUT.PUT_LINE('--TABLE_HIST--');
      DBMS_OUTPUT.PUT_LINE('--------------');
      DBMS_OUTPUT.PUT_LINE('');
    
      DBMS_OUTPUT.PUT_LINE('CREATE TABLE ' || vTabela || '_HIST (');
    
      FOR I IN (SELECT *
                  FROM ALL_TAB_COLUMNS
                 WHERE TABLE_NAME = vTabela
                 ORDER BY COLUMN_ID) LOOP
      
        vColumn := REGEXP_REPLACE(I.COLUMN_NAME, '([A-Z]+)(_\w+)', '\1H\2');
        vColumn := vColumn || ' ' || I.DATA_TYPE;
      
        IF I.DATA_TYPE = 'NUMBER' AND I.DATA_PRECISION IS NOT NULL THEN
        
          vColumn := vColumn || '(' || I.DATA_PRECISION;
        
          IF I.DATA_SCALE IS NOT NULL AND I.DATA_SCALE != 0 THEN
          
            vColumn := vColumn || ',' || I.DATA_SCALE;
          
          END IF;
        
          vColumn := vColumn || ')';
        
        ELSIF I.DATA_LENGTH IS NOT NULL AND I.DATA_TYPE = 'VARCHAR2' THEN
        
          vColumn := vColumn || '(' || I.DATA_LENGTH || ')';
        
        END IF;
      
        IF I.COLUMN_ID != vMaxColumnId THEN
        
          vColumn := vColumn || ',';
        
        END IF;
      
        DBMS_OUTPUT.PUT_LINE(vColumn);
      
      END LOOP;
    
      DBMS_OUTPUT.PUT_LINE(');');
    
    END IF;
  
    IF vInsertUpdateTrigger THEN
    
      DBMS_OUTPUT.PUT_LINE('');
      DBMS_OUTPUT.PUT_LINE('----------------------------');
      DBMS_OUTPUT.PUT_LINE('--TRIGGER INSERT OR UPDATE--');
      DBMS_OUTPUT.PUT_LINE('----------------------------');
      DBMS_OUTPUT.PUT_LINE('');
    
      IF vColumnId IS NOT NULL THEN
      
        DBMS_OUTPUT.PUT_LINE('--SEQUENCE');
        DBMS_OUTPUT.PUT_LINE('CREATE SEQUENCE SEQ_' || vColumnId ||
                             ' START WITH 1 INCREMENT BY 1 NOCACHE;');
        DBMS_OUTPUT.PUT_LINE('');
      
        DBMS_OUTPUT.PUT_LINE('CREATE OR REPLACE TRIGGER T_IU_' || vTabela);
        DBMS_OUTPUT.PUT_LINE('BEFORE INSERT OR UPDATE ON ' || vTabela);
        DBMS_OUTPUT.PUT_LINE('FOR EACH ROW');
        DBMS_OUTPUT.PUT_LINE('DECLARE');
        DBMS_OUTPUT.PUT_LINE('vId ' || vTabela || '.' || vColumnId ||
                             '%TYPE;');
        DBMS_OUTPUT.PUT_LINE('BEGIN');
        DBMS_OUTPUT.PUT_LINE('');
        DBMS_OUTPUT.PUT_LINE('IF INSERTING THEN');
        DBMS_OUTPUT.PUT_LINE('');
        DBMS_OUTPUT.PUT_LINE('SELECT SEQ_' || vColumnId ||
                             '.NEXTVAL INTO vId FROM DUAL;');
        DBMS_OUTPUT.PUT_LINE('');
      
        vPrefix := REGEXP_REPLACE(vColumnId, '^(\w+?)ID$', '\1');
      
        DBMS_OUTPUT.PUT_LINE(':NEW.' || vColumnId || ' := vId;');
        DBMS_OUTPUT.PUT_LINE(':NEW.' || vPrefix || 'GENTIME := SYSDATE;');
        DBMS_OUTPUT.PUT_LINE(':NEW.' || vPrefix ||
                             'GENUSER := VARIABLES.gUser;');
        DBMS_OUTPUT.PUT_LINE(':NEW.' || vPrefix || 'MODTIME := SYSDATE;');
        DBMS_OUTPUT.PUT_LINE(':NEW.' || vPrefix ||
                             'MODUSER := VARIABLES.gUser;');
        DBMS_OUTPUT.PUT_LINE(':NEW.' || vPrefix || 'CC := 1;');
      
        DBMS_OUTPUT.PUT_LINE('');
        DBMS_OUTPUT.PUT_LINE('ELSIF UPDATING THEN');
        DBMS_OUTPUT.PUT_LINE('');
      
        DBMS_OUTPUT.PUT_LINE(':NEW.' || vColumnId || ' := :OLD.' ||
                             vColumnId || ';');
        DBMS_OUTPUT.PUT_LINE(':NEW.' || vPrefix || 'GENTIME := :OLD.' ||
                             vPrefix || 'GENTIME;');
        DBMS_OUTPUT.PUT_LINE(':NEW.' || vPrefix || 'GENUSER := :OLD.' ||
                             vPrefix || 'GENUSER;');
        DBMS_OUTPUT.PUT_LINE(':NEW.' || vPrefix || 'MODTIME := SYSDATE;');
        DBMS_OUTPUT.PUT_LINE(':NEW.' || vPrefix ||
                             'MODUSER := VARIABLES.gUser;');
        DBMS_OUTPUT.PUT_LINE(':NEW.' || vPrefix || 'CC := :OLD.' ||
                             vPrefix || 'CC + 1;');
      
        DBMS_OUTPUT.PUT_LINE('');
      
        DBMS_OUTPUT.PUT_LINE('END;');
      
      ELSE
      
        DBMS_OUTPUT.PUT_LINE('NÃO FOI POSSÍVEL IDENTIFICAR O ID DA TABELA AUTOMATICAMENTE');
        DBMS_OUTPUT.PUT_LINE('FAVOR INFORMAR O MESMO MANUALMENTE PARA GERAÇÃO DA TRIGGER DE INSERT E UPDATE');
      
      END IF;
    
    END IF;
  
    IF vDeleteTrigger THEN
    
      DBMS_OUTPUT.PUT_LINE('');
      DBMS_OUTPUT.PUT_LINE('------------------');
      DBMS_OUTPUT.PUT_LINE('--TRIGGER DELETE--');
      DBMS_OUTPUT.PUT_LINE('------------------');
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
        
          vColumn := vColumn;
        
        END IF;
      
        DBMS_OUTPUT.PUT_LINE(vColumn);
      
      END LOOP;
    
      DBMS_OUTPUT.PUT_LINE(');');
      DBMS_OUTPUT.PUT_LINE('');
      DBMS_OUTPUT.PUT_LINE('END;');
    
    END IF;
  
  END IF;

END;
