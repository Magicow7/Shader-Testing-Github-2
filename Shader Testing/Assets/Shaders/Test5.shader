Shader "Custom/Test5"
//similar to Test4, but using distance to the centerpoint instead of uv.y
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _Color1 ("Main Color", Color) = (1,0,1,1)
        _Color2 ("Secondary Color", Color) = (1,1,0,1)
        _Speed("Rate", float) = 1.0
        _SinClamp("SinClamp", float) = 2
        _SmoothEdge("SmoothEdge", float) = 2
        _CurrTime("Current Time", float) = 0
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

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                UNITY_TRANSFER_FOG(o,o.vertex);
                return o;
            }

            fixed4 _Color1;
            fixed4 _Color2;
            float _Speed;
            float _SinClamp;
            float _CurrTime;
            float _SmoothEdge;

            fixed4 frag (v2f i) : SV_Target
            {
                // sample the texture

                fixed4 col = tex2D(_MainTex, i.uv);

                //get the centerpoint. we subtract 0.5 from the uv to get the bottom left corner
                float2 newUV = i.uv - 0.5;
                float d = length(newUV);

                //same as test4 shader
                float time = _CurrTime * _Speed;
                float sinTime = sin(time)/_SinClamp;

                //same as test4 shader except using smoothstep to change how sharp the gradient is.
                col = fixed4(0,0,0,0);
                col += (smoothstep(0.5-(_SmoothEdge/2),0.5+(_SmoothEdge/2),(d + sinTime))) * _Color1;
                col += (smoothstep(0.5-(_SmoothEdge/2),0.5+(_SmoothEdge/2),(1- d - sinTime))) *  _Color2;

                return col;
            }
            ENDCG
        }
    }
}

