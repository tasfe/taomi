package org.taomi.swiz.event
{
    import flash.events.Event;

    public class SysEvent extends Event
    {
		public static const APP_START:String="application_start";
        public function SysEvent(type:String)
        {
            super(type, true, true);
        }
    }
}