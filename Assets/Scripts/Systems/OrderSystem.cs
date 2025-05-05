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
    void ResetOrders();
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
        this.SendEvent(new OrderCompletedEvent(order , order.template.recipe.basePoints));
        Debug.Log($"Orden completada: {order.orderId}");
    }

    public bool ValidateBox(Box box, int deliverySlotId, out int points)
    {
        Debug.Log($"🧪 Iniciando validación de caja en el slot #{deliverySlotId}...");

        foreach (var order in ActiveOrders)
        {
            if (order.deliverySlotId != deliverySlotId)
            {
                Debug.Log($"🔸 Ignorando orden #{order.orderId}, no es del slot {deliverySlotId}.");
                continue;
            }

            var recipe = order.template.recipe;

            Debug.Log($"🔍 Comparando con orden #{order.orderId} → Receta: {recipe.recipeName}");

            // 1. Validar tipo de caja
            var boxSO = box.GetBoxSO();
            if (boxSO != recipe.box)
            {
                Debug.Log($"❌ Tipo de caja no coincide. Esperado: {recipe.box.name}, Actual: {boxSO?.name ?? "null"}");
                continue;
            }
            // 2. Validar ingrediente
            var ingrediente = box.GetIngredient();
            if (ingrediente == null)
            {
                Debug.Log("❌ La caja no tiene ningún ingrediente asignado.");
                continue;
            }
            if (ingrediente != recipe.ingredients)
            {
                string esperado = recipe.ingredients != null ? recipe.ingredients.ingredientName : "null";
                string actual = ingrediente != null ? ingrediente.ingredientName : "null";
                Debug.Log($"❌ Ingrediente no coincide. Esperado: {esperado}, Actual: {actual}"); continue;
            }

            // 3. Validar especias
            bool allSpicesPresent = true;
            foreach (var spice in order.template.spices)
            {
                if (!box.appliedSeasonings.Contains(spice))
                {
                    Debug.Log($"❌ Falta especia: {spice.type}");
                    allSpicesPresent = false;
                    break;
                }
            }

            if (!allSpicesPresent)
            {
                Debug.Log("❌ No se aplicaron todas las especias requeridas.");
                continue;
            }

            // ÉXITO
            Debug.Log($"✅ Validación exitosa para orden #{order.orderId}.");
            points = recipe.basePoints;
            CompleteOrder(order);
            return true;
        }

        Debug.Log("❌ Ninguna orden coincidió con la caja entregada.");
        points = 0;
        return false;
    }
    public void ResetOrders()
{
    foreach (var stand in Object.FindObjectsByType<OrderStand>(FindObjectsSortMode.None))
{
    stand.ClearOrder();
}
    ActiveOrders.Clear();
    nextOrderId = 1;
}


}