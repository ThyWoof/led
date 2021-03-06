package data.def;

class FieldDef implements ISerializable {
	public var uid(default,null) : Int;
	public var type(default,null) : FieldType;
	public var name : String;
	public var canBeNull : Bool;
	public var editorDisplayMode : FieldDisplayMode;
	public var editorDisplayPos : FieldDisplayPosition;

	@:allow(ui.modal.panel.EditEntityDefs)
	var defaultOverride : Null<ValueWrapper>;

	public var min : Null<Float>;
	public var max : Null<Float>;

	@:allow(data.def.EntityDef)
	private function new(uid:Int, t:FieldType) {
		this.uid = uid;
		type = t;
		editorDisplayMode = Hidden;
		editorDisplayPos = Above;
		name = "New field "+uid;
		canBeNull = type==F_String;
		min = max = null;
		defaultOverride = null;
	}

	@:keep public function toString() {
		return '$name('
			+ ( canBeNull ? 'Null<$type>' : '$type' )
			+ ', default=${getDefault()})'
			+ ( type==F_Int || type==F_Float ? '[$min-$max]' : "" );
	}

	public function clone() {
		return fromJson( Const.DATA_VERSION, toJson() );
	}

	public static function fromJson(dataVersion:Int, json:Dynamic) {
		var o = new FieldDef( JsonTools.readInt(json.uid), JsonTools.readEnum(FieldType, json.type, false) );
		o.name = JsonTools.readString(json.name);
		o.canBeNull = JsonTools.readBool(json.canBeNull);
		o.editorDisplayMode = JsonTools.readEnum(FieldDisplayMode, json.editorDisplayMode, false, Hidden);
		o.editorDisplayPos = JsonTools.readEnum(FieldDisplayPosition, json.editorDisplayPos, false, Above);
		o.min = JsonTools.readNullableFloat(json.min);
		o.max = JsonTools.readNullableFloat(json.max);
		o.defaultOverride = JsonTools.readEnum(ValueWrapper, json.defaultOverride, true);
		return o;
	}

	public function toJson() {
		return {
			uid: uid,
			type: JsonTools.writeEnum(type, false),
			name: name,
			canBeNull: canBeNull,
			editorDisplayMode: JsonTools.writeEnum(editorDisplayMode, false),
			editorDisplayPos: JsonTools.writeEnum(editorDisplayPos, false),
			min: min==null ? null : JsonTools.clampFloatPrecision(min),
			max: max==null ? null : JsonTools.clampFloatPrecision(max),
			defaultOverride: JsonTools.writeEnum(defaultOverride, true),
		}
	}


	public function getDescription() {
		var infinity = "∞";
		return L.getFieldType(type)
			+ ( canBeNull ? " nullable" : "" )
			+ "=" + ( type==F_String && getDefault()!=null ? '"${getDefault()}"' : getDefault() )
			+ ( min==null && max==null ? "" :
				( type==F_Int ? " ["+(min==null?"-"+infinity:""+M.round(min))+";"+(max==null?"+"+infinity:""+M.round(max))+"]" : "" )
				+ ( type==F_Float ? " ["+(min==null?"-"+infinity:""+min)+";"+(max==null?infinity:""+max)+"]" : "" )
			);
	}

	inline function require(type:FieldType) {
		if( this.type!=type )
			throw "Only available on "+type+" fields";
	}

	public function iClamp(v:Null<Int>) {
		if( v==null )
			return v;

		if( min!=null )
			v = M.imax(v, M.round(min));

		if( max!=null )
			v = M.imin(v, M.round(max));

		return v;
	}

	public function fClamp(v:Null<Float>) {
		if( v==null )
			return v;

		if( min!=null )
			v = M.fmax(v, min);

		if( max!=null )
			v = M.fmin(v, max);

		return v;
	}

	public function getUntypedDefault() : Dynamic {
		return switch defaultOverride {
			case null: null;
			case V_Int(v): v;
			case V_Float(v): v;
			case V_Bool(v): v;
			case V_String(v): v;
		}
	}

	public function getBoolDefault() : Null<Bool> {
		require(F_Bool);
		return switch defaultOverride {
			case null: canBeNull ? null : false;
			case V_Bool(v): v;
			case _: null;
		}
	}

	public function getColorDefault() : Null<Int> {
		require(F_Color);
		return switch defaultOverride {
			case null: canBeNull ? null : 0x0;
			case V_Int(v): v;
			case _: null;
		}
	}

	public function getIntDefault() : Null<Int> {
		require(F_Int);
		return iClamp(switch defaultOverride {
			case null: canBeNull ? null : 0;
			case V_Int(v): v;
			case _: null;
		});
	}

	public function getFloatDefault() : Null<Float> {
		require(F_Float);
		return fClamp( switch defaultOverride {
			case null: canBeNull ? null : 0.;
			case V_Float(v): v;
			case _: null;
		});
	}

	public function getStringDefault() : Null<String> {
		require(F_String);
		return switch defaultOverride {
			case null: canBeNull ? null : "";
			case V_String(v): v;
			case _: null;
		}
	}

	public function restoreDefault() {
		defaultOverride = null;
	}

	public function setDefault(rawDef:Null<String>) {
		if( rawDef==null )
			defaultOverride = null;
		else switch type {
			case F_Int:
				var def = Std.parseInt(rawDef);
				defaultOverride = !M.isValidNumber(def) ? null : V_Int( iClamp(def) );

			case F_Color:
				var def = C.hexToInt(rawDef);
				defaultOverride = !M.isValidNumber(def) ? null : V_Int(def);

			case F_Float:
				var def = Std.parseFloat(rawDef);
				defaultOverride = !M.isValidNumber(def) ? null : V_Float( fClamp(def) );

			case F_String:
				rawDef = StringTools.trim(rawDef);
				defaultOverride = rawDef=="" ? null : V_String(rawDef);

			case F_Bool:
				rawDef = StringTools.trim(rawDef).toLowerCase();
				if( rawDef=="true" ) defaultOverride = V_Bool(true);
				else if( rawDef=="false" ) defaultOverride = V_Bool(false);
				else defaultOverride = null;

		}
	}

	public function getDefault() : Dynamic {
		return switch type {
			case F_Int: getIntDefault();
			case F_Color: getColorDefault();
			case F_Float: getFloatDefault();
			case F_String: getStringDefault();
			case F_Bool: getBoolDefault();
		}
	}


	public function setMin(raw:Null<String>) {
		if( raw==null )
			min = null;
		else {
			switch type {
				case F_Int:
					var v = Std.parseInt(raw);
					if( !M.isValidNumber(v) )
						min = null;
					else
						min = v;

				case F_Float:
					var v = Std.parseFloat(raw);
					if( !M.isValidNumber(v) )
						min = null;
					else
						min = v;

				case _:
			}
		}
		checkMinMax();
	}

	public function setMax(raw:Null<String>) {
		if( raw==null )
			max = null;
		else {
			switch type {
				case F_Int:
					var v = Std.parseInt(raw);
					if( !M.isValidNumber(v) )
						max = null;
					else
						max = v;

				case F_Float:
					var v = Std.parseFloat(raw);
					if( !M.isValidNumber(v) )
						max = null;
					else
						max = v;

				case _:
			}
		}
		checkMinMax();
	}

	function checkMinMax() {
		if( type!=F_Int && type!=F_Float )
			return;

		// Swap reversed min/max
		if( min!=null && max!=null && max<min ) {
			var tmp = max;
			max = min;
			min = tmp;
		}

		// Clamp existing default if needed
		switch defaultOverride {
			case V_Int(v): defaultOverride = V_Int( iClamp(v) );
			case V_Float(v): defaultOverride = V_Float( fClamp(v) );
			case _:
		}
		// if( defaultOverride!=null )
		// 	switch type {
		// 		case F_Int: defaultOverride = Std.string( getIntDefault() );
		// 		case F_Float: defaultOverride = Std.string( getFloatDefault() );
		// 		case _:
		// 	}
	}
}
