Trovare nome e cognome dei pazienti visitati solo da ortopedici
SELECT P.Nome, P.Cognome
FROM Visita V1
  INNER JOIN Paziente P1 ON V1.Paziente = P1.CodFiscale
  INNER JOIN Medico M1 ON V1.Medico = M1.Matricola 
  LEFT OUTER JOIN (
    SELECT *
    FROM Visita V2
      INNER JOIN Paziente P2 ON V2.Paziente = P2.CodFiscale
      INNER JOIN Medico M2 ON V2.Medico = M2.Matricola
    WHERE M2.Specializzazione != "Ortopedico"
      AND P2.CodFiscale = P1.CodFiscale
      AND V2.Medico != V1.Medico
  )
WHERE M1.Specializzazione = "Ortopedico" 
  AND P2.CodFiscale = NULL
