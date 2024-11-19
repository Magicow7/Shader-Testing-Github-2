Shader "Custom/Test7"
//this was a mistake I made with shader 6, but it had a cool outcome that I thought might be useful later.
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _SecondaryTex ("Texture2", 2D) = "white" {}
        _CutoutThreshold("Cutout Threshold", Range (0, 1)) = 0
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

            fixed4 frag (v2f i) : SV_Target
            {
                // sample the texture

                fixed4 col1 = tex2D(_MainTex, -i.uv);
                fixed4 col2 = tex2D(_SecondaryTex, -i.uv);
                fixed4 returnCol = col1;

                if(col2.a < _CutoutThreshold){
                    //my mistake was discarding everything with alpha value 0, because the lower layer wouldn't render, but it created a cool effect.
                    discard;
                }


                return lerp(col1, col2, 0.5);

            }
            ENDCG
        }
    }
}

