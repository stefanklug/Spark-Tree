/* Copyright (c) 2010 Maxim Kachurovskiy

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE. */

package com.sparkTree
{
import flash.events.EventDispatcher;
import flash.utils.Dictionary;

import mx.collections.ICollectionView;
import mx.collections.IList;
import mx.collections.IViewCursor;
import mx.collections.ISort;
import mx.events.CollectionEvent;
import mx.events.CollectionEventKind;
import mx.events.PropertyChangeEvent;
import mx.events.PropertyChangeEventKind;

//--------------------------------------
//  Events
//--------------------------------------

/**
 *  Dispatched when a branch is closed or collapsed.
 */
[Event(name="itemClose", type="TreeEvent")]

/**
 *  Dispatched when a branch is opened or expanded.
 */
[Event(name="itemOpen", type="TreeEvent")]

/**
 *  Dispatched when a branch open or close is initiated.
 */
[Event(name="itemOpenStart", type="TreeEvent")]

[Event(name="itemCloseStart", type="TreeEvent")]

/**
 * Special implementation of <code>IList</code> that server as a 
 * <code>dataProvider</code> for spark <code>Tree</code>.
 * Flattens given <code>ArrayCollection</code> so that it can be used in default
 * spark <code>List</code>.
 */
public class TreeDataFlattener extends EventDispatcher implements ITreeDataFlattener
{
	
	protected var _rootItem:Object;
	protected var _dataProvider:ITreeDataProvider;
	protected var _subTrees:Array;
	protected var _localItems:IList;
	
	
	public function TreeDataFlattener(dataProvider:ITreeDataProvider, rootItem:Object = null)
	{
		_subTrees = new Array();
		_dataProvider = dataProvider;
		_rootItem = rootItem;
		
		if(_localItems) {
			_localItems.removeEventListener(CollectionEvent.COLLECTION_CHANGE, onLocalItemsCollectionChange);
		}
		_localItems = dataProvider.getChildren(rootItem);
		_localItems.addEventListener(CollectionEvent.COLLECTION_CHANGE, onLocalItemsCollectionChange, false, 0, true);
	}
	
	
	
	public function get dataProvider():ITreeDataProvider {
		return _dataProvider;
	}
	
	public function getSubtree(index:int):ITreeDataFlattener {
		if(_subTrees.length <= index) {
			return null;
		}
		
		return _subTrees[index] as ITreeDataFlattener;
	}
	
	[Bindable("collectionChange")]
	public function get length():int
	{
		var l:int = _localItems.length;
		_subTrees.forEach(function(item:Object, index:int, array:Array):void {
			if(item is ITreeDataFlattener){
				l += ITreeDataFlattener(item).length;
			}
		});
		return l;
	}

	//--------------------------------------------------------------------------
	//
	//  Implementation of IList: methods
	//
	//--------------------------------------------------------------------------
	
	public function addItem(item:Object):void
	{
		throw new Error("Inserting through TreeDataFlattener is not possible. Use the DataDescriptor to modify the underlying data.")
	}
	
	public function addItemAt(item:Object, index:int):void
	{
		throw new Error("Inserting through TreeDataProvider is not possible. Use the DataDescriptor to modify the underlying data.")
	}
	
	public function getItemAt(index:int, prefetch:int=0):Object
	{
		if (index < 0 || index >= length)
			throw new Error("index " + index + " is out of bounds");

		var localIndex:int = 0;
		var virtualIndex:int = 0;
		
		for(localIndex=0; localIndex < _localItems.length; localIndex++) {
			if(virtualIndex == index) {
				return _localItems.getItemAt(localIndex, prefetch);
			}
			
			var subtree:ITreeDataFlattener = getSubtree(localIndex);
			var sublength:int = 0;
			//check if the requested index is in the subtree
			if(subtree) sublength = subtree.length;
			if(sublength == 0) {
				virtualIndex++;
				continue;
			} else {
				virtualIndex++;
				var subindex:int = index - virtualIndex;
				if(subindex < sublength) {
					//the requested item is inside this subtree
					return subtree.getItemAt(subindex, prefetch);
				} else {
					//the requested item is not in this subtree, continue to the next local item
					virtualIndex += subtree.length;
					continue;
				}
			}
		}
		
		throw new Error("something went wrong in getItemAt");
	}
	
	public function getItemIndex(item:Object):int {
		//do a depth first search
		var virtualIndex:int = 0;
		var localIndex:int = 0;
		var ll:int = _localItems.length;
		
		while(localIndex < ll) {
			if(_localItems.getItemAt(localIndex) == item) {
				return virtualIndex;
			}
			
			var subtree:ITreeDataFlattener = getSubtree(localIndex);
			var sublength:int = 0;
			if(subtree) sublength = subtree.length;
			
			virtualIndex++;
			localIndex++;
			
			if(sublength == 0) {
				continue;
			} else {
				//check the subtree
				var subindex:int = subtree.getItemIndex(item);
				if(subindex > -1) {
					return virtualIndex + subindex;
				}
				//not found so continue
				virtualIndex += sublength;
			}
		}
		
		return -1;
	}
	
	public function itemUpdated(item:Object, property:Object = null, 
		oldValue:Object = null, newValue:Object = null):void
	{
		trace("itemUpdated is not implemented!");
	}
	
	public function removeAll():void
	{
		throw new Error("Removing through TreeDataProvider is not possible. Use the DataDescriptor to modify the underlying data.")
	}
	
	public function removeItemAt(index:int):Object
	{
		throw new Error("Removing through TreeDataProvider is not possible. Use the DataDescriptor to modify the underlying data.")
	}
	
	public function setItemAt(item:Object, index:int):Object
	{
		throw new Error("Insertig through TreeDataProvider is not possible. Use the DataDescriptor to modify the underlying data.")
	}
	
	public function toArray():Array
	{
		var result:Array = [];
		var localIndex:int = 0;
		for(localIndex=0; localIndex < _localItems.length; localIndex++) {
			result.push(_localItems.getItemAt(localIndex));
			var subtree:ITreeDataFlattener = getSubtree(localIndex);
			if(subtree) {
				result = result.concat(subtree.toArray());
			}
		}
		return result;
	}
	
	protected function internalOpenItem(item:Object):Boolean {
		var localIndex:int = _localItems.getItemIndex(item);
		if(localIndex > -1) {
			
			var treeEvent:TreeEvent;
			treeEvent = new TreeEvent(TreeEvent.ITEM_OPEN_START, false, true, item);
			dispatchEvent(treeEvent);
			if (treeEvent.isDefaultPrevented()) {
				return false;
			}
			
			addSubtreeAt(new TreeDataFlattener(dataProvider, item), localIndex);
			
			treeEvent = new TreeEvent(TreeEvent.ITEM_OPEN, false, false, item);
			dispatchEvent(treeEvent);

			return true;
		}
		
		for each(var subtree:Object in _subTrees) {
			if(!subtree) continue;
			
			if(TreeDataFlattener(subtree).internalOpenItem(item)) {
				return true;
			}
		}
		
		return false;
	}
	
	protected function internalCloseItem(item:Object):Boolean {
		var localIndex:int = _localItems.getItemIndex(item);
		if(localIndex > -1) {
			var treeEvent:TreeEvent;
			treeEvent = new TreeEvent(TreeEvent.ITEM_CLOSE_START, false, true, item);
			dispatchEvent(treeEvent);
			if (treeEvent.isDefaultPrevented()) {
				return false;
			}
			
			removeSubtreeAt(localIndex);
			
			treeEvent = new TreeEvent(TreeEvent.ITEM_CLOSE, false, false, item);
			dispatchEvent(treeEvent);
			
			return true;
		}
		
		for each(var subtree:Object in _subTrees) {
			if(!subtree) continue;
			
			if(TreeDataFlattener(subtree).internalCloseItem(item)) {
				return true;
			}
		}
		
		return false;
	}
	
	protected function addSubtreeAt(subtree:ITreeDataFlattener, index:int, dispatchEvt:Boolean = true):void {
		removeSubtreeAt(index);
		
		_subTrees[index] = subtree;
		
		subtree.addEventListener(CollectionEvent.COLLECTION_CHANGE, onSubtreeCollectionChange, false, 0, true);
		subtree.addEventListener(TreeEvent.ITEM_OPEN, onSubtreeTreeEvent, false, 0, true);
		subtree.addEventListener(TreeEvent.ITEM_CLOSE, onSubtreeTreeEvent, false, 0, true);
		
		if(dispatchEvt) {
			var e:CollectionEvent = new CollectionEvent(CollectionEvent.COLLECTION_CHANGE,
														false,
														false,
														CollectionEventKind.ADD,
														getSubtreeStartIndex(index),
														-1,
														subtree.toArray());
			dispatchEvent(e);
		}
	}
	
	protected function removeSubtreeAt(index:int, dispatchEvt:Boolean = true):ITreeDataFlattener {
		var subtree:ITreeDataFlattener = getSubtree(index);
		if(!subtree) return null;
		
		_subTrees[index] = null;
		
		subtree.removeEventListener(CollectionEvent.COLLECTION_CHANGE, onSubtreeCollectionChange);
		subtree.removeEventListener(TreeEvent.ITEM_OPEN, onSubtreeTreeEvent);
		subtree.removeEventListener(TreeEvent.ITEM_CLOSE, onSubtreeTreeEvent);
		
		if(dispatchEvt) {
			var e:CollectionEvent = new CollectionEvent(CollectionEvent.COLLECTION_CHANGE,
														false,
														false,
														CollectionEventKind.REMOVE,
														getSubtreeStartIndex(index),
														-1,
														subtree.toArray());
			dispatchEvent(e);
		}
		return subtree;
	}
	
	protected function removeAllSubtrees(dispatchEvent:Boolean = true):void {
		for(var i:int = 0; i<_subTrees.length; i++) {
			removeSubtreeAt(i,dispatchEvent);
		}
		_subTrees = new Array();
	}
	
	protected function getVirtualIndex(localIndex:int):int {
		var index:int;
		var result:int = 0;
		//add all preceding items
		for(index=0; index < localIndex; index++) {
			//the item
			result++;
			var subtree:ITreeDataFlattener = getSubtree(index);
			if(subtree) {
				result += subtree.length;
			}
		}
		
		return result;
	}
	
	//returns the virtual index of the subtree at the given local index
	protected function getSubtreeStartIndex(index:int):int {
		return getVirtualIndex(index)+1;
	}
	
	protected function onSubtreeTreeEvent(e:TreeEvent):void {
		dispatchEvent(e);
	}
	
	protected function onSubtreeCollectionChange(e:CollectionEvent):void {
		
		var clone:CollectionEvent = CollectionEvent(e.clone());
		var subtree:ITreeDataFlattener;
		var localIndex:int = -1;
		
		//find the subtree index
		for(var i:int = 0; i<_subTrees.length; i++) {
			if(e.target == _subTrees[i]) {
				subtree = ITreeDataFlattener(e.target);
				localIndex = i;
				break;
			}
		}
		
		if(localIndex < 0) throw new Error("Couldn't find subtree");
		
		var offset:int = getSubtreeStartIndex(localIndex);
		
		if(clone.location > -1) clone.location += offset;
		if(clone.oldLocation > -1) clone.oldLocation += offset;
		
		dispatchEvent(clone);
	}
	
	protected function onLocalItemsCollectionChange(e:CollectionEvent):void {
		//finde the target
		var clone:CollectionEvent = CollectionEvent(e.clone());
		var items:Array;
		var i:int;
		var subtree:ITreeDataFlattener;
		
		switch(e.kind) {
			case CollectionEventKind.ADD:
				//move the subtrees and dispatch an updated event
				if(_subTrees.length > e.location) {
					var tail:Array = _subTrees.splice(e.location, int.MAX_VALUE);
					_subTrees = _subTrees.concat(new Array(e.items.length));
					_subTrees = _subTrees.concat(tail);
				}
				clone.location = getVirtualIndex(e.location);
				dispatchEvent(clone);
				return;
				
			case CollectionEventKind.REMOVE:
				//remove the subtrees and dispatch an updated event with all the items
				var localIndex:int = e.location;
				items = new Array();
				for(i = 0; i < e.items.length; i++) {
					items.push(e.items[i]);
					subtree = removeSubtreeAt(i+e.location, false);
					if(subtree) {
						items = items.concat(subtree.toArray());
					}
				}
				_subTrees.splice(e.location, e.items.length);
				clone.location = getVirtualIndex(e.location);
				clone.items = items;
				dispatchEvent(clone);
				return;
				
			case CollectionEventKind.MOVE:
				//make sure the subtrees array is big enough
				var diff:int = _localItems.length - _subTrees.length;
				if(diff > 0) _subTrees = _subTrees.concat(new Array(diff));
				
				clone.oldLocation = getVirtualIndex(e.oldLocation);
				
				//apply the move to the subtrees
				var toMove:Array = _subTrees.splice(e.oldLocation, e.items.length);
				var rest:Array = _subTrees.splice(e.location, int.MAX_VALUE);
				_subTrees = _subTrees.concat(toMove);
				_subTrees = _subTrees.concat(rest);
				
				clone.location = getVirtualIndex(e.location);
								
				//rebuild items array
				items = new Array();
				for(i = 0; i < e.items.length; i++) {
					items.push(e.items[i]);
					subtree = getSubtree(i+e.location);
					if(subtree) {
						items = items.concat(subtree.toArray());
					}
				}
				
				clone.items = items;
				dispatchEvent(clone);
				return;
				
			case CollectionEventKind.REFRESH:
				//refresh is handled like a reset
				clone.kind = CollectionEventKind.RESET;
				clone.items = [];
				clone.location = -1;
				//no break to fall through
			case CollectionEventKind.RESET:
				removeAllSubtrees();
				dispatchEvent(clone);
				return;
				
			case CollectionEventKind.REPLACE:
				//remove the subtrees with corresponding events
				for(i = 0; i < e.items.length; i++) {
					subtree = removeSubtreeAt(i+e.location, true);
				}
				clone.location = getVirtualIndex(e.location);
				dispatchEvent(clone);
				return;
				
			case CollectionEventKind.UPDATE:
				//TODO it might be needed to reload the subtree if the item is open
				clone.location = getVirtualIndex(e.location);
				dispatchEvent(clone);
				return;
			
				
		}
	}
	
	public function openItem(item:Object):void
	{
		if(!item || isOpen(item)) return;
		if(!internalOpenItem(item)) throw new Error("Couldn't find item");
	}
	
	public function closeItem(item:Object):void
	{
		if(!item || !isOpen(item)) return;
		if(!internalCloseItem(item)) throw new Error("Couldn't find item");
	}
	
	
	
	public function isOpen(item:Object):Boolean
	{
		return internalIsOpen(item) > 0;
	}
	
	protected function internalIsOpen(item:Object):int {
		var localIndex:int = _localItems.getItemIndex(item);
		if(localIndex > -1) {
			return getSubtree(localIndex) != null ? 1 : 0;
		}
		
		for each(var subtree:Object in _subTrees) {
			if(!subtree) continue;
			
			var res:int = TreeDataFlattener(subtree).internalIsOpen(item);
			if(res > -1) return res;
		}
		
		return -1;
	}
	
	public function getItemLevel(item:Object):int
	{
		var localIndex:int = _localItems.getItemIndex(item);
		if(localIndex > -1) {
			return 0;
		}
		
		for each(var subtree:Object in _subTrees) {
			if(!subtree) continue;
			
			var res:int = ITreeDataFlattener(subtree).getItemLevel(item);
			if(res > -1) return res+1;
		}
		
		return -1;
	}
	
	public function getItemParent(item:Object):Object
	{
		if(item == null) return null;
		var localIndex:int = _localItems.getItemIndex(item);
		if(localIndex > -1) {
			return _rootItem;
		}
		
		for each(var subtree:Object in _subTrees) {
			if(!subtree) continue;
			
			var res:Object = ITreeDataFlattener(subtree).getItemParent(item);
			if(res != null) return res;
		}
		
		return null;
	}
}
}