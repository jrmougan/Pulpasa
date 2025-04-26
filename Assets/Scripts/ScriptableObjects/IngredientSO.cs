using System.Collections.Generic;
using UnityEngine;

[CreateAssetMenu(fileName = "NewIngredient", menuName = "PulpaSA/Ingredient")]
public class IngredientSO : ScriptableObject
{
    public string ingredientName;
    public Sprite icon;
    public GameObject prefab;
    public float totalCapacity = 100f;

    public IngredientType type;
    public bool isCookable;
    public bool isCuttable;
    public float cookTime;

    [TextArea]
    public string description;
}


public enum IngredientType
{
    Octopus
}

public enum CookingState
{
    Raw,
    Cooked,
    Burnt
}