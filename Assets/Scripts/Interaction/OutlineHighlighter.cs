using UnityEngine;
using System.Collections.Generic;

public class OutlineHighlighter : MonoBehaviour
{
    [SerializeField] private Material outlineMaterial;
    [SerializeField] private float scaleFactor = 1.05f;

    private readonly List<GameObject> outlines = new();

    void Awake()
    {
        CreateOutlines();
        Hide();
    }

    private void CreateOutlines()
    {
        foreach (var originalRenderer in GetComponentsInChildren<MeshRenderer>())
        {
            var originalFilter = originalRenderer.GetComponent<MeshFilter>();
            if (originalFilter == null) continue;

            // Crear objeto hijo
            var outlineObj = new GameObject($"{originalRenderer.gameObject.name}_Outline");
            outlineObj.transform.SetParent(originalRenderer.transform, false);
            outlineObj.transform.localScale = Vector3.one * scaleFactor;

            // Asignar mesh
            var outlineFilter = outlineObj.AddComponent<MeshFilter>();
            outlineFilter.sharedMesh = originalFilter.sharedMesh;

            var outlineRenderer = outlineObj.AddComponent<MeshRenderer>();
            outlineRenderer.material = outlineMaterial;
            outlineRenderer.shadowCastingMode = UnityEngine.Rendering.ShadowCastingMode.Off;
            outlineRenderer.receiveShadows = false;
            outlineRenderer.lightProbeUsage = UnityEngine.Rendering.LightProbeUsage.Off;
            outlineRenderer.reflectionProbeUsage = UnityEngine.Rendering.ReflectionProbeUsage.Off;

            outlines.Add(outlineObj);
        }
    }

    public void Show()
    {
        foreach (var obj in outlines)
            obj.SetActive(true);
    }

    public void Hide()
    {
        foreach (var obj in outlines)
            obj.SetActive(false);
    }
}
