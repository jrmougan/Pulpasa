using System.Collections;
using UnityEngine;


public class Ingredient : MonoBehaviour, IPickable, IInteractable, ISeasonable
{
    [SerializeField] private IngredientType type;
    [SerializeField] private bool canBePickedUp = true;

    [SerializeField] private IngredientSO data;

    public float remainintCuantity = 100f;

    public SimpleProgressBar progressBar;
    public IngredientSO Data => data;

    public IngredientType Type => type;

    public CookingState cookingState = CookingState.Raw;
    public bool IsHeld { get; private set; }

    public void SetCooked()
    {
        cookingState = CookingState.Cooked;
        // cambiar color, icono, sprite, etc. aquí
    }

    public IngredientSO GetIngredientSO() => data;

    public bool IsCooked => cookingState == CookingState.Cooked;


    public void Cut(float amount)
    {
        if (remainintCuantity <= 0f) return;

        if (remainintCuantity < 100f && progressBar != null)
        {
            progressBar.gameObject.SetActive(true);
        }

        remainintCuantity -= amount;
        remainintCuantity = Mathf.Clamp(remainintCuantity, 0f, 100f);

        Debug.Log($"🔪 Cortando {type}: {remainintCuantity}% restante");

        if (progressBar != null)
        {
            progressBar.SetProgress(remainintCuantity / 100f);
            if (remainintCuantity <= 0f)
            {
                progressBar.gameObject.SetActive(false);
                gameObject.SetActive(false);
                StartCoroutine(DestroyWithDelay(0.5f));
            }
        }
    }

    public void OnPickedUp(Transform parent)
    {
        if (!canBePickedUp) return;

        Debug.Log($"🧺 Ingrediente recogido: {type}");

        transform.SetParent(parent);
        transform.localPosition = Vector3.zero;
        transform.localRotation = Quaternion.identity;

        var rb = GetComponent<Rigidbody>();
        if (rb)
        {
            rb.linearVelocity = Vector3.zero;
            rb.angularVelocity = Vector3.zero;
            rb.isKinematic = true;
        }

        IsHeld = true;
    }

    public void OnDropped(Vector3 dropPosition)
    {
        transform.SetParent(null);
        transform.position = dropPosition;

        var rb = GetComponent<Rigidbody>();
        if (rb)
        {
            rb.isKinematic = false;
            rb.linearVelocity = Vector3.zero;
            rb.angularVelocity = Vector3.zero;
        }

        IsHeld = false;
    }

    public void Interact(PlayerInteractionController interactor)
    {
        if (!canBePickedUp) return;

        interactor.HoldSystem.TryToggleHold(gameObject);
    }

    public void ApplySeasoning(SpicesSO SpicesSO)
    {
        Debug.Log($"🧂 Aplicando {SpicesSO.type} a {type}");

        // Aquí puedes agregar la lógica para aplicar el sazonador al ingrediente.
        // Por ejemplo, podrías cambiar su color o modificar su comportamiento.
    }

    public bool CanReceiveSeasoning(SpicesSO SpicesSO)
    {
        // Aquí puedes agregar la lógica para determinar si el ingrediente puede recibir el sazonador.
        // Por ejemplo, podrías verificar si el ingrediente ya tiene un sazonador aplicado.
        return true; // Por defecto, todos los ingredientes pueden recibir sazonadores.
    }
    private IEnumerator DestroyWithDelay(float delay)
    {
        yield return new WaitForSeconds(delay);
        Destroy(gameObject);
    }

    public GameObject GetGameObject() => gameObject;
}


