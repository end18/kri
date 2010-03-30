﻿namespace kri.rend.tech

import System
import System.Collections.Generic


public class Basic(kri.rend.Basic):
	protected	final tid	as int		# technique ID
	protected def constructor(name as string):
		super(false)
		tid = kri.Ant.Inst.slotTechniques.create(name)
	def destructor():
		kri.Ant.Inst.slotTechniques.delete(tid)


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
		if alist and not e.enable(alist):
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
	private final mList	as (string)
	private final shobs	as (kri.shade.Object)
	private final sMap		= SortedDictionary[of string, kri.shade.Smart]()
	protected final dict	= kri.shade.rep.Dict()
	
	protected def constructor(name as string, mets as (string), sh as kri.shade.Object*):
		super(name)
		mList,shobs = mets,array(sh)
	protected def constructor(name as string, mets as (string), prefix as string):
		super(name)
		mList = mets
		shobs = array( kri.shade.Object(prefix+s) for s in ('_v','_f') )

	private override def construct(mat as kri.Material) as kri.shade.Smart:
		sl = mat.collect(mList)
		return kri.shade.Smart.Fixed	if not sl
		key = String.Join(',', array(x.id.ToString() for x in sl) )
		sa as kri.shade.Smart = null
		return sa	if sMap.TryGetValue(key,sa)
		sa = kri.shade.Smart()
		sMap.Add(key,sa)
		sa.add( *(kri.Ant.Inst.shaders.gentleSet + array(sl) + shobs) )
		sa.link(kri.Ant.Inst.slotAttributes, dict, mat.dict, kri.Ant.Inst.dict) 
		return sa
