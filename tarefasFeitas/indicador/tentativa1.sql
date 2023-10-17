--- Existe uma função em group by que que eu esqueci o nome, é uma função. 
-- Transformar o 0 as ... em indicador, pq? Pq a minha tabela armazena o 0 e depois substitui pelo valor que eu passo
-- depois usar uma função do group by para criar o SPC 
-- Acho para criar os indicadores eu preciso usar o indice, mas expeficico o Índice Não-Cluster mas to com muito sono e não consigo entender o que ele faz
-- não tenho certeza sobre os index, preciso pensar mais 
-- o spc não tem ind então eu preciso dar esse valor pra ele, tipo quando sei lá oq for null, ele vai ser spc então recebe 100x 
-- quando ... for null vai ter ind ordem 1000x 
-- gropup by concat, rollup, 

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
	SELECT MT.Cluster
		,SUM(Total) as  Total
   		,SUM(Outliers) as  Outliers
   		,SUM(Entrante_Real) as Entrante_Real  
   		,SUM(Realizado_Real) as Realizado_Real  
   		--,MT.Total 
   		--,MT.Outliers
   		--,MT.Entrante_Real  
   		--,MT.Realizado_Real  
		,MN.minInd AS IND 
	FROM (
		SELECT 
   			nom_Cluster as [Cluster] -- TOTAL + OUTLIERS
			,COUNT(cod_ID) as [Total] 
   			,SUM(CASE WHEN ind_OutliersHoras <> 0 THEN 1 ELSE 0 END) as [Outliers]  
			,0 AS [Entrante_Real] 
			,0 as [Realizado_Real]
		FROM TB_PL_Reparo_Restante  WITH (NOLOCK) 
		WHERE dat_Referencia = @dat_Referencia 
   			AND cod_Cluster BETWEEN 1 AND 13
   			AND cod_Origem = @cod_Origem
			AND (ind_Gpon = @ind_Gpon OR @ind_Gpon IS NULL)
		GROUP BY nom_Cluster -- TOTAL -- TOTAL + OUTLIERS
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
		GROUP BY nom_Cluster -- ENTRANTE REAL
		UNION ALL
		SELECT nom_Cluster as [Cluster] -- REALIZADO REAL 
			,0 as [Total] -- preciso tranformar esse valor em um indicador 
    		,0 as [Outliers] 
  			,0 as [Entrante_Real] 
  			,sum(CASE WHEN cod_Status = @cod_Status THEN 1 ELSE 0 END)  AS [Realizado Real]
		FROM TB_PL_Reparo_Encerrado WITH (NOLOCK)
		WHERE dat_Referencia = @dat_Referencia
			AND cod_Origem = @cod_Origem 
    		AND cod_Regional = @cod_Regional  
    		AND cod_Cluster BETWEEN 1 AND 13 
			AND (ind_Gpon = @ind_Gpon OR @ind_Gpon IS NULL) 
		GROUP BY nom_Cluster  -- REALIZADO REAL 	 	
)MT
	LEFT JOIN (
		SELECT MIN(ind_Ordem) AS minInd 
			,nom_Cluster AS CLUSTER
		FROM TB_FGT_Contrato WITH (NOLOCK)
		GROUP BY ind_Ordem 
			,nom_Cluster 
	)MN on MN.CLUSTER = MT.Cluster
	GROUP BY MT.Cluster 
			--,MT.Total 
   --			,MT.Outliers
   --			,MT.Entrante_Real  
   --			,MT.Realizado_Real    
			,MN.minInd
)ODIO
-- PQ O ORDER BY ESTÁ FORA DO SELECT PRINCIPAL? PQ PELA ORDEM DE PRECESSAMENTO O SELECT VEM PRIMEIRO E DEPOIS É O ORDER 
SELECT Cluster
	,Total
	,Outliers
	,Entrante_Real
	,Realizado_Real
   		--,SUM(Total) as  Total
   		--,SUM(Outliers) as  Outliers
   		--,SUM(Entrante_Real) as Entrante_Real  
   		--,SUM(Realizado_Real) as Realizado_Real  
FROM #FUNCIONAPELOAMORDEDEUS
--GROUP BY Total
--	,Outliers
--	,Entrante_Real
--	,Realizado_Real
ORDER BY IND ASC
	,Cluster asc

IF OBJECT_ID('TEMPDB..#FUNCIONAPELOAMORDEDEUS') IS NOT NULL BEGIN DROP TABLE #FUNCIONAPELOAMORDEDEUS END
SET @I = @I - 1
END 

