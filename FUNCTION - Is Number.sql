  FUNCTION F_IS_NUMBER(P_STRING IN VARCHAR2) RETURN BOOLEAN;
  
  ---------------  
  --F_IS_NUMBER--
  ---------------

  -- Author  : Kauan Polydoro
  -- Created : 27/11/2019
  -- Purpose : Function utilizada para verificar se o valor de entrada é um NUMBER

  FUNCTION F_IS_NUMBER(P_STRING IN VARCHAR2) RETURN BOOLEAN IS
  
    V_NEW_NUM NUMBER;
  
  BEGIN
  
    V_NEW_NUM := TO_NUMBER(P_STRING);
  
    IF V_NEW_NUM IS NOT NULL THEN
    
      RETURN TRUE;
    
    ELSE
    
      RETURN FALSE;
    
    END IF;
  
  EXCEPTION
    WHEN VALUE_ERROR THEN
    
      RETURN FALSE;
    
  END F_IS_NUMBER;