USE [FGESTAO]
GO
/****** Object:  StoredProcedure [dbo].[Raquel_HxH]    Script Date: 24/07/2023 11:50:16 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[Raquel_HxH] 
	@dat_Referencia DATE = NULL  
	,@cod_Origem VARCHAR (100) = NULL
	,@ind_Agrup INT = NULL
	,@cod_Regional VARCHAR (100) = NULL
	,@cod_Paramns VARCHAR(100) = NULL 
AS 

BEGIN

IF OBJECT_ID('TEMPDB..#clusterTotal') IS NOT NULL BEGIN DROP TABLE #clusterTotal END	

DECLARE @cod_Status INT = 4,  @dat_Encerramento DATETIME SET @dat_Encerramento = CONVERT(DATETIME, CONVERT(VARCHAR(10), @dat_Referencia, 120) + ' 23:59:59.999');

--DECLARE @dat_Referencia DATE = '2023-06-16', @cod_Origem INT = 1, @cod_Status INT = 4, @dat_Encerramento DATETIME SET @dat_Encerramento = CONVERT(DATETIME, CONVERT(VARCHAR(10), @dat_Referencia, 120) + ' 23:59:59.999')

SELECT cod_Cluster 
	,COUNT(cod_ID) AS Valor
	,cod_par
	,ind_Gpon
INTO #clusterTotal 
FROM(
	SELECT cod_ID
		,cod_Cluster
		,ind_Gpon
		,cod_Origem
		,CASE 
			WHEN ind_OutliersHoras = 1 THEN 1 
			WHEN ind_OutliersHoras = 0 THEN 2
		END AS cod_par
	FROM TB_PL_Reparo_Restante  WITH (NOLOCK) 
	WHERE dat_Referencia = @dat_Referencia 
		AND cod_Cluster is not null 
	UNION ALL 
		-- ENTRANTE REAL
	SELECT cod_ID 
		,cod_Cluster
		,ind_Gpon 
		,cod_Origem
		,3 AS cod_Par
	FROM TB_PL_Reparo_Entrante WITH (NOLOCK)
	WHERE dat_Referencia = @dat_Referencia
		AND (dat_Encerramento >= @dat_Encerramento OR cod_Status <> 3)
		AND cod_Cluster is not null 
	UNION ALL 
	-- REALIZADO REAL 
	--DECLARE @dat_Referencia DATE = '2023-06-16', @cod_Status INT = 4, @cod_Origem INT = 1, @dat_Encerramento DATETIME SET @dat_Encerramento = CONVERT(DATETIME, CONVERT(VARCHAR(10), @dat_Referencia, 120) + ' 23:59:59.999')
	SELECT cod_ID 
		,cod_Cluster
		,ind_Gpon 
		,cod_Origem
		,4 AS cod_Par
	FROM TB_PL_Reparo_Encerrado WITH (NOLOCK)
	WHERE dat_Referencia = @dat_Referencia
		AND cod_Status = @cod_Status
		AND cod_Cluster is not null 
)t1
WHERE cod_Origem IN (SELECT VALUE FROM dbo.FN_SPLIT_STRING(@cod_Origem, ','))
GROUP BY cod_Cluster
	,cod_par
	,ind_Gpon

-- FIM DA TEMP

DECLARE @ind_Gpon INT = NULL , @I INT = 2
 
WHILE @I >= 0

BEGIN

SELECT CASE @I
	WHEN 1 THEN 'Premium'
	WHEN 0 THEN 'Massivo'
	WHEN 2 THEN 'UGR'
ELSE NULL END AS 'Tipo_Tecnologia'

SET @ind_Gpon = CASE WHEN @I = 2 THEN NULL ELSE @I END

--DECLARE @ind_Agrup INT =1, @cod_Regional AS VARCHAR (100) = '1,6', @cod_Paramns VARCHAR (100) = NULL
SELECT Contrato
	,Total
	,Outliers
	,Entrante_Real
	,Realizado_Real
FROM(
	SELECT Contrato	 = (CASE WHEN cod_Regional = 1 AND ind_Ordem IS NULL THEN 'SPC'
							WHEN cod_Regional =  2 AND ind_Ordem IS NULL THEN 'Sudeste'
							WHEN cod_Regional = 3 AND ind_Ordem IS NULL THEN 'Sul'
							WHEN cod_Regional = 4 AND ind_Ordem IS NULL THEN 'Centro-Oeste'
							WHEN cod_Regional = 5 AND ind_Ordem IS NULL THEN 'Nordeste'
							WHEN cod_Regional = 6 AND ind_Ordem IS NULL THEN 'SPI' 
							WHEN cod_Regional IS NULL AND ind_Ordem IS NULL THEN 'DSP' 
						ELSE Contrato 
						END)
	,ind_Ordem = (CASE WHEN cod_Regional = 1 AND ind_Ordem IS NULL THEN 9
					WHEN cod_Regional = 6 AND ind_Ordem IS NULL THEN 30 
					WHEN cod_Regional =  2 AND ind_Ordem IS NULL THEN 60
					WHEN cod_Regional = 3 AND ind_Ordem IS NULL THEN 90
					WHEN cod_Regional = 4 AND ind_Ordem IS NULL THEN 111
					WHEN cod_Regional = 5 AND ind_Ordem IS NULL THEN 131
					WHEN cod_Regional IS NULL AND ind_Ordem IS NULL THEN 31 
				ELSE ind_Ordem
				END)			
	,SUM(CASE WHEN cod_par IN(1,2) THEN Valor ELSE 0 END) AS [Total]
	,SUM(CASE cod_par WHEN 1 THEN Valor ELSE 0 END) as [Outliers] 
	,SUM(CASE cod_par WHEN 3 THEN Valor ELSE 0 END) as [Entrante_Real] 
	,SUM(CASE cod_par WHEN 4 THEN Valor ELSE 0 END) as [Realizado_Real] 
	,B.cod_Regional
	FROM(
		SELECT CASE @ind_Agrup WHEN 1  THEN nom_Contrato_Grupo
					WHEN 2 THEN nom_Cluster
					WHEN 3 THEN nom_Gerencia
				END AS Contrato
		,ind_Ordem
		,cod_Regional
		,cod_Cluster
		FROM TB_FGT_Contrato WITH (NOLOCK)
		WHERE cod_Regional  IN (SELECT VALUE FROM dbo.FN_SPLIT_STRING(@cod_Regional, ','))
			AND ((CASE @ind_Agrup
				WHEN 1 THEN cod_Contrato_Grupo
				WHEN 2 THEN cod_Cluster
				WHEN 3 THEN cod_Cluster
				ELSE NULL END) IN (SELECT VALUE FROM dbo.FN_SPLIT_STRING(@cod_Paramns,',')) OR @cod_Paramns IS NULL ) 
			AND cod_Cluster NOT IN(24,29,30,100,101,102,121,120)
		GROUP BY 
			CASE @ind_Agrup WHEN 1  THEN nom_Contrato_Grupo
				WHEN 2 THEN nom_Cluster
				WHEN 3 THEN nom_Gerencia
			END 
			,ind_Ordem
			,cod_Regional
			,cod_Cluster
	)B
	LEFT JOIN (
		SELECT cod_Cluster 
			,Valor
			,cod_par
			,ind_Gpon
		FROM #clusterTotal
		WHERE (ind_Gpon = @ind_Gpon OR @ind_Gpon IS NULL) 
	)A ON A.cod_Cluster = B.cod_Cluster 
	GROUP BY cod_Regional, B.ind_Ordem, Contrato
	WITH ROLLUP
)C
WHERE Contrato is not null
ORDER BY ind_Ordem

SET @I = @I - 1

END 

IF OBJECT_ID('TEMPDB..#clusterTotal')   IS NOT NULL BEGIN DROP TABLE #clusterTotal END	

END