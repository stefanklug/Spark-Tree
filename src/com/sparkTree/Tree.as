package com.sparkTree
{
import flash.events.Event;
import flash.events.KeyboardEvent;
import flash.geom.Point;
import flash.ui.Keyboard;

import mx.collections.IList;
import mx.core.ClassFactory;
import mx.core.FlexGlobals;
import mx.core.IVisualElement;
import mx.core.mx_internal;
import mx.core.DragSource;
import mx.events.DragEvent;
import mx.styles.CSSStyleDeclaration;
import mx.managers.DragManager;
import mx.events.CollectionEvent;

import spark.components.List;
import spark.layouts.supportClasses.DropLocation;

use namespace mx_internal;

//--------------------------------------
//  Events
//--------------------------------------

/**
 *  Dispatched when a branch is closed or collapsed.
 */
[Event(name="itemClose", type="com.sparkTree.TreeEvent")]

/**
 *  Dispatched when a branch is opened or expanded.
 */
[Event(name="itemOpen", type="com.sparkTree.TreeEvent")]

/**
 *  Dispatched when a branch open or close is initiated.
 */
[Event(name="itemOpening", type="com.sparkTree.TreeEvent")]

/**
 * Custom Spark Tree that is based on Spark List. Supports most of MX Tree
 * features and does not have it's bugs.
 */
public class Tree extends List
{
	
	//--------------------------------------------------------------------------
	//
	//  Constructor
	//
	//--------------------------------------------------------------------------
	
	public function Tree()
	{
		super();
		itemRenderer = new ClassFactory(DefaultTreeItemRenderer);
	}
	
	//--------------------------------------------------------------------------
	//
	//  Variables
	//
	//--------------------------------------------------------------------------
	
	
	
	private var refreshRenderersCalled:Boolean = false;
	
	private var renderersToRefresh:Vector.<ITreeItemRenderer> = new Vector.<ITreeItemRenderer>();
	
	//--------------------------------------------------------------------------
	//
	//  Properties
	//
	//--------------------------------------------------------------------------
	
	
	//----------------------------------
	//  dataProvider
	//----------------------------------
	
	private var _treeDataProvider:ITreeDataProvider;
	private var _dataFlattener:ITreeDataFlattener;
	
	override public function get dataProvider():IList
	{
		return _dataFlattener;
	}
	
	override public function set dataProvider(value:IList):void
	{
		if(!value is ITreeDataFlattener) {
			throw new Error("The dataProvider of a Tree is handled automatically. Use treeDataProvider instead.");
		}
		if (_dataFlattener)
		{
			_dataFlattener.removeEventListener(TreeEvent.ITEM_CLOSE, dataProvider_someHandler);
			_dataFlattener.removeEventListener(TreeEvent.ITEM_OPEN, dataProvider_someHandler);
		}
		
		_dataFlattener = ITreeDataFlattener(value);
		super.dataProvider = value;
		
		if (_dataFlattener)
		{
			_dataFlattener.addEventListener(CollectionEvent.COLLECTION_CHANGE, onCollectionChange);
			_dataFlattener.addEventListener(TreeEvent.ITEM_CLOSE, dataProvider_someHandler);
			_dataFlattener.addEventListener(TreeEvent.ITEM_OPEN, dataProvider_someHandler);
		}
	}
	
	protected function onCollectionChange(e:CollectionEvent):void {
		trace("collection change "+e.kind+" "+e.location +" "+e.items);
	}
	
	public function get treeDataProvider():ITreeDataProvider
	{
		return _treeDataProvider;
	}
	
	public function set treeDataProvider(value:ITreeDataProvider):void
	{
		_treeDataProvider = value;
		dataProvider = new TreeDataFlattener(value);
	}
	
	
	//--------------------------------------------------------------------------
	//
	//  Overriden methods
	//
	//--------------------------------------------------------------------------
	
	override public function updateRenderer(renderer:IVisualElement, itemIndex:int, data:Object):void
	{
		itemIndex = _dataFlattener.getItemIndex(data);
		
		super.updateRenderer(renderer, itemIndex, data);
		
		var treeItemRenderer:ITreeItemRenderer = ITreeItemRenderer(renderer);
		treeItemRenderer.level = _dataFlattener.getItemLevel(data);
		treeItemRenderer.isOpen = _dataFlattener.isOpen(data);
	}
	
	override protected function updateDisplayList(unscaledWidth:Number, unscaledHeight:Number):void
	{
		super.updateDisplayList(unscaledWidth, unscaledHeight);
		
		// refresh all renderers or only some of them
		var n:int;
		var i:int;
		var renderer:ITreeItemRenderer;
		if (refreshRenderersCalled)
		{
			refreshRenderersCalled = false;
			n = dataGroup.numElements;
			for (i = 0; i < n; i++)
			{
				renderer = dataGroup.getElementAt(i) as ITreeItemRenderer;
				if (renderer)
					updateRenderer(renderer, renderer.itemIndex, renderer.data);
			}
		}
		else if (renderersToRefresh.length > 0)
		{
			n = renderersToRefresh.length;
			for (i = 0; i < n; i++)
			{
				renderer = renderersToRefresh[i];
				updateRenderer(renderer, renderer.itemIndex, renderer.data);
			}
		}
		if (renderersToRefresh.length > 0)
			renderersToRefresh.splice(0, renderersToRefresh.length);
	}
	
	/**
	 * Handle <code>Keyboard.LEFT</code> and <code>Keyboard.RIGHT</code> as tree
	 * node collapsing and expanding.
	 */
	override protected function adjustSelectionAndCaretUponNavigation(event:KeyboardEvent):void
	{
		super.adjustSelectionAndCaretUponNavigation(event);
		
		if (!selectedItem)
			return;
		
		var navigationUnit:uint = mapKeycodeForLayoutDirection(event);
		if (navigationUnit == Keyboard.LEFT)
		{
			if (_dataFlattener.isOpen(selectedItem))
			{
				expandItem(selectedItem, false);
			}
			else
			{
				var parent:Object = _dataFlattener.getItemParent(selectedItem);
				if (parent)
					selectedItem = parent;
			}
		}
		else if (navigationUnit == Keyboard.RIGHT)
		{
			expandItem(selectedItem);
		}
	}
		
	//--------------------------------------------------------------------------
	//
	//  Methods
	//
	//--------------------------------------------------------------------------
	
	public function expandItem(item:Object, open:Boolean = true):void
	{
		if (open)
			_dataFlattener.openItem(item);
		else
			_dataFlattener.closeItem(item);
	}
	
	public function refreshRenderers():void
	{
		refreshRenderersCalled = true;
		invalidateDisplayList();
	}
	
	public function refreshRenderer(renderer:ITreeItemRenderer):void
	{
		renderersToRefresh.push(renderer);
		invalidateDisplayList();
	}
	
	//--------------------------------------------------------------------------
	//
	//  Overriden event handlers
	//
	//--------------------------------------------------------------------------

	override protected function dragDropHandler(event:DragEvent):void
    {
        if (event.isDefaultPrevented())
            return;
        
        // Hide the drop indicator
        layout.hideDropIndicator();
        destroyDropIndicator();
        
        // Hide focus
        drawFocus(false);
        drawFocusAnyway = false;
        
        // Get the dropLocation
        var dropLocation:TreeDropLocation = TreeDropLocation(calculateDropLocation(event));
        if (!dropLocation)
            return;
        
        // Find the dropIndex
        var dropIndex:int = dropLocation.dropIndex;
        var dropParent:Object = dropLocation.dropParent;
        
        // Make sure the manager has the appropriate action
        DragManager.showFeedback(event.ctrlKey ? DragManager.COPY : DragManager.MOVE);
        
        var dragSource:DragSource = event.dragSource;
        var items:Vector.<Object> = dragSource.dataForFormat("itemsByIndex") as Vector.<Object>;

        var caretIndex:int = -1;
        if (dragSource.hasFormat("caretIndex"))
            caretIndex = event.dragSource.dataForFormat("caretIndex") as int;
        
        // Clear the selection first to avoid extra work while adding and removing items.
        // We will set a new selection further below in the method.
        setSelectedIndices(new Vector.<int>(), false);
        validateProperties(); // To commit the selection
        
        var newSelectedItems:Vector.<Object> = new Vector.<Object>();
        
        // If we are reordering the list, remove the items now,
        // adjusting the dropIndex in the mean time.
        // If the items are drag moved to this list from a different list,
        // the drag initiator will remove the items when it receives the
        // DragEvent.DRAG_COMPLETE event.
        if (dragMoveEnabled &&
            event.action == DragManager.MOVE &&
            event.dragInitiator == this)
        {
            //convert the indices to nodes and parents as the indices will change by the move operation
            var parentAndNode:Vector.<Object> = new Vector.<Object>();
            
            //ise forEach as vector.map is buggy
            items.forEach(function(item:Object, index:int, vector:Vector.<Object>):void {
            	parentAndNode.push({ parent: _dataFlattener.getItemParent(item), item:item });
            });
            
            //move the items
            parentAndNode.forEach(function(item:Object, index:int, vector:Vector.<Object>):void {
            	//get the index, as it might have changed by the previous move
            	var idx:int = treeDataProvider.getChildren(item.parent).getItemIndex(item.item);
            	treeDataProvider.moveNode(item.parent, idx, dropParent, dropIndex);
            	dropIndex++;
            	newSelectedItems.push(item.item);
            });
        } else {
        	//inserting items if drag copy or from other source
        	var copyItems:Boolean = (event.action == DragManager.COPY);
        	
        	items.forEach(function(item:Object, index:int, vector:Vector.<Object>):void {
        		if (copyItems)
                	item = copyItemWithUID(item);
                	
            	treeDataProvider.addChildAt(dropParent, item, dropIndex);
            	dropIndex++;
            	newSelectedItems.push(item);
            });
        }
        
        
        
        // Drop the items at the dropIndex
        var newSelection:Vector.<int> = new Vector.<int>();
        newSelectedItems.forEach(function(item:Object, index:int, vector:Vector.<Object>):void {
        	var idx:int = _dataFlattener.getItemIndex(item);
        	if(idx != -1) newSelection.push(idx);
        });

        // Set the selection
        setSelectedIndices(newSelection, false);

        // Scroll the caret index in view
        if (caretIndex != -1 && newSelection.length > 0)
        {        	
            // Sometimes we may need to scroll several times as for virtual layouts
            // this is not guaranteed to bring in the element in view the first try
            // as some items in between may not be loaded yet and their size is only
            // estimated.
            var delta:Point;
            var loopCount:int = 0;
            while (loopCount++ < 10)
            {
                validateNow();
                delta = layout.getScrollPositionDeltaToElement(newSelection[0] + caretIndex);
                if (!delta || (delta.x == 0 && delta.y == 0))
                    break;
                layout.horizontalScrollPosition += delta.x;
                layout.verticalScrollPosition += delta.y;
            }
        }
    }
    
    /**
     * copy from spark.components.List
     */
    private function calculateDropLocation(event:DragEvent):DropLocation
    {
        // Verify data format
        if (!enabled || !event.dragSource.hasFormat("itemsByIndex"))
            return null;
        
        // Calculate the drop location
        return layout.calculateDropLocation(event);
    }
	
	//--------------------------------------------------------------------------
	//
	//  Event handlers
	//
	//--------------------------------------------------------------------------

	private function dataProvider_someHandler(event:TreeEvent):void
	{
		if (dataGroup) {
			var idx:int = _dataFlattener.getItemIndex(event.item);
			var renderer:ITreeItemRenderer = dataGroup.getElementAt(idx) as ITreeItemRenderer;
			trace("refresh "+idx);
			refreshRenderer(renderer);
		}
	}
	
}
}
