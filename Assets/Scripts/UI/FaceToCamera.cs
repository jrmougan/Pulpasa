using UnityEngine;

public class FaceToCamera : MonoBehaviour
{
    private Camera mainCam;

    void Start()
    {
        mainCam = Camera.main;
    }

    void LateUpdate()
    {
        if (mainCam != null)
        {
            transform.forward = mainCam.transform.forward;
        }
    }
}
