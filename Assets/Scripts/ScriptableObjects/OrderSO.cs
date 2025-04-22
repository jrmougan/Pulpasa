// OrderSO.cs
using System.Collections.Generic;
using UnityEngine;


[CreateAssetMenu(fileName = "NewOrder", menuName = "PulpaSA/Order")]
public class OrderSO : ScriptableObject
{
    public string orderName;

    public RecipeSO recipe;

    public List<SpicesSO> spices = new List<SpicesSO>();


    public float maxTime;

    [TextArea]
    public string description;


}
