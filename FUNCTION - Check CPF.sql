FUNCTION F_CHECK_CPF(ICPF IN VARCHAR2) RETURN BOOLEAN;

FUNCTION F_CHECK_CPF(ICPF IN VARCHAR2) RETURN BOOLEAN IS
  
    CPF    VARCHAR2(20);
    CPF1   VARCHAR2(20);
    SOMA   NUMBER := 0;
    RESTO  NUMBER := 0;
    C      VARCHAR2(20);
    DIGITO NUMBER;
  
  BEGIN
    IF ICPF IS NULL THEN
      RETURN FALSE;
    END IF;
  
    --REMOVE MÁSCARA CASO TENHA
    SELECT REGEXP_REPLACE(ICPF, '/|-|\.| ', '') INTO CPF FROM DUAL;
  
    IF LENGTH(CPF) != 11 THEN
      RETURN FALSE;
    END IF;
  
    IF IS_NUMBER(CPF) = 0 THEN
      RETURN FALSE;
    END IF;
  
    --DETERMINA O 10º DÍGITO
    SOMA := TO_NUMBER(SUBSTR(CPF, 1, 1)) * 10 +
            TO_NUMBER(SUBSTR(CPF, 2, 1)) * 9 +
            TO_NUMBER(SUBSTR(CPF, 3, 1)) * 8 +
            TO_NUMBER(SUBSTR(CPF, 4, 1)) * 7 +
            TO_NUMBER(SUBSTR(CPF, 5, 1)) * 6 +
            TO_NUMBER(SUBSTR(CPF, 6, 1)) * 5 +
            TO_NUMBER(SUBSTR(CPF, 7, 1)) * 4 +
            TO_NUMBER(SUBSTR(CPF, 8, 1)) * 3 +
            TO_NUMBER(SUBSTR(CPF, 9, 1)) * 2;
  
    RESTO := MOD(SOMA, 11);
    C     := SUBSTR(CPF, 1, 9);
  
    IF RESTO < 2 THEN
      C := C || '0';
    ELSE
      DIGITO := 11 - RESTO;
      C      := C || TO_CHAR(DIGITO);
    END IF;
  
    CPF1 := C;
  
    --DETERMINA O 11º DÍGITO
    SOMA := TO_NUMBER(SUBSTR(CPF, 1, 1)) * 11 +
            TO_NUMBER(SUBSTR(CPF, 2, 1)) * 10 +
            TO_NUMBER(SUBSTR(CPF, 3, 1)) * 9 +
            TO_NUMBER(SUBSTR(CPF, 4, 1)) * 8 +
            TO_NUMBER(SUBSTR(CPF, 5, 1)) * 7 +
            TO_NUMBER(SUBSTR(CPF, 6, 1)) * 6 +
            TO_NUMBER(SUBSTR(CPF, 7, 1)) * 5 +
            TO_NUMBER(SUBSTR(CPF, 8, 1)) * 4 +
            TO_NUMBER(SUBSTR(CPF, 9, 1)) * 3 +
            TO_NUMBER(SUBSTR(CPF, 10, 1)) * 2;
  
    RESTO := MOD(SOMA, 11);
    C     := SUBSTR(CPF1, 1, 10);
  
    IF RESTO < 2 THEN
      C := C || '0';
    ELSE
      DIGITO := 11 - RESTO;
      C      := C || TO_CHAR(DIGITO);
    END IF;
  
    CPF1 := C;
  
    IF CPF = CPF1 THEN
      RETURN TRUE;
    ELSE
      RETURN FALSE;
    END IF;
  
  END F_CHECK_CPF;