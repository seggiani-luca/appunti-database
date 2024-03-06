-- 1) Indicare l’incasso totale degli ultimi due anni, realizzato grazie alle visite dei medici cardiologi della clinica
SELECT SUM(M.Parcella) AS IncassoTotale
FROM Visita V
INNER JOIN Medico M ON V.Medico = M.Matricola
WHERE V.Data > CURRENT_DATE - INTERVAL 2 YEAR
  AND M.Specializzazione = 'Cardiologia'

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
  PAziente P ON D.Paziente = P.CodFiscale
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
SELECT AVG(P.Reddito)
