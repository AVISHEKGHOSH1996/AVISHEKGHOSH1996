/****************************************************************************************************
	Object Type: 	Sequence Creation Script
	Name       :    
	Created by:		Trinamix
	Created On:		06/01/2023
	Description:	Sequences for Claims applications
	Modified On:	
	Reason:		    
****************************************************************************************************/

-------------------------------------------------------- 
--  DDL for Sequence XXTWC_CLAIMS_APPR_GROUPS_SEQ
--------------------------------------------------------

   CREATE SEQUENCE  "CLAIMS"."XXTWC_CLAIMS_APPR_GROUPS_SEQ"  MINVALUE 1 MAXVALUE 9999999999999999999999999999 INCREMENT BY 1 START WITH 55 NOCACHE  NOORDER  NOCYCLE  NOKEEP  NOSCALE  GLOBAL ;
--------------------------------------------------------
--  DDL for Sequence XXTWC_CLAIMS_APPR_GROUP_USERS_SEQ
--------------------------------------------------------

   CREATE SEQUENCE  "CLAIMS"."XXTWC_CLAIMS_APPR_GROUP_USERS_SEQ"  MINVALUE 1 MAXVALUE 9999999999999999999999999999 INCREMENT BY 1 START WITH 378 NOCACHE  NOORDER  NOCYCLE  NOKEEP  NOSCALE  GLOBAL ;
--------------------------------------------------------
--  DDL for Sequence XXTWC_CLAIMS_APPR_WF_ACT_LOG_SEQ
--------------------------------------------------------

   CREATE SEQUENCE  "CLAIMS"."XXTWC_CLAIMS_APPR_WF_ACT_LOG_SEQ"  MINVALUE 1 MAXVALUE 9999999999999999999999999999 INCREMENT BY 1 START WITH 3076 NOCACHE  NOORDER  NOCYCLE  NOKEEP  NOSCALE  GLOBAL ;
--------------------------------------------------------
--  DDL for Sequence XXTWC_CLAIMS_APPR_WF_DETAILS_SEQ
--------------------------------------------------------

   CREATE SEQUENCE  "CLAIMS"."XXTWC_CLAIMS_APPR_WF_DETAILS_SEQ"  MINVALUE 1 MAXVALUE 9999999999999999999999999999 INCREMENT BY 1 START WITH 525 NOCACHE  NOORDER  NOCYCLE  NOKEEP  NOSCALE  GLOBAL ;
--------------------------------------------------------
--  DDL for Sequence XXTWC_CLAIMS_APPR_WF_HEADER_SEQ
--------------------------------------------------------

   CREATE SEQUENCE  "CLAIMS"."XXTWC_CLAIMS_APPR_WF_HEADER_SEQ"  MINVALUE 1 MAXVALUE 9999999999999999999999999999 INCREMENT BY 1 START WITH 38 NOCACHE  NOORDER  NOCYCLE  NOKEEP  NOSCALE  GLOBAL ;
--------------------------------------------------------
--  DDL for Sequence XXTWC_CLAIMS_APPR_LVL_HDR_SEQ
--------------------------------------------------------

   CREATE SEQUENCE   "XXTWC_CLAIMS_APPR_LVL_HDR_SEQ"  MINVALUE 1 MAXVALUE 9999999999999999999999999999 INCREMENT BY 1 START WITH 79 CACHE 20 NOORDER  NOCYCLE  NOKEEP  NOSCALE  GLOBAL ;
   
   --------------------------------------------------------
--  DDL for Sequence XXTWC_CLAIMS_APPR_LVL_DTL_SEQ
--------------------------------------------------------

   CREATE SEQUENCE   "XXTWC_CLAIMS_APPR_LVL_DTL_SEQ"  MINVALUE 1 MAXVALUE 9999999999999999999999999999 INCREMENT BY 1 START WITH 152 CACHE 20 NOORDER  NOCYCLE  NOKEEP  NOSCALE  GLOBAL ;
--------------------------------------------------------
--  DDL for Sequence XXTWC_CLAIMS_DATA_ACT_LOG_SEQ
--------------------------------------------------------

   CREATE SEQUENCE  "CLAIMS"."XXTWC_CLAIMS_DATA_ACT_LOG_SEQ"  MINVALUE 1 MAXVALUE 9999999999999999999999999999 INCREMENT BY 1 START WITH 2089 NOCACHE  NOORDER  NOCYCLE  NOKEEP  NOSCALE  GLOBAL ;
--------------------------------------------------------
--  DDL for Sequence XXTWC_CLAIMS_DOCUMENTS_SEQ
--------------------------------------------------------

   CREATE SEQUENCE  "CLAIMS"."XXTWC_CLAIMS_DOCUMENTS_SEQ"  MINVALUE 1 MAXVALUE 9999999999999999999999999999 INCREMENT BY 1 START WITH 1563 CACHE 20 NOORDER  NOCYCLE  NOKEEP  NOSCALE  GLOBAL ;
--------------------------------------------------------
--  DDL for Sequence XXTWC_CLAIMS_GEN_NUMBER_SEQ
--------------------------------------------------------

   CREATE SEQUENCE  "CLAIMS"."XXTWC_CLAIMS_GEN_NUMBER_SEQ"  MINVALUE 1 MAXVALUE 9999999999999999999999999999 INCREMENT BY 1 START WITH 1022 NOCACHE  NOORDER  NOCYCLE  NOKEEP  NOSCALE  GLOBAL ;
--------------------------------------------------------
--  DDL for Sequence XXTWC_CLAIMS_HEADERS_SEQ
--------------------------------------------------------

   CREATE SEQUENCE  "CLAIMS"."XXTWC_CLAIMS_HEADERS_SEQ"  MINVALUE 1 MAXVALUE 9999999999999999999999999999 INCREMENT BY 1 START WITH 1484 NOCACHE  NOORDER  NOCYCLE  NOKEEP  NOSCALE  GLOBAL ;
--------------------------------------------------------
--  DDL for Sequence XXTWC_CLAIMS_LINES_SEQ
--------------------------------------------------------

   CREATE SEQUENCE  "CLAIMS"."XXTWC_CLAIMS_LINES_SEQ"  MINVALUE 1 MAXVALUE 9999999999999999999999999999 INCREMENT BY 1 START WITH 303544 NOCACHE  NOORDER  NOCYCLE  NOKEEP  NOSCALE  GLOBAL ;
--------------------------------------------------------
--  DDL for Sequence XXTWC_CLAIMS_LOOKUPS_SEQ
--------------------------------------------------------

   CREATE SEQUENCE  "CLAIMS"."XXTWC_CLAIMS_LOOKUPS_SEQ"  MINVALUE 1 MAXVALUE 9999999999999999999999999999 INCREMENT BY 1 START WITH 210 NOCACHE  NOORDER  NOCYCLE  NOKEEP  NOSCALE  GLOBAL ;
--------------------------------------------------------
--  DDL for Sequence XXTWC_CLAIMS_MODULES_SEQ
--------------------------------------------------------

   CREATE SEQUENCE  "CLAIMS"."XXTWC_CLAIMS_MODULES_SEQ"  MINVALUE 1 MAXVALUE 9999999999999999999999999999 INCREMENT BY 1 START WITH 118 NOCACHE  NOORDER  NOCYCLE  NOKEEP  NOSCALE  GLOBAL ;
--------------------------------------------------------
--  DDL for Sequence XXTWC_CLAIMS_ROLE_MODULES_SEQ
--------------------------------------------------------

   CREATE SEQUENCE  "CLAIMS"."XXTWC_CLAIMS_ROLE_MODULES_SEQ"  MINVALUE 1 MAXVALUE 9999999999999999999999999999 INCREMENT BY 1 START WITH 8043 NOCACHE  NOORDER  NOCYCLE  NOKEEP  NOSCALE  GLOBAL ;
--------------------------------------------------------
--  DDL for Sequence XXTWC_CLAIMS_USER_LOGIN_DETAILS_SEQ
--------------------------------------------------------

   CREATE SEQUENCE  "CLAIMS"."XXTWC_CLAIMS_USER_LOGIN_DETAILS_SEQ"  MINVALUE 1 MAXVALUE 9999999999999999999999999999 INCREMENT BY 1 START WITH 542 CACHE 20 NOORDER  NOCYCLE  NOKEEP  NOSCALE  GLOBAL ;
--------------------------------------------------------
--  DDL for Sequence XXTWC_CLAIMS_USER_MODULES_SEQ
--------------------------------------------------------

   CREATE SEQUENCE  "CLAIMS"."XXTWC_CLAIMS_USER_MODULES_SEQ"  MINVALUE 1 MAXVALUE 9999999999999999999999999999 INCREMENT BY 1 START WITH 3 NOCACHE  NOORDER  NOCYCLE  NOKEEP  NOSCALE  GLOBAL ;
--------------------------------------------------------
--  DDL for Sequence XXTWC_CLAIMS_USER_ORG_DETAILS_SEQ
--------------------------------------------------------

   CREATE SEQUENCE  "CLAIMS"."XXTWC_CLAIMS_USER_ORG_DETAILS_SEQ"  MINVALUE 1 MAXVALUE 9999999999999999999999999999 INCREMENT BY 1 START WITH 275 NOCACHE  NOORDER  NOCYCLE  NOKEEP  NOSCALE  GLOBAL ;
--------------------------------------------------------
--  DDL for Sequence XXTWC_CLAIMS_USER_ROLES_SEQ
--------------------------------------------------------

   CREATE SEQUENCE  "CLAIMS"."XXTWC_CLAIMS_USER_ROLES_SEQ"  MINVALUE 1 MAXVALUE 9999999999999999999999999999 INCREMENT BY 1 START WITH 10152 NOCACHE  NOORDER  NOCYCLE  NOKEEP  NOSCALE  GLOBAL ;
--------------------------------------------------------
--  DDL for Sequence XXTWC_CLAIM_USERS_SEQ
--------------------------------------------------------

   CREATE SEQUENCE  "CLAIMS"."XXTWC_CLAIM_USERS_SEQ"  MINVALUE 1 MAXVALUE 9999999999999999999999999999 INCREMENT BY 1 START WITH 25 NOCACHE  NOORDER  NOCYCLE  NOKEEP  NOSCALE  GLOBAL ;

--------------------------------------------------------
--  DDL for Sequence XXTWC_CLAIM_ROLES_SEQ
--------------------------------------------------------

   CREATE SEQUENCE  "CLAIMS"."XXTWC_CLAIM_ROLES_SEQ"  MINVALUE 1 MAXVALUE 9999999999999999999999999999 INCREMENT BY 1 START WITH 9 NOCACHE  NOORDER  NOCYCLE  NOKEEP  NOSCALE  GLOBAL ;
   
--------------------------------------------------------
--  DDL for Sequence XXTWC_CLAIMS_EMAIL_TEMPLATES_SEQ
--------------------------------------------------------

   CREATE SEQUENCE  "CLAIMS"."XXTWC_CLAIMS_EMAIL_TEMPLATES_SEQ"  MINVALUE 1 MAXVALUE 9999999999999999999999999999 INCREMENT BY 1 START WITH 10 NOCACHE  NOORDER  NOCYCLE  NOKEEP  NOSCALE  GLOBAL ;
   
--------------------------------------------------------
--  DDL for Sequence XXTWC_CLAIMS_USER_MANUAL_SEQ
--------------------------------------------------------

   CREATE SEQUENCE  "CLAIMS"."XXTWC_CLAIMS_USER_MANUAL_SEQ"  MINVALUE 1 MAXVALUE 9999999999999999999999999999 INCREMENT BY 1 START WITH 6 NOCACHE  NOORDER  NOCYCLE  NOKEEP  NOSCALE  GLOBAL ;

--------------------------------------------------------
--  DDL for Sequence XXTWC_CLAIMS_GP_COMMON_ERROR_SEQ
--------------------------------------------------------
   
   CREATE SEQUENCE  "CLAIMS"."XXTWC_CLAIMS_GP_COMMON_ERROR_SEQ"  MINVALUE 0 MAXVALUE 999999999999999999999 INCREMENT BY 1 START WITH 792 NOCACHE  NOORDER  NOCYCLE  NOKEEP  NOSCALE  GLOBAL ;   
