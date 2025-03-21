// Created by inigo quilez - iq/2013
// https://www.youtube.com/c/InigoQuilez
// https://iquilezles.org/

// Shows how to use the mouse input (only left button supported):
//
//      mouse.xy  = mouse position during last button down
//  abs(mouse.zw) = mouse position during last button click
// sign(mouze.z)  = button is down
// sign(mouze.w)  = button is clicked

// See also:
//
// Input - Keyboard    : https://www.shadertoy.com/view/lsXGzf
// Input - Microphone  : https://www.shadertoy.com/view/llSGDh
// Input - Mouse       : https://www.shadertoy.com/view/Mss3zH
// Input - Sound       : https://www.shadertoy.com/view/Xds3Rr
// Input - SoundCloud  : https://www.shadertoy.com/view/MsdGzn
// Input - Time        : https://www.shadertoy.com/view/lsXGz8
// Input - TimeDelta   : https://www.shadertoy.com/view/lsKGWV
// Inout - 3D Texture  : https://www.shadertoy.com/view/4llcR4

float distanceToSegment(vec2 a, vec2 b, vec2 p)
{
    vec2 pa = p - a, ba = b - a;
    float h = clamp(dot(pa, ba) / dot(ba, ba), 0.0, 1.0);
    return length(pa - ba * h);
}

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    vec2 p = fragCoord / iResolution.x;
    vec2 cen = 0.5 * iResolution.xy / iResolution.x;
    //vec4 m = iMouse / iResolution.x;

    vec4 current = vec4(.125, .1, 10, 20);
    vec4 previous = vec4(.75, .35, 10, 20);

    vec3 col = vec3(0.0);

    float d = distanceToSegment(previous.xy, abs(current.xy), p);
    col = mix(col, vec3(1.0, 7.0, 0.0), 1.0 - smoothstep(.004, 0.058, d));

    col = mix(col, vec3(1.0, 0.0, 0.0), 1.0 - smoothstep(0.03, 0.035, length(p - previous.xy)));
    col = mix(col, vec3(0.0, 0.0, 1.0), 1.0 - smoothstep(0.03, 0.035, length(p - abs(current.xy))));

    float alphaDistance = distance(p.xy, previous.xy) * 10.;
    float alpha = abs(sin(iTime)) * alphaDistance;

    fragColor = mix(vec4(col, 1.0), fragColor, alpha);
    //fragColor = vec4( col, 1.0 );
}
