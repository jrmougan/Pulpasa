using UnityEngine;

public struct ObjectPickedUpEvent
{
    public GameObject pickedObject;

    public ObjectPickedUpEvent(GameObject obj)
    {
        pickedObject = obj;
    }
}
