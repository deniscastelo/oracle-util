
----------------------------------------------------------

REGEX para mudar de camelCase para snake_case

([a-zA-Z][a-z]*)([A-Z])

\L\1_\L\2

----------------------------------------------------------

Pega todas as procedures da página para montar o Header

(PROCEDURE\s\w+(\([\w\s,.%]+\))?)
\1;\n

----------------------------------------------------------