// RequestOrderCommand.cs - Archivo generado como plantilla base
using QFramework;

public class RequestOrderCommand : AbstractCommand
{
    private int deliverySlotId;

    public RequestOrderCommand(int deliverySlotId)
    {
        this.deliverySlotId = deliverySlotId;
    }

    protected override void OnExecute()
    {
        var orderSystem = this.GetSystem<IOrderSystem>();
        orderSystem.GenerateOrder(deliverySlotId);

    }
}
