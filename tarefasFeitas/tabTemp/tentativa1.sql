--- Começando a fazer tabelas temporarias ---- 

CREATE TABLE #TESTE_TABELA_TEMP
(
	CLUSTER VARCHAR (50),
	TOTAL SMALLINT,
	OUTLIERS SMALLINT, 
	ENTRANTE_REAL SMALLINT,
	REALIZADO_REAL SMALLINT 
)

-- 
INSERT INTO #TESTE_TABELA_TEMP(CLUSTER,TOTAL) -- TOTAL 
 SELECT nom_Cluster as [Cluster]
        ,COUNT (cod_ID) as [Total] 
 FROM TB_PL_Reparo_Restante as RR WITH (NOLOCK) 
 WHERE dat_Referencia = '2023-04-12'  
	AND cod_Cluster BETWEEN 1 AND 13
    AND cod_Origem = 1
GROUP BY cod_Cluster
	,nom_Cluster

SELECT * FROM  #TESTE_TABELA_TEMP 



-- TENTANDO UTILIZAR O WHEN CASE -- 

DECLARE @cod_Origem INT = 1
DECLARE @dat_Referencia DATE = '2023-04-12' 

SELECT RR.nom_Cluster as CLuster --TOTAL + Outliers
	,sum(case when 1=1 then 1 else 0 end) as [Total] 
	,sum(case when ind_OutliersHoras <> 0 then 1 else 0 end) as [Outliers]
	,MIN(C.ind_Ordem) as indOrdem 
FROM TB_PL_Reparo_Restante AS RR  WITH (NOLOCK)
INNER JOIN TB_FGT_Contrato AS C WITH (NOLOCK)
ON RR.cod_Cluster = C.cod_Cluster
WHERE dat_Referencia = @dat_Referencia 
      AND RR.cod_Cluster BETWEEN 1 AND 13
      AND RR.cod_Origem = @cod_Origem
GROUP BY RR.nom_Cluster
		,C.ind_Ordem 
ORDER BY indOrdem ASC 

UNION ALL
SELECT 'SPC' as [Cluster] 
	,sum(case when 1=1 then 1 else 0 end) as [Total] 
	,sum(case when ind_OutliersHoras <> 0 then 1 else 0 end) as [Outliers] 
FROM TB_PL_Reparo_Restante   WITH (NOLOCK) --TOTAL + Outliers
WHERE dat_Referencia = @dat_Referencia 
      AND cod_Cluster BETWEEN 1 AND 13
      AND cod_Origem = @cod_Origem


SELECT COUNT(RR.cod_ID) AS TOTAL  
--	,RR.ind_Gpon
--	,MIN(C.ind_Ordem) as indOrdem 
	,RR.nom_Cluster
--	,RR.ind_OutliersHoras
FROM TB_PL_Reparo_Restante AS RR WITH (NOLOCK)
INNER JOIN TB_FGT_Contrato as C WITH (NOLOCK)
ON RR.cod_Cluster = C.cod_Cluster
WHERE RR.dat_Referencia = '2023-04-12' 
         AND RR.cod_Cluster BETWEEN 1 AND 13
         AND RR.cod_Origem = 1
GROUP BY --RR.cod_ID 
--	,RR.ind_Gpon 
	C.ind_Ordem 
	,RR.nom_Cluster 
--	,RR.ind_OutliersHoras
ORDER BY C.ind_Ordem ASC 

SELECT TOP 10 * FROM TB_FGT_Contrato



----------------------- TABELA GIGANTE TEMPORARIA --------------------- 
--------------- ESSA SEGUNDA TENTATIVA NÃO ORDENA PELO IND_ORDEM ----------
CREATE TABLE #TESTE_TABELA_TEMP
(
	CLUSTER VARCHAR (50),
	TOTAL SMALLINT,
	OUTLIERS SMALLINT, 
	ENTRANTE_REAL SMALLINT,
	REALIZADO_REAL SMALLINT 
)

INSERT INTO #TESTE_TABELA_TEMP(CLUSTER,TOTAL, OUTLIERS, ENTRANTE_REAL, REALIZADO_REAL)
SELECT megaTabela.Cluster
    ,SUM(Total) as  Total
    ,SUM(Outliers) as  Outliers
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
        AND  (dat_Encerramento >= '2023-04-12 23:59:59.999' OR cod_Status <> 3)
    GROUP BY nom_Cluster
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
) megaTabela

LEFT JOIN (
	SELECT MIN(ind_Ordem) AS minInd 
		,nom_Cluster AS CLUSTER
	FROM TB_FGT_Contrato WITH (NOLOCK)
	WHERE cod_Cluster BETWEEN 0 AND 13 
	GROUP BY ind_Ordem 
		,nom_Cluster 
)miniTabela on miniTabela.CLUSTER = megaTabela.Cluster
GROUP BY megaTabela.Cluster   
		,miniTabela.minInd
ORDER BY miniTabela.minInd ASC


IF OBJECT_ID('TEMPDB..#TESTE_TABELA_TEMP')       IS NOT NULL BEGIN DROP TABLE #TESTE_TABELA_TEMP END

select * from #TESTE_TABELA_TEMP