using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class CurveMaker : MonoBehaviour
{
    public AnimationCurve curve; // Curve to visualize
    public int textureWidth = 256; // Width of the curve texture
    public Material shaderMat;
    private Texture2D curveTexture;

    void Start()
    {
        GenerateCurveTexture();
    }

    void GenerateCurveTexture()
    {
        curveTexture = new Texture2D(textureWidth, 1);
        for (int x = 0; x < textureWidth; x++)
        {
            float t = (float)x / (textureWidth - 1); // Normalize x to [0, 1]
            float value = curve.Evaluate(t); // Evaluate the curve
            curveTexture.SetPixel(x, 0, new Color(value, value, value)); // Store in grayscale
        }
        curveTexture.Apply();
        shaderMat.SetTexture("_CurveTex", curveTexture);

    }

}
