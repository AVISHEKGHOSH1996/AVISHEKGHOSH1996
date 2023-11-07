/****************************************************************************************************
	Object Type: 	Package Spec
	Name       :    XXTWC_CLAIMS_GP_ERROR_PKG
	Created by:		Trinamix
	Created On:		06/21/2023
	Description:	Package Spec for error handling XXTWC_CLAIMS_GP_ERROR_PKG
****************************************************************************************************/
    
--------------------------------------------------------
--  DDL for Package XXTWC_CLAIMS_GP_ERROR_PKG
--------------------------------------------------------
create or replace PACKAGE XXTWC_CLAIMS_GP_ERROR_PKG AS
    PROCEDURE GP_ERROR_LOG(
        p_error_type    IN VARCHAR2,
        p_error_code    IN VARCHAR2,
        p_error_msg     IN VARCHAR2,
        p_created_by    IN VARCHAR2,
        p_page_id       IN NUMBER,
        p_claim_id      IN NUMBER
    );
END XXTWC_CLAIMS_GP_ERROR_PKG;

/