program blopmatch_parse_teffects, sclass
    // Set syntax
    version 13.0
    syntax anything(id="blopmatch specification" name=teffects),  ///
    touse(varname numeric) [evar(varlist numeric fv)]

    // Verify the correct use of parentheses
    local tmp : list retokenize teffects
    local tmp : subinstr local tmp "(" "", all count(local left)
    local tmp : subinstr local tmp ")" "", all count(local right)
    if ((`left' != 2) | (`right' != 2)) {
        display as error ///
            "invalid {bf:blopmatch} specification:{break}" ///
            "the model specifications should be enclosed " ///
            "in parentheses, or you are missing the " ///
            "comma preceding the options"
        exit 198
    }

    // Extract yvar, tvar and xvar from tmp
    gettoken yvar tmp : tmp
    local n : list sizeof tmp
    local tvar : word `n' of `tmp'
    local xvar : list tmp - tvar

    // Expand wildcards and factors present in xvar or evar
    foreach macname in xvar evar {
        fvexpand ``macname''
        local `macname' "`r(varlist)'"
    }

    // Check that xvar and ematch art not simultanoeouly empty
    if (("`xvar'" == "") & ("`evar'" == "")) {
        display as error  ///
            "{it:omvarlist} or {bf:ematch}(varlist) "
            "must be specified"
        exit 100
    }

    // Check varname(varlist) types
    blopmatch_check_type `tvar', type("varname") specifiers("numeric")
    blopmatch_check_type `yvar', type("varname") specifiers("numeric")
    blopmatch_check_type `xvar', type("varlist") specifiers("numeric fv")
    blopmatch_check_type `evar', type("varlist") specifiers("numeric fv")

    // Search for redundancies
    local name_evar "in the exact-match varlist ematch(varlist)"
    local name_tvar "the treatment variable"
    local name_yvar "the outcome variable"
    local name_xvar "a covariate"
    foreach var1 in tvar yvar xvar evar {
        foreach var2 in tvar yvar xvar evar {
            if ("`var1'" == "`var2'") continue
            local overlap : list `var1' & `var2'
            if ("`overlap'" != "") {
                local msg "`name_`var1'' cannot be `name_`var2''"
                display as error "`msg'"
                exit 198
            }
        }
    }

    // Modify the marker variable
    markout `touse' `yvar' `tvar' `xvar' `evar'

    // Report results
    sreturn local touse = "`touse'"
    sreturn local tvar = "`tvar'"
    sreturn local yvar = "`yvar'"
    sreturn local xvar = "`xvar'"
    sreturn local evar = "`evar'"
end
