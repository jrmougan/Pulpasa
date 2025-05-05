using UnityEngine;
using System.Collections.Generic;

public class EmissionHighlighter : MonoBehaviour
{
    [ColorUsage(true, true)]
    [SerializeField] private Color highlightEmission = Color.yellow * 5f;

    private List<Material> materialInstances = new();
    private List<Color> originalEmissions = new();
    private List<Renderer> renderers = new();

    void Awake()
    {
        var renderers = GetComponentsInChildren<Renderer>();

        foreach (var rend in renderers)
        {
            var materials = rend.materials; // instancia
            for (int i = 0; i < materials.Length; i++)
            {
                Material mat = materials[i];
                if (rend.gameObject.CompareTag("IgnoreEmission")) continue;

                if (mat.shader.name != "Universal Render Pipeline/Lit")
                {
                    mat.shader = Shader.Find("Universal Render Pipeline/Lit");
                }

                if (mat.HasProperty("_EmissionColor"))
                {
                    materialInstances.Add(mat);
                    originalEmissions.Add(mat.GetColor("_EmissionColor"));
                }
            }
        }

    }


    public void Show()
    {
        for (int i = 0; i < materialInstances.Count; i++)
        {
            var mat = materialInstances[i];
            mat.EnableKeyword("_EMISSION");
            mat.SetColor("_EmissionColor", highlightEmission);
            mat.globalIlluminationFlags = MaterialGlobalIlluminationFlags.RealtimeEmissive;

            if (i < renderers.Count)
            {
                DynamicGI.SetEmissive(renderers[i], highlightEmission);
            }
        }
    }

    public void Hide()
    {
        for (int i = 0; i < materialInstances.Count; i++)
        {
            materialInstances[i].SetColor("_EmissionColor", originalEmissions[i]);

            if (i < renderers.Count)
            {
                DynamicGI.SetEmissive(renderers[i], originalEmissions[i]);
            }
        }
    }
}
