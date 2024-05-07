-- indicare cognome e nome dei pazienti visitati almeno una volta da tutti i cardiologi di pisa nel primo 
-- trimestre del 2015
SELECT P.Cognome, P.Nome
FROM Paziente P
WHERE NOT EXISTS (
  SELECT *
  FROM Medico M
  WHERE M.Specializzazione = "Cardiologia"
    AND NOT EXISTS (
      SELECT *
      FROM Visita V
      WHERE YEAR(V.Data) = 2015 AND MONTH(V.Data) BETWEEN 1 AND 3 
        AND V.Medico = M.Matricola
        AND V.Paziente = P.CodFiscale
    )
)

--oppure
SELECT P.Cognome, P.Nome
FROM Visita V
  INNER JOIN Paziente P ON P.CodFiscale = V.Paziente
  INNER JOIN Medico M ON M.Matricola = V.Medico
WHERE YEAR(V.Data) = 2015 AND MONTH(V.Data) BETWEEN 1 AND 3
  AND M.Specializzazione = "Cardiologia"
GROUP BY P.CodFiscale
HAVING COUNT(DISTINCT M.Matricola) = (SELECT COUNT(*)
									  FROM Medico M1
									  WHERE M1.Specializzazione = "Cardiologia")

-- selezionare cognome e specializzazione dei medici la cui parcella è superiore alla media delle parcelle della
-- loro specializzazione e che nell'anno 2011 hanno visitato almeno un paziente che non avevano mai visto prima
SELECT M.Cognome, M.Specializzazione
FROM Medico M
WHERE M.Parcella > (
  SELECT AVG(M1.Parcella)
  FROM Medico M1
  WHERE M1.Specializzazione = M.Specializzazione
) AND EXISTS (
  SELECT *
  FROM Visita V
  WHERE NOT EXISTS (
    SELECT *
    FROM Visita V1
    WHERE V1.Paziente = V.Paziente AND V1.Data < V.Data
  )
)

-- scrivere una query che restituisca nome e cognome del medico che, al 31/12/2014, aveva visitato un numero
-- di pazienti superiore a quelli visitati da ciascun medico della sua stessa superiore
WITH NumeroVisite AS (
	SELECT M.Matricola, M.Nome, M.Cognome, M.Specializzazione, COUNT(DISTINCT V.Paziente) AS Visite
    FROM Visita V
		INNER JOIN Medico M ON V.Medico = M.Matricola
	WHERE V.Data < '2014-12-31'
	GROUP BY M.Matricola
) SELECT NV.Nome, NV.Cognome
FROM NumeroVisite NV
	LEFT OUTER JOIN NumeroVisite NV1 ON NV.Specializzazione = NV1.Specializzazione
		AND NV1.Visite >= NV.Visite AND NV1.Matricola <> NV.Matricola
WHERE NV1.Matricola IS NULL

-- versione che non funziona: (M.Specializzazione è "troppo lontano" dalla outer query, ci sono 2 livelli di nesting)
-- questo esercizio si può comunque fare col not exists, solo non avevo voglia
SELECT M.Nome, M.Cognome
FROM Medico M
WHERE
   (SELECT COUNT(*)
	FROM Visita V
	WHERE V.Medico = M.Matricola AND V.Data < '2014-12-31') 
>= (SELECT MAX(Visite.Numero)
	FROM (SELECT COUNT(*) AS Numero
		FROM Visita V1
			INNER JOIN Medico M1 ON M1.Matricola = V1.Medico
		WHERE M1.Specializzazione = M.Specializzazione AND V1.Data < '2014-12-31'
		GROUP BY V1.Medico
		) AS Visite
	)

-- Scrivere una query che restituisca il codice fiscale dei pazienti che sono stati visitati sempre dal medico
-- avente la parcella più alta, in tutte le specializzazioni. Se, anche per una sola specializzazione, non vi è un unico
-- medico avente la parcella più alta, la query è muta (quest'ultima parte sembra tosta) --NON SONO SICURO!
SELECT *
FROM Paziente P1
WHERE P1.CodFiscale NOT IN
(
SELECT PazientiVisite.CodFiscale
FROM (
	SELECT P.CodFiscale, M.Matricola
	FROM Visita V
		INNER JOIN Medico M ON M.Matricola = V.Medico
		INNER JOIN Paziente P ON P.CodFiscale = V.Paziente
    ) PazientiVisite
    LEFT OUTER JOIN
    (
    SELECT M.Matricola
	FROM Medico M
	WHERE M.Parcella > 
		( 
		SELECT MAX(M1.Parcella)
		FROM Medico M1
		WHERE M1.Matricola <> M.Matricola 
			AND M1.Specializzazione = M.Specializzazione
		)
    ) MediciMaxParcelle ON PazientiVisite.Matricola = MediciMaxParcelle.Matricola
WHERE MediciMaxParcelle.Matricola IS NULL
)

