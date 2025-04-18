using UnityEngine;
using TMPro;
using QFramework;

[RequireComponent(typeof(Collider))]
public class OrderStand : MonoBehaviour, IController
{
    public int deliverySlotId;
    public TextMeshPro textDisplay;
    public Transform deliveryPoint;

    public ActiveOrder currentOrder;
    public bool IsOccupied => currentOrder != null;

    private void OnTriggerEnter(Collider other)
    {
        var holder = other.GetComponent<PlayerBoxHolder>();
        if (holder != null && holder.HasBox)
        {
            TryValidate(holder);
        }
    }

    private void TryValidate(PlayerBoxHolder holder)
    {
        var system = this.GetArchitecture().GetSystem<IOrderSystem>();
        var box = holder.GetBox();

        if (system.ValidateBox(box, deliverySlotId, out int points))
        {
            Debug.Log($"✅ Orden completada en stand {deliverySlotId}, puntos: {points}");


            // 🗑️ Eliminar la caja
            Destroy(box.gameObject);

            // 🔄 Vaciar referencia en el jugador
            holder.DropBox();

            system.CompleteOrder(currentOrder);
            ClearOrder();
        }
        else
        {
            Debug.Log("❌ Caja no válida para este pedido.");
        }
    }

    public void AssignOrder(ActiveOrder order)
    {
        currentOrder = order;
        textDisplay.text = $"#{order.orderId}";
    }

    public void ClearOrder()
    {
        currentOrder = null;
        textDisplay.text = "–";
    }

    public IArchitecture GetArchitecture() => PulpaSAArchitecture.Interface;
}
