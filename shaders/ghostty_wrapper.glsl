#ifdef GL_ES
precision mediump float;
#endif
//Compatible with shadertoy
#define iTime u_time
#define iResolution u_resolution

uniform float u_time;
uniform vec2 u_resolution;
uniform vec4 iCursorCurrent;
uniform vec4 iCursorPrevious;
uniform float iTimeCursorChange;

//$REPLACE$

void main() {
    mainImage(gl_FragColor, gl_FragCoord.xy);
}
