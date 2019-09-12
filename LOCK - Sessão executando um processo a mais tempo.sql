SELECT S.SID,
       S.SERIAL#,
       P.SPID AS "OS PID",
       S.USERNAME,
       S.MODULE,
       ST.VALUE / 100 AS "CPU sec"
  FROM V$SESSTAT ST, V$STATNAME SN, V$SESSION S, V$PROCESS P
 WHERE SN.NAME = 'CPU used by this session' --— CPU
   AND ST.STATISTIC# = SN.STATISTIC#
   AND ST.SID = S.SID
   AND S.PADDR = P.ADDR
   AND S.LAST_CALL_ET < 1800 --Ativas nos últimos 30 minutos (Em segundos)
   AND S.LOGON_TIME > (SYSDATE - 240 / 1440) --Sessões logadas a mais de 4 horas
 ORDER BY ST.VALUE DESC;