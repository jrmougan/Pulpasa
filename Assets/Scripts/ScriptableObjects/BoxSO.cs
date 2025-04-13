using UnityEngine;

[CreateAssetMenu(fileName = "NewBox", menuName = "PulpaSA/Box")]
public class BoxSO : ScriptableObject
{
    public string boxName;
    public Sprite icon;
    public GameObject prefab;

    public float requiredCapacity = 100f;

    [TextArea]
    public string description;
}