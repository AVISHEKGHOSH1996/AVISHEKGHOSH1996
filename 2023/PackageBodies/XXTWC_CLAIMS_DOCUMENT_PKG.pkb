/****************************************************************************************************
	Object Type: 	Package Body
	Name       :    XXTWC_CLAIMS_DOCUMENT_PKG
	Created by:		Trinamix
	Created On:		06/01/2023
	Description:	Package Body for XXTWC_CLAIMS_DOCUMENT_PKG
	Modified On:	
	Reason:		    
****************************************************************************************************/

--------------------------------------------------------
--  DDL for Package Body XXTWC_CLAIMS_DOCUMENT_PKG
--------------------------------------------------------
create or replace PACKAGE BODY xxtwc_claims_document_pkg AS
    lerrmsg  VARCHAR2(100);
    lerrcode VARCHAR2(100);
    lblock   VARCHAR2(200);

    PROCEDURE upload (
        p_claim_id     NUMBER,
        p_base_url     VARCHAR2,
        p_bucket_name  VARCHAR2,
        p_category     VARCHAR2,
        p_file_browser VARCHAR2,
        p_notes        VARCHAR2,
        p_status       OUT VARCHAR2
    ) IS

        l_blob          CLOB;
        l_input_payload BLOB;
        l_status        VARCHAR2(100);
        l_base_url      VARCHAR2(200);
        l_bucket_name   VARCHAR2(300);
        l_url           VARCHAR2(2000);
        l_file_type     VARCHAR2(100);
        l_doctype       VARCHAR2(100);
        l_timestamp     VARCHAR2(100);
        l_category      VARCHAR2(100);
        l_new_name      VARCHAR2(300);
        l_file_name     VARCHAR2(300);
        l_error         VARCHAR2(1000);
        l_body          CLOB;
        l_body_html     CLOB;
        arr             apex_application_global.vc_arr2;
        l_document      VARCHAR2(100);
    BEGIN
        BEGIN
            SELECT  attribute1 INTO l_document from xxtwc_claims_lookups WHERE lookup_type = 'DOCUMENT_CATEGORY' AND  nvl(status,0) = 1 and lookup_name = p_category;
        EXCEPTION
            WHEN OTHERS THEN
            l_document := 'NOTE';
        END;
        IF l_document <> 'NOTE' THEN
            l_bucket_name := p_bucket_name;
            arr := apex_util.string_to_table(p_file_browser);
        /* Looping Data to be inserted in  Table */
            FOR i IN 1..arr.count LOOP
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
                    t.name = arr(i);

                SELECT
                    substr(t.name, instr(t.name, '.') + 0)
                INTO l_doctype
                FROM
                    apex_application_temp_files t
                WHERE
                    t.name = arr(i);

            /* Adding timestamp to Child document file */
                SELECT
                    to_char(systimestamp, 'YYYYMMDDHH24MISSFF3')
                INTO l_timestamp
                FROM
                    dual;

                l_category := p_category;
                l_new_name := REPLACE(l_category
                              || '_'
                              || SUBSTR (l_file_name,0,80)
                              || '_'
                              || l_timestamp
                              || l_doctype,'#','');

                l_url := p_base_url
                         || 'b/'
                         || l_bucket_name
                         || '/o/'
                         || apex_util.url_encode(l_new_name);

                apex_web_service.g_request_headers(1).name := 'Content-Type';
                apex_web_service.g_request_headers(1).value := l_file_type;

            /*Input Payload */
                l_blob := apex_web_service.make_rest_request(p_url => l_url, p_http_method => 'PUT', p_body_blob => l_input_payload);

                l_status := apex_web_service.g_status_code;
                p_status := l_status;

            /* Insert Data in Child dcouments Table */
                INSERT INTO claims.xxtwc_claims_documents (
                    claim_id,
                    file_id,
                    document_category,
                    file_name,
                    file_ext,
                    file_comment,
                    status
                ) VALUES (
                    p_claim_id,
                    NULL,
                    l_category,
                    l_new_name --l_file_name
                    ,
                    l_file_type,
                    p_notes,
                    '1'
                );

            END LOOP;

        ELSE
            INSERT INTO claims.xxtwc_claims_documents (
                claim_id,
                file_id,
                document_category,
                file_name,
                file_ext,
                file_comment,
                status
            ) VALUES (
                p_claim_id,
                NULL,
                p_category,
                NULL --l_file_name
                ,
                NULL,
                p_notes,
                '1'
            );

        END IF;
    EXCEPTION
        WHEN OTHERS THEN
            lerrmsg := sqlerrm;
            lerrcode := sqlcode;
            xxtwc_claims_gp_error_pkg.gp_error_log(
                'Error in XXTWC_CLAIMS_DOCUMENT_PKG.upload',
                '-20000', 'Error While Processing XXTWC_CLAIMS_DOCUMENT_PKG.upload :-' ||sqlerrm,
                v('APP_USER'), 
                '-1', 
                p_claim_id
            );

--            COMMIT;
    END upload;

    PROCEDURE upload_from_collection (
        p_claim_id     NUMBER,
        p_base_url     VARCHAR2,
        p_bucket_name  VARCHAR2,
        p_status       OUT VARCHAR2
    ) IS

        l_input_payload BLOB;
        l_blob          CLOB;
        l_status        VARCHAR2(100);
        l_base_url      VARCHAR2(200);
        l_bucket_name   VARCHAR2(2000);
        l_url           CLOB;
        l_file_name     VARCHAR2(2000);
        l_error         VARCHAR2(1000);
        l_body          CLOB;
        l_body_html     CLOB;
    BEGIN
		FOR i IN (
        SELECT
            c001    AS file_name,
            c002    AS file_mimetype,
            c003    AS document_category,
            c004    AS file_comment,
            blob001 AS file_doc,
            nvl((select attribute1 from xxtwc_claims_lookups where lookup_type = 'DOCUMENT_CATEGORY' AND  nvl(status,0) = 1 and lookup_name = c003),'NOTE') doc_type
        FROM
            apex_collections
        WHERE
            collection_name = 'XXTWC_CLAIMS_DOC'
		) LOOP

			IF i.doc_type <> 'NOTE' THEN
				l_bucket_name := p_bucket_name;
				l_url := p_base_url
						 || 'b/'
						 || l_bucket_name
						 || '/o/'
						 || apex_util.url_encode(i.file_name);

				apex_web_service.g_request_headers(1).name := 'Content-Type';
				apex_web_service.g_request_headers(1).value := i.file_mimetype;
		
					/*Input Payload */
				l_blob := apex_web_service.make_rest_request(p_url => l_url, p_http_method => 'PUT', p_body_blob => i.file_doc);

				l_status := apex_web_service.g_status_code;
				p_status := l_status;
			END IF;
				/* Insert Data in Child dcouments Table */
			INSERT INTO claims.xxtwc_claims_documents (
				claim_id,
				file_id,
				document_category,
				file_name,
				file_ext,
				file_comment,
				status
			) VALUES (
				p_claim_id,
				NULL,
				i.document_category,
				i.file_name,
				i.file_mimetype,
				i.file_comment,
				'1'
			);
		END LOOP;
    EXCEPTION
        WHEN OTHERS THEN
            lerrmsg := sqlerrm;
            lerrcode := sqlcode;
            xxtwc_claims_gp_error_pkg.gp_error_log(
                'Error in XXTWC_CLAIMS_DOCUMENT_PKG.upload_from_collection', 
                '-20000', 'Error While Processing XXTWC_CLAIMS_DOCUMENT_PKG.upload_from_collection :-' ||sqlerrm, 
                v('APP_USER'), 
                '-1',
                p_claim_id
            );
            COMMIT;
    END upload_from_collection;
END xxtwc_claims_document_pkg;

/
