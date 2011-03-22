﻿namespace support.light.omni

import System
import OpenTK
import OpenTK.Graphics.OpenGL


#---------	LIGHT OMNI FILL	--------#

public class Fill( kri.rend.tech.General ):
	protected final fbo		= kri.buf.Holder(mask:0)
	protected final bu		= kri.shade.Bundle()
	protected final context	as support.light.Context
	protected final pDist	= kri.shade.par.Value[of Vector4]('uni_dist')

	public def constructor(lc as support.light.Context):
		super('lit.omni.bake')
		context = lc
		# omni shader
		bu.shader.add( '/light/omni/bake_v', '/light/omni/bake_g', '/empty_f' )
		bu.shader.add( *kri.Ant.Inst.libShaders )
		dict = kri.shade.par.Dict()
		dict.var(pDist)
		bu.dicts.Add( dict )
		bu.dicts.Add( lc.dict )
		bu.link()

	public override def construct(mat as kri.Material) as kri.shade.Bundle:
		return bu
	private def setLight(l as kri.Light) as void:
		kri.Ant.Inst.params.pLit.spatial.activate( l.node )
		k = 1f / (l.rangeOut - l.rangeIn)
		pDist.Value = Vector4(k, l.rangeIn+l.rangeOut, 0f, 0f)

	public override def process(con as kri.rend.link.Basic) as void:
		con.SetDepth(1f, true)	# offset for HW filtering
		for l in kri.Scene.Current.lights:
			continue	if l.fov != 0f
			setLight(l)
			if not l.depth:
				l.depth = t = kri.buf.Texture.Depth(0)
				t.target = TextureTarget.TextureCubeMap
				t.wid = t.het = context.size
			fbo.at.depth = l.depth
			fbo.bind()
			GL.ClearDepth( 1f )
			GL.Clear( ClearBufferMask.DepthBufferBit )
			drawScene()


#---------	LIGHT OMNI APPLY	--------#

public class Apply( kri.rend.tech.Meta ):
	private lit as kri.Light	= null
	private final smooth	as bool
	public def constructor(bSmooth as bool):
		super('lit.omni.apply', false, null, *kri.load.Meta.LightSet)
		shade(('/light/omni/apply_v','/light/omni/apply_f','/light/common_f'))
		smooth = bSmooth
	protected override def getUpdater(mat as kri.Material) as Updater:
		metaFun = super(mat).fun
		curLight = lit
		return Updater() do() as int:
			kri.Ant.Inst.params.activate(curLight)
			return metaFun()
	public override def process(con as kri.rend.link.Basic) as void:
		con.activate( con.Target.Same, 0f, false )
		butch.Clear()
		#Texture.Slot(8)
		for l in kri.Scene.Current.lights:
			continue	if l.fov != 0f
			lit = l
			#if l.depth:
			#	l.depth.bind()
			#	Texture.Shadow(false)
			#	Texture.Filter(false,false);
			# determine subset of affected objects
			for e in kri.Scene.Current.entities:
				addObject(e)
		using blend = kri.Blender():
			blend.add()
			butch.Sort( kri.rend.tech.Batch.cMat )
			for b in butch:
				b.draw()
