using UnityEngine;

public static class SnappingHelper
{
    public static void AlignByAnchorPoint(GameObject obj, Transform anchorTarget, string anchorName = "AnchorPoint")
    {
        if (obj == null || anchorTarget == null)
        {
            Debug.LogWarning("❌ SnappingHelper: Objeto o anchor nulo.");
            return;
        }

        Transform anchorPoint = obj.transform.Find(anchorName);
        if (anchorPoint == null)
        {
            Debug.LogWarning($"❌ No se encontró '{anchorName}' en {obj.name}");
            return;
        }

        Debug.Log($"📌 Parentando {obj.name} a {anchorTarget.name}");

        // Offset entre el objeto y su anchor interno
        Vector3 offset = obj.transform.position - anchorPoint.position;

        Vector3 originalScale = obj.transform.localScale;

        // ✅ Aseguramos el parenting correcto
        obj.transform.SetParent(anchorTarget, true);
        obj.transform.localScale = originalScale;
        obj.transform.rotation = anchorTarget.rotation * Quaternion.Inverse(anchorPoint.localRotation);


        // Posición corregida
        obj.transform.position = anchorTarget.position + offset;

        Debug.Log($"📍 Posición después: {obj.transform.position}");

        // Física
        var rb = obj.GetComponent<Rigidbody>();
        if (rb != null)
        {
            rb.isKinematic = true;
            rb.linearVelocity = Vector3.zero;
            rb.angularVelocity = Vector3.zero;
        }
    }
}