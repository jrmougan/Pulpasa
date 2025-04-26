using UnityEngine;

public class KitchenStation : MonoBehaviour, IInteractable
{
    [SerializeField] private Transform potTransform;


    private bool isBusy = false;
    private Ingredient currentIngredient;
    [SerializeField] private KitchenProgress kitchenProgress;


    public GameObject GetGameObject() => gameObject;

    private void Awake()
    {
        kitchenProgress.OnCookingFinished += HandleCookingDone;
    }
    public void Interact(PlayerInteractionController interactor)
    {
        if (isBusy) return;
        Debug.Log("🍳 Interactuando con la estación de cocina.");

        var heldObject = interactor.HoldSystem.HeldObject;
        if (heldObject == null) return;

        var ingredient = heldObject.GetComponent<Ingredient>();
        if (ingredient == null) return;
        Debug.Log($"🍳 Interactuando con ingrediente: {ingredient.Data.type}");
        if (ingredient.Data == null || !ingredient.Data.isCookable || ingredient.Data.type != IngredientType.Octopus) return;

        isBusy = true;
        currentIngredient = ingredient;

        // Soltar de la mano del jugador
        interactor.HoldSystem.Drop();

        // Posicionar el ingrediente sobre la olla
        ingredient.transform.position = potTransform.position;
        ingredient.transform.rotation = potTransform.rotation;
        ingredient.transform.SetParent(potTransform);

        kitchenProgress.gameObject.SetActive(true);
        kitchenProgress.StartCooking(ingredient.Data.cookTime);


    }

    private void HandleCookingDone()
    {
        Debug.Log("🐙 ¡Pulpo cocido!");

        if (currentIngredient != null)
        {
            currentIngredient.SetCooked(); // Cambiar estado
            currentIngredient.transform.SetParent(null); // Liberarlo visualmente
            var renderer = currentIngredient.GetComponentInChildren<Renderer>();
            if (renderer != null)
            {
                var materials = renderer.materials;
                materials[0].color = new Color(1f, 0.5f, 0.3f);
                materials[1].color = new Color(0.8f, 0.2f, 0.2f);
            }
        }

        isBusy = false;
    }
}
