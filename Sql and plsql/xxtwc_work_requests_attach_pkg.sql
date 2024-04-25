create or replace PACKAGE XXTWC_WORK_REQUESTS_ATTACH_PKG
IS
    PROCEDURE upload
    (
        p_base_url     VARCHAR2,
        p_bucket_name  VARCHAR2,
        p_file_browser VARCHAR2,
		p_attachment   VARCHAR2,
		p_wr_id        NUMBER,
        p_status       OUT VARCHAR2
    );     
END XXTWC_WORK_REQUESTS_ATTACH_PKG;
/