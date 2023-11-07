/****************************************************************************************************
	Object Type: 	Package Spec
	Name       :    XXTWC_CLAIMS_REPORT_PKG
	Created by:		Trinamix
	Created On:		06/01/2023
	Description:	Package Spec for Claims Approval Report
	Modified On:	06/12/2023
	Reason:		    Generated Report Query From Package
****************************************************************************************************/
   
--------------------------------------------------------
--  DDL for Package XXTWC_CLAIMS_REPORT_PKG
--------------------------------------------------------

create or replace PACKAGE  XXTWC_CLAIMS_REPORT_PKG
IS
FUNCTION PENDING_FOR_APPROVAL (

p_group_id IN VARCHAR2,
p_org_id IN NUMBER,
p_query1 OUT VARCHAR2,
p_query OUT VARCHAR2)
RETURN NUMBER;

FUNCTION APPROVAL (

p_group_id IN VARCHAR2,
p_org_id IN NUMBER,
p_query1 OUT VARCHAR2,
p_query OUT VARCHAR2)
RETURN NUMBER; 

FUNCTION REJECTED (

p_group_id IN VARCHAR2,
p_org_id IN NUMBER,
p_query1 OUT VARCHAR2,
p_query OUT VARCHAR2)

RETURN NUMBER;

END XXTWC_CLAIMS_REPORT_PKG;
/