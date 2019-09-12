CASE WHEN TRUNC(DT_FIM - DT_INI) IS NULL THEN NULL
     ELSE CASE WHEN TRUNC(DT_FIM - DT_INI) = 0 THEN NULL
               ELSE TRUNC(DT_FIM - DT_INI) || 'D ' END 
                 || TO_CHAR(TRUNC(SYSDATE) + (DT_FIM - DT_INI), 'HH24') || ':' 
                 || TO_CHAR(TRUNC(SYSDATE) + (DT_FIM - DT_INI), 'MI')   || ':' 
                 || TO_CHAR(TRUNC(SYSDATE) + (DT_FIM - DT_INI), 'SS')                 
   END TEMPO_TOTAL