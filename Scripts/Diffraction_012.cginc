#ifndef DIFFRACTION_CGINC_INCLUDED
#define DIFFRACTION_CGINC_INCLUDED
            #include "AutoLight.cginc"
            #include "Lighting.cginc"
            #include "UnityCG.cginc"
            #pragma multi_compile_fwdadd
            #pragma multi_compile_fog
            #pragma vertex vert
            #pragma fragment frag

            // Use shader model 3.0 target, to get nicer looking lighting
            #pragma target 3.0

            struct appdata
            {
                //ワールドにおける座標
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float3 normal : NORMAL;
                //float4 diffraction : TEXCOORD1;
            };

            struct v2f
            {
                float4 vertex : SV_POSITION;
                float2 uv : TEXCOORD0;
                float4 worldPos : TEXCOORD2;  
                float3 normal : NORMAL; 
                //float4 diffraction : TEXCOORD1;
                //fixed4 color : Color;
                UNITY_FOG_COORDS(3)
            };
            //変数
            #define PI 3.141592
            #define LATTICE 5

            float _Surface; //Display Threshold
            float _WaveLength;
            float _Frequency;
            float _phase;
            float _fresnel;

            sampler2D _MainTex;
            float _PowerOfMainTex;
            float _DistortionOfMainTex;
            float4 _BackGroundColor;
            float4 _WaveIntensityColor;
            float _PowerOfWaveIntensity;
            float4 _SumwaveCColor;
            float _PowerOfSumwaveC;

            //結晶格子について
            //光源の位置
            float4 _Point_P;

            //点O(結晶の基準点)
            float4 _lat_o;

            //基本並進ベクトル
            float4 _vec_a_1;
            float4 _vec_a_2;
            float4 _vec_a_3;

            //ベクトルA,B,C
            float4 _vec_a;
            float4 _vec_b;
            float4 _vec_c;

            //格子点の座標
            float4 _lat[LATTICE*LATTICE*LATTICE];



            //cos波を生成する。光源の座標（反射点の座標、スクリーンの座標、位相）
            float CustomWave(float3 ReflectionPoint,float3 DisplayPosition,float AddtitionalPhase)
            {
                float distanceP2R = distance(_Point_P, ReflectionPoint);//光源から格子点までの距離
                float distanceR2D = distance(ReflectionPoint, DisplayPosition);//格子点から表示点までの距離

                return cos(2*PI*(1/_WaveLength*(distanceP2R + distanceR2D)-_Frequency*_Time) + AddtitionalPhase);
            }
            
            v2f vert(appdata v)
            {
                v2f o;

                o.vertex = UnityObjectToClipPos(v.vertex); //ディスプレイ上の座標に変換
                
                o.normal = normalize(UnityObjectToWorldNormal(v.normal)); //ワールド法線に変換
                //o.vertex = UnityObjectToClipPos(v.vertex + Hoge * float4(normal,1)); //頂点座標を法線方向に変位

                o.worldPos = mul(unity_ObjectToWorld, v.vertex) ;//- mul(UNITY_MATRIX_M, _lat_o);//ワールド座標を取得
                
                //float4 diffraction = DiffractionCalculation(mul(unity_ObjectToWorld, v.vertex), _lat[0]);
                //o.diffraction = diffraction;
                //o.vertex = UnityObjectToClipPos(v.vertex + diffraction.z*normalize(UnityObjectToWorldNormal(v.normal))); //頂点の位置を移動
                
                o.uv = v.uv; //uv座標の変換

                UNITY_TRANSFER_FOG(o, o.vertex);

                return o;
            }

            fixed4 frag(v2f IN) : SV_Target
            {
                fixed4 c;

                UNITY_LIGHT_ATTENUATION(attenuation, IN, IN.worldPos.xyz); //光の減衰

                fixed4 tex = tex2D(_MainTex, IN.uv); //メインテクスチャ
                
                float3 normal = normalize(IN.normal); //単位法線ベクトル
                float3 viewdirection = normalize(_WorldSpaceCameraPos - IN.worldPos); //単位視線ベクトル
                float3 rflt = normalize(reflect(-viewdirection, normal)); //単位反射ベクトル
                float3 lightdirection = normalize(
                    _WorldSpaceLightPos0.w == 0 ?
                    _WorldSpaceLightPos0.xyz :
                    _WorldSpaceLightPos0.xyz - IN.worldPos.xyz
                ); //単位光源ベクトル

                float ambient = ShadeSH9(half4(IN.normal,1)); //環境光

                //環境マップの映り込み
                fixed specCubeLevel = UNITY_SPECCUBE_LOD_STEPS * 0.1;
                fixed4 specularColor = UNITY_SAMPLE_TEXCUBE_LOD(unity_SpecCube0, rflt, specCubeLevel);                

                float diffuse = dot(normal, lightdirection); //拡散光

                float3 hlf = normalize(lightdirection + viewdirection); //ハーフベクトル
                float specular = pow(dot(hlf, IN.normal), 10); //鏡面反射

                //float _fresnel = 0.1; 
                float fresnel = saturate(_fresnel + (1-_fresnel) * exp(-6 * dot(viewdirection, normal))); //フレネル反射

                //回折の計算
                //全格子点をもとに波を合成
                //格子点を基本並進ベクトルをもとに計算（ここはそれぞれ）
                //基本並進ベクトルを設定する
                _vec_a=_vec_a_1;
                _vec_b=_vec_a_2;
                _vec_c=_vec_a_3;
                float wavec[LATTICE*LATTICE*LATTICE];
                float waves[LATTICE*LATTICE*LATTICE];
                for(int i=0;i<LATTICE;i++){
                    for(int j=0;j<LATTICE;j++){
                        for(int k=0;k<LATTICE;k++){    
                            //_lat[]に実格子点の座標を代入する
                            _lat[LATTICE*LATTICE*i+LATTICE*j+k]=(i-2)*_vec_a+(j-2)*_vec_b+(k-2)*_vec_c + _lat_o;
                        }
                    }
                }
                /*格子点をたとえば縦に並べる
                float wavec[LATTICE*LATTICE*LATTICE];
                float waves[LATTICE*LATTICE*LATTICE];
                for(int i=0;i<LATTICE;i++){
                    for(int j=0;j<LATTICE;j++){
                        for(int k=0;k<LATTICE;k++){    
                            //_lat[]に実格子点の座標を代入する
                            _lat[LATTICE*LATTICE*i+LATTICE*j+k]=float4(0,-20 + 10*k,0,1);
                        }
                    }
                }
                */
                ////格子点を基本並進ベクトルをもとに計算（終わり）

                //すべての波をすべて足し合わせる(ここは共通)
                float SumwaveC = 0;
                float SumwaveS = 0;
                for(int i=0;i<LATTICE;i++){
                    for(int j=0;j<LATTICE;j++){
                        for(int k=0;k<LATTICE;k++){                         
                            //_lat[]の座標、メッシュの座標を利用して波を計算する.wavec[]はcos波、wavesはsin波の意味.waves[]はwavec[]の位相をπ/2ずらすことで計算している
                            wavec[LATTICE*LATTICE*i+LATTICE*j+k]=CustomWave(_lat[LATTICE*LATTICE*i+LATTICE*j+k], IN.worldPos, 0);
                            waves[LATTICE*LATTICE*i+LATTICE*j+k]=CustomWave(_lat[LATTICE*LATTICE*i+LATTICE*j+k], IN.worldPos, -PI/2);
                            //cos波、sin波はそれぞれ繰り返しSumwaveCとSumwaveSに足し合わせていく
                            SumwaveC+=wavec[LATTICE*LATTICE*i+LATTICE*j+k];
                            SumwaveS+=waves[LATTICE*LATTICE*i+LATTICE*j+k];
                        }
                    }
                }
                SumwaveC /= pow(LATTICE, 3);//規格化
                SumwaveS /= pow(LATTICE, 3);//規格化

                //定在波の2乗を算出|exp()|^2 =（cos(wt)^2+sin(wt)^2）(ここは共通)
                float staticwave;
                //staticwave=SumwaveC*SumwaveC+SumwaveS*SumwaveS;
                staticwave = pow(SumwaveC, 2) + pow(SumwaveS, 2);

                //float4 Diffraction = DiffractionCalculation(IN.worldPos);
                float4 Diffraction = float4(SumwaveC, SumwaveS, staticwave, 0);
                //c += step(_Surface, Diffraction.z) * float4(0,0,0,1);//透過処理
                fixed4 displaydata;
                //displaydata = lerp(_BackGroundColor, _SumwaveCColor, Diffraction.x);
                //displaydata += lerp(_BackGroundColor, _WaveIntensityColor, Diffraction.z);
                displaydata = _PowerOfWaveIntensity*lerp(_BackGroundColor, _WaveIntensityColor, smoothstep(_Surface-0.1,_Surface, Diffraction.z));
                displaydata += _PowerOfSumwaveC*lerp(_BackGroundColor, _SumwaveCColor, smoothstep(_Surface-0.1,_Surface, Diffraction.x));
                                

                //最終出力
                c = diffuse * displaydata * _LightColor0 * attenuation; //拡散光
                
                c += ambient * displaydata; //環境光

                //c += specular * specularColor * _LightColor0 * attenuation; //鏡面反射
                
                c += fresnel * fixed4(1,1,1,1) * ambient; //フレネル反射
                
                //水面
                fixed4 _watertex = tex2D(_MainTex, IN.uv + _DistortionOfMainTex * float2(Diffraction.x, Diffraction.y));
                c += _PowerOfMainTex * _watertex; //水のテクスチャを貼り付け
                /*試しにランダムノイズを入れたがうまくいかなかった
                float noise = frac(1000*sin(dot(floor(IN.uv*200), float2(12.3, 8.92))));
                c += _PowerOfMainTex * float4(noise*float3(1,1,1),0);
                */

                UNITY_APPLY_FOG(IN.fogCoord, c); //fogの適用

                return c;
            }
#endif //#ifndef DIFFRACTION_CGINC_INCLUDED