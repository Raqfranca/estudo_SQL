--Criar uma mega tabela com as tabelas 
-- onde eu preciso juntar as tabelas 

SELECT TOP 1 * FROM TB_PL_Reparo_Restante    WITH (NOLOCK)
SELECT TOP 1 * FROM TB_PL_Reparo_Entrante    WITH (NOLOCK)
SELECT TOP 1 * FROM TB_PL_Reparo_Encerrado   WITH (NOLOCK)

-- dat_Referencia 
-- cod_Cluster
-- cod_Origem
-- cod_Regional -- FROM TB_PL_Reparo_Restante 
-- ind_OutliersHoras -- FROM TB_PL_Reparo_Restante 
-- dat_Encerramento -- FROM TB_PL_Reparo_Entrante 
-- cod_Status -- FROM TB_PL_Reparo_Encerrado 

--select count(re.cod_ID) 
--from TB_PL_Reparo_Restante as rr
--right join TB_PL_Reparo_Encerrado as re with(nolock)
--on rr.cod_Cluster = re.cod_Cluster
--WHERE rr.dat_Referencia = '2023-05-12'
--	AND rr.cod_Origem = 1
--	AND rr.cod_Cluster BETWEEN 1 AND 13 

SELECT cod_ID,  
FROM TB_PL_Reparo_Restante
WHERE dat_Referencia = '2023-05-18'
	AND cod_Origem = 1
	AND cod_Cluster BETWEEN 1 AND 13 
union 
SELECT cod_ID, dat_Referencia 
FROM TB_PL_Reparo_Encerrado
WHERE dat_Referencia = '2023-05-18'
	AND cod_Origem = 1
	AND cod_Cluster BETWEEN 1 AND 13 



-- cod_Cluster
-- cod_Origem
-- cod_Regional -- FROM TB_PL_Reparo_Restante 
-- ind_OutliersHoras -- FROM TB_PL_Reparo_Restante 
-- dat_Encerramento -- FROM TB_PL_Reparo_Entrante 
-- cod_Status -- FROM TB_PL_Reparo_Encerrado 