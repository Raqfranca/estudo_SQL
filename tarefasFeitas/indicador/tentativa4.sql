------------------- Criando uma Mega Temporaria Consolidado com só 4 colunas ------------------------------------------ 
 
IF OBJECT_ID('TEMPDB..#clusterTotal')   IS NOT NULL BEGIN DROP TABLE #clusterTotal END	


DECLARE @cod_Origem INT = 1 ,@dat_Referencia DATE = '2023-06-01' ,@cod_Regional INT = 1, @cod_Status INT = 4 ,@dat_Encerramento DATETIME ,@I INT = 2, @ind_Gpon INT = NULL SET @dat_Encerramento = CONVERT(DATETIME, CONVERT(VARCHAR(10), @dat_Referencia, 120) + ' 23:59:59.999')

WHILE @I >= 0

BEGIN

SELECT CASE @I
	WHEN 1 THEN 'Premium'
	WHEN 0 THEN 'Massivo'
	WHEN 2 THEN 'UGR'
ELSE NULL END AS 'Tipo_Tecnologia'



SET @ind_Gpon = CASE WHEN @I = 2 THEN NULL ELSE @I END 

SELECT * INTO #clusterTotal 
FROM(	
	SELECT MT.Cluster
		,MT.Valor
		,MT.cod_Tabela 
		,MN.minInd AS IND
	FROM ( 	
		--TOTAL ERRO
		SELECT nom_Cluster as [Cluster]
		,COUNT(cod_ID) as [Valor] 
   		, 1 AS cod_Tabela
		FROM TB_PL_Reparo_Restante  WITH (NOLOCK) 
		WHERE dat_Referencia = @dat_Referencia 
   				AND cod_Cluster BETWEEN 1 AND 13
   				AND cod_Origem = @cod_Origem 
				AND (ind_Gpon = @ind_Gpon OR @ind_Gpon IS NULL) 
		GROUP BY nom_Cluster
		UNION ALL 
	-- OUTLIERS ERRO 
		SELECT 
   		nom_Cluster as [Cluster]
		,SUM(CASE WHEN ind_OutliersHoras <> 0 THEN 1 ELSE 0 END) as [Valor]  
   		, 2 AS cod_Tabela
		FROM TB_PL_Reparo_Restante  WITH (NOLOCK) 
		WHERE dat_Referencia = @dat_Referencia 
   				AND cod_Cluster BETWEEN 1 AND 13
   				AND cod_Origem = @cod_Origem 
				AND (ind_Gpon = @ind_Gpon OR @ind_Gpon IS NULL) 
		GROUP BY nom_Cluster
		UNION ALL 
		 -- ENTRANTE REAL
		SELECT nom_Cluster as [Cluster] 
		,SUM(CASE WHEN (dat_Encerramento >= @dat_Encerramento OR cod_Status <> 3)THEN 1 ELSE 0 END) AS [Valor] 
		, 3 AS cod_Tabela
		FROM TB_PL_Reparo_Entrante WITH (NOLOCK)
		WHERE dat_Referencia = @dat_Referencia
   			AND cod_Origem = @cod_Origem
    		AND cod_Regional = @cod_Regional 
    		AND cod_Cluster BETWEEN 1 AND 13 
			AND (ind_Gpon = @ind_Gpon OR @ind_Gpon IS NULL) 
		GROUP BY nom_Cluster
		UNION ALL 
	-- REALIZADO REAL 
		SELECT nom_Cluster as [Cluster]  
		,SUM(CASE WHEN cod_Status = @cod_Status THEN 1 ELSE 0 END)  AS [Valor]
		, 4 AS cod_Tabela
		FROM TB_PL_Reparo_Encerrado WITH (NOLOCK)
		WHERE dat_Referencia = @dat_Referencia
			AND cod_Origem = @cod_Origem 
    		AND cod_Regional = @cod_Regional  
    		AND cod_Cluster BETWEEN 1 AND 13 
			AND (ind_Gpon = @ind_Gpon OR @ind_Gpon IS NULL) 
		GROUP BY nom_Cluster
	)MT
	LEFT JOIN (
		SELECT MIN(ind_Ordem) AS minInd -- erro
			,nom_Cluster AS CLUSTER
		FROM TB_FGT_Contrato WITH (NOLOCK)
		GROUP BY ind_Ordem 
			,nom_Cluster 
	)MN on MN.CLUSTER = MT.Cluster
	GROUP BY MT.Cluster 
			,MT.Valor
			,MT.cod_Tabela  
			,MN.minInd
)t1

--- TRANSFORMANDO A TABELA --- 

SELECT Cluster
	,Total
	,Outliers
	,Entrante_Real
	,Realizado_Real
FROM (
	SELECT [Cluster] = (CASE WHEN [Cluster] IS NULL THEN 'SPC' ELSE [Cluster] END)
		,IND = MAX((CASE WHEN [Cluster] = 'SPC' THEN 1000 ELSE IND END))
		,SUM(Total) as [Total] 
		,SUM(Outliers) as [Outliers] 
		,SUM(Entrante_Real) as [Entrante_Real]
		,SUM(Realizado_Real)  as [Realizado_Real]  
	FROM(
		SELECT Cluster
			,SUM(Total) as [Total] 
			,SUM(Outliers) as [Outliers] 
			,SUM(Entrante_Real) as [Entrante_Real]
			,SUM(Realizado_Real)  as [Realizado_Real]
			,IND
		FROM(
			SELECT Cluster
				,ISNULL (Total, 0)  as [Total]
				,ISNULL (Outliers, 0)  as [Outliers]
				,ISNULL (Entrante_Real, 0)  as [Entrante_Real]
				,ISNULL (Realizado_Real, 0)  as [Realizado_Real]
				,IND	 
			FROM(	
				SELECT Cluster
					,cod_Tabela
					,CASE cod_Tabela WHEN 1 THEN valor END as [Total] 
					,CASE cod_Tabela WHEN 2 THEN valor END as [Outliers] 
					,CASE cod_Tabela WHEN 3 THEN Valor END as [Entrante_Real] 
					,CASE cod_Tabela WHEN 4 THEN Valor END as [Realizado_Real]
					,IND
				FROM #clusterTotal  
			)P 
		)M
		GROUP BY M.Cluster
				,M.IND
	)G
	GROUP BY ROLLUP(Cluster, IND)
	HAVING (IND IS NOT NULL AND Cluster IS NOT NULL) OR (IND IS NULL AND Cluster IS NULL) 
)GG
ORDER BY IND ASC
	,Cluster asc
	
IF OBJECT_ID('TEMPDB..#clusterTotal')   IS NOT NULL BEGIN DROP TABLE #clusterTotal END	

SET @I = @I - 1
END 


