using UnityEngine;

public class HighlightController : MonoBehaviour
{
    private EmissionHighlighter emissionHighlighter;
    private InteractableHighlight visualHighlighter;

    void Awake()
    {
        emissionHighlighter = GetComponentInChildren<EmissionHighlighter>();
        visualHighlighter = GetComponentInChildren<InteractableHighlight>();
    }

    public void Show()
    {
        Debug.Log($"🔆 HighlightController.Show() llamado en {name}");

        emissionHighlighter?.Show();
        visualHighlighter?.Show();
    }

    public void Hide()
    {
        Debug.Log($"❌ HighlightController.Hide() llamado en {name}");
        emissionHighlighter?.Hide();
        visualHighlighter?.Hide();
    }
}
