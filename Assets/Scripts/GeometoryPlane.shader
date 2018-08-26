// based on https://github.com/n0mimono/GeoToybox
// modified by Yasuo Hasegawa
Shader "Custom/GeometoryPlane"
{
	Properties
	{
		_MainTex("Texture", 2D) = "white" {}
		_Tint("Tint", Color) = (1,1,1,1)
		_lightPower("Light Power", Float) = 1
		_lightAmplitude("Light Amplitude", Float) = 1
		_lightTint("Light Tint", Color) = (1,1,1,1)
	}

	SubShader
	{
		Tags{ "RenderType" = "Opaque" }
		LOD 100
		cull off

		Pass
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma geometry geom
			#pragma fragment frag

			#include "UnityCG.cginc"
			#include "ShaderUtils.cginc"

			struct appdata
			{
				float4 vertex : POSITION;
				float2 uv : TEXCOORD0;
				float4 color  : COLOR;
				float3 normal : NORMAL;
			};

			struct v2f {
				float4 vertex : SV_POSITION;
				float2 uv     : TEXCOORD0;
				float4 wpos   : TEXCOORD1;
				float4 color  : TEXCOORD2;
				float3 normal : TEXCOORD3;
			};

			sampler2D _MainTex;
			float4 _MainTex_ST;
			float4 _Tint;
			float _lightPower;
			float _lightAmplitude;
			float4 _lightTint;

			v2f vert(appdata v)
			{
				v2f o;

				float x = cos(v.vertex.y*_Time.w)*0.05;
				float y = sin(v.vertex.x*_Time.w)*0.05;
				float noise = cnoise(float2(x, y));
				float4 pos = float4(noise, noise, noise, 1.0);

				o.vertex = v.vertex + pos;
				o.uv = TRANSFORM_TEX(v.uv, _MainTex);
				o.wpos = mul(unity_ObjectToWorld, v.vertex);
				o.color = v.color;
				o.normal = v.normal;
				return o;
			}

			[maxvertexcount(6)]
			void geom(triangle v2f v[3], inout TriangleStream<v2f> TriStream) {
				float4 wpos = (v[0].wpos + v[1].wpos + v[2].wpos) / 3;
				float4 vertex = (v[0].vertex + v[1].vertex + v[2].vertex) / 3;
				float2 uv = (v[0].uv + v[1].uv + v[2].uv) / 3;

				v2f o = v[0];
				o.uv = uv;
				o.wpos = wpos;
				float scale = 0.01 + sin(uv.x*_Time.y)*0.05;

				float rad = _Time.w*(uv.x*30.0) * degToRad;
				float rad2 = _Time.w*(uv.y*30.0) * degToRad;
				float rad3 = _Time.z*(uv.x*50.0) * degToRad;
				float4x4 rotX = matRotateX(rad);
				float4x4 rotY = matRotateY(rad2);
				float4x4 rotZ = matRotateY(rad3);


				float4 v0 = mul(mul(mul(float4(-1, -1, 0, 1), rotX), rotY), rotZ)*scale + float4(vertex.xyz, 0);
				float4 v1 = mul(mul(mul(float4(1, -1, 0, 1), rotX), rotY), rotZ)*scale + float4(vertex.xyz, 0);
				float4 v2 = mul(mul(mul(float4(1, 1, 0, 1), rotX), rotY), rotZ)*scale + float4(vertex.xyz, 0);
				float4 v3 = mul(mul(mul(float4(-1, 1, 0, 1), rotX), rotY), rotZ)*scale + float4(vertex.xyz, 0);

				float3 n0 = float3(0, 0, 1);
				float3 n1 = float3(0, 0, 1);

				ADD_TRI(v0, v2, v1, n0);
				ADD_TRI(v0, v3, v2, n0);
			}

			fixed4 frag(v2f i) : SV_Target
			{
				float3 normalDir = normalize(i.normal);
				float3 viewDir = normalize(_WorldSpaceCameraPos.xyz - i.wpos.xyz);
				float dotV = 1 - dot(normalDir, viewDir);
				float light = pow(dotV, _lightPower) * _lightAmplitude;

				float4 col = tex2D(_MainTex, i.uv) * i.color * _Tint;
				col.rgb = col.rgb * _lightTint.a + light * _lightTint.rgb;
				return col;
			}
			ENDCG
		}
	}
}
