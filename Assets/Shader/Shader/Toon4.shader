Shader "Toon4"
    {
        Properties
        {
            [Header(High Level Setting)]
            [ToggleUI]_IsFace("Is Face? (please turn on if this is a face material)", Float) = 0

            _AmbientStrength("Ambient Strength", Float) = 0.25
            _DiffuseColor("Diffuse Color", Color) = (1, 1, 1, 1)
            [NoScaleOffset]_MainTex("Diffuse Texture", 2D) = "white" {}
            _SpecularColor("Specular Color", Color) = (1, 1, 1, 1)
            _FresnelColor("Fresnel Color", Color) = (1, 1, 1, 1)
            _Smoothness("Smoothness", Float) = 1000
            _FresnelSize("Fresnel Size", Float) = 0.1
            _LightingCutoff("Lighting Cutoff", Float) = 0
            _FalloffAmount("Falloff Amount", Float) = 0.05
            [HideInInspector][NoScaleOffset]unity_Lightmaps("unity_Lightmaps", 2DArray) = "" {}
            [HideInInspector][NoScaleOffset]unity_LightmapsInd("unity_LightmapsInd", 2DArray) = "" {}
            [HideInInspector][NoScaleOffset]unity_ShadowMasks("unity_ShadowMasks", 2DArray) = "" {}

            
            [Header(Outline)]
            _OutlineWidth("_OutlineWidth (World Space)", Range(0,4)) = 1
            _OutlineColor("_OutlineColor", Color) = (0.5,0.5,0.5,1)
            _OutlineZOffset("_OutlineZOffset (View Space)", Range(0,1)) = 0.0001
            [NoScaleOffset]_OutlineZOffsetMaskTex("_OutlineZOffsetMask (black is apply ZOffset)", 2D) = "black" {}
            _OutlineZOffsetMaskRemapStart("_OutlineZOffsetMaskRemapStart", Range(0,1)) = 0
            _OutlineZOffsetMaskRemapEnd("_OutlineZOffsetMaskRemapEnd", Range(0,1)) = 1
        }
        SubShader
        {
            Tags
            {
                "RenderPipeline"="UniversalPipeline"
                "RenderType"="Opaque"
                "UniversalMaterialType" = "Lit"
                "Queue"="Geometry"
            }

            HLSLINCLUDE
            #pragma shader_feature_local_fragment _UseAlphaClipping
            ENDHLSL

            Pass
            {
                Name "Universal Forward"
                Tags
                {
                    "LightMode" = "UniversalForward"
                }
    
                // Render State
                Cull Back
                Blend One Zero
                ZTest LEqual
                ZWrite On
    
                // Debug
                // <None>
    
                // --------------------------------------------------
                // Pass
    
                HLSLPROGRAM
    
                // Pragmas
                #pragma target 4.5
                #pragma exclude_renderers gles gles3 glcore
                #pragma multi_compile_instancing
                #pragma multi_compile_fog
                #pragma multi_compile _ DOTS_INSTANCING_ON
                #pragma vertex vert
                #pragma fragment frag
    
                // DotsInstancingOptions: <None>
                // HybridV1InjectedBuiltinProperties: <None>
    
                // Keywords
                #pragma multi_compile _ _SCREEN_SPACE_OCCLUSION
                #pragma multi_compile _ LIGHTMAP_ON
                #pragma multi_compile _ DIRLIGHTMAP_COMBINED
                #pragma multi_compile _ _MAIN_LIGHT_SHADOWS
                #pragma multi_compile _ _MAIN_LIGHT_SHADOWS_CASCADE
                #pragma multi_compile _ADDITIONAL_LIGHTS_VERTEX _ADDITIONAL_LIGHTS _ADDITIONAL_OFF
                #pragma multi_compile _ _ADDITIONAL_LIGHT_SHADOWS
                #pragma multi_compile _ _SHADOWS_SOFT
                #pragma multi_compile _ LIGHTMAP_SHADOW_MIXING
                #pragma multi_compile _ SHADOWS_SHADOWMASK
                // GraphKeywords: <None>
    
                // Defines
                #define _NORMALMAP 1
                #define _NORMAL_DROPOFF_TS 1
                #define ATTRIBUTES_NEED_NORMAL
                #define ATTRIBUTES_NEED_TANGENT
                #define ATTRIBUTES_NEED_TEXCOORD0
                #define ATTRIBUTES_NEED_TEXCOORD1
                #define VARYINGS_NEED_POSITION_WS
                #define VARYINGS_NEED_NORMAL_WS
                #define VARYINGS_NEED_TANGENT_WS
                #define VARYINGS_NEED_TEXCOORD0
                #define VARYINGS_NEED_VIEWDIRECTION_WS
                #define VARYINGS_NEED_FOG_AND_VERTEX_LIGHT
                #define FEATURES_GRAPH_VERTEX
                /* WARNING: $splice Could not find named fragment 'PassInstancing' */
                #define SHADERPASS SHADERPASS_FORWARD
                /* WARNING: $splice Could not find named fragment 'DotsInstancingVars' */
    
                // Includes
                #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
                #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Texture.hlsl"
                #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
                #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
                #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/TextureStack.hlsl"
                #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Shadows.hlsl"
                #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"
    
                // --------------------------------------------------
                // Structs and Packing
    
                struct Attributes
                {
                    float3 positionOS : POSITION;
                    float3 normalOS : NORMAL;
                    float4 tangentOS : TANGENT;
                    float4 uv0 : TEXCOORD0;
                    float4 uv1 : TEXCOORD1;
                    #if UNITY_ANY_INSTANCING_ENABLED
                    uint instanceID : INSTANCEID_SEMANTIC;
                    #endif
                };
                struct Varyings
                {
                    float4 positionCS : SV_POSITION;
                    float3 positionWS;
                    float3 normalWS;
                    float4 tangentWS;
                    float4 texCoord0;
                    float3 viewDirectionWS;
                    #if defined(LIGHTMAP_ON)
                    float2 lightmapUV;
                    #endif
                    #if !defined(LIGHTMAP_ON)
                    float3 sh;
                    #endif
                    float4 fogFactorAndVertexLight;
                    float4 shadowCoord;
                    #if UNITY_ANY_INSTANCING_ENABLED
                    uint instanceID : CUSTOM_INSTANCE_ID;
                    #endif
                    #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
                    uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
                    #endif
                    #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
                    uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
                    #endif
                    #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
                    FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
                    #endif
                };
                struct SurfaceDescriptionInputs
                {
                    float3 WorldSpaceNormal;
                    float3 TangentSpaceNormal;
                    float3 WorldSpaceViewDirection;
                    float3 WorldSpacePosition;
                    float4 uv0;
                };
                struct VertexDescriptionInputs
                {
                    float3 ObjectSpaceNormal;
                    float3 ObjectSpaceTangent;
                    float3 ObjectSpacePosition;
                };
                struct PackedVaryings
                {
                    float4 positionCS : SV_POSITION;
                    float3 interp0 : TEXCOORD0;
                    float3 interp1 : TEXCOORD1;
                    float4 interp2 : TEXCOORD2;
                    float4 interp3 : TEXCOORD3;
                    float3 interp4 : TEXCOORD4;
                    #if defined(LIGHTMAP_ON)
                    float2 interp5 : TEXCOORD5;
                    #endif
                    #if !defined(LIGHTMAP_ON)
                    float3 interp6 : TEXCOORD6;
                    #endif
                    float4 interp7 : TEXCOORD7;
                    float4 interp8 : TEXCOORD8;
                    #if UNITY_ANY_INSTANCING_ENABLED
                    uint instanceID : CUSTOM_INSTANCE_ID;
                    #endif
                    #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
                    uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
                    #endif
                    #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
                    uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
                    #endif
                    #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
                    FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
                    #endif
                };
    
                PackedVaryings PackVaryings (Varyings input)
                {
                    PackedVaryings output;
                    output.positionCS = input.positionCS;
                    output.interp0.xyz =  input.positionWS;
                    output.interp1.xyz =  input.normalWS;
                    output.interp2.xyzw =  input.tangentWS;
                    output.interp3.xyzw =  input.texCoord0;
                    output.interp4.xyz =  input.viewDirectionWS;
                    #if defined(LIGHTMAP_ON)
                    output.interp5.xy =  input.lightmapUV;
                    #endif
                    #if !defined(LIGHTMAP_ON)
                    output.interp6.xyz =  input.sh;
                    #endif
                    output.interp7.xyzw =  input.fogFactorAndVertexLight;
                    output.interp8.xyzw =  input.shadowCoord;
                    #if UNITY_ANY_INSTANCING_ENABLED
                    output.instanceID = input.instanceID;
                    #endif
                    #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
                    output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
                    #endif
                    #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
                    output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
                    #endif
                    #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
                    output.cullFace = input.cullFace;
                    #endif
                    return output;
                }
                Varyings UnpackVaryings (PackedVaryings input)
                {
                    Varyings output;
                    output.positionCS = input.positionCS;
                    output.positionWS = input.interp0.xyz;
                    output.normalWS = input.interp1.xyz;
                    output.tangentWS = input.interp2.xyzw;
                    output.texCoord0 = input.interp3.xyzw;
                    output.viewDirectionWS = input.interp4.xyz;
                    #if defined(LIGHTMAP_ON)
                    output.lightmapUV = input.interp5.xy;
                    #endif
                    #if !defined(LIGHTMAP_ON)
                    output.sh = input.interp6.xyz;
                    #endif
                    output.fogFactorAndVertexLight = input.interp7.xyzw;
                    output.shadowCoord = input.interp8.xyzw;
                    #if UNITY_ANY_INSTANCING_ENABLED
                    output.instanceID = input.instanceID;
                    #endif
                    #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
                    output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
                    #endif
                    #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
                    output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
                    #endif
                    #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
                    output.cullFace = input.cullFace;
                    #endif
                    return output;
                }
    
                // --------------------------------------------------
                // Graph
    
                // Graph Properties
                CBUFFER_START(UnityPerMaterial)
                float _AmbientStrength;
                float4 _DiffuseColor;
                float4 _MainTex_TexelSize;
                float4 _SpecularColor;
                float4 _FresnelColor;
                float _Smoothness;
                float _FresnelSize;
                float _LightingCutoff;
                float _FalloffAmount;
                CBUFFER_END
                
                // Object and Global properties
                SAMPLER(SamplerState_Linear_Repeat);
                TEXTURE2D(_MainTex);
                SAMPLER(sampler_MainTex);
    
                // Graph Functions
                
                void Unity_Add_float(float A, float B, out float Out)
                {
                    Out = A + B;
                }
                
                void Unity_Reciprocal_float(float In, out float Out)
                {
                    Out = 1.0/In;
                }
                
                void Unity_FresnelEffect_float(float3 Normal, float3 ViewDir, float Power, out float Out)
                {
                    Out = pow((1.0 - saturate(dot(normalize(Normal), normalize(ViewDir)))), Power);
                }
                
                // a6264222ffebf7cfce349cb3e07ea356
                #include "./Lighting.hlsl"
                
                void Unity_Multiply_float(float A, float B, out float Out)
                {
                    Out = A * B;
                }
                
                struct Bindings_GetMainLight_d6b14a2e8b6f3554b8459648535f697e
                {
                };
                
                void SG_GetMainLight_d6b14a2e8b6f3554b8459648535f697e(float3 Vector3_b21c75b9b8514ef286d5e6dc199fa9af, Bindings_GetMainLight_d6b14a2e8b6f3554b8459648535f697e IN, out float3 Direction_0, out float3 Color_1, out float Attenuation_2)
                {
                    float3 _Property_923162a64885457196b5ccbf7a2aaac7_Out_0 = Vector3_b21c75b9b8514ef286d5e6dc199fa9af;
                    float3 _MainLightCustomFunction_93e39954c04146b5ae1be272ea9d714b_Direction_0;
                    float3 _MainLightCustomFunction_93e39954c04146b5ae1be272ea9d714b_Color_2;
                    float _MainLightCustomFunction_93e39954c04146b5ae1be272ea9d714b_DistanceAtten_3;
                    float _MainLightCustomFunction_93e39954c04146b5ae1be272ea9d714b_ShadowAtten_4;
                    MainLight_float(_Property_923162a64885457196b5ccbf7a2aaac7_Out_0, _MainLightCustomFunction_93e39954c04146b5ae1be272ea9d714b_Direction_0, _MainLightCustomFunction_93e39954c04146b5ae1be272ea9d714b_Color_2, _MainLightCustomFunction_93e39954c04146b5ae1be272ea9d714b_DistanceAtten_3, _MainLightCustomFunction_93e39954c04146b5ae1be272ea9d714b_ShadowAtten_4);
                    float _Multiply_6d878674c9b447478a9564442340c0a2_Out_2;
                    Unity_Multiply_float(_MainLightCustomFunction_93e39954c04146b5ae1be272ea9d714b_DistanceAtten_3, _MainLightCustomFunction_93e39954c04146b5ae1be272ea9d714b_ShadowAtten_4, _Multiply_6d878674c9b447478a9564442340c0a2_Out_2);
                    Direction_0 = _MainLightCustomFunction_93e39954c04146b5ae1be272ea9d714b_Direction_0;
                    Color_1 = _MainLightCustomFunction_93e39954c04146b5ae1be272ea9d714b_Color_2;
                    Attenuation_2 = _Multiply_6d878674c9b447478a9564442340c0a2_Out_2;
                }
                
                void Unity_DotProduct_float3(float3 A, float3 B, out float Out)
                {
                    Out = dot(A, B);
                }
                
                void Unity_Multiply_float(float3 A, float3 B, out float3 Out)
                {
                    Out = A * B;
                }
                
                void Unity_Saturate_float3(float3 In, out float3 Out)
                {
                    Out = saturate(In);
                }
                
                struct Bindings_GetAdditionalLight_b5516a5008f7d104abebe27210c42de8
                {
                };
                
                void SG_GetAdditionalLight_b5516a5008f7d104abebe27210c42de8(float3 Vector3_1e07dec0084a48e38c95166c3cdc688d, float Vector1_0ce9574e837f408991312a6c71473833, Bindings_GetAdditionalLight_b5516a5008f7d104abebe27210c42de8 IN, out float3 Direction_0, out float3 Color_1, out float Attenuation_2)
                {
                    float3 _Property_e9927ccc4a684aeabdaa70dbe76689f0_Out_0 = Vector3_1e07dec0084a48e38c95166c3cdc688d;
                    float _Property_c6fa454cb94449b6923e1c90fafaf929_Out_0 = Vector1_0ce9574e837f408991312a6c71473833;
                    float3 _AdditionalLightCustomFunction_c6ec52ed99634926b12dc96d48e96f1b_Direction_1;
                    float3 _AdditionalLightCustomFunction_c6ec52ed99634926b12dc96d48e96f1b_Color_2;
                    float _AdditionalLightCustomFunction_c6ec52ed99634926b12dc96d48e96f1b_DistanceAtten_3;
                    float _AdditionalLightCustomFunction_c6ec52ed99634926b12dc96d48e96f1b_ShadowAtten_4;
                    AdditionalLight_float(_Property_e9927ccc4a684aeabdaa70dbe76689f0_Out_0, _Property_c6fa454cb94449b6923e1c90fafaf929_Out_0, _AdditionalLightCustomFunction_c6ec52ed99634926b12dc96d48e96f1b_Direction_1, _AdditionalLightCustomFunction_c6ec52ed99634926b12dc96d48e96f1b_Color_2, _AdditionalLightCustomFunction_c6ec52ed99634926b12dc96d48e96f1b_DistanceAtten_3, _AdditionalLightCustomFunction_c6ec52ed99634926b12dc96d48e96f1b_ShadowAtten_4);
                    float _Multiply_0b8ec7bbb926441e8c14c7c32d369adf_Out_2;
                    Unity_Multiply_float(_AdditionalLightCustomFunction_c6ec52ed99634926b12dc96d48e96f1b_DistanceAtten_3, _AdditionalLightCustomFunction_c6ec52ed99634926b12dc96d48e96f1b_ShadowAtten_4, _Multiply_0b8ec7bbb926441e8c14c7c32d369adf_Out_2);
                    Direction_0 = _AdditionalLightCustomFunction_c6ec52ed99634926b12dc96d48e96f1b_Direction_1;
                    Color_1 = _AdditionalLightCustomFunction_c6ec52ed99634926b12dc96d48e96f1b_Color_2;
                    Attenuation_2 = _Multiply_0b8ec7bbb926441e8c14c7c32d369adf_Out_2;
                }
                
                void Unity_Saturate_float(float In, out float Out)
                {
                    Out = saturate(In);
                }
                
                void Unity_Add_float3(float3 A, float3 B, out float3 Out)
                {
                    Out = A + B;
                }
                
                struct Bindings_CalcAdditionalDiffuse_e85823578a3493d41ade631af12166aa
                {
                    float3 WorldSpaceNormal;
                    float3 WorldSpacePosition;
                };
                
                void SG_CalcAdditionalDiffuse_e85823578a3493d41ade631af12166aa(Bindings_CalcAdditionalDiffuse_e85823578a3493d41ade631af12166aa IN, out float3 Diffuse_1)
                {
                    Bindings_GetAdditionalLight_b5516a5008f7d104abebe27210c42de8 _GetAdditionalLight_e6c10dfa199649fca18a0cb673fcba44;
                    float3 _GetAdditionalLight_e6c10dfa199649fca18a0cb673fcba44_Direction_0;
                    float3 _GetAdditionalLight_e6c10dfa199649fca18a0cb673fcba44_Color_1;
                    float _GetAdditionalLight_e6c10dfa199649fca18a0cb673fcba44_Attenuation_2;
                    SG_GetAdditionalLight_b5516a5008f7d104abebe27210c42de8(IN.WorldSpacePosition, 0, _GetAdditionalLight_e6c10dfa199649fca18a0cb673fcba44, _GetAdditionalLight_e6c10dfa199649fca18a0cb673fcba44_Direction_0, _GetAdditionalLight_e6c10dfa199649fca18a0cb673fcba44_Color_1, _GetAdditionalLight_e6c10dfa199649fca18a0cb673fcba44_Attenuation_2);
                    float _DotProduct_aee5f4b498024e2da9796ed342f8a43a_Out_2;
                    Unity_DotProduct_float3(_GetAdditionalLight_e6c10dfa199649fca18a0cb673fcba44_Direction_0, IN.WorldSpaceNormal, _DotProduct_aee5f4b498024e2da9796ed342f8a43a_Out_2);
                    float _Saturate_2080d664f6004dc9ad574ba7e91917b2_Out_1;
                    Unity_Saturate_float(_DotProduct_aee5f4b498024e2da9796ed342f8a43a_Out_2, _Saturate_2080d664f6004dc9ad574ba7e91917b2_Out_1);
                    float3 _Multiply_57fcc7dc0fb845cf924c855eadbb7792_Out_2;
                    Unity_Multiply_float((_Saturate_2080d664f6004dc9ad574ba7e91917b2_Out_1.xxx), _GetAdditionalLight_e6c10dfa199649fca18a0cb673fcba44_Color_1, _Multiply_57fcc7dc0fb845cf924c855eadbb7792_Out_2);
                    float3 _Multiply_59016ca5433045d0a06ff03a13ec13b6_Out_2;
                    Unity_Multiply_float(_Multiply_57fcc7dc0fb845cf924c855eadbb7792_Out_2, (_GetAdditionalLight_e6c10dfa199649fca18a0cb673fcba44_Attenuation_2.xxx), _Multiply_59016ca5433045d0a06ff03a13ec13b6_Out_2);
                    Bindings_GetAdditionalLight_b5516a5008f7d104abebe27210c42de8 _GetAdditionalLight_a054a4cd5b484e1492208dc9ca4a85f5;
                    float3 _GetAdditionalLight_a054a4cd5b484e1492208dc9ca4a85f5_Direction_0;
                    float3 _GetAdditionalLight_a054a4cd5b484e1492208dc9ca4a85f5_Color_1;
                    float _GetAdditionalLight_a054a4cd5b484e1492208dc9ca4a85f5_Attenuation_2;
                    SG_GetAdditionalLight_b5516a5008f7d104abebe27210c42de8(IN.WorldSpacePosition, 1, _GetAdditionalLight_a054a4cd5b484e1492208dc9ca4a85f5, _GetAdditionalLight_a054a4cd5b484e1492208dc9ca4a85f5_Direction_0, _GetAdditionalLight_a054a4cd5b484e1492208dc9ca4a85f5_Color_1, _GetAdditionalLight_a054a4cd5b484e1492208dc9ca4a85f5_Attenuation_2);
                    float _DotProduct_00e581a08ce7465588597fd11859eea2_Out_2;
                    Unity_DotProduct_float3(_GetAdditionalLight_a054a4cd5b484e1492208dc9ca4a85f5_Direction_0, IN.WorldSpaceNormal, _DotProduct_00e581a08ce7465588597fd11859eea2_Out_2);
                    float _Saturate_58b5f4d3dcaf45e6bda212ef43edc4ea_Out_1;
                    Unity_Saturate_float(_DotProduct_00e581a08ce7465588597fd11859eea2_Out_2, _Saturate_58b5f4d3dcaf45e6bda212ef43edc4ea_Out_1);
                    float3 _Multiply_6ff1cb7ecc8542848d8d721f284a3b3c_Out_2;
                    Unity_Multiply_float((_Saturate_58b5f4d3dcaf45e6bda212ef43edc4ea_Out_1.xxx), _GetAdditionalLight_a054a4cd5b484e1492208dc9ca4a85f5_Color_1, _Multiply_6ff1cb7ecc8542848d8d721f284a3b3c_Out_2);
                    float3 _Multiply_8337e9ec92b74cefb421776f67b29661_Out_2;
                    Unity_Multiply_float(_Multiply_6ff1cb7ecc8542848d8d721f284a3b3c_Out_2, (_GetAdditionalLight_a054a4cd5b484e1492208dc9ca4a85f5_Attenuation_2.xxx), _Multiply_8337e9ec92b74cefb421776f67b29661_Out_2);
                    float3 _Add_8d5fe4674e364518a5d8f4559669df92_Out_2;
                    Unity_Add_float3(_Multiply_59016ca5433045d0a06ff03a13ec13b6_Out_2, _Multiply_8337e9ec92b74cefb421776f67b29661_Out_2, _Add_8d5fe4674e364518a5d8f4559669df92_Out_2);
                    Bindings_GetAdditionalLight_b5516a5008f7d104abebe27210c42de8 _GetAdditionalLight_ee2152ac3ed64138932b3a2e4b8e3f14;
                    float3 _GetAdditionalLight_ee2152ac3ed64138932b3a2e4b8e3f14_Direction_0;
                    float3 _GetAdditionalLight_ee2152ac3ed64138932b3a2e4b8e3f14_Color_1;
                    float _GetAdditionalLight_ee2152ac3ed64138932b3a2e4b8e3f14_Attenuation_2;
                    SG_GetAdditionalLight_b5516a5008f7d104abebe27210c42de8(IN.WorldSpacePosition, 2, _GetAdditionalLight_ee2152ac3ed64138932b3a2e4b8e3f14, _GetAdditionalLight_ee2152ac3ed64138932b3a2e4b8e3f14_Direction_0, _GetAdditionalLight_ee2152ac3ed64138932b3a2e4b8e3f14_Color_1, _GetAdditionalLight_ee2152ac3ed64138932b3a2e4b8e3f14_Attenuation_2);
                    float _DotProduct_7a3fce316c4a453e9b9e18226fc2d066_Out_2;
                    Unity_DotProduct_float3(_GetAdditionalLight_ee2152ac3ed64138932b3a2e4b8e3f14_Direction_0, IN.WorldSpaceNormal, _DotProduct_7a3fce316c4a453e9b9e18226fc2d066_Out_2);
                    float _Saturate_c9919732b14f4622aa82e1eec5cb383d_Out_1;
                    Unity_Saturate_float(_DotProduct_7a3fce316c4a453e9b9e18226fc2d066_Out_2, _Saturate_c9919732b14f4622aa82e1eec5cb383d_Out_1);
                    float3 _Multiply_013e04c47fdf4f46a7f2a4868ec83bed_Out_2;
                    Unity_Multiply_float((_Saturate_c9919732b14f4622aa82e1eec5cb383d_Out_1.xxx), _GetAdditionalLight_ee2152ac3ed64138932b3a2e4b8e3f14_Color_1, _Multiply_013e04c47fdf4f46a7f2a4868ec83bed_Out_2);
                    float3 _Multiply_8d16da0d689d4d49909909e6c2cc2da6_Out_2;
                    Unity_Multiply_float(_Multiply_013e04c47fdf4f46a7f2a4868ec83bed_Out_2, (_GetAdditionalLight_ee2152ac3ed64138932b3a2e4b8e3f14_Attenuation_2.xxx), _Multiply_8d16da0d689d4d49909909e6c2cc2da6_Out_2);
                    Bindings_GetAdditionalLight_b5516a5008f7d104abebe27210c42de8 _GetAdditionalLight_da7753016bd64b489b897349d7f3fc0f;
                    float3 _GetAdditionalLight_da7753016bd64b489b897349d7f3fc0f_Direction_0;
                    float3 _GetAdditionalLight_da7753016bd64b489b897349d7f3fc0f_Color_1;
                    float _GetAdditionalLight_da7753016bd64b489b897349d7f3fc0f_Attenuation_2;
                    SG_GetAdditionalLight_b5516a5008f7d104abebe27210c42de8(IN.WorldSpacePosition, 3, _GetAdditionalLight_da7753016bd64b489b897349d7f3fc0f, _GetAdditionalLight_da7753016bd64b489b897349d7f3fc0f_Direction_0, _GetAdditionalLight_da7753016bd64b489b897349d7f3fc0f_Color_1, _GetAdditionalLight_da7753016bd64b489b897349d7f3fc0f_Attenuation_2);
                    float _DotProduct_be3ed23b71d142e3a88f9f21ca2b9bb1_Out_2;
                    Unity_DotProduct_float3(_GetAdditionalLight_da7753016bd64b489b897349d7f3fc0f_Direction_0, IN.WorldSpaceNormal, _DotProduct_be3ed23b71d142e3a88f9f21ca2b9bb1_Out_2);
                    float _Saturate_b3794fe44470430e954d43bb481a3d9a_Out_1;
                    Unity_Saturate_float(_DotProduct_be3ed23b71d142e3a88f9f21ca2b9bb1_Out_2, _Saturate_b3794fe44470430e954d43bb481a3d9a_Out_1);
                    float3 _Multiply_fcf9bc551f0e42f39634ac95fab7cae5_Out_2;
                    Unity_Multiply_float((_Saturate_b3794fe44470430e954d43bb481a3d9a_Out_1.xxx), _GetAdditionalLight_da7753016bd64b489b897349d7f3fc0f_Color_1, _Multiply_fcf9bc551f0e42f39634ac95fab7cae5_Out_2);
                    float3 _Multiply_0cc8c00775354d6a9f91977c3e357ff8_Out_2;
                    Unity_Multiply_float(_Multiply_fcf9bc551f0e42f39634ac95fab7cae5_Out_2, (_GetAdditionalLight_da7753016bd64b489b897349d7f3fc0f_Attenuation_2.xxx), _Multiply_0cc8c00775354d6a9f91977c3e357ff8_Out_2);
                    float3 _Add_0992646b9a764f6eb220517d0e9fc815_Out_2;
                    Unity_Add_float3(_Multiply_8d16da0d689d4d49909909e6c2cc2da6_Out_2, _Multiply_0cc8c00775354d6a9f91977c3e357ff8_Out_2, _Add_0992646b9a764f6eb220517d0e9fc815_Out_2);
                    float3 _Add_d239c6ae017b45cba8fda7bfa29dc880_Out_2;
                    Unity_Add_float3(_Add_8d5fe4674e364518a5d8f4559669df92_Out_2, _Add_0992646b9a764f6eb220517d0e9fc815_Out_2, _Add_d239c6ae017b45cba8fda7bfa29dc880_Out_2);
                    Diffuse_1 = _Add_d239c6ae017b45cba8fda7bfa29dc880_Out_2;
                }
                
                void Unity_Smoothstep_float3(float3 Edge1, float3 Edge2, float3 In, out float3 Out)
                {
                    Out = smoothstep(Edge1, Edge2, In);
                }
                
                void Unity_Normalize_float3(float3 In, out float3 Out)
                {
                    Out = normalize(In);
                }
                
                void Unity_Power_float(float A, float B, out float Out)
                {
                    Out = pow(A, B);
                }
                
                void Unity_Step_float(float Edge, float In, out float Out)
                {
                    Out = step(Edge, In);
                }
                
                struct Bindings_CalcAdditionalSpecular_d84098efe9b2b6043a74a1631b825314
                {
                    float3 WorldSpaceNormal;
                    float3 WorldSpaceViewDirection;
                    float3 WorldSpacePosition;
                };
                
                void SG_CalcAdditionalSpecular_d84098efe9b2b6043a74a1631b825314(float Vector1_ba56f786be984242bee2ff33f2d093fc, Bindings_CalcAdditionalSpecular_d84098efe9b2b6043a74a1631b825314 IN, out float3 Diffuse_1)
                {
                    Bindings_GetAdditionalLight_b5516a5008f7d104abebe27210c42de8 _GetAdditionalLight_e6c10dfa199649fca18a0cb673fcba44;
                    float3 _GetAdditionalLight_e6c10dfa199649fca18a0cb673fcba44_Direction_0;
                    float3 _GetAdditionalLight_e6c10dfa199649fca18a0cb673fcba44_Color_1;
                    float _GetAdditionalLight_e6c10dfa199649fca18a0cb673fcba44_Attenuation_2;
                    SG_GetAdditionalLight_b5516a5008f7d104abebe27210c42de8(IN.WorldSpacePosition, 0, _GetAdditionalLight_e6c10dfa199649fca18a0cb673fcba44, _GetAdditionalLight_e6c10dfa199649fca18a0cb673fcba44_Direction_0, _GetAdditionalLight_e6c10dfa199649fca18a0cb673fcba44_Color_1, _GetAdditionalLight_e6c10dfa199649fca18a0cb673fcba44_Attenuation_2);
                    float3 _Add_7b85500005d849309401cd5cf5ee87fd_Out_2;
                    Unity_Add_float3(_GetAdditionalLight_e6c10dfa199649fca18a0cb673fcba44_Direction_0, IN.WorldSpaceViewDirection, _Add_7b85500005d849309401cd5cf5ee87fd_Out_2);
                    float3 _Normalize_e287e84e1db74e1d979a340af21eb458_Out_1;
                    Unity_Normalize_float3(_Add_7b85500005d849309401cd5cf5ee87fd_Out_2, _Normalize_e287e84e1db74e1d979a340af21eb458_Out_1);
                    float _DotProduct_aee5f4b498024e2da9796ed342f8a43a_Out_2;
                    Unity_DotProduct_float3(_Normalize_e287e84e1db74e1d979a340af21eb458_Out_1, IN.WorldSpaceNormal, _DotProduct_aee5f4b498024e2da9796ed342f8a43a_Out_2);
                    float _Saturate_2080d664f6004dc9ad574ba7e91917b2_Out_1;
                    Unity_Saturate_float(_DotProduct_aee5f4b498024e2da9796ed342f8a43a_Out_2, _Saturate_2080d664f6004dc9ad574ba7e91917b2_Out_1);
                    float _DotProduct_0526a944521c47d3b6c84b963fedd1ff_Out_2;
                    Unity_DotProduct_float3(_GetAdditionalLight_e6c10dfa199649fca18a0cb673fcba44_Direction_0, IN.WorldSpaceNormal, _DotProduct_0526a944521c47d3b6c84b963fedd1ff_Out_2);
                    float _Step_c67d6a53c975466dbaef6447b6a8bb15_Out_2;
                    Unity_Step_float(0, _DotProduct_0526a944521c47d3b6c84b963fedd1ff_Out_2, _Step_c67d6a53c975466dbaef6447b6a8bb15_Out_2);
                    float _Multiply_31278482890d4002a4b8eaea84d893d7_Out_2;
                    Unity_Multiply_float(_Saturate_2080d664f6004dc9ad574ba7e91917b2_Out_1, _Step_c67d6a53c975466dbaef6447b6a8bb15_Out_2, _Multiply_31278482890d4002a4b8eaea84d893d7_Out_2);
                    float _Property_b388a74e1b6a4d90939e467c9ef567a3_Out_0 = Vector1_ba56f786be984242bee2ff33f2d093fc;
                    float _Power_99f8e80de63e4acaa6046138e24f4bd2_Out_2;
                    Unity_Power_float(_Multiply_31278482890d4002a4b8eaea84d893d7_Out_2, _Property_b388a74e1b6a4d90939e467c9ef567a3_Out_0, _Power_99f8e80de63e4acaa6046138e24f4bd2_Out_2);
                    float3 _Multiply_9cc47eeb7de841d19b65dc8e1cb229c5_Out_2;
                    Unity_Multiply_float((_Power_99f8e80de63e4acaa6046138e24f4bd2_Out_2.xxx), _GetAdditionalLight_e6c10dfa199649fca18a0cb673fcba44_Color_1, _Multiply_9cc47eeb7de841d19b65dc8e1cb229c5_Out_2);
                    float3 _Multiply_40c5102279054efb933d4fd61a725966_Out_2;
                    Unity_Multiply_float(_Multiply_9cc47eeb7de841d19b65dc8e1cb229c5_Out_2, (_GetAdditionalLight_e6c10dfa199649fca18a0cb673fcba44_Attenuation_2.xxx), _Multiply_40c5102279054efb933d4fd61a725966_Out_2);
                    Bindings_GetAdditionalLight_b5516a5008f7d104abebe27210c42de8 _GetAdditionalLight_a054a4cd5b484e1492208dc9ca4a85f5;
                    float3 _GetAdditionalLight_a054a4cd5b484e1492208dc9ca4a85f5_Direction_0;
                    float3 _GetAdditionalLight_a054a4cd5b484e1492208dc9ca4a85f5_Color_1;
                    float _GetAdditionalLight_a054a4cd5b484e1492208dc9ca4a85f5_Attenuation_2;
                    SG_GetAdditionalLight_b5516a5008f7d104abebe27210c42de8(IN.WorldSpacePosition, 1, _GetAdditionalLight_a054a4cd5b484e1492208dc9ca4a85f5, _GetAdditionalLight_a054a4cd5b484e1492208dc9ca4a85f5_Direction_0, _GetAdditionalLight_a054a4cd5b484e1492208dc9ca4a85f5_Color_1, _GetAdditionalLight_a054a4cd5b484e1492208dc9ca4a85f5_Attenuation_2);
                    float3 _Add_282adf4f675a4392bdd7447da1537cff_Out_2;
                    Unity_Add_float3(_GetAdditionalLight_a054a4cd5b484e1492208dc9ca4a85f5_Direction_0, IN.WorldSpaceViewDirection, _Add_282adf4f675a4392bdd7447da1537cff_Out_2);
                    float3 _Normalize_d3d2dd5bbe7e4e749daa7d0b940b66e2_Out_1;
                    Unity_Normalize_float3(_Add_282adf4f675a4392bdd7447da1537cff_Out_2, _Normalize_d3d2dd5bbe7e4e749daa7d0b940b66e2_Out_1);
                    float _DotProduct_00e581a08ce7465588597fd11859eea2_Out_2;
                    Unity_DotProduct_float3(_Normalize_d3d2dd5bbe7e4e749daa7d0b940b66e2_Out_1, IN.WorldSpaceNormal, _DotProduct_00e581a08ce7465588597fd11859eea2_Out_2);
                    float _Saturate_58b5f4d3dcaf45e6bda212ef43edc4ea_Out_1;
                    Unity_Saturate_float(_DotProduct_00e581a08ce7465588597fd11859eea2_Out_2, _Saturate_58b5f4d3dcaf45e6bda212ef43edc4ea_Out_1);
                    float _DotProduct_e5d1d640606340949f9ecba8df9c866d_Out_2;
                    Unity_DotProduct_float3(_GetAdditionalLight_a054a4cd5b484e1492208dc9ca4a85f5_Direction_0, IN.WorldSpaceNormal, _DotProduct_e5d1d640606340949f9ecba8df9c866d_Out_2);
                    float _Step_d5595987000246e096b1bd14ec15600e_Out_2;
                    Unity_Step_float(0, _DotProduct_e5d1d640606340949f9ecba8df9c866d_Out_2, _Step_d5595987000246e096b1bd14ec15600e_Out_2);
                    float _Multiply_556cb17951c5463481d66c85c69f72ae_Out_2;
                    Unity_Multiply_float(_Saturate_58b5f4d3dcaf45e6bda212ef43edc4ea_Out_1, _Step_d5595987000246e096b1bd14ec15600e_Out_2, _Multiply_556cb17951c5463481d66c85c69f72ae_Out_2);
                    float _Power_1783632603444ae9bd39ecc3677738f0_Out_2;
                    Unity_Power_float(_Multiply_556cb17951c5463481d66c85c69f72ae_Out_2, _Property_b388a74e1b6a4d90939e467c9ef567a3_Out_0, _Power_1783632603444ae9bd39ecc3677738f0_Out_2);
                    float3 _Multiply_f4914d2b6dae4123a4ce1897d42f8dda_Out_2;
                    Unity_Multiply_float((_Power_1783632603444ae9bd39ecc3677738f0_Out_2.xxx), _GetAdditionalLight_a054a4cd5b484e1492208dc9ca4a85f5_Color_1, _Multiply_f4914d2b6dae4123a4ce1897d42f8dda_Out_2);
                    float3 _Multiply_dff05416518540d5b4d99dfdf00c5766_Out_2;
                    Unity_Multiply_float(_Multiply_f4914d2b6dae4123a4ce1897d42f8dda_Out_2, (_GetAdditionalLight_a054a4cd5b484e1492208dc9ca4a85f5_Attenuation_2.xxx), _Multiply_dff05416518540d5b4d99dfdf00c5766_Out_2);
                    float3 _Add_8d5fe4674e364518a5d8f4559669df92_Out_2;
                    Unity_Add_float3(_Multiply_40c5102279054efb933d4fd61a725966_Out_2, _Multiply_dff05416518540d5b4d99dfdf00c5766_Out_2, _Add_8d5fe4674e364518a5d8f4559669df92_Out_2);
                    Bindings_GetAdditionalLight_b5516a5008f7d104abebe27210c42de8 _GetAdditionalLight_ee2152ac3ed64138932b3a2e4b8e3f14;
                    float3 _GetAdditionalLight_ee2152ac3ed64138932b3a2e4b8e3f14_Direction_0;
                    float3 _GetAdditionalLight_ee2152ac3ed64138932b3a2e4b8e3f14_Color_1;
                    float _GetAdditionalLight_ee2152ac3ed64138932b3a2e4b8e3f14_Attenuation_2;
                    SG_GetAdditionalLight_b5516a5008f7d104abebe27210c42de8(IN.WorldSpacePosition, 2, _GetAdditionalLight_ee2152ac3ed64138932b3a2e4b8e3f14, _GetAdditionalLight_ee2152ac3ed64138932b3a2e4b8e3f14_Direction_0, _GetAdditionalLight_ee2152ac3ed64138932b3a2e4b8e3f14_Color_1, _GetAdditionalLight_ee2152ac3ed64138932b3a2e4b8e3f14_Attenuation_2);
                    float3 _Add_b3b13d361198482f9ee7222ea4d9d819_Out_2;
                    Unity_Add_float3(_GetAdditionalLight_ee2152ac3ed64138932b3a2e4b8e3f14_Direction_0, IN.WorldSpaceViewDirection, _Add_b3b13d361198482f9ee7222ea4d9d819_Out_2);
                    float3 _Normalize_ceaea3816fe94ba48dc9c37f6336e177_Out_1;
                    Unity_Normalize_float3(_Add_b3b13d361198482f9ee7222ea4d9d819_Out_2, _Normalize_ceaea3816fe94ba48dc9c37f6336e177_Out_1);
                    float _DotProduct_7a3fce316c4a453e9b9e18226fc2d066_Out_2;
                    Unity_DotProduct_float3(_Normalize_ceaea3816fe94ba48dc9c37f6336e177_Out_1, IN.WorldSpaceNormal, _DotProduct_7a3fce316c4a453e9b9e18226fc2d066_Out_2);
                    float _Saturate_c9919732b14f4622aa82e1eec5cb383d_Out_1;
                    Unity_Saturate_float(_DotProduct_7a3fce316c4a453e9b9e18226fc2d066_Out_2, _Saturate_c9919732b14f4622aa82e1eec5cb383d_Out_1);
                    float _DotProduct_172616bd9ee743ac9176fabfc0972b90_Out_2;
                    Unity_DotProduct_float3(_GetAdditionalLight_ee2152ac3ed64138932b3a2e4b8e3f14_Direction_0, IN.WorldSpaceNormal, _DotProduct_172616bd9ee743ac9176fabfc0972b90_Out_2);
                    float _Step_6ae114101d8f4d26a00a90cccaa45672_Out_2;
                    Unity_Step_float(0, _DotProduct_172616bd9ee743ac9176fabfc0972b90_Out_2, _Step_6ae114101d8f4d26a00a90cccaa45672_Out_2);
                    float _Multiply_4a9b97617c2448dea4f10cdcb58d4202_Out_2;
                    Unity_Multiply_float(_Saturate_c9919732b14f4622aa82e1eec5cb383d_Out_1, _Step_6ae114101d8f4d26a00a90cccaa45672_Out_2, _Multiply_4a9b97617c2448dea4f10cdcb58d4202_Out_2);
                    float _Power_0801befaab9143ffb3380be20bbdc5ab_Out_2;
                    Unity_Power_float(_Multiply_4a9b97617c2448dea4f10cdcb58d4202_Out_2, _Property_b388a74e1b6a4d90939e467c9ef567a3_Out_0, _Power_0801befaab9143ffb3380be20bbdc5ab_Out_2);
                    float3 _Multiply_cef864918e1e44799f326a20b8334c24_Out_2;
                    Unity_Multiply_float((_Power_0801befaab9143ffb3380be20bbdc5ab_Out_2.xxx), _GetAdditionalLight_ee2152ac3ed64138932b3a2e4b8e3f14_Color_1, _Multiply_cef864918e1e44799f326a20b8334c24_Out_2);
                    float3 _Multiply_d95d25aea25e4461b8a3af2420f0d8e2_Out_2;
                    Unity_Multiply_float(_Multiply_cef864918e1e44799f326a20b8334c24_Out_2, (_GetAdditionalLight_ee2152ac3ed64138932b3a2e4b8e3f14_Attenuation_2.xxx), _Multiply_d95d25aea25e4461b8a3af2420f0d8e2_Out_2);
                    Bindings_GetAdditionalLight_b5516a5008f7d104abebe27210c42de8 _GetAdditionalLight_da7753016bd64b489b897349d7f3fc0f;
                    float3 _GetAdditionalLight_da7753016bd64b489b897349d7f3fc0f_Direction_0;
                    float3 _GetAdditionalLight_da7753016bd64b489b897349d7f3fc0f_Color_1;
                    float _GetAdditionalLight_da7753016bd64b489b897349d7f3fc0f_Attenuation_2;
                    SG_GetAdditionalLight_b5516a5008f7d104abebe27210c42de8(IN.WorldSpacePosition, 3, _GetAdditionalLight_da7753016bd64b489b897349d7f3fc0f, _GetAdditionalLight_da7753016bd64b489b897349d7f3fc0f_Direction_0, _GetAdditionalLight_da7753016bd64b489b897349d7f3fc0f_Color_1, _GetAdditionalLight_da7753016bd64b489b897349d7f3fc0f_Attenuation_2);
                    float3 _Add_3d580f5eb4d44d1a9308632cf3541341_Out_2;
                    Unity_Add_float3(_GetAdditionalLight_da7753016bd64b489b897349d7f3fc0f_Direction_0, IN.WorldSpaceViewDirection, _Add_3d580f5eb4d44d1a9308632cf3541341_Out_2);
                    float3 _Normalize_d6753f83c1d7448991e6e7d8b08f3ffe_Out_1;
                    Unity_Normalize_float3(_Add_3d580f5eb4d44d1a9308632cf3541341_Out_2, _Normalize_d6753f83c1d7448991e6e7d8b08f3ffe_Out_1);
                    float _DotProduct_be3ed23b71d142e3a88f9f21ca2b9bb1_Out_2;
                    Unity_DotProduct_float3(_Normalize_d6753f83c1d7448991e6e7d8b08f3ffe_Out_1, IN.WorldSpaceNormal, _DotProduct_be3ed23b71d142e3a88f9f21ca2b9bb1_Out_2);
                    float _Saturate_b3794fe44470430e954d43bb481a3d9a_Out_1;
                    Unity_Saturate_float(_DotProduct_be3ed23b71d142e3a88f9f21ca2b9bb1_Out_2, _Saturate_b3794fe44470430e954d43bb481a3d9a_Out_1);
                    float _DotProduct_6919254c79d54f02beaaea46cea4bb88_Out_2;
                    Unity_DotProduct_float3(_GetAdditionalLight_da7753016bd64b489b897349d7f3fc0f_Direction_0, IN.WorldSpaceNormal, _DotProduct_6919254c79d54f02beaaea46cea4bb88_Out_2);
                    float _Step_298fb6a31079465894cd805c44c575e3_Out_2;
                    Unity_Step_float(0, _DotProduct_6919254c79d54f02beaaea46cea4bb88_Out_2, _Step_298fb6a31079465894cd805c44c575e3_Out_2);
                    float _Multiply_2531419c34224bfd8f2a6b986099fc14_Out_2;
                    Unity_Multiply_float(_Saturate_b3794fe44470430e954d43bb481a3d9a_Out_1, _Step_298fb6a31079465894cd805c44c575e3_Out_2, _Multiply_2531419c34224bfd8f2a6b986099fc14_Out_2);
                    float _Power_ef3de81b9a0f42a7a6689a0949350c4f_Out_2;
                    Unity_Power_float(_Multiply_2531419c34224bfd8f2a6b986099fc14_Out_2, _Property_b388a74e1b6a4d90939e467c9ef567a3_Out_0, _Power_ef3de81b9a0f42a7a6689a0949350c4f_Out_2);
                    float3 _Multiply_8962de9ab0024826abfc88590336908a_Out_2;
                    Unity_Multiply_float((_Power_ef3de81b9a0f42a7a6689a0949350c4f_Out_2.xxx), _GetAdditionalLight_da7753016bd64b489b897349d7f3fc0f_Color_1, _Multiply_8962de9ab0024826abfc88590336908a_Out_2);
                    float3 _Multiply_d130cd99cdd04ddbb2d61d5a1fa09fd9_Out_2;
                    Unity_Multiply_float(_Multiply_8962de9ab0024826abfc88590336908a_Out_2, (_GetAdditionalLight_da7753016bd64b489b897349d7f3fc0f_Attenuation_2.xxx), _Multiply_d130cd99cdd04ddbb2d61d5a1fa09fd9_Out_2);
                    float3 _Add_0992646b9a764f6eb220517d0e9fc815_Out_2;
                    Unity_Add_float3(_Multiply_d95d25aea25e4461b8a3af2420f0d8e2_Out_2, _Multiply_d130cd99cdd04ddbb2d61d5a1fa09fd9_Out_2, _Add_0992646b9a764f6eb220517d0e9fc815_Out_2);
                    float3 _Add_d239c6ae017b45cba8fda7bfa29dc880_Out_2;
                    Unity_Add_float3(_Add_8d5fe4674e364518a5d8f4559669df92_Out_2, _Add_0992646b9a764f6eb220517d0e9fc815_Out_2, _Add_d239c6ae017b45cba8fda7bfa29dc880_Out_2);
                    Diffuse_1 = _Add_d239c6ae017b45cba8fda7bfa29dc880_Out_2;
                }
                
                void Unity_Maximum_float3(float3 A, float3 B, out float3 Out)
                {
                    Out = max(A, B);
                }
    
                // Graph Vertex
                struct VertexDescription
                {
                    float3 Position;
                    float3 Normal;
                    float3 Tangent;
                };
                
                VertexDescription VertexDescriptionFunction(VertexDescriptionInputs IN)
                {
                    VertexDescription description = (VertexDescription)0;
                    description.Position = IN.ObjectSpacePosition;
                    description.Normal = IN.ObjectSpaceNormal;
                    description.Tangent = IN.ObjectSpaceTangent;
                    return description;
                }
    
                // Graph Pixel
                struct SurfaceDescription
                {
                    float3 BaseColor;
                    float3 NormalTS;
                    float3 Emission;
                    float Metallic;
                    float Smoothness;
                    float Occlusion;
                };
                
                SurfaceDescription SurfaceDescriptionFunction(SurfaceDescriptionInputs IN)
                {
                    SurfaceDescription surface = (SurfaceDescription)0;
                    float4 _Property_fd7e56b6f55544e1b80c8fd2c097fb78_Out_0 = _FresnelColor;
                    float _Property_faab3ff61e174da380387a5284f29359_Out_0 = _LightingCutoff;
                    float _Property_1f83c6224c604735b8fc5e7585df4c66_Out_0 = _FalloffAmount;
                    float _Add_b1804a0ba53b477b9d8fb474b3008e5f_Out_2;
                    Unity_Add_float(_Property_faab3ff61e174da380387a5284f29359_Out_0, _Property_1f83c6224c604735b8fc5e7585df4c66_Out_0, _Add_b1804a0ba53b477b9d8fb474b3008e5f_Out_2);
                    float _Property_f71948fe16194e1c9767bb52a648a2c1_Out_0 = _FresnelSize;
                    float _Reciprocal_1ab5ff841a4e496dbcaf48eca728ce63_Out_1;
                    Unity_Reciprocal_float(_Property_f71948fe16194e1c9767bb52a648a2c1_Out_0, _Reciprocal_1ab5ff841a4e496dbcaf48eca728ce63_Out_1);
                    float _FresnelEffect_b85b6878ded3452382e4918a35e68e34_Out_3;
                    Unity_FresnelEffect_float(IN.WorldSpaceNormal, IN.WorldSpaceViewDirection, _Reciprocal_1ab5ff841a4e496dbcaf48eca728ce63_Out_1, _FresnelEffect_b85b6878ded3452382e4918a35e68e34_Out_3);
                    Bindings_GetMainLight_d6b14a2e8b6f3554b8459648535f697e _GetMainLight_41b37094e05a429f8266b6602caf8242;
                    float3 _GetMainLight_41b37094e05a429f8266b6602caf8242_Direction_0;
                    float3 _GetMainLight_41b37094e05a429f8266b6602caf8242_Color_1;
                    float _GetMainLight_41b37094e05a429f8266b6602caf8242_Attenuation_2;
                    SG_GetMainLight_d6b14a2e8b6f3554b8459648535f697e(IN.WorldSpacePosition, _GetMainLight_41b37094e05a429f8266b6602caf8242, _GetMainLight_41b37094e05a429f8266b6602caf8242_Direction_0, _GetMainLight_41b37094e05a429f8266b6602caf8242_Color_1, _GetMainLight_41b37094e05a429f8266b6602caf8242_Attenuation_2);
                    float _DotProduct_8d4bdec92ac948559d5a94572dd8cb4d_Out_2;
                    Unity_DotProduct_float3(IN.WorldSpaceNormal, _GetMainLight_41b37094e05a429f8266b6602caf8242_Direction_0, _DotProduct_8d4bdec92ac948559d5a94572dd8cb4d_Out_2);
                    float _Multiply_315cde53c6dc4a3592ed4ee8f047be73_Out_2;
                    Unity_Multiply_float(_DotProduct_8d4bdec92ac948559d5a94572dd8cb4d_Out_2, _GetMainLight_41b37094e05a429f8266b6602caf8242_Attenuation_2, _Multiply_315cde53c6dc4a3592ed4ee8f047be73_Out_2);
                    float3 _Multiply_250e64e5c0fe4aa3aa2515f930a78e5a_Out_2;
                    Unity_Multiply_float((_Multiply_315cde53c6dc4a3592ed4ee8f047be73_Out_2.xxx), _GetMainLight_41b37094e05a429f8266b6602caf8242_Color_1, _Multiply_250e64e5c0fe4aa3aa2515f930a78e5a_Out_2);
                    float3 _Saturate_fdaf2acf4b0d40b3ae196b038de92740_Out_1;
                    Unity_Saturate_float3(_Multiply_250e64e5c0fe4aa3aa2515f930a78e5a_Out_2, _Saturate_fdaf2acf4b0d40b3ae196b038de92740_Out_1);
                    Bindings_CalcAdditionalDiffuse_e85823578a3493d41ade631af12166aa _CalcAdditionalDiffuse_f61ebb0caffa49798669b455d28ddc2f;
                    _CalcAdditionalDiffuse_f61ebb0caffa49798669b455d28ddc2f.WorldSpaceNormal = IN.WorldSpaceNormal;
                    _CalcAdditionalDiffuse_f61ebb0caffa49798669b455d28ddc2f.WorldSpacePosition = IN.WorldSpacePosition;
                    float3 _CalcAdditionalDiffuse_f61ebb0caffa49798669b455d28ddc2f_Diffuse_1;
                    SG_CalcAdditionalDiffuse_e85823578a3493d41ade631af12166aa(_CalcAdditionalDiffuse_f61ebb0caffa49798669b455d28ddc2f, _CalcAdditionalDiffuse_f61ebb0caffa49798669b455d28ddc2f_Diffuse_1);
                    float3 _Add_0f6ab824bf464526bbf3116b8d1e102f_Out_2;
                    Unity_Add_float3(_Saturate_fdaf2acf4b0d40b3ae196b038de92740_Out_1, _CalcAdditionalDiffuse_f61ebb0caffa49798669b455d28ddc2f_Diffuse_1, _Add_0f6ab824bf464526bbf3116b8d1e102f_Out_2);
                    float3 _Multiply_57cc1ea2df2f4223815236660d4ba4b2_Out_2;
                    Unity_Multiply_float((_FresnelEffect_b85b6878ded3452382e4918a35e68e34_Out_3.xxx), _Add_0f6ab824bf464526bbf3116b8d1e102f_Out_2, _Multiply_57cc1ea2df2f4223815236660d4ba4b2_Out_2);
                    float3 _Smoothstep_424686c920094f11a03df5f03afe5145_Out_3;
                    Unity_Smoothstep_float3((_Property_faab3ff61e174da380387a5284f29359_Out_0.xxx), (_Add_b1804a0ba53b477b9d8fb474b3008e5f_Out_2.xxx), _Multiply_57cc1ea2df2f4223815236660d4ba4b2_Out_2, _Smoothstep_424686c920094f11a03df5f03afe5145_Out_3);
                    float3 _Multiply_08e1c96546e24df2920fcd26690a7402_Out_2;
                    Unity_Multiply_float((_Property_fd7e56b6f55544e1b80c8fd2c097fb78_Out_0.xyz), _Smoothstep_424686c920094f11a03df5f03afe5145_Out_3, _Multiply_08e1c96546e24df2920fcd26690a7402_Out_2);
                    float4 _Property_0d605fca5a9b4f2e8020677b52b5629d_Out_0 = _SpecularColor;
                    float _Property_1d077dd941fc4016a62636a6048577bc_Out_0 = _LightingCutoff;
                    float _Property_2a13ac2eb2084e0f912c6485bff7e1fb_Out_0 = _FalloffAmount;
                    float _Add_aee813a1674a41449133aac98f918ac9_Out_2;
                    Unity_Add_float(_Property_1d077dd941fc4016a62636a6048577bc_Out_0, _Property_2a13ac2eb2084e0f912c6485bff7e1fb_Out_0, _Add_aee813a1674a41449133aac98f918ac9_Out_2);
                    Bindings_GetMainLight_d6b14a2e8b6f3554b8459648535f697e _GetMainLight_5a267f1983eb45038dd25d47096b3576;
                    float3 _GetMainLight_5a267f1983eb45038dd25d47096b3576_Direction_0;
                    float3 _GetMainLight_5a267f1983eb45038dd25d47096b3576_Color_1;
                    float _GetMainLight_5a267f1983eb45038dd25d47096b3576_Attenuation_2;
                    SG_GetMainLight_d6b14a2e8b6f3554b8459648535f697e(IN.WorldSpacePosition, _GetMainLight_5a267f1983eb45038dd25d47096b3576, _GetMainLight_5a267f1983eb45038dd25d47096b3576_Direction_0, _GetMainLight_5a267f1983eb45038dd25d47096b3576_Color_1, _GetMainLight_5a267f1983eb45038dd25d47096b3576_Attenuation_2);
                    float3 _Add_cdec837b18d14622929b74d779f9ed53_Out_2;
                    Unity_Add_float3(IN.WorldSpaceViewDirection, _GetMainLight_5a267f1983eb45038dd25d47096b3576_Direction_0, _Add_cdec837b18d14622929b74d779f9ed53_Out_2);
                    float3 _Normalize_4ed8697fa3534c40a04c3b38c2f39118_Out_1;
                    Unity_Normalize_float3(_Add_cdec837b18d14622929b74d779f9ed53_Out_2, _Normalize_4ed8697fa3534c40a04c3b38c2f39118_Out_1);
                    float _DotProduct_2a86b7ba7a4e47c1b993a25eea174112_Out_2;
                    Unity_DotProduct_float3(IN.WorldSpaceNormal, _Normalize_4ed8697fa3534c40a04c3b38c2f39118_Out_1, _DotProduct_2a86b7ba7a4e47c1b993a25eea174112_Out_2);
                    float _Saturate_5954bbc00cbe4ab1aaece8a4042a2ae1_Out_1;
                    Unity_Saturate_float(_DotProduct_2a86b7ba7a4e47c1b993a25eea174112_Out_2, _Saturate_5954bbc00cbe4ab1aaece8a4042a2ae1_Out_1);
                    float _Property_09addda5751f4ae38ffd75d2cf5042be_Out_0 = _Smoothness;
                    float _Power_d01facce68d2456bb5459bf9144d966c_Out_2;
                    Unity_Power_float(_Saturate_5954bbc00cbe4ab1aaece8a4042a2ae1_Out_1, _Property_09addda5751f4ae38ffd75d2cf5042be_Out_0, _Power_d01facce68d2456bb5459bf9144d966c_Out_2);
                    float3 _Multiply_37f25c3b613140a98d39720af3f46c04_Out_2;
                    Unity_Multiply_float((_Power_d01facce68d2456bb5459bf9144d966c_Out_2.xxx), _GetMainLight_5a267f1983eb45038dd25d47096b3576_Color_1, _Multiply_37f25c3b613140a98d39720af3f46c04_Out_2);
                    float3 _Multiply_40d12c060eda4e9293ea46113abcac99_Out_2;
                    Unity_Multiply_float(_Multiply_37f25c3b613140a98d39720af3f46c04_Out_2, (_GetMainLight_5a267f1983eb45038dd25d47096b3576_Attenuation_2.xxx), _Multiply_40d12c060eda4e9293ea46113abcac99_Out_2);
                    float3 _Multiply_20c6e31cff10450ab4a4e6910c501dff_Out_2;
                    Unity_Multiply_float(_Multiply_40d12c060eda4e9293ea46113abcac99_Out_2, _Saturate_fdaf2acf4b0d40b3ae196b038de92740_Out_1, _Multiply_20c6e31cff10450ab4a4e6910c501dff_Out_2);
                    Bindings_CalcAdditionalSpecular_d84098efe9b2b6043a74a1631b825314 _CalcAdditionalSpecular_cd3669952dc74dfe8fc61749791c4fda;
                    _CalcAdditionalSpecular_cd3669952dc74dfe8fc61749791c4fda.WorldSpaceNormal = IN.WorldSpaceNormal;
                    _CalcAdditionalSpecular_cd3669952dc74dfe8fc61749791c4fda.WorldSpaceViewDirection = IN.WorldSpaceViewDirection;
                    _CalcAdditionalSpecular_cd3669952dc74dfe8fc61749791c4fda.WorldSpacePosition = IN.WorldSpacePosition;
                    float3 _CalcAdditionalSpecular_cd3669952dc74dfe8fc61749791c4fda_Diffuse_1;
                    SG_CalcAdditionalSpecular_d84098efe9b2b6043a74a1631b825314(_Property_09addda5751f4ae38ffd75d2cf5042be_Out_0, _CalcAdditionalSpecular_cd3669952dc74dfe8fc61749791c4fda, _CalcAdditionalSpecular_cd3669952dc74dfe8fc61749791c4fda_Diffuse_1);
                    float3 _Add_6cdd48355c7448bbbc9dc34639d2f16d_Out_2;
                    Unity_Add_float3(_Multiply_20c6e31cff10450ab4a4e6910c501dff_Out_2, _CalcAdditionalSpecular_cd3669952dc74dfe8fc61749791c4fda_Diffuse_1, _Add_6cdd48355c7448bbbc9dc34639d2f16d_Out_2);
                    float3 _Smoothstep_46bf89c479e64da1a8083fa09e5d323d_Out_3;
                    Unity_Smoothstep_float3((_Property_1d077dd941fc4016a62636a6048577bc_Out_0.xxx), (_Add_aee813a1674a41449133aac98f918ac9_Out_2.xxx), _Add_6cdd48355c7448bbbc9dc34639d2f16d_Out_2, _Smoothstep_46bf89c479e64da1a8083fa09e5d323d_Out_3);
                    float3 _Multiply_fb48a1d2f9404211ad52dd2f26a46f28_Out_2;
                    Unity_Multiply_float((_Property_0d605fca5a9b4f2e8020677b52b5629d_Out_0.xyz), _Smoothstep_46bf89c479e64da1a8083fa09e5d323d_Out_3, _Multiply_fb48a1d2f9404211ad52dd2f26a46f28_Out_2);
                    float4 _Property_5bce803f7b1342118efa64dfd7a5c5af_Out_0 = _DiffuseColor;
                    float _Property_5b63eda1ad9a4c349b54058af0283a6a_Out_0 = _LightingCutoff;
                    float _Property_6b8c43c8c4e04f089b490e01842c10e7_Out_0 = _FalloffAmount;
                    float _Add_f9f052f699b24c22a7e6ed992dbded4d_Out_2;
                    Unity_Add_float(_Property_5b63eda1ad9a4c349b54058af0283a6a_Out_0, _Property_6b8c43c8c4e04f089b490e01842c10e7_Out_0, _Add_f9f052f699b24c22a7e6ed992dbded4d_Out_2);
                    float3 _Smoothstep_6421ae70d4a0477a913d197174717db2_Out_3;
                    Unity_Smoothstep_float3((_Property_5b63eda1ad9a4c349b54058af0283a6a_Out_0.xxx), (_Add_f9f052f699b24c22a7e6ed992dbded4d_Out_2.xxx), _Add_0f6ab824bf464526bbf3116b8d1e102f_Out_2, _Smoothstep_6421ae70d4a0477a913d197174717db2_Out_3);
                    float _Property_68149cd9c2eb40a79d0105acc016d1c4_Out_0 = _AmbientStrength;
                    float3 _Maximum_c73c7cbcf6c4463a865782d13a0c4101_Out_2;
                    Unity_Maximum_float3(_Smoothstep_6421ae70d4a0477a913d197174717db2_Out_3, (_Property_68149cd9c2eb40a79d0105acc016d1c4_Out_0.xxx), _Maximum_c73c7cbcf6c4463a865782d13a0c4101_Out_2);
                    float3 _Multiply_d622b247c4a84f8bbebf6a902f0b0fcb_Out_2;
                    Unity_Multiply_float((_Property_5bce803f7b1342118efa64dfd7a5c5af_Out_0.xyz), _Maximum_c73c7cbcf6c4463a865782d13a0c4101_Out_2, _Multiply_d622b247c4a84f8bbebf6a902f0b0fcb_Out_2);
                    UnityTexture2D _Property_a111b087fff64719b899025161b92d31_Out_0 = UnityBuildTexture2DStructNoScale(_MainTex);
                    float4 _SampleTexture2D_68405c1067a64b7f874afd25ede0e0c8_RGBA_0 = SAMPLE_TEXTURE2D(_Property_a111b087fff64719b899025161b92d31_Out_0.tex, _Property_a111b087fff64719b899025161b92d31_Out_0.samplerstate, IN.uv0.xy);
                    float _SampleTexture2D_68405c1067a64b7f874afd25ede0e0c8_R_4 = _SampleTexture2D_68405c1067a64b7f874afd25ede0e0c8_RGBA_0.r;
                    float _SampleTexture2D_68405c1067a64b7f874afd25ede0e0c8_G_5 = _SampleTexture2D_68405c1067a64b7f874afd25ede0e0c8_RGBA_0.g;
                    float _SampleTexture2D_68405c1067a64b7f874afd25ede0e0c8_B_6 = _SampleTexture2D_68405c1067a64b7f874afd25ede0e0c8_RGBA_0.b;
                    float _SampleTexture2D_68405c1067a64b7f874afd25ede0e0c8_A_7 = _SampleTexture2D_68405c1067a64b7f874afd25ede0e0c8_RGBA_0.a;
                    float3 _Multiply_8ac74964cd004464a81865818d5afcc4_Out_2;
                    Unity_Multiply_float(_Multiply_d622b247c4a84f8bbebf6a902f0b0fcb_Out_2, (_SampleTexture2D_68405c1067a64b7f874afd25ede0e0c8_RGBA_0.xyz), _Multiply_8ac74964cd004464a81865818d5afcc4_Out_2);
                    float3 _Add_2ebf33fa6b00434db9194d0243d86458_Out_2;
                    Unity_Add_float3(_Multiply_fb48a1d2f9404211ad52dd2f26a46f28_Out_2, _Multiply_8ac74964cd004464a81865818d5afcc4_Out_2, _Add_2ebf33fa6b00434db9194d0243d86458_Out_2);
                    float3 _Add_5db2a9e6feef42bc9e81d7017a4e1bd8_Out_2;
                    Unity_Add_float3(_Multiply_08e1c96546e24df2920fcd26690a7402_Out_2, _Add_2ebf33fa6b00434db9194d0243d86458_Out_2, _Add_5db2a9e6feef42bc9e81d7017a4e1bd8_Out_2);
                    surface.BaseColor = IsGammaSpace() ? float3(0, 0, 0) : SRGBToLinear(float3(0, 0, 0));
                    surface.NormalTS = IN.TangentSpaceNormal;
                    surface.Emission = _Add_5db2a9e6feef42bc9e81d7017a4e1bd8_Out_2;
                    surface.Metallic = 0;
                    surface.Smoothness = 0;
                    surface.Occlusion = 1;
                    return surface;
                }
    
                // --------------------------------------------------
                // Build Graph Inputs
    
                VertexDescriptionInputs BuildVertexDescriptionInputs(Attributes input)
                {
                    VertexDescriptionInputs output;
                    ZERO_INITIALIZE(VertexDescriptionInputs, output);
                
                    output.ObjectSpaceNormal =           input.normalOS;
                    output.ObjectSpaceTangent =          input.tangentOS.xyz;
                    output.ObjectSpacePosition =         input.positionOS;
                
                    return output;
                }
                
                SurfaceDescriptionInputs BuildSurfaceDescriptionInputs(Varyings input)
                {
                    SurfaceDescriptionInputs output;
                    ZERO_INITIALIZE(SurfaceDescriptionInputs, output);
                
                	// must use interpolated tangent, bitangent and normal before they are normalized in the pixel shader.
                	float3 unnormalizedNormalWS = input.normalWS;
                    const float renormFactor = 1.0 / length(unnormalizedNormalWS);
                
                
                    output.WorldSpaceNormal =            renormFactor*input.normalWS.xyz;		// we want a unit length Normal Vector node in shader graph
                    output.TangentSpaceNormal =          float3(0.0f, 0.0f, 1.0f);
                
                
                    output.WorldSpaceViewDirection =     input.viewDirectionWS; //TODO: by default normalized in HD, but not in universal
                    output.WorldSpacePosition =          input.positionWS;
                    output.uv0 =                         input.texCoord0;
                #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
                #define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN output.FaceSign =                    IS_FRONT_VFACE(input.cullFace, true, false);
                #else
                #define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN
                #endif
                #undef BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN
                
                    return output;
                }
                
    
                // --------------------------------------------------
                // Main
    
                #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/ShaderPass.hlsl"
                #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/Varyings.hlsl"
                #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/PBRForwardPass.hlsl"
    
                ENDHLSL
            }
            Pass
            {
                Name "GBuffer"
                Tags
                {
                    "LightMode" = "UniversalGBuffer"
                }
    
                // Render State
                Cull Back
                Blend One Zero
                ZTest LEqual
                ZWrite On
    
                // Debug
                // <None>
    
                // --------------------------------------------------
                // Pass
    
                HLSLPROGRAM
    
                // Pragmas
                #pragma target 4.5
                #pragma exclude_renderers gles gles3 glcore
                #pragma multi_compile_instancing
                #pragma multi_compile_fog
                #pragma multi_compile _ DOTS_INSTANCING_ON
                #pragma vertex vert
                #pragma fragment frag
    
                // DotsInstancingOptions: <None>
                // HybridV1InjectedBuiltinProperties: <None>
    
                // Keywords
                #pragma multi_compile _ LIGHTMAP_ON
                #pragma multi_compile _ DIRLIGHTMAP_COMBINED
                #pragma multi_compile _ _MAIN_LIGHT_SHADOWS
                #pragma multi_compile _ _MAIN_LIGHT_SHADOWS_CASCADE
                #pragma multi_compile _ _SHADOWS_SOFT
                #pragma multi_compile _ _MIXED_LIGHTING_SUBTRACTIVE
                #pragma multi_compile _ _GBUFFER_NORMALS_OCT
                // GraphKeywords: <None>
    
                // Defines
                #define _NORMALMAP 1
                #define _NORMAL_DROPOFF_TS 1
                #define ATTRIBUTES_NEED_NORMAL
                #define ATTRIBUTES_NEED_TANGENT
                #define ATTRIBUTES_NEED_TEXCOORD0
                #define ATTRIBUTES_NEED_TEXCOORD1
                #define VARYINGS_NEED_POSITION_WS
                #define VARYINGS_NEED_NORMAL_WS
                #define VARYINGS_NEED_TANGENT_WS
                #define VARYINGS_NEED_TEXCOORD0
                #define VARYINGS_NEED_VIEWDIRECTION_WS
                #define VARYINGS_NEED_FOG_AND_VERTEX_LIGHT
                #define FEATURES_GRAPH_VERTEX
                /* WARNING: $splice Could not find named fragment 'PassInstancing' */
                #define SHADERPASS SHADERPASS_GBUFFER
                /* WARNING: $splice Could not find named fragment 'DotsInstancingVars' */
    
                // Includes
                #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
                #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Texture.hlsl"
                #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
                #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
                #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/TextureStack.hlsl"
                #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Shadows.hlsl"
                #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"
    
                // --------------------------------------------------
                // Structs and Packing
    
                struct Attributes
                {
                    float3 positionOS : POSITION;
                    float3 normalOS : NORMAL;
                    float4 tangentOS : TANGENT;
                    float4 uv0 : TEXCOORD0;
                    float4 uv1 : TEXCOORD1;
                    #if UNITY_ANY_INSTANCING_ENABLED
                    uint instanceID : INSTANCEID_SEMANTIC;
                    #endif
                };
                struct Varyings
                {
                    float4 positionCS : SV_POSITION;
                    float3 positionWS;
                    float3 normalWS;
                    float4 tangentWS;
                    float4 texCoord0;
                    float3 viewDirectionWS;
                    #if defined(LIGHTMAP_ON)
                    float2 lightmapUV;
                    #endif
                    #if !defined(LIGHTMAP_ON)
                    float3 sh;
                    #endif
                    float4 fogFactorAndVertexLight;
                    float4 shadowCoord;
                    #if UNITY_ANY_INSTANCING_ENABLED
                    uint instanceID : CUSTOM_INSTANCE_ID;
                    #endif
                    #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
                    uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
                    #endif
                    #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
                    uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
                    #endif
                    #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
                    FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
                    #endif
                };
                struct SurfaceDescriptionInputs
                {
                    float3 WorldSpaceNormal;
                    float3 TangentSpaceNormal;
                    float3 WorldSpaceViewDirection;
                    float3 WorldSpacePosition;
                    float4 uv0;
                };
                struct VertexDescriptionInputs
                {
                    float3 ObjectSpaceNormal;
                    float3 ObjectSpaceTangent;
                    float3 ObjectSpacePosition;
                };
                struct PackedVaryings
                {
                    float4 positionCS : SV_POSITION;
                    float3 interp0 : TEXCOORD0;
                    float3 interp1 : TEXCOORD1;
                    float4 interp2 : TEXCOORD2;
                    float4 interp3 : TEXCOORD3;
                    float3 interp4 : TEXCOORD4;
                    #if defined(LIGHTMAP_ON)
                    float2 interp5 : TEXCOORD5;
                    #endif
                    #if !defined(LIGHTMAP_ON)
                    float3 interp6 : TEXCOORD6;
                    #endif
                    float4 interp7 : TEXCOORD7;
                    float4 interp8 : TEXCOORD8;
                    #if UNITY_ANY_INSTANCING_ENABLED
                    uint instanceID : CUSTOM_INSTANCE_ID;
                    #endif
                    #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
                    uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
                    #endif
                    #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
                    uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
                    #endif
                    #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
                    FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
                    #endif
                };
    
                PackedVaryings PackVaryings (Varyings input)
                {
                    PackedVaryings output;
                    output.positionCS = input.positionCS;
                    output.interp0.xyz =  input.positionWS;
                    output.interp1.xyz =  input.normalWS;
                    output.interp2.xyzw =  input.tangentWS;
                    output.interp3.xyzw =  input.texCoord0;
                    output.interp4.xyz =  input.viewDirectionWS;
                    #if defined(LIGHTMAP_ON)
                    output.interp5.xy =  input.lightmapUV;
                    #endif
                    #if !defined(LIGHTMAP_ON)
                    output.interp6.xyz =  input.sh;
                    #endif
                    output.interp7.xyzw =  input.fogFactorAndVertexLight;
                    output.interp8.xyzw =  input.shadowCoord;
                    #if UNITY_ANY_INSTANCING_ENABLED
                    output.instanceID = input.instanceID;
                    #endif
                    #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
                    output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
                    #endif
                    #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
                    output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
                    #endif
                    #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
                    output.cullFace = input.cullFace;
                    #endif
                    return output;
                }
                Varyings UnpackVaryings (PackedVaryings input)
                {
                    Varyings output;
                    output.positionCS = input.positionCS;
                    output.positionWS = input.interp0.xyz;
                    output.normalWS = input.interp1.xyz;
                    output.tangentWS = input.interp2.xyzw;
                    output.texCoord0 = input.interp3.xyzw;
                    output.viewDirectionWS = input.interp4.xyz;
                    #if defined(LIGHTMAP_ON)
                    output.lightmapUV = input.interp5.xy;
                    #endif
                    #if !defined(LIGHTMAP_ON)
                    output.sh = input.interp6.xyz;
                    #endif
                    output.fogFactorAndVertexLight = input.interp7.xyzw;
                    output.shadowCoord = input.interp8.xyzw;
                    #if UNITY_ANY_INSTANCING_ENABLED
                    output.instanceID = input.instanceID;
                    #endif
                    #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
                    output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
                    #endif
                    #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
                    output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
                    #endif
                    #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
                    output.cullFace = input.cullFace;
                    #endif
                    return output;
                }
    
                // --------------------------------------------------
                // Graph
    
                // Graph Properties
                CBUFFER_START(UnityPerMaterial)
                float _AmbientStrength;
                float4 _DiffuseColor;
                float4 _MainTex_TexelSize;
                float4 _SpecularColor;
                float4 _FresnelColor;
                float _Smoothness;
                float _FresnelSize;
                float _LightingCutoff;
                float _FalloffAmount;
                CBUFFER_END
                
                // Object and Global properties
                SAMPLER(SamplerState_Linear_Repeat);
                TEXTURE2D(_MainTex);
                SAMPLER(sampler_MainTex);
    
                // Graph Functions
                
                void Unity_Add_float(float A, float B, out float Out)
                {
                    Out = A + B;
                }
                
                void Unity_Reciprocal_float(float In, out float Out)
                {
                    Out = 1.0/In;
                }
                
                void Unity_FresnelEffect_float(float3 Normal, float3 ViewDir, float Power, out float Out)
                {
                    Out = pow((1.0 - saturate(dot(normalize(Normal), normalize(ViewDir)))), Power);
                }
                
                // a6264222ffebf7cfce349cb3e07ea356
                #include "./Lighting.hlsl"
                
                void Unity_Multiply_float(float A, float B, out float Out)
                {
                    Out = A * B;
                }
                
                struct Bindings_GetMainLight_d6b14a2e8b6f3554b8459648535f697e
                {
                };
                
                void SG_GetMainLight_d6b14a2e8b6f3554b8459648535f697e(float3 Vector3_b21c75b9b8514ef286d5e6dc199fa9af, Bindings_GetMainLight_d6b14a2e8b6f3554b8459648535f697e IN, out float3 Direction_0, out float3 Color_1, out float Attenuation_2)
                {
                    float3 _Property_923162a64885457196b5ccbf7a2aaac7_Out_0 = Vector3_b21c75b9b8514ef286d5e6dc199fa9af;
                    float3 _MainLightCustomFunction_93e39954c04146b5ae1be272ea9d714b_Direction_0;
                    float3 _MainLightCustomFunction_93e39954c04146b5ae1be272ea9d714b_Color_2;
                    float _MainLightCustomFunction_93e39954c04146b5ae1be272ea9d714b_DistanceAtten_3;
                    float _MainLightCustomFunction_93e39954c04146b5ae1be272ea9d714b_ShadowAtten_4;
                    MainLight_float(_Property_923162a64885457196b5ccbf7a2aaac7_Out_0, _MainLightCustomFunction_93e39954c04146b5ae1be272ea9d714b_Direction_0, _MainLightCustomFunction_93e39954c04146b5ae1be272ea9d714b_Color_2, _MainLightCustomFunction_93e39954c04146b5ae1be272ea9d714b_DistanceAtten_3, _MainLightCustomFunction_93e39954c04146b5ae1be272ea9d714b_ShadowAtten_4);
                    float _Multiply_6d878674c9b447478a9564442340c0a2_Out_2;
                    Unity_Multiply_float(_MainLightCustomFunction_93e39954c04146b5ae1be272ea9d714b_DistanceAtten_3, _MainLightCustomFunction_93e39954c04146b5ae1be272ea9d714b_ShadowAtten_4, _Multiply_6d878674c9b447478a9564442340c0a2_Out_2);
                    Direction_0 = _MainLightCustomFunction_93e39954c04146b5ae1be272ea9d714b_Direction_0;
                    Color_1 = _MainLightCustomFunction_93e39954c04146b5ae1be272ea9d714b_Color_2;
                    Attenuation_2 = _Multiply_6d878674c9b447478a9564442340c0a2_Out_2;
                }
                
                void Unity_DotProduct_float3(float3 A, float3 B, out float Out)
                {
                    Out = dot(A, B);
                }
                
                void Unity_Multiply_float(float3 A, float3 B, out float3 Out)
                {
                    Out = A * B;
                }
                
                void Unity_Saturate_float3(float3 In, out float3 Out)
                {
                    Out = saturate(In);
                }
                
                struct Bindings_GetAdditionalLight_b5516a5008f7d104abebe27210c42de8
                {
                };
                
                void SG_GetAdditionalLight_b5516a5008f7d104abebe27210c42de8(float3 Vector3_1e07dec0084a48e38c95166c3cdc688d, float Vector1_0ce9574e837f408991312a6c71473833, Bindings_GetAdditionalLight_b5516a5008f7d104abebe27210c42de8 IN, out float3 Direction_0, out float3 Color_1, out float Attenuation_2)
                {
                    float3 _Property_e9927ccc4a684aeabdaa70dbe76689f0_Out_0 = Vector3_1e07dec0084a48e38c95166c3cdc688d;
                    float _Property_c6fa454cb94449b6923e1c90fafaf929_Out_0 = Vector1_0ce9574e837f408991312a6c71473833;
                    float3 _AdditionalLightCustomFunction_c6ec52ed99634926b12dc96d48e96f1b_Direction_1;
                    float3 _AdditionalLightCustomFunction_c6ec52ed99634926b12dc96d48e96f1b_Color_2;
                    float _AdditionalLightCustomFunction_c6ec52ed99634926b12dc96d48e96f1b_DistanceAtten_3;
                    float _AdditionalLightCustomFunction_c6ec52ed99634926b12dc96d48e96f1b_ShadowAtten_4;
                    AdditionalLight_float(_Property_e9927ccc4a684aeabdaa70dbe76689f0_Out_0, _Property_c6fa454cb94449b6923e1c90fafaf929_Out_0, _AdditionalLightCustomFunction_c6ec52ed99634926b12dc96d48e96f1b_Direction_1, _AdditionalLightCustomFunction_c6ec52ed99634926b12dc96d48e96f1b_Color_2, _AdditionalLightCustomFunction_c6ec52ed99634926b12dc96d48e96f1b_DistanceAtten_3, _AdditionalLightCustomFunction_c6ec52ed99634926b12dc96d48e96f1b_ShadowAtten_4);
                    float _Multiply_0b8ec7bbb926441e8c14c7c32d369adf_Out_2;
                    Unity_Multiply_float(_AdditionalLightCustomFunction_c6ec52ed99634926b12dc96d48e96f1b_DistanceAtten_3, _AdditionalLightCustomFunction_c6ec52ed99634926b12dc96d48e96f1b_ShadowAtten_4, _Multiply_0b8ec7bbb926441e8c14c7c32d369adf_Out_2);
                    Direction_0 = _AdditionalLightCustomFunction_c6ec52ed99634926b12dc96d48e96f1b_Direction_1;
                    Color_1 = _AdditionalLightCustomFunction_c6ec52ed99634926b12dc96d48e96f1b_Color_2;
                    Attenuation_2 = _Multiply_0b8ec7bbb926441e8c14c7c32d369adf_Out_2;
                }
                
                void Unity_Saturate_float(float In, out float Out)
                {
                    Out = saturate(In);
                }
                
                void Unity_Add_float3(float3 A, float3 B, out float3 Out)
                {
                    Out = A + B;
                }
                
                struct Bindings_CalcAdditionalDiffuse_e85823578a3493d41ade631af12166aa
                {
                    float3 WorldSpaceNormal;
                    float3 WorldSpacePosition;
                };
                
                void SG_CalcAdditionalDiffuse_e85823578a3493d41ade631af12166aa(Bindings_CalcAdditionalDiffuse_e85823578a3493d41ade631af12166aa IN, out float3 Diffuse_1)
                {
                    Bindings_GetAdditionalLight_b5516a5008f7d104abebe27210c42de8 _GetAdditionalLight_e6c10dfa199649fca18a0cb673fcba44;
                    float3 _GetAdditionalLight_e6c10dfa199649fca18a0cb673fcba44_Direction_0;
                    float3 _GetAdditionalLight_e6c10dfa199649fca18a0cb673fcba44_Color_1;
                    float _GetAdditionalLight_e6c10dfa199649fca18a0cb673fcba44_Attenuation_2;
                    SG_GetAdditionalLight_b5516a5008f7d104abebe27210c42de8(IN.WorldSpacePosition, 0, _GetAdditionalLight_e6c10dfa199649fca18a0cb673fcba44, _GetAdditionalLight_e6c10dfa199649fca18a0cb673fcba44_Direction_0, _GetAdditionalLight_e6c10dfa199649fca18a0cb673fcba44_Color_1, _GetAdditionalLight_e6c10dfa199649fca18a0cb673fcba44_Attenuation_2);
                    float _DotProduct_aee5f4b498024e2da9796ed342f8a43a_Out_2;
                    Unity_DotProduct_float3(_GetAdditionalLight_e6c10dfa199649fca18a0cb673fcba44_Direction_0, IN.WorldSpaceNormal, _DotProduct_aee5f4b498024e2da9796ed342f8a43a_Out_2);
                    float _Saturate_2080d664f6004dc9ad574ba7e91917b2_Out_1;
                    Unity_Saturate_float(_DotProduct_aee5f4b498024e2da9796ed342f8a43a_Out_2, _Saturate_2080d664f6004dc9ad574ba7e91917b2_Out_1);
                    float3 _Multiply_57fcc7dc0fb845cf924c855eadbb7792_Out_2;
                    Unity_Multiply_float((_Saturate_2080d664f6004dc9ad574ba7e91917b2_Out_1.xxx), _GetAdditionalLight_e6c10dfa199649fca18a0cb673fcba44_Color_1, _Multiply_57fcc7dc0fb845cf924c855eadbb7792_Out_2);
                    float3 _Multiply_59016ca5433045d0a06ff03a13ec13b6_Out_2;
                    Unity_Multiply_float(_Multiply_57fcc7dc0fb845cf924c855eadbb7792_Out_2, (_GetAdditionalLight_e6c10dfa199649fca18a0cb673fcba44_Attenuation_2.xxx), _Multiply_59016ca5433045d0a06ff03a13ec13b6_Out_2);
                    Bindings_GetAdditionalLight_b5516a5008f7d104abebe27210c42de8 _GetAdditionalLight_a054a4cd5b484e1492208dc9ca4a85f5;
                    float3 _GetAdditionalLight_a054a4cd5b484e1492208dc9ca4a85f5_Direction_0;
                    float3 _GetAdditionalLight_a054a4cd5b484e1492208dc9ca4a85f5_Color_1;
                    float _GetAdditionalLight_a054a4cd5b484e1492208dc9ca4a85f5_Attenuation_2;
                    SG_GetAdditionalLight_b5516a5008f7d104abebe27210c42de8(IN.WorldSpacePosition, 1, _GetAdditionalLight_a054a4cd5b484e1492208dc9ca4a85f5, _GetAdditionalLight_a054a4cd5b484e1492208dc9ca4a85f5_Direction_0, _GetAdditionalLight_a054a4cd5b484e1492208dc9ca4a85f5_Color_1, _GetAdditionalLight_a054a4cd5b484e1492208dc9ca4a85f5_Attenuation_2);
                    float _DotProduct_00e581a08ce7465588597fd11859eea2_Out_2;
                    Unity_DotProduct_float3(_GetAdditionalLight_a054a4cd5b484e1492208dc9ca4a85f5_Direction_0, IN.WorldSpaceNormal, _DotProduct_00e581a08ce7465588597fd11859eea2_Out_2);
                    float _Saturate_58b5f4d3dcaf45e6bda212ef43edc4ea_Out_1;
                    Unity_Saturate_float(_DotProduct_00e581a08ce7465588597fd11859eea2_Out_2, _Saturate_58b5f4d3dcaf45e6bda212ef43edc4ea_Out_1);
                    float3 _Multiply_6ff1cb7ecc8542848d8d721f284a3b3c_Out_2;
                    Unity_Multiply_float((_Saturate_58b5f4d3dcaf45e6bda212ef43edc4ea_Out_1.xxx), _GetAdditionalLight_a054a4cd5b484e1492208dc9ca4a85f5_Color_1, _Multiply_6ff1cb7ecc8542848d8d721f284a3b3c_Out_2);
                    float3 _Multiply_8337e9ec92b74cefb421776f67b29661_Out_2;
                    Unity_Multiply_float(_Multiply_6ff1cb7ecc8542848d8d721f284a3b3c_Out_2, (_GetAdditionalLight_a054a4cd5b484e1492208dc9ca4a85f5_Attenuation_2.xxx), _Multiply_8337e9ec92b74cefb421776f67b29661_Out_2);
                    float3 _Add_8d5fe4674e364518a5d8f4559669df92_Out_2;
                    Unity_Add_float3(_Multiply_59016ca5433045d0a06ff03a13ec13b6_Out_2, _Multiply_8337e9ec92b74cefb421776f67b29661_Out_2, _Add_8d5fe4674e364518a5d8f4559669df92_Out_2);
                    Bindings_GetAdditionalLight_b5516a5008f7d104abebe27210c42de8 _GetAdditionalLight_ee2152ac3ed64138932b3a2e4b8e3f14;
                    float3 _GetAdditionalLight_ee2152ac3ed64138932b3a2e4b8e3f14_Direction_0;
                    float3 _GetAdditionalLight_ee2152ac3ed64138932b3a2e4b8e3f14_Color_1;
                    float _GetAdditionalLight_ee2152ac3ed64138932b3a2e4b8e3f14_Attenuation_2;
                    SG_GetAdditionalLight_b5516a5008f7d104abebe27210c42de8(IN.WorldSpacePosition, 2, _GetAdditionalLight_ee2152ac3ed64138932b3a2e4b8e3f14, _GetAdditionalLight_ee2152ac3ed64138932b3a2e4b8e3f14_Direction_0, _GetAdditionalLight_ee2152ac3ed64138932b3a2e4b8e3f14_Color_1, _GetAdditionalLight_ee2152ac3ed64138932b3a2e4b8e3f14_Attenuation_2);
                    float _DotProduct_7a3fce316c4a453e9b9e18226fc2d066_Out_2;
                    Unity_DotProduct_float3(_GetAdditionalLight_ee2152ac3ed64138932b3a2e4b8e3f14_Direction_0, IN.WorldSpaceNormal, _DotProduct_7a3fce316c4a453e9b9e18226fc2d066_Out_2);
                    float _Saturate_c9919732b14f4622aa82e1eec5cb383d_Out_1;
                    Unity_Saturate_float(_DotProduct_7a3fce316c4a453e9b9e18226fc2d066_Out_2, _Saturate_c9919732b14f4622aa82e1eec5cb383d_Out_1);
                    float3 _Multiply_013e04c47fdf4f46a7f2a4868ec83bed_Out_2;
                    Unity_Multiply_float((_Saturate_c9919732b14f4622aa82e1eec5cb383d_Out_1.xxx), _GetAdditionalLight_ee2152ac3ed64138932b3a2e4b8e3f14_Color_1, _Multiply_013e04c47fdf4f46a7f2a4868ec83bed_Out_2);
                    float3 _Multiply_8d16da0d689d4d49909909e6c2cc2da6_Out_2;
                    Unity_Multiply_float(_Multiply_013e04c47fdf4f46a7f2a4868ec83bed_Out_2, (_GetAdditionalLight_ee2152ac3ed64138932b3a2e4b8e3f14_Attenuation_2.xxx), _Multiply_8d16da0d689d4d49909909e6c2cc2da6_Out_2);
                    Bindings_GetAdditionalLight_b5516a5008f7d104abebe27210c42de8 _GetAdditionalLight_da7753016bd64b489b897349d7f3fc0f;
                    float3 _GetAdditionalLight_da7753016bd64b489b897349d7f3fc0f_Direction_0;
                    float3 _GetAdditionalLight_da7753016bd64b489b897349d7f3fc0f_Color_1;
                    float _GetAdditionalLight_da7753016bd64b489b897349d7f3fc0f_Attenuation_2;
                    SG_GetAdditionalLight_b5516a5008f7d104abebe27210c42de8(IN.WorldSpacePosition, 3, _GetAdditionalLight_da7753016bd64b489b897349d7f3fc0f, _GetAdditionalLight_da7753016bd64b489b897349d7f3fc0f_Direction_0, _GetAdditionalLight_da7753016bd64b489b897349d7f3fc0f_Color_1, _GetAdditionalLight_da7753016bd64b489b897349d7f3fc0f_Attenuation_2);
                    float _DotProduct_be3ed23b71d142e3a88f9f21ca2b9bb1_Out_2;
                    Unity_DotProduct_float3(_GetAdditionalLight_da7753016bd64b489b897349d7f3fc0f_Direction_0, IN.WorldSpaceNormal, _DotProduct_be3ed23b71d142e3a88f9f21ca2b9bb1_Out_2);
                    float _Saturate_b3794fe44470430e954d43bb481a3d9a_Out_1;
                    Unity_Saturate_float(_DotProduct_be3ed23b71d142e3a88f9f21ca2b9bb1_Out_2, _Saturate_b3794fe44470430e954d43bb481a3d9a_Out_1);
                    float3 _Multiply_fcf9bc551f0e42f39634ac95fab7cae5_Out_2;
                    Unity_Multiply_float((_Saturate_b3794fe44470430e954d43bb481a3d9a_Out_1.xxx), _GetAdditionalLight_da7753016bd64b489b897349d7f3fc0f_Color_1, _Multiply_fcf9bc551f0e42f39634ac95fab7cae5_Out_2);
                    float3 _Multiply_0cc8c00775354d6a9f91977c3e357ff8_Out_2;
                    Unity_Multiply_float(_Multiply_fcf9bc551f0e42f39634ac95fab7cae5_Out_2, (_GetAdditionalLight_da7753016bd64b489b897349d7f3fc0f_Attenuation_2.xxx), _Multiply_0cc8c00775354d6a9f91977c3e357ff8_Out_2);
                    float3 _Add_0992646b9a764f6eb220517d0e9fc815_Out_2;
                    Unity_Add_float3(_Multiply_8d16da0d689d4d49909909e6c2cc2da6_Out_2, _Multiply_0cc8c00775354d6a9f91977c3e357ff8_Out_2, _Add_0992646b9a764f6eb220517d0e9fc815_Out_2);
                    float3 _Add_d239c6ae017b45cba8fda7bfa29dc880_Out_2;
                    Unity_Add_float3(_Add_8d5fe4674e364518a5d8f4559669df92_Out_2, _Add_0992646b9a764f6eb220517d0e9fc815_Out_2, _Add_d239c6ae017b45cba8fda7bfa29dc880_Out_2);
                    Diffuse_1 = _Add_d239c6ae017b45cba8fda7bfa29dc880_Out_2;
                }
                
                void Unity_Smoothstep_float3(float3 Edge1, float3 Edge2, float3 In, out float3 Out)
                {
                    Out = smoothstep(Edge1, Edge2, In);
                }
                
                void Unity_Normalize_float3(float3 In, out float3 Out)
                {
                    Out = normalize(In);
                }
                
                void Unity_Power_float(float A, float B, out float Out)
                {
                    Out = pow(A, B);
                }
                
                void Unity_Step_float(float Edge, float In, out float Out)
                {
                    Out = step(Edge, In);
                }
                
                struct Bindings_CalcAdditionalSpecular_d84098efe9b2b6043a74a1631b825314
                {
                    float3 WorldSpaceNormal;
                    float3 WorldSpaceViewDirection;
                    float3 WorldSpacePosition;
                };
                
                void SG_CalcAdditionalSpecular_d84098efe9b2b6043a74a1631b825314(float Vector1_ba56f786be984242bee2ff33f2d093fc, Bindings_CalcAdditionalSpecular_d84098efe9b2b6043a74a1631b825314 IN, out float3 Diffuse_1)
                {
                    Bindings_GetAdditionalLight_b5516a5008f7d104abebe27210c42de8 _GetAdditionalLight_e6c10dfa199649fca18a0cb673fcba44;
                    float3 _GetAdditionalLight_e6c10dfa199649fca18a0cb673fcba44_Direction_0;
                    float3 _GetAdditionalLight_e6c10dfa199649fca18a0cb673fcba44_Color_1;
                    float _GetAdditionalLight_e6c10dfa199649fca18a0cb673fcba44_Attenuation_2;
                    SG_GetAdditionalLight_b5516a5008f7d104abebe27210c42de8(IN.WorldSpacePosition, 0, _GetAdditionalLight_e6c10dfa199649fca18a0cb673fcba44, _GetAdditionalLight_e6c10dfa199649fca18a0cb673fcba44_Direction_0, _GetAdditionalLight_e6c10dfa199649fca18a0cb673fcba44_Color_1, _GetAdditionalLight_e6c10dfa199649fca18a0cb673fcba44_Attenuation_2);
                    float3 _Add_7b85500005d849309401cd5cf5ee87fd_Out_2;
                    Unity_Add_float3(_GetAdditionalLight_e6c10dfa199649fca18a0cb673fcba44_Direction_0, IN.WorldSpaceViewDirection, _Add_7b85500005d849309401cd5cf5ee87fd_Out_2);
                    float3 _Normalize_e287e84e1db74e1d979a340af21eb458_Out_1;
                    Unity_Normalize_float3(_Add_7b85500005d849309401cd5cf5ee87fd_Out_2, _Normalize_e287e84e1db74e1d979a340af21eb458_Out_1);
                    float _DotProduct_aee5f4b498024e2da9796ed342f8a43a_Out_2;
                    Unity_DotProduct_float3(_Normalize_e287e84e1db74e1d979a340af21eb458_Out_1, IN.WorldSpaceNormal, _DotProduct_aee5f4b498024e2da9796ed342f8a43a_Out_2);
                    float _Saturate_2080d664f6004dc9ad574ba7e91917b2_Out_1;
                    Unity_Saturate_float(_DotProduct_aee5f4b498024e2da9796ed342f8a43a_Out_2, _Saturate_2080d664f6004dc9ad574ba7e91917b2_Out_1);
                    float _DotProduct_0526a944521c47d3b6c84b963fedd1ff_Out_2;
                    Unity_DotProduct_float3(_GetAdditionalLight_e6c10dfa199649fca18a0cb673fcba44_Direction_0, IN.WorldSpaceNormal, _DotProduct_0526a944521c47d3b6c84b963fedd1ff_Out_2);
                    float _Step_c67d6a53c975466dbaef6447b6a8bb15_Out_2;
                    Unity_Step_float(0, _DotProduct_0526a944521c47d3b6c84b963fedd1ff_Out_2, _Step_c67d6a53c975466dbaef6447b6a8bb15_Out_2);
                    float _Multiply_31278482890d4002a4b8eaea84d893d7_Out_2;
                    Unity_Multiply_float(_Saturate_2080d664f6004dc9ad574ba7e91917b2_Out_1, _Step_c67d6a53c975466dbaef6447b6a8bb15_Out_2, _Multiply_31278482890d4002a4b8eaea84d893d7_Out_2);
                    float _Property_b388a74e1b6a4d90939e467c9ef567a3_Out_0 = Vector1_ba56f786be984242bee2ff33f2d093fc;
                    float _Power_99f8e80de63e4acaa6046138e24f4bd2_Out_2;
                    Unity_Power_float(_Multiply_31278482890d4002a4b8eaea84d893d7_Out_2, _Property_b388a74e1b6a4d90939e467c9ef567a3_Out_0, _Power_99f8e80de63e4acaa6046138e24f4bd2_Out_2);
                    float3 _Multiply_9cc47eeb7de841d19b65dc8e1cb229c5_Out_2;
                    Unity_Multiply_float((_Power_99f8e80de63e4acaa6046138e24f4bd2_Out_2.xxx), _GetAdditionalLight_e6c10dfa199649fca18a0cb673fcba44_Color_1, _Multiply_9cc47eeb7de841d19b65dc8e1cb229c5_Out_2);
                    float3 _Multiply_40c5102279054efb933d4fd61a725966_Out_2;
                    Unity_Multiply_float(_Multiply_9cc47eeb7de841d19b65dc8e1cb229c5_Out_2, (_GetAdditionalLight_e6c10dfa199649fca18a0cb673fcba44_Attenuation_2.xxx), _Multiply_40c5102279054efb933d4fd61a725966_Out_2);
                    Bindings_GetAdditionalLight_b5516a5008f7d104abebe27210c42de8 _GetAdditionalLight_a054a4cd5b484e1492208dc9ca4a85f5;
                    float3 _GetAdditionalLight_a054a4cd5b484e1492208dc9ca4a85f5_Direction_0;
                    float3 _GetAdditionalLight_a054a4cd5b484e1492208dc9ca4a85f5_Color_1;
                    float _GetAdditionalLight_a054a4cd5b484e1492208dc9ca4a85f5_Attenuation_2;
                    SG_GetAdditionalLight_b5516a5008f7d104abebe27210c42de8(IN.WorldSpacePosition, 1, _GetAdditionalLight_a054a4cd5b484e1492208dc9ca4a85f5, _GetAdditionalLight_a054a4cd5b484e1492208dc9ca4a85f5_Direction_0, _GetAdditionalLight_a054a4cd5b484e1492208dc9ca4a85f5_Color_1, _GetAdditionalLight_a054a4cd5b484e1492208dc9ca4a85f5_Attenuation_2);
                    float3 _Add_282adf4f675a4392bdd7447da1537cff_Out_2;
                    Unity_Add_float3(_GetAdditionalLight_a054a4cd5b484e1492208dc9ca4a85f5_Direction_0, IN.WorldSpaceViewDirection, _Add_282adf4f675a4392bdd7447da1537cff_Out_2);
                    float3 _Normalize_d3d2dd5bbe7e4e749daa7d0b940b66e2_Out_1;
                    Unity_Normalize_float3(_Add_282adf4f675a4392bdd7447da1537cff_Out_2, _Normalize_d3d2dd5bbe7e4e749daa7d0b940b66e2_Out_1);
                    float _DotProduct_00e581a08ce7465588597fd11859eea2_Out_2;
                    Unity_DotProduct_float3(_Normalize_d3d2dd5bbe7e4e749daa7d0b940b66e2_Out_1, IN.WorldSpaceNormal, _DotProduct_00e581a08ce7465588597fd11859eea2_Out_2);
                    float _Saturate_58b5f4d3dcaf45e6bda212ef43edc4ea_Out_1;
                    Unity_Saturate_float(_DotProduct_00e581a08ce7465588597fd11859eea2_Out_2, _Saturate_58b5f4d3dcaf45e6bda212ef43edc4ea_Out_1);
                    float _DotProduct_e5d1d640606340949f9ecba8df9c866d_Out_2;
                    Unity_DotProduct_float3(_GetAdditionalLight_a054a4cd5b484e1492208dc9ca4a85f5_Direction_0, IN.WorldSpaceNormal, _DotProduct_e5d1d640606340949f9ecba8df9c866d_Out_2);
                    float _Step_d5595987000246e096b1bd14ec15600e_Out_2;
                    Unity_Step_float(0, _DotProduct_e5d1d640606340949f9ecba8df9c866d_Out_2, _Step_d5595987000246e096b1bd14ec15600e_Out_2);
                    float _Multiply_556cb17951c5463481d66c85c69f72ae_Out_2;
                    Unity_Multiply_float(_Saturate_58b5f4d3dcaf45e6bda212ef43edc4ea_Out_1, _Step_d5595987000246e096b1bd14ec15600e_Out_2, _Multiply_556cb17951c5463481d66c85c69f72ae_Out_2);
                    float _Power_1783632603444ae9bd39ecc3677738f0_Out_2;
                    Unity_Power_float(_Multiply_556cb17951c5463481d66c85c69f72ae_Out_2, _Property_b388a74e1b6a4d90939e467c9ef567a3_Out_0, _Power_1783632603444ae9bd39ecc3677738f0_Out_2);
                    float3 _Multiply_f4914d2b6dae4123a4ce1897d42f8dda_Out_2;
                    Unity_Multiply_float((_Power_1783632603444ae9bd39ecc3677738f0_Out_2.xxx), _GetAdditionalLight_a054a4cd5b484e1492208dc9ca4a85f5_Color_1, _Multiply_f4914d2b6dae4123a4ce1897d42f8dda_Out_2);
                    float3 _Multiply_dff05416518540d5b4d99dfdf00c5766_Out_2;
                    Unity_Multiply_float(_Multiply_f4914d2b6dae4123a4ce1897d42f8dda_Out_2, (_GetAdditionalLight_a054a4cd5b484e1492208dc9ca4a85f5_Attenuation_2.xxx), _Multiply_dff05416518540d5b4d99dfdf00c5766_Out_2);
                    float3 _Add_8d5fe4674e364518a5d8f4559669df92_Out_2;
                    Unity_Add_float3(_Multiply_40c5102279054efb933d4fd61a725966_Out_2, _Multiply_dff05416518540d5b4d99dfdf00c5766_Out_2, _Add_8d5fe4674e364518a5d8f4559669df92_Out_2);
                    Bindings_GetAdditionalLight_b5516a5008f7d104abebe27210c42de8 _GetAdditionalLight_ee2152ac3ed64138932b3a2e4b8e3f14;
                    float3 _GetAdditionalLight_ee2152ac3ed64138932b3a2e4b8e3f14_Direction_0;
                    float3 _GetAdditionalLight_ee2152ac3ed64138932b3a2e4b8e3f14_Color_1;
                    float _GetAdditionalLight_ee2152ac3ed64138932b3a2e4b8e3f14_Attenuation_2;
                    SG_GetAdditionalLight_b5516a5008f7d104abebe27210c42de8(IN.WorldSpacePosition, 2, _GetAdditionalLight_ee2152ac3ed64138932b3a2e4b8e3f14, _GetAdditionalLight_ee2152ac3ed64138932b3a2e4b8e3f14_Direction_0, _GetAdditionalLight_ee2152ac3ed64138932b3a2e4b8e3f14_Color_1, _GetAdditionalLight_ee2152ac3ed64138932b3a2e4b8e3f14_Attenuation_2);
                    float3 _Add_b3b13d361198482f9ee7222ea4d9d819_Out_2;
                    Unity_Add_float3(_GetAdditionalLight_ee2152ac3ed64138932b3a2e4b8e3f14_Direction_0, IN.WorldSpaceViewDirection, _Add_b3b13d361198482f9ee7222ea4d9d819_Out_2);
                    float3 _Normalize_ceaea3816fe94ba48dc9c37f6336e177_Out_1;
                    Unity_Normalize_float3(_Add_b3b13d361198482f9ee7222ea4d9d819_Out_2, _Normalize_ceaea3816fe94ba48dc9c37f6336e177_Out_1);
                    float _DotProduct_7a3fce316c4a453e9b9e18226fc2d066_Out_2;
                    Unity_DotProduct_float3(_Normalize_ceaea3816fe94ba48dc9c37f6336e177_Out_1, IN.WorldSpaceNormal, _DotProduct_7a3fce316c4a453e9b9e18226fc2d066_Out_2);
                    float _Saturate_c9919732b14f4622aa82e1eec5cb383d_Out_1;
                    Unity_Saturate_float(_DotProduct_7a3fce316c4a453e9b9e18226fc2d066_Out_2, _Saturate_c9919732b14f4622aa82e1eec5cb383d_Out_1);
                    float _DotProduct_172616bd9ee743ac9176fabfc0972b90_Out_2;
                    Unity_DotProduct_float3(_GetAdditionalLight_ee2152ac3ed64138932b3a2e4b8e3f14_Direction_0, IN.WorldSpaceNormal, _DotProduct_172616bd9ee743ac9176fabfc0972b90_Out_2);
                    float _Step_6ae114101d8f4d26a00a90cccaa45672_Out_2;
                    Unity_Step_float(0, _DotProduct_172616bd9ee743ac9176fabfc0972b90_Out_2, _Step_6ae114101d8f4d26a00a90cccaa45672_Out_2);
                    float _Multiply_4a9b97617c2448dea4f10cdcb58d4202_Out_2;
                    Unity_Multiply_float(_Saturate_c9919732b14f4622aa82e1eec5cb383d_Out_1, _Step_6ae114101d8f4d26a00a90cccaa45672_Out_2, _Multiply_4a9b97617c2448dea4f10cdcb58d4202_Out_2);
                    float _Power_0801befaab9143ffb3380be20bbdc5ab_Out_2;
                    Unity_Power_float(_Multiply_4a9b97617c2448dea4f10cdcb58d4202_Out_2, _Property_b388a74e1b6a4d90939e467c9ef567a3_Out_0, _Power_0801befaab9143ffb3380be20bbdc5ab_Out_2);
                    float3 _Multiply_cef864918e1e44799f326a20b8334c24_Out_2;
                    Unity_Multiply_float((_Power_0801befaab9143ffb3380be20bbdc5ab_Out_2.xxx), _GetAdditionalLight_ee2152ac3ed64138932b3a2e4b8e3f14_Color_1, _Multiply_cef864918e1e44799f326a20b8334c24_Out_2);
                    float3 _Multiply_d95d25aea25e4461b8a3af2420f0d8e2_Out_2;
                    Unity_Multiply_float(_Multiply_cef864918e1e44799f326a20b8334c24_Out_2, (_GetAdditionalLight_ee2152ac3ed64138932b3a2e4b8e3f14_Attenuation_2.xxx), _Multiply_d95d25aea25e4461b8a3af2420f0d8e2_Out_2);
                    Bindings_GetAdditionalLight_b5516a5008f7d104abebe27210c42de8 _GetAdditionalLight_da7753016bd64b489b897349d7f3fc0f;
                    float3 _GetAdditionalLight_da7753016bd64b489b897349d7f3fc0f_Direction_0;
                    float3 _GetAdditionalLight_da7753016bd64b489b897349d7f3fc0f_Color_1;
                    float _GetAdditionalLight_da7753016bd64b489b897349d7f3fc0f_Attenuation_2;
                    SG_GetAdditionalLight_b5516a5008f7d104abebe27210c42de8(IN.WorldSpacePosition, 3, _GetAdditionalLight_da7753016bd64b489b897349d7f3fc0f, _GetAdditionalLight_da7753016bd64b489b897349d7f3fc0f_Direction_0, _GetAdditionalLight_da7753016bd64b489b897349d7f3fc0f_Color_1, _GetAdditionalLight_da7753016bd64b489b897349d7f3fc0f_Attenuation_2);
                    float3 _Add_3d580f5eb4d44d1a9308632cf3541341_Out_2;
                    Unity_Add_float3(_GetAdditionalLight_da7753016bd64b489b897349d7f3fc0f_Direction_0, IN.WorldSpaceViewDirection, _Add_3d580f5eb4d44d1a9308632cf3541341_Out_2);
                    float3 _Normalize_d6753f83c1d7448991e6e7d8b08f3ffe_Out_1;
                    Unity_Normalize_float3(_Add_3d580f5eb4d44d1a9308632cf3541341_Out_2, _Normalize_d6753f83c1d7448991e6e7d8b08f3ffe_Out_1);
                    float _DotProduct_be3ed23b71d142e3a88f9f21ca2b9bb1_Out_2;
                    Unity_DotProduct_float3(_Normalize_d6753f83c1d7448991e6e7d8b08f3ffe_Out_1, IN.WorldSpaceNormal, _DotProduct_be3ed23b71d142e3a88f9f21ca2b9bb1_Out_2);
                    float _Saturate_b3794fe44470430e954d43bb481a3d9a_Out_1;
                    Unity_Saturate_float(_DotProduct_be3ed23b71d142e3a88f9f21ca2b9bb1_Out_2, _Saturate_b3794fe44470430e954d43bb481a3d9a_Out_1);
                    float _DotProduct_6919254c79d54f02beaaea46cea4bb88_Out_2;
                    Unity_DotProduct_float3(_GetAdditionalLight_da7753016bd64b489b897349d7f3fc0f_Direction_0, IN.WorldSpaceNormal, _DotProduct_6919254c79d54f02beaaea46cea4bb88_Out_2);
                    float _Step_298fb6a31079465894cd805c44c575e3_Out_2;
                    Unity_Step_float(0, _DotProduct_6919254c79d54f02beaaea46cea4bb88_Out_2, _Step_298fb6a31079465894cd805c44c575e3_Out_2);
                    float _Multiply_2531419c34224bfd8f2a6b986099fc14_Out_2;
                    Unity_Multiply_float(_Saturate_b3794fe44470430e954d43bb481a3d9a_Out_1, _Step_298fb6a31079465894cd805c44c575e3_Out_2, _Multiply_2531419c34224bfd8f2a6b986099fc14_Out_2);
                    float _Power_ef3de81b9a0f42a7a6689a0949350c4f_Out_2;
                    Unity_Power_float(_Multiply_2531419c34224bfd8f2a6b986099fc14_Out_2, _Property_b388a74e1b6a4d90939e467c9ef567a3_Out_0, _Power_ef3de81b9a0f42a7a6689a0949350c4f_Out_2);
                    float3 _Multiply_8962de9ab0024826abfc88590336908a_Out_2;
                    Unity_Multiply_float((_Power_ef3de81b9a0f42a7a6689a0949350c4f_Out_2.xxx), _GetAdditionalLight_da7753016bd64b489b897349d7f3fc0f_Color_1, _Multiply_8962de9ab0024826abfc88590336908a_Out_2);
                    float3 _Multiply_d130cd99cdd04ddbb2d61d5a1fa09fd9_Out_2;
                    Unity_Multiply_float(_Multiply_8962de9ab0024826abfc88590336908a_Out_2, (_GetAdditionalLight_da7753016bd64b489b897349d7f3fc0f_Attenuation_2.xxx), _Multiply_d130cd99cdd04ddbb2d61d5a1fa09fd9_Out_2);
                    float3 _Add_0992646b9a764f6eb220517d0e9fc815_Out_2;
                    Unity_Add_float3(_Multiply_d95d25aea25e4461b8a3af2420f0d8e2_Out_2, _Multiply_d130cd99cdd04ddbb2d61d5a1fa09fd9_Out_2, _Add_0992646b9a764f6eb220517d0e9fc815_Out_2);
                    float3 _Add_d239c6ae017b45cba8fda7bfa29dc880_Out_2;
                    Unity_Add_float3(_Add_8d5fe4674e364518a5d8f4559669df92_Out_2, _Add_0992646b9a764f6eb220517d0e9fc815_Out_2, _Add_d239c6ae017b45cba8fda7bfa29dc880_Out_2);
                    Diffuse_1 = _Add_d239c6ae017b45cba8fda7bfa29dc880_Out_2;
                }
                
                void Unity_Maximum_float3(float3 A, float3 B, out float3 Out)
                {
                    Out = max(A, B);
                }
    
                // Graph Vertex
                struct VertexDescription
                {
                    float3 Position;
                    float3 Normal;
                    float3 Tangent;
                };
                
                VertexDescription VertexDescriptionFunction(VertexDescriptionInputs IN)
                {
                    VertexDescription description = (VertexDescription)0;
                    description.Position = IN.ObjectSpacePosition;
                    description.Normal = IN.ObjectSpaceNormal;
                    description.Tangent = IN.ObjectSpaceTangent;
                    return description;
                }
    
                // Graph Pixel
                struct SurfaceDescription
                {
                    float3 BaseColor;
                    float3 NormalTS;
                    float3 Emission;
                    float Metallic;
                    float Smoothness;
                    float Occlusion;
                };
                
                SurfaceDescription SurfaceDescriptionFunction(SurfaceDescriptionInputs IN)
                {
                    SurfaceDescription surface = (SurfaceDescription)0;
                    float4 _Property_fd7e56b6f55544e1b80c8fd2c097fb78_Out_0 = _FresnelColor;
                    float _Property_faab3ff61e174da380387a5284f29359_Out_0 = _LightingCutoff;
                    float _Property_1f83c6224c604735b8fc5e7585df4c66_Out_0 = _FalloffAmount;
                    float _Add_b1804a0ba53b477b9d8fb474b3008e5f_Out_2;
                    Unity_Add_float(_Property_faab3ff61e174da380387a5284f29359_Out_0, _Property_1f83c6224c604735b8fc5e7585df4c66_Out_0, _Add_b1804a0ba53b477b9d8fb474b3008e5f_Out_2);
                    float _Property_f71948fe16194e1c9767bb52a648a2c1_Out_0 = _FresnelSize;
                    float _Reciprocal_1ab5ff841a4e496dbcaf48eca728ce63_Out_1;
                    Unity_Reciprocal_float(_Property_f71948fe16194e1c9767bb52a648a2c1_Out_0, _Reciprocal_1ab5ff841a4e496dbcaf48eca728ce63_Out_1);
                    float _FresnelEffect_b85b6878ded3452382e4918a35e68e34_Out_3;
                    Unity_FresnelEffect_float(IN.WorldSpaceNormal, IN.WorldSpaceViewDirection, _Reciprocal_1ab5ff841a4e496dbcaf48eca728ce63_Out_1, _FresnelEffect_b85b6878ded3452382e4918a35e68e34_Out_3);
                    Bindings_GetMainLight_d6b14a2e8b6f3554b8459648535f697e _GetMainLight_41b37094e05a429f8266b6602caf8242;
                    float3 _GetMainLight_41b37094e05a429f8266b6602caf8242_Direction_0;
                    float3 _GetMainLight_41b37094e05a429f8266b6602caf8242_Color_1;
                    float _GetMainLight_41b37094e05a429f8266b6602caf8242_Attenuation_2;
                    SG_GetMainLight_d6b14a2e8b6f3554b8459648535f697e(IN.WorldSpacePosition, _GetMainLight_41b37094e05a429f8266b6602caf8242, _GetMainLight_41b37094e05a429f8266b6602caf8242_Direction_0, _GetMainLight_41b37094e05a429f8266b6602caf8242_Color_1, _GetMainLight_41b37094e05a429f8266b6602caf8242_Attenuation_2);
                    float _DotProduct_8d4bdec92ac948559d5a94572dd8cb4d_Out_2;
                    Unity_DotProduct_float3(IN.WorldSpaceNormal, _GetMainLight_41b37094e05a429f8266b6602caf8242_Direction_0, _DotProduct_8d4bdec92ac948559d5a94572dd8cb4d_Out_2);
                    float _Multiply_315cde53c6dc4a3592ed4ee8f047be73_Out_2;
                    Unity_Multiply_float(_DotProduct_8d4bdec92ac948559d5a94572dd8cb4d_Out_2, _GetMainLight_41b37094e05a429f8266b6602caf8242_Attenuation_2, _Multiply_315cde53c6dc4a3592ed4ee8f047be73_Out_2);
                    float3 _Multiply_250e64e5c0fe4aa3aa2515f930a78e5a_Out_2;
                    Unity_Multiply_float((_Multiply_315cde53c6dc4a3592ed4ee8f047be73_Out_2.xxx), _GetMainLight_41b37094e05a429f8266b6602caf8242_Color_1, _Multiply_250e64e5c0fe4aa3aa2515f930a78e5a_Out_2);
                    float3 _Saturate_fdaf2acf4b0d40b3ae196b038de92740_Out_1;
                    Unity_Saturate_float3(_Multiply_250e64e5c0fe4aa3aa2515f930a78e5a_Out_2, _Saturate_fdaf2acf4b0d40b3ae196b038de92740_Out_1);
                    Bindings_CalcAdditionalDiffuse_e85823578a3493d41ade631af12166aa _CalcAdditionalDiffuse_f61ebb0caffa49798669b455d28ddc2f;
                    _CalcAdditionalDiffuse_f61ebb0caffa49798669b455d28ddc2f.WorldSpaceNormal = IN.WorldSpaceNormal;
                    _CalcAdditionalDiffuse_f61ebb0caffa49798669b455d28ddc2f.WorldSpacePosition = IN.WorldSpacePosition;
                    float3 _CalcAdditionalDiffuse_f61ebb0caffa49798669b455d28ddc2f_Diffuse_1;
                    SG_CalcAdditionalDiffuse_e85823578a3493d41ade631af12166aa(_CalcAdditionalDiffuse_f61ebb0caffa49798669b455d28ddc2f, _CalcAdditionalDiffuse_f61ebb0caffa49798669b455d28ddc2f_Diffuse_1);
                    float3 _Add_0f6ab824bf464526bbf3116b8d1e102f_Out_2;
                    Unity_Add_float3(_Saturate_fdaf2acf4b0d40b3ae196b038de92740_Out_1, _CalcAdditionalDiffuse_f61ebb0caffa49798669b455d28ddc2f_Diffuse_1, _Add_0f6ab824bf464526bbf3116b8d1e102f_Out_2);
                    float3 _Multiply_57cc1ea2df2f4223815236660d4ba4b2_Out_2;
                    Unity_Multiply_float((_FresnelEffect_b85b6878ded3452382e4918a35e68e34_Out_3.xxx), _Add_0f6ab824bf464526bbf3116b8d1e102f_Out_2, _Multiply_57cc1ea2df2f4223815236660d4ba4b2_Out_2);
                    float3 _Smoothstep_424686c920094f11a03df5f03afe5145_Out_3;
                    Unity_Smoothstep_float3((_Property_faab3ff61e174da380387a5284f29359_Out_0.xxx), (_Add_b1804a0ba53b477b9d8fb474b3008e5f_Out_2.xxx), _Multiply_57cc1ea2df2f4223815236660d4ba4b2_Out_2, _Smoothstep_424686c920094f11a03df5f03afe5145_Out_3);
                    float3 _Multiply_08e1c96546e24df2920fcd26690a7402_Out_2;
                    Unity_Multiply_float((_Property_fd7e56b6f55544e1b80c8fd2c097fb78_Out_0.xyz), _Smoothstep_424686c920094f11a03df5f03afe5145_Out_3, _Multiply_08e1c96546e24df2920fcd26690a7402_Out_2);
                    float4 _Property_0d605fca5a9b4f2e8020677b52b5629d_Out_0 = _SpecularColor;
                    float _Property_1d077dd941fc4016a62636a6048577bc_Out_0 = _LightingCutoff;
                    float _Property_2a13ac2eb2084e0f912c6485bff7e1fb_Out_0 = _FalloffAmount;
                    float _Add_aee813a1674a41449133aac98f918ac9_Out_2;
                    Unity_Add_float(_Property_1d077dd941fc4016a62636a6048577bc_Out_0, _Property_2a13ac2eb2084e0f912c6485bff7e1fb_Out_0, _Add_aee813a1674a41449133aac98f918ac9_Out_2);
                    Bindings_GetMainLight_d6b14a2e8b6f3554b8459648535f697e _GetMainLight_5a267f1983eb45038dd25d47096b3576;
                    float3 _GetMainLight_5a267f1983eb45038dd25d47096b3576_Direction_0;
                    float3 _GetMainLight_5a267f1983eb45038dd25d47096b3576_Color_1;
                    float _GetMainLight_5a267f1983eb45038dd25d47096b3576_Attenuation_2;
                    SG_GetMainLight_d6b14a2e8b6f3554b8459648535f697e(IN.WorldSpacePosition, _GetMainLight_5a267f1983eb45038dd25d47096b3576, _GetMainLight_5a267f1983eb45038dd25d47096b3576_Direction_0, _GetMainLight_5a267f1983eb45038dd25d47096b3576_Color_1, _GetMainLight_5a267f1983eb45038dd25d47096b3576_Attenuation_2);
                    float3 _Add_cdec837b18d14622929b74d779f9ed53_Out_2;
                    Unity_Add_float3(IN.WorldSpaceViewDirection, _GetMainLight_5a267f1983eb45038dd25d47096b3576_Direction_0, _Add_cdec837b18d14622929b74d779f9ed53_Out_2);
                    float3 _Normalize_4ed8697fa3534c40a04c3b38c2f39118_Out_1;
                    Unity_Normalize_float3(_Add_cdec837b18d14622929b74d779f9ed53_Out_2, _Normalize_4ed8697fa3534c40a04c3b38c2f39118_Out_1);
                    float _DotProduct_2a86b7ba7a4e47c1b993a25eea174112_Out_2;
                    Unity_DotProduct_float3(IN.WorldSpaceNormal, _Normalize_4ed8697fa3534c40a04c3b38c2f39118_Out_1, _DotProduct_2a86b7ba7a4e47c1b993a25eea174112_Out_2);
                    float _Saturate_5954bbc00cbe4ab1aaece8a4042a2ae1_Out_1;
                    Unity_Saturate_float(_DotProduct_2a86b7ba7a4e47c1b993a25eea174112_Out_2, _Saturate_5954bbc00cbe4ab1aaece8a4042a2ae1_Out_1);
                    float _Property_09addda5751f4ae38ffd75d2cf5042be_Out_0 = _Smoothness;
                    float _Power_d01facce68d2456bb5459bf9144d966c_Out_2;
                    Unity_Power_float(_Saturate_5954bbc00cbe4ab1aaece8a4042a2ae1_Out_1, _Property_09addda5751f4ae38ffd75d2cf5042be_Out_0, _Power_d01facce68d2456bb5459bf9144d966c_Out_2);
                    float3 _Multiply_37f25c3b613140a98d39720af3f46c04_Out_2;
                    Unity_Multiply_float((_Power_d01facce68d2456bb5459bf9144d966c_Out_2.xxx), _GetMainLight_5a267f1983eb45038dd25d47096b3576_Color_1, _Multiply_37f25c3b613140a98d39720af3f46c04_Out_2);
                    float3 _Multiply_40d12c060eda4e9293ea46113abcac99_Out_2;
                    Unity_Multiply_float(_Multiply_37f25c3b613140a98d39720af3f46c04_Out_2, (_GetMainLight_5a267f1983eb45038dd25d47096b3576_Attenuation_2.xxx), _Multiply_40d12c060eda4e9293ea46113abcac99_Out_2);
                    float3 _Multiply_20c6e31cff10450ab4a4e6910c501dff_Out_2;
                    Unity_Multiply_float(_Multiply_40d12c060eda4e9293ea46113abcac99_Out_2, _Saturate_fdaf2acf4b0d40b3ae196b038de92740_Out_1, _Multiply_20c6e31cff10450ab4a4e6910c501dff_Out_2);
                    Bindings_CalcAdditionalSpecular_d84098efe9b2b6043a74a1631b825314 _CalcAdditionalSpecular_cd3669952dc74dfe8fc61749791c4fda;
                    _CalcAdditionalSpecular_cd3669952dc74dfe8fc61749791c4fda.WorldSpaceNormal = IN.WorldSpaceNormal;
                    _CalcAdditionalSpecular_cd3669952dc74dfe8fc61749791c4fda.WorldSpaceViewDirection = IN.WorldSpaceViewDirection;
                    _CalcAdditionalSpecular_cd3669952dc74dfe8fc61749791c4fda.WorldSpacePosition = IN.WorldSpacePosition;
                    float3 _CalcAdditionalSpecular_cd3669952dc74dfe8fc61749791c4fda_Diffuse_1;
                    SG_CalcAdditionalSpecular_d84098efe9b2b6043a74a1631b825314(_Property_09addda5751f4ae38ffd75d2cf5042be_Out_0, _CalcAdditionalSpecular_cd3669952dc74dfe8fc61749791c4fda, _CalcAdditionalSpecular_cd3669952dc74dfe8fc61749791c4fda_Diffuse_1);
                    float3 _Add_6cdd48355c7448bbbc9dc34639d2f16d_Out_2;
                    Unity_Add_float3(_Multiply_20c6e31cff10450ab4a4e6910c501dff_Out_2, _CalcAdditionalSpecular_cd3669952dc74dfe8fc61749791c4fda_Diffuse_1, _Add_6cdd48355c7448bbbc9dc34639d2f16d_Out_2);
                    float3 _Smoothstep_46bf89c479e64da1a8083fa09e5d323d_Out_3;
                    Unity_Smoothstep_float3((_Property_1d077dd941fc4016a62636a6048577bc_Out_0.xxx), (_Add_aee813a1674a41449133aac98f918ac9_Out_2.xxx), _Add_6cdd48355c7448bbbc9dc34639d2f16d_Out_2, _Smoothstep_46bf89c479e64da1a8083fa09e5d323d_Out_3);
                    float3 _Multiply_fb48a1d2f9404211ad52dd2f26a46f28_Out_2;
                    Unity_Multiply_float((_Property_0d605fca5a9b4f2e8020677b52b5629d_Out_0.xyz), _Smoothstep_46bf89c479e64da1a8083fa09e5d323d_Out_3, _Multiply_fb48a1d2f9404211ad52dd2f26a46f28_Out_2);
                    float4 _Property_5bce803f7b1342118efa64dfd7a5c5af_Out_0 = _DiffuseColor;
                    float _Property_5b63eda1ad9a4c349b54058af0283a6a_Out_0 = _LightingCutoff;
                    float _Property_6b8c43c8c4e04f089b490e01842c10e7_Out_0 = _FalloffAmount;
                    float _Add_f9f052f699b24c22a7e6ed992dbded4d_Out_2;
                    Unity_Add_float(_Property_5b63eda1ad9a4c349b54058af0283a6a_Out_0, _Property_6b8c43c8c4e04f089b490e01842c10e7_Out_0, _Add_f9f052f699b24c22a7e6ed992dbded4d_Out_2);
                    float3 _Smoothstep_6421ae70d4a0477a913d197174717db2_Out_3;
                    Unity_Smoothstep_float3((_Property_5b63eda1ad9a4c349b54058af0283a6a_Out_0.xxx), (_Add_f9f052f699b24c22a7e6ed992dbded4d_Out_2.xxx), _Add_0f6ab824bf464526bbf3116b8d1e102f_Out_2, _Smoothstep_6421ae70d4a0477a913d197174717db2_Out_3);
                    float _Property_68149cd9c2eb40a79d0105acc016d1c4_Out_0 = _AmbientStrength;
                    float3 _Maximum_c73c7cbcf6c4463a865782d13a0c4101_Out_2;
                    Unity_Maximum_float3(_Smoothstep_6421ae70d4a0477a913d197174717db2_Out_3, (_Property_68149cd9c2eb40a79d0105acc016d1c4_Out_0.xxx), _Maximum_c73c7cbcf6c4463a865782d13a0c4101_Out_2);
                    float3 _Multiply_d622b247c4a84f8bbebf6a902f0b0fcb_Out_2;
                    Unity_Multiply_float((_Property_5bce803f7b1342118efa64dfd7a5c5af_Out_0.xyz), _Maximum_c73c7cbcf6c4463a865782d13a0c4101_Out_2, _Multiply_d622b247c4a84f8bbebf6a902f0b0fcb_Out_2);
                    UnityTexture2D _Property_a111b087fff64719b899025161b92d31_Out_0 = UnityBuildTexture2DStructNoScale(_MainTex);
                    float4 _SampleTexture2D_68405c1067a64b7f874afd25ede0e0c8_RGBA_0 = SAMPLE_TEXTURE2D(_Property_a111b087fff64719b899025161b92d31_Out_0.tex, _Property_a111b087fff64719b899025161b92d31_Out_0.samplerstate, IN.uv0.xy);
                    float _SampleTexture2D_68405c1067a64b7f874afd25ede0e0c8_R_4 = _SampleTexture2D_68405c1067a64b7f874afd25ede0e0c8_RGBA_0.r;
                    float _SampleTexture2D_68405c1067a64b7f874afd25ede0e0c8_G_5 = _SampleTexture2D_68405c1067a64b7f874afd25ede0e0c8_RGBA_0.g;
                    float _SampleTexture2D_68405c1067a64b7f874afd25ede0e0c8_B_6 = _SampleTexture2D_68405c1067a64b7f874afd25ede0e0c8_RGBA_0.b;
                    float _SampleTexture2D_68405c1067a64b7f874afd25ede0e0c8_A_7 = _SampleTexture2D_68405c1067a64b7f874afd25ede0e0c8_RGBA_0.a;
                    float3 _Multiply_8ac74964cd004464a81865818d5afcc4_Out_2;
                    Unity_Multiply_float(_Multiply_d622b247c4a84f8bbebf6a902f0b0fcb_Out_2, (_SampleTexture2D_68405c1067a64b7f874afd25ede0e0c8_RGBA_0.xyz), _Multiply_8ac74964cd004464a81865818d5afcc4_Out_2);
                    float3 _Add_2ebf33fa6b00434db9194d0243d86458_Out_2;
                    Unity_Add_float3(_Multiply_fb48a1d2f9404211ad52dd2f26a46f28_Out_2, _Multiply_8ac74964cd004464a81865818d5afcc4_Out_2, _Add_2ebf33fa6b00434db9194d0243d86458_Out_2);
                    float3 _Add_5db2a9e6feef42bc9e81d7017a4e1bd8_Out_2;
                    Unity_Add_float3(_Multiply_08e1c96546e24df2920fcd26690a7402_Out_2, _Add_2ebf33fa6b00434db9194d0243d86458_Out_2, _Add_5db2a9e6feef42bc9e81d7017a4e1bd8_Out_2);
                    surface.BaseColor = IsGammaSpace() ? float3(0, 0, 0) : SRGBToLinear(float3(0, 0, 0));
                    surface.NormalTS = IN.TangentSpaceNormal;
                    surface.Emission = _Add_5db2a9e6feef42bc9e81d7017a4e1bd8_Out_2;
                    surface.Metallic = 0;
                    surface.Smoothness = 0;
                    surface.Occlusion = 1;
                    return surface;
                }
    
                // --------------------------------------------------
                // Build Graph Inputs
    
                VertexDescriptionInputs BuildVertexDescriptionInputs(Attributes input)
                {
                    VertexDescriptionInputs output;
                    ZERO_INITIALIZE(VertexDescriptionInputs, output);
                
                    output.ObjectSpaceNormal =           input.normalOS;
                    output.ObjectSpaceTangent =          input.tangentOS.xyz;
                    output.ObjectSpacePosition =         input.positionOS;
                
                    return output;
                }
                
                SurfaceDescriptionInputs BuildSurfaceDescriptionInputs(Varyings input)
                {
                    SurfaceDescriptionInputs output;
                    ZERO_INITIALIZE(SurfaceDescriptionInputs, output);
                
                	// must use interpolated tangent, bitangent and normal before they are normalized in the pixel shader.
                	float3 unnormalizedNormalWS = input.normalWS;
                    const float renormFactor = 1.0 / length(unnormalizedNormalWS);
                
                
                    output.WorldSpaceNormal =            renormFactor*input.normalWS.xyz;		// we want a unit length Normal Vector node in shader graph
                    output.TangentSpaceNormal =          float3(0.0f, 0.0f, 1.0f);
                
                
                    output.WorldSpaceViewDirection =     input.viewDirectionWS; //TODO: by default normalized in HD, but not in universal
                    output.WorldSpacePosition =          input.positionWS;
                    output.uv0 =                         input.texCoord0;
                #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
                #define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN output.FaceSign =                    IS_FRONT_VFACE(input.cullFace, true, false);
                #else
                #define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN
                #endif
                #undef BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN
                
                    return output;
                }
                
    
                // --------------------------------------------------
                // Main
    
                #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/ShaderPass.hlsl"
                #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/Varyings.hlsl"
                #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/UnityGBuffer.hlsl"
                #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/PBRGBufferPass.hlsl"
    
                ENDHLSL
            }

            Pass 
            {
                Name "Outline"
                Tags 
                {
                    // IMPORTANT: don't write this line for any custom pass! else this outline pass will not be rendered by URP!
                    //"LightMode" = "UniversalForward" 

                    // [Important CPU performance note]
                    // If you need to add a custom pass to your shader (outline pass, planar shadow pass, XRay pass when blocked....),
                    // (0) Add a new Pass{} to your shader
                    // (1) Write "LightMode" = "YourCustomPassTag" inside new Pass's Tags{}
                    // (2) Add a new custom RendererFeature(C#) to your renderer,
                    // (3) write cmd.DrawRenderers() with ShaderPassName = "YourCustomPassTag"
                    // (4) if done correctly, URP will render your new Pass{} for your shader, in a SRP-batcher friendly way (usually in 1 big SRP batch)

                    // For tutorial purpose, current everything is just shader files without any C#, so this Outline pass is actually NOT SRP-batcher friendly.
                    // If you are working on a project with lots of characters, make sure you use the above method to make Outline pass SRP-batcher friendly!
                }

                Cull Front // Cull Front is a must for extra pass outline method

                HLSLPROGRAM

                // Direct copy all keywords from "ForwardLit" pass
                // ---------------------------------------------------------------------------------------------
                #pragma multi_compile _ _MAIN_LIGHT_SHADOWS
                #pragma multi_compile _ _MAIN_LIGHT_SHADOWS_CASCADE
                #pragma multi_compile _ _ADDITIONAL_LIGHTS_VERTEX _ADDITIONAL_LIGHTS
                #pragma multi_compile_fragment _ _ADDITIONAL_LIGHT_SHADOWS
                #pragma multi_compile_fragment _ _SHADOWS_SOFT
                // ---------------------------------------------------------------------------------------------
                #pragma multi_compile_fog
                // ---------------------------------------------------------------------------------------------

                #pragma vertex VertexShaderWork
                #pragma fragment ShadeFinalColor

                // because this is an Outline pass, define "ToonShaderIsOutline" to inject outline related code into both VertexShaderWork() and ShadeFinalColor()
                #define ToonShaderIsOutline

                // all shader logic written inside this .hlsl, remember to write all #define BEFORE writing #include
                #include "./SimpleURPToonLitOutlineExample_Shared.hlsl"

                ENDHLSL
            }

            Pass
            {
                Name "ShadowCaster"
                Tags
                {
                    "LightMode" = "ShadowCaster"
                }
    
                // Render State
                Cull Back
                Blend One Zero
                ZTest LEqual
                ZWrite On
                ColorMask 0
    
                // Debug
                // <None>
    
                // --------------------------------------------------
                // Pass
    
                HLSLPROGRAM
    
                // Pragmas
                #pragma target 4.5
                #pragma exclude_renderers gles gles3 glcore
                #pragma multi_compile_instancing
                #pragma multi_compile _ DOTS_INSTANCING_ON
                #pragma vertex vert
                #pragma fragment frag
    
                // DotsInstancingOptions: <None>
                // HybridV1InjectedBuiltinProperties: <None>
    
                // Keywords
                // PassKeywords: <None>
                // GraphKeywords: <None>
    
                // Defines
                #define _NORMALMAP 1
                #define _NORMAL_DROPOFF_TS 1
                #define ATTRIBUTES_NEED_NORMAL
                #define ATTRIBUTES_NEED_TANGENT
                #define FEATURES_GRAPH_VERTEX
                /* WARNING: $splice Could not find named fragment 'PassInstancing' */
                #define SHADERPASS SHADERPASS_SHADOWCASTER
                /* WARNING: $splice Could not find named fragment 'DotsInstancingVars' */
    
                // Includes
                #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
                #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Texture.hlsl"
                #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
                #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
                #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/TextureStack.hlsl"
                #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"
    
                // --------------------------------------------------
                // Structs and Packing
    
                struct Attributes
                {
                    float3 positionOS : POSITION;
                    float3 normalOS : NORMAL;
                    float4 tangentOS : TANGENT;
                    #if UNITY_ANY_INSTANCING_ENABLED
                    uint instanceID : INSTANCEID_SEMANTIC;
                    #endif
                };
                struct Varyings
                {
                    float4 positionCS : SV_POSITION;
                    #if UNITY_ANY_INSTANCING_ENABLED
                    uint instanceID : CUSTOM_INSTANCE_ID;
                    #endif
                    #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
                    uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
                    #endif
                    #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
                    uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
                    #endif
                    #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
                    FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
                    #endif
                };
                struct SurfaceDescriptionInputs
                {
                };
                struct VertexDescriptionInputs
                {
                    float3 ObjectSpaceNormal;
                    float3 ObjectSpaceTangent;
                    float3 ObjectSpacePosition;
                };
                struct PackedVaryings
                {
                    float4 positionCS : SV_POSITION;
                    #if UNITY_ANY_INSTANCING_ENABLED
                    uint instanceID : CUSTOM_INSTANCE_ID;
                    #endif
                    #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
                    uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
                    #endif
                    #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
                    uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
                    #endif
                    #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
                    FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
                    #endif
                };
    
                PackedVaryings PackVaryings (Varyings input)
                {
                    PackedVaryings output;
                    output.positionCS = input.positionCS;
                    #if UNITY_ANY_INSTANCING_ENABLED
                    output.instanceID = input.instanceID;
                    #endif
                    #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
                    output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
                    #endif
                    #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
                    output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
                    #endif
                    #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
                    output.cullFace = input.cullFace;
                    #endif
                    return output;
                }
                Varyings UnpackVaryings (PackedVaryings input)
                {
                    Varyings output;
                    output.positionCS = input.positionCS;
                    #if UNITY_ANY_INSTANCING_ENABLED
                    output.instanceID = input.instanceID;
                    #endif
                    #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
                    output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
                    #endif
                    #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
                    output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
                    #endif
                    #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
                    output.cullFace = input.cullFace;
                    #endif
                    return output;
                }
    
                // --------------------------------------------------
                // Graph
    
                // Graph Properties
                CBUFFER_START(UnityPerMaterial)
                float _AmbientStrength;
                float4 _DiffuseColor;
                float4 _MainTex_TexelSize;
                float4 _SpecularColor;
                float4 _FresnelColor;
                float _Smoothness;
                float _FresnelSize;
                float _LightingCutoff;
                float _FalloffAmount;
                CBUFFER_END
                
                // Object and Global properties
                SAMPLER(SamplerState_Linear_Repeat);
                TEXTURE2D(_MainTex);
                SAMPLER(sampler_MainTex);
    
                // Graph Functions
                // GraphFunctions: <None>
    
                // Graph Vertex
                struct VertexDescription
                {
                    float3 Position;
                    float3 Normal;
                    float3 Tangent;
                };
                
                VertexDescription VertexDescriptionFunction(VertexDescriptionInputs IN)
                {
                    VertexDescription description = (VertexDescription)0;
                    description.Position = IN.ObjectSpacePosition;
                    description.Normal = IN.ObjectSpaceNormal;
                    description.Tangent = IN.ObjectSpaceTangent;
                    return description;
                }
    
                // Graph Pixel
                struct SurfaceDescription
                {
                };
                
                SurfaceDescription SurfaceDescriptionFunction(SurfaceDescriptionInputs IN)
                {
                    SurfaceDescription surface = (SurfaceDescription)0;
                    return surface;
                }
    
                // --------------------------------------------------
                // Build Graph Inputs
    
                VertexDescriptionInputs BuildVertexDescriptionInputs(Attributes input)
                {
                    VertexDescriptionInputs output;
                    ZERO_INITIALIZE(VertexDescriptionInputs, output);
                
                    output.ObjectSpaceNormal =           input.normalOS;
                    output.ObjectSpaceTangent =          input.tangentOS.xyz;
                    output.ObjectSpacePosition =         input.positionOS;
                
                    return output;
                }
                
                SurfaceDescriptionInputs BuildSurfaceDescriptionInputs(Varyings input)
                {
                    SurfaceDescriptionInputs output;
                    ZERO_INITIALIZE(SurfaceDescriptionInputs, output);
                
                
                
                
                
                #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
                #define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN output.FaceSign =                    IS_FRONT_VFACE(input.cullFace, true, false);
                #else
                #define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN
                #endif
                #undef BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN
                
                    return output;
                }
                
    
                // --------------------------------------------------
                // Main
    
                #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/ShaderPass.hlsl"
                #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/Varyings.hlsl"
                #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/ShadowCasterPass.hlsl"
    
                ENDHLSL
            }
            Pass
            {
                Name "DepthOnly"
                Tags
                {
                    "LightMode" = "DepthOnly"
                }
    
                // Render State
                Cull Back
                Blend One Zero
                ZTest LEqual
                ZWrite On
                ColorMask 0
    
                // Debug
                // <None>
    
                // --------------------------------------------------
                // Pass
    
                HLSLPROGRAM
    
                // Pragmas
                #pragma target 4.5
                #pragma exclude_renderers gles gles3 glcore
                #pragma multi_compile_instancing
                #pragma multi_compile _ DOTS_INSTANCING_ON
                #pragma vertex vert
                #pragma fragment frag
    
                // DotsInstancingOptions: <None>
                // HybridV1InjectedBuiltinProperties: <None>
    
                // Keywords
                // PassKeywords: <None>
                // GraphKeywords: <None>
    
                // Defines
                #define _NORMALMAP 1
                #define _NORMAL_DROPOFF_TS 1
                #define ATTRIBUTES_NEED_NORMAL
                #define ATTRIBUTES_NEED_TANGENT
                #define FEATURES_GRAPH_VERTEX
                /* WARNING: $splice Could not find named fragment 'PassInstancing' */
                #define SHADERPASS SHADERPASS_DEPTHONLY
                /* WARNING: $splice Could not find named fragment 'DotsInstancingVars' */
    
                // Includes
                #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
                #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Texture.hlsl"
                #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
                #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
                #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/TextureStack.hlsl"
                #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"
    
                // --------------------------------------------------
                // Structs and Packing
    
                struct Attributes
                {
                    float3 positionOS : POSITION;
                    float3 normalOS : NORMAL;
                    float4 tangentOS : TANGENT;
                    #if UNITY_ANY_INSTANCING_ENABLED
                    uint instanceID : INSTANCEID_SEMANTIC;
                    #endif
                };
                struct Varyings
                {
                    float4 positionCS : SV_POSITION;
                    #if UNITY_ANY_INSTANCING_ENABLED
                    uint instanceID : CUSTOM_INSTANCE_ID;
                    #endif
                    #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
                    uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
                    #endif
                    #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
                    uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
                    #endif
                    #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
                    FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
                    #endif
                };
                struct SurfaceDescriptionInputs
                {
                };
                struct VertexDescriptionInputs
                {
                    float3 ObjectSpaceNormal;
                    float3 ObjectSpaceTangent;
                    float3 ObjectSpacePosition;
                };
                struct PackedVaryings
                {
                    float4 positionCS : SV_POSITION;
                    #if UNITY_ANY_INSTANCING_ENABLED
                    uint instanceID : CUSTOM_INSTANCE_ID;
                    #endif
                    #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
                    uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
                    #endif
                    #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
                    uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
                    #endif
                    #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
                    FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
                    #endif
                };
    
                PackedVaryings PackVaryings (Varyings input)
                {
                    PackedVaryings output;
                    output.positionCS = input.positionCS;
                    #if UNITY_ANY_INSTANCING_ENABLED
                    output.instanceID = input.instanceID;
                    #endif
                    #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
                    output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
                    #endif
                    #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
                    output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
                    #endif
                    #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
                    output.cullFace = input.cullFace;
                    #endif
                    return output;
                }
                Varyings UnpackVaryings (PackedVaryings input)
                {
                    Varyings output;
                    output.positionCS = input.positionCS;
                    #if UNITY_ANY_INSTANCING_ENABLED
                    output.instanceID = input.instanceID;
                    #endif
                    #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
                    output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
                    #endif
                    #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
                    output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
                    #endif
                    #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
                    output.cullFace = input.cullFace;
                    #endif
                    return output;
                }
    
                // --------------------------------------------------
                // Graph
    
                // Graph Properties
                CBUFFER_START(UnityPerMaterial)
                float _AmbientStrength;
                float4 _DiffuseColor;
                float4 _MainTex_TexelSize;
                float4 _SpecularColor;
                float4 _FresnelColor;
                float _Smoothness;
                float _FresnelSize;
                float _LightingCutoff;
                float _FalloffAmount;
                CBUFFER_END
                
                // Object and Global properties
                SAMPLER(SamplerState_Linear_Repeat);
                TEXTURE2D(_MainTex);
                SAMPLER(sampler_MainTex);
    
                // Graph Functions
                // GraphFunctions: <None>
    
                // Graph Vertex
                struct VertexDescription
                {
                    float3 Position;
                    float3 Normal;
                    float3 Tangent;
                };
                
                VertexDescription VertexDescriptionFunction(VertexDescriptionInputs IN)
                {
                    VertexDescription description = (VertexDescription)0;
                    description.Position = IN.ObjectSpacePosition;
                    description.Normal = IN.ObjectSpaceNormal;
                    description.Tangent = IN.ObjectSpaceTangent;
                    return description;
                }
    
                // Graph Pixel
                struct SurfaceDescription
                {
                };
                
                SurfaceDescription SurfaceDescriptionFunction(SurfaceDescriptionInputs IN)
                {
                    SurfaceDescription surface = (SurfaceDescription)0;
                    return surface;
                }
    
                // --------------------------------------------------
                // Build Graph Inputs
    
                VertexDescriptionInputs BuildVertexDescriptionInputs(Attributes input)
                {
                    VertexDescriptionInputs output;
                    ZERO_INITIALIZE(VertexDescriptionInputs, output);
                
                    output.ObjectSpaceNormal =           input.normalOS;
                    output.ObjectSpaceTangent =          input.tangentOS.xyz;
                    output.ObjectSpacePosition =         input.positionOS;
                
                    return output;
                }
                
                SurfaceDescriptionInputs BuildSurfaceDescriptionInputs(Varyings input)
                {
                    SurfaceDescriptionInputs output;
                    ZERO_INITIALIZE(SurfaceDescriptionInputs, output);
                
                
                
                
                
                #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
                #define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN output.FaceSign =                    IS_FRONT_VFACE(input.cullFace, true, false);
                #else
                #define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN
                #endif
                #undef BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN
                
                    return output;
                }
                
    
                // --------------------------------------------------
                // Main
    
                #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/ShaderPass.hlsl"
                #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/Varyings.hlsl"
                #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/DepthOnlyPass.hlsl"
    
                ENDHLSL
            }
            Pass
            {
                Name "DepthNormals"
                Tags
                {
                    "LightMode" = "DepthNormals"
                }
    
                // Render State
                Cull Back
                Blend One Zero
                ZTest LEqual
                ZWrite On
    
                // Debug
                // <None>
    
                // --------------------------------------------------
                // Pass
    
                HLSLPROGRAM
    
                // Pragmas
                #pragma target 4.5
                #pragma exclude_renderers gles gles3 glcore
                #pragma multi_compile_instancing
                #pragma multi_compile _ DOTS_INSTANCING_ON
                #pragma vertex vert
                #pragma fragment frag
    
                // DotsInstancingOptions: <None>
                // HybridV1InjectedBuiltinProperties: <None>
    
                // Keywords
                // PassKeywords: <None>
                // GraphKeywords: <None>
    
                // Defines
                #define _NORMALMAP 1
                #define _NORMAL_DROPOFF_TS 1
                #define ATTRIBUTES_NEED_NORMAL
                #define ATTRIBUTES_NEED_TANGENT
                #define ATTRIBUTES_NEED_TEXCOORD1
                #define VARYINGS_NEED_NORMAL_WS
                #define VARYINGS_NEED_TANGENT_WS
                #define FEATURES_GRAPH_VERTEX
                /* WARNING: $splice Could not find named fragment 'PassInstancing' */
                #define SHADERPASS SHADERPASS_DEPTHNORMALSONLY
                /* WARNING: $splice Could not find named fragment 'DotsInstancingVars' */
    
                // Includes
                #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
                #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Texture.hlsl"
                #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
                #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
                #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/TextureStack.hlsl"
                #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"
    
                // --------------------------------------------------
                // Structs and Packing
    
                struct Attributes
                {
                    float3 positionOS : POSITION;
                    float3 normalOS : NORMAL;
                    float4 tangentOS : TANGENT;
                    float4 uv1 : TEXCOORD1;
                    #if UNITY_ANY_INSTANCING_ENABLED
                    uint instanceID : INSTANCEID_SEMANTIC;
                    #endif
                };
                struct Varyings
                {
                    float4 positionCS : SV_POSITION;
                    float3 normalWS;
                    float4 tangentWS;
                    #if UNITY_ANY_INSTANCING_ENABLED
                    uint instanceID : CUSTOM_INSTANCE_ID;
                    #endif
                    #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
                    uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
                    #endif
                    #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
                    uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
                    #endif
                    #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
                    FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
                    #endif
                };
                struct SurfaceDescriptionInputs
                {
                    float3 TangentSpaceNormal;
                };
                struct VertexDescriptionInputs
                {
                    float3 ObjectSpaceNormal;
                    float3 ObjectSpaceTangent;
                    float3 ObjectSpacePosition;
                };
                struct PackedVaryings
                {
                    float4 positionCS : SV_POSITION;
                    float3 interp0 : TEXCOORD0;
                    float4 interp1 : TEXCOORD1;
                    #if UNITY_ANY_INSTANCING_ENABLED
                    uint instanceID : CUSTOM_INSTANCE_ID;
                    #endif
                    #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
                    uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
                    #endif
                    #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
                    uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
                    #endif
                    #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
                    FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
                    #endif
                };
    
                PackedVaryings PackVaryings (Varyings input)
                {
                    PackedVaryings output;
                    output.positionCS = input.positionCS;
                    output.interp0.xyz =  input.normalWS;
                    output.interp1.xyzw =  input.tangentWS;
                    #if UNITY_ANY_INSTANCING_ENABLED
                    output.instanceID = input.instanceID;
                    #endif
                    #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
                    output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
                    #endif
                    #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
                    output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
                    #endif
                    #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
                    output.cullFace = input.cullFace;
                    #endif
                    return output;
                }
                Varyings UnpackVaryings (PackedVaryings input)
                {
                    Varyings output;
                    output.positionCS = input.positionCS;
                    output.normalWS = input.interp0.xyz;
                    output.tangentWS = input.interp1.xyzw;
                    #if UNITY_ANY_INSTANCING_ENABLED
                    output.instanceID = input.instanceID;
                    #endif
                    #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
                    output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
                    #endif
                    #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
                    output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
                    #endif
                    #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
                    output.cullFace = input.cullFace;
                    #endif
                    return output;
                }
    
                // --------------------------------------------------
                // Graph
    
                // Graph Properties
                CBUFFER_START(UnityPerMaterial)
                float _AmbientStrength;
                float4 _DiffuseColor;
                float4 _MainTex_TexelSize;
                float4 _SpecularColor;
                float4 _FresnelColor;
                float _Smoothness;
                float _FresnelSize;
                float _LightingCutoff;
                float _FalloffAmount;
                CBUFFER_END
                
                // Object and Global properties
                SAMPLER(SamplerState_Linear_Repeat);
                TEXTURE2D(_MainTex);
                SAMPLER(sampler_MainTex);
    
                // Graph Functions
                // GraphFunctions: <None>
    
                // Graph Vertex
                struct VertexDescription
                {
                    float3 Position;
                    float3 Normal;
                    float3 Tangent;
                };
                
                VertexDescription VertexDescriptionFunction(VertexDescriptionInputs IN)
                {
                    VertexDescription description = (VertexDescription)0;
                    description.Position = IN.ObjectSpacePosition;
                    description.Normal = IN.ObjectSpaceNormal;
                    description.Tangent = IN.ObjectSpaceTangent;
                    return description;
                }
    
                // Graph Pixel
                struct SurfaceDescription
                {
                    float3 NormalTS;
                };
                
                SurfaceDescription SurfaceDescriptionFunction(SurfaceDescriptionInputs IN)
                {
                    SurfaceDescription surface = (SurfaceDescription)0;
                    surface.NormalTS = IN.TangentSpaceNormal;
                    return surface;
                }
    
                // --------------------------------------------------
                // Build Graph Inputs
    
                VertexDescriptionInputs BuildVertexDescriptionInputs(Attributes input)
                {
                    VertexDescriptionInputs output;
                    ZERO_INITIALIZE(VertexDescriptionInputs, output);
                
                    output.ObjectSpaceNormal =           input.normalOS;
                    output.ObjectSpaceTangent =          input.tangentOS.xyz;
                    output.ObjectSpacePosition =         input.positionOS;
                
                    return output;
                }
                
                SurfaceDescriptionInputs BuildSurfaceDescriptionInputs(Varyings input)
                {
                    SurfaceDescriptionInputs output;
                    ZERO_INITIALIZE(SurfaceDescriptionInputs, output);
                
                
                
                    output.TangentSpaceNormal =          float3(0.0f, 0.0f, 1.0f);
                
                
                #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
                #define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN output.FaceSign =                    IS_FRONT_VFACE(input.cullFace, true, false);
                #else
                #define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN
                #endif
                #undef BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN
                
                    return output;
                }
                
    
                // --------------------------------------------------
                // Main
    
                #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/ShaderPass.hlsl"
                #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/Varyings.hlsl"
                #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/DepthNormalsOnlyPass.hlsl"
    
                ENDHLSL
            }
            Pass
            {
                Name "Meta"
                Tags
                {
                    "LightMode" = "Meta"
                }
    
                // Render State
                Cull Off
    
                // Debug
                // <None>
    
                // --------------------------------------------------
                // Pass
    
                HLSLPROGRAM
    
                // Pragmas
                #pragma target 4.5
                #pragma exclude_renderers gles gles3 glcore
                #pragma vertex vert
                #pragma fragment frag
    
                // DotsInstancingOptions: <None>
                // HybridV1InjectedBuiltinProperties: <None>
    
                // Keywords
                #pragma shader_feature _ _SMOOTHNESS_TEXTURE_ALBEDO_CHANNEL_A
                // GraphKeywords: <None>
    
                // Defines
                #define _NORMALMAP 1
                #define _NORMAL_DROPOFF_TS 1
                #define ATTRIBUTES_NEED_NORMAL
                #define ATTRIBUTES_NEED_TANGENT
                #define ATTRIBUTES_NEED_TEXCOORD0
                #define ATTRIBUTES_NEED_TEXCOORD1
                #define ATTRIBUTES_NEED_TEXCOORD2
                #define VARYINGS_NEED_POSITION_WS
                #define VARYINGS_NEED_NORMAL_WS
                #define VARYINGS_NEED_TEXCOORD0
                #define VARYINGS_NEED_VIEWDIRECTION_WS
                #define FEATURES_GRAPH_VERTEX
                /* WARNING: $splice Could not find named fragment 'PassInstancing' */
                #define SHADERPASS SHADERPASS_META
                /* WARNING: $splice Could not find named fragment 'DotsInstancingVars' */
    
                // Includes
                #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
                #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Texture.hlsl"
                #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
                #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
                #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/TextureStack.hlsl"
                #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"
                #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/MetaInput.hlsl"
    
                // --------------------------------------------------
                // Structs and Packing
    
                struct Attributes
                {
                    float3 positionOS : POSITION;
                    float3 normalOS : NORMAL;
                    float4 tangentOS : TANGENT;
                    float4 uv0 : TEXCOORD0;
                    float4 uv1 : TEXCOORD1;
                    float4 uv2 : TEXCOORD2;
                    #if UNITY_ANY_INSTANCING_ENABLED
                    uint instanceID : INSTANCEID_SEMANTIC;
                    #endif
                };
                struct Varyings
                {
                    float4 positionCS : SV_POSITION;
                    float3 positionWS;
                    float3 normalWS;
                    float4 texCoord0;
                    float3 viewDirectionWS;
                    #if UNITY_ANY_INSTANCING_ENABLED
                    uint instanceID : CUSTOM_INSTANCE_ID;
                    #endif
                    #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
                    uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
                    #endif
                    #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
                    uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
                    #endif
                    #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
                    FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
                    #endif
                };
                struct SurfaceDescriptionInputs
                {
                    float3 WorldSpaceNormal;
                    float3 WorldSpaceViewDirection;
                    float3 WorldSpacePosition;
                    float4 uv0;
                };
                struct VertexDescriptionInputs
                {
                    float3 ObjectSpaceNormal;
                    float3 ObjectSpaceTangent;
                    float3 ObjectSpacePosition;
                };
                struct PackedVaryings
                {
                    float4 positionCS : SV_POSITION;
                    float3 interp0 : TEXCOORD0;
                    float3 interp1 : TEXCOORD1;
                    float4 interp2 : TEXCOORD2;
                    float3 interp3 : TEXCOORD3;
                    #if UNITY_ANY_INSTANCING_ENABLED
                    uint instanceID : CUSTOM_INSTANCE_ID;
                    #endif
                    #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
                    uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
                    #endif
                    #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
                    uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
                    #endif
                    #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
                    FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
                    #endif
                };
    
                PackedVaryings PackVaryings (Varyings input)
                {
                    PackedVaryings output;
                    output.positionCS = input.positionCS;
                    output.interp0.xyz =  input.positionWS;
                    output.interp1.xyz =  input.normalWS;
                    output.interp2.xyzw =  input.texCoord0;
                    output.interp3.xyz =  input.viewDirectionWS;
                    #if UNITY_ANY_INSTANCING_ENABLED
                    output.instanceID = input.instanceID;
                    #endif
                    #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
                    output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
                    #endif
                    #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
                    output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
                    #endif
                    #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
                    output.cullFace = input.cullFace;
                    #endif
                    return output;
                }
                Varyings UnpackVaryings (PackedVaryings input)
                {
                    Varyings output;
                    output.positionCS = input.positionCS;
                    output.positionWS = input.interp0.xyz;
                    output.normalWS = input.interp1.xyz;
                    output.texCoord0 = input.interp2.xyzw;
                    output.viewDirectionWS = input.interp3.xyz;
                    #if UNITY_ANY_INSTANCING_ENABLED
                    output.instanceID = input.instanceID;
                    #endif
                    #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
                    output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
                    #endif
                    #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
                    output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
                    #endif
                    #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
                    output.cullFace = input.cullFace;
                    #endif
                    return output;
                }
    
                // --------------------------------------------------
                // Graph
    
                // Graph Properties
                CBUFFER_START(UnityPerMaterial)
                float _AmbientStrength;
                float4 _DiffuseColor;
                float4 _MainTex_TexelSize;
                float4 _SpecularColor;
                float4 _FresnelColor;
                float _Smoothness;
                float _FresnelSize;
                float _LightingCutoff;
                float _FalloffAmount;
                CBUFFER_END
                
                // Object and Global properties
                SAMPLER(SamplerState_Linear_Repeat);
                TEXTURE2D(_MainTex);
                SAMPLER(sampler_MainTex);
    
                // Graph Functions
                
                void Unity_Add_float(float A, float B, out float Out)
                {
                    Out = A + B;
                }
                
                void Unity_Reciprocal_float(float In, out float Out)
                {
                    Out = 1.0/In;
                }
                
                void Unity_FresnelEffect_float(float3 Normal, float3 ViewDir, float Power, out float Out)
                {
                    Out = pow((1.0 - saturate(dot(normalize(Normal), normalize(ViewDir)))), Power);
                }
                
                // a6264222ffebf7cfce349cb3e07ea356
                #include "./Lighting.hlsl"
                
                void Unity_Multiply_float(float A, float B, out float Out)
                {
                    Out = A * B;
                }
                
                struct Bindings_GetMainLight_d6b14a2e8b6f3554b8459648535f697e
                {
                };
                
                void SG_GetMainLight_d6b14a2e8b6f3554b8459648535f697e(float3 Vector3_b21c75b9b8514ef286d5e6dc199fa9af, Bindings_GetMainLight_d6b14a2e8b6f3554b8459648535f697e IN, out float3 Direction_0, out float3 Color_1, out float Attenuation_2)
                {
                    float3 _Property_923162a64885457196b5ccbf7a2aaac7_Out_0 = Vector3_b21c75b9b8514ef286d5e6dc199fa9af;
                    float3 _MainLightCustomFunction_93e39954c04146b5ae1be272ea9d714b_Direction_0;
                    float3 _MainLightCustomFunction_93e39954c04146b5ae1be272ea9d714b_Color_2;
                    float _MainLightCustomFunction_93e39954c04146b5ae1be272ea9d714b_DistanceAtten_3;
                    float _MainLightCustomFunction_93e39954c04146b5ae1be272ea9d714b_ShadowAtten_4;
                    MainLight_float(_Property_923162a64885457196b5ccbf7a2aaac7_Out_0, _MainLightCustomFunction_93e39954c04146b5ae1be272ea9d714b_Direction_0, _MainLightCustomFunction_93e39954c04146b5ae1be272ea9d714b_Color_2, _MainLightCustomFunction_93e39954c04146b5ae1be272ea9d714b_DistanceAtten_3, _MainLightCustomFunction_93e39954c04146b5ae1be272ea9d714b_ShadowAtten_4);
                    float _Multiply_6d878674c9b447478a9564442340c0a2_Out_2;
                    Unity_Multiply_float(_MainLightCustomFunction_93e39954c04146b5ae1be272ea9d714b_DistanceAtten_3, _MainLightCustomFunction_93e39954c04146b5ae1be272ea9d714b_ShadowAtten_4, _Multiply_6d878674c9b447478a9564442340c0a2_Out_2);
                    Direction_0 = _MainLightCustomFunction_93e39954c04146b5ae1be272ea9d714b_Direction_0;
                    Color_1 = _MainLightCustomFunction_93e39954c04146b5ae1be272ea9d714b_Color_2;
                    Attenuation_2 = _Multiply_6d878674c9b447478a9564442340c0a2_Out_2;
                }
                
                void Unity_DotProduct_float3(float3 A, float3 B, out float Out)
                {
                    Out = dot(A, B);
                }
                
                void Unity_Multiply_float(float3 A, float3 B, out float3 Out)
                {
                    Out = A * B;
                }
                
                void Unity_Saturate_float3(float3 In, out float3 Out)
                {
                    Out = saturate(In);
                }
                
                struct Bindings_GetAdditionalLight_b5516a5008f7d104abebe27210c42de8
                {
                };
                
                void SG_GetAdditionalLight_b5516a5008f7d104abebe27210c42de8(float3 Vector3_1e07dec0084a48e38c95166c3cdc688d, float Vector1_0ce9574e837f408991312a6c71473833, Bindings_GetAdditionalLight_b5516a5008f7d104abebe27210c42de8 IN, out float3 Direction_0, out float3 Color_1, out float Attenuation_2)
                {
                    float3 _Property_e9927ccc4a684aeabdaa70dbe76689f0_Out_0 = Vector3_1e07dec0084a48e38c95166c3cdc688d;
                    float _Property_c6fa454cb94449b6923e1c90fafaf929_Out_0 = Vector1_0ce9574e837f408991312a6c71473833;
                    float3 _AdditionalLightCustomFunction_c6ec52ed99634926b12dc96d48e96f1b_Direction_1;
                    float3 _AdditionalLightCustomFunction_c6ec52ed99634926b12dc96d48e96f1b_Color_2;
                    float _AdditionalLightCustomFunction_c6ec52ed99634926b12dc96d48e96f1b_DistanceAtten_3;
                    float _AdditionalLightCustomFunction_c6ec52ed99634926b12dc96d48e96f1b_ShadowAtten_4;
                    AdditionalLight_float(_Property_e9927ccc4a684aeabdaa70dbe76689f0_Out_0, _Property_c6fa454cb94449b6923e1c90fafaf929_Out_0, _AdditionalLightCustomFunction_c6ec52ed99634926b12dc96d48e96f1b_Direction_1, _AdditionalLightCustomFunction_c6ec52ed99634926b12dc96d48e96f1b_Color_2, _AdditionalLightCustomFunction_c6ec52ed99634926b12dc96d48e96f1b_DistanceAtten_3, _AdditionalLightCustomFunction_c6ec52ed99634926b12dc96d48e96f1b_ShadowAtten_4);
                    float _Multiply_0b8ec7bbb926441e8c14c7c32d369adf_Out_2;
                    Unity_Multiply_float(_AdditionalLightCustomFunction_c6ec52ed99634926b12dc96d48e96f1b_DistanceAtten_3, _AdditionalLightCustomFunction_c6ec52ed99634926b12dc96d48e96f1b_ShadowAtten_4, _Multiply_0b8ec7bbb926441e8c14c7c32d369adf_Out_2);
                    Direction_0 = _AdditionalLightCustomFunction_c6ec52ed99634926b12dc96d48e96f1b_Direction_1;
                    Color_1 = _AdditionalLightCustomFunction_c6ec52ed99634926b12dc96d48e96f1b_Color_2;
                    Attenuation_2 = _Multiply_0b8ec7bbb926441e8c14c7c32d369adf_Out_2;
                }
                
                void Unity_Saturate_float(float In, out float Out)
                {
                    Out = saturate(In);
                }
                
                void Unity_Add_float3(float3 A, float3 B, out float3 Out)
                {
                    Out = A + B;
                }
                
                struct Bindings_CalcAdditionalDiffuse_e85823578a3493d41ade631af12166aa
                {
                    float3 WorldSpaceNormal;
                    float3 WorldSpacePosition;
                };
                
                void SG_CalcAdditionalDiffuse_e85823578a3493d41ade631af12166aa(Bindings_CalcAdditionalDiffuse_e85823578a3493d41ade631af12166aa IN, out float3 Diffuse_1)
                {
                    Bindings_GetAdditionalLight_b5516a5008f7d104abebe27210c42de8 _GetAdditionalLight_e6c10dfa199649fca18a0cb673fcba44;
                    float3 _GetAdditionalLight_e6c10dfa199649fca18a0cb673fcba44_Direction_0;
                    float3 _GetAdditionalLight_e6c10dfa199649fca18a0cb673fcba44_Color_1;
                    float _GetAdditionalLight_e6c10dfa199649fca18a0cb673fcba44_Attenuation_2;
                    SG_GetAdditionalLight_b5516a5008f7d104abebe27210c42de8(IN.WorldSpacePosition, 0, _GetAdditionalLight_e6c10dfa199649fca18a0cb673fcba44, _GetAdditionalLight_e6c10dfa199649fca18a0cb673fcba44_Direction_0, _GetAdditionalLight_e6c10dfa199649fca18a0cb673fcba44_Color_1, _GetAdditionalLight_e6c10dfa199649fca18a0cb673fcba44_Attenuation_2);
                    float _DotProduct_aee5f4b498024e2da9796ed342f8a43a_Out_2;
                    Unity_DotProduct_float3(_GetAdditionalLight_e6c10dfa199649fca18a0cb673fcba44_Direction_0, IN.WorldSpaceNormal, _DotProduct_aee5f4b498024e2da9796ed342f8a43a_Out_2);
                    float _Saturate_2080d664f6004dc9ad574ba7e91917b2_Out_1;
                    Unity_Saturate_float(_DotProduct_aee5f4b498024e2da9796ed342f8a43a_Out_2, _Saturate_2080d664f6004dc9ad574ba7e91917b2_Out_1);
                    float3 _Multiply_57fcc7dc0fb845cf924c855eadbb7792_Out_2;
                    Unity_Multiply_float((_Saturate_2080d664f6004dc9ad574ba7e91917b2_Out_1.xxx), _GetAdditionalLight_e6c10dfa199649fca18a0cb673fcba44_Color_1, _Multiply_57fcc7dc0fb845cf924c855eadbb7792_Out_2);
                    float3 _Multiply_59016ca5433045d0a06ff03a13ec13b6_Out_2;
                    Unity_Multiply_float(_Multiply_57fcc7dc0fb845cf924c855eadbb7792_Out_2, (_GetAdditionalLight_e6c10dfa199649fca18a0cb673fcba44_Attenuation_2.xxx), _Multiply_59016ca5433045d0a06ff03a13ec13b6_Out_2);
                    Bindings_GetAdditionalLight_b5516a5008f7d104abebe27210c42de8 _GetAdditionalLight_a054a4cd5b484e1492208dc9ca4a85f5;
                    float3 _GetAdditionalLight_a054a4cd5b484e1492208dc9ca4a85f5_Direction_0;
                    float3 _GetAdditionalLight_a054a4cd5b484e1492208dc9ca4a85f5_Color_1;
                    float _GetAdditionalLight_a054a4cd5b484e1492208dc9ca4a85f5_Attenuation_2;
                    SG_GetAdditionalLight_b5516a5008f7d104abebe27210c42de8(IN.WorldSpacePosition, 1, _GetAdditionalLight_a054a4cd5b484e1492208dc9ca4a85f5, _GetAdditionalLight_a054a4cd5b484e1492208dc9ca4a85f5_Direction_0, _GetAdditionalLight_a054a4cd5b484e1492208dc9ca4a85f5_Color_1, _GetAdditionalLight_a054a4cd5b484e1492208dc9ca4a85f5_Attenuation_2);
                    float _DotProduct_00e581a08ce7465588597fd11859eea2_Out_2;
                    Unity_DotProduct_float3(_GetAdditionalLight_a054a4cd5b484e1492208dc9ca4a85f5_Direction_0, IN.WorldSpaceNormal, _DotProduct_00e581a08ce7465588597fd11859eea2_Out_2);
                    float _Saturate_58b5f4d3dcaf45e6bda212ef43edc4ea_Out_1;
                    Unity_Saturate_float(_DotProduct_00e581a08ce7465588597fd11859eea2_Out_2, _Saturate_58b5f4d3dcaf45e6bda212ef43edc4ea_Out_1);
                    float3 _Multiply_6ff1cb7ecc8542848d8d721f284a3b3c_Out_2;
                    Unity_Multiply_float((_Saturate_58b5f4d3dcaf45e6bda212ef43edc4ea_Out_1.xxx), _GetAdditionalLight_a054a4cd5b484e1492208dc9ca4a85f5_Color_1, _Multiply_6ff1cb7ecc8542848d8d721f284a3b3c_Out_2);
                    float3 _Multiply_8337e9ec92b74cefb421776f67b29661_Out_2;
                    Unity_Multiply_float(_Multiply_6ff1cb7ecc8542848d8d721f284a3b3c_Out_2, (_GetAdditionalLight_a054a4cd5b484e1492208dc9ca4a85f5_Attenuation_2.xxx), _Multiply_8337e9ec92b74cefb421776f67b29661_Out_2);
                    float3 _Add_8d5fe4674e364518a5d8f4559669df92_Out_2;
                    Unity_Add_float3(_Multiply_59016ca5433045d0a06ff03a13ec13b6_Out_2, _Multiply_8337e9ec92b74cefb421776f67b29661_Out_2, _Add_8d5fe4674e364518a5d8f4559669df92_Out_2);
                    Bindings_GetAdditionalLight_b5516a5008f7d104abebe27210c42de8 _GetAdditionalLight_ee2152ac3ed64138932b3a2e4b8e3f14;
                    float3 _GetAdditionalLight_ee2152ac3ed64138932b3a2e4b8e3f14_Direction_0;
                    float3 _GetAdditionalLight_ee2152ac3ed64138932b3a2e4b8e3f14_Color_1;
                    float _GetAdditionalLight_ee2152ac3ed64138932b3a2e4b8e3f14_Attenuation_2;
                    SG_GetAdditionalLight_b5516a5008f7d104abebe27210c42de8(IN.WorldSpacePosition, 2, _GetAdditionalLight_ee2152ac3ed64138932b3a2e4b8e3f14, _GetAdditionalLight_ee2152ac3ed64138932b3a2e4b8e3f14_Direction_0, _GetAdditionalLight_ee2152ac3ed64138932b3a2e4b8e3f14_Color_1, _GetAdditionalLight_ee2152ac3ed64138932b3a2e4b8e3f14_Attenuation_2);
                    float _DotProduct_7a3fce316c4a453e9b9e18226fc2d066_Out_2;
                    Unity_DotProduct_float3(_GetAdditionalLight_ee2152ac3ed64138932b3a2e4b8e3f14_Direction_0, IN.WorldSpaceNormal, _DotProduct_7a3fce316c4a453e9b9e18226fc2d066_Out_2);
                    float _Saturate_c9919732b14f4622aa82e1eec5cb383d_Out_1;
                    Unity_Saturate_float(_DotProduct_7a3fce316c4a453e9b9e18226fc2d066_Out_2, _Saturate_c9919732b14f4622aa82e1eec5cb383d_Out_1);
                    float3 _Multiply_013e04c47fdf4f46a7f2a4868ec83bed_Out_2;
                    Unity_Multiply_float((_Saturate_c9919732b14f4622aa82e1eec5cb383d_Out_1.xxx), _GetAdditionalLight_ee2152ac3ed64138932b3a2e4b8e3f14_Color_1, _Multiply_013e04c47fdf4f46a7f2a4868ec83bed_Out_2);
                    float3 _Multiply_8d16da0d689d4d49909909e6c2cc2da6_Out_2;
                    Unity_Multiply_float(_Multiply_013e04c47fdf4f46a7f2a4868ec83bed_Out_2, (_GetAdditionalLight_ee2152ac3ed64138932b3a2e4b8e3f14_Attenuation_2.xxx), _Multiply_8d16da0d689d4d49909909e6c2cc2da6_Out_2);
                    Bindings_GetAdditionalLight_b5516a5008f7d104abebe27210c42de8 _GetAdditionalLight_da7753016bd64b489b897349d7f3fc0f;
                    float3 _GetAdditionalLight_da7753016bd64b489b897349d7f3fc0f_Direction_0;
                    float3 _GetAdditionalLight_da7753016bd64b489b897349d7f3fc0f_Color_1;
                    float _GetAdditionalLight_da7753016bd64b489b897349d7f3fc0f_Attenuation_2;
                    SG_GetAdditionalLight_b5516a5008f7d104abebe27210c42de8(IN.WorldSpacePosition, 3, _GetAdditionalLight_da7753016bd64b489b897349d7f3fc0f, _GetAdditionalLight_da7753016bd64b489b897349d7f3fc0f_Direction_0, _GetAdditionalLight_da7753016bd64b489b897349d7f3fc0f_Color_1, _GetAdditionalLight_da7753016bd64b489b897349d7f3fc0f_Attenuation_2);
                    float _DotProduct_be3ed23b71d142e3a88f9f21ca2b9bb1_Out_2;
                    Unity_DotProduct_float3(_GetAdditionalLight_da7753016bd64b489b897349d7f3fc0f_Direction_0, IN.WorldSpaceNormal, _DotProduct_be3ed23b71d142e3a88f9f21ca2b9bb1_Out_2);
                    float _Saturate_b3794fe44470430e954d43bb481a3d9a_Out_1;
                    Unity_Saturate_float(_DotProduct_be3ed23b71d142e3a88f9f21ca2b9bb1_Out_2, _Saturate_b3794fe44470430e954d43bb481a3d9a_Out_1);
                    float3 _Multiply_fcf9bc551f0e42f39634ac95fab7cae5_Out_2;
                    Unity_Multiply_float((_Saturate_b3794fe44470430e954d43bb481a3d9a_Out_1.xxx), _GetAdditionalLight_da7753016bd64b489b897349d7f3fc0f_Color_1, _Multiply_fcf9bc551f0e42f39634ac95fab7cae5_Out_2);
                    float3 _Multiply_0cc8c00775354d6a9f91977c3e357ff8_Out_2;
                    Unity_Multiply_float(_Multiply_fcf9bc551f0e42f39634ac95fab7cae5_Out_2, (_GetAdditionalLight_da7753016bd64b489b897349d7f3fc0f_Attenuation_2.xxx), _Multiply_0cc8c00775354d6a9f91977c3e357ff8_Out_2);
                    float3 _Add_0992646b9a764f6eb220517d0e9fc815_Out_2;
                    Unity_Add_float3(_Multiply_8d16da0d689d4d49909909e6c2cc2da6_Out_2, _Multiply_0cc8c00775354d6a9f91977c3e357ff8_Out_2, _Add_0992646b9a764f6eb220517d0e9fc815_Out_2);
                    float3 _Add_d239c6ae017b45cba8fda7bfa29dc880_Out_2;
                    Unity_Add_float3(_Add_8d5fe4674e364518a5d8f4559669df92_Out_2, _Add_0992646b9a764f6eb220517d0e9fc815_Out_2, _Add_d239c6ae017b45cba8fda7bfa29dc880_Out_2);
                    Diffuse_1 = _Add_d239c6ae017b45cba8fda7bfa29dc880_Out_2;
                }
                
                void Unity_Smoothstep_float3(float3 Edge1, float3 Edge2, float3 In, out float3 Out)
                {
                    Out = smoothstep(Edge1, Edge2, In);
                }
                
                void Unity_Normalize_float3(float3 In, out float3 Out)
                {
                    Out = normalize(In);
                }
                
                void Unity_Power_float(float A, float B, out float Out)
                {
                    Out = pow(A, B);
                }
                
                void Unity_Step_float(float Edge, float In, out float Out)
                {
                    Out = step(Edge, In);
                }
                
                struct Bindings_CalcAdditionalSpecular_d84098efe9b2b6043a74a1631b825314
                {
                    float3 WorldSpaceNormal;
                    float3 WorldSpaceViewDirection;
                    float3 WorldSpacePosition;
                };
                
                void SG_CalcAdditionalSpecular_d84098efe9b2b6043a74a1631b825314(float Vector1_ba56f786be984242bee2ff33f2d093fc, Bindings_CalcAdditionalSpecular_d84098efe9b2b6043a74a1631b825314 IN, out float3 Diffuse_1)
                {
                    Bindings_GetAdditionalLight_b5516a5008f7d104abebe27210c42de8 _GetAdditionalLight_e6c10dfa199649fca18a0cb673fcba44;
                    float3 _GetAdditionalLight_e6c10dfa199649fca18a0cb673fcba44_Direction_0;
                    float3 _GetAdditionalLight_e6c10dfa199649fca18a0cb673fcba44_Color_1;
                    float _GetAdditionalLight_e6c10dfa199649fca18a0cb673fcba44_Attenuation_2;
                    SG_GetAdditionalLight_b5516a5008f7d104abebe27210c42de8(IN.WorldSpacePosition, 0, _GetAdditionalLight_e6c10dfa199649fca18a0cb673fcba44, _GetAdditionalLight_e6c10dfa199649fca18a0cb673fcba44_Direction_0, _GetAdditionalLight_e6c10dfa199649fca18a0cb673fcba44_Color_1, _GetAdditionalLight_e6c10dfa199649fca18a0cb673fcba44_Attenuation_2);
                    float3 _Add_7b85500005d849309401cd5cf5ee87fd_Out_2;
                    Unity_Add_float3(_GetAdditionalLight_e6c10dfa199649fca18a0cb673fcba44_Direction_0, IN.WorldSpaceViewDirection, _Add_7b85500005d849309401cd5cf5ee87fd_Out_2);
                    float3 _Normalize_e287e84e1db74e1d979a340af21eb458_Out_1;
                    Unity_Normalize_float3(_Add_7b85500005d849309401cd5cf5ee87fd_Out_2, _Normalize_e287e84e1db74e1d979a340af21eb458_Out_1);
                    float _DotProduct_aee5f4b498024e2da9796ed342f8a43a_Out_2;
                    Unity_DotProduct_float3(_Normalize_e287e84e1db74e1d979a340af21eb458_Out_1, IN.WorldSpaceNormal, _DotProduct_aee5f4b498024e2da9796ed342f8a43a_Out_2);
                    float _Saturate_2080d664f6004dc9ad574ba7e91917b2_Out_1;
                    Unity_Saturate_float(_DotProduct_aee5f4b498024e2da9796ed342f8a43a_Out_2, _Saturate_2080d664f6004dc9ad574ba7e91917b2_Out_1);
                    float _DotProduct_0526a944521c47d3b6c84b963fedd1ff_Out_2;
                    Unity_DotProduct_float3(_GetAdditionalLight_e6c10dfa199649fca18a0cb673fcba44_Direction_0, IN.WorldSpaceNormal, _DotProduct_0526a944521c47d3b6c84b963fedd1ff_Out_2);
                    float _Step_c67d6a53c975466dbaef6447b6a8bb15_Out_2;
                    Unity_Step_float(0, _DotProduct_0526a944521c47d3b6c84b963fedd1ff_Out_2, _Step_c67d6a53c975466dbaef6447b6a8bb15_Out_2);
                    float _Multiply_31278482890d4002a4b8eaea84d893d7_Out_2;
                    Unity_Multiply_float(_Saturate_2080d664f6004dc9ad574ba7e91917b2_Out_1, _Step_c67d6a53c975466dbaef6447b6a8bb15_Out_2, _Multiply_31278482890d4002a4b8eaea84d893d7_Out_2);
                    float _Property_b388a74e1b6a4d90939e467c9ef567a3_Out_0 = Vector1_ba56f786be984242bee2ff33f2d093fc;
                    float _Power_99f8e80de63e4acaa6046138e24f4bd2_Out_2;
                    Unity_Power_float(_Multiply_31278482890d4002a4b8eaea84d893d7_Out_2, _Property_b388a74e1b6a4d90939e467c9ef567a3_Out_0, _Power_99f8e80de63e4acaa6046138e24f4bd2_Out_2);
                    float3 _Multiply_9cc47eeb7de841d19b65dc8e1cb229c5_Out_2;
                    Unity_Multiply_float((_Power_99f8e80de63e4acaa6046138e24f4bd2_Out_2.xxx), _GetAdditionalLight_e6c10dfa199649fca18a0cb673fcba44_Color_1, _Multiply_9cc47eeb7de841d19b65dc8e1cb229c5_Out_2);
                    float3 _Multiply_40c5102279054efb933d4fd61a725966_Out_2;
                    Unity_Multiply_float(_Multiply_9cc47eeb7de841d19b65dc8e1cb229c5_Out_2, (_GetAdditionalLight_e6c10dfa199649fca18a0cb673fcba44_Attenuation_2.xxx), _Multiply_40c5102279054efb933d4fd61a725966_Out_2);
                    Bindings_GetAdditionalLight_b5516a5008f7d104abebe27210c42de8 _GetAdditionalLight_a054a4cd5b484e1492208dc9ca4a85f5;
                    float3 _GetAdditionalLight_a054a4cd5b484e1492208dc9ca4a85f5_Direction_0;
                    float3 _GetAdditionalLight_a054a4cd5b484e1492208dc9ca4a85f5_Color_1;
                    float _GetAdditionalLight_a054a4cd5b484e1492208dc9ca4a85f5_Attenuation_2;
                    SG_GetAdditionalLight_b5516a5008f7d104abebe27210c42de8(IN.WorldSpacePosition, 1, _GetAdditionalLight_a054a4cd5b484e1492208dc9ca4a85f5, _GetAdditionalLight_a054a4cd5b484e1492208dc9ca4a85f5_Direction_0, _GetAdditionalLight_a054a4cd5b484e1492208dc9ca4a85f5_Color_1, _GetAdditionalLight_a054a4cd5b484e1492208dc9ca4a85f5_Attenuation_2);
                    float3 _Add_282adf4f675a4392bdd7447da1537cff_Out_2;
                    Unity_Add_float3(_GetAdditionalLight_a054a4cd5b484e1492208dc9ca4a85f5_Direction_0, IN.WorldSpaceViewDirection, _Add_282adf4f675a4392bdd7447da1537cff_Out_2);
                    float3 _Normalize_d3d2dd5bbe7e4e749daa7d0b940b66e2_Out_1;
                    Unity_Normalize_float3(_Add_282adf4f675a4392bdd7447da1537cff_Out_2, _Normalize_d3d2dd5bbe7e4e749daa7d0b940b66e2_Out_1);
                    float _DotProduct_00e581a08ce7465588597fd11859eea2_Out_2;
                    Unity_DotProduct_float3(_Normalize_d3d2dd5bbe7e4e749daa7d0b940b66e2_Out_1, IN.WorldSpaceNormal, _DotProduct_00e581a08ce7465588597fd11859eea2_Out_2);
                    float _Saturate_58b5f4d3dcaf45e6bda212ef43edc4ea_Out_1;
                    Unity_Saturate_float(_DotProduct_00e581a08ce7465588597fd11859eea2_Out_2, _Saturate_58b5f4d3dcaf45e6bda212ef43edc4ea_Out_1);
                    float _DotProduct_e5d1d640606340949f9ecba8df9c866d_Out_2;
                    Unity_DotProduct_float3(_GetAdditionalLight_a054a4cd5b484e1492208dc9ca4a85f5_Direction_0, IN.WorldSpaceNormal, _DotProduct_e5d1d640606340949f9ecba8df9c866d_Out_2);
                    float _Step_d5595987000246e096b1bd14ec15600e_Out_2;
                    Unity_Step_float(0, _DotProduct_e5d1d640606340949f9ecba8df9c866d_Out_2, _Step_d5595987000246e096b1bd14ec15600e_Out_2);
                    float _Multiply_556cb17951c5463481d66c85c69f72ae_Out_2;
                    Unity_Multiply_float(_Saturate_58b5f4d3dcaf45e6bda212ef43edc4ea_Out_1, _Step_d5595987000246e096b1bd14ec15600e_Out_2, _Multiply_556cb17951c5463481d66c85c69f72ae_Out_2);
                    float _Power_1783632603444ae9bd39ecc3677738f0_Out_2;
                    Unity_Power_float(_Multiply_556cb17951c5463481d66c85c69f72ae_Out_2, _Property_b388a74e1b6a4d90939e467c9ef567a3_Out_0, _Power_1783632603444ae9bd39ecc3677738f0_Out_2);
                    float3 _Multiply_f4914d2b6dae4123a4ce1897d42f8dda_Out_2;
                    Unity_Multiply_float((_Power_1783632603444ae9bd39ecc3677738f0_Out_2.xxx), _GetAdditionalLight_a054a4cd5b484e1492208dc9ca4a85f5_Color_1, _Multiply_f4914d2b6dae4123a4ce1897d42f8dda_Out_2);
                    float3 _Multiply_dff05416518540d5b4d99dfdf00c5766_Out_2;
                    Unity_Multiply_float(_Multiply_f4914d2b6dae4123a4ce1897d42f8dda_Out_2, (_GetAdditionalLight_a054a4cd5b484e1492208dc9ca4a85f5_Attenuation_2.xxx), _Multiply_dff05416518540d5b4d99dfdf00c5766_Out_2);
                    float3 _Add_8d5fe4674e364518a5d8f4559669df92_Out_2;
                    Unity_Add_float3(_Multiply_40c5102279054efb933d4fd61a725966_Out_2, _Multiply_dff05416518540d5b4d99dfdf00c5766_Out_2, _Add_8d5fe4674e364518a5d8f4559669df92_Out_2);
                    Bindings_GetAdditionalLight_b5516a5008f7d104abebe27210c42de8 _GetAdditionalLight_ee2152ac3ed64138932b3a2e4b8e3f14;
                    float3 _GetAdditionalLight_ee2152ac3ed64138932b3a2e4b8e3f14_Direction_0;
                    float3 _GetAdditionalLight_ee2152ac3ed64138932b3a2e4b8e3f14_Color_1;
                    float _GetAdditionalLight_ee2152ac3ed64138932b3a2e4b8e3f14_Attenuation_2;
                    SG_GetAdditionalLight_b5516a5008f7d104abebe27210c42de8(IN.WorldSpacePosition, 2, _GetAdditionalLight_ee2152ac3ed64138932b3a2e4b8e3f14, _GetAdditionalLight_ee2152ac3ed64138932b3a2e4b8e3f14_Direction_0, _GetAdditionalLight_ee2152ac3ed64138932b3a2e4b8e3f14_Color_1, _GetAdditionalLight_ee2152ac3ed64138932b3a2e4b8e3f14_Attenuation_2);
                    float3 _Add_b3b13d361198482f9ee7222ea4d9d819_Out_2;
                    Unity_Add_float3(_GetAdditionalLight_ee2152ac3ed64138932b3a2e4b8e3f14_Direction_0, IN.WorldSpaceViewDirection, _Add_b3b13d361198482f9ee7222ea4d9d819_Out_2);
                    float3 _Normalize_ceaea3816fe94ba48dc9c37f6336e177_Out_1;
                    Unity_Normalize_float3(_Add_b3b13d361198482f9ee7222ea4d9d819_Out_2, _Normalize_ceaea3816fe94ba48dc9c37f6336e177_Out_1);
                    float _DotProduct_7a3fce316c4a453e9b9e18226fc2d066_Out_2;
                    Unity_DotProduct_float3(_Normalize_ceaea3816fe94ba48dc9c37f6336e177_Out_1, IN.WorldSpaceNormal, _DotProduct_7a3fce316c4a453e9b9e18226fc2d066_Out_2);
                    float _Saturate_c9919732b14f4622aa82e1eec5cb383d_Out_1;
                    Unity_Saturate_float(_DotProduct_7a3fce316c4a453e9b9e18226fc2d066_Out_2, _Saturate_c9919732b14f4622aa82e1eec5cb383d_Out_1);
                    float _DotProduct_172616bd9ee743ac9176fabfc0972b90_Out_2;
                    Unity_DotProduct_float3(_GetAdditionalLight_ee2152ac3ed64138932b3a2e4b8e3f14_Direction_0, IN.WorldSpaceNormal, _DotProduct_172616bd9ee743ac9176fabfc0972b90_Out_2);
                    float _Step_6ae114101d8f4d26a00a90cccaa45672_Out_2;
                    Unity_Step_float(0, _DotProduct_172616bd9ee743ac9176fabfc0972b90_Out_2, _Step_6ae114101d8f4d26a00a90cccaa45672_Out_2);
                    float _Multiply_4a9b97617c2448dea4f10cdcb58d4202_Out_2;
                    Unity_Multiply_float(_Saturate_c9919732b14f4622aa82e1eec5cb383d_Out_1, _Step_6ae114101d8f4d26a00a90cccaa45672_Out_2, _Multiply_4a9b97617c2448dea4f10cdcb58d4202_Out_2);
                    float _Power_0801befaab9143ffb3380be20bbdc5ab_Out_2;
                    Unity_Power_float(_Multiply_4a9b97617c2448dea4f10cdcb58d4202_Out_2, _Property_b388a74e1b6a4d90939e467c9ef567a3_Out_0, _Power_0801befaab9143ffb3380be20bbdc5ab_Out_2);
                    float3 _Multiply_cef864918e1e44799f326a20b8334c24_Out_2;
                    Unity_Multiply_float((_Power_0801befaab9143ffb3380be20bbdc5ab_Out_2.xxx), _GetAdditionalLight_ee2152ac3ed64138932b3a2e4b8e3f14_Color_1, _Multiply_cef864918e1e44799f326a20b8334c24_Out_2);
                    float3 _Multiply_d95d25aea25e4461b8a3af2420f0d8e2_Out_2;
                    Unity_Multiply_float(_Multiply_cef864918e1e44799f326a20b8334c24_Out_2, (_GetAdditionalLight_ee2152ac3ed64138932b3a2e4b8e3f14_Attenuation_2.xxx), _Multiply_d95d25aea25e4461b8a3af2420f0d8e2_Out_2);
                    Bindings_GetAdditionalLight_b5516a5008f7d104abebe27210c42de8 _GetAdditionalLight_da7753016bd64b489b897349d7f3fc0f;
                    float3 _GetAdditionalLight_da7753016bd64b489b897349d7f3fc0f_Direction_0;
                    float3 _GetAdditionalLight_da7753016bd64b489b897349d7f3fc0f_Color_1;
                    float _GetAdditionalLight_da7753016bd64b489b897349d7f3fc0f_Attenuation_2;
                    SG_GetAdditionalLight_b5516a5008f7d104abebe27210c42de8(IN.WorldSpacePosition, 3, _GetAdditionalLight_da7753016bd64b489b897349d7f3fc0f, _GetAdditionalLight_da7753016bd64b489b897349d7f3fc0f_Direction_0, _GetAdditionalLight_da7753016bd64b489b897349d7f3fc0f_Color_1, _GetAdditionalLight_da7753016bd64b489b897349d7f3fc0f_Attenuation_2);
                    float3 _Add_3d580f5eb4d44d1a9308632cf3541341_Out_2;
                    Unity_Add_float3(_GetAdditionalLight_da7753016bd64b489b897349d7f3fc0f_Direction_0, IN.WorldSpaceViewDirection, _Add_3d580f5eb4d44d1a9308632cf3541341_Out_2);
                    float3 _Normalize_d6753f83c1d7448991e6e7d8b08f3ffe_Out_1;
                    Unity_Normalize_float3(_Add_3d580f5eb4d44d1a9308632cf3541341_Out_2, _Normalize_d6753f83c1d7448991e6e7d8b08f3ffe_Out_1);
                    float _DotProduct_be3ed23b71d142e3a88f9f21ca2b9bb1_Out_2;
                    Unity_DotProduct_float3(_Normalize_d6753f83c1d7448991e6e7d8b08f3ffe_Out_1, IN.WorldSpaceNormal, _DotProduct_be3ed23b71d142e3a88f9f21ca2b9bb1_Out_2);
                    float _Saturate_b3794fe44470430e954d43bb481a3d9a_Out_1;
                    Unity_Saturate_float(_DotProduct_be3ed23b71d142e3a88f9f21ca2b9bb1_Out_2, _Saturate_b3794fe44470430e954d43bb481a3d9a_Out_1);
                    float _DotProduct_6919254c79d54f02beaaea46cea4bb88_Out_2;
                    Unity_DotProduct_float3(_GetAdditionalLight_da7753016bd64b489b897349d7f3fc0f_Direction_0, IN.WorldSpaceNormal, _DotProduct_6919254c79d54f02beaaea46cea4bb88_Out_2);
                    float _Step_298fb6a31079465894cd805c44c575e3_Out_2;
                    Unity_Step_float(0, _DotProduct_6919254c79d54f02beaaea46cea4bb88_Out_2, _Step_298fb6a31079465894cd805c44c575e3_Out_2);
                    float _Multiply_2531419c34224bfd8f2a6b986099fc14_Out_2;
                    Unity_Multiply_float(_Saturate_b3794fe44470430e954d43bb481a3d9a_Out_1, _Step_298fb6a31079465894cd805c44c575e3_Out_2, _Multiply_2531419c34224bfd8f2a6b986099fc14_Out_2);
                    float _Power_ef3de81b9a0f42a7a6689a0949350c4f_Out_2;
                    Unity_Power_float(_Multiply_2531419c34224bfd8f2a6b986099fc14_Out_2, _Property_b388a74e1b6a4d90939e467c9ef567a3_Out_0, _Power_ef3de81b9a0f42a7a6689a0949350c4f_Out_2);
                    float3 _Multiply_8962de9ab0024826abfc88590336908a_Out_2;
                    Unity_Multiply_float((_Power_ef3de81b9a0f42a7a6689a0949350c4f_Out_2.xxx), _GetAdditionalLight_da7753016bd64b489b897349d7f3fc0f_Color_1, _Multiply_8962de9ab0024826abfc88590336908a_Out_2);
                    float3 _Multiply_d130cd99cdd04ddbb2d61d5a1fa09fd9_Out_2;
                    Unity_Multiply_float(_Multiply_8962de9ab0024826abfc88590336908a_Out_2, (_GetAdditionalLight_da7753016bd64b489b897349d7f3fc0f_Attenuation_2.xxx), _Multiply_d130cd99cdd04ddbb2d61d5a1fa09fd9_Out_2);
                    float3 _Add_0992646b9a764f6eb220517d0e9fc815_Out_2;
                    Unity_Add_float3(_Multiply_d95d25aea25e4461b8a3af2420f0d8e2_Out_2, _Multiply_d130cd99cdd04ddbb2d61d5a1fa09fd9_Out_2, _Add_0992646b9a764f6eb220517d0e9fc815_Out_2);
                    float3 _Add_d239c6ae017b45cba8fda7bfa29dc880_Out_2;
                    Unity_Add_float3(_Add_8d5fe4674e364518a5d8f4559669df92_Out_2, _Add_0992646b9a764f6eb220517d0e9fc815_Out_2, _Add_d239c6ae017b45cba8fda7bfa29dc880_Out_2);
                    Diffuse_1 = _Add_d239c6ae017b45cba8fda7bfa29dc880_Out_2;
                }
                
                void Unity_Maximum_float3(float3 A, float3 B, out float3 Out)
                {
                    Out = max(A, B);
                }
    
                // Graph Vertex
                struct VertexDescription
                {
                    float3 Position;
                    float3 Normal;
                    float3 Tangent;
                };
                
                VertexDescription VertexDescriptionFunction(VertexDescriptionInputs IN)
                {
                    VertexDescription description = (VertexDescription)0;
                    description.Position = IN.ObjectSpacePosition;
                    description.Normal = IN.ObjectSpaceNormal;
                    description.Tangent = IN.ObjectSpaceTangent;
                    return description;
                }
    
                // Graph Pixel
                struct SurfaceDescription
                {
                    float3 BaseColor;
                    float3 Emission;
                };
                
                SurfaceDescription SurfaceDescriptionFunction(SurfaceDescriptionInputs IN)
                {
                    SurfaceDescription surface = (SurfaceDescription)0;
                    float4 _Property_fd7e56b6f55544e1b80c8fd2c097fb78_Out_0 = _FresnelColor;
                    float _Property_faab3ff61e174da380387a5284f29359_Out_0 = _LightingCutoff;
                    float _Property_1f83c6224c604735b8fc5e7585df4c66_Out_0 = _FalloffAmount;
                    float _Add_b1804a0ba53b477b9d8fb474b3008e5f_Out_2;
                    Unity_Add_float(_Property_faab3ff61e174da380387a5284f29359_Out_0, _Property_1f83c6224c604735b8fc5e7585df4c66_Out_0, _Add_b1804a0ba53b477b9d8fb474b3008e5f_Out_2);
                    float _Property_f71948fe16194e1c9767bb52a648a2c1_Out_0 = _FresnelSize;
                    float _Reciprocal_1ab5ff841a4e496dbcaf48eca728ce63_Out_1;
                    Unity_Reciprocal_float(_Property_f71948fe16194e1c9767bb52a648a2c1_Out_0, _Reciprocal_1ab5ff841a4e496dbcaf48eca728ce63_Out_1);
                    float _FresnelEffect_b85b6878ded3452382e4918a35e68e34_Out_3;
                    Unity_FresnelEffect_float(IN.WorldSpaceNormal, IN.WorldSpaceViewDirection, _Reciprocal_1ab5ff841a4e496dbcaf48eca728ce63_Out_1, _FresnelEffect_b85b6878ded3452382e4918a35e68e34_Out_3);
                    Bindings_GetMainLight_d6b14a2e8b6f3554b8459648535f697e _GetMainLight_41b37094e05a429f8266b6602caf8242;
                    float3 _GetMainLight_41b37094e05a429f8266b6602caf8242_Direction_0;
                    float3 _GetMainLight_41b37094e05a429f8266b6602caf8242_Color_1;
                    float _GetMainLight_41b37094e05a429f8266b6602caf8242_Attenuation_2;
                    SG_GetMainLight_d6b14a2e8b6f3554b8459648535f697e(IN.WorldSpacePosition, _GetMainLight_41b37094e05a429f8266b6602caf8242, _GetMainLight_41b37094e05a429f8266b6602caf8242_Direction_0, _GetMainLight_41b37094e05a429f8266b6602caf8242_Color_1, _GetMainLight_41b37094e05a429f8266b6602caf8242_Attenuation_2);
                    float _DotProduct_8d4bdec92ac948559d5a94572dd8cb4d_Out_2;
                    Unity_DotProduct_float3(IN.WorldSpaceNormal, _GetMainLight_41b37094e05a429f8266b6602caf8242_Direction_0, _DotProduct_8d4bdec92ac948559d5a94572dd8cb4d_Out_2);
                    float _Multiply_315cde53c6dc4a3592ed4ee8f047be73_Out_2;
                    Unity_Multiply_float(_DotProduct_8d4bdec92ac948559d5a94572dd8cb4d_Out_2, _GetMainLight_41b37094e05a429f8266b6602caf8242_Attenuation_2, _Multiply_315cde53c6dc4a3592ed4ee8f047be73_Out_2);
                    float3 _Multiply_250e64e5c0fe4aa3aa2515f930a78e5a_Out_2;
                    Unity_Multiply_float((_Multiply_315cde53c6dc4a3592ed4ee8f047be73_Out_2.xxx), _GetMainLight_41b37094e05a429f8266b6602caf8242_Color_1, _Multiply_250e64e5c0fe4aa3aa2515f930a78e5a_Out_2);
                    float3 _Saturate_fdaf2acf4b0d40b3ae196b038de92740_Out_1;
                    Unity_Saturate_float3(_Multiply_250e64e5c0fe4aa3aa2515f930a78e5a_Out_2, _Saturate_fdaf2acf4b0d40b3ae196b038de92740_Out_1);
                    Bindings_CalcAdditionalDiffuse_e85823578a3493d41ade631af12166aa _CalcAdditionalDiffuse_f61ebb0caffa49798669b455d28ddc2f;
                    _CalcAdditionalDiffuse_f61ebb0caffa49798669b455d28ddc2f.WorldSpaceNormal = IN.WorldSpaceNormal;
                    _CalcAdditionalDiffuse_f61ebb0caffa49798669b455d28ddc2f.WorldSpacePosition = IN.WorldSpacePosition;
                    float3 _CalcAdditionalDiffuse_f61ebb0caffa49798669b455d28ddc2f_Diffuse_1;
                    SG_CalcAdditionalDiffuse_e85823578a3493d41ade631af12166aa(_CalcAdditionalDiffuse_f61ebb0caffa49798669b455d28ddc2f, _CalcAdditionalDiffuse_f61ebb0caffa49798669b455d28ddc2f_Diffuse_1);
                    float3 _Add_0f6ab824bf464526bbf3116b8d1e102f_Out_2;
                    Unity_Add_float3(_Saturate_fdaf2acf4b0d40b3ae196b038de92740_Out_1, _CalcAdditionalDiffuse_f61ebb0caffa49798669b455d28ddc2f_Diffuse_1, _Add_0f6ab824bf464526bbf3116b8d1e102f_Out_2);
                    float3 _Multiply_57cc1ea2df2f4223815236660d4ba4b2_Out_2;
                    Unity_Multiply_float((_FresnelEffect_b85b6878ded3452382e4918a35e68e34_Out_3.xxx), _Add_0f6ab824bf464526bbf3116b8d1e102f_Out_2, _Multiply_57cc1ea2df2f4223815236660d4ba4b2_Out_2);
                    float3 _Smoothstep_424686c920094f11a03df5f03afe5145_Out_3;
                    Unity_Smoothstep_float3((_Property_faab3ff61e174da380387a5284f29359_Out_0.xxx), (_Add_b1804a0ba53b477b9d8fb474b3008e5f_Out_2.xxx), _Multiply_57cc1ea2df2f4223815236660d4ba4b2_Out_2, _Smoothstep_424686c920094f11a03df5f03afe5145_Out_3);
                    float3 _Multiply_08e1c96546e24df2920fcd26690a7402_Out_2;
                    Unity_Multiply_float((_Property_fd7e56b6f55544e1b80c8fd2c097fb78_Out_0.xyz), _Smoothstep_424686c920094f11a03df5f03afe5145_Out_3, _Multiply_08e1c96546e24df2920fcd26690a7402_Out_2);
                    float4 _Property_0d605fca5a9b4f2e8020677b52b5629d_Out_0 = _SpecularColor;
                    float _Property_1d077dd941fc4016a62636a6048577bc_Out_0 = _LightingCutoff;
                    float _Property_2a13ac2eb2084e0f912c6485bff7e1fb_Out_0 = _FalloffAmount;
                    float _Add_aee813a1674a41449133aac98f918ac9_Out_2;
                    Unity_Add_float(_Property_1d077dd941fc4016a62636a6048577bc_Out_0, _Property_2a13ac2eb2084e0f912c6485bff7e1fb_Out_0, _Add_aee813a1674a41449133aac98f918ac9_Out_2);
                    Bindings_GetMainLight_d6b14a2e8b6f3554b8459648535f697e _GetMainLight_5a267f1983eb45038dd25d47096b3576;
                    float3 _GetMainLight_5a267f1983eb45038dd25d47096b3576_Direction_0;
                    float3 _GetMainLight_5a267f1983eb45038dd25d47096b3576_Color_1;
                    float _GetMainLight_5a267f1983eb45038dd25d47096b3576_Attenuation_2;
                    SG_GetMainLight_d6b14a2e8b6f3554b8459648535f697e(IN.WorldSpacePosition, _GetMainLight_5a267f1983eb45038dd25d47096b3576, _GetMainLight_5a267f1983eb45038dd25d47096b3576_Direction_0, _GetMainLight_5a267f1983eb45038dd25d47096b3576_Color_1, _GetMainLight_5a267f1983eb45038dd25d47096b3576_Attenuation_2);
                    float3 _Add_cdec837b18d14622929b74d779f9ed53_Out_2;
                    Unity_Add_float3(IN.WorldSpaceViewDirection, _GetMainLight_5a267f1983eb45038dd25d47096b3576_Direction_0, _Add_cdec837b18d14622929b74d779f9ed53_Out_2);
                    float3 _Normalize_4ed8697fa3534c40a04c3b38c2f39118_Out_1;
                    Unity_Normalize_float3(_Add_cdec837b18d14622929b74d779f9ed53_Out_2, _Normalize_4ed8697fa3534c40a04c3b38c2f39118_Out_1);
                    float _DotProduct_2a86b7ba7a4e47c1b993a25eea174112_Out_2;
                    Unity_DotProduct_float3(IN.WorldSpaceNormal, _Normalize_4ed8697fa3534c40a04c3b38c2f39118_Out_1, _DotProduct_2a86b7ba7a4e47c1b993a25eea174112_Out_2);
                    float _Saturate_5954bbc00cbe4ab1aaece8a4042a2ae1_Out_1;
                    Unity_Saturate_float(_DotProduct_2a86b7ba7a4e47c1b993a25eea174112_Out_2, _Saturate_5954bbc00cbe4ab1aaece8a4042a2ae1_Out_1);
                    float _Property_09addda5751f4ae38ffd75d2cf5042be_Out_0 = _Smoothness;
                    float _Power_d01facce68d2456bb5459bf9144d966c_Out_2;
                    Unity_Power_float(_Saturate_5954bbc00cbe4ab1aaece8a4042a2ae1_Out_1, _Property_09addda5751f4ae38ffd75d2cf5042be_Out_0, _Power_d01facce68d2456bb5459bf9144d966c_Out_2);
                    float3 _Multiply_37f25c3b613140a98d39720af3f46c04_Out_2;
                    Unity_Multiply_float((_Power_d01facce68d2456bb5459bf9144d966c_Out_2.xxx), _GetMainLight_5a267f1983eb45038dd25d47096b3576_Color_1, _Multiply_37f25c3b613140a98d39720af3f46c04_Out_2);
                    float3 _Multiply_40d12c060eda4e9293ea46113abcac99_Out_2;
                    Unity_Multiply_float(_Multiply_37f25c3b613140a98d39720af3f46c04_Out_2, (_GetMainLight_5a267f1983eb45038dd25d47096b3576_Attenuation_2.xxx), _Multiply_40d12c060eda4e9293ea46113abcac99_Out_2);
                    float3 _Multiply_20c6e31cff10450ab4a4e6910c501dff_Out_2;
                    Unity_Multiply_float(_Multiply_40d12c060eda4e9293ea46113abcac99_Out_2, _Saturate_fdaf2acf4b0d40b3ae196b038de92740_Out_1, _Multiply_20c6e31cff10450ab4a4e6910c501dff_Out_2);
                    Bindings_CalcAdditionalSpecular_d84098efe9b2b6043a74a1631b825314 _CalcAdditionalSpecular_cd3669952dc74dfe8fc61749791c4fda;
                    _CalcAdditionalSpecular_cd3669952dc74dfe8fc61749791c4fda.WorldSpaceNormal = IN.WorldSpaceNormal;
                    _CalcAdditionalSpecular_cd3669952dc74dfe8fc61749791c4fda.WorldSpaceViewDirection = IN.WorldSpaceViewDirection;
                    _CalcAdditionalSpecular_cd3669952dc74dfe8fc61749791c4fda.WorldSpacePosition = IN.WorldSpacePosition;
                    float3 _CalcAdditionalSpecular_cd3669952dc74dfe8fc61749791c4fda_Diffuse_1;
                    SG_CalcAdditionalSpecular_d84098efe9b2b6043a74a1631b825314(_Property_09addda5751f4ae38ffd75d2cf5042be_Out_0, _CalcAdditionalSpecular_cd3669952dc74dfe8fc61749791c4fda, _CalcAdditionalSpecular_cd3669952dc74dfe8fc61749791c4fda_Diffuse_1);
                    float3 _Add_6cdd48355c7448bbbc9dc34639d2f16d_Out_2;
                    Unity_Add_float3(_Multiply_20c6e31cff10450ab4a4e6910c501dff_Out_2, _CalcAdditionalSpecular_cd3669952dc74dfe8fc61749791c4fda_Diffuse_1, _Add_6cdd48355c7448bbbc9dc34639d2f16d_Out_2);
                    float3 _Smoothstep_46bf89c479e64da1a8083fa09e5d323d_Out_3;
                    Unity_Smoothstep_float3((_Property_1d077dd941fc4016a62636a6048577bc_Out_0.xxx), (_Add_aee813a1674a41449133aac98f918ac9_Out_2.xxx), _Add_6cdd48355c7448bbbc9dc34639d2f16d_Out_2, _Smoothstep_46bf89c479e64da1a8083fa09e5d323d_Out_3);
                    float3 _Multiply_fb48a1d2f9404211ad52dd2f26a46f28_Out_2;
                    Unity_Multiply_float((_Property_0d605fca5a9b4f2e8020677b52b5629d_Out_0.xyz), _Smoothstep_46bf89c479e64da1a8083fa09e5d323d_Out_3, _Multiply_fb48a1d2f9404211ad52dd2f26a46f28_Out_2);
                    float4 _Property_5bce803f7b1342118efa64dfd7a5c5af_Out_0 = _DiffuseColor;
                    float _Property_5b63eda1ad9a4c349b54058af0283a6a_Out_0 = _LightingCutoff;
                    float _Property_6b8c43c8c4e04f089b490e01842c10e7_Out_0 = _FalloffAmount;
                    float _Add_f9f052f699b24c22a7e6ed992dbded4d_Out_2;
                    Unity_Add_float(_Property_5b63eda1ad9a4c349b54058af0283a6a_Out_0, _Property_6b8c43c8c4e04f089b490e01842c10e7_Out_0, _Add_f9f052f699b24c22a7e6ed992dbded4d_Out_2);
                    float3 _Smoothstep_6421ae70d4a0477a913d197174717db2_Out_3;
                    Unity_Smoothstep_float3((_Property_5b63eda1ad9a4c349b54058af0283a6a_Out_0.xxx), (_Add_f9f052f699b24c22a7e6ed992dbded4d_Out_2.xxx), _Add_0f6ab824bf464526bbf3116b8d1e102f_Out_2, _Smoothstep_6421ae70d4a0477a913d197174717db2_Out_3);
                    float _Property_68149cd9c2eb40a79d0105acc016d1c4_Out_0 = _AmbientStrength;
                    float3 _Maximum_c73c7cbcf6c4463a865782d13a0c4101_Out_2;
                    Unity_Maximum_float3(_Smoothstep_6421ae70d4a0477a913d197174717db2_Out_3, (_Property_68149cd9c2eb40a79d0105acc016d1c4_Out_0.xxx), _Maximum_c73c7cbcf6c4463a865782d13a0c4101_Out_2);
                    float3 _Multiply_d622b247c4a84f8bbebf6a902f0b0fcb_Out_2;
                    Unity_Multiply_float((_Property_5bce803f7b1342118efa64dfd7a5c5af_Out_0.xyz), _Maximum_c73c7cbcf6c4463a865782d13a0c4101_Out_2, _Multiply_d622b247c4a84f8bbebf6a902f0b0fcb_Out_2);
                    UnityTexture2D _Property_a111b087fff64719b899025161b92d31_Out_0 = UnityBuildTexture2DStructNoScale(_MainTex);
                    float4 _SampleTexture2D_68405c1067a64b7f874afd25ede0e0c8_RGBA_0 = SAMPLE_TEXTURE2D(_Property_a111b087fff64719b899025161b92d31_Out_0.tex, _Property_a111b087fff64719b899025161b92d31_Out_0.samplerstate, IN.uv0.xy);
                    float _SampleTexture2D_68405c1067a64b7f874afd25ede0e0c8_R_4 = _SampleTexture2D_68405c1067a64b7f874afd25ede0e0c8_RGBA_0.r;
                    float _SampleTexture2D_68405c1067a64b7f874afd25ede0e0c8_G_5 = _SampleTexture2D_68405c1067a64b7f874afd25ede0e0c8_RGBA_0.g;
                    float _SampleTexture2D_68405c1067a64b7f874afd25ede0e0c8_B_6 = _SampleTexture2D_68405c1067a64b7f874afd25ede0e0c8_RGBA_0.b;
                    float _SampleTexture2D_68405c1067a64b7f874afd25ede0e0c8_A_7 = _SampleTexture2D_68405c1067a64b7f874afd25ede0e0c8_RGBA_0.a;
                    float3 _Multiply_8ac74964cd004464a81865818d5afcc4_Out_2;
                    Unity_Multiply_float(_Multiply_d622b247c4a84f8bbebf6a902f0b0fcb_Out_2, (_SampleTexture2D_68405c1067a64b7f874afd25ede0e0c8_RGBA_0.xyz), _Multiply_8ac74964cd004464a81865818d5afcc4_Out_2);
                    float3 _Add_2ebf33fa6b00434db9194d0243d86458_Out_2;
                    Unity_Add_float3(_Multiply_fb48a1d2f9404211ad52dd2f26a46f28_Out_2, _Multiply_8ac74964cd004464a81865818d5afcc4_Out_2, _Add_2ebf33fa6b00434db9194d0243d86458_Out_2);
                    float3 _Add_5db2a9e6feef42bc9e81d7017a4e1bd8_Out_2;
                    Unity_Add_float3(_Multiply_08e1c96546e24df2920fcd26690a7402_Out_2, _Add_2ebf33fa6b00434db9194d0243d86458_Out_2, _Add_5db2a9e6feef42bc9e81d7017a4e1bd8_Out_2);
                    surface.BaseColor = IsGammaSpace() ? float3(0, 0, 0) : SRGBToLinear(float3(0, 0, 0));
                    surface.Emission = _Add_5db2a9e6feef42bc9e81d7017a4e1bd8_Out_2;
                    return surface;
                }
    
                // --------------------------------------------------
                // Build Graph Inputs
    
                VertexDescriptionInputs BuildVertexDescriptionInputs(Attributes input)
                {
                    VertexDescriptionInputs output;
                    ZERO_INITIALIZE(VertexDescriptionInputs, output);
                
                    output.ObjectSpaceNormal =           input.normalOS;
                    output.ObjectSpaceTangent =          input.tangentOS.xyz;
                    output.ObjectSpacePosition =         input.positionOS;
                
                    return output;
                }
                
                SurfaceDescriptionInputs BuildSurfaceDescriptionInputs(Varyings input)
                {
                    SurfaceDescriptionInputs output;
                    ZERO_INITIALIZE(SurfaceDescriptionInputs, output);
                
                	// must use interpolated tangent, bitangent and normal before they are normalized in the pixel shader.
                	float3 unnormalizedNormalWS = input.normalWS;
                    const float renormFactor = 1.0 / length(unnormalizedNormalWS);
                
                
                    output.WorldSpaceNormal =            renormFactor*input.normalWS.xyz;		// we want a unit length Normal Vector node in shader graph
                
                
                    output.WorldSpaceViewDirection =     input.viewDirectionWS; //TODO: by default normalized in HD, but not in universal
                    output.WorldSpacePosition =          input.positionWS;
                    output.uv0 =                         input.texCoord0;
                #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
                #define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN output.FaceSign =                    IS_FRONT_VFACE(input.cullFace, true, false);
                #else
                #define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN
                #endif
                #undef BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN
                
                    return output;
                }
                
    
                // --------------------------------------------------
                // Main
    
                #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/ShaderPass.hlsl"
                #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/Varyings.hlsl"
                #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/LightingMetaPass.hlsl"
    
                ENDHLSL
            }
            Pass
            {
                // Name: <None>
                Tags
                {
                    "LightMode" = "Universal2D"
                }
    
                // Render State
                Cull Back
                Blend One Zero
                ZTest LEqual
                ZWrite On
    
                // Debug
                // <None>
    
                // --------------------------------------------------
                // Pass
    
                HLSLPROGRAM
    
                // Pragmas
                #pragma target 4.5
                #pragma exclude_renderers gles gles3 glcore
                #pragma vertex vert
                #pragma fragment frag
    
                // DotsInstancingOptions: <None>
                // HybridV1InjectedBuiltinProperties: <None>
    
                // Keywords
                // PassKeywords: <None>
                // GraphKeywords: <None>
    
                // Defines
                #define _NORMALMAP 1
                #define _NORMAL_DROPOFF_TS 1
                #define ATTRIBUTES_NEED_NORMAL
                #define ATTRIBUTES_NEED_TANGENT
                #define FEATURES_GRAPH_VERTEX
                /* WARNING: $splice Could not find named fragment 'PassInstancing' */
                #define SHADERPASS SHADERPASS_2D
                /* WARNING: $splice Could not find named fragment 'DotsInstancingVars' */
    
                // Includes
                #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
                #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Texture.hlsl"
                #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
                #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
                #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/TextureStack.hlsl"
                #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"
    
                // --------------------------------------------------
                // Structs and Packing
    
                struct Attributes
                {
                    float3 positionOS : POSITION;
                    float3 normalOS : NORMAL;
                    float4 tangentOS : TANGENT;
                    #if UNITY_ANY_INSTANCING_ENABLED
                    uint instanceID : INSTANCEID_SEMANTIC;
                    #endif
                };
                struct Varyings
                {
                    float4 positionCS : SV_POSITION;
                    #if UNITY_ANY_INSTANCING_ENABLED
                    uint instanceID : CUSTOM_INSTANCE_ID;
                    #endif
                    #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
                    uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
                    #endif
                    #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
                    uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
                    #endif
                    #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
                    FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
                    #endif
                };
                struct SurfaceDescriptionInputs
                {
                };
                struct VertexDescriptionInputs
                {
                    float3 ObjectSpaceNormal;
                    float3 ObjectSpaceTangent;
                    float3 ObjectSpacePosition;
                };
                struct PackedVaryings
                {
                    float4 positionCS : SV_POSITION;
                    #if UNITY_ANY_INSTANCING_ENABLED
                    uint instanceID : CUSTOM_INSTANCE_ID;
                    #endif
                    #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
                    uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
                    #endif
                    #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
                    uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
                    #endif
                    #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
                    FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
                    #endif
                };
    
                PackedVaryings PackVaryings (Varyings input)
                {
                    PackedVaryings output;
                    output.positionCS = input.positionCS;
                    #if UNITY_ANY_INSTANCING_ENABLED
                    output.instanceID = input.instanceID;
                    #endif
                    #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
                    output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
                    #endif
                    #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
                    output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
                    #endif
                    #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
                    output.cullFace = input.cullFace;
                    #endif
                    return output;
                }
                Varyings UnpackVaryings (PackedVaryings input)
                {
                    Varyings output;
                    output.positionCS = input.positionCS;
                    #if UNITY_ANY_INSTANCING_ENABLED
                    output.instanceID = input.instanceID;
                    #endif
                    #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
                    output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
                    #endif
                    #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
                    output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
                    #endif
                    #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
                    output.cullFace = input.cullFace;
                    #endif
                    return output;
                }
    
                // --------------------------------------------------
                // Graph
    
                // Graph Properties
                CBUFFER_START(UnityPerMaterial)
                float _AmbientStrength;
                float4 _DiffuseColor;
                float4 _MainTex_TexelSize;
                float4 _SpecularColor;
                float4 _FresnelColor;
                float _Smoothness;
                float _FresnelSize;
                float _LightingCutoff;
                float _FalloffAmount;
                CBUFFER_END
                
                // Object and Global properties
                SAMPLER(SamplerState_Linear_Repeat);
                TEXTURE2D(_MainTex);
                SAMPLER(sampler_MainTex);
    
                // Graph Functions
                // GraphFunctions: <None>
    
                // Graph Vertex
                struct VertexDescription
                {
                    float3 Position;
                    float3 Normal;
                    float3 Tangent;
                };
                
                VertexDescription VertexDescriptionFunction(VertexDescriptionInputs IN)
                {
                    VertexDescription description = (VertexDescription)0;
                    description.Position = IN.ObjectSpacePosition;
                    description.Normal = IN.ObjectSpaceNormal;
                    description.Tangent = IN.ObjectSpaceTangent;
                    return description;
                }
    
                // Graph Pixel
                struct SurfaceDescription
                {
                    float3 BaseColor;
                };
                
                SurfaceDescription SurfaceDescriptionFunction(SurfaceDescriptionInputs IN)
                {
                    SurfaceDescription surface = (SurfaceDescription)0;
                    surface.BaseColor = IsGammaSpace() ? float3(0, 0, 0) : SRGBToLinear(float3(0, 0, 0));
                    return surface;
                }
    
                // --------------------------------------------------
                // Build Graph Inputs
    
                VertexDescriptionInputs BuildVertexDescriptionInputs(Attributes input)
                {
                    VertexDescriptionInputs output;
                    ZERO_INITIALIZE(VertexDescriptionInputs, output);
                
                    output.ObjectSpaceNormal =           input.normalOS;
                    output.ObjectSpaceTangent =          input.tangentOS.xyz;
                    output.ObjectSpacePosition =         input.positionOS;
                
                    return output;
                }
                
                SurfaceDescriptionInputs BuildSurfaceDescriptionInputs(Varyings input)
                {
                    SurfaceDescriptionInputs output;
                    ZERO_INITIALIZE(SurfaceDescriptionInputs, output);
                
                
                
                
                
                #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
                #define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN output.FaceSign =                    IS_FRONT_VFACE(input.cullFace, true, false);
                #else
                #define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN
                #endif
                #undef BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN
                
                    return output;
                }
                
    
                // --------------------------------------------------
                // Main
    
                #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/ShaderPass.hlsl"
                #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/Varyings.hlsl"
                #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/PBR2DPass.hlsl"
    
                ENDHLSL
            }
        }
        SubShader
        {
            Tags
            {
                "RenderPipeline"="UniversalPipeline"
                "RenderType"="Opaque"
                "UniversalMaterialType" = "Lit"
                "Queue"="Geometry"
            }
            Pass
            {
                Name "Universal Forward"
                Tags
                {
                    "LightMode" = "UniversalForward"
                }
    
                // Render State
                Cull Back
                Blend One Zero
                ZTest LEqual
                ZWrite On
    
                // Debug
                // <None>
    
                // --------------------------------------------------
                // Pass
    
                HLSLPROGRAM
    
                // Pragmas
                #pragma target 2.0
                #pragma only_renderers gles gles3 glcore d3d11
                #pragma multi_compile_instancing
                #pragma multi_compile_fog
                #pragma vertex vert
                #pragma fragment frag
    
                // DotsInstancingOptions: <None>
                // HybridV1InjectedBuiltinProperties: <None>
    
                // Keywords
                #pragma multi_compile _ _SCREEN_SPACE_OCCLUSION
                #pragma multi_compile _ LIGHTMAP_ON
                #pragma multi_compile _ DIRLIGHTMAP_COMBINED
                #pragma multi_compile _ _MAIN_LIGHT_SHADOWS
                #pragma multi_compile _ _MAIN_LIGHT_SHADOWS_CASCADE
                #pragma multi_compile _ADDITIONAL_LIGHTS_VERTEX _ADDITIONAL_LIGHTS _ADDITIONAL_OFF
                #pragma multi_compile _ _ADDITIONAL_LIGHT_SHADOWS
                #pragma multi_compile _ _SHADOWS_SOFT
                #pragma multi_compile _ LIGHTMAP_SHADOW_MIXING
                #pragma multi_compile _ SHADOWS_SHADOWMASK
                // GraphKeywords: <None>
    
                // Defines
                #define _NORMALMAP 1
                #define _NORMAL_DROPOFF_TS 1
                #define ATTRIBUTES_NEED_NORMAL
                #define ATTRIBUTES_NEED_TANGENT
                #define ATTRIBUTES_NEED_TEXCOORD0
                #define ATTRIBUTES_NEED_TEXCOORD1
                #define VARYINGS_NEED_POSITION_WS
                #define VARYINGS_NEED_NORMAL_WS
                #define VARYINGS_NEED_TANGENT_WS
                #define VARYINGS_NEED_TEXCOORD0
                #define VARYINGS_NEED_VIEWDIRECTION_WS
                #define VARYINGS_NEED_FOG_AND_VERTEX_LIGHT
                #define FEATURES_GRAPH_VERTEX
                /* WARNING: $splice Could not find named fragment 'PassInstancing' */
                #define SHADERPASS SHADERPASS_FORWARD
                /* WARNING: $splice Could not find named fragment 'DotsInstancingVars' */
    
                // Includes
                #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
                #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Texture.hlsl"
                #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
                #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
                #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/TextureStack.hlsl"
                #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Shadows.hlsl"
                #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"
    
                // --------------------------------------------------
                // Structs and Packing
    
                struct Attributes
                {
                    float3 positionOS : POSITION;
                    float3 normalOS : NORMAL;
                    float4 tangentOS : TANGENT;
                    float4 uv0 : TEXCOORD0;
                    float4 uv1 : TEXCOORD1;
                    #if UNITY_ANY_INSTANCING_ENABLED
                    uint instanceID : INSTANCEID_SEMANTIC;
                    #endif
                };
                struct Varyings
                {
                    float4 positionCS : SV_POSITION;
                    float3 positionWS;
                    float3 normalWS;
                    float4 tangentWS;
                    float4 texCoord0;
                    float3 viewDirectionWS;
                    #if defined(LIGHTMAP_ON)
                    float2 lightmapUV;
                    #endif
                    #if !defined(LIGHTMAP_ON)
                    float3 sh;
                    #endif
                    float4 fogFactorAndVertexLight;
                    float4 shadowCoord;
                    #if UNITY_ANY_INSTANCING_ENABLED
                    uint instanceID : CUSTOM_INSTANCE_ID;
                    #endif
                    #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
                    uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
                    #endif
                    #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
                    uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
                    #endif
                    #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
                    FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
                    #endif
                };
                struct SurfaceDescriptionInputs
                {
                    float3 WorldSpaceNormal;
                    float3 TangentSpaceNormal;
                    float3 WorldSpaceViewDirection;
                    float3 WorldSpacePosition;
                    float4 uv0;
                };
                struct VertexDescriptionInputs
                {
                    float3 ObjectSpaceNormal;
                    float3 ObjectSpaceTangent;
                    float3 ObjectSpacePosition;
                };
                struct PackedVaryings
                {
                    float4 positionCS : SV_POSITION;
                    float3 interp0 : TEXCOORD0;
                    float3 interp1 : TEXCOORD1;
                    float4 interp2 : TEXCOORD2;
                    float4 interp3 : TEXCOORD3;
                    float3 interp4 : TEXCOORD4;
                    #if defined(LIGHTMAP_ON)
                    float2 interp5 : TEXCOORD5;
                    #endif
                    #if !defined(LIGHTMAP_ON)
                    float3 interp6 : TEXCOORD6;
                    #endif
                    float4 interp7 : TEXCOORD7;
                    float4 interp8 : TEXCOORD8;
                    #if UNITY_ANY_INSTANCING_ENABLED
                    uint instanceID : CUSTOM_INSTANCE_ID;
                    #endif
                    #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
                    uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
                    #endif
                    #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
                    uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
                    #endif
                    #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
                    FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
                    #endif
                };
    
                PackedVaryings PackVaryings (Varyings input)
                {
                    PackedVaryings output;
                    output.positionCS = input.positionCS;
                    output.interp0.xyz =  input.positionWS;
                    output.interp1.xyz =  input.normalWS;
                    output.interp2.xyzw =  input.tangentWS;
                    output.interp3.xyzw =  input.texCoord0;
                    output.interp4.xyz =  input.viewDirectionWS;
                    #if defined(LIGHTMAP_ON)
                    output.interp5.xy =  input.lightmapUV;
                    #endif
                    #if !defined(LIGHTMAP_ON)
                    output.interp6.xyz =  input.sh;
                    #endif
                    output.interp7.xyzw =  input.fogFactorAndVertexLight;
                    output.interp8.xyzw =  input.shadowCoord;
                    #if UNITY_ANY_INSTANCING_ENABLED
                    output.instanceID = input.instanceID;
                    #endif
                    #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
                    output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
                    #endif
                    #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
                    output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
                    #endif
                    #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
                    output.cullFace = input.cullFace;
                    #endif
                    return output;
                }
                Varyings UnpackVaryings (PackedVaryings input)
                {
                    Varyings output;
                    output.positionCS = input.positionCS;
                    output.positionWS = input.interp0.xyz;
                    output.normalWS = input.interp1.xyz;
                    output.tangentWS = input.interp2.xyzw;
                    output.texCoord0 = input.interp3.xyzw;
                    output.viewDirectionWS = input.interp4.xyz;
                    #if defined(LIGHTMAP_ON)
                    output.lightmapUV = input.interp5.xy;
                    #endif
                    #if !defined(LIGHTMAP_ON)
                    output.sh = input.interp6.xyz;
                    #endif
                    output.fogFactorAndVertexLight = input.interp7.xyzw;
                    output.shadowCoord = input.interp8.xyzw;
                    #if UNITY_ANY_INSTANCING_ENABLED
                    output.instanceID = input.instanceID;
                    #endif
                    #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
                    output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
                    #endif
                    #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
                    output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
                    #endif
                    #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
                    output.cullFace = input.cullFace;
                    #endif
                    return output;
                }
    
                // --------------------------------------------------
                // Graph
    
                // Graph Properties
                CBUFFER_START(UnityPerMaterial)
                float _AmbientStrength;
                float4 _DiffuseColor;
                float4 _MainTex_TexelSize;
                float4 _SpecularColor;
                float4 _FresnelColor;
                float _Smoothness;
                float _FresnelSize;
                float _LightingCutoff;
                float _FalloffAmount;
                CBUFFER_END
                
                // Object and Global properties
                SAMPLER(SamplerState_Linear_Repeat);
                TEXTURE2D(_MainTex);
                SAMPLER(sampler_MainTex);
    
                // Graph Functions
                
                void Unity_Add_float(float A, float B, out float Out)
                {
                    Out = A + B;
                }
                
                void Unity_Reciprocal_float(float In, out float Out)
                {
                    Out = 1.0/In;
                }
                
                void Unity_FresnelEffect_float(float3 Normal, float3 ViewDir, float Power, out float Out)
                {
                    Out = pow((1.0 - saturate(dot(normalize(Normal), normalize(ViewDir)))), Power);
                }
                
                // a6264222ffebf7cfce349cb3e07ea356
                #include "./Lighting.hlsl"
                
                void Unity_Multiply_float(float A, float B, out float Out)
                {
                    Out = A * B;
                }
                
                struct Bindings_GetMainLight_d6b14a2e8b6f3554b8459648535f697e
                {
                };
                
                void SG_GetMainLight_d6b14a2e8b6f3554b8459648535f697e(float3 Vector3_b21c75b9b8514ef286d5e6dc199fa9af, Bindings_GetMainLight_d6b14a2e8b6f3554b8459648535f697e IN, out float3 Direction_0, out float3 Color_1, out float Attenuation_2)
                {
                    float3 _Property_923162a64885457196b5ccbf7a2aaac7_Out_0 = Vector3_b21c75b9b8514ef286d5e6dc199fa9af;
                    float3 _MainLightCustomFunction_93e39954c04146b5ae1be272ea9d714b_Direction_0;
                    float3 _MainLightCustomFunction_93e39954c04146b5ae1be272ea9d714b_Color_2;
                    float _MainLightCustomFunction_93e39954c04146b5ae1be272ea9d714b_DistanceAtten_3;
                    float _MainLightCustomFunction_93e39954c04146b5ae1be272ea9d714b_ShadowAtten_4;
                    MainLight_float(_Property_923162a64885457196b5ccbf7a2aaac7_Out_0, _MainLightCustomFunction_93e39954c04146b5ae1be272ea9d714b_Direction_0, _MainLightCustomFunction_93e39954c04146b5ae1be272ea9d714b_Color_2, _MainLightCustomFunction_93e39954c04146b5ae1be272ea9d714b_DistanceAtten_3, _MainLightCustomFunction_93e39954c04146b5ae1be272ea9d714b_ShadowAtten_4);
                    float _Multiply_6d878674c9b447478a9564442340c0a2_Out_2;
                    Unity_Multiply_float(_MainLightCustomFunction_93e39954c04146b5ae1be272ea9d714b_DistanceAtten_3, _MainLightCustomFunction_93e39954c04146b5ae1be272ea9d714b_ShadowAtten_4, _Multiply_6d878674c9b447478a9564442340c0a2_Out_2);
                    Direction_0 = _MainLightCustomFunction_93e39954c04146b5ae1be272ea9d714b_Direction_0;
                    Color_1 = _MainLightCustomFunction_93e39954c04146b5ae1be272ea9d714b_Color_2;
                    Attenuation_2 = _Multiply_6d878674c9b447478a9564442340c0a2_Out_2;
                }
                
                void Unity_DotProduct_float3(float3 A, float3 B, out float Out)
                {
                    Out = dot(A, B);
                }
                
                void Unity_Multiply_float(float3 A, float3 B, out float3 Out)
                {
                    Out = A * B;
                }
                
                void Unity_Saturate_float3(float3 In, out float3 Out)
                {
                    Out = saturate(In);
                }
                
                struct Bindings_GetAdditionalLight_b5516a5008f7d104abebe27210c42de8
                {
                };
                
                void SG_GetAdditionalLight_b5516a5008f7d104abebe27210c42de8(float3 Vector3_1e07dec0084a48e38c95166c3cdc688d, float Vector1_0ce9574e837f408991312a6c71473833, Bindings_GetAdditionalLight_b5516a5008f7d104abebe27210c42de8 IN, out float3 Direction_0, out float3 Color_1, out float Attenuation_2)
                {
                    float3 _Property_e9927ccc4a684aeabdaa70dbe76689f0_Out_0 = Vector3_1e07dec0084a48e38c95166c3cdc688d;
                    float _Property_c6fa454cb94449b6923e1c90fafaf929_Out_0 = Vector1_0ce9574e837f408991312a6c71473833;
                    float3 _AdditionalLightCustomFunction_c6ec52ed99634926b12dc96d48e96f1b_Direction_1;
                    float3 _AdditionalLightCustomFunction_c6ec52ed99634926b12dc96d48e96f1b_Color_2;
                    float _AdditionalLightCustomFunction_c6ec52ed99634926b12dc96d48e96f1b_DistanceAtten_3;
                    float _AdditionalLightCustomFunction_c6ec52ed99634926b12dc96d48e96f1b_ShadowAtten_4;
                    AdditionalLight_float(_Property_e9927ccc4a684aeabdaa70dbe76689f0_Out_0, _Property_c6fa454cb94449b6923e1c90fafaf929_Out_0, _AdditionalLightCustomFunction_c6ec52ed99634926b12dc96d48e96f1b_Direction_1, _AdditionalLightCustomFunction_c6ec52ed99634926b12dc96d48e96f1b_Color_2, _AdditionalLightCustomFunction_c6ec52ed99634926b12dc96d48e96f1b_DistanceAtten_3, _AdditionalLightCustomFunction_c6ec52ed99634926b12dc96d48e96f1b_ShadowAtten_4);
                    float _Multiply_0b8ec7bbb926441e8c14c7c32d369adf_Out_2;
                    Unity_Multiply_float(_AdditionalLightCustomFunction_c6ec52ed99634926b12dc96d48e96f1b_DistanceAtten_3, _AdditionalLightCustomFunction_c6ec52ed99634926b12dc96d48e96f1b_ShadowAtten_4, _Multiply_0b8ec7bbb926441e8c14c7c32d369adf_Out_2);
                    Direction_0 = _AdditionalLightCustomFunction_c6ec52ed99634926b12dc96d48e96f1b_Direction_1;
                    Color_1 = _AdditionalLightCustomFunction_c6ec52ed99634926b12dc96d48e96f1b_Color_2;
                    Attenuation_2 = _Multiply_0b8ec7bbb926441e8c14c7c32d369adf_Out_2;
                }
                
                void Unity_Saturate_float(float In, out float Out)
                {
                    Out = saturate(In);
                }
                
                void Unity_Add_float3(float3 A, float3 B, out float3 Out)
                {
                    Out = A + B;
                }
                
                struct Bindings_CalcAdditionalDiffuse_e85823578a3493d41ade631af12166aa
                {
                    float3 WorldSpaceNormal;
                    float3 WorldSpacePosition;
                };
                
                void SG_CalcAdditionalDiffuse_e85823578a3493d41ade631af12166aa(Bindings_CalcAdditionalDiffuse_e85823578a3493d41ade631af12166aa IN, out float3 Diffuse_1)
                {
                    Bindings_GetAdditionalLight_b5516a5008f7d104abebe27210c42de8 _GetAdditionalLight_e6c10dfa199649fca18a0cb673fcba44;
                    float3 _GetAdditionalLight_e6c10dfa199649fca18a0cb673fcba44_Direction_0;
                    float3 _GetAdditionalLight_e6c10dfa199649fca18a0cb673fcba44_Color_1;
                    float _GetAdditionalLight_e6c10dfa199649fca18a0cb673fcba44_Attenuation_2;
                    SG_GetAdditionalLight_b5516a5008f7d104abebe27210c42de8(IN.WorldSpacePosition, 0, _GetAdditionalLight_e6c10dfa199649fca18a0cb673fcba44, _GetAdditionalLight_e6c10dfa199649fca18a0cb673fcba44_Direction_0, _GetAdditionalLight_e6c10dfa199649fca18a0cb673fcba44_Color_1, _GetAdditionalLight_e6c10dfa199649fca18a0cb673fcba44_Attenuation_2);
                    float _DotProduct_aee5f4b498024e2da9796ed342f8a43a_Out_2;
                    Unity_DotProduct_float3(_GetAdditionalLight_e6c10dfa199649fca18a0cb673fcba44_Direction_0, IN.WorldSpaceNormal, _DotProduct_aee5f4b498024e2da9796ed342f8a43a_Out_2);
                    float _Saturate_2080d664f6004dc9ad574ba7e91917b2_Out_1;
                    Unity_Saturate_float(_DotProduct_aee5f4b498024e2da9796ed342f8a43a_Out_2, _Saturate_2080d664f6004dc9ad574ba7e91917b2_Out_1);
                    float3 _Multiply_57fcc7dc0fb845cf924c855eadbb7792_Out_2;
                    Unity_Multiply_float((_Saturate_2080d664f6004dc9ad574ba7e91917b2_Out_1.xxx), _GetAdditionalLight_e6c10dfa199649fca18a0cb673fcba44_Color_1, _Multiply_57fcc7dc0fb845cf924c855eadbb7792_Out_2);
                    float3 _Multiply_59016ca5433045d0a06ff03a13ec13b6_Out_2;
                    Unity_Multiply_float(_Multiply_57fcc7dc0fb845cf924c855eadbb7792_Out_2, (_GetAdditionalLight_e6c10dfa199649fca18a0cb673fcba44_Attenuation_2.xxx), _Multiply_59016ca5433045d0a06ff03a13ec13b6_Out_2);
                    Bindings_GetAdditionalLight_b5516a5008f7d104abebe27210c42de8 _GetAdditionalLight_a054a4cd5b484e1492208dc9ca4a85f5;
                    float3 _GetAdditionalLight_a054a4cd5b484e1492208dc9ca4a85f5_Direction_0;
                    float3 _GetAdditionalLight_a054a4cd5b484e1492208dc9ca4a85f5_Color_1;
                    float _GetAdditionalLight_a054a4cd5b484e1492208dc9ca4a85f5_Attenuation_2;
                    SG_GetAdditionalLight_b5516a5008f7d104abebe27210c42de8(IN.WorldSpacePosition, 1, _GetAdditionalLight_a054a4cd5b484e1492208dc9ca4a85f5, _GetAdditionalLight_a054a4cd5b484e1492208dc9ca4a85f5_Direction_0, _GetAdditionalLight_a054a4cd5b484e1492208dc9ca4a85f5_Color_1, _GetAdditionalLight_a054a4cd5b484e1492208dc9ca4a85f5_Attenuation_2);
                    float _DotProduct_00e581a08ce7465588597fd11859eea2_Out_2;
                    Unity_DotProduct_float3(_GetAdditionalLight_a054a4cd5b484e1492208dc9ca4a85f5_Direction_0, IN.WorldSpaceNormal, _DotProduct_00e581a08ce7465588597fd11859eea2_Out_2);
                    float _Saturate_58b5f4d3dcaf45e6bda212ef43edc4ea_Out_1;
                    Unity_Saturate_float(_DotProduct_00e581a08ce7465588597fd11859eea2_Out_2, _Saturate_58b5f4d3dcaf45e6bda212ef43edc4ea_Out_1);
                    float3 _Multiply_6ff1cb7ecc8542848d8d721f284a3b3c_Out_2;
                    Unity_Multiply_float((_Saturate_58b5f4d3dcaf45e6bda212ef43edc4ea_Out_1.xxx), _GetAdditionalLight_a054a4cd5b484e1492208dc9ca4a85f5_Color_1, _Multiply_6ff1cb7ecc8542848d8d721f284a3b3c_Out_2);
                    float3 _Multiply_8337e9ec92b74cefb421776f67b29661_Out_2;
                    Unity_Multiply_float(_Multiply_6ff1cb7ecc8542848d8d721f284a3b3c_Out_2, (_GetAdditionalLight_a054a4cd5b484e1492208dc9ca4a85f5_Attenuation_2.xxx), _Multiply_8337e9ec92b74cefb421776f67b29661_Out_2);
                    float3 _Add_8d5fe4674e364518a5d8f4559669df92_Out_2;
                    Unity_Add_float3(_Multiply_59016ca5433045d0a06ff03a13ec13b6_Out_2, _Multiply_8337e9ec92b74cefb421776f67b29661_Out_2, _Add_8d5fe4674e364518a5d8f4559669df92_Out_2);
                    Bindings_GetAdditionalLight_b5516a5008f7d104abebe27210c42de8 _GetAdditionalLight_ee2152ac3ed64138932b3a2e4b8e3f14;
                    float3 _GetAdditionalLight_ee2152ac3ed64138932b3a2e4b8e3f14_Direction_0;
                    float3 _GetAdditionalLight_ee2152ac3ed64138932b3a2e4b8e3f14_Color_1;
                    float _GetAdditionalLight_ee2152ac3ed64138932b3a2e4b8e3f14_Attenuation_2;
                    SG_GetAdditionalLight_b5516a5008f7d104abebe27210c42de8(IN.WorldSpacePosition, 2, _GetAdditionalLight_ee2152ac3ed64138932b3a2e4b8e3f14, _GetAdditionalLight_ee2152ac3ed64138932b3a2e4b8e3f14_Direction_0, _GetAdditionalLight_ee2152ac3ed64138932b3a2e4b8e3f14_Color_1, _GetAdditionalLight_ee2152ac3ed64138932b3a2e4b8e3f14_Attenuation_2);
                    float _DotProduct_7a3fce316c4a453e9b9e18226fc2d066_Out_2;
                    Unity_DotProduct_float3(_GetAdditionalLight_ee2152ac3ed64138932b3a2e4b8e3f14_Direction_0, IN.WorldSpaceNormal, _DotProduct_7a3fce316c4a453e9b9e18226fc2d066_Out_2);
                    float _Saturate_c9919732b14f4622aa82e1eec5cb383d_Out_1;
                    Unity_Saturate_float(_DotProduct_7a3fce316c4a453e9b9e18226fc2d066_Out_2, _Saturate_c9919732b14f4622aa82e1eec5cb383d_Out_1);
                    float3 _Multiply_013e04c47fdf4f46a7f2a4868ec83bed_Out_2;
                    Unity_Multiply_float((_Saturate_c9919732b14f4622aa82e1eec5cb383d_Out_1.xxx), _GetAdditionalLight_ee2152ac3ed64138932b3a2e4b8e3f14_Color_1, _Multiply_013e04c47fdf4f46a7f2a4868ec83bed_Out_2);
                    float3 _Multiply_8d16da0d689d4d49909909e6c2cc2da6_Out_2;
                    Unity_Multiply_float(_Multiply_013e04c47fdf4f46a7f2a4868ec83bed_Out_2, (_GetAdditionalLight_ee2152ac3ed64138932b3a2e4b8e3f14_Attenuation_2.xxx), _Multiply_8d16da0d689d4d49909909e6c2cc2da6_Out_2);
                    Bindings_GetAdditionalLight_b5516a5008f7d104abebe27210c42de8 _GetAdditionalLight_da7753016bd64b489b897349d7f3fc0f;
                    float3 _GetAdditionalLight_da7753016bd64b489b897349d7f3fc0f_Direction_0;
                    float3 _GetAdditionalLight_da7753016bd64b489b897349d7f3fc0f_Color_1;
                    float _GetAdditionalLight_da7753016bd64b489b897349d7f3fc0f_Attenuation_2;
                    SG_GetAdditionalLight_b5516a5008f7d104abebe27210c42de8(IN.WorldSpacePosition, 3, _GetAdditionalLight_da7753016bd64b489b897349d7f3fc0f, _GetAdditionalLight_da7753016bd64b489b897349d7f3fc0f_Direction_0, _GetAdditionalLight_da7753016bd64b489b897349d7f3fc0f_Color_1, _GetAdditionalLight_da7753016bd64b489b897349d7f3fc0f_Attenuation_2);
                    float _DotProduct_be3ed23b71d142e3a88f9f21ca2b9bb1_Out_2;
                    Unity_DotProduct_float3(_GetAdditionalLight_da7753016bd64b489b897349d7f3fc0f_Direction_0, IN.WorldSpaceNormal, _DotProduct_be3ed23b71d142e3a88f9f21ca2b9bb1_Out_2);
                    float _Saturate_b3794fe44470430e954d43bb481a3d9a_Out_1;
                    Unity_Saturate_float(_DotProduct_be3ed23b71d142e3a88f9f21ca2b9bb1_Out_2, _Saturate_b3794fe44470430e954d43bb481a3d9a_Out_1);
                    float3 _Multiply_fcf9bc551f0e42f39634ac95fab7cae5_Out_2;
                    Unity_Multiply_float((_Saturate_b3794fe44470430e954d43bb481a3d9a_Out_1.xxx), _GetAdditionalLight_da7753016bd64b489b897349d7f3fc0f_Color_1, _Multiply_fcf9bc551f0e42f39634ac95fab7cae5_Out_2);
                    float3 _Multiply_0cc8c00775354d6a9f91977c3e357ff8_Out_2;
                    Unity_Multiply_float(_Multiply_fcf9bc551f0e42f39634ac95fab7cae5_Out_2, (_GetAdditionalLight_da7753016bd64b489b897349d7f3fc0f_Attenuation_2.xxx), _Multiply_0cc8c00775354d6a9f91977c3e357ff8_Out_2);
                    float3 _Add_0992646b9a764f6eb220517d0e9fc815_Out_2;
                    Unity_Add_float3(_Multiply_8d16da0d689d4d49909909e6c2cc2da6_Out_2, _Multiply_0cc8c00775354d6a9f91977c3e357ff8_Out_2, _Add_0992646b9a764f6eb220517d0e9fc815_Out_2);
                    float3 _Add_d239c6ae017b45cba8fda7bfa29dc880_Out_2;
                    Unity_Add_float3(_Add_8d5fe4674e364518a5d8f4559669df92_Out_2, _Add_0992646b9a764f6eb220517d0e9fc815_Out_2, _Add_d239c6ae017b45cba8fda7bfa29dc880_Out_2);
                    Diffuse_1 = _Add_d239c6ae017b45cba8fda7bfa29dc880_Out_2;
                }
                
                void Unity_Smoothstep_float3(float3 Edge1, float3 Edge2, float3 In, out float3 Out)
                {
                    Out = smoothstep(Edge1, Edge2, In);
                }
                
                void Unity_Normalize_float3(float3 In, out float3 Out)
                {
                    Out = normalize(In);
                }
                
                void Unity_Power_float(float A, float B, out float Out)
                {
                    Out = pow(A, B);
                }
                
                void Unity_Step_float(float Edge, float In, out float Out)
                {
                    Out = step(Edge, In);
                }
                
                struct Bindings_CalcAdditionalSpecular_d84098efe9b2b6043a74a1631b825314
                {
                    float3 WorldSpaceNormal;
                    float3 WorldSpaceViewDirection;
                    float3 WorldSpacePosition;
                };
                
                void SG_CalcAdditionalSpecular_d84098efe9b2b6043a74a1631b825314(float Vector1_ba56f786be984242bee2ff33f2d093fc, Bindings_CalcAdditionalSpecular_d84098efe9b2b6043a74a1631b825314 IN, out float3 Diffuse_1)
                {
                    Bindings_GetAdditionalLight_b5516a5008f7d104abebe27210c42de8 _GetAdditionalLight_e6c10dfa199649fca18a0cb673fcba44;
                    float3 _GetAdditionalLight_e6c10dfa199649fca18a0cb673fcba44_Direction_0;
                    float3 _GetAdditionalLight_e6c10dfa199649fca18a0cb673fcba44_Color_1;
                    float _GetAdditionalLight_e6c10dfa199649fca18a0cb673fcba44_Attenuation_2;
                    SG_GetAdditionalLight_b5516a5008f7d104abebe27210c42de8(IN.WorldSpacePosition, 0, _GetAdditionalLight_e6c10dfa199649fca18a0cb673fcba44, _GetAdditionalLight_e6c10dfa199649fca18a0cb673fcba44_Direction_0, _GetAdditionalLight_e6c10dfa199649fca18a0cb673fcba44_Color_1, _GetAdditionalLight_e6c10dfa199649fca18a0cb673fcba44_Attenuation_2);
                    float3 _Add_7b85500005d849309401cd5cf5ee87fd_Out_2;
                    Unity_Add_float3(_GetAdditionalLight_e6c10dfa199649fca18a0cb673fcba44_Direction_0, IN.WorldSpaceViewDirection, _Add_7b85500005d849309401cd5cf5ee87fd_Out_2);
                    float3 _Normalize_e287e84e1db74e1d979a340af21eb458_Out_1;
                    Unity_Normalize_float3(_Add_7b85500005d849309401cd5cf5ee87fd_Out_2, _Normalize_e287e84e1db74e1d979a340af21eb458_Out_1);
                    float _DotProduct_aee5f4b498024e2da9796ed342f8a43a_Out_2;
                    Unity_DotProduct_float3(_Normalize_e287e84e1db74e1d979a340af21eb458_Out_1, IN.WorldSpaceNormal, _DotProduct_aee5f4b498024e2da9796ed342f8a43a_Out_2);
                    float _Saturate_2080d664f6004dc9ad574ba7e91917b2_Out_1;
                    Unity_Saturate_float(_DotProduct_aee5f4b498024e2da9796ed342f8a43a_Out_2, _Saturate_2080d664f6004dc9ad574ba7e91917b2_Out_1);
                    float _DotProduct_0526a944521c47d3b6c84b963fedd1ff_Out_2;
                    Unity_DotProduct_float3(_GetAdditionalLight_e6c10dfa199649fca18a0cb673fcba44_Direction_0, IN.WorldSpaceNormal, _DotProduct_0526a944521c47d3b6c84b963fedd1ff_Out_2);
                    float _Step_c67d6a53c975466dbaef6447b6a8bb15_Out_2;
                    Unity_Step_float(0, _DotProduct_0526a944521c47d3b6c84b963fedd1ff_Out_2, _Step_c67d6a53c975466dbaef6447b6a8bb15_Out_2);
                    float _Multiply_31278482890d4002a4b8eaea84d893d7_Out_2;
                    Unity_Multiply_float(_Saturate_2080d664f6004dc9ad574ba7e91917b2_Out_1, _Step_c67d6a53c975466dbaef6447b6a8bb15_Out_2, _Multiply_31278482890d4002a4b8eaea84d893d7_Out_2);
                    float _Property_b388a74e1b6a4d90939e467c9ef567a3_Out_0 = Vector1_ba56f786be984242bee2ff33f2d093fc;
                    float _Power_99f8e80de63e4acaa6046138e24f4bd2_Out_2;
                    Unity_Power_float(_Multiply_31278482890d4002a4b8eaea84d893d7_Out_2, _Property_b388a74e1b6a4d90939e467c9ef567a3_Out_0, _Power_99f8e80de63e4acaa6046138e24f4bd2_Out_2);
                    float3 _Multiply_9cc47eeb7de841d19b65dc8e1cb229c5_Out_2;
                    Unity_Multiply_float((_Power_99f8e80de63e4acaa6046138e24f4bd2_Out_2.xxx), _GetAdditionalLight_e6c10dfa199649fca18a0cb673fcba44_Color_1, _Multiply_9cc47eeb7de841d19b65dc8e1cb229c5_Out_2);
                    float3 _Multiply_40c5102279054efb933d4fd61a725966_Out_2;
                    Unity_Multiply_float(_Multiply_9cc47eeb7de841d19b65dc8e1cb229c5_Out_2, (_GetAdditionalLight_e6c10dfa199649fca18a0cb673fcba44_Attenuation_2.xxx), _Multiply_40c5102279054efb933d4fd61a725966_Out_2);
                    Bindings_GetAdditionalLight_b5516a5008f7d104abebe27210c42de8 _GetAdditionalLight_a054a4cd5b484e1492208dc9ca4a85f5;
                    float3 _GetAdditionalLight_a054a4cd5b484e1492208dc9ca4a85f5_Direction_0;
                    float3 _GetAdditionalLight_a054a4cd5b484e1492208dc9ca4a85f5_Color_1;
                    float _GetAdditionalLight_a054a4cd5b484e1492208dc9ca4a85f5_Attenuation_2;
                    SG_GetAdditionalLight_b5516a5008f7d104abebe27210c42de8(IN.WorldSpacePosition, 1, _GetAdditionalLight_a054a4cd5b484e1492208dc9ca4a85f5, _GetAdditionalLight_a054a4cd5b484e1492208dc9ca4a85f5_Direction_0, _GetAdditionalLight_a054a4cd5b484e1492208dc9ca4a85f5_Color_1, _GetAdditionalLight_a054a4cd5b484e1492208dc9ca4a85f5_Attenuation_2);
                    float3 _Add_282adf4f675a4392bdd7447da1537cff_Out_2;
                    Unity_Add_float3(_GetAdditionalLight_a054a4cd5b484e1492208dc9ca4a85f5_Direction_0, IN.WorldSpaceViewDirection, _Add_282adf4f675a4392bdd7447da1537cff_Out_2);
                    float3 _Normalize_d3d2dd5bbe7e4e749daa7d0b940b66e2_Out_1;
                    Unity_Normalize_float3(_Add_282adf4f675a4392bdd7447da1537cff_Out_2, _Normalize_d3d2dd5bbe7e4e749daa7d0b940b66e2_Out_1);
                    float _DotProduct_00e581a08ce7465588597fd11859eea2_Out_2;
                    Unity_DotProduct_float3(_Normalize_d3d2dd5bbe7e4e749daa7d0b940b66e2_Out_1, IN.WorldSpaceNormal, _DotProduct_00e581a08ce7465588597fd11859eea2_Out_2);
                    float _Saturate_58b5f4d3dcaf45e6bda212ef43edc4ea_Out_1;
                    Unity_Saturate_float(_DotProduct_00e581a08ce7465588597fd11859eea2_Out_2, _Saturate_58b5f4d3dcaf45e6bda212ef43edc4ea_Out_1);
                    float _DotProduct_e5d1d640606340949f9ecba8df9c866d_Out_2;
                    Unity_DotProduct_float3(_GetAdditionalLight_a054a4cd5b484e1492208dc9ca4a85f5_Direction_0, IN.WorldSpaceNormal, _DotProduct_e5d1d640606340949f9ecba8df9c866d_Out_2);
                    float _Step_d5595987000246e096b1bd14ec15600e_Out_2;
                    Unity_Step_float(0, _DotProduct_e5d1d640606340949f9ecba8df9c866d_Out_2, _Step_d5595987000246e096b1bd14ec15600e_Out_2);
                    float _Multiply_556cb17951c5463481d66c85c69f72ae_Out_2;
                    Unity_Multiply_float(_Saturate_58b5f4d3dcaf45e6bda212ef43edc4ea_Out_1, _Step_d5595987000246e096b1bd14ec15600e_Out_2, _Multiply_556cb17951c5463481d66c85c69f72ae_Out_2);
                    float _Power_1783632603444ae9bd39ecc3677738f0_Out_2;
                    Unity_Power_float(_Multiply_556cb17951c5463481d66c85c69f72ae_Out_2, _Property_b388a74e1b6a4d90939e467c9ef567a3_Out_0, _Power_1783632603444ae9bd39ecc3677738f0_Out_2);
                    float3 _Multiply_f4914d2b6dae4123a4ce1897d42f8dda_Out_2;
                    Unity_Multiply_float((_Power_1783632603444ae9bd39ecc3677738f0_Out_2.xxx), _GetAdditionalLight_a054a4cd5b484e1492208dc9ca4a85f5_Color_1, _Multiply_f4914d2b6dae4123a4ce1897d42f8dda_Out_2);
                    float3 _Multiply_dff05416518540d5b4d99dfdf00c5766_Out_2;
                    Unity_Multiply_float(_Multiply_f4914d2b6dae4123a4ce1897d42f8dda_Out_2, (_GetAdditionalLight_a054a4cd5b484e1492208dc9ca4a85f5_Attenuation_2.xxx), _Multiply_dff05416518540d5b4d99dfdf00c5766_Out_2);
                    float3 _Add_8d5fe4674e364518a5d8f4559669df92_Out_2;
                    Unity_Add_float3(_Multiply_40c5102279054efb933d4fd61a725966_Out_2, _Multiply_dff05416518540d5b4d99dfdf00c5766_Out_2, _Add_8d5fe4674e364518a5d8f4559669df92_Out_2);
                    Bindings_GetAdditionalLight_b5516a5008f7d104abebe27210c42de8 _GetAdditionalLight_ee2152ac3ed64138932b3a2e4b8e3f14;
                    float3 _GetAdditionalLight_ee2152ac3ed64138932b3a2e4b8e3f14_Direction_0;
                    float3 _GetAdditionalLight_ee2152ac3ed64138932b3a2e4b8e3f14_Color_1;
                    float _GetAdditionalLight_ee2152ac3ed64138932b3a2e4b8e3f14_Attenuation_2;
                    SG_GetAdditionalLight_b5516a5008f7d104abebe27210c42de8(IN.WorldSpacePosition, 2, _GetAdditionalLight_ee2152ac3ed64138932b3a2e4b8e3f14, _GetAdditionalLight_ee2152ac3ed64138932b3a2e4b8e3f14_Direction_0, _GetAdditionalLight_ee2152ac3ed64138932b3a2e4b8e3f14_Color_1, _GetAdditionalLight_ee2152ac3ed64138932b3a2e4b8e3f14_Attenuation_2);
                    float3 _Add_b3b13d361198482f9ee7222ea4d9d819_Out_2;
                    Unity_Add_float3(_GetAdditionalLight_ee2152ac3ed64138932b3a2e4b8e3f14_Direction_0, IN.WorldSpaceViewDirection, _Add_b3b13d361198482f9ee7222ea4d9d819_Out_2);
                    float3 _Normalize_ceaea3816fe94ba48dc9c37f6336e177_Out_1;
                    Unity_Normalize_float3(_Add_b3b13d361198482f9ee7222ea4d9d819_Out_2, _Normalize_ceaea3816fe94ba48dc9c37f6336e177_Out_1);
                    float _DotProduct_7a3fce316c4a453e9b9e18226fc2d066_Out_2;
                    Unity_DotProduct_float3(_Normalize_ceaea3816fe94ba48dc9c37f6336e177_Out_1, IN.WorldSpaceNormal, _DotProduct_7a3fce316c4a453e9b9e18226fc2d066_Out_2);
                    float _Saturate_c9919732b14f4622aa82e1eec5cb383d_Out_1;
                    Unity_Saturate_float(_DotProduct_7a3fce316c4a453e9b9e18226fc2d066_Out_2, _Saturate_c9919732b14f4622aa82e1eec5cb383d_Out_1);
                    float _DotProduct_172616bd9ee743ac9176fabfc0972b90_Out_2;
                    Unity_DotProduct_float3(_GetAdditionalLight_ee2152ac3ed64138932b3a2e4b8e3f14_Direction_0, IN.WorldSpaceNormal, _DotProduct_172616bd9ee743ac9176fabfc0972b90_Out_2);
                    float _Step_6ae114101d8f4d26a00a90cccaa45672_Out_2;
                    Unity_Step_float(0, _DotProduct_172616bd9ee743ac9176fabfc0972b90_Out_2, _Step_6ae114101d8f4d26a00a90cccaa45672_Out_2);
                    float _Multiply_4a9b97617c2448dea4f10cdcb58d4202_Out_2;
                    Unity_Multiply_float(_Saturate_c9919732b14f4622aa82e1eec5cb383d_Out_1, _Step_6ae114101d8f4d26a00a90cccaa45672_Out_2, _Multiply_4a9b97617c2448dea4f10cdcb58d4202_Out_2);
                    float _Power_0801befaab9143ffb3380be20bbdc5ab_Out_2;
                    Unity_Power_float(_Multiply_4a9b97617c2448dea4f10cdcb58d4202_Out_2, _Property_b388a74e1b6a4d90939e467c9ef567a3_Out_0, _Power_0801befaab9143ffb3380be20bbdc5ab_Out_2);
                    float3 _Multiply_cef864918e1e44799f326a20b8334c24_Out_2;
                    Unity_Multiply_float((_Power_0801befaab9143ffb3380be20bbdc5ab_Out_2.xxx), _GetAdditionalLight_ee2152ac3ed64138932b3a2e4b8e3f14_Color_1, _Multiply_cef864918e1e44799f326a20b8334c24_Out_2);
                    float3 _Multiply_d95d25aea25e4461b8a3af2420f0d8e2_Out_2;
                    Unity_Multiply_float(_Multiply_cef864918e1e44799f326a20b8334c24_Out_2, (_GetAdditionalLight_ee2152ac3ed64138932b3a2e4b8e3f14_Attenuation_2.xxx), _Multiply_d95d25aea25e4461b8a3af2420f0d8e2_Out_2);
                    Bindings_GetAdditionalLight_b5516a5008f7d104abebe27210c42de8 _GetAdditionalLight_da7753016bd64b489b897349d7f3fc0f;
                    float3 _GetAdditionalLight_da7753016bd64b489b897349d7f3fc0f_Direction_0;
                    float3 _GetAdditionalLight_da7753016bd64b489b897349d7f3fc0f_Color_1;
                    float _GetAdditionalLight_da7753016bd64b489b897349d7f3fc0f_Attenuation_2;
                    SG_GetAdditionalLight_b5516a5008f7d104abebe27210c42de8(IN.WorldSpacePosition, 3, _GetAdditionalLight_da7753016bd64b489b897349d7f3fc0f, _GetAdditionalLight_da7753016bd64b489b897349d7f3fc0f_Direction_0, _GetAdditionalLight_da7753016bd64b489b897349d7f3fc0f_Color_1, _GetAdditionalLight_da7753016bd64b489b897349d7f3fc0f_Attenuation_2);
                    float3 _Add_3d580f5eb4d44d1a9308632cf3541341_Out_2;
                    Unity_Add_float3(_GetAdditionalLight_da7753016bd64b489b897349d7f3fc0f_Direction_0, IN.WorldSpaceViewDirection, _Add_3d580f5eb4d44d1a9308632cf3541341_Out_2);
                    float3 _Normalize_d6753f83c1d7448991e6e7d8b08f3ffe_Out_1;
                    Unity_Normalize_float3(_Add_3d580f5eb4d44d1a9308632cf3541341_Out_2, _Normalize_d6753f83c1d7448991e6e7d8b08f3ffe_Out_1);
                    float _DotProduct_be3ed23b71d142e3a88f9f21ca2b9bb1_Out_2;
                    Unity_DotProduct_float3(_Normalize_d6753f83c1d7448991e6e7d8b08f3ffe_Out_1, IN.WorldSpaceNormal, _DotProduct_be3ed23b71d142e3a88f9f21ca2b9bb1_Out_2);
                    float _Saturate_b3794fe44470430e954d43bb481a3d9a_Out_1;
                    Unity_Saturate_float(_DotProduct_be3ed23b71d142e3a88f9f21ca2b9bb1_Out_2, _Saturate_b3794fe44470430e954d43bb481a3d9a_Out_1);
                    float _DotProduct_6919254c79d54f02beaaea46cea4bb88_Out_2;
                    Unity_DotProduct_float3(_GetAdditionalLight_da7753016bd64b489b897349d7f3fc0f_Direction_0, IN.WorldSpaceNormal, _DotProduct_6919254c79d54f02beaaea46cea4bb88_Out_2);
                    float _Step_298fb6a31079465894cd805c44c575e3_Out_2;
                    Unity_Step_float(0, _DotProduct_6919254c79d54f02beaaea46cea4bb88_Out_2, _Step_298fb6a31079465894cd805c44c575e3_Out_2);
                    float _Multiply_2531419c34224bfd8f2a6b986099fc14_Out_2;
                    Unity_Multiply_float(_Saturate_b3794fe44470430e954d43bb481a3d9a_Out_1, _Step_298fb6a31079465894cd805c44c575e3_Out_2, _Multiply_2531419c34224bfd8f2a6b986099fc14_Out_2);
                    float _Power_ef3de81b9a0f42a7a6689a0949350c4f_Out_2;
                    Unity_Power_float(_Multiply_2531419c34224bfd8f2a6b986099fc14_Out_2, _Property_b388a74e1b6a4d90939e467c9ef567a3_Out_0, _Power_ef3de81b9a0f42a7a6689a0949350c4f_Out_2);
                    float3 _Multiply_8962de9ab0024826abfc88590336908a_Out_2;
                    Unity_Multiply_float((_Power_ef3de81b9a0f42a7a6689a0949350c4f_Out_2.xxx), _GetAdditionalLight_da7753016bd64b489b897349d7f3fc0f_Color_1, _Multiply_8962de9ab0024826abfc88590336908a_Out_2);
                    float3 _Multiply_d130cd99cdd04ddbb2d61d5a1fa09fd9_Out_2;
                    Unity_Multiply_float(_Multiply_8962de9ab0024826abfc88590336908a_Out_2, (_GetAdditionalLight_da7753016bd64b489b897349d7f3fc0f_Attenuation_2.xxx), _Multiply_d130cd99cdd04ddbb2d61d5a1fa09fd9_Out_2);
                    float3 _Add_0992646b9a764f6eb220517d0e9fc815_Out_2;
                    Unity_Add_float3(_Multiply_d95d25aea25e4461b8a3af2420f0d8e2_Out_2, _Multiply_d130cd99cdd04ddbb2d61d5a1fa09fd9_Out_2, _Add_0992646b9a764f6eb220517d0e9fc815_Out_2);
                    float3 _Add_d239c6ae017b45cba8fda7bfa29dc880_Out_2;
                    Unity_Add_float3(_Add_8d5fe4674e364518a5d8f4559669df92_Out_2, _Add_0992646b9a764f6eb220517d0e9fc815_Out_2, _Add_d239c6ae017b45cba8fda7bfa29dc880_Out_2);
                    Diffuse_1 = _Add_d239c6ae017b45cba8fda7bfa29dc880_Out_2;
                }
                
                void Unity_Maximum_float3(float3 A, float3 B, out float3 Out)
                {
                    Out = max(A, B);
                }
    
                // Graph Vertex
                struct VertexDescription
                {
                    float3 Position;
                    float3 Normal;
                    float3 Tangent;
                };
                
                VertexDescription VertexDescriptionFunction(VertexDescriptionInputs IN)
                {
                    VertexDescription description = (VertexDescription)0;
                    description.Position = IN.ObjectSpacePosition;
                    description.Normal = IN.ObjectSpaceNormal;
                    description.Tangent = IN.ObjectSpaceTangent;
                    return description;
                }
    
                // Graph Pixel
                struct SurfaceDescription
                {
                    float3 BaseColor;
                    float3 NormalTS;
                    float3 Emission;
                    float Metallic;
                    float Smoothness;
                    float Occlusion;
                };
                
                SurfaceDescription SurfaceDescriptionFunction(SurfaceDescriptionInputs IN)
                {
                    SurfaceDescription surface = (SurfaceDescription)0;
                    float4 _Property_fd7e56b6f55544e1b80c8fd2c097fb78_Out_0 = _FresnelColor;
                    float _Property_faab3ff61e174da380387a5284f29359_Out_0 = _LightingCutoff;
                    float _Property_1f83c6224c604735b8fc5e7585df4c66_Out_0 = _FalloffAmount;
                    float _Add_b1804a0ba53b477b9d8fb474b3008e5f_Out_2;
                    Unity_Add_float(_Property_faab3ff61e174da380387a5284f29359_Out_0, _Property_1f83c6224c604735b8fc5e7585df4c66_Out_0, _Add_b1804a0ba53b477b9d8fb474b3008e5f_Out_2);
                    float _Property_f71948fe16194e1c9767bb52a648a2c1_Out_0 = _FresnelSize;
                    float _Reciprocal_1ab5ff841a4e496dbcaf48eca728ce63_Out_1;
                    Unity_Reciprocal_float(_Property_f71948fe16194e1c9767bb52a648a2c1_Out_0, _Reciprocal_1ab5ff841a4e496dbcaf48eca728ce63_Out_1);
                    float _FresnelEffect_b85b6878ded3452382e4918a35e68e34_Out_3;
                    Unity_FresnelEffect_float(IN.WorldSpaceNormal, IN.WorldSpaceViewDirection, _Reciprocal_1ab5ff841a4e496dbcaf48eca728ce63_Out_1, _FresnelEffect_b85b6878ded3452382e4918a35e68e34_Out_3);
                    Bindings_GetMainLight_d6b14a2e8b6f3554b8459648535f697e _GetMainLight_41b37094e05a429f8266b6602caf8242;
                    float3 _GetMainLight_41b37094e05a429f8266b6602caf8242_Direction_0;
                    float3 _GetMainLight_41b37094e05a429f8266b6602caf8242_Color_1;
                    float _GetMainLight_41b37094e05a429f8266b6602caf8242_Attenuation_2;
                    SG_GetMainLight_d6b14a2e8b6f3554b8459648535f697e(IN.WorldSpacePosition, _GetMainLight_41b37094e05a429f8266b6602caf8242, _GetMainLight_41b37094e05a429f8266b6602caf8242_Direction_0, _GetMainLight_41b37094e05a429f8266b6602caf8242_Color_1, _GetMainLight_41b37094e05a429f8266b6602caf8242_Attenuation_2);
                    float _DotProduct_8d4bdec92ac948559d5a94572dd8cb4d_Out_2;
                    Unity_DotProduct_float3(IN.WorldSpaceNormal, _GetMainLight_41b37094e05a429f8266b6602caf8242_Direction_0, _DotProduct_8d4bdec92ac948559d5a94572dd8cb4d_Out_2);
                    float _Multiply_315cde53c6dc4a3592ed4ee8f047be73_Out_2;
                    Unity_Multiply_float(_DotProduct_8d4bdec92ac948559d5a94572dd8cb4d_Out_2, _GetMainLight_41b37094e05a429f8266b6602caf8242_Attenuation_2, _Multiply_315cde53c6dc4a3592ed4ee8f047be73_Out_2);
                    float3 _Multiply_250e64e5c0fe4aa3aa2515f930a78e5a_Out_2;
                    Unity_Multiply_float((_Multiply_315cde53c6dc4a3592ed4ee8f047be73_Out_2.xxx), _GetMainLight_41b37094e05a429f8266b6602caf8242_Color_1, _Multiply_250e64e5c0fe4aa3aa2515f930a78e5a_Out_2);
                    float3 _Saturate_fdaf2acf4b0d40b3ae196b038de92740_Out_1;
                    Unity_Saturate_float3(_Multiply_250e64e5c0fe4aa3aa2515f930a78e5a_Out_2, _Saturate_fdaf2acf4b0d40b3ae196b038de92740_Out_1);
                    Bindings_CalcAdditionalDiffuse_e85823578a3493d41ade631af12166aa _CalcAdditionalDiffuse_f61ebb0caffa49798669b455d28ddc2f;
                    _CalcAdditionalDiffuse_f61ebb0caffa49798669b455d28ddc2f.WorldSpaceNormal = IN.WorldSpaceNormal;
                    _CalcAdditionalDiffuse_f61ebb0caffa49798669b455d28ddc2f.WorldSpacePosition = IN.WorldSpacePosition;
                    float3 _CalcAdditionalDiffuse_f61ebb0caffa49798669b455d28ddc2f_Diffuse_1;
                    SG_CalcAdditionalDiffuse_e85823578a3493d41ade631af12166aa(_CalcAdditionalDiffuse_f61ebb0caffa49798669b455d28ddc2f, _CalcAdditionalDiffuse_f61ebb0caffa49798669b455d28ddc2f_Diffuse_1);
                    float3 _Add_0f6ab824bf464526bbf3116b8d1e102f_Out_2;
                    Unity_Add_float3(_Saturate_fdaf2acf4b0d40b3ae196b038de92740_Out_1, _CalcAdditionalDiffuse_f61ebb0caffa49798669b455d28ddc2f_Diffuse_1, _Add_0f6ab824bf464526bbf3116b8d1e102f_Out_2);
                    float3 _Multiply_57cc1ea2df2f4223815236660d4ba4b2_Out_2;
                    Unity_Multiply_float((_FresnelEffect_b85b6878ded3452382e4918a35e68e34_Out_3.xxx), _Add_0f6ab824bf464526bbf3116b8d1e102f_Out_2, _Multiply_57cc1ea2df2f4223815236660d4ba4b2_Out_2);
                    float3 _Smoothstep_424686c920094f11a03df5f03afe5145_Out_3;
                    Unity_Smoothstep_float3((_Property_faab3ff61e174da380387a5284f29359_Out_0.xxx), (_Add_b1804a0ba53b477b9d8fb474b3008e5f_Out_2.xxx), _Multiply_57cc1ea2df2f4223815236660d4ba4b2_Out_2, _Smoothstep_424686c920094f11a03df5f03afe5145_Out_3);
                    float3 _Multiply_08e1c96546e24df2920fcd26690a7402_Out_2;
                    Unity_Multiply_float((_Property_fd7e56b6f55544e1b80c8fd2c097fb78_Out_0.xyz), _Smoothstep_424686c920094f11a03df5f03afe5145_Out_3, _Multiply_08e1c96546e24df2920fcd26690a7402_Out_2);
                    float4 _Property_0d605fca5a9b4f2e8020677b52b5629d_Out_0 = _SpecularColor;
                    float _Property_1d077dd941fc4016a62636a6048577bc_Out_0 = _LightingCutoff;
                    float _Property_2a13ac2eb2084e0f912c6485bff7e1fb_Out_0 = _FalloffAmount;
                    float _Add_aee813a1674a41449133aac98f918ac9_Out_2;
                    Unity_Add_float(_Property_1d077dd941fc4016a62636a6048577bc_Out_0, _Property_2a13ac2eb2084e0f912c6485bff7e1fb_Out_0, _Add_aee813a1674a41449133aac98f918ac9_Out_2);
                    Bindings_GetMainLight_d6b14a2e8b6f3554b8459648535f697e _GetMainLight_5a267f1983eb45038dd25d47096b3576;
                    float3 _GetMainLight_5a267f1983eb45038dd25d47096b3576_Direction_0;
                    float3 _GetMainLight_5a267f1983eb45038dd25d47096b3576_Color_1;
                    float _GetMainLight_5a267f1983eb45038dd25d47096b3576_Attenuation_2;
                    SG_GetMainLight_d6b14a2e8b6f3554b8459648535f697e(IN.WorldSpacePosition, _GetMainLight_5a267f1983eb45038dd25d47096b3576, _GetMainLight_5a267f1983eb45038dd25d47096b3576_Direction_0, _GetMainLight_5a267f1983eb45038dd25d47096b3576_Color_1, _GetMainLight_5a267f1983eb45038dd25d47096b3576_Attenuation_2);
                    float3 _Add_cdec837b18d14622929b74d779f9ed53_Out_2;
                    Unity_Add_float3(IN.WorldSpaceViewDirection, _GetMainLight_5a267f1983eb45038dd25d47096b3576_Direction_0, _Add_cdec837b18d14622929b74d779f9ed53_Out_2);
                    float3 _Normalize_4ed8697fa3534c40a04c3b38c2f39118_Out_1;
                    Unity_Normalize_float3(_Add_cdec837b18d14622929b74d779f9ed53_Out_2, _Normalize_4ed8697fa3534c40a04c3b38c2f39118_Out_1);
                    float _DotProduct_2a86b7ba7a4e47c1b993a25eea174112_Out_2;
                    Unity_DotProduct_float3(IN.WorldSpaceNormal, _Normalize_4ed8697fa3534c40a04c3b38c2f39118_Out_1, _DotProduct_2a86b7ba7a4e47c1b993a25eea174112_Out_2);
                    float _Saturate_5954bbc00cbe4ab1aaece8a4042a2ae1_Out_1;
                    Unity_Saturate_float(_DotProduct_2a86b7ba7a4e47c1b993a25eea174112_Out_2, _Saturate_5954bbc00cbe4ab1aaece8a4042a2ae1_Out_1);
                    float _Property_09addda5751f4ae38ffd75d2cf5042be_Out_0 = _Smoothness;
                    float _Power_d01facce68d2456bb5459bf9144d966c_Out_2;
                    Unity_Power_float(_Saturate_5954bbc00cbe4ab1aaece8a4042a2ae1_Out_1, _Property_09addda5751f4ae38ffd75d2cf5042be_Out_0, _Power_d01facce68d2456bb5459bf9144d966c_Out_2);
                    float3 _Multiply_37f25c3b613140a98d39720af3f46c04_Out_2;
                    Unity_Multiply_float((_Power_d01facce68d2456bb5459bf9144d966c_Out_2.xxx), _GetMainLight_5a267f1983eb45038dd25d47096b3576_Color_1, _Multiply_37f25c3b613140a98d39720af3f46c04_Out_2);
                    float3 _Multiply_40d12c060eda4e9293ea46113abcac99_Out_2;
                    Unity_Multiply_float(_Multiply_37f25c3b613140a98d39720af3f46c04_Out_2, (_GetMainLight_5a267f1983eb45038dd25d47096b3576_Attenuation_2.xxx), _Multiply_40d12c060eda4e9293ea46113abcac99_Out_2);
                    float3 _Multiply_20c6e31cff10450ab4a4e6910c501dff_Out_2;
                    Unity_Multiply_float(_Multiply_40d12c060eda4e9293ea46113abcac99_Out_2, _Saturate_fdaf2acf4b0d40b3ae196b038de92740_Out_1, _Multiply_20c6e31cff10450ab4a4e6910c501dff_Out_2);
                    Bindings_CalcAdditionalSpecular_d84098efe9b2b6043a74a1631b825314 _CalcAdditionalSpecular_cd3669952dc74dfe8fc61749791c4fda;
                    _CalcAdditionalSpecular_cd3669952dc74dfe8fc61749791c4fda.WorldSpaceNormal = IN.WorldSpaceNormal;
                    _CalcAdditionalSpecular_cd3669952dc74dfe8fc61749791c4fda.WorldSpaceViewDirection = IN.WorldSpaceViewDirection;
                    _CalcAdditionalSpecular_cd3669952dc74dfe8fc61749791c4fda.WorldSpacePosition = IN.WorldSpacePosition;
                    float3 _CalcAdditionalSpecular_cd3669952dc74dfe8fc61749791c4fda_Diffuse_1;
                    SG_CalcAdditionalSpecular_d84098efe9b2b6043a74a1631b825314(_Property_09addda5751f4ae38ffd75d2cf5042be_Out_0, _CalcAdditionalSpecular_cd3669952dc74dfe8fc61749791c4fda, _CalcAdditionalSpecular_cd3669952dc74dfe8fc61749791c4fda_Diffuse_1);
                    float3 _Add_6cdd48355c7448bbbc9dc34639d2f16d_Out_2;
                    Unity_Add_float3(_Multiply_20c6e31cff10450ab4a4e6910c501dff_Out_2, _CalcAdditionalSpecular_cd3669952dc74dfe8fc61749791c4fda_Diffuse_1, _Add_6cdd48355c7448bbbc9dc34639d2f16d_Out_2);
                    float3 _Smoothstep_46bf89c479e64da1a8083fa09e5d323d_Out_3;
                    Unity_Smoothstep_float3((_Property_1d077dd941fc4016a62636a6048577bc_Out_0.xxx), (_Add_aee813a1674a41449133aac98f918ac9_Out_2.xxx), _Add_6cdd48355c7448bbbc9dc34639d2f16d_Out_2, _Smoothstep_46bf89c479e64da1a8083fa09e5d323d_Out_3);
                    float3 _Multiply_fb48a1d2f9404211ad52dd2f26a46f28_Out_2;
                    Unity_Multiply_float((_Property_0d605fca5a9b4f2e8020677b52b5629d_Out_0.xyz), _Smoothstep_46bf89c479e64da1a8083fa09e5d323d_Out_3, _Multiply_fb48a1d2f9404211ad52dd2f26a46f28_Out_2);
                    float4 _Property_5bce803f7b1342118efa64dfd7a5c5af_Out_0 = _DiffuseColor;
                    float _Property_5b63eda1ad9a4c349b54058af0283a6a_Out_0 = _LightingCutoff;
                    float _Property_6b8c43c8c4e04f089b490e01842c10e7_Out_0 = _FalloffAmount;
                    float _Add_f9f052f699b24c22a7e6ed992dbded4d_Out_2;
                    Unity_Add_float(_Property_5b63eda1ad9a4c349b54058af0283a6a_Out_0, _Property_6b8c43c8c4e04f089b490e01842c10e7_Out_0, _Add_f9f052f699b24c22a7e6ed992dbded4d_Out_2);
                    float3 _Smoothstep_6421ae70d4a0477a913d197174717db2_Out_3;
                    Unity_Smoothstep_float3((_Property_5b63eda1ad9a4c349b54058af0283a6a_Out_0.xxx), (_Add_f9f052f699b24c22a7e6ed992dbded4d_Out_2.xxx), _Add_0f6ab824bf464526bbf3116b8d1e102f_Out_2, _Smoothstep_6421ae70d4a0477a913d197174717db2_Out_3);
                    float _Property_68149cd9c2eb40a79d0105acc016d1c4_Out_0 = _AmbientStrength;
                    float3 _Maximum_c73c7cbcf6c4463a865782d13a0c4101_Out_2;
                    Unity_Maximum_float3(_Smoothstep_6421ae70d4a0477a913d197174717db2_Out_3, (_Property_68149cd9c2eb40a79d0105acc016d1c4_Out_0.xxx), _Maximum_c73c7cbcf6c4463a865782d13a0c4101_Out_2);
                    float3 _Multiply_d622b247c4a84f8bbebf6a902f0b0fcb_Out_2;
                    Unity_Multiply_float((_Property_5bce803f7b1342118efa64dfd7a5c5af_Out_0.xyz), _Maximum_c73c7cbcf6c4463a865782d13a0c4101_Out_2, _Multiply_d622b247c4a84f8bbebf6a902f0b0fcb_Out_2);
                    UnityTexture2D _Property_a111b087fff64719b899025161b92d31_Out_0 = UnityBuildTexture2DStructNoScale(_MainTex);
                    float4 _SampleTexture2D_68405c1067a64b7f874afd25ede0e0c8_RGBA_0 = SAMPLE_TEXTURE2D(_Property_a111b087fff64719b899025161b92d31_Out_0.tex, _Property_a111b087fff64719b899025161b92d31_Out_0.samplerstate, IN.uv0.xy);
                    float _SampleTexture2D_68405c1067a64b7f874afd25ede0e0c8_R_4 = _SampleTexture2D_68405c1067a64b7f874afd25ede0e0c8_RGBA_0.r;
                    float _SampleTexture2D_68405c1067a64b7f874afd25ede0e0c8_G_5 = _SampleTexture2D_68405c1067a64b7f874afd25ede0e0c8_RGBA_0.g;
                    float _SampleTexture2D_68405c1067a64b7f874afd25ede0e0c8_B_6 = _SampleTexture2D_68405c1067a64b7f874afd25ede0e0c8_RGBA_0.b;
                    float _SampleTexture2D_68405c1067a64b7f874afd25ede0e0c8_A_7 = _SampleTexture2D_68405c1067a64b7f874afd25ede0e0c8_RGBA_0.a;
                    float3 _Multiply_8ac74964cd004464a81865818d5afcc4_Out_2;
                    Unity_Multiply_float(_Multiply_d622b247c4a84f8bbebf6a902f0b0fcb_Out_2, (_SampleTexture2D_68405c1067a64b7f874afd25ede0e0c8_RGBA_0.xyz), _Multiply_8ac74964cd004464a81865818d5afcc4_Out_2);
                    float3 _Add_2ebf33fa6b00434db9194d0243d86458_Out_2;
                    Unity_Add_float3(_Multiply_fb48a1d2f9404211ad52dd2f26a46f28_Out_2, _Multiply_8ac74964cd004464a81865818d5afcc4_Out_2, _Add_2ebf33fa6b00434db9194d0243d86458_Out_2);
                    float3 _Add_5db2a9e6feef42bc9e81d7017a4e1bd8_Out_2;
                    Unity_Add_float3(_Multiply_08e1c96546e24df2920fcd26690a7402_Out_2, _Add_2ebf33fa6b00434db9194d0243d86458_Out_2, _Add_5db2a9e6feef42bc9e81d7017a4e1bd8_Out_2);
                    surface.BaseColor = IsGammaSpace() ? float3(0, 0, 0) : SRGBToLinear(float3(0, 0, 0));
                    surface.NormalTS = IN.TangentSpaceNormal;
                    surface.Emission = _Add_5db2a9e6feef42bc9e81d7017a4e1bd8_Out_2;
                    surface.Metallic = 0;
                    surface.Smoothness = 0;
                    surface.Occlusion = 1;
                    return surface;
                }
    
                // --------------------------------------------------
                // Build Graph Inputs
    
                VertexDescriptionInputs BuildVertexDescriptionInputs(Attributes input)
                {
                    VertexDescriptionInputs output;
                    ZERO_INITIALIZE(VertexDescriptionInputs, output);
                
                    output.ObjectSpaceNormal =           input.normalOS;
                    output.ObjectSpaceTangent =          input.tangentOS.xyz;
                    output.ObjectSpacePosition =         input.positionOS;
                
                    return output;
                }
                
                SurfaceDescriptionInputs BuildSurfaceDescriptionInputs(Varyings input)
                {
                    SurfaceDescriptionInputs output;
                    ZERO_INITIALIZE(SurfaceDescriptionInputs, output);
                
                	// must use interpolated tangent, bitangent and normal before they are normalized in the pixel shader.
                	float3 unnormalizedNormalWS = input.normalWS;
                    const float renormFactor = 1.0 / length(unnormalizedNormalWS);
                
                
                    output.WorldSpaceNormal =            renormFactor*input.normalWS.xyz;		// we want a unit length Normal Vector node in shader graph
                    output.TangentSpaceNormal =          float3(0.0f, 0.0f, 1.0f);
                
                
                    output.WorldSpaceViewDirection =     input.viewDirectionWS; //TODO: by default normalized in HD, but not in universal
                    output.WorldSpacePosition =          input.positionWS;
                    output.uv0 =                         input.texCoord0;
                #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
                #define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN output.FaceSign =                    IS_FRONT_VFACE(input.cullFace, true, false);
                #else
                #define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN
                #endif
                #undef BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN
                
                    return output;
                }
                
    
                // --------------------------------------------------
                // Main
    
                #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/ShaderPass.hlsl"
                #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/Varyings.hlsl"
                #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/PBRForwardPass.hlsl"
    
                ENDHLSL
            }
            Pass
            {
                Name "ShadowCaster"
                Tags
                {
                    "LightMode" = "ShadowCaster"
                }
    
                // Render State
                Cull Back
                Blend One Zero
                ZTest LEqual
                ZWrite On
                ColorMask 0
    
                // Debug
                // <None>
    
                // --------------------------------------------------
                // Pass
    
                HLSLPROGRAM
    
                // Pragmas
                #pragma target 2.0
                #pragma only_renderers gles gles3 glcore d3d11
                #pragma multi_compile_instancing
                #pragma vertex vert
                #pragma fragment frag
    
                // DotsInstancingOptions: <None>
                // HybridV1InjectedBuiltinProperties: <None>
    
                // Keywords
                // PassKeywords: <None>
                // GraphKeywords: <None>
    
                // Defines
                #define _NORMALMAP 1
                #define _NORMAL_DROPOFF_TS 1
                #define ATTRIBUTES_NEED_NORMAL
                #define ATTRIBUTES_NEED_TANGENT
                #define FEATURES_GRAPH_VERTEX
                /* WARNING: $splice Could not find named fragment 'PassInstancing' */
                #define SHADERPASS SHADERPASS_SHADOWCASTER
                /* WARNING: $splice Could not find named fragment 'DotsInstancingVars' */
    
                // Includes
                #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
                #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Texture.hlsl"
                #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
                #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
                #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/TextureStack.hlsl"
                #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"
    
                // --------------------------------------------------
                // Structs and Packing
    
                struct Attributes
                {
                    float3 positionOS : POSITION;
                    float3 normalOS : NORMAL;
                    float4 tangentOS : TANGENT;
                    #if UNITY_ANY_INSTANCING_ENABLED
                    uint instanceID : INSTANCEID_SEMANTIC;
                    #endif
                };
                struct Varyings
                {
                    float4 positionCS : SV_POSITION;
                    #if UNITY_ANY_INSTANCING_ENABLED
                    uint instanceID : CUSTOM_INSTANCE_ID;
                    #endif
                    #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
                    uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
                    #endif
                    #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
                    uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
                    #endif
                    #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
                    FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
                    #endif
                };
                struct SurfaceDescriptionInputs
                {
                };
                struct VertexDescriptionInputs
                {
                    float3 ObjectSpaceNormal;
                    float3 ObjectSpaceTangent;
                    float3 ObjectSpacePosition;
                };
                struct PackedVaryings
                {
                    float4 positionCS : SV_POSITION;
                    #if UNITY_ANY_INSTANCING_ENABLED
                    uint instanceID : CUSTOM_INSTANCE_ID;
                    #endif
                    #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
                    uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
                    #endif
                    #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
                    uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
                    #endif
                    #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
                    FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
                    #endif
                };
    
                PackedVaryings PackVaryings (Varyings input)
                {
                    PackedVaryings output;
                    output.positionCS = input.positionCS;
                    #if UNITY_ANY_INSTANCING_ENABLED
                    output.instanceID = input.instanceID;
                    #endif
                    #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
                    output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
                    #endif
                    #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
                    output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
                    #endif
                    #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
                    output.cullFace = input.cullFace;
                    #endif
                    return output;
                }
                Varyings UnpackVaryings (PackedVaryings input)
                {
                    Varyings output;
                    output.positionCS = input.positionCS;
                    #if UNITY_ANY_INSTANCING_ENABLED
                    output.instanceID = input.instanceID;
                    #endif
                    #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
                    output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
                    #endif
                    #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
                    output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
                    #endif
                    #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
                    output.cullFace = input.cullFace;
                    #endif
                    return output;
                }
    
                // --------------------------------------------------
                // Graph
    
                // Graph Properties
                CBUFFER_START(UnityPerMaterial)
                float _AmbientStrength;
                float4 _DiffuseColor;
                float4 _MainTex_TexelSize;
                float4 _SpecularColor;
                float4 _FresnelColor;
                float _Smoothness;
                float _FresnelSize;
                float _LightingCutoff;
                float _FalloffAmount;
                CBUFFER_END
                
                // Object and Global properties
                SAMPLER(SamplerState_Linear_Repeat);
                TEXTURE2D(_MainTex);
                SAMPLER(sampler_MainTex);
    
                // Graph Functions
                // GraphFunctions: <None>
    
                // Graph Vertex
                struct VertexDescription
                {
                    float3 Position;
                    float3 Normal;
                    float3 Tangent;
                };
                
                VertexDescription VertexDescriptionFunction(VertexDescriptionInputs IN)
                {
                    VertexDescription description = (VertexDescription)0;
                    description.Position = IN.ObjectSpacePosition;
                    description.Normal = IN.ObjectSpaceNormal;
                    description.Tangent = IN.ObjectSpaceTangent;
                    return description;
                }
    
                // Graph Pixel
                struct SurfaceDescription
                {
                };
                
                SurfaceDescription SurfaceDescriptionFunction(SurfaceDescriptionInputs IN)
                {
                    SurfaceDescription surface = (SurfaceDescription)0;
                    return surface;
                }
    
                // --------------------------------------------------
                // Build Graph Inputs
    
                VertexDescriptionInputs BuildVertexDescriptionInputs(Attributes input)
                {
                    VertexDescriptionInputs output;
                    ZERO_INITIALIZE(VertexDescriptionInputs, output);
                
                    output.ObjectSpaceNormal =           input.normalOS;
                    output.ObjectSpaceTangent =          input.tangentOS.xyz;
                    output.ObjectSpacePosition =         input.positionOS;
                
                    return output;
                }
                
                SurfaceDescriptionInputs BuildSurfaceDescriptionInputs(Varyings input)
                {
                    SurfaceDescriptionInputs output;
                    ZERO_INITIALIZE(SurfaceDescriptionInputs, output);
                
                
                
                
                
                #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
                #define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN output.FaceSign =                    IS_FRONT_VFACE(input.cullFace, true, false);
                #else
                #define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN
                #endif
                #undef BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN
                
                    return output;
                }
                
    
                // --------------------------------------------------
                // Main
    
                #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/ShaderPass.hlsl"
                #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/Varyings.hlsl"
                #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/ShadowCasterPass.hlsl"
    
                ENDHLSL
            }
            Pass
            {
                Name "DepthOnly"
                Tags
                {
                    "LightMode" = "DepthOnly"
                }
    
                // Render State
                Cull Back
                Blend One Zero
                ZTest LEqual
                ZWrite On
                ColorMask 0
    
                // Debug
                // <None>
    
                // --------------------------------------------------
                // Pass
    
                HLSLPROGRAM
    
                // Pragmas
                #pragma target 2.0
                #pragma only_renderers gles gles3 glcore d3d11
                #pragma multi_compile_instancing
                #pragma vertex vert
                #pragma fragment frag
    
                // DotsInstancingOptions: <None>
                // HybridV1InjectedBuiltinProperties: <None>
    
                // Keywords
                // PassKeywords: <None>
                // GraphKeywords: <None>
    
                // Defines
                #define _NORMALMAP 1
                #define _NORMAL_DROPOFF_TS 1
                #define ATTRIBUTES_NEED_NORMAL
                #define ATTRIBUTES_NEED_TANGENT
                #define FEATURES_GRAPH_VERTEX
                /* WARNING: $splice Could not find named fragment 'PassInstancing' */
                #define SHADERPASS SHADERPASS_DEPTHONLY
                /* WARNING: $splice Could not find named fragment 'DotsInstancingVars' */
    
                // Includes
                #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
                #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Texture.hlsl"
                #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
                #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
                #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/TextureStack.hlsl"
                #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"
    
                // --------------------------------------------------
                // Structs and Packing
    
                struct Attributes
                {
                    float3 positionOS : POSITION;
                    float3 normalOS : NORMAL;
                    float4 tangentOS : TANGENT;
                    #if UNITY_ANY_INSTANCING_ENABLED
                    uint instanceID : INSTANCEID_SEMANTIC;
                    #endif
                };
                struct Varyings
                {
                    float4 positionCS : SV_POSITION;
                    #if UNITY_ANY_INSTANCING_ENABLED
                    uint instanceID : CUSTOM_INSTANCE_ID;
                    #endif
                    #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
                    uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
                    #endif
                    #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
                    uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
                    #endif
                    #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
                    FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
                    #endif
                };
                struct SurfaceDescriptionInputs
                {
                };
                struct VertexDescriptionInputs
                {
                    float3 ObjectSpaceNormal;
                    float3 ObjectSpaceTangent;
                    float3 ObjectSpacePosition;
                };
                struct PackedVaryings
                {
                    float4 positionCS : SV_POSITION;
                    #if UNITY_ANY_INSTANCING_ENABLED
                    uint instanceID : CUSTOM_INSTANCE_ID;
                    #endif
                    #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
                    uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
                    #endif
                    #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
                    uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
                    #endif
                    #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
                    FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
                    #endif
                };
    
                PackedVaryings PackVaryings (Varyings input)
                {
                    PackedVaryings output;
                    output.positionCS = input.positionCS;
                    #if UNITY_ANY_INSTANCING_ENABLED
                    output.instanceID = input.instanceID;
                    #endif
                    #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
                    output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
                    #endif
                    #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
                    output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
                    #endif
                    #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
                    output.cullFace = input.cullFace;
                    #endif
                    return output;
                }
                Varyings UnpackVaryings (PackedVaryings input)
                {
                    Varyings output;
                    output.positionCS = input.positionCS;
                    #if UNITY_ANY_INSTANCING_ENABLED
                    output.instanceID = input.instanceID;
                    #endif
                    #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
                    output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
                    #endif
                    #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
                    output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
                    #endif
                    #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
                    output.cullFace = input.cullFace;
                    #endif
                    return output;
                }
    
                // --------------------------------------------------
                // Graph
    
                // Graph Properties
                CBUFFER_START(UnityPerMaterial)
                float _AmbientStrength;
                float4 _DiffuseColor;
                float4 _MainTex_TexelSize;
                float4 _SpecularColor;
                float4 _FresnelColor;
                float _Smoothness;
                float _FresnelSize;
                float _LightingCutoff;
                float _FalloffAmount;
                CBUFFER_END
                
                // Object and Global properties
                SAMPLER(SamplerState_Linear_Repeat);
                TEXTURE2D(_MainTex);
                SAMPLER(sampler_MainTex);
    
                // Graph Functions
                // GraphFunctions: <None>
    
                // Graph Vertex
                struct VertexDescription
                {
                    float3 Position;
                    float3 Normal;
                    float3 Tangent;
                };
                
                VertexDescription VertexDescriptionFunction(VertexDescriptionInputs IN)
                {
                    VertexDescription description = (VertexDescription)0;
                    description.Position = IN.ObjectSpacePosition;
                    description.Normal = IN.ObjectSpaceNormal;
                    description.Tangent = IN.ObjectSpaceTangent;
                    return description;
                }
    
                // Graph Pixel
                struct SurfaceDescription
                {
                };
                
                SurfaceDescription SurfaceDescriptionFunction(SurfaceDescriptionInputs IN)
                {
                    SurfaceDescription surface = (SurfaceDescription)0;
                    return surface;
                }
    
                // --------------------------------------------------
                // Build Graph Inputs
    
                VertexDescriptionInputs BuildVertexDescriptionInputs(Attributes input)
                {
                    VertexDescriptionInputs output;
                    ZERO_INITIALIZE(VertexDescriptionInputs, output);
                
                    output.ObjectSpaceNormal =           input.normalOS;
                    output.ObjectSpaceTangent =          input.tangentOS.xyz;
                    output.ObjectSpacePosition =         input.positionOS;
                
                    return output;
                }
                
                SurfaceDescriptionInputs BuildSurfaceDescriptionInputs(Varyings input)
                {
                    SurfaceDescriptionInputs output;
                    ZERO_INITIALIZE(SurfaceDescriptionInputs, output);
                
                
                
                
                
                #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
                #define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN output.FaceSign =                    IS_FRONT_VFACE(input.cullFace, true, false);
                #else
                #define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN
                #endif
                #undef BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN
                
                    return output;
                }
                
    
                // --------------------------------------------------
                // Main
    
                #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/ShaderPass.hlsl"
                #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/Varyings.hlsl"
                #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/DepthOnlyPass.hlsl"
    
                ENDHLSL
            }
            Pass
            {
                Name "DepthNormals"
                Tags
                {
                    "LightMode" = "DepthNormals"
                }
    
                // Render State
                Cull Back
                Blend One Zero
                ZTest LEqual
                ZWrite On
    
                // Debug
                // <None>
    
                // --------------------------------------------------
                // Pass
    
                HLSLPROGRAM
    
                // Pragmas
                #pragma target 2.0
                #pragma only_renderers gles gles3 glcore d3d11
                #pragma multi_compile_instancing
                #pragma vertex vert
                #pragma fragment frag
    
                // DotsInstancingOptions: <None>
                // HybridV1InjectedBuiltinProperties: <None>
    
                // Keywords
                // PassKeywords: <None>
                // GraphKeywords: <None>
    
                // Defines
                #define _NORMALMAP 1
                #define _NORMAL_DROPOFF_TS 1
                #define ATTRIBUTES_NEED_NORMAL
                #define ATTRIBUTES_NEED_TANGENT
                #define ATTRIBUTES_NEED_TEXCOORD1
                #define VARYINGS_NEED_NORMAL_WS
                #define VARYINGS_NEED_TANGENT_WS
                #define FEATURES_GRAPH_VERTEX
                /* WARNING: $splice Could not find named fragment 'PassInstancing' */
                #define SHADERPASS SHADERPASS_DEPTHNORMALSONLY
                /* WARNING: $splice Could not find named fragment 'DotsInstancingVars' */
    
                // Includes
                #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
                #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Texture.hlsl"
                #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
                #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
                #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/TextureStack.hlsl"
                #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"
    
                // --------------------------------------------------
                // Structs and Packing
    
                struct Attributes
                {
                    float3 positionOS : POSITION;
                    float3 normalOS : NORMAL;
                    float4 tangentOS : TANGENT;
                    float4 uv1 : TEXCOORD1;
                    #if UNITY_ANY_INSTANCING_ENABLED
                    uint instanceID : INSTANCEID_SEMANTIC;
                    #endif
                };
                struct Varyings
                {
                    float4 positionCS : SV_POSITION;
                    float3 normalWS;
                    float4 tangentWS;
                    #if UNITY_ANY_INSTANCING_ENABLED
                    uint instanceID : CUSTOM_INSTANCE_ID;
                    #endif
                    #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
                    uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
                    #endif
                    #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
                    uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
                    #endif
                    #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
                    FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
                    #endif
                };
                struct SurfaceDescriptionInputs
                {
                    float3 TangentSpaceNormal;
                };
                struct VertexDescriptionInputs
                {
                    float3 ObjectSpaceNormal;
                    float3 ObjectSpaceTangent;
                    float3 ObjectSpacePosition;
                };
                struct PackedVaryings
                {
                    float4 positionCS : SV_POSITION;
                    float3 interp0 : TEXCOORD0;
                    float4 interp1 : TEXCOORD1;
                    #if UNITY_ANY_INSTANCING_ENABLED
                    uint instanceID : CUSTOM_INSTANCE_ID;
                    #endif
                    #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
                    uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
                    #endif
                    #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
                    uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
                    #endif
                    #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
                    FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
                    #endif
                };
    
                PackedVaryings PackVaryings (Varyings input)
                {
                    PackedVaryings output;
                    output.positionCS = input.positionCS;
                    output.interp0.xyz =  input.normalWS;
                    output.interp1.xyzw =  input.tangentWS;
                    #if UNITY_ANY_INSTANCING_ENABLED
                    output.instanceID = input.instanceID;
                    #endif
                    #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
                    output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
                    #endif
                    #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
                    output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
                    #endif
                    #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
                    output.cullFace = input.cullFace;
                    #endif
                    return output;
                }
                Varyings UnpackVaryings (PackedVaryings input)
                {
                    Varyings output;
                    output.positionCS = input.positionCS;
                    output.normalWS = input.interp0.xyz;
                    output.tangentWS = input.interp1.xyzw;
                    #if UNITY_ANY_INSTANCING_ENABLED
                    output.instanceID = input.instanceID;
                    #endif
                    #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
                    output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
                    #endif
                    #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
                    output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
                    #endif
                    #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
                    output.cullFace = input.cullFace;
                    #endif
                    return output;
                }
    
                // --------------------------------------------------
                // Graph
    
                // Graph Properties
                CBUFFER_START(UnityPerMaterial)
                float _AmbientStrength;
                float4 _DiffuseColor;
                float4 _MainTex_TexelSize;
                float4 _SpecularColor;
                float4 _FresnelColor;
                float _Smoothness;
                float _FresnelSize;
                float _LightingCutoff;
                float _FalloffAmount;
                CBUFFER_END
                
                // Object and Global properties
                SAMPLER(SamplerState_Linear_Repeat);
                TEXTURE2D(_MainTex);
                SAMPLER(sampler_MainTex);
    
                // Graph Functions
                // GraphFunctions: <None>
    
                // Graph Vertex
                struct VertexDescription
                {
                    float3 Position;
                    float3 Normal;
                    float3 Tangent;
                };
                
                VertexDescription VertexDescriptionFunction(VertexDescriptionInputs IN)
                {
                    VertexDescription description = (VertexDescription)0;
                    description.Position = IN.ObjectSpacePosition;
                    description.Normal = IN.ObjectSpaceNormal;
                    description.Tangent = IN.ObjectSpaceTangent;
                    return description;
                }
    
                // Graph Pixel
                struct SurfaceDescription
                {
                    float3 NormalTS;
                };
                
                SurfaceDescription SurfaceDescriptionFunction(SurfaceDescriptionInputs IN)
                {
                    SurfaceDescription surface = (SurfaceDescription)0;
                    surface.NormalTS = IN.TangentSpaceNormal;
                    return surface;
                }
    
                // --------------------------------------------------
                // Build Graph Inputs
    
                VertexDescriptionInputs BuildVertexDescriptionInputs(Attributes input)
                {
                    VertexDescriptionInputs output;
                    ZERO_INITIALIZE(VertexDescriptionInputs, output);
                
                    output.ObjectSpaceNormal =           input.normalOS;
                    output.ObjectSpaceTangent =          input.tangentOS.xyz;
                    output.ObjectSpacePosition =         input.positionOS;
                
                    return output;
                }
                
                SurfaceDescriptionInputs BuildSurfaceDescriptionInputs(Varyings input)
                {
                    SurfaceDescriptionInputs output;
                    ZERO_INITIALIZE(SurfaceDescriptionInputs, output);
                
                
                
                    output.TangentSpaceNormal =          float3(0.0f, 0.0f, 1.0f);
                
                
                #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
                #define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN output.FaceSign =                    IS_FRONT_VFACE(input.cullFace, true, false);
                #else
                #define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN
                #endif
                #undef BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN
                
                    return output;
                }
                
    
                // --------------------------------------------------
                // Main
    
                #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/ShaderPass.hlsl"
                #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/Varyings.hlsl"
                #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/DepthNormalsOnlyPass.hlsl"
    
                ENDHLSL
            }
            Pass
            {
                Name "Meta"
                Tags
                {
                    "LightMode" = "Meta"
                }
    
                // Render State
                Cull Off
    
                // Debug
                // <None>
    
                // --------------------------------------------------
                // Pass
    
                HLSLPROGRAM
    
                // Pragmas
                #pragma target 2.0
                #pragma only_renderers gles gles3 glcore d3d11
                #pragma vertex vert
                #pragma fragment frag
    
                // DotsInstancingOptions: <None>
                // HybridV1InjectedBuiltinProperties: <None>
    
                // Keywords
                #pragma shader_feature _ _SMOOTHNESS_TEXTURE_ALBEDO_CHANNEL_A
                // GraphKeywords: <None>
    
                // Defines
                #define _NORMALMAP 1
                #define _NORMAL_DROPOFF_TS 1
                #define ATTRIBUTES_NEED_NORMAL
                #define ATTRIBUTES_NEED_TANGENT
                #define ATTRIBUTES_NEED_TEXCOORD0
                #define ATTRIBUTES_NEED_TEXCOORD1
                #define ATTRIBUTES_NEED_TEXCOORD2
                #define VARYINGS_NEED_POSITION_WS
                #define VARYINGS_NEED_NORMAL_WS
                #define VARYINGS_NEED_TEXCOORD0
                #define VARYINGS_NEED_VIEWDIRECTION_WS
                #define FEATURES_GRAPH_VERTEX
                /* WARNING: $splice Could not find named fragment 'PassInstancing' */
                #define SHADERPASS SHADERPASS_META
                /* WARNING: $splice Could not find named fragment 'DotsInstancingVars' */
    
                // Includes
                #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
                #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Texture.hlsl"
                #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
                #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
                #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/TextureStack.hlsl"
                #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"
                #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/MetaInput.hlsl"
    
                // --------------------------------------------------
                // Structs and Packing
    
                struct Attributes
                {
                    float3 positionOS : POSITION;
                    float3 normalOS : NORMAL;
                    float4 tangentOS : TANGENT;
                    float4 uv0 : TEXCOORD0;
                    float4 uv1 : TEXCOORD1;
                    float4 uv2 : TEXCOORD2;
                    #if UNITY_ANY_INSTANCING_ENABLED
                    uint instanceID : INSTANCEID_SEMANTIC;
                    #endif
                };
                struct Varyings
                {
                    float4 positionCS : SV_POSITION;
                    float3 positionWS;
                    float3 normalWS;
                    float4 texCoord0;
                    float3 viewDirectionWS;
                    #if UNITY_ANY_INSTANCING_ENABLED
                    uint instanceID : CUSTOM_INSTANCE_ID;
                    #endif
                    #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
                    uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
                    #endif
                    #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
                    uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
                    #endif
                    #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
                    FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
                    #endif
                };
                struct SurfaceDescriptionInputs
                {
                    float3 WorldSpaceNormal;
                    float3 WorldSpaceViewDirection;
                    float3 WorldSpacePosition;
                    float4 uv0;
                };
                struct VertexDescriptionInputs
                {
                    float3 ObjectSpaceNormal;
                    float3 ObjectSpaceTangent;
                    float3 ObjectSpacePosition;
                };
                struct PackedVaryings
                {
                    float4 positionCS : SV_POSITION;
                    float3 interp0 : TEXCOORD0;
                    float3 interp1 : TEXCOORD1;
                    float4 interp2 : TEXCOORD2;
                    float3 interp3 : TEXCOORD3;
                    #if UNITY_ANY_INSTANCING_ENABLED
                    uint instanceID : CUSTOM_INSTANCE_ID;
                    #endif
                    #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
                    uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
                    #endif
                    #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
                    uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
                    #endif
                    #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
                    FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
                    #endif
                };
    
                PackedVaryings PackVaryings (Varyings input)
                {
                    PackedVaryings output;
                    output.positionCS = input.positionCS;
                    output.interp0.xyz =  input.positionWS;
                    output.interp1.xyz =  input.normalWS;
                    output.interp2.xyzw =  input.texCoord0;
                    output.interp3.xyz =  input.viewDirectionWS;
                    #if UNITY_ANY_INSTANCING_ENABLED
                    output.instanceID = input.instanceID;
                    #endif
                    #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
                    output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
                    #endif
                    #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
                    output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
                    #endif
                    #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
                    output.cullFace = input.cullFace;
                    #endif
                    return output;
                }
                Varyings UnpackVaryings (PackedVaryings input)
                {
                    Varyings output;
                    output.positionCS = input.positionCS;
                    output.positionWS = input.interp0.xyz;
                    output.normalWS = input.interp1.xyz;
                    output.texCoord0 = input.interp2.xyzw;
                    output.viewDirectionWS = input.interp3.xyz;
                    #if UNITY_ANY_INSTANCING_ENABLED
                    output.instanceID = input.instanceID;
                    #endif
                    #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
                    output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
                    #endif
                    #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
                    output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
                    #endif
                    #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
                    output.cullFace = input.cullFace;
                    #endif
                    return output;
                }
    
                // --------------------------------------------------
                // Graph
    
                // Graph Properties
                CBUFFER_START(UnityPerMaterial)
                float _AmbientStrength;
                float4 _DiffuseColor;
                float4 _MainTex_TexelSize;
                float4 _SpecularColor;
                float4 _FresnelColor;
                float _Smoothness;
                float _FresnelSize;
                float _LightingCutoff;
                float _FalloffAmount;
                CBUFFER_END
                
                // Object and Global properties
                SAMPLER(SamplerState_Linear_Repeat);
                TEXTURE2D(_MainTex);
                SAMPLER(sampler_MainTex);
    
                // Graph Functions
                
                void Unity_Add_float(float A, float B, out float Out)
                {
                    Out = A + B;
                }
                
                void Unity_Reciprocal_float(float In, out float Out)
                {
                    Out = 1.0/In;
                }
                
                void Unity_FresnelEffect_float(float3 Normal, float3 ViewDir, float Power, out float Out)
                {
                    Out = pow((1.0 - saturate(dot(normalize(Normal), normalize(ViewDir)))), Power);
                }
                
                // a6264222ffebf7cfce349cb3e07ea356
                #include "./Lighting.hlsl"
                
                void Unity_Multiply_float(float A, float B, out float Out)
                {
                    Out = A * B;
                }
                
                struct Bindings_GetMainLight_d6b14a2e8b6f3554b8459648535f697e
                {
                };
                
                void SG_GetMainLight_d6b14a2e8b6f3554b8459648535f697e(float3 Vector3_b21c75b9b8514ef286d5e6dc199fa9af, Bindings_GetMainLight_d6b14a2e8b6f3554b8459648535f697e IN, out float3 Direction_0, out float3 Color_1, out float Attenuation_2)
                {
                    float3 _Property_923162a64885457196b5ccbf7a2aaac7_Out_0 = Vector3_b21c75b9b8514ef286d5e6dc199fa9af;
                    float3 _MainLightCustomFunction_93e39954c04146b5ae1be272ea9d714b_Direction_0;
                    float3 _MainLightCustomFunction_93e39954c04146b5ae1be272ea9d714b_Color_2;
                    float _MainLightCustomFunction_93e39954c04146b5ae1be272ea9d714b_DistanceAtten_3;
                    float _MainLightCustomFunction_93e39954c04146b5ae1be272ea9d714b_ShadowAtten_4;
                    MainLight_float(_Property_923162a64885457196b5ccbf7a2aaac7_Out_0, _MainLightCustomFunction_93e39954c04146b5ae1be272ea9d714b_Direction_0, _MainLightCustomFunction_93e39954c04146b5ae1be272ea9d714b_Color_2, _MainLightCustomFunction_93e39954c04146b5ae1be272ea9d714b_DistanceAtten_3, _MainLightCustomFunction_93e39954c04146b5ae1be272ea9d714b_ShadowAtten_4);
                    float _Multiply_6d878674c9b447478a9564442340c0a2_Out_2;
                    Unity_Multiply_float(_MainLightCustomFunction_93e39954c04146b5ae1be272ea9d714b_DistanceAtten_3, _MainLightCustomFunction_93e39954c04146b5ae1be272ea9d714b_ShadowAtten_4, _Multiply_6d878674c9b447478a9564442340c0a2_Out_2);
                    Direction_0 = _MainLightCustomFunction_93e39954c04146b5ae1be272ea9d714b_Direction_0;
                    Color_1 = _MainLightCustomFunction_93e39954c04146b5ae1be272ea9d714b_Color_2;
                    Attenuation_2 = _Multiply_6d878674c9b447478a9564442340c0a2_Out_2;
                }
                
                void Unity_DotProduct_float3(float3 A, float3 B, out float Out)
                {
                    Out = dot(A, B);
                }
                
                void Unity_Multiply_float(float3 A, float3 B, out float3 Out)
                {
                    Out = A * B;
                }
                
                void Unity_Saturate_float3(float3 In, out float3 Out)
                {
                    Out = saturate(In);
                }
                
                struct Bindings_GetAdditionalLight_b5516a5008f7d104abebe27210c42de8
                {
                };
                
                void SG_GetAdditionalLight_b5516a5008f7d104abebe27210c42de8(float3 Vector3_1e07dec0084a48e38c95166c3cdc688d, float Vector1_0ce9574e837f408991312a6c71473833, Bindings_GetAdditionalLight_b5516a5008f7d104abebe27210c42de8 IN, out float3 Direction_0, out float3 Color_1, out float Attenuation_2)
                {
                    float3 _Property_e9927ccc4a684aeabdaa70dbe76689f0_Out_0 = Vector3_1e07dec0084a48e38c95166c3cdc688d;
                    float _Property_c6fa454cb94449b6923e1c90fafaf929_Out_0 = Vector1_0ce9574e837f408991312a6c71473833;
                    float3 _AdditionalLightCustomFunction_c6ec52ed99634926b12dc96d48e96f1b_Direction_1;
                    float3 _AdditionalLightCustomFunction_c6ec52ed99634926b12dc96d48e96f1b_Color_2;
                    float _AdditionalLightCustomFunction_c6ec52ed99634926b12dc96d48e96f1b_DistanceAtten_3;
                    float _AdditionalLightCustomFunction_c6ec52ed99634926b12dc96d48e96f1b_ShadowAtten_4;
                    AdditionalLight_float(_Property_e9927ccc4a684aeabdaa70dbe76689f0_Out_0, _Property_c6fa454cb94449b6923e1c90fafaf929_Out_0, _AdditionalLightCustomFunction_c6ec52ed99634926b12dc96d48e96f1b_Direction_1, _AdditionalLightCustomFunction_c6ec52ed99634926b12dc96d48e96f1b_Color_2, _AdditionalLightCustomFunction_c6ec52ed99634926b12dc96d48e96f1b_DistanceAtten_3, _AdditionalLightCustomFunction_c6ec52ed99634926b12dc96d48e96f1b_ShadowAtten_4);
                    float _Multiply_0b8ec7bbb926441e8c14c7c32d369adf_Out_2;
                    Unity_Multiply_float(_AdditionalLightCustomFunction_c6ec52ed99634926b12dc96d48e96f1b_DistanceAtten_3, _AdditionalLightCustomFunction_c6ec52ed99634926b12dc96d48e96f1b_ShadowAtten_4, _Multiply_0b8ec7bbb926441e8c14c7c32d369adf_Out_2);
                    Direction_0 = _AdditionalLightCustomFunction_c6ec52ed99634926b12dc96d48e96f1b_Direction_1;
                    Color_1 = _AdditionalLightCustomFunction_c6ec52ed99634926b12dc96d48e96f1b_Color_2;
                    Attenuation_2 = _Multiply_0b8ec7bbb926441e8c14c7c32d369adf_Out_2;
                }
                
                void Unity_Saturate_float(float In, out float Out)
                {
                    Out = saturate(In);
                }
                
                void Unity_Add_float3(float3 A, float3 B, out float3 Out)
                {
                    Out = A + B;
                }
                
                struct Bindings_CalcAdditionalDiffuse_e85823578a3493d41ade631af12166aa
                {
                    float3 WorldSpaceNormal;
                    float3 WorldSpacePosition;
                };
                
                void SG_CalcAdditionalDiffuse_e85823578a3493d41ade631af12166aa(Bindings_CalcAdditionalDiffuse_e85823578a3493d41ade631af12166aa IN, out float3 Diffuse_1)
                {
                    Bindings_GetAdditionalLight_b5516a5008f7d104abebe27210c42de8 _GetAdditionalLight_e6c10dfa199649fca18a0cb673fcba44;
                    float3 _GetAdditionalLight_e6c10dfa199649fca18a0cb673fcba44_Direction_0;
                    float3 _GetAdditionalLight_e6c10dfa199649fca18a0cb673fcba44_Color_1;
                    float _GetAdditionalLight_e6c10dfa199649fca18a0cb673fcba44_Attenuation_2;
                    SG_GetAdditionalLight_b5516a5008f7d104abebe27210c42de8(IN.WorldSpacePosition, 0, _GetAdditionalLight_e6c10dfa199649fca18a0cb673fcba44, _GetAdditionalLight_e6c10dfa199649fca18a0cb673fcba44_Direction_0, _GetAdditionalLight_e6c10dfa199649fca18a0cb673fcba44_Color_1, _GetAdditionalLight_e6c10dfa199649fca18a0cb673fcba44_Attenuation_2);
                    float _DotProduct_aee5f4b498024e2da9796ed342f8a43a_Out_2;
                    Unity_DotProduct_float3(_GetAdditionalLight_e6c10dfa199649fca18a0cb673fcba44_Direction_0, IN.WorldSpaceNormal, _DotProduct_aee5f4b498024e2da9796ed342f8a43a_Out_2);
                    float _Saturate_2080d664f6004dc9ad574ba7e91917b2_Out_1;
                    Unity_Saturate_float(_DotProduct_aee5f4b498024e2da9796ed342f8a43a_Out_2, _Saturate_2080d664f6004dc9ad574ba7e91917b2_Out_1);
                    float3 _Multiply_57fcc7dc0fb845cf924c855eadbb7792_Out_2;
                    Unity_Multiply_float((_Saturate_2080d664f6004dc9ad574ba7e91917b2_Out_1.xxx), _GetAdditionalLight_e6c10dfa199649fca18a0cb673fcba44_Color_1, _Multiply_57fcc7dc0fb845cf924c855eadbb7792_Out_2);
                    float3 _Multiply_59016ca5433045d0a06ff03a13ec13b6_Out_2;
                    Unity_Multiply_float(_Multiply_57fcc7dc0fb845cf924c855eadbb7792_Out_2, (_GetAdditionalLight_e6c10dfa199649fca18a0cb673fcba44_Attenuation_2.xxx), _Multiply_59016ca5433045d0a06ff03a13ec13b6_Out_2);
                    Bindings_GetAdditionalLight_b5516a5008f7d104abebe27210c42de8 _GetAdditionalLight_a054a4cd5b484e1492208dc9ca4a85f5;
                    float3 _GetAdditionalLight_a054a4cd5b484e1492208dc9ca4a85f5_Direction_0;
                    float3 _GetAdditionalLight_a054a4cd5b484e1492208dc9ca4a85f5_Color_1;
                    float _GetAdditionalLight_a054a4cd5b484e1492208dc9ca4a85f5_Attenuation_2;
                    SG_GetAdditionalLight_b5516a5008f7d104abebe27210c42de8(IN.WorldSpacePosition, 1, _GetAdditionalLight_a054a4cd5b484e1492208dc9ca4a85f5, _GetAdditionalLight_a054a4cd5b484e1492208dc9ca4a85f5_Direction_0, _GetAdditionalLight_a054a4cd5b484e1492208dc9ca4a85f5_Color_1, _GetAdditionalLight_a054a4cd5b484e1492208dc9ca4a85f5_Attenuation_2);
                    float _DotProduct_00e581a08ce7465588597fd11859eea2_Out_2;
                    Unity_DotProduct_float3(_GetAdditionalLight_a054a4cd5b484e1492208dc9ca4a85f5_Direction_0, IN.WorldSpaceNormal, _DotProduct_00e581a08ce7465588597fd11859eea2_Out_2);
                    float _Saturate_58b5f4d3dcaf45e6bda212ef43edc4ea_Out_1;
                    Unity_Saturate_float(_DotProduct_00e581a08ce7465588597fd11859eea2_Out_2, _Saturate_58b5f4d3dcaf45e6bda212ef43edc4ea_Out_1);
                    float3 _Multiply_6ff1cb7ecc8542848d8d721f284a3b3c_Out_2;
                    Unity_Multiply_float((_Saturate_58b5f4d3dcaf45e6bda212ef43edc4ea_Out_1.xxx), _GetAdditionalLight_a054a4cd5b484e1492208dc9ca4a85f5_Color_1, _Multiply_6ff1cb7ecc8542848d8d721f284a3b3c_Out_2);
                    float3 _Multiply_8337e9ec92b74cefb421776f67b29661_Out_2;
                    Unity_Multiply_float(_Multiply_6ff1cb7ecc8542848d8d721f284a3b3c_Out_2, (_GetAdditionalLight_a054a4cd5b484e1492208dc9ca4a85f5_Attenuation_2.xxx), _Multiply_8337e9ec92b74cefb421776f67b29661_Out_2);
                    float3 _Add_8d5fe4674e364518a5d8f4559669df92_Out_2;
                    Unity_Add_float3(_Multiply_59016ca5433045d0a06ff03a13ec13b6_Out_2, _Multiply_8337e9ec92b74cefb421776f67b29661_Out_2, _Add_8d5fe4674e364518a5d8f4559669df92_Out_2);
                    Bindings_GetAdditionalLight_b5516a5008f7d104abebe27210c42de8 _GetAdditionalLight_ee2152ac3ed64138932b3a2e4b8e3f14;
                    float3 _GetAdditionalLight_ee2152ac3ed64138932b3a2e4b8e3f14_Direction_0;
                    float3 _GetAdditionalLight_ee2152ac3ed64138932b3a2e4b8e3f14_Color_1;
                    float _GetAdditionalLight_ee2152ac3ed64138932b3a2e4b8e3f14_Attenuation_2;
                    SG_GetAdditionalLight_b5516a5008f7d104abebe27210c42de8(IN.WorldSpacePosition, 2, _GetAdditionalLight_ee2152ac3ed64138932b3a2e4b8e3f14, _GetAdditionalLight_ee2152ac3ed64138932b3a2e4b8e3f14_Direction_0, _GetAdditionalLight_ee2152ac3ed64138932b3a2e4b8e3f14_Color_1, _GetAdditionalLight_ee2152ac3ed64138932b3a2e4b8e3f14_Attenuation_2);
                    float _DotProduct_7a3fce316c4a453e9b9e18226fc2d066_Out_2;
                    Unity_DotProduct_float3(_GetAdditionalLight_ee2152ac3ed64138932b3a2e4b8e3f14_Direction_0, IN.WorldSpaceNormal, _DotProduct_7a3fce316c4a453e9b9e18226fc2d066_Out_2);
                    float _Saturate_c9919732b14f4622aa82e1eec5cb383d_Out_1;
                    Unity_Saturate_float(_DotProduct_7a3fce316c4a453e9b9e18226fc2d066_Out_2, _Saturate_c9919732b14f4622aa82e1eec5cb383d_Out_1);
                    float3 _Multiply_013e04c47fdf4f46a7f2a4868ec83bed_Out_2;
                    Unity_Multiply_float((_Saturate_c9919732b14f4622aa82e1eec5cb383d_Out_1.xxx), _GetAdditionalLight_ee2152ac3ed64138932b3a2e4b8e3f14_Color_1, _Multiply_013e04c47fdf4f46a7f2a4868ec83bed_Out_2);
                    float3 _Multiply_8d16da0d689d4d49909909e6c2cc2da6_Out_2;
                    Unity_Multiply_float(_Multiply_013e04c47fdf4f46a7f2a4868ec83bed_Out_2, (_GetAdditionalLight_ee2152ac3ed64138932b3a2e4b8e3f14_Attenuation_2.xxx), _Multiply_8d16da0d689d4d49909909e6c2cc2da6_Out_2);
                    Bindings_GetAdditionalLight_b5516a5008f7d104abebe27210c42de8 _GetAdditionalLight_da7753016bd64b489b897349d7f3fc0f;
                    float3 _GetAdditionalLight_da7753016bd64b489b897349d7f3fc0f_Direction_0;
                    float3 _GetAdditionalLight_da7753016bd64b489b897349d7f3fc0f_Color_1;
                    float _GetAdditionalLight_da7753016bd64b489b897349d7f3fc0f_Attenuation_2;
                    SG_GetAdditionalLight_b5516a5008f7d104abebe27210c42de8(IN.WorldSpacePosition, 3, _GetAdditionalLight_da7753016bd64b489b897349d7f3fc0f, _GetAdditionalLight_da7753016bd64b489b897349d7f3fc0f_Direction_0, _GetAdditionalLight_da7753016bd64b489b897349d7f3fc0f_Color_1, _GetAdditionalLight_da7753016bd64b489b897349d7f3fc0f_Attenuation_2);
                    float _DotProduct_be3ed23b71d142e3a88f9f21ca2b9bb1_Out_2;
                    Unity_DotProduct_float3(_GetAdditionalLight_da7753016bd64b489b897349d7f3fc0f_Direction_0, IN.WorldSpaceNormal, _DotProduct_be3ed23b71d142e3a88f9f21ca2b9bb1_Out_2);
                    float _Saturate_b3794fe44470430e954d43bb481a3d9a_Out_1;
                    Unity_Saturate_float(_DotProduct_be3ed23b71d142e3a88f9f21ca2b9bb1_Out_2, _Saturate_b3794fe44470430e954d43bb481a3d9a_Out_1);
                    float3 _Multiply_fcf9bc551f0e42f39634ac95fab7cae5_Out_2;
                    Unity_Multiply_float((_Saturate_b3794fe44470430e954d43bb481a3d9a_Out_1.xxx), _GetAdditionalLight_da7753016bd64b489b897349d7f3fc0f_Color_1, _Multiply_fcf9bc551f0e42f39634ac95fab7cae5_Out_2);
                    float3 _Multiply_0cc8c00775354d6a9f91977c3e357ff8_Out_2;
                    Unity_Multiply_float(_Multiply_fcf9bc551f0e42f39634ac95fab7cae5_Out_2, (_GetAdditionalLight_da7753016bd64b489b897349d7f3fc0f_Attenuation_2.xxx), _Multiply_0cc8c00775354d6a9f91977c3e357ff8_Out_2);
                    float3 _Add_0992646b9a764f6eb220517d0e9fc815_Out_2;
                    Unity_Add_float3(_Multiply_8d16da0d689d4d49909909e6c2cc2da6_Out_2, _Multiply_0cc8c00775354d6a9f91977c3e357ff8_Out_2, _Add_0992646b9a764f6eb220517d0e9fc815_Out_2);
                    float3 _Add_d239c6ae017b45cba8fda7bfa29dc880_Out_2;
                    Unity_Add_float3(_Add_8d5fe4674e364518a5d8f4559669df92_Out_2, _Add_0992646b9a764f6eb220517d0e9fc815_Out_2, _Add_d239c6ae017b45cba8fda7bfa29dc880_Out_2);
                    Diffuse_1 = _Add_d239c6ae017b45cba8fda7bfa29dc880_Out_2;
                }
                
                void Unity_Smoothstep_float3(float3 Edge1, float3 Edge2, float3 In, out float3 Out)
                {
                    Out = smoothstep(Edge1, Edge2, In);
                }
                
                void Unity_Normalize_float3(float3 In, out float3 Out)
                {
                    Out = normalize(In);
                }
                
                void Unity_Power_float(float A, float B, out float Out)
                {
                    Out = pow(A, B);
                }
                
                void Unity_Step_float(float Edge, float In, out float Out)
                {
                    Out = step(Edge, In);
                }
                
                struct Bindings_CalcAdditionalSpecular_d84098efe9b2b6043a74a1631b825314
                {
                    float3 WorldSpaceNormal;
                    float3 WorldSpaceViewDirection;
                    float3 WorldSpacePosition;
                };
                
                void SG_CalcAdditionalSpecular_d84098efe9b2b6043a74a1631b825314(float Vector1_ba56f786be984242bee2ff33f2d093fc, Bindings_CalcAdditionalSpecular_d84098efe9b2b6043a74a1631b825314 IN, out float3 Diffuse_1)
                {
                    Bindings_GetAdditionalLight_b5516a5008f7d104abebe27210c42de8 _GetAdditionalLight_e6c10dfa199649fca18a0cb673fcba44;
                    float3 _GetAdditionalLight_e6c10dfa199649fca18a0cb673fcba44_Direction_0;
                    float3 _GetAdditionalLight_e6c10dfa199649fca18a0cb673fcba44_Color_1;
                    float _GetAdditionalLight_e6c10dfa199649fca18a0cb673fcba44_Attenuation_2;
                    SG_GetAdditionalLight_b5516a5008f7d104abebe27210c42de8(IN.WorldSpacePosition, 0, _GetAdditionalLight_e6c10dfa199649fca18a0cb673fcba44, _GetAdditionalLight_e6c10dfa199649fca18a0cb673fcba44_Direction_0, _GetAdditionalLight_e6c10dfa199649fca18a0cb673fcba44_Color_1, _GetAdditionalLight_e6c10dfa199649fca18a0cb673fcba44_Attenuation_2);
                    float3 _Add_7b85500005d849309401cd5cf5ee87fd_Out_2;
                    Unity_Add_float3(_GetAdditionalLight_e6c10dfa199649fca18a0cb673fcba44_Direction_0, IN.WorldSpaceViewDirection, _Add_7b85500005d849309401cd5cf5ee87fd_Out_2);
                    float3 _Normalize_e287e84e1db74e1d979a340af21eb458_Out_1;
                    Unity_Normalize_float3(_Add_7b85500005d849309401cd5cf5ee87fd_Out_2, _Normalize_e287e84e1db74e1d979a340af21eb458_Out_1);
                    float _DotProduct_aee5f4b498024e2da9796ed342f8a43a_Out_2;
                    Unity_DotProduct_float3(_Normalize_e287e84e1db74e1d979a340af21eb458_Out_1, IN.WorldSpaceNormal, _DotProduct_aee5f4b498024e2da9796ed342f8a43a_Out_2);
                    float _Saturate_2080d664f6004dc9ad574ba7e91917b2_Out_1;
                    Unity_Saturate_float(_DotProduct_aee5f4b498024e2da9796ed342f8a43a_Out_2, _Saturate_2080d664f6004dc9ad574ba7e91917b2_Out_1);
                    float _DotProduct_0526a944521c47d3b6c84b963fedd1ff_Out_2;
                    Unity_DotProduct_float3(_GetAdditionalLight_e6c10dfa199649fca18a0cb673fcba44_Direction_0, IN.WorldSpaceNormal, _DotProduct_0526a944521c47d3b6c84b963fedd1ff_Out_2);
                    float _Step_c67d6a53c975466dbaef6447b6a8bb15_Out_2;
                    Unity_Step_float(0, _DotProduct_0526a944521c47d3b6c84b963fedd1ff_Out_2, _Step_c67d6a53c975466dbaef6447b6a8bb15_Out_2);
                    float _Multiply_31278482890d4002a4b8eaea84d893d7_Out_2;
                    Unity_Multiply_float(_Saturate_2080d664f6004dc9ad574ba7e91917b2_Out_1, _Step_c67d6a53c975466dbaef6447b6a8bb15_Out_2, _Multiply_31278482890d4002a4b8eaea84d893d7_Out_2);
                    float _Property_b388a74e1b6a4d90939e467c9ef567a3_Out_0 = Vector1_ba56f786be984242bee2ff33f2d093fc;
                    float _Power_99f8e80de63e4acaa6046138e24f4bd2_Out_2;
                    Unity_Power_float(_Multiply_31278482890d4002a4b8eaea84d893d7_Out_2, _Property_b388a74e1b6a4d90939e467c9ef567a3_Out_0, _Power_99f8e80de63e4acaa6046138e24f4bd2_Out_2);
                    float3 _Multiply_9cc47eeb7de841d19b65dc8e1cb229c5_Out_2;
                    Unity_Multiply_float((_Power_99f8e80de63e4acaa6046138e24f4bd2_Out_2.xxx), _GetAdditionalLight_e6c10dfa199649fca18a0cb673fcba44_Color_1, _Multiply_9cc47eeb7de841d19b65dc8e1cb229c5_Out_2);
                    float3 _Multiply_40c5102279054efb933d4fd61a725966_Out_2;
                    Unity_Multiply_float(_Multiply_9cc47eeb7de841d19b65dc8e1cb229c5_Out_2, (_GetAdditionalLight_e6c10dfa199649fca18a0cb673fcba44_Attenuation_2.xxx), _Multiply_40c5102279054efb933d4fd61a725966_Out_2);
                    Bindings_GetAdditionalLight_b5516a5008f7d104abebe27210c42de8 _GetAdditionalLight_a054a4cd5b484e1492208dc9ca4a85f5;
                    float3 _GetAdditionalLight_a054a4cd5b484e1492208dc9ca4a85f5_Direction_0;
                    float3 _GetAdditionalLight_a054a4cd5b484e1492208dc9ca4a85f5_Color_1;
                    float _GetAdditionalLight_a054a4cd5b484e1492208dc9ca4a85f5_Attenuation_2;
                    SG_GetAdditionalLight_b5516a5008f7d104abebe27210c42de8(IN.WorldSpacePosition, 1, _GetAdditionalLight_a054a4cd5b484e1492208dc9ca4a85f5, _GetAdditionalLight_a054a4cd5b484e1492208dc9ca4a85f5_Direction_0, _GetAdditionalLight_a054a4cd5b484e1492208dc9ca4a85f5_Color_1, _GetAdditionalLight_a054a4cd5b484e1492208dc9ca4a85f5_Attenuation_2);
                    float3 _Add_282adf4f675a4392bdd7447da1537cff_Out_2;
                    Unity_Add_float3(_GetAdditionalLight_a054a4cd5b484e1492208dc9ca4a85f5_Direction_0, IN.WorldSpaceViewDirection, _Add_282adf4f675a4392bdd7447da1537cff_Out_2);
                    float3 _Normalize_d3d2dd5bbe7e4e749daa7d0b940b66e2_Out_1;
                    Unity_Normalize_float3(_Add_282adf4f675a4392bdd7447da1537cff_Out_2, _Normalize_d3d2dd5bbe7e4e749daa7d0b940b66e2_Out_1);
                    float _DotProduct_00e581a08ce7465588597fd11859eea2_Out_2;
                    Unity_DotProduct_float3(_Normalize_d3d2dd5bbe7e4e749daa7d0b940b66e2_Out_1, IN.WorldSpaceNormal, _DotProduct_00e581a08ce7465588597fd11859eea2_Out_2);
                    float _Saturate_58b5f4d3dcaf45e6bda212ef43edc4ea_Out_1;
                    Unity_Saturate_float(_DotProduct_00e581a08ce7465588597fd11859eea2_Out_2, _Saturate_58b5f4d3dcaf45e6bda212ef43edc4ea_Out_1);
                    float _DotProduct_e5d1d640606340949f9ecba8df9c866d_Out_2;
                    Unity_DotProduct_float3(_GetAdditionalLight_a054a4cd5b484e1492208dc9ca4a85f5_Direction_0, IN.WorldSpaceNormal, _DotProduct_e5d1d640606340949f9ecba8df9c866d_Out_2);
                    float _Step_d5595987000246e096b1bd14ec15600e_Out_2;
                    Unity_Step_float(0, _DotProduct_e5d1d640606340949f9ecba8df9c866d_Out_2, _Step_d5595987000246e096b1bd14ec15600e_Out_2);
                    float _Multiply_556cb17951c5463481d66c85c69f72ae_Out_2;
                    Unity_Multiply_float(_Saturate_58b5f4d3dcaf45e6bda212ef43edc4ea_Out_1, _Step_d5595987000246e096b1bd14ec15600e_Out_2, _Multiply_556cb17951c5463481d66c85c69f72ae_Out_2);
                    float _Power_1783632603444ae9bd39ecc3677738f0_Out_2;
                    Unity_Power_float(_Multiply_556cb17951c5463481d66c85c69f72ae_Out_2, _Property_b388a74e1b6a4d90939e467c9ef567a3_Out_0, _Power_1783632603444ae9bd39ecc3677738f0_Out_2);
                    float3 _Multiply_f4914d2b6dae4123a4ce1897d42f8dda_Out_2;
                    Unity_Multiply_float((_Power_1783632603444ae9bd39ecc3677738f0_Out_2.xxx), _GetAdditionalLight_a054a4cd5b484e1492208dc9ca4a85f5_Color_1, _Multiply_f4914d2b6dae4123a4ce1897d42f8dda_Out_2);
                    float3 _Multiply_dff05416518540d5b4d99dfdf00c5766_Out_2;
                    Unity_Multiply_float(_Multiply_f4914d2b6dae4123a4ce1897d42f8dda_Out_2, (_GetAdditionalLight_a054a4cd5b484e1492208dc9ca4a85f5_Attenuation_2.xxx), _Multiply_dff05416518540d5b4d99dfdf00c5766_Out_2);
                    float3 _Add_8d5fe4674e364518a5d8f4559669df92_Out_2;
                    Unity_Add_float3(_Multiply_40c5102279054efb933d4fd61a725966_Out_2, _Multiply_dff05416518540d5b4d99dfdf00c5766_Out_2, _Add_8d5fe4674e364518a5d8f4559669df92_Out_2);
                    Bindings_GetAdditionalLight_b5516a5008f7d104abebe27210c42de8 _GetAdditionalLight_ee2152ac3ed64138932b3a2e4b8e3f14;
                    float3 _GetAdditionalLight_ee2152ac3ed64138932b3a2e4b8e3f14_Direction_0;
                    float3 _GetAdditionalLight_ee2152ac3ed64138932b3a2e4b8e3f14_Color_1;
                    float _GetAdditionalLight_ee2152ac3ed64138932b3a2e4b8e3f14_Attenuation_2;
                    SG_GetAdditionalLight_b5516a5008f7d104abebe27210c42de8(IN.WorldSpacePosition, 2, _GetAdditionalLight_ee2152ac3ed64138932b3a2e4b8e3f14, _GetAdditionalLight_ee2152ac3ed64138932b3a2e4b8e3f14_Direction_0, _GetAdditionalLight_ee2152ac3ed64138932b3a2e4b8e3f14_Color_1, _GetAdditionalLight_ee2152ac3ed64138932b3a2e4b8e3f14_Attenuation_2);
                    float3 _Add_b3b13d361198482f9ee7222ea4d9d819_Out_2;
                    Unity_Add_float3(_GetAdditionalLight_ee2152ac3ed64138932b3a2e4b8e3f14_Direction_0, IN.WorldSpaceViewDirection, _Add_b3b13d361198482f9ee7222ea4d9d819_Out_2);
                    float3 _Normalize_ceaea3816fe94ba48dc9c37f6336e177_Out_1;
                    Unity_Normalize_float3(_Add_b3b13d361198482f9ee7222ea4d9d819_Out_2, _Normalize_ceaea3816fe94ba48dc9c37f6336e177_Out_1);
                    float _DotProduct_7a3fce316c4a453e9b9e18226fc2d066_Out_2;
                    Unity_DotProduct_float3(_Normalize_ceaea3816fe94ba48dc9c37f6336e177_Out_1, IN.WorldSpaceNormal, _DotProduct_7a3fce316c4a453e9b9e18226fc2d066_Out_2);
                    float _Saturate_c9919732b14f4622aa82e1eec5cb383d_Out_1;
                    Unity_Saturate_float(_DotProduct_7a3fce316c4a453e9b9e18226fc2d066_Out_2, _Saturate_c9919732b14f4622aa82e1eec5cb383d_Out_1);
                    float _DotProduct_172616bd9ee743ac9176fabfc0972b90_Out_2;
                    Unity_DotProduct_float3(_GetAdditionalLight_ee2152ac3ed64138932b3a2e4b8e3f14_Direction_0, IN.WorldSpaceNormal, _DotProduct_172616bd9ee743ac9176fabfc0972b90_Out_2);
                    float _Step_6ae114101d8f4d26a00a90cccaa45672_Out_2;
                    Unity_Step_float(0, _DotProduct_172616bd9ee743ac9176fabfc0972b90_Out_2, _Step_6ae114101d8f4d26a00a90cccaa45672_Out_2);
                    float _Multiply_4a9b97617c2448dea4f10cdcb58d4202_Out_2;
                    Unity_Multiply_float(_Saturate_c9919732b14f4622aa82e1eec5cb383d_Out_1, _Step_6ae114101d8f4d26a00a90cccaa45672_Out_2, _Multiply_4a9b97617c2448dea4f10cdcb58d4202_Out_2);
                    float _Power_0801befaab9143ffb3380be20bbdc5ab_Out_2;
                    Unity_Power_float(_Multiply_4a9b97617c2448dea4f10cdcb58d4202_Out_2, _Property_b388a74e1b6a4d90939e467c9ef567a3_Out_0, _Power_0801befaab9143ffb3380be20bbdc5ab_Out_2);
                    float3 _Multiply_cef864918e1e44799f326a20b8334c24_Out_2;
                    Unity_Multiply_float((_Power_0801befaab9143ffb3380be20bbdc5ab_Out_2.xxx), _GetAdditionalLight_ee2152ac3ed64138932b3a2e4b8e3f14_Color_1, _Multiply_cef864918e1e44799f326a20b8334c24_Out_2);
                    float3 _Multiply_d95d25aea25e4461b8a3af2420f0d8e2_Out_2;
                    Unity_Multiply_float(_Multiply_cef864918e1e44799f326a20b8334c24_Out_2, (_GetAdditionalLight_ee2152ac3ed64138932b3a2e4b8e3f14_Attenuation_2.xxx), _Multiply_d95d25aea25e4461b8a3af2420f0d8e2_Out_2);
                    Bindings_GetAdditionalLight_b5516a5008f7d104abebe27210c42de8 _GetAdditionalLight_da7753016bd64b489b897349d7f3fc0f;
                    float3 _GetAdditionalLight_da7753016bd64b489b897349d7f3fc0f_Direction_0;
                    float3 _GetAdditionalLight_da7753016bd64b489b897349d7f3fc0f_Color_1;
                    float _GetAdditionalLight_da7753016bd64b489b897349d7f3fc0f_Attenuation_2;
                    SG_GetAdditionalLight_b5516a5008f7d104abebe27210c42de8(IN.WorldSpacePosition, 3, _GetAdditionalLight_da7753016bd64b489b897349d7f3fc0f, _GetAdditionalLight_da7753016bd64b489b897349d7f3fc0f_Direction_0, _GetAdditionalLight_da7753016bd64b489b897349d7f3fc0f_Color_1, _GetAdditionalLight_da7753016bd64b489b897349d7f3fc0f_Attenuation_2);
                    float3 _Add_3d580f5eb4d44d1a9308632cf3541341_Out_2;
                    Unity_Add_float3(_GetAdditionalLight_da7753016bd64b489b897349d7f3fc0f_Direction_0, IN.WorldSpaceViewDirection, _Add_3d580f5eb4d44d1a9308632cf3541341_Out_2);
                    float3 _Normalize_d6753f83c1d7448991e6e7d8b08f3ffe_Out_1;
                    Unity_Normalize_float3(_Add_3d580f5eb4d44d1a9308632cf3541341_Out_2, _Normalize_d6753f83c1d7448991e6e7d8b08f3ffe_Out_1);
                    float _DotProduct_be3ed23b71d142e3a88f9f21ca2b9bb1_Out_2;
                    Unity_DotProduct_float3(_Normalize_d6753f83c1d7448991e6e7d8b08f3ffe_Out_1, IN.WorldSpaceNormal, _DotProduct_be3ed23b71d142e3a88f9f21ca2b9bb1_Out_2);
                    float _Saturate_b3794fe44470430e954d43bb481a3d9a_Out_1;
                    Unity_Saturate_float(_DotProduct_be3ed23b71d142e3a88f9f21ca2b9bb1_Out_2, _Saturate_b3794fe44470430e954d43bb481a3d9a_Out_1);
                    float _DotProduct_6919254c79d54f02beaaea46cea4bb88_Out_2;
                    Unity_DotProduct_float3(_GetAdditionalLight_da7753016bd64b489b897349d7f3fc0f_Direction_0, IN.WorldSpaceNormal, _DotProduct_6919254c79d54f02beaaea46cea4bb88_Out_2);
                    float _Step_298fb6a31079465894cd805c44c575e3_Out_2;
                    Unity_Step_float(0, _DotProduct_6919254c79d54f02beaaea46cea4bb88_Out_2, _Step_298fb6a31079465894cd805c44c575e3_Out_2);
                    float _Multiply_2531419c34224bfd8f2a6b986099fc14_Out_2;
                    Unity_Multiply_float(_Saturate_b3794fe44470430e954d43bb481a3d9a_Out_1, _Step_298fb6a31079465894cd805c44c575e3_Out_2, _Multiply_2531419c34224bfd8f2a6b986099fc14_Out_2);
                    float _Power_ef3de81b9a0f42a7a6689a0949350c4f_Out_2;
                    Unity_Power_float(_Multiply_2531419c34224bfd8f2a6b986099fc14_Out_2, _Property_b388a74e1b6a4d90939e467c9ef567a3_Out_0, _Power_ef3de81b9a0f42a7a6689a0949350c4f_Out_2);
                    float3 _Multiply_8962de9ab0024826abfc88590336908a_Out_2;
                    Unity_Multiply_float((_Power_ef3de81b9a0f42a7a6689a0949350c4f_Out_2.xxx), _GetAdditionalLight_da7753016bd64b489b897349d7f3fc0f_Color_1, _Multiply_8962de9ab0024826abfc88590336908a_Out_2);
                    float3 _Multiply_d130cd99cdd04ddbb2d61d5a1fa09fd9_Out_2;
                    Unity_Multiply_float(_Multiply_8962de9ab0024826abfc88590336908a_Out_2, (_GetAdditionalLight_da7753016bd64b489b897349d7f3fc0f_Attenuation_2.xxx), _Multiply_d130cd99cdd04ddbb2d61d5a1fa09fd9_Out_2);
                    float3 _Add_0992646b9a764f6eb220517d0e9fc815_Out_2;
                    Unity_Add_float3(_Multiply_d95d25aea25e4461b8a3af2420f0d8e2_Out_2, _Multiply_d130cd99cdd04ddbb2d61d5a1fa09fd9_Out_2, _Add_0992646b9a764f6eb220517d0e9fc815_Out_2);
                    float3 _Add_d239c6ae017b45cba8fda7bfa29dc880_Out_2;
                    Unity_Add_float3(_Add_8d5fe4674e364518a5d8f4559669df92_Out_2, _Add_0992646b9a764f6eb220517d0e9fc815_Out_2, _Add_d239c6ae017b45cba8fda7bfa29dc880_Out_2);
                    Diffuse_1 = _Add_d239c6ae017b45cba8fda7bfa29dc880_Out_2;
                }
                
                void Unity_Maximum_float3(float3 A, float3 B, out float3 Out)
                {
                    Out = max(A, B);
                }
    
                // Graph Vertex
                struct VertexDescription
                {
                    float3 Position;
                    float3 Normal;
                    float3 Tangent;
                };
                
                VertexDescription VertexDescriptionFunction(VertexDescriptionInputs IN)
                {
                    VertexDescription description = (VertexDescription)0;
                    description.Position = IN.ObjectSpacePosition;
                    description.Normal = IN.ObjectSpaceNormal;
                    description.Tangent = IN.ObjectSpaceTangent;
                    return description;
                }
    
                // Graph Pixel
                struct SurfaceDescription
                {
                    float3 BaseColor;
                    float3 Emission;
                };
                
                SurfaceDescription SurfaceDescriptionFunction(SurfaceDescriptionInputs IN)
                {
                    SurfaceDescription surface = (SurfaceDescription)0;
                    float4 _Property_fd7e56b6f55544e1b80c8fd2c097fb78_Out_0 = _FresnelColor;
                    float _Property_faab3ff61e174da380387a5284f29359_Out_0 = _LightingCutoff;
                    float _Property_1f83c6224c604735b8fc5e7585df4c66_Out_0 = _FalloffAmount;
                    float _Add_b1804a0ba53b477b9d8fb474b3008e5f_Out_2;
                    Unity_Add_float(_Property_faab3ff61e174da380387a5284f29359_Out_0, _Property_1f83c6224c604735b8fc5e7585df4c66_Out_0, _Add_b1804a0ba53b477b9d8fb474b3008e5f_Out_2);
                    float _Property_f71948fe16194e1c9767bb52a648a2c1_Out_0 = _FresnelSize;
                    float _Reciprocal_1ab5ff841a4e496dbcaf48eca728ce63_Out_1;
                    Unity_Reciprocal_float(_Property_f71948fe16194e1c9767bb52a648a2c1_Out_0, _Reciprocal_1ab5ff841a4e496dbcaf48eca728ce63_Out_1);
                    float _FresnelEffect_b85b6878ded3452382e4918a35e68e34_Out_3;
                    Unity_FresnelEffect_float(IN.WorldSpaceNormal, IN.WorldSpaceViewDirection, _Reciprocal_1ab5ff841a4e496dbcaf48eca728ce63_Out_1, _FresnelEffect_b85b6878ded3452382e4918a35e68e34_Out_3);
                    Bindings_GetMainLight_d6b14a2e8b6f3554b8459648535f697e _GetMainLight_41b37094e05a429f8266b6602caf8242;
                    float3 _GetMainLight_41b37094e05a429f8266b6602caf8242_Direction_0;
                    float3 _GetMainLight_41b37094e05a429f8266b6602caf8242_Color_1;
                    float _GetMainLight_41b37094e05a429f8266b6602caf8242_Attenuation_2;
                    SG_GetMainLight_d6b14a2e8b6f3554b8459648535f697e(IN.WorldSpacePosition, _GetMainLight_41b37094e05a429f8266b6602caf8242, _GetMainLight_41b37094e05a429f8266b6602caf8242_Direction_0, _GetMainLight_41b37094e05a429f8266b6602caf8242_Color_1, _GetMainLight_41b37094e05a429f8266b6602caf8242_Attenuation_2);
                    float _DotProduct_8d4bdec92ac948559d5a94572dd8cb4d_Out_2;
                    Unity_DotProduct_float3(IN.WorldSpaceNormal, _GetMainLight_41b37094e05a429f8266b6602caf8242_Direction_0, _DotProduct_8d4bdec92ac948559d5a94572dd8cb4d_Out_2);
                    float _Multiply_315cde53c6dc4a3592ed4ee8f047be73_Out_2;
                    Unity_Multiply_float(_DotProduct_8d4bdec92ac948559d5a94572dd8cb4d_Out_2, _GetMainLight_41b37094e05a429f8266b6602caf8242_Attenuation_2, _Multiply_315cde53c6dc4a3592ed4ee8f047be73_Out_2);
                    float3 _Multiply_250e64e5c0fe4aa3aa2515f930a78e5a_Out_2;
                    Unity_Multiply_float((_Multiply_315cde53c6dc4a3592ed4ee8f047be73_Out_2.xxx), _GetMainLight_41b37094e05a429f8266b6602caf8242_Color_1, _Multiply_250e64e5c0fe4aa3aa2515f930a78e5a_Out_2);
                    float3 _Saturate_fdaf2acf4b0d40b3ae196b038de92740_Out_1;
                    Unity_Saturate_float3(_Multiply_250e64e5c0fe4aa3aa2515f930a78e5a_Out_2, _Saturate_fdaf2acf4b0d40b3ae196b038de92740_Out_1);
                    Bindings_CalcAdditionalDiffuse_e85823578a3493d41ade631af12166aa _CalcAdditionalDiffuse_f61ebb0caffa49798669b455d28ddc2f;
                    _CalcAdditionalDiffuse_f61ebb0caffa49798669b455d28ddc2f.WorldSpaceNormal = IN.WorldSpaceNormal;
                    _CalcAdditionalDiffuse_f61ebb0caffa49798669b455d28ddc2f.WorldSpacePosition = IN.WorldSpacePosition;
                    float3 _CalcAdditionalDiffuse_f61ebb0caffa49798669b455d28ddc2f_Diffuse_1;
                    SG_CalcAdditionalDiffuse_e85823578a3493d41ade631af12166aa(_CalcAdditionalDiffuse_f61ebb0caffa49798669b455d28ddc2f, _CalcAdditionalDiffuse_f61ebb0caffa49798669b455d28ddc2f_Diffuse_1);
                    float3 _Add_0f6ab824bf464526bbf3116b8d1e102f_Out_2;
                    Unity_Add_float3(_Saturate_fdaf2acf4b0d40b3ae196b038de92740_Out_1, _CalcAdditionalDiffuse_f61ebb0caffa49798669b455d28ddc2f_Diffuse_1, _Add_0f6ab824bf464526bbf3116b8d1e102f_Out_2);
                    float3 _Multiply_57cc1ea2df2f4223815236660d4ba4b2_Out_2;
                    Unity_Multiply_float((_FresnelEffect_b85b6878ded3452382e4918a35e68e34_Out_3.xxx), _Add_0f6ab824bf464526bbf3116b8d1e102f_Out_2, _Multiply_57cc1ea2df2f4223815236660d4ba4b2_Out_2);
                    float3 _Smoothstep_424686c920094f11a03df5f03afe5145_Out_3;
                    Unity_Smoothstep_float3((_Property_faab3ff61e174da380387a5284f29359_Out_0.xxx), (_Add_b1804a0ba53b477b9d8fb474b3008e5f_Out_2.xxx), _Multiply_57cc1ea2df2f4223815236660d4ba4b2_Out_2, _Smoothstep_424686c920094f11a03df5f03afe5145_Out_3);
                    float3 _Multiply_08e1c96546e24df2920fcd26690a7402_Out_2;
                    Unity_Multiply_float((_Property_fd7e56b6f55544e1b80c8fd2c097fb78_Out_0.xyz), _Smoothstep_424686c920094f11a03df5f03afe5145_Out_3, _Multiply_08e1c96546e24df2920fcd26690a7402_Out_2);
                    float4 _Property_0d605fca5a9b4f2e8020677b52b5629d_Out_0 = _SpecularColor;
                    float _Property_1d077dd941fc4016a62636a6048577bc_Out_0 = _LightingCutoff;
                    float _Property_2a13ac2eb2084e0f912c6485bff7e1fb_Out_0 = _FalloffAmount;
                    float _Add_aee813a1674a41449133aac98f918ac9_Out_2;
                    Unity_Add_float(_Property_1d077dd941fc4016a62636a6048577bc_Out_0, _Property_2a13ac2eb2084e0f912c6485bff7e1fb_Out_0, _Add_aee813a1674a41449133aac98f918ac9_Out_2);
                    Bindings_GetMainLight_d6b14a2e8b6f3554b8459648535f697e _GetMainLight_5a267f1983eb45038dd25d47096b3576;
                    float3 _GetMainLight_5a267f1983eb45038dd25d47096b3576_Direction_0;
                    float3 _GetMainLight_5a267f1983eb45038dd25d47096b3576_Color_1;
                    float _GetMainLight_5a267f1983eb45038dd25d47096b3576_Attenuation_2;
                    SG_GetMainLight_d6b14a2e8b6f3554b8459648535f697e(IN.WorldSpacePosition, _GetMainLight_5a267f1983eb45038dd25d47096b3576, _GetMainLight_5a267f1983eb45038dd25d47096b3576_Direction_0, _GetMainLight_5a267f1983eb45038dd25d47096b3576_Color_1, _GetMainLight_5a267f1983eb45038dd25d47096b3576_Attenuation_2);
                    float3 _Add_cdec837b18d14622929b74d779f9ed53_Out_2;
                    Unity_Add_float3(IN.WorldSpaceViewDirection, _GetMainLight_5a267f1983eb45038dd25d47096b3576_Direction_0, _Add_cdec837b18d14622929b74d779f9ed53_Out_2);
                    float3 _Normalize_4ed8697fa3534c40a04c3b38c2f39118_Out_1;
                    Unity_Normalize_float3(_Add_cdec837b18d14622929b74d779f9ed53_Out_2, _Normalize_4ed8697fa3534c40a04c3b38c2f39118_Out_1);
                    float _DotProduct_2a86b7ba7a4e47c1b993a25eea174112_Out_2;
                    Unity_DotProduct_float3(IN.WorldSpaceNormal, _Normalize_4ed8697fa3534c40a04c3b38c2f39118_Out_1, _DotProduct_2a86b7ba7a4e47c1b993a25eea174112_Out_2);
                    float _Saturate_5954bbc00cbe4ab1aaece8a4042a2ae1_Out_1;
                    Unity_Saturate_float(_DotProduct_2a86b7ba7a4e47c1b993a25eea174112_Out_2, _Saturate_5954bbc00cbe4ab1aaece8a4042a2ae1_Out_1);
                    float _Property_09addda5751f4ae38ffd75d2cf5042be_Out_0 = _Smoothness;
                    float _Power_d01facce68d2456bb5459bf9144d966c_Out_2;
                    Unity_Power_float(_Saturate_5954bbc00cbe4ab1aaece8a4042a2ae1_Out_1, _Property_09addda5751f4ae38ffd75d2cf5042be_Out_0, _Power_d01facce68d2456bb5459bf9144d966c_Out_2);
                    float3 _Multiply_37f25c3b613140a98d39720af3f46c04_Out_2;
                    Unity_Multiply_float((_Power_d01facce68d2456bb5459bf9144d966c_Out_2.xxx), _GetMainLight_5a267f1983eb45038dd25d47096b3576_Color_1, _Multiply_37f25c3b613140a98d39720af3f46c04_Out_2);
                    float3 _Multiply_40d12c060eda4e9293ea46113abcac99_Out_2;
                    Unity_Multiply_float(_Multiply_37f25c3b613140a98d39720af3f46c04_Out_2, (_GetMainLight_5a267f1983eb45038dd25d47096b3576_Attenuation_2.xxx), _Multiply_40d12c060eda4e9293ea46113abcac99_Out_2);
                    float3 _Multiply_20c6e31cff10450ab4a4e6910c501dff_Out_2;
                    Unity_Multiply_float(_Multiply_40d12c060eda4e9293ea46113abcac99_Out_2, _Saturate_fdaf2acf4b0d40b3ae196b038de92740_Out_1, _Multiply_20c6e31cff10450ab4a4e6910c501dff_Out_2);
                    Bindings_CalcAdditionalSpecular_d84098efe9b2b6043a74a1631b825314 _CalcAdditionalSpecular_cd3669952dc74dfe8fc61749791c4fda;
                    _CalcAdditionalSpecular_cd3669952dc74dfe8fc61749791c4fda.WorldSpaceNormal = IN.WorldSpaceNormal;
                    _CalcAdditionalSpecular_cd3669952dc74dfe8fc61749791c4fda.WorldSpaceViewDirection = IN.WorldSpaceViewDirection;
                    _CalcAdditionalSpecular_cd3669952dc74dfe8fc61749791c4fda.WorldSpacePosition = IN.WorldSpacePosition;
                    float3 _CalcAdditionalSpecular_cd3669952dc74dfe8fc61749791c4fda_Diffuse_1;
                    SG_CalcAdditionalSpecular_d84098efe9b2b6043a74a1631b825314(_Property_09addda5751f4ae38ffd75d2cf5042be_Out_0, _CalcAdditionalSpecular_cd3669952dc74dfe8fc61749791c4fda, _CalcAdditionalSpecular_cd3669952dc74dfe8fc61749791c4fda_Diffuse_1);
                    float3 _Add_6cdd48355c7448bbbc9dc34639d2f16d_Out_2;
                    Unity_Add_float3(_Multiply_20c6e31cff10450ab4a4e6910c501dff_Out_2, _CalcAdditionalSpecular_cd3669952dc74dfe8fc61749791c4fda_Diffuse_1, _Add_6cdd48355c7448bbbc9dc34639d2f16d_Out_2);
                    float3 _Smoothstep_46bf89c479e64da1a8083fa09e5d323d_Out_3;
                    Unity_Smoothstep_float3((_Property_1d077dd941fc4016a62636a6048577bc_Out_0.xxx), (_Add_aee813a1674a41449133aac98f918ac9_Out_2.xxx), _Add_6cdd48355c7448bbbc9dc34639d2f16d_Out_2, _Smoothstep_46bf89c479e64da1a8083fa09e5d323d_Out_3);
                    float3 _Multiply_fb48a1d2f9404211ad52dd2f26a46f28_Out_2;
                    Unity_Multiply_float((_Property_0d605fca5a9b4f2e8020677b52b5629d_Out_0.xyz), _Smoothstep_46bf89c479e64da1a8083fa09e5d323d_Out_3, _Multiply_fb48a1d2f9404211ad52dd2f26a46f28_Out_2);
                    float4 _Property_5bce803f7b1342118efa64dfd7a5c5af_Out_0 = _DiffuseColor;
                    float _Property_5b63eda1ad9a4c349b54058af0283a6a_Out_0 = _LightingCutoff;
                    float _Property_6b8c43c8c4e04f089b490e01842c10e7_Out_0 = _FalloffAmount;
                    float _Add_f9f052f699b24c22a7e6ed992dbded4d_Out_2;
                    Unity_Add_float(_Property_5b63eda1ad9a4c349b54058af0283a6a_Out_0, _Property_6b8c43c8c4e04f089b490e01842c10e7_Out_0, _Add_f9f052f699b24c22a7e6ed992dbded4d_Out_2);
                    float3 _Smoothstep_6421ae70d4a0477a913d197174717db2_Out_3;
                    Unity_Smoothstep_float3((_Property_5b63eda1ad9a4c349b54058af0283a6a_Out_0.xxx), (_Add_f9f052f699b24c22a7e6ed992dbded4d_Out_2.xxx), _Add_0f6ab824bf464526bbf3116b8d1e102f_Out_2, _Smoothstep_6421ae70d4a0477a913d197174717db2_Out_3);
                    float _Property_68149cd9c2eb40a79d0105acc016d1c4_Out_0 = _AmbientStrength;
                    float3 _Maximum_c73c7cbcf6c4463a865782d13a0c4101_Out_2;
                    Unity_Maximum_float3(_Smoothstep_6421ae70d4a0477a913d197174717db2_Out_3, (_Property_68149cd9c2eb40a79d0105acc016d1c4_Out_0.xxx), _Maximum_c73c7cbcf6c4463a865782d13a0c4101_Out_2);
                    float3 _Multiply_d622b247c4a84f8bbebf6a902f0b0fcb_Out_2;
                    Unity_Multiply_float((_Property_5bce803f7b1342118efa64dfd7a5c5af_Out_0.xyz), _Maximum_c73c7cbcf6c4463a865782d13a0c4101_Out_2, _Multiply_d622b247c4a84f8bbebf6a902f0b0fcb_Out_2);
                    UnityTexture2D _Property_a111b087fff64719b899025161b92d31_Out_0 = UnityBuildTexture2DStructNoScale(_MainTex);
                    float4 _SampleTexture2D_68405c1067a64b7f874afd25ede0e0c8_RGBA_0 = SAMPLE_TEXTURE2D(_Property_a111b087fff64719b899025161b92d31_Out_0.tex, _Property_a111b087fff64719b899025161b92d31_Out_0.samplerstate, IN.uv0.xy);
                    float _SampleTexture2D_68405c1067a64b7f874afd25ede0e0c8_R_4 = _SampleTexture2D_68405c1067a64b7f874afd25ede0e0c8_RGBA_0.r;
                    float _SampleTexture2D_68405c1067a64b7f874afd25ede0e0c8_G_5 = _SampleTexture2D_68405c1067a64b7f874afd25ede0e0c8_RGBA_0.g;
                    float _SampleTexture2D_68405c1067a64b7f874afd25ede0e0c8_B_6 = _SampleTexture2D_68405c1067a64b7f874afd25ede0e0c8_RGBA_0.b;
                    float _SampleTexture2D_68405c1067a64b7f874afd25ede0e0c8_A_7 = _SampleTexture2D_68405c1067a64b7f874afd25ede0e0c8_RGBA_0.a;
                    float3 _Multiply_8ac74964cd004464a81865818d5afcc4_Out_2;
                    Unity_Multiply_float(_Multiply_d622b247c4a84f8bbebf6a902f0b0fcb_Out_2, (_SampleTexture2D_68405c1067a64b7f874afd25ede0e0c8_RGBA_0.xyz), _Multiply_8ac74964cd004464a81865818d5afcc4_Out_2);
                    float3 _Add_2ebf33fa6b00434db9194d0243d86458_Out_2;
                    Unity_Add_float3(_Multiply_fb48a1d2f9404211ad52dd2f26a46f28_Out_2, _Multiply_8ac74964cd004464a81865818d5afcc4_Out_2, _Add_2ebf33fa6b00434db9194d0243d86458_Out_2);
                    float3 _Add_5db2a9e6feef42bc9e81d7017a4e1bd8_Out_2;
                    Unity_Add_float3(_Multiply_08e1c96546e24df2920fcd26690a7402_Out_2, _Add_2ebf33fa6b00434db9194d0243d86458_Out_2, _Add_5db2a9e6feef42bc9e81d7017a4e1bd8_Out_2);
                    surface.BaseColor = IsGammaSpace() ? float3(0, 0, 0) : SRGBToLinear(float3(0, 0, 0));
                    surface.Emission = _Add_5db2a9e6feef42bc9e81d7017a4e1bd8_Out_2;
                    return surface;
                }
    
                // --------------------------------------------------
                // Build Graph Inputs
    
                VertexDescriptionInputs BuildVertexDescriptionInputs(Attributes input)
                {
                    VertexDescriptionInputs output;
                    ZERO_INITIALIZE(VertexDescriptionInputs, output);
                
                    output.ObjectSpaceNormal =           input.normalOS;
                    output.ObjectSpaceTangent =          input.tangentOS.xyz;
                    output.ObjectSpacePosition =         input.positionOS;
                
                    return output;
                }
                
                SurfaceDescriptionInputs BuildSurfaceDescriptionInputs(Varyings input)
                {
                    SurfaceDescriptionInputs output;
                    ZERO_INITIALIZE(SurfaceDescriptionInputs, output);
                
                	// must use interpolated tangent, bitangent and normal before they are normalized in the pixel shader.
                	float3 unnormalizedNormalWS = input.normalWS;
                    const float renormFactor = 1.0 / length(unnormalizedNormalWS);
                
                
                    output.WorldSpaceNormal =            renormFactor*input.normalWS.xyz;		// we want a unit length Normal Vector node in shader graph
                
                
                    output.WorldSpaceViewDirection =     input.viewDirectionWS; //TODO: by default normalized in HD, but not in universal
                    output.WorldSpacePosition =          input.positionWS;
                    output.uv0 =                         input.texCoord0;
                #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
                #define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN output.FaceSign =                    IS_FRONT_VFACE(input.cullFace, true, false);
                #else
                #define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN
                #endif
                #undef BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN
                
                    return output;
                }
                
    
                // --------------------------------------------------
                // Main
    
                #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/ShaderPass.hlsl"
                #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/Varyings.hlsl"
                #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/LightingMetaPass.hlsl"
    
                ENDHLSL
            }
            Pass
            {
                // Name: <None>
                Tags
                {
                    "LightMode" = "Universal2D"
                }
    
                // Render State
                Cull Back
                Blend One Zero
                ZTest LEqual
                ZWrite On
    
                // Debug
                // <None>
    
                // --------------------------------------------------
                // Pass
    
                HLSLPROGRAM
    
                // Pragmas
                #pragma target 2.0
                #pragma only_renderers gles gles3 glcore d3d11
                #pragma multi_compile_instancing
                #pragma vertex vert
                #pragma fragment frag
    
                // DotsInstancingOptions: <None>
                // HybridV1InjectedBuiltinProperties: <None>
    
                // Keywords
                // PassKeywords: <None>
                // GraphKeywords: <None>
    
                // Defines
                #define _NORMALMAP 1
                #define _NORMAL_DROPOFF_TS 1
                #define ATTRIBUTES_NEED_NORMAL
                #define ATTRIBUTES_NEED_TANGENT
                #define FEATURES_GRAPH_VERTEX
                /* WARNING: $splice Could not find named fragment 'PassInstancing' */
                #define SHADERPASS SHADERPASS_2D
                /* WARNING: $splice Could not find named fragment 'DotsInstancingVars' */
    
                // Includes
                #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
                #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Texture.hlsl"
                #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
                #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
                #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/TextureStack.hlsl"
                #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"
    
                // --------------------------------------------------
                // Structs and Packing
    
                struct Attributes
                {
                    float3 positionOS : POSITION;
                    float3 normalOS : NORMAL;
                    float4 tangentOS : TANGENT;
                    #if UNITY_ANY_INSTANCING_ENABLED
                    uint instanceID : INSTANCEID_SEMANTIC;
                    #endif
                };
                struct Varyings
                {
                    float4 positionCS : SV_POSITION;
                    #if UNITY_ANY_INSTANCING_ENABLED
                    uint instanceID : CUSTOM_INSTANCE_ID;
                    #endif
                    #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
                    uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
                    #endif
                    #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
                    uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
                    #endif
                    #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
                    FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
                    #endif
                };
                struct SurfaceDescriptionInputs
                {
                };
                struct VertexDescriptionInputs
                {
                    float3 ObjectSpaceNormal;
                    float3 ObjectSpaceTangent;
                    float3 ObjectSpacePosition;
                };
                struct PackedVaryings
                {
                    float4 positionCS : SV_POSITION;
                    #if UNITY_ANY_INSTANCING_ENABLED
                    uint instanceID : CUSTOM_INSTANCE_ID;
                    #endif
                    #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
                    uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
                    #endif
                    #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
                    uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
                    #endif
                    #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
                    FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
                    #endif
                };
    
                PackedVaryings PackVaryings (Varyings input)
                {
                    PackedVaryings output;
                    output.positionCS = input.positionCS;
                    #if UNITY_ANY_INSTANCING_ENABLED
                    output.instanceID = input.instanceID;
                    #endif
                    #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
                    output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
                    #endif
                    #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
                    output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
                    #endif
                    #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
                    output.cullFace = input.cullFace;
                    #endif
                    return output;
                }
                Varyings UnpackVaryings (PackedVaryings input)
                {
                    Varyings output;
                    output.positionCS = input.positionCS;
                    #if UNITY_ANY_INSTANCING_ENABLED
                    output.instanceID = input.instanceID;
                    #endif
                    #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
                    output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
                    #endif
                    #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
                    output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
                    #endif
                    #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
                    output.cullFace = input.cullFace;
                    #endif
                    return output;
                }
    
                // --------------------------------------------------
                // Graph
    
                // Graph Properties
                CBUFFER_START(UnityPerMaterial)
                float _AmbientStrength;
                float4 _DiffuseColor;
                float4 _MainTex_TexelSize;
                float4 _SpecularColor;
                float4 _FresnelColor;
                float _Smoothness;
                float _FresnelSize;
                float _LightingCutoff;
                float _FalloffAmount;
                CBUFFER_END
                
                // Object and Global properties
                SAMPLER(SamplerState_Linear_Repeat);
                TEXTURE2D(_MainTex);
                SAMPLER(sampler_MainTex);
    
                // Graph Functions
                // GraphFunctions: <None>
    
                // Graph Vertex
                struct VertexDescription
                {
                    float3 Position;
                    float3 Normal;
                    float3 Tangent;
                };
                
                VertexDescription VertexDescriptionFunction(VertexDescriptionInputs IN)
                {
                    VertexDescription description = (VertexDescription)0;
                    description.Position = IN.ObjectSpacePosition;
                    description.Normal = IN.ObjectSpaceNormal;
                    description.Tangent = IN.ObjectSpaceTangent;
                    return description;
                }
    
                // Graph Pixel
                struct SurfaceDescription
                {
                    float3 BaseColor;
                };
                
                SurfaceDescription SurfaceDescriptionFunction(SurfaceDescriptionInputs IN)
                {
                    SurfaceDescription surface = (SurfaceDescription)0;
                    surface.BaseColor = IsGammaSpace() ? float3(0, 0, 0) : SRGBToLinear(float3(0, 0, 0));
                    return surface;
                }
    
                // --------------------------------------------------
                // Build Graph Inputs
    
                VertexDescriptionInputs BuildVertexDescriptionInputs(Attributes input)
                {
                    VertexDescriptionInputs output;
                    ZERO_INITIALIZE(VertexDescriptionInputs, output);
                
                    output.ObjectSpaceNormal =           input.normalOS;
                    output.ObjectSpaceTangent =          input.tangentOS.xyz;
                    output.ObjectSpacePosition =         input.positionOS;
                
                    return output;
                }
                
                SurfaceDescriptionInputs BuildSurfaceDescriptionInputs(Varyings input)
                {
                    SurfaceDescriptionInputs output;
                    ZERO_INITIALIZE(SurfaceDescriptionInputs, output);
                
                
                
                
                
                #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
                #define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN output.FaceSign =                    IS_FRONT_VFACE(input.cullFace, true, false);
                #else
                #define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN
                #endif
                #undef BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN
                
                    return output;
                }
                
    
                // --------------------------------------------------
                // Main
    
                #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/ShaderPass.hlsl"
                #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/Varyings.hlsl"
                #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/PBR2DPass.hlsl"
    
                ENDHLSL
            }
        }
        CustomEditor "ShaderGraph.PBRMasterGUI"
        FallBack "Hidden/Shader Graph/FallbackError"
    }