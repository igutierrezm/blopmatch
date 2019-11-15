program blopmatch_label_to_value
    version 13.0
    syntax varname(numeric), label(string) local(string)

    // Capture the value label of the variable
    local vallab : value label `varlist'
    if ("`vallab'" == "") {
        display as error "variable {bf:`varlist'} has no label"
        exit 459
    }

    // Get some information about the values behind the "value labels"
    capture label list `vallab'
    local kmin = `r(min)'
    local kmax = `r(max)'

    // Find the value whose "value label" matches `label'
    forvalues k = `kmin'(1)`kmax' {
        local str : label `vallab' `k', strict
        if ("`str'" == "`label'") {
            c_local `local' = "`k'"
        exit
        }
    }

    // Throw an error if no match was found
    display as error ///
        `"label "{bf:`label'}" cannot be found in value label "' ///
        `"{bf:`vallab'} for variable {bf:`varlist'}"'
    exit 459
end
