--------------------------------------------------------
--  File created - Wednesday-June-21-2023   
--------------------------------------------------------
--------------------------------------------------------
--  DDL for Table XXTWC_CLAIMS_APPR_WF_ACT_LOG
--------------------------------------------------------

  CREATE TABLE "CLAIMS"."XXTWC_CLAIMS_APPR_WF_ACT_LOG" 
   (	"WF_ACTIVITY_ID" NUMBER, 
	"WF_ID" NUMBER, 
	"ACTION" VARCHAR2(100 BYTE), 
	"ACTIONED_BY" NUMBER, 
	"SEQ" NUMBER, 
	"MESSAGE" VARCHAR2(1000 BYTE), 
	"START_DATE" TIMESTAMP (6), 
	"END_DATE" TIMESTAMP (6), 
	"CLAIM_TYPE" VARCHAR2(100 BYTE), 
	"USER_COMMENTS" VARCHAR2(1000 BYTE), 
	"CLAIM_ID" NUMBER, 
	"USER_ID" VARCHAR2(250 BYTE), 
	"GROUP_ID" VARCHAR2(250 BYTE), 
	"REASSIGN_TO" NUMBER, 
	"CREATION_DATE" TIMESTAMP (6), 
	"CREATED_BY" VARCHAR2(255 BYTE), 
	"LAST_UPDATE_DATE" TIMESTAMP (6), 
	"LAST_UPDATED_BY" VARCHAR2(255 BYTE), 
	"STATUS" VARCHAR2(1 BYTE)
   ) SEGMENT CREATION IMMEDIATE 
  PCTFREE 10 PCTUSED 40 INITRANS 1 MAXTRANS 255 
 NOCOMPRESS LOGGING
  STORAGE(INITIAL 65536 NEXT 1048576 MINEXTENTS 1 MAXEXTENTS 2147483645
  PCTINCREASE 0 FREELISTS 1 FREELIST GROUPS 1
  BUFFER_POOL DEFAULT FLASH_CACHE DEFAULT CELL_FLASH_CACHE DEFAULT)
  TABLESPACE "CLAIMS_DATA" ;
