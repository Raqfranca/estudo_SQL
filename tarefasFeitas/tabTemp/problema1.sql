DECLARE @cod_Origem INT = 1
	,@dat_Referencia DATE = '2023-05-22'
	,@cod_Regional INT = 1, @cod_Status INT = 4
	,@dat_Encerramento DATETIME = '2023-05-22 23:59:59.999'
	,@I INT = 2, @ind_Gpon INT = NULL

SELECT *
	--,nom_Cluster as [Cluster]   
	--,sum(case when (dat_Encerramento >= @dat_Encerramento OR cod_Status <> 3)then 1 else 0 end) as [Entrante_Real] 
FROM TB_PL_Reparo_Entrante WITH (NOLOCK)
WHERE dat_Referencia = @dat_Referencia 
	AND cod_Origem = @cod_Origem
	AND cod_Regional = @cod_Regional
	AND (dat_Encerramento >= @dat_Encerramento OR cod_Status <> 3)
--GROUP BY nom_Cluster

-- CERTO 6474 