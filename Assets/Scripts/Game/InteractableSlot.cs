using UnityEngine;

public class InteractableSlot : MonoBehaviour, IInteractable
{
    [SerializeField] private Transform anchor;
    private IPickable currentItem; // 🔥 Solo privado

    public bool HasItem => currentItem != null;

    public void Interact(PlayerInteractionController player)
    {
        var hold = player.HoldSystem;
        if (hold == null) return;

        if (currentItem == null && hold.HasItem)
        {
            currentItem = hold.HeldItem;
            var go = currentItem.GetGameObject();

            SnappingHelper.AlignByAnchorPoint(go, anchor);

            go.layer = LayerMask.NameToLayer("Interactable");

            Animator anim = go.GetComponentInChildren<Animator>();
            if (anim != null)
                anim.SetTrigger("Open");

            hold.Clear();
        }

        else if (currentItem != null && !hold.HasItem)
        {
            var go = currentItem.GetGameObject();
            currentItem = null;
            hold.PickUp(go);
        }
        else if (currentItem != null && hold.HasItem)
        {
            Debug.Log("El Slot ya tiene un objeto, no puedes colocar otro encima.");
        }
    }



    public void ForceClearSlot()
    {
        currentItem = null;
    }

    public IInteractable GetContainedItem()
    {
        return currentItem as IInteractable;
    }

    public GameObject GetGameObject() => gameObject;
}
