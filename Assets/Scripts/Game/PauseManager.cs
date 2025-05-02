using UnityEngine;
using UnityEngine.SceneManagement;

public class PauseMenuManager : MonoBehaviour
{
    public GameObject pausePanel;
    private bool isPaused = false;

    private ProductivitySystem productivitySystem;
    private PlayerController playerController;

    void Start()
    {
        productivitySystem = FindObjectOfType<ProductivitySystem>();
        playerController = FindObjectOfType<PlayerController>();
        pausePanel.SetActive(false);
    }

    void Update()
    {
        if (Input.GetKeyDown(KeyCode.Escape))
        {
            if (isPaused)
                ResumeGame();
            else
                PauseGame();
        }
    }

    public void PauseGame()
    {
        isPaused = true;
        pausePanel.SetActive(true);
        Time.timeScale = 0f; // congela todo menos UI

        if (productivitySystem != null)
        {
            productivitySystem.isPaused = true;
        }

        if (playerController != null)
        {
            playerController.enabled = false;
        }
    }

    public void ResumeGame()
    {
        isPaused = false;
        pausePanel.SetActive(false);
        Time.timeScale = 1f;

        if (productivitySystem != null)
        {
            productivitySystem.isPaused = false;
        }

        if (playerController != null)
        {
            playerController.enabled = true;
        }
    }

    public void ExitToMainMenu()
    {
        Time.timeScale = 1f;
        SceneManager.LoadScene("MainMenu");
    }
}
