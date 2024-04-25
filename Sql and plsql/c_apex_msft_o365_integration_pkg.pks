create or replace PACKAGE c_apex_msft_o365_integration_pkg AS

-- -----------------------------------------------------------------------------------
-- File Name    : C_APEX_MSFT_O365_INTEGRATION_PKG.pks
-- Author       : Sett Consultant
-- Description  : Oracle Apex and Microsoft Office 365 Integration
-- Creation Date: 01-May-2021 Draft
-- -----------------------------------------------------------------------------------

    lv_tenant_id CONSTANT VARCHAR2(240) := '9d742a33-e8f9-4ebe-acdf-9d9ba04a62ae'; -- need to change as per MSFT Azure Active Directory tenant id
    lv_client_id CONSTANT VARCHAR2(240) := '5bc982a9-7f97-4f09-9113-2cd77865cc8f'; -- need to change as per MSFT Azure Active Directory client id
    lv_client_secret CONSTANT VARCHAR2(240) := 'D2-rvS1.iH.f9rcE83CMS8NQXx_m1QjF18'; -- need to change as per MSFT Azure Active Directory client Secret id

    lv_resorce VARCHAR2(240) := '00000003-0000-0000-c000-000000000000'; --this will be fixed for Audiance - graph.microsoft.com

    g_from_mail VARCHAR2(100) := 'info1@frontagelab.com'; --applicable for mail send procedure

    g_recepients_email_id VARCHAR2(500) := NULL;
    g_kace_report_email_id VARCHAR2(500) := NULL;
    FUNCTION decode_base64 (
        p_clob_in IN CLOB
    ) RETURN BLOB;

    PROCEDURE load_o365_emails (
        x_status         OUT  VARCHAR2,
        x_error_message  OUT  VARCHAR2
    );

    PROCEDURE generate_outh2_token (
        x_token          OUT  VARCHAR2,
        x_status         OUT  VARCHAR2,
        x_error_code     OUT  VARCHAR2,
        x_error_message  OUT  VARCHAR2
    );

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
    );

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
    );

    PROCEDURE delete_cal_event (
        p_event_id               IN   VARCHAR2,
        p_event_recepient_email  IN   VARCHAR2,
        x_status                 OUT  VARCHAR2,
        x_error_code             OUT  VARCHAR2,
        x_error_message          OUT  VARCHAR2
    );

    PROCEDURE mail_send (
        p_email_subject     IN   VARCHAR2,
        p_to_mail           IN   VARCHAR2,
        p_cc_mail           IN   VARCHAR2,
        p_email_body        IN   VARCHAR2,
        p_email_attachment  IN   BLOB,
        x_status            OUT  VARCHAR2,
        x_error_code        OUT  VARCHAR2,
        x_error_message     OUT  VARCHAR2
    );

    PROCEDURE delete_message (
        p_message_id          IN   VARCHAR2,
        p_from_email_address  IN   VARCHAR2,
        x_status              OUT  VARCHAR2,
       -- x_error_code          OUT  VARCHAR2,
        x_error_message       OUT  VARCHAR2
    );

    PROCEDURE get_cal_events (
        p_user_email     IN   VARCHAR2,
        x_status         OUT  VARCHAR2,
        x_error_code     OUT  VARCHAR2,
        x_error_message  OUT  VARCHAR2
    );

    PROCEDURE get_user_details (
        p_user_email     IN   VARCHAR2,
        x_status         OUT  VARCHAR2,
        x_error_message  OUT  VARCHAR2,
        x_msft_user_id OUT VARCHAR2
    );
    
    PROCEDURE update_user_details(p_user_email     IN   VARCHAR2,
        p_JOB_TITLE IN   VARCHAR2,
        p_MOBILE_PHONE IN   VARCHAR2,
        p_BUSINESS_PHONE IN   VARCHAR2,
        p_OFFICE_LOCATION IN   VARCHAR2,
        p_DEPARTMENT IN   VARCHAR2,
        x_status         OUT  VARCHAR2,
        x_error_message  OUT  VARCHAR2) ;

    PROCEDURE get_team_members_roles (
        p_team_id        IN   VARCHAR2 DEFAULT NULL,
        p_user_email     IN   VARCHAR2 DEFAULT NULL,
        x_status         OUT  VARCHAR2,
        x_error_message  OUT  VARCHAR2
    );

    PROCEDURE get_user_joined_teams (
        p_user_email     IN   VARCHAR2,
        x_status         OUT  VARCHAR2,
        x_error_message  OUT  VARCHAR2
    );
    
    PROCEDURE get_joined_team_channels (
        p_team_id        IN   VARCHAR2 DEFAULT NULL,
        x_status         OUT  VARCHAR2,
        x_error_message  OUT  VARCHAR2
    );
    
    PROCEDURE get_team_channels (
        p_team_id        IN   VARCHAR2 DEFAULT NULL,
        x_status         OUT  VARCHAR2,
        x_error_message  OUT  VARCHAR2
    );
    
    
     PROCEDURE get_onedrive_shared_files (
        p_user_email     IN   VARCHAR2,
        x_status         OUT  VARCHAR2,
        x_error_message  OUT  VARCHAR2
    );


    PROCEDURE load_mail_attachments (
        p_message_id     VARCHAR2,
        p_attachment_id  VARCHAR2,
       -- p_email_address  VARCHAR2,
        x_status         OUT  VARCHAR2,
        x_error_message  OUT  VARCHAR2
    );

    PROCEDURE load_csv_data (
        x_status OUT VARCHAR2
    );

    PROCEDURE read_emails (
        x_status         OUT  VARCHAR2,
        x_error_message  OUT  VARCHAR2
    );
    
    
      PROCEDURE list_tenant_user_activities (
        x_status         OUT  VARCHAR2,
        x_error_message  OUT  VARCHAR2
    );
    
    PROCEDURE list_tenant_user_signins (
        x_status         OUT  VARCHAR2,
        x_error_message  OUT  VARCHAR2
    );
    
    PROCEDURE create_teams_with_channels(
        p_team_name IN VARCHAR2,
        p_team_description IN VARCHAR2,
        p_team_owner_email     IN   VARCHAR2,
        x_status         OUT  VARCHAR2,
        x_error_message  OUT  VARCHAR2,
        x_team_id out VARCHAR2
    );
    

    
   PROCEDURE get_teams_channel_filesfolder_id (
        p_team_id        VARCHAR2,
        p_channel_id     VARCHAR2,
        x_status         OUT  VARCHAR2,
        x_error_message  OUT  VARCHAR2,
        x_drive_id OUT varchar2,
        x_drive_item_id out varchar2
    );
    
    --file upload procedure till 4 mb
    PROCEDURE upload_study_binder_small_files(
    p_folder_id number,
    x_status         OUT  VARCHAR2,
    x_error_message  OUT  VARCHAR2    
    );
        
     /*PROCEDURE create_folder_in_teams (
        p_drive_id       VARCHAR2,
        p_folder_name     varchar2,
        p_drive_item_id  VARCHAR2,
        x_status         OUT  VARCHAR2,
        x_error_message  OUT  VARCHAR2,
        x_folder_id out varchar2
    );*/
    
    
    procedure add_binder_members_inbulk( 
        p_binder_id      VARCHAR2,
        x_status         OUT  VARCHAR2,
        x_error_message  OUT  VARCHAR2); 
        
    
    procedure add_binder_channel_members_inbulk( 
        p_channel_id      VARCHAR2,
        x_status         OUT  VARCHAR2,
        x_error_message  OUT  VARCHAR2);
                              
                          
                              
                                
   
        
      
    
END c_apex_msft_o365_integration_pkg;
/