package com.sparkTree
{
import flash.display.DisplayObjectContainer;
import flash.events.Event;
import flash.events.IEventDispatcher;

import mx.collections.ICollectionView;
import mx.events.CollectionEvent;
import mx.events.CollectionEventKind;
import mx.events.PropertyChangeEvent;
import mx.styles.IStyleClient;

import spark.components.supportClasses.ItemRenderer;

/**
 * Base class for all Spark Tree item renderers. Provides various properties
 * that can be used in descendant's UI.
 * 
 * <p>Watches the <code>data</code> children collection for modifications
 * <a href="https://github.com/kachurovskiy/Spark-Tree/issues#issue/2">and 
 * updates renderer when it changes</a>.</p>
 */
public class TreeItemRenderer extends ItemRenderer implements ITreeItemRenderer
{
	
	//--------------------------------------------------------------------------
	//
	//  Constructor
	//
	//--------------------------------------------------------------------------
	
	public function TreeItemRenderer()
	{
		super();
		addEventListener(Event.ADDED_TO_STAGE, addedToStage);
	}
	
	//--------------------------------------------------------------------------
	//
	//  Variables
	//
	//--------------------------------------------------------------------------
	
	private var _tree:Tree;
	
	//--------------------------------------------------------------------------
	//
	//  Overriden properties
	//
	//--------------------------------------------------------------------------
	
	//--------------------------------------------------------------------------
	//
	//  Implementation of ITreeItemRenderer: properties
	//
	//--------------------------------------------------------------------------
	
	//----------------------------------
	//  level
	//----------------------------------

	protected var _level:int = 0;
	
	[Bindable("levelChange")]
	public function get level():int
	{
		return _level;
	}
	
	public function set level(value:int):void
	{
		if (_level == value)
			return;
		
		_level = value;
		dispatchEvent(new Event("levelChange"));
	}
	
	/**
	 * convenience function to get the owner
	 */
	[Bindable("treeChange")]
	public function get tree():Tree {
		return _tree;
	}
	
	/**
	 * convenience function to get the owner
	 */
	public function set tree(t:Tree):void {
		if (_tree == t)
			return;
		
		_tree = t;
		dispatchEvent(new Event("treeChange"));
	}
	

	//----------------------------------
	//  isBranch
	//----------------------------------

	protected var _isBranch:Boolean = false;
	
	[Bindable("isBranchChange")]
	public function get isBranch():Boolean
	{
		return _isBranch;
	}
	
	public function set isBranch(value:Boolean):void
	{
		if (_isBranch == value)
			return;
		
		_isBranch = value;
		dispatchEvent(new Event("isBranchChange"));
	}
	
	
	//----------------------------------
	//  isOpen
	//----------------------------------
	
	protected var _isOpen:Boolean = false;
	
	[Bindable("isOpenChange")]
	public function get isOpen():Boolean
	{
		return _isOpen;
	}
	
	public function set isOpen(value:Boolean):void
	{
		if (_isOpen == value)
			return;
		
		_isOpen = value;
		dispatchEvent(new Event("isOpenChange"));
	}
	
	//--------------------------------------------------------------------------
	//
	//  Overriden methods
	//
	//--------------------------------------------------------------------------
	
	override protected function updateDisplayList(unscaledWidth:Number, unscaledHeight:Number):void
	{
		super.updateDisplayList(unscaledWidth, unscaledHeight);
	}
	
	//--------------------------------------------------------------------------
	//
	//  Methods
	//
	//--------------------------------------------------------------------------
	
	public function toggle():void
	{
		tree.expandItem(data, !_isOpen);
	}
	
	
	//--------------------------------------------------------------------------
	//
	//  Event handlers
	//
	//--------------------------------------------------------------------------

	private function addedToStage(event:Event):void
	{
		var container:DisplayObjectContainer = owner;
		while (!(container is Tree) && container)
		{
			container = container.parent;
		}
		tree = Tree(container);
		callPostInitialize();
	}
	
	override public function set data(v:Object):void {
		super.data = v;
		callPostInitialize();
	}
	
	/*
	 * this gets called as soon as tree and data is valid
	 */
	protected function postInitialize():void {
		isBranch = tree.treeDataProvider.isBranch(data);
	}
	
	protected function callPostInitialize():void {
		if(!tree) return;
		if(!data) return;
		
		postInitialize();
	}
}
}