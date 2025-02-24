create or replace PACKAGE BODY c_apex_msft_o365_integration_pkg IS

-- -----------------------------------------------------------------------------------
-- File Name    : C_APEX_MSFT_O365_INTEGRATION_PKG.pks
-- Author       : Sett Consultant
-- Description  : Oracle Apex and Microsoft Office 365 Integration
-- Creation Date: 13-Jun-2020 Draft
-- -----------------------------------------------------------------------------------

  -- g_recepients_email_id VARCHAR2(500) := 'sdutta@frontagelab.com';
   -- g_kace_report_email_id VARCHAR2(500) := 'reporter@KACE-SMA.frontagelab.local';

    FUNCTION base64encode (
        p_blob IN BLOB
    ) RETURN CLOB
-- -----------------------------------------------------------------------------------
-- File Name    : https://oracle-base.com/dba/miscellaneous/base64encode.sql
-- Author       : Tim Hall
-- Description  : Encodes a BLOB into a Base64 CLOB.
-- Last Modified: 09/11/2011
-- -----------------------------------------------------------------------------------
     IS
        l_clob  CLOB;
        l_step  PLS_INTEGER := 12000; -- make sure you set a multiple of 3 not higher than 24573
    BEGIN
        FOR i IN 0..trunc((dbms_lob.getlength(p_blob) - 1) / l_step) LOOP
            l_clob := l_clob
                      || utl_raw.cast_to_varchar2(utl_encode.base64_encode(dbms_lob.substr(p_blob, l_step, i * l_step + 1)));
        END LOOP;

        RETURN l_clob;
    END;

    PROCEDURE initialize_kace_env_details IS
    BEGIN
        SELECT
            value
        INTO g_kace_report_email_id
        FROM
            g_cfgvars
        WHERE
                name = 'KACE_REPORT_EMAIL'
            AND status = 1;

        SELECT
            value
        INTO g_recepients_email_id
        FROM
            g_cfgvars
        WHERE
                name = 'KACE_REPORT_MAIL_RECP'
            AND status = 1;

    EXCEPTION
        WHEN OTHERS THEN
            raise_application_error('20001', ' Failed to assign Kace env details');
    END initialize_kace_env_details;

    FUNCTION decode_base64 (
        p_clob_in IN CLOB
    ) RETURN BLOB IS

        v_blob            BLOB;
        v_result          BLOB;
        v_offset          INTEGER;
        v_buffer_size     BINARY_INTEGER := 48;
        v_buffer_varchar  VARCHAR2(48);
        v_buffer_raw      RAW(48);
    BEGIN
        IF p_clob_in IS NULL THEN
            RETURN NULL;
        END IF;
        dbms_lob.createtemporary(v_blob, true);
        v_offset := 1;
        FOR i IN 1..ceil(dbms_lob.getlength(p_clob_in) / v_buffer_size) LOOP
            dbms_lob.read(p_clob_in, v_buffer_size, v_offset, v_buffer_varchar);
            v_buffer_raw := utl_raw.cast_to_raw(v_buffer_varchar);
            v_buffer_raw := utl_encode.base64_decode(v_buffer_raw);
            dbms_lob.writeappend(v_blob, utl_raw.length(v_buffer_raw), v_buffer_raw);
            v_offset := v_offset + v_buffer_size;
        END LOOP;

        v_result := v_blob;
        dbms_lob.freetemporary(v_blob);
        RETURN v_result;
    END decode_base64;

    PROCEDURE generate_outh2_token (
        x_token          OUT  VARCHAR2,
        x_status         OUT  VARCHAR2,
        x_error_code     OUT  VARCHAR2,
        x_error_message  OUT  VARCHAR2
    ) IS
        lc_auth2_return CLOB;

        --lv_resorce VARCHAR2(240):= '00000003-0000-0000-c000-000000000000';
    BEGIN
        apex_web_service.g_request_headers(1).name := 'Content-Type';
        apex_web_service.g_request_headers(1).value := 'application/x-www-form-urlencoded;charset=utf-8';
        lc_auth2_return := apex_web_service.make_rest_request(p_url => 'https://login.microsoftonline.com/'
                                                                       || lv_tenant_id
                                                                       || '/oauth2/token',
                                                             p_http_method => 'POST',
                                                             p_parm_name => apex_util.string_to_table('grant_type:client_id:client_secret:resource'),
                                                             p_parm_value => apex_util.string_to_table('client_credentials'
                                                                                                       || ':'
                                                                                                       || lv_client_id
                                                                                                       || ':'
                                                                                                       || lv_client_secret
                                                                                                       || ':'
                                                                                                       || lv_resorce));


       -- dbms_output.put_line(lc_auth2_return);
        apex_json.parse(lc_auth2_return);
        x_token := apex_json.get_varchar2('access_token');
       -- dbms_output.put_line('x_token '|| x_token);

        IF x_token IS NOT NULL THEN
            x_status := 'S';
            x_error_code := NULL;
            x_error_message := NULL;
        ELSE
            x_status := 'E';
            x_error_code := apex_json.get_varchar2('error');
            x_error_message := substr(apex_json.get_varchar2('error_description'), 1, 3999);
        END IF;

    EXCEPTION
        WHEN OTHERS THEN
            x_status := 'E';
            x_error_code := sqlcode;
            x_error_message := sqlerrm;
    END generate_outh2_token;

    PROCEDURE create_cal_event (
        p_event_recepient_email  IN   VARCHAR2,
        p_event_subject          IN   VARCHAR2,
        p_event_start_date       IN   VARCHAR2,
        p_event_end_date         IN   VARCHAR2,
        p_calender_timezone      IN   VARCHAR2,
        x_event_id               OUT  VARCHAR2,
        x_status                 OUT  VARCHAR2,
        x_error_code             OUT  VARCHAR2,
        x_error_message          OUT  VARCHAR2
    ) IS

        lc_cal_event_body       CLOB;
        lc_create_event_result  CLOB;
        l_x_token               VARCHAR2(4000);
        l_x_status              VARCHAR2(200);
        l_x_error_code          VARCHAR2(1000);
        l_x_error_message       VARCHAR2(4000);
    BEGIN


     --dbms_output.put_line('l_body '||l_body);

        generate_outh2_token(x_token => l_x_token, x_status => l_x_status, x_error_code => l_x_error_code,
                            x_error_message => l_x_error_message);

        IF l_x_token IS NOT NULL THEN

       --dbms_output.put_line('L_X_TOKEN ' || L_X_TOKEN);

            apex_web_service.g_request_headers(1).name := 'Content-Type';
            apex_web_service.g_request_headers(1).value := 'application/json';
            apex_web_service.g_request_headers(2).name := 'Authorization';
            apex_web_service.g_request_headers(2).value := 'Bearer ' || l_x_token;
            lc_cal_event_body := '{
      "subject": '
                                 || '"'
                                 || p_event_subject
                                 || '"'
                                 || ',
      "start": {
       "dateTime": '
                                 || '"'
                                 || p_event_start_date
                                 || '"'
                                 || ' ,
        "timeZone": '
                                 || '"'
                                 || p_calender_timezone
                                 || '"'
                                 || '
                },
       "end": {
           "dateTime": '
                                 || '"'
                                 || p_event_end_date
                                 || '"'
                                 || ' ,
           "timeZone": '
                                 || '"'
                                 || p_calender_timezone
                                 || '"'
                                 || '
                }
            }';

            lc_create_event_result := apex_web_service.make_rest_request(p_url => 'https://graph.microsoft.com/v1.0/users/'
                                                                                  || p_event_recepient_email
                                                                                  || '/calendar/events',
                                                                        p_http_method => 'POST',
                                                                        p_body => lc_cal_event_body);

       --dbms_output.put_line('lC_create_event_result = ' || substr(lC_create_event_result,1,3000) );

            apex_json.parse(lc_create_event_result);
            x_event_id := apex_json.get_varchar2('id');
         --dbms_output.put_line('x_event_id '|| x_event_id);

            IF x_event_id IS NOT NULL THEN
                x_status := 'S';
                x_error_code := NULL;
                x_error_message := NULL;
            ELSE
                x_status := 'E';
                x_error_code := substr(apex_json.get_varchar2('error'), 1, 999);
                x_error_message := substr(apex_json.get_varchar2('error_description'), 1, 3999);
            END IF;

        ELSE
            x_status := 'E';
            x_error_code := substr(l_x_error_code, 1, 999);
            x_error_message := substr(l_x_error_message, 1, 999);
        END IF;

    EXCEPTION
        WHEN OTHERS THEN
            x_status := 'E';
            x_error_code := sqlcode;
            x_error_message := sqlerrm;
    END create_cal_event;

    PROCEDURE update_cal_event (
        p_event_id               IN   VARCHAR2,
        p_event_recepient_email  IN   VARCHAR2,
        p_event_subject          IN   VARCHAR2,
        p_event_start_date       IN   VARCHAR2,
        p_event_end_date         IN   VARCHAR2,
        p_calender_timezone      IN   VARCHAR2,
        xn_event_id              OUT  VARCHAR2,
        x_status                 OUT  VARCHAR2,
        x_error_code             OUT  VARCHAR2,
        x_error_message          OUT  VARCHAR2
    ) IS

        xd_status         VARCHAR2(100) := NULL;
        xd_error_code     VARCHAR2(1000) := NULL;
        xd_error_message  VARCHAR2(4000) := NULL;
        xc_event_id       VARCHAR2(500) := NULL;
        xc_status         VARCHAR2(100) := NULL;
        xc_error_code     VARCHAR2(1000) := NULL;
        xc_error_message  VARCHAR2(4000) := NULL;
    BEGIN
        delete_cal_event(p_event_id, p_event_recepient_email, xd_status, xd_error_code,
                        xd_error_message);
        IF xd_status = 'S' THEN
            create_cal_event(p_event_recepient_email, p_event_subject, p_event_start_date,
                            p_event_end_date,
                            p_calender_timezone,
                            xc_event_id,
                            xc_status,
                            xc_error_code,
                            xc_error_message);

            IF xc_status = 'S' THEN
                xn_event_id := xc_event_id;
                x_status := xc_status;
                x_error_code := xc_error_code;
                x_error_message := xc_error_message;
            ELSE
                xn_event_id := NULL;
                x_status := xc_status;
                x_error_code := xc_error_code;
                x_error_message := xc_error_message;
            END IF;

        ELSE
            xn_event_id := NULL;
            x_status := xd_status;
            x_error_code := xd_error_code;
            x_error_message := xd_error_message;
        END IF;

    EXCEPTION
        WHEN OTHERS THEN
            xn_event_id := NULL;
            x_status := xc_status;
            x_error_code := xc_error_code;
            x_error_message := xc_error_message;
    END update_cal_event;

    PROCEDURE delete_cal_event (
        p_event_id               IN   VARCHAR2,
        p_event_recepient_email  IN   VARCHAR2,
        x_status                 OUT  VARCHAR2,
        x_error_code             OUT  VARCHAR2,
        x_error_message          OUT  VARCHAR2
    ) IS

        l_x_token          VARCHAR2(4000);
        l_x_status         VARCHAR2(200);
        l_x_error_code     VARCHAR2(200);
        l_x_error_message  VARCHAR2(4000);
        l_clob             CLOB;
    BEGIN
        generate_outh2_token(x_token => l_x_token, x_status => l_x_status, x_error_code => l_x_error_code,
                            x_error_message => l_x_error_message);

        IF l_x_token IS NOT NULL THEN
            apex_web_service.g_request_headers(1).name := 'Authorization';
            apex_web_service.g_request_headers(1).value := 'Bearer ' || l_x_token;
            dbms_output.put_line('L_X_TOKEN: ' || l_x_token);
            l_clob := apex_web_service.make_rest_request(p_url => 'https://graph.microsoft.com/v1.0/users/'
                                                                  || p_event_recepient_email
                                                                  || '/calendar/events/'
                                                                  || p_event_id,
                                                        p_http_method => 'DELETE');

            dbms_output.put_line('l_clob: ' || l_clob);
            IF l_clob IS NULL THEN
                x_status := 'S';
                x_error_code := NULL;
                x_error_message := NULL;
            ELSE
                apex_json.parse(l_clob);
                x_status := 'E';
                x_error_code := substr(apex_json.get_varchar2('error.code'), 1, 999);
                x_error_message := substr(apex_json.get_varchar2('error.message'), 1, 3999);


        --dbms_output.put_line ('code: ' || apex_json.get_varchar2 ('error.code'));
        --dbms_output.put_line ('message: ' || apex_json.get_varchar2 ('error.message'));
            END IF;

        ELSE
            x_status := 'E';
            x_error_code := substr(l_x_error_code, 1, 999);
            x_error_message := substr(l_x_error_message, 1, 3999);
        END IF;

    EXCEPTION
        WHEN OTHERS THEN
            x_status := 'E';
            x_error_code := sqlcode;
            x_error_message := sqlerrm;
    END delete_cal_event;

    PROCEDURE get_cal_events (
        p_user_email     IN   VARCHAR2,
        x_status         OUT  VARCHAR2,
        x_error_code     OUT  VARCHAR2,
        x_error_message  OUT  VARCHAR2
    ) IS

        l_x_token          VARCHAR2(10000);
        l_x_status         VARCHAR2(200);
        l_x_error_code     VARCHAR2(200);
        l_x_error_message  VARCHAR2(4000);
        l_clob             CLOB;
    BEGIN
        generate_outh2_token(x_token => l_x_token, x_status => l_x_status, x_error_code => l_x_error_code,
                            x_error_message => l_x_error_message);

        IF l_x_token IS NOT NULL THEN
            apex_web_service.g_request_headers(1).name := 'Authorization';
            apex_web_service.g_request_headers(1).value := 'Bearer ' || l_x_token;

        --dbms_output.put_line ('L_X_TOKEN: ' || L_X_TOKEN);

            l_clob := apex_web_service.make_rest_request(p_url => 'https://graph.microsoft.com/v1.0/users/'
                                                                  || p_user_email
                                                                  || '/calendar/calendarView?startDateTime=2020-08-01T19%3a00%3a00-08%3a00'
                                                                  || CHR(38)
                                                                  || 'endDateTime=2020-08-12T19%3a00%3a00-08%3a00'
                                                                  || CHR(38)
                                                                  || '$skip=20',
                                                        p_http_method => 'GET');
            /*https://graph.microsoft.com/v1.0/users/'||p_user_email||'/events?$filter=start/dateTime ge '2017-07-01T08:00' and end/dateTime ge '2017-07-30T08:00'
'|| CHR(38)||'select=subject,start,end*/
            /* 'https://graph.microsoft.com/v1.0/users/'||p_user_email||'/events?$select=subject,body,bodyPreview,organizer,attendees,start,end,location'*/
            /*SGM*/
        --dbms_output.put_line ('l_clob: ' || substr(l_clob,1,3999));
            apex_collection.create_or_truncate_collection(p_collection_name => 'OFFICE');
            apex_collection.add_member(p_collection_name => 'OFFICE', p_clob001 => l_clob);
        /*SGM*/
        END IF;

         /*IF l_clob IS NULL THEN
           x_status        := 'S';
           x_error_code    := NULL;
           x_error_message := NULL;
         ELSE
           apex_json.parse (l_clob);
           x_status        := 'E';
           x_error_code    := substr(apex_json.get_varchar2 ('error.code'),1,999);
           x_error_message := substr(apex_json.get_varchar2 ('error.message'),1,3999);


        --dbms_output.put_line ('code: ' || apex_json.get_varchar2 ('error.code'));
        --dbms_output.put_line ('message: ' || apex_json.get_varchar2 ('error.message'));
       END IF;
  ELSE
   x_status        := 'E';
   x_error_code    := substr(L_X_ERROR_CODE,1,999);
   x_error_message := substr(L_X_ERROR_MESSAGE,1,3999);
   END IF;
    EXCEPTION WHEN OTHERS THEN */
        x_status := 'P';
      --x_error_code    := NULL;
      --x_error_message := NULL;

    END get_cal_events;

    PROCEDURE get_user_details (
        p_user_email     IN   VARCHAR2,
        x_status         OUT  VARCHAR2,
        x_error_message  OUT  VARCHAR2,
        x_msft_user_id   OUT  VARCHAR2 
    ) IS

        l_x_token              VARCHAR2(10000);
        l_x_status             VARCHAR2(200);
        l_x_error_code         VARCHAR2(200);
        l_x_error_message      VARCHAR2(4000);
        l_clob                 CLOB;
        l_user_exists          NUMBER;
        l_user_principle_name  VARCHAR2(500) := NULL;
        CURSOR c_get_emails IS
        SELECT
            address email
        FROM
            c_emails
        WHERE
                upper(type) = 'WORK'
            AND upper(address) = nvl(upper(p_user_email), upper(address))
            AND status = 1;

    BEGIN
        generate_outh2_token(x_token => l_x_token, x_status => l_x_status, x_error_code => l_x_error_code,
                            x_error_message => l_x_error_message);

        IF l_x_token IS NOT NULL THEN
           -- FOR rec_get_emails IN c_get_emails LOOP
            apex_web_service.g_request_headers(1).name := 'Authorization';
            apex_web_service.g_request_headers(1).value := 'Bearer ' || l_x_token;
            dbms_output.put_line('L_X_TOKEN: ' || l_x_token);
            l_clob := apex_web_service.make_rest_request(p_url => 'https://graph.microsoft.com/v1.0/users/'
                                                                  || p_user_email --|| rec_get_emails.email
                                                                  || '?$select=displayName,givenName,jobTitle,mail,mobilePhone,businessPhones,officeLocation,userPrincipalName,id,surname,hireDate,department,userType,accountEnabled'
                                                                  || CHR(38)
                                                                  || '$expand=manager($levels=max;$select=displayName,department,jobTitle,mail,mobilePhone,businessPhones)'
                                                                  || CHR(38)
                                                                  || '$count=true',
                                                        p_http_method => 'GET');

         --apex_json.parse(l_clob);
            dbms_output.put_line('after api call status ' || apex_web_service.g_status_code);
            dbms_output.put_line(l_clob);
            IF l_clob IS NOT NULL THEN
                apex_json.parse(l_clob);
                l_user_principle_name := apex_json.get_varchar2(p_path => 'userPrincipalName');
                dbms_output.put_line('after api call l_user_principle_name ' || l_user_principle_name);
                SELECT
                    COUNT(*)
                INTO l_user_exists
                FROM
                    c_msft_o365_users
                WHERE
                    user_principal_name = l_user_principle_name;

                dbms_output.put_line('l_user_exists API call: ' || l_user_exists);
                IF l_user_exists > 0 THEN
                    UPDATE c_msft_o365_users
                    SET
                        display_name = apex_json.get_varchar2(p_path => 'displayName'),
                        given_name = apex_json.get_varchar2(p_path => 'givenName'),
                        job_title = apex_json.get_varchar2(p_path => 'jobTitle'),
                        mail = apex_json.get_varchar2(p_path => 'mail'),
                        mobile_phone = apex_json.get_varchar2(p_path => 'mobilePhone'),
                        business_phone = apex_json.get_varchar2(p_path => 'businessPhones[1]'),
                        office_location = apex_json.get_varchar2(p_path => 'officeLocation'),
                        last_update_date = sysdate,
                        department = apex_json.get_varchar2(p_path => 'department'),
                        manager_name = apex_json.get_varchar2(p_path => 'manager.displayName'),
                        manager_email = apex_json.get_varchar2(p_path => 'manager.mail'),
                        manager_job_title = apex_json.get_varchar2(p_path => 'manager.jobTitle'),
                        manager_department = apex_json.get_varchar2(p_path => 'manager.department'),
                        manager_mobile = apex_json.get_varchar2(p_path => 'manager.mobilePhone'),
                        manager_business_phones = apex_json.get_varchar2(p_path => 'manager.businessPhones[1]'),
                        account_enabled = apex_json.get_varchar2(p_path => 'accountEnabled')
                    WHERE
                        user_principal_name = l_user_principle_name;

                    COMMIT;
                ELSE
                    IF apex_json.get_varchar2(p_path => 'id') IS NOT NULL THEN
                        INSERT INTO c_msft_o365_users a (
                            gtt_user_id,
                            msft_user_id,
                            user_principal_name,
                            display_name,
                            given_name,
                            job_title,
                            mail,
                            mobile_phone,
                            business_phone,
                            office_location,
                            created_by,
                            creation_date,
                            last_updated_by,
                            last_update_date,
                            department,
                            manager_name,
                            manager_email,
                            manager_job_title,
                            manager_department,
                            manager_mobile,
                            manager_business_phones,
                            account_enabled
                        ) VALUES (
                            c_msft_o365_users_sq.NEXTVAL,
                            apex_json.get_varchar2(p_path => 'id'),
                            apex_json.get_varchar2(p_path => 'userPrincipalName'),
                            apex_json.get_varchar2(p_path => 'displayName'),
                            apex_json.get_varchar2(p_path => 'givenName'),
                            apex_json.get_varchar2(p_path => 'jobTitle'),
                            apex_json.get_varchar2(p_path => 'mail'),
                            apex_json.get_varchar2(p_path => 'mobilePhone'),
                            apex_json.get_varchar2(p_path => 'businessPhones[1]'),
                            apex_json.get_varchar2(p_path => 'officeLocation'),
                            - 1,
                            sysdate,
                            - 1,
                            sysdate,
                            apex_json.get_varchar2(p_path => 'department'),
                            apex_json.get_varchar2(p_path => 'manager.displayName'),
                            apex_json.get_varchar2(p_path => 'manager.mail'),
                            apex_json.get_varchar2(p_path => 'manager.jobTitle'),
                            apex_json.get_varchar2(p_path => 'manager.department'),
                            apex_json.get_varchar2(p_path => 'manager.mobilePhone'),
                            apex_json.get_varchar2(p_path => 'manager.businessPhones[1]'),
                            apex_json.get_varchar2(p_path => 'accountEnabled')
                        );

                    END IF;

                    COMMIT;
                END IF;
            
                    --INSERT INTO test_json(test_json) values(l_clob);
                dbms_output.put_line('l_clob: '
                                     || substr(l_clob, 1, 37000));
                IF apex_json.get_varchar2('error.message') IS NULL THEN
                    x_msft_user_id := apex_json.get_varchar2(p_path => 'id');
                    x_status := 'S';
                    x_error_message := NULL;
                ELSE
                    x_status := 'E';
                    x_error_message := substr(apex_json.get_varchar2('error.message'), 1, 3999);
                    dbms_output.put_line('message: ' || apex_json.get_varchar2('error.message'));
                END IF;

            ELSE
                apex_json.parse(l_clob);
                    --INSERT INTO test_json(test_json) values(l_clob);
                dbms_output.put_line('l_clob: '
                                     || substr(l_clob, 1, 37000));
                x_status := 'E';
                x_error_message := substr(apex_json.get_varchar2('error.message'), 1, 3999);
                dbms_output.put_line('message: ' || apex_json.get_varchar2('error.message'));
            END IF;

            COMMIT;
           -- END LOOP;

        ELSE
            x_status := 'E';
            x_error_message := substr(l_x_error_message, 1, 3999);
        END IF;

    EXCEPTION
        WHEN OTHERS THEN
            x_status := 'E';
            x_error_message := sqlerrm;
    END get_user_details;

    PROCEDURE update_user_details (
        p_user_email       IN   VARCHAR2,
        p_job_title        IN   VARCHAR2,
        p_mobile_phone     IN   VARCHAR2,
        p_business_phone   IN   VARCHAR2,
        p_office_location  IN   VARCHAR2,
        p_department       IN   VARCHAR2,
        x_status           OUT  VARCHAR2,
        x_error_message    OUT  VARCHAR2
    ) IS

        lx_status              VARCHAR2(240);
        lx_error_message       VARCHAR2(4000);
        lc_user_update_body    CLOB;
        lc_user_update_result  CLOB;
        l_x_token              VARCHAR2(4000);
        l_x_error_code         VARCHAR2(500);
        l_job_title            VARCHAR2(500);
        l_mobile_phone         VARCHAR2(500);
        l_business_phone       VARCHAR2(500);
        l_office_location      VARCHAR2(500);
        l_department           VARCHAR2(500);
    BEGIN
       -- get_user_details(p_user_email, lx_status, lx_error_message);
        lx_status := 'S';
        IF lx_status = 'S' THEN
            lx_status := NULL;
            lx_error_message := NULL;
            generate_outh2_token(x_token => l_x_token, x_status => lx_status, x_error_code => l_x_error_code,
                                x_error_message => lx_error_message);

            IF l_x_token IS NOT NULL THEN
                x_status := 'S';
                BEGIN
                    SELECT
                        nvl(p_job_title, job_title),
                        nvl(p_mobile_phone, mobile_phone),
                        nvl(p_business_phone, business_phone),
                        nvl(p_office_location, office_location),
                        nvl(p_department, department)
                    INTO
                        l_job_title,
                        l_mobile_phone,
                        l_business_phone,
                        l_office_location,
                        l_department
                    FROM
                        c_msft_o365_users
                    WHERE
                        user_principal_name = p_user_email;

                EXCEPTION
                    WHEN OTHERS THEN
                        x_status := 'E';
                        x_error_message := sqlerrm;
                END;

                dbms_output.put_line('after fecthing details.');
                IF x_status = 'S' THEN
                    apex_web_service.g_request_headers(1).name := 'Content-Type';
                    apex_web_service.g_request_headers(1).value := 'application/json';
                    apex_web_service.g_request_headers(2).name := 'Authorization';
                    apex_web_service.g_request_headers(2).value := 'Bearer ' || l_x_token;
                    lc_user_update_body := '{
                  "jobTitle": '
                                           || '"'
                                           || l_job_title
                                           || '"'
                                           || ',
                  "department": '
                                           || '"'
                                           || l_department
                                           || '"'
                                           || ',  
                    "mobilePhone": '
                                           || '"'
                                           || l_mobile_phone
                                           || '"'
                                           || ',
                      "officeLocation": '
                                           || '"'
                                           || l_office_location
                                           || '"'
                                           || ', 

                  "businessPhones": ['
                                           || '"'
                                           || l_business_phone
                                           || '"'
                                           || ']
                        }';

                    dbms_output.put_line('lc_user_update_body '
                                         || substr(lc_user_update_body, 1, 3999));
                    lc_user_update_result := apex_web_service.make_rest_request(p_url => 'https://graph.microsoft.com/v1.0/users/' ||
                    p_user_email,
                                                                               p_http_method => 'PATCH',
                                                                               p_body => lc_user_update_body);

                    dbms_output.put_line('Webservice Status Code ' || apex_web_service.g_status_code);
                    apex_json.parse(lc_user_update_result);
                    dbms_output.put_line('lc_user_update_result = '
                                         || substr(lc_user_update_result, 1, 3000));
                    IF apex_web_service.g_status_code = '200' THEN
                        apex_json.parse(lc_user_update_result);
                        dbms_output.put_line('lc_user_update_result = '
                                             || substr(lc_user_update_result, 1, 3000));
                        x_status := 'S';
                        x_error_message := NULL;
                    END IF;

                END IF;

            END IF;

        ELSE
            x_status := lx_status;
            x_error_message := 'Exception from Get User Details API ' || lx_error_message;
        END IF;

    EXCEPTION
        WHEN OTHERS THEN
            x_status := 'E';
            x_error_message := sqlerrm;
    END update_user_details;

    PROCEDURE get_team_members_roles (
        p_team_id        IN   VARCHAR2 DEFAULT NULL,
        p_user_email     IN   VARCHAR2 DEFAULT NULL,
        x_status         OUT  VARCHAR2,
        x_error_message  OUT  VARCHAR2
    ) IS

        l_x_token              VARCHAR2(10000);
        l_x_status             VARCHAR2(200);
        l_x_error_code         VARCHAR2(200);
        l_x_error_message      VARCHAR2(4000);
        l_clob                 CLOB;
        l_user_team_exists     NUMBER;
        l_user_principle_name  VARCHAR2(500) := NULL;
        CURSOR c_get_teams IS
        SELECT DISTINCT
            msft_team_id team_id
        FROM
            c_msft_o365_user_joined_teams
        WHERE
                msft_team_id = nvl(p_team_id, msft_team_id)
            AND user_principal_name = nvl(p_user_email, user_principal_name);

    BEGIN
        generate_outh2_token(x_token => l_x_token, x_status => l_x_status, x_error_code => l_x_error_code,
                            x_error_message => l_x_error_message);

        dbms_output.put_line('L_X_TOKEN: ' || l_x_token);
        FOR rec_get_teams IN c_get_teams LOOP
            IF l_x_token IS NOT NULL THEN
                apex_web_service.g_request_headers(1).name := 'Authorization';
                apex_web_service.g_request_headers(1).value := 'Bearer ' || l_x_token;
                l_clob := apex_web_service.make_rest_request(p_url => 'https://graph.microsoft.com/v1.0/teams/'
                                                                      || rec_get_teams.team_id
                                                                      || '/members',
                                                            p_http_method => 'GET');

         --apex_json.parse(l_clob);
        -- dbms_output.put_line('l_clob after API call: '
          --                           || substr(l_clob, 1, 37000));

                IF l_clob IS NOT NULL THEN
                    apex_json.parse(l_clob);
                --l_user_principle_name := apex_json.get_varchar2(p_path => 'userPrincipalName');



                    FOR i IN 1..apex_json.get_count(p_path => 'value') LOOP
                        dbms_output.put_line('Roles API call: '
                                             || apex_json.get_varchar2(p_path => 'value[%d].roles[1]', p0 => i));

                        UPDATE c_msft_o365_user_joined_teams
                        SET
                            roles = nvl(apex_json.get_varchar2(p_path => 'value[%d].roles[1]', p0 => i), 'Member'),
                            last_update_date = sysdate
                        WHERE
                                user_principal_name = apex_json.get_varchar2(p_path => 'value[%d].email', p0 => i)
                            AND msft_team_id = rec_get_teams.team_id;

                    END LOOP;

                    COMMIT;
                
                --dbms_output.put_line('l_clob: '
                --                     || substr(l_clob, 1, 37000));
                    IF apex_json.get_varchar2('error.message') IS NULL THEN
                        x_status := 'S';
                        x_error_message := NULL;
                    ELSE
                        x_status := 'E';
                        x_error_message := substr(apex_json.get_varchar2('error.message'), 1, 3999);
                        dbms_output.put_line('message: ' || apex_json.get_varchar2('error.message'));
                    END IF;

                ELSE
                    apex_json.parse(l_clob);
            --INSERT INTO test_json(test_json) values(l_clob);
                    dbms_output.put_line('l_clob: '
                                         || substr(l_clob, 1, 37000));
                    x_status := 'E';
                    x_error_message := substr(apex_json.get_varchar2('error.message'), 1, 3999);
                    dbms_output.put_line('message: ' || apex_json.get_varchar2('error.message'));
                END IF;

                COMMIT;
            ELSE
                x_status := 'E';
                x_error_message := substr(l_x_error_message, 1, 3999);
            END IF;
        END LOOP;

    EXCEPTION
        WHEN OTHERS THEN
            x_status := 'E';
            x_error_message := sqlerrm;
    END get_team_members_roles;

    PROCEDURE get_user_joined_teams (
        p_user_email     IN   VARCHAR2,
        x_status         OUT  VARCHAR2,
        x_error_message  OUT  VARCHAR2
    ) IS

        l_x_token              VARCHAR2(10000);
        l_x_status             VARCHAR2(200);
        l_x_error_code         VARCHAR2(200);
        l_x_error_message      VARCHAR2(4000);
        l_clob                 CLOB;
        l_user_team_exists     NUMBER := NULL;
        l_user_principle_name  VARCHAR2(500) := NULL;
        CURSOR c_get_users IS
        SELECT
            user_principal_name
        FROM
            c_msft_o365_users
        WHERE
                1 = 1
            AND upper(user_principal_name) = upper(nvl(p_user_email, user_principal_name));

    BEGIN
        generate_outh2_token(x_token => l_x_token, x_status => l_x_status, x_error_code => l_x_error_code,
                            x_error_message => l_x_error_message);

        IF l_x_token IS NOT NULL THEN
            FOR rec_get_users IN c_get_users LOOP
                apex_web_service.g_request_headers(1).name := 'Authorization';
                apex_web_service.g_request_headers(1).value := 'Bearer ' || l_x_token;
                dbms_output.put_line('L_X_TOKEN: ' || l_x_token);
                l_clob := apex_web_service.make_rest_request(p_url => 'https://graph.microsoft.com/v1.0/users/'
                                                                      || rec_get_users.user_principal_name
                                                                      || '/joinedTeams',
                                                            p_http_method => 'GET');

         --apex_json.parse(l_clob);
        -- dbms_output.put_line('l_clob after API call: '
          --                           || substr(l_clob, 1, 37000));

                IF l_clob IS NOT NULL THEN
                    apex_json.parse(l_clob);
                   -- dbms_output.put_line('l_clob: '
                    --                     || substr(l_clob, 1, 37000));
                --l_user_principle_name := apex_json.get_varchar2(p_path => 'userPrincipalName');

                    --dbms_output.put_line('l_user_exists API call: ' || l_user_team_exists);
                    FOR i IN 1..apex_json.get_count(p_path => 'value') LOOP
                        l_user_team_exists := 0;
                        SELECT
                            COUNT(*)
                        INTO l_user_team_exists
                        FROM
                            c_msft_o365_user_joined_teams
                        WHERE
                                user_principal_name = rec_get_users.user_principal_name
                            AND msft_team_id = apex_json.get_varchar2(p_path => 'value[%d].id', p0 => i);

                        dbms_output.put_line('l_user_exists API call: '
                                             || l_user_team_exists
                                             || ' msft_team_id '
                                             || apex_json.get_varchar2(p_path => 'value[%d].id', p0 => i));

                        IF l_user_team_exists > 0 THEN
                            UPDATE c_msft_o365_user_joined_teams
                            SET
                                team_display_name = substr(apex_json.get_varchar2(p_path => 'value[%d].displayName', p0 => i), 1,
                                3999),
                                team_description = substr(apex_json.get_varchar2(p_path => 'value[%d].description', p0 => i), 1, 3999),
                                last_update_date = sysdate
                            WHERE
                                    user_principal_name = rec_get_users.user_principal_name
                                AND msft_team_id = apex_json.get_varchar2(p_path => 'value[%d].id', p0 => i);

                            COMMIT;
                        ELSE
                            INSERT INTO c_msft_o365_user_joined_teams (
                                gtt_team_id,
                                user_principal_name,
                                msft_team_id,
                                team_display_name,
                                team_description,
                                created_by,
                                creation_date,
                                last_update_date,
                                last_updated_by
                            ) VALUES (
                                c_msft_o365_user_joined_teams_sq.NEXTVAL,
                                p_user_email,
                                apex_json.get_varchar2(p_path => 'value[%d].id',
                                                      p0 => i),
                                substr(apex_json.get_varchar2(p_path => 'value[%d].displayName', p0 => i), 1, 3999),
                                substr(apex_json.get_varchar2(p_path => 'value[%d].description', p0 => i), 1, 3999),
                                - 1,
                                sysdate,
                                sysdate,
                                - 1
                            );

                        END IF;

                        COMMIT;
                    END LOOP;   
                
                
            
           --INSERT INTO test_json(test_json) values(l_clob);
                    --dbms_output.put_line('l_clob: '
                      --                   || substr(l_clob, 1, 37000));
                    IF apex_json.get_varchar2('error.message') IS NULL THEN
                        x_status := 'S';
                        x_error_message := NULL;
                    ELSE
                        x_status := 'E';
                        x_error_message := substr(apex_json.get_varchar2('error.message'), 1, 3999);
                        dbms_output.put_line('message: ' || apex_json.get_varchar2('error.message'));
                    END IF;

                ELSE
                    apex_json.parse(l_clob);
            --INSERT INTO test_json(test_json) values(l_clob);
                   -- dbms_output.put_line('l_clob: '
                     --                    || substr(l_clob, 1, 37000));
                    x_status := 'E';
                    x_error_message := substr(apex_json.get_varchar2('error.message'), 1, 3999);
                    dbms_output.put_line('message: ' || apex_json.get_varchar2('error.message'));
                END IF;

            END LOOP;

            COMMIT;
        ELSE
            x_status := 'E';
            x_error_message := substr(l_x_error_message, 1, 3999);
        END IF;

    EXCEPTION
        WHEN OTHERS THEN
            x_status := 'E';
            x_error_message := sqlerrm;
    END get_user_joined_teams;

    PROCEDURE get_team_channels (
        p_team_id        IN   VARCHAR2 DEFAULT NULL,
        x_status         OUT  VARCHAR2,
        x_error_message  OUT  VARCHAR2
    ) IS

        l_x_token              VARCHAR2(10000);
        l_x_status             VARCHAR2(200);
        l_x_error_code         VARCHAR2(200);
        l_x_error_message      VARCHAR2(4000);
        l_clob                 CLOB;
        l_user_team_exists     NUMBER;
        l_user_principle_name  VARCHAR2(500) := NULL;
        l_channel_exist_count  NUMBER := 0;
    BEGIN
        generate_outh2_token(x_token => l_x_token, x_status => l_x_status, x_error_code => l_x_error_code,
                            x_error_message => l_x_error_message);

        dbms_output.put_line('L_X_TOKEN: ' || l_x_token);
       -- FOR rec_get_teams IN c_get_teams LOOP
        IF l_x_token IS NOT NULL THEN
            apex_web_service.g_request_headers(1).name := 'Authorization';
            apex_web_service.g_request_headers(1).value := 'Bearer ' || l_x_token;
            l_clob := apex_web_service.make_rest_request(p_url => 'https://graph.microsoft.com/v1.0/teams/'
                                                                  || p_team_id
                                                                  || '/channels',
                                                        p_http_method => 'GET');

         --apex_json.parse(l_clob);
        -- dbms_output.put_line('l_clob after API call: '
          --                           || substr(l_clob, 1, 37000));

            IF l_clob IS NOT NULL THEN
                apex_json.parse(l_clob);
                    --INSERT INTO test_json(test_json) values(l_clob);
                --l_user_principle_name := apex_json.get_varchar2(p_path => 'userPrincipalName');
                --dbms_output.put_line('Team Channels API call: '|| substr(l_clob, 1, 37000));



                FOR i IN 1..apex_json.get_count(p_path => 'value') LOOP
                    SELECT
                        COUNT(*)
                    INTO l_channel_exist_count
                    FROM
                        c_msft_team_channels
                    WHERE
                        msft_channel_id = apex_json.get_varchar2(p_path => 'value[%d].id', p0 => i);

                    IF l_channel_exist_count > 0 THEN
                        UPDATE c_msft_team_channels
                        SET
                            display_name = apex_json.get_varchar2(p_path => 'value[%d].displayName', p0 => i),
                            description = apex_json.get_varchar2(p_path => 'value[%d].description', p0 => i),
                            is_favoritebydefault = apex_json.get_varchar2(p_path => 'value[%d].isFavoriteByDefault', p0 => i),
                            weburl = apex_json.get_varchar2(p_path => 'value[%d].webUrl', p0 => i),
                            membership_type = apex_json.get_varchar2(p_path => 'value[%d].membershipType', p0 => i)
                        WHERE
                            msft_channel_id = apex_json.get_varchar2(p_path => 'value[%d].id', p0 => i);

                    ELSE
                        INSERT INTO c_msft_team_channels (
                            gtt_channel_id,
                            msft_team_id,
                            msft_channel_id,
                            display_name,
                            description,
                            is_favoritebydefault,
                            weburl,
                            membership_type,
                            created_by,
                            creation_date,
                            last_update_date,
                            last_updated_by
                        ) VALUES (
                            c_msft_team_channels_sq.NEXTVAL,
                            p_team_id,
                            apex_json.get_varchar2(p_path => 'value[%d].id',
                                                  p0 => i),
                            apex_json.get_varchar2(p_path => 'value[%d].displayName', p0 => i),
                            apex_json.get_varchar2(p_path => 'value[%d].description', p0 => i),
                            apex_json.get_varchar2(p_path => 'value[%d].isFavoriteByDefault', p0 => i),
                            apex_json.get_varchar2(p_path => 'value[%d].webUrl', p0 => i),
                            apex_json.get_varchar2(p_path => 'value[%d].membershipType', p0 => i),
                            - 1,
                            sysdate,
                            sysdate,
                            - 1
                        );

                       -- COMMIT;
                    END IF;

                END LOOP;

                COMMIT;
                IF apex_json.get_varchar2('error.message') IS NULL THEN
                    x_status := 'S';
                    x_error_message := NULL;
                ELSE
                    x_status := 'E';
                    x_error_message := substr(apex_json.get_varchar2('error.message'), 1, 3999);
                    dbms_output.put_line('message: ' || apex_json.get_varchar2('error.message'));
                END IF;

            ELSE
                apex_json.parse(l_clob);
                    --INSERT INTO test_json(test_json) values(l_clob);
                   -- dbms_output.put_line('l_clob: '
                     --                    || substr(l_clob, 1, 37000));
                x_status := 'E';
                x_error_message := substr(apex_json.get_varchar2('error.message'), 1, 3999);
                dbms_output.put_line('message: ' || apex_json.get_varchar2('error.message'));
            END IF;

            COMMIT;
        ELSE
            x_status := 'E';
            x_error_message := substr(l_x_error_message, 1, 3999);
        END IF;
       -- END LOOP;

    EXCEPTION
        WHEN OTHERS THEN
            x_status := 'E';
            x_error_message := sqlerrm;
    END get_team_channels;

    

    PROCEDURE get_joined_team_channels (
        p_team_id        IN   VARCHAR2 DEFAULT NULL,
        x_status         OUT  VARCHAR2,
        x_error_message  OUT  VARCHAR2
    ) IS

        l_x_token              VARCHAR2(10000);
        l_x_status             VARCHAR2(200);
        l_x_error_code         VARCHAR2(200);
        l_x_error_message      VARCHAR2(4000);
        l_clob                 CLOB;
        l_user_team_exists     NUMBER;
        l_user_principle_name  VARCHAR2(500) := NULL;
        CURSOR c_get_teams IS
        SELECT DISTINCT
            msft_team_id team_id
        FROM
            c_msft_o365_user_joined_teams
        WHERE
            msft_team_id = nvl(p_team_id, msft_team_id)
            --AND rownum < 3
            ;

        l_channel_exist_count  NUMBER := 0;
    BEGIN
        generate_outh2_token(x_token => l_x_token, x_status => l_x_status, x_error_code => l_x_error_code,
                            x_error_message => l_x_error_message);

        dbms_output.put_line('L_X_TOKEN: ' || l_x_token);
        FOR rec_get_teams IN c_get_teams LOOP
            IF l_x_token IS NOT NULL THEN
                apex_web_service.g_request_headers(1).name := 'Authorization';
                apex_web_service.g_request_headers(1).value := 'Bearer ' || l_x_token;
                l_clob := apex_web_service.make_rest_request(p_url => 'https://graph.microsoft.com/v1.0/teams/'
                                                                      || rec_get_teams.team_id
                                                                      || '/channels',
                                                            p_http_method => 'GET');

         --apex_json.parse(l_clob);
        -- dbms_output.put_line('l_clob after API call: '
          --                           || substr(l_clob, 1, 37000));

                IF l_clob IS NOT NULL THEN
                    apex_json.parse(l_clob);
                    --INSERT INTO test_json(test_json) values(l_clob);
                --l_user_principle_name := apex_json.get_varchar2(p_path => 'userPrincipalName');
                --dbms_output.put_line('Team Channels API call: '|| substr(l_clob, 1, 37000));



                    FOR i IN 1..apex_json.get_count(p_path => 'value') LOOP
                        SELECT
                            COUNT(*)
                        INTO l_channel_exist_count
                        FROM
                            c_msft_team_channels
                        WHERE
                            msft_channel_id = apex_json.get_varchar2(p_path => 'value[%d].id', p0 => i);

                        IF l_channel_exist_count > 0 THEN
                            UPDATE c_msft_team_channels
                            SET
                                display_name = apex_json.get_varchar2(p_path => 'value[%d].displayName', p0 => i),
                                description = apex_json.get_varchar2(p_path => 'value[%d].description', p0 => i),
                                is_favoritebydefault = apex_json.get_varchar2(p_path => 'value[%d].isFavoriteByDefault', p0 => i),
                                weburl = apex_json.get_varchar2(p_path => 'value[%d].webUrl', p0 => i),
                                membership_type = apex_json.get_varchar2(p_path => 'value[%d].membershipType', p0 => i)
                            WHERE
                                msft_channel_id = apex_json.get_varchar2(p_path => 'value[%d].id', p0 => i);

                        ELSE
                            INSERT INTO c_msft_team_channels (
                                gtt_channel_id,
                                msft_team_id,
                                msft_channel_id,
                                display_name,
                                description,
                                is_favoritebydefault,
                                weburl,
                                membership_type,
                                created_by,
                                creation_date,
                                last_update_date,
                                last_updated_by
                            ) VALUES (
                                c_msft_team_channels_sq.NEXTVAL,
                                rec_get_teams.team_id,
                                apex_json.get_varchar2(p_path => 'value[%d].id',
                                                      p0 => i),
                                apex_json.get_varchar2(p_path => 'value[%d].displayName', p0 => i),
                                apex_json.get_varchar2(p_path => 'value[%d].description', p0 => i),
                                apex_json.get_varchar2(p_path => 'value[%d].isFavoriteByDefault', p0 => i),
                                apex_json.get_varchar2(p_path => 'value[%d].webUrl', p0 => i),
                                apex_json.get_varchar2(p_path => 'value[%d].membershipType', p0 => i),
                                - 1,
                                sysdate,
                                sysdate,
                                - 1
                            );

                       -- COMMIT;
                        END IF;

                    END LOOP;

                    COMMIT;
                    IF apex_json.get_varchar2('error.message') IS NULL THEN
                        x_status := 'S';
                        x_error_message := NULL;
                    ELSE
                        x_status := 'E';
                        x_error_message := substr(apex_json.get_varchar2('error.message'), 1, 3999);
                        dbms_output.put_line('message: ' || apex_json.get_varchar2('error.message'));
                    END IF;

                ELSE
                    apex_json.parse(l_clob);
                    --INSERT INTO test_json(test_json) values(l_clob);
                   -- dbms_output.put_line('l_clob: '
                     --                    || substr(l_clob, 1, 37000));
                    x_status := 'E';
                    x_error_message := substr(apex_json.get_varchar2('error.message'), 1, 3999);
                    dbms_output.put_line('message: ' || apex_json.get_varchar2('error.message'));
                END IF;

                COMMIT;
            ELSE
                x_status := 'E';
                x_error_message := substr(l_x_error_message, 1, 3999);
            END IF;
        END LOOP;

    EXCEPTION
        WHEN OTHERS THEN
            x_status := 'E';
            x_error_message := sqlerrm;
    END get_joined_team_channels;

    PROCEDURE get_onedrive_shared_files (
        p_user_email     IN   VARCHAR2,
        x_status         OUT  VARCHAR2,
        x_error_message  OUT  VARCHAR2
    ) IS

        l_x_token              VARCHAR2(10000);
        l_x_status             VARCHAR2(2000);
        l_x_error_code         VARCHAR2(2000);
        l_x_error_message      VARCHAR2(4000);
        l_clob                 CLOB;
        l_user_principle_name  VARCHAR2(500) := NULL;
        CURSOR c_get_users IS
        SELECT
            user_principal_name user_email
        FROM
            c_msft_o365_users
        WHERE
            user_principal_name = nvl(p_user_email, user_principal_name);

    BEGIN
        generate_outh2_token(x_token => l_x_token, x_status => l_x_status, x_error_code => l_x_error_code,
                            x_error_message => l_x_error_message);

        IF p_user_email IS NULL THEN
            EXECUTE IMMEDIATE 'TRUNCATE TABLE c_msft_onedrive_items';
        ELSE
            DELETE FROM c_msft_onedrive_items
            WHERE
                user_principal_name = p_user_email;

        END IF;

        IF l_x_token IS NOT NULL THEN
            FOR rec_get_users IN c_get_users LOOP
                apex_web_service.g_request_headers(1).name := 'Authorization';
                apex_web_service.g_request_headers(1).value := 'Bearer ' || l_x_token;
                dbms_output.put_line('L_X_TOKEN: ' || l_x_token);
                l_clob := apex_web_service.make_rest_request(p_url => 'https://graph.microsoft.com/v1.0/users/'
                                                                      || rec_get_users.user_email
                                                                      || '/drive/sharedWithMe',
                                                            p_http_method => 'GET');

                dbms_output.put_line(' status ' || apex_web_service.g_status_code);
                IF l_clob IS NOT NULL THEN
                    apex_json.parse(l_clob);
                --l_user_principle_name := apex_json.get_varchar2(p_path => 'userPrincipalName');

               -- dbms_output.put_line('l_user_exists API call: ' || l_user_team_exists);
                    FOR i IN 1..apex_json.get_count(p_path => 'value') LOOP
                    --l_user_team_exists := 0;

                        INSERT INTO c_msft_onedrive_items (
                            gtt_item_id,
                            user_principal_name,
                            msft_drive_item_id,
                            item_name,
                            web_url,
                            item_created_by_email,
                            item_created_by_user,
                            item_last_upd_by_email,
                            item_last_upd_by_usr,
                            file_mime_type,
                            filesys_crt_dt,
                            filesys_last_modify_dt,
                            parent_driveid,
                            parent_drivetype,
                            shared_scope,
                            shared_datetime,
                            sharedby_user_email,
                            sharedby_user_name,
                            folder_child_count,
                            created_by,
                            creation_date,
                            last_update_date,
                            last_updated_by
                        ) VALUES (
                            c_msft_onedrive_items_sq.NEXTVAL, --GTT_ITEM_ID, 
                            rec_get_users.user_email, --	 USER_PRINCIPAL_NAME   , 
                            apex_json.get_varchar2(p_path => 'value[%d].id', p0 => i),  --MSFT_DRIVE_ITEM_ID  , 

                            apex_json.get_varchar2(p_path => 'value[%d].name', p0 => i),  --ITEM_NAME   , 
                            apex_json.get_varchar2(p_path => 'value[%d].webUrl', p0 => i),  --web_url,
                            apex_json.get_varchar2(p_path => 'value[%d].createdBy.user.email', p0 => i),  --ITEM_CREATED_BY_EMAIL   , 
                            apex_json.get_varchar2(p_path => 'value[%d].createdBy.user.displayName', p0 => i),  --ITEM_CREATED_BY_USER   ,
                            apex_json.get_varchar2(p_path => 'value[%d].lastModifiedBy.user.email', p0 => i),  --ITEM_LAST_UPD_BY_EMAIL   , 
                            apex_json.get_varchar2(p_path => 'value[%d].lastModifiedBy.user.displayName', p0 => i),  --ITEM_LAST_UPD_BY_USR   ,
                            apex_json.get_varchar2(p_path => 'value[%d].file.mimeType', p0 => i),  --file_mime_type  ,
                            apex_json.get_varchar2(p_path => 'value[%d].fileSystemInfo.createdDateTime', p0 => i),  --filesys_crt_dt  ,
                            apex_json.get_varchar2(p_path => 'value[%d].fileSystemInfo.lastModifiedDateTime', p0 => i),  --FILESYS_LAST_MODIFY_DT  ,
                            apex_json.get_varchar2(p_path => 'value[%d].remoteItem.parentReference.driveId', p0 => i), --parent_driveid  ,
                            apex_json.get_varchar2(p_path => 'value[%d].remoteItem.parentReference.driveType', p0 => i), --parent_drivetype  ,
                            apex_json.get_varchar2(p_path => 'value[%d].remoteItem.shared.scope', p0 => i), --shared_scope  ,
                            apex_json.get_varchar2(p_path => 'value[%d].remoteItem.shared.sharedDateTime', p0 => i), --shared_datetime  ,
                            apex_json.get_varchar2(p_path => 'value[%d].remoteItem.shared.sharedBy.user.email', p0 => i), --sharedBy_user_email  ,
                            apex_json.get_varchar2(p_path => 'value[%d].remoteItem.shared.sharedBy.user.displayName', p0 => i), --sharedBy_user_name  ,
                            apex_json.get_varchar2(p_path => 'value[%d].remoteItem.folder.childCount', p0 => i), --folder_child_count,
                            v('USER_ID'),  --CREATED_BY, 
                            sysdate,  --CREATION_DATE, 
                            sysdate, --LAST_UPDATE_DATE, 
                            v('USER_ID')--LAST_UPDATED_BY
                        );

                    END LOOP;

                    IF apex_json.get_varchar2('error.message') IS NULL THEN
                        x_status := 'S';
                        x_error_message := NULL;
                    ELSE
                        x_status := 'E';
                        x_error_message := substr(apex_json.get_varchar2('error.message'), 1, 3999);
                        dbms_output.put_line('message: ' || apex_json.get_varchar2('error.message'));
                    END IF;

                ELSE
                    apex_json.parse(l_clob);
            --INSERT INTO test_json(test_json) values(l_clob);
                   -- dbms_output.put_line('l_clob: '
                     --                    || substr(l_clob, 1, 37000));
                    x_status := 'E';
                    x_error_message := substr(apex_json.get_varchar2('error.message'), 1, 3999);
                    dbms_output.put_line('message: ' || apex_json.get_varchar2('error.message'));
                END IF;

                COMMIT;
            END LOOP;
        ELSE
            x_status := 'E';
            x_error_message := substr(l_x_error_message, 1, 3999);
        END IF;

    EXCEPTION
        WHEN OTHERS THEN
            x_status := 'E';
            x_error_message := sqlerrm;
    END get_onedrive_shared_files;

    PROCEDURE mail_send (
        p_email_subject     IN   VARCHAR2,
        p_to_mail           IN   VARCHAR2,
        p_cc_mail           IN   VARCHAR2,
        p_email_body        IN   VARCHAR2,
        p_email_attachment  IN   BLOB,
        x_status            OUT  VARCHAR2,
        x_error_code        OUT  VARCHAR2,
        x_error_message     OUT  VARCHAR2
    ) IS

        lc_mail_event_body   CLOB;
        lc_send_mail_result  CLOB;
        l_x_token            VARCHAR2(4000);
        l_x_status           VARCHAR2(200);
        l_x_error_code       VARCHAR2(1000);
        l_x_error_message    VARCHAR2(4000);
    BEGIN
        generate_outh2_token(x_token => l_x_token, x_status => l_x_status, x_error_code => l_x_error_code,
                            x_error_message => l_x_error_message);

        IF l_x_token IS NOT NULL THEN
            dbms_output.put_line('L_X_TOKEN ' || l_x_token);
            lc_mail_event_body := '
               {
          "message": {
            "subject": '
                                  || '"'
                                  || p_email_subject
                                  || '"'
                                  || ',
            "body": {
              "contentType": "Text",
              "content": '
                                  || '"'
                                  || p_email_body
                                  || '"'
                                  || '
            },
            "toRecipients": [
              {
                "emailAddress": {
                  "address": '
                                  || '"'
                                  || p_to_mail
                                  || '"'
                                  || '
                }
              }
            ],
            "ccRecipients": [
              {
                "emailAddress": {
                  "address": '
                                  || '"'
                                  || p_cc_mail
                                  || '"'
                                  || '
                }
              }
            ]
            ,
            "attachments": [
              {
                "@odata.type": "#microsoft.graph.fileAttachment",
                "name": "attachment.txt",
                "contentType": "text/plain",
                "contentBytes": "SGVsbG8gV29ybGQh"
              }
            ]
          },
          "saveToSentItems": "true"
        }
        ';

            apex_web_service.g_request_headers(1).name := 'Content-Type';
            apex_web_service.g_request_headers(1).value := 'application/json';
            apex_web_service.g_request_headers(2).name := 'Authorization';
            apex_web_service.g_request_headers(2).value := 'Bearer ' || l_x_token;
            lc_send_mail_result := apex_web_service.make_rest_request(p_url => 'https://graph.microsoft.com/v1.0//users/'
                                                                               || g_from_mail
                                                                               || '/sendMail',
                                                                     p_http_method => 'POST',
                                                                     p_body => lc_mail_event_body);

            dbms_output.put_line('lc_send_mail_result = '
                                 || substr(lc_send_mail_result, 1, 3000));
            apex_json.parse(lc_send_mail_result);
            IF lc_send_mail_result IS NULL THEN
                x_status := 'S';
                x_error_code := NULL;
                x_error_message := NULL;
            ELSE
                x_status := 'E';
                x_error_code := substr(apex_json.get_varchar2('error.code'), 1, 999);
                x_error_message := substr(apex_json.get_varchar2('error.message'), 1, 3999);
            END IF;

        ELSE
            x_status := 'E';
            x_error_code := substr(l_x_error_code, 1, 999);
            x_error_message := substr(l_x_error_message, 1, 999);
        END IF;

    EXCEPTION
        WHEN OTHERS THEN
            x_status := 'E';
            x_error_code := sqlcode;
            x_error_message := sqlerrm;
            x_status := NULL;
            x_error_code := NULL;
            x_error_message := NULL;
    END mail_send;

    PROCEDURE delete_message (
        p_message_id          IN   VARCHAR2,
        p_from_email_address  IN   VARCHAR2,
        x_status              OUT  VARCHAR2,
       -- x_error_code          OUT  VARCHAR2,
        x_error_message       OUT  VARCHAR2
    ) IS

        l_x_token          VARCHAR2(4000);
        l_x_status         VARCHAR2(200);
        l_x_error_code     VARCHAR2(200);
        l_x_error_message  VARCHAR2(4000);
        l_clob             CLOB;
    BEGIN
        generate_outh2_token(x_token => l_x_token, x_status => l_x_status, x_error_code => l_x_error_code,
                            x_error_message => l_x_error_message);

        IF l_x_token IS NOT NULL THEN
            apex_web_service.g_request_headers(1).name := 'Authorization';
            apex_web_service.g_request_headers(1).value := 'Bearer ' || l_x_token;
            dbms_output.put_line('delete_message p_message_id: ' || p_message_id);
            l_clob := apex_web_service.make_rest_request(p_url => 'https://graph.microsoft.com/v1.0/users/'
                                                                  || p_from_email_address
                                                                  || '/messages/'
                                                                  || p_message_id,
                                                        p_http_method => 'DELETE');
       -- dbms_output.put_line ('l_clob: ' || l_clob);

            IF l_clob IS NULL THEN
                x_status := 'S';
               --x_error_code := NULL;
                x_error_message := NULL;
            ELSE
                apex_json.parse(l_clob);
                x_status := 'E';
        --x_error_code := substr(apex_json.get_varchar2('error.code'), 1, 999);
                x_error_message := substr(apex_json.get_varchar2('error.message'), 1, 3999);


        --dbms_output.put_line ('code: ' || apex_json.get_varchar2 ('error.code'));
        --dbms_output.put_line ('message: ' || apex_json.get_varchar2 ('error.message'));
            END IF;

        ELSE
            x_status := 'E';
            --x_error_code := substr(l_x_error_code, 1, 999);
            x_error_message := substr(l_x_error_message, 1, 3999);
        END IF;

    EXCEPTION
        WHEN OTHERS THEN
            x_status := 'E';
            --x_error_code := sqlcode;
            x_error_message := sqlerrm;
    END delete_message;

    PROCEDURE get_attachment_id (
        p_message_id     VARCHAR2,
        x_attachment_id  OUT  VARCHAR2,
        x_return_status  OUT  VARCHAR2,
        x_err_msg        OUT  VARCHAR2
    ) IS

        l_x_token                       VARCHAR2(4000);
        l_x_status                      VARCHAR2(200);
        l_x_error_code                  VARCHAR2(200);
        l_x_error_message               VARCHAR2(4000);
        l_list_messages_attach_respone  CLOB;
        l_message_id                    VARCHAR2(1000);
        l_attach_file_name              VARCHAR2(500);
        l_attachment_id                 VARCHAR2(500);
        l_recepients_email_id           VARCHAR2(500) := NULL;
        l_from_email_id                 VARCHAR2(500) := NULL;
    BEGIN
        c_apex_msft_o365_integration_pkg.generate_outh2_token(x_token => l_x_token, x_status => l_x_status,
                                                             x_error_code => l_x_error_code,
                                                             x_error_message => l_x_error_message);

        IF l_x_token IS NOT NULL THEN
            dbms_output.put_line('L_X_TOKEN : ' || l_x_token);
            apex_web_service.g_request_headers(1).name := 'Authorization';
            apex_web_service.g_request_headers(1).value := 'Bearer ' || l_x_token;
            l_recepients_email_id := g_recepients_email_id;
            --l_message_id := 'AAMkAGNmMmY3YzFkLTQ4OWEtNDA5Mi1iZTE1LThhMmZhMDI2ZjUyYQBGAAAAAABNoBtsiaLwSZ7og383RV0dBwARa7Xe-0siSrtY9MglGRDCAhM-5CqCAAAp_XBE6xyUR7C6mIkeH59nAAAnM9IQAAA=';

            l_message_id := p_message_id;
            l_list_messages_attach_respone := apex_web_service.make_rest_request(p_url => 'https://graph.microsoft.com/v1.0/users/'
                                                                                          || l_recepients_email_id
                                                                                          || '/messages/'
                                                                                          || l_message_id
                                                                                          || '/attachments?$select=Name',
                                                                                p_http_method => 'GET');

            dbms_output.put_line('l_list_messages_attach_respone : '
                                 || substr(l_list_messages_attach_respone, 1, 3000));
            apex_json.parse(l_list_messages_attach_respone);
            l_attach_file_name := apex_json.get_varchar2(p_path => 'value[%d].name', p0 => 1);
            x_attachment_id := apex_json.get_varchar2(p_path => 'value[%d].id', p0 => 1);
            IF x_attachment_id IS NOT NULL THEN
                UPDATE c_kace_user_o365_emails
                SET
                    report_name = l_attach_file_name
                WHERE
                    o365_message_id = l_message_id;

                COMMIT;
                x_return_status := 'S';
                x_err_msg := NULL;
            ELSE
                x_return_status := 'E';
                x_err_msg := substr(apex_json.get_varchar2('error_description'), 1, 3999);
            END IF;

        ELSE
            x_return_status := 'E';
            x_err_msg := l_x_error_message;
        END IF;

    EXCEPTION
        WHEN OTHERS THEN
            x_return_status := 'E';
            x_err_msg := sqlerrm;
    END get_attachment_id;

    PROCEDURE load_mail_attachments (
        p_message_id     VARCHAR2,
        p_attachment_id  VARCHAR2,
       -- p_email_address  VARCHAR2,
        x_status         OUT  VARCHAR2,
        x_error_message  OUT  VARCHAR2
    ) IS

        l_x_token                       VARCHAR2(4000);
        l_x_token_status                VARCHAR2(200);
        l_x_token_error_code            VARCHAR2(200);
        l_x_token_error_message         VARCHAR2(4000);
        l_list_messages_attach_respone  CLOB;
        l_attach_file_name              VARCHAR2(500);
        l_content_type                  VARCHAR2(240);
        l_from_email_id                 VARCHAR2(500) := NULL;
        l_url                           VARCHAR2(1000) := NULL;
        l_req                           utl_http.req;
        l_resp                          utl_http.resp;
        l_response_header_name          VARCHAR2(256);
        l_response_header_value         VARCHAR2(1024);
        l_content                       CLOB;
        l_buffer                        VARCHAR2(32766);
        l_x_status                      VARCHAR2(200);
        l_x_error_code                  VARCHAR2(200);
        l_x_error_message               VARCHAR2(4000);
        l_message_id                    VARCHAR2(2000);
        l_attachment_id                 VARCHAR2(1000);
    BEGIN
        generate_outh2_token(x_token => l_x_token, x_status => l_x_token_status, x_error_code => l_x_token_error_code,
                            x_error_message => l_x_token_error_message);

        x_status := 'S';
        x_error_message := NULL;
        IF l_x_token IS NOT NULL THEN
            l_from_email_id := g_recepients_email_id;
            l_message_id := p_message_id;
            l_attachment_id := p_attachment_id;
            l_url := 'https://graph.microsoft.com/v1.0/users/'
                     || l_from_email_id
                     || '/messages/'
                     || l_message_id
                     || '/attachments/'
                     || l_attachment_id
                     || '/$value';

            dbms_lob.createtemporary(l_content, true, dbms_lob.call);
            dbms_lob.open(l_content, dbms_lob.lob_readwrite);
            c_apex_msft_o365_integration_pkg.generate_outh2_token(x_token => l_x_token,
                                                                 x_status => l_x_status,
                                                                 x_error_code => l_x_error_code,
                                                                 x_error_message => l_x_error_message);

            dbms_output.put_line('L_X_TOKEN : ' || l_x_token);
            l_req := utl_http.begin_request(l_url, method => 'GET', http_version => 'HTTP/1.1');

            utl_http.set_header(l_req, 'Authorization', 'Bearer ' || l_x_token);
            utl_http.set_header(l_req, 'Content-Transfer-Encoding', 'chunked');
            utl_http.set_header(l_req, name => 'User-Agent', value => 'Mozilla/4.0');
            utl_http.set_header(l_req, 'content-type', 'text/csv');
            l_resp := utl_http.get_response(l_req);
            dbms_output.put_line('RESPONSE CODE IS ' || l_resp.status_code);
            dbms_output.put_line('Reason phrase: ' || l_resp.reason_phrase);
          /*  FOR i IN 1..utl_http.get_header_count(l_resp) LOOP
                utl_http.get_header(l_resp, i, l_response_header_name, l_response_header_value);
                dbms_output.put_line('Response Header> '
                                     || l_response_header_name
                                     || ': '
                                     || l_response_header_value);
            END LOOP; */

            IF l_resp.status_code = '200' THEN
                BEGIN
                    LOOP
                        utl_http.read_text(l_resp, l_buffer, 32766);
                        dbms_lob.writeappend(l_content, length(l_buffer), l_buffer);
                    END LOOP;
                EXCEPTION
                    WHEN utl_http.end_of_body THEN
                        utl_http.end_response(l_resp);
                END;

                --INSERT INTO c_kace_users_file_stg ( file_content ) VALUES ( l_content );
                UPDATE c_kace_user_o365_emails
                SET
                    users_raw_data = l_content
                WHERE
                    o365_message_id = l_message_id;

                COMMIT;
            END IF;

        ELSE
            x_status := l_x_token_status;
            x_error_message := l_x_token_error_message;
        END IF;

    EXCEPTION
        WHEN utl_http.request_failed THEN
            dbms_output.put_line('Request_Failed: ' || utl_http.get_detailed_sqlerrm);
            x_status := 'E';
            x_error_message := utl_http.get_detailed_sqlerrm;
            utl_http.end_request(r => l_req);
        WHEN OTHERS THEN
            x_status := 'E';
            x_error_message := sqlerrm;
            --raise_application_error(-20002, 'Exception in get_mail_attachments ' || sqlerrm);
            utl_http.end_request(r => l_req);
    END load_mail_attachments;

    PROCEDURE load_o365_emails (
        x_status         OUT  VARCHAR2,
        x_error_message  OUT  VARCHAR2
    ) IS

        l_x_token                VARCHAR2(4000);
        l_x_status               VARCHAR2(200);
        l_x_error_code           VARCHAR2(200);
        l_x_error_message        VARCHAR2(4000);
        l_list_messages_respone  CLOB;
        l_message_id             VARCHAR2(500);
        l_subject                VARCHAR2(500);
        l_recepients_email_id    VARCHAR2(500) := NULL;
        l_from_email_id          VARCHAR2(500) := NULL;
        x_areturn_status         VARCHAR2(4000) := NULL;
        x_aerr_msg               VARCHAR2(4000) := NULL;
        x_la_status              VARCHAR2(4000) := NULL;
        x_la_error_message       VARCHAR2(4000) := NULL;
        x_attachment_id          VARCHAR2(4000) := NULL;
        x_del_status             VARCHAR2(4000) := NULL;
        x_del_error_message      VARCHAR2(4000) := NULL;
        TYPE t_message IS RECORD (
            message_id VARCHAR2(1000)
        );
        TYPE t_messages IS
            TABLE OF t_message INDEX BY PLS_INTEGER;
        l_messages               t_messages;
        counter                  NUMBER := 0;
        l_message_count          NUMBER := 0;
        x_load_csv_data_status   VARCHAR2(200) := NULL;
    BEGIN
        initialize_kace_env_details;
        x_status := 'S';
        x_error_message := NULL;
        c_apex_msft_o365_integration_pkg.generate_outh2_token(x_token => l_x_token,
                                                             x_status => l_x_status,
                                                             x_error_code => l_x_error_code,
                                                             x_error_message => l_x_error_message);

        IF l_x_token IS NOT NULL THEN
            apex_web_service.g_request_headers(1).name := 'Authorization';
            apex_web_service.g_request_headers(1).value := 'Bearer ' || l_x_token;

        --dbms_output.put_line ('L_X_TOKEN: ' || L_X_TOKEN);

            l_from_email_id := g_kace_report_email_id;
            l_recepients_email_id := g_recepients_email_id;
            --dbms_output.put_line('l_recepients_email_id: ' || l_recepients_email_id);
            l_list_messages_respone := apex_web_service.make_rest_request(p_url => 'https://graph.microsoft.com/v1.0/users/'
                                                                                   || l_recepients_email_id
                                                                                   || '/messages?$select=subject,hasAttachments'
                                                                                   || CHR(38)
                                                                                   || 'filter=from/emailAddress/address+eq+'
                                                                                   || ''''
                                                                                   || l_from_email_id
                                                                                   || '''',
                                                                         p_http_method => 'GET');

           --dbms_output.put_line('l_list_messages_respone : ' || l_list_messages_respone);
            dbms_output.put_line(' status ' || apex_web_service.g_status_code);
            IF apex_web_service.g_status_code = '200' THEN
                apex_json.parse(l_list_messages_respone);

              --parsing json list message response
                counter := 0;
                l_message_count := 0;
                FOR i IN 1..apex_json.get_count(p_path => 'value') LOOP
                    l_message_id := NULL;
                    l_message_id := apex_json.get_varchar2(p_path => 'value[%d].id', p0 => i);
                    l_subject := apex_json.get_varchar2(p_path => 'value[%d].subject', p0 => i);
                    dbms_output.put_line('New l_message_id : ' || l_message_id);
                    dbms_output.put_line('New l_subject : ' || l_subject);
                    IF l_subject = 'New KACE List of users' THEN
                        counter := counter + 1;
                        dbms_output.put_line('Inside tabletype : ' || l_message_id);
                        l_messages(counter).message_id := l_message_id;
                        SELECT
                            COUNT(o365_message_id)
                        INTO l_message_count
                        FROM
                            c_kace_user_o365_emails
                        WHERE
                            o365_message_id = l_message_id;

                        IF l_message_count = 0 THEN
                            INSERT INTO c_kace_user_o365_emails (
                                rpt_id,
                                o365_message_id,
                                status,
                                creation_date
                            ) VALUES (
                                c_kace_user_o365_emails_sq.NEXTVAL,
                                l_message_id,
                                'N',
                                sysdate
                            );

                        END IF;

                    END IF;

                END LOOP;

                COMMIT;
                --dbms_output.put_line('Before Loop ' || l_messages.count);

                FOR i IN 1..l_messages.count LOOP
                  --  dbms_output.put_line('Loop ('
                  --                       || i
                   --                      || l_messages(i).message_id);
                    x_status := 'S';
                    x_error_message := NULL;
                    get_attachment_id(l_messages(i).message_id, x_attachment_id, x_areturn_status,
                                     x_aerr_msg);
                    x_status := x_areturn_status;
                    x_error_message := x_aerr_msg;
                    dbms_output.put_line('get_attachment_id  x_status ' || x_areturn_status);
                    IF x_attachment_id IS NOT NULL THEN
                        load_mail_attachments(l_messages(i).message_id, x_attachment_id, x_la_status,
                                             x_la_error_message);
                        IF x_la_status = 'S' THEN
                            delete_message(l_messages(i).message_id,
                                          l_recepients_email_id,
                                          x_del_status,
                                          x_del_error_message);
                        END IF;

                        dbms_output.put_line('load_mail_attachments  x_status ' || x_la_status);
                        dbms_output.put_line('delete_message  x_del_status ' || x_del_status);
                        dbms_output.put_line('delete_message  x_del_error_message ' || x_del_error_message);
                        x_status := x_la_status;
                        x_error_message := x_la_error_message;
                            --dbms_output.put_line('l_subject ' || l_subject);
                    END IF;

                    UPDATE c_kace_user_o365_emails
                    SET
                        error_message = x_error_message,
                        status = x_status
                    WHERE
                        o365_message_id = l_messages(i).message_id;

                    COMMIT;
                    dbms_output.put_line('end of iteration l_message_id : ' || l_messages(i).message_id);
                    dbms_output.put_line('+++++++++++++++++++++++++++++++++++++++++++++++++');
                END LOOP;

                x_load_csv_data_status := 'S';
                load_csv_data(x_load_csv_data_status);
                x_status := x_load_csv_data_status;
            END IF;

        ELSE
            x_status := l_x_status;
            x_error_message := l_x_error_message;
        END IF;

    EXCEPTION
        WHEN OTHERS THEN
            x_status := 'E';
            x_error_message := sqlerrm;
           -- raise_application_error(-20001, 'Exception in load_o365_emails ' || sqlerrm);
    END load_o365_emails;

    PROCEDURE load_csv_data (
        x_status OUT VARCHAR2
    ) IS

        CURSOR c_get_users IS
        SELECT DISTINCT
            csv.c001    id,
            csv.c002    user_name,
            csv.c003    full_name
        FROM
            c_kace_user_o365_emails                                                        d,
            TABLE ( c_kace_itop_intr_pkg.clob_to_csv(d.users_raw_data, ',', 2) )           csv
        WHERE
            d.report_name IS NOT NULL
            AND line_raw IS NOT NULL
            AND status = 'S'
            AND NOT EXISTS (
                SELECT
                    1
                FROM
                    c_kace_users
                WHERE
                    kace_user_id = csv.c001
            )
        ORDER BY
            c001 ASC;

    BEGIN
        FOR rec_get_users IN c_get_users LOOP
            BEGIN
                INSERT INTO c_kace_users (
                    kace_user_id,
                    user_name,
                    full_name,
                    g_users_user_id
                ) VALUES (
                    rec_get_users.id,
                    rec_get_users.user_name,
                    rec_get_users.full_name,
                    (
                        SELECT
                            user_id
                        FROM
                            g_users
                        WHERE
                                name = rec_get_users.user_name
                            AND ROWNUM = 1
                    )
                );

            EXCEPTION
                WHEN OTHERS THEN
                    dbms_output.put_line('KACE User Id '
                                         || rec_get_users.id
                                         || sqlerrm);
            END;
        END LOOP;

        UPDATE c_kace_users ku
        SET
            g_users_user_id = (
                SELECT
                    user_id
                FROM
                    g_users
                WHERE
                        name = ku.user_name
                    AND ROWNUM = 1
            )
        WHERE
            g_users_user_id IS NULL;

        COMMIT;
        x_status := 'S';
    EXCEPTION
        WHEN OTHERS THEN
            dbms_output.put_line('load_csv_data Exception When Others :' || sqlerrm);
    END load_csv_data;

    PROCEDURE read_emails (
        x_status         OUT  VARCHAR2,
        x_error_message  OUT  VARCHAR2
    ) IS

        l_x_token                VARCHAR2(4000);
        l_x_status               VARCHAR2(200);
        l_x_error_code           VARCHAR2(200);
        l_x_error_message        VARCHAR2(4000);
        l_list_messages_respone  CLOB;
        l_message_id             VARCHAR2(500);
        l_subject                VARCHAR2(500);
        l_recepients_email_id    VARCHAR2(500) := NULL;
        l_from_email_id          VARCHAR2(500) := NULL;
        l_isread                 VARCHAR2(500) := NULL;
        l_sentdatetime           VARCHAR2(500) := NULL;
        CURSOR c_read_emails IS
        SELECT
            cer.recipients_email,
            cer.recipient_date,
            cer.send_email_subject,
            cec.from_addr,
            cer.recipient_id
        FROM
            c_epcp_responses  cer,
            c_epcp_campaigns  cec
        WHERE
                cer.recipients_email_open = 1
            AND cer.send_email_subject IS NOT NULL
            AND cer.campaign_id = cec.campaign_id
            AND trunc(cec.end_date) > trunc(sysdate);

    BEGIN
        x_status := 'S';
        x_error_message := NULL;
        c_apex_msft_o365_integration_pkg.generate_outh2_token(x_token => l_x_token,
                                                             x_status => l_x_status,
                                                             x_error_code => l_x_error_code,
                                                             x_error_message => l_x_error_message);

        dbms_output.put_line('L_X_TOKEN: ' || l_x_token);
        IF l_x_token IS NOT NULL THEN
            apex_web_service.g_request_headers(1).name := 'Authorization';
            apex_web_service.g_request_headers(1).value := 'Bearer ' || l_x_token;

        --dbms_output.put_line ('L_X_TOKEN: ' || L_X_TOKEN);

            FOR rec_read_emails IN c_read_emails LOOP
                l_from_email_id := NULL;
                l_recepients_email_id := NULL;
                l_from_email_id := rec_read_emails.from_addr;
                l_recepients_email_id := rec_read_emails.recipients_email;
                l_list_messages_respone := apex_web_service.make_rest_request(p_url => 'https://graph.microsoft.com/v1.0/users/'
                                                                                       || l_recepients_email_id
                                                                                       || '/messages?$select=subject,isRead,sentDateTime'
                                                                                       || CHR(38)
                                                                                       || 'filter=from/emailAddress/address+eq+'
                                                                                       || ''''
                                                                                       || l_from_email_id
                                                                                       || '''',
                                                                             p_http_method => 'GET');

                dbms_output.put_line('l_list_messages_respone : ' || l_list_messages_respone);
                dbms_output.put_line(' status ' || apex_web_service.g_status_code);
                IF apex_web_service.g_status_code = '200' THEN
                    apex_json.parse(l_list_messages_respone);
                    FOR i IN 1..apex_json.get_count(p_path => 'value') LOOP
                        l_message_id := NULL;
                        l_subject := NULL;
                        l_isread := NULL;
                        l_sentdatetime := NULL;
                        l_message_id := apex_json.get_varchar2(p_path => 'value[%d].id', p0 => i);
                        l_subject := apex_json.get_varchar2(p_path => 'value[%d].subject', p0 => i);
                        l_isread := apex_json.get_varchar2(p_path => 'value[%d].isRead', p0 => i);
                        l_sentdatetime := apex_json.get_varchar2(p_path => 'value[%d].sentDateTime', p0 => i);
                        dbms_output.put_line('New l_message_id : ' || l_message_id);
                        dbms_output.put_line('New l_subject : ' || l_subject);
                        IF
                            l_subject = rec_read_emails.send_email_subject
                            AND upper(l_isread) = 'TRUE'
                        THEN
                            UPDATE c_epcp_responses
                            SET
                                recipients_email_open = 0,
                                msft_message_id = l_message_id
                            WHERE
                                    send_email_subject = l_subject
                                AND upper(recipients_email) = upper(l_recepients_email_id)
                                AND trunc(recipient_date) = to_date(substr(l_sentdatetime, 1, 10), 'YYYY-MM-DD');

                            dbms_output.put_line('User Read the mail Subject  : ' || l_subject);
                        END IF;

                    END LOOP;

                END IF;

            END LOOP;

        ELSE
            x_status := 'E';
            x_error_message := l_x_error_message;
        END IF;

    EXCEPTION
        WHEN OTHERS THEN
            x_status := 'E';
            x_error_message := sqlerrm;
           -- raise_application_error(-20001, 'Exception in load_o365_emails ' || sqlerrm);
    END read_emails;

    PROCEDURE list_tenant_user_activities (
        x_status         OUT  VARCHAR2,
        x_error_message  OUT  VARCHAR2
    ) IS

        l_x_token              VARCHAR2(10000);
        l_x_status             VARCHAR2(200);
        l_x_error_code         VARCHAR2(200);
        l_x_error_message      VARCHAR2(4000);
        l_clob                 CLOB;
        l_user_exists          NUMBER;
        l_user_principle_name  VARCHAR2(500) := NULL;
       /* CURSOR c_get_emails IS
        SELECT
            address email
        FROM
            c_emails
        WHERE
                upper(type) = 'WORK'
            AND upper(address) = nvl(upper(p_user_email), upper(address))
            AND status = 1; */

    BEGIN
        generate_outh2_token(x_token => l_x_token, x_status => l_x_status, x_error_code => l_x_error_code,
                            x_error_message => l_x_error_message);

        IF l_x_token IS NOT NULL THEN
           -- FOR rec_get_emails IN c_get_emails LOOP
            apex_web_service.g_request_headers(1).name := 'Authorization';
            apex_web_service.g_request_headers(1).value := 'Bearer ' || l_x_token;
            dbms_output.put_line('L_X_TOKEN: ' || l_x_token);
           /*l_clob := apex_web_service.make_rest_request(p_url => 'https://graph.microsoft.com/v1.0/users/'
                                                                  || p_user_email --|| rec_get_emails.email
                                                                  || '?$select=displayName,givenName,jobTitle,mail,mobilePhone,businessPhones,officeLocation,userPrincipalName,id,surname,hireDate,department,userType,accountEnabled'
                                                                  || CHR(38)
                                                                  || '$expand=manager($levels=max;$select=displayName,department,jobTitle,mail,mobilePhone,businessPhones)'
                                                                  || CHR(38)
                                                                  || '$count=true',
                                                        p_http_method => 'GET'); */

            l_clob := apex_web_service.make_rest_request(p_url => 'https://graph.microsoft.com/v1.0/' || 'auditLogs/directoryAudits',
                                                        p_http_method => 'GET');                                            

         --apex_json.parse(l_clob);
                --dbms_output.put_line('Start Processing for rec_get_emails.email: ' || rec_get_emails.email);
            IF l_clob IS NOT NULL THEN
                apex_json.parse(l_clob);
                INSERT INTO test_json ( test_json ) VALUES ( l_clob );
               -- dbms_output.put_line('l_clob: '
                 --                    || substr(l_clob, 1, 37000));
                IF apex_json.get_varchar2('error.message') IS NULL THEN
                    x_status := 'S';
                    x_error_message := NULL;
                ELSE
                    x_status := 'E';
                    x_error_message := substr(apex_json.get_varchar2('error.message'), 1, 3999);
                    dbms_output.put_line('message: ' || apex_json.get_varchar2('error.message'));
                END IF;

            ELSE
                apex_json.parse(l_clob);
                INSERT INTO test_json ( test_json ) VALUES ( l_clob );
               -- dbms_output.put_line('l_clob: '
                 --                    || substr(l_clob, 1, 37000));
                x_status := 'E';
                x_error_message := substr(apex_json.get_varchar2('error.message'), 1, 3999);
               -- dbms_output.put_line('message: ' || apex_json.get_varchar2('error.message'));
            END IF;

            COMMIT;
           -- END LOOP;

        ELSE
            x_status := 'E';
            x_error_message := substr(l_x_error_message, 1, 3999);
        END IF;

    EXCEPTION
        WHEN OTHERS THEN
            x_status := 'E';
            x_error_message := sqlerrm;
    END list_tenant_user_activities;

    PROCEDURE list_tenant_user_signins (
        x_status         OUT  VARCHAR2,
        x_error_message  OUT  VARCHAR2
    ) IS

        l_x_token              VARCHAR2(10000);
        l_x_status             VARCHAR2(200);
        l_x_error_code         VARCHAR2(200);
        l_x_error_message      VARCHAR2(4000);
        l_clob                 CLOB;
        l_user_exists          NUMBER;
        l_user_principle_name  VARCHAR2(500) := NULL;
       /* CURSOR c_get_emails IS
        SELECT
            address email
        FROM
            c_emails
        WHERE
                upper(type) = 'WORK'
            AND upper(address) = nvl(upper(p_user_email), upper(address))
            AND status = 1; */

    BEGIN
        generate_outh2_token(x_token => l_x_token, x_status => l_x_status, x_error_code => l_x_error_code,
                            x_error_message => l_x_error_message);

        IF l_x_token IS NOT NULL THEN
           -- FOR rec_get_emails IN c_get_emails LOOP
            apex_web_service.g_request_headers(1).name := 'Authorization';
            apex_web_service.g_request_headers(1).value := 'Bearer ' || l_x_token;
            dbms_output.put_line('L_X_TOKEN: ' || l_x_token);
           /*l_clob := apex_web_service.make_rest_request(p_url => 'https://graph.microsoft.com/v1.0/users/'
                                                                  || p_user_email --|| rec_get_emails.email
                                                                  || '?$select=displayName,givenName,jobTitle,mail,mobilePhone,businessPhones,officeLocation,userPrincipalName,id,surname,hireDate,department,userType,accountEnabled'
                                                                  || CHR(38)
                                                                  || '$expand=manager($levels=max;$select=displayName,department,jobTitle,mail,mobilePhone,businessPhones)'
                                                                  || CHR(38)
                                                                  || '$count=true',
                                                        p_http_method => 'GET'); */

            l_clob := apex_web_service.make_rest_request(p_url => 'https://graph.microsoft.com/v1.0/' || 'auditLogs/signIns',
                                                        p_http_method => 'GET');                                            

         --apex_json.parse(l_clob);
                --dbms_output.put_line('Start Processing for rec_get_emails.email: ' || rec_get_emails.email);
            IF l_clob IS NOT NULL THEN
                apex_json.parse(l_clob);
                INSERT INTO test_json ( test_json ) VALUES ( l_clob );
               -- dbms_output.put_line('l_clob: '
                 --                    || substr(l_clob, 1, 37000));
                IF apex_json.get_varchar2('error.message') IS NULL THEN
                    x_status := 'S';
                    x_error_message := NULL;
                ELSE
                    x_status := 'E';
                    x_error_message := substr(apex_json.get_varchar2('error.message'), 1, 3999);
                    dbms_output.put_line('message: ' || apex_json.get_varchar2('error.message'));
                END IF;

            ELSE
                apex_json.parse(l_clob);
                INSERT INTO test_json ( test_json ) VALUES ( l_clob );
               -- dbms_output.put_line('l_clob: '
                 --                    || substr(l_clob, 1, 37000));
                x_status := 'E';
                x_error_message := substr(apex_json.get_varchar2('error.message'), 1, 3999);
               -- dbms_output.put_line('message: ' || apex_json.get_varchar2('error.message'));
            END IF;

            COMMIT;
           -- END LOOP;

        ELSE
            x_status := 'E';
            x_error_message := substr(l_x_error_message, 1, 3999);
        END IF;

    EXCEPTION
        WHEN OTHERS THEN
            x_status := 'E';
            x_error_message := sqlerrm;
    END list_tenant_user_signins;

    PROCEDURE create_teams_with_channels (
        p_team_name         IN   VARCHAR2,
        p_team_description  IN   VARCHAR2,
        p_team_owner_email  IN   VARCHAR2,
        x_status            OUT  VARCHAR2,
        x_error_message     OUT  VARCHAR2,
        x_team_id           OUT  VARCHAR2
    ) IS

        lc_teams_body             CLOB;
        lc_create_teams_response  CLOB;
        l_x_token                 VARCHAR2(4000);
        l_x_status                VARCHAR2(200);
        l_x_error_code            VARCHAR2(1000);
        l_x_error_message         VARCHAR2(4000);
        l_msft_user_id            VARCHAR2(2000);
        l_vcheadername            VARCHAR2(32000) := NULL;
        l_vcheadervalue           VARCHAR2(32000) := NULL;
    BEGIN
        x_status := 'S';
        x_error_message := NULL;
        BEGIN
            SELECT
                msft_user_id
            INTO l_msft_user_id
            FROM
                c_msft_o365_users
            WHERE
                upper(user_principal_name) = upper(p_team_owner_email);

        EXCEPTION
            WHEN OTHERS THEN
                c_apex_msft_o365_integration_pkg.get_user_details(p_user_email => p_team_owner_email,
                                                                 x_status => x_status,
                                                                 x_error_message => x_error_message,
                                                                 x_msft_user_id => l_msft_user_id);
        END;

        IF x_status = 'S' THEN
            generate_outh2_token(x_token => l_x_token, x_status => l_x_status, x_error_code => l_x_error_code,
                                x_error_message => l_x_error_message);
                            
                            

        
       -- "visibility": "Public",
            IF l_x_token IS NOT NULL THEN
                dbms_output.put_line('L_X_TOKEN ' || l_x_token);
                lc_teams_body := '
                {
                   "template@odata.bind":"https://graph.microsoft.com/v1.0/teamsTemplates(''standard'')", 
                    
                    "displayName": '
                                 || '"'
                                 || p_team_name
                                 || '"'
                                 || ',
                    "description":  '
                                 || '"'
                                 || p_team_description
                                 || '"'
                                 || ',
                    "members":[
                      {
                         "@odata.type":"#microsoft.graph.aadUserConversationMember",
                         "roles":[
                            "owner"
                         ],
                          
                          "user@odata.bind":"https://graph.microsoft.com/v1.0/users('
                                 || ''''
                                 || l_msft_user_id
                                 || ''''
                                 || ')"
                          
    
                      }
                      ],
                    "channels": [
                        {
                            "displayName": "Announcements 📢",
                            "isFavoriteByDefault": true,
                            "description": "This is a sample announcements channel that is favorited by default. Use this channel to make important team, product, and service announcements."
                        },
                        {
                            "displayName": "Training 🏋️",
                            "isFavoriteByDefault": true,
                            "description": "This is a sample training channel, that is favorited by default, and contains an example of pinned website and YouTube tabs.",
                            "tabs": [
                                {
                                    "teamsApp@odata.bind": "https://graph.microsoft.com/v1.0/appCatalogs/teamsApps(''com.microsoft.teamspace.tab.web'')",
                                    "displayName": "A Pinned Website",
                                    "configuration": {
                                        "contentUrl": "https://docs.microsoft.com/microsoftteams/microsoft-teams"
                                    }
                                },
                                {
                                    "teamsApp@odata.bind": "https://graph.microsoft.com/v1.0/appCatalogs/teamsApps(''com.microsoft.teamspace.tab.youtube'')",
                                    "displayName": "A Pinned YouTube Video",
                                    "configuration": {
                                        "contentUrl": "https://tabs.teams.microsoft.com/Youtube/Home/YoutubeTab?videoId=X8krAMdGvCQ",
                                        "websiteUrl": "https://www.youtube.com/watch?v=X8krAMdGvCQ"
                                    }
                                }
                            ]
                        },
                        {
                            "displayName": "Planning",
                            "description": "This is a sample of a channel that is not favorited by default, these channels will appear in the more channels overflow menu.",
                           false
                        },
                        {
                            "displayName": "Issues and Feedback",
                            "deson": "Thismppear in the more channels over               }
                    ],
              tings": {
                        "allowCreateUpdateChannels": true,
                        "allowDeleteChannels": true,
                        "allowAddRemoveApps": true,
                        "allowCreateUpdateRemoveTabs": true,
                        "allowCreateUpdateRemoveConnectors": true
                    }             "allowCreateUpdateChannels": false,
                        "allowDeleteChannels": false
                    },
                    "funSettings": {
                        "allowGiphy": true,
                        "giphyContentRating": "Moderate",
                        "allowStickersAndMemes":
                        "allowCustomMemes": true
                    },
                    "messagingSettings": {
                        "allowUserEditMessages": true,
                        "allowUserDeleteMessages": true,
                        "allowOwnerDeleteMessages": true,
                        "allowTeamMentions": true,
                        "allowChannelMentions": true
                    },
                    "discoverySettings": {
                        "showInTeamsSearchAndSuggestions": true
                    }
                }
        ';

                apex_web_service.g_request_headers(1).name := 'Content-Type';
                apex_web_service.g_request_headers(1).value := 'application/json';
                apex_web_service.g_request_headers(2).name := 'Authorization';
                apex_web_service.g_request_headers(2).value := 'Bearer ' || l_x_token;
                lc_create_teams_response := apex_web_service.make_rest_request(p_url => 'https://graph.microsoft.com/v1.0/teams',
                                                                              p_http_method => 'POST',
                                                                              p_body => lc_teams_body);

           
            --apex_json.parse(lc_create_teams_response);
             --dbms_output.put_line('lc_create_teams_response = '
               --              || substr(lc_create_teams_response, 1, 3000));

                dbms_output.put_line(' status ' || apex_web_service.g_status_code);
                IF apex_web_service.g_status_code = 202 THEN
                    FOR i IN 1..apex_web_service.g_headers.count LOOP
                        l_vcheadername := apex_web_service.g_headers(i).name;
                        l_vcheadervalue := apex_web_service.g_headers(i).value;
                        EXIT WHEN l_vcheadername = 'Content-Location';
                    END LOOP;

                    dbms_output.put_line('Name: ' || l_vcheadername);
                    dbms_output.put_line('Value: ' || l_vcheadervalue);
                    x_team_id := l_vcheadervalue; 

                   /* BEGIN
                        SELECT
                            substr(l_vcheadervalue, 8
                        INTO x_team_id
                        FROM
                            dual;

                    END;*/
                    INSERT INTO test_json (
                        test_json,
                        source,
                        json_id
                    ) VALUES (
                        lc_create_teams_response,
                        'O365_TEAMS_WITH_CANNEL',
                        test_json_seq.NEXTVAL
                    );

                    COMMIT;
            --IF lc_create_teams_response IS NULL THEN
                    x_status := 'S';
                --x_error_code := NULL;
                    x_error_message := NULL;
            -- END IF;


                ELSE
                    x_status := 'E';
              --  x_error_code := substr(apex_json.get_varchar2('error.code'), 1, 999);
                    x_error_message := substr(apex_json.get_varchar2('error.message'), 1, 3999);
                END IF;

            ELSE
                x_status := 'E';
            --x_error_code := substr(l_x_error_code, 1, 999);
                x_error_message := substr(l_x_error_message, 1, 999);
            END IF;

        END IF;

    EXCEPTION
        WHEN OTHERS THEN
            x_status := 'E';
           -- x_error_code := sqlcode;
            x_error_message := sqlerrm;
    END create_teams_with_channels;


    PROCEDURE get_teams_channel_filesfolder_id (
        p_team_id        VARCHAR2,
        p_channel_id     VARCHAR2,
        x_status         OUT  VARCHAR2,
        x_error_message  OUT  VARCHAR2,
        x_drive_id       OUT  VARCHAR2,
        x_drive_item_id  OUT  VARCHAR2
    ) IS

        l_x_token              VARCHAR2(10000);
        l_x_status             VARCHAR2(2000);
        l_x_error_code         VARCHAR2(2000);
        l_x_error_message      VARCHAR2(4000);
        l_clob                 CLOB;
        l_user_principle_name  VARCHAR2(500) := NULL;
        l_drive_id             VARCHAR2(4000) := NULL;
        l_drive_item_id        VARCHAR2(4000) := NULL;
       /* CURSOR c_get_users IS
        SELECT
            user_principal_name user_email
        FROM
            c_msft_o365_users
        WHERE
            user_principal_name = nvl(p_user_email, user_principal_name); */

    BEGIN
        generate_outh2_token(x_token => l_x_token, x_status => l_x_status, x_error_code => l_x_error_code,
                            x_error_message => l_x_error_message);

        /*IF p_user_email IS NULL THEN
            EXECUTE IMMEDIATE 'TRUNCATE TABLE c_msft_onedrive_items';
        ELSE
            DELETE FROM c_msft_onedrive_items
            WHERE
                user_principal_name = p_user_email;

        END IF;*/

        IF l_x_token IS NOT NULL THEN
            --FOR rec_get_users IN c_get_users LOOP
            apex_web_service.g_request_headers(1).name := 'Authorization';
            apex_web_service.g_request_headers(1).value := 'Bearer ' || l_x_token;
            dbms_output.put_line('L_X_TOKEN: ' || l_x_token);
            l_clob := apex_web_service.make_rest_request(p_url => 'https://graph.microsoft.com/v1.0/teams/'
                                                                  || p_team_id
                                                                  || '/channels/'
                                                                  || p_channel_id
                                                                  || '/filesFolder',
                                                        p_http_method => 'GET');

            dbms_output.put_line(' status ' || apex_web_service.g_status_code);
            IF l_clob IS NOT NULL THEN
                apex_json.parse(l_clob);
                dbms_output.put_line(' File folder Id Return  '
                                     || substr(l_clob, 1, 32000));
                INSERT INTO test_json (
                    test_json,
                    source,
                    json_id
                ) VALUES (
                    l_clob,
                    'O365_get_teams_channel_filesfolder_id',
                    test_json_seq.NEXTVAL
                );

                COMMIT;
               -- l_user_principle_name := apex_json.get_varchar2(p_path => 'userPrincipalName');



                dbms_output.put_line('l_user_exists API call:');
                l_drive_id := apex_json.get_varchar2(p_path => 'parentReference.driveId');
                l_drive_item_id := apex_json.get_varchar2(p_path => 'id');
                x_drive_item_id := l_drive_item_id;
                x_drive_id := l_drive_id;
                   /* FOR i IN 1..apex_json.get_count(p_path => '.') LOOP
                    --l_user_team_exists := 0;
                    
                    dbms_output.put_line('inside  loop API call: ' || apex_json.get_varchar2(p_path => 'value[%d].parentReference.driveId', p0 => i));
                    
                    
                     
                    

                      /*  INSERT INTO c_msft_onedrive_items (
                            gtt_item_id,
                            user_principal_name,
                            msft_drive_item_id,
                            item_name,
                            web_url,
                            item_created_by_email,
                            item_created_by_user,
                            item_last_upd_by_email,
                            item_last_upd_by_usr,
                            file_mime_type,
                            filesys_crt_dt,
                            filesys_last_modify_dt,
                            parent_driveid,
                            parent_drivetype,
                            shared_scope,
                            shared_datetime,
                            sharedby_user_email,
                            sharedby_user_name,
                            folder_child_count,
                            created_by,
                            creation_date,
                            last_update_date,
                            last_updated_by
                        ) VALUES (
                            c_msft_onedrive_items_sq.NEXTVAL, --GTT_ITEM_ID, 
                            rec_get_users.user_email, --	 USER_PRINCIPAL_NAME   , 
                            apex_json.get_varchar2(p_path => 'value[%d].id', p0 => i),  --MSFT_DRIVE_ITEM_ID  , 

                            apex_json.get_varchar2(p_path => 'value[%d].name', p0 => i),  --ITEM_NAME   , 
                            apex_json.get_varchar2(p_path => 'value[%d].webUrl', p0 => i),  --web_url,
                            apex_json.get_varchar2(p_path => 'value[%d].createdBy.user.email', p0 => i),  --ITEM_CREATED_BY_EMAIL   , 
                            apex_json.get_varchar2(p_path => 'value[%d].createdBy.user.displayName', p0 => i),  --ITEM_CREATED_BY_USER   ,
                            apex_json.get_varchar2(p_path => 'value[%d].lastModifiedBy.user.email', p0 => i),  --ITEM_LAST_UPD_BY_EMAIL   , 
                            apex_json.get_varchar2(p_path => 'value[%d].lastModifiedBy.user.displayName', p0 => i),  --ITEM_LAST_UPD_BY_USR   ,
                            apex_json.get_varchar2(p_path => 'value[%d].file.mimeType', p0 => i),  --file_mime_type  ,
                            apex_json.get_varchar2(p_path => 'value[%d].fileSystemInfo.createdDateTime', p0 => i),  --filesys_crt_dt  ,
                            apex_json.get_varchar2(p_path => 'value[%d].fileSystemInfo.lastModifiedDateTime', p0 => i),  --FILESYS_LAST_MODIFY_DT  ,
                            apex_json.get_varchar2(p_path => 'value[%d].remoteItem.parentReference.driveId', p0 => i), --parent_driveid  ,
                            apex_json.get_varchar2(p_path => 'value[%d].remoteItem.parentReference.driveType', p0 => i), --parent_drivetype  ,
                            apex_json.get_varchar2(p_path => 'value[%d].remoteItem.shared.scope', p0 => i), --shared_scope  ,
                            apex_json.get_varchar2(p_path => 'value[%d].remoteItem.shared.sharedDateTime', p0 => i), --shared_datetime  ,
                            apex_json.get_varchar2(p_path => 'value[%d].remoteItem.shared.sharedBy.user.email', p0 => i), --sharedBy_user_email  ,
                            apex_json.get_varchar2(p_path => 'value[%d].remoteItem.shared.sharedBy.user.displayName', p0 => i), --sharedBy_user_name  ,
                            apex_json.get_varchar2(p_path => 'value[%d].remoteItem.folder.childCount', p0 => i), --folder_child_count,
                            v('USER_ID'),  --CREATED_BY, 
                            sysdate,  --CREATION_DATE, 
                            sysdate, --LAST_UPDATE_DATE, 
                            v('USER_ID')--LAST_UPDATED_BY
                        ); 

                    END LOOP; */



                IF apex_json.get_varchar2('error.message') IS NULL THEN
                    x_status := 'S';
                    x_error_message := NULL;
                ELSE
                    x_status := 'E';
                    x_error_message := substr(apex_json.get_varchar2('error.message'), 1, 3999);
                    dbms_output.put_line('message: ' || apex_json.get_varchar2('error.message'));
                END IF;

            ELSE
                apex_json.parse(l_clob);
            --INSERT INTO test_json(test_json) values(l_clob);
                   -- dbms_output.put_line('l_clob: '
                     --                    || substr(l_clob, 1, 37000));
                x_status := 'E';
                x_error_message := substr(apex_json.get_varchar2('error.message'), 1, 3999);
                dbms_output.put_line('message: ' || apex_json.get_varchar2('error.message'));
            END IF;

            COMMIT;
           -- END LOOP;
        ELSE
            x_status := 'E';
            x_error_message := substr(l_x_error_message, 1, 3999);
        END IF;

    EXCEPTION
        WHEN OTHERS THEN
            x_status := 'E';
            x_error_message := sqlerrm;
    END get_teams_channel_filesfolder_id;
    
        --file upload procedure till 4 mb
    PROCEDURE upload_study_binder_small_files (
        p_folder_id      NUMBER,
        x_status         OUT  VARCHAR2,
        x_error_message  OUT  VARCHAR2
    ) IS

        lc_teams_body             CLOB;
        lc_create_teams_response  CLOB;
        l_x_token                 VARCHAR2(4000);
        l_x_status                VARCHAR2(200);
        l_x_error_code            VARCHAR2(1000);
        l_x_error_message         VARCHAR2(4000);
        l_msft_user_id            VARCHAR2(2000);
        l_vcheadername            VARCHAR2(32000) := NULL;
        l_vcheadervalue           VARCHAR2(32000) := NULL;
        l_aop_document            BLOB;
        l_aop_clob                CLOB;
        x_env_error_code          VARCHAR2(500) := NULL;
        l_tab_name                VARCHAR2(500) := NULL;
        l_tab_key                 VARCHAR2(500) := NULL;
        l_rec_id                  VARCHAR2(500) := NULL;
        l_envelope_id_seq         NUMBER := 0;
        l_mime_type               VARCHAR2(500) := NULL;
        l_document_name           VARCHAR2(500) := NULL;
    BEGIN
        x_status := 'S';
        x_error_message := NULL;
        generate_outh2_token(x_token => l_x_token, x_status => l_x_status, x_error_code => l_x_error_code,
                            x_error_message => l_x_error_message);

        dbms_output.put_line('L_X_TOKEN ' || l_x_token);
        BEGIN
            SELECT
                bin_doc,
                file_name,
                tab_name,
                tab_key,
                rec_id,
                mime_type
            INTO
                l_aop_document,
                l_document_name,
                l_tab_name,
                l_tab_key,
                l_rec_id,
                l_mime_type
            FROM
                c_bin_docs
            WHERE
                    bdoc_id = 3941
                AND status = 1;

        EXCEPTION
            WHEN OTHERS THEN
                NULL;
              --  x_env_return_status := 'E';
              --  x_env_error_message := 'Document is not avaiable in c_bin_docs';
        END;

       -- l_aop_clob := apex_web_service.blob2clobbase64(l_aop_document);
        l_aop_clob := base64encode(l_aop_document);
        dbms_output.put_line('l_aop_clob '
                             || substr(l_aop_clob, 1, 32000));
        apex_web_service.g_request_headers(1).name := 'Authorization';
        apex_web_service.g_request_headers(1).value := 'Bearer ' || l_x_token;
        apex_web_service.g_request_headers(2).name := 'Content-Type';
        apex_web_service.g_request_headers(2).value := 'text/plain';
                
                --apex_web_service.g_request_headers(2).name := 'Content-Transfer-Encoding';
                -- apex_web_service.g_request_headers(2).value := 'base64';
        lc_create_teams_response := apex_web_service.make_rest_request(p_url => 'https://graph.microsoft.com/v1.0/drives/b!zt4k14HEe0q83Lv68V3Ds5gD7T1QFg1Cqm7koL6JI-aYeYEytwnoQZ2GSeat2eVf/items/013A376RDYIRKX7GIUGZB3UZW2ECVIHHMJ:/sampll:/content',
                                                                      p_http_method => 'PUT',
                                                                      p_body => l_aop_clob);

        apex_json.parse(lc_create_teams_response);
        dbms_output.put_line('lc_create_teams_response = '
                             || substr(lc_create_teams_response, 1, 3000));
        dbms_output.put_line(' status ' || apex_web_service.g_status_code);
    EXCEPTION
        WHEN OTHERS THEN
            x_status := 'E';
           -- x_error_code := sqlcode;
            x_error_message := sqlerrm;
    END upload_study_binder_small_files;
    
    
     procedure add_binder_members_inbulk( 
        p_binder_id      VARCHAR2,
        x_status         OUT  VARCHAR2,
        x_error_message  OUT  VARCHAR2) IS
        
       lc_team_members_body               CLOB;
        lc_team_members_response    CLOB;
        l_x_token                   VARCHAR2(4000);
        l_x_status                  VARCHAR2(200);
        l_x_error_code              VARCHAR2(1000);
        l_x_error_message           VARCHAR2(4000);
        l_msft_user_id              VARCHAR2(2000);
        l_vcheadername              VARCHAR2(32000) := NULL;
        l_vcheadervalue             VARCHAR2(32000) := NULL;
        
        CURSOR c_team_members IS
        SELECT
            member_email
        FROM
            C_STUDY_TEAM_MEMBERS
        WHERE
            team_id = p_binder_id
            --and api_status is null
            and membership_type is null;

        lc_create_members_response  CLOB := NULL;
        
        lc_create_members_payload clob :=null;
        lc_create_members_payload_temp clob :=null;
        lc_create_members_payload_temp_base clob :=null;
        lc_create_members_payload_temp_base_end clob:=null;
        
        l_msft_team_id VARCHAR2(500) :=null;
    BEGIN
        generate_outh2_token(x_token => l_x_token, x_status => l_x_status, x_error_code => l_x_error_code,
                            x_error_message => l_x_error_message);

        IF l_x_token IS NOT NULL THEN
        lc_create_members_payload :=null;
        
            FOR rec_team_members IN c_team_members LOOP
              
              
                       
                        lc_create_members_payload_temp := '
                        
                        {
                           "@odata.type":"#microsoft.graph.aadUserConversationMember",
                           "user@odata.bind":"https://graph.microsoft.com/v1.0/users('
                                 || ''''
                                 || rec_team_members.member_email
                                 || ''''
                                 || ')",
                           "roles":[]
                        },
                      '  ;
                    
                    lc_create_members_payload := lc_create_members_payload || lc_create_members_payload_temp;
                 END LOOP;
                 
                 IF lc_create_members_payload IS NOT NULL THEN
           
                 
                  lc_create_members_payload_temp_base := '{
                    "values": [';
                 lc_create_members_payload_temp_base_end := ']
                    }';
                 
                 
                   
                lc_create_members_payload :=  lc_create_members_payload_temp_base || lc_create_members_payload ||  lc_create_members_payload_temp_base_end;
                lc_create_members_payload_temp :=null;   
               END IF;  
               
                  
                dbms_output.put_line('lc_create_members_payload '
                                     || substr(lc_create_members_payload, 1, 32000));
                                     
                SELECT msft_team_id
                INTO l_msft_team_id
                FROM
                    c_study_teams
                WHERE
                    team_id = p_binder_id;                    
                apex_web_service.g_request_headers(1).name := 'Content-Type';
                apex_web_service.g_request_headers(1).value := 'application/json';
                apex_web_service.g_request_headers(2).name := 'Authorization';
                apex_web_service.g_request_headers(2).value := 'Bearer ' || l_x_token;
                lc_create_members_response := apex_web_service.make_rest_request(p_url => 'https://graph.microsoft.com/v1.0/teams/'
                                                                                          || l_msft_team_id
                                                                                          || '/members/add',
                                                                                p_http_method => 'POST',
                                                                                p_body => lc_create_members_payload);

                dbms_output.put_line(' status ' || apex_web_service.g_status_code);
                apex_json.parse(lc_create_members_response);
                dbms_output.put_line(' lc_create_members_response ' || substr(lc_create_members_response,1,32000));
                
                IF apex_web_service.g_status_code = 200 OR apex_web_service.g_status_code = 207  THEN
                    --apex_json.parse(lc_create_members_response);
                    
                    FOR i IN 1..apex_json.get_count(p_path => 'value') LOOP
                       
                      
                    UPDATE C_STUDY_TEAM_MEMBERS
                    SET
                        api_status = DECODE (apex_json.get_varchar2(p_path => 'value[%d].error', p0 => i ),null,'S','E'),
                        API_ERROR_MESSAGE = apex_json.get_varchar2(p_path => 'value[%d].error', p0 => i )
                    WHERE
                        member_email = (SELECT USER_PRINCIPAL_NAME FROM C_MSFT_O365_USERS 
                        WHERE MSFT_USER_ID = apex_json.get_varchar2(p_path => 'value[%d].userId', p0 => i ))
                        and team_id = p_binder_id;

                    x_status := 'S';
                    x_error_message := NULL;
                    end loop;
                END IF;
               IF  apex_web_service.g_status_code = 207  THEN

                    x_status := 'E';
                    x_error_message := 'Some of Membership addition failed.';
                END IF; 
                --end loop;

 

        ELSE
            x_status := 'E';
            --x_error_code := substr(l_x_error_code, 1, 999);
            x_error_message := substr(l_x_error_message, 1, 999);
        END IF;

    EXCEPTION
        WHEN OTHERS THEN
            x_status := 'E';
           -- x_error_code := sqlcode;
            x_error_message := sqlerrm;
        
        END add_binder_members_inbulk;
        
        procedure add_binder_channel_members_inbulk( 
        p_channel_id      VARCHAR2,
        x_status         OUT  VARCHAR2,
        x_error_message  OUT  VARCHAR2) IS
      
      lc_team_members_body               CLOB;
        lc_team_members_response    CLOB;
        l_x_token                   VARCHAR2(4000) :=null;
        l_x_status                  VARCHAR2(200) :=null;
        l_x_error_code              VARCHAR2(1000) :=null;
        l_x_error_message           VARCHAR2(4000) :=null;
        l_msft_user_id              VARCHAR2(2000) :=null;
        l_msft_channel_id           VARCHAR2(2000) :=null;
        l_rest_url varchar2(1000) :=null;
        
        CURSOR c_channel_members IS
        SELECT
            MEMBER_EMAIL,membership_type
        FROM
            C_STUDY_CHANNEL_MEMBERS
        WHERE
            channel_id = p_channel_id
            --and api_status is null
            --and membership_type is null
            ;

        lc_create_members_response  CLOB := NULL;
        
        lc_create_members_payload clob :=null;
        lc_create_members_payload_temp clob :=null;
        lc_create_members_payload_temp_base clob :=null;
        lc_create_members_payload_temp_base_end clob:=null;
        
        l_msft_team_id VARCHAR2(500) :=null;
        
        l_binder_id number :=0;
    
    BEGIN
        generate_outh2_token(x_token => l_x_token, x_status => l_x_status, x_error_code => l_x_error_code,
                            x_error_message => l_x_error_message);

        IF l_x_token IS NOT NULL THEN
        lc_create_members_payload :=null;
        
        SELECT sb.MSFT_TEAM_ID,
                    sc.MSFT_CHANNEL_ID 
                INTO l_msft_team_id, 
                     l_msft_channel_id 
                FROM c_study_channels sc ,c_study_teams sb
                 where channel_id = p_channel_id
                 and sb.team_id = sc.team_id;
        
            FOR rec_team_members IN c_channel_members LOOP
              lc_create_members_payload :=null;
              
              
              
                       
                        lc_create_members_payload := '
                        
                        {
                           "@odata.type":"#microsoft.graph.aadUserConversationMember",
                           "user@odata.bind":"https://graph.microsoft.com/v1.0/users('
                                 || ''''
                                 || rec_team_members.member_email
                                 || ''''
                                 || ')",
                           "roles":['
                                      || '"'
                                      || rec_team_members.membership_type
                                      || '"'
                                      || ']
                        },
                      '  ;
                    
                    --lc_create_members_payload := lc_create_members_payload || lc_create_members_payload_temp;
                
                  lc_create_members_payload := replace(lc_create_members_payload,'[""]','[]'); 
                dbms_output.put_line('lc_create_members_payload '
                                     || substr(lc_create_members_payload, 1, 32000));
                                     
               
                    
                
                 
                 l_rest_url := 'https://graph.microsoft.com/v1.0/teams/'
                                                                                          || l_msft_team_id||'/channels/'||l_msft_channel_id
                                                                                          || '/members';
                dbms_output.put_line('l_rest_url '||l_rest_url);                                                                          
    
                apex_web_service.g_request_headers(1).name := 'Content-Type';
                apex_web_service.g_request_headers(1).value := 'application/json';
                apex_web_service.g_request_headers(2).name := 'Authorization';
                apex_web_service.g_request_headers(2).value := 'Bearer ' || l_x_token;
                lc_create_members_response := apex_web_service.make_rest_request(p_url => l_rest_url,
                                                                                p_http_method => 'POST',
                                                                                p_body => lc_create_members_payload);

                dbms_output.put_line(' status ' || apex_web_service.g_status_code);
                apex_json.parse(lc_create_members_response);
                dbms_output.put_line(' lc_create_members_response ' || substr(lc_create_members_response,1,32000));
                
                IF apex_web_service.g_status_code = 201 THEN
                    --apex_json.parse(lc_create_members_response);
                       
                      
                    UPDATE C_STUDY_CHANNEL_MEMBERS
                    SET
                        api_status = 'S',
                        API_ERROR_MESSAGE = null
                    WHERE
                        upper(member_email) = upper(apex_json.get_varchar2(p_path => 'email'))
                        and channel_id = p_channel_id;
                        
                       SELECT team_id into l_binder_id from c_study_channels WHERE channel_id = p_channel_id;
                        
                    C_ESTUDY_BINDERS_PKG.insert_audit_trails(
                       P_TEAM_ID  =>l_binder_id,
                      P_CHANNEL_ID  => p_channel_id, 
                      P_SOURCE      =>'oracle apex',   
                      P_MESSAGE     => rec_team_members.member_email || ' has been added as '|| rec_team_members.membership_type ||' in Teams Channel');      

                    x_status := 'S';
                    x_error_message := NULL;
                ELSE
                    UPDATE C_STUDY_CHANNEL_MEMBERS
                    SET
                        api_status = 'E',
                        API_ERROR_MESSAGE = substr(apex_json.get_varchar2('error.message'), 1, 3999)
                    WHERE
                        upper(member_email) = upper(apex_json.get_varchar2(p_path => 'email'))
                        and channel_id = p_channel_id;
 
                   x_status := 'E';
                   x_error_message := substr(apex_json.get_varchar2('error.message'), 1, 3999);
                    dbms_output.put_line('message: ' || apex_json.get_varchar2('error.message'));

                END IF;
             end loop;

 

        ELSE
            x_status := 'E';
            --x_error_code := substr(l_x_error_code, 1, 999);
            x_error_message := substr(l_x_error_message, 1, 999);
        END IF;

    EXCEPTION
        WHEN OTHERS THEN
            x_status := 'E';
           -- x_error_code := sqlcode;
            x_error_message := sqlerrm;
        END add_binder_channel_members_inbulk;   
----------------------------------------------------------------------------------------------------------        





        

END "C_APEX_MSFT_O365_INTEGRATION_PKG";
/