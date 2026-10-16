// Torcida em MultiMesh: cada instância é um quad com uma silhueta (cabeça,
// tronco e braços) desenhada no shader. Pula com "empolgacao".
// INSTANCE_CUSTOM: x = fase, y = tom de pele, z = bandeira (1) ou pessoa (0), w = celular aceso (noite)
shader_type spatial;
render_mode cull_disabled;

uniform float empolgacao = 0.0;
uniform float noite = 0.0;

varying vec3 cor;
varying vec4 extra;

void vertex() {
	cor = COLOR.rgb;
	extra = INSTANCE_CUSTOM;
	float fase = extra.x * 6.2831;
	float pulo = max(0.0, sin(TIME * (6.0 + extra.x * 2.0) + fase));
	VERTEX.y += pulo * (0.03 + empolgacao * 0.32) * (1.0 - extra.z);
	VERTEX.x += sin(TIME * 1.1 + fase * 3.0) * 0.04 * (UV.y < 0.5 ? 1.0 : 0.0);
	if (extra.z > 0.5) {
		// bandeira tremulando
		VERTEX.z += sin(TIME * 4.0 + VERTEX.x * 3.0 + fase) * 0.12 * (1.0 - UV.y);
	}
}

void fragment() {
	vec2 uv = UV;
	vec3 c = cor;
	if (extra.z > 0.5) {
		// bandeira: duas faixas
		c = mix(cor, vec3(1.0), step(0.5, fract(uv.y * 2.0 + 0.25)) * 0.85);
		c *= 0.8 + 0.2 * sin(uv.x * 6.0 + TIME * 4.0);
		ALBEDO = c;
	} else {
		float braco_up = smoothstep(0.35, 0.9, empolgacao) * step(0.45, fract(extra.x * 7.3));
		float cabeca = length((uv - vec2(0.5, 0.2)) * vec2(1.0, 0.9)) - 0.15;
		vec2 q = uv - vec2(0.5, 0.7);
		float tronco = length(max(abs(q) - vec2(0.24, 0.3), 0.0)) - 0.1;
		float b1 = length(max(abs(uv - vec2(0.16, 0.32 - braco_up * 0.22)) - vec2(0.05, 0.12 + braco_up * 0.08), 0.0)) - 0.03;
		float b2 = length(max(abs(uv - vec2(0.84, 0.32 - braco_up * 0.22)) - vec2(0.05, 0.12 + braco_up * 0.08), 0.0)) - 0.03;
		float bracos = braco_up > 0.5 ? min(b1, b2) : 1.0;
		float d = min(min(cabeca, tronco), bracos);
		if (d > 0.0) {
			discard;
		}
		vec3 pele = mix(vec3(0.3, 0.19, 0.12), vec3(0.94, 0.77, 0.62), extra.y);
		bool e_pele = cabeca < 0.0 && uv.y < 0.36 || (bracos < 0.0 && uv.y < 0.22);
		c = e_pele ? pele : cor;
		c *= 0.72 + 0.4 * (1.0 - uv.y);
		ALBEDO = c;
		if (noite > 0.5 && extra.w > 0.5) {
			float flash = 1.0 - smoothstep(0.0, 0.06, length(uv - vec2(0.84, 0.12)));
			EMISSION = vec3(1.0, 0.98, 0.9) * flash * 4.0;
		}
	}
	ROUGHNESS = 1.0;
}
