/****************************************************************************************************
	Object Type: 	Package Spec
	Name       :    XXTWC_CLAIMS_WF_PKG
	Created by:		Trinamix
	Created On:		06/01/2023
	Description:	Package Spec for Claims Approval Workflows
	Modified On:	06/12/2023
	Reason:		    Modified for Direct Approval
****************************************************************************************************/
   
--------------------------------------------------------
--  DDL for Package XXTWC_CLAIMS_WF_PKG
--------------------------------------------------------

create or replace PACKAGE  XXTWC_CLAIMS_WF_PKG
IS
procedure XXTWC_INSERT_LOG 
( 
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
	);



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
	);

PROCEDURE XXTWC_CLAIM_REVISE (
p_claim_id           IN NUMBER,
p_claim_number		 IN VARCHAR2,
p_revised_claim_id 	 OUT NUMBER
);

PROCEDURE XXTWC_CALL_WF_FOR_SUBMIT_CLAIM (
	p_claim_id          IN NUMBER
	);

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
	);	
	
	
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
	);
	
    FUNCTION GET_CURRENT_APPROVER_EMAILS(
    P_CLAIM_ID         IN  NUMBER,
    P_ORG_ID           IN  NUMBER,
    P_WF_ID            IN  NUMBER,
    P_WAREHOUSE_CODE   IN  VARCHAR2,
    P_CLAIM_AMOUNT     IN  NUMBER,
    P_DEPT             IN  VARCHAR2
    )
    RETURN VARCHAR2
    ;
    
    FUNCTION GET_CURRENT_APPROVER_USER_NAME(
    P_CLAIM_ID         IN  NUMBER,
    P_ORG_ID           IN  NUMBER,
    P_WF_ID            IN  NUMBER,
    P_WAREHOUSE_CODE   IN  VARCHAR2,
    P_CLAIM_AMOUNT     IN  NUMBER,
    P_DEPT             IN  VARCHAR2
    )
    RETURN VARCHAR2
    ;

PROCEDURE XXTWC_CHANGES_AFTER_REVISE_CLAIM(
P_CLAIM_ID IN VARCHAR2)
;

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
	);	

END XXTWC_CLAIMS_WF_PKG;
/