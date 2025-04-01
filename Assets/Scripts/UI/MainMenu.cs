using UnityEngine;
using UnityEngine.SceneManagement;
using TMPro;
using UnityEngine.UI;

public class MainMenu : MonoBehaviour
{
    public TextMeshProUGUI[] opciones;
    public Color colorSeleccionado = Color.red;
    public Color colorNormal = Color.black;
    public AudioSource audioMover;
    public AudioSource audioSeleccionar;

    private int indiceSeleccionado = 0;

    void Start()
    {
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
        else if (Input.GetKeyDown(KeyCode.Return))
        {
            SeleccionarOpcion();
            audioSeleccionar?.Play();
        }
    }

    void ActualizarSeleccion()
    {
        for (int i = 0; i < opciones.Length; i++)
        {
            opciones[i].color = (i == indiceSeleccionado) ? colorSeleccionado : colorNormal;
            opciones[i].text = (i == indiceSeleccionado) ? $"> {opciones[i].text.TrimStart('>', ' ') }" : opciones[i].text.TrimStart('>', ' ');
        }
    }

    void SeleccionarOpcion()
    {
        switch (indiceSeleccionado)
        {
            case 0:
                SceneManager.LoadScene("EscenaIndividual");
                break;
            case 1:
                SceneManager.LoadScene("EscenaMultijugador");
                break;
            case 2:
                SceneManager.LoadScene("EscenaOpciones");
                break;
            case 3:
                Application.Quit();
#if UNITY_EDITOR
                UnityEditor.EditorApplication.isPlaying = false;
#endif
                break;
        }
    }
}
