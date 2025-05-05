using UnityEngine;
using QFramework;

public class OrderTicketSpawner : MonoBehaviour, IController
{
    [Header("Referencias")]
    public Transform ticketContainer; // Donde se colocarán los tickets
    public GameObject ticketPrefab;   // Prefab con el script OrderTicket

    void Start()
    {
        // Volver a pintar las órdenes ya activas si reinicias la escena
        var activeOrders = this.GetSystem<IOrderSystem>().ActiveOrders;
        foreach (var order in activeOrders)
        {
            CreateTicket(order);
        }
    }

    void OnEnable()
    {
        this.RegisterEvent<OrderGeneratedEvent>(OnOrderGenerated);
    }

    void OnDisable()
    {
        this.UnRegisterEvent<OrderGeneratedEvent>(OnOrderGenerated);
    }

    void OnOrderGenerated(OrderGeneratedEvent e)
    {
        Debug.Log($"🧾 Ticket generado para orden #{e.order.orderId}");
        CreateTicket(e.order);
    }

    void CreateTicket(ActiveOrder order)
    {
        GameObject ticketGO = Instantiate(ticketPrefab, ticketContainer);
        OrderTicket ticket = ticketGO.GetComponent<OrderTicket>();
        ticket.Setup(order);
    }

    public IArchitecture GetArchitecture() => PulpaSAArchitecture.Interface;
}
