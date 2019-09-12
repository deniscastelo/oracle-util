SELECT XMLELEMENT("soapenv:Envelope",
                    XMLATTRIBUTES('http://www.w3.org/2001/XMLSchema-instance' AS
                                  "xmlns:xsi",
                                  'http://www.w3.org/2001/XMLSchema' AS
                                  "xmlns:xsd",
                                  'http://schemas.xmlsoap.org/soap/envelope/' AS
                                  "xmlns:soapenv",
                                  'http://core.jintegra.mv.com.br' AS
                                  "xmlns:core"),
                    XMLELEMENT("soapenv:Header"),
                    XMLELEMENT("soapenv:Body",
                               XMLELEMENT("core:processar",
                                          XMLATTRIBUTES('http://schemas.xmlsoap.org/soap/encoding/' AS
                                                        "soapenv:encodingStyle"),
                                          XMLELEMENT("xml",
                                                     XMLATTRIBUTES('soapenc:string' AS
                                                                   "xsi:type",
                                                                   'http://schemas.xmlsoap.org/soap/encoding/' AS
                                                                   "xmlns:soapenc"),
                                                     
                                                     XMLCDATA(XMLELEMENT("Mensagem",
                                                                         XMLELEMENT("Cabecalho",
                                                                                    XMLFOREST(1 AS
                                                                                              "mensagemID",
                                                                                              1 AS
                                                                                              "versaoXML",
                                                                                              1 AS
                                                                                              "identificacaoCliente",
                                                                                              TO_CHAR(SYSDATE,
                                                                                                      'YYYY-MM-DD HH24:MI:SS') AS
                                                                                              "dataHora",
                                                                                              'MOVIMENTO_ESTOQUE_BRINT' AS
                                                                                              "servico",
                                                                                              1 AS
                                                                                              "empresaOrigem",
                                                                                              'MV' AS
                                                                                              "sistemaOrigem",
                                                                                              1 AS
                                                                                              "empresaDestino",
                                                                                              1 AS
                                                                                              "sistemaDestino",
                                                                                              'MV' AS
                                                                                              "usuario",
                                                                                              'MV' AS
                                                                                              "senha")),
                                                                         XMLELEMENT("Movimento",
                                                                                    XMLFOREST('I' AS
                                                                                              "operacao",
                                                                                              OEL_INVNUMBER AS
                                                                                              "solicitacaoProduto"),
                                                                                    XMLELEMENT("listaProduto",
                                                                                               XMLAGG(XMLELEMENT("Produto",
                                                                                                                 XMLFOREST(RI_AT_ID AS
                                                                                                                           "codigoProduto",
                                                                                                                           RI_QTY AS
                                                                                                                           "quantidadeAtendida",
                                                                                                                           RI_LOTNR AS
                                                                                                                           "codigoLote",
                                                                                                                           RI_EXPIREDATE AS
                                                                                                                           "dataValidade"))))))))))
                    
                    ) XML
    FROM (SELECT '10987619' OEL_INVNUMBER, --solicitacaoProduto
                 '438814' RI_AT_ID, --codigoProduto
                 SUM(1) RI_QTY, --quantidadeAtendida
                 'LOTEMVTESTE2000' RI_LOTNR, --codigoLote
                 '2020-05-27' RI_EXPIREDATE --dataValidade
            FROM DUAL)
   GROUP BY OEL_INVNUMBER;