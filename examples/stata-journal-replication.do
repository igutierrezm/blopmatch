// Setup
use "nsw.dta", clear
egen stdre75 = std(re75)

// Set response, covariates and treatment variables
local Y = "re78"
local W = "treat"
local X = "age education black hispanic married nodegree stdre75"

// Estimate ATE using blopmatch and nnmatch
blopmatch (`Y' `X') (`W'), ate                      // ATE = 975.6248
teffects nnmatch (`Y' `X') (`W'), ate nneighbor(01) // ATE = 744.9789
teffects nnmatch (`Y' `X') (`W'), ate nneighbor(16) // ATE = 968.9167
