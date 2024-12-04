using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class LagBehindPos : MonoBehaviour
{
    public  GameObject followObject;
    float timeMult = 1;

    // Update is called once per frame
    void Update()
    {
        transform.position = Vector3.Lerp(transform.position, followObject.transform.position, Time.deltaTime * timeMult);
    }
}
