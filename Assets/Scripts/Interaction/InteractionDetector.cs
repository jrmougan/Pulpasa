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
            // 🔥 Filtrar colliders no deseados aquí si es necesario (por Layer, Tag o componente especial)

            var interactable = hit.GetComponentInParent<IInteractable>() ?? hit.GetComponentInChildren<IInteractable>();
            var pickable = hit.GetComponentInParent<IPickable>() ?? hit.GetComponentInChildren<IPickable>();

            if (interactable == null && pickable == null)
                continue;

            Vector3 toTarget = (hit.transform.position - transform.position).normalized;
            float dot = Vector3.Dot(transform.forward, toTarget);

            if (dot < Mathf.Cos(30f * Mathf.Deg2Rad))
                continue; // ❌ Fuera del ángulo de visión permitido

            float dist = Vector3.Distance(hit.transform.position, transform.position);
            float score = dot * 2f + (1f / Mathf.Max(dist, 0.1f)); // 💡 Score combinando alineación + distancia

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
                if (holdSystem.HasItem && interactable is InteractableSlot slot && slot.HasItem)
                    continue; // ⚠️ Ignorar slots ocupados si llevas algo

                if (!holdSystem.HasItem && interactable.GetGameObject().CompareTag("Kitchen"))
                    score += 1.0f; // 🎯 Bonus si es cocina y vas vacío

                if (score > bestInteractableScore)
                {
                    bestInteractable = interactable;
                    bestInteractableScore = score;
                }
            }
        }

        // ✅ Prioridad: primero pickables, luego interactuables
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
