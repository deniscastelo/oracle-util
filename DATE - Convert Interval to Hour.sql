--Converter intervalo em horas
SELECT TO_CHAR(TRUNC(SYSDATE) + NUMTODSINTERVAL(1, 'hour'), 'hh24:mi:ss') hours
  FROM DUAL;

SELECT TO_CHAR(TRUNC(SYSDATE) + NUMTODSINTERVAL(60, 'minute'), 'hh24:mi:ss') hours
  FROM DUAL;

SELECT TO_CHAR(TRUNC(SYSDATE) + NUMTODSINTERVAL(3600, 'second'), 'hh24:mi:ss') hours
  FROM DUAL;