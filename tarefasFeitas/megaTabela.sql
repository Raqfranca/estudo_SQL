-- Ugr 
-- Backlog // Total // Outliers // Com SPC // Com Entrante_Real // Com Realizado_Real 

SELECT  Cluster
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
	WHERE dat_Referencia = '2023-04-12' 
   		AND cod_Cluster BETWEEN 1 AND 13
   		AND cod_Origem = 1
	GROUP BY cod_Cluster
   		,nom_Cluster
	UNION all
	SELECT nom_Cluster as [Cluster]
		,0 as [Total] 
		,0 as [Outliers] 
		,COUNT (cod_ID) as [Entrante_Real]
		,0 as [Realizado_Real]
	FROM TB_PL_Reparo_Entrante WITH (NOLOCK)
	WHERE dat_Referencia = '2023-04-12' 
		AND cod_Origem = 1 -- Vivo01
		AND cod_Regional =1 -- SPC 
		AND cod_Cluster BETWEEN 1 AND 13 
		AND  (dat_Encerramento >= '2023-04-12 23:59:59.999' OR cod_Status <> 3)
	GROUP BY nom_Cluster
	UNION all 
	SELECT 'SPC' as [Cluster] 
			,COUNT (cod_ID) as [Total]
		,0 as [Outliers] 
		,0 as [Entrante Real]
		,0 as [Realizado_Real]
	FROM TB_PL_Reparo_Restante WITH (NOLOCK) 
	WHERE dat_Referencia = '2023-04-12' 
		AND cod_Origem = 1 
		AND cod_Cluster BETWEEN 1 AND 13 
		UNION all
	SELECT nom_Cluster as [Cluster] 
   		,0 as [Total]   
		,COUNT (cod_ID) as [Outliers] 
		,0 as [Entrante_Real]
		,0 as [Realizado_Real]
	FROM TB_PL_Reparo_Restante  WITH (NOLOCK) 
	WHERE dat_Referencia = '2023-04-12' 
		AND cod_Regional =1 
		AND cod_Origem = 1 
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
	WHERE dat_Referencia = '2023-04-12' 
		AND cod_Origem = 1 
		AND cod_Regional =1  
		AND cod_Cluster BETWEEN 1 AND 13 
		AND cod_Status = 4 
	GROUP BY nom_Cluster
	UNION all
	SELECT 'SPC' as [Cluster] 
		,0 as [Total] 
		,0 as [Outliers]
		,0 as [Entrante_Real]
		,COUNT (cod_ID) as [Realizado Real]
	FROM TB_PL_Reparo_Encerrado WITH (NOLOCK)
	WHERE dat_Referencia = '2023-04-12' 
		AND cod_Origem = 1 
		AND cod_Regional =1 
		AND cod_Status = 4
	UNION all 
	SELECT 'SPC' as [Cluster] 
		,0 as [Total] 
		,COUNT (cod_ID) as [Outliers]
		,0 as [Entrante_Real]
		,0 as [Realizado_Real]
	FROM TB_PL_Reparo_Restante  WITH (NOLOCK) 
	WHERE dat_Referencia = '2023-04-12' 
		AND cod_Origem = 1 
		AND cod_Cluster BETWEEN 1 AND 13
		AND ind_OutliersHoras <> 0  
	UNION all
	SELECT 'SPC' as [Cluster] 
		,0 as [Total]
		,0 as [Outliers] 
		,COUNT (cod_ID) as [Entrante_Real]
		,0 as [Realizado_Real]
	FROM TB_PL_Reparo_Entrante WITH (NOLOCK)
	WHERE dat_Referencia = '2023-04-12' 
		AND cod_Origem = 1 -- Vivo01
		AND cod_Regional =1 -- SPC 
		AND  (dat_Encerramento >= '2023-04-12 23:59:59.999' OR cod_Status <> 3)		 
) megaTabela
GROUP BY Cluster  
ORDER BY Cluster ASC

-- Massivo and Premium 
-- Backlog // Total // Outliers // Com SPC // Com Entrante_Real // Com Realizado_Real 

DECLARE @indGpon INT = 0

WHILE @indGpon <= 1

BEGIN
	SELECT  Cluster
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
		WHERE dat_Referencia = '2023-04-12' 
   			AND cod_Cluster BETWEEN 1 AND 13
   			AND cod_Origem = 1
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
		WHERE dat_Referencia = '2023-04-12' 
			AND cod_Origem = 1 -- Vivo01
			AND cod_Regional =1 -- SPC 
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
		WHERE dat_Referencia = '2023-04-12' 
			AND cod_Origem = 1 
			AND cod_Cluster BETWEEN 1 AND 13
			AND ind_Gpon = @indGpon 
			UNION all
		SELECT nom_Cluster as [Cluster] 
   			,0 as [Total]   
			,COUNT (cod_ID) as [Outliers] 
			,0 as [Entrante_Real]
			,0 as [Realizado_Real]
		FROM TB_PL_Reparo_Restante  WITH (NOLOCK) 
		WHERE dat_Referencia = '2023-04-12' 
			AND cod_Regional =1 
			AND cod_Origem = 1 
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
		WHERE dat_Referencia = '2023-04-12' 
			AND cod_Origem = 1 
			AND cod_Regional =1  
			AND cod_Cluster BETWEEN 1 AND 13 
			AND cod_Status = 4 
			AND ind_Gpon = @indGpon
		GROUP BY nom_Cluster
			UNION all
		SELECT 'SPC' as [Cluster] 
			,0 as [Total] 
			,0 as [Outliers]
			,0 as [Entrante_Real]
			,COUNT (cod_ID) as [Realizado Real]
		FROM TB_PL_Reparo_Encerrado WITH (NOLOCK)
		WHERE dat_Referencia = '2023-04-12' 
			AND cod_Origem = 1 
			AND cod_Regional =1 
			AND cod_Status = 4
			AND ind_Gpon = @indGpon
			UNION all 
		SELECT 'SPC' as [Cluster] 
			,0 as [Total] 
			,COUNT (cod_ID) as [Outliers]
			,0 as [Entrante_Real]
			,0 as [Realizado_Real]
		FROM TB_PL_Reparo_Restante  WITH (NOLOCK) 
		WHERE dat_Referencia = '2023-04-12' 
			AND cod_Origem = 1 
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
		WHERE dat_Referencia = '2023-04-12' 
			AND cod_Origem = 1 -- Vivo01
			AND cod_Regional =1 -- SPC 
			AND  (dat_Encerramento >= '2023-04-12 23:59:59.999' OR cod_Status <> 3)	-- alterar 
			AND ind_Gpon = @indGpon	 
	) megaTabela_Massivo_Premium 
	GROUP BY Cluster  
	ORDER BY Cluster ASC

	SET @indGpon = @indGpon + 1
END 

-- Para diferenciar a tabela de massivo(0) e premium (1) preciso mudar o  ind_Gpon

-- O QUE EU PRECISO FAZER!! 
-- Criar a tabela UGR - FEITO 
-- Arrumar a coluna de entrante - FEITO 
-- Colocar a coluna de entrante no megaBloco - FEITO
-- Fazer a coluna de realizado real - FEITO 
-- Colocar a coluna realizado real no megaBloco - FEITO  
-- Aprender a fazer loops em SQL - FEITO
-- Aplicar o loops para criar todas as tabelas - FEITO
-- Extra: Tentar realizar a média - FEITO


-- ATIVIDADE 03: Arrumar a ordem das Cluster usando a tabela de contrato de Cluster 