package com.sparkTree
{
import flash.events.Event;

/**
 * Dispatched by spark Tree.
 */
public class TreeEvent extends Event
{
	
	//--------------------------------------------------------------------------
	//
	//  Static constants
	//
	//--------------------------------------------------------------------------
	
	public static const ITEM_CLOSE:String = "itemClose";
	
	public static const ITEM_OPEN:String = "itemOpen";
	
	public static const ITEM_OPEN_START:String = "itemOpenStart";
	
	public static const ITEM_CLOSE_START:String = "itemCloseStart";
	
	//--------------------------------------------------------------------------
	//
	//  Constructor
	//
	//--------------------------------------------------------------------------
	
	public function TreeEvent(type:String, bubbles:Boolean = false, 
		cancelable:Boolean = false, item:Object = null)
	{
		super(type, bubbles, cancelable);
		
		this.item = item;
	}
	
	//--------------------------------------------------------------------------
	//
	//  Variables
	//
	//--------------------------------------------------------------------------
	
	public var item:Object;

	//--------------------------------------------------------------------------
	//
	//  Overridden methods: Event
	//
	//--------------------------------------------------------------------------
	
	/**
	 *  @private
	 */
	override public function clone():Event
	{
		return new TreeEvent(type, bubbles, cancelable,
			item);
	}
}
}