Shader "Custom/ChromaKeyWithBlur"
{
     Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _BackgroundTex("BackgroundTex", 2D) = "white" {}
        _KeyColor("KeyColor", Color) = (0,1,0,1)
        _KeyColorRange("KeyColorRange", Color) = (0,0,0,1)
        _BlurSize ("Blur Size", Float) = 1.0   // Controls the blur intensity

        _CurveTex ("Curve Texture", 2D) = "white" {} // 1D texture for the curve
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
            sampler2D _BackgroundTex;
            sampler2D _CurveTex;
            float4 _MainTex_TexelSize;          // Automatically provided by Unity (1/texture width, 1/texture height)
            float _BlurSize;                    // Blur intensity (adjustable)
            half4 _KeyColor;
            half4 _KeyColorRange;

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

            half GetRatio(half4 inColor, half4 KeyColor, half3 ColorCubeParams){
                half4 cube = half4(ColorCubeParams.r,ColorCubeParams.g, ColorCubeParams.b,0);
                half4 clampedColor = clamp(inColor, KeyColor - cube, KeyColor + cube);
                //THE ALL WAS THE ISSUE
                half val = all(clampedColor == inColor) ? 0 : 1;
                return val;
            }

            // Fragment shader (3x3 box blur)
            fixed4 frag(v2f i) : SV_Target
            {
                //main tex color
                half4 c = tex2D(_MainTex, i.uv);
                //background tex color
                half4 b = tex2D(_BackgroundTex, i.uv);
                // Define texel size (from _MainTex_TexelSize, auto-assigned by Unity)
                float2 texelSize = _MainTex_TexelSize.xy * _BlurSize;

                // Sample the surrounding 9 pixels in a 3x3 grid
                float accumulator = 0;
                accumulator += GetRatio(tex2D(_MainTex, i.uv + texelSize * float2(-1, -1)), _KeyColor, _KeyColorRange.rgb);  // Top-left
                accumulator += GetRatio(tex2D(_MainTex, i.uv + texelSize * float2(0, -1)), _KeyColor, _KeyColorRange.rgb);   // Top-center
                accumulator += GetRatio(tex2D(_MainTex, i.uv + texelSize * float2(1, -1)), _KeyColor, _KeyColorRange.rgb);   // Top-right

                accumulator += GetRatio(tex2D(_MainTex, i.uv + texelSize * float2(-1, 0)), _KeyColor, _KeyColorRange.rgb);   // Mid-left
                accumulator += GetRatio(tex2D(_MainTex, i.uv + texelSize * float2(0, 0)), _KeyColor, _KeyColorRange.rgb);     // Center pixel
                accumulator += GetRatio(tex2D(_MainTex, i.uv + texelSize * float2(1, 0)), _KeyColor, _KeyColorRange.rgb);    // Mid-right

                accumulator += GetRatio(tex2D(_MainTex, i.uv + texelSize * float2(-1, 1)), _KeyColor, _KeyColorRange.rgb);   // Bottom-left
                accumulator += GetRatio(tex2D(_MainTex, i.uv + texelSize * float2(0, 1)), _KeyColor, _KeyColorRange.rgb);// Bottom-center
                accumulator += GetRatio(tex2D(_MainTex, i.uv + texelSize * float2(1, 1)), _KeyColor, _KeyColorRange.rgb);    // Bottom-right
                
                // Average the color of the sampled pixels
                accumulator /= 9.0;

                //return fixed4(accumulator,0,0,1);

                // Sample the curve texture using the curve input
                /*
                float4 curveValue = tex2D(_CurveTex, float2(accumulator,0)); // Sample the curve texture
                accumulator = curveValue.r;
                return curveValue;
                */
                //apply logistic function
                //this funciton uses E
                //f(x)=1/(1+e^(-17x + 10))
                
                /*
                if(accumulator < 0.5){
                    accumulator = 1/(1+pow(2.718281828459045,(-30*accumulator + 15)));
                }else{
                    accumulator = 1/(1+pow(2.718281828459045,(-10*accumulator + 5)));
                }*/

                accumulator = smoothstep(0.6,0.7,accumulator);


                
                //return accumulator;
                return (c * accumulator + b * (1-accumulator));  // Return final value
            }
            ENDCG
        }
    }
    FallBack "Diffuse"
}