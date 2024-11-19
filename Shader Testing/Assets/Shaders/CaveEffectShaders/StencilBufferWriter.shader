Shader "CaveEffects/StencilBufferWriter"
{
    Properties
    {
        _Color ("Color", Color) = (1,1,1,1)
        _StencilRef ("Stencil Reference Value", Range(1, 255)) = 1 // Default value
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" "Queue"="Geometry-2"}
        
        Pass
        {
            // Write to the stencil buffer
            Stencil
            {
                Ref [_StencilRef]        // Reference value to write to stencil
                Comp always   // Always pass stencil test
                Pass replace  // Replace stencil buffer value with Ref
            }

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"
            
            struct appdata
            {
                float4 vertex : POSITION;
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
            };

            float4 _Color;

            v2f vert (appdata v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                return _Color;
            }
            ENDCG
        }
    }
    FallBack "Diffuse"
}