#ifndef ListenceTools_h
#define ListenceTools_h

#include <string>

class MachineCode{
    static bool isNumOrChar(char x);
    static bool isMacAddressPart(const std::string &cmdInfo , const int index);
    static std::string genMachineCode(const std::string &cmdInfo);
    static std::string getMachineCode();
    static constexpr int macAddressLength = 16;//00:00:00:00:00:00
    static constexpr double criticalValueOfAuthorization = 0.66;
public:
    static bool verifyMachineCode();
};

#endif /* ListenceTools_h */
