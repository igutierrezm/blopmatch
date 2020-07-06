cls
clear all
set more off

// net install lp,        from("`c(pwd)'/../lp") force 
// net install blopmatch, from("`c(pwd)'/../blopmatch") force

webuse cattaneo2, clear
blopmatch (bweight mage prenatal1 mmarried fbaby) (mbsmoke)


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
