using System.Data.Common;
using UnityEngine;

public class ActiveOrder
{
    public OrderSO template;

    public int orderId; // ID de la orden, si lo necesitas
    public float timeRemaining;

    public ActiveOrder(OrderSO template)
    {
        // Asignar un ID único, de 3 cifras
        orderId = Random.Range(100, 999); // o usar un ID si lo tenés

        this.template = template;
        this.timeRemaining = template.maxTime;
    }

    public bool IsExpired => timeRemaining <= 0f;
}
