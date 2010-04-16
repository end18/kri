﻿namespace kri.frame

import OpenTK.Graphics.OpenGL

#--------- Simple dirty value holder	---------#
internal struct DirtyHolder[of T]:
	[getter(Dirty)]
	private dirty	as bool
	private val		as T
	internal Value	as T:
		set: dirty,val = true,value
		get: return val
	internal def clean():
		dirty = false


#---------	Single frame representor inside the FBO	---------#

public class Unit:
	internal tex		as kri.Texture = null					# texture
	internal dLayer		as DirtyHolder[of int]					# layer id
	internal dFormat	as DirtyHolder[of PixelInternalFormat]	# pixel format
	internal dirty		as bool = false							# tex changed
	[getter(Slot)]
	private final slot	as FramebufferAttachment				# fbo slot
	
	internal def constructor(s as FramebufferAttachment):
		slot = s
	public Tex as kri.Texture:
		get: return tex
		set: tex,dirty = value,true
	public Layer as int:
		get: return dLayer.Value
	public Format as PixelInternalFormat:
		get: return dFormat.Value
	
	# custom internal format
	public def new(pif as PixelInternalFormat, targ as TextureTarget) as kri.Texture:
		Tex = kri.Texture(targ)
		dFormat.Value = pif
		return tex
	# format defined by class & bits
	public def new(cl as kri.Texture.Class, bits as uint, targ as TextureTarget) as kri.Texture:
		if cl == kri.Texture.Class.Stencil:	assert slot == FramebufferAttachment.DepthStencilAttachment
		if cl == kri.Texture.Class.Depth:	assert slot == FramebufferAttachment.DepthAttachment
		return new( kri.Texture.AskFormat(cl,bits), targ )
	# class defined by slot
	public def new(bits as uint, targ as TextureTarget) as kri.Texture:
		cl = kri.Texture.Class.Color
		if slot == FramebufferAttachment.DepthStencilAttachment:
			cl = kri.Texture.Class.Stencil
		if slot == FramebufferAttachment.DepthAttachment:
			cl = kri.Texture.Class.Depth
		return new( cl, bits, targ )
	# target is rectangle
	public def new(bits as uint) as kri.Texture:
		return new(bits, TextureTarget.TextureRectangle)
	# set texture layer
	public def layer(t as kri.Texture, z as int) as void:
		tex = t	if t
		dLayer.Value = z