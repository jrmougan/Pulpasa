using UnityEngine;
using UnityEngine.UI;
using TMPro;
using QFramework;

public class GameOverUI : MonoBehaviour, IController
{
    [Header("Referencias UI")]
    public GameObject gameOverPanel;
    public TextMeshProUGUI resultText;
    public TextMeshProUGUI ratioText;
    public Button restartButton;
    public Button exitButton;

    private ProductivitySystem productivity;

    void Start()
    {
        productivity = FindObjectOfType<ProductivitySystem>();
        gameOverPanel.SetActive(false);

        restartButton.onClick.AddListener(RestartGame);
        exitButton.onClick.AddListener(ExitGameToMenu);

    }

    void Update()
    {
        if (productivity.isFinished && !gameOverPanel.activeSelf)
        {
            ShowGameOver();
        }
    }

    void ShowGameOver()
    {
        Debug.Log("Turno terminado. Cajas entregadas: " + productivity.boxesDelivered);
        float ratio = productivity.GetProductivityRatio();
        string desc = productivity.GetPerformanceDescription();

        gameOverPanel.SetActive(true);
        ratioText.text = $"Rendimiento: {ratio:F2} cajas/minuto";
        resultText.text = desc;
    }

    void RestartGame()
    {
        var index = UnityEngine.SceneManagement.SceneManager.GetActiveScene().buildIndex;
        UnityEngine.SceneManagement.SceneManager.LoadScene(index);
    }
    

    void ExitGameToMenu()
    {

        UnityEngine.SceneManagement.SceneManager.LoadScene("MainMenu");

       
    }

    public IArchitecture GetArchitecture() => PulpaSAArchitecture.Interface;
}
