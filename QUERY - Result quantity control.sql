SELECT *
  FROM all_views
 ORDER BY 1 ASC OFFSET 1 ROWS --Pula uma linha
 FETCH FIRST 1 ROWS ONLY; --Recupera apenas uma linha