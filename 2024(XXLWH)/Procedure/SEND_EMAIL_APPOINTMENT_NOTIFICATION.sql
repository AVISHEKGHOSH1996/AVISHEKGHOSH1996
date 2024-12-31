create or replace PROCEDURE SEND_EMAIL_APPOINTMENT_NOTIFICATION
	IS
v_email_body VARCHAR2(4000);

	LV_EMAIL_BODY VARCHAR2(30000);

	LV_RE_EMAIL VARCHAR2(30000):='Hi,
<br>
<br>

				This is a gentle reminder that the pickup appointment is scheduled within the next 24 hours at <b>#LOCATION# </b>Location for the orders listed below.

				If you haven''t'' already done 

				so, please update the driver details in the carrier portal at your earliest convenience.
<br>
<br>
<table>
<b>#TABLE_DATA#</b>
</table>
<br><br>Thanks!!<br>Wonderful';

	LV_TABLE_DATA VARCHAR2(30000) := '<tr>
<th  style="border : 1px solid; text-align: center;">Sales Order Number</th>
<th  style="border : 1px solid; text-align: center;">WMS Order Number</th>
<th  style="border : 1px solid; text-align: center;">Schedule Ship Date</th>
<th  style="border : 1px solid; text-align: center;">Pallets</th>
<th  style="border : 1px solid; text-align: center;">Cases</th>
<th  style="border : 1px solid; text-align: center;">Facility</th>
<th  style="border : 1px solid; text-align: center;">Status</th>
<th  style="border : 1px solid; text-align: center;">Customer Name</th>
<th  style="border : 1px solid; text-align: center;">Customer Address</th>
<th  style="border : 1px solid; text-align: center;">Last Updated By</th>
<th  style="border : 1px solid; text-align: center;">Last Update Date</th>
</tr>
	<tr>
<td  style="border : 1px solid; text-align: center;"> #SALES_ORDER_NUMBER# </td>
<td  style="border : 1px solid; text-align: center;"> #WMS_Order_Number# </td>
<td  style="border : 1px solid; text-align: center;"> #SCHEDULE_SHIP_DATE#</td>
<td  style="border : 1px solid; text-align: center;"> #PALLETS#</td>
<td  style="border : 1px solid; text-align: center;"> #CASES#</td>
<td  style="border : 1px solid; text-align: center;"> #FACILITY#</td>
<td  style="border : 1px solid; text-align: center;"> #STATUS#</td>
<td  style="border : 1px solid; text-align: center;"> #CUSTOMER_NAME#</td>
<td  style="border : 1px solid; text-align: center;"> #CUSTOMER_ADDRESS#</td>
<td  style="border : 1px solid; text-align: center;"> #LAST_UPDATED_BY#</td>
<td  style="border : 1px solid; text-align: center;"> #LAST_UPDATE_DATE#</td>
</tr>';

	LV_REPLACED_DATA	 VARCHAR2(30000);		

    LV_DATA  VARCHAR2(30000);	

    LV_LOCATION	VARCHAR2(30000);	

	BEGIN

	--DBMS_OUTPUT.PUT_LINE('START');

    FOR J IN (SELECT  APPOINTMENT_NUMBER,LAST_UPDATED_BY FROM xxtwc_ymt_appointment WHERE DRIVER_NAME IS NOT NULL

                                 AND DRIVER_PHONE_NO IS NOT NULL

                                 AND CONFIRM_DATE BETWEEN SYSDATE AND SYSDATE +1)

    LOOP

		--DBMS_OUTPUT.PUT_LINE('enter first loop');
        LV_REPLACED_DATA:=NULL;

	FOR I IN ( SELECT  

    ao.order_nbr, 

    ao.sales_order_number,

    carrier_notify,

    max(Req_ship_date) sched_ship_date,

    round(SUM(wol.ord_qty / eff.attribute_char16), 2) PALLETS,

    SUM(ORD_QTY) CASES,

    a.FACILITY,

    a.STATUS,

    wo.CUST_NAME,

    wo.CUST_ADDR,

    ao.LAST_UPDATED_BY,

    ao.LAST_UPDATE_DATE,
	a.appointment_number

FROM  

    xxtwc_ymt_appointment_orders ao, 

    xxtwc_wms_order_header wo ,

    XXTWC_WMS_ORDER_LINE wol,

    xxtwc_egp_system_items_vl item,

    xxtwc_inv_org_parameters  inv,

    xxtwc_ego_item_eff_b      eff,

( select a.*, 

  CASE WHEN SOURCE_SYSTEM = 'OTM' THEN LOAD_NUMBER ELSE NULL END CARRIER_NOTIFy 

  from xxtwc_ymt_appointment a ) a

WHERE a.appointment_number = ao.appointment_number

  and   a.appointment_number = J.appointment_number

  AND  ao.order_nbr = wo.order_nbr

  AND  ao.sales_order_number = wo.sales_order_nbr

  AND  wo.facility_code = a.facility

  AND  wol.item_alternate_code = item.item_number

  AND  item.organization_id = inv.organization_id

  AND inv.organization_code = wo.facility_code

  AND item.primary_uom_code = 'CTN'

  AND item.inventory_item_id = eff.inventory_item_id

  AND NOT EXISTS (

                   SELECT

                        1

                    FROM

                        xxics.xxtwc_wms_cancelled_ord_dtl cancel_line

                    WHERE

                        cancel_line.line_id = wol.line_id

                        AND wo.sales_order_nbr = cancel_line.sales_order_nbr

                )

  AND wo.header_id = wol.header_id

  AND a.DRIVER_NAME IS NOT NULL

  AND a.DRIVER_PHONE_NO IS NOT NULL

  AND a.CONFIRM_DATE BETWEEN SYSDATE AND SYSDATE +1

  group by ao.order_nbr,ao.sales_order_number,carrier_notify,a.FACILITY,a.STATUS,ao.LAST_UPDATED_BY,ao.LAST_UPDATE_DATE, wo.CUST_NAME,

    wo.CUST_ADDR,a.appointment_number

                )

	LOOP

		  LV_REPLACED_DATA := LV_REPLACED_DATA || LV_TABLE_DATA;

			  LV_REPLACED_DATA := REPLACE(LV_REPLACED_DATA, '#FACILITY#',I.Facility);

			  LV_REPLACED_DATA := REPLACE(LV_REPLACED_DATA, '#LAST_UPDATE_DATE#',I.LAST_UPDATE_DATE);

			  LV_REPLACED_DATA := REPLACE(LV_REPLACED_DATA, '#LAST_UPDATED_BY#',I.LAST_UPDATED_BY);

              LV_REPLACED_DATA := REPLACE(LV_REPLACED_DATA, '#WMS_Order_Number#',I.order_nbr);

			  LV_REPLACED_DATA := REPLACE(LV_REPLACED_DATA, '#SALES_ORDER_NUMBER#',I.sales_order_number);

              LV_REPLACED_DATA := REPLACE(LV_REPLACED_DATA, '#PALLETS#',I.PALLETS);

              LV_REPLACED_DATA := REPLACE(LV_REPLACED_DATA, '#STATUS#',I.STATUS);

              LV_REPLACED_DATA := REPLACE(LV_REPLACED_DATA, '#CUSTOMER_NAME#',I.CUST_NAME);

              LV_REPLACED_DATA := REPLACE(LV_REPLACED_DATA, '#CUSTOMER_ADDRESS#',I.CUST_ADDR);

              LV_REPLACED_DATA := REPLACE(LV_REPLACED_DATA, '#SCHEDULE_SHIP_DATE#',I.sched_ship_date);

              LV_REPLACED_DATA := REPLACE(LV_REPLACED_DATA, '#SCHEDULE_SHIP_DATE#',I.sched_ship_date);

              LV_REPLACED_DATA := REPLACE(LV_REPLACED_DATA, '#CASES#',I.CASES);	  

    BEGIN

    SELECT CODE || ' , ' || ADDRESS_1 ||' , '|| CITY ||' , '|| STATE ||' , '|| ZIP || ' , '|| COUNTRY

    INTO LV_LOCATION

    FROM facility F

    WHERE F.CODE = I.Facility;

	EXCEPTION WHEN OTHERS THEN 

    LV_LOCATION := NULL;

    END;

 --DBMS_OUTPUT.PUT_LINE('SALES ORD:'||I.order_nbr||' APPT # '||i.appointment_number||'FIRST LOOP APPT # '||J.appointment_number);

    END LOOP;

	 LV_EMAIL_BODY := LV_RE_EMAIL;

        LV_EMAIL_BODY := REPLACE(LV_EMAIL_BODY, '\',NULL);

    LV_EMAIL_BODY := REPLACE(LV_EMAIL_BODY, '#TABLE_DATA#',NVL(LV_REPLACED_DATA,'No Sales Order Found')); -- LV_EMAIL_BODY := REPLACE(LV_EMAIL_BODY, '#TABLE_DATA#',LV_REPLACED_DATA));

    LV_EMAIL_BODY := REPLACE(LV_EMAIL_BODY, '#LOCATION#',LV_LOCATION);
 
				apex_mail.send( p_from        => 'No-Reply-regs@Wonderful.com',
                                p_to          => J.LAST_UPDATED_BY,
                                p_subj        => 'Pickup Appointment Scheduled Within 24 Hours',
                                p_body        => 'Appointment Notification Mail',
                                p_body_html   => LV_EMAIL_BODY);
                apex_mail.push_queue ();
	END LOOP;
 
	END SEND_EMAIL_APPOINTMENT_NOTIFICATION;
/
