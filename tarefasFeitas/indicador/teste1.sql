
DECLARE @cod_Origem INT = 1 ,@dat_Referencia DATE = '2023-06-01' ,@cod_Regional INT = 1, @cod_Status INT = 4 ,@dat_Encerramento DATETIME ,@I INT = 2, @ind_Gpon INT = NULL SET @dat_Encerramento = CONVERT(DATETIME, CONVERT(VARCHAR(10), @dat_Referencia, 120) + ' 23:59:59.999')

select *
from(
	SELECT cod_Cluster  as [cod_Cluster]
		,COUNT(cod_ID)  as valor1 
		,SUM(CASE WHEN ind_OutliersHoras <> 0 THEN 1 ELSE 0 END) as valor2
		,1 AS cod_Tabel
	FROM TB_PL_Reparo_Restante  WITH (NOLOCK) 
	WHERE dat_Referencia = @dat_Referencia 
   			AND cod_Cluster BETWEEN 1 AND 13
   			AND cod_Origem = @cod_Origem 
			AND (ind_Gpon = @ind_Gpon OR @ind_Gpon IS NULL) 
	GROUP BY cod_Cluster  
	UNION ALL 
		 -- ENTRANTE REAL
		SELECT cod_Cluster as [cod_Cluster] 
		,SUM(CASE WHEN (dat_Encerramento >= @dat_Encerramento OR cod_Status <> 3)THEN 1 ELSE 0 END) as valor1 
		,null as valor2  
		,2 AS cod_Tabela
		FROM TB_PL_Reparo_Entrante WITH (NOLOCK)
		WHERE dat_Referencia = @dat_Referencia
   			AND cod_Origem = @cod_Origem
    		AND cod_Regional = @cod_Regional 
    		AND cod_Cluster BETWEEN 1 AND 13 
			AND (ind_Gpon = @ind_Gpon OR @ind_Gpon IS NULL) 
		GROUP BY cod_Cluster  
		UNION ALL 
		--Encerrado 
		SELECT cod_Cluster as [cod_Cluster]
			,SUM(CASE WHEN cod_Status = @cod_Status THEN 1 ELSE 0 END)  AS [Valor]
			,null as valor2
			,3 AS cod_Tabela
		FROM TB_PL_Reparo_Encerrado WITH (NOLOCK)
		WHERE dat_Referencia = @dat_Referencia
			AND cod_Origem = @cod_Origem 
    		AND cod_Regional = @cod_Regional  
    		AND cod_Cluster BETWEEN 1 AND 13 
			AND (ind_Gpon = @ind_Gpon OR @ind_Gpon IS NULL) 
		GROUP BY cod_Cluster
)b
