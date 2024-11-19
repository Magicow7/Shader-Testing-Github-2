
Shader "Custom/Test8"
//TO USE THIS SHADER ON THE PLANE, ROTATE THE PLANE TRANSFORM TO (90,0,0). THE IMAGE IS RENDERING ON THE WRONG SIDE
//this is an attempt to do transparency
//this shader was copied from a forum I found, the made a bunch of changes to the shader setup that I don't entirely understand
//but it is useful to experiment with for now
{
    Properties 
    {
        _MainTex ("Base (RGB)", 2D) = "white" {}
        _Color ("Color (RGBA)", Color) = (1, 1, 1, 1) // add _Color property
        _Size("LerpVal", Range (0, 1)) = 0.5
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

            #include "UnityCG.cginc"

            struct appdata_t 
            {
                float4 vertex   : POSITION;
                float2 texcoord : TEXCOORD0;
            };

            struct v2f 
            {
                float4 vertex  : SV_POSITION;
                half2 texcoord : TEXCOORD0;
            };

            sampler2D _MainTex;
            //this variable handles the transforms, scales, and rotations of the objects.
            float4 _MainTex_ST;
            float4 _Color;
            float _Size;

            v2f vert (appdata_t v)
            {
                v2f o;

                o.vertex     = UnityObjectToClipPos(v.vertex);
                v.texcoord.x = 1 - v.texcoord.x;
                o.texcoord   = TRANSFORM_TEX(v.texcoord, _MainTex);

                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                fixed4 col = tex2D(_MainTex, i.texcoord) * _Color; // multiply by _Color

                //this part was added by me, I changed transparency by distance to the center
                float2 newUV = i.texcoord - 0.5;
                float d = length(newUV);
                //clamp to avoid negative transparency
                col.a = clamp(1-d - _Size,0,1);

                return col;
            }

            ENDCG
        }
    }
}

