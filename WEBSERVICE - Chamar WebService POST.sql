CREATE OR REPLACE PACKAGE PCK_CALL_WEBSERVICE IS

  PROCEDURE WS_DEL_LOAD_ERROR(IOE_INVNUMBER IN VARCHAR2);

  PROCEDURE WS_TEMP_ORDERS_ERROR(IOE_INVNUMBER IN ORDERS.OE_INVNUMBER%TYPE);

  PROCEDURE P_CALL_WEBSERVICE_JSON(IURL IN VARCHAR2, IJSON IN VARCHAR2);

  PROCEDURE P_CALL_WEBSERVICE_XML_OUT(IURL         IN VARCHAR2,
                                      IXML         IN XMLTYPE,
                                      ISOAP_ACTION IN NUMBER DEFAULT 0,
                                      OXML         OUT XMLTYPE,
                                      OHTTP_STATUS OUT NUMBER);

  FUNCTION F_EXTRACT_XML_NODE(IXML IN XMLTYPE, INODE IN VARCHAR2)
    RETURN VARCHAR2;
    
  FUNCTION F_XML_BEAUTIFIER(IXML IN xmltype) RETURN CLOB;

END PCK_CALL_WEBSERVICE;

/

CREATE OR REPLACE PACKAGE BODY PCK_CALL_WEBSERVICE IS

  --------------------------
  --P_CALL_WEBSERVICE_JSON--
  --------------------------

  -- Author  : Kauan Polydoro
  -- Created : 10/05/2019
  -- Purpose : Procedure utilizada para enviar um JSON via WebService(POST)

  PROCEDURE P_CALL_WEBSERVICE_JSON(IURL IN VARCHAR2, IJSON IN VARCHAR2) IS
  
    REQ    UTL_HTTP.REQ;
    RESP   UTL_HTTP.RESP;
    BUFFER VARCHAR2(32767);
  
  BEGIN
  
    REQ := UTL_HTTP.BEGIN_REQUEST(IURL, 'POST');
    UTL_HTTP.SET_HEADER(REQ, 'Content-Type', 'application/json');
    UTL_HTTP.SET_HEADER(REQ, 'Content-Length', LENGTH(IJSON));
  
    UTL_HTTP.WRITE_TEXT(REQ, IJSON);
  
    RESP := UTL_HTTP.GET_RESPONSE(REQ);
  
    DBMS_OUTPUT.PUT_LINE('HTTP Status Code: ' || RESP.STATUS_CODE);
  
    BEGIN
    
      LOOP
      
        UTL_HTTP.READ_LINE(RESP, BUFFER);
        DBMS_OUTPUT.PUT_LINE(BUFFER);
      
      END LOOP;
    
    EXCEPTION
      WHEN UTL_HTTP.END_OF_BODY THEN
      
        NULL;
      
    END;
  
    UTL_HTTP.END_RESPONSE(RESP);
  
  EXCEPTION
    WHEN OTHERS THEN
    
      NULL;
      DBMS_OUTPUT.PUT_LINE(SQLERRM);
    
  END P_CALL_WEBSERVICE_JSON;

  ------------------------------
  ---P_CALL_WEBSERVICE_XML_OUT--
  ------------------------------

  -- Author  : Kauan Polydoro
  -- Created : 28/05/2019
  -- Purpose : Procedure utilizada para enviar um XML via WebService e ler o retorno

  PROCEDURE P_CALL_WEBSERVICE_XML_OUT(IURL         IN VARCHAR2,
                                      IXML         IN XMLTYPE,
                                      ISOAP_ACTION IN NUMBER DEFAULT 0,
                                      OXML         OUT XMLTYPE,
                                      OHTTP_STATUS OUT NUMBER) IS
  
    REQ      UTL_HTTP.REQ;
    RESP     UTL_HTTP.RESP;
    RESP_VAL CLOB;
  
  BEGIN
  
    --Monta os dados de envio
  
    REQ := UTL_HTTP.BEGIN_REQUEST(IURL, 'POST');
    UTL_HTTP.SET_BODY_CHARSET('UTF-8');
    UTL_HTTP.SET_HEADER(REQ, 'Content-Type', 'application/xml');
    UTL_HTTP.SET_HEADER(REQ, 'Content-Length', LENGTH(IXML.getClobVal));
  
    --Adiciona um SOAP_ACTION padrão
    IF ISOAP_ACTION = 1 THEN
    
      UTL_HTTP.SET_HEADER(REQ,
                          'SOAPAction',
                          'http://www.oracle.com/IdcService/');
    
    END IF;
  
    --Envia o XML
    UTL_HTTP.WRITE_TEXT(REQ, IXML.getClobVal);
  
    --Pega a resposta
    RESP := UTL_HTTP.GET_RESPONSE(REQ);
  
    DBMS_OUTPUT.PUT_LINE('HTTP Status Code: ' || RESP.STATUS_CODE);
  
    --HTTP Response Code (200, 404, 500, ...)
    OHTTP_STATUS := RESP.STATUS_CODE;
  
    --Armazena o retorno no CLOB
    UTL_HTTP.READ_TEXT(RESP, RESP_VAL);
  
    --Transforma o CLOB em XML
    OXML := XMLTYPE(RESP_VAL);
  
    --Fecha a conexão
    UTL_HTTP.END_RESPONSE(RESP);
  
  EXCEPTION
    WHEN OTHERS THEN
    
      UTL_HTTP.END_RESPONSE(RESP);
      OHTTP_STATUS := 999999;
    
  END P_CALL_WEBSERVICE_XML_OUT;

  ----------------------
  --F_EXTRACT_XML_NODE--
  ----------------------

  -- Author  : Kauan Polydoro
  -- Created : 28/05/2019
  -- Purpose : Function utilizada para extrair o valor de um node de um XML

  FUNCTION F_EXTRACT_XML_NODE(IXML IN XMLTYPE, INODE IN VARCHAR2)
    RETURN VARCHAR2 IS
  
    tXML  XMLTYPE;
    tNODE VARCHAR2(500) := '//' || INODE || '/text()';
    tClob CLOB;
  
  BEGIN
  
    tClob := (REPLACE(REPLACE(IXML.getClobVal, '<![CDATA[', ''), ']]>', ''));
  
    select XMLQUERY(tNODE PASSING XMLTYPE(tClob) RETURNING CONTENT)
      INTO tXML
      FROM DUAL;
  
    IF tXML IS NOT NULL THEN
    
      RETURN F_XML_BEAUTIFIER(IXML => IXML);
    
    ELSE
    
      RETURN NULL;
    
    END IF;
  
  EXCEPTION
    WHEN OTHERS THEN
    
      IF SQLCODE = -31011 THEN
      
        RETURN 'ORA-31011: XML parsing failed';
      
      ELSE
      
        RAISE;
      
      END IF;
    
  END F_EXTRACT_XML_NODE;

  --------------------
  --F_XML_BEAUTIFIER--
  --------------------

  -- Author  : Kauan Polydoro
  -- Created : 28/05/2019
  -- Purpose : Function utilizada para transformar o XML gerado pelo Oracle em um XML legivel (Retorno para o usuario)

  FUNCTION F_XML_BEAUTIFIER(IXML IN xmltype) RETURN CLOB IS
  
    tClob CLOB;
  
  BEGIN
  
    tClob := IXML.getClobVal;
  
    tClob := REPLACE(tClob, '&lt;', '<');
  
    tClob := REPLACE(tClob, '&gt;', '>');
  
    tClob := REPLACE(tClob, '&quot;', '"');
  
    tClob := REPLACE(tClob, '&apos;', '''');
  
    RETURN tClob;
  
  END F_XML_BEAUTIFIER;

END PCK_CALL_WEBSERVICE;

/