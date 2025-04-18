using UnityEngine;
using QFramework;

public class Bootstrap : MonoBehaviour
{
    // Registrar Sistemas y utilidades en la arquitectura
    void Awake()
    {
        PulpaSAArchitecture.Interface.RegisterUtility<IRandomUtility>(new UnityRandomUtility());
    }
}

public class UnityRandomUtility : IRandomUtility
{
    public int Range(int min, int max)
    {
        return Random.Range(min, max);
    }
}

public interface IRandomUtility : IUtility
{
    int Range(int min, int max);
}
