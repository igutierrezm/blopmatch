program blopmatch_parse_fweight, sclass
    version 13.0
    syntax, wvar(name) [wexp(string)]
    if ("`wexp'" != "") {
        quietly : generate `wvar' = `wexp'
        sreturn local wtype = "fweight"
        sreturn local wexp  = "= `wexp'"
        sreturn local wvar  = "`wvar'"
    }
    else {
        quietly : generate `wvar' = 1
        sreturn local wvar = "`wvar'"
    }
end
