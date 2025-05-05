using UnityEngine;
using System.Collections.Generic;
using UnityEngine.UIElements;
using Unity.VisualScripting;

public class Box : MonoBehaviour, IPickable, IInteractable
{
    [SerializeField] private bool canBePickedUp = true;

    [SerializeField] private bool isSpawner = false;
    [SerializeField] private GameObject boxPrefab;

    [SerializeField] private IngredientSO ingredient;
    [SerializeField] private BoxSO boxSO;
    public AudioSource audioSource;
    public AudioClip millSound;

    [SerializeField] private float fillAmount = 0f; // 0 = vacío, 1 = lleno
    [SerializeField] private float fillPerPress = 0.05f; // cuánto llena cada pulsación
    [SerializeField] private float maxFill = 1f; // cuando llega a 1 está completa

    public SimpleProgressBar progressBar;

    public bool IsFull()
    {
        return fillAmount >= maxFill;
    }

    public float GetFillPercent()
    {
        return fillAmount * 100f; // Devuelve el porcentaje de llenado
    }

    public float GetFillPerPress()
    {
        return fillPerPress;
    }

    public void Fill(float amount)
    {
        fillAmount += amount;
        fillAmount = Mathf.Clamp(fillAmount, 0f, maxFill);

        Debug.Log($"🧪 Caja llena: {fillAmount * 100f}%");
        if (fillAmount > 0 && progressBar != null)
        {
            progressBar.gameObject.SetActive(true);

        }
        if (progressBar != null)
        {
            progressBar.SetProgress(fillAmount);
        }

        if (fillAmount >= maxFill)
        {
            Debug.Log("✅ Caja llena al 100%!");
            progressBar.gameObject.SetActive(false);


        }
    }

    public IngredientSO GetIngredient() => ingredient;
    public BoxSO GetBoxSO() => boxSO;


    public bool IsHeld { get; private set; }

    [SerializeField] private bool isFilled = false;
    public bool IsFilled => isFilled;
    public List<SpicesSO> appliedSeasonings = new();

    public void ApplySeasoning(SpicesSO seasoning)
    {
        if (CanReceiveSeasoning(seasoning))
        {
            appliedSeasonings.Add(seasoning);
            audioSource.PlayOneShot(millSound);
            Debug.Log($"{seasoning.type} aplicado a la caja {name}");
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
        return IsFull() && !appliedSeasonings.Contains(seasoning);
    }

    public void OnPickedUp(Transform parent)
    {
        var slot = GetComponentInParent<InteractableSlot>();
        if (slot != null)
        {
            slot.ForceClearSlot();
        }

        transform.SetParent(parent);
        transform.localPosition = Vector3.zero;
        transform.localRotation = Quaternion.identity;

        var rb = GetComponent<Rigidbody>();
        if (rb)
        {
            rb.isKinematic = true;
            rb.linearVelocity = Vector3.zero;
            rb.angularVelocity = Vector3.zero;
        }

        IsHeld = true;
    }


    public void OnDropped(Vector3 dropPosition, bool keepParent = false)
    {
        if (!keepParent)
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

    public void OnDropped(Vector3 dropPosition)
    {
        OnDropped(dropPosition, false);
    }



    public GameObject GetGameObject() => gameObject;

    public void Interact(PlayerInteractionController interactor)
    {
        if (isSpawner)
        {
            if (boxPrefab != null)
            {
                GameObject spawned = Instantiate(boxPrefab);
                Canvas canvas = spawned.GetComponentInChildren<Canvas>();
                if (canvas != null)
                {
                    canvas.worldCamera = Camera.main;
                }
                interactor.HoldSystem.PickUp(spawned);
            }
            else
            {
                Debug.LogWarning("No hay prefab asignado para spawnear.");
            }

            return;
        }

        if (!canBePickedUp)
        {
            Debug.Log("No se puede recoger esta caja.");
            return;
        }


        interactor.HoldSystem.TryToggleHold(gameObject);
    }

}
