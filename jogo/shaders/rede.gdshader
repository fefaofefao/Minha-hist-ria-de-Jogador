// Rede do gol em losangos, com ondulação quando a bola entra.
shader_type spatial;
render_mode cull_disabled;

uniform vec3 cor_rede : source_color = vec3(0.95, 0.95, 0.95);
uniform vec2 malhas = vec2(46.0, 16.0);
uniform vec3 impacto = vec3(0.0, 1.2, -40.0);
uniform float tempo_impacto = 10.0; // segundos desde o impacto
uniform float buracos = 0.0; // rede rasgada (várzea)

varying vec3 mundo;

float hash(vec2 p) { return fract(sin(dot(p, vec2(41.3, 289.1))) * 43758.5453); }

void vertex() {
	mundo = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	float t = tempo_impacto;
	if (t < 2.5) {
		float dist = distance(mundo, impacto);
		float onda = exp(-dist * 0.9) * exp(-t * 2.6) * sin(t * 16.0 - dist * 3.5);
		VERTEX += NORMAL * onda * 0.45;
	}
}

void fragment() {
	vec2 uv = UV * malhas;
	uv = vec2(uv.x + uv.y, uv.x - uv.y) * 0.7071;
	vec2 f = abs(fract(uv) - 0.5);
	float fio = smoothstep(0.38, 0.47, max(f.x, f.y));
	if (buracos > 0.0 && hash(floor(UV * 6.0)) < buracos) {
		fio = 0.0;
	}
	if (fio < 0.5) {
		discard;
	}
	ALBEDO = cor_rede;
	ROUGHNESS = 0.8;
}
