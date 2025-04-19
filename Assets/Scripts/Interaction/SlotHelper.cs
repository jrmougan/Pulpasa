using UnityEngine;

public static class SlotHelper
{
    public static void SnapObjectToAnchor(GameObject obj, Transform anchor)
    {
        if (obj == null || anchor == null) return;

        // 1. Guardar escala original
        Vector3 originalScale = obj.transform.localScale;

        // 2. Parentar sin heredar escala
        obj.transform.SetParent(anchor, true);
        obj.transform.localScale = originalScale;
        obj.transform.rotation = anchor.rotation;

        // 3. Ajustar altura visual (base sobre el anchor)
        Renderer rend = obj.GetComponentInChildren<Renderer>();
        if (rend != null)
        {
            float baseToPivot = rend.bounds.extents.y;
            obj.transform.position = anchor.position + new Vector3(0, baseToPivot, 0);
        }
        else
        {
            obj.transform.position = anchor.position;
        }

        // 4. Física
        var rb = obj.GetComponent<Rigidbody>();
        if (rb)
        {
            rb.isKinematic = true;
            rb.linearVelocity = Vector3.zero;
            rb.angularVelocity = Vector3.zero;
        }
    }
}
