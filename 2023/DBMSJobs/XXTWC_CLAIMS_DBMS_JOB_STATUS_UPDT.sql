/****************************************************************************************************
	Object Type: 	DBMS Job and Schedule
	Name       :    XXTWC_CLAIMS_DBMS_JOB_STATUS_UPDT
	Created by:		Trinamix
	Created On:		06/01/2023
	Description:	DBMS job to call XXTWC_CLAIMS_STATUS_UPDATE_PKG.update_status to update Claims status
	                based on Sales Order status from Oracle Fusion
	Modified On:	
	Reason:		    
****************************************************************************************************/
  
/* Define the Program */
BEGIN
  dbms_scheduler.create_program(
  program_name => 'XXTWC_CLAIMS_DBMS_JOB_STATUS_UPDT',
  program_type => 'PLSQL_BLOCK',
  program_action => 'BEGIN XXTWC_CLAIMS_STATUS_UPDATE_PKG.update_status; END;',
  enabled => TRUE,
  comments => 'Program to update Claims status based on Sales Order status from Oracle Fusion');
  dbms_scheduler.enable (name=>'XXTWC_CLAIMS_DBMS_JOB_STATUS_UPDT');
END;
/

/* Define Schedule */
BEGIN
dbms_scheduler.create_schedule (
  schedule_name => 'claims_every_3min_sched',
  start_date => SYSTIMESTAMP,
  repeat_interval => 'freq=minutely; interval=3; bysecond=0',
  end_date => NULL,
  comments => 'Run every hour at 3 minutes everyday');
END;
/

/* Define DBMS Job */
BEGIN
---DBMS_SCHEDULER.DROP_JOB (job_name => 'XXTWC_CLAIMS_DBMS_JOB_STATUS_UPDT_JOB');
dbms_scheduler.create_job (
  job_name => 'XXTWC_CLAIMS_DBMS_JOB_STATUS_UPDT_JOB',
  program_name => 'XXTWC_CLAIMS_DBMS_JOB_STATUS_UPDT',
  schedule_name => 'claims_every_3min_sched',
  enabled => TRUE,
  comments => 'scheduler job for updating Claims status');
END;
/