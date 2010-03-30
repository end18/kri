﻿#version 130
precision lowp float;

uniform vec4 lit_color, lit_data, proj_lit;

float get_shadow(vec4);
vec4 get_diffuse();
vec4 get_specular();
vec4 get_bump();
float get_glossiness();

vec4 comp_diffuse(vec3 no, vec3 lit)	{
	return get_diffuse() * max( dot(no,lit), 0.0);
}
vec4 comp_specular(vec3 no, vec3 lit, vec3 cam)	{
	vec3 ha = normalize(lit+cam);	//half-vector
	float nh = max( dot(no,ha), 0.0);
	return get_specular() * pow(nh, get_glossiness());
}

in vec3 v2lit, v2cam;
in vec4 v_shadow;
in float lit_int;


void main()	{
	vec3 v_lit = normalize(v2lit);
	vec3 v_cam = normalize(v2cam);
	
	// spot angle limit check
	vec3 vlit = v_shadow.xyz / mix(1.0, v_shadow.w, lit_data.y);
	vec2 r2 = vlit.xy;
	vec4 vs = vec4(0.5*vlit + vec3(0.5), 1.0);
	float rad = smoothstep( 0.0, lit_data.x, 1.0-dot(r2,r2) );
	float intensity = rad * lit_int * get_shadow(vs);
	//gl_FragColor = vec4(get_shadow(vs)); return;
	if(intensity < 0.01) discard;

	vec4 bump = get_bump();

	gl_FragColor = intensity*lit_color * (
		comp_diffuse (bump.xyz,v_lit) +
		comp_specular(bump.xyz,v_lit,v_cam) );
}
