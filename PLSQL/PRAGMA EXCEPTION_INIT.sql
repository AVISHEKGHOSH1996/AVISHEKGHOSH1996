Ex:- Oracle Standard
whenever oracle define any exception then there are 3 things their
1. Exception Name
2. Exception Code
3. Error Messgare 

Ex:-

Exception Name                      Error Code (SQLCODE)        ERROR Description (SQLERRM)
INVALID_NUMBER                       -1722                                  ORA-01722: invalid number  
NO_DATA_FOUND                      -1403                                   ORA-01403: no data found
TOO_MANY_ROWS                    -1422                                   ORA-01422: exact fetch returns more than requested number of rows
VALUE_ERROR                          -6502                                    ORA-06502: PL/SQL: numeric or value error: character string buffer too small
VALUE_ERROR                          -6502                                    ORA-06502: PL/SQL: numeric or value error: character to number conversion error
ZERO_DIVIDE                           -1476                                     ORA-01476: divisor is equal to zero
LARGE_VALUE                           -1438                                    ORA-01438: value larger than specified precision allowed for this column

we will not handel with name. so we use OTHERS EXCEPTION class in this , IF you wan to handel with Name then option is available in Oracle i.e. PRAGMA EXCEPTION_INIT
for giving the Proper name to any UN-NAME exception in Oracle we will use PRAGMA EXCEPTION_INIT (exception_name, error_code)

--====================================================
--Example:- Raising User-Defined Exception with RAISE_APPLICATION_ERROR
PRAGMA EXCEPTION_INIT (exception_name, error_code)
The error_code is an integer in the range -20000..-20999 
The message is a character string of at most 2048 bytes.
--====================================================

DECLARE

BEGIN

INSERT INTO SCOTT.emp  (EMPNO) VALUES (123478732123312);

EXCEPTION
WHEN OTHERS THEN
dbms_output.put_line('SQLCODE: '|| SQLCODE);
dbms_output.put_line('SQLERRM: '|| SQLERRM);
END;



OUTPUT:-
SQLCODE: -1438
SQLERRM: ORA-01438: value larger than specified precision allowed for this column

--===================================================

DECLARE
LARGE_VALUE  exception;
PRAGMA EXCEPTION_INIT(LARGE_VALUE, -1438);
BEGIN

INSERT INTO SCOTT.emp  (EMPNO) VALUES (123432123312);


EXCEPTION
WHEN LARGE_VALUE THEN
dbms_output.put_line('SQLCODE: '|| SQLCODE);
dbms_output.put_line('SQLERRM: '|| SQLERRM);
END;


OUTPUT:-
SQLCODE: -1438
SQLERRM: ORA-01438: value larger than specified precision allowed for this column

--===================================================


DECLARE
V_NAME SCOTT.EMP.ENAME%TYPE;
 invalid_column  exception;
pragma exception_init(invalid_column, -904); 
BEGIN

execute immediate 'select namewrong into V_name from SCOTT.emp where rownum = 1';

RAISE_APPLICATION_ERROR(-904, 'This column is not valid please check again.');

EXCEPTION WHEN invalid_column THEN

dbms_output.put_line('SQLCODE: '|| SQLCODE);
dbms_output.put_line('SQLERRM: '|| SQLERRM);

END;


OUTPUT:-
SQLCODE: -904
SQLERRM: ORA-00904: "NAMEWRONG": invalid identifier

--====================================================

DECLARE
due_date DATE:= '31-MAY-2020';
today    DATE:= '1-JUN-2020';
PAST_DUE_REAMINING  EXCEPTION;   -- declare exception

BEGIN

    IF due_date < today THEN                   -- explicitly raise exception
    RAISE PAST_DUE_REAMINING;
    --RAISE_APPLICATION_ERROR(-20000, 'Account past due. Reamining first pay that ..');
  END IF;
 
 
EXCEPTION
  WHEN PAST_DUE_REAMINING THEN
dbms_output.put_line ('Account past due. Reamining first pay that .');
dbms_output.put_line('SQLCODE: '|| SQLCODE);
dbms_output.put_line('SQLERRM: '|| SQLERRM);
 
END;



OUTPUT:-
Account past due. Reamining first pay that .
SQLCODE: 1
SQLERRM: User-Defined Exception


--=================================================

DECLARE
due_date DATE:= '31-MAY-2020';
today    DATE:= '1-JUN-2020';
PAST_DUE_REAMINING  EXCEPTION;   -- declare exception
PRAGMA EXCEPTION_INIT (PAST_DUE_REAMINING, -20000);  -- assign error code to exception

BEGIN

  IF due_date < today THEN                   -- explicitly raise exception
    RAISE_APPLICATION_ERROR(-20000, 'Account past due. Reamining first pay that ..');
  END IF;
 
 
EXCEPTION
  WHEN PAST_DUE_REAMINING THEN  -- handle exception
dbms_output.put_line('SQLCODE: '|| SQLCODE);
dbms_output.put_line('SQLERRM: '|| SQLERRM);

END;
