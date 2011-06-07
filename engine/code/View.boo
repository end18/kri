namespace kri

import System
import System.Collections.Generic
import OpenTK
import OpenTK.Graphics

public interface IColored:
	Color as Color4:
		get
		set

public interface INoded:
	Node as Node:
		get

# Perspective projector for light & camera
public class Projector( ani.data.Player, INoded ):
	public node		as Node
	public rangeIn	= 1f
	public rangeOut	= 100f
	public fov		= 0.4f	# ~23 degrees (half)
	public aspect	= 1f
	
	INoded.Node as Node:
		get: return node
	
	public def touch() as void:	#imp: IPlayer
		pass
	public def project(ref v as Vector3) as Vector3:
		dz = -1f / v.Z
		tn = dz / Math.Tan(fov)
		assert fov > 0f
		return Vector3( tn*v.X, tn*v.Y * aspect,
				(2f*dz*rangeIn*rangeOut - rangeIn-rangeOut) / (rangeIn - rangeOut))
	public def toWorld(ref vin as Vector3) as Vector3:
		v = Vector3.Add( Vector3.Multiply(vin,2f), Vector3.One )
		z = 2f*rangeIn*rangeOut / (v.Z*(rangeOut-rangeIn) - rangeOut - rangeIn)
		return Vector3(-z*v.X, -z*v.Y / aspect, z)
	public def makeOrtho(radius as single) as void:
		fov = -2f / radius
	public def setRanges(a as single, b as single) as void:
		assert b>a
		rangeIn,rangeOut = a,b
		

public class Camera(Projector):
	[property(Current)]
	public static current	as Camera = null


public class Light(Projector,IColored):
	public enum Type:
		Omni
		Directed
		Spot
	# attributes
	public softness	= 0f
	[Property(Color)]
	private color	as Color4	= Color4(1f,1f,1f,1f)
	public energy	= 1f	# initial energy
	public quad1	= 0f	# linear factor
	public quad2	= 0f	# quadratic factor
	public sphere	= 0f	# spherical bound
	public depth	as buf.Texture	= null
	# parallel projection
	public def setLimit(radius as single) as void:
		rangeIn = 1
		rangeOut = radius
		sphere = 1f / radius
	public def getType() as Type:
		if fov<0f:	return Type.Directed
		if fov>0f:	return Type.Spot
		return Type.Omni



public abstract class Shape:
	public virtual def collide(sh as Shape) as Vector3:
		return -sh.collide(self)

public class ShapeSphere(Shape):
	public center	as Vector3	= Vector3(0f,0f,0f)
	public radius	as single	= 0f
	public virtual def collide(sh as ShapeSphere) as Vector3:
		rez = sh.center - center
		kf = (sh.radius + radius) / rez.LengthFast
		return rez * Math.Max(0f,1f-kf)

# Physics atom
public class Body:
	public final node	as Node
	public final shape	as Shape
	public mass		= 0f
	public vLinear	= Vector3(0f,0f,0f)
	public vAngular	= Vector3(0f,0f,0f)
	public def constructor(n as Node, sh as Shape):
		node,shape = n,sh
	


# Scene that holds entities, lights & cameras
public class Scene:
	[getter(Current)]
	internal static current as Scene = null
	public final name		as string
	public pGravity			as kri.shade.par.Value[of Vector4]	= null
	public backColor		= Graphics.Color4.Black
	# content
	public final entities	= List[of Entity]()
	public final bodies		= List[of Body]()
	public final lights		= List[of Light]()
	public final cameras	= List[of Camera]()
	public final particles	= List[of part.Emitter]()
	# funcs
	public def constructor(str as string):
		name = str


# Renders a scene with camera to some buffer
public class View:
	# rendering
	public virtual Link as kri.rend.link.Basic:
		get: return null
	public ren		as rend.Basic	# root render
	# view
	public cam		as Camera	= null
	public scene	as Scene	= null

	public virtual def resize(wid as int, het as int) as bool:
		if not ren:
			return true
		return ren.setup( kri.buf.Plane(wid:wid,het:het) )
	public def update() as void:
		Scene.current = scene
		if cam and Link:
			cam.aspect = Link.Frame.getInfo().Aspect
			Ant.Inst.params.activate(cam)
		if ren and ren.active:
			ren.process(Link)
		vb.Array.Default.bind()
		Scene.current = null


# View for rendering to screen
public class ViewScreen(View):
	public final area	= Box2(0f,0f,1f,1f)
	public final link	= kri.rend.link.Screen()
	public override Link as kri.rend.link.Basic:
		get: return link
	public override def resize(wid as int, het as int) as bool:
		return resize(0,0,wid,het)
	public def resize(ofx as int, ofy as int, wid as int, het as int) as bool:
		sc = link.screen
		pl = sc.plane
		pl.wid	= cast(int, wid*area.Width	)
		pl.het	= cast(int, het*area.Height	)
		sc.ofx	= cast(int, wid*area.Left	) + ofx
		sc.ofy	= cast(int, het*area.Top	) + ofy
		return super.resize(wid,het)
