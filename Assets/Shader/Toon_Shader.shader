Shader "Unlit/Outline"
{
    Properties
    {
        _BaseColor("Color",Color) =(1,1,1,1)
        _MainTex ("Texture", 2D) = "white" {}
       
        _Outline("Outline width (view space)",Range(0,5)) = 0.1
        _OutlineColor ("Outline Color",Color) = (0,0,0,1)
        
        [Toggle]_EnableRim("Enable rim",float) = 1
        _F0("fresnel",Vector) = (0.04,0.04,0.04)
        _rimColor("rim color",Color) = (0.5,0.5,0.5,1)
        _rimAttenuation("rim decay",Range(1.0,6.0)) = 5.0 
        [Toggle]_EnableLightMap("Enable Lightmap",float) = 0
        [NoScaleOffset]_LightMapTex("LightMap",2D) = "white" {}
        _ShadowColor("Shadow Color",Color) = (0.5,0.5,0.5)
        _ShadowRange("Shadow Range",Range(0,1)) = 0.5
        _ShadowSmooth("Shadow Smooth",Range(0,1)) = 0.2
        _OffsetY ("lightmap adjustmentY",Range(-1,1)) =0.0
        _angle ("lightmap rotate adjustment",Range(-90,90)) =0.0
       
        [Toggle]_EnablePBR("use pbr texture",float) = 0
        _roughness("roughness",Range(0.0,1.0)) = 0.0
       // _metallic("metallic",Range(0.0,1.0)) = 0.0
        [NoScaleOffset]_metallic("metallic texture for pbr",2D) ="black" {}
        _diffuseEnvScale("diffuse scale",Range(0.0,2.0)) =1.0
        [NoScaleOffset]_irradianceMap("irradiance cubemap for diffuse BRDF",Cube) = "_Skybox"{}
        [NoScaleOffset]_prefilterMap("prefilter cubemap for specular BRDF",Cube) = "_Skybox"{}
        [NoScaleOffset]_brdfLUT("LUT 2d texture",2D) = "white"{}
        //[Toggle]_EnableLocalLight("Enable light",float) = 1
        //_LightDir("light direction",Vector) = (0.0,-1.0,0.0)
        //_ViewDir("fix camera front direction",vector) = (0.0,0.0,-1.0)
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        {
            Tags {"LightMode"="ForwardBase"}
            Name "ForwardLit"
            Cull back
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            // make fog work
            #pragma multi_compile_fog

            #include "UnityCG.cginc"
            #include "Lighting.cginc"
            struct appdata
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float3 worldNomral : TEXCOORD1;
                float3 worldPos : TEXCOORD2;
                UNITY_FOG_COORDS(1)
                float4 vertex : SV_POSITION;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            float4 _ShadowColor;
            float _ShadowRange;
            float _ShadowSmooth;
            float4 _BaseColor;
            float3 _LightDir;
            float3 _ViewDir;
            sampler2D _LightMapTex;
            float _EnableLightMap;
            float _angle;
            float _OffsetY;
            
            float _EnableRim;
            float3 _F0;
            float4 _rimColor;
            float _rimAttenuation;

            float _EnablePBR;
            float _roughness;
           // float _metallic;
            float _diffuseEnvScale;
            samplerCUBE _irradianceMap;
            samplerCUBE _prefilterMap;
            sampler2D _brdfLUT;
           sampler2D _metallic;

            float SoftLightSum(float J,float H)
            {
                if(H>0.5) return J+(2*H-1)*(J-J*J);
                else return J+(2*H-1)*(sqrt(J)-J);
            }
            float3 SoftLight(float3 J,float3 H)
            {
                float r = SoftLightSum(J.r,H.r);
                float g = SoftLightSum(J.g,H.g);
                float b = SoftLightSum(J.b,H.b);
                return float3(r,g,b);
            }
            float3 ColorMix(float3 J,float3 H)
            {
                return J + J * H/(1-H);
            }

            float3 Fresnel_Schlick(float NdotV,float3 F0)
            {
                return F0 + (1-F0)*pow(1-NdotV,_rimAttenuation);
            }

            float D_GTR2(float NdotH,float r){
	            float a=r*r;
	            float a2=a*a;
	            float cos2=NdotH*NdotH;
	            float den=1.0+(a2-1.0)*cos2;
	            return a2/max(3.1415926*den*den,0.001);
            }
            float smithG_GGX_disney(float NdotV,float roughness){
		        float alpha=(0.5+roughness/2)*(0.5+roughness/2);
		        float a=alpha*alpha;
		        float b=NdotV*NdotV;
		        return 2*NdotV/(NdotV+sqrt(a+b-a*b));
            }
            float GeometrySmith(float3 N,float3 V,float L,float alpha){
		            float NdotV=max(dot(N,V),0.0);
		            float NdotL=max(dot(N,L),0.0);
	            //	float ggx1=smithG_GGX(NdotV,alpha);
	            //	float ggx2=smithG_GGX(NdotL,alpha);
		            float ggx1=smithG_GGX_disney(NdotV,alpha);
		            float ggx2=smithG_GGX_disney(NdotL,alpha);
		            return ggx1*ggx2;
            }
            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.worldPos = mul(unity_ObjectToWorld,v.vertex);
                o.worldNomral = normalize(UnityObjectToWorldNormal(v.normal));
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                UNITY_TRANSFER_FOG(o,o.vertex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                // sample the texture
                fixed4 col = tex2D(_MainTex, i.uv);
                float3 viewDir = normalize(_WorldSpaceCameraPos.xyz - i.worldPos.xyz);
                float3 lightDir = normalize(UnityWorldSpaceLightDir(i.worldPos));
                float3 halfDir = normalize(viewDir+lightDir);
                half3 diffuse=float3(1.0,1.0,1.0);
                if(_EnableLightMap){
                   
                    float3 front = unity_ObjectToWorld._m02_m12_m22;
	                float3 right = unity_ObjectToWorld._m00_m10_m20;
                    float3 up =unity_ObjectToWorld._m01_m11_m21;
                  
                    float3 ProjectionToXZ = normalize(lightDir-up * dot(lightDir,up));//projection to XZ plane in object space
                    
                    float4 ProjectionToXZInObject = mul(unity_WorldToObject,float4(ProjectionToXZ,0.0));
                    float4x4 rotationMatrix;
                    float c = cos(radians(_angle));
                    float s = sin(radians(_angle));
                    rotationMatrix[0]=float4(c,0,-s,0);
                    rotationMatrix[1]=float4(0,1,0,0);
                    rotationMatrix[2]=float4(s,0,c,0);
                    rotationMatrix[3]=float4(0,0,0,1);
                    float3 ProjectionToXZAfterRotation = mul(rotationMatrix,ProjectionToXZInObject);
                    ProjectionToXZ = mul(unity_ObjectToWorld,ProjectionToXZAfterRotation);
	                float FrontLight = dot(normalize(front),ProjectionToXZ);
                    float RightLight = dot(normalize(right),ProjectionToXZ);
                    
                    i.uv.y += _OffsetY;
                    float3 lightMap = RightLight < 0 ? tex2D(_LightMapTex,i.uv) : tex2D(_LightMapTex,float2(1.0-i.uv.x,i.uv.y));
                    
                    float shadowMask = (lightMap.r  > 0.5 - 0.5 * FrontLight);//math derived
       
         

                    diffuse = lerp(_ShadowColor*col,col,shadowMask);
                }
                else{
                     float halfLambert = 0.5 * dot(lightDir,i.worldNomral) +0.5;
                     half ramp = smoothstep(0, _ShadowSmooth, halfLambert - _ShadowRange);
                     diffuse = lerp(_ShadowColor*col,col, ramp);
                }
                float NdotV = saturate(dot(i.worldNomral,viewDir));
                float NdotL = dot(i.worldNomral,lightDir);
                float NdotH = dot(i.worldNomral,halfDir);
                float metallic = tex2D(_metallic,i.uv);
               //float metallic = _metallic;
                float3 F0 = _EnablePBR ? lerp(_F0,col.rgb,metallic) : _F0;
                float3 rim = (NdotL+1)/2  * _rimColor * Fresnel_Schlick(NdotV,F0);
                diffuse = _EnablePBR ? (1-metallic) * diffuse : diffuse;
                float3 result = _EnableRim ? diffuse + rim : diffuse;
                //float D = D_GTR2(NdotH,_roughness);
                //float G = GeometrySmith(i.worldNomral,viewDir,lightDir,_roughness);
                float3 F = Fresnel_Schlick(NdotV,F0);
                //float denominator = 4.0 * NdotV * NdotL;
                //float3 specular = D*G*F/max(denominator,0.001);
                //specular = specular/(specular+1.0);
                float3 R = reflect(-viewDir,i.worldNomral);
                float3 prefilteredColor = texCUBE(_prefilterMap, R).rgb; 
	            float2 envBRDF  = tex2D(_brdfLUT, float2(max(dot(i.worldNomral, viewDir), 0.0), _roughness)).rg;
	     
	
	            float3 irradiance=texCUBE(_irradianceMap,i.worldNomral).rgb;
               // result = _EnablePBR ? result + specular :result;
                if(_EnablePBR){
                float3 diffuseEnv = _diffuseEnvScale* (1.0-F)*(1-metallic)*irradiance*col*3.1415926;
                float3 specularEnv =  prefilteredColor *(F * envBRDF.x + envBRDF.y);
                result =max(result,diffuseEnv);
                result += metallic*(specularEnv);
                //result = result/(1+result);
                //result =pow(result,1/2.2);
               }
                // apply fog
                
                return fixed4(result,1.0);
                //return fixed4(1,1,1,1);
            }
            ENDCG
        }
        Pass
        {
            Name "Outline"
            Cull Front
             CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"
            float _Outline;
            half4 _OutlineColor;
            sampler2D _MainTex;
            float4 _MainTex_ST;
         
            struct appdata
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                float4 color  : COLOR;
                float2 uv   : TEXCOORD0;
                float3 tangent : TANGENT;
            };

            struct v2f
            {
                float3 color :COLOR1;
                float2 uv   :TEXCOORD0;
                float4 vertex : SV_POSITION;
            };

            float GetCameraFOV()
            {
                //https://answers.unity.com/questions/770838/how-can-i-extract-the-fov-information-from-the-pro.html
                float t = unity_CameraProjection._m11;
                //float Rad2Deg = 180 / 3.1415;
                float fov = atan(1.0f / t) * 2.0;
                return fov;
            }
            float ApplyOutlineDistanceFadeOut(float inputMulFix)
            {
                //make outline "fadeout" if character is too small in camera's view
                return (1/inputMulFix-1/_ProjectionParams.y)/(_ProjectionParams.w-1/_ProjectionParams.y);
            }
            float GetOutlineCameraFovAndDistanceFixMultiplier(float positionVS_Z)
            {
                float cameraMulFix;
                if(unity_OrthoParams.w == 0)
                {
                    ////////////////////////////////
                    // Perspective camera case
                    ////////////////////////////////

                    // keep outline similar width on screen accoss all camera distance       
                  //  cameraMulFix = abs(positionVS_Z);

                    // can replace to a tonemap function if a smooth stop is needed
                    cameraMulFix = ApplyOutlineDistanceFadeOut(positionVS_Z);

                    // keep outline similar width on screen accoss all camera fov
                    cameraMulFix *= GetCameraFOV();       
                }
                else
                {
                    ////////////////////////////////
                    // Orthographic camera case
                    ////////////////////////////////
                    float orthoSize = abs(unity_OrthoParams.y);
                    orthoSize = ApplyOutlineDistanceFadeOut(orthoSize);
                    cameraMulFix = orthoSize * 50; // 50 is a magic number to match perspective camera's outline width
                }

                return cameraMulFix * 0.01; // mul a const to make return result = default normal expand amount WS
             }
            v2f vert (appdata v)
            {
                v2f o;
                //float4 viewPos= mul(UNITY_MATRIX_MV,v.vertex);
                //float3 viewNormal = mul(UNITY_MATRIX_MV,v.normal) -0.5;
                //viewPos = viewPos + float4(normalize(viewNormal),0.0) * _Outline;
                //o.vertex = mul(UNITY_MATRIX_P,viewPos);
                o.vertex = UnityObjectToClipPos(v.vertex);
                float3 viewPos = UnityObjectToViewPos(v.vertex.xyz);
                float3 viewNormal =  mul((float3x3)UNITY_MATRIX_IT_MV, v.normal.xyz);
                float3 clipNormal = normalize(TransformViewToProjection(viewNormal.xyz));
                float2 extension = normalize(clipNormal).xy;

                float4 nearPlaneUpRight = mul(unity_CameraInvProjection,float4(1,1,0,1));
                float aspect = nearPlaneUpRight.y / nearPlaneUpRight.x;
                extension.x *= aspect;
                o.vertex.xy += extension * _Outline * GetOutlineCameraFovAndDistanceFixMultiplier(viewPos.z) * v.color.a * o.vertex.w;
                o.color = v.color.rgb;
                o.uv = TRANSFORM_TEX(v.uv,_MainTex);
                
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                fixed4 col = tex2D(_MainTex, i.uv);
                return fixed4(_OutlineColor.rgb * i.color,1.0) * col;
            }
            ENDCG
        }
        
    }
    FallBack "Specular"
}
