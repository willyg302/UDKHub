class NEGameViewportClient extends UTGameViewportClient
    config(Game);

function DrawTransition(Canvas Canvas)
{
    
/*
    local class<UTGame> GameClass;
    local string HintMessage;
    local bool bAllowHints;
    local string GameClassName;

    if (Outer.TransitionType == TT_Loading)
    {
        bAllowHints = !("UDKFrontEndMap" == Outer.TransitionDescription);
        GameClass = class<UTGame>(FindObject(Outer.TransitionGameType, class'Class'));
        if(bAllowHints)
        {
            GameClassName = "";
            if(GameClass != none)
                GameClassName = string(GameClass.Name);

            // Draw a random hint!
            // NOTE: We always include deathmatch hints, since they're generally appropriate for all game types
            HintMessage = LoadRandomLocalizedHintMessage( string( class'UTDeathmatch'.Name ), GameClassName);
            if(Len(HintMessage) > 0)
            {
                class'Engine'.static.AddOverlayWrapped(LoadingScreenHintMessageFont, HintMessage, 0.1822, 0.585, 1.0, 1.0, 0.7 );
            }
        }
    }
    else if (Outer.TransitionType == TT_Precaching)
    {
        // Do nothing if precaching
        `log("Neverend GVC - Precaching!");
    }
    
*/
}

defaultproperties
{
    //HintLocFileName="UTGameUI"
    LoadingScreenHintMessageFont=MultiFont'UI_Fonts_Final.HUD.MF_Medium'
}

