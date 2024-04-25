DECLARE
LV_EMAIL        VARCHAR2(500);
LV_USER_NAME VARCHAR2(500);
LV_PWD VARCHAR2 (100);
BEGIN
BEGIN
SELECT USER_EMAIL INTO LV_EMAIL FROM ORG_USER WHERE USER_EMAIL = :P6_USER_EMAIL;
SELECT USER_NAME INTO LV_USER_NAME FROM ORG_USER WHERE USER_EMAIL = :P6_USER_EMAIL;
SELECT dbms_random.string('P', 6) str INTO LV_PWD FROM dual;
EXCEPTION WHEN OTHERS THEN
LV_EMAIL := NULL;
END;
BEGIN
UPDATE ORG_USER 
SET USER_PASSWORD =  LV_PWD ,
WHERE USER_EMAIL = :P6_USER_EMAIL;
END;
--IF LV_EMAIL IS NOT NULL THEN
BEGIN
 apex_mail.send (
        P_from               => 'avishek.settconsultant0@gmail.com',
        --p_to                 => LV_EMAIL,
        p_to                 => 'avishekghosh088@gmail.com',
        p_template_static_id => 'PASSWORD_HAD_CHANGED',
        p_placeholders       => '{' ||
        '    "USER_NAME":'            || apex_json.stringify((LV_USER_NAME)) ||
        '    ,"USER_PASSWORD":'            || apex_json.stringify((LV_PWD)) ||
        '}' );
		
		APEX_MAIL.PUSH_QUEUE;
END;
--END IF;
END;
-----------------------------------------------------------------------------------
Change password email code:

DECLARE
LV_EMAIL        VARCHAR2(500);
LV_USER_NAME VARCHAR2(500);
LV_PWD VARCHAR2 (100);
BEGIN
BEGIN
SELECT USER_NAME INTO LV_USER_NAME FROM ORG_USER WHERE UPPER(USER_EMAIL) = UPPER(:P10_USER_EMAIL);
EXCEPTION WHEN OTHERS THEN
LV_EMAIL := NULL;
END;
SELECT dbms_random.string('P', 6)  INTO LV_PWD FROM dual;
:P10_USER_PASSWORD := LV_PWD;
UPDATE ORG_USER 
SET USER_PASSWORD =  LV_PWD
WHERE UPPER(USER_EMAIL) = UPPER(:P10_USER_EMAIL);
--IF LV_EMAIL IS NOT NULL THEN
BEGIN
 apex_mail.send (
        P_from               => 'avishek.settconsultant0@gmail.com',
        p_to                 => :P10_USER_EMAIL,
        p_template_static_id => 'PASSWORD_HAD_CHANGED',
        p_placeholders       => '{' ||
        '    "USER_NAME":'            || apex_json.stringify((LV_USER_NAME)) ||
        '    ,"USER_PASSWORD":'            || apex_json.stringify((LV_PWD)) ||
        '}' );
		
		APEX_MAIL.PUSH_QUEUE;
END;
--END IF;
END;

Success Message

Reset Password Successfully.Your Default Password is &P10_USER_PASSWORD.
