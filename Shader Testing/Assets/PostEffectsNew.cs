using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class PostEffectsControllerMask : MonoBehaviour
{
    //OLD AND DOESN'T WORK AS INTENDED
    private const int PASSED_ARRAY_LENGTH = 50;

    [SerializeField]
    Material postEffectMaterial;

    [SerializeField]
    public LayerMask BoidMaskLayer;

    private Camera _camera;

    [Serializable]
    public struct MetaballParameters{
        public Vector3 position;
        public float radius;
        public MetaballParameters(Vector3 position, float radius){
            this.position = position;
            this.radius = radius;
        }
    }
    [SerializeField]
    private List<MetaballParameters> metaballs;

    void Start(){
        _camera = Camera.main;
        _camera.depthTextureMode = DepthTextureMode.Depth;
    }

    Vector2 ScreenToUV(Vector3 screenPos)
    {
        float u = screenPos.x / Screen.width;          // Normalize x
        float v = screenPos.y / Screen.height;         // Normalize y
        return new Vector2(u, v);
    }

    [ImageEffectOpaque]
    void OnRenderImage(RenderTexture src, RenderTexture dest){
        //set to read depth texture
        if(metaballs.Count <= 0){
            return;
        }

        //_camera.cullingMask = objectLayer;

        RenderTexture rt = RenderTexture.GetTemporary(src.width, src.height, 0, src.format);
        

        //cameraspace to worldspace matrix
        //Matrix4x4 inverseViewMatrix = _camera.cameraToWorldMatrix;
        //Matrix4x4 inverseProjMatrix = GL.GetGPUProjectionMatrix(_camera.projectionMatrix, false).inverse;
        /*Matrix4x4 viewProjMatrix = _camera.worldToCameraMatrix;
        Matrix4x4 screenToWorldMatrix = (_camera.projectionMatrix * _camera.worldToCameraMatrix).inverse;*/
        Matrix4x4 inverseProjectionMatrix = _camera.projectionMatrix.inverse;
        Matrix4x4 inverseViewMatrix = _camera.cameraToWorldMatrix;

        
        //pass in matricies
        //postEffectMaterial.SetMatrix("_InverseViewMatrix", inverseViewMatrix);
        //postEffectMaterial.SetMatrix("_InverseProjMatrix", inverseProjMatrix);
        //clip to screen space
        postEffectMaterial.SetMatrix("_InvProjMatrix", inverseProjectionMatrix);
        postEffectMaterial.SetMatrix("_InvViewMatrix", inverseViewMatrix);

        

        //must be vector4 because that's what SetVectorArrayTakes
        Vector4[] positions = new Vector4[PASSED_ARRAY_LENGTH];
        Vector4[] screenPositions = new Vector4[PASSED_ARRAY_LENGTH];
        //Vector4[] radii = new Vector4[PASSED_ARRAY_LENGTH];


        //pass in meta ball parameters
        if(metaballs.Count >= PASSED_ARRAY_LENGTH){
            Debug.Log("THERE ARE MORE METABALLS THAN ARRAY LENGTH, SOME WILL BE PRUNED FROM RENDERING");
        }
        for(int i = 0; i < PASSED_ARRAY_LENGTH; i++){
            //in list
            if(i < metaballs.Count){
                //Vector3 screenPoint = _camera.WorldToScreenPoint(metaballs[i].position);
                //z value is for depth comparison
                //Vector3 uvPoint = new Vector3(screenPoint.x/Screen.width, screenPoint.y/Screen.height, screenPoint.z / _camera.farClipPlane);
                //positions[i] = new Vector4(uvPoint.x,uvPoint.y,uvPoint.z);
                positions[i] = new Vector4(metaballs[i].position.x,metaballs[i].position.y,metaballs[i].position.z);
                Vector3 edgePos = metaballs[i].position + metaballs[i].radius * _camera.transform.right;
                Vector2 centerScreenPoint = ScreenToUV(_camera.WorldToScreenPoint(metaballs[i].position));
                Vector2 edgeScreenPoint = ScreenToUV(_camera.WorldToScreenPoint(edgePos));
                //Debug.Log("Center uv point is" + centerScreenPoint + "edge uvPoint is" + edgeScreenPoint);
                //Debug.Log(positions[i]);
                screenPositions[i] = new Vector4(centerScreenPoint.x, centerScreenPoint.y, edgeScreenPoint.x, edgeScreenPoint.y);
                //Vector3 sideDir = _camera.transform.right;
                //radii[i] = new Vector4(sideDir.x, sideDir.y, sideDir.z, metaballs[i].radius);
            }else{//outside of list
                positions[i] = new Vector3(0,0,0);
                screenPositions[i] = new Vector4(0,0,0,0);
                //this case will be ignored by shader
                //radii[i] = new Vector4(0,0,0,-1);
            }
            
        }
        //encoded in xyz
        postEffectMaterial.SetVectorArray("_BoidPositions", positions);
        //xy is screenpos of center, zw is screenpos of edge
        postEffectMaterial.SetVectorArray("_BoidScreenPositions", screenPositions);
        //postEffectMaterial.SetVectorArray("_BoidRadii", radii);
        postEffectMaterial.SetInt("_BoidCount", Mathf.Clamp(metaballs.Count,0,50));
        //postEffectMaterial.SetFloat("_Radius", 4);
        
        //get mask
        /*
        Camera targetCamera = _camera;
        // Store the original culling mask
        int originalCullingMask = targetCamera.cullingMask;

        // Set the camera's culling mask to the desired layer(s)
        targetCamera.cullingMask = BoidMaskLayer;

        // Set the target texture for the camera
        targetCamera.targetTexture = rt;

        // Render the camera
        targetCamera.Render();

        // Restore the original culling mask
        targetCamera.cullingMask = originalCullingMask;

        // Reset the target texture to null
        targetCamera.targetTexture = null;*/
        RaycastCornerBlit(src, rt, postEffectMaterial);
        Graphics.Blit(rt, dest);
        /*Graphics.Blit(src,rt, postEffectMaterial);
        Graphics.Blit(rt, dest);*/

        /*Texture2D depthImage = new Texture2D(rt.width, rt.height, TextureFormat.RGB24, false);
        depthImage.ReadPixels(new Rect(0, 0, rt.width, rt.height), 0, 0);
        depthImage.Apply();
        Color pixelColor = depthImage.GetPixel(rt.width/2, rt.height/2);*/
        //Debug.Log("center pixel is " + pixelColor.r);
        /*
        Vector4 temp = inverseProjectionMatrix * new Vector4(0,0,(pixelColor.r * 2) - 1,1);
        Debug.Log("temp is" +temp);
        //perspective divide
        temp /= temp.w;
        Debug.Log("next is" + inverseViewMatrix * temp);*/
        //Graphics.Blit(rt, dest);
        //Graphics.Blit(rt, dest);

        RenderTexture.ReleaseTemporary(rt);
    }

    Texture2D toTexture2D(RenderTexture rTex)
    {
        Texture2D tex = new Texture2D(512, 512, TextureFormat.RGB24, false);
        // ReadPixels looks at the active RenderTexture.
        RenderTexture.active = rTex;
        tex.ReadPixels(new Rect(0, 0, rTex.width, rTex.height), 0, 0);
        tex.Apply();
        return tex;
    }

    //source https://github.com/Broxxar/NoMansScanner/blob/master/Assets/Scanner%20Effect/ScannerEffectDemo.cs
    void RaycastCornerBlit(RenderTexture source, RenderTexture dest, Material mat)
	{
		// Compute Frustum Corners
		float camFar = _camera.farClipPlane;
		float camFov = _camera.fieldOfView;
		float camAspect = _camera.aspect;

		float fovWHalf = camFov * 0.5f;

		Vector3 toRight = _camera.transform.right * Mathf.Tan(fovWHalf * Mathf.Deg2Rad) * camAspect;
		Vector3 toTop = _camera.transform.up * Mathf.Tan(fovWHalf * Mathf.Deg2Rad);

		Vector3 topLeft = (_camera.transform.forward - toRight + toTop);
		float camScale = topLeft.magnitude * camFar;

		topLeft.Normalize();
		topLeft *= camScale;

		Vector3 topRight = (_camera.transform.forward + toRight + toTop);
		topRight.Normalize();
		topRight *= camScale;

		Vector3 bottomRight = (_camera.transform.forward + toRight - toTop);
		bottomRight.Normalize();
		bottomRight *= camScale;

		Vector3 bottomLeft = (_camera.transform.forward - toRight - toTop);
		bottomLeft.Normalize();
		bottomLeft *= camScale;

		// Custom Blit, encoding Frustum Corners as additional Texture Coordinates
		RenderTexture.active = dest;

		mat.SetTexture("_MainTex", source);

		GL.PushMatrix();
		GL.LoadOrtho();

		mat.SetPass(0);

		GL.Begin(GL.QUADS);

		GL.MultiTexCoord2(0, 0.0f, 0.0f);
		GL.MultiTexCoord(1, bottomLeft);
		GL.Vertex3(0.0f, 0.0f, 0.0f);

		GL.MultiTexCoord2(0, 1.0f, 0.0f);
		GL.MultiTexCoord(1, bottomRight);
		GL.Vertex3(1.0f, 0.0f, 0.0f);

		GL.MultiTexCoord2(0, 1.0f, 1.0f);
		GL.MultiTexCoord(1, topRight);
		GL.Vertex3(1.0f, 1.0f, 0.0f);

		GL.MultiTexCoord2(0, 0.0f, 1.0f);
		GL.MultiTexCoord(1, topLeft);
		GL.Vertex3(0.0f, 1.0f, 0.0f);

		GL.End();
		GL.PopMatrix();
	}
}
