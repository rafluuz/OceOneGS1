-- Rodar os códigos em blocos. Pois caso as funções/procedures sejam executadas juntas irá acarretar em erros. :)


-- Função para verificar se a tabela existe antes de deletar
SET SERVEROUTPUT ON;
DECLARE
    v_table_exists NUMBER;
BEGIN
    FOR cur_rec IN (SELECT table_name FROM user_tables WHERE table_name IN ('CAD_USER', 'LOGIN', 'PESSOA_J', 'PESSOA_F', 'RANKING', 'PREMIO', 'LOCALIZACAO', 'REPORTE_LIXO', 'LOG_ERROS')) LOOP
        BEGIN
            EXECUTE IMMEDIATE 'SELECT COUNT(*) FROM ' || cur_rec.table_name;
            v_table_exists := 1;
        EXCEPTION
            WHEN OTHERS THEN
                v_table_exists := 0;
        END;
        IF v_table_exists = 1 THEN
            EXECUTE IMMEDIATE 'DROP TABLE ' || cur_rec.table_name || ' CASCADE CONSTRAINTS';
        END IF;
    END LOOP;
END;

/

-- Função para verificar se as Sequences existem // O COMANDO ABAIXO SÓ VAI EXECUTAR SEM ERROS CASO AS SEQUENCES EXISTAM, POIS ELE É PARA APAGAR.
DECLARE
    v_sequence_exists NUMBER;
BEGIN
    SELECT COUNT(*) INTO v_sequence_exists
    FROM user_sequences
    WHERE sequence_name IN ('SEQ_CAD_USER', 'SEQ_LOGIN', 'SEQ_PESSOA_F', 'SEQ_PESSOA_J', 'SEQ_PREMIO', 'SEQ_LOCALIZACAO', 'SEQ_REPORTE_LIXO', 'SEQ_RANKING', 'LOG_ERROS_SEQ');

    IF v_sequence_exists > 0 THEN
        EXECUTE IMMEDIATE 'DROP SEQUENCE SEQ_CAD_USER';
        EXECUTE IMMEDIATE 'DROP SEQUENCE SEQ_LOGIN';
        EXECUTE IMMEDIATE 'DROP SEQUENCE SEQ_PESSOA_F';
        EXECUTE IMMEDIATE 'DROP SEQUENCE SEQ_PESSOA_J';
        EXECUTE IMMEDIATE 'DROP SEQUENCE SEQ_PREMIO';
        EXECUTE IMMEDIATE 'DROP SEQUENCE SEQ_LOCALIZACAO';
        EXECUTE IMMEDIATE 'DROP SEQUENCE SEQ_REPORTE_LIXO';
        EXECUTE IMMEDIATE 'DROP SEQUENCE SEQ_RANKING';
        EXECUTE IMMEDIATE 'DROP SEQUENCE LOG_ERROS_SEQ';
    END IF;
END;


/

-- Criando as Sequences
CREATE SEQUENCE seq_cad_user MINVALUE 1;
CREATE SEQUENCE seq_login MINVALUE 1;
CREATE SEQUENCE seq_pessoa_f MINVALUE 1;
CREATE SEQUENCE seq_pessoa_j MINVALUE 1;
CREATE SEQUENCE seq_premio MINVALUE 1;
CREATE SEQUENCE seq_localizacao MINVALUE 1;
CREATE SEQUENCE seq_reporte_lixo MINVALUE 1;
CREATE SEQUENCE seq_ranking MINVALUE 1;
CREATE SEQUENCE log_erros_seq START WITH 1;


/


-- Criando a tabela de log de erros
CREATE TABLE log_erros (
    log_id          NUMBER NOT NULL,
    procedure_name  VARCHAR2(100),
    error_date      TIMESTAMP,
    error_code      NUMBER,
    error_message   VARCHAR2(4000),
    CONSTRAINT log_erros_pk PRIMARY KEY (log_id)
);


-- Procedure da log
CREATE OR REPLACE PROCEDURE log_error (
    p_procedure_name  IN VARCHAR2,
    p_error_code      IN NUMBER,
    p_error_message   IN VARCHAR2
) AS
BEGIN
    INSERT INTO log_erros (log_id, procedure_name, error_date, error_code, error_message)
    VALUES (log_erros_seq.NEXTVAL, p_procedure_name, SYSTIMESTAMP, p_error_code, p_error_message);
    COMMIT;
END log_error;



/


--Criando das tabelas - via DataModeler (com algumas alterações para ficar de acordo com o projeto)
-- predefined type, no DDL - MDSYS.SDO_GEOMETRY

-- predefined type, no DDL - XMLTYPE
CREATE TABLE cad_user (
    id_cad_user    NUMBER(4) NOT NULL,
    nome_comp      VARCHAR2(100),
    telefone       NUMBER(11),
    email_cad      VARCHAR2(80),
    senha_cad      VARCHAR2(50)
);

ALTER TABLE cad_user ADD CONSTRAINT cad_user_pk PRIMARY KEY ( id_cad_user );



CREATE TABLE localizacao (
    id_loc                  NUMBER(4) NOT NULL,
    praia                   VARCHAR2(100),
    cidade                  VARCHAR2(100),
    estado                  VARCHAR2(100),
    pais                    VARCHAR2(100),
    latitude_atual          VARCHAR2(100),
    longitude_atual         VARCHAR2(100),
    reporte_lixo_id_reporte NUMBER NOT NULL
);

CREATE UNIQUE INDEX localizacao__idx ON
    localizacao (
        reporte_lixo_id_reporte
    ASC );

ALTER TABLE localizacao ADD CONSTRAINT localizacao_pk PRIMARY KEY ( id_loc );



CREATE TABLE login (
    id_login             NUMBER(4) NOT NULL,
    email_login          VARCHAR2(80),
    senha_login          VARCHAR2(50),
    data_hora_login      TIMESTAMP,
    data_logout          TIMESTAMP,
    cad_user_id_cad_user NUMBER(4) NOT NULL
);

CREATE UNIQUE INDEX login__idx ON
    login (
        cad_user_id_cad_user
    ASC );

ALTER TABLE login ADD CONSTRAINT login_pk PRIMARY KEY ( id_login );



CREATE TABLE pessoa_f (
    id_pf                NUMBER(4) NOT NULL,
    cpf                  CHAR(11),
    xp                   NUMBER(5),
    data_nasc            DATE,
    cad_user_id_cad_user NUMBER(4) NOT NULL
);

CREATE UNIQUE INDEX pessoa_fisica__idx ON
    pessoa_f (
        cad_user_id_cad_user
    ASC );

ALTER TABLE pessoa_f ADD CONSTRAINT pessoa_fisica_pk PRIMARY KEY ( id_pf );



CREATE TABLE pessoa_j (
    id_pj                NUMBER(4) NOT NULL,
    cnpj                 CHAR(14),
    qtd_lixo_coletado    NUMBER,
    data_coleta          DATE,
    cad_user_id_cad_user NUMBER(4) NOT NULL
);

CREATE UNIQUE INDEX pessoa_juridica__idx ON
    pessoa_j (
        cad_user_id_cad_user
    ASC );


ALTER TABLE pessoa_j ADD CONSTRAINT pessoa_juridica_pk PRIMARY KEY ( id_pj );



CREATE TABLE premio (
    id_premio        NUMBER(4) NOT NULL,
    xp_premio        NUMBER(5),
    descricao_premio VARCHAR2(100),
    produto          VARCHAR2(80),
    sku              VARCHAR2(80),
    hash_resgate     VARCHAR2(50),
    pessoa_f_id_pf   NUMBER NOT NULL
);

ALTER TABLE premio ADD CONSTRAINT premio_pk PRIMARY KEY ( id_premio );



CREATE TABLE ranking (
    id_ranking     NUMBER(4) NOT NULL,
    posicao        VARCHAR2(70),
    pessoa_j_id_pj NUMBER(4) NOT NULL
);

CREATE UNIQUE INDEX ranking__idx ON
    ranking (
        pessoa_j_id_pj
    ASC );

ALTER TABLE ranking ADD CONSTRAINT ranking_pk PRIMARY KEY ( id_ranking );



CREATE TABLE reporte_lixo (
    id_reporte         NUMBER(4) NOT NULL,
    qtd_lixo           NUMBER,
    descricao_reporte  VARCHAR2(100),
    data_hora_reporte  TIMESTAMP,
    pessoa_f_id_pf     NUMBER(4) NOT NULL
);


ALTER TABLE reporte_lixo ADD CONSTRAINT reporte_lixo_pk PRIMARY KEY ( id_reporte );




-- Chaves Estrangeiras
ALTER TABLE localizacao
    ADD CONSTRAINT localizacao_reporte_lixo_fk FOREIGN KEY ( reporte_lixo_id_reporte )
        REFERENCES reporte_lixo ( id_reporte );

ALTER TABLE login
    ADD CONSTRAINT login_cad_user_fk FOREIGN KEY ( cad_user_id_cad_user )
        REFERENCES cad_user ( id_cad_user );

ALTER TABLE pessoa_f
    ADD CONSTRAINT pessoa_f_cad_user_fk FOREIGN KEY ( cad_user_id_cad_user )
        REFERENCES cad_user ( id_cad_user );

ALTER TABLE pessoa_j
    ADD CONSTRAINT pessoa_j_cad_user_fk FOREIGN KEY ( cad_user_id_cad_user )
        REFERENCES cad_user ( id_cad_user );

ALTER TABLE premio
    ADD CONSTRAINT premio_pessoa_f_fk FOREIGN KEY ( pessoa_f_id_pf )
        REFERENCES pessoa_f ( id_pf );

ALTER TABLE ranking
    ADD CONSTRAINT ranking_pessoa_j_fk FOREIGN KEY ( pessoa_j_id_pj )
        REFERENCES pessoa_j ( id_pj );

ALTER TABLE reporte_lixo
    ADD CONSTRAINT reporte_lixo_pessoa_f_fk FOREIGN KEY ( pessoa_f_id_pf )
        REFERENCES pessoa_f ( id_pf );


/


-- Função para validar CPF
CREATE OR REPLACE FUNCTION validar_cpf(p_cpf IN VARCHAR2) RETURN BOOLEAN AS
BEGIN
    IF LENGTH(p_cpf) <> 11 THEN
        RETURN FALSE;
    END IF;
    
    FOR i IN 1..10 LOOP
        IF NOT REGEXP_LIKE(SUBSTR(p_cpf, i, 1), '^\d$') THEN
            RETURN FALSE;
        END IF;
    END LOOP;
    
    RETURN TRUE;
END validar_cpf;


/

-- Função para validar e-mail
CREATE OR REPLACE FUNCTION validar_email(p_email IN VARCHAR2) RETURN BOOLEAN AS
BEGIN
    IF NOT REGEXP_LIKE(p_email, '^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$') THEN
        RETURN FALSE;
    END IF;
    
    RETURN TRUE;
END validar_email;


/

-- Procedures para carga de dados nas tabelas
CREATE OR REPLACE PROCEDURE insert_cad_user (
    p_id_cad_user    IN cad_user.id_cad_user%TYPE,
    p_nome_comp      IN cad_user.nome_comp%TYPE,
    p_telefone       IN cad_user.telefone%TYPE,
    p_email_cad      IN cad_user.email_cad%TYPE,
    p_senha_cad      IN cad_user.senha_cad%TYPE
) AS
BEGIN
    INSERT INTO cad_user (id_cad_user, nome_comp, telefone, email_cad, senha_cad)
    VALUES (p_id_cad_user, p_nome_comp, p_telefone, p_email_cad, p_senha_cad);
EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
        log_error('insert_cad_user', SQLCODE, SQLERRM);
        RAISE;
    WHEN VALUE_ERROR THEN
        log_error('insert_cad_user', SQLCODE, SQLERRM);
        RAISE;
    WHEN OTHERS THEN
        log_error('insert_cad_user', SQLCODE, SQLERRM);
        RAISE;
END insert_cad_user;

/

CREATE OR REPLACE PROCEDURE insert_login (
    p_id_login             IN login.id_login%TYPE,
    p_email_login          IN login.email_login%TYPE,
    p_senha_login          IN login.senha_login%TYPE,
    p_data_hora_login      IN login.data_hora_login%TYPE,
    p_data_logout          IN login.data_logout%TYPE,
    p_cad_user_id_cad_user IN login.cad_user_id_cad_user%TYPE
) AS
BEGIN
    INSERT INTO login (id_login, email_login, senha_login, data_hora_login, data_logout, cad_user_id_cad_user)
    VALUES (p_id_login, p_email_login, p_senha_login, p_data_hora_login, p_data_logout, p_cad_user_id_cad_user);
EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
        log_error('insert_login', SQLCODE, SQLERRM);
        RAISE;
    WHEN VALUE_ERROR THEN
        log_error('insert_login', SQLCODE, SQLERRM);
        RAISE;
    WHEN OTHERS THEN
        log_error('insert_login', SQLCODE, SQLERRM);
        RAISE;
END insert_login;

/

CREATE OR REPLACE PROCEDURE insert_pessoa_f (
    p_id_pf                IN pessoa_f.id_pf%TYPE,
    p_cpf                  IN pessoa_f.cpf%TYPE,
    p_xp                   IN pessoa_f.xp%TYPE,
    p_data_nasc            IN pessoa_f.data_nasc%TYPE,
    p_cad_user_id_cad_user IN pessoa_f.cad_user_id_cad_user%TYPE
) AS
BEGIN
    INSERT INTO pessoa_f (id_pf, cpf, xp, data_nasc, cad_user_id_cad_user)
    VALUES (p_id_pf, p_cpf, p_xp, p_data_nasc, p_cad_user_id_cad_user);
EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
        log_error('insert_pessoa_f', SQLCODE, SQLERRM);
        RAISE;
    WHEN VALUE_ERROR THEN
        log_error('insert_pessoa_f', SQLCODE, SQLERRM);
        RAISE;
    WHEN OTHERS THEN
        log_error('insert_pessoa_f', SQLCODE, SQLERRM);
        RAISE;
END insert_pessoa_f;

/

CREATE OR REPLACE PROCEDURE insert_pessoa_j (
    p_id_pj                IN pessoa_j.id_pj%TYPE,
    p_cnpj                 IN pessoa_j.cnpj%TYPE,
    p_qtd_lixo_coletado    IN pessoa_j.qtd_lixo_coletado%TYPE,
    p_data_coleta          IN pessoa_j.data_coleta%TYPE,
    p_cad_user_id_cad_user IN pessoa_j.cad_user_id_cad_user%TYPE
) AS
BEGIN
    INSERT INTO pessoa_j (id_pj, cnpj, qtd_lixo_coletado, data_coleta, cad_user_id_cad_user)
    VALUES (p_id_pj, p_cnpj, p_qtd_lixo_coletado, p_data_coleta, p_cad_user_id_cad_user);
EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
        log_error('insert_pessoa_j', SQLCODE, SQLERRM);
        RAISE;
    WHEN VALUE_ERROR THEN
        log_error('insert_pessoa_j', SQLCODE, SQLERRM);
        RAISE;
    WHEN OTHERS THEN
        log_error('insert_pessoa_j', SQLCODE, SQLERRM);
        RAISE;
END insert_pessoa_j;

/

CREATE OR REPLACE PROCEDURE insert_premio (
    p_id_premio        IN premio.id_premio%TYPE,
    p_xp_premio        IN premio.xp_premio%TYPE,
    p_descricao_premio IN premio.descricao_premio%TYPE,
    p_produto          IN premio.produto%TYPE,
    p_sku              IN premio.sku%TYPE,
    p_hash_resgate     IN premio.hash_resgate%TYPE,
    p_pessoa_f_id_pf   IN premio.pessoa_f_id_pf%TYPE
) AS
BEGIN
    INSERT INTO premio (id_premio, xp_premio, descricao_premio, produto, sku, hash_resgate, pessoa_f_id_pf)
    VALUES (p_id_premio, p_xp_premio, p_descricao_premio, p_produto, p_sku, p_hash_resgate, p_pessoa_f_id_pf);
EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
        log_error('insert_premio', SQLCODE, SQLERRM);
        RAISE;
    WHEN VALUE_ERROR THEN
        log_error('insert_premio', SQLCODE, SQLERRM);
        RAISE;
    WHEN OTHERS THEN
        log_error('insert_premio', SQLCODE, SQLERRM);
        RAISE;
END insert_premio;

/

CREATE OR REPLACE PROCEDURE insert_ranking (
    p_id_ranking     IN ranking.id_ranking%TYPE,
    p_posicao        IN ranking.posicao%TYPE,
    p_pessoa_j_id_pj IN ranking.pessoa_j_id_pj%TYPE
) AS
BEGIN
    INSERT INTO ranking (id_ranking, posicao, pessoa_j_id_pj)
    VALUES (p_id_ranking, p_posicao, p_pessoa_j_id_pj);
EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
        log_error('insert_ranking', SQLCODE, SQLERRM);
        RAISE;
    WHEN VALUE_ERROR THEN
        log_error('insert_ranking', SQLCODE, SQLERRM);
        RAISE;
    WHEN OTHERS THEN
        log_error('insert_ranking', SQLCODE, SQLERRM);
        RAISE;
END insert_ranking;

/

CREATE OR REPLACE PROCEDURE insert_reporte_lixo (
    p_id_reporte        IN reporte_lixo.id_reporte%TYPE,
    p_qtd_lixo          IN reporte_lixo.qtd_lixo%TYPE,
    p_descricao_reporte IN reporte_lixo.descricao_reporte%TYPE,
    p_data_hora_reporte IN reporte_lixo.data_hora_reporte%TYPE,
    p_pessoa_f_id_pf    IN reporte_lixo.pessoa_f_id_pf%TYPE
) AS
BEGIN
    INSERT INTO reporte_lixo (id_reporte, qtd_lixo, descricao_reporte, data_hora_reporte, pessoa_f_id_pf)
    VALUES (p_id_reporte, p_qtd_lixo, p_descricao_reporte, p_data_hora_reporte, p_pessoa_f_id_pf);
EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
        log_error('insert_reporte_lixo', SQLCODE, SQLERRM);
        RAISE;
    WHEN VALUE_ERROR THEN
        log_error('insert_reporte_lixo', SQLCODE, SQLERRM);
        RAISE;
    WHEN OTHERS THEN
        log_error('insert_reporte_lixo', SQLCODE, SQLERRM);
        RAISE;
END insert_reporte_lixo;

/

CREATE OR REPLACE PROCEDURE insert_localizacao (
    p_id_loc                  IN localizacao.id_loc%TYPE,
    p_praia                   IN localizacao.praia%TYPE,
    p_cidade                  IN localizacao.cidade%TYPE,
    p_estado                  IN localizacao.estado%TYPE,
    p_pais                    IN localizacao.pais%TYPE,
    p_latitude_atual          IN localizacao.latitude_atual%TYPE,
    p_longitude_atual         IN localizacao.longitude_atual%TYPE,
    p_reporte_lixo_id_reporte IN localizacao.reporte_lixo_id_reporte%TYPE
) AS
BEGIN
    INSERT INTO localizacao (id_loc, praia, cidade, estado, pais, latitude_atual, longitude_atual, reporte_lixo_id_reporte)
    VALUES (p_id_loc, p_praia, p_cidade, p_estado, p_pais, p_latitude_atual, p_longitude_atual, p_reporte_lixo_id_reporte);
EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
        log_error('insert_localizacao', SQLCODE, SQLERRM);
        RAISE;
    WHEN VALUE_ERROR THEN
        log_error('insert_localizacao', SQLCODE, SQLERRM);
        RAISE;
    WHEN OTHERS THEN
        log_error('insert_localizacao', SQLCODE, SQLERRM);
        RAISE;
END insert_localizacao;

/


-- Chamadas das procedures
BEGIN
    insert_cad_user(seq_cad_user.nextval, 'Mario Silca', 1234467890, 'mario.silca@example.com', 'senha123');
    insert_cad_user(seq_cad_user.nextval, 'Maria Souza', 9876543210, 'maria.souza@example.com', 'senha456');
    insert_cad_user(seq_cad_user.nextval, 'Carlos Oliveira', 1122334455, 'carlos.oliveira@example.com', 'senha789');
    insert_cad_user(seq_cad_user.nextval, 'Ana Rodrigues', 9988776655, 'ana.rodrigues@example.com', 'senha246');
    insert_cad_user(seq_cad_user.nextval, 'Pedro Almeida', 9988776655, 'pedro.almeida@example.com', 'senha135');
    
    insert_login(seq_login.nextval, 'mario.silca@example.com', 'senha123', SYSTIMESTAMP, NULL, 1);
    insert_login(seq_login.nextval, 'maria.souza@example.com', 'senha456', SYSTIMESTAMP, NULL, 2);
    insert_login(seq_login.nextval, 'carlos.oliveira@example.com', 'senha789', SYSTIMESTAMP, NULL, 3);
    insert_login(seq_login.nextval, 'ana.rodrigues@example.com', 'senha246', SYSTIMESTAMP, NULL, 4);
    insert_login(seq_login.nextval, 'pedro.almeida@example.com', 'senha135', SYSTIMESTAMP, NULL, 5);
    
    insert_pessoa_f(seq_pessoa_f.nextval, '12345678901', 100, TO_DATE('1990-01-15', 'YYYY-MM-DD'), 1);
    insert_pessoa_f(seq_pessoa_f.nextval, '45668795446', 95, TO_DATE('2005-05-05', 'YYYY-MM-DD'), 2);
    insert_pessoa_f(seq_pessoa_f.nextval, '78901234567', 110, TO_DATE('1985-10-20', 'YYYY-MM-DD'), 3);
    insert_pessoa_f(seq_pessoa_f.nextval, '23456789012', 80, TO_DATE('1978-03-12', 'YYYY-MM-DD'), 4);
    insert_pessoa_f(seq_pessoa_f.nextval, '89012345678', 105, TO_DATE('2000-12-30', 'YYYY-MM-DD'), 5);
    
    insert_pessoa_j(seq_pessoa_j.nextval, '98765432109', 15, TO_DATE('2003-05-22', 'YYYY-MM-DD'), 3);
    insert_pessoa_j(seq_pessoa_j.nextval, '65432109876', 20, TO_DATE('2000-11-10', 'YYYY-MM-DD'), 4);
    insert_pessoa_j(seq_pessoa_j.nextval, '32109876543', 10, TO_DATE('2005-08-18', 'YYYY-MM-DD'), 5);
    insert_pessoa_j(seq_pessoa_j.nextval, '01234567890', 25, TO_DATE('1998-04-25', 'YYYY-MM-DD'), 1);
    insert_pessoa_j(seq_pessoa_j.nextval, '78901234567', 30, TO_DATE('2008-09-05', 'YYYY-MM-DD'), 2);
    
    insert_premio(seq_premio.nextval, 100, 'Vale-presente', 'Livro', 'SKU123', 'hash123', 1);
    insert_premio(seq_premio.nextval, 150, 'Voucher de restaurante', 'Refeiï¿½ï¿½o', 'SKU456', 'hash456', 2);
    insert_premio(seq_premio.nextval, 200, 'Ingresso de cinema', 'Entretenimento', 'SKU789', 'hash789', 3);
    insert_premio(seq_premio.nextval, 120, 'Cartão-presente', 'Loja', 'SKU101', 'hash101', 4);
    insert_premio(seq_premio.nextval, 180, 'Vale-combustível', 'Combustível', 'SKU202', 'hash202', 5);
    
    insert_ranking(seq_ranking.nextval, '1º lugar', 3);
    insert_ranking(seq_ranking.nextval, '2º lugar', 4);
    insert_ranking(seq_ranking.nextval, '3º lugar', 5);
    insert_ranking(seq_ranking.nextval, '4º lugar', 1);
    insert_ranking(seq_ranking.nextval, '5º lugar', 2);
    
    insert_reporte_lixo(seq_reporte_lixo.nextval, 10, 'Lixo na praia', SYSTIMESTAMP, 1);
    insert_reporte_lixo(seq_reporte_lixo.nextval, 15, 'Resíduos plásticos no rio', SYSTIMESTAMP, 2);
    insert_reporte_lixo(seq_reporte_lixo.nextval, 20, 'Descarte irregular de lixo', SYSTIMESTAMP, 3);
    insert_reporte_lixo(seq_reporte_lixo.nextval, 8, 'Poluição na praia', SYSTIMESTAMP, 4);
    insert_reporte_lixo(seq_reporte_lixo.nextval, 12, 'Lixo acumulado nas ruas', SYSTIMESTAMP, 5);
    
    insert_localizacao(seq_localizacao.nextval , 'Copacabana', 'Rio de Janeiro', 'Rio de Janeiro', 'Brasil', '-22.971389', '-43.182778', 1);
    insert_localizacao(seq_localizacao.nextval , 'Ipanema', 'Rio de Janeiro', 'Rio de Janeiro', 'Brasil', '-22.9836', '-43.2047', 2);
    insert_localizacao(seq_localizacao.nextval , 'Leblon', 'Rio de Janeiro', 'Rio de Janeiro', 'Brasil', '-22.9838', '-43.2246', 3);
    insert_localizacao(seq_localizacao.nextval , 'Barra da Tijuca', 'Rio de Janeiro', 'Rio de Janeiro', 'Brasil', '-23.0121', '-43.3169', 4);
    insert_localizacao(seq_localizacao.nextval , 'Santa Teresa', 'Rio de Janeiro', 'Rio de Janeiro', 'Brasil', '-22.9176', '-43.1917', 5);
END;


/



-- Blocos Anônimos para Relatório de Dados das Tabelas
--CADASTRO USUÁRIO
DECLARE
    CURSOR cur_cad_user IS
        SELECT id_cad_user, nome_comp, telefone, email_cad, senha_cad
        FROM cad_user;
    v_total_cad_user NUMBER := 0;
    v_total_per_estado NUMBER := 0;
    v_current_estado VARCHAR2(100);
BEGIN
    DBMS_OUTPUT.PUT_LINE('ID_CAD_USER | NOME_COMP     | TELEFONE     | EMAIL_CAD        | SENHA_CAD');
    DBMS_OUTPUT.PUT_LINE('-------------------------------------------------------------------');

    FOR rec IN cur_cad_user LOOP
        DBMS_OUTPUT.PUT_LINE(rec.id_cad_user || ' | ' || rec.nome_comp || ' | ' || rec.telefone || ' | ' || rec.email_cad || ' | ' || rec.senha_cad);
        v_total_cad_user := v_total_cad_user + 1;
        IF v_current_estado IS NULL OR SUBSTR(rec.email_cad, INSTR(rec.email_cad, '@') + 1) <> v_current_estado THEN
            IF v_current_estado IS NOT NULL THEN
                DBMS_OUTPUT.PUT_LINE('Sub-Total for ' || v_current_estado || ': ' || v_total_per_estado);
            END IF;
            v_current_estado := SUBSTR(rec.email_cad, INSTR(rec.email_cad, '@') + 1);
            v_total_per_estado := 1;
        ELSE
            v_total_per_estado := v_total_per_estado + 1;
        END IF;
    END LOOP;
    DBMS_OUTPUT.PUT_LINE('Sub-Total for ' || v_current_estado || ': ' || v_total_per_estado);
    DBMS_OUTPUT.PUT_LINE('Total Geral: ' || v_total_cad_user);
END;

/

-- PESSOA JURÍDICA
DECLARE
    CURSOR cur_pessoa_j IS
        SELECT id_pj, cnpj, qtd_lixo_coletado, data_coleta, cad_user_id_cad_user FROM pessoa_j;
    v_total_pessoa_j NUMBER := 0;
    v_total_per_quantidade NUMBER := 0;
    v_current_quantidade VARCHAR2(20);
BEGIN
    DBMS_OUTPUT.PUT_LINE('ID_PJ | CNPJ           | QTD_LIXO_COLETADO | DATA_COLETA   | CAD_USER_ID_CAD_USER');
    DBMS_OUTPUT.PUT_LINE('--------------------------------------------------------------------------');

    FOR rec IN cur_pessoa_j LOOP
        DBMS_OUTPUT.PUT_LINE(rec.id_pj || ' | ' || rec.cnpj || ' | ' || rec.qtd_lixo_coletado || ' | ' || rec.data_coleta || ' | ' || rec.cad_user_id_cad_user);
        v_total_pessoa_j := v_total_pessoa_j + 1;
        IF v_current_quantidade IS NULL OR rec.qtd_lixo_coletado <> TO_NUMBER(v_current_quantidade) THEN
            IF v_current_quantidade IS NOT NULL THEN
                DBMS_OUTPUT.PUT_LINE('Sub-Total for Qtd. ' || v_current_quantidade || ': ' || v_total_per_quantidade);
            END IF;
            v_current_quantidade := rec.qtd_lixo_coletado;
            v_total_per_quantidade := 1;
        ELSE
            v_total_per_quantidade := v_total_per_quantidade + 1;
        END IF;
    END LOOP;
    DBMS_OUTPUT.PUT_LINE('Sub-Total for Qtd. ' || v_current_quantidade || ': ' || v_total_per_quantidade);
    DBMS_OUTPUT.PUT_LINE('Total Geral: ' || v_total_pessoa_j);
END;

/

-- REPORTE LIXO
DECLARE
    CURSOR c_reporte_lixo IS
        SELECT id_reporte, qtd_lixo, descricao_reporte, data_hora_reporte, pessoa_f_id_pf
        FROM reporte_lixo;

    v_id_reporte        reporte_lixo.id_reporte%TYPE;
    v_qtd_lixo          reporte_lixo.qtd_lixo%TYPE;
    v_descricao_reporte reporte_lixo.descricao_reporte%TYPE;
    v_data_hora_reporte reporte_lixo.data_hora_reporte%TYPE;
    v_pessoa_f_id_pf    reporte_lixo.pessoa_f_id_pf%TYPE;
    v_total_lixo        NUMBER := 0;
    v_subtotal_lixo     NUMBER := 0;
    v_current_pf_id     NUMBER := 0;

BEGIN
    DBMS_OUTPUT.PUT_LINE('Relatório de Reportes de Lixo:');
    DBMS_OUTPUT.PUT_LINE('ID_REPORTE | QTD_LIXO | DESCRICAO_REPORTE | DATA_HORA_REPORTE | PESSOA_F_ID_PF');
    DBMS_OUTPUT.PUT_LINE('---------------------------------------------------------------');

    OPEN c_reporte_lixo;
    LOOP
        FETCH c_reporte_lixo INTO v_id_reporte, v_qtd_lixo, v_descricao_reporte, v_data_hora_reporte, v_pessoa_f_id_pf;
        EXIT WHEN c_reporte_lixo%NOTFOUND;

        IF v_current_pf_id != v_pessoa_f_id_pf THEN
            IF v_current_pf_id != 0 THEN
                DBMS_OUTPUT.PUT_LINE('Subtotal para PESSOA_F_ID_PF ' || v_current_pf_id || ': ' || v_subtotal_lixo);
                v_subtotal_lixo := 0;
            END IF;
            v_current_pf_id := v_pessoa_f_id_pf;
        END IF;

        DBMS_OUTPUT.PUT_LINE(v_id_reporte || ' | ' || v_qtd_lixo || ' | ' || v_descricao_reporte || ' | ' || v_data_hora_reporte || ' | ' || v_pessoa_f_id_pf);
        
        v_total_lixo := v_total_lixo + v_qtd_lixo;
        v_subtotal_lixo := v_subtotal_lixo + v_qtd_lixo;
    END LOOP;

    DBMS_OUTPUT.PUT_LINE('Subtotal para PESSOA_F_ID_PF ' || v_current_pf_id || ': ' || v_subtotal_lixo);
    DBMS_OUTPUT.PUT_LINE('Total Geral: ' || v_total_lixo);

    CLOSE c_reporte_lixo;
END;

/


-- LOGIN
DECLARE
    CURSOR c_login_sumarizado IS
        SELECT email_login, COUNT(*) AS total_registros
        FROM login
        GROUP BY email_login;
    v_subtotal NUMBER := 0;
    v_total    NUMBER := 0;
BEGIN
    DBMS_OUTPUT.PUT_LINE('- Email_Login Total_Registros');
    FOR rec IN c_login_sumarizado LOOP
        IF rec.email_login IS NOT NULL THEN
            IF v_subtotal > 0 THEN
                DBMS_OUTPUT.PUT_LINE(' ');
                v_total := v_total + v_subtotal;
                v_subtotal := 0;
            END IF;
            DBMS_OUTPUT.PUT_LINE(rec.email_login || ' ' || rec.total_registros);
            v_subtotal := v_subtotal + rec.total_registros;
        END IF;
    END LOOP;
    DBMS_OUTPUT.PUT_LINE('- Sub-Total');
    DBMS_OUTPUT.PUT_LINE('?');
    v_total := v_total + v_subtotal;
    DBMS_OUTPUT.PUT_LINE('- Total Geral');
    DBMS_OUTPUT.PUT_LINE(' ' || v_total);
END;