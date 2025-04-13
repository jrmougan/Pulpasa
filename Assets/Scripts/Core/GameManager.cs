using UnityEngine;

public class GameManager : MonoBehaviour
{
    public OrderManager orderManager;
    // Start is called once before the first execution of Update after the MonoBehaviour is created
    void Start()
    {
        if (orderManager == null)
        {
            Debug.LogError("OrderManager no encontrado en el GameManager.");
            return;
        }
        // Iniciar la primera orden
        orderManager.SpawnRandomOrder();
    }

    // Update is called once per frame
    void Update()
    {

    }
}
