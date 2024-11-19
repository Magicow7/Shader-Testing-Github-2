Shader "Custom/OverlapShader3"
{
	Properties
	{
		_Color ("Color (RGBA)", Color) = (1, 1, 1, 1)
        _Color2 ("Color2 (RGBA)", Color) = (1, 1, 0, 1)
	}

	SubShader
	{
		Cull Off ZTest Always

		Pass
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#pragma target 5.0
			
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

			float4x4 clipToWorld;
			sampler2D_float _CameraDepthTexture;
			float4 _CameraDepthTexture_ST;

            float4 _Color;
            float4 _Color2;

			v2f vert (appdata v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.uv = v.uv;
				return o;
			}

			float4 ComputeClipSpacePosition(float2 positionNDC, float deviceDepth)
			{
				float4 positionCS = float4(positionNDC * 2.0 - 1.0, deviceDepth, 1.0);
				/*#if UNITY_UV_STARTS_AT_TOP
				positionCS.y = -positionCS.y;
				#endif*/
				return positionCS;
			}

			float3 ComputeWorldSpacePosition(float2 positionNDC, float deviceDepth, float4x4 invViewProjMatrix)
			{
				float4 positionCS = ComputeClipSpacePosition(positionNDC, deviceDepth);
				float4 hpositionWS = mul(invViewProjMatrix, positionCS);
				return hpositionWS.xyz / hpositionWS.w;
			}

			float4 frag (v2f i) : SV_Target
			{
				float depth = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, i.uv.xy);
				#if defined(SHADER_API_GLES) || defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)
				depth = (depth * 2.0) - 1.0;
				#endif
				float3 worldspace = ComputeWorldSpacePosition(i.uv.xy, depth, clipToWorld);
				
                half4 col = _Color;
                //if(all(worldPos >= _MinBounds.xyz) && all(worldPos <= _MaxBounds.xyz)){
                if(worldspace.y > 0){//d){
                    col = _Color2;
                }
                return col;
			}
			ENDCG
		}
	}
}