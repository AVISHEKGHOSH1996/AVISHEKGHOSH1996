-------------------------------------BULK COLLECT USING (SELECT-INTO)------------------
DECLARE
    TYPE NT_EMP_NAME IS TABLE OF VARCHAR2(1000);
    LV_EMP_NAME NT_EMP_NAME := NT_EMP_NAME();
BEGIN
    SELECT ENAME BULK COLLECT INTO LV_EMP_NAME FROM EMP;
FOR I IN 1.. LV_EMP_NAME.COUNT 
	LOOP
		DBMS_OUTPUT.PUT_LINE(I||'.'||LV_EMP_NAME(I));
        EXIT WHEN I = 10;
	END LOOP;
END;
----------------------------------------BULK COLLECT USING (FETCH-INTO)--------------------------

DECLARE
	TYPE NT_EMP_NAME IS TABLE OF VARCHAR2(1000);
	LV_EMP_NAME NT_EMP_NAME := NT_EMP_NAME();
	CURSOR CUR_EMP 
		IS 
	SELECT ENAME FROM EMP;
BEGIN
	OPEN CUR_EMP;
LOOP
	FETCH CUR_EMP BULK COLLECT INTO LV_EMP_NAME;-- LIMIT 10;
	EXIT WHEN LV_EMP_NAME.COUNT = 0;
		FOR I IN 1.. LV_EMP_NAME.COUNT 
			LOOP
					DBMS_OUTPUT.PUT_LINE(I||'.'||LV_EMP_NAME(I));
			END LOOP;
END LOOP;
CLOSE CUR_EMP;
END;
----------------------------------------BULK COLLECT(FETCH-INTO) USING LIMIT--------------------------
DECLARE
	TYPE NT_EMP_NAME IS TABLE OF VARCHAR2(1000);
	LV_EMP_NAME NT_EMP_NAME:= NT_EMP_NAME();
	CURSOR CUR_EMP IS SELECT ENAME FROM EMP;
BEGIN
	OPEN CUR_EMP;
	FETCH CUR_EMP BULK COLLECT INTO LV_EMP_NAME LIMIT 10;
	--EXIT WHEN LV_EMP_NAME.COUNT = 0;
	CLOSE CUR_EMP;
FOR I IN 1.. LV_EMP_NAME.COUNT 
	LOOP
		DBMS_OUTPUT.PUT_LINE(I||'.'||LV_EMP_NAME(I));
	END LOOP;
END;
-------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------
---------------------------------------FORALL(INDICES OF)-----------------------------------------------------------
CREATE TABLE tut_78(
    mul_tab NUMBER(5)
);
------------------------------------------------------------------------------------------------------
DECLARE
    TYPE my_nested_table IS TABLE OF number;
    var_nt my_nested_table := my_nested_table (9,18,27,36,45,54,63,72,81,90);
    --Another variable for holding total number of record stored into the table 
    tot_rec NUMBER;
BEGIN
    --var_nt.DELETE(3, 6);
    
    FORALL idx IN INDICES OF var_nt
        INSERT INTO tut_78 (mul_tab) VALUES (var_nt(idx));
        
    SELECT COUNT (*) INTO tot_rec FROM tut_78;
    DBMS_OUTPUT.PUT_LINE ('Total records inserted are '||tot_rec);
END;