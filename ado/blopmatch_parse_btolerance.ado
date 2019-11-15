program blopmatch_parse_btolerance, sclass
    version 13.0
    syntax, btolerance(real)

    // Throw an error if btolerance is equal or less than zero
    if (`btolerance' <= 0) {
        display as error ///
            "{bf:btolerance({it:#})} must be " ///
            "a real greater than zero"
        exit 198
    }
    sreturn local btolerance = `btolerance'
end
