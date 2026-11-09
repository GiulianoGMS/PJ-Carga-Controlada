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
     AND X.GRUPO = psIndLojaMatriz;
  
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
