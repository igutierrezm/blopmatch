program blopmatch_parse, sclass
    version 13.0
    # delimit ;
    syntax anything(id="blopmatch specification" name=teffects) [if] [in] [,
        /// Model
        ate
        atet
        Ematch(varlist numeric fv)
        /// Reporting
        Level(cilevel)
        DMVariables
        /// Advanced
        Metric(string)
        TLEvel(passthru)
        CONtrol(passthru)
        /// Minimization
        OTOLerance(real 1e-8)
        BTOLerance(real 1e-8)
        ITERate(real 2000)
        /// Other options
        wvar(string)           // fweight name
        wexp(string)           // fweight exp
        touse(varname numeric) // marker var
    ];
    # delimit cr

    // Parse weights
    sreturn clear
    blopmatch_parse_fweight, wvar(`wvar') wexp(`wexp')

    // Parse variables
    blopmatch_parse_teffects `teffects', touse(`touse') evar(`ematch')
    blopmatch_parse_tvar, `tlevel' `control'

    // Parse remanent options
    blopmatch_parse_otolerance, otolerance(`otolerance')
    blopmatch_parse_btolerance, btolerance(`btolerance')
    blopmatch_parse_iterate, iterate(`iterate')
    blopmatch_parse_metric, `metric'
    blopmatch_parse_stat, `ate' `atet'
end
