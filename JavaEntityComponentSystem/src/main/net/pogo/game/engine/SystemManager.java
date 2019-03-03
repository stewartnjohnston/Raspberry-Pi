package net.pogo.game.engine;

import java.util.List;
import java.util.ArrayList;
import static java.lang.System.out;

public class SystemManager
{
  private List<System> PrioritisedList = new ArrayList<System>();

  public void addSystem( System system)
  {
    PrioritisedList.add( system );
    system.start();
  }

  public static void test()
  {
       out.println("Hello World Simple = ");
  }

  public void update( int time )
  {

    out.println("SystemManager::update() start");
    for (System system : PrioritisedList)
    {
       system.update( time );
    }
  out.println("SystemManager::update() end");
  }

  public void removeSystem(System system)
  {
    system.stop();
    PrioritisedList.remove( system );
  }

  public void addEntity( Entity entity )
  {
    for (System system : PrioritisedList)
    {
       system.addEntity( entity );
    }
  }

  public void removeEntity( Entity entity )
  {
    for (System system : PrioritisedList)
    {
       system.removeEntity( entity );
    }
  }
}
