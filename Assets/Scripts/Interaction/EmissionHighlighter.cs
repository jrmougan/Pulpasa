using UnityEngine;
using System.Collections.Generic;

public class EmissionHighlighter : MonoBehaviour
{
    [ColorUsage(true, true)]
    [SerializeField] private Color highlightEmission = Color.yellow * 5f;

    private List<Material> materialInstances = new();
    private List<Color> originalEmissions = new();

    void Awake()
    {
        var renderers = GetComponentsInChildren<Renderer>();

        foreach (var rend in renderers)
        {
            foreach (var mat in rend.materials) // instanciar materiales
            {
                if (mat.HasProperty("_EmissionColor"))
                {
                    materialInstances.Add(mat);
                    originalEmissions.Add(mat.GetColor("_EmissionColor"));
                }
            }
        }

        if (materialInstances.Count == 0)
            Debug.LogWarning($"⚠️ No se encontraron materiales con _EmissionColor en {name}");
    }

    public void Show()
    {
        foreach (var mat in materialInstances)
        {
            mat.EnableKeyword("_EMISSION");
            mat.SetColor("_EmissionColor", highlightEmission);
        }
    }

    public void Hide()
    {
        for (int i = 0; i < materialInstances.Count; i++)
        {
            materialInstances[i].SetColor("_EmissionColor", originalEmissions[i]);
        }
    }
}
