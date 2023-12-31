--------------------------------------------------------
--  File created - Wednesday-June-21-2023   
--------------------------------------------------------
--------------------------------------------------------
--  DDL for Table XXTWC_CLAIMS_RMA_LINES_LPN_OUT
--------------------------------------------------------

  CREATE TABLE "CLAIMS"."XXTWC_CLAIMS_RMA_LINES_LPN_OUT" 
   (	"CLAIM_DTL_ID" NUMBER, 
	"CLAIM_ID" NUMBER, 
	"SHIP_QTY" NUMBER, 
	"CLAIM_QTY" NUMBER, 
	"LPN" VARCHAR2(50 BYTE), 
	"LOT_NUMBER" VARCHAR2(50 BYTE), 
	"BATCH_NUMBER" VARCHAR2(50 BYTE), 
	"HEADER_ID" VARCHAR2(100 BYTE), 
	"FULFILL_LINE_ID" VARCHAR2(100 BYTE), 
	"CREATION_DATE" TIMESTAMP (6), 
	"CREATED_BY" VARCHAR2(255 BYTE), 
	"LAST_UPDATE_DATE" TIMESTAMP (6), 
	"LAST_UPDATED_BY" VARCHAR2(255 BYTE), 
	"ATTRIBUTE1" VARCHAR2(150 BYTE), 
	"ATTRIBUTE2" VARCHAR2(150 BYTE), 
	"ATTRIBUTE3" VARCHAR2(150 BYTE), 
	"ATTRIBUTE4" VARCHAR2(150 BYTE), 
	"ATTRIBUTE5" VARCHAR2(150 BYTE), 
	"ATTRIBUTE_NUM1" NUMBER, 
	"ATTRIBUTE_NUM2" NUMBER, 
	"ATTRIBUTE_NUM3" NUMBER, 
	"ATTRIBUTE_NUM4" NUMBER, 
	"ATTRIBUTE_NUM5" NUMBER, 
	"ATTRIBUTE_DATE1" DATE, 
	"ATTRIBUTE_DATE2" DATE, 
	"ATTRIBUTE_DATE3" DATE, 
	"ATTRIBUTE_DATE4" DATE, 
	"ATTRIBUTE_DATE5" DATE, 
	"DELIVERY_NAME" VARCHAR2(150 BYTE), 
	"ORIGINAL_LPN_NUMBER" VARCHAR2(150 BYTE), 
	"ORIGINAL_LOT_NUMBER" VARCHAR2(150 BYTE)
   ) SEGMENT CREATION IMMEDIATE 
  PCTFREE 10 PCTUSED 40 INITRANS 1 MAXTRANS 255 
 NOCOMPRESS LOGGING
  STORAGE(INITIAL 65536 NEXT 1048576 MINEXTENTS 1 MAXEXTENTS 2147483645
  PCTINCREASE 0 FREELISTS 1 FREELIST GROUPS 1
  BUFFER_POOL DEFAULT FLASH_CACHE DEFAULT CELL_FLASH_CACHE DEFAULT)
  TABLESPACE "CLAIMS_DATA" ;

