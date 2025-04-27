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

            // 🔥 Asegurar Layer correcto
            go.layer = LayerMask.NameToLayer("Interactable");

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

            currentItem = null;
            hold.PickUp(go);
        }
        // 🔶 CASO NUEVO: tienes algo en mano y el slot también está ocupado
        else if (currentItem != null && hold.HasItem)
        {
            Debug.Log("⚠️ No puedes colocar porque el Slot ya tiene un objeto y tú llevas otro.");
            // Aquí podrías añadir lógica de swap en el futuro si quieres.
        }
    }

    public void ForceClearSlot()
    {
        currentItem = null;
    }

    public GameObject GetGameObject() => gameObject;
}