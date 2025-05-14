🔹 1. FUNCTION
 
Definition:
A Function in Oracle is a PL/SQL subprogram that returns a single value (scalar or object type).
 
Use Case:
Used in SQL statements or PL/SQL blocks where a return value is required (e.g., calculations, string manipulations, etc.).
 
Example:
 
CREATE OR REPLACE FUNCTION get_bonus(salary NUMBER) RETURN NUMBER IS
BEGIN
   RETURN salary * 0.1;
END;
 
Usage:
 
SELECT employee_name, get_bonus(salary) FROM employees;
 
Key Point:
Returns a single value (not a collection or table).
🔹 2. TABLE FUNCTION
 
Definition:
A Table Function returns a collection (typically a nested table or VARRAY) that can be queried like a table in SQL.
 
Use Case:
Used when you want to return a set of rows that can be treated like a table.
 
Example:
 
CREATE OR REPLACE TYPE emp_type AS OBJECT (
   emp_id   NUMBER,
   emp_name VARCHAR2(100)
);
 
CREATE OR REPLACE TYPE emp_table_type AS TABLE OF emp_type;
 
CREATE OR REPLACE FUNCTION get_employees RETURN emp_table_type PIPELINED IS
BEGIN
   -- You can populate the collection and return it
   NULL;
END;
 
Usage:
 
SELECT * FROM TABLE(get_employees());
 
Key Point:
Returns a collection of rows like a table, but the entire collection is materialized first before being returned (unless pipelined).
🔹 3. PIPELINED TABLE FUNCTION
 
Definition:
A Pipelined Table Function is a table function that returns rows one at a time (streamed), improving performance and memory efficiency for large datasets.
 
Use Case:
Used for high-performance row-wise processing, especially for ETL and transformation logic.
 
Requires:
 
    Use of the PIPELINED keyword.
 
    Use of PIPE ROW() to return individual rows.
 
Example:
 
CREATE OR REPLACE FUNCTION get_employees_pipe RETURN emp_table_type PIPELINED IS
BEGIN
   PIPE ROW(emp_type(1, 'John'));
   PIPE ROW(emp_type(2, 'Jane'));
   RETURN;
END;
 
Usage:
 
SELECT * FROM TABLE(get_employees_pipe());
 
Key Point:
Returns rows one-by-one instead of materializing the whole result set.
🔸 Summary Table
Feature	      FUNCTION	              TABLE FUNCTION	                             PIPELINED FUNCTION
Returns	   Single value	    Collection (nested table/varray)	         Collection row by row (streamed)
Use in SQL	  Yes	                  Yes	                                                  Yes
Performance	 Good	           OK (for small data sets)	                        Best (for large data sets)
Memory usage Minimal	           High (for large collections)               	Low (streaming rows)
Keyword	      RETURN	            RETURN collection_type	                 RETURN collection_type PIPELINED
Requires PIPE ROW()	No	                        No	                                          Yes