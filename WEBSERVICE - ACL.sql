-- 
-- Liberar acesso ACL
-- 

-- Criar regra e arquivo de liberação 
BEGIN
   DBMS_NETWORK_ACL_ADMIN.CREATE_ACL (
    acl          => 'oracleflash.xml',
    description  => 'Permissions to access http://www.oracleflash.com',
    principal    => 'SCOTT',
    is_grant     => TRUE,
    privilege    => 'connect');
   COMMIT;
END;
-- acesso ao usuário
BEGIN
   DBMS_NETWORK_ACL_ADMIN.ADD_PRIVILEGE (
    acl          => 'oracleflash.xml',                
    principal    => 'ORACLEFLASH',
    is_grant     => TRUE, 
    privilege    => 'connect',
    position     => null);
   COMMIT;
END;
/

--
-- libera URL
BEGIN
   DBMS_NETWORK_ACL_ADMIN.ASSIGN_ACL (
    acl          => 'oracleflash.xml',                
    host         => '*.oracleflash.com',
	lower_port => 1,
    upper_port => 9999);
     COMMIT;
END;
/

-- REMOVE ACESS
BEGIN
  DBMS_NETWORK_ACL_ADMIN.unassign_acl (
    acl         => '/sys/acls/open_acl_file.xml',
    host        => 'smtplw.com.br'); 
  COMMIT;
END;
/

-- deleta o privilegio 

BEGIN
  DBMS_NETWORK_ACL_ADMIN.delete_privilege ( 
    acl         => 'oracleflash.xml', 
    principal   => 'ORACLEFLASH',
    is_grant    => TRUE, 
    privilege   => 'connect');
  COMMIT;
END;
/

-- drop regra e arquivo
BEGIN
  DBMS_NETWORK_ACL_ADMIN.DROP_ACL ( 
    acl         => 'oracleflash.xml');
  COMMIT;
END;
/