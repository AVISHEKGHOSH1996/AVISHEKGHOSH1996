/****************************************************************************************************
	Object Type: 	Package Body
	Name       :    XXTWC_CLAIMS_OUTBOUND_PKG
	Created by:		Trinamix
	Created On:		06/01/2023
	Description:	Package Body for Claims applications
	Modified On:	06/12/2023
	Reason:		    Modified for Freight Only claims
	Modified On:	15/09/2023
	Reason:		    Modified code for extended amount for RMA and SO
****************************************************************************************************/

--------------------------------------------------------
--  DDL for Package Body XXTWC_CLAIMS_OUTBOUND_PKG
--------------------------------------------------------

create or replace PACKAGE BODY  XXTWC_CLAIMS_OUTBOUND_PKG
AS
FUNCTION check_import_item(p_claim_id NUMBER, p_claim_dtl_id NUMBER) RETURN NUMBER
IS
  lv_import_count NUMBER;
BEGIN
  SELECT COUNT(1)
    INTO lv_import_count
    FROM xxtwc_claims_headers ch,
         xxtwc_claims_lines cl
  WHERE 1=1
    AND ch.claim_id = cl.claim_id
    AND ch.claim_id = p_claim_id
    AND cl.claim_dtl_id= p_claim_dtl_id
    AND cl.item_region = 'IM'
    AND cl.inventory_item_desc LIKE 'IM%';
    RETURN lv_import_count;
EXCEPTION
  WHEN OTHERS
  THEN
    lv_import_count:=0;
    RETURN lv_import_count;
END;

FUNCTION check_import_item(p_claim_id NUMBER) RETURN NUMBER
IS
  lv_import_count NUMBER;
BEGIN
  SELECT COUNT(1)
    INTO lv_import_count
    FROM xxtwc_claims_headers ch,
         xxtwc_claims_lines cl
  WHERE 1=1
    AND ch.claim_id = cl.claim_id
    AND ch.claim_id = p_claim_id
    AND cl.item_region = 'IM'
    AND cl.inventory_item_desc LIKE 'IM%';
    RETURN lv_import_count;
EXCEPTION
  WHEN OTHERS
  THEN
    lv_import_count:=0;
    RETURN lv_import_count;
END;

PROCEDURE main_proc
(  p_claim_id  NUMBER ,
   p_error OUT VARCHAR2	 	) IS

l_claim_type VARCHAR2(30);
l_supplier_name VARCHAR2(200);
l_error VARCHAR2(4000);
BEGIN

SELECT claim_type, supplier_name
INTO l_claim_type, l_supplier_name
FROM xxtwc_claims_headers
WHERE claim_id = p_claim_id;

IF l_claim_type = 'REJECTION_DIVERSION' THEN
  so_upload(p_claim_id,l_error);
  /* IF l_supplier_name IS NOT NULL THEN
    ap_inv_upload(p_claim_id);
   END IF;*/
  rma_upload(p_claim_id,l_error);
ELSIF l_claim_type = 'FREIGHT_ONLY' THEN
  freight_rma_upload(p_claim_id,l_error);
ELSIF l_claim_type = 'CREDIT_CLAIM' THEN
  credit_rma_upload(p_claim_id,l_error); 
ELSIF l_claim_type = 'AR_CLAIM' THEN
  ci_so_upload(p_claim_id,l_error);  
ELSIF l_claim_type = 'UNREFRENCE_CLAIM' THEN
  unrefer_rma_upload(p_claim_id,l_error);
ELSE 
  rma_upload(p_claim_id,l_error);
END IF;

COMMIT;

EXCEPTION
 WHEN OTHERS THEN
 raise_application_error('-20000','Error While Processing XXTWC_CLAIMS_OUTBOUND_PKG.main_proc:-'||sqlerrm);
 p_error := l_error||' Error While Processing XXTWC_CLAIMS_OUTBOUND_PKG.main_proc :-'||sqlerrm;
  xxtwc_claims_gp_error_pkg.gp_error_log ('Error', 
                                          sqlcode ,     
                                          SUBSTRB(l_error||' Error While Processing XXTWC_CLAIMS_OUTBOUND_PKG.main_proc :-'||sqlerrm,1,4000), 
                                          -1,
                                         -1,
										 p_claim_id
                                          );
END; 


PROCEDURE rma_upload
( p_claim_id  NUMBER ,
  p_error OUT VARCHAR2	) IS

CURSOR c_claim_details ( p_claim_id NUMBER) IS
SELECT 
  ch.claim_id,
  ch.claim_number,
  ch.claim_revision_number,
  ch.claim_date,
  ch.org_id,
  ch.bu_name,
  ch.claim_type,
  ch.order_number,
  ch.sold_to_customer_name,
  ( SELECT hp.party_number
    FROM fusion.hz_parties hp
    WHERE hp.party_id = ch.sold_to_customer_id
   ) sold_to_party_number,
  ch.header_id,
  DECODE(ch.claim_type,'RETURN_INVENTORY','RMA'||SUBSTRB(ch.claim_number,3,20),ch.claim_number) source_transaction_number,
  'OPS' source_transaction_system,
  DECODE(ch.claim_type,'RETURN_INVENTORY','RMA'||SUBSTRB(ch.claim_number,3,20),ch.claim_number)  source_transaction_id,
  dha.order_type_code  transaction_type_code,
  ch.warehouse_code	,
  doa_ship.party_id ship_to_party_id,
  hp_ship.party_name   ship_to_customer_name,
  hps_ship.party_site_id ship_to_site_id,
  hc_bill.cust_account_id bill_to_customer_id,
  hp_bill.party_name  bill_to_customer_name ,
  NVL( ( SELECT site_use_id
         FROM fusion.hz_cust_site_uses_all hzcsua1
         WHERE hzcsua.site_use_id =hzcsua1.site_use_id
         AND hzcsua1.status = 'A'
         AND TRUNC(SYSDATE) BETWEEN hzcsua1.start_date AND hzcsua1.end_date),
       ( SELECT site_use_id 
	     FROM fusion.hz_cust_site_uses_all hzcsua1,
              fusion.hz_cust_accounts hc_bill1,
              fusion.hz_cust_acct_sites_all hcs1
         WHERE hzcsua1.cust_acct_site_id = hcs1.cust_acct_site_id
         AND hcs1.cust_account_id = hc_bill1.cust_account_id 
         AND hzcsua1.site_use_code ='BILL_TO'
         AND hzcsua1.status = 'A'
         AND TRUNC(SYSDATE) BETWEEN hzcsua1.start_date AND hzcsua1.end_date
         AND hzcsua1.primary_flag ='Y'
         AND hc_bill1.cust_account_id = doa_bill.cust_acct_id)) bill_to_site_use_id,
  ch.claim_currency_code	,
  ch.claim_status,
  ch.csr_name, 
  ch.sales_person_id,
  ch.preventable,
  xxtwc_claims_outbound_pkg.get_claim_type_details(ch.claim_type, 'REBILL_TO_OTHER_CUSTOMER')  rebill_to_other_cust,     
  xxtwc_claims_outbound_pkg.get_claim_type_details(ch.claim_type, 'PRICE_ADJUSTMENT_ONLY')  price_adj_only,
  NVL(ch.inspection_required,'N') inspection_required,
  ch.creation_date,
  ch.created_by,
  ch.last_update_date,
  ch.last_updated_by,
  ch.last_updated_logon ,
  ch.claim_note,
  ch.po_number,
  ch.export_order,
  ch.consignment_order
FROM xxtwc_claims_headers ch,
     fusion.doo_headers_all dha,
     fusion.doo_order_addresses doa_ship,
     fusion.hz_parties hp_ship, 
     fusion.hz_party_sites hps_ship,       
     fusion.doo_order_addresses doa_bill,
     fusion.hz_cust_accounts hc_bill,
     fusion.hz_parties hp_bill,
     fusion.hz_cust_site_uses_all hzcsua
WHERE ch.header_id = dha.header_id
  AND doa_ship.header_id(+) = dha.header_id
  AND doa_ship.address_use_type(+) = 'SHIP_TO' 
  AND hp_ship.party_id(+) = doa_ship.party_id 
  AND hps_ship.party_site_id = doa_ship.party_site_id
  AND hps_ship.party_id = hp_ship.party_id
  AND doa_bill.header_id(+) = dha.header_id
  AND doa_bill.address_use_type(+) = 'BILL_TO'
  AND hp_bill.party_id(+) =  doa_bill.party_id 
  AND hc_bill.cust_account_id(+) = doa_bill.cust_acct_id
  AND doa_bill.cust_acct_site_use_id = hzcsua.site_use_id(+)
  AND  ch.claim_id = p_claim_id;

l_rma_exists VARCHAR2(2);
BEGIN

l_rma_exists := 'N';

 BEGIN
  SELECT 'Y'
  INTO l_rma_exists
  FROM xxtwc_claims_rma_headers_out rma
  WHERE rma.claim_id = p_claim_id;
 EXCEPTION
   WHEN OTHERS THEN
    l_rma_exists := 'N'; 
 END;

 IF l_rma_exists = 'N' THEN

  FOR l_claim_details IN c_claim_details(p_claim_id) LOOP

 INSERT INTO xxtwc_claims_rma_headers_out
 ( claim_id, 
   claim_number, 
   claim_revision_number, 
   claim_date, 
   org_id, 
   bu_name, 
   claim_type, 
   order_number, 
   sold_to_customer_name, 
   sold_to_party_number, 
   header_id, 
   source_transaction_number, 
   source_transaction_system, 
   source_transaction_id, 
   transaction_type_code, 
   requested_fulfil_org_code,
   ship_to_party_id, 
   ship_to_customer_name, 
   ship_to_site_id, 
   bill_to_customer_id, 
   bill_to_customer_name, 
   bill_to_site_use_id, 
   claim_currency_code, 
   claim_status,
   ora_rma_status,
   csr_name,
   preventable,
   rebill_to_other_cust,
   price_adj_only,
   inspection,
   process_type,
   sales_person_id,
   creation_date, 
   created_by, 
   last_update_date, 
   last_updated_by, 
   last_updated_logon,
   claim_note,
   po_number,
   export_order,
   consignment_order
   )
  VALUES
  ( l_claim_details.claim_id, 
   l_claim_details.claim_number, 
   l_claim_details.claim_revision_number, 
   l_claim_details.claim_date, 
   l_claim_details.org_id, 
   l_claim_details.bu_name, 
   l_claim_details.claim_type, 
   l_claim_details.order_number, 
   l_claim_details.sold_to_customer_name, 
   l_claim_details.sold_to_party_number, 
   l_claim_details.header_id, 
   l_claim_details.source_transaction_number, 
   l_claim_details.source_transaction_system, 
   l_claim_details.source_transaction_id, 
   l_claim_details.transaction_type_code, 
   l_claim_details.warehouse_code,
   l_claim_details.ship_to_party_id, 
   l_claim_details.ship_to_customer_name, 
   l_claim_details.ship_to_site_id, 
   l_claim_details.bill_to_customer_id, 
   l_claim_details.bill_to_customer_name, 
   l_claim_details.bill_to_site_use_id, 
   l_claim_details.claim_currency_code, 
   l_claim_details.claim_status,
   'NEW',
   l_claim_details.csr_name, 
   l_claim_details.preventable,
   l_claim_details.rebill_to_other_cust,
   l_claim_details.price_adj_only,
   l_claim_details.inspection_required,
   xxtwc_claims_outbound_pkg.get_claim_type_details(l_claim_details.claim_type, 'PROCESS_TYPE')  , 
   l_claim_details.sales_person_id,
   l_claim_details.creation_date, 
   l_claim_details.created_by, 
   l_claim_details.last_update_date, 
   l_claim_details.last_updated_by, 
   l_claim_details.last_updated_logon,
   NVL(l_claim_details.claim_note, 'NA') ,
   l_claim_details.po_number,
   l_claim_details.export_order,
   l_claim_details.consignment_order
   );
   DELETE xxtwc_claims_rma_lines_out
   WHERE claim_id = p_claim_id;  

   DELETE xxtwc_claims_rma_lines_lpn_out
   WHERE claim_id = p_claim_id;  

INSERT INTO xxtwc_claims_rma_lines_out
(
  claim_dtl_id,
  claim_id,
  claim_line_no,
  fulfillment_line_id,
  source_transaction_line_id,
  source_transaction_line_number,
  source_schedule_number,
  source_transaction_schedule_id,
  ordered_uom_code,
  claim_qty,
  inventory_item_number,
  inventory_item_id,
  transaction_category_code,
  transaction_line_type_code,
  unit_list_price,
  unit_selling_price,
  unit_adjustment_price,
  adjustment_amount,
  adjustment_type_code,
  charge_definition_code,
  charge_rollup_flag,
  charge_reason_code,
  source_manual_price_adj_id,
  fright_charges,
  return_reason_code,
  lpn,
  lot_number,
  currency_code,
  creation_date,
  created_by,
  last_update_date,
  last_updated_by )
SELECT claim_dtl_id,
  claim_id,
  claim_line_no,
  fulfillment_line_id, 
  ROWNUM source_transaction_lineid,
  ROWNUM source_transaction_line_number,
  ROWNUM source_schedule_number,
  ROWNUM sourcetransactionscheduleid,
  ordered_uom_code,
  claim_qty,
  inventory_item_number,
  inventory_item_id,
  transaction_category_code,
  transaction_line_type_code,
  unit_list_price,
  unit_selling_price,
  unit_adjustment_price,
  adjustment_amount,
  adjustment_type_code,
  charge_definition_code,
  charge_rollup_flag,
  charge_reason_code,
  claim_line_no,
  fright_charges,
  claim_reason_code, 
  lpn,
  lot_number,
  l_claim_details.claim_currency_code, 
  creation_date,
  created_by,
  last_update_date,
  last_updated_by 
FROM
(  
SELECT  
    lines.claim_dtl_id,
    lines.claim_id,
    lines.claim_line_no,
    lines.fulfillment_line_id, 
   (SELECT b.uom_code
    FROM fusion.inv_units_of_measure_b b,
        fusion.inv_units_of_measure_tl tl
    WHERE b.unit_of_measure_id = tl.unit_of_measure_id
    AND tl.language = 'US' 
    AND tl.unit_of_measure =lines.uom )   ordered_uom_code,
    lines.claim_qty ,
    lines.inventory_item_name inventory_item_number,
    lines.inventory_item_id,
    'RETURN' transaction_category_code,
    --'ORA_RETURN' transaction_line_type_code,
    xxtwc_claims_outbound_pkg.get_claim_type_details(l_claim_details.claim_type, 'TRANSACTION_LINE_TYPE')   transaction_line_type_code,
    -1*lines.unit_list_price unit_list_price,
    -1*lines.unit_selling_price unit_selling_price,
    -1*lines.unit_adjustment_price unit_adjustment_price,
    -1*lines.unit_adjustment_price*lines.claim_qty adjustment_amount,
    'PRICE_OVERRIDE' adjustment_type_code,
    'QP_SALE_PRICE' charge_definition_code,
    'false' charge_rollup_flag,
    xxtwc_claims_outbound_pkg.get_charge_reason_code(lines.claim_reason_code) charge_reason_code, 
    NULL fright_charges,
    lines.claim_reason_code, 
    NULL lpn,
    NULL lot_number,
   -- l_claim_details.claim_currency_code, 
    lines.creation_date,
    lines.created_by,
    lines.last_update_date,
    lines.last_updated_by 
FROM xxtwc_claims_lines lines 
WHERE 1=1
AND lines.claim_id = p_claim_id 
AND lines.claim_qty >0
UNION 
SELECT 
    lines.claim_dtl_id,
    lines.claim_id,
    lines.claim_line_no,
    null fulfillment_line_id, 
    esi1.primary_uom_code   ordered_uom_code,
    1,
    esi1.item_number inventory_item_number,
    esi1.inventory_item_id,
    'RETURN' transaction_category_code,
    xxtwc_claims_outbound_pkg.get_claim_type_details(l_claim_details.claim_type, 'TRANSACTION_LINE_TYPE')   transaction_line_type_code,
    -1*lines.fright_charges unit_list_price,
    -1*lines.fright_charges unit_selling_price,
    -1*lines.fright_charges unit_adjustment_price,
    -1*lines.fright_charges adjustment_amount,
    'PRICE_OVERRIDE' adjustment_type_code,
    'QP_SALE_PRICE' charge_definition_code,
    'false' charge_rollup_flag,
    xxtwc_claims_outbound_pkg.get_charge_reason_code(lines.claim_reason_code) charge_reason_code,
    NULL fright_charges,
    lines.claim_reason_code, 
    NULL lpn,
    NULL lot_number, 
 --   l_claim_details.claim_currency_code, 
    lines.creation_date,
    lines.created_by,
    lines.last_update_date,
    lines.last_updated_by 
FROM xxtwc_claims_lines lines,
     xxtwc_claims_headers head,
     fusion.egp_system_items_tl esi,
     fusion.egp_system_items_b esi1,
     fusion.inv_org_parameters orgp
WHERE lines.claim_id = p_claim_id 
AND lines.claim_id = head.claim_id 
--AND lines.unit_adjustment_price !=0 
--AND lines.claim_qty >0
AND lines.fright_charges !=0
AND esi.language = 'US'
AND esi.inventory_item_id = esi1.inventory_item_id
AND esi.organization_id = esi1.organization_id
AND orgp.organization_id = esi1.organization_id
AND orgp.organization_code= head.warehouse_code
AND esi1.item_number = (SELECT lookup_name
                        FROM claims.xxtwc_claims_lookups 
                        WHERE lookup_type ='FREIGHT_ONLY_ITEMS'
                        AND status =1
                        AND ROWNUM =1)
);

  IF (l_claim_details.claim_type IN ('REJECT_RETURN','RETURN_INVENTORY','IMPORT_CLAIM') )
     OR (XXTWC_CLAIMS_OUTBOUND_PKG.check_import_item(p_claim_id) > 0) 
  THEN

   INSERT INTO xxtwc_claims_rma_lines_lpn_out
   ( claim_dtl_id , 
     claim_id , 
     ship_qty , 
     claim_qty , 
     lpn,
     lot_number ,
     original_lpn_number,
     original_lot_number,
     batch_number,
     header_id,
     fulfill_line_id,
     creation_date,
     created_by,
     last_update_date,
     last_updated_by,
     delivery_name 
     )
   SELECT 
     claim_dtl_id , 
     claim_id , 
     ship_qty , 
     claim_qty , 
     lpn,     
     lot_number ,
     original_lpn_number,
     original_lot_number,
     batch_number,
     header_id,
     fulfill_line_id,
     creation_date,
     created_by,
     last_update_date,
     last_updated_by,
     delivery_name 
   FROM  xxtwc_claims_lpn_lines cll
   WHERE cll.claim_id = p_claim_id 
   AND cll.claim_qty >0; 

  END IF;

 END LOOP;
 END IF;
EXCEPTION
 WHEN OTHERS THEN
 raise_application_error('-20000','Error While Processing XXTWC_CLAIMS_OUTBOUND_PKG.rma_upload:-'||sqlerrm);
 p_error := 'Error While Processing XXTWC_CLAIMS_OUTBOUND_PKG.rma_upload :-'||sqlerrm;
 xxtwc_claims_gp_error_pkg.gp_error_log ('Error', 
                                          sqlcode ,     
                                          SUBSTRB('Error While Processing XXTWC_CLAIMS_OUTBOUND_PKG.rma_upload :-'||sqlerrm,1,4000), 
                                          -1,
                                         -1,
										 p_claim_id
                                          );
END;  

PROCEDURE so_upload 
( p_claim_id  NUMBER ,
  p_error OUT VARCHAR2	) IS
CURSOR c_claim_details ( p_claim_id NUMBER) IS
SELECT ch.claim_id,
  ch.claim_number,
  ch.claim_revision_number,
  ch.claim_date,
  ch.org_id,
  ch.bu_name,
  ch.claim_type,
  ch.order_number,
  ch.div_sold_to_customer_name,
  ( SELECT hp.party_number
    FROM fusion.hz_parties hp
    WHERE hp.party_id = ch.div_sold_to_customer_id
  ) div_sold_to_party_number,
  ch.header_id,
  'DIV'||SUBSTRB(ch.claim_number,3,20) source_transaction_number,
  'OPS' source_transaction_system,
  'DIV'||SUBSTRB(ch.claim_number,3,20) source_transaction_id,
  dha.order_type_code  transaction_type_code,
  ch.warehouse_code	,
  ch.div_ship_to_party_id ,
  ch.div_ship_to_customer_name,
  ch.div_ship_to_party_site_id,
  ch.div_bill_to_customer_id,
  ch.div_bill_to_customer_name,
  ch.div_bill_to_site_use_id,
  ch.claim_currency_code	,
  ch.claim_status,
  ch.csr_name,
  ch.preventable,
  ch.sales_person_id,
  --ch.po_number,
  'Rejection from '||ch.order_number po_number,
  ch.claim_note,
  ch.creation_date,
  ch.created_by,
  ch.last_update_date,
  ch.last_updated_by,
  ch.last_updated_logon,
  ch.export_order,
  ch.consignment_order
FROM xxtwc_claims_headers ch,
     fusion.doo_headers_all dha 
WHERE ch.header_id = dha.header_id 
AND  ch.claim_id = p_claim_id;

l_so_exists VARCHAR2(2);
l_max_line_id NUMBER;

BEGIN

l_so_exists := 'N';

 BEGIN
  SELECT 'Y'
  INTO l_so_exists
  FROM xxtwc_claims_so_headers_out so
  WHERE so.claim_id = p_claim_id;
 EXCEPTION
   WHEN OTHERS THEN
    l_so_exists := 'N'; 
 END;

 IF l_so_exists = 'N' THEN

  FOR l_claim_details IN c_claim_details(p_claim_id) LOOP

 INSERT INTO xxtwc_claims_so_headers_out
 ( claim_id, 
   claim_number, 
   claim_revision_number, 
   claim_date, 
   org_id, 
   bu_name, 
   claim_type, 
   order_number, 
   div_sold_to_customer_name, 
   div_sold_to_party_number, 
   header_id,
   source_transaction_number, 
   source_transaction_system, 
   source_transaction_id, 
   transaction_type_code, 
   requested_fulfil_org_code, 
   div_ship_to_party_id, 
   div_ship_to_customer_name, 
   div_ship_to_site_id, 
   div_bill_to_customer_id, 
   div_bill_to_customer_name, 
   div_bill_to_site_use_id, 
   claim_currency_code, 
   claim_status, 
   ora_so_status,
   csr_name,
   preventable,
   process_type,
   sales_person_id,
   po_number,   
   claim_note,
   creation_date, 
   created_by, 
   last_update_date, 
   last_updated_by, 
   last_updated_logon,
   export_order,
   consignment_order
   )
  VALUES
  ( l_claim_details.claim_id, 
   l_claim_details.claim_number, 
   l_claim_details.claim_revision_number, 
   l_claim_details.claim_date, 
   l_claim_details.org_id, 
   l_claim_details.bu_name, 
   l_claim_details.claim_type, 
   l_claim_details.order_number, 
   l_claim_details.div_sold_to_customer_name, 
   l_claim_details.div_sold_to_party_number, 
   l_claim_details.header_id,
   l_claim_details.source_transaction_number, 
   l_claim_details.source_transaction_system, 
   l_claim_details.source_transaction_id, 
   l_claim_details.transaction_type_code, 
   l_claim_details.warehouse_code, 
   l_claim_details.div_ship_to_party_id, 
   l_claim_details.div_ship_to_customer_name, 
   l_claim_details.div_ship_to_party_site_id, 
   l_claim_details.div_bill_to_customer_id, 
   l_claim_details.div_bill_to_customer_name, 
   l_claim_details.div_bill_to_site_use_id, 
   l_claim_details.claim_currency_code, 
   l_claim_details.claim_status, 
   'NEW',
   l_claim_details.csr_name, 
   l_claim_details.preventable, 
   xxtwc_claims_outbound_pkg.get_claim_type_details(l_claim_details.claim_type, 'PROCESS_TYPE')  , 
   l_claim_details.sales_person_id,
   l_claim_details.po_number,
   l_claim_details.claim_note,
   l_claim_details.creation_date, 
   l_claim_details.created_by, 
   l_claim_details.last_update_date, 
   l_claim_details.last_updated_by, 
   l_claim_details.last_updated_logon,   
   l_claim_details.export_order,
   l_claim_details.consignment_order
   );
   DELETE xxtwc_claims_so_lines_out
   WHERE claim_id = p_claim_id;

   DELETE xxtwc_claims_so_lines_lpn_out
   WHERE claim_id = p_claim_id;

   INSERT INTO xxtwc_claims_so_lines_out
(
   claim_dtl_id,
   claim_id,
   claim_line_no,
   fulfillment_line_id,
   source_transaction_lineid,
   source_transaction_line_number,
   source_schedule_number,
   source_transaction_schedule_id,
   ordered_uom_code,
   claim_qty,
   inventory_item_number,
   inventory_item_id,
   transaction_category_code,
   transaction_line_type_code,
   unit_list_price,
   unit_selling_price,
   unit_adjustment_price,
   adjustment_amount,
   adjustment_type_code,
   charge_definition_code,
   charge_rollup_flag,
   charge_reason_code,
   lpn,
   lot_number,
   source_manual_price_adj_id,
   fright_charges, 
   currency_code,
   creation_date,
   created_by,
   last_update_date,
   last_updated_by )
SELECT 
   claim_dtl_id,
   claim_id,
   claim_line_no,
   fulfillment_line_id, 
   ROWNUM source_transaction_lineid,
   ROWNUM source_transaction_line_number,
   ROWNUM source_schedule_number,
   ROWNUM sourcetransactionscheduleid, 
   ordered_uom_code,
   claim_qty,
   inventory_item_number,
   inventory_item_id,
   transaction_category_code,
   transaction_line_type_code,
   unit_list_price,
   unit_selling_price,
   unit_rebill_price,
   adjustment_amount,
   adjustment_type_code,
   charge_definition_code,
   charge_rollup_flag,
   charge_reason_code,
   lpn,
   lot_number,
   claim_line_no,
   fright_charges,
   l_claim_details.claim_currency_code, 
   creation_date,
   created_by,
   last_update_date,
   last_updated_by 
FROM 
(
 SELECT lines.claim_dtl_id,
   lines.claim_id,
   lines.claim_line_no,   
   lines.fulfillment_line_id, 
  (SELECT b.uom_code
   FROM fusion.inv_units_of_measure_b b,
        fusion.inv_units_of_measure_tl tl
   WHERE b.unit_of_measure_id = tl.unit_of_measure_id
   AND tl.language = 'US' 
   AND tl.unit_of_measure =lines.uom )   ordered_uom_code,
   lines.claim_qty,
   lines.inventory_item_name inventory_item_number,
   lines.inventory_item_id,
   'ORDER' transaction_category_code,
   'ORA_BUY' transaction_line_type_code,
   lines.unit_list_price,
   lines.unit_selling_price,
   lines.unit_rebill_price,
   lines.unit_rebill_price*lines.claim_qty adjustment_amount,
   'PRICE_OVERRIDE' adjustment_type_code,
   'QP_SALE_PRICE' charge_definition_code,
   'false' charge_rollup_flag,
   'CLAIM-GOODS PREVIOUSLY REJECTE' charge_reason_code,
   NULL lpn,
   NULL lot_number, 
   NULL fright_charges ,
   --l_claim_details.claim_currency_code, 
   lines.creation_date,
   lines.created_by,
   lines.last_update_date,
   lines.last_updated_by 
  FROM xxtwc_claims_lines lines 
  WHERE lines.claim_id = p_claim_id
  AND lines.unit_adjustment_price !=0 
  AND lines.claim_qty >0
  UNION
  SELECT lines.claim_dtl_id,
   lines.claim_id,
   lines.claim_line_no,
   null fulfillment_line_id, 
    esi1.primary_uom_code   ordered_uom_code,
   1,
   esi1.item_number inventory_item_number,
   esi1.inventory_item_id,
   'ORDER' transaction_category_code,
   'ORA_BUY' transaction_line_type_code,
   lines.fright_charges unit_list_price,
   lines.fright_charges unit_selling_price,
   lines.fright_charges unit_adjustment_price,
   lines.fright_charges adjustment_amount,
   'PRICE_OVERRIDE' adjustment_type_code,
   'QP_SALE_PRICE' charge_definition_code,
   'false' charge_rollup_flag,
   'CLAIM-GOODS PREVIOUSLY REJECTE' charge_reason_code,
   NULL lpn,
   NULL lot_number, 
   NULL fright_charges,
 --  l_claim_details.claim_currency_code, 
   lines.creation_date,
   lines.created_by,
   lines.last_update_date,
   lines.last_updated_by 
  FROM xxtwc_claims_lines lines,
      xxtwc_claims_headers head,
      fusion.egp_system_items_tl esi,
      fusion.egp_system_items_b esi1,
      fusion.inv_org_parameters orgp
  WHERE lines.claim_id = p_claim_id 
  AND lines.claim_id = head.claim_id 
  --AND lines.unit_adjustment_price !=0 
  --AND lines.claim_qty >0
  AND lines.fright_charges !=0
  AND esi.language = 'US'
  AND esi.inventory_item_id = esi1.inventory_item_id
  AND esi.organization_id = esi1.organization_id
  AND orgp.organization_id = esi1.organization_id
  AND  orgp.organization_code= head.warehouse_code
  AND esi1.item_number = ( SELECT lookup_name
                           FROM claims.xxtwc_claims_lookups 
                           WHERE lookup_type ='FREIGHT_ONLY_ITEMS'
                           AND status =1
                           AND ROWNUM =1)  
  );

    INSERT INTO xxtwc_claims_so_lines_lpn_out
   ( claim_dtl_id , 
     claim_id , 
     ship_qty , 
     claim_qty , 
     lpn,
     lot_number ,
     original_lpn_number,
     original_lot_number,
     batch_number,
     header_id,
     fulfill_line_id,
     creation_date,
     created_by,
     last_update_date,
     last_updated_by,
     delivery_name 
     )
   SELECT 
     claim_dtl_id , 
     claim_id , 
     ship_qty , 
     claim_qty , 
     lpn,
     lot_number ,
     original_lpn_number,
     original_lot_number,
     batch_number,
     header_id,
     fulfill_line_id,
     creation_date,
     created_by,
     last_update_date,
     last_updated_by,
     delivery_name 
   FROM  xxtwc_claims_lpn_lines cll
   WHERE cll.claim_id = p_claim_id 
   AND cll.claim_qty >0;   

 END LOOP;
 END IF;
EXCEPTION
 WHEN OTHERS THEN
 raise_application_error('-20000','Error While Processing XXTWC_CLAIMS_OUTBOUND_PKG.so_upload:-'||sqlerrm);
 p_error := 'Error While Processing XXTWC_CLAIMS_OUTBOUND_PKG.so_upload :-'||sqlerrm;
 xxtwc_claims_gp_error_pkg.gp_error_log ('Error', 
                                          sqlcode ,     
                                          SUBSTRB('Error While Processing XXTWC_CLAIMS_OUTBOUND_PKG.so_upload :-'||sqlerrm,1,4000), 
                                          -1,
                                         -1,
										 p_claim_id
                                          );
END;  

PROCEDURE freight_rma_upload
( p_claim_id  NUMBER ,
  p_error OUT VARCHAR2	) IS

CURSOR c_claim_details ( p_claim_id NUMBER) IS
SELECT frch.claim_id,
   frch.claim_number,
   frch.claim_revision_number,
   frch.claim_date,
   ch.org_id,
   ch.bu_name,
   frch.claim_type,
   frch.order_number,
   ch.sold_to_customer_name,
   ( SELECT hp.party_number
     FROM fusion.hz_parties hp
     WHERE hp.party_id = ch.sold_to_customer_id
   ) sold_to_party_number,
   ch.header_id,
   frch.claim_number source_transaction_number,
   'OPS' source_transaction_system,
   frch.claim_number  source_transaction_id,
   dha.order_type_code  transaction_type_code,
   frch.warehouse_code	,
   doa_ship.party_id ship_to_party_id,
   hp_ship.party_name   ship_to_customer_name,
   hps_ship.party_site_id ship_to_site_id,
   hc_bill.cust_account_id bill_to_customer_id,
   hp_bill.party_name  bill_to_customer_name ,
   NVL( ( SELECT site_use_id
          FROM fusion.hz_cust_site_uses_all hzcsua1
          WHERE hzcsua.site_use_id =hzcsua1.site_use_id
          AND hzcsua1.status = 'A'
          AND TRUNC(SYSDATE) BETWEEN hzcsua1.start_date AND hzcsua1.end_date),
        ( SELECT site_use_id 
	      FROM fusion.hz_cust_site_uses_all hzcsua1,
              fusion.hz_cust_accounts hc_bill1,
              fusion.hz_cust_acct_sites_all hcs1
          WHERE hzcsua1.cust_acct_site_id = hcs1.cust_acct_site_id
          AND hcs1.cust_account_id = hc_bill1.cust_account_id 
          AND hzcsua1.site_use_code ='BILL_TO'
          AND hzcsua1.status = 'A'
          AND TRUNC(SYSDATE) BETWEEN hzcsua1.start_date AND hzcsua1.end_date
          AND hzcsua1.primary_flag ='Y'
          AND hc_bill1.cust_account_id = doa_bill.cust_acct_id)) bill_to_site_use_id,
   frch.claim_currency_code	,
   frch.claim_status,
   frch.csr_name, 
   frch.sales_person_id,
   frch.preventable,
   xxtwc_claims_outbound_pkg.get_claim_type_details(frch.claim_type, 'REBILL_TO_OTHER_CUSTOMER')  rebill_to_other_cust,     
   xxtwc_claims_outbound_pkg.get_claim_type_details(frch.claim_type, 'PRICE_ADJUSTMENT_ONLY')  price_adj_only,
   NVL(frch.inspection_required,'N') inspection_required,
   ch.po_number,
   ch.claim_note,   
   frch.creation_date,
   frch.created_by,
   frch.last_update_date,
   frch.last_updated_by,
   frch.last_updated_logon, 
   frch.export_order,
   frch.consignment_order
FROM xxtwc_claims_headers ch,
     xxtwc_claims_headers frch,
     fusion.doo_headers_all dha,
     fusion.doo_order_addresses doa_ship,
     fusion.hz_parties hp_ship, 
     fusion.hz_party_sites hps_ship,       
     fusion.doo_order_addresses doa_bill,
     fusion.hz_cust_accounts hc_bill,
     fusion.hz_parties hp_bill,
     fusion.hz_cust_site_uses_all hzcsua
WHERE frch.orig_claim_id = ch.claim_id
  AND ch.header_id = dha.header_id
  AND doa_ship.header_id(+) = dha.header_id
  AND doa_ship.address_use_type(+) = 'SHIP_TO' 
  AND hp_ship.party_id(+) = doa_ship.party_id 
  AND hps_ship.party_site_id = doa_ship.party_site_id
  AND hps_ship.party_id = hp_ship.party_id
  AND doa_bill.header_id(+) = dha.header_id
  AND doa_bill.address_use_type(+) = 'BILL_TO'
  AND hp_bill.party_id(+) =  doa_bill.party_id 
  AND hc_bill.cust_account_id(+) = doa_bill.cust_acct_id
  AND doa_bill.cust_acct_site_use_id = hzcsua.site_use_id(+)
  AND frch.claim_id = p_claim_id;

l_rma_exists VARCHAR2(2);
BEGIN

l_rma_exists := 'N';

 BEGIN
  SELECT 'Y'
  INTO l_rma_exists
  FROM xxtwc_claims_rma_headers_out rma
  WHERE rma.claim_id = p_claim_id;
 EXCEPTION
   WHEN OTHERS THEN
    l_rma_exists := 'N'; 
 END;

 IF l_rma_exists = 'N' THEN

  FOR l_claim_details IN c_claim_details(p_claim_id) LOOP

 INSERT INTO xxtwc_claims_rma_headers_out
 ( claim_id, 
   claim_number, 
   claim_revision_number, 
   claim_date, 
   org_id, 
   bu_name, 
   claim_type, 
   order_number, 
   sold_to_customer_name, 
   sold_to_party_number, 
   header_id, 
   source_transaction_number, 
   source_transaction_system, 
   source_transaction_id, 
   transaction_type_code, 
   requested_fulfil_org_code,
   ship_to_party_id, 
   ship_to_customer_name, 
   ship_to_site_id, 
   bill_to_customer_id, 
   bill_to_customer_name, 
   bill_to_site_use_id, 
   claim_currency_code, 
   claim_status,
   ora_rma_status,
   csr_name,
   preventable,
   rebill_to_other_cust,
   price_adj_only,
   inspection,
   process_type,
   sales_person_id,
   po_number,
   claim_note,  
   creation_date, 
   created_by, 
   last_update_date, 
   last_updated_by, 
   last_updated_logon,
   export_order,
   consignment_order
   )
  VALUES
  ( l_claim_details.claim_id, 
   l_claim_details.claim_number, 
   l_claim_details.claim_revision_number, 
   l_claim_details.claim_date, 
   l_claim_details.org_id, 
   l_claim_details.bu_name, 
   l_claim_details.claim_type, 
   l_claim_details.order_number, 
   l_claim_details.sold_to_customer_name, 
   l_claim_details.sold_to_party_number, 
   l_claim_details.header_id, 
   l_claim_details.source_transaction_number, 
   l_claim_details.source_transaction_system, 
   l_claim_details.source_transaction_id, 
   l_claim_details.transaction_type_code, 
   l_claim_details.warehouse_code,
   l_claim_details.ship_to_party_id, 
   l_claim_details.ship_to_customer_name, 
   l_claim_details.ship_to_site_id, 
   l_claim_details.bill_to_customer_id, 
   l_claim_details.bill_to_customer_name, 
   l_claim_details.bill_to_site_use_id, 
   l_claim_details.claim_currency_code, 
   l_claim_details.claim_status,
   'NEW',
   l_claim_details.csr_name, 
   l_claim_details.preventable,
   l_claim_details.rebill_to_other_cust,
   l_claim_details.price_adj_only,
   l_claim_details.inspection_required,
   xxtwc_claims_outbound_pkg.get_claim_type_details(l_claim_details.claim_type, 'PROCESS_TYPE'), 
   l_claim_details.sales_person_id,
   l_claim_details.po_number,
   l_claim_details.claim_note,  
   l_claim_details.creation_date, 
   l_claim_details.created_by, 
   l_claim_details.last_update_date, 
   l_claim_details.last_updated_by, 
   l_claim_details.last_updated_logon,
   l_claim_details.export_order,
   l_claim_details.consignment_order
   );
   DELETE xxtwc_claims_rma_lines_out
   WHERE claim_id = p_claim_id;

INSERT INTO xxtwc_claims_rma_lines_out
(
   claim_dtl_id,
   claim_id,
   claim_line_no,
   fulfillment_line_id,
   source_transaction_line_id,
   source_transaction_line_number,
   source_schedule_number,
   source_transaction_schedule_id,
   ordered_uom_code,
   claim_qty,
   inventory_item_number,
   inventory_item_id,
   transaction_category_code,
   transaction_line_type_code,
   unit_list_price,
   unit_selling_price,
   unit_adjustment_price,
   adjustment_amount,
   adjustment_type_code,
   charge_definition_code,
   charge_rollup_flag,
   charge_reason_code,
   source_manual_price_adj_id,
   fright_charges,
   return_reason_code,
   lpn,
   lot_number,
   currency_code,
   creation_date,
   created_by,
   last_update_date,
   last_updated_by )
SELECT  lines.claim_dtl_id,
   lines.claim_id,
   lines.claim_line_no,
   lines.fulfillment_line_id,
--	claim_line_no source_transaction_lineid,
--	claim_line_no source_transaction_line_number,
--	claim_line_no source_schedule_number,
--	claim_line_no sourcetransactionscheduleid,
   ROWNUM source_transaction_lineid,
   ROWNUM source_transaction_line_number,
   ROWNUM source_schedule_number,
   ROWNUM sourcetransactionscheduleid,
   (SELECT b.uom_code
    FROM fusion.inv_units_of_measure_b b,
         fusion.inv_units_of_measure_tl tl
    WHERE b.unit_of_measure_id = tl.unit_of_measure_id
    AND tl.language = 'US' 
    AND tl.unit_of_measure =lines.uom )   ordered_uom_code,
   lines.claim_qty,
   lines.inventory_item_name inventory_item_number,
   lines.inventory_item_id,
   'RETURN' transaction_category_code, 
   xxtwc_claims_outbound_pkg.get_claim_type_details(l_claim_details.claim_type, 'TRANSACTION_LINE_TYPE') transaction_line_type_code,
   -1*lines.unit_list_price,
   -1*lines.unit_selling_price,
   -1*lines.unit_adjustment_price,
   -1*lines.extended_amount adjustment_amount,
   'PRICE_OVERRIDE' adjustment_type_code,
   'QP_SALE_PRICE' charge_definition_code,
   'false' charge_rollup_flag,
   xxtwc_claims_outbound_pkg.get_charge_reason_code(lines.claim_reason_code) charge_reason_code,
   lines.claim_line_no, 
   0 fright_charges,
   lines.claim_reason_code, 
   NULL lpn,
   NULL  lot_number,
   l_claim_details.claim_currency_code, 
   lines.creation_date,
   lines.created_by,
   lines.last_update_date,
   lines.last_updated_by 
FROM xxtwc_claims_lines lines ,
     xxtwc_claims_headers ch
WHERE 1=1
AND lines.claim_id = ch.claim_id
AND lines.claim_id = p_claim_id 
AND lines.claim_qty >0;

 END LOOP;
 END IF;
EXCEPTION
 WHEN OTHERS THEN
 raise_application_error('-20000','Error While Processing XXTWC_CLAIMS_OUTBOUND_PKG.freight_rma_upload:-'||sqlerrm);
 p_error := 'Error While Processing XXTWC_CLAIMS_OUTBOUND_PKG.freight_rma_upload :-'||sqlerrm;
 xxtwc_claims_gp_error_pkg.gp_error_log ('Error', 
                                          sqlcode ,     
                                          SUBSTRB('Error While Processing XXTWC_CLAIMS_OUTBOUND_PKG.freight_rma_upload :-'||sqlerrm,1,4000), 
                                          -1,
                                         -1,
										 p_claim_id
                                          );
END;

--Unreferenced RMA

PROCEDURE unrefer_rma_upload
( p_claim_id  NUMBER ,
  p_error OUT VARCHAR2	) IS

CURSOR c_claim_details ( p_claim_id NUMBER) IS
SELECT ch.claim_id,
   ch.claim_number,
   ch.claim_revision_number,
   ch.claim_date,
   ch.org_id,
   ch.bu_name,
   ch.claim_type,
   ch.order_number,
   ch.sold_to_customer_name,
   ( SELECT hp.party_number
     FROM fusion.hz_parties hp
     WHERE hp.party_id = ch.sold_to_customer_id
   ) sold_to_party_number,
   ch.header_id,
   ch.claim_number source_transaction_number,
   'OPS' source_transaction_system,
   ch.claim_number source_transaction_id,
   dha.order_type_code  transaction_type_code,
   ch.warehouse_code	,
   doa_ship.party_id ship_to_party_id,
   hp_ship.party_name   ship_to_customer_name,
   hps_ship.party_site_id ship_to_site_id,
   hc_bill.cust_account_id bill_to_customer_id,
   hp_bill.party_name  bill_to_customer_name ,
   NVL( ( SELECT site_use_id
          FROM fusion.hz_cust_site_uses_all hzcsua1
          WHERE hzcsua.site_use_id =hzcsua1.site_use_id
          AND hzcsua1.status = 'A'
          AND TRUNC(SYSDATE) BETWEEN hzcsua1.start_date AND hzcsua1.end_date),
        ( SELECT site_use_id 
	      FROM fusion.hz_cust_site_uses_all hzcsua1,
              fusion.hz_cust_accounts hc_bill1,
              fusion.hz_cust_acct_sites_all hcs1
          WHERE hzcsua1.cust_acct_site_id = hcs1.cust_acct_site_id
          AND hcs1.cust_account_id = hc_bill1.cust_account_id 
          AND hzcsua1.site_use_code ='BILL_TO'
          AND hzcsua1.status = 'A'
          AND TRUNC(SYSDATE) BETWEEN hzcsua1.start_date AND hzcsua1.end_date
          AND hzcsua1.primary_flag ='Y'
          AND hc_bill1.cust_account_id = doa_bill.cust_acct_id)) bill_to_site_use_id,
   ch.claim_currency_code	,
   ch.claim_status,
   ch.csr_name, 
   ch.sales_person_id,
   ch.preventable,
   xxtwc_claims_outbound_pkg.get_claim_type_details(ch.claim_type, 'REBILL_TO_OTHER_CUSTOMER')  rebill_to_other_cust,     
   xxtwc_claims_outbound_pkg.get_claim_type_details(ch.claim_type, 'PRICE_ADJUSTMENT_ONLY')  price_adj_only,
   NVL(ch.inspection_required,'N') inspection_required,
   ch.po_number,
   ch.claim_note,      
   ch.creation_date,
   ch.created_by,
   ch.last_update_date,
   ch.last_updated_by,
   ch.last_updated_logon, 
   ch.export_order,
   ch.consignment_order 
FROM xxtwc_claims_headers ch,
     fusion.doo_headers_all dha,
     fusion.doo_order_addresses doa_ship,
     fusion.hz_parties hp_ship, 
     fusion.hz_party_sites hps_ship,       
     fusion.doo_order_addresses doa_bill,
     fusion.hz_cust_accounts hc_bill,
     fusion.hz_parties hp_bill,
     fusion.hz_cust_site_uses_all hzcsua
WHERE 1=1
  AND ch.header_id = dha.header_id
  AND doa_ship.header_id(+) = dha.header_id
  AND doa_ship.address_use_type(+) = 'SHIP_TO' 
  AND hp_ship.party_id(+) = doa_ship.party_id 
  AND hps_ship.party_site_id = doa_ship.party_site_id
  AND hps_ship.party_id = hp_ship.party_id
  AND doa_bill.header_id(+) = dha.header_id
  AND doa_bill.address_use_type(+) = 'BILL_TO'
  AND hp_bill.party_id(+) =  doa_bill.party_id 
  AND hc_bill.cust_account_id(+) = doa_bill.cust_acct_id
  AND doa_bill.cust_acct_site_use_id = hzcsua.site_use_id(+)
  AND ch.claim_id = p_claim_id;

  l_rma_exists VARCHAR2(2);
BEGIN

  l_rma_exists := 'N';

 BEGIN
  SELECT 'Y'
  INTO l_rma_exists
  FROM xxtwc_claims_rma_headers_out rma
  WHERE rma.claim_id = p_claim_id;
 EXCEPTION
   WHEN OTHERS THEN
    l_rma_exists := 'N'; 
 END;

 IF l_rma_exists = 'N' THEN

FOR l_claim_details IN c_claim_details(p_claim_id) LOOP

 INSERT INTO xxtwc_claims_rma_headers_out
 ( claim_id, 
   claim_number, 
   claim_revision_number, 
   claim_date, 
   org_id, 
   bu_name, 
   claim_type, 
   order_number, 
   sold_to_customer_name, 
   sold_to_party_number, 
   header_id, 
   source_transaction_number, 
   source_transaction_system, 
   source_transaction_id, 
   transaction_type_code, 
   requested_fulfil_org_code,
   ship_to_party_id, 
   ship_to_customer_name, 
   ship_to_site_id, 
   bill_to_customer_id, 
   bill_to_customer_name, 
   bill_to_site_use_id, 
   claim_currency_code, 
   claim_status,
   ora_rma_status,
   csr_name,
   preventable,
   rebill_to_other_cust,
   price_adj_only,
   inspection,
   process_type,
   sales_person_id,
   po_number,
   claim_note,
   creation_date, 
   created_by, 
   last_update_date, 
   last_updated_by, 
   last_updated_logon,
   export_order,
   consignment_order 
   )
  VALUES
  ( l_claim_details.claim_id, 
   l_claim_details.claim_number, 
   l_claim_details.claim_revision_number, 
   l_claim_details.claim_date, 
   l_claim_details.org_id, 
   l_claim_details.bu_name, 
   l_claim_details.claim_type, 
   l_claim_details.order_number, 
   l_claim_details.sold_to_customer_name, 
   l_claim_details.sold_to_party_number, 
   l_claim_details.header_id, 
   l_claim_details.source_transaction_number, 
   l_claim_details.source_transaction_system, 
   l_claim_details.source_transaction_id, 
   l_claim_details.transaction_type_code, 
   l_claim_details.warehouse_code,
   l_claim_details.ship_to_party_id, 
   l_claim_details.ship_to_customer_name, 
   l_claim_details.ship_to_site_id, 
   l_claim_details.bill_to_customer_id, 
   l_claim_details.bill_to_customer_name, 
   l_claim_details.bill_to_site_use_id, 
   l_claim_details.claim_currency_code, 
   l_claim_details.claim_status,
   'NEW',
   l_claim_details.csr_name, 
   l_claim_details.preventable,
   l_claim_details.rebill_to_other_cust,
   l_claim_details.price_adj_only,
   l_claim_details.inspection_required,
   xxtwc_claims_outbound_pkg.get_claim_type_details(l_claim_details.claim_type, 'PROCESS_TYPE'), 
   l_claim_details.sales_person_id,
   l_claim_details.po_number,
   l_claim_details.claim_note,
   l_claim_details.creation_date, 
   l_claim_details.created_by, 
   l_claim_details.last_update_date, 
   l_claim_details.last_updated_by, 
   l_claim_details.last_updated_logon,
   l_claim_details.export_order,
   l_claim_details.consignment_order 
   );
   DELETE xxtwc_claims_rma_lines_out
   WHERE claim_id = p_claim_id;

INSERT INTO xxtwc_claims_rma_lines_out
(
   claim_dtl_id,
   claim_id,
   claim_line_no,
   fulfillment_line_id,
   source_transaction_line_id,
   source_transaction_line_number,
   source_schedule_number,
   source_transaction_schedule_id,
   ordered_uom_code,
   claim_qty,
   inventory_item_number,
   inventory_item_id,
   transaction_category_code,
   transaction_line_type_code,
   unit_list_price,
   unit_selling_price,
   unit_adjustment_price,
   adjustment_amount,
   adjustment_type_code,
   charge_definition_code,
   charge_rollup_flag,
   charge_reason_code,
   source_manual_price_adj_id,
   fright_charges,
   return_reason_code,
   lpn,
   lot_number,
   currency_code,
   creation_date,
   created_by,
   last_update_date,
   last_updated_by )
SELECT  lines.claim_dtl_id,
   lines.claim_id,
   lines.claim_line_no,
   lines.fulfillment_line_id,
--	claim_line_no source_transaction_lineid,
--	claim_line_no source_transaction_line_number,
--	claim_line_no source_schedule_number,
--	claim_line_no sourcetransactionscheduleid,
   ROWNUM source_transaction_lineid,
   ROWNUM source_transaction_line_number,
   ROWNUM source_schedule_number,
   ROWNUM sourcetransactionscheduleid,
   ( SELECT b.uom_code
     FROM fusion.inv_units_of_measure_b b,
          fusion.inv_units_of_measure_tl tl
    WHERE b.unit_of_measure_id = tl.unit_of_measure_id
    AND tl.language = 'US' 
    AND tl.unit_of_measure =lines.uom )   ordered_uom_code,
   lines.claim_qty,
   lines.inventory_item_name inventory_item_number,
   lines.inventory_item_id,
   'RETURN' transaction_category_code, 
   xxtwc_claims_outbound_pkg.get_claim_type_details(l_claim_details.claim_type, 'TRANSACTION_LINE_TYPE')  transaction_line_type_code,
   -1*lines.unit_list_price,
   -1*lines.unit_selling_price,
   -1*lines.unit_adjustment_price,
   -1*lines.extended_amount adjustment_amount,
   'PRICE_OVERRIDE' adjustment_type_code,
   'QP_SALE_PRICE' charge_definition_code,
   'false' charge_rollup_flag,
   xxtwc_claims_outbound_pkg.get_charge_reason_code(lines.claim_reason_code) charge_reason_code,
   lines.claim_line_no, 
   0 fright_charges,
   lines.claim_reason_code, 
   NULL lpn,
   NULL  lot_number,
   l_claim_details.claim_currency_code, 
   lines.creation_date,
   lines.created_by,
   lines.last_update_date,
   lines.last_updated_by 
FROM xxtwc_claims_lines lines ,
     xxtwc_claims_headers ch
WHERE 1=1
AND lines.claim_id = ch.claim_id
AND lines.claim_id = p_claim_id 
AND lines.claim_qty >0;

 END LOOP;
 END IF;
EXCEPTION
 WHEN OTHERS THEN
 raise_application_error('-20000','Error While Processing XXTWC_CLAIMS_OUTBOUND_PKG.unrefer_rma_upload:-'||sqlerrm);
 p_error := 'Error While Processing XXTWC_CLAIMS_OUTBOUND_PKG.unrefer_rma_upload :-'||sqlerrm;
 xxtwc_claims_gp_error_pkg.gp_error_log ('Error', 
                                          sqlcode ,     
                                          SUBSTRB('Error While Processing XXTWC_CLAIMS_OUTBOUND_PKG.unrefer_rma_upload :-'||sqlerrm,1,4000),
                                          -1,
                                         -1,
										 p_claim_id
                                          ); 
END;

FUNCTION get_claim_type_details 
 ( p_claim_type VARCHAR2,
   p_attribute VARCHAR2)
RETURN VARCHAR2 IS

 l_process_type VARCHAR(20);
 l_transaction_line_type  VARCHAR(40);
 l_rebill_to_other_customer VARCHAR(1);
 l_price_adjustment_only  VARCHAR(1);
BEGIN
 SELECT Attribute2,
        Attribute3,
        Attribute4,
        Attribute5
 INTO   l_process_type,
        l_transaction_line_type,
        l_rebill_to_other_customer,
        l_price_adjustment_only
 FROM  claims.xxtwc_claims_lookups 
 WHERE lookup_type ='CLAIM_TYPE'
 AND lookup_name = p_claim_type;

IF p_attribute = 'PROCESS_TYPE' THEN
  RETURN l_process_type;
ELSIF p_attribute = 'TRANSACTION_LINE_TYPE' THEN
  RETURN l_transaction_line_type;
ELSIF p_attribute = 'REBILL_TO_OTHER_CUSTOMER' THEN
  RETURN l_rebill_to_other_customer;
ELSIF p_attribute = 'PRICE_ADJUSTMENT_ONLY' THEN
  RETURN l_price_adjustment_only;
END IF;

EXCEPTION
  WHEN OTHERS THEN 
   raise_application_error('-20000','Error While Processing XXTWC_CLAIMS_OUTBOUND_PKG.get_claim_type_details:-'||sqlerrm);
END;

FUNCTION get_charge_reason_code 
 ( p_return_reason_code VARCHAR2 )
RETURN VARCHAR2 IS

 l_charge_reason_code VARCHAR(100); 
 l_reason_type VARCHAR2(20);
BEGIN
 SELECT tag
 INTO   l_reason_type
 FROM  fusion.fnd_lookup_values a
 WHERE lookup_type ='DOO_RETURN_REASON'
 AND LANGUAGE ='US'
 AND tag IN ('CARRIER','OPERATIONS','QUALITY','SALES')
 AND lookup_code = p_return_reason_code;

IF l_reason_type = 'OPERATIONS' OR l_reason_type ='QUALITY' THEN
   l_charge_reason_code := 'ORA_SALES_NEGOTIATION';
ELSIF p_return_reason_code = 'SALES_257' THEN
   l_charge_reason_code := 'CLAIM-CONSIGNMENT PRICE FINALI';
ELSIF p_return_reason_code = 'SALES_262' OR p_return_reason_code= 'SALES_264' THEN
   l_charge_reason_code := 'ORA_ERROR_CORRECTION'; 
ELSE
   l_charge_reason_code := 'ORA_SALES_NEGOTIATION';
END IF;
RETURN l_charge_reason_code;
EXCEPTION
  WHEN OTHERS THEN 
   l_charge_reason_code := 'ORA_SALES_NEGOTIATION';
   RETURN l_charge_reason_code;   
END;

PROCEDURE split_line_quantity
(  p_claim_id  NUMBER ,
   p_claim_dtl_id NUMBER ,
   p_fulfill_id NUMBER,
   p_claim_qty NUMBER   ) 
IS
l_claim_type VARCHAR2(30);
l_line_type VARCHAR2(30);
l_so_header_id NUMBER;
l_error VARCHAR2(4000);
l_running_qty NUMBER;
l_lpn_qty_used NUMBER;
l_lpn_qty_available NUMBER;
l_claim_qty NUMBER;
l_total_ship_qty  NUMBER;
l_last_line_qty NUMBER;
l_line_count number;
/*
CURSOR c_lpn IS
SELECT lpn_rowid rowid1, gt.*
FROM claims.xxtwc_claims_lpn_lines_gt gt
WHERE fulfill_line_id = p_fulfill_id;
*/

  CURSOR lpn_cur IS 
  /*
  SELECT rowid rowid1, lpn.* 
    FROM xxtwc_claims_lpn_lines lpn 
   WHERE claim_id = p_claim_id and claim_dtl_id = p_claim_dtl_id;
  */
  SELECT rowid rowid1,tmp.*, rownum
    FROM (select *
            from xxtwc_claims_lpn_lines 
           where claim_id = p_claim_id and claim_dtl_id = p_claim_dtl_id ) tmp;
  CURSOR sum_qty_cur IS
  SELECT SUM(ship_qty) 
    FROM xxtwc_claims_lpn_lines 
   WHERE claim_id = p_claim_id and claim_dtl_id = p_claim_dtl_id;

BEGIN

  SELECT count(1) 
    INTO l_line_count 
    FROM xxtwc_claims_lpn_lines 
   WHERE claim_id = p_claim_id and claim_dtl_id = p_claim_dtl_id;

  OPEN sum_qty_cur;
  FETCH sum_qty_cur INTO l_total_ship_qty;
  CLOSE sum_qty_cur;

  l_running_qty := 0;

  FOR i IN lpn_cur
  LOOP
    l_claim_qty := ROUND((i.ship_qty/l_total_ship_qty)*p_claim_qty); 
    l_running_qty := l_running_qty+l_claim_qty;
    l_lpn_qty_available := p_claim_qty - l_running_qty;
    IF i.rownum = l_line_count
    THEN    
      l_last_line_qty := l_claim_qty+l_lpn_qty_available;

      UPDATE claims.xxtwc_claims_lpn_lines  lpn
       SET claim_qty = l_last_line_qty
      WHERE lpn.rowid = i.rowid1 and claim_dtl_id = p_claim_dtl_id;
    ELSE
      UPDATE claims.xxtwc_claims_lpn_lines  lpn
       SET claim_qty = l_claim_qty
      WHERE lpn.rowid = i.rowid1 and claim_dtl_id = p_claim_dtl_id;
    END IF;  
  END LOOP;

  COMMIT;
/* 
SELECT claim_type,
       lkp.attribute3,
       ch.header_id	   
INTO l_claim_type,
     l_line_type,
	 l_so_header_id
FROM claims.xxtwc_claims_headers ch,
     claims.xxtwc_claims_lookups lkp
WHERE claim_id = p_claim_id
AND lookup_type ='CLAIM_TYPE' 
AND lookup_name = claim_type;

DELETE claims.xxtwc_claims_lpn_lines_gt
WHERE fulfill_line_id = p_fulfill_id;

INSERT INTO claims.xxtwc_claims_lpn_lines_gt
 (
  claim_dtl_id , 
  claim_id , 
  ship_qty , 
  claim_qty , 
  lpn, 
  lot_number, 
  batch_number, 
  header_id, 
  fulfill_line_id,
  original_lpn_number,
  lpn_rowid
  )
SELECT claim_dtl_id,
       claim_id,
	   ship_qty,
	   NULL,
	   lpn ,
	   lot_number,
	   NULL,
	   header_id,
	   fulfill_line_id,
       original_lpn_number,
	   rowid
FROM claims.xxtwc_claims_lpn_lines  
WHERE claim_dtl_id = p_claim_dtl_id;

IF l_line_type = 'ORA_CREDIT_ONLY' THEN
l_running_qty := NULL;
FOR l_lpn IN c_lpn LOOP

 IF l_running_qty IS NULL THEN
  IF l_lpn.ship_qty <= p_claim_qty THEN
     UPDATE claims.xxtwc_claims_lpn_lines_gt
	 SET claim_qty = l_lpn.ship_qty
	 WHERE lpn_rowid = l_lpn.rowid1;
	 l_running_qty := p_claim_qty - l_lpn.ship_qty;
  ELSE
     UPDATE claims.xxtwc_claims_lpn_lines_gt
	 SET claim_qty = p_claim_qty
	 WHERE lpn_rowid = l_lpn.rowid1;
	 l_running_qty := 0;  
  END IF;
 ELSE
 IF l_running_qty >0 THEN
   IF l_lpn.ship_qty <= l_running_qty THEN
     UPDATE claims.xxtwc_claims_lpn_lines_gt
	 SET claim_qty = l_lpn.ship_qty
	 WHERE lpn_rowid = l_lpn.rowid1;
	 l_running_qty := l_running_qty - l_lpn.ship_qty;
  ELSE
     UPDATE claims.xxtwc_claims_lpn_lines_gt
	 SET claim_qty = l_running_qty
	 WHERE lpn_rowid = l_lpn.rowid1;
	 l_running_qty := 0;  
  END IF;
 END IF;
 END IF;

END LOOP;
ELSE
l_running_qty := NULL;
FOR l_lpn IN c_lpn LOOP

l_lpn_qty_used :=0;
l_lpn_qty_available := 0;
BEGIN

  begin

  IF l_lpn.original_lpn_number IS NOT NULL
  THEN
     SELECT SUM(claim_qty)
     INTO l_lpn_qty_used
     FROM
     (
     SELECT rma_lpn.fulfill_line_id,
            rma_lpn.lpn,
            rma_lpn.original_lpn_number,
            rma_lpn.lot_number,
            rma_lpn.claim_qty
     FROM xxtwc_claims_rma_headers_out rma_header,
          xxtwc_claims_rma_lines_lpn_out rma_lpn,
          claims.xxtwc_claims_lookups lkp
     WHERE 1=1
     AND lookup_type ='CLAIM_TYPE' 
     AND lkp.attribute3 ='ORA_RETURN'
     AND lookup_name = rma_header.claim_type
     AND rma_header.claim_id = rma_lpn.claim_id
     AND rma_header.ora_rma_no IS NOT NULL
     AND rma_lpn.fulfill_line_id = l_lpn.fulfill_line_id
     AND rma_lpn.lpn = l_lpn.lpn
     AND rma_lpn.lot_number = l_lpn.lot_number
     AND rma_lpn.original_lpn_number = l_lpn.original_lpn_number
     UNION ALL
     SELECT rma_lpn.fulfill_line_id,
            rma_lpn.lpn,
            rma_lpn.original_lpn_number,
            rma_lpn.lot_number,
            rma_lpn.claim_qty
     FROM xxtwc_claims_lpn_lines_gt rma_lpn
     WHERE rma_lpn.fulfill_line_id = l_lpn.fulfill_line_id
     AND rma_lpn.lpn = l_lpn.lpn
     AND rma_lpn.lot_number = l_lpn.lot_number
     AND rma_lpn.original_lpn_number = l_lpn.original_lpn_number
     AND rma_lpn.claim_qty IS NOT NULL)
     GROUP BY fulfill_line_id,
              lpn,
              lot_number,
              original_lpn_number;
  ELSE
     SELECT SUM(claim_qty)
     INTO l_lpn_qty_used
     FROM
     (
     SELECT rma_lpn.fulfill_line_id,
            rma_lpn.lpn,
                rma_lpn.lot_number,
                rma_lpn.claim_qty
     FROM xxtwc_claims_rma_headers_out rma_header,
          xxtwc_claims_rma_lines_lpn_out rma_lpn,
          claims.xxtwc_claims_lookups lkp
     WHERE 1=1-- claim_id = p_claim_id
     AND lookup_type ='CLAIM_TYPE' 
     AND lkp.attribute3 ='ORA_RETURN'
     AND lookup_name = rma_header.claim_type
     AND rma_header.claim_id = rma_lpn.claim_id
     AND rma_header.ora_rma_no IS NOT NULL
     AND rma_lpn.fulfill_line_id = l_lpn.fulfill_line_id
     AND rma_lpn.lpn = l_lpn.lpn
     AND rma_lpn.lot_number = l_lpn.lot_number
     AND rma_lpn.original_lpn_number IS NULL
     UNION ALL
     SELECT rma_lpn.fulfill_line_id,
            rma_lpn.lpn,
                rma_lpn.lot_number,
                rma_lpn.claim_qty
     FROM xxtwc_claims_lpn_lines_gt rma_lpn
     WHERE rma_lpn.fulfill_line_id = l_lpn.fulfill_line_id
     AND rma_lpn.lpn = l_lpn.lpn
     AND rma_lpn.lot_number = l_lpn.lot_number
     AND rma_lpn.original_lpn_number IS NULL
     AND rma_lpn.claim_qty IS NOT NULL)
     GROUP BY fulfill_line_id,
              lpn,
              lot_number;
  END IF;

  exception
    when others  then
      l_lpn_qty_used := 0;
  end;
EXCEPTION
 WHEN OTHERS THEN
   raise;     
END; 

  l_lpn_qty_available := l_lpn.ship_qty - l_lpn_qty_used;

 IF l_running_qty IS NULL THEN
  IF l_lpn_qty_available <= p_claim_qty THEN
     UPDATE claims.xxtwc_claims_lpn_lines_gt
	 SET claim_qty = l_lpn_qty_available
	 WHERE lpn_rowid = l_lpn.rowid1;
	 l_running_qty := p_claim_qty - l_lpn_qty_available;
  ELSE
     UPDATE claims.xxtwc_claims_lpn_lines_gt
	 SET claim_qty = p_claim_qty
	 WHERE lpn_rowid = l_lpn.rowid1;
	 l_running_qty := 0;  
  END IF;
 ELSE
 IF l_running_qty >0 THEN
   IF l_lpn_qty_available <= l_running_qty THEN
     UPDATE claims.xxtwc_claims_lpn_lines_gt
	 SET claim_qty = l_lpn_qty_available
	 WHERE lpn_rowid = l_lpn.rowid1;
	 l_running_qty := l_running_qty - l_lpn_qty_available;
  ELSE
     UPDATE claims.xxtwc_claims_lpn_lines_gt
	 SET claim_qty = l_running_qty
	 WHERE lpn_rowid = l_lpn.rowid1;
	 l_running_qty := 0;  
  END IF;

 END IF;
 END IF;
END LOOP;
END IF;

UPDATE claims.xxtwc_claims_lpn_lines  lpn
SET claim_qty = ( SELECT claim_qty
                  FROM claims.xxtwc_claims_lpn_lines_gt gt
				  WHERE gt.claim_dtl_id = p_claim_dtl_id
				  AND lpn.rowid = gt.lpn_rowid)
WHERE lpn.claim_dtl_id = p_claim_dtl_id;
*/

/* Added By Apporva 01/09/2023 */

for i in (select * from claims.xxtwc_claims_lines where claim_id = p_claim_id and claim_dtl_id = p_claim_dtl_id) loop
    BEGIN
        SELECT SUM(lpn.claim_qty) into l_claim_qty FROM  claims.xxtwc_claims_lpn_lines lpn WHERE lpn.claim_id = i.claim_id AND lpn.claim_dtl_id = i.claim_dtl_id;
    EXCEPTION
        WHEN OTHERS THEN
        l_claim_qty := 0;
    END;


    claims.xxtwc_Claims_insupd_pkg.update_claim_lines(
        p_claim_id                =>p_claim_id,
        p_claim_dtl_id            =>p_claim_dtl_id,
        p_claim_qty               =>l_claim_qty,
        p_unit_adjustment_price   =>i.unit_adjustment_price,
        p_extended_amount         => l_claim_qty *i.unit_adjustment_price,
        p_fright_charges          => i.fright_charges ,
        p_claim_reason_code       => i.claim_reason_code,
        p_unit_new_price          => i.unit_new_price,
        p_unit_rebill_price       => i.unit_rebill_price
    );
end loop;

COMMIT;

EXCEPTION
 WHEN OTHERS THEN
  raise;
END;

--Misc Charges -- Credit RMA

PROCEDURE credit_rma_upload
( p_claim_id  NUMBER ,
  p_error OUT VARCHAR2	) IS

CURSOR c_claim_details ( p_claim_id NUMBER) IS
SELECT frch.claim_id,
   frch.claim_number,
   frch.claim_revision_number,
   frch.claim_date,
   ch.org_id,
   ch.bu_name,
   frch.claim_type,
   frch.order_number,
   ch.sold_to_customer_name,
   ( SELECT hp.party_number
     FROM fusion.hz_parties hp
     WHERE hp.party_id = ch.sold_to_customer_id
   ) sold_to_party_number,
   ch.header_id,
   frch.claim_number source_transaction_number,
   'OPS' source_transaction_system,
   frch.claim_number  source_transaction_id,
   dha.order_type_code  transaction_type_code,
   frch.warehouse_code	,
   doa_ship.party_id ship_to_party_id,
   hp_ship.party_name   ship_to_customer_name,
   hps_ship.party_site_id ship_to_site_id,
   hc_bill.cust_account_id bill_to_customer_id,
   hp_bill.party_name  bill_to_customer_name ,
   NVL( ( SELECT site_use_id
          FROM fusion.hz_cust_site_uses_all hzcsua1
          WHERE hzcsua.site_use_id =hzcsua1.site_use_id
          AND hzcsua1.status = 'A'
          AND TRUNC(SYSDATE) BETWEEN hzcsua1.start_date AND hzcsua1.end_date),
        ( SELECT site_use_id 
	      FROM fusion.hz_cust_site_uses_all hzcsua1,
              fusion.hz_cust_accounts hc_bill1,
              fusion.hz_cust_acct_sites_all hcs1
          WHERE hzcsua1.cust_acct_site_id = hcs1.cust_acct_site_id
          AND hcs1.cust_account_id = hc_bill1.cust_account_id 
          AND hzcsua1.site_use_code ='BILL_TO'
          AND hzcsua1.status = 'A'
          AND TRUNC(SYSDATE) BETWEEN hzcsua1.start_date AND hzcsua1.end_date
          AND hzcsua1.primary_flag ='Y'
          AND hc_bill1.cust_account_id = doa_bill.cust_acct_id)) bill_to_site_use_id,
   frch.claim_currency_code	,
   frch.claim_status,
   frch.csr_name, 
   frch.sales_person_id,
   frch.preventable,
   xxtwc_claims_outbound_pkg.get_claim_type_details(frch.claim_type, 'REBILL_TO_OTHER_CUSTOMER')  rebill_to_other_cust,     
   xxtwc_claims_outbound_pkg.get_claim_type_details(frch.claim_type, 'PRICE_ADJUSTMENT_ONLY')  price_adj_only,
   NVL(frch.inspection_required,'N') inspection_required,
   ch.po_number,
   ch.claim_note,   
   frch.creation_date,
   frch.created_by,
   frch.last_update_date,
   frch.last_updated_by,
   frch.last_updated_logon, 
   frch.export_order,
   frch.consignment_order
FROM xxtwc_claims_headers ch,
     xxtwc_claims_headers frch,
     fusion.doo_headers_all dha,
     fusion.doo_order_addresses doa_ship,
     fusion.hz_parties hp_ship, 
     fusion.hz_party_sites hps_ship,       
     fusion.doo_order_addresses doa_bill,
     fusion.hz_cust_accounts hc_bill,
     fusion.hz_parties hp_bill,
     fusion.hz_cust_site_uses_all hzcsua
WHERE frch.orig_claim_id = ch.claim_id
  AND ch.header_id = dha.header_id
  AND doa_ship.header_id(+) = dha.header_id
  AND doa_ship.address_use_type(+) = 'SHIP_TO' 
  AND hp_ship.party_id(+) = doa_ship.party_id 
  AND hps_ship.party_site_id = doa_ship.party_site_id
  AND hps_ship.party_id = hp_ship.party_id
  AND doa_bill.header_id(+) = dha.header_id
  AND doa_bill.address_use_type(+) = 'BILL_TO'
  AND hp_bill.party_id(+) =  doa_bill.party_id 
  AND hc_bill.cust_account_id(+) = doa_bill.cust_acct_id
  AND doa_bill.cust_acct_site_use_id = hzcsua.site_use_id(+)
  AND frch.claim_id = p_claim_id;

l_rma_exists VARCHAR2(2);
BEGIN

l_rma_exists := 'N';

 BEGIN
  SELECT 'Y'
  INTO l_rma_exists
  FROM xxtwc_claims_rma_headers_out rma
  WHERE rma.claim_id = p_claim_id;
 EXCEPTION
   WHEN OTHERS THEN
    l_rma_exists := 'N'; 
 END;

 IF l_rma_exists = 'N' THEN

  FOR l_claim_details IN c_claim_details(p_claim_id) LOOP

 INSERT INTO xxtwc_claims_rma_headers_out
 ( claim_id, 
   claim_number, 
   claim_revision_number, 
   claim_date, 
   org_id, 
   bu_name, 
   claim_type, 
   order_number, 
   sold_to_customer_name, 
   sold_to_party_number, 
   header_id, 
   source_transaction_number, 
   source_transaction_system, 
   source_transaction_id, 
   transaction_type_code, 
   requested_fulfil_org_code,
   ship_to_party_id, 
   ship_to_customer_name, 
   ship_to_site_id, 
   bill_to_customer_id, 
   bill_to_customer_name, 
   bill_to_site_use_id, 
   claim_currency_code, 
   claim_status,
   ora_rma_status,
   csr_name,
   preventable,
   rebill_to_other_cust,
   price_adj_only,
   inspection,
   process_type,
   sales_person_id,
   po_number,
   claim_note,  
   creation_date, 
   created_by, 
   last_update_date, 
   last_updated_by, 
   last_updated_logon,
   export_order,
   consignment_order
   )
  VALUES
  ( l_claim_details.claim_id, 
   l_claim_details.claim_number, 
   l_claim_details.claim_revision_number, 
   l_claim_details.claim_date, 
   l_claim_details.org_id, 
   l_claim_details.bu_name, 
   l_claim_details.claim_type, 
   l_claim_details.order_number, 
   l_claim_details.sold_to_customer_name, 
   l_claim_details.sold_to_party_number, 
   l_claim_details.header_id, 
   l_claim_details.source_transaction_number, 
   l_claim_details.source_transaction_system, 
   l_claim_details.source_transaction_id, 
   l_claim_details.transaction_type_code, 
   l_claim_details.warehouse_code,
   l_claim_details.ship_to_party_id, 
   l_claim_details.ship_to_customer_name, 
   l_claim_details.ship_to_site_id, 
   l_claim_details.bill_to_customer_id, 
   l_claim_details.bill_to_customer_name, 
   l_claim_details.bill_to_site_use_id, 
   l_claim_details.claim_currency_code, 
   l_claim_details.claim_status,
   'NEW',
   l_claim_details.csr_name, 
   l_claim_details.preventable,
   l_claim_details.rebill_to_other_cust,
   l_claim_details.price_adj_only,
   l_claim_details.inspection_required,
   xxtwc_claims_outbound_pkg.get_claim_type_details(l_claim_details.claim_type, 'PROCESS_TYPE'), 
   l_claim_details.sales_person_id,
   l_claim_details.po_number,
   l_claim_details.claim_note,  
   l_claim_details.creation_date, 
   l_claim_details.created_by, 
   l_claim_details.last_update_date, 
   l_claim_details.last_updated_by, 
   l_claim_details.last_updated_logon,
   l_claim_details.export_order,
   l_claim_details.consignment_order
   );
   DELETE xxtwc_claims_rma_lines_out
   WHERE claim_id = p_claim_id;

INSERT INTO xxtwc_claims_rma_lines_out
(
   claim_dtl_id,
   claim_id,
   claim_line_no,
   fulfillment_line_id,
   source_transaction_line_id,
   source_transaction_line_number,
   source_schedule_number,
   source_transaction_schedule_id,
   ordered_uom_code,
   claim_qty,
   inventory_item_number,
   inventory_item_id,
   transaction_category_code,
   transaction_line_type_code,
   unit_list_price,
   unit_selling_price,
   unit_adjustment_price,
   adjustment_amount,
   adjustment_type_code,
   charge_definition_code,
   charge_rollup_flag,
   charge_reason_code,
   source_manual_price_adj_id,
   fright_charges,
   return_reason_code,
   lpn,
   lot_number,
   currency_code,
   creation_date,
   created_by,
   last_update_date,
   last_updated_by )
SELECT  lines.claim_dtl_id,
   lines.claim_id,
   lines.claim_line_no,
   lines.fulfillment_line_id,
--	claim_line_no source_transaction_lineid,
--	claim_line_no source_transaction_line_number,
--	claim_line_no source_schedule_number,
--	claim_line_no sourcetransactionscheduleid,
   ROWNUM source_transaction_lineid,
   ROWNUM source_transaction_line_number,
   ROWNUM source_schedule_number,
   ROWNUM sourcetransactionscheduleid,
   (SELECT b.uom_code
    FROM fusion.inv_units_of_measure_b b,
         fusion.inv_units_of_measure_tl tl
    WHERE b.unit_of_measure_id = tl.unit_of_measure_id
    AND tl.language = 'US' 
    AND tl.unit_of_measure =lines.uom )   ordered_uom_code,
   lines.claim_qty,
   lines.inventory_item_name inventory_item_number,
   lines.inventory_item_id,
   'RETURN' transaction_category_code, 
   xxtwc_claims_outbound_pkg.get_claim_type_details(l_claim_details.claim_type, 'TRANSACTION_LINE_TYPE') transaction_line_type_code,
   -1*lines.unit_list_price,
   -1*lines.unit_selling_price,
   -1*lines.unit_adjustment_price,
   -1*lines.extended_amount adjustment_amount,
   'PRICE_OVERRIDE' adjustment_type_code,
   'QP_SALE_PRICE' charge_definition_code,
   'false' charge_rollup_flag,
   xxtwc_claims_outbound_pkg.get_charge_reason_code(lines.claim_reason_code) charge_reason_code,
   lines.claim_line_no, 
   0 fright_charges,
   lines.claim_reason_code, 
   NULL lpn,
   NULL  lot_number,
   l_claim_details.claim_currency_code, 
   lines.creation_date,
   lines.created_by,
   lines.last_update_date,
   lines.last_updated_by 
FROM xxtwc_claims_lines lines ,
     xxtwc_claims_headers ch
WHERE 1=1
AND lines.claim_id = ch.claim_id
AND lines.claim_id = p_claim_id 
AND lines.claim_qty >0;

 END LOOP;
 END IF;
EXCEPTION
 WHEN OTHERS THEN
 raise_application_error('-20000','Error While Processing XXTWC_CLAIMS_OUTBOUND_PKG.credit_rma_upload:-'||sqlerrm);
 p_error := 'Error While Processing XXTWC_CLAIMS_OUTBOUND_PKG.credit_rma_upload :-'||sqlerrm;
 xxtwc_claims_gp_error_pkg.gp_error_log ('Error', 
                                          sqlcode ,     
                                          SUBSTRB('Error While Processing XXTWC_CLAIMS_OUTBOUND_PKG.credit_rma_upload :-'||sqlerrm,1,4000), 
                                          -1,
                                         -1,
										 p_claim_id
                                          );
END;

--AR SO 

PROCEDURE ci_so_upload
( p_claim_id  NUMBER ,
  p_error OUT VARCHAR2	) IS
CURSOR c_claim_details ( p_claim_id NUMBER) IS
SELECT frch.claim_id,
   frch.claim_number,
   frch.claim_revision_number,
   frch.claim_date,
   ch.org_id,
   ch.bu_name,
   frch.claim_type,
   frch.order_number,
   ch.sold_to_customer_name,
   ( SELECT hp.party_number
     FROM fusion.hz_parties hp
     WHERE hp.party_id = ch.sold_to_customer_id
   ) sold_to_party_number,
   ch.header_id,
   'DR'||SUBSTRB(frch.claim_number,3,20) source_transaction_number,
   'OPS' source_transaction_system,
   'CI'||SUBSTRB(frch.claim_number,3,20)  source_transaction_id,
   dha.order_type_code  transaction_type_code,
   frch.warehouse_code	,
   doa_ship.party_id ship_to_party_id,
   hp_ship.party_name   ship_to_customer_name,
   hps_ship.party_site_id ship_to_site_id,
   hc_bill.cust_account_id bill_to_customer_id,
   hp_bill.party_name  bill_to_customer_name ,
   NVL( ( SELECT site_use_id
          FROM fusion.hz_cust_site_uses_all hzcsua1
          WHERE hzcsua.site_use_id =hzcsua1.site_use_id
          AND hzcsua1.status = 'A'
          AND TRUNC(SYSDATE) BETWEEN hzcsua1.start_date AND hzcsua1.end_date),
        ( SELECT site_use_id 
	      FROM fusion.hz_cust_site_uses_all hzcsua1,
              fusion.hz_cust_accounts hc_bill1,
              fusion.hz_cust_acct_sites_all hcs1
          WHERE hzcsua1.cust_acct_site_id = hcs1.cust_acct_site_id
          AND hcs1.cust_account_id = hc_bill1.cust_account_id 
          AND hzcsua1.site_use_code ='BILL_TO'
          AND hzcsua1.status = 'A'
          AND TRUNC(SYSDATE) BETWEEN hzcsua1.start_date AND hzcsua1.end_date
          AND hzcsua1.primary_flag ='Y'
          AND hc_bill1.cust_account_id = doa_bill.cust_acct_id)) bill_to_site_use_id,
   frch.claim_currency_code	,
   frch.claim_status,
   frch.csr_name, 
   frch.sales_person_id,
   frch.preventable,
   xxtwc_claims_outbound_pkg.get_claim_type_details(frch.claim_type, 'REBILL_TO_OTHER_CUSTOMER')  rebill_to_other_cust,     
   xxtwc_claims_outbound_pkg.get_claim_type_details(frch.claim_type, 'PRICE_ADJUSTMENT_ONLY')  price_adj_only,
   NVL(frch.inspection_required,'N') inspection_required,
   ch.po_number,
   ch.claim_note,   
   frch.creation_date,
   frch.created_by,
   frch.last_update_date,
   frch.last_updated_by,
   frch.last_updated_logon, 
   frch.export_order,
   frch.consignment_order
FROM xxtwc_claims_headers ch,
     xxtwc_claims_headers frch,
     fusion.doo_headers_all dha,
     fusion.doo_order_addresses doa_ship,
     fusion.hz_parties hp_ship, 
     fusion.hz_party_sites hps_ship,       
     fusion.doo_order_addresses doa_bill,
     fusion.hz_cust_accounts hc_bill,
     fusion.hz_parties hp_bill,
     fusion.hz_cust_site_uses_all hzcsua
WHERE frch.orig_claim_id = ch.claim_id
  AND ch.header_id = dha.header_id
  AND doa_ship.header_id(+) = dha.header_id
  AND doa_ship.address_use_type(+) = 'SHIP_TO' 
  AND hp_ship.party_id(+) = doa_ship.party_id 
  AND hps_ship.party_site_id = doa_ship.party_site_id
  AND hps_ship.party_id = hp_ship.party_id
  AND doa_bill.header_id(+) = dha.header_id
  AND doa_bill.address_use_type(+) = 'BILL_TO'
  AND hp_bill.party_id(+) =  doa_bill.party_id 
  AND hc_bill.cust_account_id(+) = doa_bill.cust_acct_id
  AND doa_bill.cust_acct_site_use_id = hzcsua.site_use_id(+)
  AND frch.claim_id = p_claim_id;

l_rma_exists VARCHAR2(2);
BEGIN

l_rma_exists := 'N';

 BEGIN
  SELECT 'Y'
  INTO l_rma_exists
  FROM xxtwc_claims_rma_headers_out rma
  WHERE rma.claim_id = p_claim_id;
 EXCEPTION
   WHEN OTHERS THEN
    l_rma_exists := 'N'; 
 END;

 IF l_rma_exists = 'N' THEN

  FOR l_claim_details IN c_claim_details(p_claim_id) LOOP

 INSERT INTO xxtwc_claims_rma_headers_out
 ( claim_id, 
   claim_number, 
   claim_revision_number, 
   claim_date, 
   org_id, 
   bu_name, 
   claim_type, 
   order_number, 
   sold_to_customer_name, 
   sold_to_party_number, 
   header_id, 
   source_transaction_number, 
   source_transaction_system, 
   source_transaction_id, 
   transaction_type_code, 
   requested_fulfil_org_code,
   ship_to_party_id, 
   ship_to_customer_name, 
   ship_to_site_id, 
   bill_to_customer_id, 
   bill_to_customer_name, 
   bill_to_site_use_id, 
   claim_currency_code, 
   claim_status,
   ora_rma_status,
   csr_name,
   preventable,
   rebill_to_other_cust,
   price_adj_only,
   inspection,
   process_type,
   sales_person_id,
   po_number,
   claim_note,  
   creation_date, 
   created_by, 
   last_update_date, 
   last_updated_by, 
   last_updated_logon,
   export_order,
   consignment_order
   )
  VALUES
  ( l_claim_details.claim_id, 
   l_claim_details.claim_number, 
   l_claim_details.claim_revision_number, 
   l_claim_details.claim_date, 
   l_claim_details.org_id, 
   l_claim_details.bu_name, 
   l_claim_details.claim_type, 
   l_claim_details.order_number, 
   l_claim_details.sold_to_customer_name, 
   l_claim_details.sold_to_party_number, 
   l_claim_details.header_id, 
   l_claim_details.source_transaction_number, 
   l_claim_details.source_transaction_system, 
   l_claim_details.source_transaction_id, 
   l_claim_details.transaction_type_code, 
   l_claim_details.warehouse_code,
   l_claim_details.ship_to_party_id, 
   l_claim_details.ship_to_customer_name, 
   l_claim_details.ship_to_site_id, 
   l_claim_details.bill_to_customer_id, 
   l_claim_details.bill_to_customer_name, 
   l_claim_details.bill_to_site_use_id, 
   l_claim_details.claim_currency_code, 
   l_claim_details.claim_status,
   'NEW',
   l_claim_details.csr_name, 
   l_claim_details.preventable,
   l_claim_details.rebill_to_other_cust,
   l_claim_details.price_adj_only,
   l_claim_details.inspection_required,
   xxtwc_claims_outbound_pkg.get_claim_type_details(l_claim_details.claim_type, 'PROCESS_TYPE'), 
   l_claim_details.sales_person_id,
   l_claim_details.po_number,
   l_claim_details.claim_note,  
   l_claim_details.creation_date, 
   l_claim_details.created_by, 
   l_claim_details.last_update_date, 
   l_claim_details.last_updated_by, 
   l_claim_details.last_updated_logon,
   l_claim_details.export_order,
   l_claim_details.consignment_order
   );
   DELETE xxtwc_claims_rma_lines_out
   WHERE claim_id = p_claim_id;

INSERT INTO xxtwc_claims_rma_lines_out
(
   claim_dtl_id,
   claim_id,
   claim_line_no,
   fulfillment_line_id,
   source_transaction_line_id,
   source_transaction_line_number,
   source_schedule_number,
   source_transaction_schedule_id,
   ordered_uom_code,
   claim_qty,
   inventory_item_number,
   inventory_item_id,
   transaction_category_code,
   transaction_line_type_code,
   unit_list_price,
   unit_selling_price,
   unit_adjustment_price,
   adjustment_amount,
   adjustment_type_code,
   charge_definition_code,
   charge_rollup_flag,
   charge_reason_code,
   source_manual_price_adj_id,
   fright_charges,
   return_reason_code,
   lpn,
   lot_number,
   currency_code,
   creation_date,
   created_by,
   last_update_date,
   last_updated_by )
SELECT  lines.claim_dtl_id,
   lines.claim_id,
   lines.claim_line_no,
   lines.fulfillment_line_id,
--	claim_line_no source_transaction_lineid,
--	claim_line_no source_transaction_line_number,
--	claim_line_no source_schedule_number,
--	claim_line_no sourcetransactionscheduleid,
   ROWNUM source_transaction_lineid,
   ROWNUM source_transaction_line_number,
   ROWNUM source_schedule_number,
   ROWNUM sourcetransactionscheduleid,
   (SELECT b.uom_code
    FROM fusion.inv_units_of_measure_b b,
         fusion.inv_units_of_measure_tl tl
    WHERE b.unit_of_measure_id = tl.unit_of_measure_id
    AND tl.language = 'US' 
    AND tl.unit_of_measure =lines.uom )   ordered_uom_code,
   lines.claim_qty,
   lines.inventory_item_name inventory_item_number,
   lines.inventory_item_id,
   'ORDER' transaction_category_code, 
   xxtwc_claims_outbound_pkg.get_claim_type_details(l_claim_details.claim_type, 'TRANSACTION_LINE_TYPE') transaction_line_type_code,
   lines.unit_list_price,
   lines.unit_selling_price,
   lines.unit_adjustment_price,
   lines.extended_amount adjustment_amount,
   'PRICE_OVERRIDE' adjustment_type_code,
   'QP_SALE_PRICE' charge_definition_code,
   'false' charge_rollup_flag,
   xxtwc_claims_outbound_pkg.get_charge_reason_code(lines.claim_reason_code) charge_reason_code,
   lines.claim_line_no, 
   0 fright_charges,
   lines.claim_reason_code, 
   NULL lpn,
   NULL  lot_number,
   l_claim_details.claim_currency_code, 
   lines.creation_date,
   lines.created_by,
   lines.last_update_date,
   lines.last_updated_by 
FROM xxtwc_claims_lines lines ,
     xxtwc_claims_headers ch
WHERE 1=1
AND lines.claim_id = ch.claim_id
AND lines.claim_id = p_claim_id 
AND lines.claim_qty >0;

 END LOOP;
 END IF;
EXCEPTION
 WHEN OTHERS THEN
 raise_application_error('-20000','Error While Processing XXTWC_CLAIMS_OUTBOUND_PKG.ci_so_upload:-'||sqlerrm);
 p_error := 'Error While Processing XXTWC_CLAIMS_OUTBOUND_PKG.ci_so_upload :-'||sqlerrm;
 xxtwc_claims_gp_error_pkg.gp_error_log ('Error', 
                                          sqlcode ,     
                                          SUBSTRB('Error While Processing XXTWC_CLAIMS_OUTBOUND_PKG.ci_so_upload :-'||sqlerrm,1,4000), 
                                          -1,
                                         -1,
										 p_claim_id
                                          );
END;

FUNCTION get_juice_claim(p_header_id NUMBER) RETURN NUMBER
IS
  l_count NUMBER;
BEGIN
        SELECT COUNT (1)
        INTO l_count
        FROM 
         fusion.doo_headers_all dha1,
         fusion.doo_lines_all dla,
         fusion.doo_fulfill_lines_all dfla,
         fusion.doo_fulfill_lines_eff_b dfle
  WHERE 1=1
    AND dha1.header_id = p_header_id
    AND dha1.header_id = dla.header_id
    AND dla.header_id = dfla.header_id
    AND dla.line_id = dfla.line_id
    AND dfla.fulfill_line_id = dfle.fulfill_line_id
    AND dfle.context_code in( 'Generic Line')  
    AND dfle.attribute_char3 is not null;

    RETURN l_count;

EXCEPTION
  WHEN OTHERS 
  THEN RETURN 0;
END;

END XXTWC_CLAIMS_OUTBOUND_PKG;

/
