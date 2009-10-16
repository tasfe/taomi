package org.taomi.swiz.controller
{
	import flash.events.Event;
	
	import mx.collections.ArrayCollection;
	import mx.collections.Sort;
	import mx.collections.SortField;
	import mx.collections.XMLListCollection;
	import mx.containers.TabNavigator;
	import mx.controls.Alert;
	import mx.events.FlexEvent;
	import mx.managers.CursorManager;
	import mx.managers.SystemManager;
	import mx.rpc.AsyncToken;
	import mx.rpc.events.ResultEvent;
	
	import org.swizframework.Swiz;
	import org.swizframework.command.CommandChain;
	import org.swizframework.controller.AbstractController;
	import org.taomi.swiz.BeansConfig;
	import org.taomi.swiz.entity.Item;
	import org.taomi.swiz.view.SearchResultBox;
	import org.taomi.swiz.view.StoreDividResultBox;
	import org.taomi.utils.APIUtils;
	import org.taomi.utils.ParamedArrayCollection;

	public class ItemController extends AbstractController
	{
		[Autowire]
		public var apiutils:APIUtils;

		private var search_params_item:Item;
		private var srb:SearchResultBox;
		private var tab_count:int=1;
		private var store_divid_array:ParamedArrayCollection=new ParamedArrayCollection();
		private var cur_page_search_result_lc:XMLListCollection;
		private var total_search_result_lc:XMLListCollection;
		
		[Bindable]
		public var analysis_result:ArrayCollection;

		[Mediate(event="ItemEvent.SEARCH_ITEM", properties="item")]
		public function search_item(item:Item):void
		{
			item.sort="commissionNum_desc";
			common_search_item(item,search_complete_handler);
		}
		public function common_search_item(item:Item,complete_h:Function):void{
			//改变鼠标指针样式
			CursorManager.setBusyCursor();
			cur_page_search_result_lc=new XMLListCollection();
			total_search_result_lc=new XMLListCollection();
			
			search_item_page(item,1,function search_first_page_handler(e:ResultEvent):void{
				var result:XMLListCollection=new XMLListCollection(e.result.taobaokeItem as
					XMLList);
				if (result.length == 0)
				{
					Alert.show("没有找到任何相关的商品.", "提示");
					CursorManager.removeBusyCursor();
					return;
				}
				removeHTML_mark(result);
				total_search_result_lc.addAll(result);
				item.total_results_count=e.result.totalResults;
				var page_count:int;
				if(item.total_results_count%BeansConfig.PAGE_SIZE==0)
					page_count=item.total_results_count/BeansConfig.PAGE_SIZE;
				else
					page_count=item.total_results_count/BeansConfig.PAGE_SIZE+1;
				var limit:int=item.result_limit==-1?page_count:item.result_limit;
				limit=limit>page_count?page_count:limit;
				//开始剩余部分搜索
				var chain : CommandChain = new CommandChain(CommandChain.SERIES);
				//page——count
				for(var i:int=2;i<=limit;i++){
					chain.addCommand(createCommand(search_item_page,[item,i,null],search_rest_item_handler,function():void{}));
				}
				chain.completeHandler=complete_h;
				chain.proceed();
			});
		}
		public function search_rest_item_handler(re:ResultEvent):void{
			var result:XMLListCollection=new XMLListCollection(re.result.taobaokeItem as XMLList)
			removeHTML_mark(result);
			total_search_result_lc.addAll(result);
		}
		public function search_complete_handler():void{
			for(var i:int=0;i<BeansConfig.PAGE_SIZE;i++){
				cur_page_search_result_lc.addItem(total_search_result_lc.getItemAt(i));
			}
			var root:Object=SystemManager.getSWFRoot(this);
			var navi:TabNavigator=(SystemManager.getSWFRoot(this) as Object).
				application.navi;
			var srb:SearchResultBox=new SearchResultBox();
			
			srb.addEventListener(FlexEvent.CREATION_COMPLETE, function():void
			{
				srb.result_item_list.dataProvider=cur_page_search_result_lc;
				srb.total_search_item_result_lc=total_search_result_lc;
				srb.search_param_item=search_params_item;
				srb.cur_page=1;
			});
			srb.label="商品" + tab_count + "_搜索结果";
			tab_count++;
			navi.addItem(srb);
			navi.selectedChild=srb;
			CursorManager.removeBusyCursor();
		}
		public function search_item_page(item:Item,page:int,rh:Function):AsyncToken{
			item.start_credit=item.start_credit == null ? "" : item.start_credit;
			item.end_credit=item.end_credit == null ? "" : item.end_credit;
			if (item.location == "全部省份")
			{
				item.location="";
			}
			var search_params:Object={"fields": "iid,title,nick,pic_url,price,click_url,commission_num",
				"nick": BeansConfig.NICK, "keyword": item.key_word, "cid": item.
					cid, "start_price": item.price_from, "end_price": item.price_to,
					"auto_send": item.autosend, "area": item.location, "start_credit": item.
					start_credit, "end_credit": item.end_credit, "sort": item.sort
					,"is_guarantee":item.is_guarantee,"page_no":page,"page_size":BeansConfig.PAGE_SIZE,
					"method": APIUtils.TAOBAOKE_ITEM_GET};
			search_params_item=item;
			return apiutils.execute(search_params, rh);
		}
		public function removeHTML_mark(result:XMLListCollection):void
		{
			var temp:String;
			var html_start:RegExp=new RegExp("<(\S*?)[^>]*>");
			var html_end:RegExp=new RegExp("<.*?/>");
			for each (var item:XML in result)
			{
				temp=item.title;
				while(temp.match(html_start)!=null){
					temp=temp.replace(html_start, "");
				}
				while(temp.match(html_end)!=null){
					temp=temp.replace(html_end, "");
				}
				item.title=temp;
			}
		}
		
		[Mediate(event="ItemEvent.CHANGE_SEARCH_SORT", properties="param")]
		public function change_search_sort(params:Object):void
		{
			cur_page_search_result_lc=new XMLListCollection();
			total_search_result_lc=new XMLListCollection();
			
			srb=params.resultbox as SearchResultBox;
			if (params.request.type == "commissionNum")
			{
				if (params.request.sort == "desc")
				{
					srb.tbb_arr[0].label="成交量升序";
					srb.tbb_arr[0].sort="asc";
				}
				else
				{
					srb.tbb_arr[0].label="成交量降序";
					srb.tbb_arr[0].sort="desc";
				}
				srb.sort_tbbar.selectedIndex=0;
			}
			else if (params.request.type == "price")
			{
				if (params.request.sort == "desc")
				{
					srb.tbb_arr[1].label="价格升序";
					srb.tbb_arr[1].sort="asc";
				}
				else
				{
					srb.tbb_arr[1].label="价格降序";
					srb.tbb_arr[1].sort="desc";
				}
				srb.sort_tbbar.selectedIndex=1;
			}
			else
			{
				srb.sort_tbbar.selectedIndex=2;
			}
			params.search_param_item["sort"]=params.request.type + "_" + params.request.sort;
			common_search_item(params.search_param_item,change_search_sort_handler);
		}

		public function change_search_sort_handler():void
		{
			for(var i:int=0;i<BeansConfig.PAGE_SIZE;i++){
				cur_page_search_result_lc.addItem(total_search_result_lc.getItemAt(i));
			}
			srb.result_item_list.dataProvider=cur_page_search_result_lc;
			CursorManager.removeBusyCursor();
		}
		public function remove_store(store_divid_array:ParamedArrayCollection,tablength:int,non_analy_tab_count:int):ParamedArrayCollection{
			var removed_arr:ParamedArrayCollection=new ParamedArrayCollection();
			var length:int=store_divid_array.length;
			for (var i:int;i<length;i++){
				var store_arr:ParamedArrayCollection=store_divid_array.getItemAt(i) as ParamedArrayCollection;
				if(store_arr.param.count==tablength-non_analy_tab_count){
					removed_arr.addItem(store_divid_array.getItemAt(i));
				}
			}
			return removed_arr;
		}

		[Mediate(event="ItemEvent.ANALYSIS_SEARCHED_ITEMS_SAME_STORE")]
		public function same_store_analysis(o:Object):void
		{
			//改变鼠标指针样式
			CursorManager.setBusyCursor();
			//记录不参与分析的tab数量;
			var non_analy_tab_count:int=0;
			var navi:TabNavigator=(SystemManager.getSWFRoot(this) as Object).
				application.navi;
			var tabs:Array=navi.getChildren();
			if (tabs.length == 0 || tabs.length == 1||tabs.length==2 )
			{
				Alert.show("请先搜索想要的宝贝2个以上后再分析结果.\n\n    该功能可以帮您过滤出能够提供所有所需商品的卖家，使您能够尽量在一家店铺买到所有商品，避免不必要的邮费开销。", "提示");
				CursorManager.removeBusyCursor();
				return;
			}
			store_divid_array=new ParamedArrayCollection();
			for  (var i:String in tabs)
			{
				var tab:Object=tabs[i];
				if (tab.name == "store_divid_result_panel"||tab.name=="introPanel"){
					non_analy_tab_count++;
					continue;
				}
					
				var result_list:XMLListCollection=tab.total_search_item_result_lc as
					XMLListCollection;
				for  each(var item:XML in result_list)
				{
					add_to_store_divid_array(item, store_divid_array,new int(i)+1);
				}
			}
			//------移除不能提供所有查询商品的卖家
			store_divid_array=remove_store(store_divid_array,tabs.length,non_analy_tab_count);
			if(store_divid_array.length==0){
				Alert.show("没有找到能提供所有所需商品的卖家.","提示");
				return;
			}
			//按总开销排序
			total_expense_analysis(null);
			analysis_result=get_result_from_store_divid_array(store_divid_array);
			add_total_expense_record(analysis_result);
			//用空Object填满DataGrid
			full_datagrid(analysis_result);
			var exist_sdrb:StoreDividResultBox=navi.getChildByName("store_divid_result_panel") as
				StoreDividResultBox;
			if (exist_sdrb == null)
			{
				var sdrb:StoreDividResultBox=new StoreDividResultBox();
				Swiz.autowire(sdrb);
				navi.addChild(sdrb);
				navi.selectedChild=sdrb;
			}else{
				navi.selectedChild=exist_sdrb;
			}
			CursorManager.removeBusyCursor();
		}
		public function add_total_expense_record(analysis_result:ArrayCollection):void{
			var seller:String=analysis_result.getItemAt(0).nick;
			for (var i:String in analysis_result){
				var total_expense:Number=0;
				var item:XML=analysis_result.getItemAt(new int(i)) as XML;
				if(item.nick!=seller){
					//在store_divid_array中找到相同卖家的total_expense记录
					for each(var items_arr:ParamedArrayCollection in store_divid_array){
						if(items_arr.getItemAt(0).nick==seller){
							total_expense=items_arr.total_expense;
							break;
						}
					}
					analysis_result.addItemAt({title:"     预计总支出:"+total_expense,price:"",commission_num:"",nick:""},new int(i))
					seller=item.nick;
				}
			}
			seller=analysis_result.getItemAt(analysis_result.length-1).nick;
			for each(items_arr in store_divid_array){
						if(items_arr.getItemAt(0).nick==seller){
							total_expense=items_arr.total_expense;
							break;
						}
			}
			analysis_result.addItemAt({title:"     预计总支出:"+total_expense,price:"",commission_num:"",nick:""},analysis_result.length)
		}
		public function full_datagrid(analysis_result:ArrayCollection):void{
			if(analysis_result.length<18){
				var len:int=18-analysis_result.length;
				for(var j:int=0;j<len;j++){
					analysis_result.addItem(new Object());	
				}
			}else{
				for(j=0;j<0;j++){
					analysis_result.addItem(new Object());	
				}
			}
		}
		public function bind_data_to_sdrb(e:Event):void
		{
			var target:StoreDividResultBox=e.target as StoreDividResultBox;
			target.store_divid_result_dg.dataProvider=analysis_result;
		}
		public function get_result_from_store_divid_array(store_divid_array:ArrayCollection):ArrayCollection
		{
			analysis_result=new ArrayCollection();
			for each (var si:ArrayCollection in store_divid_array)
			{
				for each (var i:XML in si)
				{
					analysis_result.addItem(i);
				}
			}
			return analysis_result;
		}

		public function init_store_divid_array():ArrayCollection
		{
			var store_divid_array:ArrayCollection=new ArrayCollection();
			for (var i:int=0; i < 20; i++)
			{
				store_divid_array.addItem(new ArrayCollection());
			}
			return store_divid_array;
		}

		public function add_to_store_divid_array(item:XML, store_divid_array:ParamedArrayCollection,item_type_count:int):void
		{
			for each (var store_items:ParamedArrayCollection in store_divid_array)
			{
				
				if (store_items.length > 0 && store_items.getItemAt(0).nick == item.
					nick)
				{
					store_items.addItem(item);
					if(item.request_item_type!=null){
						item.request_item_type=item_type_count;
					}else{
						item.appendChild(<request_item_type>{item_type_count}</request_item_type>);
					}
					
					for each(var type:int in store_items.param.item_type){
						if(type==item_type_count){
							return;
						}
					}
					store_items.param.item_type.addItem(item_type_count);
					store_items.param.count++;
					return;
				}
			}
			var si:ParamedArrayCollection=new ParamedArrayCollection();
			si.param.count=1;
			si.param.item_type=new ArrayCollection();
			si.param.item_type.addItem(item_type_count);
			//加入商品类型编号，用来辨别该商品是用户所需的哪一类商品
			if(item.request_item_type!=null){
						item.request_item_type=item_type_count;
			}else{
				item.appendChild(<request_item_type>{item_type_count}</request_item_type>);
			}
			si.addItem(item);
			store_divid_array.addItem(si);
		}
		
		public function caculate_total_expense_commission_num():void{
			var tab_count:int=(SystemManager.getSWFRoot(this) as Object).
				application.navi.getChildren().length;
				var request_item_types:Object={};
				var item_types:ArrayCollection=(store_divid_array.getItemAt(0) as ParamedArrayCollection).param.item_type;
			for each(var items_arr:ParamedArrayCollection in store_divid_array){
				var item_type_divid_arr:ParamedArrayCollection=new ParamedArrayCollection();
				for each(var it:int in item_types){
					var cur_item_type_item_arr:ArrayCollection=new ArrayCollection();
					for each(var item:XML in items_arr){
						if(item.request_item_type==it){
							cur_item_type_item_arr.addItem(item);
						}
					}
					item_type_divid_arr.addItem(cur_item_type_item_arr);
				}
				//分类计算总支出
				var total_expense:Number=0;
				for each(var cur_type_items_arr:ArrayCollection in item_type_divid_arr){
					var max_item_commission_num:int=0;
					var cur_item_price:Number=0;
					for each(item in cur_type_items_arr){
						if(item.commission_num>=max_item_commission_num){
							cur_item_price=item.price;
							max_item_commission_num=item.commission_num
						}
					}
					total_expense+=cur_item_price;
				}
				items_arr.total_expense=total_expense;
				//分类计算总销量
				var total_commission_num:Number=0;
				for each(cur_type_items_arr in item_type_divid_arr){
					var cur_item_commission_num:Number=0;
					for each(item in cur_type_items_arr){
						if(item.commission_num>=cur_item_commission_num){
							cur_item_commission_num=item.commission_num;
						}
					}
					total_commission_num+=cur_item_commission_num;
				}
				items_arr.total_commission_num=total_commission_num;
			}
			
		}
		public function sortcompare(obj1:Object, obj2:Object,p:Array):int
		{
			var sortfield:String=p[0].name;
			var num1:Number=Number(obj1[sortfield].toString());
			var num2:Number=Number(obj2[sortfield].toString());
			if (num1 > num2)
			{
				return 1;
			}
			else if (num1 < num2)
			{
				return -1;
			}
			else
			{
				return 0;
			}
		}
		[Mediate(event="ItemEvent.S_D_RESULT_TOTAL_EXPENSE_ASC")]
		public function total_expense_analysis(o:Object):void{
			if(store_divid_array.getItemAt(0).total_expense==-1){
				caculate_total_expense_commission_num();
			}
			var sort:Sort=new Sort();
			sort.fields=[new SortField("total_expense", true)];
			sort.compareFunction=sortcompare;
			store_divid_array.sort=sort;
			store_divid_array.refresh();
			analysis_result=get_result_from_store_divid_array(store_divid_array);
			add_total_expense_record(analysis_result);
			full_datagrid(analysis_result);
		}
		[Mediate(event="ItemEvent.S_D_RESULT_TOTAL_COMMISSION_NUM_DESC")]
		public function total_commission_num_analysis(o:Object):void{
			if(store_divid_array.getItemAt(0).total_commission_num==-1){
				caculate_total_expense_commission_num();
			}
			var sort:Sort=new Sort();
			var sf:SortField=new SortField("total_commission_num", true);
			sf.descending=true;
			sf.numeric=true;
			sort.fields=[sf];
			var sda:Array=store_divid_array.toArray();
			sort.sort(sda);
			store_divid_array=new ParamedArrayCollection(sda);
			analysis_result=get_result_from_store_divid_array(store_divid_array);
			add_total_expense_record(analysis_result);
			full_datagrid(analysis_result);
		}
		[Mediate(event="ItemEvent.PREV_ITEMS_RESULT_PAGE", properties="param")]
		public function prev_result_page(param:Object):void{
			cur_page_search_result_lc=new XMLListCollection();
			var cur_page:int=param.resultbox.cur_page;
			if(cur_page==1)
				return;
			var start:int=(cur_page-2)*BeansConfig.PAGE_SIZE;
			var end:int=start+BeansConfig.PAGE_SIZE;
			for(start;start<end;start++){
				cur_page_search_result_lc.addItem(total_search_result_lc.getItemAt(start));
			}
			var srb:SearchResultBox=param.resultbox as SearchResultBox;
			srb.result_item_list.dataProvider=cur_page_search_result_lc;
			param.resultbox.cur_page--;
			CursorManager.removeBusyCursor();
		}
		[Mediate(event="ItemEvent.NEXT_ITEMS_RESULT_PAGE", properties="param")]
		public function next_result_page(param:Object):void{
			cur_page_search_result_lc=new XMLListCollection();
			var cur_page:int=param.resultbox.cur_page;
			var srb:SearchResultBox=param.resultbox as SearchResultBox;
			var total_page:int;
			if(srb.total_search_item_result_lc.length%BeansConfig.PAGE_SIZE==0)
				total_page=srb.total_search_item_result_lc.length/BeansConfig.PAGE_SIZE;
			else
				total_page=srb.total_search_item_result_lc.length/BeansConfig.PAGE_SIZE+1;
			if(cur_page==total_page)
				return;
			var start:int=cur_page*BeansConfig.PAGE_SIZE;
			var end:int=start+BeansConfig.PAGE_SIZE;
			for(start;start<end;start++){
				cur_page_search_result_lc.addItem(total_search_result_lc.getItemAt(start));
			}
			srb.result_item_list.dataProvider=cur_page_search_result_lc;
			param.resultbox.cur_page++;
		}
		[Mediate(event="ItemEvent.TO_PAGE", properties="param")]
		public function to_page(param:Object):void{

			cur_page_search_result_lc=new XMLListCollection();
			var cur_page:int=param.resultbox.cur_page;
			var srb:SearchResultBox=param.resultbox as SearchResultBox;
			var total_page:int;
			if(srb.total_search_item_result_lc.length%BeansConfig.PAGE_SIZE==0)
				total_page=srb.total_search_item_result_lc.length/BeansConfig.PAGE_SIZE;
			else
				total_page=srb.total_search_item_result_lc.length/BeansConfig.PAGE_SIZE+1;
			var to_page:int=param.page;
			if(to_page<1||to_page>total_page)
				return;
			var start:int=(to_page-1)*BeansConfig.PAGE_SIZE;
			var end:int=start+BeansConfig.PAGE_SIZE;
			for(start;start<end;start++){
				cur_page_search_result_lc.addItem(total_search_result_lc.getItemAt(start));
			}
			srb.result_item_list.dataProvider=cur_page_search_result_lc;
			param.resultbox.cur_page=to_page;
		}

	}
}