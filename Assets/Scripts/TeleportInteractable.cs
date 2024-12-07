using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class TeleportInteractable : Interactable
{
    public Transform teleport;
    public override void Interact(PlayerController interactor)
    {
        base.Interact(interactor);
        interactor.transform.position = teleport.position;
        //interactor.GetComponent<CharacterController>().Move(teleport.position - interactor.transform.position);
    }
}
