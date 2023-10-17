

--Cada numero (cod_par) ele corresponde a alguma coisa em outras palavras quando ele for 1 ele vai ser hc  coluna de valor que ela vai ser 100
DROP TABLE #TMP_COD_PAR
--Transfromar os dados que você precisa em parametro
--O que voce precisa 
--total, outliers e os outros bagulhos la!

--Primeiro passo criar a tabela de parametro
CREATE TABLE #TMP_COD_PAR(
	COD_PAR INT
	,DESC_PAR VARCHAR(55)

)

INSERT INTO #TMP_COD_PAR (COD_PAR,DESC_PAR)
VALUES(1,'HC A')

INSERT INTO #TMP_COD_PAR (COD_PAR,DESC_PAR)
VALUES(2,'HC F')



-- Segundo Passo criar um grande analitico
CREATE TABLE #TMP_PL_ANALITICO(
cod_ID INT
,ind_Gpon INT
,cod_Status INT
,dat_Encerramento  DATETIME
,dat_Referencia DATETIME
,cod_Cluster INT
,cod_Tb SMALLINT
)
---------------GRANDE ANALITICO----------------------------
SELECT cod_ID
	,ind_Gpon
	,cod_Status
	,dat_Encerramento 
	,dat_Referencia
	,cod_Cluster
	,1 as cod_Tb
FROM TB_PL_Reparo_Entrante WITH(NOLOCK)
WHERE dat_Referencia = '2023-05-30'
	

SELECT cod_ID
	,ind_Gpon
	,cod_Status
	,dat_Encerramento 
	,dat_Referencia
	,cod_Cluster
	,2 as cod_tbPl
FROM TB_PL_Reparo_Entrante WITH(NOLOCK)
WHERE dat_Referencia = '2023-05-30'


SELECT cod_ID
	,ind_Gpon
	,cod_Status
	,dat_Encerramento 
	,dat_Referencia
	,cod_Cluster
	,3 as cod_tbPl
FROM TB_PL_Reparo_Entrante WITH(NOLOCK)
WHERE dat_Referencia = '2023-05-30'
---------------GRANDE ANALITICO----------------------------	




--Mostrar os dados parametrizados 
SELECT cod_Cluster
	,ind_Gpon
	,cod_Status
	,dat_Referencia
	,dat_Encerramento
	,COD_PAR
	,CASE COD_PAR 
		WHEN 1 THEN SUM(CASE WHEN cod_Tb = 3 AND ind_OutliersHoras <> 0 THEN 1 ELSE 0 END)AS outliers
FROM #TMP_PL_ANALITICO
--Cruzar com a tmp parametro!
CROSS JOIN(
	SELECT COD_PAR
	FROM #TMP_COD_PAR
)AS PAR
GROUP BY dat_Referencia
	,dat_Encerramento
	,cod_Cluster
	,ind_Gpon
	,cod_Status