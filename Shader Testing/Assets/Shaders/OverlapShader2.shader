Shader "Custom/OverlapShader2"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _SecondayTex ("Texture", 2D) = "white" {}
        _MinBounds ("Min Bounds", Vector) = (0, 0, -1, 0)
        _MaxBounds ("Max Bounds", Vector) = (1, 1.42, 1, 0)
        _Color ("Color (RGBA)", Color) = (1, 1, 1, 1)
        _Color2 ("Color2 (RGBA)", Color) = (1, 1, 0, 1)
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
                //float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
                float4 projPos : TEXCOORD0; 
                float3 camRelativeWorldPos : TEXCOORD1;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            sampler2D _SecondaryTex;
            float4 _SecondaryTex_ST;
            float4 _Color;
            float4 _Color2;
            float4 _MinBounds;
            float4 _MaxBounds;

            UNITY_DECLARE_DEPTH_TEXTURE(_CameraDepthTexture);

            v2f vert (appdata v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.projPos = ComputeScreenPos(o.pos);
                o.camRelativeWorldPos = mul(unity_ObjectToWorld, float4(v.vertex.xyz, 1.0)).xyz - _WorldSpaceCameraPos;
                return o;
            }

            
            bool depthIsNotSky(float depth)
            {
                #if defined(UNITY_REVERSED_Z)
                return (depth > 0.0);
                #else
                return (depth < 1.0);
                #endif
            }

            fixed4 frag (v2f i) : SV_Target
            {
                float2 screenUV = i.projPos.xy / i.projPos.w;

                // sample depth texture
                float depth = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, screenUV);

                // get linear depth from the depth
                float sceneZ = LinearEyeDepth(depth);

                // calculate the view plane vector
                // note: Something like normalize(i.camRelativeWorldPos.xyz) is what you'll see other
                // examples do, but that is wrong! You need a vector that at a 1 unit view depth, not
                // a1 unit magnitude.
                float3 viewPlane = i.camRelativeWorldPos.xyz / dot(i.camRelativeWorldPos.xyz, unity_WorldToCamera._m20_m21_m22);

                // calculate the world position
                // multiply the view plane by the linear depth to get the camera relative world space position
                // add the world space camera position to get the world space position from the depth texture
                float3 worldPos = viewPlane * sceneZ + _WorldSpaceCameraPos;
                worldPos = mul(unity_CameraToWorld, float4(worldPos, 1.0));

                half4 col = _Color;
                //if(all(worldPos >= _MinBounds.xyz) && all(worldPos <= _MaxBounds.xyz)){
                if(worldPos.y > 0){
                    col = _Color2;
                }
                return col;
            }
            ENDCG
        }
    }
}
