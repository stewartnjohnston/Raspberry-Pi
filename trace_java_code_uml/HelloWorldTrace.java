// import all BTrace annotations 
import com.sun.btrace.AnyType;
import com.sun.btrace.annotations.*;  
// import statics from BTraceUtils class  
import static com.sun.btrace.BTraceUtils.*; 
import com.sun.btrace.BTraceMap;
import com.sun.btrace.BTraceDeque;
import com.sun.btrace.BTraceRuntime;
import java.util.Map;
import java.util.Deque;

import java.lang.Class;
import java.lang.reflect.Field; 
import java.util.regex.Matcher;
import java.util.regex.Pattern;

   
// @BTrace annotation tells that this is a BTrace program  
@BTrace
public class HelloWorldTrace {
//    @OnMethod(clazz="HelloWorld2", method="/.*/", location=@Location(Kind.RETURN))
//    @OnMethod(clazz="stewart.HelloWorld2", method="/.*/", location=@Location(Kind.RETURN))
//    @OnMethod(clazz="/stewart\\..*/", method="/.*/", location=@Location(Kind.RETURN)) //This one works!!!

//    static BTraceMap<String, BTraceDeque<String> > stackPerThread = new BTraceMap<String, BTraceDeque<String> >(); 
//    static BTraceMap<String, BTraceDeque<String> > stackPerThread = new BTraceMap<String, BTraceDeque<String> >(); 
    private static Map<String, Deque<String>> stackPerThread = newHashMap();

    @OnMethod(clazz="/stewart\\..*/", method="/.*/")

        public static void onMethod(@Self Object thiz, @ProbeClassName String pcn, @ProbeMethodName(fqn = true) String pmn, AnyType[] args) {
        
        Thread t = currentThread();
        
        println("onMethod()   " + pcn + "::" + pmn + "()  TheadID=" + t + "  this = " + thiz);
        //printFields(args[0]);
    }
    
    @OnMethod(
    clazz="/stewart\\..*/", 
    method="/.*/")
//    public static void entry(@ProbeMethodName(fqn=true) String probeMethod) {
    public static void entry(@Self Object thiz, @ProbeClassName String pcn, @ProbeMethodName(fqn = true) String pmn, AnyType[] args) {
/*
        print("Pogo Entry" );
        println(timestamp() );
        println(probeMethod);
*/
        Thread t = currentThread();
        
        String threadId = Threads.name(t);
        String lastObjectThreadId;
        
        println(">>>>>> Enter()   " + pcn + "::" + pmn + "()  TheadID=" + t + "  this = " + thiz);





      String ObjectAndThis = str(thiz);
      int ObjectAndThisLen = length(ObjectAndThis);
      println("ObjectAndThis =" + ObjectAndThis );
      println("ObjectAndThisLen =" + ObjectAndThisLen );
      
      String thisPointer = "null";
      String className = "null";
        
          // Parse the this pointer name

          // Example ObjectAndThis = "stewart.HelloWorld2@621be5d1"  or  ObjectAndThis = "null"
          // the thisPointer="621be5d1" or thisPointer="null"
          // the className="HelloWorld2" or thisPointer="null"
          
          println("ObjectAndThis =" + ObjectAndThis );
          int pos = lastIndexOf(ObjectAndThis, "@");
          int pos1 = 0;
          println("pos (@) =" + pos );
          if ( pos > 0 )
          {
             thisPointer = Strings.substr(ObjectAndThis, pos+1) ;
             pos1 = lastIndexOf(ObjectAndThis, ".");
             if ( pos1 < 0 )
                pos1 = 0;
             className = Strings.substr(ObjectAndThis,pos1+1, pos) ;
          }
          println("thisPointer =" + thisPointer );

        println("pmn=" + pmn );
        println("pmn=01234567890123456789012345678901234567890123456789012345678901234567890");
        println("pmn=0         1         2         3         4         5         6         7");

          // Parse the class name
          // Example pcn="stewart.HelloWorld" and ObjectAndThis = "null"
          // we want className="HelloWorld" and classNameThisPointer = HelloWorld(nul)

          // Example pcn="stewart.Bclass" and ObjectAndThis = "stewart.HelloWorld2@621be5d1"
          // we want className="HelloWorld" and classNameThisPointer = HelloWorld(621be5d1)
          // Where class HelloWorld2 extends Aclass   and   class Aclass extends Bclass

          if ( strcmp(className,"null") == 0 )
          {  // the className=="null" so we need to find the real class name 
             pos1 = lastIndexOf(pcn, ".");
             if ( pos1 < 0 )
                pos1=-1;
             pos = length(pcn);
             println("pos1 (.) =" + pos1 );
             println("pos pnc.length() =" + pos );
             className = Strings.substr(pcn, pos1+1, pos);
          }
        
        println("className=" + className );


          // Parse function signature
          // Example pmn="public static void stewart.HelloWorld#main(java.lang.String[])()"
          // we want functionSignature="HelloWorld#main(java.lang.String[])()" or "null"

          // Example pmn=" void stewart.Bclass#<init>()"
          // we want functionSignature="Bclass#<init>()" or "null"

        pos = lastIndexOf(pmn , className + "#");
        println("pos from pmn (#) =" + pos );
        
        String functionSignature = "";

        if( pos > 0 )
        {
           pos = lastIndexOf(pmn , "#");
           pos1 = lastIndexOf(pmn, ")");
           if ( pos1 < 0 )
              pos1 = length(pmn) - 1;
           println("pos from pmn (#) =" + pos );
           println("pos1 from pmn (\")\") =" + pos1 );
           functionSignature = Strings.substr(pmn, pos+1, pos1+1);
           println("1 functionSignature =" + functionSignature );
        }
        else
        {
           pos = lastIndexOf(pmn, "#");
           String tmp = Strings.substr(pmn, 0 , pos);
           pos = lastIndexOf(tmp, ".");
           pos1 = lastIndexOf(pmn, ")");
           if ( pos1 < 0 )
              pos1 = length(pmn) - 1;
           println("pos from pmn (.) =" + pos );
           println("pos1 from pmn (\")\") =" + pos1 );
           functionSignature = Strings.substr(pmn, pos+1, pos1+1);
           println("2 functionSignature =" + functionSignature );
        
        }


        String classNameThisPointer = className + "(" + thisPointer + ")";

        Deque<String> currentThreadStack = Collections.get(stackPerThread, threadId);
        
        if (currentThreadStack == null)
        {
            Deque<String> stack = newDeque();
            Collections.put(stackPerThread, threadId, stack);
            currentThreadStack = stack;
            
            lastObjectThreadId = "Main(0)";

            println("entry() create new stack for classNameThisPointer=" + classNameThisPointer + 
                    "  with name threadId=" + threadId);
        }
        else
        {
            lastObjectThreadId = Collections.peekFirst(currentThreadStack);
            println("entry() found stack for threadId=" + threadId);
        }
        
        Collections.push(currentThreadStack,classNameThisPointer);
        println("entry() pushing classNameThisPointer=" + classNameThisPointer + 
                "  Into stack threadId" + threadId);

        println(">>>>>> UML(" + threadId + ")  \"" + lastObjectThreadId + "\" -> \"" +  classNameThisPointer + "\":    \"" + functionSignature + "\"");
        println(">>>>>> UML(" + threadId + ")   activate \"" + classNameThisPointer + "\"  #" +  threadId + "b617FF");

    }

@OnMethod(
    clazz="/stewart\\..*/", 
    location=@Location(value=Kind.RETURN)
    )
//    public static void exit(@ProbeMethodName(fqn=true) String probeMethod, @Duration long duration) {
    public static void exit(@Self Object thiz, @ProbeClassName String pcn, @ProbeMethodName(fqn = true) String pmn, AnyType[] args) {
/*
        print("Pogo Exit:" );
        println(timestamp() );
        println(probeMethod);
*/
        Thread t = currentThread();
        
        String threadId = Threads.name(t);
        
        Deque<String> currentThreadStack = Collections.get(stackPerThread, threadId);
        
        if (currentThreadStack == null)
        {
            println("exit() No stack found for threadId=" + threadId);
        }
        else
        {
            println("exit() Found stack for threadId=" + threadId + "   size=" + Collections.size(currentThreadStack));
            String classNameThisPointer = Collections.removeFirst(currentThreadStack);
            println("exit() Found stack for pop=" + classNameThisPointer);
            //Collections.pop(currentThreadStack);
            println("exit() size=" + Collections.size(currentThreadStack));
            
            println(">>>>>> UML(" + threadId + ")   deactivate \"" + classNameThisPointer + "\"  #" +  threadId + "b617FF");


        }
        
        println("<<<<<< Exit()   " + pcn + "::" + pmn + "()  TheadID=" + t + "  this = " + thiz);

    }

}


// HelloWorld2::printOne()  ThreadID=11threadName=Thread-2  this = HelloWorld2@7f2d51f7   i = 18
