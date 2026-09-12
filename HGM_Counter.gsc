// HGM Compact Counter — BO2 Plutonium ZM
// Original work for HGM servers. Single pill, top-left, O(1) updates.
// Shows: HGM tag | Round + round time | Zombies left (alive + remaining to spawn)
// Install: drop in %localappdata%\Plutonium\storage\t6\scripts\zm\  (or raw\scripts\zm\)
// Chat: .hgm  /  .hc  toggles the pill (per player, memory only, default ON)

#include common_scripts\utility;
#include maps\mp\_utility;
#include maps\mp\zombies\_zm_utility;

init()
{
    PrecacheShader( "white" );
    level thread hgm_listen_connect();
    level thread hgm_listen_chat();
}

hgm_listen_connect()
{
    level endon( "end_game" );

    players = get_players();
    for ( i = 0; i < players.size; i++ )
        players[i] thread hgm_player();

    for ( ;; )
    {
        level waittill( "connected", p );
        p thread hgm_player();
    }
}

hgm_player()
{
    self endon( "disconnect" );
    level endon( "end_game" );

    self waittill( "spawned_player" );
    flag_wait( "initial_blackscreen_passed" );

    if ( isdefined( self.hgm_ready ) && self.hgm_ready )
        return;
    self.hgm_ready = true;
    self.hgm_show = true;

    hgm_make_hud();

    self thread hgm_watch();
}

hgm_make_hud()
{
    // One compact pill, very top-left.
    bx = 10;
    by = 10;
    bw = 158;
    bh = 20;

    // HGM purple / round green / zombies orange.
    cr = 0.68;
    cg = 0.35;
    cb = 1.0;

    self.hgm_bg = newClientHudElem( self );
    self.hgm_bg.foreground = 1;
    self.hgm_bg.hidewheninmenu = 1;
    self.hgm_bg.hidewhendead = 0;
    self.hgm_bg.horzAlign = "left";
    self.hgm_bg.vertAlign = "top";
    self.hgm_bg.alignX = "left";
    self.hgm_bg.alignY = "top";
    self.hgm_bg.x = bx;
    self.hgm_bg.y = by;
    self.hgm_bg.sort = 5;
    self.hgm_bg setShader( "white", bw, bh );
    self.hgm_bg.color = ( 0.03, 0.03, 0.05 );
    self.hgm_bg.alpha = 0.62;

    self.hgm_edge = newClientHudElem( self );
    self.hgm_edge.foreground = 1;
    self.hgm_edge.hidewheninmenu = 1;
    self.hgm_edge.hidewhendead = 0;
    self.hgm_edge.horzAlign = "left";
    self.hgm_edge.vertAlign = "top";
    self.hgm_edge.alignX = "left";
    self.hgm_edge.alignY = "top";
    self.hgm_edge.x = bx;
    self.hgm_edge.y = by;
    self.hgm_edge.sort = 6;
    self.hgm_edge setShader( "white", 3, bh );
    self.hgm_edge.color = ( cr, cg, cb );
    self.hgm_edge.alpha = 0.95;

    self.hgm_tag = newClientHudElem( self );
    self.hgm_tag.foreground = 1;
    self.hgm_tag.hidewheninmenu = 1;
    self.hgm_tag.hidewhendead = 0;
    self.hgm_tag.horzAlign = "left";
    self.hgm_tag.vertAlign = "top";
    self.hgm_tag.alignX = "left";
    self.hgm_tag.alignY = "top";
    self.hgm_tag.x = bx + 7;
    self.hgm_tag.y = by + 2;
    self.hgm_tag.font = "default";
    self.hgm_tag.fontscale = 1.2;
    self.hgm_tag.color = ( cr, cg, cb );
    self.hgm_tag.alpha = 1;
    self.hgm_tag.sort = 7;
    self.hgm_tag setText( "HGM" );

    // Round uses label+value so no strings are built per update.
    self.hgm_round = newClientHudElem( self );
    self.hgm_round.foreground = 1;
    self.hgm_round.hidewheninmenu = 1;
    self.hgm_round.hidewhendead = 0;
    self.hgm_round.horzAlign = "left";
    self.hgm_round.vertAlign = "top";
    self.hgm_round.alignX = "left";
    self.hgm_round.alignY = "top";
    self.hgm_round.x = bx + 42;
    self.hgm_round.y = by + 2;
    self.hgm_round.font = "default";
    self.hgm_round.fontscale = 1.2;
    self.hgm_round.color = ( 0.35, 1.0, 0.45 );
    self.hgm_round.alpha = 1;
    self.hgm_round.sort = 7;
    self.hgm_round.label = &"R ";
    self.hgm_round setValue( 1 );

    // Round elapsed time, engine-driven (zero per-frame cost).
    // Reset via setTimerUp() in hgm_watch() whenever the round changes.
    self.hgm_time = newClientHudElem( self );
    self.hgm_time.foreground = 1;
    self.hgm_time.hidewheninmenu = 1;
    self.hgm_time.hidewhendead = 0;
    self.hgm_time.horzAlign = "left";
    self.hgm_time.vertAlign = "top";
    self.hgm_time.alignX = "left";
    self.hgm_time.alignY = "top";
    self.hgm_time.x = bx + 70;
    self.hgm_time.y = by + 2;
    self.hgm_time.font = "default";
    self.hgm_time.fontscale = 1.2;
    self.hgm_time.color = ( 0.72, 0.76, 0.84 );
    self.hgm_time.alpha = 1;
    self.hgm_time.sort = 7;
    self.hgm_time setTimerUp( 0 );

    // Zombies left: alive on map + remaining to spawn.
    self.hgm_left = newClientHudElem( self );
    self.hgm_left.foreground = 1;
    self.hgm_left.hidewheninmenu = 1;
    self.hgm_left.hidewhendead = 0;
    self.hgm_left.horzAlign = "left";
    self.hgm_left.vertAlign = "top";
    self.hgm_left.alignX = "left";
    self.hgm_left.alignY = "top";
    self.hgm_left.x = bx + 114;
    self.hgm_left.y = by + 2;
    self.hgm_left.font = "default";
    self.hgm_left.fontscale = 1.2;
    self.hgm_left.color = ( 1.0, 0.62, 0.15 );
    self.hgm_left.alpha = 1;
    self.hgm_left.sort = 7;
    self.hgm_left.label = &"Z ";
    self.hgm_left setValue( 0 );
}

hgm_watch()
{
    self endon( "disconnect" );
    level endon( "end_game" );

    last_round = -1;
    last_left = -1;

    for ( ;; )
    {
        wait 0.25;

        if ( !isdefined( self.hgm_show ) || !self.hgm_show )
            continue;

        r = 0;
        if ( isdefined( level.round_number ) )
            r = level.round_number;

        alive = 0;
        arr = get_round_enemy_array();
        if ( isdefined( arr ) )
            alive = arr.size;

        rest = 0;
        if ( isdefined( level.zombie_total ) )
            rest = level.zombie_total;
        if ( rest < 0 )
            rest = 0;

        left = alive + rest;

        if ( r != last_round )
        {
            last_round = r;
            if ( isdefined( self.hgm_round ) )
                self.hgm_round setValue( r );
            // Restart engine round timer. Sync to real round start when known
            // (join mid-round), else 0. Engine counts up by itself — no polling.
            if ( isdefined( self.hgm_time ) )
            {
                start = 0;
                if ( isdefined( level.round_start_time ) && level.round_start_time > 0 )
                {
                    start = ( gettime() - level.round_start_time ) / 1000;
                    if ( start < 0 )
                        start = 0;
                    if ( start > 3600 )
                        start = 0;
                }
                self.hgm_time setTimerUp( start );
            }
        }

        if ( left != last_left )
        {
            last_left = left;
            if ( isdefined( self.hgm_left ) )
            {
                self.hgm_left setValue( left );
                if ( left <= 5 )
                    self.hgm_left.color = ( 1, 0.28, 0.15 );
                else
                    self.hgm_left.color = ( 1.0, 0.62, 0.15 );
            }
        }
    }
}

hgm_listen_chat()
{
    level endon( "end_game" );

    for ( ;; )
    {
        level waittill( "say", msg, p );

        if ( !isdefined( msg ) || !isdefined( p ) )
            continue;

        cmd = hgm_clean( msg );
        if ( cmd != ".hgm" && cmd != ".hc" )
            continue;

        if ( !isdefined( p.hgm_ready ) || !p.hgm_ready )
            continue;

        p.hgm_show = !p.hgm_show;
        p hgm_apply_visible( 0.2 );

        if ( p.hgm_show )
            p iprintln( "^5[HGM]^7 counter ^2ON" );
        else
            p iprintln( "^5[HGM]^7 counter ^1OFF" );
    }
}

hgm_apply_visible( t )
{
    if ( !isdefined( self.hgm_bg ) )
        return;

    if ( isdefined( self.hgm_show ) && self.hgm_show )
    {
        self.hgm_bg fadeOverTime( t );
        self.hgm_bg.alpha = 0.62;
        self.hgm_edge fadeOverTime( t );
        self.hgm_edge.alpha = 0.95;
        self.hgm_tag fadeOverTime( t );
        self.hgm_tag.alpha = 1;
        self.hgm_round fadeOverTime( t );
        self.hgm_round.alpha = 1;
        self.hgm_time fadeOverTime( t );
        self.hgm_time.alpha = 1;
        self.hgm_left fadeOverTime( t );
        self.hgm_left.alpha = 1;
    }
    else
    {
        self.hgm_bg fadeOverTime( t );
        self.hgm_bg.alpha = 0;
        self.hgm_edge fadeOverTime( t );
        self.hgm_edge.alpha = 0;
        self.hgm_tag fadeOverTime( t );
        self.hgm_tag.alpha = 0;
        self.hgm_round fadeOverTime( t );
        self.hgm_round.alpha = 0;
        self.hgm_time fadeOverTime( t );
        self.hgm_time.alpha = 0;
        self.hgm_left fadeOverTime( t );
        self.hgm_left.alpha = 0;
    }
}

hgm_clean( s )
{
    if ( !isdefined( s ) )
        return "";

    // Strip leading spaces / chat prefixes so ".hgm" matches first word.
    for ( i = 0; i < 32; i++ )
    {
        if ( s == "" )
            return "";
        f = getSubStr( s, 0, 1 );
        if ( f == " " || f == "	" )
        {
            s = getSubStr( s, 1, 1024 );
            continue;
        }
        break;
    }

    // Keep first token only (" .hgm  extra" -> ".hgm").
    for ( i = 0; i < s.size; i++ )
    {
        if ( s[i] == " " )
            return getSubStr( s, 0, i );
    }
    return s;
}
