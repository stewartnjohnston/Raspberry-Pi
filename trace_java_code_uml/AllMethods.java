

package com.sun.btrace.samples;

import com.sun.btrace.annotations.*;
import com.sun.btrace.services.impl.Printer;

/**
 * This script traces method entry into every method of
 * every class in javax.swing package! Think before using
 * this script -- this will slow down your app significantly!!
 */
@BTrace public class AllMethods {
    @Injected(ServiceType.RUNTIME)
    private static Printer printer;

    @OnMethod(
        clazz="HelloWorld",
        method="${m}"
    )
    public static void m(@Self Object o, @ProbeClassName String probeClass, @ProbeMethodName String probeMethod) {
        printer.println("this = " + o);
        printer.print("entered " + probeClass);
        printer.println("." + probeMethod);
    }
}

