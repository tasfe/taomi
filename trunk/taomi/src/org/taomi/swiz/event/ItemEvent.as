package org.taomi.swiz.event
{
	import flash.events.Event;
	
	import org.taomi.swiz.entity.Item;
	


	public class ItemEvent extends Event
	{
		public var item:Item;
		public var param:Object;
		public static const SEARCH_ITEM:String="search_item";
		public static const CLOSE_SEARCH_ITEM_TAB:String="close_search_item_tab";
		public static const CHANGE_SEARCH_SORT:String="change_search_sort";
		public static const ANALYSIS_SEARCHED_ITEMS_SAME_STORE:String="analysis_searched_items_same_store"
		public static const S_D_RESULT_TOTAL_EXPENSE_ASC:String="store_divide_result_total_expense_ASC";
		public static const S_D_RESULT_TOTAL_COMMISSION_NUM_DESC:String="store_divide_result_total_commission_num_desc";
		public static const SEARCH_ITEMS_COMPLETE:String="search_items_complete";
		public static const PREV_ITEMS_RESULT_PAGE:String="prev_item_result_page";
		public static const NEXT_ITEMS_RESULT_PAGE:String="next_item_result_page";
		public static const TO_PAGE:String="to_page";
		public function ItemEvent(type:String, item:Item=null, p:Object=null)
		{
			super(type, true, true);
			this.item=item;
			param=p;
		}

		override public function clone():Event
		{
			return new ItemEvent(type, item,param);
		}

	}
}