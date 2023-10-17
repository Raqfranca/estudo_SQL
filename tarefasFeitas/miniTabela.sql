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
	GROUP BY ind_Ordem 
		,nom_Cluster 
)miniTabela on miniTabela.CLUSTER = megaTabela.Cluster
GROUP BY megaTabela.Cluster   
		,miniTabela.minInd
ORDER BY miniTabela.minInd ASC





 



