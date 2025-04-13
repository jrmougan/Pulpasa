using UnityEngine;

[CreateAssetMenu(fileName = "NewSpice", menuName = "PulpaSA/Spice")]
public class SpiceSO : ScriptableObject
{
    public string spiceName;
    public Sprite icon;
    public Color visualColor;
    public GameObject applyEffectPrefab;

    public int pointsBonus; // puntos extra por usar esta especia
    public float spiceTime; // tiempo para aplicarla, si es relevante

    [TextArea]
    public string description;
}