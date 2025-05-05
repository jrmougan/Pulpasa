using UnityEngine;

public class HighlightController : MonoBehaviour
{
    private OutlineHighlighter outline;

    private InteractableHighlight reticule;

    private void Awake()
    {
        outline = GetComponent<OutlineHighlighter>();
        reticule = GetComponent<InteractableHighlight>();
    }

    public void Show()
    {
        outline?.Show();
        reticule?.Show();
    }

    public void Hide()
    {
        outline?.Hide();
        reticule?.Hide();
    }
}