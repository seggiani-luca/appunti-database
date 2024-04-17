-- 1) Indicare l’incasso totale degli ultimi due anni, realizzato grazie alle visite dei medici cardiologi della clinica
SELECT SUM(M.Parcella) AS IncassoTotale
FROM Visita V
INNER JOIN Medico M ON V.Medico = M.Matricola
WHERE V.Data > CURRENT_DATE - INTERVAL 2 YEAR
  AND M.Specializzazione = 'Cardiologia'

-- con subquery:
SELECT SUM(M.Parcella) AS IncassoTotale --ERRORE: Chi è M?
FROM Visita V
WHERE V.Medico IN (
                  SELECT M.Matricola, M.Parcella
                  FROM Medico M
                  WHERE M.Specializzazione = 'Cardiologia'
                  )
  AND V.Data > CURRENT_DATE - INTERVAL 2 YEAR

SELECT SUM(M.Parcella) AS IncassoTotale --ERRORE: ogni M compare una volta sola (e non una per ogni visita)
FROM Medico M
WHERE M.Matricola IN  (
                      SELECT V.Medico
                      FROM Visita V
                      WHERE V.Data > CURRENT_DATE - INTERVAL 2 YEAR
                      )
  AND M.Specializzazione = 'Cardiologia'

SELECT SUM(M1.Parcella) AS IncassoTotale --ERRORE: uguale a prima, solo hai fatto una piroetta prima di spararti in un piede
FROM Medico M1
WHERE M1.Matricola IN (
  SELECT V.Medico
  FROM Visita V
  WHERE V.Medico IN (
    SELECT M.Matricola
    FROM Medico M
    WHERE M.Specializzazione = 'Cardiologia'
  ) AND V.Data > CURRENT_DATE - INTERVAL 2 YEAR
)

/* FORSE QUESTA? */
SELECT SUM((
  SELECT M.Parcella
  FROM Medico M
  WHERE M.Matricola = V.Medico
     AND M.Specializzazione = 'Cardiologia'
)) AS IncassoTotale
FROM Visita V
WHERE V.Data > CURRENT_DATE - INTERVAL 24 YEAR

-- 2) Indicare il numero di pazienti di sesso femminile che, nel quarantesimo anno d’età, sono stati visitati,
--    una o più volte, sempre dallo stesso gastroenterologo
WITH PazientiVisitate AS
(
  SELECT V.Paziente, V.Medico, V.Data
  FROM Visita V
    INNER JOIN Medico M ON V.Medico = M.Matricola
    INNER JOIN Paziente P ON V.Paziente = P.CodFiscale
  WHERE V.Data BETWEEN P.DataNascita + INTERVAL 39 YEAR
    AND P.DataNascita + INTERVAL 40 YEAR
    AND P.Sesso = 'F'
    AND M.Specializzazione = 'Gastroenterologia'
)
SELECT COUNT(DISTINCT P1.Paziente)
FROM PazientiVisitate P1
  LEFT OUTER JOIN PazientiVisitate P2 ON P1.Medico <> P2.Medico
    AND P1.Paziente = P2.Paziente
WHERE P2.Medico IS NULL

-- Indicare l’età media dei pazienti mai visitati da ortopedici
SELECT AVG(DISTINCT P.Eta)
FROM (SELECT V.Paziente
  FROM Visita V
    INNER JOIN Medico M ON V.Medico = M.Matricola
  WHERE M.Specializzazione != 'Ortopedia' ) AS D
  RIGHT OUTER JOIN
  Paziente P ON D.Paziente = P.CodFiscale
WHERE D.Paziente IS NULL;

-- Indicare nome e cognome dei pazienti che sono stati visitati non meno di due
-- volte dalla dottoressa Gialli Rita
WITH (
  SELECT P.Nome, P.Cognome, V.Paziente, V.Data, V.Medico
  FROM Visita V
    INNER JOIN Medico M ON V.Medico = M.Matricola
    INNER JOIN Paziente P ON V.Paziente = P.CodFiscale
) AS PazienteVisitato
SELECT P1.Nome, P1.Cognome
FROM PazienteVisitato P1
  LEFT OUTER JOIN PazienteVisitato P2 ON P1.Data <> P2.Data
    AND P1.Paziente = P2.Paziente
    AND P1.Medico = P2.Medico AND P1.Medico = 003
WHERE P2.Medico IS NOT NULL

-- Indicare il reddito medio dei pazienti che sono stati visitati solo da medici con
-- parcella superiore a 100 euro, negli ultimi sei mesi
/* STRATEGIA: avrò bisogno di inner join di qualsiasi visita x con ogni altra visita y operata sullo
stesso paziente. */
WITH PazientiMesi AS (
	SELECT P.CodFiscale, P.Reddito, M.Parcella
    FROM Paziente P
		INNER JOIN Visita V ON V.Paziente = P.CodFiscale
        INNER JOIN Medico M ON M.Matricola = V.Medico
	WHERE V.Data > '2014-05-28' - INTERVAL 12 MONTH
),
PazientiParcella AS (
	SELECT M.CodFiscale, M.Parcella
    FROM PazientiMesi M
	WHERE M.Parcella <= 100
),
PazientiSelezionati AS (
	SELECT DISTINCT M.CodFiscale
	FROM PazientiMesi M
		LEFT OUTER JOIN PazientiParcella P ON P.CodFiscale = M.CodFiscale
	WHERE P.CodFiscale IS NULL
)
SELECT AVG(P.Reddito)
FROM Paziente P
	INNER JOIN PazientiSelezionati S ON S.CodFiscale = P.CodFiscale

-- Rifaccio con raggruppamento...
-- numero di pazienti femmina visitati nel quarantesimo anno di eta dallo stesso gastroenterologo
SELECT COUNT(DISTINCT P.CodFiscale)
FROM Visita V 
  INNER JOIN Paziente P ON P.CodFiscale = V.Paziente
  INNER JOIN Medico M ON M.Matricola = V.Medico
WHERE P.Sesso = 'F' 
  AND V.Data >= P.DataNascita + INTERVAL 39 YEAR
  AND V.Data < P.DataNascita + INTERVAL 40 YEAR 
  AND M.Specializzazione = 'Gastroenterologia'
GROUP BY P.CodFiscale
HAVING COUNT(DISTINCT M.Matricola) = 1

-- Indicare nome e cognome dei pazienti che sono stati visitati non meno di due
-- volte dalla dottoressa Gialli Rita
SELECT P.Nome, P.Cognome
FROM Visita V 
  INNER JOIN Paziente P ON V.Paziente = P.CodFiscale
  INNER JOIN Medico M ON V.Medico = M.Matricola
WHERE M.Cogome = 'Gialli' AND M.Nome = 'Rita'
GROUP BY P.CodFiscale
  HAVING COUNT(M.Matricola) >= 2

-- Indicare il reddito medio dei pazienti che sono stati visitati solo da medici con parcella superiore a 100 euro, negli ultimi sei mesi
-- STRATEGIA: voglio conto dottori totali = conto dottori parcellosi
SELECT AVG(P.Reddito)
FROM Paziente P
WHERE
(
  -- conto parcellosi
  SELECT COUNT(DISTINCT M.Matricola)
  FROM Visita V INNER JOIN Medico M ON V.Medico = M.Matricola
  WHERE V.Paziente = P.CodFiscale AND M.Parcella > 100 AND V.Data + INTERVAL 6 MONTH >= CURRENT_DATE
) =
(
  -- conto tote
  SELECT COUNT(DISTINCT M.Matricola)
  FROM Visita V INNER JOIN Medico M ON V.Medico = M.Matricola
  WHERE V.Paziente = P.CodFiscale AND V.Data + INTERVAL 6 MONTH >= CURRENT_DATE
) AND
(
  -- conto totale
  SELECT COUNT(DISTINCT M.Matricola)
  FROM Visita V INNER JOIN Medico M ON V.Medico = M.Matricola
  WHERE V.Paziente = P.CodFiscale AND V.Data + INTERVAL 6 MONTH >= CURRENT_DATE
) >= 1
