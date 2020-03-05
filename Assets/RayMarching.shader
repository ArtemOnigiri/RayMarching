Shader "Shaders/RayMarching"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
    }

    SubShader
    {
        Cull Off ZWrite Off ZTest Always
        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
                float2 uv : TEXCOORD0;
                float3 ray : TEXCOORD1;
            };

            uniform float4x4 _FrustumCornersES;
            uniform sampler2D _MainTex;
            uniform float4 _MainTex_TexelSize;
            uniform float4x4 _CameraInvViewMatrix;
            uniform float3 _CameraWS;

            uniform float _Param;
            uniform float3 _Object1;
            uniform float3 _Object2;

            static const float MAX_DIST = 50;
            static const int ITERATIONS = 500;

            float smin(float a, float b, float k)
            {
                float h = clamp(0.5 + 0.5 * (b - a) / k, 0.0, 1.0);
                return lerp(b, a, h) - k * h * (1.0 - h);
            }

            float plane(float3 p)
            {
                return p.y;
            }

            float sphere(float4 s, float3 p)
            {
                return length(p - s.xyz) - s.w;
            }

            float cube(float4 s, float3 p)
            {
                float3 q = abs(p - s.xyz) - s.w;
                return length(max(q, 0)) + min(max(q.x, max(q.y, q.z)), 0);
            }

            float getDist(float3 p)
            {
                float dist1 = sphere(float4(_Object1, 1), p);
                float dist2 = cube(float4(_Object2, 0.75), p);
                float dist3 = plane(p);
                return smin(smin(dist1, dist2, 0.5), dist3, 0.5);
            }

            float3 getNormal(float3 p)
            {
                float d = getDist(p);
                float2 e = float2(0.001, 0);
                float3 n = d - float3(getDist(p - e.xyy), getDist(p - e.yxy), getDist(p - e.yyx));
                return normalize(n);
            }

            float raymarchLight(float3 ro, float3 rd)
            {
                float dO = 0;
                float md = 1;
                for (int i = 0; i < 20; i++)
                {
                    float3 p = ro + rd * dO;
                    float dS = getDist(p);
                    md = min(md, dS);
                    dO += dS;
                    if(dO > 50 || dS < 0.1) break;
                }
                return md;
            }

            float4 getLight(float3 p, float3 ro, int i, float3 lightPos)
            {
                float3 l = normalize(lightPos - p);
                float3 n = getNormal(p);
                float dif = clamp(dot(n, l) * 0.5 + 0.5, 0, 1);
                float d = raymarchLight(p + n * 0.1 * 10, l);
                d += 1;
                d = clamp(d, 0, 1);
                dif *= d;
                float4 col = float4(dif, dif, dif, 1);
                float occ = (float(i) / ITERATIONS * 2);
                occ = 1 - occ;
                occ *= occ;
                col.rgb *= occ;
                float fog = distance(p, ro);
                fog /= MAX_DIST;
                fog = clamp(fog, 0, 1);
                fog *= fog;
                col.rgb = col.rgb * (1 - fog) + 0.28 * fog;
                return col;
            }

            float4 raymarch(float3 ro, float3 rd)
            {
                float3 p = ro;
                for (int i = 0; i < ITERATIONS; i++)
                {
                    float d = getDist(p);
                    if(d > MAX_DIST) return 0;
                    p += rd * d;
                    if(d < 0.001)
                    {
                        return getLight(p, ro, i, float3(0, 50, 0));
                    }
                }
                return 0;
            }

            v2f vert (appdata v)
            {
                v2f o;
                half index = v.vertex.z;
                v.vertex.z = 0.1;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv.xy;
                #if UNITY_UV_STARTS_AT_TOP
                    if (_MainTex_TexelSize.y < 0) o.uv.y = 1 - o.uv.y;
                #endif
                o.ray = _FrustumCornersES[(int)index].xyz;
                o.ray = mul(_CameraInvViewMatrix, o.ray);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                float3 rd = normalize(i.ray.xyz);
                float3 ro = _CameraWS;
                float4 c = raymarch(ro, rd);
                c = c * c.a + tex2D(_MainTex, i.uv) * (1 - c.a);
                fixed4 col = fixed4(c.r, c.g, c.b, 1);
                return col;
            }
            ENDCG
        }
    }
}