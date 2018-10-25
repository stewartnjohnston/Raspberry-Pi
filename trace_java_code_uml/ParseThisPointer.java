import java.util.regex.Matcher;
import java.util.regex.Pattern;
import static com.sun.btrace.BTraceUtils.*;

public class ParseThisPointer {

   public static void main( String args[] ) {
      // String to be scanned to find the pattern.
      //String line = "This order was placed for QT3000! OK?";
      //String pattern = "(.*)(\\d+)(.*)";
      
      String line = "stewart.HelloWorld2@5263c5bc";
      String thiz = line;
      String pattern = "@[0-f]+";
      
      Pattern rx = pattern(pattern);
      String thisPointer;
      String className;
        
      if ( matches(rx,thiz))
      { 
          int pos = lastIndexOf(thiz, "@");
          thisPointer = Strings.substr(thiz, pos+1) ;

          int pos1 = lastIndexOf(thiz, ".");
          className = Strings.substr(thiz, pos+1, pos1-pos);
      }
        
      System.out.println("thisPointer = : " + thisPointer );
      System.out.println("className: " + className );
        
        
        
        
      

      // Create a Pattern object
      Pattern r = Pattern.compile(pattern);

      // Now create matcher object.
      Matcher m = r.matcher(line);
      if (m.find( )) {
         System.out.println("Found value: " + m.group(0) );
         System.out.println("Found value: " + m.group(1) );
         System.out.println("Found value: " + m.group(2) );
      }else {
         System.out.println("NO MATCH");
      }
   }
}
