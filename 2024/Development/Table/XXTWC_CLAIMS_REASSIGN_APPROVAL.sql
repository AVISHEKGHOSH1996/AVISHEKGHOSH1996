--------------------------------------------------------
--  File created - Wednesday-January-17-2024   
--------------------------------------------------------
--------------------------------------------------------
--  DDL for Table XXTWC_CLAIMS_REASSIGN_APPROVAL
--------------------------------------------------------

  CREATE TABLE "CLAIMS"."XXTWC_CLAIMS_REASSIGN_APPROVAL" 
   (	"REASSIGN_ID" NUMBER, 
	"CLAIM_ID" NUMBER, 
	"WF_NEXT_SEQ_NO" NUMBER, 
	"REASSIGN_TO" NUMBER, 
	"REASSIGN_BY" NUMBER, 
	"CREATION_DATE" DATE, 
	"CREATED_BY" VARCHAR2(255 BYTE), 
	"LAST_UPDATE_DATE" DATE, 
	"LAST_UPDATED_BY" VARCHAR2(255 BYTE), 
	"STATUS" VARCHAR2(1 BYTE), 
	"GROUP_ID" VARCHAR2(255 BYTE)
   ) SEGMENT CREATION IMMEDIATE 
  PCTFREE 10 PCTUSED 40 INITRANS 1 MAXTRANS 255 
 NOCOMPRESS LOGGING
  STORAGE(INITIAL 65536 NEXT 1048576 MINEXTENTS 1 MAXEXTENTS 2147483645
  PCTINCREASE 0 FREELISTS 1 FREELIST GROUPS 1
  BUFFER_POOL DEFAULT FLASH_CACHE DEFAULT CELL_FLASH_CACHE DEFAULT)
  TABLESPACE "CLAIMS_DATA" ;
  
  GRANT ALL ON "CLAIMS"."XXTWC_CLAIMS_REASSIGN_APPROVAL" TO "XXAPPS";
  