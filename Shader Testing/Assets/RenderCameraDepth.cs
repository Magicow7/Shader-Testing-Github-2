using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class RenderCameraDepth : MonoBehaviour
{
    private Camera camera;

    public RenderTexture depthTexture;
    public RenderTexture colorTexture;
    void Start()
    {
        camera = GetComponent<Camera>();
        // Create depth textures
        colorTexture = new RenderTexture(Screen.width, Screen.height, 0);
        depthTexture = new RenderTexture(Screen.width, Screen.height, 24, RenderTextureFormat.Depth);
        camera.targetTexture = depthTexture;
        camera.SetTargetBuffers(colorTexture.colorBuffer, depthTexture.depthBuffer);
    }

    void OnPreRender()
    {
        // Clear the render textures before each camera renders
        Graphics.SetRenderTarget(depthTexture);
        GL.Clear(true, true, Color.clear);

        Graphics.SetRenderTarget(colorTexture);
        GL.Clear(true, true, Color.clear);

    }

    void OnRenderObject()
    {
        // Reset the render target to default after rendering
        Graphics.SetRenderTarget(null);
    }
}
