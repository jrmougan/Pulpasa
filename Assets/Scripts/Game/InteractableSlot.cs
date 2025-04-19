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

        // 🟩 COLOCAR objeto en el slot
        if (currentItem == null && hold.HasItem)
        {
            currentItem = hold.HeldItem;
            var go = currentItem.GetGameObject();

            SnappingHelper.AlignByAnchorPoint(go, anchor);

            // ✅ Animar apertura
            Animator anim = go.GetComponentInChildren<Animator>();
            if (anim != null)
                anim.SetTrigger("Open");

            hold.Clear();
        }

        // 🟥 RECOGER objeto desde el slot
        else if (currentItem != null && !hold.HasItem)
        {
            var go = currentItem.GetGameObject();

            // ✅ Animar cierre
            Animator anim = go.GetComponentInChildren<Animator>();
            if (anim != null)
                anim.SetTrigger("Close");

            hold.PickUp(go);
            currentItem = null;
        }
    }


    public GameObject GetGameObject() => gameObject;
}
