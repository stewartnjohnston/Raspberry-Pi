package net.pogo.game.engine;

import java.util.List;
import java.util.ArrayList;


public class Engine
{
  private List<Entity> entities = new ArrayList<Entity>();
  private SystemManager systemManager = new SystemManager();

  public void Engine()
  {
    addALLSystems();
  }

  public void addEntity(Entity entity )
  {
    entities.add( entity );
    systemManager.addEntity(entity);
  }

  public void removeEntity(Entity entity)
  {
    // destroy nodes containing this entity's components
    // and remove them from the node lists
    systemManager.removeEntity(entity);
    entities.remove( entity );
  }

  public SystemManager GetSystemManager()
  {
    return systemManager;
  }

  public void addALLSystems()
  {
    systemManager.addSystem(new MoveSystem());
    systemManager.addSystem(new RenderSystem());
  }
}

