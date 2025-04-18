using UnityEngine;
using QFramework;
using System.Collections.Generic;

[RequireComponent(typeof(Collider))]
public class Box : MonoBehaviour, IInteractable
{
    [Header("Visual")]
    public GameObject highlightVisual; // opcional, por si quieres mostrar si está seleccionada

    [Header("Contenido")]
    public List<IngredientSO> ingredientes = new(); // si estás usando contenido interno
    public bool IsHeld { get; set; }

    public void Interact(PlayerInteraction interactor)
    {
        var holder = interactor.GetComponent<PlayerBoxHolder>();
        if (holder == null) return;

        if (IsHeld)
        {
            holder.DropBox();
        }
        else if (!holder.HasBox)
        {
            holder.PickUpBox(this);
        }
    }

    public void SetHighlight(bool active)
    {
        if (highlightVisual != null)
            highlightVisual.SetActive(active);
    }

    // Opcional: lógica extra para contenido o validaciones
    public bool ContainsRecipe(RecipeSO receta)
    {
        // Ejemplo básico
        // return ingredientes != null && ingredientes.Contains(receta.requiredIngredient);
        return true;
    }

    private void OnMouseEnter()
    {
        SetHighlight(true);
    }

    private void OnMouseExit()
    {
        SetHighlight(false);
    }
}
