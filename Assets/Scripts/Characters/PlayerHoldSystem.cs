using UnityEngine;

public class PlayerHoldSystem : MonoBehaviour
{
    [Header("Punto de sujeción")]
    public Transform holdPoint;

    private IPickable heldItem;

    public bool HasItem => heldItem != null;

    public void PickUp(IPickable item)
    {
        if (HasItem)
        {
            Debug.LogWarning($"⚠️ Ya se está sujetando un objeto: {heldItem.GetGameObject().name}. No se puede recoger {item.GetGameObject().name}");
            return;
        }

        heldItem = item;

        if (heldItem == null)
        {
            Debug.LogError("❌ Error: IPickable pasado a PickUp() es null.");
            return;
        }

        heldItem.OnPickedUp(holdPoint);
        Debug.Log($"✅ Recogido: {heldItem.GetGameObject().name}");
    }

    public void Drop()
    {
        if (!HasItem)
        {
            Debug.LogWarning("⚠️ No hay objeto en la mano para soltar.");
            return;
        }

        if (heldItem.GetGameObject() == null)
        {
            Debug.LogError("❌ Error: el objeto recogido ha sido destruido o es null.");
            heldItem = null;
            return;
        }

        Vector3 dropPos = transform.position + transform.forward * 0.6f + Vector3.up * 0.3f;
        heldItem.OnDropped(dropPos);
        Debug.Log($"📤 Soltado: {heldItem.GetGameObject().name} en {dropPos}");

        heldItem = null;
    }

    public GameObject GetHeldObject() => heldItem?.GetGameObject();
}
