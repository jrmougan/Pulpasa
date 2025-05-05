using UnityEngine;

public class SeasoningItem : MonoBehaviour, IPickable, IInteractable
{
    [SerializeField] private SpicesSO seasoning;

    public bool IsHeld { get; private set; }
    public SpicesSO GetSeasoning() => seasoning;
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

        var target = player.InteractionDetector?.Current;

        if (target == null) return;

        Box box = target.GetGameObject().GetComponent<Box>();
        if (box != null)
        {
            if (!box.IsFull()) return;

            if (box.CanReceiveSeasoning(seasoning))
            {
                box.ApplySeasoning(seasoning);
                // todo: feedback de aplicar condimento
                player.HoldSystem.Drop();
                Destroy(gameObject);
            }
        }
    }

    public GameObject GetGameObject() => gameObject;
}
