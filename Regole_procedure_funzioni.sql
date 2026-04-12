# Regola per utenti solo maggiorenni
ALTER TABLE utenti
ADD CHECK (eta >=18);

# Regola per fare in modo che l'id utente si possa registrare solo con p.iva(11 caratteri) o con codice fiscale(16 caratteri)
ALTER TABLE utenti
ADD CONSTRAINT chk_registrazione CHECK (length(id_utente) = 11 OR length(id_utente) = 16);

# Regola se lenght = 16 (CF) la categoria deve essere obbligatoriamente acquisto
ALTER TABLE utenti
ADD CONSTRAINT chk_privato_solo_acquisto CHECK ((length(id_utente) = 16 AND categoria = 'acquisto') OR (length(id_utente) = 11) AND categoria IN ('acquisto', 'vendita'));

# Regola se l'utente è privato l'agevolazione è 0
ALTER TABLE clienti
ADD CONSTRAINT chk_agevolazione_privato CHECK (tipologia_clienti = 'privato' AND agevolazione = 0 OR tipologia_clienti = 'azienda');

CREATE VIEW storico_acquisti AS
SELECT ordine.data_ordine, ordine.id_ordine, ordine.sconto_applicato, utenti.NOME_UTENTE, clienti.tipologia_clienti, clienti.Agevolazione, prodotti.nome, prodotti.marca
FROM prodotti 
	join annuncio on prodotti.ID_PRODOTTI= annuncio.ID_PRODOTTI
    join ordine on ordine.id_ordine = annuncio.ID_ORDINE
    join clienti on clienti.ID_UTENTE = ordine.ID_UTENTE
    join utenti on utenti.ID_UTENTE = clienti.ID_UTENTE;
    
# Funzione per calcolare il prezzo totale
DELIMITER //
CREATE FUNCTION Totale_Ordine(prezzo_partenza DOUBLE, sconto INT, quantita INT) RETURNS DOUBLE
DETERMINISTIC
BEGIN
	SET @prezzoscontato=(prezzo_partenza-(prezzo_partenza * sconto/100));
	RETURN ROUND((@prezzoscontato * quantita),2);
END    
// DELIMITER ; 

SELECT Totale_Ordine(3.5,25,2) as Totale_Ordine;
    
SELECT Totale_Ordine(annuncio.prezzo_originale, ordine.sconto_applicato, annuncio.quantita) AS Prezzo_finale
FROM annuncio JOIN ordine ON annuncio.id_ordine = ordine.id_ordine;

CREATE VIEW catalogo_annuncio AS
SELECT annuncio.id_annuncio,
	   annuncio.data_annuncio,
	   utenti.nome_utente,
       prodotti.nome,
       prodotti.marca,
       annuncio.quantita,
       annuncio.data_scadenza,
       annuncio.prezzo_originale,
       totale_ordine(annuncio.prezzo_originale, ordine.sconto_applicato, annuncio.quantita) AS prezzo_finale
FROM prodotti 
JOIN annuncio
	ON prodotti.id_prodotti = annuncio.id_prodotti
JOIN attivita_vendita
	ON attivita_vendita.id_utente = annuncio.id_utente
JOIN utenti 
	ON utenti.id_utente = attivita_vendita.id_utente
JOIN ordine
	ON annuncio.id_ordine = ordine.id_ordine


# PROCEDURA CHE AGGIUNGE UN UTENTE NUOVO    
DELIMITER //
CREATE PROCEDURE Aggiungi_Utente(IN ID_UTENT varchar(105), IN NOME_UTENT VARCHAR(105), IN ET int, IN CATEGORI VARCHAR(105), IN  tipologi VARCHAR(105), IN agevolazion TINYINT)
BEGIN 
	SET @verificautente = (SELECT ID_UTENTE from utenti WHERE ID_UTENTE = ID_UTENT);
    IF @verificautente IS NOT NULL THEN SELECT "Utente già registrato";
    ELSE INSERT INTO utenti ( id_utente, nome_utente, eta, categoria) VALUES (id_utent, nome_utent, et, categori);
    END IF;
    SET @verificacategoria = (SELECT Categoria FROM utenti WHERE ID_UTENTE = ID_UTENT);
    IF @verificacategoria = "Vendita" THEN insert into attivita_vendita( id_utente, tipologia_vendita) VALUES (id_utent, tipologi);
    ELSEIF @verificacategoria = "Acquisto" THEN INSERT INTO clienti(id_utente, tipologia_clienti, agevolazione) VALUES (id_utent, tipologi, agevolazion);
	ELSE SELECT "Non esiste questa categoria";
    END IF; 
    END    
// DELIMITER ;

CALL Aggiungi_Utente("ZNNMCH92F16H501T","SARA PACE",19,"acquisto","privato",0);

