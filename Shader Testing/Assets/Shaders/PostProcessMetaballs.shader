Shader "Custom/PostProcessMetaballs"
{
    Properties
    {
        _MainTex ("Base (RGB)", 2D) = "white" {}
        _Threshold ("Threshold", Float) = 1.0
        //_NumMetaballs ("Number of Metaballs", Int) = 3
        //_MetaballPositions ("Metaball Positions", Vector) = (0, 0, 0, 0)
        _Position ("Metaball 1 position", Vector) = (0,0,0)
        _Radius ("Metaball 1 radius", Float) = 2.0

        _Position2 ("Metaball 1 position", Vector) = (0,0,0)
        _Radius2 ("Metaball 1 radius", Float) = 2.0

        _MeldTolerance ("Meld Tolerance", Float) = 1.0

       // _InverseViewMatrix ("Inverse View Matrix", Matrix) = ""
        //_InverseProjMatrix ("Inverse Projection Matrix", Matrix) = ""
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
                float4 vertex : SV_POSITION;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            float _Threshold;
            Vector _Position;
            float _Radius;
            Vector _Position2;
            float _Radius2;
            float _MeldTolerance;

            float4x4 _InverseViewMatrix;
            float4x4 _InverseProjMatrix;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                return o;
            }

            float3 getRayDirection(float2 uv, float4x4 invProj, float4x4 invView)
            {
                // Transform UV into normalized device coordinates (-1 to 1 range)
                float4 clipPos = float4(uv * 2.0 - 1.0, 0, 1); // UV -> NDC

                // Transform into view space (from clip space)
                float4 viewPos = mul(invProj, clipPos);
                viewPos /= viewPos.w; // Perspective divide

                // Now transform from view space to world space
                float4 worldPos = mul(invView, viewPos);

                // Ray direction from camera (in world space)
                float3 rayDir = normalize(worldPos.xyz);

                return rayDir;
            }

            //there are multiple ways to do smoothmin, this is just one using the square root method
            //found here https://iquilezles.org/articles/smin/
            //the square root method made both object grow when they were overlapping, so I'm switching to a different method
            /*
            float SmoothMin(float a, float b, float k )
            {
                k *= 2.0;
                float x = b-a;
                return 0.5*( a+b-sqrt(x*x+k*k) );
            }*/
            //this is the circular geometrical method
            float SmoothMin( float a, float b, float k )
            {
                k *= 1.0/(1.0-sqrt(0.5));
                float h = max( k-abs(a-b), 0.0 )/k;
                return min(a,b) - k*0.5*(1.0+h-sqrt(1.0-h*(h-2.0)));
            }



            // Helper functions for raymarching
            float sphereSDF(float3 p, float3 center, float radius, float3 center2, float radius2)
            {
                float dist1 = length(p - center) - radius;
                float dist2 = length(p - center2) - radius2;

                //return min(dist1, dist2);
                return SmoothMin(dist1, dist2, _MeldTolerance);
                //return min(SmoothMin(dist1, dist2, _MeldTolerance), min(dist1, dist2));
                /*
                float sum = 0.0;
                float dist = length(p - center) - radius;
                sum += exp(-dist * dist);
                dist = length(p - center2) - radius2;
                sum += exp(-dist * dist);

                return sum;*/
            }

            float Raymarch(float3 ro, float3 rd, float threshold, float3 position, float radius){

                float t = 0.0;
                for (int i = 0; i < 100; i++) // Max steps
                {
                    float3 p = ro + t * rd;
                    float dist = sphereSDF(p, _Position, _Radius,_Position2, _Radius2);
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
                float3 rd = getRayDirection(i.uv, _InverseProjMatrix, _InverseViewMatrix);

                // Perform raymarching
                float t = Raymarch(ro, rd, _Threshold, _Position, _Radius);
                if (t > 0.0)
                {
                    return fixed4(t, 0, 0, 1); // Render metaball in red color
                }
                return fixed4(0, 0, 0, 1); // Background (black)
            }
            ENDCG
        }
    }
}
