using UnityEngine;
using UnityEngine.InputSystem;

public class PlayerInteraction : MonoBehaviour
{
    public float interactRange = 1.5f;
    public Transform interactOrigin;
    public LayerMask interactableLayerMask;
    private bool canInteract = true;

    private void Update()
    {
        if (Keyboard.current.eKey.wasPressedThisFrame)
        {
            TryInteract();
        }
    }

    public void TryInteract()
    {
        if (!canInteract) return;

        // Busca todos los colliders dentro de un radio
        Collider[] hits = Physics.OverlapSphere(interactOrigin.position, interactRange, interactableLayerMask);

        if (hits.Length == 0) return;

        // Buscar el más cercano
        Collider closest = null;
        float minDistance = Mathf.Infinity;

        foreach (var hit in hits)
        {
            float dist = Vector3.Distance(interactOrigin.position, hit.ClosestPoint(interactOrigin.position));
            if (dist < minDistance)
            {
                minDistance = dist;
                closest = hit;
            }
        }

        if (closest != null)
        {
            var interactable = closest.GetComponent<IInteractable>();
            if (interactable != null)
            {
                canInteract = false;
                Invoke(nameof(EnableInteraction), 0.3f);

                interactable.Interact(this);
                Debug.Log("Interacción auto-apuntada con: " + closest.name);
            }
        }
    }

    private void EnableInteraction()
    {
        canInteract = true;
    }

    // DEBUG visual en escena
    private void OnDrawGizmosSelected()
    {
        if (interactOrigin != null)
        {
            Gizmos.color = Color.yellow;
            Gizmos.DrawWireSphere(interactOrigin.position, interactRange);
        }
    }
}
