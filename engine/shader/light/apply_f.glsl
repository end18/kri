﻿#version 130
precision lowp float;

uniform vec4 lit_color, lit_data, proj_lit;

float get_shadow(vec4);
vec4 get_lighting(vec3,vec3);

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
	gl_FragColor = vec4( get_shadow(vs) );
	if(intensity < 0.01) discard;

	gl_FragColor = intensity*lit_color *
		get_lighting(v_lit,v_cam);
}
