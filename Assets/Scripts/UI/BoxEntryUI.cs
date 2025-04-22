using UnityEngine;
using TMPro;

public class BoxEntryUI : MonoBehaviour
{
    public TextMeshProUGUI titleText;
    public TextMeshProUGUI amountText;

    [Header("Detalle de especias")]
    public Transform detailListContainer; // Asigna DetailList
    public TextMeshProUGUI detailTextPrefab; // Asigna el Text (TMP) dentro

    public void Setup(OrderSO box)
    {
        titleText.text = $"{box.recipe.recipeName}";
        amountText.text = ""; // Puedes rellenar si necesitas mostrar cantidad

        // Limpiar anteriores (opcional)
        foreach (Transform child in detailListContainer)
        {
            if (child != detailTextPrefab.transform) Destroy(child.gameObject);
        }

        if (box.spices.Count == 0) return;

        foreach (var detail in box.spices)
        {
            var spiceText = Instantiate(detailTextPrefab, detailListContainer);
            spiceText.text = $"{detail.type}";
            spiceText.gameObject.SetActive(true);
        }

        detailTextPrefab.gameObject.SetActive(false); // Oculta el original
    }
}
