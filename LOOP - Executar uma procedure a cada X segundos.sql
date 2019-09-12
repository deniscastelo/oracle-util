DECLARE

  IN_TIME NUMBER; --Segundos
  V_NOW   DATE; --Data atual
  V_ARRAY PHP_ARRAY; --V_ARRAY

BEGIN
  
  V_ARRAY := PHP_ARRAY(1, 2, 3, 4, 5);
  
  IN_TIME := 375; --Quantos segundos irá demorar em cada loop

  FOR I IN 1..V_ARRAY.COUNT LOOP
  
    SELECT SYSDATE INTO V_NOW FROM DUAL; --Pega a data atual
  
    LOOP
    
      EXIT WHEN V_NOW +(IN_TIME * (1 / 86400)) <= SYSDATE; --Espera dar os segundos
    
    END LOOP;
    
    PACKAGE_EXEMPLO.PROCEDURE_EXEMPLO(PARAM => V_ARRAY(I)); 

    DBMS_OUTPUT.PUT_LINE(V_ARRAY(I) || ' - ' || TO_CHAR(SYSDATE,'dd/mm/yyyy hh24:mi:ss')); --Data que executou o processo para LOG 
    
  
  END LOOP;

END;
