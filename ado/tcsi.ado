*! version 1.1  26may2017
program tcsi, rclass
	syntax varname [if] [in], [CMATrix(name)]	
	local y `varlist'
	
	quietly {
	
	// Check if variable is numeric
	confirm numeric variable `y'
	
	// touse variable
	marksample touse
	
	// Length of the pattern
	count if `touse'
	local patternLength = `r(N)'
	if `patternLength' == 0 {
		display as error "No observations"
		exit 198
	}
	
	// Check if all values in the pattern are non-negative
	count if `touse' & `y'<0
	if `r(N)' > 0 {
		display as error "All values must be non-negative"
		exit 198	
	}
	
	// Various checks for the cost matrix that has been provided by the user
	if "`cmatrix'" != "" {	
		// Check if cost matrix exists
		confirm matrix `cmatrix'		
		
		// Check if cost matrix has missing values
		if (matmissing(`cmatrix') != 0) {
			display as error "There are missing values in the cost matrix"
			exit 198
		}		
		
		// Dimensions of cost matrix
		local rowsOfCostMatrix = rowsof(`cmatrix')
		local colsOfCostMatrix = colsof(`cmatrix')
		
		// Check if cost matrix is a square matrix
		if (`rowsOfCostMatrix' != `colsOfCostMatrix') {
			display as error "The cost matrix is not a square matrix"
			exit 198		
		} 	
		
		// Check if each element of the cost matrix is non-negative
		forvalues i = 1/`rowsOfCostMatrix' {
			forvalues j = 1/`colsOfCostMatrix' {
				if (`cmatrix'[`i', `j'] < 0) {
					display as error "Each element of the cost matrix must be non-negative"
					exit 198			
				}
			}
		}
	}	
	
	// Prepare returned values (they will be filled by the Stata plugin)
	tempname returnedAbsSeasonalityScalar
	scalar `returnedAbsSeasonalityScalar' = .
	tempname returnedRelSeasonalityScalar
	scalar `returnedRelSeasonalityScalar' = .	
	tempname returnedMaxSeasonalityScalar
	scalar `returnedMaxSeasonalityScalar' = .
	tempname returnedNScalar
	scalar `returnedNScalar' = .
	tempname returnedSumScalar
	scalar `returnedSumScalar' = .
	tempname returnedMeanScalar
	scalar `returnedMeanScalar' = .
	tempname returnedSurplusesCountScalar
	scalar `returnedSurplusesCountScalar' = .
	tempname returnedShortagesCountScalar
	scalar `returnedShortagesCountScalar' = .
	tempname returnedPatternMatrix
	matrix `returnedPatternMatrix' = J(`patternLength', 1, .)
	tempname returnedSurplusesTMatrix
	matrix `returnedSurplusesTMatrix' = J(`patternLength', 1, .)
	tempname returnedShortagesTMatrix
	matrix `returnedShortagesTMatrix' = J(`patternLength', 1, .)	
	tempname returnedSurplusesMatrix
	matrix `returnedSurplusesMatrix' = J(`patternLength', 1, .)
	tempname returnedShortagesMatrix
	matrix `returnedShortagesMatrix' = J(`patternLength', 1, .)		
	tempname returnedCostMatrix
	matrix `returnedCostMatrix' = J(`patternLength', `patternLength', .)
	tempname transfersMatrix
	matrix `transfersMatrix' = J(`patternLength', `patternLength', .)
	
	// Solve a bug of the SF_mat_store() function of Stata Plugin Interface 2.0
	if `patternLength' > 1 {
		matrix `returnedCostMatrix'[1,2] = 0
		matrix `transfersMatrix'[1,2] = 0
	}	

	// Call plugin
	plugin call tcsi_plugin `y' `if' `in'
	
	// Return scalars
	return scalar shortages_N = scalar(`returnedShortagesCountScalar')
	return scalar surpluses_N = scalar(`returnedSurplusesCountScalar')
	return scalar mean = scalar(`returnedMeanScalar')
	return scalar sum = scalar(`returnedSumScalar')
	return scalar N = scalar(`returnedNScalar')
	return scalar max_seasonality = scalar(`returnedMaxSeasonalityScalar')
	return scalar rel_seasonality = scalar(`returnedRelSeasonalityScalar')
	return scalar abs_seasonality = scalar(`returnedAbsSeasonalityScalar')
	
	// Adjust matrices
	if `returnedSurplusesCountScalar' > 0 {
		matrix `transfersMatrix' = `transfersMatrix'[1..scalar(`returnedSurplusesCountScalar'), 1..scalar(`returnedShortagesCountScalar')]
		matrix `returnedShortagesMatrix' = `returnedShortagesMatrix'[1..scalar(`returnedShortagesCountScalar'),.]
		matrix `returnedSurplusesMatrix' = `returnedSurplusesMatrix'[1..scalar(`returnedSurplusesCountScalar'),.]
		matrix `returnedShortagesTMatrix' = `returnedShortagesTMatrix'[1..scalar(`returnedShortagesCountScalar'),.]
		matrix `returnedSurplusesTMatrix' = `returnedSurplusesTMatrix'[1..scalar(`returnedSurplusesCountScalar'),.]	
		
		// Row names for transfers matrix
		local transfersMatrixRowNames
		local nS = `returnedSurplusesCountScalar'
		forvalues i = 1/`nS' {
			local t = `returnedSurplusesTMatrix'[`i', 1]
			local transfersMatrixRowNames = "`transfersMatrixRowNames' `t'"
		}
		matrix rownames `transfersMatrix' = `transfersMatrixRowNames'
		
		// Column names for transfers matrix
		local transfersMatrixColumnNames
		local nD = `returnedShortagesCountScalar'
		forvalues i = 1/`nD' {
			local t = `returnedShortagesTMatrix'[`i', 1]
			local transfersMatrixColumnNames = "`transfersMatrixColumnNames' `t'"
		}
		matrix colnames `transfersMatrix' = `transfersMatrixColumnNames'			
	}
		
	// Return matrices
	if `returnedSurplusesCountScalar' > 0 {
		return matrix transfers = `transfersMatrix', copy
	}
	return matrix costs = `returnedCostMatrix', copy
	if `returnedSurplusesCountScalar' > 0 {
		return matrix shortages = `returnedShortagesMatrix', copy
		return matrix surpluses = `returnedSurplusesMatrix', copy
		return matrix shortages_t = `returnedShortagesTMatrix', copy
		return matrix surpluses_t = `returnedSurplusesTMatrix', copy
	}
	return matrix pattern = `returnedPatternMatrix', copy
	
	// Display results
	noisily display ""
	noisily display as text "Absolute seasonality = " as result scalar(`returnedAbsSeasonalityScalar')
	noisily display as text "Relative seasonality = " as result scalar(`returnedRelSeasonalityScalar')
	
	} // End of quietly
end

if (c(os) == "Unix") {
	capture program tcsi_plugin, plugin using(tcsi_linux.plugin)
	if (_rc != 0) {
		noisily display "Error occured while loading tcsi_linux.plugin." _n "Try to install the libglpk36 from the terminal by using the following command:" _n "apt-get install libglpk36."
		exit 198
	}
}
else if (c(os) == "MacOSX") {
	program tcsi_plugin, plugin using(tcsi_mac.plugin)
}
else if (c(os) == "Windows") {
	program tcsi_plugin, plugin using(tcsi_windows.plugin)
}
else {
	display as error "This program can't run in your operating system and/or in your machine because it requires a version of the tcsi plugin which is specific to your computer system"
	exit
}


