
using QFramework;
using UnityEngine;
using System.Collections.Generic;

public class OrderTicketUIController : MonoBehaviour, IController
{
    [System.Serializable]
    public class StationSlot
    {
        public int deliverySlotId;
        public GameObject deliveryStationGO;  
    }

    public Transform ticketContainer; 
    public GameObject ticketPrefab;
    public List<StationSlot> stations = new();

    private Dictionary<int, GameObject> activeTickets = new();
void Start()
{
    foreach (var station in stations)
    {
        if (!station.deliveryStationGO.GetComponent<OrderStand>().IsOccupied)
        {
            // ⚠️ Si ya hay una orden activa para ese slot, no generes otra
            bool alreadyAssigned = this.GetSystem<IOrderSystem>()
                .ActiveOrders.Exists(o => o.deliverySlotId == station.deliverySlotId);

            if (!alreadyAssigned)
            {
                PulpaSAArchitecture.Interface.SendCommand(
                    new RequestOrderCommand(station.deliverySlotId));
            }
        }
    }
}

    void OnEnable()
    {
        this.RegisterEvent<OrderGeneratedEvent>(OnOrderGenerated);
        this.RegisterEvent<OrderCompletedEvent>(OnClearTicket);
    }
    void OnDisable()
    {
        this.UnRegisterEvent<OrderGeneratedEvent>(OnOrderGenerated);
        this.UnRegisterEvent<OrderCompletedEvent>(OnClearTicket);

    }

    private void OnOrderGenerated(OrderGeneratedEvent e)
    {
        if (activeTickets.ContainsKey(e.order.orderId)) return;
        GameObject ticketGO = Instantiate(ticketPrefab, ticketContainer);
        ticketGO.GetComponent<OrderTicket>().Setup(e.order);
        activeTickets[e.order.orderId] = ticketGO;

        foreach (var station in stations)
        {
            if (station.deliverySlotId == e.order.deliverySlotId)
            {
                station.deliveryStationGO.GetComponent<OrderStand>().AssignOrder(e.order);
                break;
            }
        }

    }

private void OnClearTicket(OrderCompletedEvent e)
{
    if (activeTickets.ContainsKey(e.order.orderId))
    {
        Destroy(activeTickets[e.order.orderId]);
        activeTickets.Remove(e.order.orderId);
    }

    foreach (var station in stations)
    {
        if (station.deliverySlotId == e.order.deliverySlotId)
        {
            var stand = station.deliveryStationGO.GetComponent<OrderStand>();
            stand.ClearOrder();

            // 🚀 Solicita nueva orden tras limpiar
            PulpaSAArchitecture.Interface.SendCommand(new RequestOrderCommand(station.deliverySlotId));
            break;
        }
    }
}







    public IArchitecture GetArchitecture() => PulpaSAArchitecture.Interface;
}