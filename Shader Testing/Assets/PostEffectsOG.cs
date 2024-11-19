using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class PostEffectsControllerRaymarching : MonoBehaviour
{
    private const int PASSED_ARRAY_LENGTH = 50;

    [SerializeField]
    Material postEffectMaterial;

    [SerializeField]
    public LayerMask BoidMaskLayer;

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

    private RenderTexture mainRT;
    private RenderTexture maskRT;


    void OnRenderImage(RenderTexture src, RenderTexture dest){
        if(metaballs.Count <= 0){
            return;
        }

        //Camera.main.cullingMask = objectLayer;

        RenderTexture rt = RenderTexture.GetTemporary(src.width, src.height, 0, src.format);

        /*

        //cameraspace to worldspace matrix
        Matrix4x4 inverseViewMatrix = Camera.main.cameraToWorldMatrix;
        Matrix4x4 inverseProjMatrix = GL.GetGPUProjectionMatrix(Camera.main.projectionMatrix, false).inverse;

        //pass in matricies
        postEffectMaterial.SetMatrix("_InverseViewMatrix", inverseViewMatrix);
        postEffectMaterial.SetMatrix("_InverseProjMatrix", inverseProjMatrix);

        //must be vector4 because that's what SetVectorArrayTakes
        Vector4[] positions = new Vector4[PASSED_ARRAY_LENGTH];
        float[] radii = new float[PASSED_ARRAY_LENGTH];


        //pass in meta ball parameters
        if(metaballs.Count >= PASSED_ARRAY_LENGTH){
            Debug.Log("THERE ARE MORE METABALLS THAN ARRAY LENGTH, SOME WILL BE PRUNED FROM RENDERING");
        }
        for(int i = 0; i < PASSED_ARRAY_LENGTH; i++){
            //in list
            if(i < metaballs.Count){
                positions[i] = new Vector4(metaballs[i].position.x,metaballs[i].position.y, metaballs[i].position.z);
                radii[i] = metaballs[i].radius;
            }else{//outside of list
                positions[i] = new Vector3(0,0,0);
                //this case will be ignored by shader
                radii[i] = -1;
            }
            
        }
        
        postEffectMaterial.SetVectorArray("_MetaballPositions", positions);
        postEffectMaterial.SetFloatArray("_MetaballRadii", radii);
        postEffectMaterial.SetInt("_MetaballCount", Mathf.Clamp(metaballs.Count,0,50));*/
        
        //get mask

        // Store the original culling mask
        /*
        Camera targetCamera = Camera.main;
        int originalCullingMask = targetCamera.cullingMask;

        // Set the camera's culling mask to the desired layer(s)
        targetCamera.cullingMask = BoidMaskLayer;

        // Set the target texture for the camera
        targetCamera.targetTexture = maskRT;

        // Render the camera
        targetCamera.Render();

        // Restore the original culling mask
        targetCamera.cullingMask = originalCullingMask;

        // Reset the target texture to null
        targetCamera.targetTexture = null;*/


        Graphics.Blit(src, rt, postEffectMaterial);
        Graphics.Blit(rt, dest);
        //Graphics.Blit(src, dest);

        RenderTexture.ReleaseTemporary(rt);

    }

}
