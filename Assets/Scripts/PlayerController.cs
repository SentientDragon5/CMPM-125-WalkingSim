using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using System.Linq;
using UnityEngine.SceneManagement;
using TMPro;

public class PlayerController : MonoBehaviour
{
    public Animator Animator;
    public CharacterController characterController;
    public static bool hasKey = false;

    protected virtual void Awake()
    {
        Debug.Assert(TryGetComponent(out Animator));
        Debug.Assert(TryGetComponent(out characterController));
    }

    #region aliases

    public bool IsAnim(string name) => Animator.GetCurrentAnimatorStateInfo(0).IsName(name);
    public bool IsAnim(string name, int layer) => Animator.GetCurrentAnimatorStateInfo(layer).IsName(name);
    #endregion

    [SerializeField] private float moveSpeed = 10;
    [SerializeField] private float turnSpeed = 360;
    [SerializeField, Min(0)] private float ySnapSpeed = 1;
    [Header("Sit")]
    public bool sitting = true;
    public float sitTime = 5;
    float lastMoveTime = -1;
    [Header("Raycasting")]
    public LayerMask enviromentLayer = 1;

    [Header("Interactor")]
    [SerializeField] private float interactionRadius = 1.5f;
    //public Vector3 offset = Vector3.zero;
    [SerializeField] private Vector3 offset = Vector3.up;

    [SerializeField] private bool lookAtTarget = true;
    public bool CanLookAtTarget { get => lookAtTarget; set => lookAtTarget = value; }
    float lookWeight = 0;
    Vector3 target;
    [SerializeField] private float lookSmoothRate = 5f;
    float maxDot = 0.2f;
    [SerializeField] private AnimationCurve lookCurve = AnimationCurve.EaseInOut(0, 0, 1, 1);
    public LayerMask interactableLayers = 8 << 1;

    public TextMeshProUGUI interactablePreview;

    [Header("Current Nearby Interactables")]
    [SerializeField] private List<Interactable> interactionQueue = new List<Interactable>();

    float upOffset = 0.5f;

    #region instance variables
    Vector3 GroundNormal;
    Vector3 moveInput;
    float TurnAmount;
    float ForwardAmount;
    float RightAmount;
    Vector3 velocity;
    #endregion


    #region properies
    public Vector3 CharacterVelocity { get => characterController.velocity; }
    public bool Sprinting { get { return Input.GetKey(KeyCode.LeftShift) && ForwardAmount > 0.1f; } }
    #endregion

    bool GroundCast(float downDist, out RaycastHit hit) => Physics.SphereCast(transform.position + Vector3.up * upOffset, characterController.radius, Vector3.down, out hit, downDist, enviromentLayer);
    bool GroundCast(float downDist) => GroundCast(downDist, out RaycastHit hit);


    void Start()
    {
        Load();
    }
    void Save()
    {
    }
    void Load()
    {
    }

    /// <summary>
    /// Call this to update the interaction Queue.
    /// </summary>
    public void CheckForInteractables()
    {
        if (gameObject == null) return;
        Collider[] colliders = Physics.OverlapSphere(transform.position + offset, interactionRadius, interactableLayers, QueryTriggerInteraction.Collide);
        interactionQueue.Clear();
        foreach (Collider collider in colliders)
        {
            if (collider.TryGetComponent(out Interactable interactable) && interactable.IsActive)
            {
                if (interactable.transform != transform)
                {
                    interactionQueue.Add(interactable);
                }
                //interactable.show = true;
            }
        }
        interactionQueue = interactionQueue.OrderBy(i => Vector3.Distance(this.transform.position, i.transform.position)).ToList();//using Linq

        if (interactionQueue.Count > 0)
            interactablePreview.text = interactionQueue[0].Tooltip;
        else
            interactablePreview.text = "";
    }
    /// <summary>
    /// Call this to interact with the nearest object.
    /// </summary>
    public void Interact()
    {
        if (gameObject == null) return;
        CheckForInteractables();

        if (interactionQueue.Count > 0)
        {
            AdjustThenInteract();
        }
    }

    void AdjustThenInteract()
    {
        Vector3 dir = (interactionQueue[0].transform.position - transform.position);
        Quaternion newRot = Quaternion.LookRotation(new Vector3(dir.x, 0, dir.z));//Or else the player will be laying down or something random.
        transform.rotation = newRot;
        interactionQueue[0].Interact(this);

    }

    private void OnDrawGizmosSelected()
    {
        Gizmos.color = Color.yellow;
        Gizmos.DrawWireSphere(offset + transform.position, interactionRadius);
    }

    private void OnAnimatorIK(int layerIndex)
    {
        CheckForInteractables();
        bool anyToLookAt = false;
        for (int i = interactionQueue.Count - 1; i >= 0; i--)
        {
            if (interactionQueue[i].LookAt)
            {
                target = interactionQueue[i].transform.position;
                anyToLookAt = true;
            }
        }

        if (lookAtTarget && (anyToLookAt))
        {
            Vector3 head = Animator.GetBoneTransform(HumanBodyBones.Head).position;
            Vector3 directionOfInteractor = transform.forward;
            Vector3 directionFromTargetToInteractor = transform.position - target;
            bool facingTarget = Vector3.Dot(directionOfInteractor.normalized, directionFromTargetToInteractor.normalized) < maxDot;
            Debug.DrawRay(head, target - head, facingTarget ? Color.green : Color.magenta);
            if (facingTarget)
            {
                Animator.SetLookAtPosition(target);
                if (lookWeight < 1)
                    lookWeight += lookSmoothRate * Time.deltaTime;

            }
            else
            {
                if (lookWeight > 0)
                    lookWeight -= lookSmoothRate * Time.deltaTime;
            }
        }
        else
        {
            if (lookWeight > 0)
                lookWeight -= lookSmoothRate * Time.deltaTime;
        }

        Animator.SetLookAtWeight(lookCurve.Evaluate(lookWeight), lookCurve.Evaluate(lookWeight) * 0.1f, 1, 0, 0.8f);
        lookWeight = Mathf.Clamp01(lookWeight);
    }

    private void Update()
    {
        Vector2 m = new(Input.GetAxis("Horizontal"), Input.GetAxis("Vertical"));
        m.x = Mathf.Clamp(m.x, -1, 1);
        m.y = Mathf.Clamp(m.y, -1, 1);

        if (!inAir)
        {

            Move(m);

            if (Input.GetKeyDown(KeyCode.E))
            {
                Interact();
            }
        }

    }

    public void Move(Vector2 input)
    {
        Transform camTransform = Camera.main.transform;

        Vector3 camForward = new Vector3(camTransform.forward.x, 0, camTransform.forward.z).normalized;
        Vector3 move = input.y * camForward + input.x * camTransform.right;

        if (move.magnitude > 1f) move.Normalize();
        moveInput = move;
        move = transform.InverseTransformDirection(move);

        move = Vector3.ProjectOnPlane(move, GroundNormal);
        TurnAmount = Mathf.Atan2(move.x, move.z);
        ForwardAmount = move.z;
        RightAmount = move.x;

        velocity.y = -1 * ySnapSpeed;

        UpdateAnimatior(move, Input.GetKey(KeyCode.LeftShift));
        transform.Rotate(0, TurnAmount * turnSpeed * Time.deltaTime, 0);
    }
    public float sprintMultiplier = 1.5f;
    public void OnAnimatorMove()
    {
        if (inAir) return;

        Vector3 move = Animator.deltaPosition * moveSpeed;

        if (GroundCast(1f, out RaycastHit hit))
        {
            move = Vector3.ProjectOnPlane(move, hit.normal);
            transform.position = hit.point;
        }
        else
        {
            velocity.y += Physics.gravity.y * Time.deltaTime;
        }
        //move *= moveSpeed;
        move = (velocity + moveInput * moveSpeed) * (Sprinting ? sprintMultiplier : 1);

        characterController.transform.rotation *= Animator.deltaRotation;
        move += velocity.y * Vector3.up;
        characterController.Move(move * Time.deltaTime);

    }

    public void FootR() { }
    public void FootL() { }
    public void Land() { }

    void UpdateAnimatior(Vector3 move, bool run)
    {
        float animForward = run && ForwardAmount > 0.1f ? 2 : ForwardAmount;
        Animator.SetFloat("Forward", animForward, 0.1f, Time.deltaTime);
        //Animator.SetFloat("Right", RightAmount, 0.1f, Time.deltaTime);
        Animator.SetFloat("Turn", TurnAmount, 0.1f, Time.deltaTime);
        Animator.SetBool("OnGround", true);

        if (Mathf.Abs(animForward) > 0.1f)
        {
            lastMoveTime = Time.time;
        }

        if (Time.time - lastMoveTime > sitTime)
            sitting = true;
        if (animForward > 0.1f)
            sitting = false;

        Animator.SetBool("Sitting", sitting);

        //if (Grounded && move.magnitude > 0.1f && !(IsAnim("Grounded") || IsAnim("Crouching") || IsAnim("Strafing"))) Animator.CrossFade("Grounded", 0f, 0);
    }

    private bool inAir;
}

