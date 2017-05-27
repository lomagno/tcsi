#ifndef STATAPLUGINUTILS_H
#define STATAPLUGINUTILS_H

#include "stplugin.h"
#include <string>

// stataDisplay and stataError are used to display text in Stata.
// They avoid the problem that arise when you use SF_display or SF_error to display
// a string with a '\n' characted which is not at the end of the string, for example "Hello\nworld"
void stataDisplay(const std::string &str);
void stataError(const std::string &str);

#endif // STATAPLUGINUTILS_H

