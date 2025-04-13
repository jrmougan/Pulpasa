using UnityEngine;
using System.Collections.Generic;
using UnityEngine.UIElements;

[CreateAssetMenu(fileName = "NewRecipe", menuName = "PulpaSA/Recipe")]
public class RecipeSO : ScriptableObject
{
    public string recipeName;
    public Sprite icon;
    public List<IngredientSO> ingredients;
    public BoxSO box;
    public bool requiresCooking;
    public float preparationTime;
    public int basePoints;

    [TextArea]
    public string description;
}
