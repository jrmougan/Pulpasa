// OrderSO.cs
using UnityEngine;
using System.Collections.Generic;

[CreateAssetMenu(fileName = "NewOrder", menuName = "PulpaSA/Order")]
public class OrderSO : ScriptableObject
{
    public string orderName;
    public List<RecipeBoxPair> recipeBoxes;
    public List<DrinkPair> drinks;
    public float maxTime;

    [TextArea]
    public string description;

    [System.Serializable]
    public class RecipeBoxPair
    {
        public RecipeSO recipe;

        public int amount;
    }

    [System.Serializable]
    public class DrinkPair
    {
        public DrinkSO drink;
        public int amount;
    }
}
