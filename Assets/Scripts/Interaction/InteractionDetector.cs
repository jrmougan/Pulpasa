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
        IInteractable closest = null;
        float closestDistance = Mathf.Infinity;

        foreach (var hit in hits)
        {
            var interactable = hit.GetComponentInParent<IInteractable>() ?? hit.GetComponentInChildren<IInteractable>();
            if (interactable == null) continue;

            // Si está sujetando algo, ignorar slots ocupados
            if (holdSystem.HasItem && interactable is InteractableSlot slot && slot.HasItem)
                continue;

            float dist = Vector3.Distance(hit.transform.position, transform.position);

            // Si es Kitchen y no llevas nada, dar peso extra
            if (!holdSystem.HasItem && interactable.GetGameObject().CompareTag("Kitchen"))
            {
                dist *= 0.25f; // prioriza
            }

            if (dist < closestDistance)
            {
                closest = interactable;
                closestDistance = dist;
            }
        }

        // Resaltar si ha cambiado
        if (closest != previous)
        {
            previous?.GetGameObject().GetComponentInChildren<HighlightController>()?.Hide();
            closest?.GetGameObject().GetComponentInChildren<HighlightController>()?.Show();
            previous = closest;
        }

        Current = closest;
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
