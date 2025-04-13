using UnityEngine;

[CreateAssetMenu(fileName = "NewDrink", menuName = "PulpaSA/Drink")]
public class DrinkSO : ScriptableObject
{
    public string drinkName;
    public Sprite icon;
    public GameObject prefab;

    [TextArea]
    public string description;
}
