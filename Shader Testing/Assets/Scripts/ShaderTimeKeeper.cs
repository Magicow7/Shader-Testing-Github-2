using System.Collections;
using System.Collections.Generic;
using UnityEngine;

//this script is just here to update the time values for the shaders from the cpu instead of doing it all on the gpu.
public class ShaderTimeKeeper : MonoBehaviour
{
    public List<Renderer> renderers = new List<Renderer>(); 

    // Update is called once per frame
    void FixedUpdate()
    {
        foreach(Renderer r in renderers){
            float temp = r.material.GetFloat("_CurrTime");
            if(temp > 2*Mathf.PI){
                temp -=  2*Mathf.PI;
            }
            r.material.SetFloat("_CurrTime", temp + Time.fixedDeltaTime);
        }
    }
}
