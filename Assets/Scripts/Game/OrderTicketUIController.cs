
using QFramework;
using UnityEngine;
using System.Collections.Generic;

public class OrderTicketUIController : MonoBehaviour, IController
{
    [System.Serializable]
    public class StationSlot
    {
        public int deliverySlotId;
        public GameObject deliveryStationGO;   // Puesto físico en la escena
    }

    public Transform ticketContainer; // único contenedor para todos los tickets
    public GameObject ticketPrefab;
    public List<StationSlot> stations = new();

    private Dictionary<int, GameObject> activeTickets = new();
    void Start()
    {

    }

    void Update()
    {
        // Generar pedidos hasta que no queden delivery slots disponibles
        foreach (var station in stations)
        {
            if (!station.deliveryStationGO.GetComponent<OrderStand>().IsOccupied)
            {
                PulpaSAArchitecture.Interface.SendCommand(new RequestOrderCommand(station.deliverySlotId));
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
        Debug.Log($"Orden generada: {e.order.orderId}");
        if (activeTickets.ContainsKey(e.order.orderId)) return;
        GameObject ticketGO = Instantiate(ticketPrefab, ticketContainer);
        ticketGO.GetComponent<OrderTicket>().Setup(e.order);
        activeTickets[e.order.orderId] = ticketGO;

        // Asignar el id del ticket al puesto de entrega correspondiente
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
        Debug.Log($"Orden completada: {e.order.orderId}");
        if (activeTickets.ContainsKey(e.order.orderId))
        {
            Destroy(activeTickets[e.order.orderId]);
            activeTickets.Remove(e.order.orderId);
        }

        // Limpiar el puesto de entrega correspondiente
        foreach (var station in stations)
        {
            if (station.deliverySlotId == e.order.deliverySlotId)
            {
                station.deliveryStationGO.GetComponent<OrderStand>().ClearOrder();
                break;
            }
        }
    }







    public IArchitecture GetArchitecture() => PulpaSAArchitecture.Interface;
}