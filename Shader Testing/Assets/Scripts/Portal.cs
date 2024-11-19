using System.Collections;
using System.Collections.Generic;
using UnityEngine;

//used this video https://www.youtube.com/watch?v=cWpFZbjtSQg as a main resource
public class Portal : MonoBehaviour
{
    public int portalNum = 1;
    public int rotationMode = 1;
    public Portal otherPortal;
    public MeshRenderer meshRenderer;
    public Camera portalCam;
    RenderTexture viewTexture;

    public GameObject debug;

    private void Awake(){
        //portalCam = GetComponentInChildren<Camera>();
    }
    //this is called right before the player camera is rendered
    private void Update(){
        var cameraPos = Camera.main.transform.position;

        //TODO: why do we do this?
        meshRenderer.enabled = false;
        CreateViewTexture();


        //get a infinite plane along the portal
        Plane p = new Plane(transform.forward, transform.position);
        //get the closest point on that plane to the player
        Vector3 closestOnPlane = p.ClosestPointOnPlane(cameraPos);
        //Instantiate(debug, closestOnPlane,Quaternion.identity);
        //get the distance from that point to the player
        float distance = Vector3.Distance(cameraPos, closestOnPlane);
        
        Vector3 otherPos = GetOppositePortalRelativePosition(closestOnPlane);

        //reflect over plane
        otherPos = ReflectionOverPlane(otherPos, new Plane(otherPortal.transform.right, otherPortal.transform.position));


        //Instantiate(debug, otherPos,Quaternion.identity);
        
        
        //transform out from that point along the -forward vector by the distance
        otherPos -= -otherPortal.transform.forward * distance;
        
        otherPortal.portalCam.transform.position = otherPos;


        //now rotation
        if(rotationMode == 1){
            Ray ray = Camera.main.ViewportPointToRay(new Vector3(0.5f, 0.5f, 0));
            float hit;

            if (p.Raycast(ray, out hit))
            {
                //Get the point that is clicked
                Vector3 hitPoint = ray.GetPoint(hit);
                Vector3 oppositeLookPoint = GetOppositePortalRelativePosition(hitPoint);
                //oppositeLookPoint -= 2 * hitPoint;
                //reflect over plane
                oppositeLookPoint = ReflectionOverPlane(oppositeLookPoint, new Plane(otherPortal.transform.right, otherPortal.transform.position));

                otherPortal.portalCam.transform.LookAt(oppositeLookPoint, otherPortal.transform.up);

                
                //Move your cube GameObject to the point where you clicked
                //Instantiate(debug, oppositeLookPoint,Quaternion.identity);
            }
        }else if(rotationMode == 2){
            //TODO: ask stevens how this works
            Quaternion relativeRotation = transform.rotation * Camera.main.transform.rotation;
            otherPortal.portalCam.transform.rotation = otherPortal.transform.rotation * relativeRotation;
            //we rotate local euler 180 so the camera faces the correct direction
            otherPortal.portalCam.transform.localEulerAngles += new Vector3(0,180,0);
        }
        
        
        
        //otherPortal.portalCam.transform.LookAt(otherPortal.transform.position);
        


        portalCam.Render();

        meshRenderer.enabled = true;

    }

    private Vector3 GetOppositePortalRelativePosition(Vector3 input){
        //get the local coordinantes of the point in respect to the portal
        Vector3 relativePos = transform.InverseTransformPoint(input);
        //get those same local coords in respect to the other portal
        Vector3 otherPos = otherPortal.transform.TransformPoint(relativePos);

        return otherPos;
    }

    private void CreateViewTexture(){
        if(viewTexture == null || viewTexture.width != Screen.width || viewTexture.height != Screen.height){
            if(viewTexture != null){
                /*we use this release method instead of Destroy(), because release destroys 
                the GPU resources used by the render texture, but not the cpu wrapper that exposes the data to us, and we can ask the cpu to regenerate
                it if we need to. This seems like standard practice for render textures.
                */
                viewTexture.Release();
            }
            //the 0 is for depth
            viewTexture = new RenderTexture(Screen.width, Screen.height, 0);

            portalCam.targetTexture = viewTexture;

            otherPortal.meshRenderer.material.SetTexture("_MainTex", viewTexture);
        }
    }

    public Vector3 ReflectionOverPlane(Vector3 point, Plane plane) {
        var closestOnPlane = plane.ClosestPointOnPlane(point);
        var dist = point - closestOnPlane;
        return closestOnPlane - dist;
    }

    public void TransportObject(Transform toTransport, Rigidbody rb, MouseLook cameraController = null){

        var temp = GetOppositePortalRelativePosition(toTransport.position);
        //temp = ReflectionOverPlane(temp, new Plane(otherPortal.transform.forward, otherPortal.transform.position));
        //toTransport.rotation = Quaternion.LookRotation(otherPortal.transform.forward);
        cameraController.transform.rotation = otherPortal.portalCam.transform.rotation;
        toTransport.position = temp;
        Instantiate(debug, temp,Quaternion.identity);
    }
}
