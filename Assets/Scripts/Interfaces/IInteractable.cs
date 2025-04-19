using UnityEngine;

public interface IInteractable
{
    void Interact(PlayerInteractionController interactor);
    GameObject GetGameObject();
}
