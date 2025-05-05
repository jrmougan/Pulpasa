public struct OrderCompletedEvent
{
    public ActiveOrder order;
    public float qualityScore;

    public OrderCompletedEvent(ActiveOrder order, float qualityScore)
    {
        this.order = order;
        this.qualityScore = qualityScore;
    }
}