FUNCTION F_CHECK_CNPJ(ICNPJ IN VARCHAR2) RETURN BOOLEAN;

FUNCTION F_CHECK_CNPJ(ICNPJ IN VARCHAR2) RETURN BOOLEAN IS
  
    CNPJ   VARCHAR2(20);
    CNPJ1  VARCHAR2(20);
    SOMA   NUMBER := 0;
    RESTO  NUMBER := 0;
    C      VARCHAR2(20);
    DIGITO NUMBER;
  
  BEGIN
    IF ICNPJ IS NULL THEN
      RETURN FALSE;
    END IF;
  
    --REMOVE MÁSCARA CASO POSSUA
    SELECT REGEXP_REPLACE(ICNPJ, '/|-|\.| ', '') INTO CNPJ FROM DUAL;
  
    IF LENGTH(CNPJ) != 14 THEN
      RETURN FALSE;
    END IF;
  
    IF IS_NUMBER(CNPJ) = 0 THEN
      RETURN FALSE;
    END IF;
  
    --DETERMINA O 13º DÍGITO
    SOMA := TO_NUMBER(SUBSTR(CNPJ, 1, 1)) * 5 +
            TO_NUMBER(SUBSTR(CNPJ, 2, 1)) * 4 +
            TO_NUMBER(SUBSTR(CNPJ, 3, 1)) * 3 +
            TO_NUMBER(SUBSTR(CNPJ, 4, 1)) * 2 +
            TO_NUMBER(SUBSTR(CNPJ, 5, 1)) * 9 +
            TO_NUMBER(SUBSTR(CNPJ, 6, 1)) * 8 +
            TO_NUMBER(SUBSTR(CNPJ, 7, 1)) * 7 +
            TO_NUMBER(SUBSTR(CNPJ, 8, 1)) * 6 +
            TO_NUMBER(SUBSTR(CNPJ, 9, 1)) * 5 +
            TO_NUMBER(SUBSTR(CNPJ, 10, 1)) * 4 +
            TO_NUMBER(SUBSTR(CNPJ, 11, 1)) * 3 +
            TO_NUMBER(SUBSTR(CNPJ, 12, 1)) * 2;
  
    RESTO := MOD(SOMA, 11);
    C     := SUBSTR(CNPJ, 1, 12);
  
    IF RESTO < 2 THEN
      C := C || '0';
    ELSE
      DIGITO := 11 - RESTO;
      C      := C || TO_CHAR(DIGITO);
    END IF;
    CNPJ1 := C;
  
    --DETERMINA O 14º DÍGITO
    SOMA := TO_NUMBER(SUBSTR(CNPJ, 1, 1)) * 6 +
            TO_NUMBER(SUBSTR(CNPJ, 2, 1)) * 5 +
            TO_NUMBER(SUBSTR(CNPJ, 3, 1)) * 4 +
            TO_NUMBER(SUBSTR(CNPJ, 4, 1)) * 3 +
            TO_NUMBER(SUBSTR(CNPJ, 5, 1)) * 2 +
            TO_NUMBER(SUBSTR(CNPJ, 6, 1)) * 9 +
            TO_NUMBER(SUBSTR(CNPJ, 7, 1)) * 8 +
            TO_NUMBER(SUBSTR(CNPJ, 8, 1)) * 7 +
            TO_NUMBER(SUBSTR(CNPJ, 9, 1)) * 6 +
            TO_NUMBER(SUBSTR(CNPJ, 10, 1)) * 5 +
            TO_NUMBER(SUBSTR(CNPJ, 11, 1)) * 4 +
            TO_NUMBER(SUBSTR(CNPJ, 12, 1)) * 3 +
            TO_NUMBER(SUBSTR(CNPJ, 13, 1)) * 2;
  
    RESTO := MOD(SOMA, 11);
    C     := SUBSTR(CNPJ1, 1, 13);
  
    IF RESTO < 2 THEN
    
      C := C || '0';
    
    ELSE
    
      DIGITO := 11 - RESTO;
      C      := C || TO_CHAR(DIGITO);
    
    END IF;
  
    CNPJ1 := C;
  
    IF CNPJ = CNPJ1 THEN
    
      RETURN TRUE;
    
    ELSE
    
      RETURN FALSE;
    
    END IF;
  
  END F_CHECK_CNPJ;