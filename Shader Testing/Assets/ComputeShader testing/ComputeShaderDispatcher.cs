using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class ComputeShaderDispatcher : MonoBehaviour
{

    // Define THREAD_GROUP_SIZE to match the compute shader
    private const int THREAD_GROUP_SIZE = 256;
    public ComputeShader m_shader;
    public RenderTexture m_mainTex;
    int m_texSize = 256;
    Renderer m_rend;
    
    void OnMouseDown(){
        Generate();
    }
    void Generate(){
        m_mainTex= new RenderTexture(m_texSize , m_texSize, 0,
        RenderTextureFormat.ARGB32);
        m_mainTex.enableRandomWrite = true;
        m_mainTex.Create();
        m_rend = GetComponent<Renderer>();
        m_rend.enabled = true;

        List<int> inList = new List<int>();
        for(int i = 0; i < 1000000; i++){
            inList.Add((int)5);//Random.Range(0,10));
        }
        bool summationFinished = false;
        while(!summationFinished){
            // Total number of integers to sum
            int totalCount = inList.Count;
            int threadGroups = Mathf.CeilToInt(totalCount / (float)THREAD_GROUP_SIZE);//ComputeShaderExample.THREAD_GROUP_SIZE);

            //length of list and length of each element
            ComputeBuffer inBuffer = new ComputeBuffer(totalCount, sizeof(int));
            ComputeBuffer outputBuffer = new ComputeBuffer(threadGroups, sizeof(int));

            // Set buffer data
            inBuffer.SetData(inList.ToArray());

            //kernel index, string name in compute shader, c# compute buffer
            m_shader.SetBuffer(0, "outputData", outputBuffer);
            m_shader.SetBuffer(0, "inputData", inBuffer);
            m_shader.SetInt("totalCount", totalCount);
            
            
            //m_shader.SetTexture(0, "Result", m_mainTex);
            //m_rend.material.SetTexture("_MainTex", m_mainTex);
            // generate the thread group to process the texture
            //number of groups in the x direction is totalCount/256


            //https://minidump.net/reading-net-performance-counters-without-the-perfcounter-api-aca5eab08874/
            m_shader.Dispatch(0, threadGroups, 1, 1);

            //get final value
            int[] outputData = new int[threadGroups];
            outputBuffer.GetData(outputData);
            /*
            for(int i = 0; i < threadGroups; i++){
                Debug.Log(i+":" + outputData[i]);
            }*/
            List<int> tempList = new List<int>(); 
            
            for(int i = 0; i < outputData.Length; i++){
                tempList.Add(outputData[i]);
            }
            inList = tempList;

            if(inList.Count == 1){
                summationFinished = true;
            }

            //release buffers
            inBuffer.Release();
            outputBuffer.Release();
        }

        Debug.Log(inList[0]);
        
    }

    /*void Start(){
        m_mainTex= new RenderTexture(m_texSize , m_texSize, 0,
        RenderTextureFormat.ARGB32);
        m_mainTex.enableRandomWrite = true;
        m_mainTex.Create();
        m_rend = GetComponent<Renderer>();
        m_rend.enabled = true;

        List<int> inList = new List<int>();
        for(int i = 0; i < 5000; i++){
            inList.Add(5);//(int)Random.Range(0,10));
        }

        // Total number of integers to sum
        int totalCount = inList.Count;
        int threadGroups = Mathf.CeilToInt(totalCount / (float)THREAD_GROUP_SIZE);//ComputeShaderExample.THREAD_GROUP_SIZE);

        //length of list and length of each element
        ComputeBuffer inBuffer = new ComputeBuffer(totalCount, sizeof(int));
        ComputeBuffer outputBuffer = new ComputeBuffer(threadGroups, sizeof(int));

        // Set buffer data
        inBuffer.SetData(inList.ToArray());

        //kernel index, string name in compute shader, c# compute buffer
        m_shader.SetBuffer(0, "outputData", outputBuffer);
        m_shader.SetBuffer(0, "inputData", inBuffer);
        m_shader.SetInt("totalCount", totalCount);
        
        
        //m_shader.SetTexture(0, "Result", m_mainTex);
        //m_rend.material.SetTexture("_MainTex", m_mainTex);
        // generate the thread group to process the texture
        //number of groups in the x direction is totalCount/256
        
        m_shader.Dispatch(0, threadGroups, 1, 1);

        //get final value
        int[] outputData = new int[threadGroups];
        outputBuffer.GetData(outputData);
        for(int i = 0; i < threadGroups; i++){
            Debug.Log(i+":" + outputData[i]);
        }
        

        //release buffers
        inBuffer.Release();
        outputBuffer.Release();
    }*/

    /*void Start(){
        m_mainTex= new RenderTexture(m_texSize , m_texSize, 0,
        RenderTextureFormat.ARGB32);
        m_mainTex.enableRandomWrite = true;
        m_mainTex.Create();
        m_rend = GetComponent<Renderer>();
        m_rend.enabled = true;

        List<int> inList = new List<int>();
        for(int i = 0; i < 5000; i++){
            inList.Add((int)Random.Range(0,10));
        }

        // Total number of integers to sum
        int totalCount = inList.Count;

        //length of list and length of each element
        ComputeBuffer inBuffer = new ComputeBuffer(totalCount, sizeof(int));
        ComputeBuffer outputBuffer = new ComputeBuffer(totalCount, sizeof(int));

        // Set buffer data
        inBuffer.SetData(inList.ToArray());

        //kernel index, string name in compute shader, c# compute buffer
        m_shader.SetBuffer(0, "outputData", outputBuffer);
        m_shader.SetBuffer(0, "inputData", inBuffer);
        m_shader.SetInt("totalCount", totalCount);
        
        
        //m_shader.SetTexture(0, "Result", m_mainTex);
        //m_rend.material.SetTexture("_MainTex", m_mainTex);
        // generate the thread group to process the texture
        //number of groups in the x direction is totalCount/256
        int threadGroups = Mathf.CeilToInt(totalCount / (float)THREAD_GROUP_SIZE);//ComputeShaderExample.THREAD_GROUP_SIZE);
        m_shader.Dispatch(0, threadGroups, 1, 1);

        //get final value
        int[] outputData = new int[totalCount];
        outputBuffer.GetData(outputData);
        for(int i = 0; i < totalCount; i++){
            Debug.Log(i+":" + outputData[i]);
        }
        

        //release buffers
        inBuffer.Release();
        outputBuffer.Release();
    }*/
}
