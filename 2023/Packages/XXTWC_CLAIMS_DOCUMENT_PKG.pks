/****************************************************************************************************
	Object Type: 	Package Spec
	Name       :    XXTWC_CLAIMS_DOCUMENT_PKG
	Created by:		Trinamix
	Created On:		06/01/2023
	Description:	Package spec for XXTWC_CLAIMS_DOCUMENT_PKG
	Modified On:	
	Reason:		    
****************************************************************************************************/
  
--------------------------------------------------------
--  DDL for Package XXTWC_CLAIMS_DOCUMENT_PKG
--------------------------------------------------------
create or replace PACKAGE XXTWC_CLAIMS_DOCUMENT_PKG AS
 
    PROCEDURE upload (p_claim_id 				NUMBER,
					  p_base_url                VARCHAR2,
                      p_bucket_name             VARCHAR2,
                      p_category                VARCHAR2,
                      p_file_browser            VARCHAR2,
                      p_notes                   VARCHAR2,
                      p_status              OUT VARCHAR2);
    PROCEDURE upload_from_collection(
                    p_claim_id     NUMBER,
                    p_base_url     VARCHAR2,
                    p_bucket_name  VARCHAR2,
                    p_status       OUT VARCHAR2);
END XXTWC_CLAIMS_DOCUMENT_PKG;
/