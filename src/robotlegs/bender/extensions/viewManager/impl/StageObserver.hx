//------------------------------------------------------------------------------
//  Copyright (c) 2009-2013 the original author or authors. All Rights Reserved. 
// 
//  NOTICE: You are permitted to use, modify, and distribute this file 
//  in accordance with the terms of the license agreement accompanying it. 
//------------------------------------------------------------------------------

package robotlegs.bender.extensions.viewManager.impl;

import openfl.display.DisplayObject;
import openfl.display.DisplayObjectContainer;
import openfl.events.Event;
import org.swiftsuspenders.utils.CallProxy;

/**
 * @private
 */

@:keepSub
class StageObserver
{

	/*============================================================================*/
	/* Private Properties                                                         */
	/*============================================================================*/

	private var _filter = ~/^mx\.|^spark\.|^flash\./;
	
	private var _registry:ContainerRegistry;
	#if !flash
	var traver:DisplaylistTraverser;
	#end
	/*============================================================================*/
	/* Constructor                                                                */
	/*============================================================================*/

	/**
	 * @private
	 */
	public function new(containerRegistry:ContainerRegistry)
	{
		_registry = containerRegistry;
		// We only care about roots
		_registry.addEventListener(ContainerRegistryEvent.ROOT_CONTAINER_ADD, onRootContainerAdd);
		_registry.addEventListener(ContainerRegistryEvent.ROOT_CONTAINER_REMOVE, onRootContainerRemove);
		// We might have arrived late on the scene
		for (binding in _registry.rootBindings)
		{
			addRootListener(binding.container);
		}
	}

	/*============================================================================*/
	/* Public Functions                                                           */
	/*============================================================================*/

	/**
	 * @private
	 */
	public function destroy():Void
	{
		_registry.removeEventListener(ContainerRegistryEvent.ROOT_CONTAINER_ADD, onRootContainerAdd);
		_registry.removeEventListener(ContainerRegistryEvent.ROOT_CONTAINER_REMOVE, onRootContainerRemove);
		for (binding in _registry.rootBindings)
		{
			removeRootListener(binding.container);
		}
	}

	/*============================================================================*/
	/* Private Functions                                                          */
	/*============================================================================*/

	private function onRootContainerAdd(event:ContainerRegistryEvent):Void
	{
		addRootListener(event.container);
	}

	private function onRootContainerRemove(event:ContainerRegistryEvent):Void
	{
		removeRootListener(event.container);
	}

	private function addRootListener(container:DisplayObjectContainer):Void
	{
		#if flash
			// The magical, but extremely expensive, capture-phase ADDED_TO_STAGE listener
			container.addEventListener(Event.ADDED_TO_STAGE, onViewAddedToStage, true);
			// Watch the root container itself - nobody else is going to pick it up!
			container.addEventListener(Event.ADDED_TO_STAGE, onContainerRootAddedToStage);
		#else
			// Unfortunately OpenFL's event system doesn't support event useCapture, which is a feature 
			// that robotlegs heavily depends upon. To resolve this a brute force enter frame displaylist traver 
			// is used for all non-flash targets. This is not ideal, however it is currently our only option.
			if (traver != null) {
				traver.childAdded.remove(OnChildAdded);
				//traver.childRemoved.remove(OnChildRemoved);
			}
			traver = new DisplaylistTraverser(container);
			traver.childAdded.add(OnChildAdded);
			//traver.childRemoved.add(OnChildRemoved);
		#end
	}
	
	#if flash
		private function onViewAddedToStage(event:Event):Void
		{
			trace("onViewAddedToStage");
			var view:DisplayObject = cast(event.target, DisplayObject);
			addView(view);
		}
		
		private function onContainerRootAddedToStage(event:Event):Void
		{
			var container:DisplayObjectContainer = cast(event.target, DisplayObjectContainer);
			container.removeEventListener(Event.ADDED_TO_STAGE, onContainerRootAddedToStage);
			var type:Class<Dynamic> = Type.getClass(container);
			var binding:ContainerBinding = _registry.getBinding(container);
			trace("container = " + container);
			trace("type = " + type);
			trace("binding = " + binding);
			if (binding != null) binding.handleView(container, type);
			trace("5");
		}
	#else
		private function OnChildAdded(display:DisplayObject):Void
		{
			trace("add: " + display);
			addView(display);
		}
		
		//private function OnChildRemoved(display:DisplayObject):Void
		//{
			//trace("remove: " + display);
		//}
	#end
	
	private function removeRootListener(container:DisplayObjectContainer):Void
	{
		#if flash
			container.removeEventListener(Event.ADDED_TO_STAGE, onViewAddedToStage, true);
			container.removeEventListener(Event.ADDED_TO_STAGE, onContainerRootAddedToStage);
		#else
			if (traver != null) traver.childAdded.remove(OnChildAdded);
		#end
	}

	
	
	private function addView(view:DisplayObject):Void
	{
		// Question: would it be worth caching QCNs by view in a weak Map<Dynamic,Dynamic>,
		// to avoid CallProxy.replaceClassName() cost?
		var qcn:String = CallProxy.replaceClassName(Type.getClass(view));
		trace("qcn = " + qcn);
		// CHECK
		//var filtered:Bool = _filter.test(qcn);
		var filtered:Bool = _filter.match(qcn);
		if (filtered)
			return;
		var type:Class<Dynamic> = Type.getClass(view);
		trace("type = " + type);
		// Walk upwards from the nearest binding
		var binding:ContainerBinding = _registry.findParentBinding(view);
		trace("binding.container = " + binding.container);
		trace("binding = " + binding);
		while (binding != null)
		{
			binding.handleView(view, type);
			binding = binding.parent;
		}
	}
}
