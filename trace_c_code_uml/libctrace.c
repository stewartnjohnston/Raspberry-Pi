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
#include <map>
#include <stack>
#include <string>
#include <boost/format.hpp>

#  define EXTERNC extern "C" 

using namespace std;

static pthread_mutex_t lockMutex = PTHREAD_MUTEX_INITIALIZER;
static std::map<int, std::stack<string>* > stackPerThread;

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
    int mrc=0;
    std::stack<string>* currentThreadStack = NULL;
    
    self = pthread_self(); 
    
    int colour = self & 0xFFFFFF;
    
    printf("__cyg_profile_func_enter(%p, %p)1 in pthread_self = %li\n", (int*)func, (int*)callsite, self);
    mrc = pthread_mutex_lock(&lockMutex);
    printf("__cyg_profile_func_enter(%p, %p)2 mutex_mrc = %i in pthread_self = %li\n", (int*)func, (int*)callsite, mrc, self);


    //  std::map<int, std::stack<string>* > stackPerThread;
    if(stackPerThread.find(self) == stackPerThread.end())
    {
       // No stack for this thread exists, create a stack for this thread
       currentThreadStack = new std::stack<string>;
       stackPerThread[self] = currentThreadStack;
    }
    else
    {
       currentThreadStack = stackPerThread[self];
    }
    

    
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
    
    printf("__cyg_profile_func_enter(%p, %p)3 mutex_mrc = %i in pthread_self = %li   buf_func=%s\n", (int*)func, (int*)callsite, mrc, self, buf_func);

    if (isCPP > 0 )
    {
        nargs += isCPP;  
    }
    else
    {
        thisPointer = self;
    }

    
    string objectName("Main");
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

    string lastOjectInstance("Main(0)");
    
    if ( !currentThreadStack->empty() )
    {
       lastOjectInstance = currentThreadStack->top();
    }

    string sequenceUML 
         = str( boost::format("thread=%i  \"%s\" -> \"%s\": \"%s\"\n")
                                %self % lastOjectInstance % objectInstance % functionName );
    //printf("**************************\n\n");
    printf("%s", sequenceUML.c_str()); 
    //printf("\n\n");
    
    sequenceUML 
         = str( boost::format("thread=%i  activate \"%s\" #%p\n")
                                %self % objectInstance % colour );
    //printf("**************************\n\n");
    printf("%s", sequenceUML.c_str()); 
    //printf("\n\n");
/*
    }
    else
    {
       //printf("**************************\n\n");
       //printf("First Main entry"); 
       objectInstance = "Main(0)";
       //printf("\n\n");
    }
*/

    //printf("functionStack.push() ------>   objectInstance =%s\n", objectInstance.c_str()); 
    //printf("functionStack.size() =%i\n", functionStack.size()); 
    currentThreadStack->push(objectInstance);
    
    // Main -> B(1234234) bf1(int)
    // B(1234234) -> C(1324123) cf1(int)
    // Main -> B(1234234) m2(int)
    
    
    
    if (nargs > MAX_ARG_SHOW)
        nargs = MAX_ARG_SHOW;
        
    mrc = pthread_mutex_unlock(&lockMutex);
    //printf("__cyg_profile_func_enter(%p, %p) out mrc=%i self = %li\n", (int*)func, (int*)callsite, mrc, self);
    printf("__cyg_profile_func_enter(%p, %p)4 out mutex_mrc = %i in pthread_self = %li   buf_func=%s\n", (int*)func, (int*)callsite, mrc, self, buf_func);


/*
    printf("T%p: %p %s this=%p %s [from %s]\n", 
           self, (int*)func, buf_func,  thisPointer,
           args(buf_args, ARG_BUF_LEN, nargs, frame), 
           buf_file);
  */  
    /*print_stack(); */
}


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
    int mrc = 0;
    std::stack<string>* currentThreadStack = NULL;
    
    self = pthread_self(); 
    
    int colour = self & 0xFFFFFF;


    printf("__cyg_profile_func_exit(%p, %p) in self = %li\n", (int*)func, (int*)callsite, self);
    mrc = pthread_mutex_lock(&lockMutex);
    printf("__cyg_profile_func_exit(%p, %p) mrc = %i in self = %li\n", (int*)func, (int*)callsite, mrc, self);
    
    GET_EBX(ret); 
   
    currentThreadStack = stackPerThread[self];
    printf("__cyg_profile_func_exit(%p, %p) 1  self = %li\n", (int*)func, (int*)callsite, self);
    
    if ( !currentThreadStack->empty() )
    {
    printf("__cyg_profile_func_exit(%p, %p) 2  self = %li\n", (int*)func, (int*)callsite, self);
       //printf("-----------------------------\n\n");
       string lastOjectInstance = currentThreadStack->top();
       //printf("functionStack.size() =%i\n", functionStack.size()); 
       //printf("lastOjectInstance =%s\n", lastOjectInstance.c_str()); 
       //printf("functionStack.pop();"); 
       //printf("\n\n");
    printf("__cyg_profile_func_exit(%p, %p) 3  self = %li\n", (int*)func, (int*)callsite, self);
       string sequenceUML 
           = str( boost::format("thread=%i  deactivate \"%s\" #%p\n")
                                %self % lastOjectInstance % colour );
       printf("%s", sequenceUML.c_str()); 

       currentThreadStack->pop();
    }
    else
    {
       //printf("-----------------------------\n\n");
       //printf("NO functionStack.pop();"); 
       //printf("\n\n");
    }
    
    printf("__cyg_profile_func_exit(%p, %p) 4  self = %li\n", (int*)func, (int*)callsite, self);
   
    
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
    
    mrc = pthread_mutex_unlock(&lockMutex);
    //printf("__cyg_profile_func_exit(%p, %p) out mrc=%i self = %li\n", (int*)func, (int*)callsite, mrc, self);
    printf("__cyg_profile_func_exit(%p, %p) out mutex_mrc = %i in pthread_self = %li   buf_func=%s\n", (int*)func, (int*)callsite, mrc, self, buf_func);


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

