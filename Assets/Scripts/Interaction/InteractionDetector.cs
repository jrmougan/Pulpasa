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
            var interactable = hit.GetComponentInParent<IInteractable>() ?? hit.GetComponentInChildren<IInteractable>();
            if (interactable != null)
                candidates.Add(interactable);
        }

        // FILTRADO INTELIGENTE
        IInteractable selected = null;

        if (holdSystem != null && holdSystem.HasItem)
        {
            // Si tengo algo en la mano → buscar slots disponibles
            selected = candidates
                .Where(c => c is InteractableSlot slot && !slot.HasItem)
                .OrderBy(c => Vector3.Distance(c.GetGameObject().transform.position, transform.position))
                .FirstOrDefault();
        }
        else
        {
            // Si no tengo nada → buscar el más cercano (caja o slot con objeto)
            selected = candidates
                .OrderBy(c => Vector3.Distance(c.GetGameObject().transform.position, transform.position))
                .FirstOrDefault();
        }

        // Actualizamos highlight como antes
        if (selected != previous)
        {
            previous?.GetGameObject().GetComponentInChildren<InteractableHighlight>()?.Hide();
            selected?.GetGameObject().GetComponentInChildren<InteractableHighlight>()?.Show();
            previous = selected;
        }

        Current = selected;
    }

    void OnDrawGizmosSelected()
    {
        if (drawGizmos)
        {
            Gizmos.color = Color.yellow;
            Gizmos.DrawWireSphere(transform.position, detectionRadius);
        }
    }
}
