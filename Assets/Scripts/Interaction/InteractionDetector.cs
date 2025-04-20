using UnityEngine;
using System.Collections.Generic;
using System.Linq;

public class InteractionDetector : MonoBehaviour
{
    public float detectionRadius = 1.5f;
    public LayerMask interactableLayer;
    public bool drawGizmos = true;

    public IInteractable Current { get; private set; }
    private IInteractable previous;
    public PlayerHoldSystem holdSystem;

    private void Awake()
    {
        holdSystem = GetComponent<PlayerHoldSystem>();
    }

    void Update()
    {
        Collider[] hits = Physics.OverlapSphere(transform.position, detectionRadius, interactableLayer);
        List<IInteractable> candidates = new();

        foreach (var hit in hits)
        {
            // Intenta encontrar un IInteractable en el collider o sus hijos/padres
            var interactable = hit.GetComponentInParent<IInteractable>() ?? hit.GetComponentInChildren<IInteractable>();
            if (interactable != null && !candidates.Contains(interactable))
                candidates.Add(interactable);
        }

        IInteractable selected = null;

        if (holdSystem != null && holdSystem.HasItem)
        {
            // Si sostiene algo, buscar slots vacíos
            selected = candidates
                .Where(c => c is InteractableSlot slot && !slot.HasItem)
                .OrderBy(c => Vector3.Distance(c.GetGameObject().transform.position, transform.position))
                .FirstOrDefault();
        }
        else
        {
            // Si no sostiene nada, priorizar Kitchen si está cerca
            selected = candidates
                .OrderBy(c =>
                {
                    float dist = Vector3.Distance(c.GetGameObject().transform.position, transform.position);
                    bool isKitchen = c.GetGameObject().CompareTag("Kitchen");
                    return isKitchen ? dist * 0.5f : dist; // Kitchen tiene "más peso"
                })
                .FirstOrDefault();
        }

        // Actualiza los highlights si el objeto ha cambiado
        if (selected != previous)
        {
            previous?.GetGameObject().GetComponentInChildren<HighlightController>()?.Hide();
            selected?.GetGameObject().GetComponentInChildren<HighlightController>()?.Show();
            previous = selected;
        }

        Current = selected;
    }

    private void OnDrawGizmosSelected()
    {
        if (drawGizmos)
        {
            Gizmos.color = Color.yellow;
            Gizmos.DrawWireSphere(transform.position, detectionRadius);
        }
    }
}
