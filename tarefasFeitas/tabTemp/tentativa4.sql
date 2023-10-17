------------------ refazendo a mega tabela ---------------------------

--SELECT * INTO #TABELA_TESTE FROM(
DECLARE @cod_Origem INT = 1, @dat_Referencia DATE = '2023-04-12', @cod_Regional INT = 1, @cod_Status INT = 4, @dat_Encerramento DATETIME = '2023-04-12 23:59:59.999', @I INT = 2, @ind_Gpon INT = NULL
WHILE @I >= 0
BEGIN
IF OBJECT_ID('TEMPDB..#FUNCIONAPELOAMORDEDEUS')   IS NOT NULL BEGIN DROP TABLE #FUNCIONAPELOAMORDEDEUS END	
	SELECT CASE @I
		WHEN 1 THEN 'Premium'
		WHEN 0 THEN 'Massivo'
		WHEN 2 THEN 'UGR'
	ELSE NULL END AS 'Tipo_Tecnologia'

	SET @ind_Gpon = CASE WHEN @I = 2 THEN NULL ELSE @I END 

SELECT * INTO #FUNCIONAPELOAMORDEDEUS FROM(
	SELECT MT.Cluster
   		,SUM(Total) as  Total
   		,SUM(Outliers) as  Outliers
   		,SUM(Entrante_Real) as Entrante_Real  
   		,SUM(Realizado_Real) as Realizado_Real  
	FROM (
   		SELECT nom_Cluster as [Cluster] -- TOTAL 
        	,COUNT (cod_ID) as [Total] 
       		,0 as [Outliers] 
       		,0 as [Entrante_Real]
       		,0 as [Realizado_Real]
   		FROM TB_PL_Reparo_Restante as RR WITH (NOLOCK) 
   		WHERE dat_Referencia = @dat_Referencia 
         	AND cod_Cluster BETWEEN 1 AND 13
         	AND cod_Origem = @cod_Origem
			AND (ind_Gpon = @ind_Gpon OR @ind_Gpon IS NULL)
   		GROUP BY cod_Cluster
          	  ,nom_Cluster
   		UNION all
		SELECT 'SPC' as [Cluster]  
				,COUNT (cod_ID) as [Total]
			,0 as [Outliers] 
			,0 as [Entrante Real]
			,0 as [Realizado_Real]
		FROM TB_PL_Reparo_Restante WITH (NOLOCK) 
		WHERE dat_Referencia = @dat_Referencia
			AND cod_Origem = @cod_Origem
			AND (ind_Gpon = @ind_Gpon OR @ind_Gpon IS NULL)
			AND cod_Cluster BETWEEN 1 AND 13  -- TOTAL 
		UNION all 
   		SELECT nom_Cluster as [Cluster] -- OUTLIERS 
        	,0 as [Total]   
       		,COUNT (cod_ID) as [Outliers] 
       		,0 as [Entrante_Real]
       		,0 as [Realizado_Real]
   		FROM TB_PL_Reparo_Restante  WITH (NOLOCK) 
   		WHERE dat_Referencia = @dat_Referencia
       		AND cod_Regional = @cod_Regional 
       		AND cod_Origem = @cod_Origem
       		AND ind_OutliersHoras <> 0 
			AND (ind_Gpon = @ind_Gpon OR @ind_Gpon IS NULL) 
   		GROUP BY cod_Cluster
       		,nom_Cluster
		UNION ALL
		SELECT 'SPC' as [Cluster] 
			,0 as [Total] 
			,COUNT (cod_ID) as [Outliers]
			,0 as [Entrante_Real]
			,0 as [Realizado_Real]
		FROM TB_PL_Reparo_Restante  WITH (NOLOCK) 
		WHERE dat_Referencia = @dat_Referencia
			AND cod_Origem = @cod_Origem 
			AND cod_Cluster BETWEEN 1 AND 13
			AND (ind_Gpon = @ind_Gpon OR @ind_Gpon IS NULL) 
			AND ind_OutliersHoras <> 0  -- OUTLIERS
		UNION ALL
		SELECT nom_Cluster as [Cluster] -- ENTRANTE REAL 
			,0 as [Total] 
       		,0 as [Outliers] 
       		,COUNT (cod_ID) as [Entrante_Real]
       		,0 as [Realizado_Real]
   		FROM TB_PL_Reparo_Entrante WITH (NOLOCK)
   		WHERE dat_Referencia = @dat_Referencia
       		AND cod_Origem = @cod_Origem
       		AND cod_Regional = @cod_Regional 
       		AND cod_Cluster BETWEEN 1 AND 13 
			AND (ind_Gpon = @ind_Gpon OR @ind_Gpon IS NULL) 
       		AND  (dat_Encerramento >= @dat_Encerramento OR cod_Status <> 3)
   		GROUP BY nom_Cluster
		UNION ALL 
			SELECT 'SPC' as [Cluster]   
			,0 as [Total]
			,0 as [Outliers] 
			,COUNT (cod_ID) as [Entrante_Real]
			,0 as [Realizado_Real]
		FROM TB_PL_Reparo_Entrante WITH (NOLOCK)
		WHERE dat_Referencia = @dat_Referencia 
			AND cod_Origem = @cod_Origem
			AND cod_Regional = @cod_Regional
			AND (ind_Gpon = @ind_Gpon OR @ind_Gpon IS NULL) 
			AND  (dat_Encerramento >= @dat_Encerramento OR cod_Status <> 3)	-- ENTRANTE REAL 
		UNION ALL 
		SELECT nom_Cluster as [Cluster] -- REALIZADO REAL 
       		,0 as [Total] 
       		,0 as [Outliers] 
       		,0 as [Entrante_Real] 
       		,COUNT (cod_ID) as [Realizado Real]
   		FROM TB_PL_Reparo_Encerrado WITH (NOLOCK)
   		WHERE dat_Referencia = @dat_Referencia
       		AND cod_Origem = @cod_Origem 
       		AND cod_Regional = @cod_Regional  
       		AND cod_Cluster BETWEEN 1 AND 13 
			AND (ind_Gpon = @ind_Gpon OR @ind_Gpon IS NULL) 
       		AND cod_Status = 4 
   		GROUP BY nom_Cluster
		UNION ALL 
		SELECT 'SPC' as [Cluster]   
			,0 as [Total] 
			,0 as [Outliers]
			,0 as [Entrante_Real]
			,COUNT (cod_ID) as [Realizado Real]
		FROM TB_PL_Reparo_Encerrado WITH (NOLOCK)
		WHERE dat_Referencia = @dat_Referencia
			AND cod_Origem = @cod_Origem
			AND cod_Regional = @cod_Regional 
			AND (ind_Gpon = @ind_Gpon OR @ind_Gpon IS NULL) 
			AND cod_Status = @cod_Status -- REALIZADO REAL 	   
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
	--ORDER BY MN.minInd ASC
	--	,MT.Cluster ASC
)ODIO	
-- excluido aqui fica o order by 
select * from #FUNCIONAPELOAMORDEDEUS
IF OBJECT_ID('TEMPDB..#FUNCIONAPELOAMORDEDEUS') IS NOT NULL BEGIN DROP TABLE #FUNCIONAPELOAMORDEDEUS END
SET @I = @I - 1
END 

