package org.taomi.utils
{
	import com.adobe.crypto.MD5;
	import com.adobe.net.URI;
	
	import flash.net.URLVariables;
	
	import mx.collections.ArrayCollection;
	import mx.collections.Sort;
	import mx.collections.SortField;
	import mx.controls.Alert;
	import mx.rpc.AsyncToken;
	import mx.rpc.events.FaultEvent;
	import mx.rpc.events.ResultEvent;
	import mx.rpc.http.HTTPService;
	import mx.utils.ObjectProxy;
	
	import org.taomi.swiz.BeansConfig;


	public class APIUtils
	{
		private static var sys_params:Object=({"app_key": BeansConfig.APP_KEY, "format": "xml", "v": "1.0", "pid": BeansConfig.PID});
		public static const TAOBAOKE_ITEM_GET:String="taobao.taobaoke.items.get";
		public static const ITEMCAT_GET:String="taobao.itemcats.get";
		public static const AREA_GET:String="taobao.areas.get";

		public function APIUtils()
		{

		}

		public function make_xml_result_bindable(result:XMLList):ArrayCollection
		{
			var result_ac:ArrayCollection=new ArrayCollection();
			for each (var item:XML in result)
			{
				var item_o:ObjectProxy=new ObjectProxy();
				for each (var child:XML in item.children())
				{
					var attr_name:String=child.name();
					item_o[attr_name]=item[attr_name].toString();
				}
				result_ac.addItem(item_o);
			}
			return result_ac;
		}

		private function create_request_param_var(input_params:Object):URLVariables
		{
			var params:Object={};
			for (var key:String in sys_params)
			{
				params[key]=sys_params[key];
			}
			params["timestamp"]=dateToString(new Date());
			for (key in input_params)
			{
				params[key]=input_params[key];
			}
			params["sign"]=sign(params, BeansConfig.APP_SECRET);
			var param_v:URLVariables=new URLVariables();
			for (key in params)
			{
				param_v[key]=params[key];
			}
			return param_v;
		}

		private function create_request_param(input_params:Object):String
		{
			var params:Object={};
			for (var key:String in sys_params)
			{
				params[key]=sys_params[key];
			}
			params["timestamp"]=dateToString(new Date());
			for (key in input_params)
			{
				params[key]=input_params[key];
			}
			params["sign"]=sign(params, BeansConfig.APP_SECRET);
			var param_str:String="";
			for (key in params)
			{
				param_str=param_str.concat("&", key, "=", params[key]);
			}
			return param_str.substring(1);
		}

		private function defaultFaultHandler(event:FaultEvent):void
		{
			Alert.show(event.fault.faultString);
		}

		public function execute(input_params:Object, rh:Function, fh:Function=null):AsyncToken
		{
			var request:String=create_request_param(input_params);
			var request_url:String=BeansConfig.SANDBOX_URL + "?" + URI.escapeChars(request);
			var service:HTTPService=new HTTPService();
			service.showBusyCursor=false;
			service.method="GET";
			service.resultFormat="e4x";
			service.url=request_url;
			if (rh != null)
			{
				service.addEventListener(ResultEvent.RESULT, rh);
			}

			if (fh == null)
			{
				service.addEventListener(FaultEvent.FAULT, defaultFaultHandler);
			}
			else
			{
				service.addEventListener(FaultEvent.FAULT, fh);
			}

			return service.send();
		}

		public function execute_var(input_params:Object, rh:Function, fh:Function=null):void
		{
			var service:mx.rpc.http.HTTPService=new HTTPService();
			service.showBusyCursor=false;
			service.method="GET";
			service.resultFormat="e4x";
			var sysp:URLVariables=new URLVariables();
			sysp.app_key=BeansConfig.APP_KEY;
			sysp.format="xml";
			sysp.v="1.0";
			sysp.pid=BeansConfig.PID;
			var request:URLVariables=create_request_param_var(input_params);
			service.request=request;
			service.addEventListener(ResultEvent.RESULT, rh);
			if (fh == null)
			{
				service.addEventListener(FaultEvent.FAULT, defaultFaultHandler);
			}
			else
			{
				service.addEventListener(FaultEvent.FAULT, fh);
			}
			service.send();

		}

		public function dateToString(date:Date):String
		{
			var str:String=date.getFullYear() + "-" + upTo2bitstr(date.getMonth() + 1) + "-" + upTo2bitstr(date.getDate()) + " " + upTo2bitstr(date.getHours()) + ":" + upTo2bitstr(date.getMinutes()) +
				":" + upTo2bitstr(date.getSeconds());

			return str;
		}

		public function upTo2bitstr(num:int):String
		{
			var temp:String=new String(num);
			if (temp.length == 1)
			{
				temp="0" + temp;
			}
			return temp;
		}

		private function sign(data:Object, app_secret:String):String
		{
			var sort_data:ArrayCollection=new ArrayCollection();
			for (var key:String in data)
			{
				sort_data.addItem(key);
			}
			var sort:Sort=new Sort();
			sort.fields=[new SortField(null, true)];
			sort_data.sort=sort;
			sort_data.refresh();
			var result:String=app_secret;
			for each (key in sort_data)
			{
				result=result.concat(key, data[key]);
			}
			return MD5.hash(result).toUpperCase();
		}

		public function addNickparam(p:Object):void
		{
			p["nick"]="logicigam";
		}

		public function ObjectToProxy(arr:Array):Array
		{
			for (var key:String in arr)
			{
				arr[key]=new ObjectProxy(arr[key]);
			}
			return arr;
		}

	}
}