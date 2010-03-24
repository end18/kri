﻿namespace kri.lib.par

import OpenTK
import OpenTK.Graphics
import kri.shade

# light settings
public final class Light:
	public final color	= par.Value[of Color4]()
	public final attenu	= par.Value[of Vector4]()
	public final data	= par.Value[of Vector4]()
	public def activate(l as kri.Light) as void:
		color.Value		= l.Color
		kdir = (1f if l.fov>0f else 0f)
		attenu.Value	= Vector4(l.energy, l.quad1, l.quad2, l.sphere)
		data.Value		= Vector4(l.softness, kdir, 0f, 0f)
		return	if not l.depth
		id = kri.Ant.Inst.units.light
		kri.Ant.Inst.units.Tex[id] = l.depth
	public def constructor(d as rep.Dict):
		d.add('lit_color',	color)
		d.add('lit_attenu',	attenu)
		d.add('lit_data',	data)


# basic projector settins
public final class Project( par.Value[of Vector4] ):
	public def activate(p as kri.Projector) as void:
		div = 1f / (p.rangeIn - p.rangeOut)
		dad = div *(p.rangeIn + p.rangeOut)
		if p.fov > 0f:
			tn = 1f / System.Math.Tan(p.fov)
			Value = Vector4(tn, tn * p.aspect, dad,
				2f*div*(p.rangeIn*p.rangeOut) )
		else:
			Value = Vector4(-p.fov, -p.fov,	2f*div, dad)
