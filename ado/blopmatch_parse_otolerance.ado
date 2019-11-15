program blopmatch_parse_otolerance, sclass
    version 13.0
    syntax, otolerance(real)

    // Throw an error if otolerance is equal or less than zero
    if (`otolerance' <= 0) {
        display as error ///
            "{bf:otolerance({it:#})} must be " ///
            "a real greater than zero"
        exit 198
    }
    sreturn local otolerance = `otolerance'
end
