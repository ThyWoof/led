package data.def;

class TilesetDef implements ISerializable {
	var pixels : Null<hxd.Pixels>;
	public var tileGridSize : Int = Const.DEFAULT_GRID_SIZE;
	public var tileGridSpacing : Int = 0;

	var texture(get,never) : Null<h3d.mat.Texture>;
	var _textureCache : Null<h3d.mat.Texture>;

	var base64(get,never) : Null<String>;
	var _base64Cache : Null<String>;

	var cWid(get,never) : Int; inline function get_cWid() return isEmpty() ? 0 : M.ceil( pixels.width / tileGridSize );

	public function new() {
	}

	public function invalidateCache() {
		if( _textureCache!=null )
			_textureCache.dispose();
		_textureCache = null;
		_base64Cache = null;
	}

	function get_texture() {
		if( _textureCache==null && pixels!=null )
			_textureCache = h3d.mat.Texture.fromPixels(pixels);
		return _textureCache;
	}

	function get_base64() {
		if( _base64Cache==null && pixels!=null )
			_base64Cache = haxe.crypto.Base64.encode( pixels.toPNG() );
		return _base64Cache;
	}

	public inline function isEmpty() return pixels==null;


	public function clone() {
		return fromJson( toJson() );
	}

	public function toJson() {
		var b64 = pixels==null ? null : haxe.crypto.Base64.encode( pixels.bytes );
		return {
			b64: b64,
			width: pixels==null ? 0 : pixels.width,
			height: pixels==null ? 0 : pixels.height,
			tileGridSize: tileGridSize,
			tileGridSpacing: tileGridSpacing,
		}
	}


	public static function fromJson(json:Dynamic) {
		var td = new TilesetDef();
		td.tileGridSize = JsonTools.readInt(json.tileGridSize, Const.DEFAULT_GRID_SIZE);
		td.tileGridSpacing = JsonTools.readInt(json.tileGridSpacing, 0);
		if( json.b64!=null ) {
			var bytes = haxe.crypto.Base64.decode(json.b64);
			var w = JsonTools.readInt(json.width);
			var h = JsonTools.readInt(json.height);
			td.pixels = new hxd.Pixels(w, h, bytes, BGRA);
		}
		return td;
	}

	public function importImage(bytes:haxe.io.Bytes) : Bool {
		invalidateCache();
		if( pixels!=null )
			pixels.dispose();

		pixels = dn.heaps.ImageDecoder.getPixels(bytes);
		if( pixels==null ) {
			switch dn.Identify.getType(bytes) {
				case Unknown:
				case Png, Gif:
					N.error("Couldn't read this image: maybe the data is corrupted or the format special?");

				case Jpeg:
					N.error("Sorry, JPEG is not yet supported, please use PNG instead.");

				case Bmp:
					N.error("Sorry, BMP is not supported, please use PNG instead.");
			}
			return false;
		}

		return true;
	}

	public function coordId(tcx,tcy) {
		return tcx + tcy * cWid;
	}

	public inline function getTileCx(tileId:Int) {
		return tileId - cWid * Std.int( tileId / cWid );
	}

	public inline function getTileCy(tileId:Int) {
		return Std.int( tileId / cWid );
	}

	public inline function getTileSourceX(tileId:Int) {
		return getTileCx(tileId) * ( tileGridSize + tileGridSpacing );
	}

	public inline function getTileSourceY(tileId:Int) {
		return getTileCy(tileId) * ( tileGridSize + tileGridSpacing );
	}

	public inline function getAtlasTile() : Null<h2d.Tile> {
		return texture==null ? null : h2d.Tile.fromTexture(texture);
	}

public inline function getTile(tileId:Int) {
		return getAtlasTile().sub( getTileSourceX(tileId), getTileSourceY(tileId), tileGridSize, tileGridSize );
	}

	public function createAtlasHtmlImage() : js.html.Image {
		var img = new js.html.Image();
		if( !isEmpty() )
			img.src = 'data:image/png;base64,$base64';
		return img;
	}

	public function drawAtlasToCanvas(canvas:js.jquery.JQuery) {
		if( !canvas.is("canvas") )
			throw "Not a canvas";

		if( isEmpty() )
			return;

		var canvas = Std.downcast(canvas.get(0), js.html.CanvasElement);
		var ctx = canvas.getContext2d();
		ctx.clearRect(0, 0, canvas.width, canvas.height);

		var img = new js.html.Image(pixels.width, pixels.height);
		img.src = 'data:image/png;base64,$base64';
		img.onload = function() {
			ctx.drawImage(img, 0, 0);
		}
	}

	public function drawTileToCanvas(canvas:js.jquery.JQuery, tileId:Int, toX:Int, toY:Int) {
		if( pixels==null )
			return;

		if( !canvas.is("canvas") )
			throw "Not a canvas";

		// TODO check image bounds limits

		var subPixels = pixels.sub(getTileSourceX(tileId), getTileSourceY(tileId), tileGridSize, tileGridSize);
		var canvas = Std.downcast(canvas.get(0), js.html.CanvasElement);
		var ctx = canvas.getContext2d();
		var img = new js.html.Image(subPixels.width, subPixels.height);
		var b64 = haxe.crypto.Base64.encode( subPixels.toPNG() );
		img.src = 'data:image/png;base64,$b64';
		img.onload = function() {
			ctx.drawImage(img, toX, toY);
		}
	}


	public function dispose() {
		if( _textureCache!=null )
			_textureCache.dispose();
		_textureCache = null;

		if( pixels!=null )
			pixels.dispose();
		pixels = null;
	}

}