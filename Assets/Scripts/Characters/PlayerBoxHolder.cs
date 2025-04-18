using UnityEngine;
using QFramework;

public class PlayerBoxHolder : MonoBehaviour, IController
{
    public Transform holdPoint;
    private Box heldBox;


    public bool HasBox => heldBox != null;

    public void PickUpBox(Box box)
    {
        heldBox = box;
        box.transform.SetParent(holdPoint);
        box.transform.localPosition = Vector3.zero;
        box.transform.localRotation = Quaternion.identity;

        var rb = box.GetComponent<Rigidbody>();
        if (rb) rb.isKinematic = true;

        box.IsHeld = true;

        this.GetArchitecture().SendEvent(new ObjectPickedUpEvent(box.gameObject));
    }

    public void DropBox()
    {
        if (heldBox == null) return;

        // Ignorar colisión reversa
        Collider boxCol = heldBox.GetComponent<Collider>();
        foreach (var col in GetComponentsInChildren<Collider>())
            Physics.IgnoreCollision(boxCol, col, false);

        // Posición segura de drop
        Vector3 dropPos = transform.position + transform.forward * 0.6f + Vector3.up * 0.3f;
        heldBox.transform.SetParent(null);
        heldBox.transform.position = dropPos;

        // Reactivar física
        var rb = heldBox.GetComponent<Rigidbody>();
        if (rb)
        {
            rb.isKinematic = false;
            rb.collisionDetectionMode = CollisionDetectionMode.Continuous;
            rb.angularVelocity = Vector3.zero;
            rb.linearVelocity = Vector3.zero;
        }

        heldBox.IsHeld = false;

        this.GetArchitecture().SendEvent(new ObjectDroppedEvent(heldBox.gameObject, transform));

        heldBox = null;
    }
    public Box GetBox() => heldBox;


    public IArchitecture GetArchitecture() => PulpaSAArchitecture.Interface;
}
