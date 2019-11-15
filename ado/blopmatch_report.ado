program blopmatch_report, eclass
    version 13.0
    syntax anything(name=cmdline)

    // Import all macros saved in s()
    local macnamelist = ///
        "control evar iterate level matrix metric " + ///
        "stat tlevel touse tvar wexp wvar wtype xvar yvar"
    foreach macname of local macnamelist {
        local `macname' "`s(`macname')'"
    }

    // Import estimation results
    tempname b V
    matrix `b' = r(b)'
    matrix `V' = r(V)
    matrix colnames `b' = "`stat'"
    matrix colnames `V' = "`stat'"
    matrix rownames `V' = "`stat'"

    // Get sample sizes
    quietly : {
        count if `touse'
        local M0 = `r(N)'
        local i = 1
        foreach level in "control" "tlevel" {
            count if `touse' & `tvar' == ``level''
            local M`i' = `r(N)'
            local ++i
        }
    }

    // Store coefficient vector and variance-covariance matrix into e()
    ereturn post `b' `V', esample(`touse') depname(`yvar')

    // Sign estimation sample
    signestimationsample `tvar' `yvar' `xvar' `evar'

    // Saved scalars
    ereturn scalar treated    = `tlevel'
    ereturn scalar control    = `control'
    ereturn scalar N          = `M0'
    ereturn scalar n`control' = `M1'
    ereturn scalar n`tlevel'  = `M2'

    // Saved macros
    ereturn local tlevels   = "`control' `tlevel'"
    ereturn local title     = "Treatment-effects estimation"
    ereturn local wexp      = "`wexp'"
    ereturn local wtype     = "`wtype'"
    ereturn local stat      = "`stat'"
    ereturn local matrix    = "`matrix'"
    ereturn local metric    = "`metric'"
    ereturn local mvarlist  = "`xvar'"
    ereturn local emvarlist = "`evar'"
    ereturn local tvar      = "`tvar'"
    ereturn local depvar    = "`yvar'"
    ereturn local cmdline   = "blopmatch " + `cmdline'
    ereturn local cmd       = "blopmatch"

    // Display coefficient table
    local Metric = proper("`metric'")
    addToHeader ""
    addToHeader "Treatment-effects estimation"
    addToHeader "Estimator,       : blop matching,      Number of obs, `M0'"
    addToHeader "Outcome model,   : matching,      Control group size, `M1'"
    addToHeader "Distance Metric, : `Metric',    Treatment group size, `M2'"
    ereturn display, level(`level')
end

program addToHeader
    tokenize `0', parse(",")
    if ("`7'" != "") local equals "= "
    display  ///
        as txt "`1'" _column(16) ///
        as res "`3'" _column(48) ///
        as txt "`5'" _column(69) ///
        "`equals'" as res %8.0f `7'
end
