#include "Timer.hpp"
#include "Timer.h"
#include <sstream>
#include <string>
#include <iostream>
#include <unordered_map>
#include <ctime>
#include <cstdlib>

using namespace std;


#ifdef WIN32

#include <Windows.h>

static LARGE_INTEGER frequency; // ticks per second

void init_timer( void ){
    QueryPerformanceFrequency(&frequency);
}

double get_current_time() {
    static LARGE_INTEGER t;
    QueryPerformanceCounter(&t);
    return 1000.0 * t.QuadPart /frequency.QuadPart;
}

#else


#include <sys/time.h>

void init_timer( void ){ }

double get_current_time() {
    static timeval t;
    gettimeofday(&t, NULL);
    return 1.0 * t.tv_sec * 1000.0  // sec to ms
    + 1.0 * t.tv_usec / 1000.0; // us to ms
}

#endif



Timer::Timer(){
    init_timer();
    whole_program.begin_time = get_current_time();
    whole_program.count = 1;
}

void Timer::begin( const std::string& func_name , bool isPrint) {
    std::unordered_map<std::string, Data>::iterator it = instance().datas.find( func_name );
    if( it==instance().datas.end() ) {
        instance().datas.insert( pair<std::string, Data>( func_name, Data()) );
        it = instance().datas.find( func_name );
        if(isPrint) {
            std::cout << "start Timer:" << func_name << std::endl;
        }
    }
    it->second.begin_time = get_current_time();
}


void Timer::end( const std::string& func_name , bool isPrint) {
    std::unordered_map<std::string, Data>::iterator it = instance().datas.find( func_name );
    if( it!=instance().datas.end() ) {
        double costTime = get_current_time() - it->second.begin_time;
        it->second.total_run_time += costTime;
        it->second.count++;
        if(isPrint){
            std::cout << "end Timer:" << func_name << " , cost: " << costTime << " ms" << std::endl;
        }
    } else {
        std::cerr << "Error: This function '" << func_name << "' is not defined" << std::endl;
        system( "pause" );
    }
}
void Timer::reset() {
    init_timer();
    instance().whole_program.begin_time = get_current_time();
    instance().whole_program.count = 1;
    instance().datas.clear();
}

std::string Timer::summary( void ) {
    Timer::instance().whole_program.total_run_time = get_current_time() - Timer::instance().whole_program.begin_time;
    
    std::stringstream ss;
    
    static const string func_name    = "Function Name";
    static const int func_name_size    = max((int)func_name.length(),    22);
    
    static const string total_time   = "Total";
    static const int total_time_size   = max((int)total_time.length(),   22);
    
    static const string called_times = "Be Called";
    const int called_times_size = max((int)called_times.length(), 12);
    
    static const string percentage   = "Percentage";
    const int percentage_size   = max((int)percentage.length(),   12);
    
    ss << "+--------------------" << endl;
    ss << "| Profiling Summery ..." << endl;
    ss << "+---------------------------------------" << endl;
    ss << "| ";
    ss.width( func_name_size );
    ss << std::left << func_name;
    ss << " |";
    ss.width( total_time_size );
    ss << std::right << total_time;
    ss << " |";
    ss.width( called_times_size );
    ss << std::right << called_times;
    ss << " |";
    ss.width( percentage_size );
    ss << std::right << percentage;
    ss << " |" << std::endl;
    
    
    double tatol_running_time = Timer::instance().whole_program.total_run_time;
    
    ss << "| ";
    ss.width( func_name_size );
    ss << std::left << "Total Run Time" << " |";
    ss.width( total_time_size - sizeof("ms") );
    ss << std::right << tatol_running_time << " ms |";
    ss.width( called_times_size - sizeof("times") );
    ss << std::right << 1 << " times |";
    ss.width( percentage_size - sizeof("%") );
    ss << std::right << 100.000 << " % |" << endl;
    
    std::unordered_map<std::string, Data>::iterator it;
    for( it = instance().datas.begin(); it != instance().datas.end(); it++ ) {
        ss << "| ";
        ss.width( func_name_size );
        ss << std::left << it->first << " |";
        ss.width( total_time_size - sizeof("ms") );
        ss << std::right<< it->second.total_run_time << " ms |";
        ss.width( called_times_size - sizeof("times") );
        ss << std::right<< it->second.count << " times |";
        ss.width( percentage_size - sizeof("%") );
        ss << std::right<< int( 100000 * it->second.total_run_time / tatol_running_time ) / 1000.0 << " % |" << endl;
    }
    
    return ss.str();
}

void Timer_start(char * name) {
    Timer::begin( name , false);
}

void Timer_start_print(char * name) {
    Timer::begin( name , true);
}

void Timer_end(char * name) {
    Timer::end( name, false);
}

void Timer_end_print(char * name) {
    Timer::end( name, true );
}

void Timer_reset() {
    Timer::reset();
}

void Timer_summary() {
    std::cout << Timer::summary() << std::endl;
}
