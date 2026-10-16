// Céu procedural: degradê, sol com halo, nuvens e estrelas à noite.
shader_type sky;
#include "res://shaders/ruido.gdshaderinc"

uniform vec3 topo : source_color = vec3(0.18, 0.4, 0.82);
uniform vec3 horizonte : source_color = vec3(0.72, 0.84, 0.96);
uniform vec3 chao : source_color = vec3(0.25, 0.27, 0.3);
uniform vec3 cor_sol : source_color = vec3(1.0, 0.93, 0.78);
uniform float nuvens = 0.55;
uniform float noite = 0.0;

void sky() {
	float y = EYEDIR.y;
	vec3 c = mix(horizonte, topo, smoothstep(-0.02, 0.55, y));
	c = mix(c, chao, smoothstep(0.0, -0.25, y));
	float sol = max(dot(EYEDIR, LIGHT0_DIRECTION), 0.0);
	c += cor_sol * (pow(sol, 1400.0) * 8.0 + pow(sol, 18.0) * 0.45 + pow(sol, 4.0) * 0.12) * (1.0 - noite);
	if (y > 0.0) {
		vec2 p = EYEDIR.xz / (y + 0.12) * 0.9 + vec2(TIME * 0.004, TIME * 0.002);
		float n = fbm(p);
		float m = smoothstep(0.48, 0.78, n) * nuvens * smoothstep(0.0, 0.2, y);
		vec3 cor_nuvem = mix(vec3(1.0, 0.98, 0.96), horizonte * 1.05, 0.25) * mix(1.0, 0.12, noite);
		cor_nuvem += cor_sol * pow(sol, 6.0) * 0.4 * (1.0 - noite);
		c = mix(c, cor_nuvem, m * 0.85);
		if (noite > 0.5) {
			vec3 d = EYEDIR * 320.0;
			float s = step(0.9965, hash31(floor(d)));
			c += vec3(s) * 0.9 * smoothstep(0.08, 0.3, y) * (1.0 - m);
		}
	}
	COLOR = c;
}
