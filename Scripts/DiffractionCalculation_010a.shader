Shader "CustomRenderTexure/Calculation_010"
{
    Properties
    {
        _Surface("Surface",Range(-1,1))=0.999
        _MainTex("MaineTex",2D)="white"{}
        //_WaveMaskTex("WaveMaskTex",2D)="white"{}
        _Point_P("Point_P",Vector)=(-100,100,100,1)
        _lat_o("lat_o",Vector)=(0,0,0,1)
        _lat_a("lat_a",Vector)=(1,0,0,1)
        _lat_b("lat_b",Vector)=(0,1,0,1)
        _lat_c("lat_c",Vector)=(0,0,1,1)
        _WaveLength("WaveLength[m]",Range(0,10))=0.06
        _Frequency("Frequency[Hz]",Range(0,1000))=1
        _phase("Phase/2Pi",Range(0,1))=0
    }
    SubShader
    {
        Lighting Off
        Blend One Zero

        Pass
        {
            //Blend One One

            CGPROGRAM
            #include "UnityCustomRenderTexture.cginc"
            #pragma vertex CustomRenderTextureVertexShader
            #pragma fragment frag
            // make fog work
            #pragma target 3.0

            //変数
            #define PI 3.141592
            #define LATTICE 5

            //Display Threshold
            float _Surface;
            float _WaveLength;
            float _Frequency;

            //結晶格子について
            //光源の位置
            float4 _Point_P;

            //点O(結晶の基準点)
            float4 _lat_o;

            //格子点A,B,C
            float4 _lat_a;
            float4 _lat_b;
            float4 _lat_c;

            //ベクトルA,B,C
            float4 _vec_a;
            float4 _vec_b;
            float4 _vec_c;

            //格子点の座標
            float4 _lat[LATTICE*LATTICE*LATTICE];

            sampler2D _MainTex;
            //float4 _MainTex_ST;

            float4 _Color;

            //cos波を生成する。光源の座標（反射点の座標、スクリーンの座標、位相）
            float CustomWave(float3 ReflectionPoint,float3 Position,float AddtitionalPhase)
            {
                float wave=cos(2*acos(-1)*(1/_WaveLength*(distance(_Point_P,ReflectionPoint)+distance(ReflectionPoint,Position))-_Frequency*_Time)+ AddtitionalPhase);
                
                return wave;
            }

            float4 DiffractionCalculation(float4 worldPos, float _Lat)
            {
                //基本並進ベクトルを設定する
                _vec_a=_lat_a;
                _vec_b=_lat_b;
                _vec_c=_lat_c;

                //波の計算用変数初期化
                float wavec[LATTICE*LATTICE*LATTICE];
                float waves[LATTICE*LATTICE*LATTICE];
                float Sumwavec;
                float Sumwaves;
                Sumwavec=0;
                Sumwaves=0;

                //125個の波をすべて足し合わせる
                for(int i=0;i<LATTICE;i++){
                    for(int j=0;j<LATTICE;j++){
                        for(int k=0;k<LATTICE;k++){
                            
                            //_lat[]に実格子点の座標を代入する
                            _lat[LATTICE*LATTICE*i+LATTICE*j+k]=(i-2)*_vec_a+(j-2)*_vec_b+(k-2)*_vec_c + _lat_o;
                            
                            //_lat[]の座標、メッシュの座標を利用して計算する.wavec[]はcos波、wavesはsin波の意味.waves[]はwavec[]の位相をπ/2ずらすことで計算している
                            wavec[LATTICE*LATTICE*i+LATTICE*j+k]=CustomWave(_lat[LATTICE*LATTICE*i+LATTICE*j+k], worldPos, 0);
                            waves[LATTICE*LATTICE*i+LATTICE*j+k]=CustomWave(_lat[LATTICE*LATTICE*i+LATTICE*j+k], worldPos, -PI/2);
                            
                            //cos波、sin波はそれぞれ繰り返しSumwavecとSumwavesに足し合わせていく
                            Sumwavec+=wavec[LATTICE*LATTICE*i+LATTICE*j+k];
                            Sumwaves+=waves[LATTICE*LATTICE*i+LATTICE*j+k];
                        }
                    }
                }

                Sumwavec /= pow(LATTICE, 3);
                Sumwaves /= pow(LATTICE, 3);

                //定在波を算出|exp()|（cos(wt)^2+sin(wt)^2）
                float staticwave=Sumwavec*Sumwavec+Sumwaves*Sumwaves;

                return float4(Sumwavec, Sumwaves, staticwave, 0);
            }
            
            float4 frag (v2f_customrendertexture IN) : COLOR
            {
                fixed4 c;

                float3 RadiusThetaPhi = float3(100, acos(-1)*(1-IN.localTexcoord.y), 2 * acos(-1)*IN.localTexcoord.x);
                float4 worldPos =float4(RadiusThetaPhi.x*sin(RadiusThetaPhi.y)*cos(RadiusThetaPhi.z), RadiusThetaPhi.x*sin(RadiusThetaPhi.y)*sin(RadiusThetaPhi.z), RadiusThetaPhi.x*cos(RadiusThetaPhi.y),1);

                //全格子点をもとに波を合成
                float4 Diffraction = DiffractionCalculation(worldPos, _lat[0]);

                //これまでの結果から出力する色を決定
                c =  Diffraction.z * float4(1,0,0,1);
                c += step(_Surface, Diffraction.x) * float4(0,1,0,1);
                //c += step(_Surface, Diffraction.z) * float4(0,0,0,1);//透過処理
                c += float4(0,0,0,1);
                
                return c;
            }
            ENDCG
        }
    }
}
