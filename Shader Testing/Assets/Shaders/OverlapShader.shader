Shader "Custom/OverlapShader"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _SecondayTex ("Texture", 2D) = "white" {}
        _MinBounds ("Min Bounds", Vector) = (0, 0, -1, 0)
        _MaxBounds ("Max Bounds", Vector) = (1, 1.42, 1, 0)
        _Color ("Color (RGBA)", Color) = (1, 1, 1, 1)
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
            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float3 worldPos : TEXCOORD1;
                float4 vertex : SV_POSITION;
                bool inObject : IN_OBJECT;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            sampler2D _SecondaryTex;
            float4 _SecondaryTex_ST;
            float4 _Color;
            float4 _MinBounds;
            float4 _MaxBounds;

            v2f vert (appdata v)
            {
                v2f o;
                //mull does matrix multiplication
                o.worldPos = mul (unity_ObjectToWorld, v.vertex);
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                o.inObject = false;
                if (all(o.worldPos >= _MinBounds.xyz) && all(o.worldPos <= _MaxBounds.xyz))
                {
                    o.inObject = true;
                }
                
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                // sample the texture
                fixed4 col = tex2D(_MainTex, i.uv);
                if(i.inObject == true){
                    col = _Color;
                }
                
                return col;
            }
            ENDCG
        }
    }
}
