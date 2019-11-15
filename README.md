# blopmatch

blopmatch estimates the average treatment effect and average treatment
effect on the treated from observational data by *blop-matching*, as proposed
by Díaz et al. (2015).

## Installation

To install this package in Stata, run the following commands:
```Stata
local url "https://raw.githubusercontent.com/igutierrezm"
net install lp,        all from("`url'/lp/master")  
net install blopmatch, all from("`url'/blopmatch/master")  
```
After installation, type
```Stata
help blopmatch
```
for additional details and examples.

## Usage

```Stata
// Load a sample dataset
webuse cattaneo2

// Estimate the average treatment effect of mbsmoke on bweight
blopmatch (bweight mage prenatal1 mmarried fbaby) (mbsmoke)

// Refit the above model, but require exact matches on the binary variables
blopmatch (bweight mage) (mbsmoke), ematch(prenatal1 mmarried fbaby)
```
