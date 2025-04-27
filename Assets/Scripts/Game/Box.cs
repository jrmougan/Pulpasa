using UnityEngine;
using System.Collections.Generic;

public class Box : MonoBehaviour, IPickable, IInteractable
{
    [SerializeField] private bool canBePickedUp = true;

    [SerializeField] private bool isSpawner = false;
    [SerializeField] private GameObject boxPrefab;

    [SerializeField] private IngredientSO ingredient;
    [SerializeField] private BoxSO boxSO;

    [SerializeField] private float fillAmount = 0f; // 0 = vacío, 1 = lleno
    [SerializeField] private float fillPerPress = 0.05f; // cuánto llena cada pulsación
    [SerializeField] private float maxFill = 1f; // cuando llega a 1 está completa

    public bool IsFull()
    {
        return fillAmount >= maxFill;
    }

    public float GetFillPercent()
    {
        return fillAmount * 100f; // Devuelve el porcentaje de llenado
    }

    public void Fill(float amount)
    {
        fillAmount += amount;
        fillAmount = Mathf.Clamp(fillAmount, 0f, maxFill);

        // 🎨 Aquí podrías actualizar un UI de barra de progreso en la caja
        Debug.Log($"🧪 Caja llena: {fillAmount * 100f}%");
    }

    public IngredientSO GetIngredient() => ingredient;
    public BoxSO GetBoxSO() => boxSO;


    public bool IsHeld { get; private set; }

    [SerializeField] private bool isFilled = false;
    public List<SpicesSO> appliedSeasonings = new();

    public void ApplySeasoning(SpicesSO seasoning)
    {
        if (CanReceiveSeasoning(seasoning))
        {
            appliedSeasonings.Add(seasoning);
            Debug.Log($"🍽 {seasoning.type} aplicado a la caja {name}");
        }
    }

    public void SetIngredient(IngredientSO newIngredient)
    {
        ingredient = newIngredient;
        isFilled = true;
    }

    public void SetBoxSO(BoxSO box) => boxSO = box;

    public bool CanReceiveSeasoning(SpicesSO seasoning)
    {
        return isFilled && !appliedSeasonings.Contains(seasoning);
    }

    public void OnPickedUp(Transform parent)
    {
        if (!canBePickedUp) return;

        Debug.Log("📦 Box.OnPickedUp() ejecutado.");

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

        // layer a interactable
        gameObject.layer = LayerMask.NameToLayer("Interactable");
        IsHeld = false;
    }

    public GameObject GetGameObject() => gameObject;

    public void Interact(PlayerInteractionController interactor)
    {
        if (isSpawner)
        {
            Debug.Log("📦 Spawner: Instanciando nueva caja.");

            if (boxPrefab != null)
            {
                GameObject spawned = Instantiate(boxPrefab);
                interactor.HoldSystem.PickUp(spawned);
            }
            else
            {
                Debug.LogWarning("⚠️ No hay prefab asignado para spawnear.");
            }

            return;
        }

        if (!canBePickedUp)
        {
            Debug.Log("❌ No se puede recoger esta caja.");
            return;
        }

        Debug.Log("📦 Box.Interact() ejecutado.");
        interactor.HoldSystem.TryToggleHold(gameObject);
    }

}
