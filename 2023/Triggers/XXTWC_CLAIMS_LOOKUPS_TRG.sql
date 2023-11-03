--------------------------------------------------------
--  DDL for Trigger XXTWC_CLAIMS_LOOKUPS_TRG
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE TRIGGER "CLAIMS"."XXTWC_CLAIMS_LOOKUPS_TRG" 
  before insert or update on "XXTWC_CLAIMS_LOOKUPS"               
  for each row  
begin  
IF INSERTING THEN  
if :NEW."LOOKUP_ID" is null then 
    select "XXTWC_CLAIMS_LOOKUPS_SEQ".nextval into :NEW."LOOKUP_ID" from sys.dual; 
  end if; 
 :NEW.CREATION_DATE := SYSDATE;
  :NEW.CREATED_BY := NVL(V('P0_USER_ID'),9999);
  ELSIF UPDATING THEN
   :NEW.LAST_UPDATE_DATE := SYSDATE;
   :NEW.LAST_UPDATED_BY := NVL(V('P0_USER_ID'),9999);
  END IF;   
END;
/
ALTER TRIGGER "CLAIMS"."XXTWC_CLAIMS_LOOKUPS_TRG" ENABLE;