package com.sparkTree 
{
	import mx.collections.IList;

    /**
     * @author stefan
     */
    public interface ITreeDataFlattener extends IList
    {
    	function isOpen(item:Object):Boolean;
    	
    	function getItemLevel(item:Object):int;
    	function getItemParent(item:Object):Object;
    	/**
		 * returns the path to the given item as Array of items.
		 * The item itself is included
		 */
		function getItemPath(item:Object):Array;
    	
    	function openItem(item:Object):void;
    	function closeItem(item:Object):void;
    }
}
