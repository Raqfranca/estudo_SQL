IF OBJECT_ID('TEMPDB..#clusterTotal')   IS NOT NULL BEGIN DROP TABLE #clusterTotal END	

DECLARE @dat_Referencia DATE = '2023-06-16', @cod_Status INT = 4, @cod_Origem INT = 1, @dat_Encerramento DATETIME SET @dat_Encerramento = CONVERT(DATETIME, CONVERT(VARCHAR(10), @dat_Referencia, 120) + ' 23:59:59.999')

SELECT * 
INTO #clusterTotal 
FROM(
	SELECT  
		cod_Cluster
		,CASE cod_Par
			WHEN 2 THEN SUM(CASE WHEN ind_OutliersHoras = 0 THEN 1 ELSE 0 END)
			WHEN 1 THEN SUM(CASE WHEN ind_OutliersHoras = 1 THEN 1  ELSE 0 END)
		END AS Valor 
		,ind_Gpon
		,cod_Par
		,cod_Regional
	FROM(   
		--DECLARE @dat_Referencia DATE = '2023-06-15', @cod_Origem INT = 1
		SELECT cod_ID
			,cod_Cluster
			,ind_OutliersHoras	
			,ind_Gpon
			,CASE 
				WHEN ind_OutliersHoras = 1 THEN 1 
				WHEN ind_OutliersHoras = 0 THEN 2
			END AS cod_par
			,cod_Regional
		FROM TB_PL_Reparo_Restante  WITH (NOLOCK) 
		WHERE dat_Referencia = @dat_Referencia 
			AND cod_Origem = @cod_Origem
			AND cod_Cluster is not null 
	)A
	GROUP BY A.cod_Cluster
		,A.cod_par
		,A.ind_Gpon
		,a.cod_Regional
	UNION ALL 
	---- ENTRANTE REAL
	----DECLARE @dat_Referencia DATE = '2023-06-15', @cod_Origem INT = 1, @dat_Encerramento DATETIME SET @dat_Encerramento = CONVERT(DATETIME, CONVERT(VARCHAR(10), @dat_Referencia, 120) + ' 23:59:59.999')
	SELECT cod_Cluster
		,COUNT(cod_ID) AS Valor
		,ind_Gpon
		,cod_Par
		,cod_Regional
	FROM(
		SELECT cod_ID 
			,ind_Gpon
			,cod_Cluster 
			,3 AS cod_Par
			,cod_Regional
		FROM TB_PL_Reparo_Entrante WITH (NOLOCK)
		WHERE dat_Referencia = @dat_Referencia
			AND cod_Origem = @cod_Origem
			AND (dat_Encerramento >= @dat_Encerramento OR cod_Status <> 3)
			AND cod_Cluster is not null 
	)b 
	GROUP BY cod_Cluster
		,ind_Gpon
		,cod_Par
		,cod_Regional
	UNION ALL 
	-- REALIZADO REAL 
	--DECLARE @dat_Referencia DATE = '2023-06-15', @cod_Status INT = 4, @cod_Origem INT = 1, @dat_Encerramento DATETIME SET @dat_Encerramento = CONVERT(DATETIME, CONVERT(VARCHAR(10), @dat_Referencia, 120) + ' 23:59:59.999')
	SELECT cod_Cluster
		,COUNT(cod_ID) AS Valor
		,ind_Gpon
		,cod_Par
		,cod_Regional
	FROM (
	--DECLARE @dat_Referencia DATE = '2023-06-15', @cod_Status INT = 4, @cod_Origem INT = 1, @dat_Encerramento DATETIME SET @dat_Encerramento = CONVERT(DATETIME, CONVERT(VARCHAR(10), @dat_Referencia, 120) + ' 23:59:59.999')
		SELECT cod_ID 
			,ind_Gpon
			,cod_Cluster 
			,4 AS cod_Par
			,cod_Regional
		FROM TB_PL_Reparo_Encerrado WITH (NOLOCK)
		WHERE dat_Referencia = @dat_Referencia
			AND cod_Origem = @cod_Origem 
			AND cod_Status = @cod_Status
			AND cod_Cluster is not null 
	)c
	GROUP BY cod_Cluster
		,ind_Gpon
		,cod_Par
		,cod_Regional
)t1

DECLARE @ind_Gpon INT = NULL ,@I INT = 2
 

WHILE @I >= 0

BEGIN

SELECT CASE @I
	WHEN 1 THEN 'Premium'
	WHEN 0 THEN 'Massivo'
	WHEN 2 THEN 'UGR'
ELSE NULL END AS 'Tipo_Tecnologia'

SET @ind_Gpon = CASE WHEN @I = 2 THEN NULL ELSE @I END

SELECT CLUSTER
	,CASE WHEN Total IS NULL THEN 0 ELSE Total END AS Total
	,CASE WHEN Outliers IS NULL THEN 0 ELSE Outliers END AS Outliers
	,CASE WHEN Realizado_Real IS NULL THEN 0 ELSE Realizado_Real END AS Realizado_Real
	,CASE WHEN Entrante_Real IS NULL THEN 0 ELSE Entrante_Real END AS Entrante_Real
FROM(
	SELECT DISTINCT cod_Gerencia
		,nom_Cluster AS CLUSTER 
		,ind_Ordem
		,cod_Cluster
	FROM TB_FGT_Contrato WITH (NOLOCK)
	GROUP BY cod_Gerencia
		,nom_Cluster
		,ind_Ordem
		,cod_Cluster
	)MN2
LEFT JOIN (
	SELECT [CODCluster] = (CASE WHEN [cod_Regional] = 1 AND [CODCluster] IS NULL THEN 29 
								WHEN [cod_Regional] = 6 AND [CODCluster] IS NULL THEN 30 
								WHEN [cod_Regional] IS NULL AND [CODCluster] IS NULL THEN 24 
								ELSE CODCluster 
							END)
		,Total
		,Entrante_Real
		,Realizado_Real
		,Outliers
	FROM(
		SELECT cod_Cluster AS CODCluster
			,SUM(CASE WHEN cod_par IN(1,2) THEN Valor ELSE 0 END) AS [Total]
			,SUM(CASE cod_par WHEN 1 THEN Valor ELSE 0 END) as [Outliers] 
			,SUM(CASE cod_par WHEN 3 THEN Valor ELSE 0 END) as [Entrante_Real] 
			,SUM(CASE cod_par WHEN 4 THEN Valor ELSE 0 END) as [Realizado_Real]
			,cod_Regional
		FROM #clusterTotal 
		WHERE (ind_Gpon = @ind_Gpon OR @ind_Gpon IS NULL) 
		GROUP BY cod_Regional, cod_Cluster
		WITH ROLLUP
	)G
)MN on MN.CODCluster = MN2.cod_Cluster
WHERE ind_Ordem BETWEEN 0 AND 35
ORDER BY ind_Ordem ASC

SET @I = @I - 1
END 

IF OBJECT_ID('TEMPDB..#clusterTotal')   IS NOT NULL BEGIN DROP TABLE #clusterTotal END	





		

