using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class Interactable : MonoBehaviour
{
    [SerializeField] private bool isActive = true;
    public bool IsActive => isActive;

    [SerializeField]
    private bool lookAt = true;
    public bool LookAt => lookAt;

    public virtual void Interact(PlayerController interactor)
    {
        Debug.Log("Interacted with " + gameObject.name);
    }
}
