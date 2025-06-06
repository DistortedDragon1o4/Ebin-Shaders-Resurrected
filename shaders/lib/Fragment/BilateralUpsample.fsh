#if !defined BILATERALUPSAMPLE_FSH
#define BILATERALUPSAMPLE_FSH


void BilateralUpsample(vec3 normal, float depth, out vec4 GI, out vec2 VL) {
	GI = vec4(0.0, 0.0, 0.0, 1.0);
	VL = vec2(1.0);
	
	vec2 scaledCoord = texcoord * COMPOSITE0_SCALE;
	
	float expDepth = ExpToLinearDepth(depth);
	
	cfloat kernel = 2.0;
	cfloat range = kernel * 0.5 - 0.5;
	
	float totalWeight = 0.0;
	
	vec4 samples = vec4(0.0);
	
#if defined GI_ENABLED || defined AO_ENABLED
	if (depth < 1.0) {
		for (float y = -range; y <= range; y++) {
			for (float x = -range; x <= range; x++) {
				vec2 offset = vec2(x, y) * pixelSize;
				
				float sampleDepth  = ExpToLinearDepth(texture(depthtex0, texcoord + offset * 8.0).x);
				vec3  sampleNormal =     DecodeNormal(texture(colortex4, texcoord + offset * 8.0).g, 11);
				
				float weight  = clamp01(1.0 - abs(expDepth - sampleDepth));
					  weight *= abs(dot(normal, sampleNormal)) * 0.5 + 0.5;
					  weight += 0.001;
				
				samples += pow2(texture2DLod(colortex5, scaledCoord + offset * 2.0, 1)) * weight;
				
				totalWeight += weight;
			}
		}
	}
	
	GI = samples / totalWeight;
	GI.rgb *= 10.0;
	
	samples = vec4(0.0);
	totalWeight = 0.0;
#endif
	
#ifdef VL_ENABLED
	for (float y = -range; y <= range; y++) {
		for (float x = -range; x <= range; x++) {
			vec2 offset = vec2(x, y) * pixelSize;
			
			float sampleDepth = ExpToLinearDepth(texture(depthtex0, texcoord + offset * 8.0).x);
			float weight = clamp01(1.0 - abs(expDepth - sampleDepth)) + 0.001;
			
			samples.xy += texture2DLod(colortex6, scaledCoord + offset * 2.0, 3).rg * weight;
			
			totalWeight += weight;
		}
	}
	
	VL = samples.xy / totalWeight;
	VL = pow2(VL);
	// VL = blur13(colortex6, texcoord)
#endif
}

#endif
