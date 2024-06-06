EXCEPTION :- it is nothing but run time error which raise by system

Types of Exception / Category of exception

1. System Defined Exceptions
    1.1 Named Exception (Predefined Exceptions)
    1.2 Un-Named Exception (Internally Defined Exceptions)

2.  User-Defined Exceptions


SQLCODE returns the number of the last encountered error.
SQLERRM returns the  message associated with its error-number argument.


--====================================================
User Defined Exceptions :-
You can declare your own exceptions in the declarative part of any PL/SQL anonymous block, subprogram, or package.
==================================================================================================================
---1.IMPLICITE EXCEPTION-----
DECLARE 
LV_ENAME EMP.ENAME%TYPE;  --VARCHAR2 (1000);
BEGIN
SELECT ENAME INTO LV_ENAME FROM EMP
WHERE EMPNO = 78839;
DBMS_OUTPUT.PUT_LINE(LV_ENAME);

EXCEPTION 
WHEN NO_DATA_FOUND THEN 
DBMS_OUTPUT.PUT_LINE
('Sql error code:'||SQLCODE||' '|| CHR(10) ||'Error message associated with its error-number argument:'||SQLERRM);

WHEN OTHERS THEN 
DBMS_OUTPUT.PUT_LINE(SQLERRM ||' ' || CHR(10) ||' '|| SQLCODE ||CHR(10)||'For this Employee number there is no record in table');
END;
=======================================================================================================================
---2. User-Defined or Explicit Exceptions-------------------
====================================================
--1 EXCEPTION Raise thru (RAISE STATEMENT)
--====================================================

DECLARE
  V_Your_age   NUMBER:=16;
  NOT_VALID_AGE EXCEPTION;
BEGIN
 
  IF V_Your_age < 18 THEN
    RAISE NOT_VALID_AGE;
  END IF;
  
EXCEPTION
WHEN NOT_VALID_AGE THEN
    DBMS_OUTPUT.PUT_LINE ('You are not authorized for vote you are below 18 years');   
END;

-====================================================
--2 EXCEPTION Raise thru ( RAISE_APPLICATION_ERROR )
--====================================================

DECLARE
  V_Your_age   NUMBER:=16;
BEGIN
 
  IF V_Your_age < 18 THEN
     RAISE_APPLICATION_ERROR (-20008, 'You are not authorized for vote you are below 18 years');
  END IF;
  
  EXCEPTION WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE (SQLERRM);
END;
-----------------------------------------------------------------------------------------------

-==================================
ZERO_DIVIDE -1476
ORA-01476: divisor is equal to zero
--==================================

DECLARE
V_Total_Qty   NUMBER := 100;
V_Count_Of_Person  NUMBER := 0;
V_Per_distrib_Qty      NUMBER;

ZERO_DIVISER EXCEPTION;

BEGIN

If  V_Count_Of_Person = 0 THEN
RAISE ZERO_DIVISER;
ELSE
  V_Per_distrib_Qty := V_Total_Qty / V_Count_Of_Person; 
END IF;

EXCEPTION

WHEN ZERO_DIVISER THEN
DBMS_OUTPUT.PUT_LINE('You can not distribute any thing to zero person so please check your no_of_person value ');

END;
