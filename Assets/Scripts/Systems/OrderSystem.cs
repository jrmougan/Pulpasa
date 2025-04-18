using QFramework;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UIElements;

public interface IOrderSystem : ISystem
{
    List<ActiveOrder> ActiveOrders { get; }
    void GenerateOrder(int deliverySlotId);
    void CompleteOrder(ActiveOrder order);
    bool ValidateBox(Box box, int deliverySlotId, out int points);
}
public class OrderSystem : AbstractSystem, IOrderSystem
{
    private List<OrderSO> posiblesOrdenes;
    public List<ActiveOrder> ActiveOrders { get; private set; } = new();
    private int nextOrderId = 1;

    protected override void OnInit()
    {
        posiblesOrdenes = new List<OrderSO>(Resources.LoadAll<OrderSO>("Orders"));
    }

    public void GenerateOrder(int deliverySlotId)
    {
        Debug.Log($"Generando orden para el puesto {deliverySlotId}");
        if (posiblesOrdenes.Count == 0 || ActiveOrders.Count >= 4) return;

        OrderSO template = posiblesOrdenes[Random.Range(0, posiblesOrdenes.Count)];
        Debug.Log($"Orden generada: {template.name}");
        ActiveOrder order = new ActiveOrder(template, nextOrderId++, deliverySlotId);
        ActiveOrders.Add(order);
        this.SendEvent(new OrderGeneratedEvent(order));
    }

    public void CompleteOrder(ActiveOrder order)
    {
        Debug.Log($"Completando orden: {order.orderId}");
        ActiveOrders.Remove(order);
        this.SendEvent(new OrderCompletedEvent(order));
        Debug.Log($"Orden completada: {order.orderId}");
    }

    public bool ValidateBox(Box box, int deliverySlotId, out int points)
    {
        foreach (var order in ActiveOrders)
        {
            if (order.deliverySlotId != deliverySlotId) continue;

            foreach (var recipe in order.template.recipeBoxes)
            {

            }
        }
        points = 0;
        return true;
    }
}