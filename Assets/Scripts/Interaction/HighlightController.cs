using UnityEngine;

public class HighlightController : MonoBehaviour
{
    private OutlineHighlighter outline;

    private InteractableHighlight reticule;

    private void Awake()
    {
        outline = GetComponent<OutlineHighlighter>();
        reticule = GetComponent<InteractableHighlight>();

        if (outline == null && reticule == null)
        {
            Debug.LogWarning($"⚠️ No se encontró un componente de resaltado en {name}");
        }
    }

    public void Show()
    {
        outline?.Show();
        reticule?.Show();
        Debug.Log($"🌟 HighlightController.Show() en {name}");
    }

    public void Hide()
    {
        outline?.Hide();
        reticule?.Hide();
        Debug.Log($"❌ HighlightController.Hide() en {name}");
    }
}