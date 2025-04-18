public class ActiveOrder
{
    public int orderId;
    public OrderSO template;
    public int deliverySlotId;

    public ActiveOrder(OrderSO template, int id, int deliverySlotId)
    {
        this.template = template;
        this.orderId = id;
        this.deliverySlotId = deliverySlotId;
    }
}
