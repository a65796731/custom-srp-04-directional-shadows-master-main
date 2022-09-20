#ifndef CUSTOM_META_PASS_INCLUDED
#define CUSTOM_META_PASS_INCLUDED

#include "../ShaderLibrary/Surface.hlsl"
#include "../ShaderLibrary/Shadow.hlsl"
#include "../ShaderLibrary/Light.hlsl"
#include "../ShaderLibrary/BRDF.hlsl"


struct Attributes {
	
    float3 positionOs : POSITIONT;
    float2 baseUV : TEXCOORD0;
};

struct Varyings {

    float3 positionCs : SV_POSITIONT;
    float2 baseUV : TEXCOORD0;
};

Varyings MetaPassVertex (Attributes input) {
	Varyings output;
	UNITY_SETUP_INSTANCE_ID(input);
	UNITY_TRANSFER_INSTANCE_ID(input, output);
	TRANSFER_GI_DATA(input,output);
	output.positionWS = TransformObjectToWorld(input.positionOS);
	output.positionCS = TransformWorldToHClip(output.positionWS);
	output.normalWS = TransformObjectToWorldNormal(input.normalOS);
    
 
    output.baseUV = TransformBaseUV(input.baseUV);
	return output;
}

float4 MetaPassFragment(Varyings input) : SV_TARGET
{
	UNITY_SETUP_INSTANCE_ID(input);

    float4 base = GetBase(input.baseUV);
	#if defined(_CLIPPING)
		clip(base.a - GetCutoff(input.baseUV));
	#endif

	Surface surface;
	surface.position = input.positionWS;
	surface.normal = normalize(input.normalWS);
	surface.viewDirection = normalize(_WorldSpaceCameraPos - input.positionWS);
	surface.depth = -TransformWorldToView(input.positionWS).z;
	surface.color = base.rgb;
	surface.alpha = base.a;
    surface.metallic = GetMetallic(input.baseUV);
    surface.smoothness = GetSmoothness(input.baseUV);
		UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, _Smoothness);
	surface.dither = InterleavedGradientNoise(input.positionCS.xy, 0);
	#if defined(_PREMULTIPLY_ALPHA)
		BRDF brdf = GetBRDF(surface, true);
	#else
		BRDF brdf = GetBRDF(surface);
	#endif
	
	GI gi=GetGI(surface,GI_FRAGMENT_DATA(input));
	float3 color = GetLighting(surface, brdf,gi);
	return float4(color, surface.alpha);
}

#endif