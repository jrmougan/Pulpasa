using UnityEngine;

public class InteractableHighlight : MonoBehaviour
{
    [SerializeField] private GameObject highlightVisual;

    public void Show() => SetHighlight(true);
    public void Hide() => SetHighlight(false);
    private void Awake()
    {
        if (highlightVisual != null)
            highlightVisual.SetActive(false);
    }

    private void SetHighlight(bool value)
    {
        if (highlightVisual != null)
            highlightVisual.SetActive(value);
    }
}
