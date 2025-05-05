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
    [SerializeField] private AudioClip cutAudio;


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
            detector.Current.Interact(this);
        }
        else if (HoldSystem.HasItem)
        {
            HoldSystem.Drop();
        }
    }

    private bool TryCutPulpo()
    {
        if (HoldSystem.HeldObject == null)
            return false;

        var ingredient = HoldSystem.HeldObject.GetComponent<Ingredient>();


        if (ingredient == null || !ingredient.IsCooked)
            return false; 

        var targetBox = InteractionDetector.Current?.GetGameObject().GetComponent<Box>();
        if (targetBox == null || targetBox.IsFull())
            return false; 

        float fillPerPress = targetBox.gameObject.GetComponent<Box>().GetFillPerPress(); 
        targetBox.Fill(fillPerPress);
        ingredient.Cut(fillPerPress * 50); 
        
  
        AudioSource.PlayClipAtPoint(cutAudio, transform.position);


        if (targetBox.IsFull())
        {
            targetBox.SetIngredient(ingredient.GetIngredientSO());
            // todo: feedback de llenado
        }

        if (ingredient.remainintCuantity <= 0f)
        {
            HoldSystem.Drop();
        }



        return true; 
    }

    private bool TrySeasonBox()
    {
        if (HoldSystem.HeldObject == null)
            return false;

        var seasoningItem = HoldSystem.HeldObject.GetComponent<SeasoningItem>();
        if (seasoningItem == null)
            return false; 

        var targetBox = InteractionDetector.Current?.GetGameObject().GetComponent<Box>();
        if (targetBox == null || !targetBox.IsFull())
            return false; 

        if (!targetBox.CanReceiveSeasoning(seasoningItem.GetSeasoning()))
        {
            return true;
        }

        targetBox.ApplySeasoning(seasoningItem.GetSeasoning());

        return true;
    }
}
