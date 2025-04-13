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


        /*         // Crear entradas visuales por cada caja del pedido
                foreach (var recipeBox in order.template.recipeBoxes)
                {
                    for (int i = 0; i < recipeBox.amount; i++)
                    {
                        GameObject entryGO = Instantiate(boxEntryPrefab, boxListContainer);
                        BoxEntryUI entry = entryGO.GetComponent<BoxEntryUI>();

                        if (entry != null)
                            entry.Setup(recipeBox.recipe, recipeBox.recipe.box);
                    }
                } */

        // También podrías agregar bebidas o especias si están en la OrderSO
    }
}
