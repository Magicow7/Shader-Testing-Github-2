Shader "Custom/Test2"

//this was a simple shader that just takes two colors and blends them.
{
    Properties
    {
        // Color property for material inspector, default to white
        _Color1 ("Main Color", Color) = (1,0,1,1)
        _Color2 ("Secondary Color", Color) = (1,1,0,1)
    }
    SubShader
    {
        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            float4 vert (float4 vertex : POSITION) : SV_POSITION
            {
                return UnityObjectToClipPos(vertex);
            }

             // color from the material
            fixed4 _Color1;
            fixed4 _Color2;

            // pixel shader, no inputs needed
            fixed4 frag () : SV_Target
            {
                return _Color1+_Color2;
            }
            ENDCG
        }
    }
}
