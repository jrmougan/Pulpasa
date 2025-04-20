using UnityEngine;

public class Kitchen : MonoBehaviour, IInteractable
{

    public GameObject GetGameObject() => gameObject;

    public void Interact(PlayerInteractionController interactor)
    {
        Debug.Log("👨‍🍳 Interactuando con la cocina.");

        // Lógica futura: por ejemplo, combinar ingredientes o cocinar.
        // Podés usar interactor.HoldSystem para verificar si el jugador sostiene algo.
    }
}
