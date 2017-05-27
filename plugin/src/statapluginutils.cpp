#include "statapluginutils.h"
#include <iostream>

void stataDisplay(const std::string &str)
{
#ifdef STATA_PLUGIN_DEBUG
    std::cout << str;
#else // STATA_PLUGIN_DEBUG
    std::string::const_iterator it = str.begin();
    std::string::const_iterator startIt = it;
    while (it != str.end())
    {
        if (*it == '\n')
        {
            std::string outString(startIt, it + 1);
            SF_display(const_cast<char*>(outString.c_str()));
            ++it;
            startIt = it;
        }
        else
            ++it;
    }
    if (startIt != it)
    {
        std::string outString(startIt, it + 1);
        SF_display(const_cast<char*>(outString.c_str()));
    }
#endif // STATA_PLUGIN_DEBUG
}

void stataError(const std::string &str)
{
#ifdef STATA_PLUGIN_DEBUG
    std::cout << str;
#else // STATA_PLUGIN_DEBUG
    std::string::const_iterator it = str.begin();
    std::string::const_iterator startIt = it;
    while (it != str.end())
    {
        if (*it == '\n')
        {
            std::string outString(startIt, it + 1);
            SF_error(const_cast<char*>(outString.c_str()));
            ++it;
            startIt = it;
        }
        else
            ++it;
    }
    if (startIt != it)
    {
        std::string outString(startIt, it + 1);
        SF_error(const_cast<char*>(outString.c_str()));
    }
#endif // STATA_PLUGIN_DEBUG
}

