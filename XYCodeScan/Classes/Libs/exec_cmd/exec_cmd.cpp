#include <string>
#include "exec_cmd.h"
using namespace std;

static char * copyString(std::string str)
{
    auto len = str.length();
    if(len > 0) {
        char * data = (char *)malloc((len + 1)*sizeof(char));
        str.copy(data,len,0);
        data[len] = '\0';
        return data;
    } else {
        return nullptr;
    }
}

static string _exec_cmd(string cmd){
    FILE *file = popen(cmd.c_str(),"r");
    
    const int maxLineLengthOfCmdString = 1024*1024;
    char temp[maxLineLengthOfCmdString];
    string ans = "";
    while(fgets(temp,sizeof(temp),file)){
        ans += temp;
    }
    
    pclose(file);
    return ans;
}

extern "C" char * exec_cmd(const char * cmd)
{
    string c(cmd);
    string ret = _exec_cmd(c);
    return copyString(ret);
}
