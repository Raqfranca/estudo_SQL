-- Ugr 
-- Backlog // Total // Outliers // Com SPC // Com Entrante_Real // Com Realizado_Real 
--MT = megaTabela 
--MN = miniTabela 
DECLARE @cod_Origem INT = 1
DECLARE @dat_Referencia DATE = '2023-04-12' 
DECLARE @cod_Regional INT = 1
DECLARE @cod_Status INT = 4
DECLARE @dat_Encerramento DATETIME = '2023-04-12 23:59:59.999' -- alterar 

SELECT MT.Cluster
    ,SUM(Total) as  Total
    ,SUM(Outliers) as  Outliers
    ,SUM(Entrante_Real) as Entrante_Real  
    ,SUM(Realizado_Real) as Realizado_Real  
FROM (
    SELECT nom_Cluster as [Cluster]
        ,COUNT (cod_ID) as [Total] 
        ,0 as [Outliers] 
        ,0 as [Entrante_Real]
        ,0 as [Realizado_Real]
    FROM TB_PL_Reparo_Restante as RR WITH (NOLOCK) 
    WHERE dat_Referencia = @dat_Referencia 
         AND cod_Cluster BETWEEN 1 AND 13
         AND cod_Origem = @cod_Origem
    GROUP BY cod_Cluster
          ,nom_Cluster
    UNION all
    SELECT nom_Cluster as [Cluster]
        ,0 as [Total] 
        ,0 as [Outliers] 
        ,COUNT (cod_ID) as [Entrante_Real]
        ,0 as [Realizado_Real]
    FROM TB_PL_Reparo_Entrante WITH (NOLOCK)
    WHERE dat_Referencia = @dat_Referencia
        AND cod_Origem = @cod_Origem
        AND cod_Regional = @cod_Regional 
        AND cod_Cluster BETWEEN 1 AND 13 
        AND  (dat_Encerramento >= @dat_Encerramento OR cod_Status <> 3)
    GROUP BY nom_Cluster
    UNION all 
    SELECT nom_Cluster as [Cluster] 
        ,0 as [Total]   
        ,COUNT (cod_ID) as [Outliers] 
        ,0 as [Entrante_Real]
        ,0 as [Realizado_Real]
    FROM TB_PL_Reparo_Restante  WITH (NOLOCK) 
    WHERE dat_Referencia = @dat_Referencia
        AND cod_Regional = @cod_Regional 
        AND cod_Origem = @cod_Origem
        AND ind_OutliersHoras <> 0  
    GROUP BY cod_Cluster
        ,nom_Cluster
        UNION all 
    SELECT nom_Cluster as [Cluster]
        ,0 as [Total] 
        ,0 as [Outliers] 
        ,0 as [Entrante_Real] 
        ,COUNT (cod_ID) as [Realizado Real]
    FROM TB_PL_Reparo_Encerrado WITH (NOLOCK)
    WHERE dat_Referencia = @dat_Referencia
        AND cod_Origem = @cod_Origem 
        AND cod_Regional = @cod_Regional  
        AND cod_Cluster BETWEEN 1 AND 13 
        AND cod_Status = 4 
    GROUP BY nom_Cluster
	UNION all 
	SELECT 'SPC' as [Cluster] 
			,COUNT (cod_ID) as [Total]
		,0 as [Outliers] 
		,0 as [Entrante Real]
		,0 as [Realizado_Real]
	FROM TB_PL_Reparo_Restante WITH (NOLOCK) 
	WHERE dat_Referencia = @dat_Referencia
		AND cod_Origem = @cod_Origem
		AND cod_Cluster BETWEEN 1 AND 13  
	UNION all 
	SELECT 'SPC' as [Cluster] 
		,0 as [Total] 
		,0 as [Outliers]
		,0 as [Entrante_Real]
		,COUNT (cod_ID) as [Realizado Real]
	FROM TB_PL_Reparo_Encerrado WITH (NOLOCK)
	WHERE dat_Referencia = @dat_Referencia
		AND cod_Origem = @cod_Origem
		AND cod_Regional = @cod_Regional 
		AND cod_Status = @cod_Status
	UNION all 
	SELECT 'SPC' as [Cluster] 
		,0 as [Total] 
		,COUNT (cod_ID) as [Outliers]
		,0 as [Entrante_Real]
		,0 as [Realizado_Real]
	FROM TB_PL_Reparo_Restante  WITH (NOLOCK) 
	WHERE dat_Referencia = @dat_Referencia
		AND cod_Origem = @cod_Origem 
		AND cod_Cluster BETWEEN 1 AND 13
		AND ind_OutliersHoras <> 0  
	UNION all
	SELECT 'SPC' as [Cluster] 
		,0 as [Total]
		,0 as [Outliers] 
		,COUNT (cod_ID) as [Entrante_Real]
		,0 as [Realizado_Real]
	FROM TB_PL_Reparo_Entrante WITH (NOLOCK)
	WHERE dat_Referencia = @dat_Referencia 
		AND cod_Origem = @cod_Origem
		AND cod_Regional = @cod_Regional
		AND  (dat_Encerramento >= @dat_Encerramento OR cod_Status <> 3)		   
)MT
LEFT JOIN (
	SELECT MIN(ind_Ordem) AS minInd 
		,nom_Cluster AS CLUSTER
	FROM TB_FGT_Contrato WITH (NOLOCK)
	GROUP BY ind_Ordem 
		,nom_Cluster 
)MN on MN.CLUSTER = MT.Cluster
GROUP BY MT.Cluster   
		,MN.minInd
ORDER BY MN.minInd ASC
	,MT.Cluster ASC
-- Massivo and Premium 
-- Backlog // Total // Outliers // Com SPC // Com Entrante_Real // Com Realizado_Real
DECLARE @indGpon INT = 0
WHILE @indGpon <= 1
-- megaTabela2 = MT2
-- miniTabela2 = MN2
BEGIN
	SELECT MT2.Cluster
		,SUM(Total) as  Total
		,SUM(Outliers) as  Outliers
		,SUM(Entrante_Real) as Entrante_Real  
		,SUM(Realizado_Real) as Realizado_Real  
	FROM (
		SELECT nom_Cluster as [Cluster]
   			,COUNT (cod_ID) as [Total] 
			,0 as [Outliers] 
			,0 as [Entrante_Real]
			,0 as [Realizado_Real]
		FROM TB_PL_Reparo_Restante as RR WITH (NOLOCK) 
		WHERE dat_Referencia = @dat_Referencia 
   			AND cod_Cluster BETWEEN 1 AND 13
   			AND cod_Origem = @cod_Origem
			AND ind_Gpon = @indGpon
		GROUP BY cod_Cluster
   			,nom_Cluster
		UNION all
		SELECT nom_Cluster as [Cluster]
			,0 as [Total] 
			,0 as [Outliers] 
			,COUNT (cod_ID) as [Entrante_Real]
			,0 as [Realizado_Real]
		FROM TB_PL_Reparo_Entrante WITH (NOLOCK)
		WHERE dat_Referencia = @dat_Referencia 
			AND cod_Origem = @cod_Origem
			AND cod_Regional = @cod_Regional 
			AND cod_Cluster BETWEEN 1 AND 13 
			AND  (dat_Encerramento >= '2023-04-12 23:59:59.999' OR cod_Status <> 3)
			AND ind_Gpon = @indGpon
		GROUP BY nom_Cluster
		UNION all 
		SELECT 'SPC' as [Cluster] 
			,COUNT (cod_ID) as [Total]
			,0 as [Outliers] 
			,0 as [Entrante Real]
			,0 as [Realizado_Real]
		FROM TB_PL_Reparo_Restante WITH (NOLOCK) 
		WHERE dat_Referencia = @dat_Referencia 
			AND cod_Origem = @cod_Origem
			AND cod_Cluster BETWEEN 1 AND 13
			AND ind_Gpon = @indGpon 
		UNION all
		SELECT nom_Cluster as [Cluster] 
   			,0 as [Total]   
			,COUNT (cod_ID) as [Outliers] 
			,0 as [Entrante_Real]
			,0 as [Realizado_Real]
		FROM TB_PL_Reparo_Restante  WITH (NOLOCK) 
		WHERE dat_Referencia = @dat_Referencia
			AND cod_Regional = @cod_Regional
			AND cod_Origem = @cod_Origem
			AND ind_OutliersHoras <> 0  
			AND ind_Gpon = @indGpon
		GROUP BY cod_Cluster
			,nom_Cluster
		UNION all 
		SELECT nom_Cluster as [Cluster]
			,0 as [Total] 
			,0 as [Outliers] 
			,0 as [Entrante_Real] 
			,COUNT (cod_ID) as [Realizado Real]
		FROM TB_PL_Reparo_Encerrado WITH (NOLOCK)
		WHERE dat_Referencia = @dat_Referencia
			AND cod_Origem = @cod_Origem
			AND cod_Regional = @cod_Regional
			AND cod_Cluster BETWEEN 1 AND 13 
			AND cod_Status = @cod_Status 
			AND ind_Gpon = @indGpon
		GROUP BY nom_Cluster
		UNION all
		SELECT 'SPC' as [Cluster] 
			,0 as [Total] 
			,0 as [Outliers]
			,0 as [Entrante_Real]
			,COUNT (cod_ID) as [Realizado Real]
		FROM TB_PL_Reparo_Encerrado WITH (NOLOCK)
		WHERE dat_Referencia = @dat_Referencia
			AND cod_Origem = @cod_Origem
			AND cod_Regional = @cod_Regional
			AND cod_Status = @cod_Status
			AND ind_Gpon = @indGpon
		UNION all 
		SELECT 'SPC' as [Cluster] 
			,0 as [Total] 
			,COUNT (cod_ID) as [Outliers]
			,0 as [Entrante_Real]
			,0 as [Realizado_Real]
		FROM TB_PL_Reparo_Restante  WITH (NOLOCK) 
		WHERE dat_Referencia = @dat_Referencia 
			AND cod_Origem = @cod_Origem 
			AND cod_Cluster BETWEEN 1 AND 13
			AND ind_OutliersHoras <> 0  
			AND ind_Gpon = @indGpon	
		UNION all
		SELECT 'SPC' as [Cluster] 
			,0 as [Total]
			,0 as [Outliers] 
			,COUNT (cod_ID) as [Entrante_Real]
			,0 as [Realizado_Real]
		FROM TB_PL_Reparo_Entrante WITH (NOLOCK)
		WHERE dat_Referencia = @dat_Referencia 
			AND cod_Origem = @cod_Origem 
			AND cod_Regional = @cod_Regional 
			AND  (dat_Encerramento >= '2023-04-12 23:59:59.999' OR cod_Status <> 3)	-- alterar 
			AND ind_Gpon = @indGpon	
		GROUP BY nom_Cluster
	)MT2
	
	LEFT JOIN (
		SELECT MIN(ind_Ordem) AS minInd 
			,nom_Cluster AS CLUSTER
		FROM TB_FGT_Contrato WITH (NOLOCK)
		GROUP BY ind_Ordem 
			,nom_Cluster 
	)MN2 ON MN2.CLUSTER = MT2.Cluster
	GROUP BY MT2.Cluster   
		,MN2.minInd
	ORDER BY MN2.minInd ASC
	SET @indGpon = @indGpon + 1
END 



