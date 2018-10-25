
import com.sun.btrace.annotations.*;
import static com.sun.btrace.BTraceUtils.*;  

/**
 * This script traces method entry into every method of
 * every class in javax.swing package! Think before using
 * this script -- this will slow down your app significantly!!
 */
@BTrace
public class AllMethods {

    @OnMethod(
        clazz="HelloWorld",
        method="${m}"
    )
    public static void m(@Self Object o, @ProbeClassName String probeClass, @ProbeMethodName String probeMethod) {
        println("Hello from pogo method");
        println("this = " + o);
        print("entered " + probeClass);
        println("." + probeMethod);
    }
    
        public static void onMethod() {
        println("Hello from pogo2 method");
    }
}


