{smcl}
{* *! version 1.0.0 27dic2017}{...}
{vieweralsosee  "[TE] teffects nnmatch" "mansection TE teffectsnnmatch" }{...}
{vieweralsosee  ""                      "--"                            }{...}
{vieweralsosee  "blopmatching - M&F"    "browse http://bit.ly/2ClRKFH"  }{...}
{vieweralsosee  ""                      "--"                            }{...}
{vieweralsosee  "[TE] teffects"         "help teffects"                 }{...}
{vieweralsosee  "[TE] teffects psmatch" "help teffects psmatch"         }{...}
{viewerjumpto   "Syntax"                "blopmatch##syntax"             }{...}
{viewerjumpto   "Description"           "blopmatch##description"        }{...}
{viewerjumpto   "Options"               "blopmatch##options"            }{...}
{viewerjumpto   "Examples"              "blopmatch##examples"           }{...}
{viewerjumpto   "Stored results"        "blopmatch##results"            }{...}
{viewerjumpto   "Notes"                 "blopmatch##notes"              }{...}
{viewerjumpto   "Authors"               "blopmatch##authors"            }{...}
{viewerjumpto   "References"            "blopmatch##references"         }{...}
{title:Title}

{phang}
{browse "http://bit.ly/2ClRKFH":{bf:blopmatch}} {hline 2} blop-matching


{marker syntax}{...}
{title:Syntax}

{p 8 12 2}
{cmd:blopmatch}
    {cmd:(}{it:{help varname:ovar}} {it:{help varlist:omvarlist}}{cmd:)}
    {cmd:(}{it:{help varname:tvar}}{cmd:)}
    {ifin}
    [{it:{help blopmatch##weight:weight}}]
    [{cmd:,}
        {it:{help blopmatch##stat:stat}}
        {it:{help blopmatch##options_table:options}}]

{p 4 4 2}
{it:ovar}       is a numeric outcome of interest.{break}
{it:omvarlist}  specifies the covariates in the outcome model.{break}
{it:tvar}       must contain integer values representing the
                treatment levels. Only two treatment levels
                are allowed.

{marker stat}{...}
{synoptset 22 tabbed}{...}
{synopthdr:stat}
{synoptline}
{syntab:Stat}
{synopt :{opt ate}}     estimate average treatment effect
                        in population; the default{p_end}
{synopt :{opt atet}}    estimate average treatment effect
                        on the treated{p_end}
{synoptline}

{marker options_table}{...}
{synopthdr:options}
{synoptline}
{syntab:Model}
{synopt :{opth e:match(varlist)}}
    match exactly on specified variables{p_end}

{syntab:Reporting}
{synopt :{opt l:evel(#)}}       set confidence level;
                                default is {cmd:level(95)}{p_end}
{synopt :{opt dmv:ariables}}    display names of matching variables{p_end}

{syntab:Advanced}
{synopt :{opt dtol:erance(#)}}          set maximum distance between
                                        individuals considered equal{p_end}
{synopt :{opt con:trol(# | label)}}     specify the level of {it:tvar}
                                        that is the control{p_end}
{synopt :{opt tle:vel(# | label)}}      specify the level of {it:tvar}
                                        that is the treatment{p_end}
{synopt :{opth m:etric(blopmatch##metric:metric)}}
                                        select distance metric
                                        for covariates{p_end}

{syntab:Minimization (simplex algortihm)}
{synopt:{opt btol:erance}}  Solver tolerance (boundedness test){p_end}
{synopt:{opt otol:erance}}  Solver tolerance (optimality test){p_end}
{synopt:{opt iter:ate}}     Maximum number of iterations{p_end}
{synoptline}

{marker metric}{...}
{synoptset 22 }{...}
{synopthdr:metric}
{synoptline}
{synopt :{opt maha:lanobis}}            inverse sample covariate
                                        covariance; the default{p_end}
{synopt :{opt ivar:iance}}              inverse diagonal sample covariate
                                        covariance{p_end}
{synopt :{opt eucl:idean}}              identity{p_end}
{synoptline}

{pstd}
{it:omvarlist} may contain factor variables; see {help fvvarlists}.{break}
{opt by} and {opt statsby} are allowed; see {help prefix}.{break}
{opt fweight}s are allowed; see {help weight}.{marker weight}{...}

{marker description}{...}
{title:Description}

{pstd}
{bf:blopmatch} estimates the average treatment effect and average treatment
effect on the treated from observational data by blop-matching
{help blopmatch##DRR2015:(Díaz et al., 2015)}.
blop-matching imputes the missing potential outcome for each subject by using
a weighted average [note 1] of the outcomes of similar subjects that receive
the other treatment level.
The vector of weights is obtained by solving an optimization problem whose
objective function is the same as that of its closest neighbor, but where
a restriction is now added that ensures the best possible balance between
the vector of covariables of that unit and those of its possible matches
within the units that receive the other treatment level.
As a by-product, both the number of neighbors and the
weights are determined endogenously.
It can be shown that this is a two-level optimization
problem (BLOP), hence the name of the method [note 2].

{pstd}
Once the weights are determined, 2 treatment effects can be calculated:

{pstd}
    -   The ATE [note 3] is computed by taking the average
        of the difference between the observed and imputed
        potential outcomes for each subject.
    {break}
    -   The ATT [note 4] is computed by taking the average
        of the difference between the observed and imputed
        potential outcomes for each subject
        in the treatment group.
{p_end}

{pstd}
See
{bf:{mansection TE teffectsintro:[TE] teffects intro}} or
{bf:{mansection TE teffectsintroadvanced:[TE] teffects intro advanced}}
for more information about estimating treatment effects
from observational data.

{marker options}{...}
{title:Options}

{dlgtab:Stat}

{phang}
{it:stat} is one of two statistics: {cmd:ate} or {cmd:atet}.
{cmd:ate} is the default.

{pmore}
{cmd:ate}
specifies that the average treatment effect be estimated.

{pmore}
{cmd:atet}
specifies that the average treatment effect on the treated be estimated.

{dlgtab: Model}

{phang}
{opth ematch(varlist)}
specifies that the variables in {it:varlist} match exactly. All variables
in {it:varlist} must be numeric and may be specified as factors.
{cmd:blopmatch} exits with an error if any observations do not
have the requested exact match.

{dlgtab:Reporting}

{phang}
{opt level(#)};
see {helpb estimation options:[R] estimation options}.

{phang}
{opt dmvariables} specifies that the matching variables be displayed.

{dlgtab:Advanced}

{phang}
{opt dtolerance(#)}
specifies the tolerance used to determine exact matches.
The default value is {cmd:dtolerance(sqrt(c(epsdouble)))}.

{pmore}
Integer-valued variables are usually used for exact matching.
The {cmd:dtolerance()} option is useful when continuous
variables are used for exact matching.

{phang}
{opt control(# | label)}
specifies the level of {it:tvar} that is the control.
The default is the 1st lowest value of {it:tvar}.
{space 1}You may specify the numeric level {it:#} (a nonnegative integer) or
the label associated with the numeric level. {opt control()} and
{opt tlevel()} may not specify the same treatment level.

{phang}
{opt tlevel(# | label)}
specifies the level of {it:tvar} that is the treatment.
The default is the 2nd lowest value of {it:tvar}.
{space 0}You may specify the numeric level {it:#} (a nonnegative integer) or
the label associated with the numeric level. {opt control()} and
{opt tlevel()} may not specify the same treatment level.

{phang}
{opth metric:(blopmatch##metric:metric)}
specifies the distance matrix used as the weight matrix in a quadratic
form that transforms the multiple distances into a single distance
measure;
see {it:Methods and formulas} of
{browse "http://bit.ly/2ClRKFH":blopmatch}
for details.

{dlgtab:Minimization}

{phang}
{opt otolerance(#)}
specifies the tolerance in the optimality test of the simplex algorithm.
The default value is {cmd:otolerance(sqrt(c(epsdouble)))}.

{pmore}
Let c be the current reduced cost.
It is well known that if c > 0 the solution is optimal.
However, this rule is impractical due to round-off errors.
{opt otolerance} relax this condition to c + otolerance > 0.

{phang}
{opt btolerane(#)}
specifies the tolerance in the boundedness test of the simplex algorithm.
The default value is {cmd:btolerance(sqrt(c(epsdouble)))}.

{pmore}
Let d be the current pivot column.
It is well known that if d < 0 the problem is unbounded.
However, this rule is impractical due to round-off errors.
{opt btolerance} relax this condition to d < btolerance.

{phang}
{opt iterate(#)}
perform maximum of # iterations; default is iterate(2000).

{marker examples}{...}
{title:Examples}

{pstd}Setup{p_end}
{phang2}{cmd:. webuse cattaneo2}

{pstd}
Estimate the average treatment effect of
{cmd:mbsmoke} on {cmd:bweight}{p_end}
{phang2}
{cmd:. blopmatch}
    {cmd:(bweight mage prenatal1 mmarried fbaby) (mbsmoke)}

{pstd}
Refit the above model, but require exact matches
on the binary variables{p_end}
{phang2}
{cmd:. blopmatch}
    {cmd:(bweight mage) (mbsmoke),}
    {cmd:ematch(prenatal1 mmarried fbaby)}

{marker results}{...}
{title:Stored results}

{pstd}
{cmd:blopmatch} stores the following in {cmd:e()}:

{synoptset 24 tabbed}{...}
{p2col 5 24 28 2:Scalars}{p_end}
{synopt :{cmd:e(N)}}number of observations{p_end}
{synopt :{cmd:e(n}{it:j}{cmd:)}}number of observations for treatment level {it:j}{p_end}
{synopt :{cmd:e(k_levels)}}number of levels in treatment variable{p_end}
{synopt :{cmd:e(treated)}}level of treatment variable defined as treated{p_end}
{synopt :{cmd:e(control)}}level of treatment variable defined as control{p_end}

{p2col 5 24 28 2:Macros}{p_end}
{synopt :{cmd:e(cmd)}}{cmd:blopmatch}{p_end}
{synopt :{cmd:e(cmdline)}}command as typed{p_end}
{synopt :{cmd:e(depvar)}}name of outcome variable{p_end}
{synopt :{cmd:e(tvar)}}name of treatment variable{p_end}
{synopt :{cmd:e(emvarlist)}}exact match variables{p_end}
{synopt :{cmd:e(mvarlist)}}match variables{p_end}
{synopt :{cmd:e(metric)}}{cmd:mahalanobis}, {cmd:ivariance}, {cmd:euclidean}, or {cmd:matrix} {it:matname}{p_end}
{synopt :{cmd:e(stat)}}statistic estimated, {cmd:ate} or {cmd:atet}{p_end}
{synopt :{cmd:e(wtype)}}weight type{p_end}
{synopt :{cmd:e(wexp)}}weight expression{p_end}
{synopt :{cmd:e(title)}}title in estimation output{p_end}
{synopt :{cmd:e(tlevels)}}levels of treatment variable{p_end}
{synopt :{cmd:e(properties)}}{cmd:b V}{p_end}

{p2col 5 24 28 2:Matrices}{p_end}
{synopt :{cmd:e(b)}}coefficient vector{p_end}
{synopt :{cmd:e(V)}}variance-covariance matrix of the estimators{p_end}

{p2col 5 24 28 2:Functions}{p_end}
{synopt :{cmd:e(sample)}}marks estimation sample{p_end}

{marker notes}{...}
{title:Notes}

{phang} [1] The weights are meant to be positives and sum one,
        so weighted sums are in fact convex combinations.{p_end}
{phang} [2] It can be shown that both problems can be rewritten as a linear
        programs (LP). Unfortunately, mata still doesn't have an official LP
        solver, so we created our own LP solver from scratch. This solver,
        lpsolver.mata, is an inefficient (but reliable) implementation
        of the revised simplex algorithm.
        See {help blopmatch##FMW2007:Ferris et al. (2007)}
        for more details.{p_end}
{phang} [3] ATE means {it: average treatment effect}.{p_end}
{phang} [4] ATT means {it: average treatment effect on the treated}.{p_end}

{marker authors}{...}
{title:Authors}

{phang}Juan Diaz,   {space 4} Universidad de Chile.{p_end}
{phang}Jorge Rivera,{space 2} Universidad de Chile.{p_end}
{phang}Ivan Gutierrez

{marker references}{...}
{title:References}

{marker DRR2015}{...}
{phang}
Diaz, J., Rau, T., and J. Rivera. 2015.
A Matching Estimator Based on a Bilevel Optimization Problem.
{it:Review of Economics & Statistics} 97(4): 803-812.
{p_end}

{marker FMW2007}{...}
{phang}
Ferris, M., Mangasarian, O. and S. Wright. 2007.
Linear Programming with MATLAB.
{it: MPS-SIAM Series on Optimization}.
{p_end}
{break}
