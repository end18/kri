﻿namespace kri.vb

import System.Collections.Generic


public interface IBuffed:
	Data	as Object:
		get

public interface ISemanted:
	Semant	as List[of Info]:
		get

public interface IProvider(IBuffed,ISemanted):
	pass



public class Dict( Dictionary[of string,Entry] ):
	public def constructor(*stores as (Storage)):
		super()
		for st in stores:
			if st: st.fillEntries(self)
	public def fake(*names as (string)) as byte:
		mask = 0
		for i in range(names.Length):
			if names[i]	in Keys:
				mask |= 1<<i
			else:
				self[names[i]] = self[names[0]]
		return mask



public class Attrib( IProvider, Object ):
	[Getter(Semant)]
	private final semantics	as List[of Info]	= List[of Info]()
	IBuffed.Data		as Object:
		get: return self

	public def unitSize() as uint:
		rez as uint = 0
		for a in semantics:
			rez += a.fullSize()
		return rez
	
	public def initUnit(num as uint) as void:
		init( num * unitSize() )
