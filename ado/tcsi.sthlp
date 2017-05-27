{smcl}
{* *! version 1.0 18jan2016}{...}
{viewerjumpto "Title" "tcsi##title"}{...}
{viewerjumpto "Syntax" "tcsi##syntax"}{...}
{viewerjumpto "Description" "tcsi##description"}{...}
{viewerjumpto "Saved results" "tcsi##saved_results"}{...}
{viewerjumpto "Also see" "maximaget##alsosee"}{...}
{cmd:help tcsi}
{hline}

{marker title}{...}
{title:Title}

{pstd}
{cmd:tcsi} {hline 2} Evaluate seasonality according to the transportation cost approach

{marker syntax}{...}
{title:Syntax}

{pstd}
{cmd:tcsi} {varname} {ifin}, [{opt CMATrix(cost_matrix)}]

{marker description}{...} 
{title:Description}

{pstd}
{cmd:tcsi} calculate the absolute and the relative version of the transportation cost seasonality index as proposed in {help tcsi##alsosee :Lo Magno G.L., Ferrante M. and De Cantis S. (forthcoming)}.

{pstd}
{it:varname} contains the data of the seasonal pattern for which seasonality has to be evaluated and must be a numeric variable. Only non-negative values are allowed.

{pstd}
{opt CMATrix()} is used to specify the cost matrix which is used to evaulate seasonality.
The cost matrix has to be a square matrix, with non-negative elements and no missing values.
If {opt CMATrix()} is not specified, the distance matrix is used by default.

{pstd}
{cmd:tcsi} is based on a Stata plugin written in C++ which is loaded the first time that {cmd:tcsi} is invoked.
This plugin is the heart of the command and its main purpose is to solve the linear transportation problem which is needed to evaluate seasonality.
The plugin is based on the open-source library {browse "https://www.gnu.org/software/glpk/":GNU Linear Programming Kit (GNU)}.

{marker saved_results}{...}
{title:Saved results}

{pstd}
{cmd:tcsi} saves the following in {cmd:r()}:

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Scalars}{p_end}
{synopt:{cmd:r(abs_seasonality)}}absolute index of seasonality{p_end}
{synopt:{cmd:r(rel_seasonality)}}relative index of seasonality{p_end}
{synopt:{cmd:r(max_seasonality) }}maximum value of the absolute index of seasonality, keeping constant the total amount of the observed phenomenon{p_end}
{synopt:{cmd:r(N)}}length of the pattern{p_end}
{synopt:{cmd:r(sum)}}total amount of the observed phenomenon{p_end}
{synopt:{cmd:r(mean)}}mean value{p_end}
{synopt:{cmd:r(surpluses_N)}}number of high seasonal periods{p_end}
{synopt:{cmd:r(shortages_N)}}number of low seasonal periods{p_end}

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Matrices}{p_end}
{synopt:{cmd:e(pattern)}}evaluted seasonal pattern{p_end}
{synopt:{cmd:e(surpluses_t)}}high-seasonal time periods{p_end}
{synopt:{cmd:e(shortages_t)}}low-seasonal time periods{p_end}
{synopt:{cmd:e(surpluses)}}surpluses corresponding to high-seasonal time periods{p_end}
{synopt:{cmd:e(shortages)}}shortages corresponding to low-seasonal time periods{p_end}
{synopt:{cmd:e(costs)}}used cost matrix{p_end}
{synopt:{cmd:e(transfers)}}transfers from high-seasonal time periods to low-seasonal time periods that eliminate seasonality at minimum cost{p_end}

{p2colreset}{...}

{marker alsosee}{...}
{title:Also see}

{psee}
Lo Magno G.L., Ferrante M., De Cantis S. (forthcoming) Measuring seasonality: a transportation cost approach.

{psee}
{browse "https://sourceforge.net/projects/seasonality-calculator/":SCalc}, a stand-alone software to evalute seasonality according to the minimum transportation cost approach.

{psee}
{browse "https://www.gnu.org/software/glpk/":GNU Linear Programming Kit (GLPK)}




