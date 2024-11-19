Shader "Custom/Test4"
//another gradient between two colors, but it oscillates over sin(time)
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _Color1 ("Main Color", Color) = (1,0,1,1)
        _Color2 ("Secondary Color", Color) = (1,1,0,1)
        _Speed("Rate", float) = 1.0
        _SinClamp("SinClamp", float) = 2
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

            fixed4 frag (v2f i) : SV_Target
            {
                // sample the texture
                fixed4 col = tex2D(_MainTex, i.uv);
            
                //multiply time by a desired rate and scale the magnitude of the sin wave
                float time = _Time.y * _Speed;
                float sinTime = sin(time)/_SinClamp;

                //same as test3 shader, but scaling by the sinTime value
                col = fixed4(0,0,0,0);
                col += (i.uv.y + sinTime ) * _Color1;
                col += (1-i.uv.y - sinTime) *  _Color2;
                return col;
            }
            ENDCG
        }
    }
}

