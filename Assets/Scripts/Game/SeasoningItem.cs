using UnityEngine;

public class SeasoningItem : MonoBehaviour, IPickable, IInteractable
{
    [SerializeField] private SpicesSO seasoning;

    public bool IsHeld { get; private set; }

    public void OnPickedUp(Transform parent)
    {
        transform.SetParent(parent);
        transform.localPosition = Vector3.zero;
        transform.localRotation = Quaternion.identity;

        var rb = GetComponent<Rigidbody>();
        if (rb)
        {
            rb.isKinematic = true;
            rb.linearVelocity = Vector3.zero;
            rb.angularVelocity = Vector3.zero;
        }

        IsHeld = true;
    }

    public void OnDropped(Vector3 dropPosition)
    {
        transform.SetParent(null);
        transform.position = dropPosition;

        var rb = GetComponent<Rigidbody>();
        if (rb)
        {
            rb.isKinematic = false;
            rb.linearVelocity = Vector3.zero;
            rb.angularVelocity = Vector3.zero;
        }

        IsHeld = false;
    }

    public void Interact(PlayerInteractionController player)
    {
        if (!IsHeld)
        {
            Debug.Log($"📥 Recogiendo {seasoning.name}");
            player.HoldSystem.TryToggleHold(gameObject);
            return;
        }

        // Si ya está sostenido, intentar sazonar el objeto objetivo
        var target = player.InteractionDetector?.Current;

        if (target == null)
        {
            Debug.Log("❗ No hay objeto objetivo para aplicar condimento.");
            return;
        }

        // 🔥 Verificar si el objetivo es una caja (Box)
        Box box = target.GetGameObject().GetComponent<Box>();
        if (box != null)
        {
            if (!box.IsFull())
            {
                Debug.Log("⚠️ La caja aún no está llena, no puedes sazonar.");
                return;
            }

            if (box.CanReceiveSeasoning(seasoning))
            {
                box.ApplySeasoning(seasoning);
                Debug.Log($"🧂 Aplicado {seasoning.type} a {box.name}");

                // Opcional: consumir el Seasoning después de usarlo
                player.HoldSystem.Drop();
                Destroy(gameObject); // ❗ Solo si quieres que desaparezca
            }
            else
            {
                Debug.Log("⚠️ Esta caja ya tiene este condimento aplicado.");
            }
        }
        else
        {
            Debug.Log("❌ No puedes aplicar el condimento a este objeto.");
        }
    }

    public GameObject GetGameObject() => gameObject;
}
