--------------------------------------------------------
--  File created - Wednesday-June-21-2023   
--------------------------------------------------------
--------------------------------------------------------
--  DDL for Table XXTWC_CLAIMS_APPR_GROUPS
--------------------------------------------------------

  CREATE TABLE "CLAIMS"."XXTWC_CLAIMS_APPR_GROUPS" 
   (	"GROUP_ID" NUMBER, 
	"GROUP_NAME" VARCHAR2(100 BYTE), 
	"GROUP_DESC" VARCHAR2(250 BYTE), 
	"CREATION_DATE" TIMESTAMP (6), 
	"CREATED_BY" VARCHAR2(255 BYTE), 
	"LAST_UPDATE_DATE" TIMESTAMP (6), 
	"LAST_UPDATED_BY" VARCHAR2(255 BYTE), 
	"STATUS" NUMBER
   ) SEGMENT CREATION IMMEDIATE 
  PCTFREE 10 PCTUSED 40 INITRANS 1 MAXTRANS 255 
 NOCOMPRESS LOGGING
  STORAGE(INITIAL 65536 NEXT 1048576 MINEXTENTS 1 MAXEXTENTS 2147483645
  PCTINCREASE 0 FREELISTS 1 FREELIST GROUPS 1
  BUFFER_POOL DEFAULT FLASH_CACHE DEFAULT CELL_FLASH_CACHE DEFAULT)
  TABLESPACE "CLAIMS_DATA" ;