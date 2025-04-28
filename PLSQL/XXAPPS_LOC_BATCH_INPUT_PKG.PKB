create or replace package body XXAPPS_LOC_BATCH_INPUT_PKG is
   /*---------------------------16-04-2024--------------------------------------
      +=========================================================================+
      |              Copyright (c) 2019 Wonderful Citrus LLC.                   |
      |                        All rights reserved                              |
      +=========================================================================+
      | Version    Date        Author         Description                       |
      | =======   ===========  =============  ==================================|
      |1           29-MAR-24    Subhojit      Location Based Batch Input App
      +=========================================================================+
         */
    g_wallet_path VARCHAR2(200); 
    g_wallet_pass VARCHAR2(200); 
    
 PROCEDURE PUT_INFO_LOG (P_PROC IN VARCHAR2, P_MESSAGE IN CLOB)
    IS
    BEGIN
        XXTWC_LOG_PKG.ADD_INFO_LOG_CLOB (
            P_MODULE       => 'APEX_WEBSERVICE',
            P_PACKAGE      => 'XXAPPS_LOC_BATCH_INPUT_PKG',
            P_PROCEDURE    => P_PROC,
            P_TEXT         => P_MESSAGE,
            P_PROCESS_ID   => NULL);
    END PUT_INFO_LOG;    
 PROCEDURE PUT_SEVERE_LOG (P_PROC IN VARCHAR2, P_MESSAGE IN CLOB)
    IS
    BEGIN
        XXTWC_LOG_PKG.ADD_SEVERE_LOG_CLOB (
            P_MODULE       => 'APEX_WEBSERVICE',
            P_PACKAGE      => 'XXAPPS_LOC_BATCH_INPUT_PKG',
            P_PROCEDURE    => P_PROC,
            P_TEXT         => P_MESSAGE,
            P_PROCESS_ID   => NULL);
    END PUT_SEVERE_LOG;     
  FUNCTION FN_QUERY_ORG_ACCESS (
        P_FACILITY_ORG    IN  VARCHAR2,
        P_APP_USER        IN  VARCHAR2
) RETURN VARCHAR2 AS

O_QUERY VARCHAR2(32000);
  BEGIN
      -- O_QUERY:='select 1 d,2 m from dual';
		 O_QUERY:='   SELECT inv.ORGANIZATION_CODE D , inv.ORGANIZATION_CODE R
            FROM fusion.FUN_USER_ROLE_DATA_ASGNMNTS role,
            fusion.INV_ORG_PARAMETERS inv,
            fusion.per_users pu,
            fusion.per_roles_dn_vl pr--,
           -- xxtwc_fnd_lookup_values flv
            WHERE inv.ORGANIZATION_ID = role.INV_ORGANIZATION_ID
            AND pu.USER_GUID = role.USER_GUID
            AND pr.ROLE_COMMON_NAME = role.ROLE_NAME
            and UPPER(pu.username) = upper('''||P_APP_USER||''')
            AND role.ACTIVE_FLAG=''Y''
            AND role.ROLE_NAME IN(''TWC_MERGE_PARTIAL_PALLETS'')
           -- AND flv.LOOKUP_TYPE=''TWC_APEX_MANUAL_ORG''TWC_MERGE_PARTIAL_PALLETS
           -- and flv.LOOKUP_CODE=inv.ORGANIZATION_CODE
--            AND flv.enabled_flag=''Y''
--            and flv.LANGUAGE=''US''
--            AND NVL(flv.start_date_active,SYSDATE-1)<=SYSDATE
--            AND NVL(flv.end_date_active,SYSDATE+1)>=SYSDATE
--   UNION ALL
--   SELECT ''CDM1'' D , ''CDM1'' FROM DUAL
            ';

    RETURN O_QUERY;      
      EXCEPTION WHEN OTHERS THEN
      
       PUT_SEVERE_LOG ('XXAPPS_LOC_BATCH_INPUT_PKG.FN_QUERY_ORG_ACCESS', SQLERRM);
	END FN_QUERY_ORG_ACCESS;    
  FUNCTION FN_QUERY_ORG_ACCESS_AUTHORIZATION (
        P_APP_USER        IN  VARCHAR2,
        P_FUS_ROLE        IN VARCHAR2
) RETURN boolean
   AS
   V_COUNT NUMBER;
  begin
            SELECT COUNT(*) INTO V_COUNT
            FROM fusion.FUN_USER_ROLE_DATA_ASGNMNTS role,
            fusion.INV_ORG_PARAMETERS inv,
            fusion.per_users pu,
            fusion.per_roles_dn_vl pr
            WHERE inv.ORGANIZATION_ID = role.INV_ORGANIZATION_ID
            AND pu.USER_GUID = role.USER_GUID
            AND pr.ROLE_COMMON_NAME = role.ROLE_NAME
            and UPPER(pu.username) = upper(P_APP_USER)
            AND role.ACTIVE_FLAG='Y'
            AND role.ROLE_NAME IN(P_FUS_ROLE);
    IF  V_COUNT=0 THEN RETURN FALSE; ELSE RETURN TRUE; END IF;
       EXCEPTION WHEN OTHERS THEN
       PUT_SEVERE_LOG ('XXAPPS_LOC_BATCH_INPUT_PKG.FN_QUERY_ORG_ACCESS_AUTHORIZATION', SQLERRM);           
 END FN_QUERY_ORG_ACCESS_AUTHORIZATION;
 
 PROCEDURE CREATE_OUTPUT_LPN_PR(
                                 P_BODY             CLOB,
                                 P_RESPONSE     OUT CLOB,
                                 P_STATUSCODE   OUT NUMBER)
    AS
        V_ENV_ROW       XXTWC_ENVIRONMENT_DETAILS%ROWTYPE;
        V_INPUT_URL     VARCHAR2 (200);
        G_WALLET_PATH   VARCHAR2 (200);
        G_WALLET_PASS   VARCHAR2 (200);
        V_STATUSCODE    NUMBER;
        L_OWNER         VARCHAR2 (200);
        L_NAME          VARCHAR2 (200);
        L_LINENO        VARCHAR2 (200);
        L_CALLER_T      VARCHAR2 (200);
        v_kit_desc      VARCHAR2(500);
    -- THIS PROCEDURE IS USED TO MAKE A WEBSERVICE CALL TO CREATE WORK ORDERS IN FUSION
    BEGIN

        XXTWC_APEX_WEBSERVICE_PKG.get_auth_details('WMS', v_env_row);
        V_INPUT_URL := CONCAT (V_ENV_ROW.BASE_URL,'/lgfapi/'||V_ENV_ROW.ATTRIBUTE1||'/entity/iblpn/composite_create');
        P_RESPONSE :=
            APEX_WEB_SERVICE.MAKE_REST_REQUEST (
                P_URL           => V_INPUT_URL,
                P_HTTP_METHOD   => 'POST',
                P_USERNAME      => V_ENV_ROW.USER_NAME,
                P_PASSWORD      => V_ENV_ROW.PASSWORD,
                P_SCHEME        => 'Basic',
                P_BODY          => P_BODY,
                P_WALLET_PATH   => G_WALLET_PATH,
                P_WALLET_PWD    => G_WALLET_PASS);

        P_STATUSCODE := APEX_WEB_SERVICE.G_STATUS_CODE;

        OWA_UTIL.WHO_CALLED_ME (OWNER      => L_OWNER,
                                NAME       => L_NAME,
                                LINENO     => L_LINENO,
                                CALLER_T   => L_CALLER_T);

        if p_statuscode=400 then
        
                                 apex_error.add_error (
                      p_message => JSON_VALUE(p_response,'$.message')
                                  ||'-'
                                  ||JSON_VALUE(p_response,'$.details'),
                      p_display_location => apex_error.c_inline_in_notification 
                             );   
       GOTO SKIP_EXECUTION;
        end if;
  <<SKIP_EXECUTION>>
    BEGIN
    PUT_SEVERE_LOG ('XXAPPS_LOC_BATCH_INPUT_PKG.CREATE_OUTPUT_LPN_PR', 'SKIP_EXECUTION');
    END;
    EXCEPTION
        WHEN OTHERS
        THEN
            PUT_SEVERE_LOG ('XXAPPS_LOC_BATCH_INPUT_PKG.CREATE_OUTPUT_LPN_PR', SQLERRM);
    END CREATE_OUTPUT_LPN_PR;     
     PROCEDURE PR_GET_WMS_ON_HAND_LPN_QTY (
                    P_FACILITY_ORG	IN	VARCHAR2,
                    P_LPN	    IN	VARCHAR2,
                    P_RESPONSE          OUT CLOB,
                    P_STATUSCODE        OUT NUMBER
                    ) AS
        V_ENV_ROW      XXTWC_ENVIRONMENT_DETAILS%ROWTYPE;
        V_INPUT_URL    VARCHAR2 (4000);
    begin
        XXTWC_APEX_WEBSERVICE_PKG.get_auth_details('WMS', v_env_row); 
        v_input_url := v_env_row.base_url 
                       || '/lgfapi/' 
                       || v_env_row.attribute1 
                       || '/entity/inventory?container_id__container_nbr=' 
                       || P_LPN 
                       || '&facility_id__code=' 
                       || P_FACILITY_ORG
                       ||'&curr_qty!=0'; 

        P_RESPONSE := apex_web_service.make_rest_request(
                           p_url => v_input_url, 
                           p_http_method => 'GET', 
                           p_username => v_env_row.user_name,
                           p_password => v_env_row.password,
                           p_scheme => 'Basic', 
                           p_body => NULL, 
                           p_wallet_path => g_wallet_path,
                           p_wallet_pwd => g_wallet_pass 
                                                        ); 
      p_statuscode := apex_web_service.g_status_code;                                                          
    EXCEPTION WHEN OTHERS THEN
     PUT_SEVERE_LOG ('XXAPPS_LOC_BATCH_INPUT_PKG.PR_GET_WMS_ON_HAND_LPN_QTY', SQLERRM);
    END PR_GET_WMS_ON_HAND_LPN_QTY;
	
  PROCEDURE PR_WMS_LPN_DETALS(
        P_FACILITY_ORG	IN	VARCHAR2,
        P_LPN	    IN	VARCHAR2,
      --  P_REQUEST_QTY	IN	NUMBER ,
      --   P_WMS_LPN_AVBLTY OUT NUMBER,
--        P_LPN_ID      OUT NUMBER,
--        P_LPN_ITEM    OUT VARCHAR2
       P_RESPONSE    OUT CLOB,
       P_STATUSCODE  OUT NUMBER
        )AS
    L_GET_LPN_RESPONSE CLOB;
    L_GET_INV_LPN_RESPONSE CLOB;
    L_STATUS_CODE NUMBER;
    L_FACILITY_ID NUMBER;
   BEGIN
    select id into L_FACILITY_ID from facility where code=P_FACILITY_ORG;

   XXTWC_APEX_WEBSERVICE_PKG.
           WMS_GET_LPN_DETAILS(
                                   P_LPN_NUMBER        =>P_LPN,
                                   P_WMS_FACILITY_ID   =>L_FACILITY_ID,
                                   P_RESPONSE          =>L_GET_LPN_RESPONSE,
                                   P_STATUSCODE        =>L_STATUS_CODE
                             );

       if L_STATUS_CODE not in(200,201,204,203) then
                 apex_error.add_error (
                      p_message => JSON_VALUE(L_GET_LPN_RESPONSE,'$.message')
                                  ||'-'
                                  ||JSON_VALUE(L_GET_LPN_RESPONSE,'$.details'),
                      p_display_location => apex_error.c_inline_in_notification 
                             );
--            RAISE_APPLICATION_ERROR(-20009,JSON_VALUE(L_GET_LPN_RESPONSE,'$.message')
--                                  ||'-'
--                                  ||JSON_VALUE(L_GET_LPN_RESPONSE,'$.details'));
            GOTO SKIP_EXECUTION;
      ELSE
     
      if TO_NUMBER(JSON_VALUE(L_GET_LPN_RESPONSE, '$.results.status_id')) not in(30,99)  then
         apex_error.add_error (
                          p_message => 'LPN is not located',
                 p_display_location => apex_error.c_inline_in_notification 
                                 );
                GOTO SKIP_EXECUTION;
        else
        P_STATUSCODE:=L_STATUS_CODE;
        P_RESPONSE:=L_GET_LPN_RESPONSE;
--        PR_GET_WMS_ON_HAND_LPN_QTY
--                           ( 
--                    P_FACILITY_ORG	=>P_FACILITY_ORG,
--                    P_LPN	    =>P_LPN,
--                    P_RESPONSE      =>L_GET_INV_LPN_RESPONSE,
--                    P_STATUSCODE    =>L_STATUS_CODE
--                            );
     end if;
--               if L_STATUS_CODE not in(200,201,204,203,404) then
--                         apex_error.add_error (
--                              p_message => JSON_VALUE(L_GET_INV_LPN_RESPONSE,'$.message')
--                                          ||'-'
--                                          ||JSON_VALUE(L_GET_INV_LPN_RESPONSE,'$.details'),
--                              p_display_location => apex_error.c_inline_in_notification 
--                                     );
--               end if;  
--        if TO_NUMBER(JSON_VALUE(L_GET_INV_LPN_RESPONSE, '$.results.curr_qty'))>=1 --P_REQUEST_QTY 
--         then
--            P_WMS_LPN_AVBLTY:=to_number(JSON_VALUE(L_GET_INV_LPN_RESPONSE, '$.results.curr_qty'));
--            P_LPN_ID:=to_number(JSON_VALUE(L_GET_LPN_RESPONSE, '$.results.id'));
--            P_LPN_ITEM:=JSON_VALUE(L_GET_INV_LPN_RESPONSE, '$.results.item_id.key');
--            else
--            P_WMS_LPN_AVBLTY:=0;
--            P_LPN_ITEM:=null;
--        end if;
     end if;
    <<SKIP_EXECUTION>>
    BEGIN
    PUT_SEVERE_LOG ('XXAPPS_LOC_BATCH_INPUT_PKG.PR_WMS_LPN_DETALS', 'SKIP_EXECUTION');
    END;
   EXCEPTION WHEN OTHERS THEN
--               P_WMS_LPN_AVBLTY:=0;
--            P_LPN_ITEM:=null;
            PUT_SEVERE_LOG('XXAPPS_LOC_BATCH_INPUT_PKG.PR_WMS_LPN_DETALS', SQLERRM);
   END PR_WMS_LPN_DETALS;   
FUNCTION FN_QUERY_LOV_ITEM_DESC(P_ITEM VARCHAR2)  RETURN VARCHAR2 AS
v_desc varchar2(4000);
  BEGIN
       SELECT
    description into v_desc
FROM
    fusion.egp_system_items_b  mb2,
    fusion.egp_system_items_tl des,
    fusion.inv_org_parameters  c
WHERE
        mb2.item_number = P_ITEM
    AND mb2.organization_id = des.organization_id
    AND mb2.inventory_item_id = des.inventory_item_id
    AND mb2.organization_id = c.organization_id
    AND des.organization_id = c.organization_id
    AND des.language = 'US'
    AND c.organization_code = 'WIMO';

    RETURN v_desc;      
      EXCEPTION WHEN OTHERS THEN
      
            PUT_SEVERE_LOG('XXAPPS_LOC_BATCH_INPUT_PKG.FN_QUERY_LOV_ITEM_DESC', SQLERRM);
  END FN_QUERY_LOV_ITEM_DESC;  
FUNCTION FN_VALIDATE_LPN_EXIST(P_LPN VARCHAR2) RETURN boolean AS
    V_COUNT number;
    BEGIN
    SELECT
        COUNT(*) INTO V_COUNT
    
    FROM
        apex_collections
     where collection_name='INPUT_LPN_LOAD' AND c001=P_LPN;  
     
     if V_COUNT!=0 then
     RETURN true;
     else
     return false;
     end if;
 END FN_VALIDATE_LPN_EXIST;
 FUNCTION FN_VALIDATE_LPN_ITEM_EXIST(P_ITEM VARCHAR2) RETURN boolean AS
    V_COUNT number;
    V_ROW_COUNT number;
    BEGIN
                SELECT
                COUNT(*) INTO V_ROW_COUNT
            
            FROM
                apex_collections
             where collection_name='INPUT_LPN_LOAD';
     
                    SELECT
                        COUNT(*) INTO V_COUNT
                    
                    FROM
                        apex_collections
                     where collection_name='INPUT_LPN_LOAD' AND c002=P_ITEM;  
     
     if V_ROW_COUNT>0 and V_COUNT=0 then
     RETURN true;
     else
     return false;
     end if;
 END FN_VALIDATE_LPN_ITEM_EXIST;
 
 PROCEDURE FN_ON_LPN_FUSION_HAND_QTY_VALIDATION(P_FACILITY_ORG IN VARCHAR,
                                        P_INPUT_LPN IN VARCHAR2, 
                                        P_REQUEST_QTY IN NUMBER,
                                        P_SEQ_ID IN NUMBER,
                                        P_VALID_QTY OUT VARCHAR2) 
    --RETURN VARCHAR2 
    AS
   V_LPN_INVENTORY_RESPONSE CLOB;
  V_LPN_INVENTORY_RESPONSE_STATUS NUMBER;
  V_FUSN_AVBLTY NUMBER;
 BEGIN
                PR_GET_WMS_ON_HAND_LPN_QTY
                           ( 
                    P_FACILITY_ORG	=>P_FACILITY_ORG,
                    P_LPN	    =>P_INPUT_LPN,
                    P_RESPONSE      =>V_LPN_INVENTORY_RESPONSE,
                    P_STATUSCODE    =>V_LPN_INVENTORY_RESPONSE_STATUS
                            );
       PR_FUSION_PASS_TBL_AVAIL_QTY(
                        P_FACILITY_ORG	=>P_FACILITY_ORG,
                        P_ITEM	    =>JSON_VALUE(V_LPN_INVENTORY_RESPONSE, '$.results.item_id.key'),
                        P_BATCH_NO	=>JSON_VALUE(V_LPN_INVENTORY_RESPONSE, '$.results.batch_number_id.key'),
                        P_REQUEST_QTY=>P_REQUEST_QTY,
                        P_FUSN_AVBLTY=>V_FUSN_AVBLTY); 
   if P_REQUEST_QTY<0 then     
      P_VALID_QTY:='N';
        
        else
          if   V_LPN_INVENTORY_RESPONSE_STATUS  IN (200,201,204,203) AND 
                P_REQUEST_QTY<=TO_NUMBER(JSON_VALUE(V_LPN_INVENTORY_RESPONSE, '$.results.curr_qty')) AND
                P_REQUEST_QTY<=V_FUSN_AVBLTY
             
              then 
                P_VALID_QTY:='Y';
           ELSE
               P_VALID_QTY:='N';
          END IF;
             BEGIN
                APEX_COLLECTION.UPDATE_MEMBER_ATTRIBUTE (
                        p_collection_name => 'INPUT_LPN_LOAD',
                        p_seq => P_SEQ_ID,
                    p_attr_number =>1,
                    p_number_value => P_REQUEST_QTY);
            END;    

    END IF;
    
  EXCEPTION WHEN OTHERS THEN
  PUT_SEVERE_LOG('XXAPPS_LOC_BATCH_INPUT_PKG.FN_ON_LPN_HAND_QTY_VALIDATION', SQLERRM);                            
 END FN_ON_LPN_FUSION_HAND_QTY_VALIDATION;
 
 PROCEDURE WMS_CONSUME_FULL_LPN_QTY (
        p_lpn_id     VARCHAR2,
        p_body       CLOB,
        p_response   OUT CLOB,
        p_statuscode OUT NUMBER
    ) AS

        v_env_row    xxtwc_environment_details%rowtype;
        v_input_url  VARCHAR2(200);
        v_statuscode NUMBER;
        l_owner      VARCHAR2(200);
        l_name       VARCHAR2(200);
        l_lineno     VARCHAR2(200);
        l_caller_t   VARCHAR2(200); 
    -- THIS PROCEDURE IS USED TO MAKE A WEBSERVICE CALL TO CONSUME FULL LPN QTY IN WMS 
    BEGIN
        XXTWC_APEX_WEBSERVICE_PKG.get_auth_details('WMS', v_env_row);
        v_input_url := v_env_row.base_url
                       || '/lgfapi/'
                       || v_env_row.attribute1
                       || '/entity/iblpn/'
                       || p_lpn_id
                       || '/direct_consume';

        p_response := apex_web_service.make_rest_request(p_url => v_input_url,
                                                         p_http_method => 'POST', 
                                                         p_username => v_env_row.user_name, 
                                                         p_password => v_env_row.password, 
                                                         p_scheme => 'Basic',
                                                        p_body => p_body, 
                                                        p_wallet_path => g_wallet_path, 
                                                        p_wallet_pwd => g_wallet_pass
                                                        );

        p_statuscode := apex_web_service.g_status_code;  

        OWA_UTIL.WHO_CALLED_ME (OWNER      => L_OWNER,
                                NAME       => L_NAME,
                                LINENO     => L_LINENO,
                                CALLER_T   => L_CALLER_T);

        XXTWC_APEX_WEBSERVICE_LOGGER (
            P_TXN_REFERENCE_ID   => NULL,
            P_TXN_TYPE           => 'XXAPPS_LOC_BATCH_INPUT_PKG.WMS_CONSUME_FULL_LPN_QTY',
            P_APP_NAME           =>    L_CALLER_T
                                    || ': '
                                    || L_OWNER
                                    || '.'
                                    || L_NAME,
            P_TXN_STATUS         => CASE
                                       WHEN P_STATUSCODE IN (200, 201,204)
                                       THEN
                                           'S'
                                       ELSE
                                           'E'
                                   END,
            P_REQUEST_URL        => V_INPUT_URL,
            P_REQUEST_PAYLOAD    => P_BODY,
            P_RESPONSE_PAYLOAD   => P_RESPONSE,
            P_HTTP_STATUS_CODE   => P_STATUSCODE);
   
    <<SKIP_EXECUTION>>
    BEGIN
    PUT_SEVERE_LOG ('XXAPPS_LOC_BATCH_INPUT_PKG.WMS_CONSUME_FULL_LPN_QTY', 'SKIP_EXECUTION');
    END;
    EXCEPTION WHEN OTHERS THEN
     PUT_SEVERE_LOG ('XXAPPS_LOC_BATCH_INPUT_PKG.WMS_CONSUME_FULL_LPN_QTY', SQLERRM);
      end WMS_CONSUME_FULL_LPN_QTY;
	  
     PROCEDURE WMS_MODIFY_LPN (
        p_lpn_id     VARCHAR2,
        p_body       CLOB,
        p_response   OUT CLOB,
        p_statuscode OUT NUMBER
    ) AS

        v_env_row    xxtwc_environment_details%rowtype;
        v_input_url  VARCHAR2(200);
        v_statuscode NUMBER;
        l_owner      VARCHAR2(200);
        l_name       VARCHAR2(200);
        l_lineno     VARCHAR2(200);
        l_caller_t   VARCHAR2(200); 
    -- THIS PROCEDURE IS USED TO MAKE A WEBSERVICE CALL TO MODIFY LPN QTY IN WMS 
    BEGIN
        XXTWC_APEX_WEBSERVICE_PKG.get_auth_details('WMS', v_env_row);
        v_input_url := v_env_row.base_url
                       || '/lgfapi/'
                       || v_env_row.attribute1
                       || '/entity/iblpn/'
                       || p_lpn_id
                       || '/modify_item_qty';

        p_response := apex_web_service.make_rest_request(p_url => v_input_url,
                                                         p_http_method => 'POST', 
                                                         p_username => v_env_row.user_name, 
                                                         p_password => v_env_row.password, 
                                                         p_scheme => 'Basic',
                                                        p_body => p_body, 
                                                        p_wallet_path => g_wallet_path, 
                                                        p_wallet_pwd => g_wallet_pass
                                                        );

        p_statuscode := apex_web_service.g_status_code;  

        OWA_UTIL.WHO_CALLED_ME (OWNER      => L_OWNER,
                                NAME       => L_NAME,
                                LINENO     => L_LINENO,
                                CALLER_T   => L_CALLER_T);

        XXTWC_APEX_WEBSERVICE_LOGGER (
            P_TXN_REFERENCE_ID   => NULL,
            P_TXN_TYPE           => 'XXAPPS_LOC_BATCH_INPUT_PKG.WMS_MODIFY_LPN',
            P_APP_NAME           =>    L_CALLER_T
                                    || ': '
                                    || L_OWNER
                                    || '.'
                                    || L_NAME,
            P_TXN_STATUS         => CASE
                                       WHEN P_STATUSCODE IN (200, 201,204)
                                       THEN
                                           'S'
                                       ELSE
                                           'E'
                                   END,
            P_REQUEST_URL        => V_INPUT_URL,
            P_REQUEST_PAYLOAD    => P_BODY,
            P_RESPONSE_PAYLOAD   => P_RESPONSE,
            P_HTTP_STATUS_CODE   => P_STATUSCODE);
   
    <<SKIP_EXECUTION>>
    BEGIN
    PUT_SEVERE_LOG ('XXAPPS_LOC_BATCH_INPUT_PKG.WMS_MODIFY_LPN', 'SKIP_EXECUTION');
    END;
    EXCEPTION WHEN OTHERS THEN
     PUT_SEVERE_LOG ('XXAPPS_LOC_BATCH_INPUT_PKG.WMS_MODIFY_LPN', SQLERRM);
      end WMS_MODIFY_LPN;
	  
   PROCEDURE PRC_CAPTURE_LPN_COLLECTION (
           --P_INPUT_LPN          IN  VARCHAR2,
           P_FACILITY_ID_CODE   IN VARCHAR2,
		   P_CURR_LOCATION_ID	IN VARCHAR2
		   
  ) IS 
  V_WMS_LPN_AVBLTY NUMBER;
  V_LPN_ID NUMBER;
  V_LPN_ITEM VARCHAR2(200);
  V_LPN_ITEM_DESC VARCHAR2(4000);
  V_LPN_CONTAINTER_RESPONSE CLOB;
  V_LPN_CONTAINTER_RESPONSE_STATUS NUMBER;
  V_LPN_INVENTORY_RESPONSE CLOB;
  V_LPN_INVENTORY_RESPONSE_STATUS NUMBER;
  v_ranch_no varchar2(300);
  v_pool_no varchar2(300);
  v_uom     varchar2(500);
  v_fusn_avblty NUMBER;
  G_WALLET_PATH   VARCHAR2 (200);
  G_WALLET_PASS   VARCHAR2 (200);
  v_row_count  NUMBER;
  v_create_event_result VARCHAR2(30000);
  l_json_response clob;
  l_statuscode    NUMBER;
  V_VARIETY	      VARCHAR2(3000);
  
   CURSOR CUR_INPUT_COLLECTION_VALID IS
         SELECT                              
            c004 Item,
            SUM(c006) Item_qty,    
            c008 Input_Batch
         FROM
            apex_collections
         where collection_name='INPUT_LPN_LOAD'
         GROUP BY c004,c008;
  
  
TYPE INV_ATTR_ARRAY IS TABLE OF  VARCHAR2 (500);
   l_attributes   INV_ATTR_ARRAY;         
    v_inv_attr_c VARCHAR2 (500);
    v_inv_attr_d VARCHAR2 (500);
    v_inv_attr_e VARCHAR2 (500);
    v_inv_attr_f VARCHAR2 (500);
    v_inv_attr_g VARCHAR2 (500);
    v_inv_attr_h VARCHAR2 (500);
    v_inv_attr_i VARCHAR2 (500);
    v_inv_attr_j VARCHAR2 (500);
    v_inv_attr_k VARCHAR2 (500);
    v_inv_attr_l VARCHAR2 (500);
    v_inv_attr_m VARCHAR2 (500);
    v_inv_attr_n VARCHAR2 (500);
    v_inv_attr_o VARCHAR2 (500);  
  BEGIN
  
  --IF P_INPUT_LPN IS NOT NULL THEN
  /*IF APEX_COLLECTION.COLLECTION_EXISTS (p_collection_name => 'INPUT_LPN_LOAD') THEN
  NULL;
  ELSE
  apex_collection.create_collection( p_collection_name => 'INPUT_LPN_LOAD' );
  END IF;
              if  FN_VALIDATE_LPN_EXIST(P_LPN =>P_INPUT_LPN) then
               apex_error.add_error (
                          p_message => P_INPUT_LPN||' LPN is Already Added!',
                 p_display_location => apex_error.c_inline_in_notification 
                                 );
                GOTO SKIP_EXECUTION;
              end if;

         PR_WMS_LPN_DETALS(
                    P_FACILITY_ORG	=>P_FACILITY_ID_CODE,
                    P_LPN	        =>P_INPUT_LPN,
                  --  P_REQUEST_QTY	IN	NUMBER ,
            --        P_WMS_LPN_AVBLTY =>V_WMS_LPN_AVBLTY, --OUT
            --        P_LPN_ID      =>V_LPN_ID,--OUT
            --        P_LPN_ITEM    =>V_LPN_ITEM--OUT
                   P_RESPONSE    =>V_LPN_CONTAINTER_RESPONSE,
                   P_STATUSCODE  =>V_LPN_CONTAINTER_RESPONSE_STATUS
                    );
        
    
           --   remove to minimize the API transactions
           PR_GET_WMS_ON_HAND_LPN_QTY
                           ( 
                    P_FACILITY_ORG	=>P_FACILITY_ID_CODE,
                    P_LPN	    	=>P_INPUT_LPN,
                    P_RESPONSE      =>V_LPN_INVENTORY_RESPONSE,
                    P_STATUSCODE    =>V_LPN_INVENTORY_RESPONSE_STATUS
                            );
                           
              if  FN_VALIDATE_LPN_ITEM_EXIST(P_ITEM=>JSON_VALUE(V_LPN_INVENTORY_RESPONSE, '$.results.item_id.key'))
              then
                apex_error.add_error (
                          p_message => ' Multiple Item Not Allowed!', --JSON_VALUE(V_LPN_INVENTORY_RESPONSE, '$.results.item_id.key')||'
                 p_display_location => apex_error.c_inline_in_notification 
                                 );
                GOTO SKIP_EXECUTION;             
              
              end if; 
			  
 if   V_LPN_INVENTORY_RESPONSE_STATUS  IN (200,201,204,203) AND 
      TO_NUMBER(JSON_VALUE(V_LPN_INVENTORY_RESPONSE, '$.results.curr_qty'))>=1
    then 
    V_LPN_ITEM:=JSON_VALUE(V_LPN_INVENTORY_RESPONSE, '$.results.item_id.key');
    V_LPN_ITEM_DESC:=FN_QUERY_LOV_ITEM_DESC(V_LPN_ITEM);
--    v_ranch_no:=RTRIM(substr(JSON_VALUE(V_LPN_INVENTORY_RESPONSE, '$.results.invn_attr_id.key'),
--                 1,
--                 instr(JSON_VALUE(V_LPN_INVENTORY_RESPONSE, '$.results.invn_attr_id.key')
--                 ,'-',1,1)-1),'-');
--   v_pool_no:=RTRIM(substr(JSON_VALUE(V_LPN_INVENTORY_RESPONSE, '$.results.invn_attr_id.key'),
--        instr(JSON_VALUE(V_LPN_INVENTORY_RESPONSE, '$.results.invn_attr_id.key'),'-',1,1)+1,
--        instr(JSON_VALUE(V_LPN_INVENTORY_RESPONSE, '$.results.invn_attr_id.key'),'-',1,2)-1),'-');  
   
    begin
            SELECT column_value 
            bulk collect into l_attributes
    FROM apex_string.split(JSON_VALUE(V_LPN_INVENTORY_RESPONSE, '$.results.invn_attr_id.key'),'-');
    v_ranch_no:=l_attributes(1);
    v_pool_no:=l_attributes(2);
    v_inv_attr_c:=l_attributes(3);
    v_inv_attr_d:=l_attributes(4);
    v_inv_attr_e:=l_attributes(5);
    v_inv_attr_f:=l_attributes(6);
    v_inv_attr_g:=l_attributes(7);
    v_inv_attr_h:=l_attributes(8);
    v_inv_attr_i:=l_attributes(9);
    v_inv_attr_j:=l_attributes(10);
    v_inv_attr_k:=l_attributes(11);
    v_inv_attr_l:=l_attributes(12);
    v_inv_attr_m:=l_attributes(13);
    v_inv_attr_n:=l_attributes(14);
    v_inv_attr_o:=l_attributes(15);
    end;
       
     FOR V IN CUR_INPUT_COLLECTION_VALID LOOP
            PR_FUSION_PASS_TBL_AVAIL_QTY(
                        P_FACILITY_ORG	=>P_FACILITY_ID_CODE,
                        P_ITEM	    =>V.Item,--V_LPN_ITEM,
                        P_BATCH_NO	=>V.Input_Batch,--JSON_VALUE(V_LPN_INVENTORY_RESPONSE, '$.results.batch_number_id.key'),
                        P_REQUEST_QTY =>V.Item_qty,--TO_NUMBER(JSON_VALUE(V_LPN_INVENTORY_RESPONSE, '$.results.curr_qty')), --passing 1 for count availability
                        P_FUSN_AVBLTY =>v_fusn_avblty);     
            if v_fusn_avblty=0 then 
               apex_error.add_error (
                          p_message => V.Input_Batch||' Fusion Onhand Qty not Available',
                 p_display_location => apex_error.c_inline_in_notification --
                                 );
            GOTO SKIP_EXECUTION;
            end if;
       END LOOP;
               --Taking UMO from WMS cloud IO table
                begin 
                 SELECT EXTERNAL_STYLE into v_uom
                 FROM ITEM  WHERE CODE=V_LPN_ITEM and rownum=1; 
                 exception when others THEN v_uom:='NA';
                 END;
				 
				BEGIN
				SELECT VARIETY INTO V_VARIETY
				FROM GEM.XX_ITEM_MASTER 
				WHERE ITEM_NO= V_LPN_ITEM;
				EXCEPTION WHEN NO_DATA_FOUND THEN V_VARIETY:='NA';
				END; 
				 
              APEX_COLLECTION.ADD_MEMBER(
                    p_collection_name => 'INPUT_LPN_LOAD',
                    p_c001            => P_INPUT_LPN,
                    p_c002            => JSON_VALUE(V_LPN_INVENTORY_RESPONSE, '$.results.facility_id.key'),
                    p_c003            => JSON_VALUE(V_LPN_CONTAINTER_RESPONSE, '$.results.curr_location_id.key'),
					p_c004            => V_LPN_ITEM,
                    p_c005            => V_LPN_ITEM_DESC,
					p_c006			  => TO_NUMBER(JSON_VALUE(V_LPN_INVENTORY_RESPONSE, '$.results.curr_qty')),
					p_c007            => v_ranch_no,
					p_c008            => JSON_VALUE(V_LPN_INVENTORY_RESPONSE, '$.results.batch_number_id.key'),
					p_c009            => v_pool_no,
                    p_c012            => v_uom,
					p_c013            => V_VARIETY,
					p_c014            => JSON_VALUE(V_LPN_INVENTORY_RESPONSE, '$.results.first_putaway_ts'),
                    p_n001            => TO_NUMBER(JSON_VALUE(V_LPN_INVENTORY_RESPONSE, '$.results.curr_qty')),--V_WMS_LPN_AVBLTY, --item qty
                    p_n002            => null,-- workorder_id for update
                    p_n003            => TO_NUMBER(JSON_VALUE(V_LPN_INVENTORY_RESPONSE, '$.results.item_id.id')),-- item_id
                    p_n004            => null,-- location_id
                    p_c015           => v_uom,
                    p_c021           => v_inv_attr_c,
                    p_c022           => v_inv_attr_d,
                    p_c023           => v_inv_attr_e,
                    p_c024           => v_inv_attr_f,
                    p_c025           => v_inv_attr_g,
                    p_c026           => v_inv_attr_h,
                    p_c027           => v_inv_attr_i,
                    p_c028           => v_inv_attr_j,
                    p_c029           => v_inv_attr_k,
                    p_c030           => v_inv_attr_l,
                    p_c031           => v_inv_attr_m,
                    p_c032           => v_inv_attr_n,
                    p_c033           => v_inv_attr_o
             );
 else
   apex_error.add_error (
                          p_message => 'Invalid LPN Number',
                 p_display_location => apex_error.c_inline_in_notification 
                                 );
  end if;*/
  
 
  --ELSE
  XXTWC_APEX_WEBSERVICE_PKG.GET_LPN_BASED_ON_LOCATION(
                                    P_BODY =>       '',   -- payload is not required as it's GET call
                                    P_CURR_LOCATION_ID => P_CURR_LOCATION_ID  ,
                                    P_FACILITY_ID_CODE => P_FACILITY_ID_CODE,
                                    P_RESPONSE =>   l_json_response,
                                    P_STATUSCODE => l_statuscode
                                  );
								  
	
  IF (l_statuscode = '200' OR l_statuscode = '201')
	THEN
		IF l_json_response IS NOT NULL THEN
                apex_json.parse(l_json_response);
				v_row_count := apex_json.get_count(p_path => 'results');
				
				--CREATE COLLCTION SKIP IF already created
				  IF APEX_COLLECTION.COLLECTION_EXISTS (p_collection_name => 'INPUT_LPN_LOAD') THEN
				  --NULL;
				  apex_collection.truncate_collection( p_collection_name => 'INPUT_LPN_LOAD' );
				  ELSE
				  apex_collection.create_collection( p_collection_name => 'INPUT_LPN_LOAD' );
				  END IF;

				IF v_row_count > 0 THEN	
                FOR i IN 1..v_row_count LOOP
				
				
				PR_GET_WMS_ON_HAND_LPN_QTY
                           ( 
                    P_FACILITY_ORG	=>P_FACILITY_ID_CODE,
                    P_LPN	        =>apex_json.get_varchar2(p_path => 'results[%d].container_nbr', p0 => i),
                    P_RESPONSE      =>V_LPN_INVENTORY_RESPONSE,
                    P_STATUSCODE    =>V_LPN_INVENTORY_RESPONSE_STATUS
                            );
                           
              /*if  FN_VALIDATE_LPN_ITEM_EXIST(P_ITEM=>JSON_VALUE(V_LPN_INVENTORY_RESPONSE, '$.results.item_id.key'))
              then
                apex_error.add_error (
                          p_message => ' Multiple Item Not Allowed!', --JSON_VALUE(V_LPN_INVENTORY_RESPONSE, '$.results.item_id.key')||'
                 p_display_location => apex_error.c_inline_in_notification 
                                 );
                GOTO SKIP_EXECUTION;          
              
              end if; */
                                         
					if   V_LPN_INVENTORY_RESPONSE_STATUS  IN (200,201,204,203) AND 
					TO_NUMBER(JSON_VALUE(V_LPN_INVENTORY_RESPONSE, '$.results.curr_qty'))>=1
					then 
					V_LPN_ITEM:=JSON_VALUE(V_LPN_INVENTORY_RESPONSE, '$.results.item_id.key');
					V_LPN_ITEM_DESC:=FN_QUERY_LOV_ITEM_DESC(V_LPN_ITEM);
					/*v_ranch_no:=RTRIM(substr(JSON_VALUE(V_LPN_INVENTORY_RESPONSE, '$.results.invn_attr_id.key'),
					1,
					instr(JSON_VALUE(V_LPN_INVENTORY_RESPONSE, '$.results.invn_attr_id.key')
					,'-',1,1)-1),'-');
					v_pool_no:=RTRIM(substr(JSON_VALUE(V_LPN_INVENTORY_RESPONSE, '$.results.invn_attr_id.key'),
					instr(JSON_VALUE(V_LPN_INVENTORY_RESPONSE, '$.results.invn_attr_id.key'),'-',1,1)+1,
					instr(JSON_VALUE(V_LPN_INVENTORY_RESPONSE, '$.results.invn_attr_id.key'),'-',1,2)-1),'-');*/

begin
            SELECT column_value 
            bulk collect into l_attributes
    FROM apex_string.split(JSON_VALUE(V_LPN_INVENTORY_RESPONSE, '$.results.invn_attr_id.key'),'-');
    v_ranch_no	:=l_attributes(1);
    v_pool_no	:=l_attributes(2);
    v_inv_attr_c:=l_attributes(3);
    v_inv_attr_d:=l_attributes(4);
    v_inv_attr_e:=l_attributes(5);
    v_inv_attr_f:=l_attributes(6);
    v_inv_attr_g:=l_attributes(7);
    v_inv_attr_h:=l_attributes(8);
    v_inv_attr_i:=l_attributes(9);
    v_inv_attr_j:=l_attributes(10);
    v_inv_attr_k:=l_attributes(11);
    v_inv_attr_l:=l_attributes(12);
    v_inv_attr_m:=l_attributes(13);
    v_inv_attr_n:=l_attributes(14);
    v_inv_attr_o:=l_attributes(15);
    end;

                    /*Taking UOM from WMS cloud IO table*/
                BEGIN 
                 SELECT EXTERNAL_STYLE into v_uom
                 FROM ITEM  WHERE CODE=V_LPN_ITEM and rownum=1; 
                 exception when others THEN v_uom:='NA';
                 END;
				 
				BEGIN
				SELECT VARIETY INTO V_VARIETY
				FROM GEM.XX_ITEM_MASTER 
				WHERE ITEM_NO= V_LPN_ITEM;
				EXCEPTION WHEN NO_DATA_FOUND THEN V_VARIETY:='NA';
				END;
				
				PR_FUSION_PASS_TBL_AVAIL_QTY(
                        P_FACILITY_ORG	=>P_FACILITY_ID_CODE,
                        P_ITEM	    =>V_LPN_ITEM,--V_LPN_ITEM,
                        P_BATCH_NO	=>JSON_VALUE(V_LPN_INVENTORY_RESPONSE, '$.results.batch_number_id.key'),
                        P_REQUEST_QTY =>TO_NUMBER(JSON_VALUE(V_LPN_INVENTORY_RESPONSE, '$.results.curr_qty')), --passing 1 for count availability
                        P_FUSN_AVBLTY =>v_fusn_avblty);
						
            if v_fusn_avblty <> 0 then 
                                   
              APEX_COLLECTION.ADD_MEMBER(
                    p_collection_name => 'INPUT_LPN_LOAD',
                    p_c001            => apex_json.get_varchar2(p_path => 'results[%d].container_nbr', p0 => i),
                    p_c002            => apex_json.get_varchar2(p_path => 'results[%d].facility_id.key', p0 => i),
                    p_c003            => apex_json.get_varchar2(p_path => 'results[%d].curr_location_id.key', p0 => i),
					p_c004            => V_LPN_ITEM,
                    p_c005            => V_LPN_ITEM_DESC,
					p_c006			  => TO_NUMBER(JSON_VALUE(V_LPN_INVENTORY_RESPONSE, '$.results.curr_qty')),
					p_c007            => v_ranch_no,
					p_c008            => JSON_VALUE(V_LPN_INVENTORY_RESPONSE, '$.results.batch_number_id.key'),
					p_c009            => v_pool_no,
                    p_c012            => v_uom,
					p_c013            => V_VARIETY,
					p_c014            => apex_json.get_varchar2(p_path => 'results[%d].first_putaway_ts', p0 => i),
                    /*p_n001            => TO_NUMBER(JSON_VALUE(V_LPN_INVENTORY_RESPONSE, '$.results.curr_qty')),--V_WMS_LPN_AVBLTY, --item qty
                    p_n002            => null,-- workorder_id for update
                    p_n003            => TO_NUMBER(JSON_VALUE(V_LPN_INVENTORY_RESPONSE, '$.results.item_id.id')),-- item_id
                    p_n004            => null,-- location_id
                    p_c015           => v_uom,*/
                    p_c021           => v_inv_attr_c,
                    p_c022           => v_inv_attr_d,
                    p_c023           => v_inv_attr_e,
                    p_c024           => v_inv_attr_f,
                    p_c025           => v_inv_attr_g,
                    p_c026           => v_inv_attr_h,
                    p_c027           => v_inv_attr_i,
                    p_c028           => v_inv_attr_j,
                    p_c029           => v_inv_attr_k,
                    p_c030           => v_inv_attr_l,
                    p_c031           => v_inv_attr_m,
                    p_c032           => v_inv_attr_n,
                    p_c033           => v_inv_attr_o
             );
 /*else
   apex_error.add_error (
                          p_message => 'Invalid LPN Number',
                 p_display_location => apex_error.c_inline_in_notification 
     	 );*/	
			end if;
					end if;
		END LOOP;
        end if;
   
        END IF;
		END IF;
  
  
  
  --END IF;
  
  <<SKIP_EXECUTION>>
    BEGIN
    PUT_SEVERE_LOG ('XXAPPS_LOC_BATCH_INPUT_PKG.PRC_CAPTURE_LPN_COLLECTION', 'SKIP_EXECUTION');
    END;
  EXCEPTION WHEN OTHERS THEN
  PUT_SEVERE_LOG('XXAPPS_LOC_BATCH_INPUT_PKG.PRC_CAPTURE_LPN_COLLECTION', SQLERRM);
  
  
  END PRC_CAPTURE_LPN_COLLECTION;


  
  PROCEDURE PR_CONSUME_INPUT_LPN_QTY (
   P_WORK_ORDER_ID  IN NUMBER,
    P_FACILITY_ORG	IN	VARCHAR2,
        P_INPUT_BATCH_NO	    IN	VARCHAR2,
        P_OUTPUT_BATCH_NO      IN VARCHAR2,
        P_LPN	    IN	VARCHAR2,
        P_UOM       IN  VARCHAR2,
        P_CONSUME_QTY	IN	NUMBER,
        P_POOL          IN  VARCHAR2 DEFAULT NULL,
        P_RANCH_BLOCK   IN  VARCHAR2 DEFAULT NULL,
        P_INV_ATTR_C VARCHAR2 DEFAULT NULL,
        P_INV_ATTR_D VARCHAR2 DEFAULT NULL,
        P_INV_ATTR_E VARCHAR2 DEFAULT NULL,
        P_INV_ATTR_F VARCHAR2 DEFAULT NULL,
        P_INV_ATTR_G VARCHAR2 DEFAULT NULL,
        P_INV_ATTR_H VARCHAR2 DEFAULT NULL,
        P_INV_ATTR_I VARCHAR2 DEFAULT NULL,
        P_INV_ATTR_J VARCHAR2 DEFAULT NULL,
        P_INV_ATTR_K VARCHAR2 DEFAULT NULL,
        P_INV_ATTR_L VARCHAR2 DEFAULT NULL,
        P_INV_ATTR_M VARCHAR2 DEFAULT NULL,
        P_INV_ATTR_N VARCHAR2 DEFAULT NULL,
        P_INV_ATTR_O VARCHAR2 DEFAULT NULL,
        P_ITEM_DESC     IN  VARCHAR2,
        P_LPN_LOCATION IN VARCHAR2    
                            ) AS

        L_WMS_LPN_AVBLTY NUMBER:=0;
        L_FUSN_AVBLTY    NUMBER:=0;
        L_MODIFY_LPN_RES CLOB;
        L_MATERIAL_TRANS_RES CLOB;
        l_statuscode   NUMBER;
        L_LPN_ID    NUMBER;
        L_LPN_ITEM    varchar2(500);
        L_MODIFY_LPN_QTY NUMBER;
        l_material_txn_statuscode number;
        l_final_status varchar2(1);
        L_MRA_ITEM VARCHAR2(200);
        v_modify_payload_change varchar2(200);
   BEGIN
           PR_WMS_LPN_AVAIL_QTY (
                P_FACILITY_ORG	=>P_FACILITY_ORG,
                P_BATCH_NO	    =>P_INPUT_BATCH_NO,
                P_LPN	    =>P_LPN,
                P_REQUEST_QTY	=>P_CONSUME_QTY,
                P_WMS_LPN_AVBLTY =>L_WMS_LPN_AVBLTY,
                P_LPN_ID      =>L_LPN_ID,
                P_LPN_ITEM    =>L_LPN_ITEM
                );
                
    if L_WMS_LPN_AVBLTY<P_CONSUME_QTY then
                                    apex_error.add_error (
                                  p_message => P_INPUT_BATCH_NO||' WMS LPN Qty Not Available',
                         p_display_location => apex_error.c_inline_in_notification 
                                         );  
                    GOTO SKIP_EXECUTION;
      end if;
      
      /*The fusion onhand check replaced with PR_FUSION_PASS_TBL_AVAIL_QTY*/
           /* PR_FUSION_AVAIL_QTY(
                    P_FACILITY_ORG	=>P_FACILITY_ORG,
                    P_ITEM	    =>L_LPN_ITEM,
                    P_BATCH_NO	    =>P_INPUT_BATCH_NO,
                    P_REQUEST_QTY	=>P_CONSUME_QTY,
                    P_FUSN_AVBLTY   =>L_FUSN_AVBLTY) ;
               if L_FUSN_AVBLTY<P_CONSUME_QTY then
                                    apex_error.add_error (
                                  p_message => 'Fusion Qty Not Available',
                         p_display_location => apex_error.c_inline_in_notification 
                                         );  
                          GOTO SKIP_EXECUTION;               
               end if;*/
            PR_FUSION_PASS_TBL_AVAIL_QTY(
                        P_FACILITY_ORG	=>P_FACILITY_ORG,
                        P_ITEM	    =>L_LPN_ITEM,
                        P_BATCH_NO	=>P_INPUT_BATCH_NO,
                        P_REQUEST_QTY =>P_CONSUME_QTY, 
                        P_FUSN_AVBLTY =>L_FUSN_AVBLTY); 
               if L_FUSN_AVBLTY<P_CONSUME_QTY then
                                    apex_error.add_error (
                                  p_message => P_INPUT_BATCH_NO||' Fusion Qty Not Available',
                         p_display_location => apex_error.c_inline_in_notification 
                                         );  
                          GOTO SKIP_EXECUTION;   
               end if;
    IF L_WMS_LPN_AVBLTY>=P_CONSUME_QTY and L_FUSN_AVBLTY>=P_CONSUME_QTY 
    then
    
         XXTWC_APEX_WEBSERVICE_PKG.WIP_ISSUE (
                         P_BODY          =>'{
                               "SourceSystemCode" : "APEX_MERGE_PALLETS",
                               "SourceSystemType" : "EXTERNAL",
                              "MaterialTransactionDetail" : [ {
                                 "InventoryItemNumber" : "'||L_LPN_ITEM||'",
                                 "OrganizationCode" : "'||P_FACILITY_ORG||'",
                                 "SubinventoryCode" : "AVAILABLE",
                                 "TransactionLot": [
                                    {
                                        "LotNumber": "'||P_INPUT_BATCH_NO||'",
                                        "TransactionQuantity": '||P_CONSUME_QTY||'
                                    }
                                                    ],
                                 "TransactionQuantity" : '||P_CONSUME_QTY||',
                                 "TransactionTypeCode" : "MATERIAL_ISSUE",
                                 "TransactionUOMCode" : "'||P_UOM||'",
                                 "WoOperationSequenceNumber" : 10,
                                 "WorkOrderNumber" : "'||P_OUTPUT_BATCH_NO||'"
                              } ]
                            }',
                         P_RESPONSE      =>L_MATERIAL_TRANS_RES,
                         P_STATUSCODE    =>l_material_txn_statuscode);
                         
          if JSON_VALUE(L_MATERIAL_TRANS_RES,'$.ErrorsExistFlag')='false' then
            l_final_status:='S';
                L_MODIFY_LPN_QTY:=L_WMS_LPN_AVBLTY-P_CONSUME_QTY;
                IF L_MODIFY_LPN_QTY!=0 THEN
--                   if P_RANCH_BLOCK is not null and P_POOL is not null then
--                   v_modify_payload_change:=', 
--                                            "invn_attr_a": "'||P_RANCH_BLOCK||'",
--                                            "invn_attr_b": "'||P_POOL||'",';
--                    else
--                    v_modify_payload_change:='';
--                   end if;
                WMS_MODIFY_LPN (
                    p_lpn_id     =>L_LPN_ID,
                           P_BODY =>'{
                                        "options": {
                                            "item_barcode": "'||L_LPN_ITEM||'",
                                            "actual_qty": '||L_MODIFY_LPN_QTY||',
                                            "batch_nbr" :"'||P_INPUT_BATCH_NO||'",
                                            "reason_code": "WI",
                                            "invn_attr_a": "'||P_RANCH_BLOCK||'",
                                            "invn_attr_b": "'||P_POOL||'",
                                            "invn_attr_c": "'||P_INV_ATTR_C||'",
                                            "invn_attr_d": "'||P_INV_ATTR_D||'",
                                            "invn_attr_e": "'||P_INV_ATTR_E||'",
                                            "invn_attr_f": "'||P_INV_ATTR_F||'",
                                            "invn_attr_g": "'||P_INV_ATTR_G||'",
                                            "invn_attr_h": "'||P_INV_ATTR_H||'",
                                            "invn_attr_i": "'||P_INV_ATTR_I||'",
                                            "invn_attr_j": "'||P_INV_ATTR_J||'",
                                            "invn_attr_k": "'||P_INV_ATTR_K||'",
                                            "invn_attr_l": "'||P_INV_ATTR_L||'",
                                            "invn_attr_m": "'||P_INV_ATTR_M||'",
                                            "invn_attr_n": "'||P_INV_ATTR_N||'",
                                            "invn_attr_o": "'||P_INV_ATTR_O||'",
                                            "transaction_ref_nbr": "'||P_INPUT_BATCH_NO||'-'||P_LPN||'"
                                        }
                                     }
                                    ',        p_response   =>L_MODIFY_LPN_RES,
                    p_statuscode =>l_statuscode);
                  ELSE
                  l_final_status:='S';
                    WMS_CONSUME_FULL_LPN_QTY(
                    p_lpn_id     =>L_LPN_ID,
                           P_BODY =>'{
                                        "options": {
                                            "reason_code": "WI", 
                                            "transaction_ref_nbr": "'||P_INPUT_BATCH_NO||'-'||P_LPN||'"
                                        }
                                     }
                                    ',        p_response   =>L_MODIFY_LPN_RES,
                    p_statuscode =>l_statuscode);  
                  l_final_status:='S';                    
                  END IF;
                    IF l_statuscode not in(200,201,204,203) then
                    l_final_status:='E';
                         XXTWC_APEX_WEBSERVICE_PKG.WIP_ISSUE (
                         P_BODY          =>'{
                               "SourceSystemCode" : "APEX_MERGE_PALLET",
                               "SourceSystemType" : "EXTERNAL",
                              "MaterialTransactionDetail" : [ {
                                 "InventoryItemNumber" : "'||L_LPN_ITEM||'",
                                 "OrganizationCode" : "'||P_FACILITY_ORG||'",
                                 "SubinventoryCode" : "AVAILABLE",
                                 "TransactionLot": [
                                    {
                                        "LotNumber": "'||P_INPUT_BATCH_NO||'",
                                        "TransactionQuantity": '||P_CONSUME_QTY||'
                                    }
                                                    ],                                 
                                 "TransactionQuantity" : '||P_CONSUME_QTY||',
                                 "TransactionTypeCode" : "MATERIAL_RETURN",
                                 "TransactionUOMCode" : "'||P_UOM||'",
                                 "WoOperationSequenceNumber" : 10,
                                 "WorkOrderNumber" : "'||P_OUTPUT_BATCH_NO||'"
                              } ]
                            }',
                         P_RESPONSE      =>L_MATERIAL_TRANS_RES,
                         P_STATUSCODE    =>l_material_txn_statuscode);
                    END IF;
             else
                 apex_error.add_error (
                                  p_message => 
                                  JSON_VALUE(L_MATERIAL_TRANS_RES,'$.MaterialTransactionDetail.ErrorMessages')
                                  ,
                         p_display_location => apex_error.c_inline_in_notification 
                                         );             
                   l_final_status:='E';
         end if;
         if l_final_status='S' THEN
         INSERT INTO XXAPPS_MERGE_INPUT_PALLETS(
                INPUT_ID         ,--NOT NULL NUMBER         
                ORG              ,--NOT NULL VARCHAR2(100)  
                INPUT_LPN_NO     ,--NOT NULL VARCHAR2(300)  
                INPUT_ITEM       ,--NOT NULL VARCHAR2(300)  
                ITEM_DESCRIPTION ,--NOT NULL VARCHAR2(4000) 
                ITEM_QTY         ,--         NUMBER         
                LOCATION         ,--         VARCHAR2(300)  
                UOM              ,--         VARCHAR2(300)  
                POOL            ,--           VARCHAR2(300)  
                BATCH_NO        ,--          VARCHAR2(300)  
                WMS_STATUS       ,--          VARCHAR2(1)    
               -- WMS_ERROR       ,--           CLOB           
                FUSION_STATUS    ,--          VARCHAR2(1)    
                INPUT_BLOCK
               -- FUSION_ERROR    ,--          CLOB           
                )
           VALUES(
                P_WORK_ORDER_ID,
                P_FACILITY_ORG,
                P_LPN,
                L_LPN_ITEM,
                P_ITEM_DESC,
                P_CONSUME_QTY,
                P_LPN_LOCATION,
                P_UOM,
                P_POOL,
                P_INPUT_BATCH_NO,
                'S',
                'S',
                P_RANCH_BLOCK
           );
        
         apex_application.g_print_success_message :='Successfully Consumed';   
    else
       INSERT INTO XXAPPS_MERGE_INPUT_PALLETS(
                INPUT_ID         ,--NOT NULL NUMBER         
                ORG              ,--NOT NULL VARCHAR2(100)  
                INPUT_LPN_NO     ,--NOT NULL VARCHAR2(300)  
                INPUT_ITEM       ,--NOT NULL VARCHAR2(300)  
                ITEM_DESCRIPTION ,--NOT NULL VARCHAR2(4000) 
                ITEM_QTY         ,--         NUMBER         
                LOCATION         ,--         VARCHAR2(300)  
                UOM              ,--         VARCHAR2(300)  
                POOL            ,--           VARCHAR2(300)  
                BATCH_NO        ,--          VARCHAR2(300)  
                WMS_STATUS       ,--          VARCHAR2(1)    
               -- WMS_ERROR       ,--           CLOB           
                FUSION_STATUS    ,--          VARCHAR2(1)    
                INPUT_BLOCK
               -- FUSION_ERROR    ,--          CLOB           
                )
           VALUES(
                P_WORK_ORDER_ID,
                P_FACILITY_ORG,
                P_LPN,
                L_LPN_ITEM,
                P_ITEM_DESC,
                P_CONSUME_QTY,
                P_LPN_LOCATION,
                P_UOM,
                P_POOL,
                P_INPUT_BATCH_NO,
                'E',
                'E',
                P_RANCH_BLOCK
           );
        END IF;
    END IF;
    COMMIT;
    
    <<SKIP_EXECUTION>>
    BEGIN
    PUT_SEVERE_LOG ('XXAPPS_LOC_BATCH_INPUT_PKG.PR_CONSUME_INPUT_LPN_QTY', 'SKIP_EXECUTION');
    END;
   EXCEPTION WHEN OTHERS THEN
    PUT_SEVERE_LOG ('XXAPPS_LOC_BATCH_INPUT_PKG.PR_CONSUME_INPUT_LPN_QTY', SQLERRM);
  END PR_CONSUME_INPUT_LPN_QTY;

	PROCEDURE PR_CREATE_OUT_LPN_QTY(P_FACILITY_ORG in varchar2,
										 P_LPN in varchar2,
                                         P_LOCATION_ID in number,
                                         P_OUTPUT_BATCH_NUM in varchar2
                                         )
                                         AS
        L_CREATE_LPN_RESPONSE CLOB;
        L_CREATE_LPN_STATUS NUMBER;        
        L_FACILITY_ID number;
        l_location_id number := P_LOCATION_ID ;
        v_upd_wrk_ord_resp clob;
        v_upd_wrk_ord_status number;
		L_MATERIAL_PRODUCT_COMP_TRANS_RES CLOB;
		L_MATERIAL_PRODUCT_COMP_TRANS_STATUS   NUMBER;
		V_OUTPUT_BLOCK varchar2(150);
		V_OUTPUT_POOL varchar2(150);
		V_QTY_VALID varchar2(1);
		V_VALID_TO_CREATE_LPN NUMBER;
		V_PRINTER_NAME VARCHAR2(150);
		v_create_lpn_payload_change varchar2(500);
		
         CURSOR CUR_INPUT_COLLECTION IS
         SELECT
            seq_id,
            c001 LPN,
			c002 FACILITY,
            c003 Location,
            c004 Item,    
            c005 Item_Description,
            c006 item_qty ,
            C007 Ranch,
            c008 Batch,
            c009 Pool,
            c012 UOM,
            c013 Variety,
            c014 Putaway_Date_Time,
			c015 work_order_out_no,
            c016 workorder_id,
			c017 consumption_status,
			c018 consumption_error,												
            c021 inv_attr_c,                                                    
            c022 inv_attr_d,                                                    
            c023 inv_attr_e,                                                    
            c024 inv_attr_f,                                                    
            c025 inv_attr_g,                                                    
            c026 inv_attr_h,                                                    
            c027 inv_attr_i,                                                    
            c028 inv_attr_j,                                                    
            c029 inv_attr_k,                                                    
            c030 inv_attr_l,
			c031 inv_attr_m,
			c032 inv_attr_n,
			c033 inv_attr_o
         FROM                                                                   
            apex_collections                                                    
         where collection_name='INPUT_LPN_LOAD' and c001 = P_LPN;
		 
         /*CURSOR CUR_OUTPUT_COLLECTION IS         
        SELECT
            --seq_id,
            c008 OutPutLPN,
            n003 Item_id,
            c002 Item,
            c003 Item_Description,
            sum(n001) Item_qty,   
            n002 as workorder_id,
            'LN-PARTIALS' Location,
            c015 UOM,
            c009 Pool,
            c010 Block,
            c011 Output_Batch--,
        --    seq_id remove
        
        FROM
            apex_collections
         where collection_name='INPUT_LPN_LOAD'
            group by c008,n003,c002,c003,n002,c015,c009,c010,c011 ; */ 
    BEGIN
    --Start Create Work order in Fusion once new LPN scanned from App
         /*for K in CUR_INPUT_COLLECTION loop
             UPDATE_WORK_ORDER (P_BODY=>'{
                                            "WorkOrderStatusCode" : "ORA_RELEASED"
                                        }'
                                            ,
                                 P_WORKORDER_ID =>K.workorder_id,
                                 P_RESPONSE     =>v_upd_wrk_ord_resp,
                                 P_STATUSCODE   =>v_upd_wrk_ord_status);
                                 
                
            if v_upd_wrk_ord_status not in(200,201,204,203) then
			
			APEX_COLLECTION.UPDATE_MEMBER_ATTRIBUTE (
                                    p_collection_name => 'INPUT_LPN_LOAD',
                                    p_seq => k.seq_id,
                                p_attr_number =>17,
                                p_attr_value  => 'E');
								
			APEX_COLLECTION.UPDATE_MEMBER_ATTRIBUTE (
                                    p_collection_name => 'INPUT_LPN_LOAD',
                                    p_seq => k.seq_id,
                                p_attr_number =>18,
                                p_attr_value  => 'Fusion updating Work Order issue. Pls contact IT team');	

			
			UPDATE XXAPPS_LOC_BATCH_INPUT
			SET CONSUMPTION_STATUS = 'E',
			CONSUMPTION_ERROR = 'Fusion updating Work Order issue. Pls contact IT team'
			WHERE LPN_NO = P_LPN;
			
								
								
			GOTO SKIP_EXECUTION;					
			end if;
        end loop;*/
		
                /*apex_error.add_error (
                        p_message => 'Fusion updating Work Order issue. Pls contact IT team',
                        p_display_location => apex_error.c_inline_in_notification 
                                     );  
                    */                                                                  
   
    --End Create Work order in Fusion once new LPN scanned from App      
    
    --Start  Post check all valid qty before consume for all LPNs & Fusion Lot Numbers
     for v in CUR_INPUT_COLLECTION loop
         FN_ON_LPN_FUSION_HAND_QTY_VALIDATION(P_FACILITY_ORG =>P_FACILITY_ORG,
                                              P_INPUT_LPN    =>v.LPN, 
                                              P_REQUEST_QTY  =>v.item_qty,
                                              P_SEQ_ID       =>v.seq_id,
                                              P_VALID_QTY    =>V_QTY_VALID);
                V_QTY_VALID:=V_QTY_VALID;                    
                if V_QTY_VALID='N' then
				
				APEX_COLLECTION.UPDATE_MEMBER_ATTRIBUTE (
                                    p_collection_name => 'INPUT_LPN_LOAD',
                                    p_seq => v.seq_id,
                                p_attr_number =>17,
                                p_attr_value  => 'E');
								
				APEX_COLLECTION.UPDATE_MEMBER_ATTRIBUTE (
                                    p_collection_name => 'INPUT_LPN_LOAD',
                                    p_seq => v.seq_id,
                                p_attr_number =>18,
                                p_attr_value  => 'On Hand Qty Not Available!');	

			
				UPDATE XXAPPS_LOC_BATCH_INPUT
				SET CONSUMPTION_STATUS = 'E',
				CONSUMPTION_ERROR = 'On Hand Qty Not Available!'
				WHERE LPN_NO = P_LPN;
				
                       /*apex_error.add_error (
                                 p_message => v.LPN||'On Hand Qty Not Available!',
                                p_display_location => apex_error.c_inline_in_notification 
                                ); */
								
                GOTO SKIP_EXECUTION;    
                end if;
			end loop;
      /*if V_QTY_VALID='N' THEN 
      GOTO SKIP_EXECUTION; 
      END if;*/
    --End Post check all valid qty before consume for all LPNs & Fusion Lot Numbers
            --Start consume LPNs & Fusion Lot Qty
			
            for i in CUR_INPUT_COLLECTION loop
					PR_CONSUME_INPUT_LPN_QTY (
					        P_WORK_ORDER_ID  	=>i.workorder_id,
					        P_FACILITY_ORG		=>P_FACILITY_ORG,
                            P_INPUT_BATCH_NO 	=>i.Batch,
                            P_OUTPUT_BATCH_NO 	=>P_OUTPUT_BATCH_NUM,
                            P_LPN	    		=>i.LPN,
                            P_UOM       		=>i.UOM,
                            P_CONSUME_QTY		=>i.item_qty,
                            P_POOL          	=>i.Pool,
                            P_RANCH_BLOCK   	=>i.Ranch,
                            P_INV_ATTR_C 		=>i.inv_attr_c,
                            P_INV_ATTR_D 		=>i.inv_attr_d,
                            P_INV_ATTR_E 		=>i.inv_attr_e,
                            P_INV_ATTR_F 		=>i.inv_attr_f,
                            P_INV_ATTR_G 		=>i.inv_attr_g,
                            P_INV_ATTR_H 		=>i.inv_attr_h,
                            P_INV_ATTR_I 		=>i.inv_attr_i,
                            P_INV_ATTR_J 		=>i.inv_attr_j,
                            P_INV_ATTR_K 		=>i.inv_attr_k,
                            P_INV_ATTR_L 		=>i.inv_attr_l,
                            P_INV_ATTR_M 		=>i.inv_attr_m,
                            P_INV_ATTR_N 		=>i.inv_attr_n,
                            P_INV_ATTR_O 		=>i.inv_attr_o,
                            P_ITEM_DESC  		=>i.Item_Description,
                            P_LPN_LOCATION		=>i.Location
                                        );
            end loop;
            --End consume LPNs & Fusion Lot Qty
        
            --Start Get location from WMS cloud IO table
            begin
                select id into L_FACILITY_ID from facility where code = P_FACILITY_ORG;
                --select id into l_location_id from LOCATION where AISLE = 'PARTIAL' AND facility_id = L_FACILITY_ID;
                exception when others then 
                     IF L_FACILITY_ID IS NULL THEN
                                         apex_error.add_error (
                                                          p_message => 'Facility issue check with IT team',
                                                          p_display_location => apex_error.c_inline_in_notification 
                                                                 );   
                        GOTO SKIP_EXECUTION;                                                                 
                     END IF;                
                     IF l_location_id IS NULL THEN
                                         apex_error.add_error (
                                                          p_message => 'location issue check with IT team',
                                                          p_display_location => apex_error.c_inline_in_notification 
                                                                 );   
                        GOTO SKIP_EXECUTION;
                     END IF;
            end;
            --End Get location from WMS cloud IO table

        /*for j in CUR_OUTPUT_COLLECTION loop
           -- check input input lpns are completed are not to create new LPN
           begin  
           select count(*)  INTO V_VALID_TO_CREATE_LPN from XXAPPS_MERGE_INPUT_PALLETS 
                 where input_id = j.workorder_id and
                       wms_status = 'E' and
                       fusion_status = 'E';
           end;   
           if V_VALID_TO_CREATE_LPN=0 then
              if j.Pool is not null and j.Block is not null then
                               v_create_lpn_payload_change:=',"invn_attr_id": {
                                            "invn_attr_a": "'||j.Block||'",
                                            "invn_attr_b": "'||j.Pool||'"
                                            }';
                            else
                               v_create_lpn_payload_change:='';
              end if;
            
                            CREATE_LPN_PR(
                                                     P_BODY =>'{
                                                            "options": {
                                                                "reason_code": "MA"
                                                            },
                                                            "fields": {
                                                                "iblpn": {
                                                                    "curr_location_id": "'||l_location_id||'",
                                                                    "status_id": "30",
                                                                    "container_nbr": "'||j.OutPutLPN||'"
                                                                },
                                                                    "company_id": "199",
                                                                    "inventory": [
                                                                        {
                                                                            "item_id": "'||j.item_id||'",   
                                                                        "batch_number_id": {
                                                                            "batch_nbr": "'||j.Output_Batch||'",
                                                                            "item_id": "'||j.item_id||'"
                                                                        },                                                                            
                                                                            "curr_qty": "'||j.Item_qty||'"
                                                                         '||v_create_lpn_payload_change||'
                                                                        }
                                                                    ],
                                                                    "facility_id": "'||L_FACILITY_ID||'"
                                                                }
                                                            }',
                                                     P_RESPONSE=>L_CREATE_LPN_RESPONSE,
                                                     P_STATUSCODE =>L_CREATE_LPN_STATUS);
                                                     
                                                     IF L_CREATE_LPN_STATUS NOT in(200,201,204,203) THEN
                                                        apex_error.add_error (
                                                          p_message => 'create LPN error'
                                                                      ||JSON_VALUE(L_CREATE_LPN_RESPONSE,'$.message')
                                                                      ||'-'
                                                                      ||JSON_VALUE(L_CREATE_LPN_RESPONSE,'$.details.iblpn.container_nbr'),
                                                          p_display_location => apex_error.c_inline_in_notification 
                                                                 );
                                                        goto SKIP_EXECUTION;
                                                    end if;
                    XXTWC_APEX_WEBSERVICE_PKG.WIP_ISSUE (
                         P_BODY          =>'{
                               "SourceSystemCode" : "APEX_MERGE_PALLET",
                               "SourceSystemType" : "EXTERNAL",
                              "MaterialTransactionDetail" : [ {
                                 "InventoryItemNumber" : "'||j.Item||'",
                                 "OrganizationCode" : "'||P_FACILITY_ORG||'",
                                 "TransactionLot": [
                                    {
                                        "LotNumber": "'||j.Output_Batch||'",
                                        "TransactionQuantity": '||j.Item_qty||'
                                    }
                                                    ],                                 
                                 "TransactionQuantity" : '||j.Item_qty||',
                                 "TransactionTypeCode" : "PRODUCT_COMPLETION",
                                 "TransactionUOMCode" : "'||j.UOM||'",
                                 "WoOperationSequenceNumber" : 10,
                                 "WorkOrderNumber" : "'||j.Output_Batch||'"
                              } ]
                            }',
                         P_RESPONSE      =>L_MATERIAL_PRODUCT_COMP_TRANS_RES,
                         P_STATUSCODE    =>L_MATERIAL_PRODUCT_COMP_TRANS_STATUS);
                if L_MATERIAL_PRODUCT_COMP_TRANS_STATUS in  (200,201,204,203) then    
                            
                    apex_application.g_print_success_message :='Successfully Merged with<br> LPN='||j.OutPutLPN||'<br>Batch='||j.Output_Batch;   
                        UPDATE XXAPPS_MERGE_OUTPUT_PALLETS
                             SET OUTPUT_ITEM=j.Item,
                                 ITEM_QTY=j.Item_qty,
                                 UOM=j.UOM,
                                 POOL=j.Pool,
                                 BATCH_NO=j.Output_Batch,
                                 WMS_STATUS='S',
                                 FUSION_STATUS='S',
                                 OUTPUT_BLOCK=j.Block
                                 
                            WHERE 
                              ID=j.workorder_id;
							  
                   UPDATE_WORK_ORDER (P_BODY=>'{
                                            "WorkOrderStatusCode" : "ORA_CLOSED"
                                        }'
                                            ,
                                 P_WORKORDER_ID =>j.workorder_id,
                                 P_RESPONSE     =>v_upd_wrk_ord_resp,
                                 P_STATUSCODE   =>v_upd_wrk_ord_status);                              
                            Begin
                                APEX_COLLECTION.CREATE_OR_TRUNCATE_COLLECTION(
                                    p_collection_name => 'INPUT_LPN_LOAD');
                            End;       
                        --PRINT PALLET TAG--2
                        BEGIN
                        SELECT PALLET_TAG_PRINTER_NAME INTO V_PRINTER_NAME
                             FROM XXTWC_PRINTERS_SETUP WHERE UPPER(USER_IDENTIFIER)=UPPER(v('APP_USER'));
                             
                         PR_PRINT_PALLET_TAG(
                                p_printer_name =>V_PRINTER_NAME,
                                p_org_code => P_FACILITY_ORG,
                                p_item_number =>j.Item,
                                p_lpn =>j.OutPutLPN,
                                p_batch_number =>j.Output_Batch,
                                p_primary_qty =>j.Item_qty
                            ) ;   
                    apex_application.g_print_success_message :='Successfully Merged with<br> LPN='||
                                                            j.OutPutLPN||'<br>Batch='||j.Output_Batch||'& Pallet Tag Printed';   
                        EXCEPTION WHEN OTHERS THEN
                    apex_application.g_print_success_message :='Successfully Merged with<br> LPN='||j.OutPutLPN||'<br>Batch='
                        ||j.Output_Batch||'& Not Printed due to Printer configuration'; 
                        
                        PUT_SEVERE_LOG ('calling PR_PRINT_PALLET_TAG from PR_CREATE_PALLET_OUT_LPN_QTY', SQLERRM);                        
                        END;

                end if;    
          else  --else part of V_VALID_TO_CREATE_LPN check
          
                             UPDATE_WORK_ORDER (P_BODY=>'{
                                            "WorkOrderStatusCode" : "ORA_CANCELED",
                                            "CanceledReason":"Failed Transaction"
                                        }'
                                            ,
                                 P_WORKORDER_ID=>j.workorder_id,
                                 P_RESPONSE     =>v_upd_wrk_ord_resp,
                                 P_STATUSCODE   =>v_upd_wrk_ord_status);  
                                 
                                                        apex_error.add_error (
                                                          p_message => 'Unable to Consume or Create LPN. Pls Contanct IT team',
                                                          p_display_location => apex_error.c_inline_in_notification 
                                                                 );
                       GOTO SKIP_EXECUTION;                                          
          end if;
                
                END LOOP;*/
 <<SKIP_EXECUTION>>
    BEGIN
    PUT_SEVERE_LOG ('XXAPPS_LOC_BATCH_INPUT_PKG.PR_CREATE_OUT_LPN_QTY', 'SKIP_EXECUTION');
    END;
EXCEPTION WHEN OTHERS THEN

 PUT_SEVERE_LOG ('XXAPPS_LOC_BATCH_INPUT_PKG.PR_CREATE_OUT_LPN_QTY', SQLERRM);
  
  END PR_CREATE_OUT_LPN_QTY;
  
    PROCEDURE PR_FUSION_AVAIL_QTY(
        P_FACILITY_ORG	IN	VARCHAR2,
        P_ITEM	    IN	VARCHAR2,
        P_BATCH_NO	    IN	VARCHAR2,
        P_REQUEST_QTY	IN	NUMBER,
        P_FUSN_AVBLTY   OUT NUMBER)AS

         L_GET_INV_FUS_RESPONSE CLOB;
         L_STATUS_CODE          NUMBER;
   BEGIN
   
     PR_GET_FUS_ON_HAND_DG_ITM_QTY (
                    P_FACILITY_ORG	=>P_FACILITY_ORG,
                    P_ITEM	    =>P_ITEM,
                    P_BATCH_NO  =>P_BATCH_NO,
                    P_RESPONSE      =>L_GET_INV_FUS_RESPONSE,
                    P_STATUSCODE    =>L_STATUS_CODE
                    );


               if L_STATUS_CODE not in(200,201,204,203) then
                         apex_error.add_error (
                              p_message => 'No Item found',
                              p_display_location => apex_error.c_inline_in_notification 
                                     );
               end if;  
        if TO_NUMBER(JSON_VALUE(L_GET_INV_FUS_RESPONSE, '$.items.OnhandQuantity'))>=P_REQUEST_QTY then
        P_FUSN_AVBLTY:=TO_NUMBER(JSON_VALUE(L_GET_INV_FUS_RESPONSE, '$.items.OnhandQuantity'));
        else
        P_FUSN_AVBLTY:=0;
        end if;
   EXCEPTION WHEN OTHERS THEN
    PUT_SEVERE_LOG ('XXAPPS_LOC_BATCH_INPUT_PKG.PR_FUSION_AVAIL_QTY', SQLERRM);
   END PR_FUSION_AVAIL_QTY;  
  PROCEDURE PR_GET_FUS_ON_HAND_DG_ITM_QTY (
                    P_FACILITY_ORG	IN	VARCHAR2,
                    P_ITEM	    IN	VARCHAR2,
                    P_BATCH_NO  IN VARCHAR2,
                    P_RESPONSE          OUT CLOB,
                    P_STATUSCODE        OUT NUMBER
                    ) AS
        V_ENV_ROW      XXTWC_ENVIRONMENT_DETAILS%ROWTYPE;
        V_INPUT_URL    VARCHAR2 (4000);
        V_STATUSCODE   NUMBER;
        L_OWNER        VARCHAR2 (200);
        L_NAME         VARCHAR2 (200);
        L_LINENO       VARCHAR2 (200);
        L_CALLER_T     VARCHAR2 (200);
    begin
        XXTWC_APEX_WEBSERVICE_PKG.GET_AUTH_DETAILS ('SAAS', V_ENV_ROW);
        V_INPUT_URL := CONCAT (V_ENV_ROW.BASE_URL, 'onhandQuantityDetails?q=ItemNumber='||P_ITEM||';OrganizationCode='||P_FACILITY_ORG||';SubinventoryCode=AVAILABLE'||';LotNumber='||P_BATCH_NO);


        P_RESPONSE :=
            APEX_WEB_SERVICE.MAKE_REST_REQUEST (
                P_URL           => V_INPUT_URL,
                P_HTTP_METHOD   => 'GET',
                P_USERNAME      => V_ENV_ROW.USER_NAME,
                P_PASSWORD      => V_ENV_ROW.PASSWORD,
                P_SCHEME        => 'Basic',
                --P_BODY          => NULL,
                P_WALLET_PATH   => G_WALLET_PATH,
                P_WALLET_PWD    => G_WALLET_PASS);

        P_STATUSCODE := APEX_WEB_SERVICE.G_STATUS_CODE;


    EXCEPTION
        WHEN OTHERS
        THEN
             PUT_SEVERE_LOG ('XXAPPS_LOC_BATCH_INPUT_PKG.PR_GET_FUS_ON_HAND_DG_ITM_QTY', SQLERRM);

    END PR_GET_FUS_ON_HAND_DG_ITM_QTY;
PROCEDURE PR_WMS_LPN_AVAIL_QTY (
        P_FACILITY_ORG	IN	VARCHAR2,
        P_BATCH_NO	    IN	VARCHAR2,
        P_LPN	    IN	VARCHAR2,
        P_REQUEST_QTY	IN	NUMBER ,
        P_WMS_LPN_AVBLTY OUT NUMBER,
        P_LPN_ID      OUT NUMBER,
        P_LPN_ITEM    OUT VARCHAR2)AS
    L_GET_LPN_RESPONSE CLOB;
    L_GET_INV_LPN_RESPONSE CLOB;
    L_STATUS_CODE NUMBER;
    L_FACILITY_ID NUMBER;
   BEGIN
    select id into L_FACILITY_ID from facility where code=P_FACILITY_ORG;

   XXTWC_APEX_WEBSERVICE_PKG.
           WMS_GET_LPN_DETAILS(
                                   P_LPN_NUMBER        =>P_LPN,
                                   P_WMS_FACILITY_ID   =>L_FACILITY_ID,
                                   P_RESPONSE          =>L_GET_LPN_RESPONSE,
                                   P_STATUSCODE        =>L_STATUS_CODE
                             );

       if L_STATUS_CODE not in(200,201,204,203,404) then
                 apex_error.add_error (
                      p_message => JSON_VALUE(L_GET_LPN_RESPONSE,'$.message')
                                  ||'-'
                                  ||JSON_VALUE(L_GET_LPN_RESPONSE,'$.details'),
                      p_display_location => apex_error.c_inline_in_notification 
                             );
      ELSE

      if TO_NUMBER(JSON_VALUE(L_GET_LPN_RESPONSE, '$.results.status_id')) not in(30,99)  then
         apex_error.add_error (
                          p_message => 'LPN is not located',
                 p_display_location => apex_error.c_inline_in_notification 
                                 );
        else
        PR_GET_WMS_ON_HAND_LPN_QTY
                           ( 
                    P_FACILITY_ORG	=>P_FACILITY_ORG,
                    P_LPN	    =>P_LPN,
                    P_RESPONSE      =>L_GET_INV_LPN_RESPONSE,
                    P_STATUSCODE    =>L_STATUS_CODE
                            );
     end if;
               if L_STATUS_CODE not in(200,201,204,203,404) then
                         apex_error.add_error (
                              p_message => JSON_VALUE(L_GET_INV_LPN_RESPONSE,'$.message')
                                          ||'-'
                                          ||JSON_VALUE(L_GET_INV_LPN_RESPONSE,'$.details'),
                              p_display_location => apex_error.c_inline_in_notification 
                                     );
               end if;  
        if TO_NUMBER(JSON_VALUE(L_GET_INV_LPN_RESPONSE, '$.results.curr_qty'))>=P_REQUEST_QTY then
            P_WMS_LPN_AVBLTY:=to_number(JSON_VALUE(L_GET_INV_LPN_RESPONSE, '$.results.curr_qty'));
            P_LPN_ID:=to_number(JSON_VALUE(L_GET_LPN_RESPONSE, '$.results.id'));
            P_LPN_ITEM:=JSON_VALUE(L_GET_INV_LPN_RESPONSE, '$.results.item_id.key');
            else
            P_WMS_LPN_AVBLTY:=0;
            P_LPN_ITEM:=null;
        end if;
     end if;
   EXCEPTION WHEN OTHERS THEN
               P_WMS_LPN_AVBLTY:=0;
            P_LPN_ITEM:=null;
            PUT_SEVERE_LOG('XXAPPS_LOC_BATCH_INPUT_PKG.PR_WMS_LPN_AVAIL_QTY', SQLERRM);
   END PR_WMS_LPN_AVAIL_QTY;  
PROCEDURE CREATE_LPN_PR(
                                 P_BODY             CLOB,
                                 P_RESPONSE     OUT CLOB,
                                 P_STATUSCODE   OUT NUMBER)
    AS
        V_ENV_ROW       XXTWC_ENVIRONMENT_DETAILS%ROWTYPE;
        V_INPUT_URL     VARCHAR2 (200);
        G_WALLET_PATH   VARCHAR2 (200);
        G_WALLET_PASS   VARCHAR2 (200);
        V_STATUSCODE    NUMBER;
        L_OWNER         VARCHAR2 (200);
        L_NAME          VARCHAR2 (200);
        L_LINENO        VARCHAR2 (200);
        L_CALLER_T      VARCHAR2 (200);
        v_kit_desc      VARCHAR2(500);
    -- THIS PROCEDURE IS USED TO MAKE A WEBSERVICE CALL TO CREATE WORK ORDERS IN FUSION
    BEGIN

        XXTWC_APEX_WEBSERVICE_PKG.get_auth_details('WMS', v_env_row);
        V_INPUT_URL := CONCAT (V_ENV_ROW.BASE_URL,'/lgfapi/'||V_ENV_ROW.ATTRIBUTE1||'/entity/iblpn/composite_create');
        P_RESPONSE :=
            APEX_WEB_SERVICE.MAKE_REST_REQUEST (
                P_URL           => V_INPUT_URL,
                P_HTTP_METHOD   => 'POST',
                P_USERNAME      => V_ENV_ROW.USER_NAME,
                P_PASSWORD      => V_ENV_ROW.PASSWORD,
                P_SCHEME        => 'Basic',
                P_BODY          => P_BODY,
                P_WALLET_PATH   => G_WALLET_PATH,
                P_WALLET_PWD    => G_WALLET_PASS);

        P_STATUSCODE := APEX_WEB_SERVICE.G_STATUS_CODE;
        OWA_UTIL.WHO_CALLED_ME (OWNER      => L_OWNER,
                                NAME       => L_NAME,
                                LINENO     => L_LINENO,
                                CALLER_T   => L_CALLER_T);

        XXTWC_APEX_WEBSERVICE_LOGGER (
            P_TXN_REFERENCE_ID   => NULL,
            P_TXN_TYPE           => 'XXAPPS_LOC_BATCH_INPUT_PKG.CREATE_LPN_PR',
            P_APP_NAME           =>    L_CALLER_T
                                    || ': '
                                    || L_OWNER
                                    || '.'
                                    || L_NAME,
            P_TXN_STATUS         => CASE
                                       WHEN P_STATUSCODE IN (200, 201)
                                       THEN
                                           'S'
                                       ELSE
                                           'E'
                                   END,
            P_REQUEST_URL        => V_INPUT_URL,
            P_REQUEST_PAYLOAD    => P_BODY,
            P_RESPONSE_PAYLOAD   => P_RESPONSE,
            P_HTTP_STATUS_CODE   => P_STATUSCODE);
    EXCEPTION
        WHEN OTHERS
        THEN
            PUT_SEVERE_LOG ('XXAPPS_LOC_BATCH_INPUT_PKG.CREATE_LPN_PR', SQLERRM);
    END CREATE_LPN_PR;   

procedure create_process_work_order(P_FACILITY_ORG	  IN VARCHAR2,
                                    P_OUTPUT_LPN_SCAN IN VARCHAR2,
									P_CREATED_ON	  IN VARCHAR2,      
                                    P_CREATED_BY      IN VARCHAR2) 
as
V_RESPONSE CLOB;
V_STATUSCODE NUMBER;
V_SYSDATE VARCHAR2(10):=TO_CHAR(SYSDATE,'YYYY-MM-DD');
V_WORK_ORDER_OUT_NO VARCHAR2(500);
V_WORK_ORDER_ID NUMBER;
V_OUTPUT_POOL VARCHAR2(200);
V_OUTPUT_BLOCK VARCHAR2(200);
V_VARIETY VARCHAR(300);

cursor c_seq  is
  SELECT seq_id ,
		c001 as LPN_NO,
       c002 as "FACILITY",
       c003 as "LOCATION",
       c004 as ITEM,
       C005 as ITEM_DESCRIPTION,
       C006 as ITEM_QTY,
       c007 as RANCH,
       c008 as LOT,
       c009 as POOL,
       c012 as UOM,
       c013 as VARIETY,
       c014 as PUTAWAY_DATE_TIME
                    FROM
                        apex_collections
                     where collection_name='INPUT_LPN_LOAD' AND c001 = P_OUTPUT_LPN_SCAN;
	BEGIN   
		for i in c_seq loop
		
         
      /*CREATE_WORK_ORDER(P_BODY=>'{
                                            "OrganizationCode": "'||P_FACILITY_ORG||'",
                                            "ProcessName": "W1000003",
                                            "PlannedStartDate": "'||V_SYSDATE||'",
                                            "ExplosionFlag": true,
                                            "WorkOrderPriority": 100,
                                            "WorkOrderDescription": "APEX_PARTIAL_MERGE",
                                            "WorkOrderType": "STANDARD",
                                            "WorkOrderStatusCode": "ORA_UNRELEASED",
                                            "ProcessWorkOrderDFF": [
                                                {
                                                    "__FLEX_Context": "TWC_Mfg_Order", 
                                                    "poolNumber": "'||i.POOL||'",
                                                    "ranchBlock": "'||i.RANCH||'", 
                                                    "directedPick": "N",
                                                    "batchType": "COMBINE_PARTIAL",
                                                    "batchVariety": "'||i.VARIETY||'", 
                                                    "packFgItem": "",
                                                    "psStatus": "",
                                                    "psProductionLines": "" 
                                                }
                                            ]
                                        }',
                        P_RESPONSE  =>V_RESPONSE,
                        P_STATUSCODE=>V_STATUSCODE
                        );
      IF V_STATUSCODE IN (200, 201) THEN
            V_WORK_ORDER_OUT_NO:=JSON_VALUE(V_RESPONSE,'$.WorkOrderNumber');
            V_WORK_ORDER_ID:=JSON_VALUE(V_RESPONSE,'$.WorkOrderId');
            
                         BEGIN                                

							APEX_COLLECTION.UPDATE_MEMBER_ATTRIBUTE (
                                    p_collection_name => 'INPUT_LPN_LOAD',
                                    p_seq => i.seq_id,
                                p_attr_number =>15,
                                p_attr_value  => V_WORK_ORDER_OUT_NO);
								
                            APEX_COLLECTION.UPDATE_MEMBER_ATTRIBUTE (
                                    p_collection_name => 'INPUT_LPN_LOAD',
                                    p_seq => i.seq_id,
                                p_attr_number =>16,
                                p_attr_value  => V_WORK_ORDER_ID);

											
                        END;  
                     
		END IF;*/
          INSERT INTO XXAPPS_LOC_BATCH_INPUT( 
                        ORG              	,
						FACILITY		 	,
						--BATCH_NO		 	,
						LOCATION		 	,
						LPN_NO			 	,
						RANCH			 	,
						ITEM				,
						ITEM_DESCRIPTION    ,
						ITEM_QTY            ,
						LOT                 ,
						UOM                 ,
						POOL                ,
						VARIETY             ,
						PUTAWAY_DATE_TIME   ,
						WORK_ORDER_ID 		,
						CREATED_ON			,
						CREATED_BY
                        )
                VALUES(
                      P_FACILITY_ORG,
                      i.FACILITY,
                      i.LOCATION,
                      i.LPN_NO,
                      i.RANCH,
					  i.ITEM,
					  i.ITEM_DESCRIPTION,
					  i.ITEM_QTY,
					  i.LOT,
					  i.UOM,
					  i.POOL,
					  i.VARIETY,
					  --TO_DATE(i.PUTAWAY_DATE_TIME,'YYYY-MM-DDTHH:MM:SS[.mmmmmm][+HH:MM]'),
                      i.PUTAWAY_DATE_TIME,
					  V_WORK_ORDER_ID,
					  TO_DATE(P_CREATED_ON,'DD/MON/YYYY HH:MI:SS PM'),
					  P_CREATED_BY
                );
				
				end loop;
end create_process_work_order;

procedure update_output_lpn_in_collection(P_FACILITY_ORG	IN	VARCHAR2,
                                    P_OUTPUT_LPN_SCAN IN VARCHAR2
                                    ) 
as
V_RESPONSE CLOB;
V_STATUSCODE NUMBER;
V_SYSDATE VARCHAR2(10):=TO_CHAR(SYSDATE,'YYYY-MM-DD');
V_WORK_ORDER_OUT_NO VARCHAR2(500);
V_WORK_ORDER_ID NUMBER;
V_OUTPUT_POOL VARCHAR2(200);
V_OUTPUT_BLOCK VARCHAR2(200);
V_VARIETY VARCHAR(300);
cursor c_seq  is
  SELECT
                     seq_id 
                    
                    FROM
                        apex_collections
                     where collection_name='INPUT_LPN_LOAD';
begin    
           BEGIN 
                      SELECT
                        c005 AS Pool INTO V_OUTPUT_POOL
                 FROM
                    apex_collections
                 where collection_name='INPUT_LPN_LOAD';
                 EXCEPTION WHEN NO_DATA_FOUND THEN V_OUTPUT_POOL:='';
                           WHEN OTHERS THEN V_OUTPUT_POOL:='MIXED';
             END;
             BEGIN 
                      SELECT
                        c006 AS Block INTO V_OUTPUT_BLOCK
                 FROM
                    apex_collections
                 where collection_name='INPUT_LPN_LOAD';
                 EXCEPTION WHEN NO_DATA_FOUND THEN V_OUTPUT_BLOCK:='';
                           WHEN OTHERS THEN V_OUTPUT_BLOCK:='GR99N';
             END;
--             BEGIN
--             SELECT VARIETY INTO V_VARIETY
--              FROM GEM.XX_ITEM_MASTER 
--               WHERE ITEM_NO=(SELECT distinct C002 AS ITEM 
--                                 FROM 
--                                    apex_collections
--                             where collection_name='INPUT_LPN_LOAD'
--                             );
--            EXCEPTION WHEN NO_DATA_FOUND THEN V_VARIETY:='NA';
--             END;

            for i in c_seq loop
                         BEGIN
                            APEX_COLLECTION.UPDATE_MEMBER_ATTRIBUTE (
                                    p_collection_name => 'INPUT_LPN_LOAD',
                                    p_seq => i.seq_id,
                                p_attr_number =>8,
                                p_attr_value  => P_OUTPUT_LPN_SCAN);
                            APEX_COLLECTION.UPDATE_MEMBER_ATTRIBUTE (
                                    p_collection_name => 'INPUT_LPN_LOAD',
                                    p_seq => i.seq_id,
                                p_attr_number =>9,
                                p_attr_value  => V_OUTPUT_POOL);   
                            APEX_COLLECTION.UPDATE_MEMBER_ATTRIBUTE (
                                    p_collection_name => 'INPUT_LPN_LOAD',
                                    p_seq => i.seq_id,
                                p_attr_number =>10,
                                p_attr_value  => V_OUTPUT_BLOCK);                                  
--                            APEX_COLLECTION.UPDATE_MEMBER_ATTRIBUTE (
--                                    p_collection_name => 'INPUT_LPN_LOAD',
--                                    p_seq => i.seq_id,
--                                p_attr_number =>11,
--                                p_attr_value  => V_WORK_ORDER_OUT_NO);   
--                                                        
--                         APEX_COLLECTION.UPDATE_MEMBER_ATTRIBUTE (
--                                                p_collection_name => 'INPUT_LPN_LOAD',
--                                                p_seq => i.seq_id,
--                                            p_attr_number =>2,
--                                            p_number_value => V_WORK_ORDER_ID);                                
                        END;    
             end loop; 
end update_output_lpn_in_collection;
    PROCEDURE CREATE_WORK_ORDER (P_BODY             CLOB,
                                 P_RESPONSE     OUT CLOB,
                                 P_STATUSCODE   OUT NUMBER)
    AS
        V_ENV_ROW       XXTWC_ENVIRONMENT_DETAILS%ROWTYPE;
        V_INPUT_URL     VARCHAR2 (200);
        G_WALLET_PATH   VARCHAR2 (200);
        G_WALLET_PASS   VARCHAR2 (200);
        V_STATUSCODE    NUMBER;
        L_OWNER         VARCHAR2 (200);
        L_NAME          VARCHAR2 (200);
        L_LINENO        VARCHAR2 (200);
        L_CALLER_T      VARCHAR2 (200);
    -- THIS PROCEDURE IS USED TO MAKE A WEBSERVICE CALL TO CREATE WORK ORDERS IN FUSION
    BEGIN
        XXTWC_APEX_WEBSERVICE_PKG.GET_AUTH_DETAILS ('SAAS', V_ENV_ROW);
        V_INPUT_URL := CONCAT (V_ENV_ROW.BASE_URL, 'processWorkOrders');
       P_RESPONSE :=
            APEX_WEB_SERVICE.MAKE_REST_REQUEST (
                P_URL           => V_INPUT_URL,
                P_HTTP_METHOD   => 'POST',
                P_USERNAME      => V_ENV_ROW.USER_NAME,
                P_PASSWORD      => V_ENV_ROW.PASSWORD,
                P_SCHEME        => 'Basic',
                P_BODY          => P_BODY,
                P_WALLET_PATH   => G_WALLET_PATH,
                P_WALLET_PWD    => G_WALLET_PASS);

        P_STATUSCODE := APEX_WEB_SERVICE.G_STATUS_CODE;

        OWA_UTIL.WHO_CALLED_ME (OWNER      => L_OWNER,
                                NAME       => L_NAME,
                                LINENO     => L_LINENO,
                                CALLER_T   => L_CALLER_T);

        XXTWC_APEX_WEBSERVICE_LOGGER (
            P_TXN_REFERENCE_ID   => NULL,
            P_TXN_TYPE           => 'XXAPPS_LOC_BATCH_INPUT_PKG.CREATE_WORK_ORDER',
            P_APP_NAME           =>    L_CALLER_T
                                    || ': '
                                    || L_OWNER
                                    || '.'
                                    || L_NAME,
            P_TXN_STATUS         => CASE
                                       WHEN P_STATUSCODE IN (200, 201)
                                       THEN
                                           'S'
                                       ELSE
                                           'E'
                                   END,
            P_REQUEST_URL        => V_INPUT_URL,
            P_REQUEST_PAYLOAD    => P_BODY,
            P_RESPONSE_PAYLOAD   => P_RESPONSE,
            P_HTTP_STATUS_CODE   => P_STATUSCODE);
    EXCEPTION
        WHEN OTHERS
        THEN
            PUT_SEVERE_LOG ('XXAPPS_LOC_BATCH_INPUT_PKG.CREATE_WORK_ORDER', SQLERRM);
    END;    
    PROCEDURE UPDATE_WORK_ORDER (P_BODY             CLOB,
                                 P_WORKORDER_ID    NUMBER,
                                 P_RESPONSE     OUT CLOB,
                                 P_STATUSCODE   OUT NUMBER)
    AS
        V_ENV_ROW       XXTWC_ENVIRONMENT_DETAILS%ROWTYPE;
        V_INPUT_URL     VARCHAR2 (200);
        G_WALLET_PATH   VARCHAR2 (200);
        G_WALLET_PASS   VARCHAR2 (200);
        V_STATUSCODE    NUMBER;
        L_OWNER         VARCHAR2 (200);
        L_NAME          VARCHAR2 (200);
        L_LINENO        VARCHAR2 (200);
        L_CALLER_T      VARCHAR2 (200);
    -- THIS PROCEDURE IS USED TO MAKE A WEBSERVICE CALL TO CREATE WORK ORDERS IN FUSION
    BEGIN
        XXTWC_APEX_WEBSERVICE_PKG.GET_AUTH_DETAILS ('SAAS', V_ENV_ROW);
        V_INPUT_URL := CONCAT (V_ENV_ROW.BASE_URL, 'processWorkOrders/'||P_WORKORDER_ID);
       P_RESPONSE :=
            APEX_WEB_SERVICE.MAKE_REST_REQUEST (
                P_URL           => V_INPUT_URL,
                P_HTTP_METHOD   => 'PATCH',
                P_USERNAME      => V_ENV_ROW.USER_NAME,
                P_PASSWORD      => V_ENV_ROW.PASSWORD,
                P_SCHEME        => 'Basic',
                P_BODY          => P_BODY,
                P_WALLET_PATH   => G_WALLET_PATH,
                P_WALLET_PWD    => G_WALLET_PASS);

        P_STATUSCODE := APEX_WEB_SERVICE.G_STATUS_CODE;

        OWA_UTIL.WHO_CALLED_ME (OWNER      => L_OWNER,
                                NAME       => L_NAME,
                                LINENO     => L_LINENO,
                                CALLER_T   => L_CALLER_T);

        XXTWC_APEX_WEBSERVICE_LOGGER (
            P_TXN_REFERENCE_ID   => NULL,
            P_TXN_TYPE           => 'XXAPPS_LOC_BATCH_INPUT_PKG.UPDATE_WORK_ORDER',
            P_APP_NAME           =>    L_CALLER_T
                                    || ': '
                                    || L_OWNER
                                    || '.'
                                    || L_NAME,
            P_TXN_STATUS         => CASE
                                       WHEN P_STATUSCODE IN (200, 201)
                                       THEN
                                           'S'
                                       ELSE
                                           'E'
                                   END,
            P_REQUEST_URL        => V_INPUT_URL,
            P_REQUEST_PAYLOAD    => P_BODY,
            P_RESPONSE_PAYLOAD   => P_RESPONSE,
            P_HTTP_STATUS_CODE   => P_STATUSCODE);
    EXCEPTION
        WHEN OTHERS
        THEN
            PUT_SEVERE_LOG ('XXAPPS_LOC_BATCH_INPUT_PKG.UPDATE_WORK_ORDER', SQLERRM);
    END UPDATE_WORK_ORDER;   
    PROCEDURE  PR_FUSION_PASS_TBL_AVAIL_QTY(
                        P_FACILITY_ORG	IN	VARCHAR2,
                        P_ITEM	    IN	VARCHAR2,
                        P_BATCH_NO	    IN	VARCHAR2,
                        P_REQUEST_QTY	IN	NUMBER,
                        P_FUSN_AVBLTY   OUT NUMBER)AS

         L_GET_INV_FUS_RESPONSE CLOB;
         L_STATUS_CODE          NUMBER;
         v_qty number;
    BEGIN

select NVL(SUM(PRIMARY_TRANSACTION_QUANTITY),0) into v_qty
  from fusion.INV_ONHAND_QUANTITIES_DETAIL OH,
       fusion.INV_ORG_PARAMETERS ORG,
       FUSION.EGP_SYSTEM_ITEMS_B itm
    where OH.LOT_NUMBER=P_BATCH_NO AND
          ORG.ORGANIZATION_ID=OH.ORGANIZATION_ID AND
          ORG.ORGANIZATION_CODE=P_FACILITY_ORG AND
          OH.SUBINVENTORY_CODE='AVAILABLE' and
          itm.ORGANIZATION_ID=ORG.ORGANIZATION_ID and
          itm.INVENTORY_ITEM_ID=oh.INVENTORY_ITEM_ID and
          itm.item_number=P_ITEM;
    if v_qty >=P_REQUEST_QTY then
    P_FUSN_AVBLTY:=v_qty;
    else
    P_FUSN_AVBLTY:=0;
    end if;
    END PR_FUSION_PASS_TBL_AVAIL_QTY;
FUNCTION FN_CHECK_OUTPUT_LPN_EXIST (
        P_FACILITY_ORG	IN	VARCHAR2,
        P_LPN	    IN	VARCHAR2
)RETURN BOOLEAN AS
    L_GET_LPN_RESPONSE CLOB;
    L_GET_INV_LPN_RESPONSE CLOB;
    L_STATUS_CODE NUMBER;
    L_FACILITY_ID NUMBER;
   BEGIN
    select id into L_FACILITY_ID from facility where code=P_FACILITY_ORG;

   XXTWC_APEX_WEBSERVICE_PKG.
           WMS_GET_LPN_DETAILS(
                                   P_LPN_NUMBER        =>P_LPN,
                                   P_WMS_FACILITY_ID   =>L_FACILITY_ID,
                                   P_RESPONSE          =>L_GET_LPN_RESPONSE,
                                   P_STATUSCODE        =>L_STATUS_CODE
                             );
 IF L_STATUS_CODE IN (200,201) THEN
     RETURN FALSE;
     ELSE
     RETURN TRUE;
 END IF;
END FN_CHECK_OUTPUT_LPN_EXIST;    
PROCEDURE PR_PRINT_PALLET_TAG(
    p_printer_name VARCHAR2,
    p_org_code VARCHAR2,
    p_item_number VARCHAR2,
    p_lpn VARCHAR2,
    p_batch_number VARCHAR2,
    p_primary_qty NUMBER
) AS

v_label_text VARCHAR2(32000);
v_return_status VARCHAR2(32000);
v_return_message VARCHAR2(32000);
v_print_status varchar2(500);
vprint_msg varchar2(500);
V_PRINTER_ID NUMBER;
BEGIN

xxics.XXTWC_MFG_RECEIPT_PKG.generate_pallet_label_text (
        p_printer_name         =>p_printer_name ,
        p_wms_enabled          =>'',
        p_org_code             =>p_org_code,
        p_item_number          =>p_item_number,
        p_reprint_flag         =>'',
        p_lpn                  =>p_lpn,
        p_batch_number         =>p_batch_number,
        p_pool_number          =>'',
        p_ranch_block_number   =>'',
        p_variety              =>'',
        p_location             =>'',
        p_prod_line            =>'',
        p_tag                  =>'',
        p_primary_qty          =>p_primary_qty,
        p_secondary_qty        =>'',
        x_label_text           =>v_label_text,
        x_return_status        =>v_return_status,
        x_return_message       => V_return_message);
  SELECT    ID INTO V_PRINTER_ID    FROM XXAPPS_TWC_PRINTER_CONFIG WHERE PRINTER_NAME=p_printer_name;
  send_to_printer (
   p_printer_id=>V_PRINTER_ID,
   p_id =>null,
   p_text =>v_label_text ,  
   p_status =>v_print_status,
   P_message =>vprint_msg);
--        DBMS_OUTPUT.PUT_LINE('LABLE=>'||v_label_text);
--        DBMS_OUTPUT.PUT_LINE('RETURN STATUS=>'||v_return_status);
--        DBMS_OUTPUT.PUT_LINE('RETURN MESSAGE=>'||V_return_message);
EXCEPTION WHEN OTHERS THEN
PUT_SEVERE_LOG ('XXAPPS_LOC_BATCH_INPUT_PKG.PR_PRINT_PALLET_TAG', SQLERRM);
END;
procedure send_to_printer (
   p_printer_id in number ,
   p_id in number,
   p_text in varchar2 ,  
   p_status out varchar2,
   P_message out varchar2)
   
   is
    CONN         UTL_TCP.CONNECTION;
    RETVAL       BINARY_INTEGER;
    L_RESPONSE   VARCHAR2(1000) := '';
    L_STATUS  VARCHAR2(400);
    L_MESSSAGE VARCHAR2(4000);
    L_ERROR VARCHAR2(4000);
    L_PRINTER_NAME VARCHAR2(200);
    L_PRINTER_IP VARCHAR2(30);
    L_PORT number;
    L_APPLICATION_ID NUMBER;
    L_FUNCTION VARCHAR2(300);
    L_LOCATION VARCHAR2(100);
    V_COUNT number;
    NO_PRINTER EXCEPTION;
   
     
BEGIN

     SELECT count(*) into v_count from XXAPPS_TWC_PRINTER_CONFIG where id=p_printer_id;
     if(v_count=0) then
     L_STATUS:='Error';
    RAISE NO_PRINTER;
    else
    SELECT PRINTER_NAME,IP_ADDRESS,PORT into L_PRINTER_NAME,L_PRINTER_IP,L_PORT from XXAPPS_TWC_PRINTER_CONFIG where id=p_printer_id;
    end if;

  -- REMOVED BELOW SQL due to one printer not for a application
   --SELECT APPLICATION_ID,FUNCTION,LOCATION into L_APPLICATION_ID,L_FUNCTION,L_LOCATION from XXAPPS_TWC_PRINTER_APPLICATION where id=p_id;

    L_STATUS:='Failed';
    CONN := UTL_TCP.OPEN_CONNECTION(
        REMOTE_HOST   => L_PRINTER_IP,
        REMOTE_PORT   => L_PORT,
        TX_TIMEOUT    => 10
    );
    L_STATUS:='Success';
   -- 2) check whether able to connect to printer or not, if not then show the error message
   DBMS_OUTPUT.PUT_LINE(L_STATUS);

    --WRITE TO SOCKET
    RETVAL := UTL_TCP.WRITE_LINE(CONN,P_TEXT);
   UTL_TCP.FLUSH(CONN);

    UTL_TCP.CLOSE_CONNECTION(CONN);
    L_STATUS:='Success';
    -- Printing Success Log
                            insert into XXAPPS_TWC_PRINTER_LOG
                            (PRINTER_ID,APPLICATION_ID,FUNCTION,LOCATION,STATUS,PRINT_DATE,ERROR_MESSAGE,REQUESTOR,PRINT_TEXT)
                            values(p_printer_id,L_APPLICATION_ID,L_FUNCTION,L_LOCATION,L_STATUS,sysdate,'Success printing',v('app_user'),P_TEXT);
                            commit;
  P_STATUS:='Success';
  --P_message:='';

--- When No Printer Name is Specified
EXCEPTION
WHEN NO_PRINTER THEN
PUT_SEVERE_LOG ('XXAPPS_LOC_BATCH_INPUT_PKG.send_to_printer', SQLERRM);
L_STATUS:='Error';
L_ERROR:='Printer'||L_PRINTER_NAME||' With IP '||L_PRINTER_IP||' Not Available';
 P_STATUS:='Error';
 --P_message:='';
                         insert into XXAPPS_TWC_PRINTER_LOG
                        (PRINTER_ID,APPLICATION_ID,FUNCTION,LOCATION,STATUS,PRINT_DATE,ERROR_MESSAGE,REQUESTOR,PRINT_TEXT)
                        values(p_printer_id,L_APPLICATION_ID,L_FUNCTION,L_LOCATION,L_STATUS,sysdate,L_ERROR,v('app_user'),P_TEXT);
                        commit;
  
     RAISE_APPLICATION_ERROR(-20103,'Printer Name not Specified'||SQLERRM);
                        UTL_TCP.CLOSE_CONNECTION(CONN);
    WHEN OTHERS THEN
      PUT_SEVERE_LOG ('XXAPPS_LOC_BATCH_INPUT_PKG.send_to_printer', SQLERRM);
L_ERROR:='Printer '||L_PRINTER_NAME||' With IP '||L_PRINTER_IP||' . Error - ' ||SQLERRM;
P_STATUS:='Error';
     --P_message:='';
                        insert into XXAPPS_TWC_PRINTER_LOG
                        (PRINTER_ID,APPLICATION_ID,FUNCTION,LOCATION,STATUS,PRINT_DATE,ERROR_MESSAGE,REQUESTOR,PRINT_TEXT)
                        values(p_printer_id,L_APPLICATION_ID,L_FUNCTION,L_LOCATION,L_STATUS,sysdate,'Error printing  : '||substr(L_ERROR,1,1000),v('app_user'),P_TEXT);
                        commit;
   -- DBMS_OUTPUT.PUT_LINE('Error printing  : ' || SQLERRM);
     RAISE_APPLICATION_ERROR(-20101,'Cannot Connect to the desired   '||L_ERROR);
                         UTL_TCP.CLOSE_CONNECTION(CONN);
                         
   
   end;


end XXAPPS_LOC_BATCH_INPUT_PKG;
/