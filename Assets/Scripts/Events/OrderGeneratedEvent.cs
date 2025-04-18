public struct OrderGeneratedEvent
{
    public ActiveOrder order;
    public OrderGeneratedEvent(ActiveOrder order)
    {
        this.order = order;
    }
}