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

        var heldObject = interactor.HoldSystem.HeldObject;
        if (heldObject == null) return;

        var ingredient = heldObject.GetComponent<Ingredient>();
        if (ingredient == null || ingredient.cookingState == CookingState.Cooked) return;
        if (ingredient.Data == null || !ingredient.Data.isCookable || ingredient.Data.type != IngredientType.Octopus) return;

        isBusy = true;
        currentIngredient = ingredient;

        interactor.HoldSystem.Drop();

        ingredient.transform.position = potTransform.position;
        ingredient.transform.rotation = potTransform.rotation;
        ingredient.transform.SetParent(potTransform);

        ingredient.gameObject.layer = LayerMask.NameToLayer("Cooking");

        kitchenProgress.gameObject.SetActive(true);
        kitchenProgress.StartCooking(ingredient.Data.cookTime);


    }

    private void HandleCookingDone()
    {
        Debug.Log("¡Pulpo cocido!");

        if (currentIngredient != null)
        {
            currentIngredient.SetCooked(); 
            currentIngredient.transform.SetParent(null); 
            var renderer = currentIngredient.GetComponentInChildren<Renderer>();
            currentIngredient.gameObject.layer = LayerMask.NameToLayer("Interactable");

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
