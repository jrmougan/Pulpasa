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
        var holder = other.GetComponent<PlayerHoldSystem>();
        if (holder != null && holder.HasItem)
        {
            var heldObject = holder.HeldObject;
            var box = heldObject?.GetComponent<Box>();

            if (box != null)
            {
                TryValidate(box, holder);
            }
        }
    }


    private void TryValidate(Box box, PlayerHoldSystem holder)
    {
        if (currentOrder == null)
        {
            Debug.Log("❌ No hay pedido activo.");
            return;
        }

        if (box == null)
        {
            Debug.Log("❌ No hay caja en la mano.");
            return;
        }

        Debug.Log($"Validando pedido #{currentOrder.orderId} con caja {box} en el stand {deliverySlotId}.");
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
