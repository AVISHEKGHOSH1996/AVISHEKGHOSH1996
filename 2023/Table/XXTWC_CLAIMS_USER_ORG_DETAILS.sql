--------------------------------------------------------
--  File created - Wednesday-June-21-2023   
--------------------------------------------------------
--------------------------------------------------------
--  DDL for Table XXTWC_CLAIMS_USER_ORG_DETAILS
--------------------------------------------------------

  CREATE TABLE "CLAIMS"."XXTWC_CLAIMS_USER_ORG_DETAILS" 
   (	"USER_ORG_ID" NUMBER, 
	"ORG_ID" NUMBER, 
	"USER_ID" NUMBER, 
	"DEFAULT_ORG" VARCHAR2(1 BYTE), 
	"CREATED_BY" VARCHAR2(150 BYTE), 
	"CREATION_DATE" DATE, 
	"LAST_UPDATED_BY" VARCHAR2(150 BYTE), 
	"LAST_UPDATE_DATE" DATE, 
	"STATUS" NUMBER
   ) SEGMENT CREATION IMMEDIATE 
  PCTFREE 10 PCTUSED 40 INITRANS 1 MAXTRANS 255 
 NOCOMPRESS LOGGING
  STORAGE(INITIAL 65536 NEXT 1048576 MINEXTENTS 1 MAXEXTENTS 2147483645
  PCTINCREASE 0 FREELISTS 1 FREELIST GROUPS 1
  BUFFER_POOL DEFAULT FLASH_CACHE DEFAULT CELL_FLASH_CACHE DEFAULT)
  TABLESPACE "CLAIMS_DATA" ;