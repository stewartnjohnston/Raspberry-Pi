package net.pogo.game.engine;

import java.util.List;
import java.util.ArrayList;

public class Entity {

    public int id;
    
    private List<Object> components = new ArrayList<Object>();

    public  void add( Object component )
    {
        components.add(component);

    }

    public void remove( Object component )
    {
    }
    
    public boolean hasComponentType(String className)
    {
       for (Object component : components)
       {
          if(component.getClass().getName().equals(className))
             return true;
       }
       return false;
    }

    public Object getComponentType(String className)
    {
       for (Object component : components)
       {
          if(component.getClass().getName().equals(className))
             return component;
       }
       return null;
    }

}
