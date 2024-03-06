create or replace PACKAGE BODY XXLWH_JUSTIN_SCORECARD_PKG IS

FUNCTION GET_TWC_SCORECARD_BY_PROGRAM(P_TWC_BRAND IN VARCHAR2,
P_VINTAGE IN VARCHAR2) 
RETURN VARCHAR2
IS
    lv_pivot_contact_types varchar2(4000);
    lv_pivot_query varchar2(15000);
	
begin

    select listagg(CONTRACT_TYPE, ',' ) 
    into lv_pivot_contact_types from 
    (select distinct '''' || CONTRACT_TYPE || '''' || ' as ' || '"' || CONTRACT_TYPE || '"' as CONTRACT_TYPE 
    from XXLWH_SCORECARD_BY_PROGRAM_V
    );

lv_pivot_query := '
SELECT * FROM
(   SELECT PROGRAM,
          VARIETY,
          VINTAGE,
       HARVEST_NEEDS,
       TONS_TO_DATE,CONTRACT_TYPE,QUANTITY_ALT_UNITS,GRAND_QUANTITY_ALT_UNITS
  FROM
    (SELECT DISTINCT PROGRAM,
        VARIETY,
        VINTAGE,
       CONTRACT_TYPE,
       HARVEST_NEEDS,
       TONS_TO_DATE,
       QUANTITY_ALT_UNITS,
      GRAND_QUANTITY_ALT_UNITS
       FROM
(select 
       PROGRAM,
       VARIETY,
       VINTAGE,
       CONTRACT_TYPE,
       SUM(HARVEST_NEEDS) OVER(PARTITION BY PROGRAM,VARIETY) HARVEST_NEEDS,
       SUM(NVL(TONS_TO_DATE,0)) OVER(PARTITION BY PROGRAM,VARIETY) TONS_TO_DATE,
       SUM(QUANTITY_ALT_UNITS) OVER(PARTITION BY PROGRAM,VARIETY) GRAND_QUANTITY_ALT_UNITS,
       SUM(QUANTITY_ALT_UNITS) OVER(PARTITION BY PROGRAM,CONTRACT_TYPE,VARIETY) QUANTITY_ALT_UNITS
  from XXLWH_SCORECARD_BY_PROGRAM_V
  where (instr('':''||'''||P_TWC_BRAND||'''||'':'', '':''||TWC_BRAND||'':'') > 0  or '''|| P_TWC_BRAND||''' is null ) 
    and  (instr('':''||'''||P_VINTAGE||'''||'':'', '':''||VINTAGE||'':'') > 0  or '''|| P_VINTAGE||''' is null ) 
  ))
)
PIVOT
(
  sum(QUANTITY_ALT_UNITS)
  FOR CONTRACT_TYPE IN ('|| lv_pivot_contact_types ||')
)
ORDER BY PROGRAM, VARIETY
';
    return lv_pivot_query;
end;

FUNCTION GET_TWC_SCORECARD_DETAIL_PROGRAM_PIVOT(P_TWC_BRAND IN VARCHAR2,
P_VINTAGE IN VARCHAR2) 
RETURN VARCHAR2
IS
    lv_pivot_contact_types varchar2(4000);
    lv_pivot_query varchar2(15000);
	
begin

    select listagg(CONTRACT_TYPE, ',' ) 
    into lv_pivot_contact_types from 
    (select distinct '''' || CONTRACT_TYPE || '''' || ' as ' || '"' || CONTRACT_TYPE || '"' as CONTRACT_TYPE 
    from XXLWH_SCORECARD_DETAIL_PIVOT_V
 
    );

lv_pivot_query := '
SELECT * FROM
(   SELECT PROGRAM,
          VARIETY,
          VINTAGE,
           CODE_APPELLATION,
        CONTRACT_NAME,
        BLOCK_NAME,
       BLOCK_CODE,
       CONTRACT_PRICE,
       HARVEST_NEEDS,
       TONS_TO_DATE,CONTRACT_TYPE,EXPECTED_YIELDS_TONS,PLANTED_AREA
  FROM
    (SELECT DISTINCT PROGRAM,
        VARIETY,
        VINTAGE,
        CODE_APPELLATION,
        CONTRACT_NAME,
        BLOCK_NAME,
       BLOCK_CODE,
       CONTRACT_PRICE,
       CONTRACT_TYPE,
       HARVEST_NEEDS,
       TONS_TO_DATE,
       EXPECTED_YIELDS_TONS,
      PLANTED_AREA
       FROM
(select 
       PROGRAM,
       VARIETY,
       VINTAGE,
       CODE_APPELLATION,
       CONTRACT_NAME,
       BLOCK_NAME,
       BLOCK_CODE,
       CONTRACT_PRICE,
       CONTRACT_TYPE,
       SUM(HARVEST_NEEDS) OVER(PARTITION BY PROGRAM,VARIETY) HARVEST_NEEDS,
       SUM(NVL(TONS_TO_DATE,0)) OVER(PARTITION BY PROGRAM,VARIETY) TONS_TO_DATE,
       SUM(PLANTED_AREA) OVER(PARTITION BY PROGRAM,VARIETY) PLANTED_AREA,
       SUM(EXPECTED_YIELDS_TONS) OVER(PARTITION BY PROGRAM,CONTRACT_TYPE,VARIETY) EXPECTED_YIELDS_TONS
  from XXLWH_SCORECARD_DETAIL_PIVOT_V
  where (instr('':''||'''||P_TWC_BRAND||'''||'':'', '':''||TWC_BRAND||'':'') > 0  or '''|| P_TWC_BRAND||''' is null ) 
    and  (instr('':''||'''||P_VINTAGE||'''||'':'', '':''||VINTAGE||'':'') > 0  or '''|| P_VINTAGE||''' is null ) 
  ))
)
PIVOT
(
  sum(EXPECTED_YIELDS_TONS)
  FOR CONTRACT_TYPE IN ('|| lv_pivot_contact_types ||')
)
ORDER BY PROGRAM, VARIETY
';

    return lv_pivot_query;
end;

-------------------------------------

FUNCTION TWC_SCORECARD(P_TWC_BRAND IN VARCHAR2,
P_VINTAGE IN VARCHAR2) 
RETURN VARCHAR2
IS
    lv_pivot_contact_types varchar2(4000);
    lv_pivot_query varchar2(15000);
begin

    select listagg(CONTRACT_TYPE, ',' ) 
    into lv_pivot_contact_types from 
    (select distinct '''' || CONTRACT_TYPE || '''' || ' as ' || '"' || CONTRACT_TYPE || '"' as CONTRACT_TYPE 
    from XXLWH_SCORECARD_V
    
    );

lv_pivot_query := '
SELECT * FROM
(   SELECT PROGRAM,
       HARVEST_NEEDS,
       TONS_TO_DATE,CONTRACT_TYPE,VINTAGE,QUANTITY_ALT_UNITS,GRAND_QUANTITY_ALT_UNITS
  FROM
    (SELECT DISTINCT PROGRAM,
       CONTRACT_TYPE,
       VINTAGE,
       HARVEST_NEEDS,
       TONS_TO_DATE,
       QUANTITY_ALT_UNITS,
      GRAND_QUANTITY_ALT_UNITS
       FROM
(select 
       PROGRAM,
       CONTRACT_TYPE,
       VINTAGE,
       SUM(HARVEST_NEEDS) OVER(PARTITION BY PROGRAM) HARVEST_NEEDS,
       SUM(NVL(TONS_TO_DATE,0)) OVER(PARTITION BY PROGRAM) TONS_TO_DATE,
       SUM(QUANTITY_ALT_UNITS) OVER(PARTITION BY PROGRAM) GRAND_QUANTITY_ALT_UNITS,
       SUM(QUANTITY_ALT_UNITS) OVER(PARTITION BY PROGRAM,CONTRACT_TYPE) QUANTITY_ALT_UNITS
  from XXLWH_SCORECARD_V
  where (instr('':''||'''||P_TWC_BRAND||'''||'':'', '':''||TWC_BRAND||'':'') > 0  or '''|| P_TWC_BRAND||''' is null ) 
    and  (instr('':''||'''||P_VINTAGE||'''||'':'', '':''||VINTAGE||'':'') > 0  or '''|| P_VINTAGE||''' is null ) 	
	
  ))
)
PIVOT
(
  sum(QUANTITY_ALT_UNITS)
  FOR CONTRACT_TYPE IN ('|| lv_pivot_contact_types ||')
)
';

    return lv_pivot_query;
end;

END XXLWH_JUSTIN_SCORECARD_PKG;	