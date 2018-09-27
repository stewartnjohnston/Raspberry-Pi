#  define EXTERNC extern "C" 

EXTERNC int 
libtrace_init(
          const char *file_name, 
          const char *section_name,
          const char *target);


EXTERNC int 
libtrace_close(void);

EXTERNC int 
libtrace_resolve(
          void *addr, 
          char *buf_func, size_t buf_func_len, 
          char *buf_file, size_t buf_file_len,  
          ...
          );

