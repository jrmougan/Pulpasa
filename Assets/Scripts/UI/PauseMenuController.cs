using UnityEngine;
using TMPro;
using UnityEngine.SceneManagement;

public class PauseMenuController : MonoBehaviour
{
    public TextMeshProUGUI[] opciones;
    public Color colorSeleccionado = Color.red;
    public Color colorNormal = Color.black;
    public AudioSource audioMover;
    public AudioSource audioSeleccionar;

    private int indiceSeleccionado = 0;
    private PauseMenuManager pauseManager;

    void Start()
    {
        pauseManager = FindObjectOfType<PauseMenuManager>();
        ActualizarSeleccion();
    }

    void Update()
    {
        if (Input.GetKeyDown(KeyCode.UpArrow))
        {
            indiceSeleccionado = (indiceSeleccionado - 1 + opciones.Length) % opciones.Length;
            ActualizarSeleccion();
            audioMover?.Play();
        }
        else if (Input.GetKeyDown(KeyCode.DownArrow))
        {
            indiceSeleccionado = (indiceSeleccionado + 1) % opciones.Length;
            ActualizarSeleccion();
            audioMover?.Play();
        }
        else if (Input.GetKeyDown(KeyCode.Return) || Input.GetMouseButtonDown(0))
        {
            SeleccionarOpcion();
            audioSeleccionar?.Play();
        }

        // Soporte para hover con el ratón
        for (int i = 0; i < opciones.Length; i++)
        {
            if (opciones[i].rectTransform.rect.Contains(Input.mousePosition - opciones[i].rectTransform.position))
            {
                indiceSeleccionado = i;
                ActualizarSeleccion();
            }
        }
    }

    void ActualizarSeleccion()
    {
        for (int i = 0; i < opciones.Length; i++)
        {
            opciones[i].color = (i == indiceSeleccionado) ? colorSeleccionado : colorNormal;
            opciones[i].fontStyle = (i == indiceSeleccionado) ? FontStyles.Bold : FontStyles.Normal;
            string textoBase = opciones[i].text.TrimStart('>', ' ');
            opciones[i].text = (i == indiceSeleccionado) ? $">{textoBase}" : textoBase;
        }
    }

    void SeleccionarOpcion()
    {
        switch (indiceSeleccionado)
        {
            case 0:
                pauseManager?.ResumeGame();
                break;
            case 1:
                pauseManager?.ExitToMainMenu();
                break;
        }
    }
}
