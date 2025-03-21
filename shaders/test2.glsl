#ifdef GL_ES
precision mediump float;
#endif

uniform float u_time;
uniform vec2 u_resolution;
uniform vec3 iMagia;

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    fragColor = vec4(iMagia, abs(sin(u_time)));
}

void main() {
    mainImage(gl_FragColor, gl_FragCoord.xy);
}
