program blopmatch_parse_stat, sclass
    version 13.0
    syntax [, ate atet]

    // Throw an error if both effects are specified
    if (("`ate'" != "") & ("`atet'" != "")) {
        display as error ///
            "options ate and atet cannot " ///
            "both be specified"
        exit 184
    }

    // Set default value: ate
    if (("`ate'" == "") & ("`atet'" == "")) {
        local ate = "ate"
    }
    sreturn local stat = "`ate'`atet'"
end
