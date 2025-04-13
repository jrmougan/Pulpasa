using UnityEngine;
using System.Collections.Generic;

public class OrderManager : MonoBehaviour
{
    public List<OrderSO> orderTemplates;
    public List<ActiveOrder> activeOrders = new();

    public GameObject ticketPrefab; // Prefab del ticket visual
    public Transform ticketContainer; // Panel con HorizontalLayoutGroup

    public void SpawnRandomOrder()
    {
        if (orderTemplates.Count == 0)
        {
            Debug.LogError("No hay plantillas de órdenes disponibles.");
            return;
        }
        OrderSO randomTemplate = orderTemplates[Random.Range(0, orderTemplates.Count)];
        ActiveOrder newOrder = new ActiveOrder(randomTemplate);
        activeOrders.Add(newOrder);

        // Crear ticket visual
        GameObject ticketGO = Instantiate(ticketPrefab, ticketContainer);
        ticketGO.transform.SetParent(ticketContainer, false); // ← importante
        OrderTicket ticketUI = ticketGO.GetComponent<OrderTicket>();
        ticketUI.Setup(newOrder); // ← método que vas a definir en el prefab */
    }

    public void UpdateOrders(float deltaTime)
    {
        foreach (var order in activeOrders)
        {
            order.timeRemaining -= deltaTime;
            // Validar expiración, avisar, etc.
        }
    }
}

