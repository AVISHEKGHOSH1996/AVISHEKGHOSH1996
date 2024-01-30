/****************************************************************************************************
	Object Type: 	Package Spec
	Name       :    XXTWC_CLAIMS_INSUPD_PKG
	Created by:		Trinamix
	Created On:		06/01/2023
	Description:	Package Spec XXTWC_CLAIMS_INSUPD_PKG
	Modified On:	
	Reason:		    
****************************************************************************************************/

--------------------------------------------------------
--  DDL for Package XXTWC_CLAIMS_INSUPD_PKG
--------------------------------------------------------
create or replace PACKAGE        xxtwc_claims_insupd_pkg IS
    TYPE xxtwc_claims_line_rec_type IS RECORD (
        claim_dtl_id          NUMBER,
        claim_id              NUMBER,
        claim_line_no         NUMBER,
        inventory_item_id     NUMBER,
        inventory_item_name   VARCHAR2(100),
        inventory_item_desc   VARCHAR2(240),
        uom                   VARCHAR2(100),
        ship_qty              NUMBER,
        claim_qty             NUMBER,
        unit_list_price       NUMBER,
        unit_selling_price    NUMBER,
        unit_adjustment_price NUMBER,
		adj_price_difference  NUMBER,
        extended_amount       NUMBER,
        fright_charges        NUMBER,
        item_variety          VARCHAR2(150),
        item_region           VARCHAR2(150),
        item_country_of_orig  VARCHAR2(150),
        claim_reason_code     VARCHAR2(100),
        creation_date         TIMESTAMP(6),
        created_by            VARCHAR2(255),
        last_update_date      TIMESTAMP(6),
        last_updated_by       VARCHAR2(255),
        ora_rma_line_id       NUMBER,
        ora_rma_line_status   VARCHAR2(100),
        ora_so_line_id        NUMBER,
        ora_so_line_status    VARCHAR2(100),
        attribute1            VARCHAR2(150),
        attribute2            VARCHAR2(150),
        attribute3            VARCHAR2(150),
        attribute4            VARCHAR2(150),
        attribute5            VARCHAR2(150),
        attribute_num1        NUMBER,
        attribute_num2        NUMBER,
        attribute_num3        NUMBER,
        attribute_num4        NUMBER,
        attribute_num5        NUMBER,
        attribute_date1       DATE,
        attribute_date2       DATE,
        attribute_date3       DATE,
        attribute_date4       DATE,
        attribute_date5       DATE,
        gl_account            VARCHAR2(150),
        fulfillment_line_id   NUMBER,
        returnable_qty        NUMBER,
        unit_new_price        NUMBER,
        unit_rebill_price     NUMBER,
        unit_finalbill_price  NUMBER,
        ship_date             DATE
    );
    TYPE xxtwc_claims_line_rec IS
        TABLE OF xxtwc_claims_line_rec_type INDEX BY BINARY_INTEGER;
    TYPE xxtwc_claims_lpn_lines_rec_type IS RECORD (
        claim_dtl_id     NUMBER,
        claim_id         NUMBER,
        ship_qty         NUMBER,
        claim_qty        NUMBER,
        lpn              VARCHAR2(50),
        lot_number       VARCHAR2(50),
        batch_number     VARCHAR2(50),
        header_id        VARCHAR2(100),
        fulfill_line_id  VARCHAR2(100),
        creation_date    TIMESTAMP(6),
        created_by       VARCHAR2(255),
        last_update_date TIMESTAMP(6),
        last_updated_by  VARCHAR2(255),
        attribute1       VARCHAR2(150),
        attribute2       VARCHAR2(150),
        attribute3       VARCHAR2(150),
        attribute4       VARCHAR2(150),
        attribute5       VARCHAR2(150),
        attribute_num1   NUMBER,
        attribute_num2   NUMBER,
        attribute_num3   NUMBER,
        attribute_num4   NUMBER,
        attribute_num5   NUMBER,
        attribute_date1  DATE,
        attribute_date2  DATE,
        attribute_date3  DATE,
        attribute_date4  DATE,
        attribute_date5  DATE,
        delivery_name    VARCHAR2(150)
    );
    TYPE xxtwc_claims_lpn_lines_rec IS
        TABLE OF xxtwc_claims_lpn_lines_rec_type INDEX BY BINARY_INTEGER;
    FUNCTION gen_claim_number RETURN VARCHAR2;

    PROCEDURE get_order_detail (
        p_order_number             IN VARCHAR2,
        p_org_id                   IN VARCHAR2,
        p_claim_type               IN VARCHAR2,
        --p_claim_id                 IN NUMBER,
        --p_claim_dtl_id             IN NUMBER,
        p_header_id                OUT VARCHAR2,
        p_xxtwc_claims_headers_rec OUT xxtwc_claims_headers%rowtype
    );

    PROCEDURE update_collection_member (
        p_collection_name IN VARCHAR2,
        p_seq_id          IN NUMBER,
        p_attr_number     IN NUMBER,
        p_value           IN VARCHAR2
    );

    PROCEDURE delete_collection_member (
        p_collection_name IN VARCHAR2,
        p_seq_id          IN NUMBER
    );

    PROCEDURE create_or_trunc_collections (
        p_collection_name IN VARCHAR2
    );

    PROCEDURE claim_creation (
        p_xxtwc_claims_headers_rec   IN xxtwc_claims_headers%rowtype,
        p_claim_id                   IN OUT NUMBER,
        p_claim_number               IN OUT VARCHAR2,
        p_error                      OUT VARCHAR2
    );

    PROCEDURE freight_claim_creation (
        p_xxtwc_claims_headers_rec IN xxtwc_claims_headers%rowtype,
        p_claim_id                 IN OUT NUMBER,
        p_claim_number             IN OUT VARCHAR2,
        p_error                    OUT VARCHAR2
    );

    PROCEDURE get_claim_header_details (
        p_claim_id                IN NUMBER,
        p_claim_number            IN VARCHAR2,
        p_xxtwc_claims_header_rec OUT xxtwc_claims_headers%rowtype,
        p_error                   OUT VARCHAR2
    );

    PROCEDURE get_claim_line_details (
        p_claim_id              IN NUMBER,
        p_xxtwc_claims_line_rec OUT xxtwc_claims_line_rec,
        p_error                 OUT VARCHAR2
    );

    PROCEDURE delete_claims (
        p_claim_id     IN NUMBER,
        p_claim_number IN VARCHAR2,
        p_error        OUT VARCHAR2,
        p_success      OUT VARCHAR2
    );

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
        
    );

    PROCEDURE update_department(
        p_claim_id  xxtwc_claims_headers.claim_id%TYPE
    );

    PROCEDURE full_claim(
        p_claim_id xxtwc_claims_headers.claim_id%TYPE
    );

    PROCEDURE clear_full_claim(
        p_claim_id xxtwc_claims_headers.claim_id%TYPE
    );

    PROCEDURE full_lot_claim(
        p_claim_id xxtwc_claims_headers.claim_id%TYPE,
        p_claim_dtl_id xxtwc_claims_lines.claim_id%TYPE
    );

    PROCEDURE clear_lot_claim(
        p_claim_id xxtwc_claims_headers.claim_id%TYPE,
         p_claim_dtl_id xxtwc_claims_lines.claim_id%TYPE
    );
    PROCEDURE update_claim_lines_price(
        p_claim_id xxtwc_claims_headers.claim_id%TYPE,
        p_header_id xxtwc_claims_headers.header_id%TYPE,
        p_claim_type xxtwc_claims_headers.claim_type%TYPE
    );
    PROCEDURE update_reason_code_all(
        p_claim_id xxtwc_claims_headers.claim_id%TYPE,
        p_reason_code xxtwc_claims_lines.claim_reason_code%type
    );
    FUNCTION get_reason_code_name (
        p_reason_code IN VARCHAR2
    ) RETURN VARCHAR2;

    FUNCTION get_reason_codes (
        p_claim_id IN NUMBER
    ) RETURN VARCHAR2;

    FUNCTION get_salesmanager(
        p_header_id IN VARCHAR2
    ) RETURN VARCHAR2;

    FUNCTION get_pending_approval_cnt(
        p_org_id IN VARCHAR2,
        p_user_name IN VARCHAR2
    ) RETURN NUMBER;

    FUNCTION check_claim_type(
        p_claim_type IN VARCHAR2
    )RETURN BOOLEAN;

END xxtwc_claims_insupd_pkg;

/