Shader "Custom/Test6"
//this was an attempt to layer two textures on top of one another, with cutout on the higher layer image so the lower image is still visible.
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _SecondaryTex ("Texture2", 2D) = "white" {}
        _CutoutThreshold("Cutout Threshold", Range(0,1)) = 0
        _LerpVal("LerpVal", Range (0, 1)) = 1.0
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            // make fog work
            #pragma multi_compile_fog

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                UNITY_FOG_COORDS(1)
                float4 vertex : SV_POSITION;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            sampler2D _SecondaryTex;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                UNITY_TRANSFER_FOG(o,o.vertex);
                return o;
            }

            float _CutoutThreshold;
            float _LerpVal;

            fixed4 frag (v2f i) : SV_Target
            {
                // sample the texture

                //I had to do -i.uv and I don't really get why, it was rendering upside down without it
                fixed4 col1 = tex2D(_MainTex, -i.uv);
                fixed4 col2 = tex2D(_SecondaryTex, -i.uv);
                fixed4 returnCol = col1;
                //if the alpha value of the higher layer is 0, lerp between the colors by the desired value, otherwise just render the lower layer.
                if(col2.a > _CutoutThreshold){
                    returnCol = lerp(col1,col2,_LerpVal);
                }

                return returnCol;

            }
            ENDCG
        }
    }
}

