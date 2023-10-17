---------------- Criando uma tabela temporaria de parametros ------------------------------ 
IF OBJECT_ID('TEMPDB..#cod_Tabela')   IS NOT NULL BEGIN DROP TABLE #cod_Tabela END	

CREATE TABLE #cod_Tabela(
	cod_tab INT
	,desc_tab VARCHAR(55)
)

INSERT INTO #cod_Tabela (cod_tab, desc_tab)
VALUES(1,'Total')

INSERT INTO #cod_Tabela (cod_tab, desc_tab)
VALUES(2,'Outliers')

INSERT INTO #cod_Tabela (cod_tab, desc_tab)
VALUES(3,'Entrante_Real')

INSERT INTO #cod_Tabela (cod_tab, desc_tab)
VALUES(4,'Realizado_Real ')

------------------- Criando uma Mega Temporaria Consolidado com só 3 colunas ------------------------------------------ 

		--Vaviavel  
IF OBJECT_ID('TEMPDB..#clusterTotal')   IS NOT NULL BEGIN DROP TABLE #clusterTotal END	
IF OBJECT_ID('TEMPDB..#tabelaNULL')   IS NOT NULL BEGIN DROP TABLE #tabelaNULL END	
IF OBJECT_ID('TEMPDB..#tabelaZERO')   IS NOT NULL BEGIN DROP TABLE #tabelaZERO END	

DECLARE @cod_Origem INT = 1 ,@dat_Referencia DATE = '2023-06-01' ,@cod_Regional INT = 1, @cod_Status INT = 4 ,@dat_Encerramento DATETIME ,@I INT = 2, @ind_Gpon INT = NULL SET @dat_Encerramento = CONVERT(DATETIME, CONVERT(VARCHAR(10), @dat_Referencia, 120) + ' 23:59:59.999')

SELECT * INTO #clusterTotal 
FROM(	
	SELECT MT.Cluster
		,MT.Valor
		,MT.cod_Tabela 
		,MN.minInd AS IND
	FROM ( 	
		--TOTAL 
		SELECT nom_Cluster as [Cluster]
		,COUNT(cod_ID) as [Valor] 
   		, 1 AS cod_Tabela
		FROM TB_PL_Reparo_Restante  WITH (NOLOCK) 
		WHERE dat_Referencia = @dat_Referencia 
   				AND cod_Cluster BETWEEN 1 AND 13
   				AND cod_Origem = @cod_Origem 
		GROUP BY nom_Cluster
		UNION ALL 
	-- OUTLIERS
		SELECT 
   		nom_Cluster as [Cluster]
		,SUM(CASE WHEN ind_OutliersHoras <> 0 THEN 1 ELSE 0 END) as [Valor]  
   		, 2 AS cod_Tabela
		FROM TB_PL_Reparo_Restante  WITH (NOLOCK) 
		WHERE dat_Referencia = @dat_Referencia 
   				AND cod_Cluster BETWEEN 1 AND 13
   				AND cod_Origem = @cod_Origem 
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
		,sum(CASE WHEN cod_Status = @cod_Status THEN 1 ELSE 0 END)  AS [Valor]
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
		SELECT MIN(ind_Ordem) AS minInd 
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

SELECT * INTO #tabelaNULL 
FROM(	
	SELECT Cluster
		,cod_Tabela
		,CASE cod_Tabela WHEN 1 THEN valor END as [Total] 
		,CASE cod_Tabela WHEN 2 THEN valor END as [Outliers] 
		,CASE cod_Tabela WHEN 3 THEN Valor END as [Entrante_Real] 
		,CASE cod_Tabela WHEN 4 THEN Valor END as [Realizado_Real]
		,IND
	FROM #clusterTotal  
	left JOIN(
		SELECT *
		FROM #cod_Tabela
	)NT		ON #clusterTotal.cod_Tabela = cod_tab
	GROUP BY #clusterTotal.Cluster
		,#clusterTotal.Valor
		,#clusterTotal.cod_Tabela
		,#clusterTotal.IND
)n

SELECT * INTO #tabelaZERO 
FROM(
	select Cluster
		,ISNULL (Total, 0)  as [Total]
		,ISNULL (Outliers, 0)  as [Outliers]
		,ISNULL (Entrante_Real, 0)  as [Entrante_Real]
		,ISNULL (Realizado_Real, 0)  as [Realizado_Real]
		,IND	 
	FROM #tabelaNULL
)P

--select * from #tabelaZERO

SELECT Cluster
	,SUM(Total) as [Total] 
	,SUM(Outliers) as [Outliers] 
	,SUM(Entrante_Real) as [Entrante_Real]
	,SUM(Realizado_Real)  as [Realizado_Real]
FROM #tabelaZERO
GROUP BY Cluster
	,Total
	,Outliers
	,Entrante_Real
	,Realizado_Real

IF OBJECT_ID('TEMPDB..#tabelaZERO')   IS NOT NULL BEGIN DROP TABLE #tabelaZERO END	

IF OBJECT_ID('TEMPDB..#tabelaNULL')   IS NOT NULL BEGIN DROP TABLE #tabelaNULL END	

IF OBJECT_ID('TEMPDB..#clusterTotal')   IS NOT NULL BEGIN DROP TABLE #clusterTotal END	

IF OBJECT_ID('TEMPDB..#cod_Tabela')   IS NOT NULL BEGIN DROP TABLE #cod_Tabela END	


