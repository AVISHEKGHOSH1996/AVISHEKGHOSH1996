--------------------------------------------------------
--  File created - Thursday-September-07-2023   
--------------------------------------------------------
--------------------------------------------------------
--  DDL for Table XXTWC_CLAIMS_LPN_LINES_GT
--------------------------------------------------------

  CREATE GLOBAL TEMPORARY TABLE "CLAIMS"."XXTWC_CLAIMS_LPN_LINES_GT" 
   (	"CLAIM_DTL_ID" NUMBER, 
	"CLAIM_ID" NUMBER, 
	"SHIP_QTY" NUMBER, 
	"CLAIM_QTY" NUMBER, 
	"LPN" VARCHAR2(50 BYTE), 
	"LOT_NUMBER" VARCHAR2(50 BYTE), 
	"BATCH_NUMBER" VARCHAR2(50 BYTE), 
	"HEADER_ID" VARCHAR2(100 BYTE), 
	"FULFILL_LINE_ID" VARCHAR2(100 BYTE), 
	"LPN_ROWID" VARCHAR2(100 BYTE), 
	"ORIGINAL_LPN_NUMBER" VARCHAR2(150 BYTE)
   ) ON COMMIT PRESERVE ROWS ;
