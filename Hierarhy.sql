/*
first create view and Function, then run the anonymous block
*/
declare @Material int = 10000
    ,@PlantID varchar(10) = 'RLT_10'
    ,@Year int = 2024

    ,@finMaterial int
    ,@finRelease_type varchar(10)
    ,@finProd_type int
    ,@finMaterialCount int;

begin
    drop table if exists #tempRes;

    SELECT * into #tempRes  
    FROM dbo.fn_GetBomHierarhy(@Material,@PlantID, @Year); 

    Select @finMaterial = material
    , @finRelease_type = release_type
    , @finProd_type =  prod_type 
    , @finMaterialCount = material_cnt
    from #tempRes where material = @Material

    select 
    plant
    , @finMaterial fin_material_id
    , @finRelease_type fin_material_release_type
    , @finProd_type fin_material_production_type
    , @finMaterialCount fin_production_quantity
    , material --prod_material_id
    , release_type --prod_material_release_type
    , prod_type --prod_material_production_type
    , material_cnt --prod_material_production_quantity
    , component --component_id
    , comp_release_type --component_material_release_type
    , comp_prod_type --component_material_production_type
    , component_cnt --Component_consumption_quantity
    , year
    from #tempRes
    where level<>1
    order by level,comp_prod_type desc;
end;

--create or alter view v_bomGroupBy
--as
--select 
--produced_material
--,produced_material_production_type
--,produced_material_release_type
--,sum(TRY_PARSE(produced_material_quantity AS DECIMAL(18, 2) USING 'en-US')) material_cnt	
--,component_material
--,component_material_production_type
--,component_material_release_type
--,sum(TRY_PARSE(component_material_quantity AS DECIMAL(18, 2) USING 'en-US')) component_cnt
--,plant_id, year from bom
--group by year, produced_material,produced_material_production_type,
--produced_material_release_type
--,component_material,component_material_production_type,component_material_release_type
--,plant_id;


--CREATE OR ALTER FUNCTION dbo.fn_GetBomHierarhy (
--    @Material int, 
--    @PlantID varchar(10),
--    @Year int
--)
--RETURNS TABLE 
--AS
--RETURN 
--(
--    -- create Recursive CTE
--    WITH BomHierarhy AS (
--    -- 
--    SELECT 
--        plant_id as plant,
--        year,
--        produced_material as material,
--        produced_material_release_type as release_type,
--        produced_material_production_type as prod_type,
--        material_cnt,
--        component_material as component,
--        component_material_release_type as comp_release_type,
--        component_material_production_type as comp_prod_type,
--        component_cnt,
--        1 AS Level
--    FROM v_bomGroupBy
--    WHERE produced_material_release_type = 'FIN'
--    and plant_id = @PlantID
--    and year = @Year
--    and produced_material = @Material

--    UNION ALL

--    -- 
--    SELECT 
--        t.plant_id as plant,
--        t.year,
--        t.produced_material as material,
--        t.produced_material_release_type as release_type,
--        t.produced_material_production_type as prod_type,
--        t.material_cnt, 
--        t.component_material as component,
--        t.component_material_release_type as comp_release_type,
--        t.component_material_production_type as comp_prod_type,
--        t.component_cnt,
--        be.Level + 1
--    FROM v_bomGroupBy t
--    INNER JOIN BomHierarhy be ON t.produced_material = be.component
--        AND t.plant_id = be.plant
--        and t.year = be.year
--)
--SELECT *  
--FROM BomHierarhy b
--)

