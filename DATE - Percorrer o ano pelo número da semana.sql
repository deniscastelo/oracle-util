SELECT DIA 
       --MIN(DIA) para pegar o primeiro dia da semana
       --Max(DIA) para pegar o último dia da semana
FROM (SELECT TO_DATE('01-01-2018', 'DD-MM-YYYY') + (ROWNUM-1) DIA
        FROM DUAL CONNECT BY LEVEL <= 366)
WHERE TO_CHAR(DIA, 'WW') = 50 --NUMERO DA SEMANA--