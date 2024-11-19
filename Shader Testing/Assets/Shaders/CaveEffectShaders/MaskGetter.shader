Shader "CaveEffects/MaskGetter"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _Position ("Metaball 1 position", Vector) = (0,0,0)
        _Radius ("Metaball 1 radius", Float) = 2.0
        _CircleDepth("Metaball 1 depth", Float) = 1.0
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
                float4 ray : TEXCOORD1;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                UNITY_FOG_COORDS(1)
                float4 vertex : SV_POSITION;
                float4 interpolatedRay : TEXCOORD1;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            Vector _Position;
            float _Radius;
            float _CircleDepth;
            sampler2D _CameraDepthTexture;

            float4x4 _InvViewMatrix;
            float4x4 _InvProjMatrix;
            float4x4 _ViewProjMatrix;
            float4x4 _ScreenToWorldSpaceMatrix;

            #define MAX_ARRAY_LENGTH 50 
            //in uv space
            float4 _BoidPositions[MAX_ARRAY_LENGTH];
            //in world space
            float4 _BoidScreenPositions[MAX_ARRAY_LENGTH];
            int _BoidCount;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                o.interpolatedRay = v.ray;
                UNITY_TRANSFER_FOG(o,o.vertex);
                //o.viewDir = mul (unity_CameraInvProjection, float4 (o.uv * 2.0 - 1.0, 1.0, 1.0));
                return o;
            }
            /*
            float CalculateDepth(float3 worldPoint, float4x4 viewProjectionMatrix)
            {
                // Transform the world-space point to clip space
                float4 clipSpacePoint = mul(viewProjectionMatrix, float4(worldPoint, 1.0));
                
                // Normalize to NDC by dividing by w
                float ndcZ = clipSpacePoint.z / clipSpacePoint.w;
                
                // Convert from NDC range [-1, 1] to depth buffer range [0, 1]
                float depthBufferValue = 0.5 * (ndcZ + 1.0);
                return depthBufferValue;
            }

            

            float2 ClipToUV(float4 clipSpacePoint)
            {
                
                // Step 2: Normalize to NDC by dividing by w
                float2 ndc = clipSpacePoint.xy / clipSpacePoint.w;
                
                // Step 3: Map from NDC [-1, 1] to UV space [0, 1]
                float2 uv = 0.5 * (ndc + float2(1.0, 1.0));
                
                return uv;
                
            }

            float4 WorldToClip(float3 worldPoint, float4x4 viewProjectionMatrix)
            {
                // Step 1: Transform the world-space point to clip space
                float4 clipSpacePoint = mul(viewProjectionMatrix, float4(worldPoint, 1.0));
                return clipSpacePoint;
                
            }

            float4 WSPositionFromDepth(float2 uv, float depth)
            {
               // Step 3: Convert UV to normalized device coordinates (NDC)
                float2 ndc = uv * 2.0 - 1.0; // Convert [0,1] to [-1,1]

                // Step 4: Calculate the world position using the depth value
                float4 clipSpacePosition = float4(ndc.x, ndc.y, depth, 1.0);
                float4 viewSpacePosition = mul(_ScreenToWorldSpaceMatrix, clipSpacePosition);
                viewSpacePosition /= viewSpacePosition.w; // Homogeneous divide

                // Now `viewSpacePosition` contains the world position
                return float4(viewSpacePosition.xyz, 1.0); // You may return this position or process it further
            }*/

            //source: https://stackoverflow.com/questions/32227283/getting-world-position-from-depth-buffer-value
            float3 WorldPosFromDepth(float depth, float2 uv) {
                float z = depth * 2.0 - 1.0;

                float4 clipSpacePosition = float4(uv * 2.0 - 1.0, z, 1.0);
                float4 viewSpacePosition = mul(_InvProjMatrix, clipSpacePosition);

                // Perspective division
                viewSpacePosition /= viewSpacePosition.w;

                float4 worldSpacePosition = mul(_InvViewMatrix, viewSpacePosition);

                return worldSpacePosition.xyz;
            }


            

            fixed4 frag (v2f i) : SV_Target
            {               
                return fixed4(1,0,0,1);
                //return _BoidPositions[0].z; 
                //return fixed4(1,0,0,1);
                //float3 ro = _WorldSpaceCameraPos;
                //Depth needs mroe than 2 color chanels worth of data, so we give it the red and green channel, and decode it to a float here
                float depth = DecodeFloatRG(tex2D(_CameraDepthTexture, i.uv));
                    return depth;
                    /*
                float3 depthWorldPos = WorldPosFromDepth(depth, i.uv);
                return depthWorldPos.z;
                if(distance(depthWorldPos,_WorldSpaceCameraPos) < 5){
                    return 1;
                }
                return 0;*/
                //return depthWorldPos.y;

                //return depth;
                
                float linearDepth = Linear01Depth(depth);
                float4 wsDir = linearDepth * i.interpolatedRay;
				float3 wsPos = _WorldSpaceCameraPos + wsDir;
                return i.interpolatedRay.x;
                return wsPos.x;
                
                //return depth;
                //float3 viewPos = (i.viewDir.xyz / i.viewDir.w) * depth;
                //float backgroundDist = length (viewPos);
                /*
                if(backgroundDist > _Position.x){
                    return 1;
                }*/
                //return 0;
                //return backgroundDist;
                //return length (viewPos);
                //return depth;
                //float4 screenPosition = float4(i.uv, depth, 1.0);
                //for depth position
                /*
                float4 depthWorldPosition = WSPositionFromDepth(i.uv, depth);//mul(_ScreenToWorldSpaceMatrix, screenPosition);
                if(depthWorldPosition.z > -5){
                    return 1;
                }*/
                //return 0;
                //return depthWorldPosition.z;
                /*
                float temp = 0;
                //return depthWorldPosition.x;
                if(backgroundDist > distance(_BoidPositions[0].xyz, ro)){
                    temp = 1;
                    //return depthWorldPosition.x;
                }
                return temp;
                //return temp;
                //return _BoidPositions[0].z;

                float2 centerPoint = _BoidScreenPositions[0].xy;
                float uvRadius = length(centerPoint - _BoidScreenPositions[0].zw);
                float distance = length(i.uv - centerPoint);
                //if(!visible){}
                if(distance < uvRadius){
                    return fixed4(1,temp,0,1);
                }
                return depth;*/

                //get boid position in uv space
                /*
                float4 BoidclipPoint = WorldToClip(_BoidPositions[0], _ViewProjMatrix);
                float2 BoiduvPoint = ClipToUV(BoidclipPoint);
                if(BoiduvPoint.x > 1){
                    return 0;
                }
                return 1;


                float tempRadius = 0;//_BoidRadii[0].w;
                float4 BoidEdgeWorldPoint = _BoidPositions[0] + fixed4(_BoidRadii[0].x * tempRadius,_BoidRadii[0].y * tempRadius, _BoidRadii[0].z * tempRadius, 0);
                float4 BoidEdgeclipPoint = WorldToClip(BoidEdgeWorldPoint.xyz, _ViewProjMatrix);
                float2 BoidEdgeuvPoint = ClipToUV(BoidEdgeclipPoint);
                float uvRadius = length(BoiduvPoint-BoidEdgeuvPoint);
                
                float distance = length(i.uv - BoiduvPoint);
                
                if(distance < uvRadius){
                    return 1;
                }
                return 0;
                //return fixed4(distance,distance,distance,1);
                distance = step(_BoidRadii[0].w, distance);

                fixed4 onCol = fixed4(1,1,1,1);
                fixed4 offCol = fixed4(0,0,0,1);
                fixed4 finalCol = offCol * distance + onCol * (1-distance);
                float visible = 1;//step(depth,-_BoidPositions[0].z);
                //return _BoidPositions[0].z;
                //return temp;
                return visible * finalCol * temp;

                //return finalCol;
                // Sample the depth texture at the pixel's UV coordinates
                
                

                // Linearize the depth to make it visible
                //float linearDepth = Linear01Depth(depth);

                // Display depth as grayscale
                //return fixed4(1,1,depth,1);
                //return float4(depth, depth, depth, 1.0);
                */
            }
            ENDCG
        }
    }
}
