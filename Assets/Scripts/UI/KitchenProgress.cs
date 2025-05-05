using UnityEngine;
using System;

public class KitchenProgress : MonoBehaviour
{
    public Action OnCookingFinished;
    public SimpleProgressBar progressBar; 
    public float duration = 5f;

    private float timer;
    private bool isCooking = false;

    [SerializeField] private AudioSource boilAudioSource; 

    public void StartCooking(float time)
    {
        duration = time;
        timer = 0f;
        isCooking = true;
        progressBar.gameObject.SetActive(true);
        boilAudioSource.Play(); 
    }

    void Update()
    {
        if (!isCooking || progressBar == null) return;

        timer += Time.deltaTime;
        float value = Mathf.Clamp01(timer / duration);
        progressBar.SetProgress(value);

        if (value >= 1f)
        {
            isCooking = false;
            progressBar.gameObject.SetActive(false); 
            boilAudioSource.Stop(); 
            OnCookingFinished?.Invoke();
        }
    }
}