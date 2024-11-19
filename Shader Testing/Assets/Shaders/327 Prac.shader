Shader "327/327 Prac"
{
     Properties
    {
        _MainTex ("Texture", 2D) = "white" {}  // The input texture
        _BlurSize ("Blur Size", Float) = 1.0   // Controls the blur intensity
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 200

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"

            // Shader properties
            sampler2D _MainTex;                 // Input texture
            float4 _MainTex_TexelSize;          // Automatically provided by Unity (1/texture width, 1/texture height)
            float _BlurSize;                    // Blur intensity (adjustable)

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
            };

            // Vertex shader
            v2f vert(appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);  // Transform to clip space
                o.uv = v.uv;  // Pass the UV coordinates to the fragment shader
                return o;
            }

            // Fragment shader (3x3 box blur)
            fixed4 frag(v2f i) : SV_Target
            {
                // Define texel size (from _MainTex_TexelSize, auto-assigned by Unity)
                float2 texelSize = _MainTex_TexelSize.xy * _BlurSize;

                // Sample the surrounding 9 pixels in a 3x3 grid
                float4 color = 0;

                color += tex2D(_MainTex, i.uv + texelSize * float2(-1, -1));  // Top-left
                color += tex2D(_MainTex, i.uv + texelSize * float2(0, -1));   // Top-center
                color += tex2D(_MainTex, i.uv + texelSize * float2(1, -1));   // Top-right

                color += tex2D(_MainTex, i.uv + texelSize * float2(-1, 0));   // Mid-left
                color += tex2D(_MainTex, i.uv);                               // Center pixel
                color += tex2D(_MainTex, i.uv + texelSize * float2(1, 0));    // Mid-right

                color += tex2D(_MainTex, i.uv + texelSize * float2(-1, 1));   // Bottom-left
                color += tex2D(_MainTex, i.uv + texelSize * float2(0, 1));    // Bottom-center
                color += tex2D(_MainTex, i.uv + texelSize * float2(1, 1));    // Bottom-right

                // Average the color of the sampled pixels
                color /= 9.0;

                return color;  // Return the blurred color
            }
            ENDCG
        }
    }
    FallBack "Diffuse"
}