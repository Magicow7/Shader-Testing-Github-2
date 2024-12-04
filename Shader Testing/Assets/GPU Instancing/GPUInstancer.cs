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
    private ComputeShader badAppleCompute;


    [SerializeField]
    private const int matrixCount = 10000;

    [SerializeField]
    private float MovementSpeed = 1;
    private Matrix4x4[] matricies;
    private Vector4[] colors;

    MaterialPropertyBlock propertyBlock;

    //compute buffers
    ComputeBuffer positionMatrixBuffer;
    ComputeBuffer timeBuffer;
    void Start()
    {
        mesh = toCopy.GetComponent<MeshFilter>().mesh;
        material = toCopy.GetComponent<Renderer>().material;

        //set up matricies
        matricies = new Matrix4x4[matrixCount];
        colors = new Vector4[matrixCount];

        for (int i = 0; i < matrixCount; i++)
        {
            //TRS is tranlation, rotation, scale
            matricies[i] = Matrix4x4.TRS(
                new Vector3(Random.Range(-6.4f, 6.4f), 0f, Random.Range(-3.6f, 3.6f)),
                toCopy.transform.rotation* Quaternion.Euler(new Vector3(0, Random.Range(0,360), 0)),
                toCopy.transform.localScale
            );
            colors[i] = new Vector4(Random.value, Random.value, Random.value, 1f);
        }

        // Create a MaterialPropertyBlock for custom properties
        //This lets us override material properties for this one render instance. multiple objects can use the same material and look different, saving memory
        //this could be used in the boids project
        propertyBlock = new MaterialPropertyBlock();
        //propertyBlock.SetVectorArray("_Color", colors);

        //create compute buffers
        positionMatrixBuffer = new ComputeBuffer(matrixCount, sizeof(float) * 16); // 4x4 matrix = 16 floats
        timeBuffer = new ComputeBuffer(1, sizeof(float), ComputeBufferType.Default);
    }

    void Update(){
        /*
        //if i store thes matricies as private vars, I can keep instancing things in the same positions.
       

        // Draw instances
        //Note this is outdated in unity 2023, but this project is on unity 2022
        Graphics.DrawMeshInstanced(mesh, 0, material, matrices, 1000, propertyBlock);
        */

        //compute shader setup
        int kernelHandle = badAppleCompute.FindKernel("CSMain");

        badAppleCompute.SetTexture(kernelHandle, "BadAppleTexture", badAppleTexture);

        
        positionMatrixBuffer.SetData(matricies);
        badAppleCompute.SetBuffer(0, "instancePositions", positionMatrixBuffer);

        //buffer to hold deltatime
        
        timeBuffer.SetData(new float[] {Time.deltaTime * MovementSpeed});
        badAppleCompute.SetBuffer(0, "timeBuffer", timeBuffer);

        //CreateIndirectBuffer(matricies.Length);
        

        int threadGroupsX = Mathf.CeilToInt(matrixCount / 64.0f);
        //int threadGroupsY = Mathf.CeilToInt(badAppleTexture.height / 8.0f);

        //dispatch
        badAppleCompute.Dispatch(kernelHandle, threadGroupsX, 1, 1);

        Matrix4x4[] outputMatricies = new Matrix4x4[matrixCount];
        positionMatrixBuffer.GetData(outputMatricies);

        Graphics.DrawMeshInstanced(mesh, 0, material, outputMatricies, matrixCount, propertyBlock);

        //update matrix list
        matricies = outputMatricies;
        Debug.Log(matricies[0]);
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
        // Release the buffer when done
        if (timeBuffer != null)
        {
            timeBuffer.Release();
        }

        if (positionMatrixBuffer != null)
        {
            positionMatrixBuffer.Release();
        }
    }

    /*void CreateIndirectBuffer(int instanceCount)
    {
        // Each element is an array of 4 integers for indirect drawing
        argsBuffer = new ComputeBuffer(1, sizeof(int) * 4, ComputeBufferType.IndirectArguments);
        uint[] args = new uint[4] { (uint)mesh.GetIndexCount(0), 0, (uint)instanceCount, 0 };
        argsBuffer.SetData(args);
    }*/
}
