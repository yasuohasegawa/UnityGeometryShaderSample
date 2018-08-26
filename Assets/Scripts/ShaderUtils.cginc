#define PI 3.14159265359
#define degToRad (PI * 2.0) / 360.0
#define ADD_VERT(v, n) \
		o.vertex = UnityObjectToClipPos(v); \
		o.normal = UnityObjectToWorldNormal(n); \
		TriStream.Append(o);

#define ADD_TRI(p0, p1, p2, n) \
		ADD_VERT(p0, n) ADD_VERT(p1, n) \
		ADD_VERT(p2, n) \
		TriStream.RestartStrip();

float4 permute(float4 x)
{
    return fmod(((x * 34.0) + 1.0) * x, 289.0);
}

float2 fade(float2 t)
{
    return t * t * t * (t * (t * 6.0 - 15.0) + 10.0);
}

float cnoise(float2 P)
{
    float4 Pi = floor(P.xyxy) + float4(0.0, 0.0, 1.0, 1.0);
    float4 Pf = frac(P.xyxy) - float4(0.0, 0.0, 1.0, 1.0);
    Pi = fmod(Pi, 289.0); // To avoid truncation effects in permutation
    float4 ix = Pi.xzxz;
    float4 iy = Pi.yyww;
    float4 fx = Pf.xzxz;
    float4 fy = Pf.yyww;
    float4 i = permute(permute(ix) + iy);
    float4 gx = 2.0 * frac(i * 0.0243902439) - 1.0; // 1/41 = 0.024...
    float4 gy = abs(gx) - 0.5;
    float4 tx = floor(gx + 0.5);
    gx = gx - tx;
    float2 g00 = float2(gx.x, gy.x);
    float2 g10 = float2(gx.y, gy.y);
    float2 g01 = float2(gx.z, gy.z);
    float2 g11 = float2(gx.w, gy.w);
    float4 norm = 1.79284291400159 - 0.85373472095314 *
					float4(dot(g00, g00), dot(g01, g01), dot(g10, g10), dot(g11, g11));
    g00 *= norm.x;
    g01 *= norm.y;
    g10 *= norm.z;
    g11 *= norm.w;
    float n00 = dot(g00, float2(fx.x, fy.x));
    float n10 = dot(g10, float2(fx.y, fy.y));
    float n01 = dot(g01, float2(fx.z, fy.z));
    float n11 = dot(g11, float2(fx.w, fy.w));
    float2 fade_xy = fade(Pf.xy);
    float2 n_x = lerp(float2(n00, n01), float2(n10, n11), fade_xy.x);
    float n_xy = lerp(n_x.x, n_x.y, fade_xy.y);
    return 2.3 * n_xy;
}

float4x4 matTranslation(float3 pos)
{
    return float4x4(1, 0, 0, pos.x,
					0, 1, 0, pos.y,
					0, 0, 1, pos.z,
					0, 0, 0, 1);
}

float4x4 matRotateX(float rad)
{
    return float4x4(1, 0, 0, 0,
					0, cos(rad), -sin(rad), 0,
					0, sin(rad), cos(rad), 0,
					0, 0, 0, 1);
}

float4x4 matRotateY(float rad)
{
    return float4x4(cos(rad), 0, -sin(rad), 0,
					0, 1, 0, 0,
					sin(rad), 0, cos(rad), 0,
					0, 0, 0, 1);
}

float4x4 matRotateZ(float rad)
{
    return float4x4(cos(rad), -sin(rad), 0, 0,
					sin(rad), cos(rad), 0, 0,
					0, 0, 1, 0,
					0, 0, 0, 1);
}
