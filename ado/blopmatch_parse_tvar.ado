program blopmatch_parse_tvar, sclass
    version 13.0
    syntax[, tlevel(string) control(string)]

    // Deduce treatment levels
    local i = 1
    quietly : levelsof `s(tvar)' if `s(touse)', local(lvls)
    foreach opt in control tlevel {
        // Set default value
        if ("``opt''" == "") {
            local `opt' : word `i' of `lvls'
            local ++i
            continue
        }

        // If ``opt'' is a number, check its an integer
        capture confirm number ``opt''
        if (_rc == 0) {
            capture noisily confirm integer number ``opt''
            if (_rc != 0) {
                display as error "in option {bf:`opt'({it:#})}"
                exit _rc
            }
            continue
        }

        // If ``opt'' is a varlab, search for the underlying value
        blopmatch_label_to_value `s(tvar)', label(``opt'') local(`opt')
    }

    // Verify that there are 2 levels
    local lvls : subinstr local lvls " " ", ", all
    local Nlevels = wordcount("`lvls'")
    if (`Nlevels' == 0) {
        display as error "No observations"
        exit 2000
    }
    if (`Nlevels' < 2) {
        display as error ///
            "there is only one level in treatment variable `s(tvar)'; " ///
            "this is not allowed"
        exit 459
    }
    if (`Nlevels' > 2) {
        display as error ///
            "treatment variable `s(tvar)' must have 2 levels, " ///
            "but `Nlevels' were found"
        exit 459
    }

    // Verify that `tlevel' and `control' take allowable values
    foreach opt in control tlevel {
        if !inlist(``opt'', `lvls') {
            display as error ///
                "invalid `opt'(``opt'') specification:{break}" ///
                "level ``opt'' not found in treatment " ///
                "variable `s(tvar)'"
            exit 459
        }
    }

    // Verify that `tlevel' and `control' take different values
    if (`control' == `tlevel') {
        display as error  ///
            "control(`control') and tlevel(`tlevel') " ///
            "cannot be the same value"
        exit 198
    }

    // Report results
    sreturn local tlevel  = "`tlevel'"
    sreturn local control = "`control'"
end
