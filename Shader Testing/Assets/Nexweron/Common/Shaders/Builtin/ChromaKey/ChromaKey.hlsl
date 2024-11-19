// Smallest positive number, such that 1.0 + FLT_EPSILON != 1.0
#ifndef FLT_EPSILON
#define FLT_EPSILON 1.192092896e-07 
#endif

// RGB/YCbCr
half3 RGBToYCbCr(half3 rgb) {
    half Y = 0.299 * rgb.r + 0.587 * rgb.g + 0.114 * rgb.b;
    half Cb = 0.564 * (rgb.b - Y);
    half Cr = 0.713 * (rgb.r - Y);
    //Cb is Blue difference chroma, difference between blue channel and luminance
    //Cr same for red
    //Y is luminance
    //green is derived from red and blue
    return half3(Cb, Cr, Y);
}

half3 YCbCrToRGB(half3 YCbCr) {
    half R = YCbCr.z + 1.402 * YCbCr.y;
    half G = YCbCr.z - 0.334 * YCbCr.x - 0.714 * YCbCr.y;
    half B = YCbCr.z + 1.772 * YCbCr.x;
    return half3(R, G, B);
}

// RGB/YIQ
half3 RGBToYIQ(half3 rgb) {
    half Y = 0.299 * rgb.r + 0.587 * rgb.g + 0.114 * rgb.b;
    half I = 0.595716 * rgb.r - 0.274453 * rgb.g - 0.321263 * rgb.b;
    half Q = 0.211456 * rgb.r - 0.522591 * rgb.g + 0.311135 * rgb.b;
    //I is related to color info related to red and yellow
    //Q is Color info related to Blue and Yellow
    //Y is luma (brightness)
    return half3(I, Q, Y);
}

// Lerp
half2 lerp3_2(half2 A, half2 B, half2 C, half v) {
    return v < 0.5 ? lerp(A, B, 2*v) : lerp(B, C, 2*(v-0.5));
}
half lerp3_1(half A, half B, half C, half v) {
    return v < 0.5 ? lerp(A, B, 2 * v) : lerp(B, C, 2 * (v - 0.5));
}

// ChromaKey Alpha
half4 GetChromaKeyAlpha(half4 baseRGBA, half3 src, half3 key, half dChroma, half dChromaT, half dLuma, half dLumaT) {
    half4 c = baseRGBA;
    //get distance from color in source image to key color.
    //we only use xy, because those store the color values, while z stores the luminance
    half deltaChroma = distance(src.xy, key.xy);
    //distance from source to key in luminance
    half deltaLuma = distance(src.z, key.z);
	
    //if the color at the pixel is in range of both the chroma and the luma, change it
    if (deltaChroma < dChroma && deltaLuma < dLuma) {
        half a = 0;
        //if it close to the threshold, defined by dChromaT
        if (deltaChroma > dChroma - dChromaT) {
            a = (deltaChroma - dChroma + dChromaT) / dChromaT;
        }
        //same for luma
        if (deltaLuma > dLuma - dLumaT) {
            a = max(a, (deltaLuma - dLuma + dLumaT) / dLumaT);
        }
        //if this made it brighter for some reason, revert to original
        c.a = min(a, c.a);
    }
    return c;
}

half4 ApplyChromaKeyAlphaYCbCr(half4 baseRGBA, half3 keyRGB, half dChroma, half dChromaT, half dLuma, half dLumaT) {
    half3 src = RGBToYCbCr(baseRGBA.rgb);
    half3 key = RGBToYCbCr(keyRGB.rgb);
    
    return GetChromaKeyAlpha(baseRGBA, src, key, dChroma, dChromaT, dLuma, dLumaT);
}

half4 ApplyChromaKeyAlphaYIQ(half4 baseRGBA, half3 keyRGB, half dChroma, half dChromaT, half dLuma, half dLumaT) {
    half3 src = RGBToYIQ(baseRGBA.rgb);
    half3 key = RGBToYIQ(keyRGB.rgb);
    
    return GetChromaKeyAlpha(baseRGBA, src, key, dChroma, dChromaT, dLuma, dLumaT);
}

// ChromaKey Bg
half4 GetChromaKeyBg(half4 baseRGB, half4 bgRGBA, half3 src, half3 key, half3 bg, half dChroma, half dChromaT, half chroma, half luma, half saturation, half alpha) {
    half4 c = baseRGB;
    half deltaChroma = distance(src.xy, key.xy);
    
    if (deltaChroma < dChroma) {
        half a = 0;
        c.rgb = bgRGBA.rgb;
        if (deltaChroma > dChroma - dChromaT) {
            a = (deltaChroma - dChroma + dChromaT) / dChromaT;
            half2 cbg = lerp(src.xy, bg.xy, 1 - a);
            half2 ct = lerp3_2(src.xy, cbg, bg.xy, chroma);

            half sa = length(cbg) + FLT_EPSILON;
            half s = lerp(0, sa, saturation);
            ct *= s / sa;

            half la = lerp(src.z, bg.z, 1 - a);
            half l = lerp3_1(src.z, la, bg.z, luma);

            c.rgb = YCbCrToRGB(half3(ct.x, ct.y, l));
        }
        a = lerp(a, c.a, alpha);
        if (c.a > a) {
            c.a = a;
        }
    }
    return c;
}

half4 ApplyChromaKeyBgYCbCr(half4 baseRGBA, half3 keyRGB, half4 bgRGBA, half dChroma, half dChromaT, half chroma, half luma, half saturation, half alpha) {
    half3 src = RGBToYCbCr(baseRGBA.rgb);
    half3 key = RGBToYCbCr(keyRGB.rgb);
    half3 bg = RGBToYCbCr(bgRGBA.rgb);
    
    return GetChromaKeyBg(baseRGBA, bgRGBA, src, key, bg, dChroma, dChromaT, chroma, luma, saturation, alpha);
}