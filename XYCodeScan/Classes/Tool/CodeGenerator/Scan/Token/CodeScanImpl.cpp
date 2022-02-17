//
//  CodeScanImpl.cpp
//  HYCodeScan
//
//  Created by admin on 2020/7/15.
//

#include "CodeScanImpl.hpp"
#include "SC_TokenScan.hpp"
#include "NameGeneratorExtern.h"

void rcgCode(char * inFile, char * outFile, int _prop )
{
    genNameClearCache(CFuncName);
    genNameClearCache(CVarName);
    scan::TokenScan scan;
    scan.obfFile(inFile, outFile, _prop);
}


void insertCode(char * inFile, char * outFile, char * import , char * code )
{
    scan::TokenScan scan;
    scan.insertToFile(inFile, outFile, import, code);
    
//    std::ifstream t(inFile);
//    std::string fileName = inFile;
//    std::string fileExt = fileName.substr(fileName.find_last_of('.') + 1);
//    std::stringstream buffer;
//    buffer << t.rdbuf();
//    std::string contents(buffer.str());
//    const unsigned char* c = (const unsigned char *)contents.c_str();
//    unsigned bom = c[0] | (c[1] << 8) | (c[2] << 16);
//    if (bom == 0xBFBBEF) { // UTF8 BOM
//        contents.erase(0,3);
//    }
//    t.close();
//    CodeTokenScan scan(true);
//    scan.insertCode = code;
//    const char * modify = scan.solve(contents.c_str(), 100, fileExt.c_str());
//    std::ofstream fout;
//    fout.open(outFile);
//    fout << import;
//    fout << modify;
//    fout.close();
}


