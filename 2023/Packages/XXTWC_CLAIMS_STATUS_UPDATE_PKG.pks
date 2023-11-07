/****************************************************************************************************
	Object Type: 	Package Spec
	Name       :    XXTWC_CLAIMS_STATUS_UPDATE_PKG
	Created by:		Trinamix
	Created On:		06/01/2023
	Description:	Package Spec to update claim status based on Oracle Order status
	Modified On:	
	Reason:		    
****************************************************************************************************/
  
--------------------------------------------------------
--  DDL for Package XXTWC_CLAIMS_STATUS_UPDATE_PKG
--------------------------------------------------------

CREATE OR REPLACE EDITIONABLE PACKAGE "CLAIMS"."XXTWC_CLAIMS_STATUS_UPDATE_PKG" 
IS

PROCEDURE update_status;  

PROCEDURE update_claim_status(p_claim_id NUMBER); 
END xxtwc_claims_status_update_pkg;

/