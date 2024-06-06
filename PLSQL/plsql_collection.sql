------------------------------------------------------Nested Table Collection----------------------------------------------------
DECLARE
    /*Create Nested Table type collection*/
   TYPE my_nested_table   IS TABLE OF number;
   var_nt  my_nested_table :=  my_nested_table (9,18,27,36,45,54,63,72,81,90); /*Declare Collection Variable*/
 BEGIN
    DBMS_OUTPUT.PUT_LINE ('Value stored at index '||1||'is '||var_nt(1));
    
   /*FOR i IN 1..var_nt.COUNT
   LOOP
     DBMS_OUTPUT.PUT_LINE ('Value stored at index '||i||'is '||var_nt(i));
   END LOOP;*/
 END;
 /
 --------------------------------------------------------------------------------------
 /*How To Create Nested Table As Database Object In Oracle*/

 CREATE OR REPLACE TYPE my_nested_table IS TABLE OF VARCHAR2 (10); /*Create Nested Table type collection*/
/
----------------------------------------------------------------------------------------
--- Use of nested table--------------------
CREATE TABLE my_subject(
	  sub_id    	NUMBER,
	  sub_name  	VARCHAR2 (20),
	  sub_schedule_day    my_nested_table
) NESTED TABLE sub_schedule_day STORE AS nested_tab_space;
/

INSERT INTO my_subject (sub_id,sub_name,sub_schedule_day)
VALUES(1,'Math',my_nested_table('Sun','Mon','Tue','Wed','Thu','Fri','Sat')); 
---------------------------------------------------------------------------------------
DECLARE
    /*Create Nested Table type collection*/
   TYPE my_nested_table   IS TABLE OF varchar2(1000);
   var_nt  my_nested_table :=  my_nested_table (); /*Declare Collection Variable*/
   cnt number := 0;
   cursor emp is select ename from emp;
 BEGIN
   for i in emp loop
   var_nt.extend();
   
   cnt := cnt + 1;
   var_nt(cnt) := i.ename;
   DBMS_OUTPUT.PUT_LINE ('Value stored at index '||cnt||'is '||var_nt(cnt));
 end loop;
   
 END; 
 -----------------------------------------------------------------------------
 --SELECT * FROM EMP
DECLARE
TYPE NEST_ENAME_TYPE IS TABLE OF EMP.ENAME%TYPE;  --VARCHAR2 (1000);
TYPE NEST_JOB_TYPE IS TABLE OF VARCHAR2 (1000);
LV_ENAME NEST_ENAME_TYPE := NEST_ENAME_TYPE() ;
LV_JOB NEST_JOB_TYPE := NEST_JOB_TYPE();
COUNTER NUMBER := 0;
BEGIN 
FOR I IN (SELECT ENAME, JOB FROM EMP)
LOOP
LV_ENAME.EXTEND();
LV_JOB.EXTEND();
COUNTER := COUNTER + 1;
LV_ENAME(COUNTER) := I.ENAME;
LV_JOB(COUNTER) := I.ENAME;
DBMS_OUTPUT.PUT_LINE ('Employee Name is '||LV_ENAME(COUNTER) || ' ('||LV_JOB(COUNTER)||')');
END LOOP;
END;
-----------------------------------------------------------------------------------------------------
---ADDING TWO COLLECTION-------
DECLARE
TYPE NESTED_COL1_TYPE IS TABLE OF NUMBER;
TYPE NESTED_COL2_TYPE IS TABLE OF NUMBER;
TYPE NESTED_COL3_TYPE IS TABLE OF NUMBER;
LV_NUMBER1 NESTED_COL1_TYPE := NESTED_COL1_TYPE(2,4,6);
LV_NUMBER2 NESTED_COL2_TYPE := NESTED_COL2_TYPE(2,4,6);
LV_NUMBER3 NESTED_COL3_TYPE := NESTED_COL3_TYPE();
BEGIN 
FOR I IN 1..LV_NUMBER1.COUNT LOOP
LV_NUMBER3.EXTEND(LV_NUMBER1.COUNT);
LV_NUMBER3(I) := LV_NUMBER1(I) + LV_NUMBER2 (I);
DBMS_OUTPUT.PUT_LINE (LV_NUMBER3(I));
END LOOP;
END;
----------------------------
---------------------------------------------------------------VARRAY--------------------------------------------------------------
DECLARE
TYPE V_NUMBER_TYPE IS VARRAY(5) OF NUMBER;  
LV_NUMBERS V_NUMBER_TYPE := V_NUMBER_TYPE();
BEGIN 
LV_NUMBERS.EXTEND(5);
LV_NUMBERS(1) := 100;
DBMS_OUTPUT.PUT_LINE(LV_NUMBERS(1));
END;
----------------------------------------------------
DECLARE
TYPE V_NAME_TYPE IS VARRAY(5) OF VARCHAR2(1000);  
LV_NUMBERS V_NAME_TYPE := V_NAME_TYPE();
CURSOR CUR_EMP IS SELECT ENAME FORM EMP;
BEGIN 
FOR I IN CUR_EMP LOOP
LV_NUMBERS.EXTEND(5);
LV_NUMBERS(1) := 100;
DBMS_OUTPUT.PUT_LINE(LV_NUMBERS(1));
END LOOP;
END;
-------------------------------------------------------------------------
-------------------------------------Associative Array in Oracle Database-------------------------------------------------------------------
DECLARE
TYPE ASCT_NUMBER_TYPE IS TABLE OF NUMBER
INDEX BY VARCHAR2(1000);
LV_NUMBERS ASCT_NUMBER_TYPE;
FLAG VARCHAR2(1000);
BEGIN
LV_NUMBERS('DBMS') := 1234; --INSERT--
LV_NUMBERS('SQL') := 123;
LV_NUMBERS('DBMS') := 12345;  --UPDATE--
--DBMS_OUTPUT.PUT_LINE(LV_NUMBERS('DBMS'));
FLAG := LV_NUMBERS.FIRST;
WHILE FLAG IS NOT NULL 
LOOP
DBMS_OUTPUT.PUT_LINE(LV_NUMBERS(FLAG));
FLAG := LV_NUMBERS.NEXT(FLAG);
END LOOP;

END;

========================================================
********Record type with nested table**********
DECLARE
    TYPE REC_TYPE IS RECORD (ENAME VARCHAR2(200), JOB VARCHAR2(200));
    TYPE NEST_TEST_TYPE IS TABLE OF REC_TYPE;
    LV_TEST NEST_TEST_TYPE;
    counter NUMBER;
BEGIN
    LV_TEST := NEST_TEST_TYPE(REC_TYPE('A' , 'JOB A'),
                              REC_TYPE('B' , 'JOB B'),
                              REC_TYPE('C' , 'JOB C'));
    counter := LV_TEST.COUNT;
    FOR i IN 1..counter
    LOOP
    DBMS_OUTPUT.PUT_LINE('ENAME : '||LV_TEST(i).ENAME||' , JOB : '||LV_TEST(i).JOB);
    END LOOP;
END;
---------------------------------------------------------------------------------------
-----------------********Record type with nested table using cursor for loop**********-----------------------------
DECLARE
    TYPE REC_TYPE IS RECORD (ENAME VARCHAR2(200),JOB VARCHAR2(200));
    TYPE NEST_TEST_TYPE IS TABLE OF REC_TYPE;
    LV_TEST NEST_TEST_TYPE := NEST_TEST_TYPE();
    counter NUMBER := 0;
    cursor cur_emp is SELECT ENAME, JOB FROM EMP;
BEGIN
    FOR I IN cur_emp
    LOOP
    LV_TEST.EXTEND();
    counter := counter + 1;
    LV_TEST(counter) := REC_TYPE(I.ENAME , I.JOB);
    DBMS_OUTPUT.PUT_LINE('Employee Name :- '||LV_TEST(counter).ename|| ' job:- '||LV_TEST(counter).job);
    END LOOP;
END;
------------------------------------------------------------------------------------------------------------
-------------------------------------Collection Method------------------------------------------------------

DECLARE
TYPE NEST_EMP_NAME IS TABLE OF VARCHAR2(1000);
LV_EMP_NAME NEST_EMP_NAME := NEST_EMP_NAME();
cnt number := 0;
--cursor cur_emp is SELECT ENAME FROM EMP;
BEGIN
FOR I IN (SELECT ENAME FROM EMP where ENAME LIKE  '%R%')
LOOP
LV_EMP_NAME.EXTEND();
cnt := cnt +1;
LV_EMP_NAME(cnt) := I.ENAME;

DBMS_OUTPUT.PUT_LINE('The '||cnt||' index value is ' || LV_EMP_NAME(cnt));
END LOOP;
DBMS_OUTPUT.PUT_LINE('Index name of 1st index is = '|| LV_EMP_NAME(LV_EMP_NAME.PRIOR(2))); /*It returns the index number that is the predecessor of the index(n) given by the user in the collection.*/
/*It returns the index number that is the successor of the index(n) given by the user in the collection.*/
DBMS_OUTPUT.PUT_LINE('Index name of 3rd index is = '|| LV_EMP_NAME(LV_EMP_NAME.NEXT(2)));
DBMS_OUTPUT.PUT_LINE('The smallest (first) index number in the collection = '|| LV_EMP_NAME.first||' and value is = '||LV_EMP_NAME(LV_EMP_NAME.first));
DBMS_OUTPUT.PUT_LINE('The largest (last) index number in the collection = '|| LV_EMP_NAME.last||' and value is = '||LV_EMP_NAME(LV_EMP_NAME.last));
DBMS_OUTPUT.PUT_LINE('The number of elements present in the collection = '|| LV_EMP_NAME.COUNT); /*It does not give us empty element count*/
/*TRIM is used to remove elements from the collection. 
TRIM removes the last element from the collection and TRIM(n) removes 
the last n element from the end of the collection.*/
--DBMS_OUTPUT.PUT_LINE('Removes the last element from the collection = '|| LV_EMP_NAME.TRIM(6));
DBMS_OUTPUT.PUT_LINE('the maximum size of the collection = '|| LV_EMP_NAME.LIMIT);  /*only worked in varray*/
END;
-------------------------------------------------------------------------------------------------------------

										------Collection Method--------
------------------------------------------------------------------------------------------------------------
/*
1.	COUNT	It returns the number of elements present in the collection
2.	FIRST	It returns the smallest (first) index number in the collection for integer subscripts
3.	LAST	It returns the largest (last) index number in the collection for integer subscripts.
4.	EXISTS(n)	It is used to check whether a particular element is present in the collection or not. It returns TRUE if the nth elements are present in the collection, FALSE if not.
5.	PRIOR(n)	It returns the index number that is the predecessor of the index(n) given by the user in the collection.
6.	NEXT(n)	It returns the index number that is the successor of the index(n) given by the user in the collection.
7.	TRIM	It is used to remove elements from the collection. TRIM removes the last element from the collection and TRIM(n) removes the last n element from the end of the collection.
8.	DELETE	It is used to remove all the elements from the given collection. It sets the collection count to 0 after removing all elements
9.	DELETE(m,n)	It is used in the case of associative arrays and indexed tables to remove all the elements in the range from m to n. It returns null if m is greater than n.
10.	LIMIT	It is used to check the maximum size of the collection.
*/
--------------record type---------------------------------------
DECLARE
TYPE REC_TYPE IS RECORD (ENAME VARCHAR2(200),JOB VARCHAR2(200) );
LV_EMP REC_TYPE;
BEGIN 
/*FOR I IN (SELECT ENAME, JOB FROM EMP)
LOOP                                                  
LV_EMP := REC_TYPE(I.ENAME , I.JOB);
DBMS_OUTPUT.PUT_LINE(LV_EMP.ename);
END LOOP;*/

SELECT ENAME, JOB 
INTO   LV_EMP FROM EMP WHERE ENAME = 'KING';
DBMS_OUTPUT.PUT_LINE(LV_EMP.ename);
DBMS_OUTPUT.PUT_LINE(LV_EMP.JOB);
END;
-----------------------------------------------------------------------------------------