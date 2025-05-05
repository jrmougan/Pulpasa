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

        if (!HasItem && hold.HasItem)
        {
            currentItem = hold.HeldItem;
            GameObject go = currentItem.GetGameObject();

            SnappingHelper.AlignByAnchorPoint(go, anchor);

            Animator anim = go.GetComponentInChildren<Animator>();
            if (anim != null)
                anim.SetTrigger("Open");

            hold.Clear();
        }

        else if (HasItem && !hold.HasItem)
        {
            GameObject go = currentItem.GetGameObject();
            currentItem = null;
            hold.PickUp(go);
        }

        else if (HasItem && hold.HasItem)
        {
            Debug.Log("El slot ya contiene un objeto y el jugador también.");
        }
    }

    public void ForceClearSlot()
    {
        currentItem = null;
    }

    public IInteractable GetContainedItem() => currentItem as IInteractable;

    public GameObject GetGameObject() => gameObject;
}
