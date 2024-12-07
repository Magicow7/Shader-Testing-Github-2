using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;
public class DepthPostEffects : MonoBehaviour
{
    public struct BoidData{
        public GameObject boidGameObject;
        public Color color;
    }

    [SerializeField]
    public List<Color> BoidColorList = new List<Color>();

    [SerializeField]
    Material maskGetMaterial;

    [SerializeField]
    Material postEffectMaterial;

    [SerializeField]
    RenderCameraDepth boidDepth;

    [SerializeField]
    RenderCameraDepth sceneDepth;

    [SerializeField]
    ComputeShader centerFinder;

    [SerializeField]
    int minCircleSize = 3;

    /*
    [SerializeField]
    public LayerMask BoidMaskLayer;*/


    private Camera _camera;


    private bool awaitTexture = false;
    
    void Start(){
        _camera = Camera.main;
        //set depth texture read to on
        _camera.depthTextureMode = DepthTextureMode.Depth;
        //boidViewer.depthTextureMode = DepthTextureMode.Depth;
        //set boidviewer destinatin texture
        /*
        if (boidViewer.targetTexture != null){
            boidViewer.targetTexture.Release();
        }
        awaitTexture = true;*/
    }
    void OnRenderImage(RenderTexture src, RenderTexture dest){
        //Graphics.Blit(src, dest, postEffectMaterial);
        //return;
        if(BoidColorList.Count == 0){
            Debug.Log("no boids");
            Graphics.Blit(src, dest);
            return;
        }

        RenderTextureDescriptor descriptor = new RenderTextureDescriptor(src.width, src.height, src.format);
        descriptor.enableRandomWrite = true;
        RenderTexture maskRT = RenderTexture.GetTemporary(descriptor);
        RenderTexture computeRT = RenderTexture.GetTemporary(descriptor);
        
        
        
        //get mask

        //postEffectMaterial.SetTexture("_MainTex", src);
        maskGetMaterial.SetTexture("_SceneDepthTex", sceneDepth.depthTexture);
        maskGetMaterial.SetTexture("_BoidDepthTex", boidDepth.depthTexture);
        maskGetMaterial.SetTexture("_BoidColorTex", boidDepth.colorTexture);

        //Graphics.Blit(src, defaultDepthRt, postEffectMaterial, 0);
        //Graphics.Blit(boidsrcRt, boidDepthRt, postEffectMaterial, 0);
        //Graphics.Blit(boidView, boidDepthRt, postEffectMaterial, 0);
        Graphics.Blit(src, maskRT, maskGetMaterial, 0);
        /*
        THIS VISUALIZES MASK
        */
        /*Graphics.Blit(maskRT, dest);
        return;*/
        //in order the parameters are: 0 is the index of the kernel we are calling, "result" the value we are getting sent back, 
        //maskRT is the texture we are putting the final value on
        //RANDOM WRITE IS NEEEDED TO LET THE COMPUTE SHADER WRITE BACK TO OUR RENDER TEXTURE
        //circleFinder.SetTexture(0,"Result", maskRT);
        //circleFinder.Dispatch(0, src.width/8 src.height/8, 1);

        //idea
        //get list of colors of boids, pass it to a compute shader
        //get the compute shader to return a list of structs containing a centerpoint in screenspace and number of pixels in the rt that contain that color

        //estimation
        //each pixel will return a color and a closest distance to a different color in each cardinal direction (8 dirs)
        //make the pixel that is furthest from the edge the center.
        int pixelCount = maskRT.width * maskRT.height;
        //color buffer to hold each possible color
        ComputeBuffer outputBuffer = new ComputeBuffer(BoidColorList.Count, sizeof(uint));
        //each return val will have the screen coords x and y and distance from edge val
        ComputeBuffer colorBuffer = new ComputeBuffer(BoidColorList.Count, sizeof(float)*4);
        colorBuffer.SetData(BoidColorList.ToArray());

        centerFinder.SetBuffer(0, "colorBuffer", colorBuffer);
        centerFinder.SetInt("colorCount", BoidColorList.Count);
        centerFinder.SetTexture(0, "inTex", maskRT);
        //centerFinder.SetTexture(0, "Result", computeRT);
        centerFinder.SetBuffer(0, "outputData", outputBuffer);

        int threadGroupsX = Mathf.CeilToInt(maskRT.width / 8.0f);
        int threadGroupsY = Mathf.CeilToInt(maskRT.height / 8.0f);
        
        //should be 64 threads per dispatch in 8x8
        centerFinder.Dispatch(0, threadGroupsX, threadGroupsY, 1);
        
        
        Vector4[] positions = new Vector4[BoidColorList.Count];
        float[] radii = new float[BoidColorList.Count];

        //get out data from compute buffer
        /*
        long[] outputData = new long[BoidColorList.Count];
        outputBuffer.GetData(outputData);
        for(int n = 0; n < BoidColorList.Count; n++){
            long number = outputData[n];
            //Debug.Log("encoded num is" + number);
            long max = (number >> (32-10)) & 0x3FF;
            //get in worlds
            float yPos = (float)((number >> (32-21)) & 0x3FF);///maskRT.height;
            float xPos = (float)((number >> (32-32)) & 0x3FF);///maskRT.width;
            //to avoid weird feet artifact
            if(max <= minCircleSize){
                max = 0;
                yPos = 0;
                xPos = 0;
            }
            positions[n] = new Vector4(xPos, yPos,0,1);
            radii[n] = max;
            //yPos -= 0.5f;
            //xPos -= 0.5f;
            //Debug.Log(n + ":" + max + "is max, " +xPos+" is x, " + yPos + " is y");
        }
        */
        
        //Debug.Log(maskRT.width + "and" + maskRT.height);

        //render final screen
        postEffectMaterial.SetVectorArray("_CirclePositions", positions);
        postEffectMaterial.SetFloatArray("_CircleRadii", radii);
        postEffectMaterial.SetFloat("_CircleCount", BoidColorList.Count);

        //remove this if compute -> frag isn't working
        postEffectMaterial.SetBuffer("ResultBuffer", outputBuffer);

       

        Graphics.Blit(src, dest, postEffectMaterial);
        //Graphics.Blit(maskRT, dest);
        


        // Release the buffer after use
        outputBuffer.Release();
        colorBuffer.Release();

        //RenderTexture.ReleaseTemporary(defaultDepthRt);
        RenderTexture.ReleaseTemporary(maskRT);
        RenderTexture.ReleaseTemporary(computeRT);
    }

}
