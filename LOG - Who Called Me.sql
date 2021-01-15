--Variaveis de retorno da WHO_CALLED_ME
L_OWNER VARCHAR2(4000); --Schema
L_NAME  VARCHAR2(4000); --Package
L_LINE  PLS_INTEGER; --Linha
L_TYPE  VARCHAR2(4000); --Object Type

--Chamando WHO_CALLED_ME (Todos os parâmetros são OUTPUT e podem ser utilizados após a chamada)
OWA_UTIL.WHO_CALLED_ME(L_OWNER, L_NAME, L_LINE, L_TYPE);

