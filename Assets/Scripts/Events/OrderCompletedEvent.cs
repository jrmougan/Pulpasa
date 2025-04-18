public struct OrderCompletedEvent
{
    public ActiveOrder order;

    public OrderCompletedEvent(ActiveOrder order)
    {
        this.order = order;
    }
}
