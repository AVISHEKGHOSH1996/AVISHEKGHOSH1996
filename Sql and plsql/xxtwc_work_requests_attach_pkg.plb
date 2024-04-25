create or replace PACKAGE BODY XXTWC_WORK_REQUESTS_ATTACH_PKG
IS
	PROCEDURE upload (
        
        p_base_url     VARCHAR2,
        p_bucket_name  VARCHAR2,
        p_file_browser VARCHAR2,
		p_attachment   VARCHAR2,
		p_wr_id        NUMBER,
        p_status       OUT VARCHAR2
	) IS

        l_blob          CLOB;
        l_input_payload BLOB;
        l_status        VARCHAR2(100);
        --l_base_url      VARCHAR2(200);
        l_bucket_name   VARCHAR2(300);
        l_url           VARCHAR2(2000);
        l_file_type     VARCHAR2(100);
        l_doctype       VARCHAR2(100);
        l_timestamp     VARCHAR2(100);
        --l_category      VARCHAR2(100);
        l_new_name      VARCHAR2(300);
        l_file_name     VARCHAR2(300);
        --l_error         VARCHAR2(1000);
        --l_body          CLOB;
        --l_body_html     CLOB;
        --arr             apex_application_global.vc_arr2;
        --l_document      VARCHAR2(100);
		
		--p_base_url := 'https://objectstorage.us-phoenix-1.oraclecloud.com/p/UWug93TzeJ-2RCxl_S8-0gvaKnvF-qJk6JW6iqtE9eFlPq-zv1xwgjYGS9AVXJB7/n/id9tu9v1bv1q/';
		--p_bucket_name := 'TWCClaimsDev';
    BEGIN
                SELECT
                    t.blob_content,
                    t.mime_type,
                    regexp_substr(substr(t.name, 0, instr(t.name, '.') - 1), '[^/]+', 1, 2)--SUBSTR (t.name,0, INSTR (t.name, '.'))
                INTO
                    l_input_payload,
                    l_file_type,
                    l_file_name
                FROM
                    apex_application_temp_files t
                WHERE
                    t.name = p_attachment;

                SELECT
                    substr(t.name, instr(t.name, '.') + 0)
                INTO l_doctype
                FROM
                    apex_application_temp_files t
                WHERE
                    t.name = p_attachment;

            -- / Adding timestamp to Child document file /
                SELECT
                    to_char(systimestamp, 'YYYYMMDDHH24MISSFF3')
                INTO l_timestamp
                FROM
                    dual;

                --l_category := p_category;
                l_new_name := REPLACE(
                              
                               SUBSTR (l_file_name,0,80)
                              || '_'
                              || l_timestamp
                              || l_doctype,'#','');

                l_url := p_base_url
                         || 'b/'
                         || p_bucket_name
                         || '/o/'
                         || apex_util.url_encode(l_new_name);

                apex_web_service.g_request_headers(1).name := 'Content-Type';
                apex_web_service.g_request_headers(1).value := l_file_type;

                INSERT INTO XXTWC_WORK_REQ_ERROR_LOG(WR_ERROR_DESC, WR_WHERE) 
                VALUES ('Content-Type : '|| l_file_type 
                        || ' | l_url :- ' || l_url, 'APP - 11112, XXTWC_WORK_REQUESTS_ATTACH_PKG');

            /*Input Payload */
                l_blob := apex_web_service.make_rest_request(p_url => l_url, p_http_method => 'PUT', p_body_blob => l_input_payload);


                l_status := apex_web_service.g_status_code;
                p_status := l_status;
				
				update XXTWC_WORK_REQUESTS 
				set WR_DOC_PATH = l_url,
                    WR_FILENAME = l_file_name,
                    WR_MIME_TYPE = l_file_type
				where WR_ID = p_wr_id;
			
			
				-- EXCEPTION
				-- WHEN OTHERS THEN
					--lerrmsg := sqlerrm;
					--lerrcode := sqlcode;
					-- xxtwc_claims_gp_error_pkg.gp_error_log(
					--     'Error in XXTWC_CLAIMS_DOCUMENT_PKG.upload',
					--     '-20000', 'Error While Processing XXTWC_CLAIMS_DOCUMENT_PKG.upload :-' ||sqlerrm,
					--     v('APP_USER'), 
					--     '-1', 
					--     p_claim_id
					-- );

					--            COMMIT;
	
    END upload;
END XXTWC_WORK_REQUESTS_ATTACH_PKG;
/

----------------------------------------------------------------------

---------------------call in page--------------------------------------

DECLARE
    L_STATUS    VARCHAR2(1000);
BEGIN
    IF :P1_WR_DOC_PATH IS NOT NULL THEN
        XXTWC_WORK_REQUESTS_ATTACH_PKG.upload
    	(
    		p_base_url		=>	'https://objectstorage.us-phoenix-1.oraclecloud.com/p/UWug93TzeJ-2RCxl_S8-0gvaKnvF-qJk6JW6iqtE9eFlPq-zv1xwgjYGS9AVXJB7/n/id9tu9v1bv1q/',
    		-- p_bucket_name	=>	'TWCWorkRequest',
    		p_bucket_name	=>	'TWCClaimsDev',
    		p_file_browser	=>	NULL,
    		p_attachment 	=>  :P1_WR_DOC_PATH,  --type= file_upload
            p_WR_ID         =>  :P1_WR_ID,
            p_status        =>  L_STATUS
    	);
        INSERT INTO XXTWC_WORK_REQ_ERROR_LOG(WR_ERROR_DESC, WR_WHERE) VALUES ('STATUS:- ' || L_STATUS, 'APP - 11112, PAGE 1');
    END IF;
END;