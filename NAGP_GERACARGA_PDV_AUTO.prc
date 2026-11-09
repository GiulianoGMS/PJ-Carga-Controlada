CREATE OR REPLACE PROCEDURE NAGP_GERACARGA_PDV_AUTO IS

  psTipoCargaPDV VARCHAR2(1);
  psTipoCargaBal VARCHAR2(1);
  psSeqProcesso  NUMBER(10);

BEGIN
  
 FOR empCarga IN (

  SELECT MAX(EMPCARGA) NROEMPRESA, MIN(X.TIPOCARGA_PDV) CARGAPDV, MIN(X.TIPOCARGA_BAL) CARGABAL
    FROM NAGT_CONTROLE_CARGA_PDV X INNER JOIN NAGT_EMP_ESPECIAL EMP ON EMP.NROEMPRESA = X.EMPCARGA -- Filtra apenas as lojas específicas neste join
   WHERE X.STATUS = 0
     AND X.GRUPO = 'M' -- Matriz, e existe no abaixo (+loja)
     AND EXISTS (SELECT 1 FROM NAGT_CONTROLE_CARGA_PDV L WHERE L.EMPCARGA = X.EMPCARGA AND L.STATUS = 0 AND L.GRUPO = 'L'))
     
     LOOP
       
     IF empCarga.Cargapdv = 'S' THEN
        psTipoCargaPDV := 'P'; ELSE psTipoCargaPDV := 'N';
     END IF;
     IF empCarga.Cargabal = 'S' THEN
        psTipoCargaBal := 'P'; ELSE psTipoCargaBal := 'N';
     END IF;
       
     BEGIN -- Abre bloco para gravar erro, caso ocorra
        
        SELECT NAGS_SEQ_CARGAPDV.NEXTVAL 
          INTO psSeqProcesso
          FROM DUAL;
          
      -- SPMRL_CARGALST_V3(empCarga.NROEMPRESA, psTipoCargaPDV, psTipoCargaBal); -- Loja
     --  NAGP_CARGA_PRECO_ECOMM_MANUAL(empCarga.NROEMPRESA);                           -- Ecommerce
     
     UPDATE NAGT_CONTROLE_CARGA_PDV X SET X.STATUS = 1, 
                                          X.DTAPROCESSO = SYSDATE,
                                          X.SEQPROCESSO = psSeqProcesso
                                    WHERE X.EMPCARGA = empCarga.Nroempresa
                                      AND X.STATUs = 0;
     EXCEPTION
      WHEN OTHERS THEN

        UPDATE NAGT_CONTROLE_CARGA_PDV X
           SET X.STATUS = 2,
               X.DTAPROCESSO = SYSDATE,
               X.SEQPROCESSO = psSeqProcesso
         WHERE X.EMPCARGA = empCarga.NROEMPRESA
           AND X.STATUS = 0;
     END;
     
     psTipoCargaPDV := NULL;
     psTipoCargaBal := NULL;
     
     COMMIT;
     
     END LOOP;
     
 END;
  
    
  
  
