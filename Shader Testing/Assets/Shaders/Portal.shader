Shader "Custom/Portal"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _Color ("_Color", Color) = (1,0,1,1)
    }
    SubShader
    {
        //these tags tell the render pipeline how to treat this shader
        //queue is where in the order to draw this
        //ingoreprojector stops object from being affected by projectors, not sure what projectors are tho
        //render type is just a catagorization
        Tags {"Queue"="Transparent" "IgnoreProjector"="True" "RenderType"="Transparent"}
        //writing to the z-buffer is disabled
        ZWrite Off
        //blend determines how the gpu  combines the output of the frag shader with the render target
        //this set the blend mode to be able to handle transparent objects
        //look at blend documentation for more
        Blend SrcAlpha OneMinusSrcAlpha

        //cull front says we should cull things facing the camera, which doesn't make much sense because then we couldn't see anything
        //changing it to back doesn't change anything that I can tell so idk about this one.
        Cull front 
        //lod specifies what order to do subshaders in, lower numbers go first.
        LOD 100

        Pass
        {
            //apparently this is a leftover from when unity shaders didn't use HLSL and used something called CG instead, this is changed to HLSLPROGRAM when compiled
            CGPROGRAM
            //pragma are preprocessor directives before compilation, used to specify gpu functionality needed by this shader, aparently HLSL calls in pixel instead of fragment
            //this is probably another leftover from the olden days.
            #pragma vertex vert alpha
            #pragma fragment frag alpha
            #pragma multi_compile_fog

            //a collection of helper functions such as screen position, UnityObjectToClipPos, UnityObjectToViewPos
            #include "UnityCG.cginc"

            //the appdata struct seems to have some default versions included in the include above, but we make a custom one, not sure why. but I know this is the type the
            //data gets passed from the cpu to the gpu in.
            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            //v2f is vertex to fragment, and is the datatype was pass into the frag shader
            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 screenPos : TEXCOORD1;
                UNITY_FOG_COORDS(1)
                float4 vertex : SV_POSITION;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                o.screenPos = ComputeScreenPos(o.vertex);
                return o;
            }

            fixed4 _Color;


            fixed4 frag (v2f i) : SV_Target
            {
                // sample the texture
                //w is the distance of the point
                float2 screenSpaceUV = i.screenPos.xy / i.screenPos.w;
                //float2 screenSpaceUV = i.screenPos.xy;
                fixed4 col = tex2D(_MainTex, screenSpaceUV);
                float2 newUV = i.uv - 0.5;
                float d = 1-length(newUV);
                d =  smoothstep(0.5, 0.6, d);
                col.a = clamp(d,0,1);
                return col;
    
            }
            ENDCG
        }

    }
}

