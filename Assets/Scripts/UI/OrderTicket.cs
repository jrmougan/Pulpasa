using UnityEngine;
using TMPro;
using System.Collections.Generic;

public class OrderTicket : MonoBehaviour
{
    [Header("Referencias UI")]
    public TextMeshProUGUI orderIdText;
    public Transform boxListContainer;
    public GameObject boxEntryPrefab;

    private ActiveOrder currentOrder;

    public void Setup(ActiveOrder order)
    {
        currentOrder = order;
        Debug.Log($"Configurando ticket para la orden #{order.orderId}");
        orderIdText.text = $"#{order.orderId}"; // Asignar el ID de la orden al texto


        // Crear entradas visuales por cada caja del pedido
        foreach (var recipeBox in order.template.recipeBoxes)
        {
            GameObject boxEntryGO = Instantiate(boxEntryPrefab, boxListContainer);
            BoxEntryUI boxEntryUI = boxEntryGO.GetComponent<BoxEntryUI>();
            boxEntryUI.Setup(recipeBox); // Asignar la receta y cantidad a la entrada visual

        }

        // También podrías agregar bebidas o especias si están en la OrderSO
    }
}
