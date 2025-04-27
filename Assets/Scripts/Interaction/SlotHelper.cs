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

        // 🔵 Calculamos desplazamiento relativo
        Vector3 localPosOffset = anchorPoint.localPosition;
        Quaternion localRotOffset = anchorPoint.localRotation;
        Debug.Log($"🌟 Snapping {obj.name} to {anchorTarget.name}");

        // 🔥 Parentar SIN mantener world position
        obj.transform.SetParent(anchorTarget, false);

        // 🔥 Aplicar los offsets para que quede igual que el AnchorPoint
        obj.transform.localPosition = -localPosOffset;
        obj.transform.localRotation = Quaternion.Inverse(localRotOffset);

        // 🔵 Física y layer
        var rb = obj.GetComponent<Rigidbody>();
        if (rb != null)
        {
            rb.isKinematic = true;
            rb.linearVelocity = Vector3.zero;
            rb.angularVelocity = Vector3.zero;
        }

        obj.layer = LayerMask.NameToLayer("Interactable");

        Debug.Log($"📍 Final local position: {obj.transform.localPosition}");
    }
}
