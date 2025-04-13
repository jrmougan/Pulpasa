using UnityEngine;

public class DebugBox : MonoBehaviour, IInteractable
{
    public void Interact(PlayerInteraction interactor)
    {
        Debug.Log("Interacting with DebugBox!");
        // Aquí puedes agregar la lógica que quieras al interactuar con el objeto
    }

    void Start()
    {

    }

    // Update is called once per frame
    void Update()
    {

    }
}
