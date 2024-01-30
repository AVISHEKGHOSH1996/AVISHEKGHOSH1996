
Step 1:-

create or replace PROCEDURE  CAL_DAILY_INTEREST_JOB as 
  v_number_of_failures NUMBER(12) := 0;
BEGIN
 DESPOSITION_AMOUNT ();
END;


Step 2:-

BEGIN
  DBMS_SCHEDULER.CREATE_JOB (
   job_name           =>  'CAL_DAILY_INT',
   job_type           =>  'STORED_PROCEDURE',
   job_action         =>  'CAL_DAILY_INTEREST_JOB',
   start_date         =>  SYSDATE,
   repeat_interval    =>  'FREQ=DAILY;BYHOUR=12;BYMINUTE=30;', 
   auto_drop          =>   FALSE,
   comments           =>  'TO CALCULATE INTEREST IN DAILY BASIC');
END;


Step 3:-

BEGIN

DBMS_SCHEDULER.ENABLE('CAL_DAILY_INT');

END;

Disabled Shedular:-

begin
dbms_scheduler.disable (job_name => 'run_load_sales');
end;


Drop Shedular:-
begin
dbms_scheduler.drop_job ('CAL_DAILY_INT');
end;