package net.pogo.game.samples.simplegame;

import java.util.Arrays;
import net.pogo.game.engine.*;
import java.util.logging.*;

public class Simple
{ 
   private final static Logger logger = Logger.getLogger(Simple.class.getName());
   //Logger logger = Logger.getLogger(MyClass.class.getName());
   static Engine engine;
   
   public static void main(String[] args)
   {
     logger.log(Level.INFO,"Hello World from Simple = ");
     System.out.println("Hello World Simple = ");
     
     engine = new Engine();
     createSpaceship();
     
     engine.GetSystemManager().update(1);
     System.out.println("Hello World Simple done ");
   }
   
  public static void createSpaceship()
  {
     Entity spaceship = new Entity();
 
     PositionComponent position = new PositionComponent();
     spaceship.add( position );
  
     DisplayComponent display = new DisplayComponent();
     spaceship.add( display );
  
     VelocityComponent velocity = new VelocityComponent();
     spaceship.add( velocity );
 
     engine.addEntity( spaceship );
  }

}
