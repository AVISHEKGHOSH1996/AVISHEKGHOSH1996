create or replace PACKAGE  XXLWH_JUSTIN_SCORECARD_PKG
IS
 FUNCTION GET_TWC_SCORECARD_BY_PROGRAM(
    P_TWC_BRAND         IN  VARCHAR2,
    P_VINTAGE           IN  VARCHAR2
    )
    RETURN VARCHAR2
    ;

    ------------------------------------------------------------------

    FUNCTION GET_TWC_SCORECARD_DETAIL_PROGRAM_PIVOT(
    P_TWC_BRAND         IN  VARCHAR2,
    P_VINTAGE           IN  VARCHAR2
    )
    RETURN VARCHAR2
    ;
-----------------------------------------------------------------   	
FUNCTION TWC_SCORECARD(
    P_TWC_BRAND         IN  VARCHAR2,
    P_VINTAGE           IN  VARCHAR2
    )
    RETURN VARCHAR2
    ;

END XXLWH_JUSTIN_SCORECARD_PKG;

-------------------------------------------------------------------------------------
Call FUNCTION inside PACKAGE:-
-------------------------------------------------------------------------------------

RETURN XXLWH_JUSTIN_SCORECARD_PKG.GET_TWC_SCORECARD_DETAIL_PROGRAM_PIVOT(
            P_TWC_BRAND         => :P9_TWC_BRAND, 
            P_VINTAGE           => :P9_VINTAGE 
       );
