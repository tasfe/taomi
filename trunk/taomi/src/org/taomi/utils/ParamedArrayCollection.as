package org.taomi.utils
{
	import mx.collections.ArrayCollection;
	
	public class ParamedArrayCollection extends ArrayCollection
	{
		public var param:Object=new Object();
		public var total_expense:Number=-1;
		public var total_commission_num:Number=-1;
		public function ParamedArrayCollection(source:Array=null)
		{
			super(source);
		}
	}
}