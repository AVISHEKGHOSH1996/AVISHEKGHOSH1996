--------------------------------------------------------
--  DDL for Trigger XXTWC_CLAIMS_USER_LOGIN_DETAILS_TRG
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE TRIGGER "CLAIMS"."XXTWC_CLAIMS_USER_LOGIN_DETAILS_TRG" 
  before insert or update on "XXTWC_CLAIMS_USER_LOGIN_DETAILS"               
  for each row  
begin  
IF INSERTING THEN  
if :NEW."USER_ID" is null then 
    select "XXTWC_CLAIMS_USER_LOGIN_DETAILS_SEQ".nextval into :NEW."USER_ID" from sys.dual; 
  end if; 
 :NEW.CREATION_DATE := SYSDATE;
  :NEW.CREATED_BY := NVL(V('P0_USER_ID'),9999);
  ELSIF UPDATING THEN
   :NEW.LAST_UPDATE_DATE := SYSDATE;
   :NEW.LAST_UPDATE_BY := NVL(V('P0_USER_ID'),9999);
  END IF;   
END;
/
ALTER TRIGGER "CLAIMS"."XXTWC_CLAIMS_USER_LOGIN_DETAILS_TRG" ENABLE;