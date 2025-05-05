using UnityEngine;
using QFramework;

public class ProductivitySystem : MonoBehaviour, IController
{
    public float elapsedTime;
    public int boxesDelivered = 0;

    public float targetRate = 300f; 
    public float timeLimit = 180f;
    public bool isRunning = false;

    public bool isPaused = false;
    public bool isFinished = false;

    public void StartTracking()
    {
        elapsedTime = 0f;
        boxesDelivered = 0;
        isRunning = true;
    }

    void OnEnable()
    {
        this.RegisterEvent<OrderCompletedEvent>(OnOrderCompleted);

    }

    void OnDisable()
    {
        this.UnRegisterEvent<OrderCompletedEvent>(OnOrderCompleted);
    }
    private void OnOrderCompleted(OrderCompletedEvent e)
    {
        boxesDelivered++;
    }

    public void StopTracking()
    {
        isRunning = false;
    }

    void Update()
    {
        if (!isRunning || isPaused || isFinished) return;

        if (isRunning)
        {
            elapsedTime += Time.deltaTime;
        }
        if (elapsedTime >= timeLimit)
        {
            isRunning = false;
            isFinished = true;
            // todo: feedback de fin de juego
        }
    }

    public void BoxDelivered()
    {
        boxesDelivered++;
    }

    public float GetPerformanceRatio()
    {
        if (elapsedTime <= 0f) return 0f;
        float hours = elapsedTime / 3600f;
        return boxesDelivered / hours; 
    }

    public bool GoalReached()
    {
        return GetPerformanceRatio() >= targetRate;
    }

    public IArchitecture GetArchitecture() => PulpaSAArchitecture.Interface;
}
