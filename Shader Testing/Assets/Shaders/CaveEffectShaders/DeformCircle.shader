Shader "Custom/DeformCircle"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _Frequency ("Distortion Frequency", Float) = 5.0
        _DistortionStrength ("Distortion Strength", Float) = 0.1
        _CirclePos ("Circle Pos", Vector) = (0,0,0,0)
        _CircleRad ("Circle Rad", float) = 1.0
        _Scariness ("Scariness", float) = 1

    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        {
            CGPROGRAM
            /*THIS GOT ADDED FOR NO REASON AND BROKE EVERYTHING RAHG
// Upgrade NOTE: excluded shader from DX11, OpenGL ES 2.0 because it uses unsized arrays
#pragma exclude_renderers d3d11 gles*/
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
            float4 _MainTex_TexelSize;
            float _Frequency;
            float _DistortionStrength;
            float2 _CirclePos;
            float _CircleRad;
            float _Scariness;
            //max 50 circles on screen
            #define MAX_ARRAY_LENGTH 50 
            float2 _CirclePositions[MAX_ARRAY_LENGTH];
            float _CircleRadii[MAX_ARRAY_LENGTH];
            int _CircleCount;
            StructuredBuffer<uint> ResultBuffer;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                UNITY_TRANSFER_FOG(o,o.vertex);
                return o;
            }
            /*
            float2 hash(float2 p)
            {
                p = float2(dot(p, float2(127.1, 311.7)), dot(p, float2(269.5, 183.3)));
                return frac(sin(p) * 43758.5453);
            }

            
            // Simple Perlin Noise function approximation
            float PerlinNoise(float2 p)
            {
                float2 i = floor(p);
                float2 f = frac(p);

                // Smooth curve
                f = f * f * (3.0 - 2.0 * f);

                // Random hash function for grid points
                float a = dot(hash(i), f - float2(0.0, 0.0));
                float b = dot(hash(i + float2(1.0, 0.0)), f - float2(1.0, 0.0));
                float c = dot(hash(i + float2(0.0, 1.0)), f - float2(0.0, 1.0));
                float d = dot(hash(i + float2(1.0, 1.0)), f - float2(1.0, 1.0));

                // Linear interpolation
                return lerp(lerp(a, b, f.x), lerp(c, d, f.x), f.y);
            }*/

            float2 CircularDistortion(float2 center, float2 uv, float strength, float frequency)
            {
                
                // Calculate direction and distance to center
                float2 dir = uv - center;
                float distance = length(dir);
                
                // Normalize the direction
                dir = normalize(dir);
                return uv * (dir * strength);

                // Create a radial wave effect using sine function
                float offset = sin(distance * frequency) * strength;
                
                // Apply the offset along the direction vector
                return uv - dir * offset;
            }

            float3 DecodeData(uint number){
                float rad = (number >> (32-10)) & 0x3FF;
                //get in worlds
                float yPos = (float)((number >> (32-21)) & 0x3FF);///maskRT.height;
                float xPos = (float)((number >> (32-32)) & 0x3FF);///maskRT.width;
                //to avoid weird feet artifact cull small circles
                if(rad <= 3){
                    rad = 0;
                    yPos = 0;
                    xPos = 0;
                }
                return float3(xPos, yPos, rad);
            }

            

            fixed4 frag (v2f i) : SV_Target
            {
                //decode data from compute shader
                //x in x, y in y, rad in z

                //return float4(0,1,0,1);
                /*
                int3[] decodedPosAndRad = Vector2[_CircleCount];
                for(int i = 0; i < _CircleCount; i++){
                    decodedPosAndRad[i] = DecodeData(ResultBuffer[i]);
                }
                return float4(_CircleCount,1,0,1);*/
                
                //return ResultBuffer[9];
                float distortionStrength = _DistortionStrength * _Scariness;
                //get distance to point in uv
                // Screen space resolution
                float2 textureSize = _MainTex_TexelSize.zw;

                // Calculate pixel position (in pixels)
                float2 pixelPos = i.uv * textureSize;

                //float2 center =  _CirclePos.xy+float2(0.5, 0.5);
                int3 decodedPosAndRad = DecodeData(ResultBuffer[0]);
                //return float4(decodedPosAndRad.r, decodedPosAndRad.g, decodedPosAndRad.b, 1);
                float distance = length(pixelPos - decodedPosAndRad.xy);
                int respectiveCircleIndex = 0;
                for(int j = 1; j < _CircleCount; j++){
                    decodedPosAndRad = DecodeData(ResultBuffer[j]);
                    float temp = length(pixelPos - decodedPosAndRad.xy);
                    if(temp < distance){
                        respectiveCircleIndex = j;
                        distance = temp;
                    }
                }
                decodedPosAndRad = DecodeData(ResultBuffer[respectiveCircleIndex]);
                float2 choosenCirclePos = decodedPosAndRad.xy;
                //abritrarily add to radius to make circles closer to eachother
                float choosenCircleRad = decodedPosAndRad.z + 10;
                //return float4(choosenCirclePos.x, choosenCirclePos.y, choosenCircleRad, 1);

                distance = smoothstep(0,choosenCircleRad,distance);
                //return distance;//float4(i.uv.x,pixelPos.y*_MainTex_TexelSize.y,0,1);    

                // Apply Perlin noise to the UVs
                float2 noiseUV = i.uv * _Frequency;
                //float2 noiseOffset = float2(PerlinNoise(noiseUV), PerlinNoise(noiseUV + float2(5.2, 1.3)));
                float2 noiseOffset = CircularDistortion(choosenCirclePos*_MainTex_TexelSize.xy, i.uv,distortionStrength, _Frequency);
                noiseOffset *= distortionStrength * (1-distance);

                // Sample the texture with distorted UVs
                float2 distortedUV = i.uv + noiseOffset;
                fixed4 discol = tex2D(_MainTex, distortedUV);
                //fixed4 col = tex2D(_MainTex, i.uv);
                
                return discol;

                //return distance;
                //col = col * distance + discol * (1-distance);
                // apply fog
                //return col;
            }
            ENDCG
        }
    }
}
