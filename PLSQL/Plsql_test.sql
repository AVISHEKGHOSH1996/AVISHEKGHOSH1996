/*Write a plsql procedure which have a out parameter that out parameter return all rows of a employee table*/
-- Create a record type
CREATE OR REPLACE TYPE emp_rec_type AS OBJECT (
    EMPNO    NUMBER,
    ENAME    VARCHAR2(100),
    JOB      VARCHAR2(100),
    MGR      NUMBER,
    HIREDATE DATE,
    SAL      NUMBER,
    COMM     NUMBER,
    DEPTNO   NUMBER
);
 
--create a collection 
CREATE OR REPLACE TYPE emp_table_type AS TABLE OF emp_rec_type;
 
--create a procedure
CREATE OR REPLACE PROCEDURE print_employee_data1(p_output OUT emp_table_type) IS
BEGIN
    SELECT emp_rec_type(EMPNO, ENAME, JOB, MGR, HIREDATE, SAL, COMM, DEPTNO)
    BULK COLLECT INTO p_output
    FROM emp;
END print_employee_data1;
 
--Call Procedure 
DECLARE
    emp_list emp_table_type;
BEGIN
    print_employee_data1(emp_list);
 
    FOR i IN 1 .. emp_list.COUNT LOOP
        DBMS_OUTPUT.PUT_LINE(
            emp_list(i).empno || ' - ' || emp_list(i).ename || ' - ' || emp_list(i).job
        );
    END LOOP;

 
END;
------------------------------------------------------------------------------------------------------------------



-------------------------------------------------------------------------------------------------------------------



CREATE OR REPLACE TYPE emp_rec_type AS OBJECT (

    EMPNO    NUMBER,

    ENAME    VARCHAR2(100),

    JOB      VARCHAR2(100),

    MGR      NUMBER,

    HIREDATE DATE,

    SAL      NUMBER,

    COMM     NUMBER,

    DEPTNO   NUMBER

);

--create a collection 

CREATE OR REPLACE TYPE emp_table_type AS TABLE OF emp_rec_type;

--create a procedure

CREATE OR REPLACE function print_employee_data2(p_output OUT emp_table_type)

return emp_table_type

IS

BEGIN

    SELECT emp_rec_type(EMPNO, ENAME, JOB, MGR, HIREDATE, SAL, COMM, DEPTNO)

    BULK COLLECT INTO p_output

    FROM emp;

    return p_output;

END print_employee_data2;
 
 
DECLARE

    emp_list emp_table_type;

    ouput emp_table_type;

BEGIN

    -- select print_employee_data2(emp_list) from dual;

    ouput := print_employee_data2(emp_list);

    FOR i IN 1 .. emp_list.COUNT LOOP

        DBMS_OUTPUT.PUT_LINE(

            emp_list(i).empno || ' - ' || emp_list(i).ename || ' - ' || emp_list(i).job

        );

    END LOOP;

END;
 

----------------------------------------------------------------------------------------------------

---------------------------------------------------------------------------------------------------------------------

INSERT INTO EMP (
    EMPNO, ENAME, JOB, MGR, HIREDATE, SAL, COMM, DEPTNO,
    CARD_COLOR, FILE_NAME, MIMETYPE, IMAGE,
    DEPT_ID, CITY, ADDRESS, SALARY
) VALUES (
    1001,                     -- EMPNO
    'AVISHEK',                 -- ENAME
    'CLERK',                 -- JOB
    7902,                    -- MGR
    TO_DATE('2023-08-15', 'YYYY-MM-DD'),  -- HIREDATE
    1500.00,                 -- SAL
    300.00,                  -- COMM
    20,                      -- DEPTNO
    EMPTY_BLOB(),            -- CARD_COLOR
    EMPTY_BLOB(),            -- FILE_NAME (can be VARCHAR2 if changed)
    EMPTY_BLOB(),            -- MIMETYPE (can be VARCHAR2 if changed)
    EMPTY_BLOB(),            -- IMAGE
    20,                      -- DEPT_ID
    'New York',              -- CITY
    '123 Wall Street',       -- ADDRESS
    1800.00                  -- SALARY
);
