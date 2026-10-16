/********************************************************************************_
 * Dynamic Region Graphics Options
 * Reads and parses user menu options for Dynamic Region Graphics
 ********************************************************************************/

class DynamicRegionGraphicsOptions
{
	public function IsEnabled() : bool
	{
		var cw : CInGameConfigWrapper;
		cw = theGame.GetInGameConfigWrapper();
		if ( !cw )
			return false;
		return cw.GetVarValue( 'DynamicRegionGraphics_Main', 'DRG_Enabled' ) == "true";
	}

	public function AreNotificationsEnabled() : bool
	{
		var cw : CInGameConfigWrapper;
		cw = theGame.GetInGameConfigWrapper();
		if ( !cw )
			return false;
		return cw.GetVarValue( 'DynamicRegionGraphics_Main', 'DRG_Notifications' ) == "true";
	}

	public function IsDisableInCombat() : bool
	{
		var cw : CInGameConfigWrapper;
		cw = theGame.GetInGameConfigWrapper();
		if ( !cw )
			return false;
		return cw.GetVarValue( 'DynamicRegionGraphics_Main', 'DRG_DisableInCombat' ) == "true";
	}

	public function GetPTUpscaleQuality() : int
	{
		var cw : CInGameConfigWrapper;
		var val : string;
		cw = theGame.GetInGameConfigWrapper();
		if ( !cw )
			return 0;
		val = cw.GetVarValue( 'DynamicRegionGraphics_Main', 'DRG_PT_UpscaleQuality' );
		if ( val == "" )
			return 0;
		return StringToInt( val, 0 );
	}

	public function GetRTUpscaleQuality() : int
	{
		var cw : CInGameConfigWrapper;
		var val : string;
		cw = theGame.GetInGameConfigWrapper();
		if ( !cw )
			return 0;
		val = cw.GetVarValue( 'DynamicRegionGraphics_Main', 'DRG_RT_UpscaleQuality' );
		if ( val == "" )
			return 0;
		return StringToInt( val, 0 );
	}

	public function GetTargetProfile( areaName : name, worldPath : string, isInterior : bool ) : int
	{
		var cw : CInGameConfigWrapper;
		var val : string;
		cw = theGame.GetInGameConfigWrapper();
		if ( !cw )
			return 0;

		// 1. Wyzima Palace
		if ( areaName == 'AN_Wyzima' || StrFindFirst( worldPath, "wyzima" ) >= 0 )
		{
			if ( isInterior )
				val = cw.GetVarValue( 'DynamicRegionGraphics_Wyzima', 'DRG_Wyzima_Int' );
			else
				val = cw.GetVarValue( 'DynamicRegionGraphics_Wyzima', 'DRG_Wyzima_Ext' );
		}
		// 2. White Orchard
		else if ( areaName == 'AN_Prologue_Village' || areaName == 'AN_Prologue_Village_Winter' || StrFindFirst( worldPath, "prolog_village" ) >= 0 )
		{
			if ( isInterior )
				val = cw.GetVarValue( 'DynamicRegionGraphics_WhiteOrchard', 'DRG_WhiteOrchard_Int' );
			else
				val = cw.GetVarValue( 'DynamicRegionGraphics_WhiteOrchard', 'DRG_WhiteOrchard_Ext' );
		}
		// 3. Novigrad & Velen
		else if ( areaName == 'AN_Velen' || areaName == 'AN_NMLandNovigrad' || StrFindFirst( worldPath, "novigrad" ) >= 0 )
		{
			if ( isInterior )
				val = cw.GetVarValue( 'DynamicRegionGraphics_NovigradVelen', 'DRG_NovigradVelen_Int' );
			else
				val = cw.GetVarValue( 'DynamicRegionGraphics_NovigradVelen', 'DRG_NovigradVelen_Ext' );
		}
		// 4. Skellige Islands
		else if ( areaName == 'AN_Skellige_ArdSkellig' || StrFindFirst( worldPath, "skellige" ) >= 0 )
		{
			if ( isInterior )
				val = cw.GetVarValue( 'DynamicRegionGraphics_Skellige', 'DRG_Skellige_Int' );
			else
				val = cw.GetVarValue( 'DynamicRegionGraphics_Skellige', 'DRG_Skellige_Ext' );
		}
		// 5. Kaer Morhen
		else if ( areaName == 'AN_Kaer_Morhen' || StrFindFirst( worldPath, "kaer_morhen" ) >= 0 )
		{
			if ( isInterior )
				val = cw.GetVarValue( 'DynamicRegionGraphics_KaerMorhen', 'DRG_KaerMorhen_Int' );
			else
				val = cw.GetVarValue( 'DynamicRegionGraphics_KaerMorhen', 'DRG_KaerMorhen_Ext' );
		}
		// 6. Toussaint (Blood and Wine)
		else if ( areaName == 'AN_Dlc_Bob' || areaName == 'AN_Bob' || StrFindFirst( worldPath, "bob" ) >= 0 )
		{
			if ( StrFindFirst( worldPath, "fairytale" ) >= 0 || StrFindFirst( worldPath, "fable" ) >= 0 )
			{
				val = cw.GetVarValue( 'DynamicRegionGraphics_Special', 'DRG_Special_Fable' );
			}
			else
			{
				if ( isInterior )
					val = cw.GetVarValue( 'DynamicRegionGraphics_Toussaint', 'DRG_Toussaint_Int' );
				else
					val = cw.GetVarValue( 'DynamicRegionGraphics_Toussaint', 'DRG_Toussaint_Ext' );
			}
		}
		// 7. Special Worlds
		else if ( areaName == 'AN_Island_of_Myst' || StrFindFirst( worldPath, "island_of_mist" ) >= 0 )
		{
			val = cw.GetVarValue( 'DynamicRegionGraphics_Special', 'DRG_Special_Mist' );
		}
		else if ( areaName == 'AN_Spiral' || StrFindFirst( worldPath, "spiral" ) >= 0 )
		{
			val = cw.GetVarValue( 'DynamicRegionGraphics_Special', 'DRG_Special_Spiral' );
		}
		else
		{
			val = cw.GetVarValue( 'DynamicRegionGraphics_Special', 'DRG_Special_Other' );
		}

		if ( val == "" )
			return 0;

		return StringToInt( val, 0 );
	}

	public function GetDRGVersion() : string
	{
		return "1.0.0";
	}
}
