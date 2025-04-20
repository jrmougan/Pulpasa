using UnityEngine;

[CreateAssetMenu(fileName = "New Seasoning", menuName = "Ingredients/Seasoning")]
public class SeasoningData : ScriptableObject
{

    public SeasoningType type;
    public Color color;

    public Sprite icon;
    public GameObject prefab;
    public AudioClip useSound;
}

public enum SeasoningType
{
    Salt,
    Paprika,
    Hot_Paprika
}