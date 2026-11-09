-- Tabela de Controle 

CREATE TABLE NAGT_CONTROLE_CARGA_PDV (DTALOG DATE, USUARIOLOG VARCHAR2(4000), EMPUSUARIO NUMBER(3), EMPCARGA NUMBER(3), GRUPO VARCHAR2(10), TIPOCARGA_PDV VARCHAR2(1), TIPOCARGA_BAL VARCHAR2(1), STATUS NUMBER(3), DTAPROCESSO DATE, SEQPROCESSO NUMBER(10));

-- Sequencial para processo futuro

CREATE SEQUENCE NAGS_SEQ_CARGAPDV
START WITH 0
INCREMENT BY 1
MINVALUE 0
NOCACHE
NOCYCLE;

-- Tabela  com de/para de empresas

CREATE TABLE NAGT_EMP_ESPECIAL (NROEMPRESA NUMBER(3));

-- Proc de gravação de envio de solicitacao/start da carga

CREATE OR REPLACE PROCEDURE NAGP_CONTROLE_CARGA_PDV (psLojaCarga VARCHAR2, psTipoCargaPDV VARCHAR2, psTipoCargaBAL VARCHAR2) IS

   -- Versao LOJA   psLojaCarga := 0, psTipoCargaPDV := X, psTipoCargaBAL := X
   -- Versao MATRIZ psLojaCarga := :LS1, psTipoCargaPDV := :LS2, psTipoCargaBAL := :LS3

   psNroEmpresaUsuario NUMBER(3);
   psIndExisteCargaPendente NUMBER(10);
   psIndLojaMatriz VARCHAR2(10);
   psCodUsuario VARCHAR2(4000);
   psEmpCarga NUMBER(3);
   
   pdTipoCargaPDV VARCHAR2(1);
   pdTipoCargaBAL VARCHAR2(1);

BEGIN
  
  -- Descobre o usuario
  SELECT NVL(SYS_CONTEXT ('USERENV','CLIENT_IDENTIFIER'), 'CONSINCO')
    INTO psCodUsuario
    FROM DUAL;
  
  --Descobre a empresa do usuario
  SELECT MAX(NROEMPRESA), CASE WHEN MAX(NROEMPRESA) < 500 THEN 'L' ELSE 'M' END
    INTO psNroEmpresaUsuario, psIndLojaMatriz
    FROM GE_USUARIO G 
   WHERE G.CODUSUARIO = psCodUsuario;
  
  IF psNroEmpresaUsuario IS NOT NULL THEN -- Se encontrou segue
    
  SELECT COUNT(1) -- Valida se nao foi solicitado carga anteriormente e que ainda nao foi processada, para nao duplicar comando
    INTO psIndExisteCargaPendente
    FROM NAGT_CONTROLE_CARGA_PDV X 
   WHERE X.EMPUSUARIO = psNroEmpresaUsuario
     AND X.GRUPO = psIndLojaMatriz
     AND X.STATUS = 0;
  
  IF psIndExisteCargaPendente = 0 THEN -- Se 0 segue
    
  -- Trata loja de carga
  IF psLojaCarga = '999' THEN
     psEmpCarga := psNroEmpresaUsuario;
  ELSE 
     psEmpCarga := psLojaCarga;
  END IF;
  
  -- Trata tipo de cargas
  IF psTipoCargaPDV = 'Sim' THEN
          pdTipoCargaPDV := 'S';
     ELSE pdTipoCargaPDV := 'N';
     
  END IF;
  
  IF psTipoCargaBAL = 'Sim' THEN
          pdTipoCargaBAL := 'S';
     ELSE pdTipoCargaBAL := 'N';
  END IF;
  
  -- Faz o insert do start
     INSERT INTO NAGT_CONTROLE_CARGA_PDV (DTALOG,
                                          USUARIOLOG,
                                          EMPUSUARIO,
                                          EMPCARGA,
                                          GRUPO,
                                          TIPOCARGA_PDV,
                                          TIPOCARGA_BAL,
                                          STATUS,
                                          DTAPROCESSO, SEQPROCESSO)
                                          
           VALUES (SYSDATE, psCodUsuario, psNroEmpresaUsuario, psEmpCarga, psIndLojaMatriz, pdTipoCargaPDV, pdTipoCargaBAL, 0, NULL, NULL);
  
  COMMIT;
  
  END IF;
  END IF;
  
END;



-- Rotina de geracao de carga

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
 
-- Chamada nas duas Querys (Matriz/Loja)
-- Matriz:

SELECT 1 A FROM DUAL;
EXECUTE NAGP_CONTROLE_CARGA_PDV(#LS1, #LS2, #LS3);

SELECT 'Carga solicitada com sucesso!' STATUS FROM DUAL
  
-- Lojas (Usuario nao seleciona a loja, é validado  pelo cadastro

SELECT 1 A FROM DUAL;
EXECUTE NAGP_CONTROLE_CARGA_PDV('999', 'X', 'X');

SELECT 'Carga solicitada com sucesso!' STATUS FROM DUAL

-- Chamada do Job

BEGIN
  NAGP_GERACARGA_PDV_AUTO;
  END;
 
  
  
