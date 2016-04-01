//
//  AccImageFilterShaders.metal
//  MetalAcc
//
//  Created by 王佳玮 on 16/3/30.
//  Copyright © 2016年 JW. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;


/*
 Values from GPUImage(https://github.com/BradLarson/GPUImage)
*/
kernel void Pixelate(texture2d<float, access::read> inTexture [[texture(0)]],
					 texture2d<float, access::write> outTexture [[texture(1)]],
					 device unsigned int *pixelSize [[buffer(0)]],
					 uint2 gid [[thread_position_in_grid]])
{
	const uint2 pixellateGrid = uint2((gid.x / pixelSize[0]) * pixelSize[0], (gid.y / pixelSize[0]) * pixelSize[0]);
	const float4 colorAtPixel = inTexture.read(pixellateGrid);
	outTexture.write(colorAtPixel, gid);
}


kernel void Grayscale(texture2d<float, access::read> inTexture [[texture(0)]],
                              texture2d<float, access::write> outTexture [[texture(1)]],
                              device float *factor [[buffer(0)]],
                              uint2 gid [[thread_position_in_grid]])
{
    float4 inColor = inTexture.read(gid);
    float value = dot(inColor.rgb, float3(0.299, 0.587, 0.114));
    float4 grayColor(value, value, value, inColor.w);
    float4 outColor = mix(grayColor, inColor, *factor);
    outTexture.write(outColor, gid);
}


kernel void Brightness(texture2d<float, access::read> inTexture [[texture(0)]],
                      texture2d<float, access::write> outTexture [[texture(1)]],
                      device float *factor [[buffer(0)]],
                      uint2 gid [[thread_position_in_grid]])
{
    float4 inColor = inTexture.read(gid);
    float4 outColor(inColor.r + *factor,
                    inColor.g + *factor,
                    inColor.b + *factor,
                    inColor.w);
    outTexture.write(outColor, gid);
}

kernel void Saturation(texture2d<float, access::read> inTexture [[texture(0)]],
                       texture2d<float, access::write> outTexture [[texture(1)]],
                       device float *factor [[buffer(0)]],
                       uint2 gid [[thread_position_in_grid]])
{
    float4 inColor = inTexture.read(gid);
    float value = dot(inColor.rgb, float3(0.2125, 0.7154, 0.0721));
    float4 grayColor(value, value, value, 1.0);
    float4 outColor = mix(grayColor, inColor, *factor);
    outTexture.write(outColor, gid);
}

kernel void Gamma(texture2d<float, access::read> inTexture [[texture(0)]],
                  texture2d<float, access::write> outTexture [[texture(1)]],
                  device float *factor [[buffer(0)]],
                  uint2 gid [[thread_position_in_grid]])
{
    float4 inColor = inTexture.read(gid);
    float4 outColor(pow(inColor.r,*factor),
                    pow(inColor.g,*factor),
                    pow(inColor.b,*factor),
                    inColor.w);

    outTexture.write(outColor, gid);
}

kernel void ColorInvert(texture2d<float, access::read> inTexture [[texture(0)]],
                        texture2d<float, access::write> outTexture [[texture(1)]],
                        uint2 gid [[thread_position_in_grid]])
{
    float4 inColor = inTexture.read(gid);
    float4 outColor(1.0 - inColor.r,
                    1.0 - inColor.g,
                    1.0 - inColor.b,
                    inColor.w);
    
    outTexture.write(outColor, gid);
}

kernel void Contrast(texture2d<float, access::read> inTexture [[texture(0)]],
                        texture2d<float, access::write> outTexture [[texture(1)]],
                     device float *factor [[buffer(0)]],
                        uint2 gid [[thread_position_in_grid]])
{
    float4 inColor = inTexture.read(gid);
    float4 outColor((inColor.r - 0.5) * (*factor + 0.5),
                    (inColor.g - 0.5) * (*factor + 0.5),
                    (inColor.b - 0.5) * (*factor + 0.5),
                    inColor.w);
    
    outTexture.write(outColor, gid);
}

kernel void Exposure(texture2d<float, access::read> inTexture [[texture(0)]],
                     texture2d<float, access::write> outTexture [[texture(1)]],
                     device float *factor [[buffer(0)]],
                     uint2 gid [[thread_position_in_grid]])
{
    float4 inColor = inTexture.read(gid);
    float4 outColor(inColor.r * pow(2.0, *factor),
                    inColor.g * pow(2.0, *factor),
                    inColor.b * pow(2.0, *factor),
                    inColor.w);
    
    outTexture.write(outColor, gid);
}

kernel void LuminanceThreshold(texture2d<float, access::read> inTexture [[texture(0)]],
                      texture2d<float, access::write> outTexture [[texture(1)]],
                      device float *factor [[buffer(0)]],
                      uint2 gid [[thread_position_in_grid]])
{
    float4 inColor = inTexture.read(gid);
    float luminance = dot(inColor.rgb, float3(0.2125, 0.7154, 0.0721));
    float thresholdResult = step(*factor,luminance);
    float4 outColor = float4(float3(thresholdResult),inColor.w);
    outTexture.write(outColor, gid);
}


kernel void LuminanceRange(texture2d<float, access::read> inTexture [[texture(0)]],
                               texture2d<float, access::write> outTexture [[texture(1)]],
                               device float *factor [[buffer(0)]],
                               uint2 gid [[thread_position_in_grid]])
{
    float4 inColor = inTexture.read(gid);
    float luminance = dot(inColor.rgb, float3(0.2125, 0.7154, 0.0721));
    float luminanceRatio = ((0.5 - luminance) * *factor);
    float4 outColor = float4(float3(inColor.rgb+luminanceRatio),inColor.w);
    outTexture.write(outColor, gid);
}

kernel void WhiteBalance(texture2d<float, access::read> inTexture [[texture(0)]],
                           texture2d<float, access::write> outTexture [[texture(1)]],
                           device float *temperature [[buffer(0)]],
                         device float *tint [[buffer(1)]],
                           uint2 gid [[thread_position_in_grid]])
{
    const float3 warmFilter = float3(0.93, 0.54, 0.0);
    const float3x3 RGBtoYIQ = float3x3(float3(0.299, 0.587, 0.114),
                                 float3(0.596, -0.274, -0.322),
                                 float3(0.212, -0.523, 0.311));
    const float3x3 YIQtoRGB = float3x3(float3(1.0, 0.956, 0.621),
                                 float3(1.0, -0.272, -0.647),
                                 float3(1.0, -1.105, 1.702));
    
    float4 inColor = inTexture.read(gid);
    float3 yiq = RGBtoYIQ * inColor.rgb;
    yiq.b = clamp(yiq.b + *tint * 0.5226 * 0.1, -0.5226, 0.5226);
    float3 rgb = YIQtoRGB * yiq;
    
    float3 processed = float3(
                               (rgb.r < 0.5 ? (2.0 * rgb.r * warmFilter.r) : (1.0 - 2.0 * (1.0 - rgb.r) * (1.0 - warmFilter.r))), //adjusting temperature
                               (rgb.g < 0.5 ? (2.0 * rgb.g * warmFilter.g) : (1.0 - 2.0 * (1.0 - rgb.g) * (1.0 - warmFilter.g))),
                               (rgb.b < 0.5 ? (2.0 * rgb.b * warmFilter.b) : (1.0 - 2.0 * (1.0 - rgb.b) * (1.0 - warmFilter.b))));
    
    float4 outColor = float4(mix(rgb, processed, *temperature), inColor.a);
    outTexture.write(outColor, gid);
}

kernel void ChromaKey(texture2d<float, access::read> inTexture [[texture(0)]],
                      texture2d<float, access::write> outTexture [[texture(1)]],
                      device float *thresholdSensitivity [[buffer(0)]],
                      device float *smoothing [[buffer(1)]],
                      device float *R [[buffer(2)]],
                      device float *G [[buffer(3)]],
                      device float *B [[buffer(4)]],
                      uint2 gid [[thread_position_in_grid]])
{
    float3 colorToReplace = float3(*R,*G,*B);
    float maskY = 0.2989 * colorToReplace.r + 0.5866 * colorToReplace.g + 0.1145 * colorToReplace.b;
    float maskCr = 0.7132 * (colorToReplace.r - maskY);
    float maskCb = 0.5647 * (colorToReplace.b - maskY);
    float4 inColor = inTexture.read(gid);
    float Y = 0.2989 * inColor.r + 0.5866 * inColor.g + 0.1145 * inColor.b;
    float Cr = 0.7132 * (inColor.r - Y);
    float Cb = 0.5647 * (inColor.b - Y);
    float blendValue = smoothstep(*thresholdSensitivity, *thresholdSensitivity + *smoothing, distance(float2(Cr, Cb),float2(maskCr, maskCb)));
    float4 outColor = float4(inColor.rgb,inColor.a * blendValue);
    outTexture.write(outColor, gid);
}

kernel void SolidColor(texture2d<float, access::read> inTexture [[texture(0)]],
                      texture2d<float, access::write> outTexture [[texture(1)]],
                      device float *R [[buffer(0)]],
                      device float *G [[buffer(1)]],
                      device float *B [[buffer(2)]],
                      device float *A [[buffer(3)]],
                      uint2 gid [[thread_position_in_grid]])
{
    float4 outColor = float4(*R,*G,*B,*A);
    outTexture.write(outColor, gid);
}
