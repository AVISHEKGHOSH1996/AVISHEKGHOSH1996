--------------------------------------------------------
--  File created - Wednesday-June-21-2023   
--------------------------------------------------------
--------------------------------------------------------
--  DDL for Table XXTWC_CLAIMS_APPR_WF_DETAILS
--------------------------------------------------------

  CREATE TABLE "CLAIMS"."XXTWC_CLAIMS_APPR_WF_DETAILS" 
   (	"WF_DETAIL_ID" NUMBER, 
	"WF_ID" NUMBER, 
	"SEQ" NUMBER, 
	"APPROVE_STEP" NUMBER, 
	"REJECT_STEP" NUMBER, 
	"STEP_NAME" VARCHAR2(100 BYTE), 
	"STATUS" VARCHAR2(1 BYTE), 
	"CREATION_DATE" TIMESTAMP (6), 
	"CREATED_BY" VARCHAR2(255 BYTE), 
	"LAST_UPDATE_DATE" TIMESTAMP (6), 
	"LAST_UPDATED_BY" VARCHAR2(255 BYTE), 
	"STEP_DESC" VARCHAR2(1000 BYTE)
   ) SEGMENT CREATION IMMEDIATE 
  PCTFREE 10 PCTUSED 40 INITRANS 1 MAXTRANS 255 
 NOCOMPRESS LOGGING
  STORAGE(INITIAL 65536 NEXT 1048576 MINEXTENTS 1 MAXEXTENTS 2147483645
  PCTINCREASE 0 FREELISTS 1 FREELIST GROUPS 1
  BUFFER_POOL DEFAULT FLASH_CACHE DEFAULT CELL_FLASH_CACHE DEFAULT)
  TABLESPACE "CLAIMS_DATA" ;