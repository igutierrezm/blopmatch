// Compile all mata files and install the package
// (the working directory MUST be the root of the repository)

// Set package name
local pkg "blopmatch"

// Clear workspace
cls
clear all
mata: mata clear

// Run all mata files
local files : dir "ado" files "*.mata", respectcase
foreach file of local files {
    run "ado/`file'"
	display "`file'"
}

// Compile mata functions
mata:
mata mlib create l`pkg', replace
mata mlib add l`pkg' *()
end

// Move library
copy "l`pkg'.mlib" "ado/l`pkg'.mlib", replace
rm "l`pkg'.mlib"

// Install package
net install `pkg', all force from("`c(pwd)'")
