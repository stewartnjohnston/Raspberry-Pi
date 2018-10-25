/* CallingMethodsInSameClass.java
 *
 * illustrates how to call static methods a class
 * from a method in the same class
 */
 
package stewart;

import java.util.Map;
import java.util.HashMap;
import java.util.Stack;

import java.util.regex.Matcher;
import java.util.regex.Pattern;

public class HelloWorld
{
   public static void main(String[] args)
   {
   

      try {	
      
         //Pause for 4 seconds
         Thread.sleep(4000);
   
         HelloWorld2 h2 = new HelloWorld2();
         h2 = null;

	      for(int i=0;i<3;i++) {
		   MultithreadingDemo object = new MultithreadingDemo(); 
		   //String newThreadName = object.currentThread().getName();
		   //String currentThreadName = Thread.currentThread().getName();
		   //object.setName(currentThreadName + "#" + newThreadName);
         
         object.start();
         
/*                   
         synchronized(object){
            try{
                System.out.println("Waiting for object to complete...");
                object.wait();
            }catch(InterruptedException e){
                e.printStackTrace();
            } 
         }         
*/                   
         }
         
         Thread.sleep(60000);
         
	   } catch (Exception e) {
             System.out.println("main interrupted e=" + e);
           }
           
        
      }

	public static void printOne(int i) {
		System.out.println("Hello World i = " + i);
	}

	public static void printTwo() {
		printOne(1);
		printOne(2);
	}
}

class MultithreadingDemo extends Thread 
{ 
    public void run() 
    { 
        try
        { 
           HelloWorld2 h2 = new HelloWorld2();

           // Displaying the thread that is running 
           System.out.println ("MultithreadingDemo::run() Thread=" + 
                  Thread.currentThread().getId()); 
 
           for(int i=0;i<3;i++) {
	            h2.printOne(i+3);
	            //Pause for 4 seconds
               Thread.sleep(1000);
           }
           h2 = null;
           
	      } catch (Exception e) {
            System.out.println("main interrupted e=" + e);
         }
    } 
} 

class HelloWorld2 extends Aclass
{
	public HelloWorld2()
	   {
	   Thread t = Thread.currentThread();
	   System.out.println("HelloWorld2::HelloWorld2()  ThreadID=" + t.getId() + "threadName=" + t.getName() +"  this = " + this);
	   }
	
        @Override
	public void printOne(int i) {
	        field = i;
		Thread t = Thread.currentThread();
		System.out.println("HelloWorld2::printOne()  ThreadID=" + t.getId() + "threadName=" + t.getName() +"  this = " + this + "   i = " + i);
                super.printOne(i);
	}

	protected void finalize()  {
		Thread t = Thread.currentThread();
      System.out.println("HelloWorld2::finalize()  ThreadID=" + t.getId() + "threadName=" + t.getName() +"  this = " + this);
   }
}

class Aclass extends Bclass
{
	public Aclass()
	   {
	   Thread t = Thread.currentThread();
	   System.out.println("Aclass::Aclass()  ThreadID=" + t.getId() + "threadName=" + t.getName() +"  this = " + this);
	   }

        @Override
	public void printOne(int i) {
	        field = i;
		Thread t = Thread.currentThread();
		System.out.println("Aclass::printOne()  ThreadID=" + t.getId() + "threadName=" + t.getName() +"  this = " + this + "   i = " + i);
                super.printOne(i);

	}
	
	protected void finalize()  {
		Thread t = Thread.currentThread();
      System.out.println("Aclass::finalize()  ThreadID=" + t.getId() + "threadName=" + t.getName() +"  this = " + this);
   }
}

class Bclass
{
   protected int field = 0;
        
	public Bclass()
	   {
	   Thread t = Thread.currentThread();
	   System.out.println("Bclass::Bclass()  ThreadID=" + t.getId() + "threadName=" + t.getName() +"  this = " + this);
	   }

	public void printOne(int i) {
	        field = i;
		Thread t = Thread.currentThread();
		System.out.println("Bclass::printOne()  ThreadID=" + t.getId() + "threadName=" + t.getName() +"  this = " + this + "   i = " + i);

	}

	protected void finalize()  {
		Thread t = Thread.currentThread();
      System.out.println("Bclass::finalize()  ThreadID=" + t.getId() + "threadName=" + t.getName() +"  this = " + this);
   }
}

