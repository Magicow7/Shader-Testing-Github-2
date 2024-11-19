using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class PortalPlacer : MonoBehaviour
{

    public Movement playerMovement;
    public GameObject portal1;
    public GameObject portal2;
    // Start is called before the first frame update

    // Update is called once per frame
    void Update()
    {
        if(Input.GetKeyDown(KeyCode.Mouse0)){PlacePortal(portal1);}
        if(Input.GetKeyDown(KeyCode.Mouse1)){PlacePortal(portal2);}
    }

    void PlacePortal(GameObject portal){
        RaycastHit hit;
            //var ray = Camera.main.ScreenPointToRay(Input.mousePosition);

            if (Physics.Raycast(transform.position, Camera.main.transform.forward, out hit, Mathf.Infinity))
            {
                
                if (hit.collider != null)
                {
                    //hit.rigidbody.AddForceAtPosition(ray.direction * pokeForce, hit.point);
                    portal.transform.position = hit.point;
                    portal.transform.LookAt(portal.transform.position - hit.normal);
                    portal.transform.position -= portal.transform.forward*0.01f;

                    //set portal values in movement
                    if(portal == portal1){
                        playerMovement.Portal1On = hit.transform.gameObject;
                    }else if(portal == portal2){
                        playerMovement.Portal2On = hit.transform.gameObject;
                    } 
                    
                }
            }
    }
}
