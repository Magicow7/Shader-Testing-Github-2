Shader "Custom/NewMetaballs"
{
    Properties
    {
        _MainTex ("Base (RGB)", 2D) = "white" {}
        _Threshold ("Threshold", Float) = 1.0
        //_NumMetaballs ("Number of Metaballs", Int) = 3
        //_MetaballPositions ("Metaball Positions", Vector) = (0, 0, 0, 0)
        _Position ("Metaball 1 position", Vector) = (0,0,0)
        _TestPos ("TestPos", Vector) = (0,0,0)
        _Radius ("Metaball 1 radius", Float) = 2.0
        //_Metaball2Position ("Metaball 2 position", Vector) = (0,0,0)
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
            float _Threshold;
            Vector _Position;
            Vector _TestPos;
            float _Radius;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                UNITY_TRANSFER_FOG(o,o.vertex);
                return o;
            }

            // Helper functions for raymarching
            float sphereSDF(float3 p, float3 center, float radius)
            {
                return length(p - center) - radius;
            }

            float Raymarch(float3 ro, float3 rd, float threshold, float3 position, float radius){

                float t = 0.0;
                for (int i = 0; i < 100; i++) // Max steps
                {
                    float3 p = ro + t * rd;
                    float dist = sphereSDF(p, position, radius);
                    if (dist < threshold) return t;
                    t += dist; // Move forward based on the distance to the surface
                }
                return -1.0; // If no intersection found

/*
                if(rd.x < 0.5){
                    return 1;
                }
                return 0;*/
            }

            fixed4 frag (v2f i) : SV_Target
            {
                // Ray origin (camera position) and ray direction (screen space direction)
                float3 ro = _WorldSpaceCameraPos;
                float3 rd = normalize(i.vertex.xyz);

                // Metaball positions and radii
                /*float3 positions[3] = {float3(0, 0, 0), float3(1, 1, 1), float3(-1, -1, -1)};
                float radii[3] = {0.5, 0.5, 0.5};
                */
                /*
                float3 position = float3(0,0,0);
                float radius = 2;
                float threshold = _Threshold;*/

                // Perform raymarching

                return sphereSDF(_WorldSpaceCameraPos, _Position, _Radius);
                
                float t = Raymarch(ro, rd, _Threshold, _Position, _Radius);
                if(t > 0){
                    //t = 1;
                }
                return(fixed4(t,t,t,1));

                if (t > 0.0)
                {
                    return fixed4(t, 0, 0, 1); // Render metaball in red color
                }else if(t == -1.0){
                    return fixed4(0, 1, 0, 1);
                }
                return fixed4(0, 0, 0, 1); // Background (black)
                
            }
            ENDCG
        }
    }
}
