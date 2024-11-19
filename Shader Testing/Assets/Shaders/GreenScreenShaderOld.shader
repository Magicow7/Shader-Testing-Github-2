Shader "Custom/GreenScreenShaderOld" {
	Properties{
		_BaseColor("BaseColor", Color) = (1,1,1,1)
		_MainTex("MainTex", 2D) = "white" {}
        _BackgroundTex("BackgroundTex", 2D) = "white" {}
		
		[KeywordEnum(YCbCr, YIQ)][Tooltip(Color Space for Chroma delta)]
		_ColorSpace("ColorSpace", Float) = 0
		_KeyColor("KeyColor", Color) = (0,1,0,1)
		_DChroma("DChroma", range(0.0, 1.0)) = 0.5
		_DChromaT("DChroma Tolerance", range(0.0, 1.0)) = 0.05
        
        [KeywordEnum(Auto, Manual)][Tooltip(Mode for Luma delta)]
        _LumaMode("LumaMode", Float) = 0
        [ShowIfKeyword(_LUMAMODE_MANUAL)]
		_DLuma("DLuma", range(0.0, 1.0)) = 0.5
		[ShowIfKeyword(_LUMAMODE_MANUAL)]
		_DLumaT("DLuma Tolerance", range(0.0, 1.0)) = 0.05
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
	half _DChroma;
	half _DChromaT;
	half _DLuma;
	half _DLumaT;
	
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

	half4 frag(v2f input) : SV_Target {
        //main tex color
		half4 c = tex2D(_MainTex, input.uv);
        //background tex color
        half4 b = tex2D(_BackgroundTex, input.uv);
		
        //half ratio = 0;
		if (c.a > 0) {
			#ifdef _LUMAMODE_AUTO
				_DLuma = _DChroma;
				_DLumaT = _DChromaT;
            #endif
			
			//YCBCR is for digital displays, YIQ is for ANALOG
            
		    #ifdef _COLORSPACE_YCBCR
				c = ApplyChromaKeyAlphaYCbCr(c, _KeyColor.rgb, _DChroma, _DChromaT, _DLuma, _DLumaT);
            #elif _COLORSPACE_YIQ
                c = ApplyChromaKeyAlphaYIQ(c, _KeyColor.rgb, _DChroma, _DChromaT, _DLuma, _DLumaT);
            #endif
            
            //custom ratio getter
            //ratio = GetRatio()
		}

        //if alpha isn't 1
        half4 finalColor = half4(c.rgb * c.a + b.rgb * (1-c.a),1);
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