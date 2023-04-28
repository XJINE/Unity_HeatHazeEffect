Shader "Unlit/HeatHaze"
{
    Properties
    {
        _Speed   ("Speed",    Float) = 0.1
        _Strength("Strength", Float) = 0.1
        _Complex ("Complex",  Float) = 5
    }
    SubShader
    {
        Tags
        {
            // NOTE:
            // This effect must be placed at the end of the RenderQueue.
            "Queue" = "Transparent"
        }

        ZTest Always

        GrabPass
        {
            "_GrabPassTex"
        }
        Pass
        {
            CGPROGRAM

            #pragma vertex   vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            struct v2f
            {
                float4 vertex : SV_POSITION;
                float4 uvGrab : TEXCOORD0;
                float2 uv     : TEXCOORD1;
            };

            sampler2D _GrabPassTex;

            float _Speed;
            float _Strength;
            float _Complex;

            float random(float2 seeds)
            {
                return frac(sin(dot(seeds, float2(12.9898, 78.233))) * 43758.5453);
            }

            float perlinNoise(float2 seeds) 
            {
                float2 p = floor(seeds);
                float2 f = frac (seeds);
                float2 u = f * f * (3.0 - 2.0 * f);

                float v00 = random(p + float2(0,0));
                float v10 = random(p + float2(1,0));
                float v01 = random(p + float2(0,1));
                float v11 = random(p + float2(1,1));

                return lerp(lerp(dot(v00, f - float2(0,0)), dot(v10, f - float2(1,0)), u.x),
                            lerp(dot(v01, f - float2(0,1)), dot(v11, f - float2(1,1)), u.x), 
                            u.y) + 0.5;
            }

            v2f vert (appdata_full v)
            {
                v2f o;

                float3 vpos       = mul((float3x3)unity_ObjectToWorld, v.vertex.xyz);
                float4 worldCoord = float4(unity_ObjectToWorld._m03, unity_ObjectToWorld._m13, unity_ObjectToWorld._m23, 1);
                float4 viewPos    = mul(UNITY_MATRIX_V, worldCoord) + float4(vpos, 0);

                o.vertex = mul(UNITY_MATRIX_P, viewPos);
                o.uvGrab = ComputeGrabScreenPos(o.vertex);
                o.uv     = v.texcoord;

                return o;
            }

            float4 frag (v2f i) : SV_Target
            {
                float lengthFromCenter = length(i.uv - float2(0.5, 0.5));
                float lengthToEdge     = saturate((lengthFromCenter - 0.35) / (0.5 - 0.35));

                float2 seed    = i.uv * _Complex;
                       seed.y -= _Time.x * _Speed;

                float noise  = lerp(-1, 1, perlinNoise(seed));
                      noise *= (1 - lengthToEdge);
                // return noise;

                float2 distortedUV = i.uvGrab.xy / i.uvGrab.w;
                       distortedUV.x += noise * _Strength;
                       distortedUV.y += noise * _Strength;

                return  tex2D(_GrabPassTex, distortedUV);
            }

            ENDCG
        }
    }
}