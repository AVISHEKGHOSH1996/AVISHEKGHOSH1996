--------------------------------------------------------
--  DDL for Trigger XXTWC_CLAIMS_HEADERS_TRG
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE TRIGGER "CLAIMS"."XXTWC_CLAIMS_HEADERS_TRG" 
  before insert or update on "XXTWC_CLAIMS_HEADERS"               
  for each row  
begin  
IF INSERTING THEN  
if :NEW."CLAIM_ID" is null then 
    select "XXTWC_CLAIMS_HEADERS_SEQ".nextval into :NEW."CLAIM_ID" from sys.dual; 
  end if; 
    :NEW.CREATION_DATE := SYSDATE;
    :NEW.CREATED_BY := NVL(V('P0_USER_ID'),9999);
    :NEW.LAST_UPDATE_DATE := SYSDATE;
    :NEW.LAST_UPDATED_BY := NVL(V('P0_USER_ID'),9999);
  ELSIF UPDATING THEN
   :NEW.LAST_UPDATE_DATE := SYSDATE;
   :NEW.LAST_UPDATED_BY := NVL(V('P0_USER_ID'),9999);
  END IF;   
END;
/
ALTER TRIGGER "CLAIMS"."XXTWC_CLAIMS_HEADERS_TRG" ENABLE;
---------------------------------------------------------------------------------------------------------------

--------------------------------------------------------
--  DDL for Trigger XXTWC_CLAIMS_HEADERS_TRG
--  Modified On:	06/12/2023
--------------------------------------------------------

create or replace TRIGGER  "XXTWC_CLAIMS_HEADERS_TRG" 
  before insert or update on "XXTWC_CLAIMS_HEADERS"               
  for each row 
declare 
PRAGMA AUTONOMOUS_TRANSACTION ;
begin  
IF INSERTING THEN  
if :NEW."CLAIM_ID" is null then 
    select "XXTWC_CLAIMS_HEADERS_SEQ".nextval into :NEW."CLAIM_ID" from sys.dual; 
  end if; 
    :NEW.CREATION_DATE := SYSDATE;
    :NEW.CREATED_BY := NVL(V('P0_USER_ID'),9999);
    :NEW.LAST_UPDATE_DATE := SYSDATE;
    :NEW.LAST_UPDATED_BY := NVL(V('P0_USER_ID'),9999);
	--:NEW.ORA_RMA_NO := NULL;
	--:NEW.ORA_DIV_SO_NUMBER := NULL;
  ELSIF UPDATING THEN
  IF :NEW.ORA_RMA_NO IS NOT NULL AND :OLD.ORA_RMA_NO IS NULL THEN
xxtwc_claims_wf_pkg.xxtwc_insert_log(
                p_wf_id => :OLD.WF_ID, 
                p_action => 'RMA Number Created',   
                p_actioned_by => :OLD.CREATED_BY, 
                p_seq => 200,       
                p_message => 'RMA Number Created', 
                p_start_date => systimestamp, 
                p_end_date => systimestamp, 
                p_user_comments => 'RMA Number Created' ,    
                p_claim_id => :OLD.CLAIM_ID, 
                p_user_id => NULL, 
                p_group_id =>  NULL
				);
                COMMIT;
	END IF;
	IF :NEW.ORA_DIV_SO_NUMBER IS NOT NULL AND :OLD.ORA_DIV_SO_NUMBER IS NULL THEN
	
	xxtwc_claims_wf_pkg.xxtwc_insert_log(
                p_wf_id => :OLD.WF_ID, 
                p_action => 'SO Number Created',   
                p_actioned_by => :OLD.CREATED_BY, 
                p_seq => 200,       
                p_message => 'SO Number Created', 
                p_start_date => systimestamp, 
                p_end_date => systimestamp, 
                p_user_comments => 'SO Number Created' ,    
                p_claim_id => :OLD.CLAIM_ID, 
                p_user_id => NULL, 
                p_group_id =>  NULL
				);
	COMMIT;
	END IF;
   :NEW.LAST_UPDATE_DATE := SYSDATE;
   :NEW.LAST_UPDATED_BY := NVL(V('P0_USER_ID'),9999);
  END IF;   
END;
-----------------------------------------------------------------------------------------
/*Autonomous Transaction: The PRAGMA AUTONOMOUS_TRANSACTION statement allows the trigger to perform independent transactions 
without affecting the main transaction. */
