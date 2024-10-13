using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class simpletest : MonoBehaviour
{
    public Vector3 moveAxis = Vector3.zero;
    public Vector3 rotAxis = Vector3.zero;
    public Vector3 scaleAxis = Vector3.zero;
    public bool hideshow = false;

    // Start is called before the first frame update
    void Start()
    {
        
    }

    // Update is called once per frame
    void Update()
    {
        transform.localScale += scaleAxis * Input.GetAxis("simpleScale") * Time.deltaTime;
        transform.eulerAngles += rotAxis * Input.GetAxis("simpleRotate") * Time.deltaTime;
        transform.localPosition += moveAxis * Input.GetAxis("simpleMove") * Time.deltaTime;
        if (hideshow && Input.GetKeyDown(KeyCode.P))
            GetComponent<MeshRenderer>().enabled = !GetComponent<MeshRenderer>().enabled;
    }
}
