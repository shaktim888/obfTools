//
//  myLuaParser.m
//  HYCodeScan
//
//  Created by admin on 2020/5/29.
//  Copyright © 2020 Admin. All rights reserved.
//

#include "myLuaParser.h"
#import "GEN_lua.h"
#define    BUFSIZ    1024
#define    LUA_SIGNATURE    "\033Lua"
#define    lua_Number double
#define    LUAI_USER_ALIGNMENT_T    union { double u; void *s; long l; }
typedef const char * (*lua_Reader) (void *ud, size_t *sz);
typedef int (*lua_Writer) (const void* p, size_t sz, void* ud);
typedef unsigned int Instruction;
typedef LUAI_USER_ALIGNMENT_T L_Umaxalign;
typedef unsigned char lu_byte;
typedef int (*lua_CFunction) (void);
#define lua_str2number(s,p)    strtod((s), (p))
#define luaZ_initbuffer(buff) ((buff)->buffer = NULL, (buff)->buffsize = 0)
#define TValuefields    Value value; int tt
#define cast(t, exp)    ((t)(exp))
#define char2int(c)    cast(int, cast(unsigned char, (c)))
#define EOZ    (-1)            /* end of stream */
#define LUAI_MAXUPVALUES    60
#define LUAI_MAXVARS        200
#define NO_JUMP (-1)
#define lua_assert assert
#define luaK_codeAsBx(fs,o,A,sBx)    luaK_codeABx(fs,o,A,(sBx)+MAXARG_sBx)
#define hasjumps(e)    ((e)->t != (e)->f)
#define setbits(x,m)    ((x) |= (m))
#define l_setbit(x,b)    setbits(x, bitmask(b))
#define LUA_COMPAT_VARARG

#define LUAI_THROW(c)    longjmp((c)->b, 1)
#define LUAI_TRY(c,a)    if (setjmp((c)->b) == 0) { a }
#define luai_jmpbuf    jmp_buf

#define WHITE0BIT    0
#define WHITE1BIT    1
#define BLACKBIT    2
#define FINALIZEDBIT    3
#define KEYWEAKBIT    3
#define VALUEWEAKBIT    4
#define FIXEDBIT    5
#define SFIXEDBIT    6

/* masks for new-style vararg */
#define VARARG_HASARG        1
#define VARARG_ISVARARG        2
#define VARARG_NEEDSARG        4

#define FIRST_RESERVED    257
#define luaS_new(s)    (luaS_newlstr(s, strlen(s)))

#define MAX_INT (INT_MAX-2)  /* maximum value of an int (-2 for safety) */

/*
** limits for opcode arguments.
** we use (signed) int to manipulate most arguments,
** so they must fit in LUAI_BITSINT-1 bits (-1 for sign)
*/
#if SIZE_Bx < LUAI_BITSINT-1
#define MAXARG_Bx        ((1<<SIZE_Bx)-1)
#define MAXARG_sBx        (MAXARG_Bx>>1)         /* `sBx' is signed */
#else
#define MAXARG_Bx        MAX_INT
#define MAXARG_sBx        MAX_INT
#endif

/* int has at least 32 bits */
#define LUAI_BITSINT    32
/* number of list items to accumulate before a SETLIST instruction */
#define LFIELDS_PER_FLUSH    50

/* minimum size for string buffer */
#ifndef LUA_MINBUFFER
#define LUA_MINBUFFER    32
#endif
#define UNARY_PRIORITY    8  /* priority for unary operators */


#define SIZE_C        9
#define SIZE_B        9
#define SIZE_Bx        (SIZE_C + SIZE_B)
#define SIZE_A        8

#define SIZE_OP        6

#define POS_OP        0
#define POS_A        (POS_OP + SIZE_OP)
#define POS_C        (POS_A + SIZE_A)
#define POS_B        (POS_C + SIZE_C)
#define POS_Bx        POS_C

/* creates a mask with `n' 1 bits at position `p' */
#define MASK1(n,p)    ((~((~(Instruction)0)<<n))<<p)

/* creates a mask with `n' 0 bits at position `p' */
#define MASK0(n,p)    (~MASK1(n,p))

/* maximum length of a reserved word */
#define TOKEN_LEN    (sizeof("function")/sizeof(char))

#define luaM_reallocv(b,on,n,e) luaM_realloc_((b), (n)*(e))
#define luaZ_resetbuffer(buff) ((buff)->n = 0)

#define luaM_reallocvector(v,oldn,n,t) \
   ((v)=cast(t *, luaM_reallocv(v, oldn, n, sizeof(t))))

#define luaZ_resizebuffer(buff, size) \
    (luaM_reallocvector((buff)->buffer, (buff)->buffsize, size, char), \
    (buff)->buffsize = size)
#define cast_num(i)    cast(lua_Number, (i))
#define zgetc(z)  (((z)->n--)>0 ?  char2int(*(z)->p++) : luaZ_fill(z))
#define next(ls) do{record(ls, ls->current);(ls->current = zgetc(ls->z));}while(0)
#define currIsNewline(ls)    (ls->current == '\n' || ls->current == '\r')
#define save_and_next(ls)    do{save(ls, ls->current); next(ls);}while(0)
#define luaX_lexerror(msg)   do{luaD_throw(99);}while(0);
#define luaX_syntaxerror(msg)   do{luaD_throw(99);}while(0);
#define LUA_COMPAT_LSTR        1
#define luaZ_buffer(buff)    ((buff)->buffer)
#define luaZ_sizebuffer(buff)    ((buff)->buffsize)
#define luaZ_bufflen(buff)    ((buff)->n)
#define LUA_QL(x)    "'" x "'"
#define LUA_QS        LUA_QL("%s")
#define getOpMode(m)    (cast(enum OpMode, luaP_opmodes[m] & 3))
#define getBMode(m)    (cast(enum OpArgMask, (luaP_opmodes[m] >> 4) & 3))
#define getCMode(m)    (cast(enum OpArgMask, (luaP_opmodes[m] >> 2) & 3))
#define testAMode(m)    (luaP_opmodes[m] & (1 << 6))
#define testTMode(m)    (luaP_opmodes[m] & (1 << 7))

#define GET_OPCODE(i)    (cast(OpCode, ((i)>>POS_OP) & MASK1(SIZE_OP,0)))
#define SET_OPCODE(i,o)    ((i) = (((i)&MASK0(SIZE_OP,POS_OP)) | \
        ((cast(Instruction, o)<<POS_OP)&MASK1(SIZE_OP,POS_OP))))

#define GETARG_A(i)    (cast(int, ((i)>>POS_A) & MASK1(SIZE_A,0)))
#define SETARG_A(i,u)    ((i) = (((i)&MASK0(SIZE_A,POS_A)) | \
        ((cast(Instruction, u)<<POS_A)&MASK1(SIZE_A,POS_A))))

#define GETARG_B(i)    (cast(int, ((i)>>POS_B) & MASK1(SIZE_B,0)))
#define SETARG_B(i,b)    ((i) = (((i)&MASK0(SIZE_B,POS_B)) | \
        ((cast(Instruction, b)<<POS_B)&MASK1(SIZE_B,POS_B))))

#define GETARG_C(i)    (cast(int, ((i)>>POS_C) & MASK1(SIZE_C,0)))
#define SETARG_C(i,b)    ((i) = (((i)&MASK0(SIZE_C,POS_C)) | \
        ((cast(Instruction, b)<<POS_C)&MASK1(SIZE_C,POS_C))))

#define GETARG_Bx(i)    (cast(int, ((i)>>POS_Bx) & MASK1(SIZE_Bx,0)))
#define SETARG_Bx(i,b)    ((i) = (((i)&MASK0(SIZE_Bx,POS_Bx)) | \
        ((cast(Instruction, b)<<POS_Bx)&MASK1(SIZE_Bx,POS_Bx))))

#define GETARG_sBx(i)    (GETARG_Bx(i)-MAXARG_sBx)
#define SETARG_sBx(i,b)    SETARG_Bx((i),cast(unsigned int, (b)+MAXARG_sBx))

#define CREATE_ABC(o,a,b,c)    ((cast(Instruction, o)<<POS_OP) \
            | (cast(Instruction, a)<<POS_A) \
            | (cast(Instruction, b)<<POS_B) \
            | (cast(Instruction, c)<<POS_C))

#define CREATE_ABx(o,a,bc)    ((cast(Instruction, o)<<POS_OP) \
            | (cast(Instruction, a)<<POS_A) \
            | (cast(Instruction, bc)<<POS_Bx))
#define getcode(fs,e)    ((fs)->f->code[(e)->u.s.info])

/* this bit 1 means constant (0 means register) */
#define BITRK        (1 << (SIZE_B - 1))

/* test whether value is a constant */
#define ISK(x)        ((x) & BITRK)
#define hasmultret(k)        ((k) == VCALL || (k) == VVARARG)
/*
* WARNING: if you change the order of this enumeration,
* grep "ORDER RESERVED"
*/
#define check_condition(c,msg)    { if (!(c)) luaX_syntaxerror(msg); }
enum RESERVED {
  /* terminal symbols denoted by reserved words */
  TK_AND = FIRST_RESERVED, TK_BREAK,
  TK_DO, TK_ELSE, TK_ELSEIF, TK_END, TK_FALSE, TK_FOR, TK_FUNCTION,
  TK_IF, TK_IN, TK_LOCAL, TK_NIL, TK_NOT, TK_OR, TK_REPEAT,
  TK_RETURN, TK_THEN, TK_TRUE, TK_UNTIL, TK_WHILE,
  /* other terminal symbols */
  TK_CONCAT, TK_DOTS, TK_EQ, TK_GE, TK_LE, TK_NE, TK_NUMBER,
  TK_NAME, TK_STRING, TK_EOS
};

typedef void (*Pfunc) (void *ud);

/* chain list of long jump buffers */
struct lua_longjmp {
  struct lua_longjmp *previous;
  luai_jmpbuf b;
  volatile int status;  /* error code */
};

/*
** Union of all Lua values
*/
typedef union {
  void *p;
  lua_Number n;
  int b;
} Value;

typedef struct lua_TValue {
  TValuefields;
} TValue;

typedef struct LoadF {
  int extraline;
  FILE *f;
  char buff[BUFSIZ];
} LoadF;

typedef struct Zio {
  size_t n;            /* bytes still unread */
  const char *p;        /* current position in buffer */
  lua_Reader reader;
  void* data;            /* additional data */
} ZIO;

typedef struct Mbuffer {
  char *buffer;
  size_t n;
  size_t buffsize;
} Mbuffer;

struct SParser {  /* data to `f_parser' */
  ZIO *z;
  Mbuffer buff;  /* buffer to be used by the scanner */
  const char *name;
};


typedef union TString {
  L_Umaxalign dummy;  /* ensures maximum alignment for strings */
  struct {
    lu_byte reserved;
    unsigned int hash;
    size_t len;
  } tsv;
} TString;

typedef struct Proto {
  TValue *k;  /* constants used by the function */
  Instruction *code;
  struct Proto **p;  /* functions defined inside the function */
  int *lineinfo;  /* map from opcodes to source lines */
  struct LocVar *locvars;  /* information about local variables */
  TString **upvalues;  /* upvalue names */
  TString  *source;
  int sizeupvalues;
  int sizek;  /* size of `k' */
  int sizecode;
  int sizelineinfo;
  int sizep;  /* size of `p' */
  int sizelocvars;
  int linedefined;
  int lastlinedefined;
  lu_byte nups;  /* number of upvalues */
  lu_byte numparams;
  lu_byte is_vararg;
  lu_byte maxstacksize;
} Proto;

typedef struct UpVal {
  TValue *v;  /* points to stack or to its own value */
  union {
    TValue value;  /* the value (when closed) */
    struct {  /* double linked list (when open) */
      struct UpVal *prev;
      struct UpVal *next;
    } l;
  } u;
} UpVal;

typedef struct CClosure {
  lua_CFunction f;
  TValue upvalue[1];
} CClosure;

typedef struct LClosure {
  struct Proto *p;
  UpVal *upvals[1];
} LClosure;

typedef union {
  lua_Number r;
  TString *ts;
} SemInfo;  /* semantics information */


typedef struct BlockCnt {
  struct BlockCnt *previous;  /* chain */
  int breaklist;  /* list of jumps out of this loop */
  lu_byte nactvar;  /* # active locals outside the breakable structure */
  lu_byte upval;  /* true if some variable in the block is an upvalue */
  lu_byte isbreakable;  /* true if `block' is a loop */
} BlockCnt;

typedef struct Token {
  int token;
  SemInfo seminfo;
} Token;

typedef struct LexState {
  int loopDeep;
  int current;  /* current character (charint) */
  int linenumber;  /* input line counter */
  int lastline;  /* line of last token `consumed' */
  Token t;  /* current token */
  Token lookahead;  /* look ahead token */
  struct FuncState *fs;  /* `FuncState' is private to the parser */
  struct lua_State *L;
  ZIO *z;  /* input stream */
  Mbuffer *buff;  /* buffer for tokens */
  Mbuffer *saveBuff;
  Mbuffer *cacheRead;
  TString *source;  /* current source name */
  char decpoint;  /* locale decimal point */
  short isAdded;
} LexState;

typedef union TKey {
  struct {
    TValuefields;
    struct Node *next;  /* for chaining */
  } nk;
  TValue tvk;
} TKey;

typedef struct Node {
  TValue i_val;
  TKey i_key;
} Node;

typedef struct Table {
  lu_byte flags;  /* 1<<p means tagmethod(p) is not present */
  lu_byte lsizenode;  /* log2 of size of `node' array */
  struct Table *metatable;
  TValue *array;  /* array part */
  Node *node;
  Node *lastfree;  /* any free position is before this position */
  int sizearray;  /* size of `array' array */
} Table;

typedef struct upvaldesc {
  lu_byte k;
  lu_byte info;
} upvaldesc;

typedef struct activeVar
{
    char * name;
    char * type;
} activeVar;

/* state needed to generate code for a given function */
typedef struct FuncState {
  Proto *f;  /* current function header */
  Table *h;  /* table to find (and reuse) elements in `k' */
  struct FuncState *prev;  /* enclosing function */
  struct LexState *ls;  /* lexical state */
  struct BlockCnt *bl;  /* chain of current blocks */
  int pc;  /* next position to code (equivalent to `ncode') */
  int lasttarget;   /* `pc' of last `jump target' */
  int jpc;  /* list of pending jumps to `pc' */
  int freereg;  /* first free register */
  int nk;  /* number of elements in `k' */
  int np;  /* number of elements in `p' */
  short nlocvars;  /* number of elements in `locvars' */
  lu_byte nactvar;  /* number of active local variables */
  upvaldesc upvalues[LUAI_MAXUPVALUES];  /* upvalues */
  unsigned short actvar[LUAI_MAXVARS];  /* declared-variable stack */
} FuncState;

typedef union Closure {
  CClosure c;
  LClosure l;
} Closure;

static const char *getF (void *ud, size_t *size) {
    LoadF *lf = (LoadF *)ud;
    if (lf->extraline) {
        lf->extraline = 0;
        *size = 1;
        return "\n";
    }
    if (feof(lf->f)) return NULL;
    *size = fread(lf->buff, 1, sizeof(lf->buff), lf->f);
    return (*size > 0) ? lf->buff : NULL;
}

static void luaZ_init (ZIO *z, lua_Reader reader, void *data) {
  z->reader = reader;
  z->data = data;
  z->n = 0;
  z->p = NULL;
}

typedef enum UnOpr { OPR_MINUS, OPR_NOT, OPR_LEN, OPR_NOUNOPR } UnOpr;

typedef enum {
  VVOID,    /* no value */
  VNIL,
  VTRUE,
  VFALSE,
  VK,        /* info = index of constant in `k' */
  VKNUM,    /* nval = numerical value */
  VLOCAL,    /* info = local register */
  VUPVAL,       /* info = index of upvalue in `upvalues' */
  VGLOBAL,    /* info = index of table; aux = index of global name in `k' */
  VINDEXED,    /* info = table register; aux = index register (or `k') */
  VJMP,        /* info = instruction pc */
  VRELOCABLE,    /* info = instruction pc */
  VNONRELOC,    /* info = result register */
  VCALL,    /* info = instruction pc */
  VVARARG    /* info = instruction pc */
} expkind;

enum OpArgMask {
  OpArgN,  /* argument is not used */
  OpArgU,  /* argument is used */
  OpArgR,  /* argument is a register or a jump offset */
  OpArgK   /* argument is a constant or register/constant */
};

typedef enum BinOpr {
  OPR_ADD, OPR_SUB, OPR_MUL, OPR_DIV, OPR_MOD, OPR_POW,
  OPR_CONCAT,
  OPR_NE, OPR_EQ,
  OPR_LT, OPR_LE, OPR_GT, OPR_GE,
  OPR_AND, OPR_OR,
  OPR_NOBINOPR
} BinOpr;

static const struct {
  lu_byte left;  /* left priority for each binary operator */
  lu_byte right; /* right priority */
} priority[] = {  /* ORDER OPR */
   {6, 6}, {6, 6}, {7, 7}, {7, 7}, {7, 7},  /* `+' `-' `/' `%' */
   {10, 9}, {5, 4},                 /* power and concat (right associative) */
   {3, 3}, {3, 3},                  /* equality and inequality */
   {3, 3}, {3, 3}, {3, 3}, {3, 3},  /* order */
   {2, 2}, {1, 1}                   /* logical (and/or) */
};

enum OpMode {iABC, iABx, iAsBx};  /* basic instruction format */

typedef struct expdesc {
  expkind k;
  union {
    struct { int info, aux; } s;
    lua_Number nval;
  } u;
  int t;  /* patch list of `exit when true' */
  int f;  /* patch list of `exit when false' */
} expdesc;

struct ConsControl {
  expdesc v;  /* last list item read */
  expdesc *t;  /* table descriptor */
  int nh;  /* total number of `record' elements */
  int na;  /* total number of array elements */
  int tostore;  /* number of array elements pending to be stored */
};

struct LHS_assign {
  struct LHS_assign *prev;
  expdesc v;  /* variable (global, local, upvalue, or indexed) */
};

typedef struct error_State {
  struct lua_longjmp *errorJmp;  /* current error recover point */
  ptrdiff_t errfunc;  /* current error handling function (stack index) */
} error_State;

// function declare
static int llex (LexState *ls, SemInfo *seminfo);
static void block (LexState *ls);
static int statement (LexState *ls);
static void expr (LexState *ls, expdesc *v);
static TString *str_checkname (LexState *ls);
static void leaveblock (FuncState *fs);

typedef enum {
/*----------------------------------------------------------------------
name        args    description
------------------------------------------------------------------------*/
OP_MOVE,/*    A B    R(A) := R(B)                    */
OP_LOADK,/*    A Bx    R(A) := Kst(Bx)                    */
OP_LOADBOOL,/*    A B C    R(A) := (Bool)B; if (C) pc++            */
OP_LOADNIL,/*    A B    R(A) := ... := R(B) := nil            */
OP_GETUPVAL,/*    A B    R(A) := UpValue[B]                */

OP_GETGLOBAL,/*    A Bx    R(A) := Gbl[Kst(Bx)]                */
OP_GETTABLE,/*    A B C    R(A) := R(B)[RK(C)]                */

OP_SETGLOBAL,/*    A Bx    Gbl[Kst(Bx)] := R(A)                */
OP_SETUPVAL,/*    A B    UpValue[B] := R(A)                */
OP_SETTABLE,/*    A B C    R(A)[RK(B)] := RK(C)                */

OP_NEWTABLE,/*    A B C    R(A) := {} (size = B,C)                */

OP_SELF,/*    A B C    R(A+1) := R(B); R(A) := R(B)[RK(C)]        */

OP_ADD,/*    A B C    R(A) := RK(B) + RK(C)                */
OP_SUB,/*    A B C    R(A) := RK(B) - RK(C)                */
OP_MUL,/*    A B C    R(A) := RK(B) * RK(C)                */
OP_DIV,/*    A B C    R(A) := RK(B) / RK(C)                */
OP_MOD,/*    A B C    R(A) := RK(B) % RK(C)                */
OP_POW,/*    A B C    R(A) := RK(B) ^ RK(C)                */
OP_UNM,/*    A B    R(A) := -R(B)                    */
OP_NOT,/*    A B    R(A) := not R(B)                */
OP_LEN,/*    A B    R(A) := length of R(B)                */

OP_CONCAT,/*    A B C    R(A) := R(B).. ... ..R(C)            */

OP_JMP,/*    sBx    pc+=sBx                    */

OP_EQ,/*    A B C    if ((RK(B) == RK(C)) ~= A) then pc++        */
OP_LT,/*    A B C    if ((RK(B) <  RK(C)) ~= A) then pc++          */
OP_LE,/*    A B C    if ((RK(B) <= RK(C)) ~= A) then pc++          */

OP_TEST,/*    A C    if not (R(A) <=> C) then pc++            */
OP_TESTSET,/*    A B C    if (R(B) <=> C) then R(A) := R(B) else pc++    */

OP_CALL,/*    A B C    R(A), ... ,R(A+C-2) := R(A)(R(A+1), ... ,R(A+B-1)) */
OP_TAILCALL,/*    A B C    return R(A)(R(A+1), ... ,R(A+B-1))        */
OP_RETURN,/*    A B    return R(A), ... ,R(A+B-2)    (see note)    */

OP_FORLOOP,/*    A sBx    R(A)+=R(A+2);
            if R(A) <?= R(A+1) then { pc+=sBx; R(A+3)=R(A) }*/
OP_FORPREP,/*    A sBx    R(A)-=R(A+2); pc+=sBx                */

OP_TFORLOOP,/*    A C    R(A+3), ... ,R(A+2+C) := R(A)(R(A+1), R(A+2));
                        if R(A+3) ~= nil then R(A+2)=R(A+3) else pc++    */
OP_SETLIST,/*    A B C    R(A)[(C-1)*FPF+i] := R(A+i), 1 <= i <= B    */

OP_CLOSE,/*    A     close all variables in the stack up to (>=) R(A)*/
OP_CLOSURE,/*    A Bx    R(A) := closure(KPROTO[Bx], R(A), ... ,R(A+n))    */

OP_VARARG/*    A B    R(A), R(A+1), ..., R(A+B-1) = vararg        */
} OpCode;

/* ORDER RESERVED */
const char *const luaX_tokens [] = {
    "and", "break", "do", "else", "elseif",
    "end", "false", "for", "function", "if",
    "in", "local", "nil", "not", "or", "repeat",
    "return", "then", "true", "until", "while",
    "..", "...", "==", ">=", "<=", "~=",
    "<number>", "<name>", "<string>", "<eof>",
    NULL
};
/* number of reserved words */
#define NUM_RESERVED    (cast(int, TK_WHILE-FIRST_RESERVED+1))

#define opmode(t,a,b,c,m) (((t)<<7) | ((a)<<6) | ((b)<<4) | ((c)<<2) | (m))
#define NUM_OPCODES    (cast(int, OP_VARARG) + 1)


const lu_byte luaP_opmodes[NUM_OPCODES] = {
/*       T  A    B       C     mode           opcode    */
  opmode(0, 1, OpArgR, OpArgN, iABC)         /* OP_MOVE */
 ,opmode(0, 1, OpArgK, OpArgN, iABx)        /* OP_LOADK */
 ,opmode(0, 1, OpArgU, OpArgU, iABC)        /* OP_LOADBOOL */
 ,opmode(0, 1, OpArgR, OpArgN, iABC)        /* OP_LOADNIL */
 ,opmode(0, 1, OpArgU, OpArgN, iABC)        /* OP_GETUPVAL */
 ,opmode(0, 1, OpArgK, OpArgN, iABx)        /* OP_GETGLOBAL */
 ,opmode(0, 1, OpArgR, OpArgK, iABC)        /* OP_GETTABLE */
 ,opmode(0, 0, OpArgK, OpArgN, iABx)        /* OP_SETGLOBAL */
 ,opmode(0, 0, OpArgU, OpArgN, iABC)        /* OP_SETUPVAL */
 ,opmode(0, 0, OpArgK, OpArgK, iABC)        /* OP_SETTABLE */
 ,opmode(0, 1, OpArgU, OpArgU, iABC)        /* OP_NEWTABLE */
 ,opmode(0, 1, OpArgR, OpArgK, iABC)        /* OP_SELF */
 ,opmode(0, 1, OpArgK, OpArgK, iABC)        /* OP_ADD */
 ,opmode(0, 1, OpArgK, OpArgK, iABC)        /* OP_SUB */
 ,opmode(0, 1, OpArgK, OpArgK, iABC)        /* OP_MUL */
 ,opmode(0, 1, OpArgK, OpArgK, iABC)        /* OP_DIV */
 ,opmode(0, 1, OpArgK, OpArgK, iABC)        /* OP_MOD */
 ,opmode(0, 1, OpArgK, OpArgK, iABC)        /* OP_POW */
 ,opmode(0, 1, OpArgR, OpArgN, iABC)        /* OP_UNM */
 ,opmode(0, 1, OpArgR, OpArgN, iABC)        /* OP_NOT */
 ,opmode(0, 1, OpArgR, OpArgN, iABC)        /* OP_LEN */
 ,opmode(0, 1, OpArgR, OpArgR, iABC)        /* OP_CONCAT */
 ,opmode(0, 0, OpArgR, OpArgN, iAsBx)        /* OP_JMP */
 ,opmode(1, 0, OpArgK, OpArgK, iABC)        /* OP_EQ */
 ,opmode(1, 0, OpArgK, OpArgK, iABC)        /* OP_LT */
 ,opmode(1, 0, OpArgK, OpArgK, iABC)        /* OP_LE */
 ,opmode(1, 1, OpArgR, OpArgU, iABC)        /* OP_TEST */
 ,opmode(1, 1, OpArgR, OpArgU, iABC)        /* OP_TESTSET */
 ,opmode(0, 1, OpArgU, OpArgU, iABC)        /* OP_CALL */
 ,opmode(0, 1, OpArgU, OpArgU, iABC)        /* OP_TAILCALL */
 ,opmode(0, 0, OpArgU, OpArgN, iABC)        /* OP_RETURN */
 ,opmode(0, 1, OpArgR, OpArgN, iAsBx)        /* OP_FORLOOP */
 ,opmode(0, 1, OpArgR, OpArgN, iAsBx)        /* OP_FORPREP */
 ,opmode(1, 0, OpArgN, OpArgU, iABC)        /* OP_TFORLOOP */
 ,opmode(0, 0, OpArgU, OpArgU, iABC)        /* OP_SETLIST */
 ,opmode(0, 0, OpArgN, OpArgN, iABC)        /* OP_CLOSE */
 ,opmode(0, 1, OpArgU, OpArgN, iABx)        /* OP_CLOSURE */
 ,opmode(0, 1, OpArgU, OpArgN, iABC)        /* OP_VARARG */
};

static void *luaM_realloc_ (void *block, size_t nsize) {
  block = realloc(block, nsize);
  return block;
}
static error_State * global_error_state = 0;
static void luaD_throw (int errcode) {
  if(global_error_state && global_error_state->errorJmp) {
    global_error_state->errorJmp->status = errcode;
    LUAI_THROW(global_error_state->errorJmp);
  }
  else {
    exit(EXIT_FAILURE);
  }
}

static void record(LexState *ls, int c) {
    if(c== EOZ || c==EOF) return;
    Mbuffer* b = ls->cacheRead;
    if (b->n + 1 > b->buffsize) {
      size_t newsize;
      newsize = b->buffsize * 2;
      luaZ_resizebuffer(b, newsize);
    }
    b->buffer[b->n++] = cast(char, c);
}

static void saveCacheReaded(LexState * ls) {
    ls->isAdded = 0;
    Mbuffer* bc = ls->cacheRead;
    Mbuffer* b = ls->saveBuff;
    size_t targetLen = b->n + bc->n;
    while (targetLen > b->buffsize) {
      size_t newsize;
      newsize = b->buffsize * 2;
      luaZ_resizebuffer(b, newsize);
    }
    for(int i = 0; i < bc->n; i++) {
        b->buffer[b->n++] = bc->buffer[i];
    }
    luaZ_resetbuffer(bc);
}

static void recordString(LexState *ls, const char* str) {
    ls->isAdded = 1;
    size_t len = strlen(str);
    Mbuffer* b = ls->saveBuff;
    size_t targetLen = b->n + len;
    while (targetLen > b->buffsize) {
      size_t newsize;
      newsize = b->buffsize * 2;
      luaZ_resizebuffer(b, newsize);
    }
    for(int i = 0; i < len; i++) {
        b->buffer[b->n++] = str[i];
    }
}

static void addRandomCode(LexState * ls) {
    if(ls->isAdded) return;
    if(ls->loopDeep == 0) {
//        recordString(ls, "\n"
//                     "tttttt");
        recordString(ls, [[[GEN_lua sharedInstance] genOneCode] UTF8String]);
    }
}

static int luaZ_fill (ZIO *z) {
  size_t size;
  const char *buff;
  buff = z->reader(z->data, &size);
  if (buff == NULL || size == 0) return EOZ;
  z->n = size - 1;
  z->p = buff;
  return char2int(*(z->p++));
}

static int luaZ_lookahead (ZIO *z) {
  if (z->n == 0) {
    if (luaZ_fill(z) == EOZ)
      return EOZ;
    else {
      z->n++;  /* luaZ_fill removed first byte; put back it */
      z->p--;
    }
  }
  return char2int(*z->p);
}


static void luaX_setinput (LexState *ls, ZIO *z) {
    ls->loopDeep = 0;
    ls->decpoint = '.';
    ls->lookahead.token = TK_EOS;  /* no look-ahead token */
    ls->current = EOZ;
    ls->z = z;
    ls->fs = NULL;
    ls->linenumber = 1;
    ls->lastline = 1;
    ls->isAdded = 0;
    luaZ_initbuffer(ls->saveBuff);
    luaZ_resetbuffer(ls->saveBuff);
    
    luaZ_initbuffer(ls->cacheRead);
    luaZ_resetbuffer(ls->cacheRead);
    
    luaZ_resizebuffer(ls->saveBuff, LUA_MINBUFFER);
    luaZ_resizebuffer(ls->cacheRead, LUA_MINBUFFER);
    luaZ_resizebuffer(ls->buff, LUA_MINBUFFER);  /* initialize buffer */
    next(ls);  /* read first char */
}

static void open_func (LexState *ls, FuncState *fs) {
  fs->prev = ls->fs;  /* linked list of funcstates */
  fs->ls = ls;
  ls->fs = fs;
  fs->pc = 0;
  fs->lasttarget = -1;
  fs->jpc = NO_JUMP;
  fs->freereg = 0;
  fs->nk = 0;
  fs->np = 0;
  fs->nlocvars = 0;
  fs->nactvar = 0;
  fs->bl = NULL;
    [[GEN_lua sharedInstance] enterBlock];
}

static void inclinenumber (LexState *ls) {
    int old = ls->current;
    lua_assert(currIsNewline(ls));
    next(ls);  /* skip `\n' or `\r' */
    if (currIsNewline(ls) && ls->current != old)
        next(ls);  /* skip `\n\r' or `\r\n' */
}

static void save (LexState *ls, int c) {
  Mbuffer *b = ls->buff;
  if (b->n + 1 > b->buffsize) {
    size_t newsize;
    newsize = b->buffsize * 2;
    luaZ_resizebuffer(b, newsize);
  }
  b->buffer[b->n++] = cast(char, c);
}


static int skip_sep (LexState *ls) {
  int count = 0;
  int s = ls->current;
  lua_assert(s == '[' || s == ']');
  save_and_next(ls);
  while (ls->current == '=') {
    save_and_next(ls);
    count++;
  }
  return (ls->current == s) ? count : (-count) - 1;
}

static TString *luaX_newstring (LexState *ls, const char *str, size_t l) {
//  TString *ts = luaS_newlstr(L, str, l);
//  TValue *o = luaH_setstr(L, ls->fs->h, ts);  /* entry for `str' */
//  if (ttisnil(o))
//    setbvalue(o, 1);  /* make sure `str' will not be collected */
//  return ts;
    return 0;
}

static void read_long_string (LexState *ls, SemInfo *seminfo, int sep) {
  int cont = 0;
  (void)(cont);  /* avoid warnings when `cont' is not used */
  save_and_next(ls);  /* skip 2nd `[' */
  if (currIsNewline(ls))  /* string starts with a newline? */
    inclinenumber(ls);  /* skip it */
  for (;;) {
    switch (ls->current) {
      case EOZ:
        luaX_lexerror((seminfo) ? "unfinished long string" :
                                   "unfinished long comment");
        break;  /* to avoid warnings */
#if defined(LUA_COMPAT_LSTR)
      case '[': {
        if (skip_sep(ls) == sep) {
          save_and_next(ls);  /* skip 2nd `[' */
          cont++;
#if LUA_COMPAT_LSTR == 1
          if (sep == 0)
            luaX_lexerror("nesting of [[...]] is deprecated");
#endif
        }
        break;
      }
#endif
      case ']': {
        if (skip_sep(ls) == sep) {
          save_and_next(ls);  /* skip 2nd `]' */
#if defined(LUA_COMPAT_LSTR) && LUA_COMPAT_LSTR == 2
          cont--;
          if (sep == 0 && cont >= 0) break;
#endif
          goto endloop;
        }
        break;
      }
      case '\n':
      case '\r': {
        save(ls, '\n');
        inclinenumber(ls);
        if (!seminfo) luaZ_resetbuffer(ls->buff);  /* avoid wasting space */
        break;
      }
      default: {
        if (seminfo) save_and_next(ls);
        else next(ls);
      }
    }
  } endloop:
  if (seminfo)
  {
      seminfo->ts = luaX_newstring(ls, luaZ_buffer(ls->buff) + (2 + sep), luaZ_bufflen(ls->buff) - 2*(2 + sep));
  }
}

static void luaX_next (LexState *ls) {
  ls->lastline = ls->linenumber;
  if (ls->lookahead.token != TK_EOS) {  /* is there a look-ahead token? */
    ls->t = ls->lookahead;  /* use this one */
    ls->lookahead.token = TK_EOS;  /* and discharge it */
  }
  else
    ls->t.token = llex(ls, &ls->t.seminfo);  /* read next token */
}

static int testnext (LexState *ls, int c) {
  if (ls->t.token == c) {
    luaX_next(ls);
    return 1;
  }
  else return 0;
}

static void read_string (LexState *ls, int del, SemInfo *seminfo) {
  save_and_next(ls);
  while (ls->current != del) {
    switch (ls->current) {
      case EOZ:
        luaX_lexerror("unfinished string");
        continue;  /* to avoid warnings */
      case '\n':
      case '\r':
        luaX_lexerror("unfinished string");
        continue;  /* to avoid warnings */
      case '\\': {
        int c;
        next(ls);  /* do not save the `\' */
        switch (ls->current) {
          case 'a': c = '\a'; break;
          case 'b': c = '\b'; break;
          case 'f': c = '\f'; break;
          case 'n': c = '\n'; break;
          case 'r': c = '\r'; break;
          case 't': c = '\t'; break;
          case 'v': c = '\v'; break;
          case '\n':  /* go through */
          case '\r': save(ls, '\n'); inclinenumber(ls); continue;
          case EOZ: continue;  /* will raise an error next loop */
          default: {
            if (!isdigit(ls->current))
              save_and_next(ls);  /* handles \\, \", \', and \? */
            else {  /* \xxx */
              int i = 0;
              c = 0;
              do {
                c = 10*c + (ls->current-'0');
                next(ls);
              } while (++i<3 && isdigit(ls->current));
              if (c > UCHAR_MAX)
                luaX_lexerror("escape sequence too large");
              save(ls, c);
            }
            continue;
          }
        }
        save(ls, c);
        next(ls);
        continue;
      }
      default:
        save_and_next(ls);
    }
  }
  save_and_next(ls);  /* skip delimiter */
  seminfo->ts = luaX_newstring(ls, luaZ_buffer(ls->buff) + 1,
                                   luaZ_bufflen(ls->buff) - 2);
}

static int check_next (LexState *ls, const char *set) {
  if (!strchr(set, ls->current))
    return 0;
  save_and_next(ls);
  return 1;
}

static void buffreplace (LexState *ls, char from, char to) {
  size_t n = luaZ_bufflen(ls->buff);
  char *p = luaZ_buffer(ls->buff);
  while (n--)
    if (p[n] == from) p[n] = to;
}

static int luaO_str2d (const char *s, lua_Number *result) {
  char *endptr;
  *result = lua_str2number(s, &endptr);
  if (endptr == s) return 0;  /* conversion failed */
  if (*endptr == 'x' || *endptr == 'X')  /* maybe an hexadecimal constant? */
    *result = cast_num(strtoul(s, &endptr, 16));
  if (*endptr == '\0') return 1;  /* most common case */
  while (isspace(cast(unsigned char, *endptr))) endptr++;
  if (*endptr != '\0') return 0;  /* invalid trailing characters? */
  return 1;
}

static void trydecpoint (LexState *ls, SemInfo *seminfo) {
  /* format error: try to update decimal point separator */
  struct lconv *cv = localeconv();
  char old = ls->decpoint;
  ls->decpoint = (cv ? cv->decimal_point[0] : '.');
  buffreplace(ls, old, ls->decpoint);  /* try updated decimal separator */
  if (!luaO_str2d(luaZ_buffer(ls->buff), &seminfo->r)) {
    /* format error with correct decimal point: no more options */
    buffreplace(ls, ls->decpoint, '.');  /* undo change (for error message) */
    luaX_lexerror("malformed number");
  }
}


/* LUA_NUMBER */
static void read_numeral (LexState *ls, SemInfo *seminfo) {
  lua_assert(isdigit(ls->current));
  do {
    save_and_next(ls);
  } while (isdigit(ls->current) || ls->current == '.');
  if (check_next(ls, "Ee"))  /* `E'? */
    check_next(ls, "+-");  /* optional exponent sign */
  while (isalnum(ls->current) || ls->current == '_')
    save_and_next(ls);
  save(ls, '\0');
  buffreplace(ls, '.', ls->decpoint);  /* follow locale for decimal point */
  if (!luaO_str2d(luaZ_buffer(ls->buff), &seminfo->r))  /* format error? */
    trydecpoint(ls, seminfo); /* try to update decimal point separator */
}


static int getStrToken (const char * str, size_t len) {
  int i;
  for (i=0; i<NUM_RESERVED; i++) {
      if(strlen(luaX_tokens[i]) == len && memcmp(str, luaX_tokens[i], len) == 0) {
          return i + FIRST_RESERVED;
      }
  }
  return -1;
}

static int llex (LexState *ls, SemInfo *seminfo) {
  luaZ_resetbuffer(ls->buff);
  saveCacheReaded(ls);
  for (;;) {
    switch (ls->current) {
      case '\n':
      case '\r': {
        inclinenumber(ls);
        continue;
      }
      case '-': {
        next(ls);
        if (ls->current != '-') return '-';
        /* else is a comment */
        next(ls);
        if (ls->current == '[') {
          int sep = skip_sep(ls);
          luaZ_resetbuffer(ls->buff);  /* `skip_sep' may dirty the buffer */
          if (sep >= 0) {
            read_long_string(ls, NULL, sep);  /* long comment */
            luaZ_resetbuffer(ls->buff);
            continue;
          }
        }
        /* else short comment */
        while (!currIsNewline(ls) && ls->current != EOZ)
          next(ls);
        continue;
      }
      case '[': {
        int sep = skip_sep(ls);
        if (sep >= 0) {
          read_long_string(ls, seminfo, sep);
          return TK_STRING;
        }
        else if (sep == -1) return '[';
        else luaX_lexerror("invalid long string delimiter");
      }
      case '=': {
        next(ls);
        if (ls->current != '=') return '=';
        else { next(ls); return TK_EQ; }
      }
      case '<': {
        next(ls);
        if (ls->current != '=') return '<';
        else { next(ls); return TK_LE; }
      }
      case '>': {
        next(ls);
        if (ls->current != '=') return '>';
        else { next(ls); return TK_GE; }
      }
      case '~': {
        next(ls);
        if (ls->current != '=') return '~';
        else { next(ls); return TK_NE; }
      }
      case '"':
      case '\'': {
        read_string(ls, ls->current, seminfo);
        return TK_STRING;
      }
      case '.': {
        save_and_next(ls);
        if (check_next(ls, ".")) {
          if (check_next(ls, "."))
            return TK_DOTS;   /* ... */
          else return TK_CONCAT;   /* .. */
        }
        else if (!isdigit(ls->current)) return '.';
        else {
          read_numeral(ls, seminfo);
          return TK_NUMBER;
        }
      }
      case EOZ: {
        return TK_EOS;
      }
      default: {
        if (isspace(ls->current)) {
          lua_assert(!currIsNewline(ls));
          next(ls);
          continue;
        }
        else if (isdigit(ls->current)) {
          read_numeral(ls, seminfo);
          return TK_NUMBER;
        }
        else if (isalpha(ls->current) || ls->current == '_') {
          /* identifier or reserved word */
//          TString *ts;
          do {
            save_and_next(ls);
          } while (isalnum(ls->current) || ls->current == '_');
            int tk = getStrToken(ls->buff->buffer, ls->buff->n);
            if(tk >= 0) {
                return tk;
            }
//          ts = luaX_newstring(ls, luaZ_buffer(ls->buff),
//                                  luaZ_bufflen(ls->buff));
//          if (ts->tsv.reserved > 0)  /* reserved word? */
//            return ts->tsv.reserved - 1 + FIRST_RESERVED;
//          else {
//            seminfo->ts = ts;
            return TK_NAME;
//          }
        }
        else {
          int c = ls->current;
          next(ls);
          return c;  /* single-char tokens (+ - / ...) */
        }
      }
    }
  }
}

static void error_expected (LexState *ls, int token) {
    luaX_lexerror("not expect");
}

static void check (LexState *ls, int c) {
  if (ls->t.token != c)
    error_expected(ls, c);
}

//static void nextUtilToken(LexState *ls, int c) {
//    while (ls->t.token != EOZ && ls->t.token != c)
//        luaX_next(ls);
//}

static void checknext (LexState *ls, int c) {
  check(ls, c);
  luaX_next(ls);
}

static void luaX_lookahead (LexState *ls) {
    if(ls->lookahead.token != TK_EOS) {
        return;
    }
    ls->lookahead.token = llex(ls, &ls->lookahead.seminfo);
}


static void enterlevel (LexState *ls) {
    
}

static int block_follow (int token) {
  switch (token) {
    case TK_ELSE: case TK_ELSEIF: case TK_END:
    case TK_UNTIL: case TK_EOS:
      return 1;
    default: return 0;
  }
}

static UnOpr getunopr (int op) {
  switch (op) {
    case TK_NOT: return OPR_NOT;
    case '-': return OPR_MINUS;
    case '#': return OPR_LEN;
    default: return OPR_NOUNOPR;
  }
}

static void enterblock (FuncState *fs, BlockCnt *bl, lu_byte isbreakable) {
  bl->breaklist = NO_JUMP;
  bl->isbreakable = isbreakable;
  bl->nactvar = fs->nactvar;
  bl->upval = 0;
  bl->previous = fs->bl;
  fs->bl = bl;
//  lua_assert(fs->freereg == fs->nactvar);
    [[GEN_lua sharedInstance] enterBlock];
}

static void leavelevel(LexState * ls) {
    
}

static void chunk (LexState *ls) {
  /* chunk -> { stat [`;'] } */
  int islast = 0;
  enterlevel(ls);
  while (!islast && !block_follow(ls->t.token)) {
    islast = statement(ls);
    testnext(ls, ';');
//    lua_assert(ls->fs->f->maxstacksize >= ls->fs->freereg &&
//               ls->fs->freereg >= ls->fs->nactvar);
//    ls->fs->freereg = ls->fs->nactvar;  /* free registers */
  }
  leavelevel(ls);
  if(!islast) addRandomCode(ls);
}


static void luaK_prefix (FuncState *fs, UnOpr op, expdesc *e) {
  expdesc e2;
  e2.t = e2.f = NO_JUMP; e2.k = VKNUM; e2.u.nval = 0;
  switch (op) {
    case OPR_MINUS: {
      break;
    }
    case OPR_NOT: break;
    case OPR_LEN: {
      break;
    }
    default: lua_assert(0);
  }
}

static void init_exp (expdesc *e, expkind k, int i) {
  e->f = e->t = NO_JUMP;
  e->k = k;
  e->u.s.info = i;
}

static void codestring (LexState *ls, expdesc *e, TString *s) {
  init_exp(e, VK, 0);
}

static void checkname(LexState *ls, expdesc *e) {
  codestring(ls, e, str_checkname(ls));
}

static void closelistfield (FuncState *fs, struct ConsControl *cc) {
  if (cc->v.k == VVOID) return;  /* there is no list item */
//  luaK_exp2nextreg(fs, &cc->v);
  cc->v.k = VVOID;
  if (cc->tostore == LFIELDS_PER_FLUSH) {
//    luaK_setlist(fs, cc->t->u.s.info, cc->na, cc->tostore);  /* flush */
    cc->tostore = 0;  /* no more items pending */
  }
}

static void listfield (LexState *ls, struct ConsControl *cc) {
  expr(ls, &cc->v);
//  luaY_checklimit(ls->fs, cc->na, MAX_INT, "items in a constructor");
  cc->na++;
  cc->tostore++;
}

static void yindex (LexState *ls, expdesc *v) {
  /* index -> '[' expr ']' */
  luaX_next(ls);  /* skip the '[' */
  expr(ls, v);
//  luaK_exp2val(ls->fs, v);
  checknext(ls, ']');
}

static void recfield (LexState *ls, struct ConsControl *cc) {
  /* recfield -> (NAME | `['exp1`]') = exp1 */
  FuncState *fs = ls->fs;
  int reg = ls->fs->freereg;
  expdesc key, val;
//  int rkkey;
  if (ls->t.token == TK_NAME) {
//    luaY_checklimit(fs, cc->nh, MAX_INT, "items in a constructor");
    checkname(ls, &key);
  }
  else  /* ls->t.token == '[' */
    yindex(ls, &key);
  cc->nh++;
  checknext(ls, '=');
//  rkkey = luaK_exp2RK(fs, &key);
  expr(ls, &val);
//  luaK_codeABC(fs, OP_SETTABLE, cc->t->u.s.info, rkkey, luaK_exp2RK(fs, &val));
  fs->freereg = reg;  /* free registers */
}

static void check_match (LexState *ls, int what, int who, int where) {
  if (!testnext(ls, what)) {
    if (where == ls->linenumber)
      error_expected(ls, what);
    else {
      luaX_syntaxerror(" expected (to close at line)");
    }
  }
}


static void lastlistfield (FuncState *fs, struct ConsControl *cc) {
  if (cc->tostore == 0) return;
  if (hasmultret(cc->v.k)) {
//    luaK_setmultret(fs, &cc->v);
//    luaK_setlist(fs, cc->t->u.s.info, cc->na, LUA_MULTRET);
    cc->na--;  /* do not count last expression (unknown number of elements) */
  }
  else {
//    if (cc->v.k != VVOID)
//      luaK_exp2nextreg(fs, &cc->v);
//    luaK_setlist(fs, cc->t->u.s.info, cc->na, cc->tostore);
  }
}

static void constructor (LexState *ls, expdesc *t) {
  /* constructor -> ?? */
  FuncState *fs = ls->fs;
  int line = ls->linenumber;
//  int pc = luaK_codeABC(fs, OP_NEWTABLE, 0, 0, 0);
  struct ConsControl cc;
  cc.na = cc.nh = cc.tostore = 0;
  cc.t = t;
  init_exp(t, VRELOCABLE, 0);
  init_exp(&cc.v, VVOID, 0);  /* no value (yet) */
//  luaK_exp2nextreg(ls->fs, t);  /* fix it at stack top (for gc) */
  checknext(ls, '{');
  do {
    lua_assert(cc.v.k == VVOID || cc.tostore > 0);
    if (ls->t.token == '}') break;
    closelistfield(fs, &cc);
    switch(ls->t.token) {
      case TK_NAME: {  /* may be listfields or recfields */
        luaX_lookahead(ls);
        if (ls->lookahead.token != '=')  /* expression? */
          listfield(ls, &cc);
        else
          recfield(ls, &cc);
        break;
      }
      case '[': {  /* constructor_item -> recfield */
        recfield(ls, &cc);
        break;
      }
      default: {  /* constructor_part -> listfield */
        listfield(ls, &cc);
        break;
      }
    }
  } while (testnext(ls, ',') || testnext(ls, ';'));
  check_match(ls, '}', '{', line);
  lastlistfield(fs, &cc);
//  SETARG_B(fs->f->code[pc], luaO_int2fb(cc.na)); /* set initial array size */
//  SETARG_C(fs->f->code[pc], luaO_int2fb(cc.nh));  /* set initial table size */
}

static void parlist (LexState *ls) {
  /* parlist -> [ param { `,' param } ] */
//  FuncState *fs = ls->fs;
//  Proto *f = fs->f;
//  int nparams = 0;
  bool is_vararg = 0;
  if (ls->t.token != ')') {  /* is `parlist' not empty? */
    do {
      switch (ls->t.token) {
        case TK_NAME: {  /* param -> NAME */
            str_checkname(ls);
//          new_localvar(ls, str_checkname(ls), nparams++);
          break;
        }
        case TK_DOTS: {  /* param -> `...' */
          luaX_next(ls);
#if defined(LUA_COMPAT_VARARG)
          /* use `arg' as default name */
//          new_localvarliteral(ls, "arg", nparams++);
          is_vararg = VARARG_HASARG | VARARG_NEEDSARG;
#endif
          is_vararg |= VARARG_ISVARARG;
          break;
        }
        default: luaX_syntaxerror("<name> or " LUA_QL("...") " expected");
      }
    } while (!is_vararg && testnext(ls, ','));
  }
//  adjustlocalvars(ls, nparams);
//  f->numparams = cast_byte(fs->nactvar - (f->is_vararg & VARARG_HASARG));
//  luaK_reserveregs(fs, fs->nactvar);  /* reserve register for parameters */
}

static void anchor_token (LexState *ls) {
  if (ls->t.token == TK_NAME || ls->t.token == TK_STRING) {
//    TString *ts = ls->t.seminfo.ts;
//    luaX_newstring(ls, getstr(ts), ts->tsv.len);
  }
}

static TString *str_checkname (LexState *ls) {
//  TString *ts;
//  check(ls, TK_NAME);
//  ts = ls->t.seminfo.ts;
    luaX_next(ls);
//  return ts;
    return 0;
}

static void close_func (LexState *ls) {
//  lua_State *L = ls->L;
  FuncState *fs = ls->fs;
//  Proto *f = fs->f;
//  removevars(ls, 0);
//  luaK_ret(fs, 0, 0);  /* final return */
//  luaM_reallocvector(L, f->code, f->sizecode, fs->pc, Instruction);
//  f->sizecode = fs->pc;
//  luaM_reallocvector(L, f->lineinfo, f->sizelineinfo, fs->pc, int);
//  f->sizelineinfo = fs->pc;
//  luaM_reallocvector(L, f->k, f->sizek, fs->nk, TValue);
//  f->sizek = fs->nk;
//  luaM_reallocvector(L, f->p, f->sizep, fs->np, Proto *);
//  f->sizep = fs->np;
//  luaM_reallocvector(L, f->locvars, f->sizelocvars, fs->nlocvars, LocVar);
//  f->sizelocvars = fs->nlocvars;
//  luaM_reallocvector(L, f->upvalues, f->sizeupvalues, f->nups, TString *);
//  f->sizeupvalues = f->nups;
//  lua_assert(luaG_checkcode(f));
//  lua_assert(fs->bl == NULL);
  ls->fs = fs->prev;
//  L->top -= 2;  /* remove table and prototype from the stack */
  /* last token read was anchored in defunct function; must reanchor it */
  if (fs) anchor_token(ls);
    [[GEN_lua sharedInstance] exitBlock];
}

static void body (LexState *ls, expdesc *e, int needself, int line) {
  /* body ->  `(' parlist `)' chunk END */
  FuncState new_fs;
  open_func(ls, &new_fs);
//  new_fs.f->linedefined = line;
  checknext(ls, '(');
//  if (needself) {
//    new_localvarliteral(ls, "self", 0);
//    adjustlocalvars(ls, 1);
//  }
  parlist(ls);
  checknext(ls, ')');
  chunk(ls);
//  new_fs.f->lastlinedefined = ls->linenumber;
  check_match(ls, TK_END, TK_FUNCTION, line);
  close_func(ls);
//  pushclosure(ls, &new_fs, e);
}

static void singlevar (LexState *ls, expdesc *var) {
  str_checkname(ls);
//  FuncState *fs = ls->fs;
//  if (singlevaraux(fs, varname, var, 1) == VGLOBAL)
//    var->u.s.info = luaK_stringK(fs, varname);  /* info points to global name */
}
//
//static void discharge2reg (FuncState *fs, expdesc *e, int reg) {
//  luaK_dischargevars(fs, e);
//  switch (e->k) {
//    case VNIL: {
//      luaK_nil(fs, reg, 1);
//      break;
//    }
//    case VFALSE:  case VTRUE: {
//      luaK_codeABC(fs, OP_LOADBOOL, reg, e->k == VTRUE, 0);
//      break;
//    }
//    case VK: {
//      luaK_codeABx(fs, OP_LOADK, reg, e->u.s.info);
//      break;
//    }
//    case VKNUM: {
//      luaK_codeABx(fs, OP_LOADK, reg, luaK_numberK(fs, e->u.nval));
//      break;
//    }
//    case VRELOCABLE: {
//      Instruction *pc = &getcode(fs, e);
//      SETARG_A(*pc, reg);
//      break;
//    }
//    case VNONRELOC: {
//      if (reg != e->u.s.info)
//        luaK_codeABC(fs, OP_MOVE, reg, e->u.s.info, 0);
//      break;
//    }
//    default: {
//      lua_assert(e->k == VVOID || e->k == VJMP);
//      return;  /* nothing to do... */
//    }
//  }
//  e->u.s.info = reg;
//  e->k = VNONRELOC;
//}

static void prefixexp (LexState *ls, expdesc *v) {
  /* prefixexp -> NAME | '(' expr ')' */
  switch (ls->t.token) {
    case '(': {
      int line = ls->linenumber;
      luaX_next(ls);
      expr(ls, v);
      check_match(ls, ')', '(', line);
//      luaK_dischargevars(ls->fs, v);
      return;
    }
    case TK_NAME: {
      singlevar(ls, v);
      return;
    }
    default: {
      luaX_syntaxerror( "unexpected symbol");
      return;
    }
  }
}


static void field (LexState *ls, expdesc *v) {
  /* field -> ['.' | ':'] NAME */
//  FuncState *fs = ls->fs;
  expdesc key;
//  luaK_exp2anyreg(fs, v);
  luaX_next(ls);  /* skip the dot or colon */
  checkname(ls, &key);
//  luaK_indexed(fs, v, &key);
}

static int explist1 (LexState *ls, expdesc *v) {
  /* explist1 -> expr { `,' expr } */
  int n = 1;  /* at least one expression */
  expr(ls, v);
  while (testnext(ls, ',')) {
//    luaK_exp2nextreg(ls->fs, v);
    expr(ls, v);
    n++;
  }
  return n;
}

static void funcargs (LexState *ls, expdesc *f) {
//  FuncState *fs = ls->fs;
  expdesc args;
  int base
//    , nparams
    ;
  int line = ls->linenumber;
  switch (ls->t.token) {
    case '(': {  /* funcargs -> `(' [ explist1 ] `)' */
      if (line != ls->lastline)
        luaX_syntaxerror("ambiguous syntax (function call x new statement)");
      luaX_next(ls);
      if (ls->t.token == ')')  /* arg list is empty? */
        args.k = VVOID;
      else {
        explist1(ls, &args);
//        luaK_setmultret(fs, &args);
      }
      check_match(ls, ')', '(', line);
      break;
    }
    case '{': {  /* funcargs -> constructor */
      constructor(ls, &args);
      break;
    }
    case TK_STRING: {  /* funcargs -> STRING */
      codestring(ls, &args, ls->t.seminfo.ts);
      luaX_next(ls);  /* must use `seminfo' before `next' */
      break;
    }
    default: {
      luaX_syntaxerror( "function arguments expected");
      return;
    }
  }
//  lua_assert(f->k == VNONRELOC);
  base = f->u.s.info;  /* base register for call */
//  if (hasmultret(args.k))
//  {
//    nparams = LUA_MULTRET;  /* open call */
//  }
//  else {
//    if (args.k != VVOID)
//      luaK_exp2nextreg(fs, &args);  /* close last argument */
//    nparams = fs->freereg - (base+1);
//  }
  init_exp(f, VCALL,0);
//  luaK_fixline(fs, line);
//  fs->freereg = base+1;  /* call remove function and arguments and leaves
//                            (unless changed) one result */
}

static void primaryexp (LexState *ls, expdesc *v) {
  /* primaryexp ->
        prefixexp { `.' NAME | `[' exp `]' | `:' NAME funcargs | funcargs } */
//  FuncState *fs = ls->fs;
  prefixexp(ls, v);
  for (;;) {
    switch (ls->t.token) {
      case '.': {  /* field */
        field(ls, v);
        break;
      }
      case '[': {  /* `[' exp1 `]' */
        expdesc key;
//        luaK_exp2anyreg(fs, v);
        yindex(ls, &key);
//        luaK_indexed(fs, v, &key);
        break;
      }
      case ':': {  /* `:' NAME funcargs */
        expdesc key;
        luaX_next(ls);
        checkname(ls, &key);
//        luaK_self(fs, v, &key);
        funcargs(ls, v);
        break;
      }
      case '(': case TK_STRING: case '{': {  /* funcargs */
//        luaK_exp2nextreg(fs, v);
        // 随便设置一下
        v->k = VNIL;
        funcargs(ls, v);
        break;
      }
      default: return;
    }
  }
}


static void simpleexp (LexState *ls, expdesc *v) {
  /* simpleexp -> NUMBER | STRING | NIL | true | false | ... |
                  constructor | FUNCTION body | primaryexp */
  switch (ls->t.token) {
    case TK_NUMBER: {
      init_exp(v, VKNUM, 0);
//      v->u.nval = ls->t.seminfo.r;
      break;
    }
    case TK_STRING: {
      codestring(ls, v, ls->t.seminfo.ts);
      break;
    }
    case TK_NIL: {
      init_exp(v, VNIL, 0);
      break;
    }
    case TK_TRUE: {
      init_exp(v, VTRUE, 0);
      break;
    }
    case TK_FALSE: {
      init_exp(v, VFALSE, 0);
      break;
    }
    case TK_DOTS: {  /* vararg */
//      FuncState *fs = ls->fs;
//      check_condition(fs->f->is_vararg,
//                      "cannot use " LUA_QL("...") " outside a vararg function");
//      fs->f->is_vararg &= ~VARARG_NEEDSARG;  /* don't need 'arg' */
      init_exp(v, VVARARG, 0);
      break;
    }
    case '{': {  /* constructor */
      constructor(ls, v);
      return;
    }
    case TK_FUNCTION: {
      luaX_next(ls);
      body(ls, v, 0, ls->linenumber);
      return;
    }
    default: {
      primaryexp(ls, v);
      return;
    }
  }
  luaX_next(ls);
}

static BinOpr getbinopr (int op) {
  switch (op) {
    case '+': return OPR_ADD;
    case '-': return OPR_SUB;
    case '*': return OPR_MUL;
    case '/': return OPR_DIV;
    case '%': return OPR_MOD;
    case '^': return OPR_POW;
    case TK_CONCAT: return OPR_CONCAT;
    case TK_NE: return OPR_NE;
    case TK_EQ: return OPR_EQ;
    case '<': return OPR_LT;
    case TK_LE: return OPR_LE;
    case '>': return OPR_GT;
    case TK_GE: return OPR_GE;
    case TK_AND: return OPR_AND;
    case TK_OR: return OPR_OR;
    default: return OPR_NOBINOPR;
  }
}

static BinOpr subexpr (LexState *ls, expdesc *v, unsigned int limit) {
  BinOpr op;
  UnOpr uop;
  enterlevel(ls);
  uop = getunopr(ls->t.token);
  if (uop != OPR_NOUNOPR) {
    luaX_next(ls);
    subexpr(ls, v, UNARY_PRIORITY);
    luaK_prefix(ls->fs, uop, v);
  }
  else simpleexp(ls, v);
  /* expand while operators have priorities higher than `limit' */
  op = getbinopr(ls->t.token);
  while (op != OPR_NOBINOPR && priority[op].left > limit) {
    expdesc v2;
    BinOpr nextop;
    luaX_next(ls);
//    luaK_infix(ls->fs, op, v);
    /* read sub-expression with higher priority */
    nextop = subexpr(ls, &v2, priority[op].right);
//    luaK_posfix(ls->fs, op, v, &v2);
    op = nextop;
  }
  leavelevel(ls);
  return op;  /* return first untreated operator */
}

static void expr (LexState *ls, expdesc *v) {
  subexpr(ls, v, 0);
}

static int cond (LexState *ls) {
  /* cond -> exp */
  expdesc v;
  expr(ls, &v);  /* read condition */
  if (v.k == VNIL) v.k = VFALSE;  /* `falses' are all equal here */
//  luaK_goiftrue(ls->fs, &v);
  return v.f;
}

static int test_then_block (LexState *ls) {
  /* test_then_block -> [IF | ELSEIF] cond THEN block */
  int condexit;
  luaX_next(ls);  /* skip IF or ELSEIF */
  condexit = cond(ls);
  checknext(ls, TK_THEN);
//  nextUtilToken(ls, TK_THEN);
  block(ls);  /* `then' part */
  return condexit;
}

static void ifstat (LexState *ls, int line) {
  /* ifstat -> IF cond THEN block {ELSEIF cond THEN block} [ELSE block] END */
//  FuncState *fs = ls->fs;
  int flist;
//  int escapelist = NO_JUMP;
  flist = test_then_block(ls);  /* IF cond THEN block */
  while (ls->t.token == TK_ELSEIF) {
//    luaK_concat(fs, &escapelist, luaK_jump(fs));
//    luaK_patchtohere(fs, flist);
    flist = test_then_block(ls);  /* ELSEIF cond THEN block */
  }
  if (ls->t.token == TK_ELSE) {
//    luaK_concat(fs, &escapelist, luaK_jump(fs));
//    luaK_patchtohere(fs, flist);
    luaX_next(ls);  /* skip ELSE (after patch, for correct line info) */
    block(ls);  /* `else' part */
  }
//  else
//    luaK_concat(fs, &escapelist, flist);
//  luaK_patchtohere(fs, escapelist);
  check_match(ls, TK_END, TK_IF, line);
}


static void whilestat (LexState *ls, int line) {
  /* whilestat -> WHILE cond DO block END */
  FuncState *fs = ls->fs;
  ls->loopDeep++;
//  int whileinit;
  int condexit;
  BlockCnt bl;
  luaX_next(ls);  /* skip WHILE */
//  whileinit = luaK_getlabel(fs);
  condexit = cond(ls);
  enterblock(fs, &bl, 1);
  checknext(ls, TK_DO);
  block(ls);
//  luaK_patchlist(fs, luaK_jump(fs), whileinit);
  check_match(ls, TK_END, TK_WHILE, line);
  leaveblock(fs);
//  luaK_patchtohere(fs, condexit);  /* false conditions finish the loop */
  ls->loopDeep--;
}

static int exp1 (LexState *ls) {
  expdesc e;
  int k;
  expr(ls, &e);
  k = e.k;
//  luaK_exp2nextreg(ls->fs, &e);
  return k;
}

static void forbody (LexState *ls, int base, int line, int nvars, int isnum) {
  /* forbody -> DO block */
  BlockCnt bl;
  FuncState *fs = ls->fs;
//  int prep, endfor;
//  adjustlocalvars(ls, 3);  /* control variables */
  checknext(ls, TK_DO);
//  prep = isnum ? luaK_codeAsBx(fs, OP_FORPREP, base, NO_JUMP) : luaK_jump(fs);
  enterblock(fs, &bl, 0);  /* scope for declared variables */
//  adjustlocalvars(ls, nvars);
//  luaK_reserveregs(fs, nvars);
  block(ls);
  leaveblock(fs);  /* end of scope for declared variables */
//  luaK_patchtohere(fs, prep);
//  endfor = (isnum) ? luaK_codeAsBx(fs, OP_FORLOOP, base, NO_JUMP) :
//                     luaK_codeABC(fs, OP_TFORLOOP, base, 0, nvars);
//  luaK_fixline(fs, line);  /* pretend that `OP_FOR' starts the loop */
//  luaK_patchlist(fs, (isnum ? endfor : luaK_jump(fs)), prep + 1);
}

static void fornum (LexState *ls, int line, TString *varname) {
  /* fornum -> NAME = exp1,exp1[,exp1] forbody */
  FuncState *fs = ls->fs;
  int base = fs->freereg;
//  new_localvarliteral(ls, "(for index)", 0);
//  new_localvarliteral(ls, "(for limit)", 1);
//  new_localvarliteral(ls, "(for step)", 2);
//  new_localvar(ls, varname, 3);
  checknext(ls, '=');
  exp1(ls);  /* initial value */
  checknext(ls, ',');
  exp1(ls);  /* limit */
  if (testnext(ls, ','))
    exp1(ls);  /* optional step */
  else {  /* default step = 1 */
//    luaK_codeABx(fs, OP_LOADK, fs->freereg, luaK_numberK(fs, 1));
//    luaK_reserveregs(fs, 1);
  }
  forbody(ls, base, line, 1, 1);
}

static void forlist (LexState *ls, TString *indexname) {
  /* forlist -> NAME {,NAME} IN explist1 forbody */
  FuncState *fs = ls->fs;
  expdesc e;
  int nvars = 0;
  int line;
  int base = fs->freereg;
  /* create control variables */
//  new_localvarliteral(ls, "(for generator)", nvars++);
//  new_localvarliteral(ls, "(for state)", nvars++);
//  new_localvarliteral(ls, "(for control)", nvars++);
  /* create declared variables */
//  new_localvar(ls, indexname, nvars++);
  while (testnext(ls, ',')){
      str_checkname(ls);
      //    new_localvar(ls, str_checkname(ls), nvars++);
  }
  checknext(ls, TK_IN);
  line = ls->linenumber;
  explist1(ls, &e);
//  adjust_assign(ls, 3, explist1(ls, &e), &e);
//  luaK_checkstack(fs, 3);  /* extra space to call generator */
  forbody(ls, base, line, nvars - 3, 0);
}

static void leaveblock (FuncState *fs) {
  BlockCnt *bl = fs->bl;
  fs->bl = bl->previous;
    [[GEN_lua sharedInstance] exitBlock];
//  removevars(fs->ls, bl->nactvar);
//  if (bl->upval)
//    luaK_codeABC(fs, OP_CLOSE, bl->nactvar, 0, 0);
  /* a block either controls scope or breaks (never both) */
//  lua_assert(!bl->isbreakable || !bl->upval);
//  lua_assert(bl->nactvar == fs->nactvar);
//  fs->freereg = fs->nactvar;  /* free registers */
//  luaK_patchtohere(fs, bl->breaklist);
}

static void forstat (LexState *ls, int line) {
  /* forstat -> FOR (fornum | forlist) END */
  FuncState *fs = ls->fs;
  TString *varname = 0;
  BlockCnt bl;
  ls->loopDeep++;
  enterblock(fs, &bl, 1);  /* scope for loop and control variables */
  luaX_next(ls);  /* skip `for' */
  varname = str_checkname(ls);  /* first variable name */
  switch (ls->t.token) {
    case '=': fornum(ls, line, varname); break;
    case ',': case TK_IN: forlist(ls, varname); break;
    default: luaX_syntaxerror(LUA_QL("=") " or " LUA_QL("in") " expected");
  }
  check_match(ls, TK_END, TK_FOR, line);
  leaveblock(fs);  /* loop scope (`break' jumps to this point) */
  ls->loopDeep--;
}
//
//static void breakstat (LexState *ls) {
//  FuncState *fs = ls->fs;
//  BlockCnt *bl = fs->bl;
//  int upval = 0;
//  while (bl && !bl->isbreakable) {
//    upval |= bl->upval;
//    bl = bl->previous;
//  }
//  if (!bl)
//    luaX_syntaxerror(ls, "no loop to break");
//  if (upval)
//    luaK_codeABC(fs, OP_CLOSE, bl->nactvar, 0, 0);
//  luaK_concat(fs, &bl->breaklist, luaK_jump(fs));
//}


static void repeatstat (LexState *ls, int line) {
  /* repeatstat -> REPEAT block UNTIL cond */
  int condexit;
  FuncState *fs = ls->fs;
    ls->loopDeep++;
//  int repeat_init = luaK_getlabel(fs);
  BlockCnt bl1, bl2;
  enterblock(fs, &bl1, 1);  /* loop block */
  enterblock(fs, &bl2, 0);  /* scope block */
  luaX_next(ls);  /* skip REPEAT */
  chunk(ls);
  check_match(ls, TK_UNTIL, TK_REPEAT, line);
  condexit = cond(ls);  /* read condition (inside scope block) */
  if (!bl2.upval) {  /* no upvalues? */
    leaveblock(fs);  /* finish scope */
//    luaK_patchlist(ls->fs, condexit, repeat_init);  /* close the loop */
  }
  else {  /* complete semantics when there are upvalues */
//    breakstat(ls);  /* if condition then break */
//    luaK_patchtohere(ls->fs, condexit);  /* else... */
    leaveblock(fs);  /* finish scope... */
//    luaK_patchlist(ls->fs, luaK_jump(fs), repeat_init);  /* and repeat */
  }
  leaveblock(fs);  /* finish loop */
    ls->loopDeep--;
}

static int funcname (LexState *ls, expdesc *v) {
  /* funcname -> NAME {field} [`:' NAME] */
  int needself = 0;
  singlevar(ls, v);
  while (ls->t.token == '.')
    field(ls, v);
  if (ls->t.token == ':') {
    needself = 1;
    field(ls, v);
  }
  return needself;
}

static void funcstat (LexState *ls, int line) {
  /* funcstat -> FUNCTION funcname body */
  int needself;
  expdesc v, b;
  luaX_next(ls);  /* skip FUNCTION */
  needself = funcname(ls, &v);
  body(ls, &b, needself, line);
//  luaK_storevar(ls->fs, &v, &b);
//  luaK_fixline(ls->fs, line);  /* definition `happens' in the first line */
}

static void localfunc (LexState *ls) {
  expdesc v, b;
//  FuncState *fs = ls->fs;
  str_checkname(ls);
//  new_localvar(ls, str_checkname(ls), 0);
  init_exp(&v, VLOCAL, 0);
//  luaK_reserveregs(fs, 1);
//  adjustlocalvars(ls, 1);
  body(ls, &b, 0, ls->linenumber);
//  luaK_storevar(fs, &v, &b);
  /* debug information will only see the variable after this point! */
//  getlocvar(fs, fs->nactvar - 1).startpc = fs->pc;
}

static void localstat (LexState *ls) {
  /* stat -> LOCAL NAME {`,' NAME} [`=' explist1] */
//  int nvars = 0;
  int nexps;
  expdesc e;
  do {
      str_checkname(ls);
//    new_localvar(ls, str_checkname(ls), nvars++);
  } while (testnext(ls, ','));
  if (testnext(ls, '='))
    nexps = explist1(ls, &e);
  else {
    e.k = VVOID;
    nexps = 0;
  }
//  adjust_assign(ls, nvars, nexps, &e);
//  adjustlocalvars(ls, nvars);
    addRandomCode(ls);
}

static void retstat (LexState *ls) {
  /* stat -> RETURN explist */
//  FuncState *fs = ls->fs;
  expdesc e;
  int first, nret;  /* registers with returned values */
  luaX_next(ls);  /* skip RETURN */
  if (block_follow(ls->t.token) || ls->t.token == ';')
    first = nret = 0;  /* return no values */
  else {
    nret = explist1(ls, &e);  /* optional return values */
//    if (hasmultret(e.k)) {
//      luaK_setmultret(fs, &e);
//      if (e.k == VCALL && nret == 1) {  /* tail call? */
//        SET_OPCODE(getcode(fs,&e), OP_TAILCALL);
//        lua_assert(GETARG_A(getcode(fs,&e)) == fs->nactvar);
//      }
//      first = fs->nactvar;
//      nret = LUA_MULTRET;  /* return all values */
//    }
//    else {
//      if (nret == 1)  /* only one single value? */
//        first = luaK_exp2anyreg(fs, &e);
//      else {
//        luaK_exp2nextreg(fs, &e);  /* values must go to the `stack' */
//        first = fs->nactvar;  /* return all `active' values */
//        lua_assert(nret == fs->freereg - first);
//      }
//    }
  }
//  luaK_ret(fs, first, nret);
}

static void breakstat (LexState *ls) {
//  FuncState *fs = ls->fs;
//  BlockCnt *bl = fs->bl;
//  int upval = 0;
//  while (bl && !bl->isbreakable) {
//    upval |= bl->upval;
//    bl = bl->previous;
//  }
//  if (!bl)
//    luaX_syntaxerror(ls, "no loop to break");
//  if (upval)
//    luaK_codeABC(fs, OP_CLOSE, bl->nactvar, 0, 0);
//  luaK_concat(fs, &bl->breaklist, luaK_jump(fs));
}

static void assignment (LexState *ls, struct LHS_assign *lh, int nvars) {
  expdesc e;
//  check_condition( VLOCAL <= lh->v.k && lh->v.k <= VINDEXED,
//                      "syntax error");
  if (testnext(ls, ',')) {  /* assignment -> `,' primaryexp assignment */
    struct LHS_assign nv;
    nv.prev = lh;
    primaryexp(ls, &nv.v);
//    if (nv.v.k == VLOCAL)
//      check_conflict(ls, lh, &nv.v);
//    luaY_checklimit(ls->fs, nvars, LUAI_MAXCCALLS - ls->L->nCcalls,
//                    "variables in assignment");
    assignment(ls, &nv, nvars+1);
  }
  else {  /* assignment -> `=' explist1 */
    int nexps;
    checknext(ls, '=');
    nexps = explist1(ls, &e);
//    if (nexps != nvars) {
//      adjust_assign(ls, nvars, nexps, &e);
//      if (nexps > nvars)
//        ls->fs->freereg -= nexps - nvars;  /* remove extra values */
//    }
//    else {
//      luaK_setoneret(ls->fs, &e);  /* close last expression */
//      luaK_storevar(ls->fs, &lh->v, &e);
//      return;  /* avoid default */
//    }
  }
  init_exp(&e, VNONRELOC,0 );  /* default assignment */
//  luaK_storevar(ls->fs, &lh->v, &e);
}

static void exprstat (LexState *ls) {
  /* stat -> func | assignment */
//  FuncState *fs = ls->fs;
  struct LHS_assign v;
  primaryexp(ls, &v.v);
  if (v.v.k == VCALL){  /* stat -> func */
      // 清空一下状态
      v.v.k = VNIL;
//    SETARG_C(getcode(fs, &v.v), 1);  /* call statement uses no results */
  } else {  /* stat -> assignment */
//    v.prev = NULL;
    assignment(ls, &v, 1);
  }
  addRandomCode(ls);
}

static int statement (LexState *ls) {
  int line = ls->linenumber;  /* may be needed for error messages */
    int ret = 0;
    switch (ls->t.token) {
        case TK_IF: {  /* stat -> ifstat */
          ifstat(ls, line);
          ret = 0;
          break;
        }
        case TK_WHILE: {  /* stat -> whilestat */
          whilestat(ls, line);
          ret = 0;
          break;
        }
        case TK_DO: {  /* stat -> DO block END */
          luaX_next(ls);  /* skip DO */
          block(ls);
          check_match(ls, TK_END, TK_DO, line);
          ret = 0;
          break;
        }
        case TK_FOR: {  /* stat -> forstat */
          forstat(ls, line);
          ret = 0;
          break;
        }
        case TK_REPEAT: {  /* stat -> repeatstat */
          repeatstat(ls, line);
          ret = 0;
          break;
        }
        case TK_FUNCTION: {
          funcstat(ls, line);  /* stat -> funcstat */
          ret = 0;
          break;
        }
        case TK_LOCAL: {  /* stat -> localstat */
          luaX_next(ls);  /* skip LOCAL */
          if (testnext(ls, TK_FUNCTION))  /* local function? */
            localfunc(ls);
          else
            localstat(ls);
          ret = 0;
          break;
        }
        case TK_RETURN: {  /* stat -> retstat */
          retstat(ls);
          ret = 1;  /* must be last statement */
          break;
        }
        case TK_BREAK: {  /* stat -> breakstat */
          luaX_next(ls);  /* skip BREAK */
          breakstat(ls);
          ret = 1;  /* must be last statement */
          break;
        }
        default: {
          exprstat(ls);
          ret = 0;  /* to avoid warnings */
          break;
        }
    }
    return ret;
}

static void block (LexState *ls) {
  /* block -> chunk */
  FuncState *fs = ls->fs;
  BlockCnt bl;
  enterblock(fs, &bl, 0);
  chunk(ls);
  lua_assert(bl.breaklist == NO_JUMP);
  leaveblock(fs);
}

static Proto *luaY_parser (ZIO *z, Mbuffer *buff, Mbuffer * savebuff) {
  struct LexState lexstate;
  struct FuncState funcstate;
  Mbuffer cacheReaded;
  lexstate.buff = buff;
  lexstate.saveBuff = savebuff;
  lexstate.cacheRead = &cacheReaded;
  luaX_setinput(&lexstate, z);
  open_func(&lexstate, &funcstate);
  luaX_next(&lexstate);  /* read first token */
  chunk(&lexstate);
  check(&lexstate, TK_EOS);
  close_func(&lexstate);
//  lua_assert(funcstate.prev == NULL);
//  lua_assert(funcstate.f->nups == 0);
//  lua_assert(lexstate.fs == NULL);
  return funcstate.f;
}

static void f_parser (void * ud, Mbuffer* savebuff) {
//  int i;
  Proto *tf;
//  Closure *cl;
  struct SParser *p = cast(struct SParser *, ud);
  luaZ_lookahead(p->z);
  tf = luaY_parser(p->z,&p->buff, savebuff);
//  cl = luaF_newLclosure(L, tf->nups, hvalue(gt(L)));
//  cl->l.p = tf;
//  for (i = 0; i < tf->nups; i++)  /* initialize eventual upvalues */
//    cl->l.upvals[i] = luaF_newupval(L);
//  setclvalue(L, L->top, cl);
//  incr_top(L);
}

static void luaZ_freebuffer(Mbuffer* buff)
{
    
}

static int luaD_protectedparser (ZIO *z, Mbuffer* buff) {
  struct SParser p;
//  int status;
  p.z = z;
  luaZ_initbuffer(&p.buff);
  f_parser(&p, buff);
//  status = luaD_pcall(L, f_parser, &p, savestack(L, L->top), L->errfunc);
  luaZ_freebuffer(&p.buff);
  return 0;
}

static int lua_load (lua_Reader reader, void *data, Mbuffer* buff) {
    struct lua_longjmp lj;
    error_State state;
    state.errorJmp = &lj;
    global_error_state = &state;
    lj.status = 0;
    lj.previous = 0;  /* chain new error handler */
    LUAI_TRY( &lj,
      ZIO z;
      luaZ_init(&z, reader, data);
      luaD_protectedparser(&z, buff);
    );
    global_error_state = 0;
    [[GEN_lua sharedInstance] clean];
    return lj.status;
}

int parserLua (const char *filename, const char * writename) {
    Mbuffer saveBuff;
    LoadF lf;
    int status, readstatus;
    int c;
    lf.extraline = 0;
    lf.f = fopen(filename, "r");
    if (lf.f == NULL)
        return 0;
    
    c = getc(lf.f);
    if (c == '#') {  /* Unix exec. file? */
        lf.extraline = 1;
        while ((c = getc(lf.f)) != EOF && c != '\n') ;  /* skip first line */
        if (c == '\n') c = getc(lf.f);
    }
//    if (c == LUA_SIGNATURE[0] && filename) {  /* binary file? */
//        lf.f = freopen(filename, "rb", lf.f);  /* reopen in binary mode */
//        if (lf.f == NULL)
//            return 0;
//        /* skip eventual `#!...' */
//        while ((c = getc(lf.f)) != EOF && c != LUA_SIGNATURE[0]);
//        lf.extraline = 0;
//    }
    ungetc(c, lf.f);
    status = lua_load(getF, &lf, &saveBuff);
    readstatus = ferror(lf.f);
    if (filename) fclose(lf.f);  /* close file (even in case of errors) */
    if(status == 0) {
        FILE * fw = fopen(writename, "w");
        if (fw == NULL)
            return 0;
        fwrite(saveBuff.buffer, saveBuff.n, 1, fw);
        fclose(fw);
    } else {
        printf("解析lua文件出错:%s\n", filename);
    }
    if (readstatus) {
        return 0;
    }
    return status;
}
