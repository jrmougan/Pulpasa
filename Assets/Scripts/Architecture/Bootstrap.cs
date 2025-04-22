using UnityEngine;
using QFramework;

public class Bootstrap : MonoBehaviour
{
    // Registrar Sistemas y utilidades en la arquitectura
    void Awake()
    {
        Application.targetFrameRate = 60; // ✅ Establece 60 FPS
        QualitySettings.vSyncCount = 1;   // ✅ Activa V-Sync (opcional, 0 si querés ignorarlo)

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
