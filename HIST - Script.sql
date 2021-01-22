DECLARE

  --Parâmetros
  vTabela     VARCHAR2(4000) := UPPER(:TABLE_NAME); --Obrigatório
  vSchema     VARCHAR2(4000) := UPPER(:SCHEMA_NAME); --Opcional
  vPrimaryKey VARCHAR2(4000) := UPPER(:PRIMARY_KEY_COLUMN); --Opcional

  vHistTable           BOOLEAN := TRUE; --Gera tabela de histórico
  vDeleteTrigger       BOOLEAN := TRUE; --Gera Trigger de delete
  vInsertUpdateTrigger BOOLEAN := TRUE; --Gera Trigger de Insert / Update
  vProcessPackage      BOOLEAN := TRUE;
  vUiwPackage          BOOLEAN := TRUE;

  --Script Variables--
  vColumn           VARCHAR2(4000);
  vColumnId         VARCHAR2(4000) := vPrimaryKey;
  vPrefix           VARCHAR2(4000);
  vSequenceName     VARCHAR2(4000);
  vTableHistName    VARCHAR2(4000);
  vProcedureName    VARCHAR2(4000);
  vSchemaName       VARCHAR2(4000);
  vPackageName      VARCHAR2(4000);
  vMaxPackageNumber NUMBER;
  vMaxColumnId      NUMBER;

  --Check variables--
  vError                BOOLEAN := FALSE;
  vCountExistsTable     NUMBER;
  vCountExistsTableHist NUMBER;
  vCountExistsSequence  NUMBER;
  vCountOneId           NUMBER;

BEGIN

  DBMS_OUTPUT.ENABLE(100000000);

  vSchema := NVL(vSchema, SYS_CONTEXT('USERENV', 'CURRENT_SCHEMA'));

  SELECT COUNT(1)
    INTO vCountExistsTable
    FROM ALL_TABLES
   WHERE TABLE_NAME = vTabela
     AND (OWNER = vSchema);

  IF vCountExistsTable = 0 THEN
  
    DBMS_OUTPUT.PUT_LINE('--TABELA NÃO EXISTE');
    vError := TRUE;
  
  ELSIF vCountExistsTable > 1 AND vSchema IS NULL THEN
  
    DBMS_OUTPUT.PUT_LINE('--EXISTEM 2 TABELAS COM ESSE NOME, FAVOR INFORMAR O SCHEMA');
    vError := TRUE;
  
  END IF;

  IF NOT vError THEN
  
    SELECT MAX(COLUMN_ID)
      INTO vMaxColumnId
      FROM ALL_TAB_COLUMNS
     WHERE TABLE_NAME = vTabela
       AND (OWNER = vSchema);
  
    IF vColumnId IS NULL THEN
    
      SELECT COUNT(1)
        INTO vCountOneId
        FROM ALL_TAB_COLUMNS
       WHERE TABLE_NAME = vTabela
         AND REGEXP_LIKE(COLUMN_NAME, '^[A-Z]+_ID$')
         AND (OWNER = vSchema);
    
      IF vCountOneId = 1 THEN
      
        SELECT COLUMN_NAME
          INTO vColumnId
          FROM ALL_TAB_COLUMNS
         WHERE TABLE_NAME = vTabela
           AND REGEXP_LIKE(COLUMN_NAME, '^[A-Z]+_ID$')
           AND (OWNER = vSchema);
      
      END IF;
    
    END IF;
  
    IF vColumnId IS NOT NULL THEN
    
      vPrefix := REGEXP_REPLACE(vColumnId, '^(\w+?)ID$', '\1');
    
    END IF;
  
    IF vHistTable THEN
    
      DBMS_OUTPUT.PUT_LINE('--------------');
      DBMS_OUTPUT.PUT_LINE('--TABLE_HIST--');
      DBMS_OUTPUT.PUT_LINE('--------------');
      DBMS_OUTPUT.PUT_LINE('');
    
      vTableHistName := vTabela || '_HIST';
    
      SELECT COUNT(1)
        INTO vCountExistsTableHist
        FROM ALL_TABLES
       WHERE TABLE_NAME = vTableHistName
         AND (OWNER = vSchema);
    
      IF vCountExistsTableHist > 0 THEN
      
        DBMS_OUTPUT.PUT_LINE(RPAD('-', LENGTH(vTableHistName) + 21, '-'));
        DBMS_OUTPUT.PUT_LINE('--Tabela ' || vTableHistName ||
                             ' já existe--');
        DBMS_OUTPUT.PUT_LINE(RPAD('-', LENGTH(vTableHistName) + 21, '-'));
        DBMS_OUTPUT.PUT_LINE('');
        DBMS_OUTPUT.PUT_LINE('/*');
        DBMS_OUTPUT.PUT_LINE('');
        DBMS_OUTPUT.PUT_LINE('--DROP TABLE ' || vTableHistName || ';');
        DBMS_OUTPUT.PUT_LINE('');
      
      END IF;
    
      DBMS_OUTPUT.PUT_LINE('CREATE TABLE ' || vTableHistName || ' (');
    
      FOR I IN (SELECT *
                  FROM ALL_TAB_COLUMNS
                 WHERE TABLE_NAME = vTabela
                   AND (OWNER = vSchema)
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
    
      IF vCountExistsTableHist > 0 THEN
      
        DBMS_OUTPUT.PUT_LINE('');
        DBMS_OUTPUT.PUT_LINE('*/');
      
      END IF;
    
    END IF;
  
    IF vInsertUpdateTrigger THEN
    
      IF vColumnId IS NOT NULL THEN
      
        DBMS_OUTPUT.PUT_LINE('');
        DBMS_OUTPUT.PUT_LINE('------------');
        DBMS_OUTPUT.PUT_LINE('--SEQUENCE--');
        DBMS_OUTPUT.PUT_LINE('------------');
        DBMS_OUTPUT.PUT_LINE('');
      
        vSequenceName := 'SEQ_' || vColumnId;
      
        SELECT COUNT(1)
          INTO vCountExistsSequence
          FROM ALL_SEQUENCES
         WHERE SEQUENCE_NAME = vSequenceName
           AND (SEQUENCE_OWNER = vSchema);
      
        IF vCountExistsSequence > 0 THEN
        
          DBMS_OUTPUT.PUT_LINE(RPAD('-', LENGTH(vSequenceName) + 23, '-'));
          DBMS_OUTPUT.PUT_LINE('--Sequence ' || vSequenceName ||
                               ' já existe--');
          DBMS_OUTPUT.PUT_LINE(RPAD('-', LENGTH(vSequenceName) + 23, '-'));
          DBMS_OUTPUT.PUT_LINE('');
          DBMS_OUTPUT.PUT_LINE('/*');
          DBMS_OUTPUT.PUT_LINE('');
          DBMS_OUTPUT.PUT_LINE('--DROP SEQUENCE ' || vSequenceName || ';');
          DBMS_OUTPUT.PUT_LINE('');
        
        END IF;
      
        DBMS_OUTPUT.PUT_LINE('CREATE SEQUENCE ' || vSequenceName ||
                             ' START WITH 1 INCREMENT BY 1 NOCACHE;');
        DBMS_OUTPUT.PUT_LINE('');
      
        IF vCountExistsSequence > 0 THEN
        
          DBMS_OUTPUT.PUT_LINE('*/');
        
        END IF;
      
        DBMS_OUTPUT.PUT_LINE('');
        DBMS_OUTPUT.PUT_LINE('----------------------------');
        DBMS_OUTPUT.PUT_LINE('--TRIGGER INSERT OR UPDATE--');
        DBMS_OUTPUT.PUT_LINE('----------------------------');
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
      
        DBMS_OUTPUT.PUT_LINE('--NÃO FOI POSSÍVEL IDENTIFICAR O ID DA TABELA AUTOMATICAMENTE');
        DBMS_OUTPUT.PUT_LINE('--FAVOR INFORMAR O MESMO MANUALMENTE PARA GERAÇÃO DA TRIGGER DE INSERT E UPDATE');
      
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
                   AND (OWNER = vSchema)
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
                   AND (OWNER = vSchema)
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
  
    -------------------------
    --PACKAGE WMS/YARD/HOST--
    -------------------------
  
    IF vProcessPackage THEN
    
      vSchemaName := REPLACE(vSchema, 'I9_', '');
    
      SELECT MAX(TO_NUMBER(REGEXP_REPLACE(OBJECT_NAME,
                                          '^PCK_UIW_(\d{2})_\w+$',
                                          '\1'))) + 1
        INTO vMaxPackageNumber
        FROM ALL_PROCEDURES
       WHERE OWNER = vSchema
         AND OBJECT_NAME LIKE 'PCK_UIW%';
    
      vPackageName := 'PCK_' || vSchemaName || '_' ||
                      LPAD(vMaxPackageNumber, 2, '0') || '_' || vTabela;
    
      SELECT MAX(COLUMN_ID)
        INTO vMaxColumnId
        FROM ALL_TAB_COLUMNS
       WHERE TABLE_NAME = vTabela
         AND COLUMN_NAME NOT IN (vPrefix || 'GENTIME',
                                 vPrefix || 'MODTIME',
                                 vPrefix || 'MODUSER',
                                 vPrefix || 'GENUSER',
                                 vPrefix || 'CC',
                                 vColumnId)
         AND (OWNER = vSchema);
    
      --------        
      --SPEC--
      --------
    
      DBMS_OUTPUT.PUT_LINE(''); 
      DBMS_OUTPUT.PUT_LINE('CREATE OR REPLACE PACKAGE ' || vPackageName ||
                           ' IS');
    
      DBMS_OUTPUT.PUT_LINE('');
    
      vProcedureName := 'P_INS_' || vTabela;
    
      -----------------------------------
      --PROCEDURE DE INSERT COM RETORNO--
      -----------------------------------
    
      DBMS_OUTPUT.PUT_LINE('PROCEDURE ' || vProcedureName || '(');
    
      FOR I IN (SELECT *
                  FROM ALL_TAB_COLUMNS
                 WHERE TABLE_NAME = vTabela
                   AND COLUMN_NAME NOT IN (vPrefix || 'GENTIME',
                                           vPrefix || 'MODTIME',
                                           vPrefix || 'MODUSER',
                                           vPrefix || 'GENUSER',
                                           vPrefix || 'CC',
                                           vColumnId)
                   AND (OWNER = vSchema)
                 ORDER BY COLUMN_ID) LOOP
      
        vColumn := 'P_' || I.COLUMN_NAME || ' IN ' || vTabela || '.' ||
                   I.COLUMN_NAME || '%TYPE,';
      
        DBMS_OUTPUT.PUT_LINE(vColumn);
      
      END LOOP;
    
      DBMS_OUTPUT.PUT_LINE('P_' || vColumnId || ' OUT ' || vTabela || '.' ||
                           vColumnId || '%TYPE);');
    
      --------------------
      --PROCEDURE INSERT--
      --------------------
    
      DBMS_OUTPUT.PUT_LINE('');
      DBMS_OUTPUT.PUT_LINE('PROCEDURE ' || vProcedureName || '(');
    
      FOR I IN (SELECT *
                  FROM ALL_TAB_COLUMNS
                 WHERE TABLE_NAME = vTabela
                   AND COLUMN_NAME NOT IN (vPrefix || 'GENTIME',
                                           vPrefix || 'MODTIME',
                                           vPrefix || 'MODUSER',
                                           vPrefix || 'GENUSER',
                                           vPrefix || 'CC',
                                           vColumnId)
                   AND (OWNER = vSchema)
                 ORDER BY COLUMN_ID) LOOP
      
        vColumn := 'P_' || I.COLUMN_NAME || ' IN ' || vTabela || '.' ||
                   I.COLUMN_NAME || '%TYPE';
      
        IF vMaxColumnId != I.COLUMN_ID THEN
        
          vColumn := vColumn || ',';
        
        ELSE
        
          vColumn := vColumn || ');';
        
        END IF;
      
        DBMS_OUTPUT.PUT_LINE(vColumn);
      
      END LOOP;
    
      --------------------
      --PROCEDURE UPDATE--
      --------------------
    
      vProcedureName := 'P_UPD_' || vTabela;
    
      DBMS_OUTPUT.PUT_LINE('');
      DBMS_OUTPUT.PUT_LINE('PROCEDURE ' || vProcedureName || '(');
    
      DBMS_OUTPUT.PUT_LINE('P_' || vColumnId || ' IN ' || vTabela || '.' ||
                           vColumnId || '%TYPE,');
    
      FOR I IN (SELECT *
                  FROM ALL_TAB_COLUMNS
                 WHERE TABLE_NAME = vTabela
                   AND COLUMN_NAME NOT IN (vPrefix || 'GENTIME',
                                           vPrefix || 'MODTIME',
                                           vPrefix || 'MODUSER',
                                           vPrefix || 'GENUSER',
                                           vPrefix || 'CC',
                                           vColumnId)
                   AND (OWNER = vSchema)
                 ORDER BY COLUMN_ID) LOOP
      
        vColumn := 'P_' || I.COLUMN_NAME || ' IN ' || vTabela || '.' ||
                   I.COLUMN_NAME || '%TYPE';
      
        IF vMaxColumnId != I.COLUMN_ID THEN
        
          vColumn := vColumn || ',';
        
        ELSE
        
          vColumn := vColumn || ');';
        
        END IF;
      
        DBMS_OUTPUT.PUT_LINE(vColumn);
      
      END LOOP;
    
      --------------------
      --PROCEDURE DELETE--
      --------------------
    
      vProcedureName := 'P_DEL_' || vTabela;
    
      DBMS_OUTPUT.PUT_LINE('');
      DBMS_OUTPUT.PUT_LINE('PROCEDURE ' || vProcedureName || '(');
    
      DBMS_OUTPUT.PUT_LINE('P_' || vColumnId || ' IN ' || vTabela || '.' ||
                           vColumnId || '%TYPE);');
    
      --------------------
      --PROCEDURE TOGGLE--
      --------------------
    
      vProcedureName := 'P_TOGGLE_' || vTabela;
    
      DBMS_OUTPUT.PUT_LINE('');
      DBMS_OUTPUT.PUT_LINE('PROCEDURE ' || vProcedureName || '(');
    
      DBMS_OUTPUT.PUT_LINE('P_' || vColumnId || ' IN ' || vTabela || '.' ||
                           vColumnId || '%TYPE,');
      DBMS_OUTPUT.PUT_LINE('P_' || vColumnId || ' IN ' || vTabela || '.' ||
                           vPrefix || 'STATUS' || '%TYPE);');
    
      ------------
      --END SPEC--
      ------------
    
      DBMS_OUTPUT.PUT_LINE('');
      DBMS_OUTPUT.PUT_LINE('END ' || vPackageName || ';');
      DBMS_OUTPUT.PUT_LINE('/');
    
      --------        
      --BODY--
      --------
    
      DBMS_OUTPUT.PUT_LINE('');
      DBMS_OUTPUT.PUT_LINE('CREATE OR REPLACE PACKAGE BODY ' ||
                           vPackageName || ' IS');
    
      DBMS_OUTPUT.PUT_LINE('');
    
      -----------------------------------
      --PROCEDURE DE INSERT COM RETORNO--
      -----------------------------------
    
      vProcedureName := 'P_INS_' || vTabela;
    
      DBMS_OUTPUT.PUT_LINE(RPAD('-', LENGTH(vProcedureName) + 4, '-'));
      DBMS_OUTPUT.PUT_LINE('--' || vProcedureName || '--');
      DBMS_OUTPUT.PUT_LINE(RPAD('-', LENGTH(vProcedureName) + 4, '-'));
      DBMS_OUTPUT.PUT_LINE('');
    
      DBMS_OUTPUT.PUT_LINE('-- Author  : ');
      DBMS_OUTPUT.PUT_LINE('-- Created : ' ||
                           TO_CHAR(SYSDATE, 'DD/MM/YYYY'));
      DBMS_OUTPUT.PUT_LINE('-- Purpose : ');
      DBMS_OUTPUT.PUT_LINE('');
    
      DBMS_OUTPUT.PUT_LINE('PROCEDURE ' || vProcedureName || '(');
    
      FOR I IN (SELECT *
                  FROM ALL_TAB_COLUMNS
                 WHERE TABLE_NAME = vTabela
                   AND COLUMN_NAME NOT IN (vPrefix || 'GENTIME',
                                           vPrefix || 'MODTIME',
                                           vPrefix || 'MODUSER',
                                           vPrefix || 'GENUSER',
                                           vPrefix || 'CC',
                                           vColumnId)
                   AND (OWNER = vSchema)
                 ORDER BY COLUMN_ID) LOOP
      
        DBMS_OUTPUT.PUT_LINE('P_' || I.COLUMN_NAME || ' IN ' || vTabela || '.' ||
                             I.COLUMN_NAME || '%TYPE,');
      
      END LOOP;
    
      DBMS_OUTPUT.PUT_LINE('P_' || vColumnId || ' OUT ' || vTabela || '.' ||
                           vColumnId || '%TYPE);');
    
      DBMS_OUTPUT.PUT_LINE('');
      DBMS_OUTPUT.PUT_LINE('BEGIN');
      DBMS_OUTPUT.PUT_LINE('');
      DBMS_OUTPUT.PUT_LINE('INSERT INTO ' || vTabela || '(');
    
      FOR I IN (SELECT *
                  FROM ALL_TAB_COLUMNS
                 WHERE TABLE_NAME = vTabela
                   AND COLUMN_NAME NOT IN (vPrefix || 'GENTIME',
                                           vPrefix || 'MODTIME',
                                           vPrefix || 'MODUSER',
                                           vPrefix || 'GENUSER',
                                           vPrefix || 'CC',
                                           vColumnId)
                   AND (OWNER = vSchema)
                 ORDER BY COLUMN_ID) LOOP
      
        vColumn := I.COLUMN_NAME;
      
        IF vMaxColumnId != I.COLUMN_ID THEN
        
          vColumn := vColumn || ',';
        
        ELSE
        
          vColumn := vColumn || ')';
        
        END IF;
      
        DBMS_OUTPUT.PUT_LINE(vColumn);
      
      END LOOP;
    
      DBMS_OUTPUT.PUT_LINE('VALUES (');
    
      FOR I IN (SELECT *
                  FROM ALL_TAB_COLUMNS
                 WHERE TABLE_NAME = vTabela
                   AND COLUMN_NAME NOT IN (vPrefix || 'GENTIME',
                                           vPrefix || 'MODTIME',
                                           vPrefix || 'MODUSER',
                                           vPrefix || 'GENUSER',
                                           vPrefix || 'CC',
                                           vColumnId)
                   AND (OWNER = vSchema)
                 ORDER BY COLUMN_ID) LOOP
      
        vColumn := 'P_' || I.COLUMN_NAME;
      
        IF vMaxColumnId != I.COLUMN_ID THEN
        
          vColumn := vColumn || ',';
        
        ELSE
        
          vColumn := vColumn || ')';
        
        END IF;
      
        DBMS_OUTPUT.PUT_LINE(vColumn);
      
      END LOOP;
    
      DBMS_OUTPUT.PUT_LINE('RETURNING ' || vColumnId || ' INTO P_' ||
                           vColumnId || ';');
    
      DBMS_OUTPUT.PUT_LINE('');
      DBMS_OUTPUT.PUT_LINE('END ' || vProcedureName || ';');
    
      --------------------
      --PROCEDURE INSERT--
      --------------------
    
      DBMS_OUTPUT.PUT_LINE('');
      DBMS_OUTPUT.PUT_LINE(RPAD('-', LENGTH(vProcedureName) + 4, '-'));
      DBMS_OUTPUT.PUT_LINE('--' || vProcedureName || '--');
      DBMS_OUTPUT.PUT_LINE(RPAD('-', LENGTH(vProcedureName) + 4, '-'));
      DBMS_OUTPUT.PUT_LINE('');
    
      DBMS_OUTPUT.PUT_LINE('-- Author  : ');
      DBMS_OUTPUT.PUT_LINE('-- Created : ' ||
                           TO_CHAR(SYSDATE, 'DD/MM/YYYY'));
      DBMS_OUTPUT.PUT_LINE('-- Purpose : ');
      DBMS_OUTPUT.PUT_LINE('');
    
      DBMS_OUTPUT.PUT_LINE('PROCEDURE ' || vProcedureName || '(');
    
      FOR I IN (SELECT *
                  FROM ALL_TAB_COLUMNS
                 WHERE TABLE_NAME = vTabela
                   AND COLUMN_NAME NOT IN (vPrefix || 'GENTIME',
                                           vPrefix || 'MODTIME',
                                           vPrefix || 'MODUSER',
                                           vPrefix || 'GENUSER',
                                           vPrefix || 'CC',
                                           vColumnId)
                   AND (OWNER = vSchema)
                 ORDER BY COLUMN_ID) LOOP
      
        vColumn := 'P_' || I.COLUMN_NAME || ' IN ' || vTabela || '.' ||
                   I.COLUMN_NAME || '%TYPE';
      
        IF vMaxColumnId != I.COLUMN_ID THEN
        
          vColumn := vColumn || ',';
        
        ELSE
        
          vColumn := vColumn || ') IS';
        
        END IF;
      
        DBMS_OUTPUT.PUT_LINE(vColumn);
      
      END LOOP;
    
      DBMS_OUTPUT.PUT_LINE('');
      DBMS_OUTPUT.PUT_LINE('BEGIN');
      DBMS_OUTPUT.PUT_LINE('');
      DBMS_OUTPUT.PUT_LINE('INSERT INTO ' || vTabela || '(');
    
      FOR I IN (SELECT *
                  FROM ALL_TAB_COLUMNS
                 WHERE TABLE_NAME = vTabela
                   AND COLUMN_NAME NOT IN (vPrefix || 'GENTIME',
                                           vPrefix || 'MODTIME',
                                           vPrefix || 'MODUSER',
                                           vPrefix || 'GENUSER',
                                           vPrefix || 'CC',
                                           vColumnId)
                   AND (OWNER = vSchema)
                 ORDER BY COLUMN_ID) LOOP
      
        vColumn := I.COLUMN_NAME;
      
        IF vMaxColumnId != I.COLUMN_ID THEN
        
          vColumn := vColumn || ',';
        
        ELSE
        
          vColumn := vColumn || ')';
        
        END IF;
      
        DBMS_OUTPUT.PUT_LINE(vColumn);
      
      END LOOP;
    
      DBMS_OUTPUT.PUT_LINE('VALUES (');
    
      FOR I IN (SELECT *
                  FROM ALL_TAB_COLUMNS
                 WHERE TABLE_NAME = vTabela
                   AND COLUMN_NAME NOT IN (vPrefix || 'GENTIME',
                                           vPrefix || 'MODTIME',
                                           vPrefix || 'MODUSER',
                                           vPrefix || 'GENUSER',
                                           vPrefix || 'CC',
                                           vColumnId)
                   AND (OWNER = vSchema)
                 ORDER BY COLUMN_ID) LOOP
      
        vColumn := 'P_' || I.COLUMN_NAME;
      
        IF vMaxColumnId != I.COLUMN_ID THEN
        
          vColumn := vColumn || ',';
        
        ELSE
        
          vColumn := vColumn || ');';
        
        END IF;
      
        DBMS_OUTPUT.PUT_LINE(vColumn);
      
      END LOOP;
    
      DBMS_OUTPUT.PUT_LINE('');
      DBMS_OUTPUT.PUT_LINE('END ' || vProcedureName || ';');
    
      --------------------
      --PROCEDURE UPDATE--
      --------------------
    
      vProcedureName := 'P_UPD_' || vTabela;
    
      DBMS_OUTPUT.PUT_LINE('');
      DBMS_OUTPUT.PUT_LINE(RPAD('-', LENGTH(vProcedureName) + 4, '-'));
      DBMS_OUTPUT.PUT_LINE('--' || vProcedureName || '--');
      DBMS_OUTPUT.PUT_LINE(RPAD('-', LENGTH(vProcedureName) + 4, '-'));
      DBMS_OUTPUT.PUT_LINE('');
    
      DBMS_OUTPUT.PUT_LINE('-- Author  : ');
      DBMS_OUTPUT.PUT_LINE('-- Created : ' ||
                           TO_CHAR(SYSDATE, 'DD/MM/YYYY'));
      DBMS_OUTPUT.PUT_LINE('-- Purpose : ');
      DBMS_OUTPUT.PUT_LINE('');
    
      DBMS_OUTPUT.PUT_LINE('PROCEDURE ' || vProcedureName || '(');
    
      DBMS_OUTPUT.PUT_LINE('P_' || vColumnId || ' IN ' || vTabela || '.' ||
                           vColumnId || '%TYPE,');
    
      FOR I IN (SELECT *
                  FROM ALL_TAB_COLUMNS
                 WHERE TABLE_NAME = vTabela
                   AND COLUMN_NAME NOT IN (vPrefix || 'GENTIME',
                                           vPrefix || 'MODTIME',
                                           vPrefix || 'MODUSER',
                                           vPrefix || 'GENUSER',
                                           vPrefix || 'CC',
                                           vColumnId)
                   AND (OWNER = vSchema)
                 ORDER BY COLUMN_ID) LOOP
      
        vColumn := 'P_' || I.COLUMN_NAME || ' IN ' || vTabela || '.' ||
                   I.COLUMN_NAME || '%TYPE';
      
        IF vMaxColumnId != I.COLUMN_ID THEN
        
          vColumn := vColumn || ',';
        
        ELSE
        
          vColumn := vColumn || ') IS';
        
        END IF;
      
        DBMS_OUTPUT.PUT_LINE(vColumn);
      
      END LOOP;
    
      DBMS_OUTPUT.PUT_LINE('');
      DBMS_OUTPUT.PUT_LINE('BEGIN');
      DBMS_OUTPUT.PUT_LINE('');
      DBMS_OUTPUT.PUT_LINE('UPDATE ' || vTabela || ' SET');
    
      FOR I IN (SELECT *
                  FROM ALL_TAB_COLUMNS
                 WHERE TABLE_NAME = vTabela
                   AND COLUMN_NAME NOT IN (vPrefix || 'GENTIME',
                                           vPrefix || 'MODTIME',
                                           vPrefix || 'MODUSER',
                                           vPrefix || 'GENUSER',
                                           vPrefix || 'CC',
                                           vColumnId)
                   AND (OWNER = vSchema)
                 ORDER BY COLUMN_ID) LOOP
      
        vColumn := I.COLUMN_NAME || ' = NVL(P_' || I.COLUMN_NAME || ',' ||
                   I.COLUMN_NAME || ')';
      
        IF vMaxColumnId != I.COLUMN_ID THEN
        
          vColumn := vColumn || ',';
        
        END IF;
        
        DBMS_OUTPUT.PUT_LINE(vColumn); 
      
      END LOOP;
    
      DBMS_OUTPUT.PUT_LINE('WHERE ' || vColumnId || ' = P_' || vColumnId || ';');
    
      DBMS_OUTPUT.PUT_LINE('');
      DBMS_OUTPUT.PUT_LINE('END ' || vProcedureName || ';');
    
      ------------
      --END BODY--
      ------------
    
      DBMS_OUTPUT.PUT_LINE('');
      DBMS_OUTPUT.PUT_LINE('END ' || vPackageName || ';');
      DBMS_OUTPUT.PUT_LINE('/');
    
    END IF;
  
  END IF;

END;
