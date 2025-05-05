using UnityEngine;

public static class SnappingHelper
{
    public static void AlignByAnchorPoint(GameObject obj, Transform anchorTarget, string anchorName = "AnchorPoint")
    {
        if (obj == null || anchorTarget == null) return;

        Transform anchorPoint = obj.transform.Find(anchorName);
        if (anchorPoint == null) return;

        Vector3 localPosOffset = anchorPoint.localPosition;
        Quaternion localRotOffset = anchorPoint.localRotation;
        
        obj.transform.SetParent(anchorTarget, false);

        obj.transform.localPosition = -localPosOffset;
        obj.transform.localRotation = Quaternion.Inverse(localRotOffset);

        var rb = obj.GetComponent<Rigidbody>();
        if (rb != null)
        {
            rb.isKinematic = true;
            rb.linearVelocity = Vector3.zero;
            rb.angularVelocity = Vector3.zero;
        }

        obj.layer = LayerMask.NameToLayer("Interactable");

    }
}
