﻿namespace kri.load

import kri.meta
import OpenTK.Graphics

public partial class Native:
	public final limdic		= Dictionary[of string,callable() as Hermit]()

	public def fillMapinDict() as void:
		def genFun(x as Hermit):
			return {return x}
		for s in ('GLOBAL','OBJECT','UV','ORCO','WINDOW','NORMAL','REFLECTION','TANGENT'):
			slow = s.ToLower()
			sh = kri.shade.Object( "/mi/${slow}_v" )
			mt = Hermit( shader:sh, Name:slow )	# careful!
			limdic[s] = genFun(mt)
		def replace(str as string, fun as callable(Hermit) as callable() as Hermit):
			h = limdic[str]()
			limdic[str] = fun(h)
		replace('UV') do(h as Hermit):
			return do():
				# uv layer name, not supported
				getString(NAME_LEN)
				muv = InputUV( shader:h.shader, Name:h.Name )
				muv.pInd.Value = 0
				return muv
		replace('OBJECT') do(h as Hermit):
			return do():
				name = getString(STR_LEN)
				mio = InputObject( shader:h.shader, Name:h.Name )
				finalActions.Add() do():
					nd = at.nodes[name]
					mio.pNode.activate(nd)
				return mio
		replace('ORCO') do(h as Hermit):
			return do():
				# mapping type, not supported
				getString(NAME_LEN)
				return h


	#---	Parse texture unit	---#
	private struct MapTarget:
		public final name	as string
		public final prog	as kri.shade.Object
		public def constructor(s as string, p as kri.shade.Object):
			name,prog = s,p
	public def pm_unit() as bool:
		m = geData[of kri.Material]()
		return false	if not m
		u = AdUnit()
		puData(u)
		tarDict = Dictionary[of string,MapTarget]()
		tarDict['colordiff']		= MapTarget( 'diffuse',		con.slib.diffuse_t2 )
		tarDict['coloremission']	= MapTarget( 'emissive',	con.slib.emissive_t2 )
		# map targets
		for i in range( br.ReadByte() ):
			name = getString(STR_LEN)
			targ as MapTarget
			continue if not tarDict.TryGetValue(name,targ)
			u.Name = targ.name	if System.String.IsNullOrEmpty(u.Name)
			me = m.Meta[targ.name]
			me.unit = u
			me.shader = targ.prog
		# map inputs
		name = getString(SHORT_LEN)
		fun as callable() as Hermit = null
		if limdic.TryGetValue(name,fun):
			u.input = fun()
			return true
		return false


	#---	Parse material	---#
	public def p_mat() as bool:
		m = kri.Material( getString(STR_LEN) )
		at.mats[m.name] = m
		puData(m)
		# colors
		m.Meta['emissive']	= Data_Color4( shader:con.slib.emissive_u,	Value:getColorByte() )
		m.Meta['diffuse']	= Data_Color4( shader:con.slib.diffuse_u,	Value:getColorByte() )
		m.Meta['specular']	= Data_Color4( shader:con.slib.specular_u,	Value:getColorByte() )
		# models
		str = getString(SHORT_LEN)
		assert str == 'LAMBERT'
		str = getString(SHORT_LEN)
		assert str in ('COOKTORR','PHONG')
		# params
		getReal()	# reflectivity, todo!
		getReal()	# specularity, todo!
		glossy	= getReal()
		getReal()	# parallax, todo!
		# META2 style
		m.Meta['glossiness']	= Data_single( shader:con.slib.glossiness_u,	Value:glossy )
		m.Meta['bump']		= Advanced( shader:con.slib.bump_c )
		return true


	protected def getTexture(str as string) as kri.Texture:
		#TODO: support for other formats
		return null	if not str.EndsWith('.tga')
		return image.Targa(str).Result.generate()
	
	#---	Parse texture slot	---#
	public def pm_tex() as bool:
		u = geData[of AdUnit]()
		return false	if not u
		image.Basic.bRepeat	= br.ReadByte()>0	# extend by repeat
		image.Basic.bMipMap	= br.ReadByte()>0	# generate mip-maps
		image.Basic.bFilter	= br.ReadByte()>0	# linear filtering
		# texcoords & image path
		u.pOffset.Value	= Vector4(getVector(), 0.0)
		u.pScale.Value	= Vector4(getVector(), 1.0)
		u.Value = getTexture( 'res' + getString(PATH_LEN) )
		return u.Value != null
