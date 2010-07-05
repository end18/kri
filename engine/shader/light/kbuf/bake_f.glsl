#version 140

uniform vec4 screen_size, lit_color, proj_cam;
uniform sampler2DRect unit_depth;

vec3 unproject(vec3,vec4);
float get_attenuation2(float);

in vec4 lit_pos;	//cam space!
out vec4 data;


void main()	{
	// extract world & light space
	float depth = texture( unit_depth, gl_FragCoord.xy ).r;
	vec2 tc = gl_FragCoord.xy / screen_size.xy;
	vec3 p_camera = unproject( vec3(tc,depth), proj_cam );
	
	// compute components
	vec3 dir = lit_pos.w * (lit_pos.xyz - p_camera);
	float len = length( dir );
	float intensity = max(0.0, get_attenuation2(len) );
	vec3 color = intensity * lit_color.xyz;

	// translate to output
	data = vec4( dir/len, intensity );
}