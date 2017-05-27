#include "stplugin.h"
#include "statapluginutils.h"
#include <stdio.h>
#include <string.h>
#include <vector>
#include <cmath>
#include <glpk.h>

double distance(int t1, int t2, int nObs)
{
    double delta = std::abs(t1 - t2);
    if (delta <= nObs/2)
        return delta;
    else
    {
        if (t1 > t2)
            return t2 + nObs - t1;
        else
            return t1 + nObs - t2;
    }
}

void saveScalar(const char *macroName, double value)
{
    char scalarName[40];
    SF_macro_use((char*)macroName, scalarName, 39);
    SF_scal_save(scalarName, value);
}

template<typename T>
void saveColumnMatrix(const char *macroName, const T &vector)
{
    char matrixName[40];
    SF_macro_use((char*)macroName, matrixName, 39);
    size_t vectorSize = vector.size();
    for (size_t i=0; i<vectorSize; ++i)
        SF_mat_store(matrixName, i+1, 1, vector.at(i));
}

#ifdef STATA_PLUGIN_DEBUG
int main(int argc, char *argv[])
#else // STATA_PLUGIN_DEBUG
STDLL stata_call(int argc, char *argv[])
#endif // STATA_PLUGIN_DEBUG
{
    char strBuf[80];       

    // Get pattern
    std::vector<double> pattern;
    ST_int in1 = SF_in1();
    ST_int in2 = SF_in2();
    for (ST_int i=in1; i<=in2; ++i)
    {
        if (SF_ifobs(i))
        {
            ST_double x;
            SF_vdata(1, i, &x);
            pattern.push_back(x);
        }
    }

    // Length of the pattern
    ST_int patternLength = pattern.size();

    // Total
    double total = 0;
    for (int i=0; i<patternLength; ++i)
        total += pattern.at(i);

    // Mean
    double mean = total / patternLength;

    // Supplies and demands
    std::vector<ST_double> s, d;
    std::vector<ST_int> sTime, dTime;
    for (int i=0; i<patternLength; ++i)
    {
        double y = pattern.at(i);
        ST_double delta = y - mean;
        if (delta > 0)
        {
            s.push_back(delta);
            sTime.push_back(i+1);
        }
        else if (delta < 0)
        {
            d.push_back(-delta);
            dTime.push_back(i+1);
        }
    }

    // Number of constraints
    size_t nS = s.size();
    size_t nD = d.size();

    // Cost matrix
    std::vector<std::vector<double> > costMatrix;
    costMatrix.resize(patternLength);
    char userProvidedCostMatrixName[40];
    SF_macro_use("_cmatrix", userProvidedCostMatrixName, 39);
    if (strcmp(userProvidedCostMatrixName, "") == 0)
    {
        // Default distance matrix
        for (int i=0; i<patternLength; ++i)
        {
            costMatrix.at(i).resize(patternLength);
            for (int j=0; j<patternLength; ++j)
                costMatrix.at(i).at(j) = (distance(i+1, j+1, patternLength));
        }
    }
    else
    {
        // User provided cost matrix
        for (int i=0; i<patternLength; ++i)
        {
            costMatrix.at(i).resize(patternLength);
            for (int j=0; j<patternLength; ++j)
            {
                double transportationCost;
                SF_mat_el(userProvidedCostMatrixName, i+1, j+1, &transportationCost);
                costMatrix.at(i).at(j) = transportationCost;
            }
        }
    }

    // Maximum
    double maximum = 0;
    for (int i=0; i<patternLength; ++i)
    {
        double rowSum = 0;
        for (int j=0; j<patternLength; ++j)
            rowSum += costMatrix.at(i).at(j);
        if (rowSum > maximum)
            maximum = rowSum;
    }
    maximum = (total / patternLength) * maximum;

    // Evaluate seasonality
    double z;
    glp_prob *lp = 0;
    if (nS==0 || nD ==0)
        z = 0;
    else
    {
        // Create problem
        lp = glp_create_prob();
        glp_set_obj_dir(lp, GLP_MIN);

        // Objective function
        glp_add_cols(lp, nS*nD);
        {
            int w = 0;
            for (size_t i=0; i<nS; ++i)
            {
                for (size_t j=0; j<nD; ++j)
                {
                    w++;
                    glp_set_col_bnds(lp, w, GLP_LO, 0.0, 0.0); // note: the last argument is ignored
                    glp_set_obj_coef(lp, w, costMatrix.at(sTime.at(i)-1).at(dTime.at(j)-1));
                }
            }
        }

        // Constraints
        glp_add_rows(lp, nS + nD);
        for (size_t i=0; i<nS; ++i)
            glp_set_row_bnds(lp, i+1, GLP_FX, s.at(i), 0); // note: the last argument is ignored
        for (size_t i=0; i<nD; ++i)
            glp_set_row_bnds(lp, i+nS+1, GLP_FX, d.at(i), 0); // note: the last argument is ignored

        // Coefficient matrix
        unsigned int coeffMatrixArraySize = 2*nS*nD + 1;
        int *iCoeff = new int[coeffMatrixArraySize];
        int *jCoeff = new int[coeffMatrixArraySize];
        double *coeff = new double[coeffMatrixArraySize];
        {
            int w=0;
            for (size_t i=1; i<=nS; ++i)
            {
                for (size_t j=1; j<=nD; ++j)
                {
                    w++;
                    iCoeff[w] = i;
                    jCoeff[w] = (i-1)*nD + j;
                    coeff[w] = 1;
                }
            }
            for (size_t i=1; i<=nD; ++i)
            {
                for (size_t j=1; j<=nS; ++j)
                {
                    w++;
                    iCoeff[w] = i + nS;
                    jCoeff[w] = (j-1)*nD + i;
                    coeff[w] = 1;
                }
            }
            glp_load_matrix(lp, w, iCoeff, jCoeff, coeff);
        }

        // Solve
        glp_simplex(lp, NULL);  // "NULL" means "default control parameters"
        z = glp_get_obj_val(lp);

        // Free memory
        delete[] iCoeff;
        delete[] jCoeff;
        delete[] coeff;
    }

    /*

    // Display the values of the decision variables of the dual problem
    for (int i=1; i<=nS + nD; ++i)
    {
        snprintf(strBuf, 80, "dual = %f\n", glp_get_row_dual(lp, i));
        SF_display(strBuf);
    }
    */

    // Save scalars
    saveScalar("_returnedAbsSeasonalityScalar", z);
    saveScalar("_returnedRelSeasonalityScalar", z/maximum);
    saveScalar("_returnedMaxSeasonalityScalar", maximum);
    saveScalar("_returnedNScalar", patternLength);
    saveScalar("_returnedSumScalar", total);
    saveScalar("_returnedMeanScalar", mean);
    saveScalar("_returnedSurplusesCountScalar", nS);
    saveScalar("_returnedShortagesCountScalar", nD);

    // Save matrices
    saveColumnMatrix("_returnedPatternMatrix", pattern);
    saveColumnMatrix("_returnedSurplusesTMatrix", sTime);
    saveColumnMatrix("_returnedShortagesTMatrix", dTime);
    saveColumnMatrix("_returnedSurplusesMatrix", s);
    saveColumnMatrix("_returnedShortagesMatrix", d);

    // Save cost matrix
    char returnedCostMatrixName[40];
    SF_macro_use("_returnedCostMatrix", returnedCostMatrixName, 39);
    for (int i=0; i<patternLength; ++i)
        for (int j=0; j<patternLength; ++j)
            SF_mat_store(returnedCostMatrixName, i+1, j+1, costMatrix.at(i).at(j));

    // Save transfers matrix
    if (lp)
    {
        char transfersMatrixName[40];
        SF_macro_use("_transfersMatrix", transfersMatrixName, 39);
        int foo = 0;
        for (size_t i=0; i<nS; ++i)
            for (size_t j=0; j<nD; ++j)
            {
                foo++;
                SF_mat_store(transfersMatrixName, i+1, j+1, glp_get_col_prim(lp, foo));
            }
    }

    // Delete problem
    glp_delete_prob(lp);

    return(0);
}

