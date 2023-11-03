/****************************************************************************************************
	Object Type: 	Package Body
	Name       :    XXTWC_CLAIMS_USER_REGISTRATION_PKG
	Created by:		Trinamix
	Created On:		06/01/2023
	Description:	Package Body for Claims User Registration
	Modified On:	06/12/2023
	Reason:		    Modified for Profile Image
****************************************************************************************************/
--------------------------------------------------------
--  DDL for Package Body XXTWC_CLAIMS_USER_REGISTRATION_PKG
--------------------------------------------------------
create or replace PACKAGE BODY xxtwc_claims_user_registration_pkg
IS
    g_password   XXTWC_CLAIMS_USER_LOGIN_DETAILS.password%TYPE;
    g_salt       XXTWC_CLAIMS_USER_LOGIN_DETAILS.salt%TYPE;

    FUNCTION get_url
        RETURN VARCHAR2
    IS
        lv_url   VARCHAR2 (1000);
    BEGIN
        SELECT    OWA_UTIL.get_cgi_env ('REQUEST_PROTOCOL')
               || '://'
               || OWA_UTIL.get_cgi_env ('HTTP_HOST')
               || OWA_UTIL.get_cgi_env ('SCRIPT_NAME')    script_name
          INTO lv_url
          FROM DUAL;

        RETURN lv_url;
    EXCEPTION
        WHEN OTHERS
        THEN
            RETURN NULL;
    END get_url;

    FUNCTION prepare_url (p_url IN VARCHAR2, p_app_id IN NUMBER)
        RETURN VARCHAR2
    IS
        lv_url   VARCHAR2 (1000);
    BEGIN
        IF p_app_id IS NOT NULL
        THEN
            SELECT    SUBSTR (p_url,
                              1,
                              INSTR (p_url,
                                     '/',
                                     1,
                                     REGEXP_COUNT (p_url, '/')))
                   || p_app_id
                   || '/'
                   || 'login'
                   || '?'    script_name
              INTO lv_url
              FROM DUAL;
        END IF;

        RETURN NVL (lv_url, p_url);
    EXCEPTION
        WHEN OTHERS
        THEN
            RETURN NULL;
    END prepare_url;

    FUNCTION validate_mailid (
        p_email_id   IN XXTWC_CLAIMS_USER_LOGIN_DETAILS.email_id%TYPE)
        RETURN BOOLEAN
    IS
    BEGIN
        RETURN REGEXP_LIKE (
                   p_email_id,
                   '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,4}$');
    END validate_mailid;

    FUNCTION get_user_id (
        p_email_id   IN XXTWC_CLAIMS_USER_LOGIN_DETAILS.email_id%TYPE)
        RETURN XXTWC_CLAIMS_USER_LOGIN_DETAILS.user_id%TYPE
    IS
        v_user_id   XXTWC_CLAIMS_USER_LOGIN_DETAILS.user_id%TYPE;
    BEGIN
        SELECT USER_ID
          INTO v_user_id
          FROM XXTWC_CLAIMS_USER_LOGIN_DETAILS
         WHERE     UPPER (email_id) = UPPER (p_email_id)
               AND ACTIVE_FLG = 'Y'
               AND ACCESS_TO_APPS = V ('APP_ID');

        RETURN v_user_id;
    EXCEPTION
        WHEN OTHERS
        THEN
            RETURN NULL;
    END get_user_id;
    
    FUNCTION get_user_name (
        p_user_id   IN XXTWC_CLAIMS_USER_LOGIN_DETAILS.user_id%TYPE)
        RETURN XXTWC_CLAIMS_USER_LOGIN_DETAILS.FIRSTNAME%TYPE
    IS
        lv_user_name varchar2(500);
    BEGIN
        SELECT FIRSTNAME||' '||LASTNAME
          INTO lv_user_name
          FROM XXTWC_CLAIMS_USER_LOGIN_DETAILS
         WHERE     UPPER (USER_ID) = UPPER (p_user_id)
               AND ACTIVE_FLG = 'Y'
               AND ACCESS_TO_APPS = NVL(V('APP_ID'),225); 
        RETURN lv_user_name;
    exception
        WHEN OTHERS THEN
            RETURN NULL;
    END get_user_name;
        
    FUNCTION get_email_id (
        p_user_id   IN XXTWC_CLAIMS_USER_LOGIN_DETAILS.user_id%TYPE)
        RETURN XXTWC_CLAIMS_USER_LOGIN_DETAILS.EMAIL_ID%TYPE
    IS
        lv_email_id XXTWC_CLAIMS_USER_LOGIN_DETAILS.EMAIL_ID%TYPE;
    BEGIN
        SELECT EMAIL_ID
          INTO lv_email_id
          FROM XXTWC_CLAIMS_USER_LOGIN_DETAILS
         WHERE     UPPER (USER_ID) = UPPER (p_user_id)
               AND ACTIVE_FLG = 'Y'
               AND ACCESS_TO_APPS = V ('APP_ID'); 
        RETURN lv_email_id;
    exception
        WHEN OTHERS THEN
            RETURN NULL;
    END get_email_id;
    
    FUNCTION validate_mailid_exists (
        p_email_id   IN XXTWC_CLAIMS_USER_LOGIN_DETAILS.email_id%TYPE)
        RETURN VARCHAR2
    IS
        lv_cnt   NUMBER;
    BEGIN
        SELECT COUNT (1)
          INTO lv_cnt
          FROM XXTWC_CLAIMS_USER_LOGIN_DETAILS
         WHERE UPPER (EMAIL_ID) = UPPER (p_email_id);

        IF lv_cnt > 0
        THEN
            RETURN 'Mail Id exists.';
        ELSE
            RETURN NULL;
        END IF;
    END validate_mailid_exists;

    FUNCTION check_password_pattern (
        p_password   IN XXTWC_CLAIMS_USER_LOGIN_DETAILS.password%TYPE)
        RETURN VARCHAR2
    IS
    BEGIN
        IF 8 <= LENGTH (p_password) AND LENGTH (p_password) <= 15
        THEN
            IF REGEXP_LIKE (p_password, '^.*[0-9]')
            THEN
                IF REGEXP_LIKE (p_password, '^.*[a-z]', 'c')
                THEN
                    IF REGEXP_LIKE (p_password, '^.*[A-Z]', 'c')
                    THEN
                        IF REGEXP_LIKE (p_password, '^.*[!@#$%^&*()_]', 'c')
                        THEN
                            RETURN '';
                        ELSE
                            RETURN 'Password should have atleast one special character';
                        END IF;
                    ELSE
                        RETURN 'Password should have atleast one UpperCase';
                    END IF;
                ELSE
                    RETURN 'Password should have atleast one LowerCase';
                END IF;
            ELSE
                RETURN 'Password should have atleast one numeric value';
            END IF;
        ELSE
            RETURN 'Password Length Must be min 8 char and max 15 char';
        END IF;
    END check_password_pattern;

    FUNCTION get_salt (p_email_id IN XXTWC_CLAIMS_USER_LOGIN_DETAILS.email_id%TYPE)
        RETURN VARCHAR2
    IS
        v_salt   XXTWC_CLAIMS_USER_LOGIN_DETAILS.salt%TYPE;
    BEGIN
        BEGIN
            SELECT salt
              INTO v_salt
              FROM XXTWC_CLAIMS_USER_LOGIN_DETAILS
             WHERE UPPER (email_id) = UPPER (p_email_id) AND ACTIVE_FLG = 'Y';
        EXCEPTION
            WHEN OTHERS
            THEN
                NULL;
        END;

        RETURN NVL (v_salt, DBMS_RANDOM.string ('A', 10));
    END get_salt;

    FUNCTION get_hash (p_username IN VARCHAR2, p_password IN VARCHAR2)
        RETURN VARCHAR2
    AS
        l_salt   VARCHAR2 (30)
                     := NVL (g_salt, get_salt (p_email_id => p_username));
    BEGIN
        RETURN DBMS_CRYPTO.hash (
                   UTL_RAW.cast_to_raw (
                       UPPER (p_username) || l_salt || UPPER (p_password)),
                   DBMS_CRYPTO.hash_sh1);
    END get_hash;

    PROCEDURE dml_user_registraion (
        p_firstname            IN     XXTWC_CLAIMS_USER_LOGIN_DETAILS.firstname%TYPE DEFAULT NULL,
        p_lastname             IN     XXTWC_CLAIMS_USER_LOGIN_DETAILS.lastname%TYPE DEFAULT NULL,
        p_email_id             IN     XXTWC_CLAIMS_USER_LOGIN_DETAILS.email_id%TYPE DEFAULT NULL,
        p_access_to_apps       IN     XXTWC_CLAIMS_USER_LOGIN_DETAILS.access_to_apps%TYPE DEFAULT NULL,
        p_password             IN     XXTWC_CLAIMS_USER_LOGIN_DETAILS.password%TYPE DEFAULT NULL,
        p_is_password_change   IN     XXTWC_CLAIMS_USER_LOGIN_DETAILS.is_password_change%TYPE DEFAULT NULL,
        p_active_flg           IN     XXTWC_CLAIMS_USER_LOGIN_DETAILS.active_flg%TYPE DEFAULT NULL,
        p_created_by           IN     XXTWC_CLAIMS_USER_LOGIN_DETAILS.created_by%TYPE DEFAULT NULL,
        p_url                  IN     VARCHAR2 DEFAULT NULL,
        p_send_mail            IN     VARCHAR2 DEFAULT 'N',
        p_sso_user             IN     XXTWC_CLAIMS_USER_LOGIN_DETAILS.SSO_USER%TYPE DEFAULT NULL,
		p_dept_code            IN     XXTWC_CLAIMS_USER_LOGIN_DETAILS.DEPT_CODE%TYPE DEFAULT NULL,
		p_user_timezone        IN     XXTWC_CLAIMS_USER_LOGIN_DETAILS.USER_TIMEZONE%TYPE DEFAULT NULL,
        p_user_id              IN OUT XXTWC_CLAIMS_USER_LOGIN_DETAILS.user_id%TYPE,
        p_view_all_claim       IN     XXTWC_CLAIMS_USER_LOGIN_DETAILS.VIEW_ALL_CLAIM%TYPE DEFAULT NULL
        )
		
		
    IS
        v_send_mail   VARCHAR2 (1) := p_send_mail;
        v_msg         VARCHAR2 (1000);
        v_password    XXTWC_CLAIMS_USER_LOGIN_DETAILS.password%TYPE := p_password;
        v_user_img    BLOB;
        v_mime_type   VARCHAR2 (1000);
        v_img_file_name VARCHAR2 (1000);     

        CURSOR c1 IS
            SELECT *
              FROM XXTWC_CLAIMS_USER_LOGIN_DETAILS
             WHERE user_id = p_user_id;

        v_c1_rslt     c1%ROWTYPE;
           
    BEGIN
   
        g_salt := get_salt (p_email_id => p_email_id);

        IF p_is_password_change = 'Y'
        THEN
            g_password := 'Welcome123';--DBMS_RANDOM.string ('A', 10);
            v_password := g_password;
        END IF;

 BEGIN
        SELECT blob_content, mime_type, filename
        INTO v_user_img,v_mime_type,v_img_file_name
        FROM apex_application_temp_files
        where name  = V('P15_USER_IMG');
        EXCEPTION WHEN NO_DATA_FOUND
                  THEN v_user_img := NULL;
                       v_mime_type := NULL;
                       v_img_file_name := NULL;
END;

        IF p_user_id IS NULL
        THEN
            INSERT INTO XXTWC_CLAIMS_USER_LOGIN_DETAILS (user_id,
                                                  firstname,
                                                  lastname,
                                                  email_id,
                                                  access_to_apps,
                                                  password,
                                                  active_flg,
                                                  is_password_change,
                                                  creation_date,
                                                  created_by,
                                                  last_update_date,
                                                  last_update_by,
                                                  salt,
                                                  SSO_USER,
                                                  USER_IMG,
                                                  MIME_TYPE,
                                                  IMG_FILE_NAME,
												  DEPT_CODE,
												  USER_TIMEZONE,
                                                  VIEW_ALL_CLAIM)
                 VALUES (
                            XXTWC_CLAIMS_USER_LOGIN_DETAILS_seq.NEXTVAL,
                            p_firstname,
                            p_lastname,
                            p_email_id,
                            p_access_to_apps,
                            get_hash (p_username   => p_email_id,
                                      p_password   => g_password),
                            p_active_flg,
                            'Y',
                            SYSDATE,
                            p_created_by,
                            SYSDATE,
                            p_created_by,
                            g_salt,
                            p_sso_user,
                            v_user_img,
                            v_mime_type,
                            v_img_file_name,
							p_dept_code,
							p_user_timezone,
                            p_view_all_claim)
              RETURNING user_id
                   INTO p_user_id;
     IF P_SSO_USER = 'N'
     THEN
            v_send_mail := 'Y';
            v_msg := 'Registration has been done successfully. ';
            END IF;
        ELSE
            UPDATE XXTWC_CLAIMS_USER_LOGIN_DETAILS
               SET firstname = NVL (p_firstname, firstname),
                   lastname = NVL (p_lastname, lastname),
                   access_to_apps = NVL (p_access_to_apps, access_to_apps),
                   is_password_change =
                       NVL (p_is_password_change, is_password_change),
                   active_flg = NVL (p_active_flg, active_flg),
                  /* password =
                       NVL (
                           CASE
                               WHEN v_password IS NOT NULL
                               THEN
                                   get_hash (p_username   => p_email_id,
                                             p_password   => v_password)
                           END,
                           password),*/
                   last_update_date = SYSDATE,
                   last_update_by = p_created_by,
                   SSO_USER = NVL (p_sso_user, SSO_USER),
                   USER_IMG = NVL (v_user_img, USER_IMG),
                   MIME_TYPE = NVL (v_mime_type, MIME_TYPE),
                   IMG_FILE_NAME = NVL (v_img_file_name, IMG_FILE_NAME),
				   DEPT_CODE =  NVL (p_dept_code, DEPT_CODE),
				   USER_TIMEZONE=  NVL (p_user_timezone, USER_TIMEZONE),
                   VIEW_ALL_CLAIM= NVL(p_view_all_claim,VIEW_ALL_CLAIM)
             WHERE user_id = p_user_id;
             COMMIT;
        END IF;

        IF v_send_mail = 'Y'
        THEN
            OPEN c1;

            FETCH c1 INTO v_c1_rslt;

            CLOSE c1;

            send_notification (p_firstname        => v_c1_rslt.firstname,
                               p_email_id         => p_email_id,
                               p_url              => p_url,
                               p_body             => v_msg,
                               p_access_to_apps   => p_access_to_apps);
        END IF;
    EXCEPTION
        WHEN OTHERS
        THEN
            apex_error.add_error (
                p_message            => 'Error in processing the DML!',
                p_display_location   => apex_error.c_inline_in_notification);
    END dml_user_registraion;

    PROCEDURE send_notification (
        p_firstname        IN XXTWC_CLAIMS_USER_LOGIN_DETAILS.firstname%TYPE,
        p_email_id         IN XXTWC_CLAIMS_USER_LOGIN_DETAILS.email_id%TYPE,
        p_url              IN VARCHAR2,
        p_body             IN VARCHAR2,
        p_access_to_apps   IN XXTWC_CLAIMS_USER_LOGIN_DETAILS.access_to_apps%TYPE)
    IS
        v_email_body   VARCHAR2 (4000) := p_body;
        v_url          VARCHAR2 (1000)
            := prepare_url (p_url => p_url, p_app_id => p_access_to_apps);
    BEGIN
        v_email_body :=
               'Dear '
            || p_firstname
            || ',<br/><br/> '
            || v_email_body
            || 'Please use the below credentials to access the application, '
            || '<br><a href="'
            || v_url
            || '">Login into Application</a></br>'
            || CASE
                   WHEN v_email_body IS NOT NULL
                   THEN
                       '<br>' || 'Username - ' || p_email_id
                   ELSE
                       NULL
               END
            || '<br>'
            || 'Password - '
            || g_password
            || ' <br><br>Thanks!!<br>Wonderful';
        apex_mail.send (p_from        => 'mailto:no-reply-citrus-grower@wonderful.com',
                        p_to          => p_email_id,
                        p_subj        => 'Registration Confirmation Mail',
                        p_body        => 'Registration Confirmation Mail',
                        p_body_html   => v_email_body);
        apex_mail.push_queue ();
    EXCEPTION
        WHEN OTHERS
        THEN
            apex_error.add_error (
                p_message            => q'[Error in processing the action.!]',
                p_display_location   => apex_error.c_inline_in_notification);
    END send_notification;

    FUNCTION authenticate_user (p_username   IN VARCHAR2,
                                p_password   IN VARCHAR2)
        RETURN BOOLEAN
    IS
        l_user_name   XXTWC_CLAIMS_USER_LOGIN_DETAILS.email_id%TYPE
                          := UPPER (p_username);
        l_password    XXTWC_CLAIMS_USER_LOGIN_DETAILS.password%TYPE;
        l_count       NUMBER;
		lv_ORG_ID      NUMBER;
        lv_warehouse_code  VARCHAR2(4000);
		lv_BU_NAME     VARCHAR2(1000);
        lv_flag        VARCHAR2(1000);
        lv_user_id     XXTWC_CLAIMS_USER_LOGIN_DETAILS.USER_ID%TYPE;
        lv_app_role_name VARCHAR2(1000);
        lv_app_role_id  NUMBER;
        lv_sso_user     VARCHAR2(1);
		lv_dept_code    VARCHAR2(1000);
        lv_view_all_claim varchar2(1);
    BEGIN
        SELECT COUNT (*)
          INTO l_count
          FROM XXTWC_CLAIMS_USER_LOGIN_DETAILS
         WHERE     UPPER (EMAIL_ID) = UPPER (l_user_name)
               AND ACTIVE_FLG = 'Y'
               AND ACCESS_TO_APPS = V ('APP_ID')
               AND NVL(SSO_USER,'N') = 'N';

        IF l_count > 0
        THEN
            -- Get the stored password
            SELECT password, IS_PASSWORD_CHANGE, USER_ID,NVL(SSO_USER,'N'),DEPT_CODE,NVL(VIEW_ALL_CLAIM,'Y')
              INTO l_password , lv_flag, lv_user_id, lv_sso_user,lv_dept_code,lv_view_all_claim
              FROM XXTWC_CLAIMS_USER_LOGIN_DETAILS
             WHERE     UPPER (EMAIL_ID) = UPPER (l_user_name)
                   AND ACTIVE_FLG = 'Y';
				   
		BEGIN
		SELECT ORG_ID,WAREHOUSE_CODE
		INTO lv_ORG_ID, lv_warehouse_code FROM 
		(SELECT ORG_ID,WAREHOUSE_CODE
		FROM XXTWC_CLAIMS_USER_ORG_DETAILS 
		WHERE USER_ID = LV_USER_ID
		ORDER BY NVL(DEFAULT_ORG,'N') DESC)
		WHERE ROWNUM <2;
		EXCEPTION WHEN NO_DATA_FOUND
				  THEN lv_ORG_ID := NULL;
                        lv_warehouse_code := NULL;
		
		END;

		BEGIN
		select distinct
            hou.name bu_name
			INTO lv_BU_NAME
            from fusion.hr_organization_units_f_tl hou,
            fusion.inv_org_parameters ood
            where language = 'US'
            AND hou.organization_id = ood.business_unit_id
            AND hou.organization_id =lv_ORG_ID;
			EXCEPTION WHEN NO_DATA_FOUND
          THEN lv_BU_NAME := NULL;
		END;
		
 BEGIN
          SELECT CR.ROLE_ID, CR.ROLE_NAME
          INTO lv_app_role_id,lv_app_role_name
          FROM XXTWC_CLAIMS_ROLES CR,XXTWC_CLAIMS_USER_ROLES UR
          WHERE CR.ROLE_ID = UR.ROLE_ID
          AND UR.USER_ID = lv_user_id
          AND ROWNUM<2
          AND CR.ROLE_NAME <> 'Super Approver'
		  AND SYSDATE BETWEEN NVL(EFF_START_DATE,SYSDATE) AND NVL(EFF_END_DATE,SYSDATE)
          AND CR.STATUS = 1
		  AND UR.STATUS = 1;
          EXCEPTION WHEN NO_DATA_FOUND
          THEN lv_app_role_id := NULL;
               lv_app_role_name := NULL;
          END;

            -- Compare the two, and if there is a match, return TRUE
            IF get_hash (p_username => l_user_name, p_password => p_password) =
               l_password
            THEN
                -- Good result.
               APEX_UTIL.SET_AUTHENTICATION_RESULT (0);
               APEX_UTIL.SET_SESSION_STATE ('P0_FLAG',lv_flag);
               APEX_UTIL.SET_SESSION_STATE ('P0_USER_NAME', LOWER(l_user_name));
               APEX_UTIL.SET_SESSION_STATE ('P0_USER_ID', lv_user_id);
               APEX_UTIL.SET_SESSION_STATE ('P0_APP_ROLE_NAME', lv_app_role_name);
               APEX_UTIL.SET_SESSION_STATE ('P0_APP_ROLE_ID', lv_app_role_id);
               APEX_UTIL.SET_SESSION_STATE ('P0_ORG_ID', lv_ORG_ID);
               APEX_UTIL.SET_SESSION_STATE ('P0_BU_NAME', lv_BU_NAME);
               APEX_UTIL.SET_SESSION_STATE ('P0_SSO_USER', lv_sso_user);
			   APEX_UTIL.SET_SESSION_STATE ('P0_DEPT_CODE', lv_dept_code);
               APEX_UTIL.SET_SESSION_STATE ('P0_DEPT_CODE', lv_dept_code);
               APEX_UTIL.SET_SESSION_STATE ('P0_WAREHOUSE_CODE', lv_warehouse_code);
               APEX_UTIL.SET_SESSION_STATE ('P0_VIEW_ALL_CLAIM', lv_view_all_claim);
                RETURN TRUE;
            ELSE
                -- The Passwords didn't match
                APEX_UTIL.SET_AUTHENTICATION_RESULT (4);
                RETURN FALSE;
            END IF;
        ELSE
            -- The username does not exist
            APEX_UTIL.SET_AUTHENTICATION_RESULT (1);
            RETURN FALSE;
        END IF;


        -- If we get here then something weird happened.
        APEX_UTIL.SET_AUTHENTICATION_RESULT (7);
        RETURN FALSE;
    EXCEPTION
        WHEN OTHERS
        THEN
            -- We don't know what happened so log an unknown internal error
            APEX_UTIL.SET_AUTHENTICATION_RESULT (7);
            -- And save the SQL Error Message to the Auth Status.
            APEX_UTIL.SET_CUSTOM_AUTH_STATUS (SQLERRM);
          CLAIMS.XXTWC_CLAIMS_GP_ERROR_PKG.GP_ERROR_LOG ('Login Failed', 
                             SQLCODE,     
                             SQLERRM, 
                             p_username,
                             9999,
                             NULL
                             );
            RETURN FALSE;
    END authenticate_user;
END xxtwc_claims_user_registration_pkg;
/