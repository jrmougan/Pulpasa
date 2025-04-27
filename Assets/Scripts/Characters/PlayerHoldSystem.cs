using UnityEngine;

public class PlayerHoldSystem : MonoBehaviour
{
    [Header("Punto de sujeción")]
    public Transform holdPoint;

    private GameObject heldObject;
    private IPickable heldItem;

    public bool HasItem => heldItem != null;
    public GameObject HeldObject => heldObject;
    public IPickable HeldItem => heldItem;

    public void PickUp(GameObject obj)
    {
        if (HasItem) return;

        // 🔥 Buscar Slot cercano antes de cambiar el parent
        TryForceClearNearbySlot(obj);

        heldObject = obj;
        heldItem = obj.GetComponent<IPickable>();

        if (heldItem == null)
        {
            Debug.LogError("❌ El objeto no implementa IPickable");
            return;
        }

        var rb = heldObject.GetComponent<Rigidbody>();
        if (rb)
        {
            rb.isKinematic = true;
            rb.linearVelocity = Vector3.zero;
            rb.angularVelocity = Vector3.zero;
            rb.interpolation = RigidbodyInterpolation.None;
        }

        // 🔥 SOLO AHORA cambiamos el parent
        heldObject.transform.SetParent(holdPoint, false);
        heldObject.transform.localPosition = Vector3.zero;
        heldObject.transform.localRotation = Quaternion.identity;

        heldObject.layer = LayerMask.NameToLayer("HeldObject");

        Debug.Log($"✅ Recogido: {obj.name}");
    }

    public void Drop()
    {
        if (!HasItem) return;

        var dropPos = transform.position + transform.forward * 0.6f + Vector3.up * 0.6f;

        heldObject.layer = LayerMask.NameToLayer("Interactable");

        heldItem.OnDropped(dropPos);

        heldObject = null;
        heldItem = null;

        Debug.Log("📤 Objeto soltado.");
    }

    public void Clear()
    {
        if (heldObject != null)
        {
            heldObject.transform.SetParent(null);
            heldObject = null;
            heldItem = null;
        }
    }

    public void TryToggleHold(GameObject obj)
    {
        Debug.Log($"🔄 TryToggleHold llamado con: {obj.name}");

        if (heldItem != null && heldItem.GetGameObject() == obj)
        {
            Debug.Log("🔁 El jugador ya sostiene este objeto. Soltando...");
            Drop();
        }
        else if (!HasItem)
        {
            Debug.Log("🖐 El jugador no tenía objeto. Recogiendo...");
            PickUp(obj);
        }
        else
        {
            Debug.Log("❌ Ya tienes otro objeto en la mano.");
        }
    }

    // 🧠 NUEVO: Buscar Slot cercano para liberar
    private void TryForceClearNearbySlot(GameObject obj)
    {
        float searchRadius = 0.5f; // Radio pequeño para detectar Slots cercanos
        LayerMask slotLayer = LayerMask.GetMask("Interactable"); // O ajusta a la Layer donde están tus Slots

        Collider[] colliders = Physics.OverlapSphere(obj.transform.position, searchRadius, slotLayer);
        foreach (var col in colliders)
        {
            var slot = col.GetComponent<InteractableSlot>();
            if (slot != null && slot.HasItem)
            {
                Debug.Log($"📤 Slot liberado: {slot.name} al recoger {obj.name}");
                slot.ForceClearSlot();
                break; // solo liberar uno
            }
        }
    }
}
