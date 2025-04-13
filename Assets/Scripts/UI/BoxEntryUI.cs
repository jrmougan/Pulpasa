using UnityEngine;
using TMPro;

public class BoxEntryUI : MonoBehaviour
{
    public TextMeshProUGUI titleText;
    public TextMeshProUGUI amountText;

    // DetailList objet detay list contains multiple TextMeshProUGUI components
    public TextMeshProUGUI[] detailList; // Array of TextMeshProUGUI components for details

    public void Setup(OrderSO.RecipeBoxPair box)
    {
        titleText.text = $"{box.recipe.recipeName}";
        amountText.text = $"x {box.amount}"; // Assuming recipe has an amount property

    }
}