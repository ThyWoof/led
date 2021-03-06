package form;

#if macro
import haxe.macro.Expr;
import haxe.macro.Context;
#end

class Input<T> {
	#if !macro
	var input : js.jquery.JQuery;
	var getter : Void->T;
	var setter : T->Void;

	var lastValidValue : T;
	public var validityCheck : Null<T->Bool>;
	public var validityError : Null<Void->Void>;
	var linkedEvents : Map<GlobalEvent,Bool> = new Map();

	private function new(jElement:js.jquery.JQuery, getter, setter) {
		if( jElement.length==0 )
			throw "Empty jQuery object";

		this.getter = getter;
		this.setter = setter;
		input = jElement;
		input.off();
		writeValueToInput();
		lastValidValue = getter();

		input.change( function(_) {
			onInputChange();
		});
	}

	function onInputChange() {
		if( validityCheck!=null && !validityCheck(parseInputValue()) ) {
			setter( lastValidValue );
			writeValueToInput();
			if( validityError==null )
				N.error("This value isn't valid.");
			else
				validityError();
			return;
		}

		setter( parseInputValue() );
		writeValueToInput();
		lastValidValue = getter();
		for(e in linkedEvents.keys())
			Client.ME.ge.emit(e);
		onChange();
		onValueChange( getter() );
	}

	public function linkEvent(eid:GlobalEvent) {
		linkedEvents.set(eid,true);
	}

	public dynamic function onChange() {}
	public dynamic function onValueChange(v:T) {}

	function parseInputValue() : T {
		return input.val();
	}

	function writeValueToInput() {
		var v = getter();
		if( v==null )
			input.val("");
		else
			input.val( Std.string( getter() ) );
	}


	public function setEnabled(v:Bool) {
		input.prop("disabled", !v);
	}

	public function enable() {
		input.prop("disabled",false);
	}

	public function disable() {
		input.prop("disabled",true);
	}

	public function setPlaceholder(v:T) {
		if( !input.is("[type=text]") )
			throw "Not compatible with this input type";
		input.attr("placeholder", Std.string(v));
	}

	#end


	public static macro function linkToHtmlInput(variable:Expr, formInput:ExprOf<js.jquery.JQuery>) {
		var t = Context.typeof(variable);
		switch t {
			case TInst(t, params):
				switch t.toString() {
					case "String":
						return macro {
							new form.input.StringInput(
								$formInput,
								function() return $variable,
								function(v) $variable = v
							);
						}
					case _: Context.fatalError("Unsupported instance type "+t, variable.pos);
				}

			case TEnum(eRef,_):
				var enumType = haxe.macro.TypeTools.getEnum(t);
				var enumExpr : Expr = {
					expr: EConst( CIdent(enumType.name) ), // TODO might need to add package+module here, one day
					pos: enumType.pos,
				}

				return macro {
					new form.input.EnumSelect(
						$formInput,
						$enumExpr,
						function() return cast $variable,
						function(v) $variable = cast v
					);
				}

			case TAbstract(t, params):
				switch t.toString() {
					case "Int", "UInt":
						return macro {
							new form.input.IntInput(
								$formInput,
								function() return $variable,
								function(v) $variable = v
							);
						}

					case "Float":
						return macro {
							new form.input.FloatInput(
								$formInput,
								function() return $variable,
								function(v) $variable = v
							);
						}

					case "Bool":
						return macro {
							new form.input.BoolInput(
								$formInput,
								function() return $variable,
								function(v) $variable = v
							);
						}

					case "Null":
						Context.fatalError("Unsupported nullable "+params, variable.pos);
						return macro {}

					case _:
						Context.fatalError("Unsupported abstract type "+t, variable.pos);
				}

			case _ :
				Context.fatalError("Unsupported type "+t, variable.pos);
		}
		return macro {}
	}
}