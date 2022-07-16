import sue/[lexer], print


let l = lexSue readFile "./examples/eg1.sue"
print l
echo dump l