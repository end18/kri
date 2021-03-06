﻿namespace demo.pick

import System
import System.Collections.Generic
import OpenTK


public class AniTrans( kri.ani.Loop ):
	private final n	as kri.Node
	private s0	as kri.Spatial
	private s1	as kri.Spatial
	public def constructor(node as kri.Node, ref targ as kri.Spatial):
		n = node
		s0 = n.local
		s1 = targ
		lTime = 0.2
	protected override def onRate(rate as double) as void:
		n.local.lerpDq(s0,s1,rate)
		n.touch()


public class AniRot( kri.ani.Loop ):
	private static final time = 0.3
	private final n as kri.Node
	private final s0 as kri.Spatial
	private final pos	as Vector3
	private final axis	as Vector3

	public def constructor(node as kri.Node, ref targ as kri.Spatial):
		n = node
		s0 = n.local
		pos = 0.5 * ( targ.pos + s0.pos )
		diff = targ.pos - s0.pos
		diff.Normalize()
		axis = Vector3.Cross(diff, Vector3.UnitZ )
		lTime = time
	protected override def onRate(rate as double) as void:
		s3 = s0
		s3.pos -= pos
		s2 = kri.Spatial.Identity
		s2.rot = Quaternion.FromAxisAngle( axis, rate*Math.PI )
		n.local.combine(s3,s2)
		n.local.pos += pos
		n.touch()



private class Task:
	private static	final size		= 5
	private ec		as kri.Entity	= null
	public	final	animan	= kri.ani.Scheduler()
	public	final	texture	as kri.buf.Texture
	private	final	grid	= array[of kri.Entity](size*size)
	
	public class TagId(kri.ITag):
		public final id	as int
		public def constructor(n as int):
			id = n
	
	private def checkGrid() as bool:
		for i in range(grid.Length):
			tag = grid[i].seTag[of TagId]()
			assert tag
			if i != tag.id:
				return false
		return true
	
	private def shuffle() as void:
		rn = Random( kri.Ant.Inst.Time )
		for i in range(1000):
			a = rn.Next() % (size*size)
			b = rn.Next() % (size*size)
			e = grid[a]
			grid[a] = grid[b]
			grid[b] = e
			n = e.node
			grid[b].node = grid[a].node
			grid[a].node = n

	public def fun(e as kri.Entity, point as Vector3) as void:
		if not animan.Empty:
			return
		# find the closest one
		i0 = i1 = -1
		for i in range(grid.Length):
			if grid[i] == ec:	i0 = i
			if grid[i] == e:	i1 = i
		# swap?
		if not 'Swap':
			kri.Help.swap[of kri.Spatial]( e.node.local, ec.node.local )
			e.node.touch()
			ec = e
			return
		# 
		#diff = Vector3.Subtract( ec.node.local.pos, e.node.local.pos )
		#ax,ay = Math.Abs(diff.X), Math.Abs(diff.Y)
		if i0!=i1+1 and i0!=i1-1 and i0!=i1+size and i0!=i1-size:
			return
		animan.add( AniTrans(e.node,ec.node.local) )
		ec.node.local = e.node.local
		ec.node.touch()
		# swap grid
		x = grid[i0]
		grid[i0] = grid[i1]
		grid[i1] = x
		# win?
		if checkGrid():
			ec.visible = true
	
	private def makeMat() as kri.Material:
		con = kri.load.Context()
		mat = kri.Material( con.mDef )
		if texture:
			con.setMatTexture(mat,texture)
		mat.link()
		return mat
	
	private def makeEnt() as kri.Entity:
		mat = makeMat()
		# create mesh
		m = kri.gen.Cube( Vector3(3f,2f,0.5f) )
		e = kri.Entity( mesh:m )
		e.tags.Add( kri.TagMat( mat:mat, num:m.nPoly ))
		e.tags.Add( support.pick.Tag( pick:fun ))
		return e
	
	private def makeRec() as kri.ani.data.Record:
		def fani(pl as kri.ani.data.IPlayer, val as Vector3, id as byte):
			n = pl as kri.Node
			n.local.pos = val
			n.touch()
		rec = kri.ani.data.Record('rotate',3f)
		ch = kri.ani.data.Channel[of Vector3](4,0,fani)
		ch.lerp = Vector3.Lerp
		ch.bezier = false
		tar = (0f, 1f, 2f, 3f)
		var = (Vector3.Zero, Vector3.UnitX, -Vector3.UnitX, Vector3.Zero)
		for i in range( ch.kar.Length ):
			ch.kar[i] = kri.ani.data.Key[of Vector3]( t:tar[i], co:var[i] )
		rec.channels.Add(ch)
		return rec
	
	private def makeTexCoord(x as uint, y as uint) as kri.vb.Attrib:
		vbo = kri.vb.Attrib()
		kri.Help.enrich(vbo,2,'tex0')
		data = array[of Vector2](24)	#vertices in a cube
		for k in range(data.Length):
			x1 = x+(((k+0)>>1)&1)
			y1 = y+(((k+1)>>1)&1)
			data[k] = Vector2( x1*1f / size, y1*1f / size )
		vbo.init(data,false)
		return vbo

	public def constructor(ar as List[of kri.Entity], texName as string):
		# prepare texture
		if texName:
			targa = kri.load.image.Targa()
			texture = targa.read(texName).generate()
			texture.setState(0,true,true)
		else:
			texture = null
		# make original
		e = makeEnt()
		rec = makeRec()
		# populate
		for i in range(size*size):
			ec = grid[i] = kri.Entity(e)
			ec.tags.Add( TagId(i) )
			ec.node = n = kri.Node('cell'+i)
			n.anims.Add(rec)
			if e.node:
				n.Parent = e.node.Parent
				n.local = e.node.local
			x,y = (i % size),(i / size)
			n.local.pos = Vector3( (x+x+1-size)*3.5f, (y+y+1-size)*2.3f, -50f )
			ar.Add(ec)
			ec.store.buffers.Add( makeTexCoord(x,y) )
		# remove original
		(ec = ar[0]).visible = false
		ec.tags.RemoveAll() do(t as kri.ITag):
			t2 = t as support.pick.Tag
			return t2 != null
		# prepare level
		shuffle()