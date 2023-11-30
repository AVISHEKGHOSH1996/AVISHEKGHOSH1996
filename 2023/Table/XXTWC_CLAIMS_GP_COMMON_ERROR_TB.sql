--------------------------------------------------------
--  File created - Wednesday-June-21-2023   
--------------------------------------------------------
--------------------------------------------------------
--  DDL for Table XXTWC_CLAIMS_GP_COMMON_ERROR_TB
--------------------------------------------------------

  CREATE TABLE "CLAIMS"."XXTWC_CLAIMS_GP_COMMON_ERROR_TB" 
   (	"ERROR_ID" NUMBER, 
	"ERROR_TYPE" VARCHAR2(100 BYTE), 
	"ERROR_CODE" VARCHAR2(100 BYTE), 
	"ERROR_MSG" VARCHAR2(4000 BYTE), 
	"CREATED_BY" VARCHAR2(100 BYTE), 
	"CREATED_DATE_TIME" TIMESTAMP (6), 
	"MODIFIED_BY" VARCHAR2(100 BYTE), 
	"MODIFIED_DATE_TIME" TIMESTAMP (6), 
	"PAGE_ID" NUMBER,
	"CLAIM_ID" NUMBER
   ) SEGMENT CREATION DEFERRED 
  PCTFREE 10 PCTUSED 40 INITRANS 1 MAXTRANS 255 
 NOCOMPRESS LOGGING
  TABLESPACE "CLAIMS_DATA" ;
