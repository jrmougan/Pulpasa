
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

        float currentRatio = productivitySystem.GetProductivityRatio();
        


        ratioStatusText.text = $"Ratio: {currentRatio:F2}";
        ratioStatusText.color = currentRatio > 1f ? Color.green : Color.red;

        if (remainingTime <= 0f)
        {
            productivitySystem.StopTracking();
        }
    }
}
