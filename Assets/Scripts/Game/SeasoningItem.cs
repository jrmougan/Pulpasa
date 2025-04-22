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

        // Si ya está sostenido, intentamos aplicar el condimento al objeto objetivo
        var target = player.InteractionDetector?.Current;

        if (target == null)
        {
            Debug.Log("❗ No hay objeto objetivo para aplicar condimento.");
            return;
        }

        var seasonable = target.GetGameObject().GetComponent<ISeasonable>();
        if (seasonable != null && seasonable.CanReceiveSeasoning(seasoning))
        {
            seasonable.ApplySeasoning(seasoning);
            Debug.Log($"🧂 Aplicado {seasoning.type} a {target.GetGameObject().name}");
        }
        else
        {
            Debug.Log("⚠️ No se puede aplicar el condimento.");
        }
    }

    public GameObject GetGameObject() => gameObject;
}
