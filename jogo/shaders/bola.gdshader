// Bola com gomos (pentágonos nos 12 vértices de um icosaedro).
shader_type spatial;

uniform vec3 cor_base : source_color = vec3(0.9, 0.9, 0.9);
uniform vec3 cor_gomo : source_color = vec3(0.07, 0.07, 0.09);

varying vec3 local;

void vertex() {
	local = normalize(VERTEX);
}

void fragment() {
	const float phi = 1.618034;
	vec3 v[12] = vec3[](vec3(-1.0, phi, 0.0), vec3(1.0, phi, 0.0), vec3(-1.0, -phi, 0.0), vec3(1.0, -phi, 0.0),
		vec3(0.0, -1.0, phi), vec3(0.0, 1.0, phi), vec3(0.0, -1.0, -phi), vec3(0.0, 1.0, -phi),
		vec3(phi, 0.0, -1.0), vec3(phi, 0.0, 1.0), vec3(-phi, 0.0, -1.0), vec3(-phi, 0.0, 1.0));
	float m1 = -1.0;
	float m2 = -1.0;
	for (int i = 0; i < 12; i++) {
		float d = dot(local, normalize(v[i]));
		if (d > m1) {
			m2 = m1;
			m1 = d;
		} else if (d > m2) {
			m2 = d;
		}
	}
	float pent = smoothstep(0.92, 0.93, m1);
	float costura = 1.0 - smoothstep(0.0, 0.012, m1 - m2);
	vec3 c = mix(cor_base, cor_gomo, pent);
	c = mix(c, c * 0.55, costura * (1.0 - pent));
	ALBEDO = c;
	ROUGHNESS = 0.35;
	SPECULAR = 0.6;
}
