program blopmatch_check_type, sclass
    version 13.0
    syntax [anything], type(string) specifiers(string)

    // Capture s() contents
    foreach field in wvar wexp wtype {
        local `field' = "`s(`field')'"
    }

    // Check variable type using the syntax command
    if ("`anything'" != "") {
        capture noisily syntax `type'(`specifiers'), *
    }

    // Explain the problem in greater detail (see teffects nnmatch)
    if (_rc != 0) {
        display as text ///
            "The outcome-model is misspecified.{break}" ///
            "An outline of the syntax is{break}" ///
            "{help blopmatch} " ///
            "(outcome_variable varlist) " ///
            "(treatment_variable)"
    }

    // Restore s() contents
    foreach field in wvar wexp wtype {
        sreturn local `field' = "``field''"
    }
end
