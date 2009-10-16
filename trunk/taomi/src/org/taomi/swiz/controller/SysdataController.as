package org.taomi.swiz.controller
{
	import mx.collections.ArrayCollection;
	import mx.collections.Sort;
	import mx.collections.SortField;
	import mx.rpc.events.ResultEvent;
	
	import org.swizframework.controller.AbstractController;
	import org.taomi.utils.APIUtils;
	import org.taomi.utils.DBUtils;

	public class SysdataController extends AbstractController
	{
		[Autowire]
		public var dbutils:DBUtils;
		[Autowire]
		public var apiutils:APIUtils;
		private static const GET_CATS_SQL:String="select cid,name,sort_order from category";
		private static const GET_CITY_SQL:String="select * from area where area_type=3";
		private static const INSERT_CAT_SQL:String="INSERT INTO category (cid,parent_cid,name,is_parent,sort_order,status) VALUES ('@','@','@',@,@,'@')";
		private static const GET_PROVINCES_SQL:String="select * from area where area_type=1 or area_type=2";
		private static const INSERT_AREA_SQL:String="INSERT INTO area (area_id,area_type,area_name,parent_id,zip) VALUES ('@','@','@','@','@')";
		[Bindable]
		public var cats_arr:Array;
		[Bindable]
		public var provinces_arr:Array;
		[Bindable]
		public var city_arr:Array;

		[Mediate(event="SysEvent.APP_START")]
		public function sys_init(o:Object):void
		{
			get_cat();
			get_province();
		}

		public function get_cat():void
		{
			cats_arr=dbutils.query(GET_CATS_SQL);
			if (cats_arr == null)
			{
				var param:Object={"parent_cid": "0", "fields": "cid,parent_cid,name,is_parent,sort_order,status",
						"method": APIUtils.ITEMCAT_GET};
				apiutils.execute(param, get_cat_handler);
			}
			else
			{
				var result_ac:ArrayCollection=new ArrayCollection(cats_arr);
				result_ac.addItemAt({cid: "", name: "所有分类", sort_order: "0"}, 0);
				var sort:Sort=new Sort();
				sort.fields=[new SortField("sort_order", true)];
				result_ac.sort=sort;
				result_ac.refresh();
				cats_arr=apiutils.ObjectToProxy(result_ac.toArray());
			}
		}

		public function get_cat_handler(e:ResultEvent):void
		{
			var result:XMLList=e.result.item_cat as XMLList;
			for each (var item:XML in result)
			{
				var insert_sql:String=INSERT_CAT_SQL;
				dbutils.SQLUpdate(insert_sql, item.cid, item.parent_cid, item.name,
					item.is_parent, item.sort_order, item.status);
			}
			var result_ac:ArrayCollection=new ArrayCollection(apiutils.ObjectToProxy(dbutils.query(GET_CATS_SQL)));
			result_ac.addItem(new Object());
			cats_arr=result_ac.toArray();
		}

		public function get_province():void
		{
			provinces_arr=apiutils.ObjectToProxy(dbutils.query(GET_PROVINCES_SQL));
			if (provinces_arr == null)
			{
				var param:Object={"method": APIUtils.AREA_GET, "fields": "area_id,area_type,area_name,parent_id,zip"}
				apiutils.execute(param, get_area_handler);
			}
		}

		public function get_area_handler(e:ResultEvent):void
		{
			var result:XMLList=e.result.area as XMLList;
			for each (var item:Object in result)
			{
				if (item.area_type <= 3)
				{
					var insert_sql:String=INSERT_AREA_SQL;
					dbutils.SQLUpdate(insert_sql, item.area_id, item.area_type, item.
						area_name, item.parent_id, item.zip);
				}
			}
			provinces_arr=apiutils.ObjectToProxy(dbutils.query(GET_PROVINCES_SQL));
			city_arr=apiutils.ObjectToProxy(dbutils.query(GET_CITY_SQL));
		}

		public function get_city():void
		{
			city_arr=apiutils.ObjectToProxy(dbutils.query(GET_CITY_SQL));
			if (city_arr == null)
			{
				var param:Object={"method": APIUtils.AREA_GET, "fields": "area_id,area_type,area_name,parent_id,zip"}
				apiutils.execute(param, get_area_handler);
			}
		}
	}
}