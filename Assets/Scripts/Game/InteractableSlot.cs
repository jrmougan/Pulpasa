using UnityEngine;

public class InteractableSlot : MonoBehaviour, IInteractable
{
    [SerializeField] private Transform anchor;
    private IPickable currentItem;

    public bool HasItem => currentItem != null;

    public void Interact(PlayerInteractionController player)
    {
        var hold = player.HoldSystem;
        if (hold == null) return;

        if (currentItem == null && hold.HasItem)
        {
            currentItem = hold.HeldItem;
            var go = currentItem.GetGameObject();

            SlotHelper.SnapObjectToAnchor(go, anchor);
            var rb = go.GetComponent<Rigidbody>();
            if (rb)
            {
                rb.isKinematic = true;
                rb.linearVelocity = Vector3.zero;
                rb.angularVelocity = Vector3.zero;
            }

            hold.Clear();
        }
        else if (currentItem != null && !hold.HasItem)
        {
            hold.PickUp(currentItem.GetGameObject());
            currentItem = null;
        }
    }

    public GameObject GetGameObject() => gameObject;
}
