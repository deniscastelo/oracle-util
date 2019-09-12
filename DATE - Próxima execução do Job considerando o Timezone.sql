--Select para saber a próxima execução do JOB

SELECT TO_CHAR(NEXT_RUN_DATE + ((SYSDATE - CURRENT_DATE)) + -
               ((-3 - (TO_NUMBER(SUBSTR(SESSIONTIMEZONE, 0, 3)))) / 24),
               'HH24:MI') HORARIO,       
       NEXT_RUN_DATE, --Próximo horario do Job
       SESSIONTIMEZONE, --Timezone da sessão atual
       CURRENT_DATE, --Horario da sessão com o Timezone do servidor (No select irá considerar o timezone da sua sessão, 
                                                                   --mas nos calculos o servidor utiliza o proprio Timezone)
       SYSDATE --Horario da Sessão atual
  FROM DBA_SCHEDULER_JOBS
 WHERE JOB_NAME = 'P_JOB_LOAD';
