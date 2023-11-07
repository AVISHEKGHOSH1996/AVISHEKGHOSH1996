/****************************************************************************************************
	Object Type: 	Package Spec
	Name       :    XXTWC_CLAIMS_OUTBOUND_PKG
	Created by:		Trinamix
	Created On:		06/01/2023
	Description:	Package Spec for Claims applications
	Modified On:	15/09/2023
	Reason:		    Modified for Freight Only claims
****************************************************************************************************/
    
--------------------------------------------------------
--  DDL for Package XXTWC_CLAIMS_OUTBOUND_PKG
--------------------------------------------------------

create or replace PACKAGE  XXTWC_CLAIMS_OUTBOUND_PKG
IS
FUNCTION check_import_item(p_claim_id NUMBER, p_claim_dtl_id NUMBER) RETURN NUMBER;
FUNCTION check_import_item(p_claim_id NUMBER) RETURN NUMBER;
PROCEDURE main_proc
(  p_claim_id  NUMBER ,
   p_error OUT VARCHAR2	);

PROCEDURE rma_upload
(  p_claim_id  NUMBER ,
   p_error OUT VARCHAR2 	);

PROCEDURE so_upload 
(  p_claim_id  NUMBER ,
   p_error OUT VARCHAR2 	);

PROCEDURE unrefer_rma_upload
(  p_claim_id  NUMBER ,
   p_error OUT VARCHAR2 	);

PROCEDURE freight_rma_upload
(  p_claim_id  NUMBER ,
   p_error OUT VARCHAR2 	);

FUNCTION get_claim_type_details 
 ( p_claim_type VARCHAR2,
   p_attribute VARCHAR2)
RETURN VARCHAR2;

FUNCTION get_charge_reason_code 
 ( p_return_reason_code VARCHAR2 )
RETURN VARCHAR2;

PROCEDURE split_line_quantity
(  p_claim_id  NUMBER ,
   p_claim_dtl_id NUMBER ,
   p_fulfill_id NUMBER,
   p_claim_qty NUMBER   );
   
PROCEDURE credit_rma_upload
(  p_claim_id  NUMBER ,
   p_error OUT VARCHAR2 	);
   
PROCEDURE ci_so_upload
(  p_claim_id  NUMBER ,
   p_error OUT VARCHAR2 	);

END XXTWC_CLAIMS_OUTBOUND_PKG;

/