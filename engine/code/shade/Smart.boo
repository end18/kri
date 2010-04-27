﻿namespace kri.shade

import OpenTK.Graphics.OpenGL

#-----------------------#
#	SMART SHADER 		#
#-----------------------#

public class Smart(Program):
	private final repList	= List[of rep.Base]()
	private sourceList		as (par.IBaseRoot)
	public static final prefixAttrib	as string	= 'at_'
	public static final prefixUnit		as string	= 'unit_'
	public static final Fixed	= Smart(0)
	
	public def constructor():
		super()
	private def constructor(xid as int):
		super(xid)
	public def constructor(sa as Smart):
		super( sa.id )	# cloning
		repList.Extend( sa.repList )
		sourceList = array[of par.IBaseRoot]( sa.sourceList.Length )
		sa.sourceList.CopyTo( sourceList, 0 )
	
	public def attribs(sl as kri.lib.Slot, *ats as (int)) as void:
		for a in ats:
			name = sl.Name[a]
			continue if string.IsNullOrEmpty(name)
			attrib(a, prefixAttrib + name)
	public def attribs(sl as kri.lib.Slot) as void:
		attribs(sl, *array(range(sl.Size)) )
	
	public override def use() as void:
		super()
		for rp in repList:
			iv = sourceList[ rp.loc ]
			rp.upload(iv)
	
	# link with attributes
	public def link(sl as kri.lib.Slot, *dicts as (rep.Dict)) as void:
		attribs(sl)
		link()
		checkAttribs(sl)
		fillPar(true,*dicts)
	
	# clear objects
	public override def clear() as void:
		repList.Clear()
		sourceList = null
		super()
	
	# collect used attributes
	public def gatherAttribs(sl as kri.lib.Slot) as int*:
		return (i for i in range(sl.Size)
			if not string.IsNullOrEmpty(sl.Name[i]) and
			i == GL.GetAttribLocation(id, prefixAttrib + sl.Name[i])
			)
	# check used attributes
	public def checkAttribs(sl as kri.lib.Slot) as void:
		num = getAttribNum()
		name = System.Text.StringBuilder()
		aux0,aux1,size = 100,0,0
		type as ActiveAttribType
		for i in range(num):
			GL.GetActiveAttrib(id,i, aux0,aux1,size,type, name)
			str = name.ToString()
			off = (0,3)[ str.StartsWith(prefixAttrib) ]
			assert sl.find( str.Substring(off) ) >= 0
	
	# setup units & gather uniforms
	public def fillPar( reset as bool, *dicts as (rep.Dict) ) as void:
		num,tun = -1,0
		GL.GetProgram(id, ProgramParameter.ActiveUniforms, num)
		if reset:
			GL.UseProgram(id)	# for texture units
			sourceList = array[of par.IBaseRoot](num+5)	#todo: fix number
			repList.Clear()
		nar = ( GL.GetActiveUniformName(id,i) for i in range(num) )
		for name in nar:
			iv	as par.IBaseRoot = null
			for d in dicts:
				d.TryGetValue(name,iv)
				break	if iv
			if iv or reset:
				loc = getVar(name)
				assert iv and loc >= 0
				sourceList[loc] = iv
			continue	if not reset
			rp as rep.Base	= null
			if name.StartsWith(prefixUnit):
				rp = rep.Unit(loc,tun)
				++tun
			else: rp = rep.Base.Create(iv,loc)
			assert rp
			repList.Add(rp)


	public def getAttribNum() as int:
		assert Ready
		num = -1
		GL.GetProgram(id, ProgramParameter.ActiveAttributes, num)
		return num

	# gather total attrib size
	public def getAttribSize() as int:
		assert Ready
		num,total,size = -1,0,0
		GL.GetProgram(id, ProgramParameter.ActiveAttributes, num)
		for i in range(num):
			tip as ActiveAttribType
			GL.GetActiveAttrib(id, i, size, tip)
			total += size
		return total
	