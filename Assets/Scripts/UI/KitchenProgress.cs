using UnityEngine;
using UnityEngine.UI;
using System.Collections;

public class KitchenProgress : MonoBehaviour
{
    public SimpleProgressBar progressBar;  // Arrastra desde la jerarquía (ClassicProgressBar)
    public float duration = 5f;

    private float timer;
    private bool isCooking = false;

    public void StartCooking(float time)
    {
        duration = time;
        timer = 0f;
        isCooking = true;
        progressBar.gameObject.SetActive(true);
    }

    void Update()
    {
        if (!isCooking || progressBar == null) return;

        timer += Time.deltaTime;
        float value = Mathf.Clamp01(timer / duration);
        progressBar.SetProgress(value);

        if (value >= 1f)
        {
            isCooking = false;
            progressBar.gameObject.SetActive(false); // Ocultar al acabar
        }
    }
}