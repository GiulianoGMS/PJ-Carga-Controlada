CREATE OR REPLACE PROCEDURE NAGP_WTS_V2_ALERTAS_CARGA_PDV (
    psNroTelefone VARCHAR2,
    psAPIKey      VARCHAR2,
    psNroEmpresa  NUMBER
)
AS
    vnLixo VARCHAR2(4000);
    vText  VARCHAR2(4000);
    vUrl   VARCHAR2(32767);

BEGIN

    FOR X IN (
        SELECT X.EMPCARGA,
               X.STATUS,
               X.DTALOG,
               X.DTAPROCESSO,
               X.USUARIOLOG,
               X.TIPOCARGA_PDV,
               X.TIPOCARGA_BAL
          FROM NAGT_CONTROLE_CARGA_PDV X
         WHERE X.IND_PROCWTS IS NULL
           AND X.STATUS IN (1, 2)
           AND X.GRUPO = 'M'
           AND X.EMPCARGA = psNroEmpresa
         ORDER BY X.DTALOG
    )
    LOOP

        -- Montar mensagem
        vText :=
               CASE
                   WHEN X.STATUS = 1 THEN
                       '%E2%9C%85%20*Carga%20Gerada%20Com%20Sucesso!*'
                   WHEN X.STATUS = 2 THEN
                       '%E2%9D%8C%20*Carga%20Gerada%20com%20ERRO*'
               END
            || '%0A%0A'
            || '*Empresa:*%20' || X.EMPCARGA
            || '%0A'
            || '*Solicitante:*%20'
            || NVL(X.USUARIOLOG, 'NAO INFORMADO')
            || '%0A'
            || '*Carga PDV:*%20'
            || CASE
                   WHEN X.TIPOCARGA_PDV = 'S' THEN 'SIM'
                   WHEN X.TIPOCARGA_PDV = 'N' THEN 'NAO'
                   ELSE 'NAO INFORMADO'
               END
            || '%0A'
            || '*Carga Balanca:*%20'
            || CASE
                   WHEN X.TIPOCARGA_BAL = 'S' THEN 'SIM'
                   WHEN X.TIPOCARGA_BAL = 'N' THEN 'NAO'
                   ELSE 'NAO INFORMADO'
               END
            || '%0A'
            || '*Solicitado em:*%20'
            || TO_CHAR(X.DTALOG, 'DD/MM/YYYY HH24:MI:SS')
            || '%0A'
            || '*Processado em:*%20'
            || NVL(
                   TO_CHAR(X.DTAPROCESSO, 'DD/MM/YYYY HH24:MI:SS'),
                   'N/A'
               );

        -- Montar URL TextMeBot
        vUrl :=
               'http://api.textmebot.com/send.php?recipient=+'
            || psNroTelefone
            || '&text=' || vText
            || '&apikey=' || psAPIKey;

        -- Enviar WhatsApp
        SELECT UTL_HTTP.REQUEST(vUrl)
          INTO vnLixo
          FROM DUAL;

        -- Intervalo entre mensagens
        DBMS_SESSION.SLEEP(10);

    END LOOP;

END;
