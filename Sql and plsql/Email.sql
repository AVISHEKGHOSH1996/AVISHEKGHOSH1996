DECLARE
LV_EMAIL VARCHAR2(100);
LV_PC_NAME VARCHAR2(100);
LV_USER_ID NUMBER;
LV_REQUESTED_BY  NUMBER;
LV_HIRING_MANAGER NUMBER;
LV_TO_EMAIL VARCHAR2(100);
LV_CC_EMAIL VARCHAR2(100);
LV_NAME  VARCHAR2(200);
LV_USER_NAME VARCHAR(200);
LV_E_DATE varchar2(200);
LV_SITE_LOC VARCHAR2(200);
LV_DEPT VARCHAR2(200);
l_id NUMBER;
BEGIN
LV_NAME := :P12_FNAME || ' ' || :P12_LNAME;
BEGIN
SELECT REQUESTED_BY,HIRING_MANAGER_ID,USER_ID INTO LV_REQUESTED_BY,LV_HIRING_MANAGER,LV_USER_ID FROM C_ACR_FORMS WHERE ACR_ID =:P12_ACR_ID;
EXCEPTION WHEN NO_DATA_FOUND THEN 
LV_REQUESTED_BY :=NULL;
LV_HIRING_MANAGER := NULL;
LV_USER_ID := NULL;
END;
BEGIN
SELECT SUBSTR(lower(FNAME),1,1)||lower(LNAME),
       to_char(trunc(EFFECTIVE_DATE),'DD-MON-YYYY'),
       SITE_LOC,
       DEPARTMENT
       INTO 
       LV_USER_NAME,
       LV_E_DATE,
       LV_SITE_LOC,
       LV_DEPT
       FROM C_ACR_FORMS
       WHERE ACR_ID = :P12_ACR_ID;
EXCEPTION
WHEN NO_DATA_FOUND THEN
LV_USER_NAME := NULL;
LV_E_DATE := NULL;
LV_SITE_LOC := NULL;
LV_DEPT := NULL;
END;
BEGIN
SELECT (SELECT ASSET_NAME FROM C_ASSETS A WHERE A.ASSET_ID = U.ASSET_ID)  INTO LV_PC_NAME FROM C_ASSET_USERS U  WHERE ACR_ID = :P12_ACR_ID AND STATUS = 1 AND ROWNUM <2;
EXCEPTION WHEN NO_DATA_FOUND THEN 
LV_PC_NAME :=NULL;
END;
BEGIN
--SELECT ADDRESS INTO LV_EMAIL FROM C_EMAILS WHERE UPPER("TYPE") = UPPER('work') AND USER_ID = :P12_USERID;
SELECT S_GETEMAIL_FN(:P12_USERID)  INTO  LV_EMAIL FROM DUAL;
EXCEPTION WHEN NO_DATA_FOUND THEN
LV_EMAIL :=NULL;
END;
BEGIN
SELECT ADDRESS INTO LV_TO_EMAIL FROM C_EMAILS WHERE UPPER("TYPE") = UPPER('work') AND USER_ID = LV_REQUESTED_BY;
SELECT ADDRESS INTO LV_CC_EMAIL FROM C_EMAILS WHERE UPPER("TYPE") = UPPER('work') AND USER_ID = LV_HIRING_MANAGER;
EXCEPTION WHEN NO_DATA_FOUND THEN
LV_TO_EMAIL :=NULL;
LV_CC_EMAIL := NULL;
END;
IF LV_TO_EMAIL IS NOT NULL THEN
BEGIN
l_id := apex_mail.send (
        P_from               => 'apex@frontagelab.com',
        --p_to                 => LV_TO_EMAIL,
        p_to                 => 'pbose.ctr@frontagelab.com',
		--p_cc                 => LV_CC_EMAIL,
        p_cc                 => 'aghosh@frontagelab.com',
        p_template_static_id => 'COMPLETED_ACR',
       p_placeholders       => '{' ||
        '    "USER_NAME":'            || apex_json.stringify(LV_NAME) ||
        '    ,"T_USER_NAME":'            || apex_json.stringify(LV_USER_NAME) ||
        '    ,"EFFECTIVE_DATE":'            || apex_json.stringify(LV_E_DATE) ||
        '    ,"SITE_LOCATION":'            || apex_json.stringify(LV_SITE_LOC) ||
        '    ,"GROUP_INFO":'            || apex_json.stringify(LV_DEPT) ||
        '    ,"PC_ASSIGNED":'            || apex_json.stringify(LV_PC_NAME) ||
        '    ,"EMAIL":'            || apex_json.stringify(LV_EMAIL) ||
        '  ,"APEX_URL":'             || apex_json.stringify(:P0_INSTANCE_URL) ||
        '}' );
        APEX_MAIL.PUSH_QUEUE;
END;
END IF;
END;
-------------------------------------------------------------------------------------------

Hi,
<br>
<br>
Account Creation Form of (#USER_NAME#) is finally completed. 
<br>
<br>
<table style="width:100%; border : 2px solid;">
  <caption>Detail Information</caption>
  <tr>
    <th  style="border : 1px solid; text-align: center;">User Name</th>
    <th  style="border : 1px solid; text-align: center;">Effective Date</th>
    <th  style="border : 1px solid; text-align: center;">Site Location</th>
    <th  style="border : 1px solid; text-align: center;">Group Info.</th>
    <th  style="border : 1px solid; text-align: center;">Email</th>
    <th  style="border : 1px solid; text-align: center;">PC Assigned</th>
	<th  style="border : 1px solid; text-align: center;">Equipment</th>
  </tr>
  <tr>
    <td  style="border : 1px solid; text-align: center;"> #T_USER_NAME# </td>
    <td  style="border : 1px solid; text-align: center;"> #EFFECTIVE_DATE# </td>
    <td  style="border : 1px solid; text-align: center;"> #SITE_LOCATION# </td>
    <td  style="border : 1px solid; text-align: center;"> #GROUP_INFO# </td>
    <td  style="border : 1px solid; text-align: center;"> #EMAIL# </td>
    <td  style="border : 1px solid; text-align: center;"> #PC_ASSIGNED# </td>
	<td  style="border : 1px solid; text-align: center;"> #EQUIPMENT# </td>
  </tr>
</table>
<br>
<br>
<span style="display: table;text-align: center;width: 100%;">
<a style = "border: none; color: white; padding: 10px 10px; text-align: center; text-decoration: none; display: inline-block; font-size: 16px;
 margin: 4px 2px; cursor: pointer; background-color: #4CAF50;" href="#APEX_URL#f?p=101:9999:&APP_SESSION.">Frontage Business Platform</a>
</span>
<br>
<br>
If you need assistance, please submit IT Ticket to get help.
<br>
<br>
<b>Thank you</b>
<br>
<br>
Application Release Number: &APP_RELEASE_NUMBER.
