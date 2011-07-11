package com.sparkTree 
{
	import mx.collections.IList;

    /**
     * @author stefan
     */
    public interface ITreeDataFlattener extends IList
    {
    	function getItemLevel(item:Object):int;
    	function isOpen(item:Object):Boolean;
    	function getItemParent(item:Object):Object;
    	
    	function openItem(item:Object):void;
    	function closeItem(item:Object):void;
    }
}
