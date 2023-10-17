IF OBJECT_ID('TEMPDB..#clusterTotal')   IS NOT NULL BEGIN DROP TABLE #clusterTotal END	

DECLARE @cod_Origem INT = 1 ,@dat_Referencia DATE = '2023-06-20' ,@cod_Regional INT = 1, @cod_Status INT = 4 ,@dat_Encerramento DATETIME ,@I INT = 2, @ind_Gpon INT = NULL SET @dat_Encerramento = CONVERT(DATETIME, CONVERT(VARCHAR(10), @dat_Referencia, 120) + ' 23:59:59.999')

WHILE @I >= 0

BEGIN

SELECT CASE @I
	WHEN 1 THEN 'Premium'
	WHEN 0 THEN 'Massivo'
	WHEN 2 THEN 'UGR'
ELSE NULL END AS 'Tipo_Tecnologia'

SET @ind_Gpon = CASE WHEN @I = 2 THEN NULL ELSE @I END 

SELECT * 
INTO #clusterTotal 
FROM(
	--DECLARE @cod_Origem INT = 1 ,@dat_Referencia DATE = '2023-06-15' ,@cod_Regional INT = 1, @cod_Status INT = 4 ,@dat_Encerramento DATETIME ,@I INT = 2, @ind_Gpon INT = NULL SET @dat_Encerramento = CONVERT(DATETIME, CONVERT(VARCHAR(10), @dat_Referencia, 120) + ' 23:59:59.999')
	SELECT MN.Cluster
		,MN.cod_Cluster
		,MT.Valor
		,MT.cod_par
		,MN.ind_Ordem 
		,MN.cod_Regional
	FROM (	
		--DECLARE @cod_Origem INT = 1 ,@dat_Referencia DATE = '2023-06-14' ,@cod_Regional INT = 1, @cod_Status INT = 4 ,@dat_Encerramento DATETIME ,@I INT = 2, @ind_Gpon INT = NULL SET @dat_Encerramento = CONVERT(DATETIME, CONVERT(VARCHAR(10), @dat_Referencia, 120) + ' 23:59:59.999')
		SELECT  
			cod_Cluster
			,CASE cod_Par
				WHEN 2 THEN SUM(CASE WHEN ind_OutliersHoras = 0 THEN 1 ELSE 0 END)
				WHEN 1 THEN SUM(CASE WHEN ind_OutliersHoras = 1 THEN ind_OutliersHoras  ELSE 0 END)
			END AS Valor 
			,cod_Par
		FROM(
			-- DECLARE @cod_Origem INT = 1 ,@dat_Referencia DATE = '2023-06-15' ,@cod_Regional INT = 1, @cod_Status INT = 4 ,@dat_Encerramento DATETIME ,@I INT = 2, @ind_Gpon INT = NULL SET @dat_Encerramento = CONVERT(DATETIME, CONVERT(VARCHAR(10), @dat_Referencia, 120) + ' 23:59:59.999')
			SELECT cod_ID
				,cod_Cluster
				,ind_OutliersHoras	
				,CASE 
					WHEN ind_OutliersHoras = 1 THEN 1 
					WHEN ind_OutliersHoras = 0 THEN 2
			END AS cod_par
			FROM TB_PL_Reparo_Restante  WITH (NOLOCK) 
			WHERE dat_Referencia = @dat_Referencia 
				AND cod_Cluster BETWEEN 1 AND 13
   				AND cod_Origem = @cod_Origem 
				AND (ind_Gpon = @ind_Gpon OR @ind_Gpon IS NULL) 
		)a
		GROUP BY 
		ind_OutliersHoras
		,cod_Cluster
		,cod_par
		UNION ALL 
		-- ENTRANTE REAL
		--DECLARE @cod_Origem INT = 1 ,@dat_Referencia DATE = '2023-06-14' ,@cod_Regional INT = 1, @cod_Status INT = 4 ,@dat_Encerramento DATETIME ,@I INT = 2, @ind_Gpon INT = NULL SET @dat_Encerramento = CONVERT(DATETIME, CONVERT(VARCHAR(10), @dat_Referencia, 120) + ' 23:59:59.999')
		SELECT cod_Cluster
		,COUNT(cod_ID) AS Valor
		,cod_Par
		FROM(
			SELECT cod_ID 
				,cod_Cluster as [cod_Cluster] 
				,CASE 
					WHEN (dat_Encerramento >= @dat_Encerramento OR cod_Status <> 3)THEN 3 
				END AS cod_par
				,3 AS cod_Tabela
			FROM TB_PL_Reparo_Entrante WITH (NOLOCK)
			WHERE dat_Referencia = @dat_Referencia
   				AND cod_Origem = @cod_Origem
    			AND cod_Regional = @cod_Regional 
    			AND cod_Cluster BETWEEN 1 AND 13 
				AND (ind_Gpon = @ind_Gpon OR @ind_Gpon IS NULL) 
			GROUP BY cod_Cluster
				,cod_ID
				,cod_Status
				,dat_Encerramento
		)b
		WHERE cod_Par IS NOT NULL 
		GROUP BY cod_Cluster
			,cod_Par
		UNION ALL
		-- REALIZADO REAL 
		--DECLARE @cod_Origem INT = 1 ,@dat_Referencia DATE = '2023-06-14' ,@cod_Regional INT = 1, @cod_Status INT = 4 ,@dat_Encerramento DATETIME ,@I INT = 2, @ind_Gpon INT = NULL SET @dat_Encerramento = CONVERT(DATETIME, CONVERT(VARCHAR(10), @dat_Referencia, 120) + ' 23:59:59.999')
		SELECT 
			cod_Cluster
			,COUNT(cod_ID) AS Valor
			,cod_Par
		FROM (
			SELECT cod_ID 
				,cod_Cluster 
				,CASE WHEN cod_Status = @cod_Status THEN 4 END  AS cod_par
				, 4 AS cod_Tabela
			FROM TB_PL_Reparo_Encerrado WITH (NOLOCK)
			WHERE dat_Referencia = @dat_Referencia
				AND cod_Origem = @cod_Origem 
    			AND cod_Regional = @cod_Regional  
    			AND cod_Cluster BETWEEN 1 AND 13 
				AND (ind_Gpon = @ind_Gpon OR @ind_Gpon IS NULL) 
			GROUP BY cod_Cluster
			,dat_Referencia
			,cod_Regional
			,cod_Status
			,dat_Encerramento
			,cod_ID
		)c
		WHERE cod_par IS NOT NULL 
		GROUP BY cod_Cluster
		,cod_Par
	) MT 
	LEFT JOIN (
		SELECT ind_Ordem AS ind_Ordem
			,nom_Cluster AS Cluster
			,cod_Cluster AS cod_Cluster
			,cod_Regional AS cod_Regional
		FROM TB_FGT_Contrato WITH (NOLOCK)
		)MN on MN.cod_Cluster = MT.cod_Cluster
		GROUP BY MN.Cluster
			,MN.cod_Cluster
			,MT.Valor
			,MT.cod_par
			,MN.ind_Ordem
			,MN.cod_Regional

)t1

DECLARE  @IND INT = NULL  --IND_ORDEM 
		
BEGIN 
	SET @IND = 1000 
END

SELECT Cluster
	,TOTAL
	,OUTLIERS
	,ENTRANTE_REAL
	,REALIZADO_REAL
FROM (
SELECT [Cluster] = (CASE WHEN [cod_Regional] = 1 AND [cod_Cluster] IS NULL THEN 'SPC' ELSE [Cluster] END)
	,IND = (CASE WHEN [cod_Regional] = 1 AND [cod_Cluster] IS NULL THEN @IND ELSE ind_Ordem END)
	,SUM(Total) AS [TOTAL]
	,SUM(Outliers) AS [OUTLIERS]
	,SUM(Entrante_Real) AS [ENTRANTE_REAL]
	,SUM(Realizado_Real) AS [REALIZADO_REAL]	
	,cod_Regional
	,cod_Cluster
FROM(
	SELECT Cluster
		,SUM(CASE WHEN cod_par IN(1,2) THEN Valor ELSE 0 END) AS [Total]
		,SUM(CASE cod_par WHEN 1 THEN Valor ELSE 0 END) as [Outliers] 
		,SUM(CASE cod_par WHEN 3 THEN Valor ELSE 0 END) as [Entrante_Real] 
		,SUM(CASE cod_par WHEN 4 THEN Valor ELSE 0 END) as [Realizado_Real]
		,ind_Ordem
		,cod_Regional
		,cod_Cluster
	FROM #clusterTotal 
	GROUP BY Cluster
		,ind_Ordem
		,cod_Regional
		,cod_Cluster
	)D
GROUP BY ROLLUP(cod_Regional, cod_Cluster, ind_Ordem, Cluster)
HAVING (Cluster IS NOT NULL ) OR (cod_Cluster IS NULL AND cod_Regional IS NOT NULL)
)B
ORDER BY IND asc 
	,Cluster asc 

IF OBJECT_ID('TEMPDB..#clusterTotal')   IS NOT NULL BEGIN DROP TABLE #clusterTotal END	

SET @I = @I - 1
END 
