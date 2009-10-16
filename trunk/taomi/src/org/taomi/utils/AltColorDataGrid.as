package org.taomi.utils
{
	import flash.display.Sprite;

	import mx.collections.ArrayCollection;
	import mx.controls.DataGrid;
	import mx.controls.dataGridClasses.DataGridItemRenderer;
	import mx.controls.listClasses.IListItemRenderer;

	public class AltColorDataGrid extends DataGrid
	{
		private var seller:String;
		private const color1:uint=0x484848;
		private const color2:uint=0x313131;
		private var cur_color:uint;

		public function AltColorDataGrid()
		{
			super();
		}

		override protected function drawItem(item:IListItemRenderer, selected:Boolean=
			false, highlighted:Boolean=false, caret:Boolean=false, transition:Boolean=
			false):void
		{
			var itemrenderer:DataGridItemRenderer=item as DataGridItemRenderer;
			itemrenderer.setStyle("color", "#969696");
			itemrenderer.setStyle("borderColor", "red");
			super.drawItem(item, selected, highlighted, caret, transition);
		}

	/*	private function backup():void
		{

			if (dataProvider == null)
			{
				super.drawRowBackground(s, rowIndex, y, height, color, dataIndex);
				return;
			}
			if (dataIndex == (dataProvider as ArrayCollection).length)
			{
				dataIndex--;
				super.drawRowBackground(s, rowIndex, y, height, color, dataIndex);
			}
			var item:Object=(dataProvider as ArrayCollection).getItemAt(dataIndex);
			if (item.nick != seller)
			{
				if (cur_color == color1)
				{
					color=color2;
				}
				else
				{
					color=color1;
				}
				cur_color=color;
			}
			else
			{
				color=cur_color;
			}
			seller=item.nick;
			super.drawRowBackground(s, rowIndex, y, height, color, dataIndex);
		}*/

		override protected function drawRowBackground(s:Sprite, rowIndex:int, y:Number,
			height:Number, color:uint, dataIndex:int):void
		{

			if (dataProvider == null)
			{
				super.drawRowBackground(s, rowIndex, y, height, color, dataIndex);
				return;
			}
			if (dataIndex == (dataProvider as ArrayCollection).length)
			{
				dataIndex--;
				super.drawRowBackground(s, rowIndex, y, height, color, dataIndex);
			}
			var item:Object=(dataProvider as ArrayCollection).getItemAt(dataIndex);
			if(item.price==""&&item.commission_num==""&&item.nick==""){
				color=color2;
			}else{
				color=color1;
			}
			super.drawRowBackground(s, rowIndex, y, height, color, dataIndex);
		}
	}
}