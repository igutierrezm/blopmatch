cls
clear all
set more off
capture : ado uninstall blopmatch
net install blopmatch, from("`c(pwd)'") force

set obs 7
generate y = rnormal()
generate x = rnormal()
generate e = 1 - (_n > 4)
generate d = mod(_n, 2)
blopmatch (y x) (d)

// webuse cattaneo2, clear
// blopmatch (bweight mage prenatal1 mmarried fbaby) (mbsmoke)
// teffects nnmatch (bweight mage prenatal1 mmarried fbaby) (mbsmoke)


// use "data/test-data-01", clear
// local y foodinsecure
// local x age
// local x female white hisp black asian other_r hsdrop hsgrad colgrad 
// local x `x' graddeg otherdeg
// local w treat
// timer on  1
// blopmatch (`y' `x') (`w'), ate
// timer off 1
// timer list
