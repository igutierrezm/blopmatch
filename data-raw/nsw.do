//=============================================================================
// nsw.do - Generate data/nsw.dta and data/nsw.dta
//=============================================================================

// Carga la BBDD de Lalonde, tal como la ofrece Dehejia en su página web
use "https://users.nber.org/~rdehejia/data/nsw.dta", clear

// Añade etiquetas/notas (BBDD)
label data "Sample from the National Supported Work Demonstration"
note: "Source: https://users.nber.org/~rdehejia/nswdata2.html"

// Añade etiquetas/notas (variables)
local cmd       "label variable"
`cmd' treat     "treatment indicator"
`cmd' age       "age (in years)"
`cmd' education "schooling (in years)"
`cmd' black     "1(black)"
`cmd' hispanic  "1(hispanic)"
`cmd' married   "1(married)"
`cmd' nodegree  "1(no high school degree)"
`cmd' re75      "earnings in 1975 (in 1982 USD)"
`cmd' re78      "earnings in 1978 (in 1982 USD)"

// Añade etiquetas/notas (valores)
label define treat    0 "otherwise" 1 "treated"
label define black    0 "otherwise" 1 "black"
label define hispanic 0 "otherwise" 1 "hispanic"
label define married  0 "otherwise" 1 "married"
label define nodegree 0 "otherwise" 1 "no high school degree"
foreach var in treat black hispanic married nodegree {
	label values `var' `var'
}

// Guarda los datos ya etiquetados
save "data/nsw.dta", replace
