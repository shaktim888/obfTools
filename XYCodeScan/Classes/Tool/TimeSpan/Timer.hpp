#ifndef Timespan_h
#define Timespan_h
#include <string>
#include <unordered_map>

class Timer {
public:
    static void begin( const std::string& function_name = "Anonymous Function" , bool isPrint = false);
    
    static void end( const std::string& function_name   = "Anonymous Function" , bool isPrint = false);
    static void reset();
    static std::string summary( void );
    
private:
    // Private Functions
    Timer();
    inline static Timer& instance();
    
    // Data Structures
    struct Data {
        double total_run_time, begin_time;
        int count;
        Data() : total_run_time( 0.0 ), begin_time( 0.0 ), count(0) { }
    };
    
    // running time data for the whole program
    Data whole_program;
    std::unordered_map<std::string, Data> datas;
};

Timer& Timer::instance(){
    static Timer t;
    return t;
}

#endif
