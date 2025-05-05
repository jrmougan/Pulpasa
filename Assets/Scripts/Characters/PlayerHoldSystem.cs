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

        TryForceClearNearbySlot(obj);

        heldObject = obj;
        heldItem = obj.GetComponent<IPickable>();

        if (heldItem == null) return;

        var rb = heldObject.GetComponent<Rigidbody>();
        if (rb)
        {
            rb.isKinematic = true;
            rb.linearVelocity = Vector3.zero;
            rb.angularVelocity = Vector3.zero;
            rb.interpolation = RigidbodyInterpolation.None;
        }

        heldObject.transform.SetParent(holdPoint, false);
        heldObject.transform.localPosition = Vector3.zero;
        heldObject.transform.localRotation = Quaternion.identity;

        heldObject.layer = LayerMask.NameToLayer("HeldObject");

    }

    public void Drop()
    {
        if (!HasItem) return;

        var dropPos = transform.position + transform.forward * 0.6f + Vector3.up * 0.6f;

        heldObject.layer = LayerMask.NameToLayer("Interactable");

        heldItem.OnDropped(dropPos);

        heldObject = null;
        heldItem = null;

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

        if (heldItem != null && heldItem.GetGameObject() == obj)
        {
            Drop();
        }
        else if (!HasItem)
        {
            PickUp(obj);
        }

    }

    private void TryForceClearNearbySlot(GameObject obj)
    {
        float searchRadius = 0.5f; 
        LayerMask slotLayer = LayerMask.GetMask("Interactable"); 

        Collider[] colliders = Physics.OverlapSphere(obj.transform.position, searchRadius, slotLayer);
        foreach (var col in colliders)
        {
            var slot = col.GetComponent<InteractableSlot>();
            if (slot != null && slot.HasItem)
            {
                slot.ForceClearSlot();
                break;
            }
        }
    }
}
