/****************************************************************************************************
	Object Type: 	Package Body
	Name       :    XXTWC_CLAIMS_WF_PKG
	Created by:		Trinamix
	Created On:		06/01/2023
	Description:	Package for Claims Approval Workflows
	Modified On:	06/12/2023
	Reason:		    Modified for Direct Approval
****************************************************************************************************/

--------------------------------------------------------
--  DDL for Package Body XXTWC_CLAIMS_WF_PKG
--------------------------------------------------------
create or replace PACKAGE BODY XXTWC_CLAIMS_WF_PKG IS

PROCEDURE XXTWC_INSERT_LOG (
    
	p_wf_id              NUMBER,
	p_seq                NUMBER,
	p_start_date         TIMESTAMP,
	p_user_comments      VARCHAR2,
	p_claim_id           NUMBER,
	p_group_id           VARCHAR2,
    p_user_id            VARCHAR2,
	p_action             VARCHAR2,
	p_actioned_by        NUMBER,
	p_message            VARCHAR2,
	p_end_date           TIMESTAMP
	) IS
	
	LV_WF_ID NUMBER := p_wf_id;
	LV_STEP_TYPE VARCHAR2(250);
	
    BEGIN
  /*Insert Data into Workflow Log Table */  
	INSERT INTO XXTWC_CLAIMS_APPR_WF_ACT_LOG (
			wf_id,
			action,
			actioned_by,
			seq,
			message,
			start_date,
			end_date,
			user_comments,
			claim_id,
			user_id,
			group_id,
            STATUS
		) VALUES (
			LV_WF_ID,
			p_action,
			p_actioned_by,
			p_seq,
			p_message,
			SYSDATE,
			p_end_date,
			p_user_comments,
			p_claim_id,
			p_user_id,
			p_group_id,
            1
		);

		COMMIT;
		
	END XXTWC_INSERT_LOG;
	
	-----------------------------------------------------------------------------------------
	
PROCEDURE XXTWC_DEPARTMENTAL_HIERARCHY_APPROVAL (
    
	p_wf_id              NUMBER,
	p_seq                NUMBER,
	p_start_date         TIMESTAMP,
	p_claim_type         VARCHAR2,
	p_user_comments      VARCHAR2,
	p_claim_id           NUMBER,
	p_group_id           VARCHAR2,
    p_user_id            VARCHAR2,
	p_action             VARCHAR2,
	p_actioned_by        NUMBER,
	p_message            VARCHAR2,
	p_end_date           TIMESTAMP,
	p_claim_amount       NUMBER
	) IS
	
	  LV_GROUP_ID  VARCHAR2(150);
	  LV_STEP_TYPE VARCHAR2(250);
	  LV_WF_ID     NUMBER := p_wf_id;
      LV_COUNT_SEQ NUMBER ;
	  LV_COUNT_GROUP_ID NUMBER;
	  LV_REJECT_STEP NUMBER;
	  LV_ORG_ID 	 NUMBER;
	  LV_DIRECT_FLAG NUMBER;
	  LV_APPR_LVL_HDR_ID NUMBER;
	  LV_ERR_MSG VARCHAR2(500);
	  lv_query  varchar2(4000);
	  LV_GROUP_NAME varchar2(4000);
	  LV_DEPARTMENT varchar2(1000);
	  LV_DEPT_CODE varchar2(1000);
	  LV_USER_ID   NUMBER;
      LV_COUNT NUMBER;
	  lv_email_count VARCHAR2(4000);
	  LV_WAREHOUSE_CODE VARCHAR2(1000);
	  lv_claim_amount NUMBER;
	  
	
    BEGIN 
    /*Get Workflow Step Info */
    BEGIN
	
	SELECT WF.REJECT_STEP, NVL(WH.DIRECT_FLAG,0),WH.APPR_LVL_HDR_ID
	INTO LV_REJECT_STEP , LV_DIRECT_FLAG,LV_APPR_LVL_HDR_ID
	FROM XXTWC_CLAIMS_APPR_WF_DETAILS WF, XXTWC_CLAIMS_APPR_WF_HEADER WH
	WHERE WF.WF_ID = WH.WF_ID
	AND WF.SEQ = p_seq
	AND WF.WF_ID = p_wf_id;
	EXCEPTION WHEN OTHERS
	THEN LV_REJECT_STEP := NULL;
	     LV_DIRECT_FLAG := 0;
		 LV_APPR_LVL_HDR_ID := NULL;
	
    END;
	
	SELECT ORG_ID,DEPARTMENT,WAREHOUSE_CODE,CLAIM_AMOUNT
	INTO LV_ORG_ID,LV_DEPARTMENT,LV_WAREHOUSE_CODE,lv_claim_amount
	FROM XXTWC_CLAIMS_HEADERS
	WHERE CLAIM_ID = p_claim_id;
	
	
	
    
	BEGIN  
    /*Getting Next Approval Level For Direct Approval*/ 
    
       BEGIN
       SELECT GROUP_ID 
				INTO 
				LV_GROUP_ID  FROM
	            (SELECT 
				GROUP_ID 
				FROM 
				XXTWC_CLAIMS_APPR_LVL_DTL ALD, XXTWC_CLAIMS_APPR_LVL_HDR ALH
	            WHERE ALD.APPR_LVL_HDR_ID = ALH.APPR_LVL_HDR_ID
				AND ALH.APPR_LVL_HDR_ID = LV_APPR_LVL_HDR_ID
				AND ((p_claim_amount <= ALD.MAX_VALUE 
				AND p_claim_amount >= (CASE WHEN ALD.ATTRIBUTE1 = 1 AND UPPER(LV_DEPARTMENT) IN ('OPERATIONS','QUALITY') THEN 0 ELSE ALD.MIN_VALUE END ))
				OR p_claim_amount > ALD.MAX_VALUE) 
				AND ALH.ORG_ID = LV_ORG_ID
				AND NOT EXISTS (SELECT 1 FROM XXTWC_CLAIMS_APPR_WF_ACT_LOG LO
				WHERE LO.SEQ = p_seq AND LO.GROUP_ID = ALD.GROUP_ID AND LO.WF_ID = p_wf_id AND LO.CLAIM_ID = p_claim_id)
				AND ALD.GROUP_ID  IS NOT NULL
				ORDER BY ALD.MAX_VALUE ASC)
				WHERE ROWNUM < 2;
				EXCEPTION WHEN OTHERS
			          THEN  LV_GROUP_ID := NULL;
        END;

	END;
    
    SELECT COUNT(1) + 1 INTO LV_COUNT
    FROM XXTWC_CLAIMS_APPR_WF_ACT_LOG
    WHERE CLAIM_ID = p_claim_id AND STATUS = 1 AND MESSAGE IN ('Departmental Hierarchy','Skip Due to User Approval limit');
    
	 IF 
	    p_action = 'Departmental Hierarchy Approval'
		THEN 
	 /*Insert Into Log Table For Approval*/
	    INSERT INTO XXTWC_CLAIMS_APPR_WF_ACT_LOG (
			wf_id,
			action,
			actioned_by,
			seq,
			message,
			start_date,
			end_date,
			claim_type,
			user_comments,
			claim_id,
			user_id,
			group_id,
			STATUS
		) VALUES (
			LV_WF_ID,
			'Department Level ' || LV_COUNT || ' Approval',
			p_actioned_by,
			p_seq,
			p_message,
			SYSDATE,
			p_end_date,
			p_claim_type,
			p_user_comments,
			p_claim_id,
			p_user_id,
			LV_GROUP_ID,
			1
		);
		COMMIT;
        BEGIN
		
lv_query:=q'#SELECT LISTAGG (GROUP_NAME, ',') FROM (
SELECT GROUP_NAME FROM XXTWC_CLAIMS_APPR_GROUPS WHERE GROUP_ID IN
(
SELECT DISTINCT result 
        FROM (
WITH RWS AS (
        SELECT GROUP_ID 
                        --INTO 
                        --LV_GROUP_ID  
                        FROM
                        (SELECT 
                        GROUP_ID 
                        FROM 
                        XXTWC_CLAIMS_APPR_LVL_DTL ALD, XXTWC_CLAIMS_APPR_LVL_HDR ALH
                        WHERE ALD.APPR_LVL_HDR_ID = ALH.APPR_LVL_HDR_ID
                        AND ALH.APPR_LVL_HDR_ID = #'||LV_APPR_LVL_HDR_ID || q'# 
                        AND ((#'||p_claim_amount|| q'#  <= ALD.MAX_VALUE        
                        AND #'||p_claim_amount|| q'#  >= (CASE WHEN ALD.ATTRIBUTE1 = 1 AND UPPER('#'||LV_DEPARTMENT|| q'#') IN ('OPERATIONS','QUALITY') THEN 0 ELSE ALD.MIN_VALUE END ))
                        OR #'||p_claim_amount|| q'#  > ALD.MAX_VALUE)  
                        AND ALH.ORG_ID = #'||LV_ORG_ID|| q'# 
                        AND NOT EXISTS (SELECT 1 FROM XXTWC_CLAIMS_APPR_WF_ACT_LOG LO
                        WHERE LO.SEQ = #'||p_seq||q'#  AND LO.GROUP_ID = ALD.GROUP_ID AND LO.WF_ID = #'||p_wf_id||q'#  AND LO.CLAIM_ID = #'||p_claim_id||q'# )
                        AND ALD.GROUP_ID  IS NOT NULL
                        ORDER BY ALD.MAX_VALUE ASC)
                        WHERE ROWNUM < 2
        )


        select regexp_substr(GROUP_ID, '[^:]+', 1, level) result
                    from RWS
                        connect by level <= length(regexp_replace(GROUP_ID, '[^:]+')) + 1)))#';
						
		
		
		EXECUTE IMMEDIATE lv_query into LV_GROUP_NAME;
		
		BEGIN

lv_email_count:=q'#SELECT COUNT(1)  
from (
SELECT DISTINCT LD.USER_ID, LD.EMAIL_ID
FROM XXTWC_CLAIMS_APPR_GROUP_USERS GU, XXTWC_CLAIMS_USER_LOGIN_DETAILS LD, XXTWC_CLAIMS_USER_ORG_DETAILS OD
WHERE GU.USER_ID = LD.USER_ID 
AND OD.USER_ID = LD.USER_ID
AND GU.STATUS = 1
AND LD.ACTIVE_FLG = 'Y'
AND LD.EMAIL_ID = (SELECT EMAIL_ID FROM XXTWC_CLAIMS_USER_LOGIN_DETAILS WHERE USER_ID = #'||p_user_id|| q'# AND ACTIVE_FLG = 'Y')
AND LD.DEPT_CODE IN (SELECT CH.DEPARTMENT FROM XXTWC_CLAIMS_HEADERS CH WHERE CH.CLAIM_ID = #'||p_claim_id|| q'#)
AND #'||LV_ORG_ID|| q'# = OD.ORG_ID 
AND EXISTS (SELECT result AS R FROM (select regexp_substr(OD.WAREHOUSE_CODE, '[^:]+', 1, level) result
			from DUAL
				connect by level <= length(regexp_replace(OD.WAREHOUSE_CODE, '[^:]+')) + 1)
                WHERE RESULT = '#'||LV_WAREHOUSE_CODE|| q'#')
AND GROUP_ID IN (
SELECT DISTINCT result 
FROM (
WITH RWS AS (
SELECT GROUP_ID 
				--INTO 
				--LV_GROUP_ID  
                FROM
	            (SELECT 
				GROUP_ID 
				FROM 
				XXTWC_CLAIMS_APPR_LVL_DTL ALD, XXTWC_CLAIMS_APPR_LVL_HDR ALH
	            WHERE ALD.APPR_LVL_HDR_ID = ALH.APPR_LVL_HDR_ID 
                AND ALH.APPR_LVL_HDR_ID = #'||LV_APPR_LVL_HDR_ID || q'#
                AND ((#'||lv_claim_amount || q'# <= ALD.MAX_VALUE        
				AND #'||lv_claim_amount || q'# >= (CASE WHEN ALD.ATTRIBUTE1 = 1 AND UPPER('#'||LV_DEPARTMENT|| q'#') IN ('OPERATIONS','QUALITY') THEN 0 ELSE ALD.MIN_VALUE END ))
				OR #'||lv_claim_amount || q'# > ALD.MAX_VALUE)  
				AND ALH.ORG_ID = #'||LV_ORG_ID || q'#
				AND NOT EXISTS (SELECT 1 FROM XXTWC_CLAIMS_APPR_WF_ACT_LOG LO
				WHERE LO.SEQ = #'||p_seq || q'# AND LO.GROUP_ID = ALD.GROUP_ID AND LO.WF_ID = #'||p_wf_id || q'# AND LO.CLAIM_ID = #'||P_CLAIM_ID || q'#)
				AND ALD.GROUP_ID  IS NOT NULL
				ORDER BY ALD.MAX_VALUE ASC)
				WHERE ROWNUM < 2
)


select regexp_substr(GROUP_ID, '[^:]+', 1, level) result
			from RWS
				connect by level <= length(regexp_replace(GROUP_ID, '[^:]+')) + 1)))#';
 
EXECUTE IMMEDIATE lv_email_count into LV_COUNT;				
	--dbms_output.put_line(LV_COUNT);	
/*EXCEPTION
WHEN OTHERS THEN
LV_COUNT := 0;*/
END;

IF LV_COUNT <> 0 THEN 
BEGIN
       SELECT GROUP_ID 
				INTO 
				LV_GROUP_ID  FROM
	            (SELECT 
				GROUP_ID 
				FROM 
				XXTWC_CLAIMS_APPR_LVL_DTL ALD, XXTWC_CLAIMS_APPR_LVL_HDR ALH
	            WHERE ALD.APPR_LVL_HDR_ID = ALH.APPR_LVL_HDR_ID
				AND ALH.APPR_LVL_HDR_ID = LV_APPR_LVL_HDR_ID
				AND ((p_claim_amount <= ALD.MAX_VALUE 
				AND p_claim_amount >= (CASE WHEN ALD.ATTRIBUTE1 = 1 AND UPPER(LV_DEPARTMENT) IN ('OPERATIONS','QUALITY') THEN 0 ELSE ALD.MIN_VALUE END ))
				OR p_claim_amount > ALD.MAX_VALUE) 
				AND ALH.ORG_ID = LV_ORG_ID
				AND NOT EXISTS (SELECT 1 FROM XXTWC_CLAIMS_APPR_WF_ACT_LOG LO
				WHERE LO.SEQ = p_seq AND LO.GROUP_ID = ALD.GROUP_ID AND LO.WF_ID = p_wf_id AND LO.CLAIM_ID = p_claim_id)
				AND ALD.GROUP_ID  IS NOT NULL
				ORDER BY ALD.MAX_VALUE ASC)
				WHERE ROWNUM < 2;
				EXCEPTION WHEN OTHERS
			          THEN  LV_GROUP_ID := NULL;
        END;
xxtwc_claims_wf_pkg.xxtwc_insert_log(
                p_wf_id => lv_wf_id,
                p_action => 'Department Level Auto Approval',
                p_actioned_by => p_user_id, 
                p_seq => 12,       
                p_message => 'Skip Due to User Approval limit',    
                p_start_date => systimestamp, 
                p_end_date => systimestamp, 
                p_user_comments => 'Auto approval based on User',  
                p_claim_id => p_claim_id, 
                p_user_id => p_user_id, 
                p_group_id => LV_GROUP_ID);
			
                EXECUTE IMMEDIATE lv_query into LV_GROUP_NAME;	

	
END IF;

BEGIN
EXECUTE IMMEDIATE lv_email_count into LV_COUNT;	
IF LV_COUNT <> 0 THEN 
BEGIN
       SELECT GROUP_ID 
				INTO 
				LV_GROUP_ID  FROM
	            (SELECT 
				GROUP_ID 
				FROM 
				XXTWC_CLAIMS_APPR_LVL_DTL ALD, XXTWC_CLAIMS_APPR_LVL_HDR ALH
	            WHERE ALD.APPR_LVL_HDR_ID = ALH.APPR_LVL_HDR_ID
				AND ALH.APPR_LVL_HDR_ID = LV_APPR_LVL_HDR_ID
				AND ((p_claim_amount <= ALD.MAX_VALUE 
				AND p_claim_amount >= (CASE WHEN ALD.ATTRIBUTE1 = 1 AND UPPER(LV_DEPARTMENT) IN ('OPERATIONS','QUALITY') THEN 0 ELSE ALD.MIN_VALUE END ))
				OR p_claim_amount > ALD.MAX_VALUE) 
				AND ALH.ORG_ID = LV_ORG_ID
				AND NOT EXISTS (SELECT 1 FROM XXTWC_CLAIMS_APPR_WF_ACT_LOG LO
				WHERE LO.SEQ = p_seq AND LO.GROUP_ID = ALD.GROUP_ID AND LO.WF_ID = p_wf_id AND LO.CLAIM_ID = p_claim_id)
				AND ALD.GROUP_ID  IS NOT NULL
				ORDER BY ALD.MAX_VALUE ASC)
				WHERE ROWNUM < 2;
				EXCEPTION WHEN OTHERS
			          THEN  LV_GROUP_ID := NULL;
        END;
xxtwc_claims_wf_pkg.xxtwc_insert_log(
                p_wf_id => lv_wf_id,
                p_action => 'Department Level Auto Approval',
                p_actioned_by => p_user_id, 
                p_seq => 12,       
                p_message => 'Skip Due to User Approval limit',    
                p_start_date => systimestamp, 
                p_end_date => systimestamp, 
                p_user_comments => 'Auto approval based on User',  
                p_claim_id => p_claim_id, 
                p_user_id => p_user_id, 
                p_group_id => LV_GROUP_ID);
			
                EXECUTE IMMEDIATE lv_query into LV_GROUP_NAME;	

	
END IF;
END ;

		
		EXCEPTION WHEN OTHERS
          THEN 
          XXTWC_CLAIMS_GP_ERROR_PKG.GP_ERROR_LOG ('Dynamic sql of Dept Approve/Reject '||LV_APPR_LVL_HDR_ID||'-' ||p_claim_amount|| '-' ||p_seq|| '-' ||p_wf_id|| '-' ||LV_ORG_ID,
                             SQLCODE,   
							 SQLERRM ||lv_email_count, 
							 V('APP_USER'),
                             35,
							 p_claim_id
                             );
		END;
		
    UPDATE XXTWC_CLAIMS_HEADERS
	SET CLAIM_SUB_STATUS = 'Awaiting Dept Approval for '|| SUBSTRB(LV_GROUP_NAME,50)
	WHERE CLAIM_ID = p_claim_id;

		COMMIT;
		
		ELSE 
  /*Insert Into Log Table For Reject*/
		INSERT INTO XXTWC_CLAIMS_APPR_WF_ACT_LOG (
			wf_id,
			action,
			actioned_by,
			seq,
			message,
			start_date,
			end_date,
			claim_type,
			user_comments,
			claim_id,
			user_id,
			group_id,
			STATUS
		)VALUES (
			LV_WF_ID,
			'Department Level ' || LV_COUNT || ' Rejection',
			p_actioned_by,
			p_seq,
			p_message,
			SYSDATE,
			p_end_date,
			p_claim_type,
			p_user_comments,
			p_claim_id,
			p_user_id,
			LV_GROUP_ID,
			1
		);
          
		  UPDATE XXTWC_CLAIMS_APPR_WF_ACT_LOG
		  SET STATUS = 0
		  WHERE CLAIM_ID = p_claim_id
		  AND SEQ = p_seq
          AND WF_ID = p_wf_id;
		  
		 UPDATE XXTWC_CLAIMS_HEADERS
	     SET WF_NEXT_SEQ_NO = LV_REJECT_STEP,
	     CLAIM_STATUS = 'Rejected',   
		 CLAIM_SUB_STATUS = 'Rejected'
	     WHERE CLAIM_ID = p_claim_id;
		 COMMIT;

		END IF;
		

    BEGIN
	   SELECT COUNT(GROUP_ID)
		    INTO LV_COUNT_GROUP_ID
		    FROM XXTWC_CLAIMS_APPR_LVL_DTL ALD, XXTWC_CLAIMS_APPR_LVL_HDR ALH
		    WHERE ALD.APPR_LVL_HDR_ID = ALH.APPR_LVL_HDR_ID 
			AND ALH.APPR_LVL_HDR_ID = LV_APPR_LVL_HDR_ID
			AND ((p_claim_amount <= ALD.MAX_VALUE 
            AND p_claim_amount >= (CASE WHEN ALD.ATTRIBUTE1 = 1 AND UPPER(LV_DEPARTMENT) IN ('OPERATIONS','QUALITY') THEN 0 ELSE ALD.MIN_VALUE END ))
            OR p_claim_amount > ALD.MAX_VALUE)
            AND ALH.ORG_ID = LV_ORG_ID;
	
	END;
	
	BEGIN
	SELECT COUNT(1)
	INTO LV_COUNT_SEQ
	FROM XXTWC_CLAIMS_APPR_WF_ACT_LOG
	WHERE SEQ = p_seq
    AND WF_ID = p_wf_id
    AND MESSAGE IS NOT NULL    -------------
    AND CLAIM_ID = p_claim_id
	AND STATUS <> 0;
	
	END;
/*Update For Final Approve*/
	IF LV_COUNT_GROUP_ID = LV_COUNT_SEQ 
	
	THEN 
	
	UPDATE xxtwc_claims_headers
            SET
                wf_next_seq_no = 13, 
                claim_status = 'Submitted',
                CLAIM_SUB_STATUS ='Pending for Finance Approval'        
            WHERE
                claim_id = p_claim_id;
	END IF;

	EXCEPTION WHEN OTHERS
          THEN 
          XXTWC_CLAIMS_GP_ERROR_PKG.GP_ERROR_LOG ('Error in Dept Approve/Reject',
                             SQLCODE,   
							 SQLERRM, 
							 V('APP_USER'),
                             35,
							 p_claim_id
                             );
	END XXTWC_DEPARTMENTAL_HIERARCHY_APPROVAL;
----------------------------------------------------------------------

PROCEDURE XXTWC_CLAIM_REVISE (
p_claim_id           IN NUMBER,
p_claim_number		 IN VARCHAR2,
p_revised_claim_id 	 OUT NUMBER
) IS
	  LV_REJECT_STEP NUMBER;
      LV_NEW_CLAIM_ID NUMBER;
	  LV_NEW_APP_SEQ NUMBER;
	  LV_REVISION_NO NUMBER;
	  LV_WF_ID		 NUMBER;
 BEGIN
 /*Get Workflow Details For Claim*/
			SELECT WF_ID , WF_NEXT_SEQ_NO 
			INTO LV_WF_ID , LV_REJECT_STEP
			FROM XXTWC_CLAIMS_HEADERS
			WHERE CLAIM_ID = p_claim_id;
/*Get New Claim Number*/			
			 SELECT (MAX(NVL(CLAIM_REVISION_NUMBER,0))+1) 
			 INTO LV_REVISION_NO 
			 FROM XXTWC_CLAIMS_HEADERS
			 WHERE CLAIM_NUMBER = (SELECT CLAIM_NUMBER FROM XXTWC_CLAIMS_HEADERS CH WHERE CH.CLAIM_ID = p_claim_id );
			 
			 SELECT XXTWC_CLAIMS_HEADERS_SEQ.NEXTVAL 
			 into LV_NEW_CLAIM_ID 
			 from DUAL;
			p_revised_claim_id := LV_NEW_CLAIM_ID;
			
			 
		BEGIN	 
			SELECT APPROVE_STEP
			INTO LV_NEW_APP_SEQ
			FROM XXTWC_CLAIMS_APPR_WF_DETAILS
			WHERE SEQ = LV_REJECT_STEP
			AND WF_ID = LV_WF_ID;
			EXCEPTION WHEN OTHERS
			THEN LV_NEW_APP_SEQ := NULL;
	
         END; 
			
	/*Copy Claim Header Data*/		
INSERT INTO XXTWC_CLAIMS_HEADERS (
 CLAIM_ID
,CLAIM_NUMBER
,CLAIM_REVISION_NUMBER
,CLAIM_DATE
,ORG_ID
,BU_NAME
,CLAIM_TYPE
,REF_CLAIM_TYPE
,ORDER_NUMBER
,ORDER_DATE
,PO_NUMBER
,SOLD_TO_CUSTOMER_ID
,SOLD_TO_CUSTOMER_NAME
,SHIP_TO_CUSTOMER_ID
,SHIP_TO_CUSTOMER_NAME
,SHIP_TO_ADDRESS1
,SHIP_TO_ADDRESS2
,SHIP_TO_ADDRESS3
,SHIP_TO_CITY
,SHIP_TO_POSTAL_CODE
,SHIP_TO_STATE
,SHIP_TO_COUNTRY
,SHIP_TO_SITE
,BILL_TO_CUSTOMER_ID
,BILL_TO_CUSTOMER_NAME
,BILL_TO_ADDRESS1
,BILL_TO_ADDRESS2
,BILL_TO_ADDRESS3
,BILL_TO_CITY
,BILL_TO_POSTAL_CODE
,BILL_TO_STATE
,BILL_TO_COUNTRY
,CLAIM_REC_DATE
,CLAIM_CURRENCY_CODE
,INSPECTION_REQUIRED
,PICTURES
,RETURN_TO_WAREHOUSE
,WAREHOUSE_CODE
,WAREHOUSE_NAME
,DIVERTED
,DIV_SOLD_TO_CUSTOMER_ID
,DIV_SOLD_TO_CUSTOMER_NAME
,DIV_SHIP_TO_CUSTOMER_ID
,DIV_SHIP_TO_CUSTOMER_NAME
,DIV_SHIP_TO_ADDRESS1
,DIV_SHIP_TO_ADDRESS2
,DIV_SHIP_TO_ADDRESS3
,DIV_SHIP_TO_CITY
,DIV_SHIP_TO_POSTAL_CODE
,DIV_SHIP_TO_STATE
,DIV_SHIP_TO_COUNTRY
,DIV_SHIP_TO_SITE
,DIV_BILL_TO_CUSTOMER_ID
,DIV_BILL_TO_CUSTOMER_NAME
,DIV_BILL_TO_ADDRESS1
,DIV_BILL_TO_ADDRESS2
,DIV_BILL_TO_ADDRESS3
,DIV_BILL_TO_CITY
,DIV_BILL_TO_POSTAL_CODE
,DIV_BILL_TO_STATE
,DIV_BILL_TO_COUNTRY
,DONATE_DUMP
,CLAIM_STATUS
,SUBMITED_BY
,SUBMITED_DATE
,LAST_UPDATED_LOGON
,ORA_RMA_NO
,ORA_RMA_STATUS
,ORA_RMA_INT_STATUS
,ORA_RMA_INT_MSG
,ORA_DIV_SO_NUMBER
,ORA_DIV_SO_STATUS
,ORA_DIV_INT_STATUS
,ORA_DIV_INT_MSG
,ORA_AP_INV_NUMBER
,ORA_AP_INV_ID
,ORA_AP_INV_INT_STATUS
,ORA_AP_INV_INT_MSG
,ATTRIBUTE1
,ATTRIBUTE2
,ATTRIBUTE3
,ATTRIBUTE4
,ATTRIBUTE5
,ATTRIBUTE_NUM1
,ATTRIBUTE_NUM2
,ATTRIBUTE_NUM3
,ATTRIBUTE_NUM4
,ATTRIBUTE_NUM5
,ATTRIBUTE_DATE1
,ATTRIBUTE_DATE2
,ATTRIBUTE_DATE3
,ATTRIBUTE_DATE4
,ATTRIBUTE_DATE5
,WF_NEXT_SEQ_NO
,WF_ID
,CLAIM_AMOUNT
,SHIP_TO_PARTY_ID
,SHIP_TO_PARTY_SITE_ID
,BILL_TO_SITE_USE_ID
,DIV_BILL_TO_SITE_USE_ID
,DIV_SHIP_TO_PARTY_ID
,DIV_SHIP_TO_PARTY_SITE_ID
,HEADER_ID
,CREATED_BY
,SUPPLIER_NAME
,SUPPLIER_SITE
,ORA_RMA_HEADER_ID
,CSR_NAME
,PREVENTABLE
,SALES_PERSON_NAME
,SALES_PERSON_ID
,ORIG_ORDER_VALUE
,CLAIM_SUB_STATUS
,CLAIM_NOTE
,DEPARTMENT
,EXPORT_ORDER
,CONSIGNMENT_ORDER
,REJECT_DUMPED
,OVERPAY
,MISSING_LOT
,SHORTPAY
)

SELECT
 LV_NEW_CLAIM_ID
,CLAIM_NUMBER
,LV_REVISION_NO
,CLAIM_DATE
,ORG_ID
,BU_NAME
,CLAIM_TYPE
,REF_CLAIM_TYPE
,ORDER_NUMBER
,ORDER_DATE
,PO_NUMBER
,SOLD_TO_CUSTOMER_ID
,SOLD_TO_CUSTOMER_NAME
,SHIP_TO_CUSTOMER_ID
,SHIP_TO_CUSTOMER_NAME
,SHIP_TO_ADDRESS1
,SHIP_TO_ADDRESS2
,SHIP_TO_ADDRESS3
,SHIP_TO_CITY
,SHIP_TO_POSTAL_CODE
,SHIP_TO_STATE
,SHIP_TO_COUNTRY
,SHIP_TO_SITE
,BILL_TO_CUSTOMER_ID
,BILL_TO_CUSTOMER_NAME
,BILL_TO_ADDRESS1
,BILL_TO_ADDRESS2
,BILL_TO_ADDRESS3
,BILL_TO_CITY
,BILL_TO_POSTAL_CODE
,BILL_TO_STATE
,BILL_TO_COUNTRY
,CLAIM_REC_DATE
,CLAIM_CURRENCY_CODE
,INSPECTION_REQUIRED
,PICTURES
,RETURN_TO_WAREHOUSE
,WAREHOUSE_CODE
,WAREHOUSE_NAME
,DIVERTED
,DIV_SOLD_TO_CUSTOMER_ID
,DIV_SOLD_TO_CUSTOMER_NAME
,DIV_SHIP_TO_CUSTOMER_ID
,DIV_SHIP_TO_CUSTOMER_NAME
,DIV_SHIP_TO_ADDRESS1
,DIV_SHIP_TO_ADDRESS2
,DIV_SHIP_TO_ADDRESS3
,DIV_SHIP_TO_CITY
,DIV_SHIP_TO_POSTAL_CODE
,DIV_SHIP_TO_STATE
,DIV_SHIP_TO_COUNTRY
,DIV_SHIP_TO_SITE
,DIV_BILL_TO_CUSTOMER_ID
,DIV_BILL_TO_CUSTOMER_NAME
,DIV_BILL_TO_ADDRESS1
,DIV_BILL_TO_ADDRESS2
,DIV_BILL_TO_ADDRESS3
,DIV_BILL_TO_CITY
,DIV_BILL_TO_POSTAL_CODE
,DIV_BILL_TO_STATE
,DIV_BILL_TO_COUNTRY
,DONATE_DUMP
,'Draft'
,SUBMITED_BY
,SUBMITED_DATE
,LAST_UPDATED_LOGON
,ORA_RMA_NO
,ORA_RMA_STATUS
,ORA_RMA_INT_STATUS
,ORA_RMA_INT_MSG
,ORA_DIV_SO_NUMBER
,ORA_DIV_SO_STATUS
,ORA_DIV_INT_STATUS
,ORA_DIV_INT_MSG
,ORA_AP_INV_NUMBER
,ORA_AP_INV_ID
,ORA_AP_INV_INT_STATUS
,ORA_AP_INV_INT_MSG
,ATTRIBUTE1
,ATTRIBUTE2
,ATTRIBUTE3
,ATTRIBUTE4
,ATTRIBUTE5
,ATTRIBUTE_NUM1
,ATTRIBUTE_NUM2
,ATTRIBUTE_NUM3
,ATTRIBUTE_NUM4
,ATTRIBUTE_NUM5
,ATTRIBUTE_DATE1
,ATTRIBUTE_DATE2
,ATTRIBUTE_DATE3
,ATTRIBUTE_DATE4
,ATTRIBUTE_DATE5
,LV_NEW_APP_SEQ
,WF_ID
,CLAIM_AMOUNT
,SHIP_TO_PARTY_ID
,SHIP_TO_PARTY_SITE_ID
,BILL_TO_SITE_USE_ID
,DIV_BILL_TO_SITE_USE_ID
,DIV_SHIP_TO_PARTY_ID
,DIV_SHIP_TO_PARTY_SITE_ID
,HEADER_ID
,CREATED_BY
,SUPPLIER_NAME
,SUPPLIER_SITE
,ORA_RMA_HEADER_ID
,CSR_NAME
,PREVENTABLE
,SALES_PERSON_NAME
,SALES_PERSON_ID
,ORIG_ORDER_VALUE
,'Draft'
,CLAIM_NOTE
,DEPARTMENT
,EXPORT_ORDER
,CONSIGNMENT_ORDER
,REJECT_DUMPED
,OVERPAY
,NULL
,SHORTPAY
FROM XXTWC_CLAIMS_HEADERS
WHERE CLAIM_ID = p_claim_id;


FOR I IN(
SELECT 
XXTWC_CLAIMS_LINES_SEQ.NEXTVAL AS SEQ
,CLAIM_DTL_ID
,CLAIM_LINE_NO
,INVENTORY_ITEM_ID
,INVENTORY_ITEM_NAME
,INVENTORY_ITEM_DESC
,UOM
,SHIP_QTY
,CLAIM_QTY
,UNIT_LIST_PRICE
,UNIT_SELLING_PRICE
,UNIT_ADJUSTMENT_PRICE
,EXTENDED_AMOUNT
,FRIGHT_CHARGES
,ITEM_VARIETY
,ITEM_REGION
,ITEM_COUNTRY_OF_ORIG
,CLAIM_REASON_CODE
,ORA_RMA_LINE_ID
,ORA_RMA_LINE_STATUS
,ORA_SO_LINE_ID
,ORA_SO_LINE_STATUS
,ATTRIBUTE1
,ATTRIBUTE2
,ATTRIBUTE3
,ATTRIBUTE4
,ATTRIBUTE5
,ATTRIBUTE_NUM1
,ATTRIBUTE_NUM2
,ATTRIBUTE_NUM3
,ATTRIBUTE_NUM4
,ATTRIBUTE_NUM5
,ATTRIBUTE_DATE1
,ATTRIBUTE_DATE2
,ATTRIBUTE_DATE3
,ATTRIBUTE_DATE4
,ATTRIBUTE_DATE5
,GL_ACCOUNT
,FULFILLMENT_LINE_ID
,RETURNABLE_QTY
,ADJ_PRICE_DIFFERENCE
,UNIT_NEW_PRICE
,UNIT_REBILL_PRICE
,UNIT_FINALBILL_PRICE
,SHIP_DATE
,OVERPAY_PRICE
FROM XXTWC_CLAIMS_LINES
WHERE CLAIM_ID = p_claim_id
)
LOOP
/*Copy Claim Lines Data*/
INSERT INTO XXTWC_CLAIMS_LINES(
CLAIM_DTL_ID
,CLAIM_ID
,CLAIM_LINE_NO
,INVENTORY_ITEM_ID
,INVENTORY_ITEM_NAME
,INVENTORY_ITEM_DESC
,UOM
,SHIP_QTY
,CLAIM_QTY
,UNIT_LIST_PRICE
,UNIT_SELLING_PRICE
,UNIT_ADJUSTMENT_PRICE
,EXTENDED_AMOUNT
,FRIGHT_CHARGES
,ITEM_VARIETY
,ITEM_REGION
,ITEM_COUNTRY_OF_ORIG
,CLAIM_REASON_CODE
,ORA_RMA_LINE_ID
,ORA_RMA_LINE_STATUS
,ORA_SO_LINE_ID
,ORA_SO_LINE_STATUS
,ATTRIBUTE1
,ATTRIBUTE2
,ATTRIBUTE3
,ATTRIBUTE4
,ATTRIBUTE5
,ATTRIBUTE_NUM1
,ATTRIBUTE_NUM2
,ATTRIBUTE_NUM3
,ATTRIBUTE_NUM4
,ATTRIBUTE_NUM5
,ATTRIBUTE_DATE1
,ATTRIBUTE_DATE2
,ATTRIBUTE_DATE3
,ATTRIBUTE_DATE4
,ATTRIBUTE_DATE5
,GL_ACCOUNT
,FULFILLMENT_LINE_ID
,RETURNABLE_QTY
,ADJ_PRICE_DIFFERENCE
,UNIT_NEW_PRICE
,UNIT_REBILL_PRICE
,UNIT_FINALBILL_PRICE
,SHIP_DATE
,OVERPAY_PRICE
)
SELECT 
I.SEQ
,LV_NEW_CLAIM_ID
,I.CLAIM_LINE_NO
,I.INVENTORY_ITEM_ID
,I.INVENTORY_ITEM_NAME
,I.INVENTORY_ITEM_DESC
,I.UOM
,I.SHIP_QTY
,I.CLAIM_QTY
,I.UNIT_LIST_PRICE
,I.UNIT_SELLING_PRICE
,I.UNIT_ADJUSTMENT_PRICE
,I.EXTENDED_AMOUNT
,I.FRIGHT_CHARGES
,I.ITEM_VARIETY
,I.ITEM_REGION
,I.ITEM_COUNTRY_OF_ORIG
,I.CLAIM_REASON_CODE
,I.ORA_RMA_LINE_ID
,I.ORA_RMA_LINE_STATUS
,I.ORA_SO_LINE_ID
,I.ORA_SO_LINE_STATUS
,I.ATTRIBUTE1
,I.ATTRIBUTE2
,I.ATTRIBUTE3
,I.ATTRIBUTE4
,I.ATTRIBUTE5
,I.ATTRIBUTE_NUM1
,I.ATTRIBUTE_NUM2
,I.ATTRIBUTE_NUM3
,I.ATTRIBUTE_NUM4
,I.ATTRIBUTE_NUM5
,I.ATTRIBUTE_DATE1
,I.ATTRIBUTE_DATE2
,I.ATTRIBUTE_DATE3
,I.ATTRIBUTE_DATE4
,I.ATTRIBUTE_DATE5
,I.GL_ACCOUNT
,I.FULFILLMENT_LINE_ID
,I.RETURNABLE_QTY
,I.ADJ_PRICE_DIFFERENCE
,I.UNIT_NEW_PRICE
,I.UNIT_REBILL_PRICE
,I.UNIT_FINALBILL_PRICE
,I.SHIP_DATE
,I.OVERPAY_PRICE
FROM XXTWC_CLAIMS_LINES
WHERE CLAIM_ID = p_claim_id
AND CLAIM_DTL_ID = I.CLAIM_DTL_ID;

/*Copy Claim LPN Lines Data*/
INSERT INTO XXTWC_CLAIMS_LPN_LINES(
CLAIM_DTL_ID
,CLAIM_ID
,SHIP_QTY
,CLAIM_QTY
,LPN
,LOT_NUMBER
,BATCH_NUMBER
,HEADER_ID
,FULFILL_LINE_ID
,ATTRIBUTE1
,ATTRIBUTE2
,ATTRIBUTE3
,ATTRIBUTE4
,ATTRIBUTE5
,ATTRIBUTE_NUM1
,ATTRIBUTE_NUM2
,ATTRIBUTE_NUM3
,ATTRIBUTE_NUM4
,ATTRIBUTE_NUM5
,ATTRIBUTE_DATE1
,ATTRIBUTE_DATE2
,ATTRIBUTE_DATE3
,ATTRIBUTE_DATE4
,ATTRIBUTE_DATE5
,DELIVERY_NAME
,ORIGINAL_LOT_NUMBER
,ORIGINAL_LPN_NUMBER
,RANCH_BLOCK
,POOL_NUMBER
,PACK_DATE
)
SELECT
I.SEQ
,LV_NEW_CLAIM_ID
,SHIP_QTY
,CLAIM_QTY
,LPN
,LOT_NUMBER
,BATCH_NUMBER
,HEADER_ID
,FULFILL_LINE_ID
,ATTRIBUTE1
,ATTRIBUTE2
,ATTRIBUTE3
,ATTRIBUTE4
,ATTRIBUTE5
,ATTRIBUTE_NUM1
,ATTRIBUTE_NUM2
,ATTRIBUTE_NUM3
,ATTRIBUTE_NUM4
,ATTRIBUTE_NUM5
,ATTRIBUTE_DATE1
,ATTRIBUTE_DATE2
,ATTRIBUTE_DATE3
,ATTRIBUTE_DATE4
,ATTRIBUTE_DATE5
,DELIVERY_NAME
,ORIGINAL_LOT_NUMBER
,ORIGINAL_LPN_NUMBER
,RANCH_BLOCK
,POOL_NUMBER
,PACK_DATE
FROM XXTWC_CLAIMS_LPN_LINES
WHERE CLAIM_ID = p_claim_id
AND CLAIM_DTL_ID = I.CLAIM_DTL_ID;

END LOOP;

/*Copy Claim Documents Data*/
INSERT INTO XXTWC_CLAIMS_DOCUMENTS(
CLAIM_DOC_ID
,CLAIM_ID
,CLAIM_DTL_ID
,FILE_ID
,DOCUMENT_CATEGORY
,FILE_NAME
,FILE_EXT
,FILE_COMMENT
,STATUS
)
SELECT 
XXTWC_CLAIMS_DOCUMENTS_SEQ.NEXTVAL
,LV_NEW_CLAIM_ID
,CLAIM_DTL_ID
,FILE_ID
,DOCUMENT_CATEGORY
,FILE_NAME
,FILE_EXT
,FILE_COMMENT
,STATUS

FROM XXTWC_CLAIMS_DOCUMENTS
WHERE CLAIM_ID = p_claim_id;

EXCEPTION WHEN OTHERS
          THEN 
          XXTWC_CLAIMS_GP_ERROR_PKG.GP_ERROR_LOG ('Error in Revise Claim',
                             SQLCODE,   
							 SQLERRM, 
							 V('APP_USER'),
                             23,
							 p_claim_id
                             );
END XXTWC_CLAIM_REVISE;

PROCEDURE XXTWC_CALL_WF_FOR_SUBMIT_CLAIM (
	p_claim_id           NUMBER
	) IS
	
    lv_max_value       NUMBER;
    lv_min_value       NUMBER;
    lv_wf_id           NUMBER;
    lv_claim_amount    NUMBER;
    lv_org_id          NUMBER;
    lv_appr_lvl_hdr_id NUMBER;
    l_error            VARCHAR2(2000);
	lv_query           VARCHAR2(4000);
	LV_GROUP_NAME      VARCHAR2(4000);
	LV_DIRECT_FLAG     NUMBER;
	LV_DEPARTMENT      VARCHAR2(1000);
	LV_SALESMANAGER    VARCHAR2(1000);
	LV_GROUP_ID        VARCHAR2(1000);
	LV_CLAIM_TYPE      VARCHAR2(1000);
    LV_CLAIM_NUMBER    VARCHAR2(1000);
    LV_CLAIM_REVISION_NUMBER NUMBER;
	LV_MISSING_LOT VARCHAR2(1);
BEGIN
    SELECT
        ch.wf_id,
        ch.claim_amount,
        ch.org_id,
        wh.appr_lvl_hdr_id,
        NVL(WH.DIRECT_FLAG,0),
		DEPARTMENT,
		SALESMANAGER,
		ch.CLAIM_TYPE,
        ch.CLAIM_NUMBER,
        ch.CLAIM_REVISION_NUMBER,
		ch.MISSING_LOT
    INTO
        lv_wf_id,
        lv_claim_amount,
        lv_org_id,
        lv_appr_lvl_hdr_id,
        LV_DIRECT_FLAG,
		LV_DEPARTMENT,
		LV_SALESMANAGER,
		LV_CLAIM_TYPE,
        LV_CLAIM_NUMBER,
        LV_CLAIM_REVISION_NUMBER,
		LV_MISSING_LOT
    FROM
        xxtwc_claims_headers ch,
        xxtwc_claims_appr_wf_header wh
    WHERE
            ch.wf_id = wh.wf_id
        AND claim_id = p_claim_id;
		
		
		

    BEGIN
        xxtwc_claims_wf_pkg.xxtwc_insert_log(
            p_wf_id => lv_wf_id, 
            p_action => 'Review Claim and Submit', 
            p_actioned_by => V('P0_USER_ID'),
            p_seq => 10, 
            p_message => 'Review Claim and Submit',
            p_start_date => systimestamp,
            p_end_date => systimestamp,
            p_user_comments => 'Claim Submitted',
            p_claim_id => p_claim_id,
            p_user_id => NULL,
            p_group_id => NULL
        );
		IF
            LV_MISSING_LOT = 'Y'  THEN
        
			xxtwc_claims_wf_pkg.xxtwc_insert_log(
            p_wf_id => lv_wf_id, 
            p_action => 'Missing Lot Details Added', 
            p_actioned_by => V('P0_USER_ID'),
            p_seq => 10, 
            p_message => 'Missing Lot Details Added',
            p_start_date => systimestamp,
            p_end_date => systimestamp,
            p_user_comments => 'Missing Lot Details Added',
            p_claim_id => p_claim_id,
            p_user_id => NULL,
            p_group_id => NULL
        );
		
UPDATE xxtwc_claims_headers
            SET
                wf_next_seq_no = 10.1, 
                claim_status = 'Submitted',
                CLAIM_SUB_STATUS = 'Pending for Import Claim Owner Approval'                 
            WHERE
                claim_id = p_claim_id;
		ELSE
		
		IF LV_CLAIM_TYPE <> 'A_MINUS'  THEN

        BEGIN
            SELECT
                ald.max_value
            INTO lv_max_value
            FROM
                xxtwc_claims_appr_lvl_dtl ald,
                xxtwc_claims_appr_lvl_hdr alh
            WHERE
                    ald.appr_lvl_hdr_id = alh.appr_lvl_hdr_id
                AND alh.appr_lvl_hdr_id = lv_appr_lvl_hdr_id
                AND nvl(ald.min_value, 0) = 0
                AND alh.org_id = lv_org_id; 

        EXCEPTION
            WHEN OTHERS THEN
                lv_max_value := 0;
        END;
		
         IF lv_max_value >= lv_claim_amount AND LV_DEPARTMENT NOT IN ('OPERATIONS','QUALITY') AND LV_CLAIM_TYPE <> 'RETURN_INVENTORY' THEN
        
			xxtwc_claims_wf_pkg.xxtwc_insert_log(
            p_wf_id => lv_wf_id, 
            p_action => 'Fast Track Claim Auto Approval', 
            p_actioned_by => V('P0_USER_ID'),
            p_seq => 10, 
            p_message => 'Fast Track Claim Auto Approval',
            p_start_date => systimestamp,
            p_end_date => systimestamp,
            p_user_comments => 'Fast Track Claim Auto Approval',
            p_claim_id => p_claim_id,
            p_user_id => NULL,
            p_group_id => NULL
        );
			UPDATE xxtwc_claims_headers
            SET
                wf_next_seq_no = 13, 
                claim_status = 'Submitted',
                CLAIM_SUB_STATUS ='Pending for Finance Approval'        
            WHERE
                claim_id = p_claim_id; 
	ELSIF
            LV_CLAIM_TYPE = 'RETURN_INVENTORY'  THEN
        
			xxtwc_claims_wf_pkg.xxtwc_insert_log(
            p_wf_id => lv_wf_id, 
            p_action => 'Claim Auto Approval', 
            p_actioned_by => V('P0_USER_ID'),
            p_seq => 10, 
            p_message => 'Claim Auto Approval',
            p_start_date => systimestamp,
            p_end_date => systimestamp,
            p_user_comments => 'Claim Auto Approval',
            p_claim_id => p_claim_id,
            p_user_id => NULL,
            p_group_id => NULL
        );
		
			UPDATE xxtwc_claims_headers
            SET
                wf_next_seq_no = 14, 
                claim_status = 'Approved', 
                CLAIM_SUB_STATUS ='Awaiting RMA/Claims Creation'     
            WHERE
                claim_id = p_claim_id; 
				
				
   
	ELSE
	UPDATE xxtwc_claims_headers
            SET
                wf_next_seq_no = 11, 
                claim_status = 'Submitted',
                CLAIM_SUB_STATUS ='Pending for Claim Owner Approval'    
            WHERE
                claim_id = p_claim_id; 
		
		END IF;
		

ELSE
	/*UPDATE xxtwc_claims_headers
            SET
                wf_next_seq_no = 11, 
                claim_status = 'Draft',
                CLAIM_SUB_STATUS ='Draft'    
            WHERE
                claim_id = p_claim_id;*/
      BEGIN
            SELECT
                ald.max_value
            INTO lv_max_value
            FROM
                xxtwc_claims_appr_lvl_dtl ald,
                xxtwc_claims_appr_lvl_hdr alh
            WHERE
                    ald.appr_lvl_hdr_id = alh.appr_lvl_hdr_id
                AND alh.appr_lvl_hdr_id = lv_appr_lvl_hdr_id
                AND nvl(ald.min_value, 0) = 0
                AND alh.org_id = lv_org_id; 

        EXCEPTION
            WHEN OTHERS THEN
                lv_max_value := 0;
        END;
         
        IF lv_max_value >= lv_claim_amount AND LV_DEPARTMENT NOT IN ('OPERATIONS','QUALITY') THEN
        
			UPDATE xxtwc_claims_headers
            SET
                wf_next_seq_no = 13, 
                claim_status = 'Submitted',
                CLAIM_SUB_STATUS ='Submitted'        
            WHERE
                claim_id = p_claim_id; 
			
	ELSE
	UPDATE xxtwc_claims_headers
            SET
                wf_next_seq_no = 11, 
                claim_status = 'Submitted',
                CLAIM_SUB_STATUS ='Submitted'    
            WHERE
                claim_id = p_claim_id; 
		
		END IF;           
END IF;

    END IF;
	
    BEGIN
    IF LV_CLAIM_REVISION_NUMBER > 1 THEN
    XXTWC_CLAIMS_WF_PKG.XXTWC_CHANGES_AFTER_REVISE_CLAIM(
    P_CLAIM_ID => p_claim_id 
    );
    END IF;
    END;
            
    END;
EXCEPTION WHEN OTHERS
          THEN 
          XXTWC_CLAIMS_GP_ERROR_PKG.GP_ERROR_LOG ('Call Workflow for Submit Claim',
                             SQLCODE,   
							 SQLERRM, 
							 V('APP_USER'),
                             7,
							 p_claim_id
                             );

END XXTWC_CALL_WF_FOR_SUBMIT_CLAIM;


PROCEDURE XXTWC_FINANCE_APPROVAL (
	p_wf_id              NUMBER,
	p_seq                NUMBER,
	p_start_date         TIMESTAMP,
	p_claim_type         VARCHAR2,
	p_user_comments      VARCHAR2,
	p_claim_id           NUMBER,
	p_group_id           VARCHAR2,
    p_user_id            VARCHAR2,
	p_action             VARCHAR2,
	p_actioned_by        NUMBER,
	p_message            VARCHAR2,
	p_end_date           TIMESTAMP,
	p_claim_amount       NUMBER
	) IS
	
	
    lv_wf_id           NUMBER;
    lv_claim_amount    NUMBER;
    lv_org_id          NUMBER;
    lv_appr_lvl_hdr_id NUMBER;
    l_error            VARCHAR2(2000);
	LV_GROUP_ID        VARCHAR2(1000);
	LV_SUPER_APPROVER  NUMBER;
	
	
	
	BEGIN
    SELECT
        ch.wf_id,
        ch.claim_amount,
        ch.org_id,
        wh.appr_lvl_hdr_id
		
     
    INTO
        lv_wf_id,
        lv_claim_amount,
        lv_org_id,
        lv_appr_lvl_hdr_id    
        
    FROM
        xxtwc_claims_headers ch,
        xxtwc_claims_appr_wf_header wh
    WHERE
            ch.wf_id = wh.wf_id
        AND claim_id = p_claim_id;
	
		
		SELECT COUNT(1) INTO LV_SUPER_APPROVER 
    FROM XXTWC_CLAIMS_ROLES CR,XXTWC_CLAIMS_USER_ROLES UR 
                WHERE CR.ROLE_ID = UR.ROLE_ID
				AND CR.ROLE_NAME = 'Super Approver'
                AND USER_ID = p_user_id;
	
	/*Getting Next Approval Level For Finance Approval*/
	
	BEGIN
SELECT GROUP_ID 
				INTO LV_GROUP_ID
				FROM 
				XXTWC_CLAIMS_APPR_LVL_DTL ALD, XXTWC_CLAIMS_APPR_LVL_HDR ALH
	            WHERE ALD.APPR_LVL_HDR_ID = ALH.APPR_LVL_HDR_ID
				AND HIERARCHY_NAME = 'Finance'
				AND lv_claim_amount BETWEEN ALD.MIN_VALUE AND ALD.MAX_VALUE 
				AND ALH.ORG_ID = LV_ORG_ID
				AND ALD.GROUP_ID  IS NOT NULL
				;
				EXCEPTION WHEN OTHERS
				          THEN  LV_GROUP_ID := NULL;
    END;  

               IF p_action = 'Finance Approved'
		       THEN 
               xxtwc_claims_wf_pkg.xxtwc_insert_log(
                p_wf_id => lv_wf_id,
                p_action => p_action,                    
                p_actioned_by => p_actioned_by, 
                p_seq => p_seq,      
                p_message => p_message,    
                p_start_date => systimestamp, 
                p_end_date => systimestamp, 
                p_user_comments => (CASE WHEN p_user_comments IS NULL 
				AND LV_SUPER_APPROVER > 0
				THEN 'Claim approval performed by Super Approver role'
                ELSE  p_user_comments 
                END),			 
                p_claim_id => p_claim_id, 
                p_user_id => p_user_id, 
                p_group_id => p_user_id  
            );	

			UPDATE xxtwc_claims_headers
            SET
                wf_next_seq_no = 14, 
                claim_status = 'Approved', 
                CLAIM_SUB_STATUS ='Awaiting RMA/Claims Creation'        
            WHERE
                claim_id = p_claim_id; 
				
				BEGIN
                xxtwc_claims_outbound_pkg.main_proc(p_claim_id,l_error);
                IF l_error IS NOT NULL THEN
                    raise_application_error('-20000',l_error);
                    apex_error.add_error (
                        p_message          => l_error,
                        p_display_location => apex_error.c_inline_in_notification 
                    );
                END IF;

            END;
			ELSE
			
	        UPDATE xxtwc_claims_headers
            SET
			wf_next_seq_no = 15, 
            claim_status = 'Rejected',  
            CLAIM_SUB_STATUS ='Rejected'     
            WHERE
                claim_id = p_claim_id;  
            
             xxtwc_claims_wf_pkg.xxtwc_insert_log(
                p_wf_id => lv_wf_id,
                p_action => p_action,  
                p_actioned_by => p_actioned_by, 
                p_seq => p_seq,       
                p_message => p_message,    
                p_start_date => systimestamp, 
                p_end_date => systimestamp, 
                p_user_comments => p_user_comments,    
                p_claim_id => p_claim_id, 
                p_user_id => p_user_id, 
                p_group_id => p_group_id  
            );	
            
          UPDATE XXTWC_CLAIMS_APPR_WF_ACT_LOG
		  SET STATUS = 0
		  WHERE CLAIM_ID = p_claim_id
		  AND SEQ = p_seq
          AND WF_ID = p_wf_id;			
		  END IF;
		EXCEPTION WHEN OTHERS
          THEN 
          XXTWC_CLAIMS_GP_ERROR_PKG.GP_ERROR_LOG ('Error in Finance Approve/Reject',
                             SQLCODE,   
							 SQLERRM, 
							 V('APP_USER'),
                             35,
							 p_claim_id
                             );
END XXTWC_FINANCE_APPROVAL;

PROCEDURE XXTWC_CLAIM_OWNER_APPROVAL (
	p_wf_id              NUMBER,
	p_seq                NUMBER,
	p_start_date         TIMESTAMP,
	p_claim_type         VARCHAR2,
	p_user_comments      VARCHAR2,
	p_claim_id           NUMBER,
	p_group_id           VARCHAR2,
    p_user_id            VARCHAR2,
	p_action             VARCHAR2,
	p_actioned_by        NUMBER,
	p_message            VARCHAR2,
	p_end_date           TIMESTAMP,
	p_claim_amount       NUMBER
	) IS
	
	
    lv_wf_id           NUMBER;
    lv_claim_amount    NUMBER;
    lv_org_id          NUMBER;
    lv_appr_lvl_hdr_id NUMBER;
    l_error            VARCHAR2(2000);
	LV_GROUP_ID        VARCHAR2(1000);
    LV_SALESMANAGER    VARCHAR2(1000);
	LV_USER_APPROVAL_AMOUNT NUMBER;
	LV_DEPARTMENT      VARCHAR2(2000);
	LV_DEPT_CODE       VARCHAR2(2000);
	LV_SALESMANAGER_ID NUMBER;
	LV_USER_ID         NUMBER;
	LV_CLAIM_ID        NUMBER;
    LV_SUPER_APPROVER  NUMBER;
    
	BEGIN
    SELECT
        ch.wf_id,
        ch.claim_amount,
        ch.org_id,
        wh.appr_lvl_hdr_id,
		SALESMANAGER,
		CLAIM_ID,
		DEPARTMENT
    INTO
        lv_wf_id,
        lv_claim_amount,
        lv_org_id,
        lv_appr_lvl_hdr_id,
		LV_SALESMANAGER,
		LV_CLAIM_ID,
		LV_DEPARTMENT
    FROM
        xxtwc_claims_headers ch,
        xxtwc_claims_appr_wf_header wh
    WHERE
            ch.wf_id = wh.wf_id
        AND claim_id = p_claim_id;
		
		
		BEGIN
        SELECT
        L.ACTIONED_BY 
        INTO 
        LV_USER_ID
        FROM XXTWC_CLAIMS_APPR_WF_ACT_LOG L
        WHERE  L.CLAIM_ID = LV_CLAIM_ID AND "ACTION" = 'Review Claim and Submit'
        AND L.STATUS <> 0;
    EXCEPTION
        WHEN OTHERS THEN
        LV_USER_ID := NULL;
    END;
		
	SELECT COUNT(1) INTO LV_SUPER_APPROVER 
    FROM XXTWC_CLAIMS_ROLES CR,XXTWC_CLAIMS_USER_ROLES UR 
                WHERE CR.ROLE_ID = UR.ROLE_ID
				AND CR.ROLE_NAME = 'Super Approver'
                AND USER_ID = p_user_id;   ---LV_USER_ID;
	
	
	
	SELECT DEPT_CODE
	INTO LV_DEPT_CODE
	FROM XXTWC_CLAIMS_USER_LOGIN_DETAILS
	WHERE USER_ID = LV_USER_ID
    AND ACTIVE_FLG = 'Y';
	
	 SELECT NVL(MAX(ALD.MAX_VALUE),0)
	INTO 
	LV_USER_APPROVAL_AMOUNT
	FROM XXTWC_CLAIMS_APPR_LVL_DTL ALD,XXTWC_CLAIMS_APPR_LVL_HDR ALH
	WHERE  ALD.APPR_LVL_HDR_ID = ALH.APPR_LVL_HDR_ID
	AND ALH.APPR_LVL_HDR_ID = LV_APPR_LVL_HDR_ID
    AND ALH.ORG_ID = LV_ORG_ID
    AND ALH.HIERARCHY_NAME <> 'Finance'
     AND EXISTS (SELECT AGU.GROUP_ID FROM XXTWC_CLAIMS_APPR_GROUP_USERS AGU
    WHERE AGU.USER_ID = LV_USER_ID AND AGU.STATUS = 1 AND AGU.GROUP_ID IN (select regexp_substr(ALD.GROUP_ID, '[^:]+', 1, level) RESULT
    from dual
    connect by level <= length(regexp_replace(ALD.GROUP_ID, '[^:]+')) + 1));
	
	BEGIN
	SELECT USER_ID
	INTO LV_SALESMANAGER_ID 
	FROM XXTWC_CLAIMS_USER_LOGIN_DETAILS
	WHERE UPPER(EMAIL_ID) = UPPER(LV_SALESMANAGER)
    AND ACTIVE_FLG = 'Y';
	EXCEPTION WHEN OTHERS THEN 
	LV_SALESMANAGER_ID := NULL;
	END;
		
	IF LV_SALESMANAGER_ID IS NULL 
		THEN
	     SELECT GROUP_ID
	     INTO LV_GROUP_ID
         FROM   XXTWC_CLAIMS_APPR_GROUPS 
         WHERE GROUP_NAME = 'Claim Owner';
	ELSE
	LV_GROUP_ID := NULL;
	END IF;
	
	IF p_action = 'Claim Owner Approval'
		       THEN 
               /*xxtwc_claims_wf_pkg.xxtwc_insert_log(
                p_wf_id => lv_wf_id,
                p_action => p_action,                    ---Sold to customer manager Approval
                p_actioned_by => p_actioned_by, 
                p_seq => p_seq,       --11
                p_message => p_message,    ---Sold to customer manager Approval
                p_start_date => systimestamp, 
                p_end_date => systimestamp, 
                p_user_comments => p_user_comments, 
                p_claim_id => p_claim_id, 
                p_user_id => p_user_id, 
                p_group_id => NULL
            );*/
            
            xxtwc_claims_wf_pkg.xxtwc_insert_log(
                p_wf_id => lv_wf_id,
                p_action => p_action,  
                p_actioned_by => p_actioned_by, 
                p_seq => p_seq,       --11
                p_message => p_message,    
                p_start_date => systimestamp, 
                p_end_date => systimestamp, 
                p_user_comments => (CASE WHEN p_user_comments IS NULL 
				AND LV_SUPER_APPROVER > 0
				THEN 'Claim approval performed by Super Approver role'
                ELSE  p_user_comments 
                END),			
                p_claim_id => p_claim_id, 
                p_user_id => p_user_id, 
                p_group_id => NULL  
            );	

			UPDATE xxtwc_claims_headers
            SET
                wf_next_seq_no = 12, 
                claim_status = 'Submitted', 
                CLAIM_SUB_STATUS ='Pending for Dept Approval'        
            WHERE
                claim_id = p_claim_id; 
				
	IF LV_DEPARTMENT = LV_DEPT_CODE THEN
	/*For Same Department*/
	IF LV_USER_APPROVAL_AMOUNT >= lv_claim_amount THEN
	UPDATE xxtwc_claims_headers
            SET
                wf_next_seq_no = 13, 
                claim_status = 'Submitted',
                CLAIM_SUB_STATUS ='Pending for Finance Approval'        
            WHERE
                claim_id = p_claim_id; 
				
	END IF;
	FOR I IN 
				(SELECT 
				GROUP_ID, Rownum lvl
				FROM 
               (SELECT GROUP_ID From 
				XXTWC_CLAIMS_APPR_LVL_DTL ALD, XXTWC_CLAIMS_APPR_LVL_HDR ALH
	            WHERE ALD.APPR_LVL_HDR_ID = ALH.APPR_LVL_HDR_ID
				AND ALH.APPR_LVL_HDR_ID = LV_APPR_LVL_HDR_ID
				AND LV_USER_APPROVAL_AMOUNT >= ALD.MAX_VALUE
                 AND ((lv_claim_amount <= ALD.MAX_VALUE 
				AND lv_claim_amount >= (CASE WHEN ALD.ATTRIBUTE1 = 1 AND UPPER(LV_DEPARTMENT) IN ('OPERATIONS','QUALITY') THEN 0 ELSE ALD.MIN_VALUE END ))
				OR lv_claim_amount > ALD.MAX_VALUE)
				AND ALH.ORG_ID = LV_ORG_ID
				AND ALD.GROUP_ID  IS NOT NULL
				ORDER BY ALD.MAX_VALUE ASC))
				LOOP
				
				xxtwc_claims_wf_pkg.xxtwc_insert_log(
                p_wf_id => lv_wf_id,
                p_action => 'Department Level ' || I.lvl || ' Auto Approval',  --'Skip Due to User Approval limit',
                p_actioned_by => LV_USER_ID, 
                p_seq => 12,       
                p_message => 'Skip Due to User Approval limit',    
                p_start_date => systimestamp, 
                p_end_date => systimestamp, 
                p_user_comments => 'Auto approval based on user('|| xxtwc_claims_user_registration_pkg.get_user_name(p_actioned_by) || ')approval limit ('||      LV_USER_APPROVAL_AMOUNT||')',  
                p_claim_id => p_claim_id, 
                p_user_id => NULL, 
                p_group_id => I.GROUP_ID  
                );	
				END LOOP;
	
	END IF;
			ELSE
			
	        UPDATE xxtwc_claims_headers
            SET
			wf_next_seq_no = 15, 
            claim_status = 'Rejected',  
            CLAIM_SUB_STATUS ='Rejected'     
            WHERE
                claim_id = p_claim_id;  
            
             xxtwc_claims_wf_pkg.xxtwc_insert_log(
                p_wf_id => lv_wf_id,
                p_action => p_action,  ---Sold to customer manager Rejected
                p_actioned_by => p_actioned_by, 
                p_seq => p_seq,       --11
                p_message => p_message,    ---Sold to customer manager Rejected
                p_start_date => systimestamp, 
                p_end_date => systimestamp, 
                p_user_comments => p_user_comments,    
                p_claim_id => p_claim_id, 
                p_user_id => p_user_id, 
                p_group_id => p_group_id  
            );	
            
          UPDATE XXTWC_CLAIMS_APPR_WF_ACT_LOG
		  SET STATUS = 0
		  WHERE CLAIM_ID = p_claim_id
		  AND SEQ = p_seq
          AND WF_ID = p_wf_id;			
		  END IF;
		EXCEPTION WHEN OTHERS
          THEN 
          XXTWC_CLAIMS_GP_ERROR_PKG.GP_ERROR_LOG ('Error in Claim Owner Approve/Reject',
                             SQLCODE,   
							 SQLERRM, 
							 V('APP_USER'),
                             35,
							 p_claim_id
                             );
END XXTWC_CLAIM_OWNER_APPROVAL;
-------------------------------------------------


FUNCTION GET_CURRENT_APPROVER_EMAILS(P_CLAIM_ID IN NUMBER,P_ORG_ID IN NUMBER,P_WF_ID IN NUMBER,P_WAREHOUSE_CODE IN VARCHAR2,P_CLAIM_AMOUNT IN NUMBER,P_DEPT IN VARCHAR2) 
RETURN VARCHAR2
IS
LV_EMAIL_ID VARCHAR2(4000);

BEGIN
select (select listagg(EMAIL_ID,'~') EMAIL_ID  from

(select  
       LD.EMAIL_ID,
       claims.xxtwc_claims_user_registration_pkg.get_user_name(LD.USER_ID) USER_NAME
  from XXTWC_CLAIMS_APPR_GROUP_USERS GU, XXTWC_CLAIMS_USER_LOGIN_DETAILS LD, XXTWC_CLAIMS_USER_ORG_DETAILS OD
  WHERE GU.USER_ID = LD.USER_ID 
  AND OD.USER_ID = LD.USER_ID
  AND GU.STATUS = 1
  AND LD.ACTIVE_FLG = 'Y'
  AND ( (LD.DEPT_CODE IN (SELECT CH.DEPARTMENT FROM XXTWC_CLAIMS_HEADERS CH WHERE CH.CLAIM_ID = P_CLAIM_ID)
  AND a.LVL_CODE NOT IN ( 'FINANCE', 'CLAIM OWNER')) OR (a.LVL_CODE IN ( 'FINANCE', 'CLAIM OWNER'))
  )
  AND P_ORG_ID = OD.ORG_ID   
  AND ( ( EXISTS (SELECT 1 FROM (select regexp_substr(OD.WAREHOUSE_CODE, '[^:]+', 1, level) result
			from DUAL
				connect by level <= length(regexp_replace(OD.WAREHOUSE_CODE, '[^:]+')) + 1) WHERE result = P_WAREHOUSE_CODE)  
                AND a.LVL_CODE = 'DEPARTMENTAL HIERARCHY') OR (a.LVL_CODE <> 'DEPARTMENTAL HIERARCHY')  )
  
  AND  (TO_CHAR(GROUP_ID) IN (select regexp_substr(a.GROUP_ID, '[^~]+', 1, level) result
			from DUAL
				connect by level <= length(regexp_replace(a.GROUP_ID, '[^~]+')) + 1 ) )
UNION
select 
       LD.EMAIL_ID,
        xxtwc_claims_user_registration_pkg.get_user_name(LD.USER_ID) USER_NAME
  from  XXTWC_CLAIMS_USER_LOGIN_DETAILS LD
  WHERE UPPER(a.GROUP_ID) = UPPER(LD.EMAIL_ID)
  AND LD.ACTIVE_FLG = 'Y')
) EMAIL_ID INTO LV_EMAIL_ID FROM
(SELECT LVL,LVL_CODE,STATUS,GROUP_ID FROM
(SELECT 'Claim Owner Approval' lvl,'CLAIM OWNER' LVL_CODE,
 NVL((SELECT DECODE(LO.STATUS, 1,'Approved',0,'Rejected')
FROM XXTWC_CLAIMS_APPR_WF_ACT_LOG LO WHERE LO.MESSAGE IN ('Claim Owner','Claim Owner Reject')
    AND CLAIM_ID = P_CLAIM_ID),'Pending') 
    STATUS , 
    CASE WHEN EXISTS (SELECT USER_ID
    FROM XXTWC_CLAIMS_USER_LOGIN_DETAILS
    WHERE UPPER(EMAIL_ID) = UPPER(ch.salesmanager) AND ACTIVE_FLG = 'Y') THEN UPPER(ch.salesmanager)
	WHEN EXISTS (SELECT 
	USER_ID
	FROM XXTWC_CLAIMS_USER_LOGIN_DETAILS
	WHERE UPPER(EMAIL_ID) = (SELECT 
	UPPER(EMAIL_ADDRESS) 
    FROM fusion.jtf_rs_salesreps jrs,
        fusion.hz_parties hp_sales
    WHERE jrs.resource_id = hp_sales.party_id  
    AND jrs.status ='A'
    AND hp_sales.status ='A'
    AND SYSDATE BETWEEN jrs.start_date_active and jrs.end_date_active
    and hp_sales.party_id = CH.SALES_PERSON_ID)
	AND ACTIVE_FLG = 'Y') THEN (SELECT 
	UPPER(EMAIL_ADDRESS) 
    FROM fusion.jtf_rs_salesreps jrs,
        fusion.hz_parties hp_sales
    WHERE jrs.resource_id = hp_sales.party_id  
    AND jrs.status ='A'
    AND hp_sales.status ='A'
    AND SYSDATE BETWEEN jrs.start_date_active and jrs.end_date_active
    and hp_sales.party_id = CH.SALES_PERSON_ID)
    ELSE (SELECT TO_CHAR(GROUP_ID) FROM XXTWC_CLAIMS_APPR_GROUPS 
WHERE GROUP_NAME = 'Claim Owner')
    END GROUP_ID
from XXTWC_CLAIMS_HEADERS CH ,XXTWC_CLAIMS_APPR_WF_HEADER HD
  WHERE HD.WF_ID = CH.WF_ID
  AND CH.ORG_ID = P_ORG_ID
  AND CLAIM_ID = P_CLAIM_ID
  AND  (( exists (SELECT USER_ID
    FROM XXTWC_CLAIMS_USER_LOGIN_DETAILS
    WHERE UPPER(EMAIL_ID) = UPPER(ch.salesmanager)AND ACTIVE_FLG = 'Y'))
	OR (exists(SELECT 
	USER_ID
	FROM XXTWC_CLAIMS_USER_LOGIN_DETAILS
	WHERE UPPER(EMAIL_ID) = (SELECT 
	UPPER(EMAIL_ADDRESS) 
    FROM fusion.jtf_rs_salesreps jrs,
        fusion.hz_parties hp_sales
    WHERE jrs.resource_id = hp_sales.party_id  
    AND jrs.status ='A'
    AND hp_sales.status ='A'
    AND SYSDATE BETWEEN jrs.start_date_active and jrs.end_date_active
    and hp_sales.party_id = CH.SALES_PERSON_ID)
	AND ACTIVE_FLG = 'Y'))
	
	OR(not exists (SELECT USER_ID
    FROM XXTWC_CLAIMS_USER_LOGIN_DETAILS
    WHERE UPPER(EMAIL_ID) = UPPER(ch.salesmanager)AND ACTIVE_FLG = 'Y') 
	AND NOT exists(SELECT 
	USER_ID
	FROM XXTWC_CLAIMS_USER_LOGIN_DETAILS
	WHERE UPPER(EMAIL_ID) = (SELECT 
	UPPER(EMAIL_ADDRESS) 
    FROM fusion.jtf_rs_salesreps jrs,
        fusion.hz_parties hp_sales
    WHERE jrs.resource_id = hp_sales.party_id  
    AND jrs.status ='A'
    AND hp_sales.status ='A'
    AND SYSDATE BETWEEN jrs.start_date_active and jrs.end_date_active
    and hp_sales.party_id = CH.SALES_PERSON_ID)
	AND ACTIVE_FLG = 'Y')
	AND EXISTS(SELECT 1
    FROM XXTWC_CLAIMS_USER_LOGIN_DETAILS LG, XXTWC_CLAIMS_APPR_GROUP_USERS GU, XXTWC_CLAIMS_APPR_GROUPS G
    WHERE LG.USER_ID = GU.USER_ID
    AND GU.GROUP_ID = G.GROUP_ID
    AND GU.STATUS = 1
    AND LG.ACTIVE_FLG = 'Y'
	--AND LG.DEPT_CODE = CH.DEPARTMENT
    AND G.GROUP_NAME = 'Claim Owner'
	))
	)
 AND ((CH.DEPARTMENT NOT IN ('OPERATIONS','QUALITY')
 AND CH.CLAIM_AMOUNT > (SELECT
                ald.max_value
            FROM
                xxtwc_claims_appr_lvl_dtl ald,
                xxtwc_claims_appr_lvl_hdr alh
            WHERE
                    ald.appr_lvl_hdr_id = alh.appr_lvl_hdr_id
                AND alh.appr_lvl_hdr_id = HD.APPR_LVL_HDR_ID
                AND nvl(ald.min_value, 0) = 0
                AND alh.org_id = CH.org_id ))OR (CH.DEPARTMENT IN ('OPERATIONS','QUALITY')))
UNION                

select  'Department Level' || ' ' || rownum lvl, 'DEPARTMENTAL HIERARCHY' lvl_code,STATUS ,
       replace(GROUP_ID,':','~') GROUP_ID 
	   from (
              SELECT			
              DISTINCT(ALD.GROUP_ID) GROUP_ID,
              MIN_VALUE,
              NVL((SELECT DECODE(LO.MESSAGE,'Departmental Hierarchy', 'Approved','Skip Due to User Approval limit','Approved', 'Departmental Hierarchy Reject','Rejected','Pending')  --DECODE(LO.STATUS, 1,'Approved',0,'Rejected') 
                   FROM XXTWC_CLAIMS_APPR_WF_ACT_LOG LO 
	               WHERE LO.GROUP_ID = ALD.GROUP_ID
                   AND LO.MESSAGE IN ('Departmental Hierarchy','Skip Due to User Approval limit','Departmental Hierarchy Reject')
                   AND CLAIM_ID = P_CLAIM_ID),'Pending') 
                   STATUS
FROM 
XXTWC_CLAIMS_APPR_LVL_DTL ALD, XXTWC_CLAIMS_APPR_LVL_HDR ALH, XXTWC_CLAIMS_APPR_WF_HEADER WH 
WHERE ALH.APPR_LVL_HDR_ID = ALD.APPR_LVL_HDR_ID
AND ALH.APPR_LVL_HDR_ID = WH.APPR_LVL_HDR_ID
AND WH.WF_ID = P_WF_ID
AND ((P_CLAIM_AMOUNT <= ALD.MAX_VALUE 
AND  P_CLAIM_AMOUNT >= (CASE WHEN ALD.ATTRIBUTE1 = 1 AND UPPER(P_DEPT) IN ('OPERATIONS','QUALITY') THEN 0 ELSE ALD.MIN_VALUE END )
--DECODE (ALD.ATTRIBUTE1, 1, 0, ALD.MIN_VALUE)

)
OR  P_CLAIM_AMOUNT > ALD.MAX_VALUE)

AND ALD.GROUP_ID  IS NOT NULL
AND ALH.ORG_ID = P_ORG_ID
order by MIN_VALUE ASC) 
                
UNION
SELECT 'Finance Approval' lvl,'FINANCE' LVL_CODE,
NVL((SELECT DECODE(LO.STATUS, 1,'Approved',0,'Rejected')
FROM XXTWC_CLAIMS_APPR_WF_ACT_LOG LO WHERE LO.MESSAGE IN ('Finance Reject', 'Finance Approved')
    AND CLAIM_ID = P_CLAIM_ID),'Pending') 
    STATUS, 
    (SELECT GROUP_ID
				FROM XXTWC_CLAIMS_APPR_LVL_DTL ALD, XXTWC_CLAIMS_APPR_LVL_HDR ALH
	            WHERE ALD.APPR_LVL_HDR_ID = ALH.APPR_LVL_HDR_ID
				AND ALH.HIERARCHY_NAME = 'Finance'
				AND TO_NUMBER(P_CLAIM_AMOUNT) BETWEEN TO_NUMBER(ALD.MIN_VALUE) AND TO_NUMBER(ALD.MAX_VALUE)
				AND ALH.ORG_ID = P_ORG_ID
				AND ALD.GROUP_ID  IS NOT NULL) GROUP_ID
FROM DUAL)
WHERE STATUS ='Pending'
order by LVL) a
where rownum<2;

RETURN LV_EMAIL_ID;

END GET_CURRENT_APPROVER_EMAILS;
-----------------------------------------------------------------------------------------
FUNCTION GET_CURRENT_APPROVER_USER_NAME(P_CLAIM_ID IN NUMBER,P_ORG_ID IN NUMBER,P_WF_ID IN NUMBER,P_WAREHOUSE_CODE IN VARCHAR2,P_CLAIM_AMOUNT IN NUMBER,P_DEPT IN VARCHAR2) 
RETURN VARCHAR2
IS
LV_USER_NAME VARCHAR2(4000);
LV_MISSING_LOT VARCHAR2(1);
LV_WF_NEXT_SEQ_NO NUMBER;

BEGIN
BEGIN
SELECT 
MISSING_LOT
,WF_NEXT_SEQ_NO
INTO 
LV_MISSING_LOT
,LV_WF_NEXT_SEQ_NO
FROM XXTWC_CLAIMS_HEADERS
WHERE CLAIM_ID = P_CLAIM_ID;
EXCEPTION
            WHEN OTHERS THEN
                LV_MISSING_LOT := 'N';
END;

select (select listagg(USER_NAME,',') USER_NAME  from

(select  
       LD.EMAIL_ID,
       claims.xxtwc_claims_user_registration_pkg.get_user_name(LD.USER_ID) USER_NAME
       --LD.USER_ID USER_NAME
  from XXTWC_CLAIMS_APPR_GROUP_USERS GU, XXTWC_CLAIMS_USER_LOGIN_DETAILS LD, XXTWC_CLAIMS_USER_ORG_DETAILS OD
  WHERE GU.USER_ID = LD.USER_ID 
  AND OD.USER_ID = LD.USER_ID
  AND GU.STATUS = 1
  AND LD.ACTIVE_FLG = 'Y'
  AND ( (LD.DEPT_CODE IN (SELECT CH.DEPARTMENT FROM XXTWC_CLAIMS_HEADERS CH WHERE CH.CLAIM_ID = P_CLAIM_ID)
  AND a.LVL_CODE NOT IN ( 'FINANCE', 'CLAIM OWNER','MISSING LOT')) OR (a.LVL_CODE IN ( 'FINANCE', 'CLAIM OWNER','MISSING LOT'))
  )
  AND P_ORG_ID = OD.ORG_ID   
  AND ( ( EXISTS (SELECT 1 FROM (select regexp_substr(OD.WAREHOUSE_CODE, '[^:]+', 1, level) result
			from DUAL
				connect by level <= length(regexp_replace(OD.WAREHOUSE_CODE, '[^:]+')) + 1) WHERE result = P_WAREHOUSE_CODE)  
                AND a.LVL_CODE = 'DEPARTMENTAL HIERARCHY') OR (a.LVL_CODE <> 'DEPARTMENTAL HIERARCHY')  )
  
  AND  (TO_CHAR(GROUP_ID) IN (select regexp_substr(a.GROUP_ID, '[^~]+', 1, level) result
			from DUAL
				connect by level <= length(regexp_replace(a.GROUP_ID, '[^~]+')) + 1 ) )
UNION
select 
       LD.EMAIL_ID,
        xxtwc_claims_user_registration_pkg.get_user_name(LD.USER_ID) USER_NAME
        --LD.USER_ID USER_NAME
  from  XXTWC_CLAIMS_USER_LOGIN_DETAILS LD
  WHERE UPPER(a.GROUP_ID) = UPPER(LD.EMAIL_ID) AND LD.ACTIVE_FLG = 'Y'
UNION
  SELECT LD.EMAIL_ID,
        xxtwc_claims_user_registration_pkg.get_user_name(LD.USER_ID) USER_NAME
          FROM CLAIMS.XXTWC_CLAIMS_REASSIGN_APPROVAL RA,XXTWC_CLAIMS_USER_LOGIN_DETAILS LD
          WHERE  RA.REASSIGN_TO = LD.USER_ID
		  AND RA.CLAIM_ID = P_CLAIM_ID
	      AND RA.WF_NEXT_SEQ_NO = LV_WF_NEXT_SEQ_NO
          AND RA.STATUS = 1 ---2024-16-01
  )
) EMAIL_ID INTO LV_USER_NAME FROM
(

SELECT LVL,LVL_CODE,STATUS,GROUP_ID FROM
(
SELECT 'Import Claim Owner Approval' lvl,'MISSING LOT' lvl_code,
 NVL((SELECT DECODE(LO.STATUS, 1,'Approved',0,'Rejected')
FROM XXTWC_CLAIMS_APPR_WF_ACT_LOG LO WHERE LO.MESSAGE IN ('Missing Lot Rejected', 'Missing Lot Approved')
    AND CLAIM_ID = P_CLAIM_ID ),'Pending')
     STATUS,
      (SELECT TO_CHAR(GROUP_ID) FROM XXTWC_CLAIMS_APPR_GROUPS 
WHERE GROUP_NAME = 'Import Claim Owner Approval') GROUP_ID,
/*AND EXISTS(SELECT 1
          FROM CLAIMS.XXTWC_CLAIMS_REASSIGN_APPROVAL RA
          WHERE  RA.CLAIM_ID = P_CLAIM_ID
	      AND RA.WF_NEXT_SEQ_NO = LV_WF_NEXT_SEQ_NO
	      AND RA.REASSIGN_TO = V('P0_USER_ID') 
            )*/
1 AS SEQ
FROM DUAL
WHERE LV_MISSING_LOT = 'Y'


UNION

SELECT 'Claim Owner Approval' lvl,'CLAIM OWNER' lvl_code,
 NVL((SELECT DECODE(LO.STATUS, 1,'Approved',0,'Rejected')
FROM XXTWC_CLAIMS_APPR_WF_ACT_LOG LO WHERE LO.MESSAGE IN ('Claim Owner','Claim Owner Reject')
    AND CLAIM_ID = P_CLAIM_ID),'Pending') 
    STATUS , 
    CASE WHEN EXISTS (SELECT USER_ID
    FROM XXTWC_CLAIMS_USER_LOGIN_DETAILS
    WHERE UPPER(EMAIL_ID) = UPPER(ch.salesmanager)AND ACTIVE_FLG = 'Y') THEN UPPER(ch.salesmanager)
	WHEN EXISTS (SELECT 
	USER_ID
	FROM XXTWC_CLAIMS_USER_LOGIN_DETAILS
	WHERE UPPER(EMAIL_ID) = (SELECT 
	UPPER(EMAIL_ADDRESS) 
    FROM fusion.jtf_rs_salesreps jrs,
        fusion.hz_parties hp_sales
    WHERE jrs.resource_id = hp_sales.party_id  
    AND jrs.status ='A'
    AND hp_sales.status ='A'
    AND SYSDATE BETWEEN jrs.start_date_active and jrs.end_date_active
    and hp_sales.party_id = CH.SALES_PERSON_ID)
	AND ACTIVE_FLG = 'Y') THEN (SELECT 
	UPPER(EMAIL_ADDRESS) 
    FROM fusion.jtf_rs_salesreps jrs,
        fusion.hz_parties hp_sales
    WHERE jrs.resource_id = hp_sales.party_id  
    AND jrs.status ='A'
    AND hp_sales.status ='A'
    AND SYSDATE BETWEEN jrs.start_date_active and jrs.end_date_active
    and hp_sales.party_id = CH.SALES_PERSON_ID)
    ELSE (SELECT TO_CHAR(GROUP_ID) FROM XXTWC_CLAIMS_APPR_GROUPS 
WHERE GROUP_NAME = 'Claim Owner') 
    END GROUP_ID,
	2 AS SEQ
from XXTWC_CLAIMS_HEADERS CH ,XXTWC_CLAIMS_APPR_WF_HEADER HD
  WHERE HD.WF_ID = CH.WF_ID
  AND CH.ORG_ID = P_ORG_ID
  AND CLAIM_ID = P_CLAIM_ID
  AND  (( exists (SELECT USER_ID
    FROM XXTWC_CLAIMS_USER_LOGIN_DETAILS
    WHERE UPPER(EMAIL_ID) = UPPER(ch.salesmanager)AND ACTIVE_FLG = 'Y'))
	OR (exists(SELECT 
	USER_ID
	FROM XXTWC_CLAIMS_USER_LOGIN_DETAILS
	WHERE UPPER(EMAIL_ID) = (SELECT 
	UPPER(EMAIL_ADDRESS) 
    FROM fusion.jtf_rs_salesreps jrs,
        fusion.hz_parties hp_sales
    WHERE jrs.resource_id = hp_sales.party_id  
    AND jrs.status ='A'
    AND hp_sales.status ='A'
    AND SYSDATE BETWEEN jrs.start_date_active and jrs.end_date_active
    and hp_sales.party_id = CH.SALES_PERSON_ID)
	AND ACTIVE_FLG = 'Y'))
	
	OR(not exists (SELECT USER_ID
    FROM XXTWC_CLAIMS_USER_LOGIN_DETAILS
    WHERE UPPER(EMAIL_ID) = UPPER(ch.salesmanager)AND ACTIVE_FLG = 'Y') 
	AND NOT exists(SELECT 
	USER_ID
	FROM XXTWC_CLAIMS_USER_LOGIN_DETAILS
	WHERE UPPER(EMAIL_ID) = (SELECT 
	UPPER(EMAIL_ADDRESS) 
    FROM fusion.jtf_rs_salesreps jrs,
        fusion.hz_parties hp_sales
    WHERE jrs.resource_id = hp_sales.party_id  
    AND jrs.status ='A'
    AND hp_sales.status ='A'
    AND SYSDATE BETWEEN jrs.start_date_active and jrs.end_date_active
    and hp_sales.party_id = CH.SALES_PERSON_ID)
	AND ACTIVE_FLG = 'Y')
	AND EXISTS(SELECT 1
    FROM XXTWC_CLAIMS_USER_LOGIN_DETAILS LG, XXTWC_CLAIMS_APPR_GROUP_USERS GU, XXTWC_CLAIMS_APPR_GROUPS G
    WHERE LG.USER_ID = GU.USER_ID
    AND GU.GROUP_ID = G.GROUP_ID
	--AND LG.DEPT_CODE = CH.DEPARTMENT
    AND G.GROUP_NAME = 'Claim Owner'
    AND GU.STATUS = 1
    AND LG.ACTIVE_FLG = 'Y'
	))
	)
 AND ((CH.DEPARTMENT NOT IN ('OPERATIONS','QUALITY')
 AND CH.CLAIM_AMOUNT > (SELECT
                ald.max_value
            FROM
                xxtwc_claims_appr_lvl_dtl ald,
                xxtwc_claims_appr_lvl_hdr alh
            WHERE
                    ald.appr_lvl_hdr_id = alh.appr_lvl_hdr_id
                AND alh.appr_lvl_hdr_id = HD.APPR_LVL_HDR_ID
                AND nvl(ald.min_value, 0) = 0
                AND alh.org_id = CH.org_id ))OR (CH.DEPARTMENT IN ('OPERATIONS','QUALITY')))
UNION                

select  'Department Level' || ' ' || rownum lvl, 'DEPARTMENTAL HIERARCHY' lvl_code,STATUS ,
       replace(GROUP_ID,':','~') GROUP_ID ,
	   3 AS SEQ
	   from (
              SELECT			
              DISTINCT(ALD.GROUP_ID) GROUP_ID,
              MIN_VALUE,
              NVL((SELECT DECODE(LO.MESSAGE,'Departmental Hierarchy', 'Approved','Skip Due to User Approval limit','Approved', 'Departmental Hierarchy Reject','Rejected','Pending')  --DECODE(LO.STATUS, 1,'Approved',0,'Rejected') 
                   FROM XXTWC_CLAIMS_APPR_WF_ACT_LOG LO 
	               WHERE LO.GROUP_ID = ALD.GROUP_ID
                   AND LO.MESSAGE IN ('Departmental Hierarchy','Skip Due to User Approval limit','Departmental Hierarchy Reject')
                   AND CLAIM_ID = P_CLAIM_ID),'Pending') 
                   STATUS
FROM 
XXTWC_CLAIMS_APPR_LVL_DTL ALD, XXTWC_CLAIMS_APPR_LVL_HDR ALH, XXTWC_CLAIMS_APPR_WF_HEADER WH 
WHERE ALH.APPR_LVL_HDR_ID = ALD.APPR_LVL_HDR_ID
AND ALH.APPR_LVL_HDR_ID = WH.APPR_LVL_HDR_ID
AND WH.WF_ID = P_WF_ID
AND ((P_CLAIM_AMOUNT <= ALD.MAX_VALUE 
AND  P_CLAIM_AMOUNT >= (CASE WHEN ALD.ATTRIBUTE1 = 1 AND UPPER(P_DEPT) IN ('OPERATIONS','QUALITY') THEN 0 ELSE ALD.MIN_VALUE END )


)
OR  P_CLAIM_AMOUNT > ALD.MAX_VALUE)

AND ALD.GROUP_ID  IS NOT NULL
AND ALH.ORG_ID = P_ORG_ID
order by MIN_VALUE ASC) 
                
UNION
SELECT 'Finance Approval' lvl,'FINANCE' lvl_code,
NVL((SELECT DECODE(LO.STATUS, 1,'Approved',0,'Rejected')
FROM XXTWC_CLAIMS_APPR_WF_ACT_LOG LO WHERE LO.MESSAGE IN ('Finance Reject', 'Finance Approved')
    AND CLAIM_ID = P_CLAIM_ID),'Pending') 
    STATUS, 
    (SELECT GROUP_ID
				FROM XXTWC_CLAIMS_APPR_LVL_DTL ALD, XXTWC_CLAIMS_APPR_LVL_HDR ALH
	            WHERE ALD.APPR_LVL_HDR_ID = ALH.APPR_LVL_HDR_ID
				AND ALH.HIERARCHY_NAME = 'Finance'
				AND TO_NUMBER(P_CLAIM_AMOUNT) BETWEEN TO_NUMBER(ALD.MIN_VALUE) AND TO_NUMBER(ALD.MAX_VALUE)
				AND ALH.ORG_ID = P_ORG_ID
				AND ALD.GROUP_ID  IS NOT NULL) GROUP_ID,
				4 AS SEQ
FROM DUAL)
WHERE STATUS ='Pending'
order by SEQ) a
where rownum<2;

RETURN LV_USER_NAME;

END GET_CURRENT_APPROVER_USER_NAME;
-------------------------------------------------------------------
PROCEDURE XXTWC_CHANGES_AFTER_REVISE_CLAIM(
P_CLAIM_ID VARCHAR2)IS
 LV_COLUMN VARCHAR2(2000);
 LV_LINES_COLUMN VARCHAR2(2000);
 LV_LINE_COL VARCHAR2(500);
 LV_WF_ID NUMBER;
 LV_CREATED_BY VARCHAR2(500);
 LV_CLAIM_ID NUMBER;
 LV_OLD_CLAIM_ID NUMBER;
 LV_CLAIM_NUMBER VARCHAR2(1000);
 LV_CLAIM_REVISION_NUMBER NUMBER;
 LV_FINAL_LINES_COLUMN VARCHAR2(4000);
 LV_FINAL_HEADER_COLUMN VARCHAR2(4000);
 LV_EXTRA_LINE VARCHAR2(2000);

BEGIN

SELECT WF_ID,CREATED_BY,CLAIM_NUMBER,CLAIM_REVISION_NUMBER
INTO LV_WF_ID,LV_CREATED_BY,LV_CLAIM_NUMBER,LV_CLAIM_REVISION_NUMBER                 
FROM XXTWC_CLAIMS_HEADERS
WHERE CLAIM_ID = P_CLAIM_ID;

BEGIN
SELECT CLAIM_ID
INTO LV_OLD_CLAIM_ID      
FROM XXTWC_CLAIMS_HEADERS
WHERE CLAIM_NUMBER = LV_CLAIM_NUMBER
AND CLAIM_REVISION_NUMBER = LV_CLAIM_REVISION_NUMBER-1;
EXCEPTION WHEN OTHERS THEN
LV_OLD_CLAIM_ID := NULL;
END;

with t1_only as (
   select 
   CLAIM_ID,
   BU_NAME,
   SOLD_TO_CUSTOMER_ID,
   CLAIM_NOTE,
   BILL_TO_CUSTOMER_ID,
   WAREHOUSE_CODE,
   SHIP_TO_CUSTOMER_ID,
   PO_NUMBER,
   SALES_PERSON_ID,
   CREATED_BY,
   CLAIM_NUMBER,
   CLAIM_DATE,
   CLAIM_AMOUNT,
   OVERPAY
   from claims.XXTWC_CLAIMS_HEADERS
   where CLAIM_NUMBER = LV_CLAIM_NUMBER
   and CLAIM_REVISION_NUMBER = LV_CLAIM_REVISION_NUMBER-1 
   minus
   select 
   CLAIM_ID,
   BU_NAME,
   SOLD_TO_CUSTOMER_ID,
   CLAIM_NOTE,
   BILL_TO_CUSTOMER_ID,
   WAREHOUSE_CODE,
   SHIP_TO_CUSTOMER_ID,
   PO_NUMBER,
   SALES_PERSON_ID,
   CREATED_BY,
   CLAIM_NUMBER,
   CLAIM_DATE,
   CLAIM_AMOUNT,
   OVERPAY
   from claims.XXTWC_CLAIMS_HEADERS
   where CLAIM_NUMBER = LV_CLAIM_NUMBER 
   and CLAIM_REVISION_NUMBER = LV_CLAIM_REVISION_NUMBER ),
     t2_only as (
   select 
   CLAIM_ID,
   BU_NAME,
   SOLD_TO_CUSTOMER_ID,
   CLAIM_NOTE,
   BILL_TO_CUSTOMER_ID,
   WAREHOUSE_CODE,
   SHIP_TO_CUSTOMER_ID,
   PO_NUMBER,
   SALES_PERSON_ID,
   CREATED_BY,
   CLAIM_NUMBER,
   CLAIM_DATE,
   CLAIM_AMOUNT,
   OVERPAY
   from claims.XXTWC_CLAIMS_HEADERS
   where CLAIM_NUMBER = LV_CLAIM_NUMBER 
   and CLAIM_REVISION_NUMBER = LV_CLAIM_REVISION_NUMBER
   minus
   select 
   CLAIM_ID,
   BU_NAME,
   SOLD_TO_CUSTOMER_ID,
   CLAIM_NOTE,
   BILL_TO_CUSTOMER_ID,
   WAREHOUSE_CODE,
   SHIP_TO_CUSTOMER_ID,
   PO_NUMBER,
   SALES_PERSON_ID,
   CREATED_BY,
   CLAIM_NUMBER,
   CLAIM_DATE,
   CLAIM_AMOUNT,
   OVERPAY
   from claims.XXTWC_CLAIMS_HEADERS
   where CLAIM_NUMBER = LV_CLAIM_NUMBER 
   and CLAIM_REVISION_NUMBER = LV_CLAIM_REVISION_NUMBER-1)
select listagg(COLUMNS,',') COLUMNS 
INTO LV_COLUMN
from (select t1_only.CLAIM_ID,
   case when t1_only.BU_NAME<>t2_only.BU_NAME then 'Changed' end BU_NAME,
   case when t1_only.SOLD_TO_CUSTOMER_ID<>t2_only.SOLD_TO_CUSTOMER_ID then 'Changed' end SOLD_TO_CUSTOMER_ID,
   case when t1_only.CLAIM_NOTE<>t2_only.CLAIM_NOTE then 'Changed' end CLAIM_NOTE,
   case when t1_only.BILL_TO_CUSTOMER_ID<>t2_only.BILL_TO_CUSTOMER_ID then 'Changed' end BILL_TO_CUSTOMER_ID,
   case when t1_only.WAREHOUSE_CODE<>t2_only.WAREHOUSE_CODE then 'Changed' end WAREHOUSE_CODE,
   case when t1_only.SHIP_TO_CUSTOMER_ID<>t2_only.SHIP_TO_CUSTOMER_ID then 'Changed' end SHIP_TO_CUSTOMER_ID,
   case when t1_only.PO_NUMBER<>t2_only.PO_NUMBER then 'Changed' end PO_NUMBER,
   case when t1_only.SALES_PERSON_ID<>t2_only.SALES_PERSON_ID then 'Changed' end SALES_PERSON_ID,
   case when t1_only.CREATED_BY<>t2_only.CREATED_BY then 'Changed' end CREATED_BY,
   case when t1_only.CLAIM_DATE<>t2_only.CLAIM_DATE then 'Changed' end CLAIM_DATE,
   case when t1_only.CLAIM_AMOUNT<>t2_only.CLAIM_AMOUNT then 'Changed' end CLAIM_AMOUNT,
   case when t1_only.OVERPAY<>t2_only.OVERPAY then 'Changed' end OVERPAY
from t1_only , t2_only
where t1_only.CLAIM_NUMBER = t2_only.CLAIM_NUMBER)
UNPIVOT (cols FOR COLUMNS IN (
 BU_NAME AS 'Business Unit',
 SOLD_TO_CUSTOMER_ID AS 'Sold-to Customer',
 CLAIM_NOTE AS 'Claim Note',
 BILL_TO_CUSTOMER_ID AS ' Bill-to Customer',
 WAREHOUSE_CODE AS 'Ship From Warehouse',
 SHIP_TO_CUSTOMER_ID AS 'Ship-to Customer',
 PO_NUMBER AS 'Purchase Order',
 SALES_PERSON_ID AS 'Salesperson',
 CREATED_BY AS 'Created By', 
CLAIM_DATE AS 'Claim Date',
CLAIM_AMOUNT AS 'Claim Amount',
OVERPAY AS 'Overpay'));

IF LV_COLUMN IS NULL THEN
LV_FINAL_HEADER_COLUMN := 'No values changed.';
ELSE
LV_FINAL_HEADER_COLUMN := 'These column value got changed : '||LV_COLUMN;
END IF;

xxtwc_claims_wf_pkg.xxtwc_insert_log(
                p_wf_id => LV_WF_ID,
                p_action => 'Claim Header values changed in Revision',  
                p_actioned_by => V('P0_USER_ID'), 
                p_seq => 200,       
                p_message => 'Claim Header values changed in Revision',  
                p_start_date => systimestamp, 
                p_end_date => systimestamp, 
                p_user_comments => LV_FINAL_HEADER_COLUMN,   
                p_claim_id => P_CLAIM_ID, 
                p_user_id => V('P0_USER_ID'),
                p_group_id => NULL);

BEGIN
FOR I IN (SELECT DISTINCT CLAIM_LINE_NO 
FROM XXTWC_CLAIMS_LINES 
WHERE CLAIM_ID = LV_OLD_CLAIM_ID
and nvl(claim_qty,0) >0)
LOOP
with t1_only as (
   select 
   CLAIM_LINE_NO,
   UNIT_NEW_PRICE,
   CLAIM_REASON_CODE,
    CLAIM_QTY,
    UNIT_LIST_PRICE,
    UNIT_SELLING_PRICE,
    UNIT_ADJUSTMENT_PRICE,
    EXTENDED_AMOUNT,
    FRIGHT_CHARGES,
    ITEM_VARIETY,
    RETURNABLE_QTY,
    ADJ_PRICE_DIFFERENCE,
    UNIT_REBILL_PRICE,
	OVERPAY_PRICE
   from claims.XXTWC_CLAIMS_LINES
   where CLAIM_ID = LV_OLD_CLAIM_ID 
   and CLAIM_LINE_NO = i.CLAIM_LINE_NO
   and nvl(claim_qty,0) >0
   minus
   select 
   CLAIM_LINE_NO,
   UNIT_NEW_PRICE,
    CLAIM_REASON_CODE,
    CLAIM_QTY,
    UNIT_LIST_PRICE,
    UNIT_SELLING_PRICE,
    UNIT_ADJUSTMENT_PRICE,
    EXTENDED_AMOUNT,
    FRIGHT_CHARGES,
    ITEM_VARIETY,
    RETURNABLE_QTY,
    ADJ_PRICE_DIFFERENCE,
    UNIT_REBILL_PRICE,
	OVERPAY_PRICE
   from claims.XXTWC_CLAIMS_LINES
   where CLAIM_ID = P_CLAIM_ID 
   and CLAIM_LINE_NO = i.CLAIM_LINE_NO 
   and nvl(claim_qty,0) >0),
     t2_only as (
   select 
   CLAIM_LINE_NO,
   UNIT_NEW_PRICE,
    CLAIM_REASON_CODE,
    CLAIM_QTY,
    UNIT_LIST_PRICE,
    UNIT_SELLING_PRICE,
    UNIT_ADJUSTMENT_PRICE,
    EXTENDED_AMOUNT,
    FRIGHT_CHARGES,
    ITEM_VARIETY,
    RETURNABLE_QTY,
    ADJ_PRICE_DIFFERENCE,
    UNIT_REBILL_PRICE,
	OVERPAY_PRICE
   from claims.XXTWC_CLAIMS_LINES
   where CLAIM_ID = P_CLAIM_ID 
   and CLAIM_LINE_NO = i.CLAIM_LINE_NO
   and nvl(claim_qty,0) >0
   minus
   select 
   CLAIM_LINE_NO,
   UNIT_NEW_PRICE,
    CLAIM_REASON_CODE,
    CLAIM_QTY,
    UNIT_LIST_PRICE,
    UNIT_SELLING_PRICE,
    UNIT_ADJUSTMENT_PRICE,
    EXTENDED_AMOUNT,
    FRIGHT_CHARGES,
    ITEM_VARIETY,
    RETURNABLE_QTY,
    ADJ_PRICE_DIFFERENCE,
    UNIT_REBILL_PRICE,
	OVERPAY_PRICE
   from claims.XXTWC_CLAIMS_LINES
   where CLAIM_ID = LV_OLD_CLAIM_ID 
   and CLAIM_LINE_NO = i.CLAIM_LINE_NO
   and nvl(claim_qty,0) >0)
select decode(nvl(length(listagg(COLUMNS,',')),0),0,'','Change in Claim Line No '|| i.CLAIM_LINE_NO || ' : '|| listagg(COLUMNS,',')) COLUMNS 
INTO LV_LINE_COL
from (select t1_only.CLAIM_LINE_NO,
   case when t1_only.UNIT_NEW_PRICE<>t2_only.UNIT_NEW_PRICE then 'Changed' end UNIT_NEW_PRICE,
   case when t1_only.CLAIM_REASON_CODE<>t2_only.CLAIM_REASON_CODE then 'Changed' end CLAIM_REASON_CODE,
   case when t1_only.CLAIM_QTY<>t2_only.CLAIM_QTY then 'Changed' end CLAIM_QTY,
   case when t1_only.UNIT_LIST_PRICE<>t2_only.UNIT_LIST_PRICE then 'Changed' end UNIT_LIST_PRICE,
   case when t1_only.UNIT_SELLING_PRICE<>t2_only.UNIT_SELLING_PRICE then 'Changed' end UNIT_SELLING_PRICE,
   case when t1_only.UNIT_ADJUSTMENT_PRICE<>t2_only.UNIT_ADJUSTMENT_PRICE then 'Changed' end UNIT_ADJUSTMENT_PRICE,
   case when t1_only.EXTENDED_AMOUNT<>t2_only.EXTENDED_AMOUNT then 'Changed' end EXTENDED_AMOUNT,
   case when t1_only.FRIGHT_CHARGES<>t2_only.FRIGHT_CHARGES then 'Changed' end FRIGHT_CHARGES,
   case when t1_only.ITEM_VARIETY<>t2_only.ITEM_VARIETY then 'Changed' end ITEM_VARIETY,
   case when t1_only.RETURNABLE_QTY<>t2_only.RETURNABLE_QTY then 'Changed' end RETURNABLE_QTY,
   case when t1_only.ADJ_PRICE_DIFFERENCE<>t2_only.ADJ_PRICE_DIFFERENCE then 'Changed' end ADJ_PRICE_DIFFERENCE,
   case when t1_only.UNIT_REBILL_PRICE<>t2_only.UNIT_REBILL_PRICE then 'Changed' end UNIT_REBILL_PRICE,
   case when t1_only.OVERPAY_PRICE<>t2_only.OVERPAY_PRICE then 'Changed' end OVERPAY_PRICE
from t1_only , t2_only
where t1_only.CLAIM_LINE_NO = t2_only.CLAIM_LINE_NO)
UNPIVOT (cols FOR COLUMNS IN (
 UNIT_NEW_PRICE AS 'Unit New Price',
 CLAIM_REASON_CODE AS 'Reason Code',
 CLAIM_QTY AS 'Claim Qty',
 UNIT_LIST_PRICE AS 'Unit List Price',
 UNIT_SELLING_PRICE AS 'Original Price',
 UNIT_ADJUSTMENT_PRICE AS 'Credit Price',
 EXTENDED_AMOUNT AS 'Amount',
 FRIGHT_CHARGES AS 'Freight Charges',
 ITEM_VARIETY AS 'Variety',
 RETURNABLE_QTY AS 'Returnable Qty',
 ADJ_PRICE_DIFFERENCE AS 'Adjustment Price / Unit',
 UNIT_REBILL_PRICE AS 'Re-Bill Price',
 OVERPAY_PRICE AS 'Overpay_Price'
));
 IF LV_LINE_COL IS NOT NULL
 THEN
 LV_LINES_COLUMN := LV_LINES_COLUMN || LV_LINE_COL || '<br>';
 END IF;
END LOOP;

BEGIN
SELECT LISTAGG(CLAIM_LINE_NO, ',') WITHIN GROUP (ORDER BY CLAIM_LINE_NO) INTO LV_EXTRA_LINE
FROM (SELECT DISTINCT CLAIM_LINE_NO
FROM XXTWC_CLAIMS_LINES 
WHERE CLAIM_ID = P_CLAIM_ID
and nvl(claim_qty,0) >0
minus
SELECT DISTINCT CLAIM_LINE_NO 
FROM XXTWC_CLAIMS_LINES 
WHERE CLAIM_ID = LV_OLD_CLAIM_ID
and nvl(claim_qty,0) >0 );
EXCEPTION WHEN OTHERS THEN 
LV_EXTRA_LINE := NULL;
END;

IF LV_LINES_COLUMN IS NULL THEN
LV_FINAL_LINES_COLUMN := 'No values changed.';
ELSE
LV_FINAL_LINES_COLUMN := 'These column value got changed : '||' <br>' || LV_LINES_COLUMN;
END IF;

IF LV_EXTRA_LINE IS NOT NULL THEN
LV_FINAL_LINES_COLUMN := LV_FINAL_LINES_COLUMN || '<br>' || 'These lines are newly added in this revision : ' || LV_EXTRA_LINE;
END IF;


xxtwc_claims_wf_pkg.xxtwc_insert_log(
                p_wf_id => LV_WF_ID,
                p_action => 'Claim Line values changed in Revision',  
                p_actioned_by => V('P0_USER_ID'),
                p_seq => 200,       
                p_message => 'Claim Line values changed in Revision',  
                p_start_date => systimestamp, 
                p_end_date => systimestamp, 
                p_user_comments => LV_FINAL_LINES_COLUMN ,   
                p_claim_id => P_CLAIM_ID, 
                p_user_id => V('P0_USER_ID'), 
                p_group_id => NULL);
                
END;
END XXTWC_CHANGES_AFTER_REVISE_CLAIM;
----------------------------------------------------------------------
PROCEDURE XXTWC_MISSING_LOT_APPROVAL (
	p_wf_id              NUMBER,
	p_seq                NUMBER,
	p_start_date         TIMESTAMP,
	p_claim_type         VARCHAR2,
	p_user_comments      VARCHAR2,
	p_claim_id           NUMBER,
	p_group_id           VARCHAR2,
    p_user_id            VARCHAR2,
	p_action             VARCHAR2,
	p_actioned_by        NUMBER,
	p_message            VARCHAR2,
	p_end_date           TIMESTAMP,
	p_claim_amount       NUMBER
	) IS
	 
	
    lv_wf_id           NUMBER;
    lv_claim_amount    NUMBER;
    lv_org_id          NUMBER;
    --l_error            VARCHAR2(2000);
	LV_GROUP_ID        VARCHAR2(1000);
	LV_SUPER_APPROVER  NUMBER;
	lv_appr_lvl_hdr_id NUMBER;
	lv_max_value       NUMBER;
	LV_DEPARTMENT      VARCHAR2(1000);
	
	
	BEGIN
    SELECT
        ch.wf_id,
        ch.claim_amount,
        ch.org_id,
		wh.appr_lvl_hdr_id,
        ch.department
     
    INTO
        lv_wf_id,
        lv_claim_amount,
        lv_org_id,
        lv_appr_lvl_hdr_id,
        LV_DEPARTMENT
        
    FROM
        xxtwc_claims_headers ch , xxtwc_claims_appr_wf_header wh
    WHERE 
	    ch.wf_id = wh.wf_id
    AND claim_id = p_claim_id;
	
		
		SELECT COUNT(1) INTO LV_SUPER_APPROVER 
    FROM XXTWC_CLAIMS_ROLES CR,XXTWC_CLAIMS_USER_ROLES UR 
                WHERE CR.ROLE_ID = UR.ROLE_ID
				AND CR.ROLE_NAME = 'Super Approver'
                AND USER_ID = p_user_id;
	
	/*Getting Next Approval Level For Missing Lot Approval*/
	
	 BEGIN
	 SELECT 
	 TO_CHAR(GROUP_ID) 
	 INTO LV_GROUP_ID
	 FROM XXTWC_CLAIMS_APPR_GROUPS 
     WHERE GROUP_NAME = 'Import Claim Owner Approval';
	 EXCEPTION WHEN OTHERS
	 THEN  LV_GROUP_ID := NULL;
	 END;
	 
	  BEGIN
            SELECT
                ald.max_value
            INTO lv_max_value
            FROM
                xxtwc_claims_appr_lvl_dtl ald,
                xxtwc_claims_appr_lvl_hdr alh
            WHERE
                    ald.appr_lvl_hdr_id = alh.appr_lvl_hdr_id
                AND alh.appr_lvl_hdr_id = lv_appr_lvl_hdr_id
                AND nvl(ald.min_value, 0) = 0
                AND alh.org_id = lv_org_id; 

        EXCEPTION
            WHEN OTHERS THEN
                lv_max_value := 0;
        END;

               IF p_action = 'Missing Lot Approved'
		       THEN 
               xxtwc_claims_wf_pkg.xxtwc_insert_log(
                p_wf_id => lv_wf_id,
                p_action => p_action,                    
                p_actioned_by => p_actioned_by, 
                p_seq => p_seq,      
                p_message => p_message,    
                p_start_date => systimestamp, 
                p_end_date => systimestamp, 
                p_user_comments => (CASE WHEN p_user_comments IS NULL 
				AND LV_SUPER_APPROVER > 0
				THEN 'Claim approval performed by Super Approver role'
                ELSE  p_user_comments 
                END),			 
                p_claim_id => p_claim_id, 
                p_user_id => p_user_id, 
                p_group_id => p_user_id  
            );	
			
        IF lv_max_value >= lv_claim_amount AND LV_DEPARTMENT NOT IN ('OPERATIONS','QUALITY') 
			THEN 
			UPDATE xxtwc_claims_headers
            SET
                wf_next_seq_no = 13, 
                claim_status = 'Submitted', 
                CLAIM_SUB_STATUS ='Pending for Finance Approval'        
            WHERE
                claim_id = p_claim_id;
				
            ELSE	
			
			UPDATE xxtwc_claims_headers
            SET
                wf_next_seq_no = 11, 
                claim_status = 'Submitted', 
                CLAIM_SUB_STATUS ='Pending for Claim Owner Approval'        
            WHERE
                claim_id = p_claim_id; 
			
		END IF;		
				/*BEGIN
                xxtwc_claims_outbound_pkg.main_proc(p_claim_id,l_error);
                IF l_error IS NOT NULL THEN
                    raise_application_error('-20000',l_error);
                    apex_error.add_error (
                        p_message          => l_error,
                        p_display_location => apex_error.c_inline_in_notification 
                    );
                END IF;

            END;*/
			ELSE
			
	        UPDATE xxtwc_claims_headers
            SET
			wf_next_seq_no = 15, 
            claim_status = 'Rejected',  
            CLAIM_SUB_STATUS ='Rejected'     
            WHERE
                claim_id = p_claim_id;  
            
             xxtwc_claims_wf_pkg.xxtwc_insert_log(
                p_wf_id => lv_wf_id,
                p_action => p_action,  
                p_actioned_by => p_actioned_by, 
                p_seq => p_seq,       
                p_message => p_message,    
                p_start_date => systimestamp, 
                p_end_date => systimestamp, 
                p_user_comments => p_user_comments,    
                p_claim_id => p_claim_id, 
                p_user_id => p_user_id, 
                p_group_id => p_group_id  
            );	
            
          UPDATE XXTWC_CLAIMS_APPR_WF_ACT_LOG
		  SET STATUS = 0
		  WHERE CLAIM_ID = p_claim_id
		  AND SEQ = p_seq
          AND WF_ID = p_wf_id;			
		  END IF;
		EXCEPTION WHEN OTHERS
          THEN 
          XXTWC_CLAIMS_GP_ERROR_PKG.GP_ERROR_LOG ('Error in Missing Lot Approve/Reject',
                             SQLCODE,   
							 SQLERRM, 
							 V('APP_USER'),
                             35,
							 p_claim_id
                             );
END XXTWC_MISSING_LOT_APPROVAL;
------------------------------------------------------------------------------------
PROCEDURE XXTWC_INSERT_CLAIMS_REASSIGN_APPROVAL (
	p_claim_id           NUMBER,
	p_reassign_to        NUMBER,
	p_ra_group_id           VARCHAR2
	) IS
	
	lv_wf_id           NUMBER;
    lv_claim_amount    NUMBER;
	lv_seq             NUMBER;
	lv_wf_next_seq_no  NUMBER;
	lv_count           NUMBER;
	
    BEGIN
	
	SELECT
	     wf_id,
		 wf_next_seq_no
	INTO
	     lv_wf_id,
		 lv_wf_next_seq_no
	FROM
        xxtwc_claims_headers
		WHERE claim_id = p_claim_id;
		
	/*SELECT
		seq
	INTO 
		lv_seq
	FROM 
		XXTWC_CLAIMS_APPR_WF_DETAILS
		WHERE wf_id = lv_wf_id;*/
	
	
	
	   -- IF p_action = 'Reassign Approver'
		       --THEN 
               xxtwc_claims_wf_pkg.xxtwc_insert_log(
                p_wf_id => lv_wf_id,
                p_action => 'Reassign Approver',                    
                p_actioned_by => V('P0_USER_ID'), 
                p_seq => lv_wf_next_seq_no,     
                p_message => NULL,    
                p_start_date => systimestamp, 
                p_end_date => systimestamp, 
                p_user_comments => 'Reassigned Approver to ' || xxtwc_claims_user_registration_pkg.get_user_name(p_reassign_to),			 
                p_claim_id => p_claim_id, 
                p_user_id => V('P0_USER_ID'), 
                p_group_id => NULL  
            );	
	
	Select 
	count(1) 
	into 
	lv_count
	from XXTWC_CLAIMS_REASSIGN_APPROVAL
	 where claim_id = p_claim_id 
	 and   wf_next_seq_no = lv_wf_next_seq_no
     and   status = 1;
	 
	 If lv_count = 0
	 then 
  /*Insert Data into Claims Reassign Approval Table */  
	INSERT INTO XXTWC_CLAIMS_REASSIGN_APPROVAL (
			--reassign_id,
			claim_id,
			wf_next_seq_no,
			reassign_to,
			reassign_by,
			creation_date,
			created_by,
			last_update_date,
			last_updated_by,
            status,
			group_id
		) VALUES (
			p_claim_id,
			lv_wf_next_seq_no,                    --p_wf_next_seq_no,
			p_reassign_to,
			V('P0_USER_ID'),                      ---p_reassign_by,
			SYSDATE,
			V('P0_USER_ID'),
			SYSDATE,
			V('P0_USER_ID'),
			1,
			p_ra_group_id
		);

		COMMIT;
		
		else
		
		UPDATE XXTWC_CLAIMS_REASSIGN_APPROVAL
		SET
			reassign_to = p_reassign_to,
			reassign_by = V('P0_USER_ID'),
            group_id = 	p_ra_group_id      
		WHERE claim_id = p_claim_id
		AND wf_next_seq_no = lv_wf_next_seq_no;
		
		END IF;
    --END IF;
	END XXTWC_INSERT_CLAIMS_REASSIGN_APPROVAL;
    
    
    
-----------------------------------------------------------------------------------
FUNCTION GET_CURRENT_APPROVER_GROUP(P_CLAIM_ID IN NUMBER,P_ORG_ID IN NUMBER,P_WF_ID IN NUMBER,P_WAREHOUSE_CODE IN VARCHAR2,P_CLAIM_AMOUNT IN NUMBER,P_DEPT IN VARCHAR2) 
RETURN VARCHAR2
IS
LV_GROUP_ID VARCHAR2(1000);

BEGIN
SELECT GROUP_ID 
INTO LV_GROUP_ID
FROM 
(select  
       replace(GROUP_ID,':','') GROUP_ID 
	   from (
              SELECT			
              DISTINCT(ALD.GROUP_ID) GROUP_ID,
              MIN_VALUE,
              NVL((SELECT DECODE(LO.MESSAGE,'Departmental Hierarchy', 'Approved','Skip Due to User Approval limit','Approved', 'Departmental Hierarchy Reject','Rejected','Pending')  --DECODE(LO.STATUS, 1,'Approved',0,'Rejected') 
                   FROM XXTWC_CLAIMS_APPR_WF_ACT_LOG LO 
	               WHERE LO.GROUP_ID = ALD.GROUP_ID
                   AND LO.MESSAGE IN ('Departmental Hierarchy','Skip Due to User Approval limit','Departmental Hierarchy Reject')
                   AND CLAIM_ID = P_CLAIM_ID),'Pending') 
                   STATUS
FROM 
XXTWC_CLAIMS_APPR_LVL_DTL ALD, XXTWC_CLAIMS_APPR_LVL_HDR ALH, XXTWC_CLAIMS_APPR_WF_HEADER WH 
WHERE ALH.APPR_LVL_HDR_ID = ALD.APPR_LVL_HDR_ID
AND ALH.APPR_LVL_HDR_ID = WH.APPR_LVL_HDR_ID
AND WH.WF_ID = P_WF_ID
AND ((P_CLAIM_AMOUNT <= ALD.MAX_VALUE 
AND  P_CLAIM_AMOUNT >= (CASE WHEN ALD.ATTRIBUTE1 = 1 AND UPPER(P_DEPT) IN ('OPERATIONS','QUALITY') THEN 0 ELSE ALD.MIN_VALUE END )


)
OR  P_CLAIM_AMOUNT > ALD.MAX_VALUE)

AND ALD.GROUP_ID  IS NOT NULL
AND ALH.ORG_ID = P_ORG_ID
order by MIN_VALUE ASC)
WHERE STATUS ='Pending' )
WHERE ROWNUM<2;

RETURN LV_GROUP_ID;


END GET_CURRENT_APPROVER_GROUP;



END XXTWC_CLAIMS_WF_PKG;
/