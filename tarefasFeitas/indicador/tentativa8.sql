IF OBJECT_ID('TEMPDB..#clusterTotal')   IS NOT NULL BEGIN DROP TABLE #clusterTotal END	

DECLARE @dat_Referencia DATE = '2023-07-02', @cod_Status INT = 4, @cod_Origem INT = 1, @dat_Encerramento DATETIME SET @dat_Encerramento = CONVERT(DATETIME, CONVERT(VARCHAR(10), @dat_Referencia, 120) + ' 23:59:59.999')

SELECT cod_Cluster 
	,COUNT(cod_ID) AS Valor
	,cod_par
	,ind_Gpon
INTO #clusterTotal 
FROM(
 --DECLARE @dat_Referencia DATE = '2023-06-16', @cod_Origem INT = 1
		SELECT cod_ID
			,cod_Cluster
			,ind_Gpon
			,CASE 
				WHEN ind_OutliersHoras = 1 THEN 1 
				WHEN ind_OutliersHoras = 0 THEN 2
			END AS cod_par
		FROM TB_PL_Reparo_Restante  WITH (NOLOCK) 
		WHERE dat_Referencia = @dat_Referencia 
			AND cod_Origem = @cod_Origem
			AND cod_Cluster is not null 
		UNION ALL 
		-- ENTRANTE REAL
		--DECLARE @dat_Referencia DATE = '2023-06-16', @cod_Origem INT = 1, @dat_Encerramento DATETIME SET @dat_Encerramento = CONVERT(DATETIME, CONVERT(VARCHAR(10), @dat_Referencia, 120) + ' 23:59:59.999')
		SELECT cod_ID 
			,cod_Cluster
			,ind_Gpon 
			,3 AS cod_Par
		FROM TB_PL_Reparo_Entrante WITH (NOLOCK)
		WHERE dat_Referencia = @dat_Referencia
			AND cod_Origem = @cod_Origem
			AND (dat_Encerramento >= @dat_Encerramento OR cod_Status <> 3)
			AND cod_Cluster is not null 
		UNION ALL 
		-- REALIZADO REAL 
		--DECLARE @dat_Referencia DATE = '2023-06-16', @cod_Status INT = 4, @cod_Origem INT = 1, @dat_Encerramento DATETIME SET @dat_Encerramento = CONVERT(DATETIME, CONVERT(VARCHAR(10), @dat_Referencia, 120) + ' 23:59:59.999')
		SELECT cod_ID 
			,cod_Cluster
			,ind_Gpon 
			,4 AS cod_Par
		FROM TB_PL_Reparo_Encerrado WITH (NOLOCK)
		WHERE dat_Referencia = @dat_Referencia
			AND cod_Origem = @cod_Origem 
			AND cod_Status = @cod_Status
			AND cod_Cluster is not null 
)t1
GROUP BY cod_Cluster
	,cod_par
	,ind_Gpon

-- TERMINA TEMP 

DECLARE @ind_Gpon INT = NULL ,@I INT = 2
 
WHILE @I >= 0

BEGIN

SELECT CASE @I
	WHEN 1 THEN 'Premium'
	WHEN 0 THEN 'Massivo'
	WHEN 2 THEN 'UGR'
ELSE NULL END AS 'Tipo_Tecnologia'

SET @ind_Gpon = CASE WHEN @I = 2 THEN NULL ELSE @I END

SELECT nom_Cluster
	,Total
	,Outliers
	,Entrante_Real
	,Realizado_Real
FROM(
	SELECT nom_Cluster = (CASE WHEN cod_Regional = 1 AND a.ind_Ordem IS NULL THEN 'SPC'
							WHEN cod_Regional = 6 AND a.ind_Ordem IS NULL THEN 'SPI' 
							WHEN cod_Regional IS NULL AND a.ind_Ordem IS NULL THEN 'DSP' 
						ELSE nom_Cluster 
						END)
		,ind_Ordem = (CASE WHEN cod_Regional = 1 AND ind_Ordem IS NULL THEN 9
							WHEN cod_Regional = 6 AND ind_Ordem IS NULL THEN 30 
							WHEN cod_Regional IS NULL AND ind_Ordem IS NULL THEN 31 
						ELSE ind_Ordem
						END)					
		,SUM(CASE WHEN cod_par IN(1,2) THEN Valor ELSE 0 END) AS [Total]
		,SUM(CASE cod_par WHEN 1 THEN Valor ELSE 0 END) as [Outliers] 
		,SUM(CASE cod_par WHEN 3 THEN Valor ELSE 0 END) as [Entrante_Real] 
		,SUM(CASE cod_par WHEN 4 THEN Valor ELSE 0 END) as [Realizado_Real] 
		,cod_Regional
	FROM (
		SELECT nom_Cluster
				,cod_Cluster 
				,ind_Ordem
				,cod_Regional
		FROM TB_FGT_Contrato WITH (NOLOCK)
		WHERE cod_Regional in(1,6)
		AND cod_Cluster NOT IN(29,30)
		GROUP BY nom_Cluster
				,cod_Cluster 
				,ind_Ordem
				,cod_Regional
	)A
	LEFT JOIN (
		SELECT * 
		FROM #clusterTotal
		WHERE (ind_Gpon = @ind_Gpon OR @ind_Gpon IS NULL) 
	)B on B.cod_Cluster = A.cod_Cluster
	GROUP BY cod_Regional, A.ind_Ordem, A.cod_Cluster, nom_Cluster
	WITH ROLLUP
)C
WHERE nom_Cluster IS NOT NULL 
ORDER BY ind_Ordem

SET @I = @I - 1

END 

IF OBJECT_ID('TEMPDB..#clusterTotal')   IS NOT NULL BEGIN DROP TABLE #clusterTotal END	
