create or replace PACKAGE XXTWC_FULCRUM_PAAS_SYNC_PKG
    /*
    +===========================================================================================+
    |  Copyright (c) 2017 The Wonderful Company     |         All rights reserved              |
    +===========================================================================================+
    |                                                                                          |
    |  FILENAME : XXTWC_FULCRUM_PAAS_SYNC_PKG.pks                                            |
    |                                                                                          |
    |  DESCRIPTION : This package is used to sync Fulcrum Apps data to PAAS tables              |
    |                                                                                          |
    |                                          |
    |  HISTORY                                                                                 |
    |                                                                                          |
    | Version    Date         Author                Description                                 |
    | =======    ==========   =================     ============================================+
    | 1.0        19-Feb-2024  Mahender Podavula     Initial version               |
	| 1.1        22-Apr-2024  Raghuveer             Modification to base the logic on APP ID    |
    | 1.2        23-Apr-2024  Subhojit Sett         Added function GET_MEDIA_URL                |
    +===========================================================================================+
    */
AS
    g_module  VARCHAR2(100) := 'FULCRUM';
    g_package VARCHAR2(250) := 'XXTWC_FULCRUM_PAAS_SYNC_PKG';
PROCEDURE PROCESS_FORM_STRUCTURE
                                (
                                    p_ics_run_id        IN     VARCHAR2
                                  , p_business_unit     IN     VARCHAR2
                                  , p_app_name          IN     VARCHAR2
								  , p_app_id            IN     VARCHAR2          --Added version 1.1
                                  , x_form_oic_id       OUT    VARCHAR2 
                                  , x_form_key          OUT    VARCHAR2 
                                  , x_interface_run_id  OUT    VARCHAR2
                                  , x_status            OUT    VARCHAR2
                                  , x_error_msg         OUT    VARCHAR2
                                );
PROCEDURE ASSIGN_LEVEL
                      (
                          p_ics_run_id    	 IN     VARCHAR2
                        , p_business_unit 	 IN     VARCHAR2
                        , p_app_name      	 IN     VARCHAR2
						, p_app_id                    IN      VARCHAR2         --Added version 1.1
                        , x_interface_run_id OUT    VARCHAR2
                        , x_status           OUT    VARCHAR2
                        , x_error_msg        OUT    VARCHAR2
                      );

PROCEDURE LOAD_FORM_DATA
                        (
                            p_ics_run_id       			IN 		VARCHAR2
                          , p_form_oic_id      			IN 		VARCHAR2
                          , p_form_key         			IN 		VARCHAR2 
                          , p_business_unit    			IN 		VARCHAR2
                          , p_app_name         			IN 		VARCHAR2
						  , p_app_id                    IN      VARCHAR2         --Added version 1.1
                          , p_interface_run_id 			IN 		VARCHAR2
						  , p_date_updated_since		IN 		VARCHAR2
--                          , x_status                    OUT     VARCHAR2
--                          , x_error_msg                 OUT     VARCHAR2
                        );

PROCEDURE JOB_SCHEDULER_LOAD_FORM_DATA
                                      (
                                          p_ics_run_id         IN VARCHAR2
                                        , p_form_oic_id        IN VARCHAR2
                                        , p_form_key           IN VARCHAR2
                                        , p_business_unit      IN VARCHAR2
                                        , p_app_name           IN VARCHAR2
										, p_app_id                    IN      VARCHAR2         --Added version 1.1
                                        , p_interface_run_id   IN VARCHAR2
                                        , p_date_updated_since IN VARCHAR2
                                        , x_status OUT            VARCHAR2
                                        , x_error_msg OUT         VARCHAR2
                                      );

PROCEDURE LOAD_CONFIG_DATA
                        (
                            p_ics_run_id       IN       VARCHAR2
                          , p_business_unit    IN       VARCHAR2
                          , p_app_name         IN       VARCHAR2
						  , p_app_id                    IN      VARCHAR2         --Added version 1.1
                          , p_interface_run_id IN       VARCHAR2
                          , x_status           OUT      VARCHAR2
                          , x_error_msg        OUT      VARCHAR2
                        );
                        
FUNCTION GET_MEDIA_URL (
        P_MEDIA_ID 				IN VARCHAR2,
		P_FIELD_TYPE 			IN VARCHAR2,
		P_INTERFACE_RUN_ID  	IN VARCHAR2,
		P_FORM_OIC_ID          	IN VARCHAR2,
		P_ICS_RUN_ID			IN VARCHAR2	
    ) RETURN VARCHAR2;                                               
END XXTWC_FULCRUM_PAAS_SYNC_PKG;
