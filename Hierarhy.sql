/*
 Firstly create view and Function, then run the anonymous block.
 You can't run the whole file, syntax error: Create View or Create Function should be the only one in the package. 
 But you can run the file step by step
 */

-- alter table bom 
--add produced_material_quantity_upd float,
--component_material_quantity_upd FLOAT;

--UPDATE bom
--    SET 
--    produced_material_quantity_upd = 
--        TRY_PARSE(
--            produced_material_quantity AS DECIMAL(18, 2) USING 'en-US'
--        ) ,
--    component_material_quantity_upd = 
--        TRY_PARSE(
--            component_material_quantity AS DECIMAL(18, 2) USING 'en-US'
--        );


-- step 1
CREATE OR ALTER VIEW v_bomGroupBy AS
SELECT
    produced_material,
    produced_material_production_type,
    produced_material_release_type,
    sum(produced_material_quantity_upd) material_cnt,
    component_material,
    component_material_production_type,
    component_material_release_type,
    sum(component_material_quantity_upd) component_cnt,
    plant_id,
    year
FROM
    bom
GROUP BY
    year,
    produced_material,
    produced_material_production_type,
    produced_material_release_type,
    component_material,
    component_material_production_type,
    component_material_release_type,
    plant_id;

-- step 2 
CREATE OR ALTER FUNCTION dbo.fn_GetBomHierarhy (
    @Material int,
    @PlantID varchar(10),
    @Year int
) RETURNS TABLE AS RETURN (
    -- create Recursive CTE
    WITH BomHierarhy AS (
        SELECT
            plant_id AS plant,
            produced_material AS fin_material_id,
            produced_material_release_type AS fin_material_release_type,
            produced_material_production_type AS fin_material_production_type,
            material_cnt AS fin_production_quantity,
            produced_material AS prod_material_id,
            produced_material_release_type AS prod_material_release_type,
            produced_material_production_type AS prod_material_production_type,
            material_cnt AS prod_material_production_quantity,
            component_material AS component_id,
            component_material_release_type AS component_material_release_type,
            component_material_production_type AS component_material_production_type,
            component_cnt AS component_consumption_quantity,
            1 AS LEVEL,
            year
        FROM
            v_bomGroupBy
        WHERE
            produced_material_release_type = 'FIN'
            --AND plant_id = @PlantID
            AND year = @Year
            --AND produced_material = @Material
        UNION
        ALL
        SELECT
            t.plant_id AS plant,
            be.fin_material_id,
            be.fin_material_release_type,
            be.fin_material_production_type,
            be.fin_production_quantity,
            t.produced_material AS prod_material_id,
            t.produced_material_release_type AS prod_material_release_type,
            t.produced_material_production_type AS prod_material_production_type,
            t.material_cnt AS prod_material_production_quantity,
            t.component_material AS component_id,
            t.component_material_release_type AS component_material_release_type,
            t.component_material_production_type AS component_material_production_type,
            t.component_cnt AS component_consumption_quantity,
            be.level + 1,
            t.year
        FROM
            v_bomGroupBy t
            INNER JOIN BomHierarhy be ON t.produced_material = be.component_id
            AND t.plant_id = be.plant
            AND t.year = be.year
    )
    SELECT
        *
    FROM
        BomHierarhy b
    WHERE
        LEVEL > 1
);
/*
possible indexes for improving performance
1) compose index for bom(YEAR,produced_material_release_type) for where clause
2) index for join 
*/

-- step 3 FINAL
declare 
@Material int = 10000,
@PlantID varchar(10) = 'RLT_10',
@Year int = 2024 


SET STATISTICS TIME ON;
GO

BEGIN
SELECT
    *
FROM
    fn_GetBomHierarhy(10000, 'RLT_10', 2024);

END;

GO
SET STATISTICS TIME OFF;

/*
   SQL Server Execution Times:
   CPU time = 16 ms,  elapsed time = 50 ms.

   ->Increase number of rows from 1320 to 133,320
   SQL Server Execution Times:
   CPU time = 719 ms,  elapsed time = 832 ms.

   ->Adding indexes on join fields component_material, produced_material doesn't improve performance
   Because View uses Group by
*/