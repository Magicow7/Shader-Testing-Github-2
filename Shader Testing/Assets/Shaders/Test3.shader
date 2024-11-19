Shader "Custom/Test3"
{
    //this shader creates a gradient
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _Color1 ("Main Color", Color) = (1,0,1,1)
        _Color2 ("Secondary Color", Color) = (1,1,0,1)
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

            fixed4 frag (v2f i) : SV_Target
            {
                // sample the texture
                fixed4 col = tex2D(_MainTex, i.uv);
                col = fixed4(0,0,0,0);
                //use uv.y values to set colors
                col += i.uv.y * _Color1;
                col += (1-i.uv.y) * _Color2;
                return col;
            }
            ENDCG
        }
    }
}
