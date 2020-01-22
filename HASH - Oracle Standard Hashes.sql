--Hash algorithms that are defined and standardized by the National Institute of Standards and Technology
select standard_hash('user_password', 'SHA1,') from dual;
select standard_hash('user_password', 'SHA256') from dual;
select standard_hash('user_password', 'SHA384') from dual;
select standard_hash('user_password', 'SHA512') from dual;
select standard_hash('user_password', 'MD5') from dual;