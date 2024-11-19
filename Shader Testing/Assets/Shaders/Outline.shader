Shader "Custom/Outline"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _OutlineColor ("Outline Color", Color) = (1, 1, 0, 1)
        _OutlineThickness ("Outline Thickness", Range(0.0, 10.0)) = 1.5
    }
    SubShader
    {
        Tags { "RenderType"="Opaque"}
        LOD 200

        Pass
        {
            //https://ameye.dev/notes/rendering-outlines/
            //look at jump flood algorithm: https://bgolus.medium.com/the-quest-for-very-wide-outlines-ba82ed442cd9


            // Outline pass
            //it wasn't rendering in scene because ZWrite was on, which allows us to update depth buffer, ZWrite off lead to inccorect depth ordering in relation to the skybox
            //ZWrite Off
            Cull Front
            Blend SrcAlpha OneMinusSrcAlpha

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"

            struct appdata_t
            {
                //type name : semantic (page 105 of the textbook)
                //unity semantics : https://docs.unity3d.com/Manual/SL-ShaderSemantics.html
                float4 vertex : POSITION;
                float3 normal : NORMAL;
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
                float4 color : COLOR;
            };

            float4 _OutlineColor;
            float _OutlineThickness;

            v2f vert(appdata_t v)
            {
                v2f o;
                float3 norm = normalize(v.normal);
                // Expand the vertex position along the normal direction
                v.vertex.xyz += norm * _OutlineThickness;
                //scale up all verticies
                //v.vertex.xyz *= _OutlineThickness;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.color = _OutlineColor;
                return o;
            }

            fixed4 frag(v2f i) : SV_Target
            {
                return i.color;
            }
            ENDHLSL
        }
        

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
                //sv position is a minor optimization over position, sv won't pass o.pos to the frag shader, while position will, so use sv when position isn't needed in frag
                float4 vertex : SV_POSITION;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                fixed4 col1 = tex2D(_MainTex, i.uv);

                return col1;

            }
            ENDCG
        }
    }
}
