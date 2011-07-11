package com.sparkTree 
{
	import spark.layouts.supportClasses.DropLocation;

    /**
     * @author stefan
     */
    public class TreeDropLocation extends DropLocation
    {
    	//the parent node, where to drop. null, if dropping into root
    	public var dropParent:Object;
    }
}
