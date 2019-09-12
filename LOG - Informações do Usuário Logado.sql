FUNCTION F_GET_OS_INFO RETURN VARCHAR2 is
    
    --Função retorna o Usuário do SO, Nome da Máquina e o IP <OSUSER>@<MACHINE>(<IP>)
    
    mResult VARCHAR2(2000);
    
  BEGIN
    
    
    SELECT UPPER(A.OSUSER || '@' || A.MACHINE || '(' ||
                 SYS_CONTEXT('USERENV', 'IP_ADDRESS') || ')')
      INTO mResult
      FROM V$SESSION A
     WHERE AUDSID = USERENV('sessionid');
    
    RETURN mResult;
    
  EXCEPTION
    WHEN OTHERS THEN
      BEGIN
        
        SELECT SYS_CONTEXT('USERENV', 'IP_ADDRESS') INTO mResult FROM DUAL;
        
        RETURN mResult;
        
      EXCEPTION
        WHEN OTHERS THEN
          RETURN NULL;
      END;
  END;