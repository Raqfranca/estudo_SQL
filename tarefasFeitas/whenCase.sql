DECLARE @cod_Origem INT = 1
	,@dat_Referencia DATE = '2023-05-22'
	,@cod_Regional INT = 1, @cod_Status INT = 4
	,@dat_Encerramento DATETIME = '2023-05-22 23:59:59.999'
	,@I INT = 2, @ind_Gpon INT = NULL

	SELECT MT.Cluster
   		,SUM(Total) as  Total
   		,SUM(Outliers) as  Outliers
   		,SUM(Entrante_Real) as Entrante_Real  
   		,SUM(Realizado_Real) as Realizado_Real  
		--,MN.minInd AS IND 
	FROM (
SELECT  -- TOTAL + OUTLIERS
    nom_Cluster as [Cluster]
    ,sum(case when 1=1 then 1 else 0 end) as [Total] 
    ,sum(case when ind_OutliersHoras <> 0 then 1 else 0 end) as [Outliers]  
	,0 AS [Entrante_Real] 
	,0 as [Realizado_Real]
FROM TB_PL_Reparo_Restante  WITH (NOLOCK) 
WHERE 
    dat_Referencia = @dat_Referencia 
    AND cod_Cluster BETWEEN 1 AND 13
    AND cod_Origem = @cod_Origem
GROUP BY nom_Cluster
union all 
SELECT 'SPC' as [Cluster]  
	,sum(case when 1=1 then 1 else 0 end) as [Total] 
	,sum(case when ind_OutliersHoras <> 0 then 1 else 0 end) as [Outliers] 
	,0 AS [Entrante_Real]
	,0 as [Realizado_Real]
FROM TB_PL_Reparo_Restante WITH (NOLOCK) 
WHERE dat_Referencia = @dat_Referencia
	AND cod_Origem = @cod_Origem
--	AND (ind_Gpon = @ind_Gpon OR @ind_Gpon IS NULL)
	AND cod_Cluster BETWEEN 1 AND 13  -- TOTAL -- TOTAL + OUTLIERS
UNION ALL
SELECT nom_Cluster as [Cluster] -- ENTRANTE REAL 
	,0 as [Total] 
    ,0 as [Outliers] 
	,sum(case when (dat_Encerramento >= @dat_Encerramento OR cod_Status <> 3)then 1 else 0 end) as [Entrante_Real] 
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
	,sum(case when (dat_Encerramento >= @dat_Encerramento OR cod_Status <> 3)then 1 else 0 end) as [Entrante_Real] 
	,0 as [Realizado_Real]
FROM TB_PL_Reparo_Entrante WITH (NOLOCK)
WHERE dat_Referencia = @dat_Referencia 
	AND cod_Origem = @cod_Origem
	AND cod_Regional = @cod_Regional
	--AND (ind_Gpon = @ind_Gpon OR @ind_Gpon IS NULL)
UNION ALL
SELECT nom_Cluster as [Cluster] -- REALIZADO REAL 
	,0 as [Total] 
    ,0 as [Outliers] 
  	,0 as [Entrante_Real] 
  	,sum(case when cod_Status = @cod_Status then 1 else 0 end)  as [Realizado Real]
FROM TB_PL_Reparo_Encerrado WITH (NOLOCK)
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
	,0 as [Entrante_Real]
	,sum(case when cod_Status = @cod_Status then 1 else 0 end)  as [Realizado Real]
FROM TB_PL_Reparo_Encerrado WITH (NOLOCK)
WHERE dat_Referencia = @dat_Referencia
	AND cod_Origem = @cod_Origem
	AND cod_Regional = @cod_Regional 
	AND (ind_Gpon = @ind_Gpon OR @ind_Gpon IS NULL)  -- REALIZADO REAL 	 
	
)MT
GROUP BY MT.Cluster













--select top 100 * FROM TB_PL_Reparo_Restante  WITH (NOLOCK) 

--select 
--sum(case when cod_ID is not null then 1 else 0 end) as [total]
--FROM TB_PL_Reparo_Restante  WITH (NOLOCK) 

--select
--case cod_Origem
--	when 1 then 'Telefonica' 
--	when 2 then 'GVT'
--	else null
--	end 
--FROM TB_PL_Reparo_Restante  WITH (NOLOCK) 
--group by cod_Origem


---- Teste de entrantes -- 
--SELECT Cluster  
--	,Total
--    ,Outliers
--FROM(
--	SELECT nom_Cluster as CLuster --TOTAL
--		,sum(case when 1=1 then 1 else 0 end) as [Total] 
--		,sum(case when ind_OutliersHoras <> 0 then 1 else 0 end) as [Outliers] 
--		,indOrdem
--	FROM VWT_TOTAL2 WITH (NOLOCK)
--	GROUP BY nom_Cluster
--		,indOrdem
--	UNION ALL
--	SELECT 'SPC' as [Cluster] 
--		,sum(case when 1=1 then 1 else 0 end) as [Total] 
--		,sum(case when ind_OutliersHoras <> 0 then 1 else 0 end) as [Outliers] 
--		,100 as indOrdem
--	FROM VWT_TOTAL2 WITH (NOLOCK) --TOTAL 		
--)MT
--GROUP BY Cluster
--	,Outliers
--	,Total
--	,indOrdem
--ORDER BY indOrdem


	
		