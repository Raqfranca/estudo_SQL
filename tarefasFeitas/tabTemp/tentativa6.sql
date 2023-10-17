DECLARE @cod_Origem INT = 1
	,@dat_Referencia DATE = '2023-05-22'
	,@cod_Regional INT = 1, @cod_Status INT = 4
	,@dat_Encerramento DATETIME 
	,@I INT = 2, @ind_Gpon INT = NULL
	SET @dat_Encerramento = CONVERT(DATETIME, CONVERT(VARCHAR(10), @dat_Referencia, 120) + ' 23:59:59.999')
WHILE @I >= 0

BEGIN

IF OBJECT_ID('TEMPDB..#FUNCIONAPELOAMORDEDEUS')   IS NOT NULL BEGIN DROP TABLE #FUNCIONAPELOAMORDEDEUS END	

SELECT CASE @I
	WHEN 1 THEN 'Premium'
	WHEN 0 THEN 'Massivo'
	WHEN 2 THEN 'UGR'
ELSE NULL END AS 'Tipo_Tecnologia'

SET @ind_Gpon = CASE WHEN @I = 2 THEN NULL ELSE @I END 

SELECT * INTO #FUNCIONAPELOAMORDEDEUS 
FROM(
	--DECLARE @cod_Origem INT = 1 ,@dat_Referencia DATE = '2023-05-22' ,@cod_Regional INT = 1, @cod_Status INT = 4 ,@dat_Encerramento DATETIME ,@I INT = 2, @ind_Gpon INT = NULL SET @dat_Encerramento = CONVERT(DATETIME, CONVERT(VARCHAR(10), @dat_Referencia, 120) + ' 23:59:59.999')
	SELECT MT.Cluster
   		,SUM(Total) as  Total
   		,SUM(Outliers) as  Outliers
   		,SUM(Entrante_Real) as Entrante_Real  
   		,SUM(Realizado_Real) as Realizado_Real  
		,MN.minInd AS IND 
	FROM (
		--DECLARE @cod_Origem INT = 1 ,@dat_Referencia DATE = '2023-05-22' ,@cod_Regional INT = 1, @cod_Status INT = 4 ,@dat_Encerramento DATETIME ,@I INT = 2, @ind_Gpon INT = NULL SET @dat_Encerramento = CONVERT(DATETIME, CONVERT(VARCHAR(10), @dat_Referencia, 120) + ' 23:59:59.999')
		SELECT  -- TOTAL + OUTLIERS
   			nom_Cluster as [Cluster]
			,COUNT(cod_ID) as [Total] 
   			,SUM(CASE WHEN ind_OutliersHoras <> 0 THEN 1 ELSE 0 END) as [Outliers]  
			,0 AS [Entrante_Real] 
			,0 as [Realizado_Real]
		FROM TB_PL_Reparo_Restante  WITH (NOLOCK) 
		WHERE dat_Referencia = @dat_Referencia 
   			AND cod_Cluster BETWEEN 1 AND 13
   			AND cod_Origem = @cod_Origem
			AND (ind_Gpon = @ind_Gpon OR @ind_Gpon IS NULL)
		GROUP BY nom_Cluster
		UNION ALL 
		SELECT 'SPC' as [Cluster]  
			,COUNT(cod_ID) as [Total] -- essa minha lógica está errada. 
			,SUM(CASE WHEN ind_OutliersHoras <> 0 THEN 1 ELSE 0 END) as [Outliers] 
			,0 AS [Entrante_Real]
			,0 as [Realizado_Real]
		FROM TB_PL_Reparo_Restante WITH (NOLOCK) 
		WHERE dat_Referencia = @dat_Referencia
			AND cod_Origem = @cod_Origem
			AND cod_Cluster BETWEEN 1 AND 13 
			AND (ind_Gpon = @ind_Gpon OR @ind_Gpon IS NULL) -- TOTAL -- TOTAL + OUTLIERS
		UNION ALL
		SELECT nom_Cluster as [Cluster] -- ENTRANTE REAL 
			,0 as [Total] 
    		,0 as [Outliers] 
			,SUM(CASE WHEN (dat_Encerramento >= @dat_Encerramento OR cod_Status <> 3)THEN 1 ELSE 0 END) AS [Entrante_Real] 
			,0 as [Realizado_Real]
		FROM TB_PL_Reparo_Entrante WITH (NOLOCK)
		WHERE dat_Referencia = @dat_Referencia
   			AND cod_Origem = @cod_Origem
    		AND cod_Regional = @cod_Regional 
    		AND cod_Cluster BETWEEN 1 AND 13 
			AND (ind_Gpon = @ind_Gpon OR @ind_Gpon IS NULL) 
		GROUP BY nom_Cluster
		UNION ALL 
		SELECT 'SPC' as [Cluster]   
			,0 as [Total]
			,0 as [Outliers] 
			,SUM(CASE WHEN (dat_Encerramento >= @dat_Encerramento OR cod_Status <> 3)THEN 1 ELSE 0 END) as [Entrante_Real] 
			,0 as [Realizado_Real]
		FROM TB_PL_Reparo_Entrante WITH (NOLOCK)
		WHERE dat_Referencia = @dat_Referencia 
			AND cod_Origem = @cod_Origem
			AND cod_Regional = @cod_Regional
			AND (ind_Gpon = @ind_Gpon OR @ind_Gpon IS NULL)
		UNION ALL
		SELECT nom_Cluster as [Cluster] -- REALIZADO REAL 
			,0 as [Total] 
    		,0 as [Outliers] 
  			,0 as [Entrante_Real] 
  			,sum(CASE WHEN cod_Status = @cod_Status THEN 1 ELSE 0 END)  AS [Realizado Real]
		FROM TB_PL_Reparo_Encerrado WITH (NOLOCK)
		WHERE dat_Referencia = @dat_Referencia
			AND cod_Origem = @cod_Origem 
    		AND cod_Regional = @cod_Regional  
    		AND cod_Cluster BETWEEN 1 AND 13 
			AND (ind_Gpon = @ind_Gpon OR @ind_Gpon IS NULL) 
		GROUP BY nom_Cluster
		UNION ALL 
		SELECT 'SPC' as [Cluster]   
			,0 as [Total] -- preciso tranformar esse valor em um indicador 
			,0 as [Outliers]
			,0 as [Entrante_Real]
			,SUM(CASE WHEN cod_Status = @cod_Status THEN 1 ELSE 0 END)  as [Realizado Real]
		FROM TB_PL_Reparo_Encerrado WITH (NOLOCK)
		WHERE dat_Referencia = @dat_Referencia
			AND cod_Origem = @cod_Origem
			AND cod_Regional = @cod_Regional 
			AND (ind_Gpon = @ind_Gpon OR @ind_Gpon IS NULL)  -- REALIZADO REAL 	 	
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
)ODIO
-- PQ O ORDER BY ESTÁ FORA DO SELECT PRINCIPAL? PQ PELA ORDEM DE PRECESSAMENTO O SELECT VEM PRIMEIRO E DEPOIS É O ORDER 
SELECT Cluster
	,Total
	,Outliers
	,Entrante_Real
	,Realizado_Real
FROM #FUNCIONAPELOAMORDEDEUS
ORDER BY IND ASC
	,Cluster asc

IF OBJECT_ID('TEMPDB..#FUNCIONAPELOAMORDEDEUS') IS NOT NULL BEGIN DROP TABLE #FUNCIONAPELOAMORDEDEUS END
SET @I = @I - 1
END 

--- existe uma função em group by que que eu esqueci o nome, é uma função. 