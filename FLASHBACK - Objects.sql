--Logar como Sysdba

SELECT *
  FROM DBA_SOURCE AS OF TIMESTAMP(TO_DATE('14/02/2019 10:33:00', 'dd/mm/yyyy hh24:mi:ss')) --Data
 WHERE (OWNER = 'I9_WMS') --Dono do Objeto     
   AND (TYPE = 'PACKAGE BODY') --(Package / Package Body / Trigger)
   AND (NAME = 'PCK_UIW_02_OUTBOUND') --Nome do Objeto
 ORDER BY LINE
