using UnityEngine;

[RequireComponent(typeof(InteractionDetector))]
[RequireComponent(typeof(PlayerHoldSystem))]
public class PlayerInteractionController : MonoBehaviour
{
    private InteractionDetector detector;
    private PlayerHoldSystem holdSystem;

    private void Awake()
    {
        detector = GetComponent<InteractionDetector>();
        holdSystem = GetComponent<PlayerHoldSystem>();
    }

    public PlayerHoldSystem HoldSystem => holdSystem;

    public void HandleInteraction()
    {
        if (detector.Current != null)
        {
            Debug.Log($"🎯 Interactuando con: {detector.Current.GetGameObject().name}");
            detector.Current.Interact(this);
        }
        else if (HoldSystem.HasItem)
        {
            Debug.Log("📤 No hay target, soltando objeto en el suelo.");
            HoldSystem.Drop();
        }
        else
        {
            Debug.Log("❌ No hay nada que interactuar ni objeto en mano.");
        }
    }
}
