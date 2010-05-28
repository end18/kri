﻿namespace demo

import OpenTK
import kri.shade


private def createParticle(pc as kri.part.Context) as kri.part.Emitter:
	pm = kri.part.Manager( 2 )
	pm.makeStandard(pc)
	pm.col_init.extra.Add( pc.sh_tool )
	pm.col_update.root = Object('./text/root_v')
	pm.col_update.extra.Add( Object('./text/born_v') )
	beh = kri.part.beh.Basic('text/beh')
	kri.vb.enrich( beh, 4, pc.at_pos )
	pm.behos.Add(beh)
	
	if not 'Dummy':
		b2 = kri.part.beh.Basic('/part/fur/dummy')
		kri.vb.enrich( b2, 2, pc.at_sys )
		pm.behos.Add( b2 )
	
	pLimt = par.Value[of single]('limit')
	pLimt.Value = 2.5f
	pm.dict.var(pLimt)
	pm.init(pc)
	
	return kri.part.Emitter(pm,'mand')


private class Render( kri.rend.part.Simple ):
	pSize = par.Value[of single]('size')
	pBrit = par.Value[of single]('bright')

	public def constructor(pcon as kri.part.Context):
		super()
		dTest,bAdd = false,true
		# dict init
		pSize.Value = 5f
		pBrit.Value = 0.025f
		d = rep.Dict()
		d.var(pSize,pBrit)
		# prog init
		sa.add( './text/draw_v', './text/draw_f')
		sa.link( kri.Ant.Inst.slotParticles, d, kri.Ant.Inst.dict )



[System.STAThread]
def Main(argv as (string)):
	using ant = kri.Ant('kri.conf',0):
		view = kri.ViewScreen(16,0)
		rchain = kri.rend.Chain()
		view.ren = rchain
		rlis = rchain.renders
		ant.views.Add( view )
		ant.VSync = VSyncMode.On
		
		view.scene = kri.Scene('main')
		view.cam = kri.Camera()
		pcon = kri.part.Context()
		ps = createParticle(pcon)
		ps.allocate()
		view.scene.particles.Add(ps)
		
		rlis.Add( kri.rend.Clear() )
		rlis.Add( Render(pcon) )
		ant.anim = al = kri.ani.Scheduler()
		al.add( kri.ani.Particle(ps) )
		ant.Run(30.0,30.0)
