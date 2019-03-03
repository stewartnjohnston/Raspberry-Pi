/*
 *  cSimpleTraced.c
 *
 *  Copyright 2008 Aurelian Melinte. 
 *  Released under GPL 3.0 or later. 
 *
 *  Call monitoring demo. 
 */
 
//#define _GNU_SOURCE  /*strerror_r*/
#include <unistd.h>  /*sleep*/
#include <stdio.h>
#include <stdlib.h>
#include <string.h>  /*strerror_r*/
#include <errno.h>
#include <assert.h>
#include <signal.h>
#include <pthread.h>

#define ERRBUF_LEN (255) 

void
f0()
{
    printf("%s %d\n", __FUNCTION__, 2);
}

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
f1(int id)
{
    printf("%s %d\n", __FUNCTION__, id);
    f2(60+id); 
    return 60;
}

static int 
f5(int i1,int i2,int i3,int i4,int i5, int i6, int i7, int i8, int i9, int ia, int ib, int ic, int id, int ie, int ifx, int i10, int i11, int i12, int i13)
{
    int ixd = i1 +  i2 + i3 + i4 + i5 + i6 + i7 + i8 + i9 + ia + ib + ic  + id + ie + ifx + i10 + i11 + i12 + i13;
    printf("functionName=%s   this=%p\n", __FUNCTION__, 0);
    return ixd;
}

float f17(float i, float j, float k, float l, float m, float n, float o, float p, float q, float r, float s, float t, float u, float v, float w, float x, float y) 
{
    printf("functionName=%s   this=%p\n", __FUNCTION__, 0);
    return i;
}

float fa17(float i, float j, float k, float l, float m, float n, float o, float p, float q, float r, float s, float t, float u, float v, float w, float x, float y) 
{
    float z;
    z = i + j + k + l + m + n + o + p + q + r + s + t + u + v + w + x + y;
    printf("functionName=%s   this=%p\n", __FUNCTION__, 0);
    return z;
}


class C
{
public:
    C() {printf("C::C() this=%p \n", this);}
    C(int i): _id(i) {printf("C::C(int=%d) this=%p\n", _id, this);}
    ~C() {printf("C::~C() this=%p\n",this);}
    
     int cf1(int i) {printf("C::cf1(%i) this=%p)\n", i, this); return 21;}
    
protected:
    int _id; 
}; 


class E
{
public:
    E() {printf("E::E() this=%p \n", this);}
    E(int i): _id(i) {printf("E::E(this=%p int=%d)\n", this, _id);}
    ~E() {printf("E::~E(this=%p)\n",this);}
    
     int ef1(int i) {printf("E::ef1(this=%p)\n", this); return 21;}
    
protected:
    int _id; 
}; 


class B
{
public://    f5(1,2,3,4,5,6,7,8,9,10,11,12);

    C c;
    B() {printf("B::B() this=%p \n", this);}
    B(int i): _id(i) {printf("B::B(this=%p int=%d)\n", this, _id);}
    ~B() {printf("B::~B(this=%p)\n",this);}
    int bf1(int i) {printf("D::~df1()\n"); return c.cf1(i);}
    
    int bfx0() 
    {
        printf("functionName=%s   this=%p\n", __FUNCTION__, this);
        return _id;
    }
    int bfx1(int i) 
    {
        printf("functionName=%s   this=%p\n", __FUNCTION__, this);
        return _id;
    }
    int bfx2(int i, int j) 
    {
        printf("functionName=%s   this=%p\n", __FUNCTION__, this);
        return _id;
    }
    int bfx3(int i, int j, int k) 
    {
        printf("functionName=%s   this=%p\n", __FUNCTION__, this);
        return _id;
    }
    int bfx4(int i, int j, int k, int l) 
    {
        printf("functionName=%s   this=%p\n", __FUNCTION__, this);
        return _id;
    }
        
    int bfxf7(float i, float j, float k, float l, float m, float n, float o) 
    {
        printf("functionName=%s   this=%p\n", __FUNCTION__, this);
        return _id;
    }
    
    int bfxf12(int i1,int i2,int i3,int i4,int i5, int i6, int i7, int i8, int i9, int ia, int ib, int ic)
    {
        printf("functionName=%s   this=%p\n", __FUNCTION__, this);
        return _id;
    }


    static int FunStatic(int x)
    {
    printf("functionName=%s   this=%p\n", __FUNCTION__, 0);
    return x++;
    }
    
    virtual int m1(int i, int j) {printf("B::m1(this=%p)\n", this); f1(i); return 20;}
    virtual int m2(int i) {printf("B::m2(this=%p)\n", this); f1(i); return 21;}
    
protected:
    int _id; 
}; 


class D : public B
{
public:
    E e;
    D() {printf("D::D() this=%p \n", this);}
    D(int i) {printf("D::D(int=%d) this=%p\n",_id,this);}
    int df1(int i) {printf("D::~df1()\n"); return e.ef1(i);}
    virtual ~D() {printf("D::~D()\n");}
   
    int fi19(int i1,int i2,int i3,int i4,int i5, int i6, int i7, int i8, int i9, int ia, int ib, int ic, int id, int ie, int ifx, int i10, int i11, int i12, int i13)
    {
        int ixd = i1 +  i2 + i3 + i4 + i5 + i6 + i7 + i8 + i9 + ia + ib + ic  + id + ie + ifx + i10 + i11 + i12 + i13;
        _id = ixd;
        printf("functionName=%s   this=%p\n", __FUNCTION__, this);
        return ixd;
    }

    
    virtual int m1(int i, int j) {printf("D::m1()\n"); m2(j+10); return 30;}
}; 

int
main(int argc, char *argv[])
{
   
    D *d = new D();
    f4(0xeeeeeeee);
    f0();
    d->fi19(0x0ccccc,  0x0ccccc2,  0x0ccccc3,  0x0ccccc4,  0x0ccccc5,   0x0ccccc6,   0x0ccccc7,   0x0ccccc8,   0x0ccccc9,   0x0ccccca,   0x0cccccb,   0x0cccccc,   0x0cccccd,   0x0ccccce,   0x0cccccf,   0x0ccccc10,   0x0ccccc11,   0x0ccccc12,   0x0ccccc13);
    fa17(11111.11, 222222.222, 333333.333, 44444.44, 555555.555, 66666.666, 77777.777, 88888.88, 99999.99, 101010.10, 110110.11, 121212.12, 131313.13,
        141414.14, 151515.15, 161616.16, 171717.17);
        
    d->bfx0();
    d->bfx1(1);
    D *d1 = new D();
    d->bfx2(2,3);
    d->FunStatic(7);
    d->bfx3(4,5,6);
    d1->bfx4(7,8,9,10);
    d->bfx4(7,8,9,10);
    d->bfxf7(11,12,13,14,15,16,17);
    d->bfxf12(21,22,23,24,25,26,27,28,29,30,31,32);
    D *d2 = new D();
    E *e = new E();
    e->ef1(99);
    delete e;
    e = NULL;
    d1->FunStatic(7);
    d->bf1(3);
    D::FunStatic(4);
    d2->bfx4(7,8,9,10);
    d1->FunStatic(7);
    d->df1(44);
    d->fi19(0x0ccccc,  0x0ccccc2,  0x0ccccc3,  0x0ccccc4,  0x0ccccc5,   0x0ccccc6,   0x0ccccc7,   0x0ccccc8,   0x0ccccc9,   0x0ccccca,   0x0cccccb,   0x0cccccc,   0x0cccccd,   0x0ccccce,   0x0cccccf,   0x0ccccc10,   0x0ccccc11,   0x0ccccc12,   0x0ccccc13);
    delete d2;
    delete d1;
    delete d;

/*    
    D *d = new D(23);
    
    d->m2(0);
    f5(1,2,3,4,5,6,7,8,9,10,11,12);
    f5(1,2,3,4,5,6,7,8,9,10,11,12);
    f5(1,2,3,4,5,6,7,8,9,10,11,12);
    D::FunStatic(4);
    delete d;
*/
    printf("%s: done.\n", argv[0]);
    return EXIT_SUCCESS;
}

