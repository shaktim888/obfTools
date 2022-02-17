#include <stdio.h>
#include <vector>
#include <iostream>
#include "exec_cmd.h"
#include "ListenceTools.hpp"
#include "Md5Encode.hpp"
using namespace std;

vector<string> machinecodelist = {
    "96fff594579323433b418787bf85d65c68d23c521307afffcb2df658ac2ee1c907f4ee619a70912f3cb11c029dd14e7177bffeb7107d505abaec0217b727de49b135cd008bbebe55004ac44a045c3406ecbd75b6f6d04bbb1e0dd86496af8bc5a084eedfc9e4f9adefef86354ea0150fe12142d17e3b065fc10f9f47cc618a08b135cd008bbebe55004ac44a045c34068ef07cc36e5a242f55598dc314355f6cdebc01ca8f866318b5318f023949efa3debc01ca8f866318b5318f023949efa3f38e37976ed9ffec7fbb8fd3d72ffe6d", //admin
    "13e4610337a4cec1f3748ae0b324f98d91271c4ef91fa2d9aecb95ef1372d69826009b249f97738641647897a1a3e63fd41616cd5a5088f589e02cc8d73db07dad0a0f6bca9e5527b8827e371b0df4f9a5aa5b88ba85a383aa0e4615a50e14b126009b249f97738641647897a1a3e63f", // cxf
    "aebbe2a1d7162a883f374a5b77604805458b3e61bbcab33ab281b13451d74644f2b73beee96181b41eb4ad6f046655aca6e76c848bd2a04075a55d73e102f155b9c5ab7c85a041835d951ee6cca41fa49be046cf6e7198a7bc43ea30ae2449ceb9c5ab7c85a041835d951ee6cca41fa4", // tanyan
    "dcbeed1d2afca668edfe5572b15bd66c4a04a5223a4323a554da71241649fe6058b7d316ae8c0796fff55a34c2e9f7dc5235a1d140e6303bcdedcdacee6afb02f63d27e44b92a3eaad924ea3912379b6d2b3786f0984e94bf8194d20fc4ea19978f588997b6aee6443a9c968d4493477d2b3786f0984e94bf8194d20fc4ea199", // zzj
    "38f4591ab88239796740eed57c66bc38acce2193fd719c9e1bb3f5bbd0726cbfe3641bdff3d9bf99c8b691f7f7552f756745e1fc8293069aa4e973c60a56bf89ee331e3b5cdc0cf8b1fe02c28e13eedceadef1f400674e5892396cf5643dff0fee331e3b5cdc0cf8b1fe02c28e13eedcc6c4cfd6914df7c064ccb8df24b94d60", // csy
    "b711c866f9627f002bc50e13bb0366bdd5d88f61fb535801ea865f8d2289afa6a4fb33439236deaef128457a79fe534d12d6173fa66c545aab6327b87aa995c2a4fb33439236deaef128457a79fe534df8a2fb6510ad8eaf41cfcad86d8aca904486d67f355299e896bad2528828a117bca4fbf5ebd947aefe69336724bc0a38", // lzc
    "babea758ed6cfb91282396c5fd2f89491d4e1d5c9ffff3db3f4aa4ea7c5e856790ca94b3f18126b50581d52d7f9cc3273d57eedfdfddc5df0c73d3dc04218a626e5a48cee3b9914238d67b5753bb7b283d57eedfdfddc5df0c73d3dc04218a62babea758ed6cfb91282396c5fd2f89492c87a764270cf2d305eb3118a20fd7a8844ce6b7393a046a327b4c5442b8afa0b5d00caba8cf0b0a7dba46a6900021d4cc678d58c2983bf350a732df43300fe7", // lilang
    "a1bd4c878f418c0cadc86f0f1a56dc85ecc2c4e206ac0f2e03603d4497cea0f49ef3f67cad74757746f8850729732472a159961f24c42f085567e3dafcfdd862fd3d5b13e04f43422cc6a02c15fc23e997b6f71ab8c5de2119b09eebe8d04d64fd3d5b13e04f43422cc6a02c15fc23e939bb281d8d83d005c38bc121c17c9193", // smy2
    "96fff594579323433b418787bf85d65ce191e4576cfd83f8773e18d0cae5bae935a05a6d9827cbd38228e3506883ef2df7d82ce74aa63aa1aaa23325d341e41e3d011c0072c5623bf7fc1fe6894ce8b0d4cccd71360eeebbd51c2a64300ed40ed4cccd71360eeebbd51c2a64300ed40eac57c690f0317def6f323c716355e3e876307d834d942210ba955e515805e6753269890441b1e19222572245391ca43f29d52565114e2a0460fc078442c0b75c09b751c76c903d403cd957a2cec23f80", // ch
    "8200e8ddd5758b23264f45a1877caafcbd67fa41ffb392fa403117fb608f3f211a68ec7ac32003ede1d44846c64e21b8d93642ba874edad2831fda6f5d44d73dd93642ba874edad2831fda6f5d44d73d", // csy new
    "91271c4ef91fa2d9aecb95ef1372d698ad0a0f6bca9e5527b8827e371b0df4f9c81bfe9c02d6d2133af78122c77ece33c81bfe9c02d6d2133af78122c77ece3313e4610337a4cec1f3748ae0b324f98dc64bc1f3bc50ff5a2d573de1389c538ac64bc1f3bc50ff5a2d573de1389c538a8560f4d9f949405926c0138afc06a6c219950c01befb4f88379d703b02d00a51", // cxf
    "b185b62d0fa2a16b484f3444257270c93f2771ded9e773ce67199d459c29f8126a01be916b8f17f6200b59cefbe3961c09c894b458eeee68619971e52f3eef8e817fffe593554d9c1da0e1063d3fbcfd4188a92f441b5942b20cd6256f71289f817fffe593554d9c1da0e1063d3fbcfd918c7809d44c981816818bba958c1f59", // ycf
    "96fff594579323433b418787bf85d65c6e6071740b62d8d9515c133395a375a886a23d6451be71d5d91ab89dcab8961cef0e147ea96a36898837c528603692a8bf4290eb16a5fb51f40dda25f612e9e6bb639e662bdf2d7eb4b3f9c3d8cc2f7d6e1b77b7db8b14689a8b5c1ed1a81e33fddd84a79df62875e7830b600194d1cf5122a3dd97d002e5be78c6e54f5adc97bb639e662bdf2d7eb4b3f9c3d8cc2f7d0f4bb34678f64f93af98418c0021e27e", // tyy
    
    "aa683447102642eb91b7c1a5409f26fb01664b4e5c59e5d1b8b538b9efa40b44918c7809d44c981816818bba958c1f59e0057c406c2aa7dd7138e0a3ca98dcc58fa719b270d7d0193f3cc4df995479cee0057c406c2aa7dd7138e0a3ca98dcc5f353e4ddbf4e76373f5958a2c45b088e2698146dc6f790f7908770da1174ca222698146dc6f790f7908770da1174ca22", //zhushuaijia
    "58a185e4f30c80e97c653ea2adfc5f4121a775b703a3e4aea7cb9a58bfe535e966530c004736ea2921f1ef86aae99b3e3330ca6e136b092a6c350b69a1c27c80b9759dcfe134633dcc3ca1371410d8c33330ca6e136b092a6c350b69a1c27c80", // xiaoyou
    "2cfa1c49726fc8349d695282574160f096fff594579323433b418787bf85d65c8eb8639a94cca7ce150b080f3a54bea8a07c01660647b09e60ded2cb8e50bace3c0efa264f60b0b6e7146f506d490fc79c2ae0207df58c7106bf741dd16746999c2ae0207df58c7106bf741dd16746996414aa47cb4d5a7d8a3091a8b1eb8f46610c8ad0dbc7112338c8d25e60d35fa3461739dbb53431ae77fb58090ae906fe35b137468dec4eb3c76c0799677d37956414aa47cb4d5a7d8a3091a8b1eb8f46", //macServer
    
    "86fe03cb2d55d9873da0958cea23b8a5d8bed12080d3f85d45745295c397f88cbe9408c9a7d30871e358a52514c841bfd8bed12080d3f85d45745295c397f88cc15b60d361b788eebbd5d6396613244db8842e2847824b64ae266ee86943b50d9cc1d3aea4838c40786b02f9c13cfd65197a2a9b91a12493c22b728b1a9f4140197a2a9b91a12493c22b728b1a9f41402baa9d4d511e1e99c0c41b50ea597c2c", // chenlanxiang
    "96fff594579323433b418787bf85d65c1c6951278c66b1288608aaeb1024c0f54685e837e8cb71f448708681ddcf6ba0895bad8368bcbc44c6c1af055464a8d46f3d3d5bee6cac57b394119291ae6bf1900526c5e79eaa558c657e5fe7e35368900526c5e79eaa558c657e5fe7e35368404f30b62bf4a66192d34e48aa227b792e6d73bafe577adb90983f34f4207c67f599a35e1a65c336bf00fc942ad3b9436424f31e54126bce06c9a5203bd6ee52404f30b62bf4a66192d34e48aa227b79",  // zw
    "82aeacab7d543dbd30e27007476da01696fff594579323433b418787bf85d65c8f0a59f4d29709bf8955e4a64f818d8cc821e29ab1c47155a941951cc1c0988c3448ba3fc44fb0a5d1b62c75833c5ba2e6879b38dbfb74021b9b34a2f073f773e6879b38dbfb74021b9b34a2f073f773976bffd06ba65a912839a18cd9498c8eb678abb5ecff848fddcb3ed6ae8ad8e37c300edb13f31f85bf8381345a16fa4c5a40cfd8da9501a0475418de10100fb0b678abb5ecff848fddcb3ed6ae8ad8e3", // server 外面的
    "bf12cd297cb19e7eb43155d1499ade71c87629d0e0fc659d63eca0452a8a1419cd72e4be6a9043afa8f45748e6a5fff5f60dfa5fb6e6350c6642c0b0e45fbf30cd72e4be6a9043afa8f45748e6a5fff5b2bed01a80f18590b8c5122597c5d798fe12c754126a59d8a7f3b95e37920fde4c77f3b76931c455ed4733b79e38f7ce", // wenjun
    
    "e314c091a52eb4f1cb4513aa99edd6ab0a01c809245e4c94cbaab7ea23bcc22ae314c091a52eb4f1cb4513aa99edd6abb1259248d7d84be94ea216f82447a9c0e99accaf5e46a188963a903eebc5c1d5b0244718436991a4b1ce3ad2cfee683ef5ddf5393fafb43f2ea0d177f7b5002e5af2904ce45e2a9f949757f8f62aaa895af2904ce45e2a9f949757f8f62aaa89", // haodong
};

bool MachineCode::isNumOrChar(const char x){
    return 'a'<=x && x<='z' || 'A'<=x && x <='Z' || '0'<=x && x<='9';
}

bool MachineCode::isMacAddressPart(const string &cmdInfo , const int index){
    if(index+15 >= cmdInfo.size()) return false;
    if(index<3) return false;
    if(!isNumOrChar(cmdInfo[index-2])) return false;
    if(!isNumOrChar(cmdInfo[index-1])) return false;
    if('\n' != cmdInfo[index-3] && ' '!= cmdInfo[index-3]) return false;
    
    vector<int> ta = {1,2,4,5,7,8,10,11,13,14};
    vector<int> ta2 = {3,6,9,12};
    for(int j = 1;j<ta.size();j++){
        if(!isNumOrChar(cmdInfo[index+ta[j]])) return false;
    }
    for(int j = 1;j<ta2.size();j++){
        if(cmdInfo[index+ta2[j]] != ':'){
            return false;
        }
    }
    return true;
}

std::string MachineCode::genMachineCode(const string &cmdInfo){
    string machineCode = "";
    unsigned long len = cmdInfo.size();
    int i = 0;
    while(i<len){
        if(cmdInfo[i]==':'){
            if(isMacAddressPart(cmdInfo,i)){
                string outInfo = cmdInfo.substr(i-2,17);
                Md5Encode md5;
                machineCode += md5.Encode(outInfo);
                i+=macAddressLength-2;
            }else ++i;
        }else ++i;
    }
    
    return machineCode;
}

std::string MachineCode::getMachineCode(){
    string data = exec_cmd("ifconfig -a");
    return genMachineCode(data);
}

bool MachineCode::verifyMachineCode()
{
    std::string machineCode = getMachineCode();
    
    int matchNum = 0;
    for(int i = 0;i < machinecodelist.size();i++){
        for(int j = 0;j<machinecodelist[i].size();j+=32){
            for(int z = 0;z<machineCode.size();z+=32){
                if(machineCode.substr(z,32)
                   == machinecodelist[i].substr(j,32)
                   ){
                    ++matchNum;
                    if(
                       (double)matchNum/((double)machinecodelist[i].size()/32)>criticalValueOfAuthorization
                       ) return true;
                }
            }
        }
        matchNum=0;
    }
    cout<<"Your Machine Code:"<<machineCode<<endl;
    return false;
}
