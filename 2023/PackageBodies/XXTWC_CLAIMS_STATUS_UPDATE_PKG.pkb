/****************************************************************************************************
	Object Type: 	Package Body
	Name       :    XXTWC_CLAIMS_STATUS_UPDATE_PKG
	Created by:		Trinamix
	Created On:		06/01/2023
	Description:	Package to update claim status based on Oracle Order status
	Modified On:	
	Reason:		    
****************************************************************************************************/

--------------------------------------------------------
--  DDL for Package Body XXTWC_CLAIMS_STATUS_UPDATE_PKG
--------------------------------------------------------

create or replace PACKAGE BODY          "XXTWC_CLAIMS_STATUS_UPDATE_PKG" 
AS
PROCEDURE update_status  IS
CURSOR c_claims IS
SELECT *
FROM claims.xxtwc_claims_headers ch
WHERE ch.claim_status NOT IN ('Closed','Submitted','Draft','Rejected')--IN ('Approved','Settled/Approved','Awaiting Disposition')
AND ch.ora_rma_no IS NOT NULL;
l_claim_status VARCHAR2(100);

CURSOR c_rma_lines ( p_order_number VARCHAR2) IS
SELECT COUNT(fline.fulfill_line_id) cnt, 
          tasks.status_code               
    FROM    fusion.doo_headers_all head               ,
        fusion.doo_fulfill_lines_all fline        ,
        fusion.doo_orchestration_groups grps      ,
        fusion.doo_process_instances proc         ,
        fusion.doo_process_definitions_tl procdef ,
        fusion.doo_process_step_instances steps   ,
        fusion.doo_process_steps_b stepdefb       ,
        fusion.doo_process_steps_tl stepdeftl     ,
        fusion.doo_task_instances tasks           ,
        fusion.doo_task_definitions_tl taskdef    ,
        fusion.doo_lines_all dla                  ,
        fusion.egp_system_items_b esib
    WHERE   head.order_number = p_order_number
        AND grps.header_id                 = head.header_id
        AND grps.fulfillment_line_id       = fline.fulfill_line_id
        AND grps.doo_process_instance_id   = steps.doo_process_instance_id
        AND grps.doo_process_instance_id   = proc.doo_process_instance_id
        AND proc.doo_process_id            = procdef.doo_process_id
        AND grps.group_id                  = steps.group_id
        AND steps.step_id                  = stepdefb.step_id
        AND stepdeftl.step_id              = stepdefb.step_id
        AND steps.task_instance_id         = tasks.task_instance_id
        AND taskdef.task_id                = tasks.task_id
        AND fline.line_id                  = dla.line_id
        AND esib.inventory_item_id         = fline.inventory_item_id
        AND esib.inventory_organization_id = fline.inventory_organization_id
        AND procdef.language               = 'US'
        AND stepdeftl.language             = 'US'
        AND taskdef.language               = 'US'
        AND step_status = 'COMPLETED' 
        AND (fline.fulfill_line_id,  stepdefb.step_number)  IN 
		(SELECT fline.fulfill_line_id, 
                MAX(  stepdefb.step_number)
      --  tasks.status_code              
        FROM fusion.doo_headers_all head               ,
             fusion.doo_fulfill_lines_all fline        ,
             fusion.doo_orchestration_groups grps      ,
             fusion.doo_process_instances proc         ,
             fusion.doo_process_definitions_tl procdef ,
             fusion.doo_process_step_instances steps   ,
             fusion.doo_process_steps_b stepdefb       ,
             fusion.doo_process_steps_tl stepdeftl     ,
             fusion.doo_task_instances tasks           ,
             fusion.doo_task_definitions_tl taskdef    ,
             fusion.doo_lines_all dla                  ,
             fusion.egp_system_items_b esib
        WHERE   head.order_number =  p_order_number
		AND head.submitted_flag ='Y'
        AND grps.header_id                 = head.header_id
        AND grps.fulfillment_line_id       = fline.fulfill_line_id
        AND grps.doo_process_instance_id   = steps.doo_process_instance_id
        AND grps.doo_process_instance_id   = proc.doo_process_instance_id
        AND proc.doo_process_id            = procdef.doo_process_id
        AND grps.group_id                  = steps.group_id
        AND steps.step_id                  = stepdefb.step_id
        AND stepdeftl.step_id              = stepdefb.step_id
        AND steps.task_instance_id         = tasks.task_instance_id
        AND taskdef.task_id                = tasks.task_id
        AND fline.line_id                  = dla.line_id
        AND esib.inventory_item_id         = fline.inventory_item_id
        AND esib.inventory_organization_id = fline.inventory_organization_id
        AND procdef.language               = 'US'
        AND stepdeftl.language             = 'US'
        AND taskdef.language               = 'US'
        AND step_status = 'COMPLETED' 
        AND fline.line_type_code ='ORA_RETURN'
        AND fline.status_code != 'CANCELLED'
        GROUP BY fline.fulfill_line_id)
        GROUP BY  tasks.status_code  ;

		l_delivered_cnt NUMBER;
		l_billed_cnt NUMBER;
		l_total_line_cnt NUMBER;

CURSOR c_rma_lines_bill ( p_order_number VARCHAR2) IS
SELECT COUNT(fline.fulfill_line_id) cnt, 
          tasks.status_code               
    FROM    fusion.doo_headers_all head               ,
        fusion.doo_fulfill_lines_all fline        ,
        fusion.doo_orchestration_groups grps      ,
        fusion.doo_process_instances proc         ,
        fusion.doo_process_definitions_tl procdef ,
        fusion.doo_process_step_instances steps   ,
        fusion.doo_process_steps_b stepdefb       ,
        fusion.doo_process_steps_tl stepdeftl     ,
        fusion.doo_task_instances tasks           ,
        fusion.doo_task_definitions_tl taskdef    ,
        fusion.doo_lines_all dla                  ,
        fusion.egp_system_items_b esib
    WHERE   head.order_number = p_order_number
        AND grps.header_id                 = head.header_id
        AND grps.fulfillment_line_id       = fline.fulfill_line_id
        AND grps.doo_process_instance_id   = steps.doo_process_instance_id
        AND grps.doo_process_instance_id   = proc.doo_process_instance_id
        AND proc.doo_process_id            = procdef.doo_process_id
        AND grps.group_id                  = steps.group_id
        AND steps.step_id                  = stepdefb.step_id
        AND stepdeftl.step_id              = stepdefb.step_id
        AND steps.task_instance_id         = tasks.task_instance_id
        AND taskdef.task_id                = tasks.task_id
        AND fline.line_id                  = dla.line_id
        AND esib.inventory_item_id         = fline.inventory_item_id
        AND esib.inventory_organization_id = fline.inventory_organization_id
        AND procdef.language               = 'US'
        AND stepdeftl.language             = 'US'
        AND taskdef.language               = 'US'
        AND step_status = 'COMPLETED' 
        AND (fline.fulfill_line_id,  stepdefb.step_number)  IN 
		(SELECT fline.fulfill_line_id, 
                MAX(  stepdefb.step_number)
      --  tasks.status_code              
        FROM fusion.doo_headers_all head               ,
             fusion.doo_fulfill_lines_all fline        ,
             fusion.doo_orchestration_groups grps      ,
             fusion.doo_process_instances proc         ,
             fusion.doo_process_definitions_tl procdef ,
             fusion.doo_process_step_instances steps   ,
             fusion.doo_process_steps_b stepdefb       ,
             fusion.doo_process_steps_tl stepdeftl     ,
             fusion.doo_task_instances tasks           ,
             fusion.doo_task_definitions_tl taskdef    ,
             fusion.doo_lines_all dla                  ,
             fusion.egp_system_items_b esib
        WHERE   head.order_number =  p_order_number
		AND head.submitted_flag ='Y'
        AND grps.header_id                 = head.header_id
        AND grps.fulfillment_line_id       = fline.fulfill_line_id
        AND grps.doo_process_instance_id   = steps.doo_process_instance_id
        AND grps.doo_process_instance_id   = proc.doo_process_instance_id
        AND proc.doo_process_id            = procdef.doo_process_id
        AND grps.group_id                  = steps.group_id
        AND steps.step_id                  = stepdefb.step_id
        AND stepdeftl.step_id              = stepdefb.step_id
        AND steps.task_instance_id         = tasks.task_instance_id
        AND taskdef.task_id                = tasks.task_id
        AND fline.line_id                  = dla.line_id
        AND esib.inventory_item_id         = fline.inventory_item_id
        AND esib.inventory_organization_id = fline.inventory_organization_id
        AND procdef.language               = 'US'
        AND stepdeftl.language             = 'US'
        AND taskdef.language               = 'US'
        AND step_status = 'COMPLETED' 
        AND fline.line_type_code !='ORA_RETURN'
        AND fline.status_code != 'CANCELLED'
        GROUP BY fline.fulfill_line_id)
        GROUP BY  tasks.status_code ;

CURSOR c_div_so_lines_price_change IS
   SELECT cl.claim_id,
       dha.order_number,
       dha.ordered_date,
       dst.display_name order_status,
       dha.transactional_currency_code currency,
       dfla.inventory_item_id,
       dfla.unit_selling_price, 
       lines.unit_finalbill_price,
       so_lines.claim_dtl_id
   FROM fusion.doo_headers_all dha,
       fusion.doo_fulfill_lines_all dfla,
       xxtwc_claims_headers cl,
       fusion.doo_statuses_b dsb,
       fusion.doo_statuses_tl dst,
       xxtwc_claims_so_lines_out so_lines,
       xxtwc_claims_lines lines
   WHERE  dha.order_number = cl.ora_div_so_number
   AND dha.submitted_flag = 'Y'
   AND dsb.status_code = dha.status_code
   AND dsb.status_id = dst.status_id
   AND dst.language = 'US'
   AND dha.header_id = dfla.header_id
   AND dfla.status_code NOT IN ( 'CANCELED' )
   AND so_lines.claim_id = cl.claim_id
   AND DFLA.source_line_number = so_lines.source_transaction_line_number
   AND so_lines.claim_id = lines.claim_id
   AND so_lines.claim_dtl_id = lines.claim_dtl_id
   AND Nvl(lines.unit_finalbill_price,0) != dfla.unit_selling_price
ORDER  BY lines.claim_id; 

BEGIN

  FOR l_claims IN c_claims LOOP
  l_claim_status:= NULL;
    IF l_claims.claim_status = 'Approved' AND ( l_claims.claim_sub_status =  'Awaiting RMA/Claims Creation' OR l_claims.claim_sub_status IS NULL) THEN
	BEGIN
	SELECT 'RMA/Claims Order Created'
	INTO l_claim_status
	FROM DUAL
	WHERE EXISTS ( SELECT 1
	               FROM  fusion.doo_headers_all dha
				   WHERE  dha.order_number = l_claims.ora_rma_no 
				   AND dha.submitted_flag ='Y'
				);
    UPDATE claims.xxtwc_claims_headers 
	   SET claim_sub_status = l_claim_status
	   WHERE claim_id = l_claims.claim_id; 
	   COMMIT;
    EXCEPTION
	  WHEN OTHERS THEN
	  l_claim_status := NULL;
	END;

	END IF;

	IF ( (( l_claims.claim_status = 'Approved' AND l_claims.claim_sub_status IN ('RMA/Claims Order Created','Delivered' ,'Partial Processed'))
	    OR ( l_claims.claim_status= 'Settled' AND l_claims.claim_sub_status = 'Partial settled')
		 OR ( l_claims.claim_status = 'Approved' AND l_claim_status= 'RMA/Claims Order Created'))
	   AND l_claims.claim_type IN ('RETURN_INVENTORY','REJECT_RETURN')) THEN 

		l_delivered_cnt := 0;
		l_billed_cnt  := 0;
		l_total_line_cnt := 0;
	 FOR l_rma_lines IN c_rma_lines(l_claims.ora_rma_no ) LOOP
	  IF l_rma_lines.status_code = 'DELIVERED' AND l_rma_lines.cnt > 0 THEN
	     l_delivered_cnt := l_delivered_cnt + l_rma_lines.cnt; 
	  END IF;
	  IF l_rma_lines.status_code = 'BILLED' AND l_rma_lines.cnt > 0 THEN
	   l_billed_cnt := l_billed_cnt + l_rma_lines.cnt; 
	  END IF;	 
	 END LOOP; 
	 BEGIN
		SELECT COUNT(1)
		INTO l_total_line_cnt
		FROM fusion.doo_headers_all head               ,
             fusion.doo_fulfill_lines_all fline    
	    WHERE head.order_number =l_claims.ora_rma_no
		AND fline.status_code != 'CANCELLED'
		AND fline.header_id  = head.header_id;
	 END;

	 IF l_delivered_cnt >0 AND l_billed_cnt >0 THEN
      UPDATE claims.xxtwc_claims_headers 
	   SET  claim_status= 'Settled',	        
			claim_sub_status = 'Partial Settled'
	   WHERE claim_id = l_claims.claim_id; 	 
      ELSIF l_delivered_cnt >0 AND l_billed_cnt =0 AND l_total_line_cnt =l_delivered_cnt +l_billed_cnt  THEN
      UPDATE claims.xxtwc_claims_headers 
	   SET  claim_status= 'Approved',	        
			claim_sub_status = 'Delivered'
	   WHERE claim_id = l_claims.claim_id; 	 	 
      ELSIF l_delivered_cnt = 0 AND l_billed_cnt >0 AND l_total_line_cnt =l_delivered_cnt +l_billed_cnt THEN
      UPDATE claims.xxtwc_claims_headers 
	   SET  claim_status= 'Settled',	        
			claim_sub_status = 'Credit Memo Processed'
	   WHERE claim_id = l_claims.claim_id; 	 
      ELSIF l_delivered_cnt +l_billed_cnt >0 AND l_total_line_cnt !=l_delivered_cnt +l_billed_cnt THEN
      UPDATE claims.xxtwc_claims_headers 
	   SET  claim_status= 'Approved',	        
			claim_sub_status = 'Partial Processed'
	   WHERE claim_id = l_claims.claim_id; 	 		   
	 END IF; 
	ELSIF ( ( ( l_claims.claim_status = 'Approved' AND l_claims.claim_sub_status IN ('RMA/Claims Order Created','Credit Memo Processed')) OR
	         ( l_claims.claim_status = 'Approved' AND l_claims.claim_sub_status IN ('Partial Processed','Partial settled','RMA Awaiting Billing')))
	   AND l_claims.claim_type IN ('REJECTION_DIVERSION')) THEN 
	 IF l_claims.claim_sub_status = 'RMA/Claims Order Created' THEN
	    l_billed_cnt  := 0;
		l_total_line_cnt := 0;
		 FOR l_rma_lines_bill IN c_rma_lines_bill(l_claims.ora_rma_no ) LOOP

		  IF l_rma_lines_bill.status_code = 'BILLED' AND l_rma_lines_bill.cnt > 0 THEN
		   l_billed_cnt := l_billed_cnt + l_rma_lines_bill.cnt; 
		  END IF;	 
		 END LOOP; 
		 BEGIN
			SELECT COUNT(1)
			INTO l_total_line_cnt
			FROM fusion.doo_headers_all head               ,
				 fusion.doo_fulfill_lines_all fline    
			WHERE head.order_number =l_claims.ora_rma_no
			AND fline.status_code != 'CANCELLED'
			AND fline.header_id  = head.header_id;
		 END;

		 IF l_billed_cnt >0 AND  l_total_line_cnt != l_billed_cnt THEN
		  UPDATE claims.xxtwc_claims_headers 
		   SET  claim_status= 'Approved',	        
				claim_sub_status = 'Partial settled'
		   WHERE claim_id = l_claims.claim_id; 	 
		  ELSIF l_billed_cnt >0 AND  l_total_line_cnt = l_billed_cnt THEN 
		  UPDATE claims.xxtwc_claims_headers 
		   SET  claim_status= 'Approved',	        
				claim_sub_status = 'Credit Memo Processed'
		   WHERE claim_id = l_claims.claim_id;  	
		  ELSIF l_billed_cnt = 0   THEN 
		  UPDATE claims.xxtwc_claims_headers 
		   SET  claim_status= 'Approved',	        
				claim_sub_status = 'RMA Awaiting Billing'
		   WHERE claim_id = l_claims.claim_id;  		   
		 END IF; 
	 END IF;
	 IF l_claims.claim_sub_status in ( 'Credit Memo Processed' ,'Partial Rebill Processing','Awaiting Rebill Processing') THEN
	    l_billed_cnt  := 0;
		l_total_line_cnt := 0;
		 FOR l_so_lines_bill IN c_rma_lines_bill(l_claims.ora_div_so_number ) LOOP

		  IF l_so_lines_bill.status_code = 'BILLED' AND l_so_lines_bill.cnt > 0 THEN
		   l_billed_cnt := l_billed_cnt + l_so_lines_bill.cnt; 
		  END IF;	 
		 END LOOP; 
		 BEGIN
			SELECT COUNT(1)
			INTO l_total_line_cnt
			FROM fusion.doo_headers_all head               ,
				 fusion.doo_fulfill_lines_all fline    
			WHERE head.order_number =l_claims.ora_div_so_number
			AND fline.status_code != 'CANCELLED'
			AND fline.header_id  = head.header_id;
		 END;

		 IF l_billed_cnt >0 AND  l_total_line_cnt != l_billed_cnt THEN
		  UPDATE claims.xxtwc_claims_headers 
		   SET  claim_status= 'Approved',	        
				claim_sub_status = 'Partial Rebill Processing'
		   WHERE claim_id = l_claims.claim_id; 	 
		  ELSIF l_billed_cnt >0 AND  l_total_line_cnt = l_billed_cnt THEN 
		  UPDATE claims.xxtwc_claims_headers 
		   SET  claim_status= 'Settled',	        
				claim_sub_status = 'Settled'
		   WHERE claim_id = l_claims.claim_id;  	
		  ELSIF l_billed_cnt = 0   THEN 
		  UPDATE claims.xxtwc_claims_headers 
		   SET  claim_status= 'Approved',	        
				claim_sub_status = 'Awaiting Rebill Processing'
		   WHERE claim_id = l_claims.claim_id;  		   
		 END IF; 
	 END IF;	 
    ELSIF l_claims.claim_type IN ('IMPORT_CLAIM','PRICE_ADJ','REJECT_DUMPED','FREIGHT_ONLY','UNREFRENCE_CLAIM','JUICE_CLAIM','AR_CLAIM','CREDIT_CLAIM') AND 
	      (l_claims.claim_sub_status = 'RMA/Claims Order Created' OR  l_claim_status= 'RMA/Claims Order Created' 
           OR l_claims.claim_status = 'Awaiting Billing' ) THEN 

		l_billed_cnt  := 0;
		l_total_line_cnt := 0;
	 FOR l_rma_lines_bill IN c_rma_lines_bill(l_claims.ora_rma_no ) LOOP

	  IF l_rma_lines_bill.status_code = 'BILLED' AND l_rma_lines_bill.cnt > 0 THEN
	   l_billed_cnt := l_billed_cnt + l_rma_lines_bill.cnt; 
	  END IF;	 
	 END LOOP; 
	 BEGIN
		SELECT COUNT(1)
		INTO l_total_line_cnt
		FROM fusion.doo_headers_all head               ,
             fusion.doo_fulfill_lines_all fline    
	    WHERE head.order_number =l_claims.ora_rma_no
		AND fline.status_code != 'CANCELLED'
		AND fline.header_id  = head.header_id;
	 END;

	 IF l_billed_cnt >0 AND  l_total_line_cnt != l_billed_cnt THEN
      UPDATE claims.xxtwc_claims_headers 
	   SET  claim_status= 'Settled',	        
			claim_sub_status = 'Partial settled'
	   WHERE claim_id = l_claims.claim_id; 	 
      ELSIF l_billed_cnt >0 AND  l_total_line_cnt = l_billed_cnt THEN 
      UPDATE claims.xxtwc_claims_headers 
	   SET  claim_status= 'Settled',	        
			claim_sub_status = 'Credit Memo Processed'
	   WHERE claim_id = l_claims.claim_id;  	
      ELSIF l_billed_cnt = 0   THEN 
      UPDATE claims.xxtwc_claims_headers 
	   SET  claim_status= 'Awaiting Billing',	        
			claim_sub_status = 'Awaiting Billing'
	   WHERE claim_id = l_claims.claim_id;  		   
	 END IF; 
   END IF;
 COMMIT;

  END LOOP;


  FOR l_div_so_lines_price_change IN c_div_so_lines_price_change LOOP
  BEGIN
   UPDATE xxtwc_claims_lines
   SET unit_finalbill_price = l_div_so_lines_price_change.unit_selling_price
   WHERE claim_id = l_div_so_lines_price_change.claim_id
   AND claim_dtl_id = l_div_so_lines_price_change.claim_dtl_id;    
  EXCEPTION
	WHEN OTHERS THEN
	  NULL;  
   END;
  END LOOP;
  COMMIT;

EXCEPTION
 WHEN OTHERS THEN
 raise_application_error('-20000','Error While Processing XXTWC_CLAIMS_STATUS_UPDATE_PKG.update_status:-'||sqlerrm); 
 xxtwc_claims_gp_error_pkg.gp_error_log ('Error', 
                                          sqlcode ,     
                                          'Error While Processing XXTWC_CLAIMS_STATUS_UPDATE_PKG.update_status :-'||sqlerrm, 
                                          -1,
                                         -1,
										 NULL
                                          );
END;  

PROCEDURE update_claim_status(p_claim_id NUMBER)  IS
CURSOR c_claims IS
SELECT *
FROM claims.xxtwc_claims_headers ch
WHERE ch.claim_status NOT IN ('Closed','Submitted','Draft','Rejected')--IN ('Approved','Settled/Approved','Awaiting Disposition')
AND ch.ora_rma_no IS NOT NULL
AND ch.claim_id = p_claim_id;
l_claim_status VARCHAR2(100);

CURSOR c_rma_lines ( p_order_number VARCHAR2) IS
SELECT COUNT(fline.fulfill_line_id) cnt, 
          tasks.status_code               
    FROM    fusion.doo_headers_all head               ,
        fusion.doo_fulfill_lines_all fline        ,
        fusion.doo_orchestration_groups grps      ,
        fusion.doo_process_instances proc         ,
        fusion.doo_process_definitions_tl procdef ,
        fusion.doo_process_step_instances steps   ,
        fusion.doo_process_steps_b stepdefb       ,
        fusion.doo_process_steps_tl stepdeftl     ,
        fusion.doo_task_instances tasks           ,
        fusion.doo_task_definitions_tl taskdef    ,
        fusion.doo_lines_all dla                  ,
        fusion.egp_system_items_b esib
    WHERE   head.order_number = p_order_number
        AND grps.header_id                 = head.header_id
        AND grps.fulfillment_line_id       = fline.fulfill_line_id
        AND grps.doo_process_instance_id   = steps.doo_process_instance_id
        AND grps.doo_process_instance_id   = proc.doo_process_instance_id
        AND proc.doo_process_id            = procdef.doo_process_id
        AND grps.group_id                  = steps.group_id
        AND steps.step_id                  = stepdefb.step_id
        AND stepdeftl.step_id              = stepdefb.step_id
        AND steps.task_instance_id         = tasks.task_instance_id
        AND taskdef.task_id                = tasks.task_id
        AND fline.line_id                  = dla.line_id
        AND esib.inventory_item_id         = fline.inventory_item_id
        AND esib.inventory_organization_id = fline.inventory_organization_id
        AND procdef.language               = 'US'
        AND stepdeftl.language             = 'US'
        AND taskdef.language               = 'US'
        AND step_status = 'COMPLETED' 
        AND (fline.fulfill_line_id,  stepdefb.step_number)  IN 
		(SELECT fline.fulfill_line_id, 
                MAX(  stepdefb.step_number)
      --  tasks.status_code              
        FROM fusion.doo_headers_all head               ,
             fusion.doo_fulfill_lines_all fline        ,
             fusion.doo_orchestration_groups grps      ,
             fusion.doo_process_instances proc         ,
             fusion.doo_process_definitions_tl procdef ,
             fusion.doo_process_step_instances steps   ,
             fusion.doo_process_steps_b stepdefb       ,
             fusion.doo_process_steps_tl stepdeftl     ,
             fusion.doo_task_instances tasks           ,
             fusion.doo_task_definitions_tl taskdef    ,
             fusion.doo_lines_all dla                  ,
             fusion.egp_system_items_b esib
        WHERE   head.order_number =  p_order_number
		AND head.submitted_flag ='Y'
        AND grps.header_id                 = head.header_id
        AND grps.fulfillment_line_id       = fline.fulfill_line_id
        AND grps.doo_process_instance_id   = steps.doo_process_instance_id
        AND grps.doo_process_instance_id   = proc.doo_process_instance_id
        AND proc.doo_process_id            = procdef.doo_process_id
        AND grps.group_id                  = steps.group_id
        AND steps.step_id                  = stepdefb.step_id
        AND stepdeftl.step_id              = stepdefb.step_id
        AND steps.task_instance_id         = tasks.task_instance_id
        AND taskdef.task_id                = tasks.task_id
        AND fline.line_id                  = dla.line_id
        AND esib.inventory_item_id         = fline.inventory_item_id
        AND esib.inventory_organization_id = fline.inventory_organization_id
        AND procdef.language               = 'US'
        AND stepdeftl.language             = 'US'
        AND taskdef.language               = 'US'
        AND step_status = 'COMPLETED' 
        AND fline.line_type_code ='ORA_RETURN'
        AND fline.status_code != 'CANCELLED'
        GROUP BY fline.fulfill_line_id)
        GROUP BY  tasks.status_code  ;

		l_delivered_cnt NUMBER;
		l_billed_cnt NUMBER;
		l_total_line_cnt NUMBER;

CURSOR c_rma_lines_bill ( p_order_number VARCHAR2) IS
SELECT COUNT(fline.fulfill_line_id) cnt, 
          tasks.status_code               
    FROM    fusion.doo_headers_all head               ,
        fusion.doo_fulfill_lines_all fline        ,
        fusion.doo_orchestration_groups grps      ,
        fusion.doo_process_instances proc         ,
        fusion.doo_process_definitions_tl procdef ,
        fusion.doo_process_step_instances steps   ,
        fusion.doo_process_steps_b stepdefb       ,
        fusion.doo_process_steps_tl stepdeftl     ,
        fusion.doo_task_instances tasks           ,
        fusion.doo_task_definitions_tl taskdef    ,
        fusion.doo_lines_all dla                  ,
        fusion.egp_system_items_b esib
    WHERE   head.order_number = p_order_number
        AND grps.header_id                 = head.header_id
        AND grps.fulfillment_line_id       = fline.fulfill_line_id
        AND grps.doo_process_instance_id   = steps.doo_process_instance_id
        AND grps.doo_process_instance_id   = proc.doo_process_instance_id
        AND proc.doo_process_id            = procdef.doo_process_id
        AND grps.group_id                  = steps.group_id
        AND steps.step_id                  = stepdefb.step_id
        AND stepdeftl.step_id              = stepdefb.step_id
        AND steps.task_instance_id         = tasks.task_instance_id
        AND taskdef.task_id                = tasks.task_id
        AND fline.line_id                  = dla.line_id
        AND esib.inventory_item_id         = fline.inventory_item_id
        AND esib.inventory_organization_id = fline.inventory_organization_id
        AND procdef.language               = 'US'
        AND stepdeftl.language             = 'US'
        AND taskdef.language               = 'US'
        AND step_status = 'COMPLETED' 
        AND (fline.fulfill_line_id,  stepdefb.step_number)  IN 
		(SELECT fline.fulfill_line_id, 
                MAX(  stepdefb.step_number)
      --  tasks.status_code              
        FROM fusion.doo_headers_all head               ,
             fusion.doo_fulfill_lines_all fline        ,
             fusion.doo_orchestration_groups grps      ,
             fusion.doo_process_instances proc         ,
             fusion.doo_process_definitions_tl procdef ,
             fusion.doo_process_step_instances steps   ,
             fusion.doo_process_steps_b stepdefb       ,
             fusion.doo_process_steps_tl stepdeftl     ,
             fusion.doo_task_instances tasks           ,
             fusion.doo_task_definitions_tl taskdef    ,
             fusion.doo_lines_all dla                  ,
             fusion.egp_system_items_b esib
        WHERE   head.order_number =  p_order_number
		AND head.submitted_flag ='Y'
        AND grps.header_id                 = head.header_id
        AND grps.fulfillment_line_id       = fline.fulfill_line_id
        AND grps.doo_process_instance_id   = steps.doo_process_instance_id
        AND grps.doo_process_instance_id   = proc.doo_process_instance_id
        AND proc.doo_process_id            = procdef.doo_process_id
        AND grps.group_id                  = steps.group_id
        AND steps.step_id                  = stepdefb.step_id
        AND stepdeftl.step_id              = stepdefb.step_id
        AND steps.task_instance_id         = tasks.task_instance_id
        AND taskdef.task_id                = tasks.task_id
        AND fline.line_id                  = dla.line_id
        AND esib.inventory_item_id         = fline.inventory_item_id
        AND esib.inventory_organization_id = fline.inventory_organization_id
        AND procdef.language               = 'US'
        AND stepdeftl.language             = 'US'
        AND taskdef.language               = 'US'
        AND step_status = 'COMPLETED' 
        AND fline.line_type_code !='ORA_RETURN'
        AND fline.status_code != 'CANCELLED'
        GROUP BY fline.fulfill_line_id)
        GROUP BY  tasks.status_code ;


BEGIN

  FOR l_claims IN c_claims LOOP
    l_claim_status:= NULL;
    IF l_claims.claim_status = 'Approved' AND ( l_claims.claim_sub_status =  'Awaiting RMA/Claims Creation' OR l_claims.claim_sub_status IS NULL) THEN

    BEGIN
	SELECT 'RMA/Claims Order Created'
	INTO l_claim_status
	FROM DUAL
	WHERE EXISTS ( SELECT 1
	               FROM  fusion.doo_headers_all dha
				   WHERE  dha.order_number = l_claims.ora_rma_no 
				   AND dha.submitted_flag ='Y'
				);

    UPDATE claims.xxtwc_claims_headers 
	   SET claim_sub_status = l_claim_status
	   WHERE claim_id = l_claims.claim_id; 

	   COMMIT;

    EXCEPTION
	  WHEN OTHERS THEN
	  l_claim_status := NULL;
	END;

	END IF;

	IF ( (( l_claims.claim_status = 'Approved' AND l_claims.claim_sub_status IN ('RMA/Claims Order Created','Delivered' ))
	    OR ( l_claims.claim_status= 'Settled' AND l_claims.claim_sub_status = 'Partial settled')
		 OR ( l_claims.claim_status = 'Approved' AND l_claim_status= 'RMA/Claims Order Created'))
	   AND l_claims.claim_type IN ('RETURN_INVENTORY','REJECT_RETURN')) THEN 

		l_delivered_cnt := 0;
		l_billed_cnt  := 0;
		l_total_line_cnt := 0;
	 FOR l_rma_lines IN c_rma_lines(l_claims.ora_rma_no ) LOOP
	  IF l_rma_lines.status_code = 'DELIVERED' AND l_rma_lines.cnt > 0 THEN
	     l_delivered_cnt := l_delivered_cnt + l_rma_lines.cnt; 
	  END IF;
	  IF l_rma_lines.status_code = 'BILLED' AND l_rma_lines.cnt > 0 THEN
	   l_billed_cnt := l_billed_cnt + l_rma_lines.cnt; 
	  END IF;	 
	 END LOOP; 
	 BEGIN
		SELECT COUNT(1)
		INTO l_total_line_cnt
		FROM fusion.doo_headers_all head               ,
             fusion.doo_fulfill_lines_all fline    
	    WHERE head.order_number =l_claims.ora_rma_no
		AND fline.status_code != 'CANCELLED'
		AND fline.header_id  = head.header_id;
	 END;

	 IF l_delivered_cnt >0 AND l_billed_cnt >0 THEN
      UPDATE claims.xxtwc_claims_headers 
	   SET  claim_status= 'Settled',	        
			claim_sub_status = 'Partial Settled'
	   WHERE claim_id = l_claims.claim_id; 	 
      ELSIF l_delivered_cnt >0 AND l_billed_cnt =0 AND l_total_line_cnt =l_delivered_cnt +l_billed_cnt  THEN
      UPDATE claims.xxtwc_claims_headers 
	   SET  claim_status= 'Approved',	        
			claim_sub_status = 'Delivered'
	   WHERE claim_id = l_claims.claim_id; 	 	 
      ELSIF l_delivered_cnt = 0 AND l_billed_cnt >0 AND l_total_line_cnt =l_delivered_cnt +l_billed_cnt THEN
      UPDATE claims.xxtwc_claims_headers 
	   SET  claim_status= 'Settled',	        
			claim_sub_status = 'Credit Memo Processed'
	   WHERE claim_id = l_claims.claim_id; 	 
      ELSIF l_delivered_cnt +l_billed_cnt >0 AND l_total_line_cnt !=l_delivered_cnt +l_billed_cnt THEN
      UPDATE claims.xxtwc_claims_headers 
	   SET  claim_status= 'Approved',	        
			claim_sub_status = 'Partial Processed'
	   WHERE claim_id = l_claims.claim_id; 	 		   
	 END IF; 
	ELSIF ( ( ( l_claims.claim_status = 'Approved' AND l_claims.claim_sub_status IN ('RMA/Claims Order Created','Credit Memo Processed')) OR
	         ( l_claims.claim_status = 'Approved' AND l_claims.claim_sub_status IN ('Partial Processed','Partial settled')))
	   AND l_claims.claim_type IN ('REJECTION_DIVERSION')) THEN 
	 IF l_claims.claim_sub_status = 'RMA/Claims Order Created' THEN
	    l_billed_cnt  := 0;
		l_total_line_cnt := 0;
		 FOR l_rma_lines_bill IN c_rma_lines_bill(l_claims.ora_rma_no ) LOOP

		  IF l_rma_lines_bill.status_code = 'BILLED' AND l_rma_lines_bill.cnt > 0 THEN
		   l_billed_cnt := l_billed_cnt + l_rma_lines_bill.cnt; 
		  END IF;	 
		 END LOOP; 
		 BEGIN
			SELECT COUNT(1)
			INTO l_total_line_cnt
			FROM fusion.doo_headers_all head               ,
				 fusion.doo_fulfill_lines_all fline    
			WHERE head.order_number =l_claims.ora_rma_no
			AND fline.status_code != 'CANCELLED'
			AND fline.header_id  = head.header_id;
		 END;

		 IF l_billed_cnt >0 AND  l_total_line_cnt != l_billed_cnt THEN
		  UPDATE claims.xxtwc_claims_headers 
		   SET  claim_status= 'Approved',	        
				claim_sub_status = 'Partial settled'
		   WHERE claim_id = l_claims.claim_id; 	 
		  ELSIF l_billed_cnt >0 AND  l_total_line_cnt = l_billed_cnt THEN 
		  UPDATE claims.xxtwc_claims_headers 
		   SET  claim_status= 'Approved',	        
				claim_sub_status = 'Credit Memo Processed'
		   WHERE claim_id = l_claims.claim_id;  	
		  ELSIF l_billed_cnt = 0   THEN 
		  UPDATE claims.xxtwc_claims_headers 
		   SET  claim_status= 'Approved',	        
				claim_sub_status = 'Partial Processed'
		   WHERE claim_id = l_claims.claim_id;  		   
		 END IF; 
	 END IF;
	 IF l_claims.claim_sub_status = 'Credit Memo Processed' THEN
	    l_billed_cnt  := 0;
		l_total_line_cnt := 0;
		 FOR l_so_lines_bill IN c_rma_lines_bill(l_claims.ora_div_so_number ) LOOP

		  IF l_so_lines_bill.status_code = 'BILLED' AND l_so_lines_bill.cnt > 0 THEN
		   l_billed_cnt := l_billed_cnt + l_so_lines_bill.cnt; 
		  END IF;	 
		 END LOOP; 
		 BEGIN
			SELECT COUNT(1)
			INTO l_total_line_cnt
			FROM fusion.doo_headers_all head               ,
				 fusion.doo_fulfill_lines_all fline    
			WHERE head.order_number =l_claims.ora_div_so_number
			AND fline.status_code != 'CANCELLED'
			AND fline.header_id  = head.header_id;
		 END;

		 IF l_billed_cnt >0 AND  l_total_line_cnt != l_billed_cnt THEN
		  UPDATE claims.xxtwc_claims_headers 
		   SET  claim_status= 'Approved',	        
				claim_sub_status = 'Awaiting Rebill Processing'
		   WHERE claim_id = l_claims.claim_id; 	 
		  ELSIF l_billed_cnt >0 AND  l_total_line_cnt = l_billed_cnt THEN 
		  UPDATE claims.xxtwc_claims_headers 
		   SET  claim_status= 'Settled',	        
				claim_sub_status = 'Settled'
		   WHERE claim_id = l_claims.claim_id;  	
		  ELSIF l_billed_cnt = 0   THEN 
		  UPDATE claims.xxtwc_claims_headers 
		   SET  claim_status= 'Approved',	        
				claim_sub_status = 'Awaiting Rebill Processing'
		   WHERE claim_id = l_claims.claim_id;  		   
		 END IF; 
	 END IF;	 
    ELSIF l_claims.claim_type IN ('IMPORT_CLAIM','PRICE_ADJ','REJECT_DUMPED','FREIGHT_ONLY','UNREFRENCE_CLAIM','JUICE_CLAIM','AR_CLAIM','CREDIT_CLAIM') AND 
	      (l_claims.claim_sub_status = 'RMA/Claims Order Created' OR  l_claim_status= 'RMA/Claims Order Created' ) THEN 

		l_billed_cnt  := 0;
		l_total_line_cnt := 0;
	 FOR l_rma_lines_bill IN c_rma_lines_bill(l_claims.ora_rma_no ) LOOP

	  IF l_rma_lines_bill.status_code = 'BILLED' AND l_rma_lines_bill.cnt > 0 THEN
	   l_billed_cnt := l_billed_cnt + l_rma_lines_bill.cnt; 
	  END IF;	 
	 END LOOP; 
	 BEGIN
		SELECT COUNT(1)
		INTO l_total_line_cnt
		FROM fusion.doo_headers_all head               ,
             fusion.doo_fulfill_lines_all fline    
	    WHERE head.order_number =l_claims.ora_rma_no
		AND fline.status_code != 'CANCELLED'
		AND fline.header_id  = head.header_id;
	 END;

	 IF l_billed_cnt >0 AND  l_total_line_cnt != l_billed_cnt THEN
      UPDATE claims.xxtwc_claims_headers 
	   SET  claim_status= 'Settled',	        
			claim_sub_status = 'Partial settled'
	   WHERE claim_id = l_claims.claim_id; 	 
      ELSIF l_billed_cnt >0 AND  l_total_line_cnt = l_billed_cnt THEN 
      UPDATE claims.xxtwc_claims_headers 
	   SET  claim_status= 'Settled',	        
			claim_sub_status = 'Credit Memo Processed'
	   WHERE claim_id = l_claims.claim_id;  	
      ELSIF l_billed_cnt = 0   THEN 
      UPDATE claims.xxtwc_claims_headers 
	   SET  claim_status= 'Awaiting Billing',	        
			claim_sub_status = 'Awaiting Billing'
	   WHERE claim_id = l_claims.claim_id;  		   
	 END IF; 
   END IF;
 COMMIT;

  END LOOP;
EXCEPTION
 WHEN OTHERS THEN
 raise_application_error('-20000','Error While Processing XXTWC_CLAIMS_STATUS_UPDATE_PKG.update_status:-'||sqlerrm); 
 xxtwc_claims_gp_error_pkg.gp_error_log ('Error', 
                                          sqlcode ,     
                                          'Error While Processing XXTWC_CLAIMS_STATUS_UPDATE_PKG.update_status :-'||sqlerrm, 
                                          -1,
                                         -1,
										 NULL
                                          );
END;  
END;


/