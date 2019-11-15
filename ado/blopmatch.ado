program blopmatch, eclass sortpreserve byable(recall)
    version 13.0
    syntax anything(name=teffects) [if] [in] [fweight/] [, *]

    // Create marker variable
    marksample touse

    // Create weight variable
    tempvar wvar

    // Create key variable for exact ematch
    tempvar gvar

    // Parse inputs
    local options "wvar(`wvar') wexp(`exp') touse(`touse') `options'"
    blopmatch_parse `teffects', `options'

    // Drop collinear covariates
    mata : blopmatch_rmcoll("`s(evar)'", "`s(xvar)'", "`touse'")

    // Create group variable
    blopmatch_parse_gvar, gvar(`gvar')

    // Sort dataset
    sort `s(tvar)' `s(gvar)', stable

    // Estimate ate/atet
    mata : blopmatch_estimate()

    // Display results
    blopmatch_report `"`0'"'
end
