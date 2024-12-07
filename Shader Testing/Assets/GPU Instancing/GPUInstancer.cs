using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class GPUInstancer : MonoBehaviour
{
    public GameObject toCopy;
    private Mesh mesh;
    private Material material;

    [SerializeField]
    private RenderTexture badAppleTexture;

    [SerializeField]
    private RenderTexture DensityMapTexture;

    [SerializeField]
    private RenderTexture DensityMapVisualizerTexture;

    [SerializeField]
    private ComputeShader badAppleCompute;


    [SerializeField]
    private const int matrixCount = 1000;

    [SerializeField]
    private bool visualizeDensityMap;

    [SerializeField]
    private float timeMult = 1;

    [SerializeField]
    private AnimationCurve MovementSpeed;

    [SerializeField]
    private AnimationCurve DensitySensitivity;

    [SerializeField]
    private AnimationCurve LookaheadDistanceMult;
    private Matrix4x4[] matricies;

    private Vector4[] instanceTraits;
    //private Vector4[] colors;

    MaterialPropertyBlock propertyBlock;

    //compute buffers
    ComputeBuffer positionMatrixBuffer;

    ComputeBuffer instanceTraitsBuffer;
    ComputeBuffer timeBuffer;
    void Start()
    {
        mesh = toCopy.GetComponent<MeshFilter>().mesh;
        material = toCopy.GetComponent<Renderer>().material;

        //set up matricies
        matricies = new Matrix4x4[matrixCount];
        instanceTraits = new Vector4[matrixCount];
        //colors = new Vector4[matrixCount];

        for (int i = 0; i < matrixCount; i++)
        {
            //TRS is tranlation, rotation, scale
            matricies[i] = Matrix4x4.TRS(
                new Vector3(Random.Range(-6.4f, 6.4f), 0f, Random.Range(-3.6f, 3.6f)),
                toCopy.transform.rotation* Quaternion.Euler(new Vector3(0, Random.Range(0,360), 0)),
                toCopy.transform.localScale
            );

            //SET TRAITS
            instanceTraits[i] = new Vector4(
                DensitySensitivity.Evaluate(Random.Range(0f,1f)), //density sensitivity
                MovementSpeed.Evaluate(Random.Range(0f,1f)), //speed
                LookaheadDistanceMult.Evaluate(Random.Range(0f,1f)), //lookaheadDist
                1 //extra value
            );
            
            //colors[i] = new Vector4(Random.value, Random.value, Random.value, 1f);
        }

        // Create a MaterialPropertyBlock for custom properties
        //This lets us override material properties for this one render instance. multiple objects can use the same material and look different, saving memory
        //this could be used in the boids project
        propertyBlock = new MaterialPropertyBlock();
        //propertyBlock.SetVectorArray("_Color", colors);

        //create compute buffers
        positionMatrixBuffer = new ComputeBuffer(matrixCount, sizeof(float) * 16); // 4x4 matrix = 16 floats
        instanceTraitsBuffer = new ComputeBuffer(matrixCount, sizeof(float) * 4);
        timeBuffer = new ComputeBuffer(1, sizeof(float), ComputeBufferType.Default);
        //this is done at start because it will not be modified
        instanceTraitsBuffer.SetData(instanceTraits);
    }

    void Update(){
        /*
        //if i store thes matricies as private vars, I can keep instancing things in the same positions.
       

        // Draw instances
        //Note this is outdated in unity 2023, but this project is on unity 2022
        Graphics.DrawMeshInstanced(mesh, 0, material, matrices, 1000, propertyBlock);
        */
        //general setup
        //64 threads per group total
        int threadGroupsX = Mathf.CeilToInt(matrixCount / 64.0f);

        positionMatrixBuffer.SetData(matricies);

        //setup desntitymap creation
        int kernelHandle = badAppleCompute.FindKernel("CSMain2");

        //reset texture from last frame
        ClearRenderTexture(DensityMapTexture);

        badAppleCompute.SetTexture(kernelHandle, "DensityTexture", DensityMapTexture);

        badAppleCompute.SetBuffer(kernelHandle, "instancePositions", positionMatrixBuffer);
        badAppleCompute.SetInt("instanceCount", matrixCount);

        //reset densitybuffer
        //uint[] zeroArray = new uint[badAppleTexture.width * badAppleTexture.height];
        //Array.Clear

        //badAppleCompute.SetBuffer(kernelHandle, "DensityBuffer", densityBuffer);

        badAppleCompute.Dispatch(kernelHandle, threadGroupsX, 1, 1);


        if(visualizeDensityMap){
            kernelHandle = badAppleCompute.FindKernel("VisualizeDensityMap");
            badAppleCompute.SetTexture(kernelHandle, "DensityTexture", DensityMapTexture);
            badAppleCompute.SetTexture(kernelHandle, "DensityVisualizeTexture", DensityMapVisualizerTexture);
            
            threadGroupsX = Mathf.CeilToInt(DensityMapTexture.width / 8.0f);
            int threadGroupsY = Mathf.CeilToInt(DensityMapTexture.height / 8.0f);
            badAppleCompute.Dispatch(kernelHandle, threadGroupsX, threadGroupsY, 1);
        }
        /*

        //read value from density texture for testing
        Texture2D texture2D = new Texture2D(DensityMapTexture.width, DensityMapTexture.height, TextureFormat.RGBA32, false);

        // Set the active RenderTexture to the one you want to read from
        RenderTexture.active = DensityMapTexture;

        // Read the pixels from the RenderTexture into the Texture2D
        texture2D.ReadPixels(new Rect(0, 0, DensityMapTexture.width, DensityMapTexture.height), 0, 0);
        texture2D.Apply();
        Color[] pixels = texture2D.GetPixels();
        uint uintValue = (uint)(pixels[0].r * uint.MaxValue);
        Debug.Log(uintValue);
        */


        //compute shader setup
        kernelHandle = badAppleCompute.FindKernel("CSMain");

        badAppleCompute.SetTexture(kernelHandle, "BadAppleTexture", badAppleTexture);

        badAppleCompute.SetTexture(kernelHandle, "DensityTexture", DensityMapTexture);
        
        badAppleCompute.SetBuffer(kernelHandle, "instancePositions", positionMatrixBuffer);

        badAppleCompute.SetBuffer(kernelHandle, "instanceTraits", instanceTraitsBuffer);

        //buffer to hold deltatime
        
        timeBuffer.SetData(new float[] {Time.deltaTime * timeMult});
        badAppleCompute.SetBuffer(kernelHandle, "timeBuffer", timeBuffer);
        
        //int threadGroupsY = Mathf.CeilToInt(badAppleTexture.height / 8.0f);
        threadGroupsX = Mathf.CeilToInt(matrixCount / 64.0f);
        //dispatch
        badAppleCompute.Dispatch(kernelHandle, threadGroupsX, 1, 1);

        Matrix4x4[] outputMatricies = new Matrix4x4[matrixCount];
        positionMatrixBuffer.GetData(outputMatricies);

        Graphics.DrawMeshInstanced(mesh, 0, material, outputMatricies, matrixCount, propertyBlock);

        //update matrix list
        matricies = outputMatricies;
        //Debug.Log(matricies[0]);
        // Draw the mesh instances using the indirect args buffer
        //Graphics.DrawMeshInstancedIndirect(mesh, 0, material, new Bounds(Vector3.zero, new Vector3(20f, 20f, 20f)), argsBuffer);

        //free buffers
        /*
        positionMatrixBuffer.Release();
        timeBuffer.Release();
        */
    }

    void OnDestroy()
    {
        // Release the buffers when done
        if (timeBuffer != null)
        {
            timeBuffer.Release();
        }

        if (positionMatrixBuffer != null)
        {
            positionMatrixBuffer.Release();
        }
        
        if (instanceTraitsBuffer != null)
        {
            instanceTraitsBuffer.Release();
        }
    }

    /*void CreateIndirectBuffer(int instanceCount)
    {
        // Each element is an array of 4 integers for indirect drawing
        argsBuffer = new ComputeBuffer(1, sizeof(int) * 4, ComputeBufferType.IndirectArguments);
        uint[] args = new uint[4] { (uint)mesh.GetIndexCount(0), 0, (uint)instanceCount, 0 };
        argsBuffer.SetData(args);
    }*/

    void ClearRenderTexture(RenderTexture rt)
    {
        // Set the render target to the RenderTexture
        RenderTexture.active = rt;

        // Clear it with a black color (or any other color you prefer)
        GL.Clear(true, true, Color.clear);

        // Optionally, reset the active render texture if you want to draw to the screen afterwards
        RenderTexture.active = null;
    }
}
