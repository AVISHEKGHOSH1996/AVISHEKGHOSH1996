/****************************************************************************************************
	Object Type: 	Package Body
	Name       :    XXTWC_CLAIMS_VALIDATION_PKG
	Created by:		Trinamix
	Created On:		06/01/2023
	Description:	Package spec and body for XXTWC_CLAIMS_VALIDATION_PKG
	Modified On:	
	Reason:		    
****************************************************************************************************/
--------------------------------------------------------
--  DDL for Package Body XXTWC_CLAIMS_VALIDATION_PKG
--------------------------------------------------------
create or replace PACKAGE BODY xxtwc_claims_validation_pkg AS

    PROCEDURE claim_submit (
        p_claim_id  IN NUMBER,
        p_status    OUT VARCHAR2,
        p_error_msg OUT VARCHAR2
    ) IS
        lv_type          VARCHAR2(30);
        lv_claim_line_no NUMBER;
    BEGIN
        SELECT
            COUNT(1)
        INTO lv_claim_line_no
        FROM
            xxtwc_claims_lines cl
        WHERE
            claim_id = p_claim_id;

        IF lv_claim_line_no = 0 THEN
            p_status := '0';
            p_error_msg := 'Claim should have lines';
        ELSE
            p_status := '1';
            p_error_msg := '';
        END IF;

    END claim_submit;
--------------------------------------------------------------------------------
    FUNCTION validate_claim_total RETURN VARCHAR2 IS
    --
        CURSOR claim_total IS
        SELECT
            SUM(to_number(c022)),
            SUM(to_number(c021))
        FROM
            apex_collections
        WHERE
            collection_name = 'XXTWC_CLAIMS_LINES'; 
    --
        lv_claim_qty NUMBER;
        lv_amount    NUMBER;
    BEGIN
	    --
        OPEN claim_total;
        FETCH claim_total INTO
            lv_claim_qty,
            lv_amount;
        CLOSE claim_total;
		    --
        IF lv_claim_qty = 0 THEN
            RETURN 'Total Claim Qty should not be 0.';
        ELSIF NVL(lv_amount,0) <= 0 THEN
            RETURN 'Claim amount should not be 0 or less then 0.';
        ELSE
            RETURN NULL;
        END IF;

    END validate_claim_total;
--------------------------------------------------------------------------------
    FUNCTION validate_reason_code RETURN VARCHAR2 IS
    lv_reason varchar2(1000);
    BEGIN
        FOR i IN (
            SELECT
                seq_id,
                c028            AS reason_code,
                to_number(c022) AS claim_qty
            FROM
                apex_collections
            WHERE
                collection_name = 'XXTWC_CLAIMS_LINES'
        ) LOOP
           -- lv_reason := lv_reason ||nvl(i.reason_code,'*')|| i.claim_qty;
           IF
                nvl(i.reason_code,'*') = '*' 
                AND nvl(i.claim_qty, 0) > 0
            THEN
                lv_reason := 'Reason Code must have some value.';
            END IF; 
        END LOOP;
        return lv_reason;
    END validate_reason_code;
--------------------------------------------------------------------------------
    FUNCTION validate_claim_reason_code(
        p_claim_id IN NUMBER
    )RETURN VARCHAR2 IS
    lv_reason varchar2(1000);
    lv_cnt number;
    lv_line varchar2(100);
    BEGIN
        FOR i IN (
            SELECT
                rownum,
                CLAIM_REASON_CODE AS reason_code,
                CLAIM_QTY         AS claim_qty
            FROM
                xxtwc_claims_lines
            WHERE
                claim_id = p_claim_id
        ) LOOP
           IF
                nvl(i.reason_code,'*') = '*' 
                AND nvl(i.claim_qty, 0) > 0
            THEN
                lv_line := lv_line || i.rownum || ',';
                lv_reason := 'Reason Code must have some value. Check Line :- ';
            END IF;
        END LOOP;
        
        /* Below Vaidation is for reason code should be in same department*/
        IF lv_reason is null then
            SELECT
                COUNT(DISTINCT tag)
            INTO lv_cnt
            FROM
                fusion.fnd_lookup_values a
            WHERE
                    lookup_type = 'DOO_RETURN_REASON'
                AND language = 'US'
                AND tag IN ( 'CARRIER', 'OPERATIONS', 'QUALITY', 'SALES' )
                AND enabled_flag = 'Y'
                AND lookup_code IN (
                    SELECT
                        CLAIM_REASON_CODE
                    FROM
                        xxtwc_claims_lines
                    WHERE
                        claim_id = p_claim_id
                );
            IF nvl(lv_cnt, 0) > 1 THEN
                lv_reason := 'Please select reason code belonging to same department';
            ELSE
                lv_reason := NULL;
            END IF;
        ELSE
            lv_reason := lv_reason ||lv_line;
        END IF;
        return lv_reason;
    END validate_claim_reason_code;
--------------------------------------------------------------------------------
    FUNCTION validate_claim_qty_against_request_qty (
        p_claim_qty          IN NUMBER,
        p_requested_quantity IN NUMBER,
        p_claim_type         IN VARCHAR2
    ) RETURN VARCHAR2 IS
    BEGIN
        IF p_claim_type not in ('UNREFRENCE_CLAIM','PRICE_ADJ') THEN
            IF p_claim_qty > p_requested_quantity THEN
                RETURN 'Claim Qty cannot be more than Shipped Qty.';
            ELSE
                RETURN NULL;
            END IF;
        ELSE
            RETURN NULL;
        END IF;
    END validate_claim_qty_against_request_qty;
--------------------------------------------------------------------------------
    FUNCTION validate_claim_qty_against_returnable_qty (
        p_claim_type IN VARCHAR2
    ) RETURN VARCHAR2 IS
        v_result VARCHAR2(100); -- Variable to store the result
    BEGIN
        IF p_claim_type not in ('UNREFRENCE_CLAIM','PRICE_ADJ') THEN
            FOR i IN (
                SELECT
                    seq_id,
                    to_number(c022) AS claim_qty,
                    to_number(c033) AS returnable_qty
                FROM
                    apex_collections
                WHERE
                    collection_name = 'XXTWC_CLAIMS_LINES'
            ) LOOP
                IF nvl(i.claim_qty, 0) > nvl(i.returnable_qty, 0) THEN
                    v_result := 'Claim Qty cannot be more than Returnable Qty.';
                    EXIT; -- Exit the loop if the condition is met
                END IF;
            END LOOP;
        ELSE
            v_result := NULL;
        END IF;

        RETURN v_result; -- Return the result
    END validate_claim_qty_against_returnable_qty;
--------------------------------------------------------------------------------
    FUNCTION validate_document_catagory (
        p_claim_type   IN VARCHAR2,
        p_doc_catagory IN VARCHAR2
    ) RETURN VARCHAR2 IS
    BEGIN
        IF p_claim_type <> 'UNREFRENCE_CLAIM' THEN
            IF p_doc_catagory IS NULL THEN
                RETURN 'Document Category must have some value.';
            ELSE
                RETURN NULL;
            END IF;
        ELSE
            RETURN NULL;
        END IF;
    END validate_document_catagory;
--------------------------------------------------------------------------------
    FUNCTION validation_reason_deparment RETURN VARCHAR2 IS
        lv_cnt NUMBER := 0;
    BEGIN
        SELECT
            COUNT(DISTINCT tag)
        INTO lv_cnt
        FROM
            fusion.fnd_lookup_values a
        WHERE
                lookup_type = 'DOO_RETURN_REASON'
            AND language = 'US'
            AND tag IN ( 'CARRIER', 'OPERATIONS', 'QUALITY', 'SALES' )
            AND enabled_flag = 'Y'
            AND lookup_code IN (
                SELECT
                    c028
                FROM
                    apex_collections
                WHERE
                    collection_name = 'XXTWC_CLAIMS_LINES'
            );

        IF nvl(lv_cnt, 0) > 1 THEN
            RETURN 'Please select reason code belonging to same department';
        ELSE
            RETURN NULL;
        END IF;

    END validation_reason_deparment;
--------------------------------------------------------------------------------
    FUNCTION validation_freight_reason_deparment RETURN VARCHAR2 IS
        lv_cnt NUMBER := 0;
    BEGIN
        SELECT
            COUNT(DISTINCT tag)
        INTO lv_cnt
        FROM
            fusion.fnd_lookup_values a
        WHERE
                lookup_type = 'DOO_RETURN_REASON'
            AND language = 'US'
            AND tag IN ( 'CARRIER', 'OPERATIONS', 'QUALITY', 'SALES' )
            AND enabled_flag = 'Y'
            AND lookup_code IN (
                SELECT
                    c028
                FROM
                    apex_collections
                WHERE
                    collection_name = 'XXTWC_FREIGHT_CLAIMS_LINES'
            );

        IF nvl(lv_cnt, 0) > 1 THEN
            RETURN 'Please select reason code belonging to same department';
        ELSE
            RETURN NULL;
        END IF;

    END validation_freight_reason_deparment;
--------------------------------------------------------------------------------
    FUNCTION validate_document_note (
        p_doc_cat IN VARCHAR2,
        p_note    IN VARCHAR2
    ) RETURN VARCHAR2 IS
        lv_type VARCHAR2(100);
    BEGIN
        BEGIN
            SELECT
                attribute1
            INTO lv_type
            FROM
                xxtwc_claims_lookups
            WHERE
                    lookup_type = 'DOCUMENT_CATEGORY'
                AND lookup_name = p_doc_cat;

        EXCEPTION
            WHEN OTHERS THEN
                lv_type := NULL;
        END;

        IF
            lv_type = 'NOTE'
            AND p_note IS NULL
        THEN
            RETURN 'Note must have some value.';
        ELSE
            RETURN NULL;
        END IF;

    END;
--------------------------------------------------------------------------------
    FUNCTION validate_document_file (
        p_doc_cat IN VARCHAR2,
        p_file    IN VARCHAR2
    ) RETURN VARCHAR2 IS
        lv_type VARCHAR2(100);
    BEGIN
        BEGIN
            SELECT
                attribute1
            INTO lv_type
            FROM
                xxtwc_claims_lookups
            WHERE
                    lookup_type = 'DOCUMENT_CATEGORY'
                AND lookup_name = p_doc_cat;

        EXCEPTION
            WHEN OTHERS THEN
                lv_type := NULL;
        END;

        IF
            lv_type = 'FILE'
            AND p_file IS NULL
        THEN
            RETURN 'Please Select a File for Upload.';
        ELSE
            RETURN NULL;
        END IF;

    END;
--------------------------------------------------------------------------------
    FUNCTION validate_attachement(
        p_claim_type IN VARCHAR2
    ) RETURN VARCHAR2 IS
    lv_cnt NUMBER;
    BEGIN
        SELECT count(*) INTO lv_cnt FROM apex_collections WHERE collection_name = 'XXTWC_CLAIMS_DOC' AND c003 in ('DONATION_NOTE','DONATION_SLIP');
        IF NVL(lv_cnt,0) = 0 THEN
            IF p_claim_type = 'REJECT_DUMPED' THEN
                RETURN 'Mandate Attachment required for Donation transactions( Donation Slip/ Note)';
            ELSE
                RETURN NULL;
            END IF;
        ELSE
            RETURN NULL;
        END IF;
    END;
--------------------------------------------------------------------------------
    FUNCTION validate_picture_document_cr RETURN VARCHAR2
    IS
    lv_department VARCHAR2(100);
    lv_cnt NUMBER;
    BEGIN
        BEGIN
                SELECT
                    DISTINCT tag
                INTO lv_department
                FROM
                    fusion.fnd_lookup_values a
                WHERE
                    lookup_type = 'DOO_RETURN_REASON'
                    AND language = 'US'
                    AND tag IN ( 'CARRIER', 'OPERATIONS', 'QUALITY', 'SALES' )
                    AND enabled_flag = 'Y'
                    AND lookup_code IN (
                        SELECT
                            c028
                        FROM
                            apex_collections
                        WHERE collection_name = 'XXTWC_CLAIMS_LINES'
                        );
            EXCEPTION
                when others then
                    lv_department := null;
            END;
            SELECT COUNT(*) INTO lv_cnt FROM apex_collections where collection_name='XXTWC_CLAIMS_DOC' AND c003 = 'PICTURE';
        IF lv_department IN ( 'CARRIER', 'OPERATIONS', 'QUALITY') THEN
            IF NVL(lv_cnt,0) = 0 THEN
                RETURN 'At lease 1 picture document required';
            ELSE
                RETURN NULL;
            END IF;
        ELSE
            RETURN NULL;
        END IF;
    END;
---------------------------------------------------------------------------------
    FUNCTION validate_picture_document_ud(
        p_claim_id IN NUMBER
    )
    RETURN VARCHAR2
    IS
    lv_department VARCHAR2(100);
    lv_cnt NUMBER;
    BEGIN
        BEGIN
                SELECT
                    DISTINCT tag
                INTO lv_department
                FROM
                    fusion.fnd_lookup_values a
                WHERE
                    lookup_type = 'DOO_RETURN_REASON'
                    AND language = 'US'
                    AND tag IN ( 'CARRIER', 'OPERATIONS', 'QUALITY', 'SALES' )
                    AND enabled_flag = 'Y'
                    AND lookup_code IN (
                        SELECT
                            CLAIM_REASON_CODE
                        FROM
                            xxtwc_claims_lines
                        WHERE claim_id = p_claim_id
                        );
            EXCEPTION
                when others then
                    lv_department := null;
            END;
            SELECT COUNT(*) INTO lv_cnt FROM xxtwc_claims_documents where claim_id=p_claim_id AND document_category in('FILE','PICTURE');
        IF lv_department IN ( 'CARRIER', 'OPERATIONS', 'QUALITY') THEN
            IF NVL(lv_cnt,0) = 0 THEN
                RETURN 'At least 1 File attachment containing pictures is mandatory.';
            ELSE
                RETURN NULL;
            END IF;
        ELSE
            RETURN NULL;
        END IF;
    END;
---------------------------------------------------------------------------------
    FUNCTION validate_document_fot_dump(
        p_claim_id in number,
        p_claim_type in varchar2
    ) return VARCHAR2 
    IS
    lv_cnt number;
    lv_return varchar2(250);
    BEGIN
    IF p_claim_type = 'REJECT_DUMPED' then
        IF p_claim_id is null then
            SELECT COUNT(*) INTO lv_cnt FROM apex_collections where collection_name='XXTWC_CLAIMS_DOC' AND c003 in ('DONATION_SLIP','DONATION_NOTE'); 
            IF NVL(lv_cnt,0) = 0 THEN
                lv_return:= 'Mandate Attachment required for Donation transactions( Donation Slip/ Note)';
            ELSE
                lv_return:= NULL;
            END IF; 
        else 
            SELECT COUNT(*) INTO lv_cnt FROM xxtwc_claims_documents where claim_id=p_claim_id AND document_category in ('DONATION_SLIP','DONATION_NOTE'); 
            IF NVL(lv_cnt,0) = 0 THEN
                lv_return:= 'Mandate Attachment required for Donation transactions( Donation Slip/ Note)';
            ELSE
                lv_return := NULL;
            END IF; 
        END IF;
    END IF;
    RETURN lv_return; 
    END;
END xxtwc_claims_validation_pkg;
/