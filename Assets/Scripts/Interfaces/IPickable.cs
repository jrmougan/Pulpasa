using UnityEngine;
public interface IPickable
{
    void OnPickedUp(Transform parent);
    void OnDropped(Vector3 dropPosition);
    GameObject GetGameObject();
    bool IsHeld { get; }
}
