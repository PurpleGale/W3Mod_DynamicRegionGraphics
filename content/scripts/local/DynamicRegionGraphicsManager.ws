/********************************************************************************_
 * Dynamic Region Graphics Manager
 * Manages caching user baseline settings, switching RT/PT profiles per region,
 * Exterior/Interior context, dynamic upscaling, and combat safety overrides.
 ********************************************************************************/

class DynamicRegionGraphicsManager
{
	private var m_options               : DynamicRegionGraphicsOptions;
	private var m_isInitialized         : bool;
	private var m_hasBaseline           : bool;
	private var m_currentAppliedProfile : int; // -1: none, 0: baseline, 1: RT, 2: PT
	private var m_lastInteriorState     : bool;
	private var m_isInCombat            : bool;

	// Cached baseline user rendering settings
	private var m_baseEnableRT            : string;
	private var m_basePTEnable            : string;
	private var m_baseRTGIPreset          : string;
	private var m_baseEnableRtRadiance    : string;
	private var m_baseShadows             : string;
	private var m_baseRTAOEnabled         : string;
	private var m_baseRTReflections       : string;

	// Cached baseline user upscaler settings
	private var m_baseDLSSQuality         : string;
	private var m_baseFSR2Quality         : string;
	private var m_baseXESSQuality         : string;

	public function Initialize() : void
	{
		if ( m_isInitialized )
			return;

		m_options = new DynamicRegionGraphicsOptions in this;
		m_currentAppliedProfile = -1;
		m_hasBaseline = false;
		m_lastInteriorState = false;
		m_isInCombat = false;
		m_isInitialized = true;
	}

	public function CacheBaselineSettings() : void
	{
		var cw : CInGameConfigWrapper;
		cw = theGame.GetInGameConfigWrapper();
		if ( !cw )
			return;

		if ( !m_hasBaseline )
		{
			m_baseEnableRT         = ReadVar( "Rendering/RT", 'EnableRT' );
			m_basePTEnable         = ReadVar( "Rendering/RT/PathTracer", 'PTEnable' );
			m_baseRTGIPreset       = ReadVar( "Rendering/RT", 'RTGIPreset' );
			m_baseEnableRtRadiance = ReadVar( "Rendering/RT", 'EnableRtRadiance' );
			m_baseShadows          = ReadVar( "Rendering/RT", 'Shadows' );
			m_baseRTAOEnabled      = ReadVar( "Rendering/RT", 'RTAOEnabled' );
			m_baseRTReflections    = ReadVar( "Rendering/RT", 'RTReflectionsEnabled' );

			m_baseDLSSQuality      = ReadVar( "PostProcess", 'DLSSQuality' );
			m_baseFSR2Quality      = ReadVar( "PostProcess", 'FSR2Quality' );
			m_baseXESSQuality      = ReadVar( "PostProcess", 'XESSQuality' );

			if ( m_baseEnableRT != "" )
			{
				m_hasBaseline = true;
			}
		}
	}

	public function EvaluateCurrentRegion() : void
	{
		var mapManager  : CCommonMapManager;
		var currentArea : name;
		var worldPath   : string;
		var isInterior  : bool;
		var profile     : int;
		var areaDisplay : string;

		if ( !m_options || !m_options.IsEnabled() )
			return;

		CacheBaselineSettings();

		if ( thePlayer )
		{
			m_isInCombat = thePlayer.IsInCombat();
			if ( m_options.IsDisableInCombat() && m_isInCombat )
			{
				ApplyProfile( 0, GetLocStringByKeyExt( "DRG_Combat" ) );
				return;
			}
		}

		mapManager = theGame.GetCommonMapManager();
		if ( mapManager )
		{
			currentArea = mapManager.GetCurrentArea();
		}

		if ( theGame.GetWorld() )
		{
			worldPath = theGame.GetWorld().GetDepotPath();
		}

		if ( thePlayer )
		{
			isInterior = thePlayer.IsInInterior();
			m_lastInteriorState = isInterior;
		}

		profile = m_options.GetTargetProfile( currentArea, worldPath, isInterior );
		areaDisplay = GetAreaDisplayName( currentArea, worldPath, isInterior );

		ApplyProfile( profile, areaDisplay );
	}

	public function EvaluateWorldChange( worldName : string ) : void
	{
		var profile     : int;
		var areaDisplay : string;

		if ( !m_options || !m_options.IsEnabled() )
			return;

		CacheBaselineSettings();

		profile = m_options.GetTargetProfile( '', worldName, false );
		areaDisplay = GetAreaDisplayName( '', worldName, false );

		ApplyProfile( profile, areaDisplay );
	}

	public function OnInteriorStateChanged( isInterior : bool ) : void
	{
		var mapManager  : CCommonMapManager;
		var currentArea : name;
		var worldPath   : string;
		var profile     : int;
		var areaDisplay : string;

		if ( !m_options || !m_options.IsEnabled() )
			return;

		// If in combat and combat override is active, maintain baseline performance
		if ( m_isInCombat && m_options.IsDisableInCombat() )
		{
			m_lastInteriorState = isInterior;
			return;
		}

		if ( m_lastInteriorState == isInterior && m_currentAppliedProfile != -1 )
			return;

		m_lastInteriorState = isInterior;
		CacheBaselineSettings();

		mapManager = theGame.GetCommonMapManager();
		if ( mapManager )
		{
			currentArea = mapManager.GetCurrentArea();
		}

		if ( theGame.GetWorld() )
		{
			worldPath = theGame.GetWorld().GetDepotPath();
		}

		profile = m_options.GetTargetProfile( currentArea, worldPath, isInterior );
		areaDisplay = GetAreaDisplayName( currentArea, worldPath, isInterior );

		ApplyProfile( profile, areaDisplay );
	}

	public function OnCombatStateChanged( inCombat : bool ) : void
	{
		if ( !m_options || !m_options.IsEnabled() || !m_options.IsDisableInCombat() )
			return;

		if ( m_isInCombat == inCombat )
			return;

		m_isInCombat = inCombat;

		if ( inCombat )
		{
			// Immediately revert to user baseline (DLAA, normal RT / Off) for combat smoothness
			ApplyProfile( 0, GetLocStringByKeyExt( "DRG_Combat" ) );
		}
		else
		{
			// Re-engage regional / interior settings once out of combat
			EvaluateCurrentRegion();
		}
	}

	private function ApplyProfile( profile : int, areaDisplay : string ) : void
	{
		var cw : CInGameConfigWrapper;
		var profileNameMsg : string;
		var notificationMsg : string;
		var upscaleOption : int;

		cw = theGame.GetInGameConfigWrapper();
		if ( !cw )
			return;

		if ( m_currentAppliedProfile == profile )
			return;

		switch ( profile )
		{
			case 2: // Force Path Tracing
				ApplyVar( "Rendering/RT", 'EnableRT', "true" );
				ApplyVar( "Rendering/RT/PathTracer", 'PTEnable', "true" );
				ApplyVar( "Rendering/RT", 'RTGIPreset', "true" );
				ApplyVar( "Rendering/RT", 'EnableRtRadiance', "true" );
				ApplyVar( "Rendering/RT", 'Shadows', "2" );
				ApplyVar( "Rendering/RT", 'RTAOEnabled', "true" );
				ApplyVar( "Rendering/RT", 'RTReflectionsEnabled', "true" );

				upscaleOption = m_options.GetPTUpscaleQuality();
				ApplyUpscaleQuality( upscaleOption );

				profileNameMsg = GetLocStringByKeyExt( "msg_drg_pt" );
				break;

			case 1: // Force Ray Tracing
				ApplyVar( "Rendering/RT", 'EnableRT', "true" );
				ApplyVar( "Rendering/RT/PathTracer", 'PTEnable', "false" );
				ApplyVar( "Rendering/RT", 'RTGIPreset', "true" );
				ApplyVar( "Rendering/RT", 'EnableRtRadiance', "true" );
				ApplyVar( "Rendering/RT", 'Shadows', "2" );
				ApplyVar( "Rendering/RT", 'RTAOEnabled', "true" );
				ApplyVar( "Rendering/RT", 'RTReflectionsEnabled', "true" );

				upscaleOption = m_options.GetRTUpscaleQuality();
				ApplyUpscaleQuality( upscaleOption );

				profileNameMsg = GetLocStringByKeyExt( "msg_drg_rt" );
				break;

			case 0: // Default (Restore User Baseline)
			default:
				if ( m_hasBaseline )
				{
					if ( m_baseEnableRT != "" )         ApplyVar( "Rendering/RT", 'EnableRT', m_baseEnableRT );
					if ( m_basePTEnable != "" )         ApplyVar( "Rendering/RT/PathTracer", 'PTEnable', m_basePTEnable );
					if ( m_baseRTGIPreset != "" )       ApplyVar( "Rendering/RT", 'RTGIPreset', m_baseRTGIPreset );
					if ( m_baseEnableRtRadiance != "" ) ApplyVar( "Rendering/RT", 'EnableRtRadiance', m_baseEnableRtRadiance );
					if ( m_baseShadows != "" )          ApplyVar( "Rendering/RT", 'Shadows', m_baseShadows );
					if ( m_baseRTAOEnabled != "" )      ApplyVar( "Rendering/RT", 'RTAOEnabled', m_baseRTAOEnabled );
					if ( m_baseRTReflections != "" )    ApplyVar( "Rendering/RT", 'RTReflectionsEnabled', m_baseRTReflections );

					// Restore baseline upscaler (e.g. DLAA)
					ApplyUpscaleQuality( 0 );
				}
				profileNameMsg = GetLocStringByKeyExt( "msg_drg_default" );
				break;
		}

		m_currentAppliedProfile = profile;
		theGame.SaveUserSettings();

		if ( m_options.AreNotificationsEnabled() && thePlayer )
		{
			if ( profileNameMsg == "" )
			{
				if ( profile == 2 ) profileNameMsg = "Path Tracing";
				else if ( profile == 1 ) profileNameMsg = "Ray Tracing";
				else profileNameMsg = "Default Settings";
			}

			if ( areaDisplay != "" )
			{
				notificationMsg = "[DRG] " + areaDisplay + ": " + profileNameMsg;
			}
			else
			{
				notificationMsg = "[DRG] Profile: " + profileNameMsg;
			}
			thePlayer.DisplayHudMessage( notificationMsg );
		}
	}

	private function ApplyUpscaleQuality( optionVal : int ) : void
	{
		var qStr : string;
		var aaModeStr : string;

		aaModeStr = ReadVar( "PostProcess", 'AAMode' );

		// 0: Restore baseline upscaler setting (e.g. DLAA)
		if ( optionVal == 0 )
		{
			if ( m_hasBaseline )
			{
				if ( ( theGame.GetDLSSEnabled() || aaModeStr == "6" ) && m_baseDLSSQuality != "" )
				{
					ApplyVar( "PostProcess", 'DLSSQuality', m_baseDLSSQuality );
				}
				else if ( ( theGame.GetFSREnabled() || aaModeStr == "5" ) && m_baseFSR2Quality != "" )
				{
					ApplyVar( "PostProcess", 'FSR2Quality', m_baseFSR2Quality );
				}
				else if ( ( theGame.GetXESSEnabled() || aaModeStr == "7" ) && m_baseXESSQuality != "" )
				{
					ApplyVar( "PostProcess", 'XESSQuality', m_baseXESSQuality );
				}
			}
			return;
		}

		// Convert menu option to in-engine upscaler quality index
		switch ( optionVal )
		{
			case 1: qStr = "0"; break; // Auto
			case 2: qStr = "1"; break; // Quality
			case 3: qStr = "2"; break; // Balanced
			case 4: qStr = "3"; break; // Performance
			case 5: qStr = "4"; break; // Ultra Performance
			default: return;
		}

		if ( theGame.GetDLSSEnabled() || aaModeStr == "6" )
		{
			ApplyVar( "PostProcess", 'DLSSQuality', qStr );
		}
		else if ( theGame.GetFSREnabled() || aaModeStr == "5" )
		{
			ApplyVar( "PostProcess", 'FSR2Quality', qStr );
		}
		else if ( theGame.GetXESSEnabled() || aaModeStr == "7" )
		{
			ApplyVar( "PostProcess", 'XESSQuality', qStr );
		}
	}

	private function ApplyVar( groupStr : string, varName : name, value : string ) : void
	{
		var cw : CInGameConfigWrapper;
		cw = theGame.GetInGameConfigWrapper();
		if ( cw && value != "" )
		{
			cw.SetVarValueByStr( groupStr, varName, value );
			cw.SetRawConfigValueByStr( groupStr, NameToString( varName ), value );
			theGame.OnConfigValueChanged( varName, value );
		}
	}

	private function ReadVar( groupStr : string, varName : name ) : string
	{
		var cw  : CInGameConfigWrapper;
		var val : string;
		cw = theGame.GetInGameConfigWrapper();
		if ( cw )
		{
			val = cw.GetVarValueByStr( groupStr, varName );
			if ( val == "" )
			{
				val = cw.GetRawConfigValueByStr( groupStr, NameToString( varName ) );
			}
			return val;
		}
		return "";
	}

	private function GetAreaDisplayName( areaName : name, worldPath : string, isInterior : bool ) : string
	{
		var locName : string;
		var contextStr : string;

		if ( isInterior )
			contextStr = " (" + GetLocStringByKeyExt( "DRG_Interior" ) + ")";
		else
			contextStr = " (" + GetLocStringByKeyExt( "DRG_Exterior" ) + ")";

		if ( areaName == 'AN_Wyzima' || StrFindFirst( worldPath, "wyzima" ) >= 0 )
			locName = GetLocStringByKeyExt( "panel_DRG_Wyzima" );
		else if ( areaName == 'AN_Prologue_Village' || areaName == 'AN_Prologue_Village_Winter' || StrFindFirst( worldPath, "prolog_village" ) >= 0 )
			locName = GetLocStringByKeyExt( "panel_DRG_WhiteOrchard" );
		else if ( areaName == 'AN_Kaer_Morhen' || StrFindFirst( worldPath, "kaer_morhen" ) >= 0 )
			locName = GetLocStringByKeyExt( "panel_DRG_KaerMorhen" );
		else if ( areaName == 'AN_Velen' || areaName == 'AN_NMLandNovigrad' || StrFindFirst( worldPath, "novigrad" ) >= 0 )
			locName = GetLocStringByKeyExt( "panel_DRG_NovigradVelen" );
		else if ( areaName == 'AN_Skellige_ArdSkellig' || StrFindFirst( worldPath, "skellige" ) >= 0 )
			locName = GetLocStringByKeyExt( "panel_DRG_Skellige" );
		else if ( areaName == 'AN_Dlc_Bob' || areaName == 'AN_Bob' || StrFindFirst( worldPath, "bob" ) >= 0 )
		{
			if ( StrFindFirst( worldPath, "fairytale" ) >= 0 || StrFindFirst( worldPath, "fable" ) >= 0 )
				return GetLocStringByKeyExt( "DRG_Special_Fable" );
			locName = GetLocStringByKeyExt( "panel_DRG_Toussaint" );
		}
		else if ( areaName == 'AN_Island_of_Myst' || StrFindFirst( worldPath, "island_of_mist" ) >= 0 )
			return GetLocStringByKeyExt( "DRG_Special_Mist" );
		else if ( areaName == 'AN_Spiral' || StrFindFirst( worldPath, "spiral" ) >= 0 )
			return GetLocStringByKeyExt( "DRG_Special_Spiral" );
		else
			locName = GetLocStringByKeyExt( "DRG_Special_Other" );

		return locName + contextStr;
	}
}
