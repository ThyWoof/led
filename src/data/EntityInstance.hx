package data;

class EntityInstance implements ISerializable {
	public var _project : ProjectData;
	public var def(get,never) : EntityDef; inline function get_def() return _project.defs.getEntityDef(defId);

	public var defId(default,null) : Int;
	public var x : Int;
	public var y : Int;
	var fieldInstances : Map<Int, data.FieldInstance> = new Map();

	public var left(get,never) : Int; inline function get_left() return Std.int( x - def.width*def.pivotX );
	public var right(get,never) : Int; inline function get_right() return left + def.width-1;
	public var top(get,never) : Int; inline function get_top() return Std.int( y - def.height*def.pivotY );
	public var bottom(get,never) : Int; inline function get_bottom() return top + def.height-1;


	public function new(p:ProjectData, entityDefId:Int) {
		_project = p;
		defId = entityDefId;
	}

	@:keep public function toString() {
		return 'Instance<${def.name}>@$x,$y';
	}

	public function clone() {
		return fromJson(_project, toJson());
	}

	public function toJson() {
		var fieldsJson = [];
		for(fi in fieldInstances)
			fieldsJson.push( fi.toJson() );

		return {
			defId: defId,
			x: x,
			y: y,
			fieldInstances: fieldsJson,
		}
	}

	public static function fromJson(project:ProjectData, json:Dynamic) {
		var ei = new EntityInstance(project, JsonTools.readInt(json.defId));
		ei.x = JsonTools.readInt( json.x, 0 );
		ei.y = JsonTools.readInt( json.y, 0 );

		for( fieldJson in JsonTools.readArray(json.fieldInstances) ) {
			var fi = FieldInstance.fromJson(project, fieldJson);
			ei.fieldInstances.set(fi.defId, fi);
		}

		return ei;
	}

	public function getCx(ld:LayerDef) {
		return Std.int( ( x + (def.pivotX==1 ? -1 : 0) ) / ld.gridSize );
	}

	public function getCy(ld:LayerDef) {
		return Std.int( ( y + (def.pivotY==1 ? -1 : 0) ) / ld.gridSize );
	}

	public function isOver(levelX:Int, levelY:Int) {
		return levelX >= left && levelX <= right && levelY >= top && levelY <= bottom;
	}

	public function tidy(p:ProjectData) {
		_project = p;

		// Remove field instances whose def was removed
		for(e in fieldInstances.keyValueIterator())
			if( e.value.def==null )
				fieldInstances.remove(e.key);

		for(fi in fieldInstances)
			fi.tidy(_project);
	}

	public function getFieldInstance(fieldDef:FieldDef) {
		if( !fieldInstances.exists(fieldDef.uid) )
			fieldInstances.set(fieldDef.uid, new data.FieldInstance(_project, fieldDef.uid));
		return fieldInstances.get( fieldDef.uid );
	}

}