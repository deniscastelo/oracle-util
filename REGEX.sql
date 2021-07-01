
----------------------------------------------------------

REGEX para mudar de camelCase para snake_case
O regex deve ser realizado em case sensitive

([a-zA-Z][a-z]*)([A-Z])

\L\1_\L\2

----------------------------------------------------------

Pega todas as procedures da página para montar o Header

([^-](PROCEDURE|FUNCTION)\s\w+(\([\w\s,.%]+\))?(\s+RETURN\s\w+)?)
\1;\n

----------------------------------------------------------