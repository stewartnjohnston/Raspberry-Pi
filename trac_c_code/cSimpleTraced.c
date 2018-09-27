/*
 *  cSimpleTraced.c
 *
 *  Copyright 2008 Aurelian Melinte. 
 *  Released under GPL 3.0 or later. 
 *
 *  Call monitoring demo. 
 */
 
#define _GNU_SOURCE  /*strerror_r*/
#include <unistd.h>  /*sleep*/
#include <stdio.h>
#include <stdlib.h>
#include <string.h>  /*strerror_r*/
#include <errno.h>
#include <assert.h>
#include <signal.h>
#include <pthread.h>


#define ERRBUF_LEN (255) 

static int  _do_exit = 0;

void
f4(int id)
{
    printf("%s %d\n", __FUNCTION__, id);
}

static inline int 
f3(int id)
{
    printf("%s %d\n", __FUNCTION__, id);
    f4(id);
    return 80;
}

int 
f2(int id)
{
    printf("%s %d\n", __FUNCTION__, id);
    f3(70+id);
    return 70;
}

static int 
f1(int id, int id2, int id3, int id4)
{
    id = id + id2 + id3 + id4;
    printf("%s %d\n", __FUNCTION__, id);
    f2(60+id); 
    return 60;
}


static char *
wrap_strerror_r(int err, char *buf, int len)
{
    char *src = NULL;
    
    memset(buf, 0, len);
    src = strerror_r(err, buf, len); 

    return src ? src : buf; 
}



static void 
sigexit(int signo)
{
    _do_exit = 1;
}

static void 
set_signal(int signo, void (*handler)(int))
{
    struct sigaction sa;

    memset(&sa, 0, sizeof(sa));
    sa.sa_handler = (void (*)(int))handler;
    sigaction(signo, &sa, NULL);
}


int
main(int argc, char *argv[])
{

    set_signal(SIGINT,  sigexit);
    set_signal(SIGQUIT, sigexit);
    
    
    printf("%s: main(argc=%d)\n", argv[0], argc);
    
    f1(13,12,11,10);
  

    printf("%s: done.\n", argv[0]);
    return EXIT_SUCCESS;
}

