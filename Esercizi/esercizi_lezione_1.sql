/* Dato lo schema di tabella: STUDENTE (Matricola, Cognome, Nome, DataNascita, DataIscrizione, DataLaurea,
NumeroEsamiSostenuti, Facolta) */

-- 1) Indicare la matricola degli studenti che non si erano ancora laureati il 15 luglio 2005
SELECT Matricola
FROM Studente
WHERE DataIscrizione < '2005-07-15'
  AND (DataLaurea > '2005-07-15'
    OR DataLaurea IS NULL)

-- 2) Indicare matricola e cognome degli studenti il cui percorso di studi è durato (o dura da) oltre sei anni
SELECT Matricola, Cognome
FROM Studente
WHERE (DataLaurea IS NULL
  AND YEAR(CURRENT_DATE) - YEAR(DataIscrizione) > 6)
  OR (DataLaurea IS NOT NULL
  AND YEAR(CURRENT_DATE) - YEAR(DataLaurea) > 6)

-- ancor meglio:
SELECT Matricola, Cognome
FROM Studente
WHERE (DataLaurea IS NULL
  AND CURRENT_DATE > DataIscrizione + INTERVAL 6 YEAR
  OR (DataLaurea IS NOT NULL
  AND DataLaurea > DataIscrizione + INTERVAL 6 YEAR

-- 3) Indicare nome, cognome ed età degli studenti laureati quest’anno in Lettere (durata standard 5 anni a ciclo
--    unico), non fuori corso e come minimo con un anticipo di sei mesi rispetto alla durata standard
SELECT Nome, Cognome, YEAR(CURRENT_DATE) - YEAR(DataNascita) AS Eta
FROM Studente
WHERE Facolta = 'Lettere'
 AND YEAR(DataLaurea) = YEAR(CURRENT_DATE)
  AND (
    YEAR(DataLaurea) - YEAR(DataIscrizione) = 5
    AND MONTH(DataLaurea) - MONTH(DataIscrizione) <= 6
    OR YEAR(DataLaurea) - YEAR(DataIscrizione) < 5
  )

-- 4) Indicare matricola e cognome degli studenti laureati fuori corso, cioè oltre il mese di Aprile del 6° anno,
--    nell’anno accademico 2009-2010
SELECT Matricola, Cognome
FROM Studente
WHERE DataLaurea IS NOT NULL
  AND (YEAR(DataLaurea) - YEAR(DataIscrizione) > 6
    OR YEAR(DataLaurea) - YEAR(DataIscrizione) = 6 
    AND MONTH(DataLaurea) - MONTH(DataIscrizione) > 4)
  AND (YEAR(DataLaurea) = 2009 OR YEAR(DataLaurea) = 2010)

-- 5) Indicare il numero di studenti che si sono laureati nel 2005,
--    dopo il compimento del ventisettesimo anno d’età,
--    e la loro età media al momento della laurea.
--    Risolvere l’esercizio con e senza l’uso di INTERVAL.

SELECT COUNT(S.Matricola) AS NumeroStudenti, AVG(YEAR(DataLaurea) - YEAR(DataNascita)) AS EtaMedia
FROM Studente
WHERE DataLaurea IS NOT NULL
  AND YEAR(DataLaurea) = 2005
  AND YEAR(DataLaurea) - YEAR(DataNascita) > 27

-- più precisamente:
SELECT COUNT(Matricola) AS NumeroStudenti, AVG(YEAR(DataLaurea) - YEAR(DataNascita)) AS EtaMedia
FROM Studente
WHERE DataLaurea IS NOT NULL
  AND YEAR(DataLaurea) = 2005
  AND (YEAR(DataLaurea) - YEAR(DataNascita) > 27
    OR YEAR(DataLaurea) - YEAR(DataNascita) = 27
    AND (MONTH(DataLaurea) > MONTH(DataNascita)
    OR MONTH(DataLaurea) = MONTH(DataNascita)
    AND DAY(DataLaurea) > DAY(DataNascita)
    )
  )

-- 6) Indicare il numero di giorni per laurearsi dallo studente più veloce
--    a laurearsi della facoltà di Ingegneria Meccanica, fra quelli laureati in pari,
--    iscritti nel 2001.
--    (Laureati in pari significa non oltre il mese di Aprile del 6° anno dall’iscrizione.)
SELECT MAX(DATEDIFF(DataLaurea, DataIscrizione))
FROM Studente
WHERE Facolta = 'Ingegneria Meccanica'
  AND (
    YEAR(DataLaurea) - YEAR(DataIscrizione) = 5
    AND MONTH(DataLaurea) - MONTH(DataIscrizione) <= 6
    OR YEAR(DataLaurea) - YEAR(DataIscrizione) < 5 )
  AND YEAR(DataIscrizione) = 2001
