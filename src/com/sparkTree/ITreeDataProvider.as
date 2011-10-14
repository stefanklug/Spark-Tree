package com.sparkTree 
{
	import mx.collections.IList;

    /**
     * 
     * @author stefan
     */
    public interface ITreeDataProvider
    {
    	/*
    	 * return true if the node is a Branch (can be opened)
    	 */
    	function isBranch(node:Object):Boolean;
    	
    	/*
    	 * return the list of childrens for the given node
    	 */
    	function getChildren(node:Object):IList;
    	
    	/**
    	 * removes the child from the given parent at the given index.
    	 * parent is included as paramater, to remove the need for a node to know its parent.
    	 */
    	function removeChildAt(parent:Object, index:int):void
    	
    	/**
    	 * Adds the given object as child of the given parent at the given position
    	 */
    	function addChildAt(parent:Object, newChild:Object, index:int):void;
    	
    	/**
    	 * moves a node. This is only called, when moving inside one TreeDataProvider
    	 */
    	function moveNode(srcParent:Object, srcIndex:int, dstParent:Object, dstIndex:int):void
    }
}
