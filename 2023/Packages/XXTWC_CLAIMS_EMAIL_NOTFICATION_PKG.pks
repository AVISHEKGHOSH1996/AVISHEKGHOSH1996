/****************************************************************************************************
	Object Type: 	Package
	Name       :    XXTWC_CLAIMS_EMAIL_NOTFICATION_PKG
	Created by:		Trinamix
	Created On:		06/01/2023
	Description:	Package for Claims Email Notification
	Modified On:	06/12/2023
	Reason:		    Modified for Email
****************************************************************************************************/
    
--------------------------------------------------------
--  DDL for Package XXTWC_CLAIMS_EMAIL_NOTFICATION_PKG
--------------------------------------------------------
create or replace PACKAGE  XXTWC_CLAIMS_EMAIL_NOTFICATION_PKG
IS
PROCEDURE SEND_EMAIL_FOR_SUBMIT (
	P_CLAIM_TYPES 		VARCHAR2,
	P_CLAIM_ID          NUMBER
);



	PROCEDURE SEND_EMAIL_FOR_DEPARTMENTAL_HIERARCHY_APPROVAL (
	P_CLAIM_ID          NUMBER,
	P_CLAIM_DATE        DATE
);

    PROCEDURE SEND_EMAIL_FOR_REJECTED (
	P_CLAIM_ID          NUMBER,
	P_CLAIM_DATE        DATE,
    P_COMMENTS          VARCHAR2
);

	PROCEDURE SEND_EMAIL_FOR_FINANCE_APPROVAL (
	P_CLAIM_ID          NUMBER,
	P_CLAIM_DATE        DATE
);

	PROCEDURE SEND_EMAIL_FOR_CLAIM_OWNER_APPROVAL (
	P_CLAIM_ID          NUMBER,
	P_CLAIM_DATE        DATE
);

PROCEDURE SEND_EMAIL_FOR_SUBMIT_A_MINUS (
	P_CLAIM_TYPES 		VARCHAR2,
	P_CLAIM_ID          NUMBER
);

PROCEDURE SEND_EMAIL_FOR_FORGOT_PASSWORD (
	P_EMAIL_ID          VARCHAR2
);

PROCEDURE SEND_EMAIL_FOR_DRAFT_CLAIM (
	P_CLAIM_ID          NUMBER
);

PROCEDURE SEND_EMAIL_REMINDER (
	P_CLAIM_ID          NUMBER,
	P_EMAIL_ID          VARCHAR2
);
END XXTWC_CLAIMS_EMAIL_NOTFICATION_PKG;

/