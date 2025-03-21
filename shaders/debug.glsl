// #version 430 core

#ifdef GL_ES
precision mediump float;
#endif

// uniform float u_time;
// uniform vec2 u_resolution;
// uniform vec3 iColor;
uniform vec3 iMagia;
void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    // vec2 iResolution = u_resolution;
    //
    // vec2 p = fragCoord / iResolution.x;
    //
    // vec4 current = vec4(0.2, 0.2, 10., 20.);
    // vec4 previous = vec4(.8, .8, 10., 20.);
    //
    // // Adjust coordinates based on aspect ratio
    // // current.x *= iResolution.x / iResolution.y;
    // previous.y *= iResolution.y / iResolution.x;
    // current.y *= iResolution.y / iResolution.x;
    //
    // vec3 col = vec3(0.);
    //
    // float d = distanceToSegment(previous.xy, abs(current.xy), p);
    // col = mix(col, vec3(1.0, 7.0, 0.0), 1.0 - smoothstep(.004, 0.058, d));
    //
    // col = mix(col, vec3(1.0, 0.0, 0.0), 1.0 - smoothstep(0.03, 0.035, length(p - previous.xy)));
    // col = mix(col, vec3(0.0, 0.0, 1.0), 1.0 - smoothstep(0.03, 0.035, length(p - abs(current.xy))));
    //
    // float alphaDistance = distance(p.xy, previous.xy) * 10.;
    // float alpha = abs(sin(iTime)) * alphaDistance;
    //
    // fragColor = mix(vec4(col, 1.0), fragColor, alpha);
    // fragColor = vec4(col, 1.0);
    if (fragCoord.x < 150. && fragCoord.y < 150.) {
        fragColor = vec4(iMagia, 1);
    }
    if (fragCoord.x > 150. && fragCoord.y > 150.) {
        fragColor = vec4(0., 1., 0., 1);
    }
}
void main() {
    mainImage(gl_FragColor, gl_FragCoord.xy);
}
