using UnityEngine;
using UnityEngine.UIElements;

[RequireComponent(typeof(InteractionDetector))]
[RequireComponent(typeof(PlayerHoldSystem))]
public class PlayerInteractionController : MonoBehaviour
{
    private InteractionDetector detector;
    private PlayerHoldSystem holdSystem;
    [SerializeField] private InteractionDetector interactionDetector;
    public InteractionDetector InteractionDetector => interactionDetector;


    private void Awake()
    {
        detector = GetComponent<InteractionDetector>();
        holdSystem = GetComponent<PlayerHoldSystem>();
    }

    public PlayerHoldSystem HoldSystem => holdSystem;

    public void HandleInteraction()
    {
        if (TryCutPulpo())
            return;

        if (TrySeasonBox())
            return;

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

    private bool TryCutPulpo()
    {
        if (HoldSystem.HeldObject == null)
            return false;

        var ingredient = HoldSystem.HeldObject.GetComponent<Ingredient>();


        if (ingredient == null || !ingredient.IsCooked)
            return false; // No llevas pulpo cocinado

        var targetBox = InteractionDetector.Current?.GetGameObject().GetComponent<Box>();
        if (targetBox == null || targetBox.IsFull())
            return false; // No apuntas a una caja válida

        // 🎯 Llenar la caja un poquito
        // cantidad a llenar del tipo de caja
        float fillPerPress = targetBox.gameObject.GetComponent<Box>().GetFillPerPress(); // Ajustar según el tipo de caja
        targetBox.Fill(fillPerPress);
        ingredient.Cut(fillPerPress * 50); // Ajustar según el tipo de ingrediente

        Debug.Log($"🔪 Cortando pulpo: Caja llena {targetBox.GetFillPercent()}%");

        // ✅ Si la caja se llenó completamente, soltamos el pulpo
        if (targetBox.IsFull())
        {
            Debug.Log("📦 Caja completamente llena");
            targetBox.SetIngredient(ingredient.GetIngredientSO());
        }

        if (ingredient.remainintCuantity <= 0f)
        {
            Debug.Log("❌ Pulpo cortado completamente, soltando.");
            HoldSystem.Drop();
        }



        return true; // Importante: devolver true si procesamos acción especial
    }

    private bool TrySeasonBox()
    {
        if (HoldSystem.HeldObject == null)
            return false;

        var seasoningItem = HoldSystem.HeldObject.GetComponent<SeasoningItem>();
        if (seasoningItem == null)
            return false; // No llevas una especia

        var targetBox = InteractionDetector.Current?.GetGameObject().GetComponent<Box>();
        if (targetBox == null || !targetBox.IsFull())
            return false; // No apuntas a una caja llena

        if (!targetBox.CanReceiveSeasoning(seasoningItem.GetSeasoning()))
        {
            Debug.Log("⚠️ Esta caja no puede recibir más sazonadores o ya tiene este.");
            return true; // 🔥 CONSUMIMOS el input igual
        }

        // 🎯 Aplicar sazonador
        targetBox.ApplySeasoning(seasoningItem.GetSeasoning());

        Debug.Log($"🧂 {seasoningItem.GetSeasoning().type} aplicado a {targetBox.name}");

        return true;
    }
}
