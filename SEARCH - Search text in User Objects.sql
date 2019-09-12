--Procura um texto específico nos Objetos

--Procura apenas nos objetos do schema atual
SELECT * FROM USER_SOURCE WHERE UPPER(TEXT) LIKE UPPER('%%')

--Procura em todos os objetos do banco de dados
SELECT * FROM ALL_SOURCE WHERE UPPER(TEXT) LIKE UPPER('%%'); 