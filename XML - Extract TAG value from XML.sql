SELECT XMLQUERY('//descricao/text()' PASSING XMLTYPE                 
('<?xml version="1.0" encoding="UTF-8"?>
  <soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
  <soapenv:Body><ns1:processarResponse soapenv:encodingStyle="http://schemas.xmlsoap.org/soap/encoding/" xmlns:ns1="http://core.jintegra.mv.com.br">
  <processarReturn xsi:type="soapenc:string" xmlns:soapenc="http://schemas.xmlsoap.org/soap/encoding/">
  <Mensagem>
    <motivoErro>
      <descricao>ORA-20001: Nao existe esta quantidade no Lote de Estoque do Produto   438814
                 ORA-06512: at "DBAMV.TRG_I_ITMVTO_ESTOQUE", line 291
                 ORA-04088: error during execution of trigger ''DBAMV.TRG_I_ITMVTO_ESTOQUE''</descricao>
    </motivoErro>
    <Cabecalho>
      <mensagemID>1</mensagemID>
      <versaoXML>1</versaoXML>
      <identificacaoCliente>1</identificacaoCliente>
      <dataHora>2019-05-28 10:06:18</dataHora>
      <servico>MOVIMENTO_ESTOQUE_BRINT</servico>
      <empresaOrigem>1</empresaOrigem>
      <sistemaOrigem>MV</sistemaOrigem>
      <empresaDestino>1</empresaDestino>
      <sistemaDestino>1</sistemaDestino>
      <usuario>MV</usuario>
      <senha>MV</senha>
    </Cabecalho>
    <Movimento>
      <operacao>I</operacao>
      <solicitacaoProduto>10987619</solicitacaoProduto>
      <listaProduto>
        <Produto>
          <codigoProduto>438814</codigoProduto>
          <quantidadeAtendida>1</quantidadeAtendida>
          <codigoLote>LOTEMVTESTE2000</codigoLote>
          <dataValidade>2020-05-27</dataValidade>
       </Produto>
      </listaProduto>
    </Movimento>
  </Mensagem>
  </processarReturn></ns1:processarResponse>
</soapenv:Body>
</soapenv:Envelope>')
RETURNING CONTENT) AS TESTE_XMLQUERY  FROM DUAL;