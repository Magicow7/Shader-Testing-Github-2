using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class MatrixSetter : MonoBehaviour
{
    public new Camera camera;
    public Material mat;
    // Start is called before the first frame update
    void Update ()
    {
        var viewMatrix = camera.worldToCameraMatrix;
		var projectionMatrix = camera.projectionMatrix;
		projectionMatrix = GL.GetGPUProjectionMatrix(projectionMatrix, false);
		var clipToPos = (projectionMatrix * viewMatrix).inverse;
		mat.SetMatrix("clipToWorld", clipToPos);

		//base.OnRenderImage(source, destination);
    }
}
