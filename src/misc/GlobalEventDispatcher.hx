package misc;

class GlobalEventDispatcher {
	var anyListeners : Array<GlobalEvent->Void> = [];
	var specificListeners : Array<{ e:GlobalEvent, cb:Void->Void }> = [];

	public function new() {
	}

	public function listenOnly(e:GlobalEvent, onEvent:Void->Void) {
		specificListeners.push({ e:e, cb:onEvent });
	}

	public function listenAll(onEvent:GlobalEvent->Void) {
		anyListeners.push(onEvent);
	}

	public function stopListening(?any:GlobalEvent->Void, ?specific:Void->Void) {
		if( any!=null )
			anyListeners.remove(any);

		if( specific!=null ) {
			for(l in specificListeners)
				if( l.cb==specific ) {
					specificListeners.remove(l);
					break;
				}
		}
	}

	public function emit(e:GlobalEvent) {
		for(ev in anyListeners)
			ev(e);

		for(l in specificListeners)
			if( l.e==e )
				l.cb();
	}

	public function dispose() {
		anyListeners = null;
	}
}