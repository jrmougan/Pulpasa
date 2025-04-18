using UnityEngine;

public struct ObjectDroppedEvent
{
    public GameObject droppedObject;
    public Transform dropper;

    public ObjectDroppedEvent(GameObject obj, Transform source)
    {
        droppedObject = obj;
        dropper = source;
    }
}
