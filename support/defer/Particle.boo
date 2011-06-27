﻿namespace support.defer

public class Particle(ApplyBase):
	private final pHalo		= kri.shade.par.Value[of OpenTK.Vector4]('halo_data')
	private final light		= kri.Light( energy:1f, quad1:0f, quad2:0f )
	private final sphere	as kri.Mesh
	# init
	public def constructor(pc as kri.part.Context, con as Context):
		super(con)
		sphere = con.sphere.mesh
		con.dict.var(pHalo)
		buSimple.shader.add('/part/draw/light_v')
	# work
	private override def onDraw() as void:
		scene = kri.Scene.Current
		if not scene:	return
		# draw particles
		for pe in scene.particles:
			#todo: add light particle meta
			if not (pe.mat and pe.Ready):
				continue
			halo = pe.mat.Meta['halo'] as kri.meta.Halo
			if not halo:
				continue
			pHalo.Value = halo.Data
			light.setLimit( pHalo.Value.X )
			d = kri.vb.Dict( sphere, pe.mesh )
			for s in ('sys','pos'):
				en = kri.vb.Entry(pe,s)
				en.divisor = 1
				d['ghost_'+s] = en
			kri.Ant.Inst.params.activate(light)
			sphere.render( pe.owner.va, buSimple, d, 1, null )
