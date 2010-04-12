﻿namespace kri.rend.tech

import System
import System.Collections.Generic


public class Basic( kri.rend.Basic ):
	protected	final tid	as int		# technique ID
	protected def constructor(name as string):
		super(false)
		tid = kri.Ant.Inst.slotTechniques.create(name)
	def destructor():
		kri.Ant.Inst.slotTechniques.delete(tid)
	protected def attribs(local as bool, e as kri.Entity, *ats as (int)) as bool:
		return false	if e.va[tid] == kri.vb.Array.Default
		if e.va[tid]:	e.va[tid].bind()
		elif not e.enable(local,tid,ats):
			e.va[tid] = kri.vb.Array.Default
			return false
		return true


#public class Object(Basic):
#	protected final sa	= kri.shade.Smart()
#	protected final va	= kri.vb.Array()


#---------	GENERAL TECHNIQUE	--------#

public class General(Basic):
	public static comparer	as IComparer[of kri.Batch]	= null
	protected	final butch	= List[of kri.Batch]()
	protected def constructor(name as string):
		super(name)
	private abstract def construct(mat as kri.Material) as kri.shade.Smart:
		pass
	protected virtual def getUpdate(mat as kri.Material) as callable() as int:
		return def() as int: return 1

	protected def addObject(e as kri.Entity) as void:
		return	if not e.visible
		#alist as List[of int] = null
		if e.va[tid] == kri.vb.Array.Default: return
		elif not e.va[tid]:
			(e.va[tid] = kri.vb.Array()).bind()
			alist = List[of int]()
		b = kri.Batch(e:e, va:e.va[tid], off:0)
		tempList = List[of kri.Batch]()
		for tag in e.tags:
			tm = tag as kri.TagMat
			continue	if not tm
			m = tm.mat
			b.num = tm.num
			b.off = tm.off
			prog = m.tech[tid]
			if not prog:
				m.tech[tid] = prog = construct(m)
			continue	if prog == kri.shade.Smart.Fixed
			if alist:
				ids = prog.gatherAttribs( kri.Ant.Inst.slotAttributes )
				alist.AddRange(a	for a in ids	if not a in alist)
			b.sa = prog
			b.up = getUpdate(m)
			tempList.Add(b)
		if alist and not e.enable(true,alist):
			e.va[tid] = kri.vb.Array.Default
		else:	butch.AddRange(tempList)

	# shouldn't be used as some objects have to be excluded
	protected def drawScene() as void:
		butch.Clear()
		for e in kri.Scene.Current.entities:
			addObject(e)
		butch.Sort(comparer)	if comparer
		for b in butch:
			b.draw()


#---------	META TECHNIQUE	--------#

public class Meta(General):
	private final lMets	as (string)
	private final lOuts	as (string)
	private final factory	= kri.ShaderLinker( kri.Ant.Inst.slotAttributes )
	protected shobs	= List[of kri.shade.Object]()
	protected final dict	= kri.shade.rep.Dict()
	
	protected def constructor(name as string, outs as (string), *mets as (string)):
		super(name)
		lMets,lOuts = mets,outs
		factory.onLink = setup
	
	protected def shade(prefix as string) as void:
		for s in ('_v','_f'):
			shobs.Add( kri.shade.Object(prefix+s) )
	protected def shade(slis as string*) as void:
		shobs.AddRange( kri.shade.Object(s) for s in slis )
	
	private def setup(sa as kri.shade.Smart) as void:
		sa.fragout( *lOuts )	if lOuts
		sa.add( *kri.Ant.Inst.shaders.gentleSet )
		sa.add( *array(shobs) )

	private override def construct(mat as kri.Material) as kri.shade.Smart:
		sl = mat.collect(lMets)
		return kri.shade.Smart.Fixed	if not sl
		return factory.link( sl, (dict, mat.dict, kri.Ant.Inst.dict) )
