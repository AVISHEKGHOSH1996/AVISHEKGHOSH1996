create or replace PACKAGE BODY XXTWC_DW_VENDOR_RATIONALIZATION_UPLOAD_PKG 
AS

PROCEDURE Process_data(P_USER VARCHAR2, P_SESSION VARCHAR2)
IS
    LV_SQLERRM   VARCHAR2(1000);
    LV_COUNT     NUMBER;
    LV_VENDOR_ID_COUNT NUMBER;
    L_CNT NUMBER := 0;
BEGIN
    EXECUTE IMMEDIATE 'TRUNCATE table XXTWC_DW.XXTWC_DW_ERROR_LOG';
        FOR j IN (
            SELECT 
			    vendor_id,                
				vendor_name, 
				datasource_num_id,
				datasource_name, 
				rationalized_vendor_name, 
				classification_status,
				inter_company_flag, 
				reporting_vendor_name,
				supplier_category
			FROM DWC_VENDOR_RATZN_INTERCO_MAP_STG
        ) 
    LOOP
    L_CNT := L_CNT+1;
	BEGIN
	
		SELECT 
			1
		INTO 
			LV_COUNT
		FROM 
			XXEBS_DW.DWC_BUSINESSUNIT_D b
		LEFT JOIN
			XXEBS_DW.dwc_party_d a
			ON b.DATASOURCE_NUM_ID = a.DATASOURCE_NUM_ID
		WHERE a.integration_id = j.vendor_id
		AND b.datasource_num_id = j.datasource_num_id
		AND a.name = j.vendor_name
		AND b.datasource_name = j.datasource_name
        AND (upper(TRIM(j.inter_company_flag)) IN ( 'YES', 'NO', 'Y', 'N')
            OR j.inter_company_flag IS NULL);
        
	EXCEPTION	
	WHEN NO_DATA_FOUND THEN
        LV_COUNT := 0;
        LV_SQLERRM := SQLERRM;
        --p_error_flag  := 'Y';
	END;

	IF	LV_COUNT = 1 THEN   
        SELECT
            COUNT(1) 
		INTO 
			LV_VENDOR_ID_COUNT
        FROM
            xxtwc_dw.dwc_vendor_ratzn_interco_map target
        WHERE target.vendor_id = j.vendor_id
        /*Added by Soumya 18/02/2025*/
        AND target.DATASOURCE_NUM_ID = j.datasource_num_id;

		IF LV_VENDOR_ID_COUNT = 1 THEN 
		UPDATE xxtwc_dw.dwc_vendor_ratzn_interco_map
			SET vendor_name = j.vendor_name,
                datasource_name = j.datasource_name,
                rationalized_vendor_name = j.rationalized_vendor_name,
                classification_status = j.classification_status,
                inter_company_flag = CASE
                                        WHEN  upper(TRIM(j.inter_company_flag)) = 'YES' THEN 'Y'
                                        WHEN  upper(TRIM(j.inter_company_flag)) = 'NO'  THEN 'N'
                                        ELSE j.inter_company_flag END,
                reporting_vendor_name = j.reporting_vendor_name,
                supplier_category  = j.supplier_category,
                LAST_UPDATED_BY    = UPPER(P_USER),
				LAST_UPDATED_ON    = SYSTIMESTAMP
			WHERE vendor_id = j.vendor_id
            /*Added by Soumya 24/02/2025*/
            AND DATASOURCE_NUM_ID = j.datasource_num_id;
        ELSE
            INSERT INTO xxtwc_dw.dwc_vendor_ratzn_interco_map (
                                vendor_id,
                                vendor_name,
                                datasource_num_id,
                                datasource_name,
                                rationalized_vendor_name,
                                classification_status,
                                inter_company_flag,
                                reporting_vendor_name,
                                supplier_category,
                                CREATED_BY,
								CREATED_ON
                            ) 
                            VALUES(
                                j.vendor_id,
                                j.vendor_name,
                                j.datasource_num_id,
                                j.datasource_name,
                                j.rationalized_vendor_name,
                                j.classification_status,
                                    CASE
                                        WHEN upper(TRIM(j.inter_company_flag)) = 'YES' THEN 'Y'
                                        WHEN upper(TRIM(j.inter_company_flag)) = 'NO'  THEN 'N'
                                        ELSE
                                            j.inter_company_flag
                                    END,
                                j.reporting_vendor_name,
                                j.supplier_category,
                                UPPER(P_USER),
								SYSTIMESTAMP);
		END IF;
        ELSE
                   INSERT INTO XXTWC_DW.XXTWC_DW_ERROR_LOG (LINE_NUMBER, MESSAGE, Created_By, Created_on,session_id)
                    VALUES (L_CNT, LV_SQLERRM ||' - '||L_CNT|| ' - ' || ' VENDOR NAME - '||j.vendor_name||  
                    ' || DATASOURCE NAME - '|| j.datasource_name || ' || VENDOR ID - '|| j.vendor_id
                    || ' || DATASOURCE NUM ID - ' || j.datasource_num_id || 
                    ' || Intercompany flag should be either Y or N - '|| j.inter_company_flag ||' - This Combination is Invalid', UPPER(P_USER), SYSDATE, P_SESSION);
                     
	END IF;
    END LOOP;
    COMMIT;
EXCEPTION
    WHEN OTHERS THEN
        LV_SQLERRM := SQLERRM;
        INSERT INTO XXTWC_DW.XXTWC_DW_ERROR_LOG (LINE_NUMBER, MESSAGE, Created_By, Created_on)
        VALUES (L_CNT, LV_SQLERRM , UPPER(P_USER), SYSDATE);
        COMMIT;
END Process_data;

PROCEDURE process_data_stg
                                    ( P_USER IN VARCHAR2,
									  P_UPLOAD_DOC IN VARCHAR2
                                    )
	IS										 
	v_file_name VARCHAR2(200);
	v_mimetype VARCHAR2(200);
	v_blob blob;
    l_count number := 0;
BEGIN
	BEGIN
    	select FILE_NAME, MIME_TYPE, FILE_UPLOAD  
    	into  v_file_name,  v_mimetype, v_blob
    	from DWC_VENDOR_RATZN_INTERCO_MAP_STG;
    EXCEPTION
    	WHEN NO_DATA_FOUND THEN
    	v_file_name := NULL;
    	v_mimetype := NULL;
    	v_blob := NULL;
	END; 
	FOR j IN (select   line_number,
				   COL001 Vendor_Id,
				   COL002 Vendor_Name,
				   COL003 Datasource_Num_Id,
				   COL004 Datasource_Name,
				   COL005 Rationalized_Vendor_Name,
				   COL006 Classification_Status,
				   COL007 INTER_COMPANY_FLAG,
				   COL008 CREATED_ON,
				   COL009 CREATED_BY,
				   COL010 LAST_UPDATED_ON,
				   COL011 LAST_UPDATED_BY,
				   COL012 REPORTING_VENDOR_NAME,
				   COL013 SUPPLIER_CATEGORY
		
	from  
       table( apex_data_parser.parse(
                  p_content                     => v_blob,
                  p_add_headers_row             => 'Y',
                  p_max_rows                    => 1000000,
                  p_store_profile_to_collection => 'FILE_PARSER_COLLECTION',
                  p_file_name                   => v_file_name ) ) p)
    LOOP
    
     IF j.line_number <> 1 THEN
        INSERT INTO xxtwc_dw.DWC_VENDOR_RATZN_INTERCO_MAP_STG (
                                vendor_id,
                                vendor_name,
                                datasource_num_id,
                                datasource_name,
                                rationalized_vendor_name,
                                classification_status,
                                inter_company_flag,
                                reporting_vendor_name,
                                supplier_category
                            ) 
                            VALUES(
                                j.vendor_id,
                                j.vendor_name,
                                j.datasource_num_id,
                                j.datasource_name,
                                j.rationalized_vendor_name,
                                j.classification_status,
                                j.inter_company_flag,
                                j.reporting_vendor_name,
                                j.supplier_category);
        END IF;
    END LOOP;
    DELETE FROM DWC_VENDOR_RATZN_INTERCO_MAP_STG WHERE FILE_NAME IS NOT NULL;
    COMMIT;
END process_data_stg;
END XXTWC_DW_VENDOR_RATIONALIZATION_UPLOAD_PKG;
/
----------------------------------------------------------------
--PKG_SPEC

create or replace PACKAGE XXTWC_DW_VENDOR_RATIONALIZATION_UPLOAD_PKG
AS
PROCEDURE Process_data(P_USER VARCHAR2, P_SESSION VARCHAR2);
PROCEDURE process_data_stg
                                    ( P_USER IN VARCHAR2,
									  P_UPLOAD_DOC IN VARCHAR2);

END XXTWC_DW_VENDOR_RATIONALIZATION_UPLOAD_PKG;
/
-------------------------------------------------------------------------
-------------------------------------------------------------------------
--CALL_IN_PAGE_USING_JOB

BEGIN   
 DBMS_SCHEDULER.CREATE_JOB (    
    job_name => 'TEMP_JOB_STG',    
	job_type => 'STORED_PROCEDURE',
    job_action => 'XXTWC_DW_VENDOR_RATIONALIZATION_UPLOAD_PKG.process_data_stg',
    number_of_arguments => 2,
    start_date => SYSTIMESTAMP,
    enabled => FALSE,
    auto_drop => TRUE, -- in my case onetimer object - not to store in DB schema   
    comments => '');
        dbms_scheduler.set_job_argument_value(job_name => 'TEMP_JOB_STG',
                      argument_position => 1,
                      argument_value => :APP_USER);
                     
    dbms_scheduler.set_job_argument_value(job_name => 'TEMP_JOB_STG',
                      argument_position => 2,
                      argument_value => :P6_FILE_UPLOAD); -- number arg
    
    DBMS_SCHEDULER.enable(name => 'TEMP_JOB_STG');
END;

------------------------------------------------------------------------------------------------------