#version 130

in	float at_pad;
out	float to_pad;

void init_pad()	{
	to_pad = 0.0;
}

float reset_pad()	{
	to_pad = 1.0;
	return to_pad;
}