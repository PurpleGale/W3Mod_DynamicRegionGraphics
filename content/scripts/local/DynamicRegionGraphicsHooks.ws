/********************************************************************************_
 * Dynamic Region Graphics Hooks
 * Hooks into CR4Game, CCommonMapManager, and CR4Player to track world changes,
 * player transitions between Exterior/Interior spaces, and combat engagement.
 ********************************************************************************/

@addField(CR4Game)
var drgManager : DynamicRegionGraphicsManager;

@wrapMethod(CR4Game)
function OnGameStarted( restored : bool )
{
	wrappedMethod( restored );

	if ( !drgManager )
	{
		drgManager = new DynamicRegionGraphicsManager in this;
		drgManager.Initialize();
	}

	drgManager.EvaluateCurrentRegion();
}

@wrapMethod(CR4Game)
function OnBeforeWorldChange( worldName : string )
{
	wrappedMethod( worldName );

	if ( drgManager )
	{
		drgManager.EvaluateWorldChange( worldName );
	}
}

@wrapMethod(CCommonMapManager)
function NotifyPlayerEnteredInterior( areaPos : Vector, areaYaw : float, texture : string )
{
	wrappedMethod( areaPos, areaYaw, texture );

	if ( theGame.drgManager )
	{
		theGame.drgManager.OnInteriorStateChanged( true );
	}
}

@wrapMethod(CCommonMapManager)
function NotifyPlayerExitedInterior()
{
	wrappedMethod();

	if ( theGame.drgManager )
	{
		theGame.drgManager.OnInteriorStateChanged( false );
	}
}

@wrapMethod(CR4Player)
function OnCombatStart()
{
	wrappedMethod();

	if ( theGame.drgManager )
	{
		theGame.drgManager.OnCombatStateChanged( true );
	}
}

@wrapMethod(CR4Player)
function OnCombatFinished()
{
	wrappedMethod();

	if ( theGame.drgManager )
	{
		theGame.drgManager.OnCombatStateChanged( false );
	}
}
