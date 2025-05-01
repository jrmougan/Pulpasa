
using TMPro;
using UnityEngine;

public class ProductivityUIDisplay : MonoBehaviour
{
    public ProductivitySystem productivitySystem;
    public TextMeshProUGUI timeRemainingText;
    public TextMeshProUGUI ratioStatusText;

    private float remainingTime;

    void Start()
    {
        remainingTime = productivitySystem.timeLimit;
        productivitySystem.StartTracking();
    }

    void Update()
    {
        if (!productivitySystem.isRunning) return;

        remainingTime -= Time.deltaTime;
        remainingTime = Mathf.Max(0f, remainingTime);
        timeRemainingText.text = $"{remainingTime:F1}s";

        float currentRatio = productivitySystem.GetPerformanceRatio();
        float diff = currentRatio - productivitySystem.targetRate;


        ratioStatusText.text = $"{diff:F1} cajas/hora";
        if (diff > 0)
        {
            ratioStatusText.color = Color.green;
        }
        else if (diff < 0)
        {
            ratioStatusText.color = Color.red;
        }
        else
        {
            ratioStatusText.color = Color.white;
        }

        if (remainingTime <= 0f)
        {
            productivitySystem.StopTracking();
        }
    }
}
