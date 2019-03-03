package net.pogo.game.engine;

import java.util.HashMap;
import java.util.Map;

public class RenderSystem extends System
{
  private Map<Integer, RenderNode> targets = new HashMap<Integer, RenderNode>();

  void addEntity(Entity entity)
  {
     if(!targets.containsKey(entity.id))
     {
      if(entity.hasComponentType(DisplayComponent.class.getName()))
        {
           RenderNode node = new RenderNode();
           node.display = (DisplayComponent) entity.getComponentType(DisplayComponent.class.getName());
           node.position = (PositionComponent) entity.getComponentType(PositionComponent.class.getName());
           targets.put(entity.id, node);
        }
     }
  }
  void removeEntity(Entity entity)
  {
     targets.remove(entity.id);
  }
  
  public void update( int time)
  {
  //System.out.println("RenderSystem::update() start");

    for (RenderNode target : targets.values())
    {
    //System.out.println("RenderSystem::update() target ");
      //target.display.view.x = target.position.x;
      //target.display.view.y = target.position.y;
      //target.display.view.rotation = target.position.rotation;
    }
    //System.out.println("RenderSystem::update() start");
  }
}
