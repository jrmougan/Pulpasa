using UnityEngine;
using UnityEngine.InputSystem;

public class PlayerController : MonoBehaviour
{
    public float moveSpeed = 5f;
    private Vector2 moveInput;
    private CharacterController controller;
    private PlayerInteraction interaction;
    private Animator animator;

    void Awake()
    {
        controller = GetComponent<CharacterController>();
        interaction = GetComponent<PlayerInteraction>();
        animator = GetComponent<Animator>();
    }

    void Update()
    {
        Vector3 move = new Vector3(moveInput.x, 0, moveInput.y);
        float speed = move.magnitude;

        if (move.magnitude > 0.01f)
        {
            Quaternion targetRotation = Quaternion.LookRotation(move, Vector3.up);
            transform.rotation = Quaternion.Slerp(transform.rotation, targetRotation, 10f * Time.deltaTime);
        }

        controller.Move(move * moveSpeed * Time.deltaTime);

        animator.SetFloat("Speed", speed); // Actualizamos el parámetro del Animator
    }

    public void OnMove(InputValue value)
    {
        moveInput = value.Get<Vector2>();
    }

    // Aquí pondremos interacción más adelante
    public void OnInteract(InputValue value)
    {
        if (value.isPressed && interaction != null)
        {
            interaction.TryInteract(); // Llamamos al método público de PlayerInteraction
        }
    }
}