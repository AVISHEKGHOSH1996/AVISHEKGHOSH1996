/****************************************************************************************************
	Object Type: 	Package Body
	Name       :    XXTWC_CLAIMS_REPORT_PKG
	Created by:		Trinamix
	Created On:		06/01/2023
	Description:	Package Body for Claims Approval Report
	Modified On:	06/12/2023
	Reason:		    Generated Report Query From Package
****************************************************************************************************/

--------------------------------------------------------
--  DDL for Package Body XXTWC_CLAIMS_REPORT_PKG
--------------------------------------------------------
create or replace PACKAGE BODY XXTWC_CLAIMS_REPORT_PKG IS
FUNCTION PENDING_FOR_APPROVAL (

p_group_id IN VARCHAR2,
p_org_id IN NUMBER,
p_query1 OUT VARCHAR2,
p_query OUT VARCHAR2)

RETURN NUMBER
IS

--lv_query VARCHAR2(4000);

BEGIN
p_query1 := q'#(select CH.CLAIM_ID,
       CH.CLAIM_NUMBER,
       CH.CLAIM_REVISION_NUMBER,
       CH.CLAIM_DATE,
       CH.ORG_ID,
       CH.BU_NAME,
       (SELECT distinct hp_sales.party_name salesperson_name
    FROM fusion.jtf_rs_salesreps jrs,
        fusion.hz_parties hp_sales
    WHERE jrs.resource_id = hp_sales.party_id
    AND hp_sales.party_id = CH.SALES_PERSON_ID
    AND jrs.status ='A'
    AND hp_sales.status ='A'
    AND SYSDATE BETWEEN jrs.start_date_active and jrs.end_date_active) SALESPERSON,
        (select LOOKUP_VALUE from XXTWC_CLAIMS_LOOKUPS where LOOKUP_TYPE='CLAIM_TYPE' and LOOKUP_NAME=CH.CLAIM_TYPE) claim_type_desc,
       CH.CLAIM_AMOUNT,
       HD.WF_NAME,
       CH.CLAIM_STATUS,
       (SELECT U.EMAIL_ID FROM CLAIMS.XXTWC_CLAIMS_USER_LOGIN_DETAILS U WHERE U.USER_ID = CH.CREATED_BY) CREATED_BY,
       
(SELECT LISTAGG(GROUP_NAME, ', ') WITHIN GROUP (ORDER BY GROUP_NAME DESC) GROUP_NAME FROM XXTWC_CLAIMS_APPR_GROUPS GP 
WHERE to_number(GP.GROUP_ID) IN (SELECT RESULTS
 FROM (select regexp_substr((SELECT GROUP_ID 
				  FROM
	            (SELECT 
				GROUP_ID 
				FROM 
				CLAIMS.XXTWC_CLAIMS_APPR_LVL_DTL ALD, CLAIMS.XXTWC_CLAIMS_APPR_LVL_HDR ALH
	            WHERE ALH.APPR_LVL_HDR_ID = ALD.APPR_LVL_HDR_ID
				AND  HD.APPR_LVL_HDR_ID = ALH.APPR_LVL_HDR_ID
				AND ((CH.CLAIM_AMOUNT <= ALD.MAX_VALUE 
				AND CH.CLAIM_AMOUNT >= ALD.MIN_VALUE)
				OR CH.CLAIM_AMOUNT > ALD.MAX_VALUE) 
				AND NOT EXISTS (SELECT 1 FROM XXTWC_CLAIMS_APPR_WF_ACT_LOG LO
				WHERE LO.SEQ = CH.WF_NEXT_SEQ_NO AND LO.GROUP_ID = ALD.GROUP_ID 
                AND LO.WF_ID = CH.WF_ID AND LO.CLAIM_ID = CH.CLAIM_ID AND LO.STATUS <> 0)
				AND ALD.GROUP_ID  IS NOT NULL
				ORDER BY ALD.MAX_VALUE ASC)
				WHERE ROWNUM < 2), '[^:]+', 1, level) results
			from dual
				connect by level <= length(regexp_replace((SELECT GROUP_ID 
				  FROM
	            (SELECT 
				GROUP_ID 
				FROM 
				CLAIMS.XXTWC_CLAIMS_APPR_LVL_DTL ALD, CLAIMS.XXTWC_CLAIMS_APPR_LVL_HDR ALH
	            WHERE ALH.APPR_LVL_HDR_ID = ALD.APPR_LVL_HDR_ID
				AND  HD.APPR_LVL_HDR_ID = ALH.APPR_LVL_HDR_ID
				AND ((CH.CLAIM_AMOUNT <= ALD.MAX_VALUE 
				AND CH.CLAIM_AMOUNT >= ALD.MIN_VALUE)
				OR CH.CLAIM_AMOUNT > ALD.MAX_VALUE) 
				AND NOT EXISTS (SELECT 1 FROM XXTWC_CLAIMS_APPR_WF_ACT_LOG LO
				WHERE LO.SEQ = CH.WF_NEXT_SEQ_NO AND LO.GROUP_ID = ALD.GROUP_ID 
                AND LO.WF_ID = CH.WF_ID AND LO.CLAIM_ID = CH.CLAIM_ID AND LO.STATUS <> 0)
				AND ALD.GROUP_ID  IS NOT NULL
				ORDER BY ALD.MAX_VALUE ASC)
				WHERE ROWNUM < 2), '[^:]+')) + 1)#';
				
p_query := q'# WHERE RESULTS IN (


                select to_number(regexp_substr( #'||p_group_id || q'# /*:P0_GROUP_ID*/, '[^:]+', 1, level)) result
			from DUAL
				connect by level <= length(regexp_replace(#'||p_group_id || q'# /*:P0_GROUP_ID*/, '[^:]+')) + 1)) )) AS GROUP_NAME

  from CLAIMS.XXTWC_CLAIMS_HEADERS CH ,XXTWC_CLAIMS_APPR_WF_HEADER HD
  
  WHERE HD.WF_ID = CH.WF_ID
  AND CH.WF_NEXT_SEQ_NO = (SELECT WD.SEQ FROM XXTWC_CLAIMS_APPR_WF_DETAILS WD 
                                     WHERE WD.WF_ID = CH.WF_ID 
                                     AND UPPER(WD.STEP_NAME) = UPPER('Approval'))


AND ((EXISTS (SELECT 1 FROM (select regexp_substr((SELECT GROUP_ID 
				  FROM
	            (SELECT 
				GROUP_ID 
				FROM 
				CLAIMS.XXTWC_CLAIMS_APPR_LVL_DTL ALD, CLAIMS.XXTWC_CLAIMS_APPR_LVL_HDR ALH
	            WHERE ALH.APPR_LVL_HDR_ID = ALD.APPR_LVL_HDR_ID
				AND  HD.APPR_LVL_HDR_ID = ALH.APPR_LVL_HDR_ID
				AND ((CH.CLAIM_AMOUNT <= ALD.MAX_VALUE 
				AND CH.CLAIM_AMOUNT >= ALD.MIN_VALUE)
				OR CH.CLAIM_AMOUNT > ALD.MAX_VALUE) 
				AND NOT EXISTS (SELECT 1 FROM XXTWC_CLAIMS_APPR_WF_ACT_LOG LO
				WHERE LO.SEQ = CH.WF_NEXT_SEQ_NO AND LO.GROUP_ID = ALD.GROUP_ID 
                AND LO.WF_ID = CH.WF_ID AND LO.CLAIM_ID = CH.CLAIM_ID AND LO.STATUS <> 0)
				AND ALD.GROUP_ID  IS NOT NULL
				ORDER BY ALD.MAX_VALUE ASC)
				WHERE ROWNUM < 2), '[^:]+', 1, level) results
			from dual
				connect by level <= length(regexp_replace((SELECT GROUP_ID 
				  FROM
	            (SELECT 
				GROUP_ID 
				FROM 
				CLAIMS.XXTWC_CLAIMS_APPR_LVL_DTL ALD, CLAIMS.XXTWC_CLAIMS_APPR_LVL_HDR ALH
	            WHERE ALH.APPR_LVL_HDR_ID = ALD.APPR_LVL_HDR_ID
				AND  HD.APPR_LVL_HDR_ID = ALD.APPR_LVL_HDR_ID
				AND ((CH.CLAIM_AMOUNT <= ALD.MAX_VALUE 
				AND CH.CLAIM_AMOUNT >= ALD.MIN_VALUE)
				OR CH.CLAIM_AMOUNT > ALD.MAX_VALUE) 
				AND NOT EXISTS (SELECT 1 FROM XXTWC_CLAIMS_APPR_WF_ACT_LOG LO
				WHERE LO.SEQ = CH.WF_NEXT_SEQ_NO AND LO.GROUP_ID = ALD.GROUP_ID 
                AND LO.WF_ID = CH.WF_ID AND LO.CLAIM_ID = CH.CLAIM_ID AND LO.STATUS <> 0)
				AND ALD.GROUP_ID  IS NOT NULL
				ORDER BY ALD.MAX_VALUE ASC)
				WHERE ROWNUM < 2), '[^:]+')) + 1)
                WHERE results IN (select regexp_substr(#'||p_group_id || q'# /*:P0_GROUP_ID*/, '[^:]+', 1, level) result
			from DUAL
				connect by level <= length(regexp_replace(#'||p_group_id || q'# /*:P0_GROUP_ID*/, '[^:]+')) + 1)
				 )
				 AND NVL(HD.DIRECT_FLAG,0) = 0)
	
	OR (EXISTS (SELECT 1 FROM (select regexp_substr((SELECT GROUP_ID 
				  FROM
	            (SELECT 
				GROUP_ID 
				FROM 
				CLAIMS.XXTWC_CLAIMS_APPR_LVL_DTL ALD, CLAIMS.XXTWC_CLAIMS_APPR_LVL_HDR ALH
	            WHERE ALH.APPR_LVL_HDR_ID = ALD.APPR_LVL_HDR_ID
				AND  HD.APPR_LVL_HDR_ID = ALD.APPR_LVL_HDR_ID
				AND (CH.CLAIM_AMOUNT <= ALD.MAX_VALUE 
				AND CH.CLAIM_AMOUNT >= ALD.MIN_VALUE)
				AND ALD.GROUP_ID  IS NOT NULL
				ORDER BY ALD.MAX_VALUE ASC)
				WHERE ROWNUM < 2), '[^:]+', 1, level) results
			from dual
				connect by level <= length(regexp_replace((SELECT GROUP_ID 
				  FROM
	            (SELECT 
				GROUP_ID 
				FROM 
				CLAIMS.XXTWC_CLAIMS_APPR_LVL_DTL ALD, CLAIMS.XXTWC_CLAIMS_APPR_LVL_HDR ALH
	            WHERE ALH.APPR_LVL_HDR_ID = ALD.APPR_LVL_HDR_ID
				AND  HD.APPR_LVL_HDR_ID = ALD.APPR_LVL_HDR_ID
				AND (CH.CLAIM_AMOUNT <= ALD.MAX_VALUE 
				AND CH.CLAIM_AMOUNT >= ALD.MIN_VALUE)
				AND ALD.GROUP_ID  IS NOT NULL
				ORDER BY ALD.MAX_VALUE ASC)
				WHERE ROWNUM < 2), '[^:]+')) + 1)
                WHERE results IN (select regexp_substr(#'||p_group_id ||q'# /*:P0_GROUP_ID*/, '[^:]+', 1, level) result
			from DUAL
				connect by level <= length(regexp_replace(#'||p_group_id || q'# /*:P0_GROUP_ID*/, '[^:]+')) + 1)
				 )
				 AND NVL(HD.DIRECT_FLAG,0) = 1))
				  AND CH.ORG_ID = #'||p_org_id ||q'# --:P0_ORG_ID
                order by CH.CLAIM_ID desc#';
				
				
        RETURN 0;
END PENDING_FOR_APPROVAL;
----------------------------------------------
/*Approved report*/
FUNCTION APPROVAL (

p_group_id IN VARCHAR2,
p_org_id IN NUMBER,
p_query1 OUT VARCHAR2,
p_query OUT VARCHAR2)

RETURN NUMBER
IS
--lv_query VARCHAR2(4000);

BEGIN
p_query1 := q'#select CH.CLAIM_ID,
       CH.CLAIM_NUMBER,
       CH.CLAIM_REVISION_NUMBER,
       CH.CLAIM_DATE,
       CH.ORG_ID,
       CH.BU_NAME,
       (select LOOKUP_VALUE from XXTWC_CLAIMS_LOOKUPS where LOOKUP_TYPE='CLAIM_TYPE' and LOOKUP_NAME=CH.CLAIM_TYPE) claim_type,
       CH.CLAIM_AMOUNT,
       HD.WF_NAME,
       CH.CLAIM_STATUS,
       (SELECT distinct hp_sales.party_name salesperson_name
    FROM fusion.jtf_rs_salesreps jrs,
        fusion.hz_parties hp_sales
    WHERE jrs.resource_id = hp_sales.party_id
    AND hp_sales.party_id = CH.SALES_PERSON_ID
    AND jrs.status ='A'
    AND hp_sales.status ='A'
    AND SYSDATE BETWEEN jrs.start_date_active and jrs.end_date_active) SALESPERSON,
       (SELECT U.EMAIL_ID FROM CLAIMS.XXTWC_CLAIMS_USER_LOGIN_DETAILS U WHERE U.USER_ID = CH.CREATED_BY) CREATED_BY
      
  from CLAIMS.XXTWC_CLAIMS_HEADERS CH, CLAIMS.XXTWC_CLAIMS_APPR_WF_HEADER HD
  WHERE HD.WF_ID = CH.WF_ID
  AND ((CH.WF_NEXT_SEQ_NO = (SELECT WD.SEQ FROM XXTWC_CLAIMS_APPR_WF_DETAILS WD 
                                     WHERE WD.WF_ID = CH.WF_ID 
                                     AND UPPER(WD.STEP_NAME) = UPPER('Approval'))


  AND EXISTS (SELECT 1 FROM (select regexp_substr(
	            (SELECT LISTAGG((GROUP_ID), ':') WITHIN GROUP (ORDER BY GROUP_ID
	            ) "Product_Listing"
 FROM (SELECT 
				ALD.GROUP_ID 
				FROM 
				CLAIMS.XXTWC_CLAIMS_APPR_LVL_DTL ALD, CLAIMS.XXTWC_CLAIMS_APPR_LVL_HDR ALH
	            WHERE ALH.APPR_LVL_HDR_ID = ALD.APPR_LVL_HDR_ID
                AND HD.APPR_LVL_HDR_ID = ALH.APPR_LVL_HDR_ID
                AND ((CH.CLAIM_AMOUNT <= ALD.MAX_VALUE 
				AND CH.CLAIM_AMOUNT >= ALD.MIN_VALUE)
				OR CH.CLAIM_AMOUNT > ALD.MAX_VALUE) 
				AND  EXISTS (SELECT 1 FROM XXTWC_CLAIMS_APPR_WF_ACT_LOG LO
				WHERE LO.SEQ = CH.WF_NEXT_SEQ_NO AND LO.GROUP_ID = ALD.GROUP_ID 
                AND LO.WF_ID = CH.WF_ID AND LO.CLAIM_ID = CH.CLAIM_ID AND LO.STATUS <> 0)
				AND ALD.GROUP_ID  IS NOT NULL)), '[^:]+', 1, level) result
			from dual
				connect by level <= length(regexp_replace(
	            (SELECT LISTAGG((GROUP_ID), ':') WITHIN GROUP (ORDER BY GROUP_ID
	            ) "Product_Listing"
FROM (SELECT 
				ALD.GROUP_ID 
				FROM 
				CLAIMS.XXTWC_CLAIMS_APPR_LVL_DTL ALD, CLAIMS.XXTWC_CLAIMS_APPR_LVL_HDR ALH
	            WHERE ALH.APPR_LVL_HDR_ID = ALD.APPR_LVL_HDR_ID
				AND  HD.APPR_LVL_HDR_ID = ALH.APPR_LVL_HDR_ID
				AND ((CH.CLAIM_AMOUNT <= ALD.MAX_VALUE 
				AND CH.CLAIM_AMOUNT>= ALD.MIN_VALUE)
				OR CH.CLAIM_AMOUNT > ALD.MAX_VALUE) 
				AND  EXISTS (SELECT 1 FROM XXTWC_CLAIMS_APPR_WF_ACT_LOG LO
				WHERE LO.SEQ = CH.WF_NEXT_SEQ_NO AND LO.GROUP_ID = ALD.GROUP_ID 
                AND LO.WF_ID = CH.WF_ID AND LO.CLAIM_ID = CH.CLAIM_ID AND LO.STATUS <> 0)
				AND ALD.GROUP_ID  IS NOT NULL)), '[^:]+')) + 1)#';
         p_query := q'# WHERE result IN (select regexp_substr(#'||p_group_id ||q'# /*:P0_GROUP_ID*/, '[^:]+', 1, level) result
			from DUAL
				connect by level <= length(regexp_replace(#'||p_group_id ||q'# /*:P0_GROUP_ID*/, '[^:]+')) + 1)))
				
				OR
                (CH.WF_NEXT_SEQ_NO > (SELECT WD.SEQ FROM XXTWC_CLAIMS_APPR_WF_DETAILS WD 
                                     WHERE WD.WF_ID = CH.WF_ID
                                    AND UPPER(WD.STEP_NAME) = UPPER('Approval') )
                AND  EXISTS (SELECT 1 FROM XXTWC_CLAIMS_APPR_WF_ACT_LOG LO
				WHERE EXISTS (SELECT 1 FROM (select regexp_substr(LO.GROUP_ID, '[^:]+', 1, level) result
			from dual
				connect by level <= length(regexp_replace(LO.GROUP_ID, '[^:]+')) + 1
               ) WHERE result IN (select regexp_substr(#'||p_group_id ||q'# /*:P0_GROUP_ID*/, '[^:]+', 1, level) result
			from DUAL
				connect by level <= length(regexp_replace(#'||p_group_id ||q'# /*:P0_GROUP_ID*/, '[^:]+')) + 1)  AND
                     LO.WF_ID = CH.WF_ID AND LO.CLAIM_ID = CH.CLAIM_ID AND LO.STATUS <> 0 ))))
                     AND CH.ORG_ID = #'||p_org_id ||q'# --:P0_ORG_ID
                     order by CH.CLAIM_ID desc #';
					 
				RETURN 0;	 

END APPROVAL;

------------------------------
/*Rejected*/
FUNCTION REJECTED (

p_group_id IN VARCHAR2,
p_org_id IN NUMBER,
p_query1 OUT VARCHAR2,
p_query OUT VARCHAR2)

RETURN NUMBER
IS
--lv_query VARCHAR2(4000);

BEGIN
p_query1 := q'# select CH.CLAIM_ID,
       CH.CLAIM_NUMBER,
       CH.CLAIM_REVISION_NUMBER,
       CH.CLAIM_DATE,
       CH.ORG_ID,
       CH.BU_NAME,
        (select LOOKUP_VALUE from XXTWC_CLAIMS_LOOKUPS where LOOKUP_TYPE='CLAIM_TYPE' and LOOKUP_NAME=CH.CLAIM_TYPE) claim_type,
       CH.CLAIM_AMOUNT,
       HD.WF_NAME,
       CH.CLAIM_STATUS,
       (SELECT distinct hp_sales.party_name salesperson_name
    FROM fusion.jtf_rs_salesreps jrs,
        fusion.hz_parties hp_sales
    WHERE jrs.resource_id = hp_sales.party_id
    AND hp_sales.party_id = CH.SALES_PERSON_ID
    AND jrs.status ='A'
    AND hp_sales.status ='A'
    AND SYSDATE BETWEEN jrs.start_date_active and jrs.end_date_active) SALESPERSON,
      (SELECT U.EMAIL_ID FROM CLAIMS.XXTWC_CLAIMS_USER_LOGIN_DETAILS U WHERE U.USER_ID = CH.CREATED_BY) CREATED_BY
        
  from CLAIMS.XXTWC_CLAIMS_HEADERS CH , CLAIMS.XXTWC_CLAIMS_APPR_WF_HEADER HD
  WHERE HD.WF_ID = CH.WF_ID
  AND ((CH.WF_NEXT_SEQ_NO = (SELECT WD.SEQ FROM XXTWC_CLAIMS_APPR_WF_DETAILS WD 
                                     WHERE WD.WF_ID = CH.WF_ID 
                                     AND UPPER(WD.STEP_NAME) = UPPER('Approval'))


AND EXISTS (SELECT 1 FROM (select regexp_substr(
	            (SELECT LISTAGG((GROUP_ID), ':') WITHIN GROUP (ORDER BY GROUP_ID
	            ) "Product_Listing"
FROM (SELECT 
				ALD.GROUP_ID 
				FROM 
				CLAIMS.XXTWC_CLAIMS_APPR_LVL_DTL ALD, CLAIMS.XXTWC_CLAIMS_APPR_LVL_HDR ALH
	            WHERE ALH.APPR_LVL_HDR_ID = ALD.APPR_LVL_HDR_ID
				AND  HD.APPR_LVL_HDR_ID = ALH.APPR_LVL_HDR_ID
				AND ((CH.CLAIM_AMOUNT <= ALD.MAX_VALUE 
				AND CH.CLAIM_AMOUNT >= ALD.MIN_VALUE)
				OR CH.CLAIM_AMOUNT > ALD.MAX_VALUE) 
				AND  EXISTS (SELECT 1 FROM XXTWC_CLAIMS_APPR_WF_ACT_LOG LO
				WHERE LO.SEQ = CH.WF_NEXT_SEQ_NO AND LO.GROUP_ID = ALD.GROUP_ID 
                AND LO.WF_ID = CH.WF_ID AND LO.CLAIM_ID = CH.CLAIM_ID AND LO.STATUS = 0)
				AND ALD.GROUP_ID  IS NOT NULL)), '[^:]+', 1, level) result
			from dual
				connect by level <= length(regexp_replace(
	            (SELECT LISTAGG((GROUP_ID), ':') WITHIN GROUP (ORDER BY GROUP_ID
	            ) "Product_Listing"
FROM (SELECT 
				ALD.GROUP_ID 
				FROM 
				CLAIMS.XXTWC_CLAIMS_APPR_LVL_DTL ALD, CLAIMS.XXTWC_CLAIMS_APPR_LVL_HDR ALH
	            WHERE ALH.APPR_LVL_HDR_ID = ALD.APPR_LVL_HDR_ID
				AND  HD.APPR_LVL_HDR_ID = ALH.APPR_LVL_HDR_ID 
				AND ((CH.CLAIM_AMOUNT <= ALD.MAX_VALUE 
				AND CH.CLAIM_AMOUNT>= ALD.MIN_VALUE)
				OR CH.CLAIM_AMOUNT > ALD.MAX_VALUE) 
				AND  EXISTS (SELECT 1 FROM XXTWC_CLAIMS_APPR_WF_ACT_LOG LO
				WHERE LO.SEQ = CH.WF_NEXT_SEQ_NO AND LO.GROUP_ID = ALD.GROUP_ID 
                AND LO.WF_ID = CH.WF_ID AND LO.CLAIM_ID = CH.CLAIM_ID AND LO.STATUS = 0)
				AND ALD.GROUP_ID  IS NOT NULL)), '[^:]+')) + 1)#';
          p_query :=  q'# WHERE result IN (select regexp_substr(#'||p_group_id ||q'# /*:P0_GROUP_ID*/, '[^:]+', 1, level) result
			from DUAL
				connect by level <= length(regexp_replace(#'||p_group_id ||q'# /*:P0_GROUP_ID*/, '[^:]+')) + 1)))
				
				OR
                (WF_NEXT_SEQ_NO > (SELECT WD.SEQ FROM XXTWC_CLAIMS_APPR_WF_DETAILS WD 
                                     WHERE WD.WF_ID = CH.WF_ID
                                    AND UPPER(STEP_NAME) = UPPER('Approval') )
                AND  EXISTS (SELECT 1 FROM XXTWC_CLAIMS_APPR_WF_ACT_LOG LO
				WHERE EXISTS (SELECT 1 FROM (select regexp_substr(LO.GROUP_ID, '[^:]+', 1, level) result
			from dual
				connect by level <= length(regexp_replace(LO.GROUP_ID, '[^:]+')) + 1
               ) WHERE result IN (select regexp_substr(#'||p_group_id ||q'# /*:P0_GROUP_ID*/, '[^:]+', 1, level) result
			from DUAL
				connect by level <= length(regexp_replace(#'||p_group_id ||q'# /*:P0_GROUP_ID*/, '[^:]+')) + 1)  AND
                     LO.WF_ID = CH.WF_ID AND LO.CLAIM_ID = CH.CLAIM_ID AND LO.STATUS = 0 ))))
                     AND CH.ORG_ID = #'||p_org_id ||q'# --:P0_ORG_ID
                     order by CH.CLAIM_ID desc #';
					 
					 RETURN 0;
END REJECTED;
END XXTWC_CLAIMS_REPORT_PKG;

/