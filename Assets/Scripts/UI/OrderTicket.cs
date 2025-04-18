using UnityEngine;
using TMPro;

public class OrderTicket : MonoBehaviour
{
    [Header("Referencias UI")]
    public TextMeshProUGUI orderIdText;
    public Transform boxListContainer;
    public GameObject boxEntryPrefab;

    private ActiveOrder currentOrder;

    public void Setup(ActiveOrder order)
    {
        Debug.Log($"Configurando ticket para la orden #{order.orderId}");
        orderIdText.text = $"#{order.orderId}";

        foreach (var recipeBox in order.template.recipeBoxes)
        {
            GameObject boxEntryGO = Instantiate(boxEntryPrefab, boxListContainer);
            BoxEntryUI boxEntryUI = boxEntryGO.GetComponent<BoxEntryUI>();
            boxEntryUI.Setup(recipeBox);
        }
    }
}
