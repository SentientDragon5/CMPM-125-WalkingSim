using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Events;

public class Interactable : MonoBehaviour
{
    [SerializeField] private bool isActive = true;
    public bool IsActive => isActive;

    [SerializeField]
    private bool lookAt = true;
    public bool LookAt => lookAt;

    [SerializeField]
    private string tooltip = "Press E to interact";
    public string Tooltip => tooltip;

    [SerializeField]
    private UnityEvent onInteract;

    public virtual void Interact(PlayerController interactor)
    {
        Debug.Log("Interacted with " + gameObject.name);
        onInteract.Invoke();
    }
}
