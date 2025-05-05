using UnityEngine;
using UnityEngine.InputSystem;

public class PlayerController : MonoBehaviour
{
    public float moveSpeed = 5f;
    private Vector2 moveInput;
    private CharacterController controller;
    private Animator animator;
    private PlayerHoldSystem holdSystem;

    public ProductivitySystem productivitySystem;

    void Awake()
    {
        controller = GetComponent<CharacterController>();
        animator = GetComponentInChildren<Animator>();
        holdSystem = GetComponent<PlayerHoldSystem>();
    }


    void Update()
    {
        if (productivitySystem == null || !productivitySystem.isRunning || productivitySystem.isFinished)
            return;
        Vector3 move = new Vector3(moveInput.x, 0, moveInput.y);
        float speed = move.magnitude;

        if (move.magnitude > 0.01f)
        {
            Quaternion targetRotation = Quaternion.LookRotation(move, Vector3.up);
            transform.rotation = Quaternion.Slerp(transform.rotation, targetRotation, 20f * Time.deltaTime);
        }

        controller.Move(move * moveSpeed * Time.deltaTime);

        animator.SetFloat("Speed", speed); 
        animator.SetBool("IsHolding", holdSystem.HasItem);
    }

    public void OnMove(InputValue value)
    {
        moveInput = value.Get<Vector2>();
    }

    public void OnInteract(InputValue value)
    {

        if (!value.isPressed) return;

        var interactionCtrl = GetComponent<PlayerInteractionController>();
        if (interactionCtrl != null)
        {
            interactionCtrl.HandleInteraction();
        }
    }



}