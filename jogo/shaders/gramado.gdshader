// Gramado (ou terra) do campo com listras de corte, desgaste e linhas
// desenhadas por SDF (nítidas em qualquer resolução).
shader_type spatial;
#include "res://shaders/ruido.gdshaderinc"

uniform int modo = 0; // 0 = grama, 1 = terra (várzea)
uniform vec3 grama_a : source_color = vec3(0.105, 0.33, 0.09);
uniform vec3 grama_b : source_color = vec3(0.15, 0.42, 0.12);
uniform vec3 grama_fora : source_color = vec3(0.11, 0.30, 0.10);
uniform vec3 terra_a : source_color = vec3(0.56, 0.38, 0.24);
uniform vec3 terra_b : source_color = vec3(0.42, 0.28, 0.17);
uniform vec3 cor_linha : source_color = vec3(0.96, 0.96, 0.93);
uniform float largura_linha = 0.12;
uniform float desgaste = 0.6;
uniform float xadrez = 0.0; // listras cruzadas (estádio)

varying vec3 mundo;

void vertex() {
	mundo = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

float sd_caixa(vec2 p, vec2 b) {
	vec2 d = abs(p) - b;
	return length(max(d, 0.0)) + min(max(d.x, d.y), 0.0);
}

float seg(vec2 p, vec2 a, vec2 b) {
	vec2 pa = p - a;
	vec2 ba = b - a;
	float h = clamp(dot(pa, ba) / dot(ba, ba), 0.0, 1.0);
	return length(pa - ba * h);
}

// distância até as linhas do campo (x em [-34,34], z em [-40,65]; meio em z = 12.5)
float linhas(vec2 p) {
	float d = abs(sd_caixa(p - vec2(0.0, 12.5), vec2(34.0, 52.5)));
	d = min(d, seg(p, vec2(-34.0, 12.5), vec2(34.0, 12.5)));
	d = min(d, abs(length(p - vec2(0.0, 12.5)) - 9.15));
	d = min(d, max(length(p - vec2(0.0, 12.5)) - 0.2, 0.0));
	// metade espelhada: o gol de cima vira o de baixo
	vec2 q = p.y < 12.5 ? p : vec2(p.x, 25.0 - p.y);
	d = min(d, abs(sd_caixa(q - vec2(0.0, -31.75), vec2(20.16, 8.25))));
	d = min(d, abs(sd_caixa(q - vec2(0.0, -37.25), vec2(9.16, 2.75))));
	d = min(d, max(length(q - vec2(0.0, -29.0)) - 0.2, 0.0));
	float arco = abs(length(q - vec2(0.0, -29.0)) - 9.15);
	d = min(d, q.y > -23.5 ? arco : 1e4);
	d = min(d, abs(length(q - vec2(-34.0, -40.0)) - 1.0));
	d = min(d, abs(length(q - vec2(34.0, -40.0)) - 1.0));
	return d;
}

void fragment() {
	vec2 p = mundo.xz;
	float dentro = 1.0 - smoothstep(34.0, 36.0, abs(p.x)) * 1.0;
	dentro *= (1.0 - smoothstep(-41.5, -43.5, p.y)) * (1.0 - smoothstep(66.5, 68.5, p.y));
	vec3 cor;
	float rug = 0.9;
	if (modo == 0) {
		float faixa = mod(floor((p.y + 40.0) / 7.5), 2.0);
		float faixa2 = mod(floor((p.x + 34.0) / 8.5), 2.0);
		float f = mix(faixa, abs(faixa - faixa2), xadrez * 0.35);
		cor = mix(grama_a, grama_b, f);
		cor *= 0.93 + 0.12 * fbm(p * 0.12);
		cor *= 0.95 + 0.1 * ruido(p * 18.0);
		// desgaste perto dos gols e no meio-campo
		vec2 g1 = (p - vec2(0.0, -36.5)) * vec2(1.0, 1.7);
		vec2 g2 = (p - vec2(0.0, 61.5)) * vec2(1.0, 1.7);
		float w = max(smoothstep(7.0, 0.0, length(g1)), smoothstep(7.0, 0.0, length(g2)));
		w = max(w, smoothstep(3.5, 0.0, length(p - vec2(0.0, 12.5))) * 0.6);
		w *= desgaste * smoothstep(0.35, 0.75, fbm(p * 0.9 + 4.0));
		cor = mix(cor, vec3(0.36, 0.33, 0.17), w * 0.7);
		cor = mix(grama_fora * (0.9 + 0.2 * fbm(p * 0.3)), cor, dentro);
	} else {
		float n = fbm(p * 0.35);
		cor = mix(terra_a, terra_b, smoothstep(0.3, 0.75, n));
		cor *= 0.9 + 0.2 * ruido(p * 9.0);
		float pedra = step(0.985, hash21(floor(p * 9.0)));
		cor = mix(cor, cor * 1.35 + 0.05, pedra);
		// tufos de grama nas beiradas e manchas
		float mato = smoothstep(0.58, 0.7, fbm(p * 0.18 + 7.0)) * (1.0 - dentro * 0.8);
		mato = max(mato, (1.0 - dentro) * smoothstep(0.45, 0.6, fbm(p * 0.5)));
		cor = mix(cor, vec3(0.32, 0.4, 0.15) * (0.8 + 0.4 * ruido(p * 6.0)), mato);
		rug = 1.0;
	}
	// linhas
	float d = linhas(p);
	float aa = fwidth(d) * 1.2 + 0.002;
	float m = 1.0 - smoothstep(largura_linha * 0.5 - aa, largura_linha * 0.5 + aa, d);
	if (modo == 1) {
		m *= smoothstep(0.25, 0.55, fbm(p * 1.7 + 2.0)); // cal gasta no campo de terra
		m *= 0.85;
	}
	cor = mix(cor, cor_linha * (modo == 1 ? 0.88 : 1.0), m);
	ALBEDO = cor;
	ROUGHNESS = mix(rug, 0.75, m);
	SPECULAR = 0.25;
}
