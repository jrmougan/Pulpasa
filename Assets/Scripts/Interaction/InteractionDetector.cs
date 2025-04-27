using UnityEngine;
using System.Collections.Generic;

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

        IPickable bestPickable = null;
        float bestPickableScore = -Mathf.Infinity;

        IInteractable bestInteractable = null;
        float bestInteractableScore = -Mathf.Infinity;

        foreach (var hit in hits)
        {
            var interactable = hit.GetComponentInParent<IInteractable>() ?? hit.GetComponentInChildren<IInteractable>();
            var pickable = hit.GetComponentInParent<IPickable>() ?? hit.GetComponentInChildren<IPickable>();

            if (interactable == null && pickable == null)
                continue;

            // 🔵 Altura ajustada
            Vector3 fromPosition = transform.position + Vector3.up * 0.8f;
            Vector3 toTarget = hit.transform.position - fromPosition;
            toTarget.y = 0;
            toTarget.Normalize();

            Vector3 forward = transform.forward;
            forward.y = 0;
            forward.Normalize();

            float dot = Vector3.Dot(forward, toTarget);
            float dist = Vector3.Distance(hit.transform.position, fromPosition);

            if (dist > 0.7f && dot < Mathf.Cos(30f * Mathf.Deg2Rad))
                continue;

            float score = dot * 2f + (1f / Mathf.Max(dist, 0.1f));

            // 🔥🔥🔥 Aquí hacemos la mejora 🔥🔥🔥

            bool holdingSeasoning = holdSystem.HeldObject?.GetComponent<SeasoningItem>() != null;

            // Si es un slot ocupado y llevas algo, mirar su contenido
            if (interactable is InteractableSlot slot && slot.HasItem)
            {
                var contained = slot.GetContainedItem();
                if (contained != null)
                {
                    interactable = contained;
                }
                else
                {
                    continue; // slot vacío, no sirve
                }
            }

            if (pickable != null && !holdSystem.HasItem)
            {
                if (score > bestPickableScore)
                {
                    bestPickable = pickable;
                    bestPickableScore = score;
                }
            }
            else if (interactable != null)
            {
                if (interactable is InteractableSlot slotInteractable)
                {
                    if (slotInteractable.HasItem && holdSystem.HasItem)
                    {
                        continue; // 🔥 Saltar porque no queremos interactuar con slot ocupado si llevamos algo
                    }
                }

                if (!holdSystem.HasItem && interactable.GetGameObject().CompareTag("Kitchen"))
                    score += 1.0f;

                if (score > bestInteractableScore)
                {
                    bestInteractable = interactable;
                    bestInteractableScore = score;
                }
            }
        }

        IInteractable best = bestPickable as IInteractable ?? bestInteractable;

        if (best != previous)
        {
            previous?.GetGameObject().GetComponentInChildren<HighlightController>()?.Hide();
            best?.GetGameObject().GetComponentInChildren<HighlightController>()?.Show();
            previous = best;
        }

        Current = best;
    }

    private void OnDrawGizmosSelected()
    {
        if (drawGizmos)
        {
            Gizmos.color = Color.yellow;
            Gizmos.DrawWireSphere(transform.position, detectionRadius);

            // 🔥 Opcional: Dibujar el cono de visión (solo visual, no afecta al juego)
            Vector3 leftLimit = Quaternion.Euler(0, -30, 0) * transform.forward;
            Vector3 rightLimit = Quaternion.Euler(0, 30, 0) * transform.forward;

            Gizmos.color = Color.cyan;
            Gizmos.DrawLine(transform.position, transform.position + leftLimit * detectionRadius);
            Gizmos.DrawLine(transform.position, transform.position + rightLimit * detectionRadius);
        }
    }
}
