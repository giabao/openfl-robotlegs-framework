#if !flash
package robotlegs.bender.extensions.viewManager.impl;

import msignal.Signal.Signal1;
import openfl.display.DisplayObject;
import openfl.display.DisplayObjectContainer;
import openfl.events.Event;
import openfl.events.EventDispatcher;

/**
 * ...
 * @author P.J.Shand
 */
class DisplaylistTraverser
{
	public var display:DisplayObjectContainer;
	private var numChildrenRegistered(get, null):Int = 0;
	private var childTraversers:Array<DisplaylistTraverser> = [];

	//tracking children that are not of type DisplayObjectContainer
	private var childTrackers: Array<DisplayObjectTracker> = [];
	
	public var active:Bool = true;
	public var childAdded = new Signal1(DisplayObject);
//	public var childRemoved = new Signal1(DisplayObject);
	
	public function new(display:DisplayObjectContainer) 
	{
		this.display = display;
		this.display.addEventListener(Event.ENTER_FRAME, CheckTree);
		//this.display.addEventListener(Event.EXIT_FRAME, CheckTree);
		this.display.addEventListener(Event.ADDED_TO_STAGE, CheckTree);
	}
	
	private function CheckTree(e:Event):Void 
	{
		if (display.parent != null && numChildrenRegistered != display.numChildren) {
			Update();
		}
	}
	
	public function dispose():Void
	{
		if (display != null) {
			display.removeEventListener(Event.ENTER_FRAME, CheckTree);
		}
	}
	
	function Update() 
	{
		for (c in childTraversers) {
			c.active = false;
		}
		for (c in childTrackers) {
			c.active = false;
		}
		
		for (i in 0...display.numChildren) 
		{
			var alreadyAdded:Bool = false;
			var child = display.getChildAt(i);
			for (c in childTrackers) {
				if (child == c.display) {
					c.active = true;
					alreadyAdded = true;
					break;
				}
			}
			if (!alreadyAdded) {
				for (c in childTraversers) {
					if (child == c.display) {
						c.active = true;
						alreadyAdded = true;
						break;
					}
				}
			}

			if (!alreadyAdded) {
				if (Std.is(child, DisplayObjectContainer)) {
					var traverser = new DisplaylistTraverser(cast(child));
					traverser.childAdded.add(OnChildrenAdded);
//					traverser.childRemoved.add(OnChildrenRemove);

					childTraversers.push(traverser);
				} else {
					childTrackers.push(new DisplayObjectTracker(child));
				}
				childAdded.dispatch(child);
			}
		}
		var l = childTraversers.length;
		while(--l >= 0) { //need iterate backward
			if (!childTraversers[l].active) {
				var traverserToRemove = childTraversers[l];
				traverserToRemove.childAdded.remove(OnChildrenAdded);
//				traverserToRemove.childRemoved.remove(OnChildrenRemove);
				childTraversers.splice(l, 1);
//				childRemoved.dispatch(traverserToRemove.display);
				traverserToRemove.dispose();
			}
		}
		l = childTrackers.length;
		while(--l >= 0) {
			if (!childTrackers[l].active) {
				childTrackers.splice(l, 1);
			}
		}
	}
	
	private function get_numChildrenRegistered():Int 
	{
		return childTraversers.length + childTrackers.length;
	}
	
	private function OnChildrenAdded(display:DisplayObject):Void
	{
		childAdded.dispatch(display);
	}
	
//	private function OnChildrenRemove(display:DisplayObject):Void
//	{
//		childRemoved.dispatch(display);
//	}
}

private class DisplayObjectTracker {
	public var display:DisplayObject;
	public var active:Bool = true;
	public function new(d: DisplayObject) {
		display = d;
	}
}
#end
