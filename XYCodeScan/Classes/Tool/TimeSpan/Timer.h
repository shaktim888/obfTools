#ifndef TimerM_h
#define TimerM_h

#ifndef FOUNDATION_EXPORT
#if defined(__cplusplus)
#define FOUNDATION_EXPORT extern "C"
#else
#define FOUNDATION_EXPORT extern
#endif
#endif

FOUNDATION_EXPORT void Timer_start(char *);
FOUNDATION_EXPORT void Timer_start_print(char * name);
FOUNDATION_EXPORT void Timer_end(char *);
FOUNDATION_EXPORT void Timer_end_print(char *);
FOUNDATION_EXPORT void Timer_reset(void);
FOUNDATION_EXPORT void Timer_summary(void);

#endif
