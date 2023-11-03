/****************************************************************************************************
	Object Type: 	Package Body
	Name       :    XXTWC_CLAIMS_GP_ERROR_PKG
	Created by:		Trinamix
	Created On:		06/21/2023
	Description:	Package for error handling
****************************************************************************************************/
 
--------------------------------------------------------
--  DDL for Package Body XXTWC_CLAIMS_GP_ERROR_PKG
--------------------------------------------------------
create or replace PACKAGE BODY "XXTWC_CLAIMS_GP_ERROR_PKG"
AS 
    PROCEDURE GP_ERROR_LOG (p_error_type   IN VARCHAR2, 
                             p_error_code   IN VARCHAR2,     
                             p_error_msg    IN VARCHAR2, 
                             p_created_by   IN VARCHAR2,
                             P_page_id      IN NUMBER,
							 p_claim_id     IN NUMBER
                             ) 
    AS 
        tindex        NUMBER; 
        lerrmsg       VARCHAR2 (4000); 
        lerrmsg_msg   VARCHAR2 (50) := 'GP_ERROR_LOG'; 
        PRAGMA AUTONOMOUS_TRANSACTION; 
    BEGIN 
        INSERT INTO XXTWC_CLAIMS_GP_COMMON_ERROR_TB (error_id, 
                                               ERROR_TYPE, 
                                               ERROR_code, 
                                               error_msg, 
                                               created_by, 
                                               created_date_time,
                                               page_id,
											   CLAIM_ID) 
             VALUES (XXTWC_CLAIMS_GP_COMMON_ERROR_SEQ.NEXTVAL, 
                     p_error_type, 
                     p_error_code, 
                     p_error_msg, 
                     p_created_by, 
                     SYSTIMESTAMP,
                     P_page_id,
					 p_claim_id); 
        COMMIT; 
    EXCEPTION 
        WHEN OTHERS 
        THEN 
            lerrmsg := SQLERRM; 
            INSERT INTO XXTWC_CLAIMS_GP_COMMON_ERROR_TB (error_id, 
                                                   ERROR_TYPE, 
                                                   ERROR_code, 
                                                   error_msg, 
                                                   created_by, 
                                                   created_date_time,
                                                   page_id,
												   CLAIM_ID) 
                 VALUES (XXTWC_CLAIMS_GP_COMMON_ERROR_SEQ.NEXTVAL, 
                         p_error_type, 
                         p_error_code, 
                         lerrmsg || ' - ' || lerrmsg_msg, 
                         p_created_by, 
                         SYSTIMESTAMP,
                         P_page_id,
						 p_claim_id); 
            COMMIT; 
    END GP_ERROR_LOG; 
END XXTWC_CLAIMS_GP_ERROR_PKG;
/