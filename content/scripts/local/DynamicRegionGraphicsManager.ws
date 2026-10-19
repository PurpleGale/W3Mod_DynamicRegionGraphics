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
	private var m_baseAAMode              : string;
	private var m_baseDLSSQuality         : string;
	private var m_baseEnableDLSSRR        : string;
	private var m_baseFSR2Quality         : string;
	private var m_baseXESSQuality         : string;
	private var m_baseDRSEnable           : string;

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

			m_baseAAMode           = ReadVar( "PostProcess", 'AAMode' );
			m_baseDLSSQuality      = ReadVar( "PostProcess", 'DLSSQuality' );
			m_baseEnableDLSSRR     = ReadVar( "PostProcess", 'EnableDLSSRR' );
			m_baseFSR2Quality      = ReadVar( "PostProcess", 'FSR2Quality' );
			m_baseXESSQuality      = ReadVar( "PostProcess", 'XESSQuality' );
			m_baseDRSEnable        = ReadVar( "Rendering/DRS", 'Enable' );

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

				ApplyAAConfig();

				profileNameMsg = GetLocStringByKeyExt( "msg_drg_pt" );
				break;

			case 1: // Force Ray Tracing
				ApplyVar( "Rendering/RT", 'EnableRT', "true" );
				ApplyVar( "Rendering/RT/PathTracer", 'PTEnable', "false" );
				ApplyVar( "Rendering/RT", 'RTGIPreset', m_options.GetRTGIQuality() );
				if ( m_options.IsRTReflectionsEnabled() )
				{
					ApplyVar( "Rendering/RT", 'EnableRtRadiance', "true" );
					ApplyVar( "Rendering/RT", 'RTReflectionsEnabled', "true" );
				}
				else
				{
					ApplyVar( "Rendering/RT", 'EnableRtRadiance', "false" );
					ApplyVar( "Rendering/RT", 'RTReflectionsEnabled', "false" );
				}
				ApplyVar( "Rendering/RT", 'Shadows', m_options.GetRTShadowsQuality() );
				if ( m_options.IsRTAOEnabled() )
				{
					ApplyVar( "Rendering/RT", 'RTAOEnabled', "true" );
				}
				else
				{
					ApplyVar( "Rendering/RT", 'RTAOEnabled', "false" );
				}

				ApplyAAConfig();

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

					// Restore baseline anti-aliasing / upscaler
					RestoreBaselineAA();
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

	private function ApplyAAConfig() : void
	{
		var aaModeVal      : string;
		var dlssQualityVal : string;
		var fsrQualityVal  : string;
		var xessQualityVal : string;
		var activeAAMode   : string;

		aaModeVal      = m_options.GetAAMode();
		dlssQualityVal = m_options.GetDLSSQuality();
		fsrQualityVal  = m_options.GetFSR2Quality();
		xessQualityVal = m_options.GetXESSQuality();

		// If user configured a specific AA mode (0=Off, 1=FXAA, 5=FSR, 6=DLSS, 7=XeSS)
		if ( aaModeVal != "-1" && aaModeVal != "" )
		{
			ApplyVar( "PostProcess", 'AAMode', aaModeVal );
			activeAAMode = aaModeVal;
		}
		else
		{
			// "Как в игре" (-1): Leave user's in-game AA Mode untouched
			activeAAMode = ReadVar( "PostProcess", 'AAMode' );
		}

		// Apply upscaler quality depending on active upscaler
		// Priority checks based on activeAAMode first to avoid stale native engine flags
		if ( activeAAMode == "6" || ( activeAAMode == "" && theGame.GetDLSSEnabled() ) )
		{
			if ( dlssQualityVal != "" )
			{
				ApplyVar( "PostProcess", 'DLSSQuality', dlssQualityVal );
			}
			if ( m_options.IsDLSSRREnabled() )
			{
				ApplyVar( "PostProcess", 'EnableDLSSRR', "true" );
			}
			else
			{
				ApplyVar( "PostProcess", 'EnableDLSSRR', "false" );
			}
		}
		else if ( activeAAMode == "5" || ( activeAAMode == "" && theGame.GetFSREnabled() ) )
		{
			if ( fsrQualityVal != "" )
			{
				ApplyVar( "PostProcess", 'FSR2Quality', fsrQualityVal );
			}
		}
		else if ( activeAAMode == "7" || ( activeAAMode == "" && theGame.GetXESSEnabled() ) )
		{
			if ( xessQualityVal != "" )
			{
				ApplyVar( "PostProcess", 'XESSQuality', xessQualityVal );
			}
		}

		if ( m_options.IsDRSEnabled() )
		{
			ApplyVar( "Rendering/DRS", 'Enable', "true" );
		}
		else
		{
			ApplyVar( "Rendering/DRS", 'Enable', "false" );
		}
	}

	private function RestoreBaselineAA() : void
	{
		var aaModeVal    : string;
		var activeAAMode : string;

		if ( !m_hasBaseline )
			return;

		aaModeVal = m_options.GetAAMode();

		// Only restore baseline AAMode if DRG actually overrode it!
		if ( aaModeVal != "-1" && aaModeVal != "" )
		{
			if ( m_baseAAMode != "" )
			{
				ApplyVar( "PostProcess", 'AAMode', m_baseAAMode );
				activeAAMode = m_baseAAMode;
			}
			else
			{
				activeAAMode = ReadVar( "PostProcess", 'AAMode' );
			}
		}
		else
		{
			// DRG didn't touch AAMode, keep current in-game AA mode
			activeAAMode = ReadVar( "PostProcess", 'AAMode' );
		}

		if ( activeAAMode == "6" || ( activeAAMode == "" && theGame.GetDLSSEnabled() ) )
		{
			if ( m_baseDLSSQuality != "" )
			{
				ApplyVar( "PostProcess", 'DLSSQuality', m_baseDLSSQuality );
			}
			if ( m_baseEnableDLSSRR != "" )
			{
				ApplyVar( "PostProcess", 'EnableDLSSRR', m_baseEnableDLSSRR );
			}
		}
		else if ( activeAAMode == "5" || ( activeAAMode == "" && theGame.GetFSREnabled() ) )
		{
			if ( m_baseFSR2Quality != "" )
			{
				ApplyVar( "PostProcess", 'FSR2Quality', m_baseFSR2Quality );
			}
		}
		else if ( activeAAMode == "7" || ( activeAAMode == "" && theGame.GetXESSEnabled() ) )
		{
			if ( m_baseXESSQuality != "" )
			{
				ApplyVar( "PostProcess", 'XESSQuality', m_baseXESSQuality );
			}
		}

		if ( m_baseDRSEnable != "" )
		{
			ApplyVar( "Rendering/DRS", 'Enable', m_baseDRSEnable );
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
