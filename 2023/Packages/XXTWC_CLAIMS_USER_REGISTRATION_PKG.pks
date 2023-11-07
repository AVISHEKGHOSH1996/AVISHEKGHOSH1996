/****************************************************************************************************
	Object Type: 	Package Spec
	Name       :    XXTWC_CLAIMS_USER_REGISTRATION_PKG
	Created by:		Trinamix
	Created On:		06/01/2023
	Description:	Package Spec for Claims User Registration
	Modified On:	06/12/2023
	Reason:		    Modified for Department Code
****************************************************************************************************/
   
--------------------------------------------------------
--  DDL for Package XXTWC_CLAIMS_USER_REGISTRATION_PKG
--------------------------------------------------------

create or replace PACKAGE xxtwc_claims_user_registration_pkg
IS
    FUNCTION get_url
        RETURN VARCHAR2;

    FUNCTION prepare_url (p_url IN VARCHAR2, p_app_id IN NUMBER)
        RETURN VARCHAR2;

    FUNCTION validate_mailid (
        p_email_id   IN XXTWC_CLAIMS_USER_LOGIN_DETAILS.email_id%TYPE)
        RETURN BOOLEAN;

    FUNCTION get_user_id (
        p_email_id   IN XXTWC_CLAIMS_USER_LOGIN_DETAILS.email_id%TYPE)
        RETURN XXTWC_CLAIMS_USER_LOGIN_DETAILS.user_id%TYPE;
        
    FUNCTION get_user_name (
        p_user_id   IN XXTWC_CLAIMS_USER_LOGIN_DETAILS.user_id%TYPE)
        RETURN XXTWC_CLAIMS_USER_LOGIN_DETAILS.FIRSTNAME%TYPE;
    
    FUNCTION get_email_id (
        p_user_id   IN XXTWC_CLAIMS_USER_LOGIN_DETAILS.user_id%TYPE)
        RETURN XXTWC_CLAIMS_USER_LOGIN_DETAILS.EMAIL_ID%TYPE;

    FUNCTION validate_mailid_exists (
        p_email_id   IN XXTWC_CLAIMS_USER_LOGIN_DETAILS.email_id%TYPE)
        RETURN VARCHAR2;

    FUNCTION check_password_pattern (
        p_password   IN XXTWC_CLAIMS_USER_LOGIN_DETAILS.password%TYPE)
        RETURN VARCHAR2;

    FUNCTION get_salt (p_email_id IN XXTWC_CLAIMS_USER_LOGIN_DETAILS.email_id%TYPE)
        RETURN VARCHAR2;

    FUNCTION get_hash (p_username IN VARCHAR2, p_password IN VARCHAR2)
        RETURN VARCHAR2;

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
       -- p_org_id			   IN	  XXTWC_CLAIMS_USER_LOGIN_DETAILS.ORG_ID%TYPE DEFAULT NULL,
        p_sso_user             IN     XXTWC_CLAIMS_USER_LOGIN_DETAILS.SSO_USER%TYPE DEFAULT NULL,
        p_dept_code            IN     XXTWC_CLAIMS_USER_LOGIN_DETAILS.dept_code%TYPE DEFAULT NULL,
        p_user_timezone        IN     XXTWC_CLAIMS_USER_LOGIN_DETAILS.USER_TIMEZONE%TYPE DEFAULT NULL,
        p_user_id              IN OUT XXTWC_CLAIMS_USER_LOGIN_DETAILS.user_id%TYPE,
        p_view_all_claim       IN     XXTWC_CLAIMS_USER_LOGIN_DETAILS.VIEW_ALL_CLAIM%TYPE DEFAULT NULL
        );

    PROCEDURE send_notification (
        p_firstname        IN XXTWC_CLAIMS_USER_LOGIN_DETAILS.firstname%TYPE,
        p_email_id         IN XXTWC_CLAIMS_USER_LOGIN_DETAILS.email_id%TYPE,
        p_url              IN VARCHAR2,
        p_body             IN VARCHAR2,
        p_access_to_apps   IN XXTWC_CLAIMS_USER_LOGIN_DETAILS.access_to_apps%TYPE);

    FUNCTION authenticate_user (p_username   IN VARCHAR2,
                                p_password   IN VARCHAR2)
        RETURN BOOLEAN;
END xxtwc_claims_user_registration_pkg;
/