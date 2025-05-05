using UnityEngine;
using QFramework;

public class ProductivitySystem : MonoBehaviour, IController
{
    [Header("Tracking")]
    public float elapsedTime = 0f;
    public int boxesDelivered = 0;

    [Header("Configuración")]
    public float timeLimit = 180f; // duración total del turno en segundos
    public bool isRunning = false;
    public bool isPaused = false;
    public bool isFinished = false;

    void OnEnable()
    {
        this.RegisterEvent<OrderCompletedEvent>(OnOrderCompleted);
    }

    void OnDisable()
    {
        this.UnRegisterEvent<OrderCompletedEvent>(OnOrderCompleted);
    }

    public void StartTracking()
    {
        elapsedTime = 0f;
        boxesDelivered = 0;
        isRunning = true;
        isFinished = false;

        this.GetSystem<IOrderSystem>().ResetOrders();
        }

    public void StopTracking()
    {
        isRunning = false;
    }

    void Update()
    {
        if (!isRunning || isPaused || isFinished) return;

        elapsedTime += Time.deltaTime;

        if (!isFinished && Mathf.RoundToInt(elapsedTime) >= Mathf.RoundToInt(timeLimit))
        {
            isRunning = false;
            isFinished = true;
            Debug.Log($"Turno terminado. Cajas entregadas: {boxesDelivered}, Ratio: {GetProductivityRatio():F2} cajas/minuto");
        }
    }

    private void OnOrderCompleted(OrderCompletedEvent e)
    {
        boxesDelivered++;
    }

    public float GetProductivityRatio()
    {
        if (elapsedTime <= 0f) return 0f;

        float minutes = elapsedTime / 60f;
        return boxesDelivered / minutes;
    }

    public string GetPerformanceDescription()
    {
        float ratio = GetProductivityRatio();

        if (ratio < 1f) return "Pulpero en prácticas";
        else if (ratio < 2f) return "Pulpero aceptable";
        else if (ratio < 3f) return "Pulpero eficiente";
        else return "¡Pulpero legendario!";
    }

    public IArchitecture GetArchitecture() => PulpaSAArchitecture.Interface;
}
