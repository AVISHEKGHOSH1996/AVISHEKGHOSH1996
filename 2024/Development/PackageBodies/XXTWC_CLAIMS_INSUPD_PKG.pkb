/****************************************************************************************************
	Object Type: 	Package Body
	Name       :    XXTWC_CLAIMS_INSUPD_PKG
	Created by:		Trinamix
	Created On:		06/01/2023
	Description:	Package Body XXTWC_CLAIMS_INSUPD_PKG
	Modified On:	
	Reason:		    
****************************************************************************************************/

--------------------------------------------------------
--  DDL for Package Body XXTWC_CLAIMS_INSUPD_PKG
--------------------------------------------------------
create or replace PACKAGE BODY  xxtwc_claims_insupd_pkg AS

    FUNCTION gen_claim_number RETURN VARCHAR2 IS
        lv_gen_number   VARCHAR2(200);
        lv_claim_number VARCHAR2(200);
        lv_claim_prefix VARCHAR2(200) := 'CL';
        lv_seq          NUMBER;
    BEGIN/*
        SELECT
            xxtwc_claims_gen_number_seq.NEXTVAL
        INTO lv_seq
        FROM
            dual; */
        SELECT
            MAX(claim_number)
        INTO lv_claim_number
        FROM
            xxtwc_claims_headers
            where substr(claim_number,1,4) != 'CL_0';

        lv_seq := NVL(to_number(ltrim(substr(lv_claim_number, '3'), '0')),0) + 1;

        lv_gen_number := lv_claim_prefix
                         || lpad(lv_seq, 6, '0');
        RETURN upper(lv_gen_number);
    EXCEPTION
        WHEN OTHERS THEN
            RETURN 'INVALID CLAIM NUMBER';
    END;
--------------------------------------------------------------------------------
PROCEDURE get_order_detail (
        p_order_number             IN VARCHAR2,
        p_org_id                   IN VARCHAR2,
        p_claim_type               IN VARCHAR2,
        --p_claim_id                 IN NUMBER,
        --p_claim_dtl_id             IN NUMBER,
        p_header_id                OUT VARCHAR2,
        p_xxtwc_claims_headers_rec OUT xxtwc_claims_headers%rowtype
    ) IS
    lv_credit_price number;
    lv_new_price number;
    lv_rebill_price number;
    lv_count NUMBER;
    BEGIN
        BEGIN
            SELECT
                header_id
            INTO p_header_id
            FROM
                xxtwc_claims_order_headers_v
            WHERE
                    org_id = p_org_id
                AND order_number = p_order_number;

        EXCEPTION
            WHEN OTHERS THEN
                p_header_id := NULL;
                apex_error.add_error(p_message => 'Order Not Found.', p_display_location => apex_error.c_inline_in_notification);
        END;

        FOR e_rec IN (
            SELECT
                *
            FROM
                 xxtwc_claims_order_headers_v
            WHERE
                header_id = p_header_id
        ) LOOP
            p_xxtwc_claims_headers_rec.org_id := e_rec.org_id;
            p_xxtwc_claims_headers_rec.bu_name := e_rec.org_name;
            p_xxtwc_claims_headers_rec.sold_to_customer_name := e_rec.sold_to_customer_name;
            p_xxtwc_claims_headers_rec.sold_to_customer_id := e_rec.sold_to_customer_id;
            p_xxtwc_claims_headers_rec.ship_to_customer_name := e_rec.ship_to_customer_name;
            p_xxtwc_claims_headers_rec.ship_to_site := e_rec.ship_to_site;
            p_xxtwc_claims_headers_rec.ship_to_customer_id := e_rec.ship_to_party_id;
            p_xxtwc_claims_headers_rec.ship_to_address1 := e_rec.ship_to_address1;
            p_xxtwc_claims_headers_rec.ship_to_address2 := e_rec.ship_to_address2;
            p_xxtwc_claims_headers_rec.ship_to_address3 := e_rec.ship_to_address3;
            p_xxtwc_claims_headers_rec.ship_to_city := e_rec.ship_to_city;
            p_xxtwc_claims_headers_rec.ship_to_state := e_rec.ship_to_state;
            p_xxtwc_claims_headers_rec.ship_to_postal_code := e_rec.ship_to_postal_code;
            p_xxtwc_claims_headers_rec.ship_to_country := e_rec.ship_to_country;
            p_xxtwc_claims_headers_rec.bill_to_customer_name := e_rec.bill_to_customer_name;
            p_xxtwc_claims_headers_rec.bill_to_address1 := e_rec.bill_to_address1;
            p_xxtwc_claims_headers_rec.bill_to_address2 := e_rec.bill_to_address2;
            p_xxtwc_claims_headers_rec.bill_to_address3 := e_rec.bill_to_address3;
            p_xxtwc_claims_headers_rec.bill_to_city := e_rec.bill_to_city;
            p_xxtwc_claims_headers_rec.bill_to_state := e_rec.bill_to_state;
            p_xxtwc_claims_headers_rec.bill_to_postal_code := e_rec.bill_to_postal_code;
            p_xxtwc_claims_headers_rec.bill_to_country := e_rec.bill_to_country;
            p_xxtwc_claims_headers_rec.bill_to_customer_id := e_rec.bill_to_customer_id;
            p_xxtwc_claims_headers_rec.po_number := e_rec.customer_po_number;
            p_xxtwc_claims_headers_rec.order_number := e_rec.order_number;
            p_xxtwc_claims_headers_rec.order_date := e_rec.ordered_date;
            p_xxtwc_claims_headers_rec.attribute1 := e_rec.ship_to_address; /* Used for ship to address */
            p_xxtwc_claims_headers_rec.attribute2 := e_rec.bill_to_address; /* Used for ship to address */
            p_xxtwc_claims_headers_rec.warehouse_name := e_rec.warehouse_name;
            p_xxtwc_claims_headers_rec.warehouse_code := e_rec.warehouse_code;
            p_xxtwc_claims_headers_rec.header_id := e_rec.header_id;
            p_xxtwc_claims_headers_rec.claim_currency_code := e_rec.transactional_currency_code;
            p_xxtwc_claims_headers_rec.sales_person_name := e_rec.sales_person_name;
            p_xxtwc_claims_headers_rec.sales_person_id := e_rec.salesperson_id;
            p_xxtwc_claims_headers_rec.orig_order_value := e_rec.order_value;
        END LOOP;

        apex_collection.create_or_truncate_collection('XXTWC_CLAIMS_LINES');
        apex_collection.create_or_truncate_collection('XXTWC_CLAIMS_LOTS');
        FOR e_rec IN (
            SELECT
                *
            FROM
                xxtwc_claims_order_lines_v
            WHERE
                header_id = p_header_id
        ) LOOP
        lv_credit_price    := e_rec.unit_selling_price;
        lv_new_price := e_rec.unit_selling_price - lv_credit_price;
        lv_rebill_price := null;
--        raise_application_error('-20000','p_claim_type-'||p_claim_type);
        if p_claim_type = 'PRICE_ADJ' then
            lv_credit_price := e_rec.unit_selling_price;
            lv_new_price    := e_rec.unit_selling_price - lv_credit_price;
            lv_rebill_price := null;
        end if;
        if p_claim_type = 'REJECTION_DIVERSION' then
            lv_credit_price := e_rec.unit_selling_price;
            lv_new_price    := e_rec.unit_selling_price - lv_credit_price;
            lv_rebill_price := e_rec.unit_selling_price;
        end if;
        if p_claim_type in ('REJECT_DUMPED','JUICE_CLAIM') then
            lv_credit_price := e_rec.unit_selling_price;
            lv_new_price    := e_rec.unit_selling_price - lv_credit_price;
            lv_rebill_price := null;
        end if;
        if p_claim_type = 'UNREFRENCE_CLAIM' then
            lv_credit_price := e_rec.unit_selling_price;
            lv_new_price := e_rec.unit_selling_price - lv_credit_price;
            lv_rebill_price := null;
        end if;

            apex_collection.add_member(p_collection_name => 'XXTWC_CLAIMS_LINES', 
                p_c001 => e_rec.header_id, 
                p_c002 => e_rec.source_order_number,
                p_c003 => e_rec.source_order_system, 
                p_c004 => e_rec.order_number,
                p_c005 => e_rec.order_type, 
                p_c006 => e_rec.ordered_date, 
                p_c007 => e_rec.customer_po_number, 
                p_c008 => e_rec.status_code, 
                p_c009 => e_rec.display_line_number,
                p_c010 => e_rec.schedule_ship_date,
                p_c011 => e_rec.request_ship_date, 
                p_c012 => e_rec.item_number,
                p_c013 => e_rec.item_description, 
                p_c014 => e_rec.uom,
                p_c015 => e_rec.line_status_code, 
                p_c016 => e_rec.serial_num, 
                p_c017 => e_rec.ord_qty, 
                p_c018 => e_rec.shipped_qty, 
                p_c019 => e_rec.transactional_currency_code,
                p_c020 => e_rec.unit_list_price,
                p_c021 => 0,/* E_REC.AMOUNT,*/
                p_c022 => 0, /* THIS WILL BE CLAIM QTY */ 
                p_c023 => e_rec.unit_selling_price, 
                p_c024 => e_rec.item_country_of_orig,
                p_c025 => e_rec.item_region, 
                p_c026 => e_rec.item_variety, 
                p_c027 => e_rec.gl_account, 
                p_c028 => NULL, 
                p_c029 => e_rec.fulfill_line_id,
                p_c030 => lv_credit_price,
                p_c031 => e_rec.inventory_item_id, 
                p_c032 => 0,/* THIS WILL BE FREIGHT CHANRGES */
                p_c033 => e_rec.returnable_qty,
                p_c034 => 0,
                P_c035 => lv_new_price,
                p_c036 => lv_rebill_price,
                p_c038 => e_rec.actual_ship_date
                );
        IF XXTWC_CLAIMS_OUTBOUND_PKG.check_import_item(p_order_number) >0 then
        /*Fix No Data Found LPN Issue */
            BEGIN
             SELECT COUNT(1) 
               INTO lv_count
               FROM XXTWC_CLAIMS_ORD_IM_LPN_LINES_V  im
              WHERE im.header_id = p_header_id
                and im.fulfill_line_id = e_rec.fulfill_line_id;
            EXCEPTION
              WHEN OTHERS
              THEN lv_count:=0;
            END;

          IF lv_count >0 THEN

            FOR e_rec_lpn1 IN (
                 SELECT
                    *
                  FROM
                     XXTWC_CLAIMS_ORD_IM_LPN_LINES_V  im
                    WHERE
                    im.header_id = p_header_id
                    and im.fulfill_line_id = e_rec.fulfill_line_id
                    )
             LOOP
                apex_collection.add_member(
                    p_collection_name => 'XXTWC_CLAIMS_LOTS', 
                    p_c001 => e_rec_lpn1.SOURCE_ORDER_NUMBER,
                    p_c002 => e_rec_lpn1.order_number, 
                    p_c003 => e_rec_lpn1.header_id,
                    p_c004 => e_rec_lpn1.fulfill_line_id,
                    p_c005 => e_rec_lpn1.delivery_name,
                    p_c006 => e_rec_lpn1.lot_number, 
                    p_c007 => e_rec_lpn1.lpn_number, 
                    p_c008 => e_rec_lpn1.requested_quantity, 
                    p_c009 => 0,
                    p_c010 =>e_rec_lpn1.ORIGINAL_LOT_NUMBER,
                    p_c011 =>e_rec_lpn1.ORIGINAL_LPN_NUMBER,
                    p_c012 =>e_rec_lpn1.RANCH_BLOCK,
                    p_c013 =>e_rec_lpn1.POOL_NUMBER,
                    p_c014 =>e_rec_lpn1.PACK_DATE
                );
            END LOOP;
          ELSE
            FOR e_rec_lpn2 IN (
                 SELECT
                    *
                  FROM
                     XXTWC_CLAIMS_ORDER_LPN_LINES_MV  im
                    WHERE
                    im.header_id = p_header_id
                    and im.fulfill_line_id = e_rec.fulfill_line_id
                    )
             LOOP
                apex_collection.add_member(
                    p_collection_name => 'XXTWC_CLAIMS_LOTS', 
                    p_c001 => e_rec_lpn2.SOURCE_HEADER_NUMBER,
                    p_c002 => e_rec_lpn2.order_number, 
                    p_c003 => e_rec_lpn2.header_id,
                    p_c004 => e_rec_lpn2.fulfill_line_id,
                    p_c005 => e_rec_lpn2.delivery_name,
                    p_c006 => e_rec_lpn2.lot_number, 
                    p_c007 => e_rec_lpn2.lpn_number, 
                    p_c008 => e_rec_lpn2.requested_quantity, 
                    p_c009 => 0,
                    p_c010 =>e_rec_lpn2.ORIGINAL_LOT_NUMBER,
                    p_c011 =>e_rec_lpn2.ORIGINAL_LPN_NUMBER,
                    p_c012 =>e_rec_lpn2.RANCH_BLOCK,
                    p_c013 =>e_rec_lpn2.POOL_NUMBER,
                    p_c014 =>e_rec_lpn2.PACK_DATE
                );
            END LOOP;
          END IF; --lv_count >0
        else  -- XXTWC_CLAIMS_OUTBOUND_PKG.check_import_item(p_order_number)
		FOR e_rec_lpn3 IN (
          SELECT
                *
              FROM
              XXTWC_CLAIMS_ORD_OT_LPN_LINES_V ot
            WHERE
                ot.header_id = p_header_id
                and ot.fulfill_line_id = e_rec.fulfill_line_id
                )
                LOOP
            apex_collection.add_member(
                p_collection_name => 'XXTWC_CLAIMS_LOTS', 
                p_c001 => e_rec_lpn3.SOURCE_ORDER_NUMBER, 
                p_c002 => e_rec_lpn3.order_number, 
                p_c003 => e_rec_lpn3.header_id,
                p_c004 => e_rec_lpn3.fulfill_line_id,
                p_c005 => e_rec_lpn3.delivery_name,
                p_c006 => e_rec_lpn3.lot_number, 
                p_c007 => e_rec_lpn3.lpn_number, 
                p_c008 => e_rec_lpn3.requested_quantity, 
                p_c009 => 0,
                p_c010 =>e_rec_lpn3.ORIGINAL_LOT_NUMBER,
                p_c011 =>e_rec_lpn3.ORIGINAL_LPN_NUMBER,
                p_c012 =>e_rec_lpn3.RANCH_BLOCK,
                p_c013 =>e_rec_lpn3.POOL_NUMBER,
                p_c014 =>e_rec_lpn3.PACK_DATE
            );
        END LOOP;
		end if;

        END LOOP; --Lines Loop
    exception
        when others then 
            xxtwc_claims_gp_error_pkg.gp_error_log(
                'Error in XXTWC_CLAIMS_INSUPD_PKG.get_order_detail', 
                '-20000', 'Error While Processing XXTWC_CLAIMS_INSUPD_PKG.get_order_detail :-' ||sqlerrm, v('APP_USER'), 
                '-1',
                null
            );
    END;
--------------------------------------------------------------------------------
    PROCEDURE update_collection_member (
        p_collection_name IN VARCHAR2,
        p_seq_id          IN NUMBER,
        p_attr_number     IN NUMBER,
        p_value           IN VARCHAR2
    ) IS
    BEGIN
        apex_collection.update_member_attribute(p_collection_name => p_collection_name, p_seq => p_seq_id, p_attr_number => p_attr_number,
        p_attr_value => p_value);
    END;
--------------------------------------------------------------------------------
    PROCEDURE delete_collection_member (
        p_collection_name IN VARCHAR2,
        p_seq_id          IN NUMBER
    ) IS
    BEGIN
        apex_collection.delete_member(p_collection_name => p_collection_name, p_seq => p_seq_id);
    END;
--------------------------------------------------------------------------------  
    PROCEDURE create_or_trunc_collections (
        p_collection_name IN VARCHAR2
    )IS
    BEGIN
        apex_collection.create_or_truncate_collection(p_collection_name);
    END;
--------------------------------------------------------------------------------
    PROCEDURE claim_creation (
        p_xxtwc_claims_headers_rec   IN xxtwc_claims_headers%rowtype,
        p_claim_id                   IN OUT NUMBER,
        p_claim_number               IN OUT VARCHAR2,
        p_error                      OUT VARCHAR2
    ) IS
        lv_claim_dtl_id NUMBER;
        l_claim_total   NUMBER;
        lv_department xxtwc_claims_headers.department%type;
    BEGIN
        IF
            p_claim_id IS NULL
            AND p_claim_number IS NULL
        THEN
            SELECT
                gen_claim_number
            INTO p_claim_number
            FROM
                dual;

            SELECT
                xxtwc_claims_headers_seq.NEXTVAL
            INTO p_claim_id
            FROM
                dual;

    /* Get Distinct Department Code from the reason code  */

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
                        union
                        SELECT
                            CLAIM_REASON_CODE as reason_code
                        FROM
                            xxtwc_claims_lines
                        WHERE claim_id=p_claim_id
                        );
            EXCEPTION
                when others then
                    lv_department := null;
            END;
            BEGIN
                INSERT INTO xxtwc_claims_headers (
                    claim_id,
                    claim_number,
                    claim_revision_number,
                    claim_date,
                    org_id,
                    bu_name,
                    claim_type,
                    ref_claim_type,
                    order_number,
                    order_date,
                    po_number,
                    sold_to_customer_id,
                    sold_to_customer_name,
                    ship_to_customer_id,
                    ship_to_customer_name,
                    ship_to_address1,
                    ship_to_address2,
                    ship_to_address3,
                    ship_to_city,
                    ship_to_postal_code,
                    ship_to_state,
                    ship_to_country,
                    ship_to_site,
                    bill_to_customer_id,
                    bill_to_customer_name,
                    bill_to_address1,
                    bill_to_address2,
                    bill_to_address3,
                    bill_to_city,
                    bill_to_postal_code,
                    bill_to_state,
                    bill_to_country,
                    claim_rec_date,
                    claim_currency_code,
                    warehouse_code,
                    warehouse_name,
                    claim_status,
                    creation_date,
                    created_by,
                    inspection_required,
                    pictures,
                    div_sold_to_customer_id,
                    div_sold_to_customer_name,
                    div_ship_to_customer_id,
                    div_ship_to_customer_name,
                    div_ship_to_address1,
                    div_ship_to_address2,
                    div_ship_to_address3,
                    div_ship_to_city,
                    div_ship_to_postal_code,
                    div_ship_to_state,
                    div_ship_to_country,
                    div_ship_to_site,
                    div_bill_to_customer_id,
                    div_bill_to_customer_name,
                    div_bill_to_address1,
                    div_bill_to_address2,
                    div_bill_to_address3,
                    div_bill_to_city,
                    div_bill_to_postal_code,
                    div_bill_to_state,
                    div_bill_to_country,
                    submited_by,
                    submited_date,
                    header_id,
                    wf_id,
                    supplier_name,
                    supplier_site,
                    div_bill_to_site_use_id,
                    div_ship_to_party_site_id,
                    div_ship_to_party_id,
                    csr_name,
                    preventable,
                    sales_person_name,
                    sales_person_id,
                    orig_order_value,
                    claim_sub_status,
                    claim_note,
                    department,
                    salesmanager,
                    export_order,
                    consignment_order
                ) VALUES (
                    p_claim_id,
                    p_claim_number,
                    p_xxtwc_claims_headers_rec.claim_revision_number,
                    p_xxtwc_claims_headers_rec.claim_date,
                    p_xxtwc_claims_headers_rec.org_id,
                    p_xxtwc_claims_headers_rec.bu_name,
                    p_xxtwc_claims_headers_rec.claim_type,
                    p_xxtwc_claims_headers_rec.ref_claim_type,
                    p_xxtwc_claims_headers_rec.order_number,
                    p_xxtwc_claims_headers_rec.order_date,
                    p_xxtwc_claims_headers_rec.po_number,
                    p_xxtwc_claims_headers_rec.sold_to_customer_id,
                    p_xxtwc_claims_headers_rec.sold_to_customer_name,
                    p_xxtwc_claims_headers_rec.ship_to_customer_id,
                    p_xxtwc_claims_headers_rec.ship_to_customer_name,
                    p_xxtwc_claims_headers_rec.ship_to_address1,
                    p_xxtwc_claims_headers_rec.ship_to_address2,
                    p_xxtwc_claims_headers_rec.ship_to_address3,
                    p_xxtwc_claims_headers_rec.ship_to_city,
                    p_xxtwc_claims_headers_rec.ship_to_postal_code,
                    p_xxtwc_claims_headers_rec.ship_to_state,
                    p_xxtwc_claims_headers_rec.ship_to_country,
                    p_xxtwc_claims_headers_rec.ship_to_site,
                    p_xxtwc_claims_headers_rec.bill_to_customer_id,
                    p_xxtwc_claims_headers_rec.bill_to_customer_name,
                    p_xxtwc_claims_headers_rec.bill_to_address1,
                    p_xxtwc_claims_headers_rec.bill_to_address2,
                    p_xxtwc_claims_headers_rec.bill_to_address3,
                    p_xxtwc_claims_headers_rec.bill_to_city,
                    p_xxtwc_claims_headers_rec.bill_to_postal_code,
                    p_xxtwc_claims_headers_rec.bill_to_state,
                    p_xxtwc_claims_headers_rec.bill_to_country,
                    p_xxtwc_claims_headers_rec.claim_rec_date,
                    p_xxtwc_claims_headers_rec.claim_currency_code,
                    p_xxtwc_claims_headers_rec.warehouse_code,
                    p_xxtwc_claims_headers_rec.warehouse_name,
                    p_xxtwc_claims_headers_rec.claim_status,
                    p_xxtwc_claims_headers_rec.creation_date,
                    p_xxtwc_claims_headers_rec.created_by,
                    p_xxtwc_claims_headers_rec.inspection_required,
                    p_xxtwc_claims_headers_rec.pictures,
                    p_xxtwc_claims_headers_rec.div_sold_to_customer_id,
                    p_xxtwc_claims_headers_rec.div_sold_to_customer_name,
                    p_xxtwc_claims_headers_rec.div_ship_to_customer_id,
                    p_xxtwc_claims_headers_rec.div_ship_to_customer_name,
                    p_xxtwc_claims_headers_rec.div_ship_to_address1,
                    p_xxtwc_claims_headers_rec.div_ship_to_address2,
                    p_xxtwc_claims_headers_rec.div_ship_to_address3,
                    p_xxtwc_claims_headers_rec.div_ship_to_city,
                    p_xxtwc_claims_headers_rec.div_ship_to_postal_code,
                    p_xxtwc_claims_headers_rec.div_ship_to_state,
                    p_xxtwc_claims_headers_rec.div_ship_to_country,
                    p_xxtwc_claims_headers_rec.div_ship_to_site,
                    p_xxtwc_claims_headers_rec.div_bill_to_customer_id,
                    p_xxtwc_claims_headers_rec.div_bill_to_customer_name,
                    p_xxtwc_claims_headers_rec.div_bill_to_address1,
                    p_xxtwc_claims_headers_rec.div_bill_to_address2,
                    p_xxtwc_claims_headers_rec.div_bill_to_address3,
                    p_xxtwc_claims_headers_rec.div_bill_to_city,
                    p_xxtwc_claims_headers_rec.div_bill_to_postal_code,
                    p_xxtwc_claims_headers_rec.div_bill_to_state,
                    p_xxtwc_claims_headers_rec.div_bill_to_country,
                    p_xxtwc_claims_headers_rec.submited_by,
                    p_xxtwc_claims_headers_rec.submited_date,
                    p_xxtwc_claims_headers_rec.header_id,
                    p_xxtwc_claims_headers_rec.wf_id,
                    p_xxtwc_claims_headers_rec.supplier_name,
                    p_xxtwc_claims_headers_rec.supplier_site,
                    p_xxtwc_claims_headers_rec.div_bill_to_site_use_id,
                    p_xxtwc_claims_headers_rec.div_ship_to_party_site_id,
                    p_xxtwc_claims_headers_rec.div_ship_to_party_id,
                    p_xxtwc_claims_headers_rec.csr_name,
                    p_xxtwc_claims_headers_rec.preventable,
                    p_xxtwc_claims_headers_rec.sales_person_name,
                    p_xxtwc_claims_headers_rec.sales_person_id,
                    p_xxtwc_claims_headers_rec.orig_order_value,
                    p_xxtwc_claims_headers_rec.claim_sub_status,
                    p_xxtwc_claims_headers_rec.claim_note,
                    lv_department,
                    p_xxtwc_claims_headers_rec.salesmanager,
                    NVL(p_xxtwc_claims_headers_rec.export_order,'N'),
                    NVL(p_xxtwc_claims_headers_rec.consignment_order,'N')
                );
               FOR i IN (
                SELECT
                    seq_id,
                    c001            AS header_id,
                    c009            AS display_line_number,
                    c012            AS item_number,
                    c013            AS item_description,
                    c014            AS uom,
                    c015            AS line_status_code,
                    c016            AS serial_num,
                    c017            AS ord_qty,
                    to_number(c018) AS shipped_qty,
                    c020            AS unit_list_price,
                    c021            AS amount,
                    to_number(c022) AS claim_qty,
                    c023            AS unit_selling_price,
                    c024            AS item_country_of_orig,
                    c025            AS item_region,
                    c026            AS item_variety,
                    c028            AS reason_code,
                    c029            AS fulfill_line_id,
                    c030            AS unit_adjustment_price,
                    c031            AS inventory_item_id,
                    c032            AS fright_charges,
                    to_number(c033) AS returnable_qty,
                    to_number(c034) AS adj_price_difference,
                    to_number(c035) AS unit_new_price,
                    to_number(c036) AS unit_rebill_price,
                    to_number(c037) AS unit_finalbill_price,    
                    c038            AS ship_date
                FROM
                    apex_collections
                WHERE
                    collection_name = 'XXTWC_CLAIMS_LINES'
                ) LOOP
                INSERT INTO xxtwc_claims_lines (
                        claim_id,
                        claim_line_no,
                        inventory_item_id,
                        inventory_item_name,
                        inventory_item_desc,
                        uom,
                        ship_qty,
                        claim_qty,
                        unit_list_price,
                        unit_selling_price,
                        unit_adjustment_price,
                        adj_price_difference,
                        extended_amount,
                        fright_charges,
                        item_variety,
                        item_region,
                        item_country_of_orig,
                        claim_reason_code,
                        fulfillment_line_id,
                        attribute1,
                        returnable_qty,
                        unit_new_price,
                        unit_rebill_price,
                        unit_finalbill_price,
                        ship_date
                    ) VALUES (
                        p_claim_id,
                        i.display_line_number,
                        i.inventory_item_id,
                        i.item_number,
                        i.item_description,
                        i.uom,
                        i.shipped_qty,
                        i.claim_qty,
                        i.unit_list_price,
                        i.unit_selling_price,
                        i.unit_adjustment_price,
                        i.adj_price_difference,
                        i.amount,
                        i.fright_charges,
                        i.item_variety,
                        i.item_region,
                        i.item_country_of_orig,
                        i.reason_code,
                        i.fulfill_line_id,
                        i.header_id,
                        i.returnable_qty,
                        i.unit_new_price,
                        i.unit_rebill_price,
                        i.unit_finalbill_price,
                       to_Date(i.ship_date,'MM/DD/YYYY')
                    ) RETURNING claim_dtl_id INTO lv_claim_dtl_id;
                END LOOP;

                FOR j IN (
                    SELECT
                        seq_id,
                        c001 AS source_order_number,
                        c002 AS order_number,
                        c003 AS header_id,
                        c004 AS fulfill_line_id,
                        c005 AS delivery_name,
                        c006 AS lot_number,
                        c007 AS lpn_number,
                        c008 AS requested_quantity,
                        c009 AS claim_qty,
                        c010 AS original_lot_number,
                        c011 AS original_lpn_number,
                        c012 AS ranch_block,
                        c013 AS pool_number,
                        c014 AS PACK_DATE
                    FROM
                        apex_collections
                    WHERE
                        collection_name = 'XXTWC_CLAIMS_LOTS'
                ) LOOP
                INSERT INTO xxtwc_claims_lpn_lines (
                        claim_dtl_id,
                        claim_id,
                        ship_qty,
                        claim_qty,
                        lpn,
                        lot_number,
                        batch_number,
                        header_id,
                        fulfill_line_id,
                        delivery_name,
                        original_lot_number,
                        original_lpn_number,
                        ranch_block,
                        pool_number,
                        PACK_DATE
                    ) VALUES (
                              --lv_claim_dtl_id, 
                        (
                            SELECT DISTINCT
                                claim_dtl_id
                            FROM
                                xxtwc_claims_lines d
                            WHERE
                                    d.fulfillment_line_id = j.fulfill_line_id
                                AND d.attribute1 = j.header_id
                                AND claim_id = p_claim_id
                        ),
                        p_claim_id,
                        j.requested_quantity,
                        j.claim_qty,
                        j.lpn_number,
                        j.lot_number,
                        null,
                        j.header_id,
                        j.fulfill_line_id,
                        j.delivery_name,
                        j.original_lot_number,
                        j.original_lpn_number,
                        j.ranch_block,
                        j.pool_number,
                        j.PACK_DATE
                    );
                END LOOP;

                /* Update Claim Header Amount */
                BEGIN
                    SELECT
                        SUM(nvl(extended_amount, 0)) + SUM(nvl(fright_charges, 0))
                    INTO l_claim_total
                    FROM
                        xxtwc_claims_lines
                    WHERE
                        claim_id = p_claim_id;

                    UPDATE xxtwc_claims_headers
                    SET
                        claim_amount = l_claim_total
                    WHERE
                        claim_id = p_claim_id;

                EXCEPTION
                    WHEN OTHERS THEN
                        xxtwc_claims_gp_error_pkg.gp_error_log(
                            'Error in XXTWC_CLAIMS_INSUPD_PKG.CREATE_CREATION', 
                            '-20000', 'Error While Processing XXTWC_CLAIMS_INSUPD_PKG.CREATE_CREATION :-' ||sqlerrm, v('APP_USER'), 
                            '-1',
                            p_claim_id
                        );
                        raise_application_error('-20000', 'Error While Processing XXTWC_CLAIMS_INSUPD_PKG.CREATE_CREATION :-' || sqlerrm);
                        p_error := 'Error While Processing XXTWC_CLAIMS_INSUPD_PKG.CREATE_CREATION :-' || sqlerrm;
                END;

            EXCEPTION
                WHEN OTHERS THEN
                    xxtwc_claims_gp_error_pkg.gp_error_log(
                            'Error in XXTWC_CLAIMS_INSUPD_PKG.CREATE_CREATION', 
                            '-20000', 'Error While Processing XXTWC_CLAIMS_INSUPD_PKG.CREATE_CREATION :-' ||sqlerrm, v('APP_USER'), 
                            '-1',
                            p_claim_id
                        );
                    raise_application_error('-20000', 'Error While Processing XXTWC_CLAIMS_INSUPD_PKG.CREATE_CREATION :-' || sqlerrm);
                    p_error := 'Error While Processing XXTWC_CLAIMS_INSUPD_PKG.CREATE_CREATION :-' || sqlerrm;
            END;

        END IF;
    END;
--------------------------------------------------------------------------------
    PROCEDURE freight_claim_creation (
        p_xxtwc_claims_headers_rec IN xxtwc_claims_headers%rowtype,
        p_claim_id                 IN OUT NUMBER,
        p_claim_number             IN OUT VARCHAR2,
        p_error                    OUT VARCHAR2
    ) IS
        lv_claim_dtl_id NUMBER;
        l_claim_total   NUMBER;
        lv_department xxtwc_claims_headers.department%type;
    BEGIN
        IF
            p_claim_id IS NULL
            AND p_claim_number IS NULL
        THEN
            SELECT
                gen_claim_number
            INTO p_claim_number
            FROM
                dual;

            SELECT
                xxtwc_claims_headers_seq.NEXTVAL
            INTO p_claim_id
            FROM
                dual;
            /* Get Distinct Department Code from the reason code  */
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
                            c028 as reason_code
                        FROM
                            apex_collections
                        WHERE collection_name = 'XXTWC_FREIGHT_CLAIMS_LINES'
                        union
                        SELECT
                            CLAIM_REASON_CODE as reason_code
                        FROM
                            xxtwc_claims_lines
                        WHERE claim_id=p_claim_id
                        );
            EXCEPTION
                when others then
                    lv_department := null;
            END;
            BEGIN
                INSERT INTO xxtwc_claims_headers (
                    claim_id,
                    claim_number,
                    claim_revision_number,
                    claim_date,
                    org_id,
                    bu_name,
                    claim_type,
                    ref_claim_type,
                    order_number,
                    order_date,
                    po_number,
                    sold_to_customer_id,
                    sold_to_customer_name,
                    ship_to_customer_id,
                    ship_to_customer_name,
                    ship_to_address1,
                    ship_to_address2,
                    ship_to_address3,
                    ship_to_city,
                    ship_to_postal_code,
                    ship_to_state,
                    ship_to_country,
                    ship_to_site,
                    bill_to_customer_id,
                    bill_to_customer_name,
                    bill_to_address1,
                    bill_to_address2,
                    bill_to_address3,
                    bill_to_city,
                    bill_to_postal_code,
                    bill_to_state,
                    bill_to_country,
                    claim_rec_date,
                    claim_currency_code,
                    warehouse_code,
                    warehouse_name,
                    claim_status,
                    creation_date,
                    created_by,
                    inspection_required,
                    pictures,
                    div_sold_to_customer_id,
                    div_sold_to_customer_name,
                    div_ship_to_customer_id,
                    div_ship_to_customer_name,
                    div_ship_to_address1,
                    div_ship_to_address2,
                    div_ship_to_address3,
                    div_ship_to_city,
                    div_ship_to_postal_code,
                    div_ship_to_state,
                    div_ship_to_country,
                    div_ship_to_site,
                    div_bill_to_customer_id,
                    div_bill_to_customer_name,
                    div_bill_to_address1,
                    div_bill_to_address2,
                    div_bill_to_address3,
                    div_bill_to_city,
                    div_bill_to_postal_code,
                    div_bill_to_state,
                    div_bill_to_country,
                    submited_by,
                    submited_date,
                    header_id,
                    wf_id,
                    supplier_name,
                    supplier_site,
                    div_bill_to_site_use_id,
                    div_ship_to_party_site_id,
                    div_ship_to_party_id,
                    csr_name,
                    preventable,
                    sales_person_name,
                    sales_person_id,
                    orig_claim_id,
                    claim_amount,
                    orig_order_value,
                    claim_sub_status,
                    claim_note,
                    department,
                    salesmanager,
                    export_order,
                    consignment_order
                ) VALUES (
                    p_claim_id,
                    p_claim_number,
                    p_xxtwc_claims_headers_rec.claim_revision_number,
                    p_xxtwc_claims_headers_rec.claim_date,
                    p_xxtwc_claims_headers_rec.org_id,
                    p_xxtwc_claims_headers_rec.bu_name,
                    p_xxtwc_claims_headers_rec.claim_type,
                    p_xxtwc_claims_headers_rec.ref_claim_type,
                    p_xxtwc_claims_headers_rec.order_number,
                    p_xxtwc_claims_headers_rec.order_date,
                    p_xxtwc_claims_headers_rec.po_number,
                    p_xxtwc_claims_headers_rec.sold_to_customer_id,
                    p_xxtwc_claims_headers_rec.sold_to_customer_name,
                    p_xxtwc_claims_headers_rec.ship_to_customer_id,
                    p_xxtwc_claims_headers_rec.ship_to_customer_name,
                    p_xxtwc_claims_headers_rec.ship_to_address1,
                    p_xxtwc_claims_headers_rec.ship_to_address2,
                    p_xxtwc_claims_headers_rec.ship_to_address3,
                    p_xxtwc_claims_headers_rec.ship_to_city,
                    p_xxtwc_claims_headers_rec.ship_to_postal_code,
                    p_xxtwc_claims_headers_rec.ship_to_state,
                    p_xxtwc_claims_headers_rec.ship_to_country,
                    p_xxtwc_claims_headers_rec.ship_to_site,
                    p_xxtwc_claims_headers_rec.bill_to_customer_id,
                    p_xxtwc_claims_headers_rec.bill_to_customer_name,
                    p_xxtwc_claims_headers_rec.bill_to_address1,
                    p_xxtwc_claims_headers_rec.bill_to_address2,
                    p_xxtwc_claims_headers_rec.bill_to_address3,
                    p_xxtwc_claims_headers_rec.bill_to_city,
                    p_xxtwc_claims_headers_rec.bill_to_postal_code,
                    p_xxtwc_claims_headers_rec.bill_to_state,
                    p_xxtwc_claims_headers_rec.bill_to_country,
                    p_xxtwc_claims_headers_rec.claim_rec_date,
                    p_xxtwc_claims_headers_rec.claim_currency_code,
                    p_xxtwc_claims_headers_rec.warehouse_code,
                    p_xxtwc_claims_headers_rec.warehouse_name,
                    p_xxtwc_claims_headers_rec.claim_status,
                    p_xxtwc_claims_headers_rec.creation_date,
                    p_xxtwc_claims_headers_rec.created_by,
                    p_xxtwc_claims_headers_rec.inspection_required,
                    p_xxtwc_claims_headers_rec.pictures,
                    p_xxtwc_claims_headers_rec.div_sold_to_customer_id,
                    p_xxtwc_claims_headers_rec.div_sold_to_customer_name,
                    p_xxtwc_claims_headers_rec.div_ship_to_customer_id,
                    p_xxtwc_claims_headers_rec.div_ship_to_customer_name,
                    p_xxtwc_claims_headers_rec.div_ship_to_address1,
                    p_xxtwc_claims_headers_rec.div_ship_to_address2,
                    p_xxtwc_claims_headers_rec.div_ship_to_address3,
                    p_xxtwc_claims_headers_rec.div_ship_to_city,
                    p_xxtwc_claims_headers_rec.div_ship_to_postal_code,
                    p_xxtwc_claims_headers_rec.div_ship_to_state,
                    p_xxtwc_claims_headers_rec.div_ship_to_country,
                    p_xxtwc_claims_headers_rec.div_ship_to_site,
                    p_xxtwc_claims_headers_rec.div_bill_to_customer_id,
                    p_xxtwc_claims_headers_rec.div_bill_to_customer_name,
                    p_xxtwc_claims_headers_rec.div_bill_to_address1,
                    p_xxtwc_claims_headers_rec.div_bill_to_address2,
                    p_xxtwc_claims_headers_rec.div_bill_to_address3,
                    p_xxtwc_claims_headers_rec.div_bill_to_city,
                    p_xxtwc_claims_headers_rec.div_bill_to_postal_code,
                    p_xxtwc_claims_headers_rec.div_bill_to_state,
                    p_xxtwc_claims_headers_rec.div_bill_to_country,
                    p_xxtwc_claims_headers_rec.submited_by,
                    p_xxtwc_claims_headers_rec.submited_date,
                    p_xxtwc_claims_headers_rec.header_id,
                    p_xxtwc_claims_headers_rec.wf_id,
                    p_xxtwc_claims_headers_rec.supplier_name,
                    p_xxtwc_claims_headers_rec.supplier_site,
                    p_xxtwc_claims_headers_rec.div_bill_to_site_use_id,
                    p_xxtwc_claims_headers_rec.div_ship_to_party_site_id,
                    p_xxtwc_claims_headers_rec.div_ship_to_party_id,
                    p_xxtwc_claims_headers_rec.csr_name,
                    p_xxtwc_claims_headers_rec.preventable,
                    p_xxtwc_claims_headers_rec.sales_person_name,
                    p_xxtwc_claims_headers_rec.sales_person_id,
                    p_xxtwc_claims_headers_rec.orig_claim_id,
                    p_xxtwc_claims_headers_rec.claim_amount,
                    p_xxtwc_claims_headers_rec.orig_order_value,
                    p_xxtwc_claims_headers_rec.claim_sub_status,
                    p_xxtwc_claims_headers_rec.claim_note,
                    lv_department,
                    p_xxtwc_claims_headers_rec.salesmanager,
                    NVL(p_xxtwc_claims_headers_rec.export_order,'N'),
                    NVL(p_xxtwc_claims_headers_rec.consignment_order,'N')
                );

                FOR i IN (
                SELECT seq_id,
                    c001 as HEADER_ID,
                    c009 as DISPLAY_LINE_NUMBER,
                    c012 as ITEM_NUMBER,
                    c013 as ITEM_DESCRIPTION,
                    c014 as UOM,
                    c015 as LINE_STATUS_CODE,
                    c016 as SERIAL_NUM,
                    c017 as ORD_QTY,
                    to_number(c018) as SHIPPED_QTY,
                    c019 as TRANSACTIONAL_CURRENCY_CODE,
                    c020 as UNIT_LIST_PRICE,
                    c021 as AMOUNT,
                    to_number(c022) as CLAIM_QTY,
                    c023 as UNIT_SELLING_PRICE,
                    c024 as ITEM_COUNTRY_OF_ORIG,
                    c025 as ITEM_REGION,
                    c026 as ITEM_VARIETY,
                    c028 as REASON_CODE,
                    c029 as FULFILL_LINE_ID,
                    c030 as UNIT_ADJUSTMENT_PRICE,
                    c031 as INVENTORY_ITEM_ID,
                    c032 as FRIGHT_CHARGES,
                    to_number(c033) as RETURNABLE_QTY
                FROM apex_collections WHERE collection_name = 'XXTWC_FREIGHT_CLAIMS_LINES' ) LOOP
                    BEGIN
                        INSERT INTO xxtwc_claims_lines (
                            claim_id,
                            claim_line_no,
                            inventory_item_id,
                            inventory_item_name,
                            inventory_item_desc,
                            uom,
                            claim_qty,
                            unit_adjustment_price,
                            extended_amount,
                            claim_reason_code
                        ) VALUES (
                            p_claim_id,
                            i.seq_id,
                            i.inventory_item_id,
                            i.item_number,
                            i.item_description,
                            i.uom,
                            i.claim_qty,
                            i.unit_adjustment_price,
                            i.amount,
                            i.reason_code
                        ) RETURNING claim_dtl_id INTO lv_claim_dtl_id;
                    EXCEPTION
                        WHEN OTHERS THEN
                            xxtwc_claims_gp_error_pkg.gp_error_log(
                                'Error in XXTWC_CLAIMS_INSUPD_PKG.FREIGHT_CLAIM_CREATION1', 
                                '-20000', 'Error While Processing XXTWC_CLAIMS_INSUPD_PKG.FREIGHT_CLAIM_CREATION1 :-' ||sqlerrm, v('APP_USER'), 
                                '-1',
                                p_claim_id
                            );
                            raise_application_error('-20000', 'Error While Processing XXTWC_CLAIMS_INSUPD_PKG.FREIGHT_CLAIM_CREATION1 :-'
                              || sqlerrm
                              || p_claim_id
                              || i.seq_id
                              || i.inventory_item_id);
                            p_error := 'Error While Processing XXTWC_CLAIMS_INSUPD_PKG.CREATE_CREATION1 :-'
                                       || sqlerrm
                                       || p_claim_id
                                       || i.seq_id
                                       || i.inventory_item_id;
                    END;
                END LOOP;    

                /* Update Claim Header Amount */
               /* begin
                    select sum(nvl(EXTENDED_AMOUNT,0)) into l_claim_total from
                    XXTWC_CLAIMS_LINES where claim_id =p_claim_id;

                    UPDATE XXTWC_CLAIMS_HEADERS set CLAIM_AMOUNT = l_claim_total
                    where claim_id =p_claim_id;
                exception
                    when others then
                    raise_application_error('-20000','Error While Processing XXTWC_CLAIMS_INSUPD_PKG.FREIGHT_CLAIM_CREATION :-'||sqlerrm);
                    p_error := 'Error While Processing XXTWC_CLAIMS_INSUPD_PKG.CREATE_CREATION :-'||sqlerrm;
                end;*/
            EXCEPTION
                WHEN OTHERS THEN
                    xxtwc_claims_gp_error_pkg.gp_error_log(
                            'Error in XXTWC_CLAIMS_INSUPD_PKG.FREIGHT_CLAIM_CREATION2', 
                            '-20000', 'Error While Processing XXTWC_CLAIMS_INSUPD_PKG.FREIGHT_CLAIM_CREATION2 :-' ||sqlerrm, v('APP_USER'), 
                            '-1',
                            p_claim_id
                        );
                    raise_application_error('-20000', 'Error While Processing XXTWC_CLAIMS_INSUPD_PKG.FREIGHT_CLAIM_CREATION2:-' || sqlerrm);
                    p_error := 'Error While Processing XXTWC_CLAIMS_INSUPD_PKG.CREATE_CREATION2 :-' || sqlerrm;
            END;

        END IF;
    END;
--------------------------------------------------------------------------------
    PROCEDURE get_claim_header_details (
        p_claim_id                IN NUMBER,
        p_claim_number            IN VARCHAR2,
        p_xxtwc_claims_header_rec OUT xxtwc_claims_headers%rowtype,
        p_error                   OUT VARCHAR2
    ) IS
    BEGIN
        BEGIN
            SELECT
                *
            INTO p_xxtwc_claims_header_rec
            FROM
                xxtwc_claims_headers
            WHERE
                    claim_id = p_claim_id
                AND claim_number = p_claim_number;

        EXCEPTION
            WHEN OTHERS THEN
                p_error := 'No Record found for Claim ID :' || p_claim_id;
        END;
    END;

    PROCEDURE get_claim_line_details (
        p_claim_id              IN NUMBER,
        p_xxtwc_claims_line_rec OUT xxtwc_claims_line_rec,
        p_error                 OUT VARCHAR2
    ) IS
    BEGIN
        BEGIN
            SELECT
        claim_dtl_id          ,
        claim_id              ,
        claim_line_no         ,
        inventory_item_id     ,
        inventory_item_name   ,
        inventory_item_desc   ,
        uom                   ,
        ship_qty              ,
        claim_qty             ,
        unit_list_price       ,
        unit_selling_price    ,
        unit_adjustment_price ,
		adj_price_difference  ,
        extended_amount       ,
        fright_charges        ,
        item_variety          ,
        item_region           ,
        item_country_of_orig  ,
        claim_reason_code     ,
        creation_date         ,
        created_by            ,
        last_update_date      ,
        last_updated_by       ,
        ora_rma_line_id       ,
        ora_rma_line_status   ,
        ora_so_line_id        ,
        ora_so_line_status    ,
        attribute1            ,
        attribute2            ,
        attribute3            ,
        attribute4            ,
        attribute5            ,
        attribute_num1        ,
        attribute_num2        ,
        attribute_num3        ,
        attribute_num4        ,
        attribute_num5        ,
        attribute_date1       ,
        attribute_date2       ,
        attribute_date3       ,
        attribute_date4       ,
        attribute_date5       ,
        gl_account            ,
        fulfillment_line_id   ,
        returnable_qty        ,
        unit_new_price        ,
        unit_rebill_price     ,
        unit_finalbill_price  ,
        ship_date             
            BULK COLLECT
            INTO p_xxtwc_claims_line_rec
            FROM
                xxtwc_claims_lines
            WHERE
                claim_id = p_claim_id;

        EXCEPTION
            WHEN OTHERS THEN
                p_error := 'No Record found for Claim ID :' || p_claim_id;
        END;
    END;
--------------------------------------------------------------------------------
    PROCEDURE delete_claims (
        p_claim_id     IN NUMBER,
        p_claim_number IN VARCHAR2,
        p_error        OUT VARCHAR2,
        p_success      OUT VARCHAR2
    ) IS
    BEGIN
        BEGIN
            DELETE FROM xxtwc_claims_documents
            WHERE
                claim_id = p_claim_id;

            DELETE FROM xxtwc_claims_lpn_lines
            WHERE
                claim_id = p_claim_id;

            DELETE FROM xxtwc_claims_lines
            WHERE
                claim_id = p_claim_id;

            DELETE FROM xxtwc_claims_headers
            WHERE
                claim_id = p_claim_id;

        EXCEPTION
            WHEN OTHERS THEN
                p_error := 'Error while Processing Delete_Claims :' || sqlerrm;
        END;

        IF p_error IS NULL THEN
            p_success := 'Claim '
                         || p_claim_number
                         || ' discarded successfully.';
        END IF;

    END;
--------------------------------------------------------------------------------    
    PROCEDURE update_claim_lines (
        p_claim_id              xxtwc_claims_lines.claim_id%TYPE,
        p_claim_dtl_id          xxtwc_claims_lines.claim_dtl_id%TYPE,
        p_claim_qty             xxtwc_claims_lines.claim_qty%TYPE,
        p_unit_adjustment_price xxtwc_claims_lines.unit_adjustment_price%TYPE,
        p_extended_amount       xxtwc_claims_lines.extended_amount%TYPE,
        p_fright_charges        xxtwc_claims_lines.fright_charges%TYPE,
        p_claim_reason_code     xxtwc_claims_lines.claim_reason_code%TYPE,
        p_unit_new_price        xxtwc_claims_lines.unit_new_price%TYPE,
        p_unit_rebill_price     xxtwc_claims_lines.unit_rebill_price%TYPE,
        p_overpay_price         xxtwc_claims_lines.overpay_price%TYPE

    )IS

    BEGIN
        UPDATE xxtwc_claims_lines
        SET
            claim_qty = p_claim_qty,
            unit_adjustment_price = p_unit_adjustment_price,
            extended_amount = p_extended_amount,
            fright_charges = p_fright_charges,
            claim_reason_code = p_claim_reason_code,
            unit_new_price = p_unit_new_price,
            unit_rebill_price = p_unit_rebill_price,
            overpay_price = p_overpay_price

        WHERE
                claim_id = p_claim_id
            AND claim_dtl_id = p_claim_dtl_id;
    EXCEPTION
        WHEN OTHERS THEN
        xxtwc_claims_gp_error_pkg.gp_error_log(
                            'Error in XXTWC_CLAIMS_INSUPD_PKG.UPDATE_CLAIM_LINES', 
                            '-20000', 'Error While Processing XXTWC_CLAIMS_INSUPD_PKG.UPDATE_CLAIM_LINES :-' ||sqlerrm, v('APP_USER'), 
                            '-1',
                            p_claim_id
                        );
        raise_application_error('-20000', 'Error While Processing XXTWC_CLAIMS_INSUPD_PKG.UPDATE_CLAIM_LINES:-' || sqlerrm);
    END;
-------------------------------------------------------------------------------
    PROCEDURE full_claim( 
        p_claim_id xxtwc_claims_headers.claim_id%TYPE
    ) IS BEGIN
        FOR i IN (
            SELECT
                claim_id,
                claim_dtl_id,
                claim_qty,
                returnable_qty,
                unit_adjustment_price,
                fright_charges,
                claim_reason_code,
                unit_new_price,
                unit_rebill_price,
                attribute1,
                fulfillment_line_id,
                overpay_price
            FROM
                xxtwc_claims_lines
            WHERE
                claim_id = p_claim_id
        ) LOOP
            FOR j IN (
                SELECT
                    claim_id,
                    claim_dtl_id,
                    ship_qty,
                    claim_qty,
                    header_id,
                    fulfill_line_id
                FROM
                    xxtwc_claims_lpn_lines
                WHERE
                        claim_id = i.claim_id
                    AND header_id = i.attribute1
                    AND fulfill_line_id = i.fulfillment_line_id
            ) LOOP
                UPDATE xxtwc_claims_lpn_lines
                SET
                    claim_qty = ship_qty
                WHERE
                        claim_id = j.claim_id
                    AND header_id = j.header_id
                    AND fulfill_line_id = j.fulfill_line_id;
            END LOOP;
            xxtwc_claims_insupd_pkg.update_claim_lines(
                p_claim_id => i.claim_id, 
                p_claim_dtl_id => i.claim_dtl_id, 
                p_claim_qty => i.returnable_qty,
                p_unit_adjustment_price => i.unit_adjustment_price, 
                p_extended_amount =>(nvl(i.returnable_qty, 0) * nvl(i.unit_adjustment_price, 0)),
                p_fright_charges => i.fright_charges, 
                p_claim_reason_code => i.claim_reason_code, 
                p_unit_new_price => i.unit_new_price, 
                p_unit_rebill_price => i.unit_rebill_price,
                p_overpay_price   => i.overpay_price

            );

        END LOOP;
EXCEPTION
    WHEN OTHERS THEN
        xxtwc_claims_gp_error_pkg.gp_error_log(
            'Error in XXTWC_CLAIMS_INSUPD_PKG.FULL_CLAIM', 
            '-20000', 
            'Error While Processing XXTWC_CLAIMS_INSUPD_PKG.FULL_CLAIM :-' ||sqlerrm,
            v('APP_USER'), 
            '-1',
             p_claim_id);
            raise_application_error('-20000', 'Error While Processing XXTWC_CLAIMS_INSUPD_PKG.FULL_CLAIM:-' || sqlerrm);
END;
-------------------------------------------------------------------------------
    PROCEDURE clear_full_claim( 
        p_claim_id xxtwc_claims_headers.claim_id%TYPE
    ) IS BEGIN
        FOR i IN (
            SELECT
                claim_id,
                claim_dtl_id,
                claim_qty,
                returnable_qty,
                unit_adjustment_price,
                fright_charges,
                claim_reason_code,
                unit_new_price,
                unit_rebill_price,
                attribute1,
                fulfillment_line_id,
                overpay_price
            FROM
                xxtwc_claims_lines
            WHERE
                claim_id = p_claim_id
        ) LOOP
            FOR j IN (
                SELECT
                    claim_id,
                    claim_dtl_id,
                    ship_qty,
                    claim_qty,
                    header_id,
                    fulfill_line_id
                FROM
                    xxtwc_claims_lpn_lines
                WHERE
                        claim_id = i.claim_id
                    AND header_id = i.attribute1
                    AND fulfill_line_id = i.fulfillment_line_id
            ) LOOP
                UPDATE xxtwc_claims_lpn_lines
                SET
                    claim_qty = 0
                WHERE
                        claim_id = j.claim_id
                    AND header_id = i.attribute1
                    AND fulfill_line_id = i.fulfillment_line_id;

            END LOOP;
            xxtwc_claims_insupd_pkg.update_claim_lines(
                p_claim_id => i.claim_id, 
                p_claim_dtl_id => i.claim_dtl_id, 
                p_claim_qty => 0,
                p_unit_adjustment_price => i.unit_adjustment_price, 
                p_extended_amount =>(0 * nvl(i.unit_adjustment_price, 0)),
                p_fright_charges => i.fright_charges, 
                p_claim_reason_code => i.claim_reason_code, 
                p_unit_new_price => i.unit_new_price, 
                p_unit_rebill_price => i.unit_rebill_price,
                p_overpay_price   => i.overpay_price

            );
        END LOOP;
EXCEPTION
    WHEN OTHERS THEN
        xxtwc_claims_gp_error_pkg.gp_error_log(
            'Error in XXTWC_CLAIMS_INSUPD_PKG.CLEAR_FULL_CLAIM', 
            '-20000', 
            'Error While Processing XXTWC_CLAIMS_INSUPD_PKG.CLEAR_FULL_CLAIM :-' ||sqlerrm,
            v('APP_USER'), 
            '-1',
             p_claim_id);
            raise_application_error('-20000', 'Error While Processing XXTWC_CLAIMS_INSUPD_PKG.FULL_CLAIM:-' || sqlerrm);
END;
--------------------------------------------------------------------------------    
    PROCEDURE full_lot_claim(
        p_claim_id xxtwc_claims_headers.claim_id%TYPE,
        p_claim_dtl_id xxtwc_claims_lines.claim_id%TYPE
    )IS
    BEGIN
        FOR i IN (
            SELECT
                claim_id,
                claim_dtl_id,
                claim_qty,
                returnable_qty,
                unit_adjustment_price,
                fright_charges,
                claim_reason_code,
                unit_new_price,
                unit_rebill_price,
                attribute1,
                fulfillment_line_id,
                overpay_price
            FROM
                xxtwc_claims_lines
            WHERE
                claim_id = p_claim_id
                and claim_dtl_id = p_claim_dtl_id
        ) LOOP
            FOR j IN (
                SELECT
                    claim_id,
                    claim_dtl_id,
                    ship_qty,
                    claim_qty,
                    header_id,
                    fulfill_line_id
                FROM
                    xxtwc_claims_lpn_lines
                WHERE
                        claim_id = i.claim_id
                    AND header_id = i.attribute1
                    AND fulfill_line_id = i.fulfillment_line_id
            ) LOOP
                UPDATE xxtwc_claims_lpn_lines
                SET
                    claim_qty = ship_qty
                WHERE
                        claim_id = j.claim_id
                    AND header_id = j.header_id
                    AND fulfill_line_id = j.fulfill_line_id;
            END LOOP;
            xxtwc_claims_insupd_pkg.update_claim_lines(
                p_claim_id => i.claim_id, 
                p_claim_dtl_id => i.claim_dtl_id, 
                p_claim_qty => i.returnable_qty,
                p_unit_adjustment_price => i.unit_adjustment_price, 
                p_extended_amount =>(nvl(i.returnable_qty, 0) * nvl(i.unit_adjustment_price, 0)),
                p_fright_charges => i.fright_charges, 
                p_claim_reason_code => i.claim_reason_code, 
                p_unit_new_price => i.unit_new_price, 
                p_unit_rebill_price => i.unit_rebill_price,
                p_overpay_price   => i.overpay_price

            );
        END LOOP;
    EXCEPTION
    WHEN OTHERS THEN
        xxtwc_claims_gp_error_pkg.gp_error_log(
            'Error in XXTWC_CLAIMS_INSUPD_PKG.FULL_LOT_CLAIM', 
            '-20000', 
            'Error While Processing XXTWC_CLAIMS_INSUPD_PKG.FULL_LOT_CLAIM :-' ||sqlerrm,
            v('APP_USER'), 
            '-1',
             p_claim_id);
            raise_application_error('-20000', 'Error While Processing XXTWC_CLAIMS_INSUPD_PKG.FULL_LOT_CLAIM:-' || sqlerrm);
    END;
--------------------------------------------------------------------------------    
    PROCEDURE clear_lot_claim(
        p_claim_id xxtwc_claims_headers.claim_id%TYPE,
        p_claim_dtl_id xxtwc_claims_lines.claim_id%TYPE
    )IS
    BEGIN
        FOR i IN (
            SELECT
                claim_id,
                claim_dtl_id,
                claim_qty,
                returnable_qty,
                unit_adjustment_price,
                fright_charges,
                claim_reason_code,
                unit_new_price,
                unit_rebill_price,
                attribute1,
                fulfillment_line_id,
                overpay_price
            FROM
                xxtwc_claims_lines
            WHERE
                claim_id = p_claim_id
                and claim_dtl_id = p_claim_dtl_id
        ) LOOP
            FOR j IN (
                SELECT
                    claim_id,
                    claim_dtl_id,
                    ship_qty,
                    claim_qty,
                    header_id,
                    fulfill_line_id
                FROM
                    xxtwc_claims_lpn_lines
                WHERE
                        claim_id = i.claim_id
                    AND header_id = i.attribute1
                    AND fulfill_line_id = i.fulfillment_line_id
            ) LOOP
                UPDATE xxtwc_claims_lpn_lines
                SET
                    claim_qty = 0
                WHERE
                        claim_id = j.claim_id
                    AND header_id = j.header_id
                    AND fulfill_line_id = j.fulfill_line_id;
            END LOOP;
            xxtwc_claims_insupd_pkg.update_claim_lines(
                p_claim_id => i.claim_id, 
                p_claim_dtl_id => i.claim_dtl_id, 
                p_claim_qty => 0,
                p_unit_adjustment_price => i.unit_adjustment_price, 
                p_extended_amount =>(0 * nvl(i.unit_adjustment_price, 0)),
                p_fright_charges => i.fright_charges, 
                p_claim_reason_code => i.claim_reason_code, 
                p_unit_new_price => i.unit_new_price, 
                p_unit_rebill_price => i.unit_rebill_price,
                p_overpay_price  => i.overpay_price

            );
        END LOOP;
    EXCEPTION
    WHEN OTHERS THEN
        xxtwc_claims_gp_error_pkg.gp_error_log(
            'Error in XXTWC_CLAIMS_INSUPD_PKG.CLEAR_LOT_CLAIM', 
            '-20000', 
            'Error While Processing XXTWC_CLAIMS_INSUPD_PKG.CLEAR_LOT_CLAIM :-' ||sqlerrm,
            v('APP_USER'), 
            '-1',
             p_claim_id);
            raise_application_error('-20000', 'Error While Processing XXTWC_CLAIMS_INSUPD_PKG.CLEAR_LOT_CLAIM:-' || sqlerrm);
    END;
--------------------------------------------------------------------------------    
    PROCEDURE update_department(
        p_claim_id xxtwc_claims_headers.claim_id%TYPE
    ) IS
    lv_department xxtwc_claims_headers.department%type;
    BEGIN
       /* SELECT
            department
        INTO lv_department
        FROM
            xxtwc_claims_headers
        WHERE
            claim_id = p_claim_id; */

        --IF lv_department IS NULL THEN
            BEGIN
                SELECT DISTINCT
                    tag
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
                            claim_reason_code AS reason_code
                        FROM
                            xxtwc_claims_lines
                        WHERE
                            claim_id = p_claim_id
                    );

            EXCEPTION
                WHEN OTHERS THEN
                    lv_department := NULL;
            END;

            UPDATE xxtwc_claims_headers
            SET
                department = lv_department
            WHERE
                claim_id = p_claim_id;

        --END IF;
    EXCEPTION
        WHEN OTHERS THEN
            xxtwc_claims_gp_error_pkg.gp_error_log(
            'Error in XXTWC_CLAIMS_INSUPD_PKG.UPDATE_DEPARTMENT', 
            '-20000', 
            'Error While Processing XXTWC_CLAIMS_INSUPD_PKG.UPDATE_DEPARTMENT :-' ||sqlerrm,
            v('APP_USER'), 
            '-1',
             p_claim_id);
            raise_application_error('-20000', 'Error While Processing XXTWC_CLAIMS_INSUPD_PKG.UPDATE_DEPARTMENT:-' || sqlerrm);
    END;
--------------------------------------------------------------------------------
    PROCEDURE update_claim_lines_price(
        p_claim_id xxtwc_claims_headers.claim_id%TYPE,
        p_header_id xxtwc_claims_headers.header_id%TYPE,
        p_claim_type xxtwc_claims_headers.claim_type%TYPE
    )IS
    lv_credit_price NUMBER;
    lv_new_price NUMBER;
    lv_rebill_price NUMBER;
    BEGIN
        FOR e_rec IN (
            SELECT
                *
            FROM
                xxtwc_claims_order_lines_v
            WHERE
                header_id = p_header_id
        ) LOOP
            lv_credit_price    := e_rec.unit_selling_price;
            lv_new_price := e_rec.unit_selling_price - lv_credit_price;
            lv_rebill_price := null;
            if p_claim_type = 'PRICE_ADJ' then
                lv_credit_price := e_rec.unit_selling_price;
                lv_new_price    := e_rec.unit_selling_price - lv_credit_price;
                lv_rebill_price := null;
            end if;
            if p_claim_type = 'REJECTION_DIVERSION' then
                lv_credit_price := e_rec.unit_selling_price;
                lv_new_price    := e_rec.unit_selling_price - lv_credit_price;
                lv_rebill_price := e_rec.unit_selling_price;
            end if;
            if p_claim_type in ('REJECT_DUMPED','JUICE_CLAIM') then
                lv_credit_price := e_rec.unit_selling_price;
                lv_new_price    := e_rec.unit_selling_price - lv_credit_price;
                lv_rebill_price := null;
            end if;
            if p_claim_type = 'UNREFRENCE_CLAIM' then
                lv_credit_price := e_rec.unit_selling_price;
                lv_new_price := e_rec.unit_selling_price - lv_credit_price;
                lv_rebill_price := null;
            end if;
            UPDATE xxtwc_claims_lines SET 
                unit_adjustment_price = lv_credit_price,
                unit_new_price = lv_new_price,
                unit_rebill_price = lv_rebill_price,
                extended_amount = nvl(claim_qty,0) * nvl(lv_credit_price,0)
            WHERE claim_id = p_claim_id
            AND attribute1 = e_Rec.header_id
            AND fulfillment_line_id = e_Rec.fulfill_line_id;
        END LOOP;
    EXCEPTION
        WHEN OTHERS THEN
        xxtwc_claims_gp_error_pkg.gp_error_log(
            'Error in XXTWC_CLAIMS_INSUPD_PKG.UPDATE_CLAIM_LINES_PRICE', 
            '-20000', 
            'Error While Processing XXTWC_CLAIMS_INSUPD_PKG.UPDATE_CLAIM_LINES_PRICE :-' ||sqlerrm,
            v('APP_USER'), 
            '-1',
             p_claim_id);
            raise_application_error('-20000', 'Error While Processing XXTWC_CLAIMS_INSUPD_PKG.UPDATE_CLAIM_LINES_PRICE:-' || sqlerrm);
    END;
--------------------------------------------------------------------------------
PROCEDURE update_reason_code_all(
        p_claim_id xxtwc_claims_headers.claim_id%TYPE,
        p_reason_code xxtwc_claims_lines.claim_reason_code%type
    )is
begin
    update xxtwc_claims_lines set claim_reason_code = p_reason_code where claim_id = p_claim_id;
exception
    when others then
        xxtwc_claims_gp_error_pkg.gp_error_log(
            'Error in XXTWC_CLAIMS_INSUPD_PKG.UPDATE_REASON_CODE_ALL', 
            '-20000', 
            'Error While Processing XXTWC_CLAIMS_INSUPD_PKG.UPDATE_REASON_CODE_ALL :-' ||sqlerrm,
            v('APP_USER'), 
            '-1',
             p_claim_id);
            raise_application_error('-20000', 'Error While Processing XXTWC_CLAIMS_INSUPD_PKG.UPDATE_REASON_CODE_ALL:-' || sqlerrm);
end;
--------------------------------------------------------------------------------
    FUNCTION get_reason_code_name (
        p_reason_code IN VARCHAR2
    ) RETURN VARCHAR2 IS
        lv_reason_name VARCHAR2(2000);
    BEGIN
        SELECT
            meaning AS reagion
        INTO lv_reason_name
        FROM
            fusion.fnd_lookup_values a
        WHERE
                lookup_type = 'DOO_RETURN_REASON'
            AND language = 'US'
            AND tag IN ( 'CARRIER', 'OPERATIONS', 'QUALITY', 'SALES' )
            AND enabled_flag = 'Y'
            AND lookup_code = p_reason_code;

        RETURN lv_reason_name;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN p_reason_code;
    END;
--------------------------------------------------------------------------------
    FUNCTION get_reason_codes (
        p_claim_id IN NUMBER
    ) RETURN VARCHAR2 IS
        lv_reason_codes VARCHAR2(2000);
    BEGIN
        SELECT
            LISTAGG(distinct get_reason_code_name(claim_reason_code), ', ') reason_code
        INTO lv_reason_codes
        FROM
            xxtwc_claims_lines
        WHERE
            claim_id = p_claim_id;

        RETURN lv_reason_codes;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END;
--------------------------------------------------------------------------------
    FUNCTION get_salesmanager(
        p_header_id IN VARCHAR2
    ) RETURN VARCHAR2 IS
        lv_salesmanager XXTWC_CLAIMS_HEADERS.SALESMANAGER%TYPE;
        lv_email XXTWC_CLAIMS_HEADERS.SALESMANAGER%TYPE;
    BEGIN
        SELECT
            hcs_ship.attribute5 salesmanager,
            ( SELECT email_address
             FROM ( SELECT (email_address)
             FROM fusion.HZ_PARTIES hp
             WHERE   hp.PARTY_NAME = hcs_ship.attribute5 
             AND hp.status ='A'
             ORDER BY hp.PARTY_ID DESC)
             WHERE ROWNUM =1) into  lv_salesmanager,lv_email
        FROM
            fusion.doo_headers_all        dha,
            fusion.doo_order_addresses    doa_ship,
            fusion.hz_parties             hp_ship,
            fusion.hz_party_sites         hps_ship,
            fusion.hz_cust_accounts       hc_ship,
            fusion.hz_cust_acct_sites_all hcs_ship
        WHERE
                doa_ship.header_id (+) = dha.header_id
            AND doa_ship.address_use_type (+) = 'SHIP_TO'
            AND hp_ship.party_id (+) = doa_ship.party_id
            AND hps_ship.party_site_id = doa_ship.party_site_id
            AND hps_ship.party_id = hp_ship.party_id
            AND hp_ship.party_id = hc_ship.party_id
            AND hps_ship.party_site_id = hcs_ship.party_site_id
            AND hcs_ship.cust_account_id = hc_ship.cust_account_id
            AND dha.header_id = p_header_id;
            return lv_email;

    exception
        when others then
        lv_email := null;
        return lv_email;
    END;
--------------------------------------------------------------------------------
    FUNCTION get_pending_approval_cnt(
        p_org_id IN VARCHAR2,
        p_user_name IN VARCHAR2
    ) RETURN NUMBER IS 
    lv_cnt NUMBER;
    BEGIN
        SELECT
            COUNT(*)
        INTO lv_cnt
        FROM
    xxtwc_claims_headers        ch,
    xxtwc_claims_appr_wf_header hd
WHERE
        hd.wf_id = ch.wf_id
    AND ch.org_id = p_org_id
    AND ch.claim_type <> 'A_MINUS'
    AND ( ( ch.wf_next_seq_no = (
            SELECT
                wd.seq
            FROM
                xxtwc_claims_appr_wf_details wd
            WHERE
                    wd.wf_id = ch.wf_id
                AND upper(wd.step_name) = upper('Claim Owner Approval')
        )
            AND ( ( EXISTS (
        SELECT
            user_id
        FROM
            xxtwc_claims_user_login_details
        WHERE
            upper(email_id) = upper(ch.salesmanager)
    )
                    AND lower(p_user_name) = lower(ch.salesmanager) )
                  OR ( NOT EXISTS (
        SELECT
            user_id
        FROM
            xxtwc_claims_user_login_details
        WHERE
            upper(email_id) = upper(ch.salesmanager)
    )
                           AND EXISTS (
        SELECT
            1
        FROM
            xxtwc_claims_user_login_details lg,
            xxtwc_claims_appr_group_users   gu,
            xxtwc_claims_appr_groups        g
        WHERE
                lg.user_id = gu.user_id
            AND gu.group_id = g.group_id
            AND g.group_name = 'Claim Owner'
            AND lower(lg.email_id) = lower(p_user_name)
    ) ) ) )
          OR ( ch.wf_next_seq_no = (
            SELECT
                wd.seq
            FROM
                xxtwc_claims_appr_wf_details wd
            WHERE
                    wd.wf_id = ch.wf_id
                AND upper(wd.step_name) = upper('Finance Approval')
        )
               AND lower(p_user_name) IN (
        SELECT
            lower(email_id)
        FROM
            xxtwc_claims_user_login_details lg, xxtwc_claims_appr_group_users   gu
        WHERE
                lg.user_id = gu.user_id
            AND to_char(gu.group_id) = (
                SELECT
                    group_id
                FROM
                    xxtwc_claims_appr_lvl_dtl ald, xxtwc_claims_appr_lvl_hdr alh
                WHERE
                        ald.appr_lvl_hdr_id = alh.appr_lvl_hdr_id
                    AND alh.hierarchy_name = 'Finance'
                    AND to_number(ch.claim_amount) BETWEEN to_number(ald.min_value) AND to_number(ald.max_value)
                    AND alh.org_id = ch.org_id
                    AND ald.group_id IS NOT NULL
            )
    ) )
          OR ( ch.wf_next_seq_no = (
            SELECT
                wd.seq
            FROM
                xxtwc_claims_appr_wf_details wd
            WHERE
                    wd.wf_id = ch.wf_id
                AND upper(wd.step_name) = upper('Departmental Hierarchy Approval')
        )
               AND lower(p_user_name) IN (
        SELECT
            lower(email_id)
        FROM
            (
                SELECT DISTINCT
                    ld.user_id, ld.email_id
                FROM
                    xxtwc_claims_appr_group_users   gu, xxtwc_claims_user_login_details ld, xxtwc_claims_user_org_details   od
                WHERE
                        gu.user_id = ld.user_id
                    AND od.user_id = ld.user_id
                    AND ld.dept_code = ch.department
                    AND EXISTS (
                        SELECT
                            result AS r
                        FROM
                            (
                                SELECT
                                    regexp_substr(od.warehouse_code, '[^:]+', 1, level) result
                                FROM
                                    dual
                                CONNECT BY
                                    level <= length(regexp_replace(od.warehouse_code, '[^:]+')) + 1
                            )
                        WHERE
                            result = ch.warehouse_code
                    )
                    AND ch.org_id = od.org_id
                    AND group_id IN (
                        SELECT DISTINCT
                            result
                        FROM
                            (
                                SELECT
                                    regexp_substr(group_id, '[^:]+', 1, level) result
                                FROM
                                    (
                                        SELECT
                                            group_id
                                        FROM
                                            (
                                                SELECT
                                                    group_id
                                                FROM
                                                    xxtwc_claims_appr_lvl_dtl ald, xxtwc_claims_appr_lvl_hdr alh
                                                WHERE
                                                        ald.appr_lvl_hdr_id = alh.appr_lvl_hdr_id
                                                    AND alh.appr_lvl_hdr_id = hd.appr_lvl_hdr_id
                                                    AND ( ( ch.claim_amount <= ald.max_value
                                                            AND ch.claim_amount >= decode(ald.attribute1, 1, 0, ald.min_value) )
                                                          OR ch.claim_amount > ald.max_value )
                                                    AND alh.org_id = ch.org_id
                                                    AND NOT EXISTS (
                                                        SELECT
                                                            1
                                                        FROM
                                                            xxtwc_claims_appr_wf_act_log lo
                                                        WHERE
                                                                lo.seq = ch.wf_next_seq_no --12 
                                                            AND lo.group_id = ald.group_id
                                                            AND lo.wf_id = ch.wf_id
                                                            AND lo.claim_id = ch.claim_id
                                                    )
                                                    AND ald.group_id IS NOT NULL
                                                ORDER BY
                                                    ald.max_value ASC
                                            )
                                        WHERE
                                            ROWNUM < 2
                                    )
                                CONNECT BY
                                    level <= length(regexp_replace(group_id, '[^:]+')) + 1
                            )
                    )
            )
    ) ) );

        RETURN nvl(lv_cnt,0);
    END;
--------------------------------------------------------------------------------
    FUNCTION check_claim_type (
        p_claim_type IN VARCHAR2
    ) RETURN BOOLEAN IS
    lv_type xxtwc_claims_lookups.attribute6%type;
    BEGIN
        BEGIN
            SELECT
                attribute6
            INTO lv_type
            FROM
                xxtwc_claims_lookups
            WHERE
                    lookup_type = 'CLAIM_TYPE'
                AND lookup_name = p_claim_type;

        EXCEPTION
            WHEN OTHERS THEN
                lv_type := '';
        END;

        IF lv_type = 'Charge' THEN
            RETURN false;
        END IF;
        RETURN true;
        end;
    END;
/