using UnityEngine;

public class Box : MonoBehaviour, IPickable, IInteractable
{
    [SerializeField] private GameObject highlightVisual;

    public bool IsHeld { get; private set; }

    public void OnPickedUp(Transform parent)
    {
        if (highlightVisual) highlightVisual.SetActive(false);

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
        if (highlightVisual) highlightVisual.SetActive(true);
    }

    public GameObject GetGameObject() => gameObject;

    public void Interact(PlayerInteractionController interactor)
    {
        Debug.Log("📦 Box.Interact() ejecutado.");
        interactor.HoldSystem.TryToggleHold(gameObject);
    }
}
