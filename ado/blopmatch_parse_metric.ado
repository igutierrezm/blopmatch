program blopmatch_parse_metric, sclass
    version 13.0
    syntax [, MAHAlanobis IVARiance EUCLidean *]

    // Capture the metric type
    local which = "`mahalanobis' `ivariance' `euclidean'"

    // Throw an error if more than 1 metric is used
    local k : word count `which'
    if (`k' > 1) {
        display as error "options {bf:`which'} may not be combined"
        exit 184
    }

    // Throw an error if a invalid metric is used
    if (`k' == 0) {
        if ("`options'" != "") {
            display as error "{bf:metric(`options')} is not allowed"
            exit 198
        }
    }

    // Set default metric: mahalanobis
    if (`k' == 0) local mahalanobis = "mahalanobis"

    // Parse metric
    sreturn local metric = "`mahalanobis'`ivariance'`euclidean'"
end
