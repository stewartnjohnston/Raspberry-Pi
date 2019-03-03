package net.pogo.game.engine;

import java.util.*;


public class MoveSystem extends System
{
  
  private Map<Integer, MoveNode> targets = new HashMap<Integer, MoveNode>();

  void addEntity(Entity entity)
  {
     if(!targets.containsKey(entity.id))
     {
        if(entity.hasComponentType(VelocityComponent.class.getName()))
        {
           MoveNode node = new MoveNode();
           node.velocity = (VelocityComponent) entity.getComponentType(VelocityComponent.class.getName());
           node.position = (PositionComponent) entity.getComponentType(PositionComponent.class.getName());
           targets.put(entity.id, node);
        }
     }
  }
  
  void removeEntity(Entity entity)
  {
     targets.remove(entity.id);
  }


  public void update( int time  )
  {
  
    for (MoveNode target : targets.values())
    {
       //System.out.println(person.getName());
       //target.position.x += target.velocity.velocityX * time;
       //target.position.y += target.velocity.velocityY * time;
       //target.position.rotation += target.velocity.angularVelocity * time;
    }
  }
}
