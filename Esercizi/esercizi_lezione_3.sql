--1) considerata ogni specializzazione, indicarne nome e incasso degli ultimi 2 anni
SELECT M.Specializzazione, 
(
  SELECT SUM(Parcella)
  FROM Visita V
    INNER JOIN Medico M1 ON V.Medico = M1.Matricola
  WHERE Specializzazione = M.Specializzazione
    AND CURRENT_DATE- INTERVAL 2 YEAR < V.Data
) AS Incasso
FROM Medico M
GROUP BY Specializzazione

--2) indicare le specializzazioni aventi medici della stessa città
SELECT DISTINCT M1.Specializzazione
FROM Medico M1
WHERE M1.Matricola NOT IN (
  SELECT M2.Matricola
  FROM Medico M2
  LEFT OUTER JOIN Medico M3 
    ON (M3.Citta <> M2.Citta AND M3.Specializzazione = M2.Specializzazione)
  WHERE M3.Matricola IS NOT NULL
)

--piu semplicemente:
SELECT Specializzazione
FROM Medico
GROUP BY Specializzazione
HAVING COUNT(DISTINCT Citta) = 1

--3) indicare codice fiscale, nome, cognome ed età del paziente più anziano della visita, e il
-- numero delle volte da cui è stato visitato da ogni medico
SELECT P.CodFiscale, P.Nome, P.Cognome, YEAR(CURRENT_DATE) - YEAR(P.DataNascita) AS Eta, 
  M.Nome AS Medico, (
    SELECT COUNT(*)
    FROM Visita V
    WHERE V.Medico = M.Matricola AND V.PVisitaVisitaaziente = P.CodFiscale  
  ) AS Visite
FROM Paziente P CROSS JOIN Medico M 
WHERE P.DataNascita = (
  SELECT MIN(P1.DataNascita) 
  FROM Paziente P1
)

--4) indicare la matricola dei medici che hanno effettuato più del 20% delle visite annue
-- della loro specializzazione in almeno due anni fra il 2010 e il 2020
SELECT M.Matricola
FROM Medico M
WHERE 
(
SELECT COUNT(DISTINCT YEAR(V1.Data))
FROM Visita V1
WHERE YEAR(V1.Data) >= 2010 AND YEAR(V1.Data) <= 2020 AND 
	(
		SELECT COUNT(*)
		FROM Visita V INNER JOIN Medico M1 ON V.Medico = M.Matricola
		WHERE YEAR(V.Data) = YEAR(V1.Data) AND M1.Matricola = M.Matricola
	) >
	(
		SELECT COUNT(*)
		FROM Visita V INNER JOIN Medico M1 ON V.Medico = M1.Matricola
		WHERE YEAR(V.Data) = YEAR(V1.Data) AND M1.Specializzazione = M.Specializzazione
	) / 100 * 20 
) > 1

--5) fra tutte le città da cui provengono più di tre pazienti con reddito superiore a 1000
-- euro, indicare quelle da cui provengono almeno due pazienti che sono stati visitati più di una volta 
-- al mese
SELECT DISTINCT P.Citta
FROM Paziente P
WHERE P.Citta IN 
(
	SELECT P1.Citta
	FROM Paziente P1
	WHERE P1.Reddito > 1000
	GROUP BY P1.Citta
	HAVING COUNT(P1.CodFiscale) > 3
) AND P.Citta IN
(
  SELECT P2.Citta
  FROM Visita V INNER JOIN Paziente P2 ON V.Paziente = P2.CodFiscale
  GROUP BY MONTH(V.Data)
  HAVING COUNT(DAY(DATA)) > 1
)
