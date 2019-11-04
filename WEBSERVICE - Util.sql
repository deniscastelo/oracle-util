CREATE OR REPLACE PACKAGE PCK_UTL_WEBSERVICE IS

  PROCEDURE P_CALL_WEBSERVICE_JSON(IURL IN VARCHAR2, IJSON IN VARCHAR2);

  PROCEDURE P_CALL_WEBSERVICE_JSON_OUT(IURL         IN VARCHAR2,
                                       IJSON        IN CLOB,
                                       METHOD       IN VARCHAR2,
                                       TOKEN        IN VARCHAR2 DEFAULT NULL,
                                       OJSON        OUT CLOB,
                                       OHTTP_STATUS OUT NUMBER);

  PROCEDURE P_CALL_WEBSERVICE_XML(IURL IN VARCHAR2, IXML IN XMLTYPE);

  PROCEDURE P_CALL_WEBSERVICE_XML_OUT(IURL         IN VARCHAR2,
                                      IXML         IN XMLTYPE,
                                      ISOAP_ACTION IN NUMBER DEFAULT 0,
                                      OXML         OUT XMLTYPE,
                                      OHTTP_STATUS OUT NUMBER);

  FUNCTION F_EXTRACT_XML_NODE(IXML IN XMLTYPE, INODE IN VARCHAR2)
    RETURN VARCHAR2;

  FUNCTION F_XML_BEAUTIFIER(IXML IN xmltype) RETURN CLOB;

  FUNCTION F_CLOB_BEAUTIFIER(IXML IN CLOB) RETURN CLOB;
  
  FUNCTION F_IS_XML(IXML IN CLOB) RETURN NUMBER;

END PCK_UTL_WEBSERVICE;

/

  --------------------------
  --P_CALL_WEBSERVICE_JSON--
  --------------------------

  -- Author  : Kauan Polydoro
  -- Created : 10/05/2019
  -- Purpose : Procedure utilizada para enviar um JSON via WebService (POST)

  PROCEDURE P_CALL_WEBSERVICE_JSON(IURL IN VARCHAR2, IJSON IN VARCHAR2) IS
  
    REQ      UTL_HTTP.REQ;
    RESP     UTL_HTTP.RESP;
    RESP_VAL CLOB;
  
  BEGIN
  
    REQ := UTL_HTTP.BEGIN_REQUEST(IURL, 'POST');
    UTL_HTTP.SET_HEADER(REQ, 'Content-Type', 'application/json');
    UTL_HTTP.SET_HEADER(REQ, 'Content-Length', LENGTH(IJSON));
  
    UTL_HTTP.WRITE_TEXT(REQ, IJSON);
  
    RESP := UTL_HTTP.GET_RESPONSE(REQ);
  
    DBMS_OUTPUT.PUT_LINE('Http Status Code: ' || RESP.STATUS_CODE);
  
    UTL_HTTP.READ_TEXT(RESP, RESP_VAL);
  
    DBMS_OUTPUT.PUT_LINE(RESP_VAL);
  
    UTL_HTTP.END_RESPONSE(RESP);
  
  EXCEPTION
    WHEN OTHERS THEN
    
      BEGIN
      
        UTL_HTTP.END_RESPONSE(RESP);
      
      EXCEPTION
        WHEN OTHERS THEN
        
          NULL;
        
      END;
    
      DBMS_OUTPUT.PUT_LINE(SQLERRM);
    
  END P_CALL_WEBSERVICE_JSON;

  ------------------------------
  --P_CALL_WEBSERVICE_JSON_OUT--
  ------------------------------

  -- Author  : Kauan Polydoro
  -- Created : 01/10/2019
  -- Purpose : Procedure utilizada para enviar um JSON via WebService e ler o retorno

  PROCEDURE P_CALL_WEBSERVICE_JSON_OUT(IURL         IN VARCHAR2,
                                       IJSON        IN CLOB, --JSON de Entrada
                                       METHOD       IN VARCHAR2, --(POST, GET, PUT, ...)
                                       TOKEN        IN VARCHAR2 DEFAULT NULL,
                                       OJSON        OUT CLOB,
                                       OHTTP_STATUS OUT NUMBER) IS
  
    REQ  UTL_HTTP.REQ;
    RESP UTL_HTTP.RESP;
  
  BEGIN
  
    --Monta o Header da requisição
    REQ := UTL_HTTP.BEGIN_REQUEST(IURL, METHOD);
    UTL_HTTP.SET_HEADER(REQ, 'Content-Type', 'application/json');
    UTL_HTTP.SET_HEADER(REQ, 'Content-Length', LENGTH(IJSON));
  
    IF TOKEN IS NOT NULL THEN
    
      UTL_HTTP.set_header(REQ, 'token', TOKEN);
    
    END IF;
  
    --Escreve o JSON na Requisição
    UTL_HTTP.WRITE_TEXT(REQ, IJSON);
  
    --Envia e pega a resposta
    RESP := UTL_HTTP.GET_RESPONSE(REQ);
  
    --HTTP Response Code (200, 400, 404, 500, ...)
    OHTTP_STATUS := RESP.STATUS_CODE;
  
    --Armazena o retorno no CLOB
    UTL_HTTP.READ_TEXT(RESP, OJSON);
  
    --Fecha a conexão
    UTL_HTTP.END_RESPONSE(RESP);
  
  EXCEPTION
    WHEN OTHERS THEN
    
      BEGIN
      
        UTL_HTTP.END_RESPONSE(RESP);
      
      EXCEPTION
        WHEN OTHERS THEN
        
          NULL;
        
      END;
    
      RAISE;
    
  END P_CALL_WEBSERVICE_JSON_OUT;

  -------------------------
  --P_CALL_WEBSERVICE_XML--
  -------------------------

  -- Author  : Kauan Polydoro
  -- Created : 10/05/2019
  -- Purpose : Procedure utilizada para enviar um XML via WebService (POST)

  PROCEDURE P_CALL_WEBSERVICE_XML(IURL IN VARCHAR2, IXML IN XMLTYPE) IS
  
    REQ      UTL_HTTP.REQ;
    RESP     UTL_HTTP.RESP;
    RESP_VAL CLOB;
  
  BEGIN
  
    REQ := UTL_HTTP.BEGIN_REQUEST(IURL, 'POST');
    UTL_HTTP.SET_HEADER(REQ, 'Content-Type', 'application/xml');
    UTL_HTTP.SET_HEADER(REQ, 'Content-Length', LENGTH(IXML.getClobVal));
  
    UTL_HTTP.WRITE_TEXT(REQ, IXML.getClobVal);
  
    RESP := UTL_HTTP.GET_RESPONSE(REQ);
  
    DBMS_OUTPUT.PUT_LINE('Http Status Code: ' || RESP.STATUS_CODE);
  
    UTL_HTTP.READ_TEXT(RESP, RESP_VAL);
  
    DBMS_OUTPUT.PUT_LINE(RESP_VAL);
  
    UTL_HTTP.END_RESPONSE(RESP);
  
  EXCEPTION
    WHEN OTHERS THEN
    
      BEGIN
      
        UTL_HTTP.END_RESPONSE(RESP);
      
      EXCEPTION
        WHEN OTHERS THEN
        
          NULL;
        
      END;
    
      DBMS_OUTPUT.PUT_LINE(SQLERRM);
    
  END P_CALL_WEBSERVICE_XML;

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
  
    --Monta o Header da requisição
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
  
    --Escreve o XML na Requisição
    UTL_HTTP.WRITE_TEXT(REQ, IXML.getClobVal);
  
    --Envia e pega a resposta
    RESP := UTL_HTTP.GET_RESPONSE(REQ);
  
    --HTTP Response Code (200, 400, 404, 500, ...)
    OHTTP_STATUS := RESP.STATUS_CODE;
  
    --Armazena o retorno no CLOB
    UTL_HTTP.READ_TEXT(RESP, RESP_VAL);
  
    --Transforma o CLOB em XML
    OXML := XMLTYPE(RESP_VAL);
  
    --Fecha a conexão
    UTL_HTTP.END_RESPONSE(RESP);
  
  EXCEPTION
    WHEN OTHERS THEN
    
      BEGIN
      
        UTL_HTTP.END_RESPONSE(RESP);
      
      EXCEPTION
        WHEN OTHERS THEN
        
          NULL;
        
      END;
    
      RAISE;
    
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
    
      RETURN F_XML_BEAUTIFIER(IXML => tXML);
    
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

  FUNCTION F_XML_BEAUTIFIER(IXML IN XMLTYPE) RETURN CLOB IS
  
    tClob CLOB;
  
  BEGIN
  
    tClob := IXML.getClobVal;
  
    tClob := REPLACE(tClob, '&lt;', '<');
  
    tClob := REPLACE(tClob, '&gt;', '>');
  
    tClob := REPLACE(tClob, '&quot;', '"');
  
    tClob := REPLACE(tClob, '&apos;', '''');
  
    RETURN tClob;
  
  END F_XML_BEAUTIFIER;

  --------------------
  --F_CLOB_BEAUTIFIER--
  --------------------

  -- Author  : Kauan Polydoro
  -- Created : 01/11/2019
  -- Purpose : Function utilizada para transformar o CLOB de um XML gerado pelo Oracle em um XML legivel (Retorno para o usuario)

  FUNCTION F_CLOB_BEAUTIFIER(IXML IN CLOB) RETURN CLOB IS
  
    tClob CLOB;
  
  BEGIN
  
    tClob := IXML;
  
    tClob := REPLACE(tClob, '&lt;', '<');
  
    tClob := REPLACE(tClob, '&gt;', '>');
  
    tClob := REPLACE(tClob, '&quot;', '"');
  
    tClob := REPLACE(tClob, '&apos;', '''');
  
    RETURN tClob;
  
  END F_CLOB_BEAUTIFIER;

  ------------
  --F_IS_XML--
  ------------

  -- Author  : Kauan Polydoro
  -- Created : 01/11/2019
  -- Purpose : Function utilizada para verificar se o valor de entrada é um XML

  FUNCTION F_IS_XML(IXML IN CLOB) RETURN NUMBER IS
  
    vXml XMLTYPE;
  
  BEGIN
  
    vXml := XMLTYPE(IXML);
  
    IF vXml IS NOT NULL THEN
    
      RETURN 1;
    
    ELSE
    
      RETURN 0;
    
    END IF;
  
  EXCEPTION
    WHEN OTHERS THEN
    
      RETURN 2;
    
  END F_IS_XML;

END PCK_UTL_WEBSERVICE;
/