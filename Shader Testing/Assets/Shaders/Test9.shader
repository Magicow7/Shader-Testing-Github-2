
Shader "Custom/Test9"
//TO USE THIS SHADER ON THE PLANE, ROTATE THE PLANE TRANSFORM TO (90,0,0). THE IMAGE IS RENDERING ON THE WRONG SIDE
//I think it has something to do with the new shader setup for transparency
//This is a remake of Test8 using conventions I'm more used to
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _Size("Size", Range (-1, 1)) = 0.5
        _Color ("Color (RGBA)", Color) = (1, 1, 1, 1)
    }
    SubShader
    {
        Tags {"Queue"="Transparent" "IgnoreProjector"="True" "RenderType"="Transparent"}
        ZWrite Off
        Blend SrcAlpha OneMinusSrcAlpha
        Cull front 
        LOD 100

        Pass
        {
            CGPROGRAM
            #pragma vertex vert alpha
            #pragma fragment frag alpha
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

            float4 _Color;
            float _Size;

            fixed4 frag (v2f i) : SV_Target
            {
                fixed4 col = tex2D(_MainTex, i.uv) * _Color; // multiply by _Color

                //this part was added by me, I changed transparency by distance to the center
                float2 newUV = i.uv - 0.5;
                float d = length(newUV);
                //clamp to avoid negative transparency
                col.a = clamp(1-d - _Size,0,1);

                return col;
            }
            ENDCG
        }
    }
}

