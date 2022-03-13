Shader "NB29979/DisplayCharacter"
{
	Properties
	{
		_CharacterValue("CharacterValue", float) = -1.0
		_CharacterIndex("CharacterIndex", Int) = -1
		_NumTex ("NumTex", 2D) = "white" {}
		[Enum(UnityEngine.Rendering.CullMode)] _Cull("Cull", float) = 0
	}
		SubShader
		{
			Tags { "RenderType" = "TransparentCutout" "Queue" = "AlphaTest" "DisableBatching" = "True"}
			LOD 100

			Pass
			{
				Cull[_Cull]

				CGPROGRAM
				#pragma vertex vert
				#pragma fragment frag

				#include "UnityCG.cginc"

			// Unityから取得する変数を格納する構造体
			struct appdata
			{
				float4 vertex : POSITION;
				float2 uv : TEXCOORD0;
			};

		// 頂点シェーダで決定した値をフラグメントシェーダに渡すための構造体
		struct v2f
		{
			float2 uv : TEXCOORD0;
			float4 vertex : SV_POSITION;
		};

		sampler2D _NumTex;
		//_NumTexのTilingとOffset
		float4 _NumTex_ST;

		float _CharacterValue;
		int _CharacterIndex;

		static const int colSize = 14;
		static const int rowSize = 5;

			// 頂点シェーダ
			v2f vert (appdata v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.uv = TRANSFORM_TEX(v.uv, _NumTex);
				UNITY_TRANSFER_FOG(o,o.vertex);
				return o;
			}
			
			// フラグメントシェーダ
			fixed4 frag (v2f i) : SV_Target
			{
				//表示位置オフセット
				i.uv.x += 0.05;
				i.uv.y -= 0.8;
				
				int r, c;
				float stringTable[rowSize][colSize];
				for (r = 0; r < rowSize; ++r) {
					for (c = 0; c < colSize; ++c) {
						// _CharacterIndex==0 -> sign(0-0) = 0.0, 1-abs(0.0) => 1.0
						// _CharacterIndex==0 -> sign(1-0) = 1.0, 1-abs(1.0) => 0.0
						// _CharacterIndex==1 -> sign(1-1) = 0.0, 1-abs(0.0) => 1.0
						// _CharacterIndex==1 -> sign(0-1) = -1.0, 1-abs(-1.0) => 0.0
						stringTable[r][c] = 1-abs(sign((r*colSize+c)-_CharacterIndex))==1.0? _CharacterValue : stringTable[r][c];
					}
				}

				fixed4 numCol = fixed4(0, 0, 0, 0);
				float2 uv;

				for (r = 0; r < rowSize; ++r) {
					for (c = 0; c < colSize; ++c) {
						// .99999対策にマジックナンバーを加算する
						float characterVal = stringTable[r][c]+0.00001;
						uv = i.uv;
						// テクスチャのScale調整。描画側からはScaleは逆数になる。
						uv = (uv) * (1.0/2.0);

						// 行を求める。characterValを0.1倍し少数のみで第一位を抽出、0.1倍してテクスチャのy-index求める。
						float floatRowIndex = floor(frac((characterVal) * 0.1) * 10) * 0.1;
						uv.y += floatRowIndex;
						// 列を求める。characterValを0.01倍し少数のみで第一位を抽出、0.1倍してテクスチャのx-index求める。
						float floatColIndex = floor(frac((characterVal) * 0.01) * 10) * 0.1;
						uv.x += floatColIndex;

						// Material側のイメージ。テクスチャをindexだけx,y軸方向にずらす。
						uv.x -= 0.035 * c;
						uv.y += 0.1 * r;

						// step(edge, x): if x>=edge then 1.0 else 0.0
						float left = step(floatColIndex, uv.x);
						// floatColIndex+0.1未満で描画する。
						float right = 1 - step(floatColIndex + 0.1, uv.x);

						// floatColIndex+0.1未満で描画する。
						float top = 1 - step(floatRowIndex+0.1, uv.y);
						float bottom = step(floatRowIndex, uv.y);

						uv.x *= left * right;
						uv.y *= top * bottom;

						numCol += tex2D(_NumTex, uv);
					}
				}

				//mix
				fixed4 col = numCol;

				//明るさちょっとさげる
				// clamp(x, a, b) = min(max(x, a), b)
				col = clamp(col, 0, 0.8);

				//黒部分透明化
				// clip()->引数が0未満のとき描画しない
				clip(col.x - 0.5);

				return col;
			}
			ENDCG
		}
	}
}
