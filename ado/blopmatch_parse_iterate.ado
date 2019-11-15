program blopmatch_parse_iterate, sclass
    version 13.0
    syntax, iterate(real)

    // Throw an error if iterate is not an integer
    capture noisily : confirm integer number `iterate'
    if (_rc != 0) {
        display as error "in option {bf:iterate({it:#})}"
        exit _rc
    }

    // Throw an error if iterate is equal or less than zero
    if (`iterate' <= 0) {
        display as error ///
            "{bf:iterate({it:#})} must be " ///
            "a real greater than zero"
        exit 198
    }
    sreturn local iterate = `iterate'
end
