Rem
Rem $Header: rdbms/admin/utlpwdmg.sql /main/8 2012/11/06 22:11:18 skayoor Exp $
Rem
Rem utlpwdmg.sql
Rem
Rem Copyright (c) 2006, 2012, Oracle and/or its affiliates. 
Rem All rights reserved. 
Rem
Rem    NAME
Rem      utlpwdmg.sql - script for Default Password Resource Limits
Rem
Rem    DESCRIPTION
Rem      This is a script for enabling the password management features
Rem      by setting the default password resource limits.
Rem
Rem    NOTES
Rem      This file contains a function for minimum checking of password
Rem      complexity. This is more of a sample function that the customer
Rem      can use to develop the function for actual complexity checks that the 
Rem      customer wants to make on the new password.
Rem
Rem    MODIFIED   (MM/DD/YY)
Rem    skayoor     10/26/12 - Bug 14671375: Execute privilege on pwd verify
Rem                           func
Rem    jmadduku    07/30/12 - Bug 13536142: Re-organize the code
Rem    jmadduku    12/02/11 - Bug 12839255: Compliant Password Verify functions
Rem    jmadduku    01/21/11 - Proj 32507: Add a new password verify function
Rem                           STIG_verify_function and enhance functionality of
Rem                           code that checks distance between old and new
Rem                           password
Rem    asurpur     05/30/06 - fix - 5246666 beef up password complexity check 
Rem    nireland    08/31/00 - Improve check for username=password. #1390553
Rem    nireland    06/28/00 - Fix null old password test. #1341892
Rem    asurpur     04/17/97 - Fix for bug479763
Rem    asurpur     12/12/96 - Changing the name of password_verify_function
Rem    asurpur     05/30/96 - New script for default password management
Rem    asurpur     05/30/96 - Created
Rem


-- This script sets the default password resource parameters
-- This script needs to be run to enable the password features.
-- However the default resource parameters can be changed based 
-- on the need.
-- A default password complexity function is provided.



Rem *************************************************************************
Rem BEGIN Password Verification Functions
Rem *************************************************************************


Rem  Function: "complexity_check" - Verifies the complexity 
Rem            of a password string.
Rem 
Rem  If not NULL, each of the following parameters specifies the minimum
Rem  number of characters of the corresponding type.
Rem  chars   -  All characters (i.e. string length)
Rem  letter  -  Alphabetic characters A-Z and a-z
Rem  upper   -  Uppercase letters A-Z
Rem  lower   -  Lowercase letters a-z
Rem  digit   -  Numeric characters 0-9
Rem  special -  All characters not in A-Z, a-z, 0-9 except DOUBLE QUOTE
Rem             which is a password delimiter


CREATE OR REPLACE FUNCTION complexity_check
(password varchar2,
 chars integer := NULL,
 letter integer := NULL,
 upper integer := NULL,
 lower integer := NULL,
 digit integer := NULL,
 special integer := NULL)
RETURN boolean IS
   digit_array varchar2(10) := '0123456789';
   alpha_array varchar2(26) := 'abcdefghijklmnopqrstuvwxyz';
   cnt_letter integer := 0;
   cnt_upper integer := 0;
   cnt_lower integer := 0;
   cnt_digit integer := 0;
   cnt_special integer := 0;
   delimiter boolean := FALSE;
   len INTEGER := NVL (length(password), 0);
   i integer ;
   ch CHAR(1);
BEGIN
   -- Check that the password length does not exceed 2 * (max DB pwd len)
   -- The maximum length of any DB User password is 128 bytes.
   -- This limit improves the performance of the Edit Distance calculation
   -- between old and new passwords.
   IF len > 256 THEN
      raise_application_error(-20020, 'Password length more than 256');
   END IF;

   -- Classify each character in the password.
   FOR i in 1..len LOOP
      ch := substr(password, i, 1);
      IF ch = '"' THEN
         delimiter := TRUE;
      ELSIF instr(digit_array, ch) > 0 THEN
         cnt_digit := cnt_digit + 1;
      ELSIF instr(alpha_array, NLS_LOWER(ch)) > 0 THEN
         cnt_letter := cnt_letter + 1;
         IF ch = NLS_LOWER(ch) THEN
            cnt_lower := cnt_lower + 1;
         ELSE
            cnt_upper := cnt_upper + 1;
         END IF;
      ELSE
         cnt_special := cnt_special + 1;
      END IF;
   END LOOP;

   IF delimiter = TRUE THEN
      raise_application_error(-20012, 'password must NOT contain a ' 
                               || 'double-quote character, which is '
                               || 'reserved as a password delimiter');
   END IF;
   IF chars IS NOT NULL AND len < chars THEN
      raise_application_error(-20001, 'Password length less than ' ||
                              chars);
   END IF;
   IF letter IS NOT NULL AND cnt_letter < letter THEN
      raise_application_error(-20022, 'Password must contain at least ' ||
                                      letter || ' letter(s)');
   END IF;
   IF upper IS NOT NULL AND cnt_upper < upper THEN
      raise_application_error(-20023, 'Password must contain at least ' ||
                                      upper || ' uppercase character(s)');
   END IF;
   IF lower IS NOT NULL AND cnt_lower < lower THEN
      raise_application_error(-20024, 'Password must contain at least ' ||
                                      lower || ' lowercase character(s)');
   END IF;
   IF digit IS NOT NULL AND cnt_digit < digit THEN
      raise_application_error(-20025, 'Password must contain at least ' ||
                                      digit || ' digit(s)');
   END IF;
   IF special IS NOT NULL AND cnt_special < special THEN
      raise_application_error(-20026, 'Password must contain at least ' ||
                                      special || ' special character(s)');
   END IF;

   RETURN(TRUE);
END;
/


Rem  Function: "string_distance" - Calculates the Levenshtein distance 
Rem            between two strings 's' and 't'.

CREATE OR REPLACE FUNCTION string_distance
(s varchar2,
 t varchar2)
RETURN integer IS
   s_len    INTEGER := NVL (length(s), 0);
   t_len    INTEGER := NVL (length(t), 0);
   TYPE arr_type is TABLE OF NUMBER INDEX BY BINARY_INTEGER;
   d_col    arr_type ;
   dist     INTEGER := 0;
BEGIN
   IF s_len = 0 THEN
      dist := t_len;
   ELSIF t_len = 0 THEN
      dist := s_len;
   ELSE
      FOR j IN 1 .. (t_len+1) * (s_len+1) - 1 LOOP
          d_col(j) := 0 ;
      END LOOP;
      FOR i IN 0 .. s_len LOOP
          d_col(i) := i;
      END LOOP;
      FOR j IN 1 .. t_len LOOP
          d_col(j * (s_len + 1)) := j;
      END LOOP;

      FOR i IN 1.. s_len LOOP
        FOR j IN 1 .. t_len LOOP
          IF substr(s, i, 1) = substr(t, j, 1)
          THEN
             d_col(j * (s_len + 1) + i) := d_col((j-1) * (s_len+1) + i-1) ;
          ELSE
             d_col(j * (s_len + 1) + i) := LEAST (
                       d_col( j * (s_len+1) + (i-1)) + 1,      -- Deletion
                       d_col((j-1) * (s_len+1) + i) + 1,       -- Insertion
                       d_col((j-1) * (s_len+1) + i-1) + 1 ) ;  -- Substitution
          END IF ;
        END LOOP;
      END LOOP;
      dist :=  d_col(t_len * (s_len+1) + s_len);
   END IF;

   RETURN (dist);
END;
/


Rem Function: "ora12c_verify_function" - provided from 12c onwards
Rem
Rem This function makes the minimum complexity checks like
Rem the minimum length of the password, password not same as the
Rem username, etc. The user may enhance this function according to
Rem the need.
Rem This function must be created in SYS schema.
Rem connect sys/<password> as sysdba before running the script

CREATE OR REPLACE FUNCTION ora12c_verify_function
(username varchar2,
 password varchar2,
 old_password varchar2)
RETURN boolean IS 
   differ integer;
   pw_lower varchar2(256); 
   db_name varchar2(40);
   i integer;
   simple_password varchar2(10);
   reverse_user varchar2(32);
BEGIN 
   IF NOT complexity_check(password, chars => 8, letter => 1, digit => 1) THEN
      RETURN(FALSE);
   END IF;

   -- Check if the password contains the username
   pw_lower := NLS_LOWER(password);
   IF instr(pw_lower, NLS_LOWER(username)) > 0 THEN
     raise_application_error(-20002, 'Password contains the username');
   END IF;

   -- Check if the password contains the username reversed
   reverse_user := '';
   FOR i in REVERSE 1..length(username) LOOP
     reverse_user := reverse_user || substr(username, i, 1);
   END LOOP;
   IF instr(pw_lower, NLS_LOWER(reverse_user)) > 0 THEN
     raise_application_error(-20003, 'Password contains the username ' || 
                                     'reversed');
   END IF;

   -- Check if the password contains the server name
   select name into db_name from sys.v$database;
   IF instr(pw_lower, NLS_LOWER(db_name)) > 0 THEN
      raise_application_error(-20004, 'Password contains the server name');
   END IF;

   -- Check if the password contains 'oracle'
   IF instr(pw_lower, 'oracle') > 0 THEN
        raise_application_error(-20006, 'Password too simple');
   END IF;

   -- Check if the password is too simple. A dictionary of words may be
   -- maintained and a check may be made so as not to allow the words
   -- that are too simple for the password.
   IF pw_lower IN ('welcome1', 'database1', 'account1', 'user1234',
                              'password1', 'oracle123', 'computer1', 
                              'abcdefg1', 'change_on_install') THEN
      raise_application_error(-20006, 'Password too simple');
   END IF;

   -- Check if the password differs from the previous password by at least
   -- 3 characters
   IF old_password IS NOT NULL THEN
     differ := string_distance(old_password, password);
     IF differ < 3 THEN
        raise_application_error(-20010, 'Password should differ from the ' 
                                || 'old password by at least 3 characters');
     END IF;
   END IF ;

   RETURN(TRUE);
END;
/

GRANT EXECUTE ON ora12c_verify_function TO PUBLIC;

Rem Function: "ora12c_strong_verify_function" - provided from12c onwards for
Rem           stringent password check requirements.
Rem
Rem This function is provided to give stronger password complexity function 
Rem that would take into consideration recommendations from Department of 
Rem Defense Database Security Technical Implementation Guide.

CREATE OR REPLACE FUNCTION ora12c_strong_verify_function
(username varchar2,
 password varchar2,
 old_password varchar2)
RETURN boolean IS 
   differ integer;
BEGIN 
   IF NOT complexity_check(password, chars => 9, upper => 2, lower => 2,
                           digit => 2, special => 2) THEN
      RETURN(FALSE);
   END IF;

   -- Check if the password differs from the previous password by at least
   -- 4 characters
   IF old_password IS NOT NULL THEN
     differ := string_distance(old_password, password);
     IF differ < 4 THEN
        raise_application_error(-20032, 'Password should differ from previous '
                                || 'password by at least 4 characters');
     END IF;
   END IF ;

   RETURN(TRUE);
END;
/

GRANT EXECUTE ON ora12c_strong_verify_function TO PUBLIC;


Rem Function: "verify_function_11G" - provided from 11G onwards.
Rem 
Rem This function makes the minimum complexity checks like
Rem the minimum length of the password, password not same as the
Rem username, etc. The user may enhance this function according to
Rem the need.

CREATE OR REPLACE FUNCTION verify_function_11G
(username varchar2,
 password varchar2,
 old_password varchar2)
RETURN boolean IS 
   differ integer;
   db_name varchar2(40);
   i integer;
   i_char varchar2(10);
   simple_password varchar2(10);
   reverse_user varchar2(32);
BEGIN 
   IF NOT complexity_check(password, chars => 8, letter => 1, digit => 1) THEN
      RETURN(FALSE);
   END IF;

   -- Check if the password is same as the username or username(1-100)
   IF NLS_LOWER(password) = NLS_LOWER(username) THEN
     raise_application_error(-20002, 'Password same as or similar to user');
   END IF;
   FOR i IN 1..100 LOOP
      i_char := to_char(i);
      if NLS_LOWER(username)|| i_char = NLS_LOWER(password) THEN
        raise_application_error(-20005, 'Password same as or similar to ' || 
                                        'username ');
      END IF;
   END LOOP;

   -- Check if the password is same as the username reversed
   FOR i in REVERSE 1..length(username) LOOP
     reverse_user := reverse_user || substr(username, i, 1);
   END LOOP;
   IF NLS_LOWER(password) = NLS_LOWER(reverse_user) THEN
     raise_application_error(-20003, 'Password same as username reversed');
   END IF;

   -- Check if the password is the same as server name and or servername(1-100)
   select name into db_name from sys.v$database;
   if NLS_LOWER(db_name) = NLS_LOWER(password) THEN
      raise_application_error(-20004, 'Password same as or similar ' ||
                                      'to server name');
   END IF;
   FOR i IN 1..100 LOOP
      i_char := to_char(i);
      if NLS_LOWER(db_name)|| i_char = NLS_LOWER(password) THEN
        raise_application_error(-20005, 'Password same as or similar ' || 
                                        'to server name ');
      END IF;
   END LOOP;

   -- Check if the password is too simple. A dictionary of words may be
   -- maintained and a check may be made so as not to allow the words
   -- that are too simple for the password.
   IF NLS_LOWER(password) IN ('welcome1', 'database1', 'account1', 'user1234',
                              'password1', 'oracle123', 'computer1', 
                              'abcdefg1', 'change_on_install') THEN
      raise_application_error(-20006, 'Password too simple');
   END IF;

   -- Check if the password is the same as oracle (1-100)
    simple_password := 'oracle';
    FOR i IN 1..100 LOOP
      i_char := to_char(i);
      if simple_password || i_char = NLS_LOWER(password) THEN
        raise_application_error(-20006, 'Password too simple ');
      END IF;
    END LOOP;

   -- Check if the password differs from the previous password by at least
   -- 3 letters
   IF old_password IS NOT NULL THEN
     differ := string_distance(old_password, password);
     IF differ < 3 THEN
         raise_application_error(-20011, 'Password should differ from the ' ||  
                                 'old password by at least 3 characters');
     END IF;
   END IF;

   RETURN(TRUE);
END;
/

GRANT EXECUTE ON verify_function_11G TO PUBLIC;

-- Below is the older version of the script

-- This script sets the default password resource parameters
-- This script needs to be run to enable the password features.
-- However the default resource parameters can be changed based 
-- on the need.
-- A default password complexity function is also provided.
-- This function makes the minimum complexity checks like
-- the minimum length of the password, password not same as the
-- username, etc. The user may enhance this function according to
-- the need.
-- This function must be created in SYS schema.
-- connect sys/<password> as sysdba before running the script

CREATE OR REPLACE FUNCTION verify_function
(username varchar2,
 password varchar2,
 old_password varchar2)
RETURN boolean IS 
   differ integer;
BEGIN 
   -- Check if the password is same as the username
   IF NLS_LOWER(password) = NLS_LOWER(username) THEN
     raise_application_error(-20001, 'Password same as or similar to user');
   END IF;

   -- Check if the password contains at least four characters, including
   -- one letter, one digit and one punctuation mark.
   IF NOT complexity_check(password, chars => 4, letter => 1, digit => 1,
                           special => 1) THEN
      RETURN(FALSE);
   END IF;

   -- Check if the password is too simple. A dictionary of words may be
   -- maintained and a check may be made so as not to allow the words
   -- that are too simple for the password.
   IF NLS_LOWER(password) IN ('welcome', 'database', 'account', 'user', 
                              'password', 'oracle', 'computer', 'abcd') THEN
      raise_application_error(-20002, 'Password too simple');
   END IF;

   -- Check if the password differs from the previous password by at least
   -- 3 letters
   IF old_password IS NOT NULL THEN
     differ := string_distance(old_password, password);
     IF differ < 3 THEN
         raise_application_error(-20004, 'Password should differ by at' ||
                                         'least 3 characters');
     END IF;
   END IF;

   RETURN(TRUE);
END;
/

GRANT EXECUTE ON verify_function TO PUBLIC;

Rem *************************************************************************
Rem END Password Verification Functions
Rem *************************************************************************

Rem *************************************************************************
Rem BEGIN Password Management Parameters
Rem *************************************************************************

-- This script alters the default parameters for Password Management
-- This means that all the users on the system have Password Management
-- enabled and set to the following values unless another profile is 
-- created with parameter values set to different value or UNLIMITED 
-- is created and assigned to the user.

ALTER PROFILE DEFAULT LIMIT
PASSWORD_LIFE_TIME 180
PASSWORD_GRACE_TIME 7
PASSWORD_REUSE_TIME UNLIMITED
PASSWORD_REUSE_MAX  UNLIMITED
FAILED_LOGIN_ATTEMPTS 10
PASSWORD_LOCK_TIME 1
PASSWORD_VERIFY_FUNCTION ora12c_verify_function;

/** 
The below set of password profile parameters would take into consideration
recommendations from Center for Internet Security[CIS Oracle 11g].

ALTER PROFILE DEFAULT LIMIT
PASSWORD_LIFE_TIME 90 
PASSWORD_GRACE_TIME 3
PASSWORD_REUSE_TIME 365
PASSWORD_REUSE_MAX  20
FAILED_LOGIN_ATTEMPTS 3
PASSWORD_LOCK_TIME 1
PASSWORD_VERIFY_FUNCTION ora12c_verify_function;
*/

/** 
The below set of password profile parameters would take into 
consideration recommendations from Department of Defense Database 
Security Technical Implementation Guide[STIG v8R1]. 

ALTER PROFILE DEFAULT LIMIT
PASSWORD_LIFE_TIME 60
PASSWORD_REUSE_TIME 365 
PASSWORD_REUSE_MAX  5
FAILED_LOGIN_ATTEMPTS 3
PASSWORD_VERIFY_FUNCTION ora12c_strong_verify_function;
*/

Rem *************************************************************************
Rem END Password Management Parameters
Rem *************************************************************************
