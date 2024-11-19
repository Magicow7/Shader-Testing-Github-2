Shader "Custom/ChromaKeySecondAttempt"
{
    //I need to make a new version that uses hue, saturation a lightness
	Properties{
		_BaseColor("BaseColor", Color) = (1,1,1,1)
		_MainTex("MainTex", 2D) = "white" {}
        _BackgroundTex("BackgroundTex", 2D) = "white" {}
		
		[KeywordEnum(YCbCr, YIQ)][Tooltip(Color Space for Chroma delta)]
		_ColorSpace("ColorSpace", Float) = 0
		_KeyColor("KeyColor", Color) = (0,1,0,1)
        _KeyColorRange("KeyColorRange", Color) = (0,0,0,1)
    
	}
	
	CGINCLUDE
	#include "UnityCG.cginc"
	#include "Assets/Nexweron/Common/Shaders/Builtin/ChromaKey/ChromaKey.hlsl"

	sampler2D _MainTex;
	half4 _MainTex_ST;
    sampler2D _BackgroundTex;
	half4 _BackgroundTex_ST;
	half4 _BaseColor;
	half4 _KeyColor;
    half4 _KeyColorRange;
	
	struct v2f {
		half2 uv : TEXCOORD0;
        half4 vertex : SV_POSITION;
	};
	
	v2f vert(appdata_base input) {
		v2f o;
		o.vertex = UnityObjectToClipPos(input.vertex);
		o.uv = TRANSFORM_TEX(input.texcoord, _MainTex);
		return o;
	}

    half GetRatio(half4 inColor, half4 KeyColor, half3 ColorCubeParams){
        half4 cube = half4(ColorCubeParams.r,ColorCubeParams.g, ColorCubeParams.b,0);
        half4 clampedColor = clamp(inColor, KeyColor - cube, KeyColor + cube);
        //THE ALL WAS THE ISSUE
        return all(clampedColor == inColor) ? 0 : 1;
    }

	half4 frag(v2f input) : SV_Target {
        //main tex color
		half4 c = tex2D(_MainTex, input.uv);
        //background tex color
        half4 b = tex2D(_BackgroundTex, input.uv);
        //all is used to test all values, not just r, g, or b
        //this was the issue in last version
        half mask = GetRatio(c,_KeyColor, _KeyColorRange.rgb);
  

        half4 finalColor = c * mask + b * (1-mask);
        finalColor = half4(mask,mask,mask,1);
		return finalColor;
	}
	ENDCG
	
    //not really sure what this subshader was here for, try deleting it and see what happens later
	SubShader {
		Tags{ "Queue" = "Transparent" "RenderType" = "Transparent" "IgnoreProjector" = "True" }
		Lighting Off
		AlphaTest Off
		ZWrite Off
		
		Blend SrcAlpha OneMinusSrcAlpha, One Zero

		Pass {
			CGPROGRAM
			    #pragma multi_compile _COLORSPACE_YCBCR _COLORSPACE_YIQ
				#pragma multi_compile _LUMAMODE_AUTO _LUMAMODE_MANUAL
				#pragma vertex vert
				#pragma fragment frag
				#pragma fragmentoption ARB_precision_hint_fastest
			ENDCG
		}
	}
	
	Fallback Off
}
