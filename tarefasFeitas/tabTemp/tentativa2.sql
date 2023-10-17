-- ESTOU USANDO A TABELA TEMPORARIA LOCAL 

-- CRIANDO A TABELA DE TOTAIS E OUTLIERS 
DROP TABLE #TT_TOTAL
CREATE TABLE #TT_TOTAL
(
	codID VARCHAR (15),
	Cluster VARCHAR (30),
	indGPON SMALLINT,
	indOrdem SMALLINT, 
	codOutliers SMALLINT, 
)
INSERT INTO #TT_TOTAL(codID,Cluster, indGPON, indOrdem,codOutliers) -- TOTAL 
SELECT RR.cod_ID AS codID
	,RR.nom_Cluster AS Cluster
	,RR.ind_Gpon AS indGPON 
	,MIN(C.ind_Ordem) AS indOrdem 
	,RR.ind_OutliersHoras AS codOutliers
FROM TB_PL_Reparo_Restante AS RR WITH (NOLOCK)
INNER JOIN TB_FGT_Contrato as C WITH (NOLOCK)
ON RR.cod_Cluster = C.cod_Cluster
WHERE RR.dat_Referencia = '2023-04-12' 
         AND RR.cod_Cluster BETWEEN 1 AND 13
         AND RR.cod_Origem = 1
GROUP BY RR.cod_ID 
	,RR.ind_Gpon 
	,C.ind_Ordem 
	,RR.nom_Cluster 
	,RR.ind_OutliersHoras
--select * from #TT_TOTAL
--IF OBJECT_ID('TEMPDB..#TT_TOTAL')       IS NOT NULL BEGIN DROP TABLE #TT_TOTAL END
-- DROP TABLE ##TT_TOTAL
-- CRIANDO A TABELA DE ENTRANTE REAL 

CREATE TABLE #TT_ENTRANTE_REAL
DROP TABLE #TT_ENTRANTE_REAL 
(
	codID VARCHAR (15),
	Cluster VARCHAR (30),
	indGPON SMALLINT,
	indOrdem SMALLINT, 
)
INSERT INTO #TT_ENTRANTE_REAL(codID,Cluster, indGPON, indOrdem)
DROP TABLE #TT_ENTRANTE_REAL 

SELECT EN.cod_ID AS codID
	,EN.nom_Cluster AS Cluster
	,EN.ind_Gpon AS indGPON
	,MIN(C.ind_Ordem) as indOrdem 
FROM TB_PL_Reparo_Entrante AS EN WITH (NOLOCK)
INNER JOIN TB_FGT_Contrato AS C WITH (NOLOCK)
ON EN.cod_Cluster = C.cod_Cluster
WHERE EN.dat_Referencia = '2023-04-12' 
    AND EN.cod_Cluster BETWEEN 1 AND 13
    AND EN.cod_Origem = 1
	AND  (dat_Encerramento >= '2023-04-12 23:59:59.999' OR cod_Status <> 3)
GROUP BY EN.cod_ID
	,EN.nom_Cluster
	,EN.ind_Gpon
	,C.ind_Ordem
-- CRIANDO A TABELA DE Realizado real 
CREATE TABLE #TT_REALIZADO_REAL 
DROP TABLE #TT_REALIZADO_REAL
(
	codID VARCHAR (15),
	Cluster VARCHAR (30),
	indGPON SMALLINT,
	indOrdem SMALLINT,  
)
INSERT INTO #TT_REALIZADO_REAL
SELECT E.cod_ID 
	,E.nom_Cluster
	,E.ind_Gpon 
	,MIN(C.ind_Ordem) as indOrdem 
INTO #TT_REALIZADO_REAL
FROM TB_PL_Reparo_Encerrado AS E WITH (NOLOCK)
INNER JOIN TB_FGT_Contrato AS C WITH (NOLOCK)
ON E.cod_Cluster = C.cod_Cluster
WHERE E.dat_Referencia = '2023-04-12' 
    AND E.cod_Cluster BETWEEN 1 AND 13
    AND E.cod_Origem = 1
	AND cod_Status = 4 
GROUP BY E.cod_ID
	,E.nom_Cluster
	,E.ind_Gpon
	,C.ind_Ordem
 ----------------------- AQUI COMEÇA A CONSULTA ----------- 
DECLARE @I INT = 2, @ind_Gpon INT = NULL
WHILE @I >= 0
BEGIN

	SELECT CASE @I
		WHEN 1 THEN 'Premium'
		WHEN 0 THEN 'Massivo'
		WHEN 2 THEN 'UGR'
	ELSE NULL END AS 'Tipo_Tecnologia'

	SET @ind_Gpon = CASE WHEN @I = 2 THEN NULL ELSE @I END  

    SELECT MT2.Cluster  
	,SUM(Total) as  Total
    ,SUM(Outliers) as  Outliers
    ,SUM(Entrante_Real) as Entrante_Real  
    ,SUM(Realizado_Real) as Realizado_Real  
	FROM(
		SELECT Cluster as CLuster --TOTAL
			,COUNT (codID) AS Total
			,0 as [Outliers] 
    		,0 as [Entrante_Real]
    		,0 as [Realizado_Real] 
			,indOrdem 
		FROM #TT_TOTAL WITH (NOLOCK)
		WHERE (indGpon = @ind_Gpon OR @ind_Gpon IS NULL)
		GROUP BY Cluster
			,indOrdem
		UNION ALL
		SELECT 'SPC' as [Cluster] 
			,COUNT (codID) as [Total]
			,0 as [Outliers] 
			,0 as [Entrante Real]
			,0 as [Realizado_Real]
			,100 as indOrdem
		FROM #TT_TOTAL WITH (NOLOCK) --TOTAL 
		WHERE (indGpon = @ind_Gpon OR @ind_Gpon IS NULL)
		UNION ALL 
		SELECT Cluster as CLuster  -- Outlier
			,0 AS Total
			,COUNT(codID) as [Outliers] 
    		,0 as [Entrante_Real]
    		,0 as [Realizado_Real]
			,indOrdem
		FROM #TT_TOTAL
		WHERE codOutliers <> 0 
		AND (indGpon = @ind_Gpon OR @ind_Gpon IS NULL)
		GROUP BY Cluster
			,indOrdem
		UNION ALL 
		SELECT 'SPC' as CLuster  
			,0 AS Total
			,COUNT(codID) as [Outliers] 
    		,0 as [Entrante_Real]
    		,0 as [Realizado_Real]  
			,100 as indOrdem
		FROM #TT_TOTAL
		WHERE codOutliers <> 0  -- Outlier
		AND (indGpon = @ind_Gpon OR @ind_Gpon IS NULL)
		UNION ALL 
		SELECT Cluster as CLuster --Entrante
			,0 AS Total
			,0 as [Outliers] 
    		,COUNT (codID) as [Entrante_Real]
    		,0 as [Realizado_Real] 
			,indOrdem
		FROM #TT_ENTRANTE_REAL WITH (NOLOCK)
		WHERE (indGpon = @ind_Gpon OR @ind_Gpon IS NULL)
		GROUP BY Cluster
			,indOrdem
		UNION ALL 
		SELECT 'SPC' as CLuster 
			,0 AS Total
			,0 as [Outliers] 
    		,COUNT (codID) as [Entrante_Real]
    		,0 as [Realizado_Real] 
			,100 as indOrdem
		FROM #TT_ENTRANTE_REAL WITH (NOLOCK) --Entrante 
		WHERE (indGpon = @ind_Gpon OR @ind_Gpon IS NULL)
		UNION ALL 
		SELECT Cluster as CLuster -- Realizado Real
			,0 AS Total
			,0 as [Outliers] 
    		,0 as [Entrante_Real]
    		,COUNT (codID) as [Realizado_Real]
			,indOrdem 
		FROM #TT_REALIZADO_REAL WITH (NOLOCK)
		WHERE (indGpon = @ind_Gpon OR @ind_Gpon IS NULL)
		GROUP BY Cluster
			,indOrdem
		UNION ALL 
		SELECT 'SPC' as CLuster 
			,0 AS Total
			,0 as [Outliers] 
    		,0 as [Entrante_Real]
    		,COUNT (codID) as [Realizado_Real] 
			,100 as indOrdem
			FROM #TT_REALIZADO_REAL WITH (NOLOCK) -- Realizado Real
			WHERE (indGpon = @ind_Gpon OR @ind_Gpon IS NULL)
		)MT2
		GROUP BY Cluster
			,indOrdem
		ORDER BY indOrdem  ASC 
			,CLUSTER ASC 
		SET @I = @I - 1
END