Shader "Custom/ArrayMetaBallsPostProcess"
{
    Properties
    {
        _MainTex ("Base (RGB)", 2D) = "white" {}
        _MetaballColor ("Metaball Color", Color) = (1.0,0.0,0.0,0.0)
        _OutlineColor ("Outline Color", Color) = (1.0,1.0,1.0,0.0)
        _Threshold ("Threshold", Float) = 1.0
        _MeldTolerance ("Meld Tolerance", Float) = 1.0
        _GlowThresholds ("Glow threshold min and max (z,w discarded)", Vector) = (2.0,15.0,0.0,0.0)

       // _InverseViewMatrix ("Inverse View Matrix", Matrix) = ""
        //_InverseProjMatrix ("Inverse Projection Matrix", Matrix) = ""
        //_Metaball2Position ("Metaball 2 position", Vector) = (0,0,0)
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 200

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
            float4 _MetaballColor;
            float4 _OutlineColor;
            float _Threshold;
            Vector _Position;
            float _Radius;
            Vector _Position2;
            float _Radius2;
            float _MeldTolerance;
            float4 _GlowThresholds;
            //MAKE SURE THE ARRAY LENGTH MATCHES THAT IN THE C# SCRIPT
            #define MAX_ARRAY_LENGTH 50 
            float4 _MetaballPositions[MAX_ARRAY_LENGTH];
            float _MetaballRadii[MAX_ARRAY_LENGTH];
            int _MetaballCount;

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
            //this is the circular method
            float SmoothMin( float a, float b, float k )
            {
                k *= 1.0/(1.0-sqrt(0.5));
                float h = max( k-abs(a-b), 0.0 )/k;
                return min(a,b) - k*0.5*(1.0+h-sqrt(1.0-h*(h-2.0)));
            }

            float SphereSDF(float3 p, float3 center, float3 radius){
                return length(p - center) - radius;
            }

            // Helper functions for raymarching
            float MetaballsSDF(float3 p)
            {
                //return SphereSDF(p,float3(0,0,0),2);
                float accumulator = SphereSDF(p, _MetaballPositions[0], _MetaballRadii[0]);
                //return accumulator;
                for(int i = 1; i < _MetaballCount; i++){
                    //this handles extra array elements
                    float newSDF = SphereSDF(p, _MetaballPositions[i], _MetaballRadii[i]);
                    accumulator = SmoothMin(accumulator, newSDF, _MeldTolerance);
                    
                }

                //return min(dist1, dist2);
                return accumulator;
                //return min(SmoothMin(dist1, dist2, _MeldTolerance), min(dist1, dist2));
            }
            //returns a float2 with the final distance in x and the minimum dist in y
            float2 Raymarch(float3 ro, float3 rd, float threshold){

                float t = 0.0;
                float minDist = 100;//arbitrary big number
                for (int i = 0; i < 100; i++) // Max steps
                {
                    float3 p = ro + t * rd;
                    float dist = MetaballsSDF(p);
                    minDist = min(minDist, dist);
                    if (dist < threshold) return float2(t,0);
                    t += dist; // Move forward based on the distance to the surface
                }
                //try changing 0 to negative 1 if issues
                return float2(0,minDist); // If no intersection found

                /*
                if(rd.x < 0.5){
                    return 1;
                }
                return 0;*/
            }

            fixed4 frag (v2f i) : SV_Target
            {
                fixed4 originalColor = tex2D(_MainTex, i.uv);
                // Ray origin (camera position) and ray direction (screen space direction)
                float3 ro = _WorldSpaceCameraPos;
                float3 rd = getRayDirection(i.uv, _InverseProjMatrix, _InverseViewMatrix);

                //return fixed4(_MetaballRadii[0],0,0,1);

                // Perform raymarching
                float2 t = Raymarch(ro, rd, _Threshold);
                float v = clamp(t.x,0,1);
                float glowAmount = 0;
                if(t.y < _GlowThresholds.y){
                    glowAmount = 1-smoothstep(_GlowThresholds.x,_GlowThresholds.y,t.y);
                }

                fixed4 returnColor;
                //draw outline first
                /*if(v == 0 && _OutlineColor.a != 0)
                {*/
                    fixed4 temp =  _OutlineColor;
                    temp.a *= glowAmount;
                    returnColor = temp;
                //}\
                //draw ball ontop
                if(v != 0){
                    returnColor = _MetaballColor * v;
                }

                //draw scene
                return returnColor * returnColor.a + originalColor *(1-returnColor.a);
                if(v == 0){
                    return originalColor;
                }else{
                    return returnColor;
                }
                
                
            }
            ENDCG
        }
    }
}