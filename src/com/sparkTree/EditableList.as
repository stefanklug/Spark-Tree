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



/**
 * This List extends the spark List with the ability to handle editing.
 * This code is inspired by the spark DataGrid component
 */
public class EditableList extends List
{
	protected var editor:ListEditor;
	
	/**
     *  @private
     *  Storage for the editable property.
     */
    private var _editable:Boolean = false;
    
    [Inspectable(category="General")]
    
    /**
     *  Determin if the list should be editable
     * 
     *  @default false
     *  
     */
    public function get editable():Boolean
    {
        return _editable;
    }
    
    /**
     *  @private
     */
    public function set editable(value:Boolean):void
    {
        _editable = value;
        if(value) {
        	editor = new ListEditor(this);
        	editor.initialize();
        }
    }
    
    //----------------------------------
    //  itemEditor
    //----------------------------------
    
    private var _itemEditor:IFactory = null;
    
    [Bindable("itemEditorChanged")]
    
    /**
     *  The default value for the GridColumn <code>itemEditor</code> property, 
     *  which specifies the IListItemEditor class used to create item editor instances.
     * 
     *  @default null.
     *
     *  @see #dataField 
     *  @see spark.components.gridClasses.IGridItemEditor
     * 
     *  @langversion 3.0
     *  @playerversion Flash 10
     *  @playerversion AIR 2.5
     *  @productversion Flex 4.5 
     */
    public function get itemEditor():IFactory
    {
        return _itemEditor;
    }
    
    /**
     *  @private
     */
    public function set itemEditor(value:IFactory):void
    {
        if (_itemEditor == value)
            return;
        
        _itemEditor = value;
        
        dispatchChangeEvent("itemEditorChanged");
    }    
        
    /**
     *  A reference to the currently active instance of the item editor, 
     *  if it exists.
     *
     *  <p>To access the item editor instance and the new item value when an 
     *  item is being edited, you use the <code>itemEditorInstance</code> 
     *  property. The <code>itemEditorInstance</code> property
     *  is not valid until the <code>itemEditorSessionStart</code> event is 
     *  dispatched.</p>
     *
     *  <p>The <code>DataGridColumn.itemEditor</code> property defines the
     *  class of the item editor and, therefore, the data type of the item
     *  editor instance.</p>
     *
     *  <p>Do not set this property in MXML.</p>
     *  
     */
    public function get itemEditorInstance():IGridItemEditor
    {
        if (editor)
            return editor.itemEditorInstance;
        
        return null; 
    }
    
    /**
     *  Starts an editor session on a selected cell in the grid.
     * 
     *  A <code>startItemEditorSession</code> event is dispatched before
     *  an item editor is created. This allows a listener dynamically change 
     *  the item editor for a specified cell. 
     * 
     *  The event can also be cancelled by calling the 
     *  <code>preventDefault()</code> method, to prevent the 
     *  editor session from being created.
     * 
     *  @param rowIndex The zero-based row index of the cell to edit.
     *
     *  @param columnIndex The zero-based column index of the cell to edit.  
     * 
     *  @return <code>true</code> if the editor session was started. 
     *  Returns <code>false</code> if the editor session was cancelled.
     * 
     *  @langversion 3.0
     *  @playerversion Flash 10
     *  @playerversion AIR 2.5
     *  @productversion Flex 4.5
     *  
     */ 
    public function startItemEditorSession(rowIndex:int, columnIndex:int):Boolean
    {
        if (editor)
            return editor.startItemEditorSession(rowIndex, columnIndex);
        
        return false;
    }
    
    /**
     *  Closes the currently active editor and optionally saves the editor's value
     *  by calling the item editor's <code>save()</code> method.  
     *  If the <code>cancel</code> parameter is <code>true</code>,
     *  then the editor's <code>cancel()</code> method is called instead.
     * 
     *  @param cancel If <code>false</code>, the data in the editor is saved. 
     *  Otherwise the data in the editor is discarded.
     *
     *  @return <code>true</code> if the editor session was saved, 
     *  and <code>false</code> if the save was cancelled.  
     * 
     *  @langversion 3.0
     *  @playerversion Flash 10
     *  @playerversion AIR 2.5
     *  @productversion Flex 4.5
     */ 
    public function endItemEditorSession(cancel:Boolean = false):Boolean
    {
        if (editor)
            return editor.endItemEditorSession(cancel);
        
        return false;
    }
}