/*
 *  libctrace.c
 * 
 *  Copyright 2008 Aurelian Melinte. 
 *  Released under GPL 3.0 or later. 
 *
 *  Call monitoring demo. 
 */

#include <execinfo.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <assert.h>
#include <pthread.h>
#include "addr2line.h"
#include <stack>
#include <string>
#include <boost/format.hpp>

#  define EXTERNC extern "C" 

using namespace std;

std::stack<string> functionStack;

/* 
  http://pdos.csail.mit.edu/6.828/2004/lec/l2.html
 
   * x86 dictates that stack grows down
   * GCC dictates how the stack is used. 
     Contract between caller and callee on x86: 
       after call instruction: 
           %eip points at first instruction of function 
           %esp+4 points at first argument 
           %esp points at return address 
       after ret instruction: 
           %eip contains return address 
           %esp points at arguments pushed by caller 
           called function may have trashed arguments 
           %ebx contains return value (or trash if function is void) <== was eax!
           %ecx, %edx may be trashed 
           %ebp, %ebx, %esi, %edi must contain contents from time of call 
       Terminology: 
           %eax, %ecx, %edx are "caller save" registers 
           %ebp, %ebx, %esi, %edi are "callee save" registers 
       each function has a stack frame marked by %ebp, %esp 
               +------------+   |brPoints
               | arg 2      |   \
               +------------+    >- previous function's stack frame
               | arg 1      |   /
               +------------+   |
               | ret %eip   |   /
               +============+   
               | saved %ebp |   \
        %ebp-> +------------+   |
               |            |   |
               |   local    |   \
               | variables, |    >- current function's stack frame
               |    etc.    |   /
               |            |   |
               |            |   |
        %esp-> +------------+   /


 */

/*
 * First's argument offset with respect to the frame.  Dependent on
 * optimizations made by the compiler.  The value below is the 
 * non-optimized one. 
 */
#define ARG_OFFET     (2) 
/*
 * gcc 4.1.2 && -O0 : return value is stored in the ebx register. 
 */
#define GET_EBX(var)  __asm__ __volatile__( "movq %%rbx, %0" : "=a"(var) ) 
#define SET_EBX(var)  __asm__ __volatile__( "movq %0, %%rbx" : :"a"(var) ) 

#define PROG_START_ADDR  0x08048000
#define STACK_START_ADDR 0xBFFFFFFF


static void
print_stack( void )
{
    void *array[10];
    size_t size;
    char **strings;
    size_t i;
  
    size = backtrace (array, 10);
    strings = backtrace_symbols (array, size);
  
    printf ("Obtained %zd stack frames.\n", size);
  
    for (i = 0; i < size; i++)
        printf ("%s\n", strings[i]);
  
    free (strings);
}


/*Number of occurences of 'ch' in 'str'. */
static int
nchr(const char *str, char ch)
{
    int n = 0;
    while (*str != '\0') {
        if (*str == ch)
            n++;
        str++;
    }
    return n; 
}

/*A not-very-sophisticated function to print arguments. */
static char *
args(char *buf, int len, int nargs, int *frame)
{
    int i; 
    int offset;
    
    memset(buf, 0, len); 
    
    snprintf(buf, len, "("); 
    offset = 1; 
/*
    for (i=0; i< offset<len; i++) {
        offset += snprintf(buf+offset, len-offset, "%d%s", 
                         *(frame+ARG_OFFET+i), 
                         i==nargs-1 ? " ...)" : ", ");
    }
  */  
    for (i=0; i< 10; i++) {
        offset += snprintf(buf+offset, len-offset, "%p%s", 
                         *(frame+i), ", ");
    }

    return buf; 
}

/*Is it a void returning function or not? */
static int
returns_void(const char *func_sig)
{
    if (NULL == strstr(func_sig, "void "))
        return 1;
    return 0; 
}

static int
is_cpp(const char *func_sig)
{
    if (NULL == strstr(func_sig, "::"))
        return 0;
    return 1; 
}


/*
 * Print only the first MAX_ARG_SHOW. 
 */
#define MAX_ARG_SHOW   (10) 
#define CTRACE_BUF_LEN (127)
#define ARG_BUF_LEN    (12*(MAX_ARG_SHOW+1))

EXTERNC void 
__cyg_profile_func_enter( void *func, void *callsite )
{
    char buf_func[CTRACE_BUF_LEN+1] = {0};
    char buf_file[CTRACE_BUF_LEN+1] = {0}; 
    char buf_args[ARG_BUF_LEN + 1] = {0}; 
    pthread_t self = (pthread_t)0;
    int *frame = NULL;
    int *frame1 = NULL;
    int nargs = 0;
    int isCPP = 0;
    int thisPointer = 0;
    

    
    self = pthread_self(); 
    frame = (int *)__builtin_frame_address(0); /*of the 'func'*/
    thisPointer = *(frame+6);
    
    frame = (int *)__builtin_frame_address(1); /*of the 'func'*/
    
    assert(frame != NULL); 
    
    /* Function Entry Address */
    
    /*Which function*/
    libtrace_resolve (func, buf_func, CTRACE_BUF_LEN, NULL, 0);
    /*From where*/
    libtrace_resolve (callsite, NULL, 0, buf_file, CTRACE_BUF_LEN);
    nargs = nchr(buf_func, ',') + 1 /*Last arg has no comma after*/; 
    isCPP += is_cpp(buf_func);      /*'this'*/
    
    string objectName;
    string functionName;
    string functionFullName(buf_func);
    int pos = functionFullName.find("::");
    
    if ( pos > 0 )
    {
       objectName   = functionFullName.substr(0, pos);
       functionName = functionFullName.substr(pos+2, functionFullName.length());
    }
    else
    {
       functionName = functionFullName;
    }
    
    string objectInstance = str( boost::format("%s(%p)") % objectName % thisPointer );

    if ( !functionStack.empty() )
    {
       string lastOjectInstance = functionStack.top();

       string sequenceUML = str( boost::format("\"%s\" -> \"%s\": \"%s\"\n") % lastOjectInstance % objectInstance % functionName );
       //printf("**************************\n\n");
       printf("%s", sequenceUML.c_str()); 
       //printf("\n\n");
    
    }
    else
    {
       //printf("**************************\n\n");
       //printf("First Main entry"); 
       objectInstance = "Main(0)";
       //printf("\n\n");
    }


    //printf("functionStack.push() ------>   objectInstance =%s\n", objectInstance.c_str()); 
    //printf("functionStack.size() =%i\n", functionStack.size()); 
    functionStack.push(objectInstance);


    if (isCPP > 0 )
    {
        nargs += isCPP;  
    }
    else
    {
        thisPointer = 0;
    }
    
    // Main -> B(1234234) bf1(int)
    // B(1234234) -> C(1324123) cf1(int)
    // Main -> B(1234234) m2(int)
    
    
    
    if (nargs > MAX_ARG_SHOW)
        nargs = MAX_ARG_SHOW;

/*
    printf("T%p: %p %s this=%p %s [from %s]\n", 
           self, (int*)func, buf_func,  thisPointer,
           args(buf_args, ARG_BUF_LEN, nargs, frame), 
           buf_file);
  */  
    /*print_stack(); */
}

// Sample output
// T0x7fccb071d700: 0x40135c f2(int) (4199458 ...) [from cpptraced.cpp:51]

/*
T0x7f6c3d635700: 0x400cd9 main (1018140720 ...) [from ]
T0x7f6c3d635700: 0x400c36 set_signal (4197641 ...) [from cSimpleTraced.c:91]
T0x7f6c3d635700: 0x400c36 set_signal => 0
T0x7f6c3d635700: 0x400c36 set_signal (4197656 ...) [from cSimpleTraced.c:93]
T0x7f6c3d635700: 0x400c36 set_signal => 0
./cSimpleTraced: main(argc=1)
T0x7f6c3d635700: 0x400b10 f1 (4197694 ...) [from cSimpleTraced.c:98]
f1 13
T0x7f6c3d635700: 0x400aae f2 (4197203 ...) [from cSimpleTraced.c:52]
f2 73
T0x7f6c3d635700: 0x400a4f f3 (4197105 ...) [from cSimpleTraced.c:44]
f3 143
T0x7f6c3d635700: 0x400a06 f4 (4197007 ...) [from cSimpleTraced.c:36]
f4 143
T0x7f6c3d635700: 0x400a06 f4 => 0
T0x7f6c3d635700: 0x400a4f f3 => 80
T0x7f6c3d635700: 0x400aae f2 => 70
T0x7f6c3d635700: 0x400b10 f1 => 60
./cSimpleTraced: done.
T0x7f6c3d635700: 0x400cd9 main => 0
Segmentation fault (core dumped)

*/

EXTERNC void 
__cyg_profile_func_exit( void *func, void *callsite )
{
    long ret = 0L; 
    char buf_func[CTRACE_BUF_LEN+1] = {0};
    char buf_file[CTRACE_BUF_LEN+1] = {0}; 
    pthread_t self = (pthread_t)0;
    int *frame = NULL;
    int thisPointer = 0;
    int isCPP = 0;
    
    if ( !functionStack.empty() )
    {
       //printf("-----------------------------\n\n");
       string lastOjectInstance = functionStack.top();
       //printf("functionStack.size() =%i\n", functionStack.size()); 
       //printf("lastOjectInstance =%s\n", lastOjectInstance.c_str()); 
       //printf("functionStack.pop();"); 
       //printf("\n\n");
       functionStack.pop();
    }
    else
    {
       //printf("-----------------------------\n\n");
       //printf("NO functionStack.pop();"); 
       //printf("\n\n");
    }
    

    
    GET_EBX(ret); 
    self = pthread_self(); 
    
    frame = (int *)__builtin_frame_address(0); /*of the 'func'*/
    thisPointer = *(frame+6);
    frame = (int *)__builtin_frame_address(1); /*of the 'func'*/
    
    assert(frame != NULL); 
    
    /* Function Exit Address */
    
    /*Which function*/
    libtrace_resolve (func, buf_func, CTRACE_BUF_LEN, NULL, 0);
    /*From where.  KO with optimizations. */
    /*libtrace_resolve (callsite, NULL, 0, buf_file, CTRACE_BUF_LEN);*/
    
    isCPP += is_cpp(buf_func);      /*'this'*/

    if (isCPP == 0 )
    {
        thisPointer = 0;
    }
/*
    printf("T%p: %p %s this=%p => %d\n", 
           self, (int*)func, buf_func, isCPP?thisPointer:0,
           ret);
  */  
    /*print_stack(); */
    
    SET_EBX(ret); 
}



void _init()  __attribute__((constructor));
void 
_init()
{
    const char *prog = getenv("CTRACE_PROGRAM"); 
    
    if (NULL == prog) {
        fprintf(stderr, 
                "The CTRACE_PROGRAM environment variable must be set to the "
                "program to be traced.");
        exit(EXIT_FAILURE); 
    }
    
    if (0 != libtrace_init(prog, NULL, NULL)) {
        fprintf(stderr, "libtrace_init() failed.");
        exit(EXIT_FAILURE); 
    }
}


void  _fini()  __attribute__((destructor)); 
void 
_fini()
{
    libtrace_close();
}

