/****************************************************************************************************
	Object Type: 	Package Spec
	Name       :    XXTWC_CLAIMS_VALIDATION_PKG
	Created by:		Trinamix
	Created On:		06/01/2023
	Description:	Package spec for XXTWC_CLAIMS_VALIDATION_PKG
	Modified On:	
	Reason:		    
****************************************************************************************************/
 
--------------------------------------------------------
--  DDL for Package XXTWC_CLAIMS_VALIDATION_PKG
--------------------------------------------------------
create or replace PACKAGE  XXTWC_CLAIMS_VALIDATION_PKG
IS
PROCEDURE claim_submit (
    p_claim_id  IN NUMBER,
    p_status    OUT VARCHAR2,
    p_error_msg OUT VARCHAR2
);

FUNCTION validate_claim_total RETURN VARCHAR2;

FUNCTION validate_reason_code RETURN VARCHAR2;

FUNCTION validate_claim_reason_code(
    p_claim_id IN NUMBER
)RETURN VARCHAR2;

FUNCTION validate_claim_qty_against_request_qty (
    p_claim_qty          IN NUMBER,
    p_requested_quantity IN NUMBER,
    p_claim_type         IN VARCHAR2
) RETURN VARCHAR2;

FUNCTION validate_claim_qty_against_returnable_qty (
    p_claim_type IN VARCHAR2
) RETURN VARCHAR2;

FUNCTION validate_document_catagory (
    p_claim_type   IN VARCHAR2,
    p_doc_catagory IN VARCHAR2
) RETURN VARCHAR2;

FUNCTION validation_reason_deparment RETURN VARCHAR2;

FUNCTION validation_freight_reason_deparment RETURN VARCHAR2;

FUNCTION validate_document_note(
    p_doc_cat IN VARCHAR2,
    p_note IN VARCHAR2
) RETURN VARCHAR2;

FUNCTION validate_document_file(
    p_doc_cat IN VARCHAR2,
    p_file IN VARCHAR2
) RETURN VARCHAR2;

FUNCTION validate_attachement(
    p_claim_type IN VARCHAR2
) RETURN VARCHAR2;

FUNCTION validate_picture_document_cr RETURN VARCHAR2;

FUNCTION validate_picture_document_ud(
    p_claim_id IN NUMBER
) RETURN VARCHAR2;

FUNCTION validate_document_fot_dump(
    p_claim_id in number,
    p_claim_type in varchar2
) return VARCHAR2;

FUNCTION validation_for_rebill_price(
    p_claim_id IN NUMBER
)RETURN VARCHAR2;

	FUNCTION validation_for_claim_qty_sum(
    p_claim_id IN NUMBER
)RETURN VARCHAR2;

	FUNCTION validation_for_claim_qty_negative(
    p_claim_id IN NUMBER
)RETURN VARCHAR2;

END XXTWC_CLAIMS_VALIDATION_PKG;
/