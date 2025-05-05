using UnityEngine;

public class OctopusSpawner : MonoBehaviour, IInteractable
{
    [SerializeField] private GameObject octopusPrefab;

    public void Interact(PlayerInteractionController player)
    {
        Debug.Log("Nevera: Spawneando pulpo...");

        if (player.HoldSystem.HasItem)
        {
            Debug.Log("Ya estás sosteniendo algo.");
            return;
        }

        if (octopusPrefab != null)
        {
            GameObject spawned = Instantiate(octopusPrefab);
            player.HoldSystem.PickUp(spawned);
        }

    }

    public GameObject GetGameObject() => gameObject;
}
