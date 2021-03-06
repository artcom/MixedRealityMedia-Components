Shader "Chroma Key/Comparison/Composite Mask YCgCo"
{
	Properties
	{
		_MainTex ("Texture", 2D) = "white" {}
		_AlphaTex ("Alpha Texture", 2D) = "white" {}
		_WebcamTex ("Webcam Texture", 2D) = "white" {}
		_WebcamMask ("Webcam Mask", 2D) = "white" {}
		_LightTex ("Light Texture", 2D) = "white" {}
		_TargetColor ("Target Color", Color) = (0, 1, 0, 1)
		_SpillRemoval ("Spill Removal", Range(0, 2)) = 0.18
		_Tolerance ("Uppper Cut Off", Range(0, 5)) = 0.1
		_Threshold ("Lower Cut Off", Range(0, 5)) = 0.4
        _YCgCoMult ("YCgCo Multiplier", Float) = 1
		[Toggle] _RawCamera ("Raw Camera Out", Float) = 0
		[Toggle] _DebugAlpha ("Debug Alpha Out", Float) = 0
	}
	SubShader
	{
		Tags { "RenderType"="Opaque" }
		LOD 100

		Pass
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#include "GreenScreen.cginc"
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

			sampler2D _MainTex;
			float4 _MainTex_ST;
			
			v2f vert (appdata v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.uv = TRANSFORM_TEX(v.uv, _MainTex);
				return o;
			}

			sampler2D _AlphaTex;
			sampler2D _WebcamTex;
			sampler2D _WebcamMask;
			sampler2D _LightTex;
			float _SpillRemoval;
			float _YCgCoMult;
			fixed4 _TargetColor;
			int _DebugAlpha;
			int _RawCamera;
			
			fixed4 frag (v2f i) : SV_Target
			{
				// sample the textures
				fixed4 webCol = tex2D(_WebcamTex, i.uv);
				if(_RawCamera) {
					return webCol;
				}

				fixed4 col = tex2D(_MainTex, i.uv);
				fixed4 alpha = tex2D(_AlphaTex, i.uv);
				fixed4 webMask = tex2D(_WebcamMask, i.uv);
				fixed4 light = tex2D(_LightTex, i.uv);

				// apply the alpha transfer
				col.a = alpha.a;
				webCol.a = 1 - webMask.a;

				// do the color distance keying and spill removal
				webCol = fixed4(
					spillRemoval(webCol.rgb, _TargetColor.rgb, _SpillRemoval),
					ycgcoRemoval(webCol.rgb, _TargetColor.rgb, _YCgCoMult)
				);

				if(_DebugAlpha) {
					return webCol.aaaa;
				}
				col = mixCol(col, webCol * light);
				return col;
			}
			ENDCG
		}
	}
}
