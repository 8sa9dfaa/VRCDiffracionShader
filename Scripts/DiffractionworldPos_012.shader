Shader "Diffraction/DiffractionworldPos_012"
{
    //背景色と表示色の設定を加える
    //a,b,c -> a_1, a_2, a_3にする
        
    Properties
    {
        //-----------------------------------
        //Physics
        _Point_P("Point_P",Vector)=(-1000,1000,0,1)
        _lat_o("lat_o",Vector)=(0,0,0,1)
        _vec_a_1("lat_a_1",Vector)=(1,0,0,1)
        _vec_a_2("lat_a_2",Vector)=(0,1,0,1)
        _vec_a_3("lat_a_3",Vector)=(0,0,1,1)
        _WaveLength("WaveLength[m]",Range(0,10))=0.06
        _Frequency("Frequency[Hz]",Range(0,1000))=0.1
        _phase("Phase/2Pi",Range(0,1))=0
        [Space(30)]
        //-----------------------------------
        //Color
        _MainTex("MaineTex",2D)="white"{}
        _PowerOfMainTex("_PowerOfMainTex",Range(0,1))=0.1
        _DistortionOfMainTex("DistortionOfMainTex",Range(0,1))=1
        _fresnel("Fresnel",Range(0,1))=0.1
        _Surface("Surface",Range(-1,1))=0.999
        _BackGroundColor("BackGroundColor", Color)=(0,0.75,0.75,0)
        _WaveIntensityColor("WaveIntensityColor", Color)=(1,0,0,0)
        _PowerOfWaveIntensity("PowerOfWaveIntensity",Range(0,1))=1
        _SumwaveCColor("SumCosWaveColor", Color)=(0,0,0,0)
        _PowerOfSumwaveC("PowerOfSumwaveC",Range(0,1))=1
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 200
        Cull off

        Pass{
            Tags{
                "LightMode" = "ForwardBase"
            }
            //Blend One srcAlpha//OneminussrcAlpha
            //Blend SrcAlpha OneminussrcAlpha

            CGPROGRAM
            
            #include "Diffraction_012.cginc"

            ENDCG
        }

        Pass{
            Tags{
                "LightMode" = "ForwardAdd"
            }
            Blend One One

            CGPROGRAM
            
            #include "Diffraction_012.cginc"

            ENDCG
        }
    }
    FallBack "Diffuse"
}
