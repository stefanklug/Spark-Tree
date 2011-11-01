package com.sparkTree
{
import spark.components.IItemRenderer;

public interface ITreeItemRenderer extends IItemRenderer
{
	/**
	 * Level in the tree hierarchy. 0 for top level items, 1 for their children
	 * and so on.
	 */
	function get level():int;
	function set level(value:int):void;
	
	function get isBranch():Boolean;
	function set isBranch(v:Boolean):void;
	
	function get isOpen():Boolean;
	function set isOpen(value:Boolean):void;
}
}