package org.taomi.utils
{
	import flash.data.SQLConnection;
	import flash.data.SQLStatement;
	import flash.filesystem.File;
	import flash.filesystem.FileMode;
	import flash.filesystem.FileStream;

	public class DBUtils
	{
		private static const DB_FILE_PATH:String="org/taomi/assets/data/data.db";
		private static const CREATE_TABLE_SQL_FILE_PATH:String="data.sql";
		private var conn:SQLConnection;

		public function DBUtils()
		{
			var file:File=File.applicationDirectory.resolvePath(DB_FILE_PATH);
			var fileExists:Boolean=file.exists;

			conn=new SQLConnection();
			conn.open(file);
			if (!fileExists)
			{
				createTable();
			}
		}

		public function createTable():void
		{
			var file:File=File.applicationDirectory.resolvePath(CREATE_TABLE_SQL_FILE_PATH);
			var stream:FileStream=new FileStream();
			stream.open(file, FileMode.READ);
			var sql:String=stream.readUTFBytes(stream.bytesAvailable);
			SQLUpdate(sql);
		}

		public function query(sql:String):Array
		{
			var stmt:SQLStatement=new SQLStatement();
			stmt.sqlConnection=conn;
			stmt.text=sql;
			stmt.execute();
			return stmt.getResult().data;
		}

		public function SQLUpdate(sql:String, ... params):int
		{
			var myPattern:RegExp=/@/;

			for each (var p:String in params)
			{
				sql=sql.replace(myPattern, p);
			}
			var stmt:SQLStatement=new SQLStatement();
			stmt.sqlConnection=conn;
			stmt.text=sql;
			stmt.execute();
			return stmt.getResult().rowsAffected;
		}
	}
}