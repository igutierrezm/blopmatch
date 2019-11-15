program blopmatch_parse_gvar, sclass
    version 13.0
    syntax, gvar(name)
    // Generate effective group variable
    quietly : egen `gvar' = group(`s(evar)') if `s(touse)'
    sreturn local gvar = "`gvar'"

    // Get number of groups
    quietly : summarize `gvar' if `s(touse)'
    sreturn local Ngroups = "`r(max)'"
end
