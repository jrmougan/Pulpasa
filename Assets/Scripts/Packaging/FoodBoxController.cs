using UnityEngine;

public class FoodBoxController : MonoBehaviour, IInteractable
{
    private Animator animator;
    private bool isOpen = false;

    private void Start()
    {
        animator = GetComponent<Animator>();
    }
    public void OpenBox()
    {
        animator.SetTrigger("open");
        isOpen = true;
    }
    public void CloseBox()
    {
        animator.SetTrigger("close");
        isOpen = false;
    }

    public void Interact(PlayerInteraction playerInteraction)
    {
        Debug.Log("INTERACT() llamada por: " + playerInteraction.gameObject.name + " - Time: " + Time.time);

        Debug.Log("Interacting with DebugBox!");
        if (isOpen)
        {
            CloseBox();
            Debug.Log("Cerrando");
        }
        else
        {
            OpenBox();
            Debug.Log("Abriendo");
        }
    }

}
