using UnityEngine;
using QFramework;
using System.Collections.Generic;

[RequireComponent(typeof(Collider))]
public class Box : MonoBehaviour, IPickable, IInteractable
{
    public GameObject highlightVisual;

    public List<IngredientSO> ingredientes = new();
    public bool IsHeld { get; private set; }

    public void OnPickedUp(Transform parent)
    {
        transform.SetParent(parent);
        transform.localPosition = Vector3.zero;
        transform.localRotation = Quaternion.identity;

        var rb = GetComponent<Rigidbody>();
        if (rb != null) rb.isKinematic = true;

        IsHeld = true;
    }

    public void OnDropped(Vector3 suggestedDropPosition)
    {
        transform.SetParent(null);

        Vector3 dropOrigin = suggestedDropPosition + Vector3.up * 1f;
        Vector3 finalDropPos = suggestedDropPosition;

        RaycastHit hit;

        // 🔽 Busca suelo justo debajo del punto sugerido
        if (Physics.Raycast(dropOrigin, Vector3.down, out hit, 3f, LayerMask.GetMask("Default", "Ground")))
        {
            finalDropPos = hit.point + Vector3.up * 0.05f; // un pelín elevado para evitar clipping
        }
        else
        {
            Debug.LogWarning("⚠ No se encontró suelo. Forzando altura por seguridad.");
            finalDropPos = new Vector3(suggestedDropPosition.x, 1.5f, suggestedDropPosition.z); // posición segura de fallback
        }

        transform.position = finalDropPos;

        var rb = GetComponent<Rigidbody>();
        if (rb != null)
        {
            rb.isKinematic = false;
            rb.linearVelocity = Vector3.zero;
            rb.angularVelocity = Vector3.zero;
            rb.collisionDetectionMode = CollisionDetectionMode.ContinuousDynamic;
        }

        IsHeld = false;

        Debug.Log($"📦 Caja soltada en {transform.position}");
    }

    public GameObject GetGameObject() => gameObject;

    public void Interact(PlayerInteraction interactor)
    {
        var holder = interactor.GetComponent<PlayerHoldSystem>();
        if (holder == null) return;

        // Si el jugador tiene otro objeto: no hace nada
        if (!holder.HasItem)
        {
            holder.PickUp(this);
        }
    }


    public bool ContainsRecipe(RecipeSO receta)
    {
        // TODO: lógica real con ingredientes
        return true;
    }

    private void OnDrawGizmosSelected()
    {
        Gizmos.color = Color.cyan;
        Gizmos.DrawWireSphere(transform.position, 0.2f);
    }


}
