/**   MIT License
*   
*   Copyright (c) 2025 Mikk155 https://github.com/Mikk155/bts_rc
*   
*   Permission is hereby granted, free of charge, to any person obtaining a copy
*   of this software and associated documentation files (the "Software"), to deal
*   in the Software without restriction, including without limitation the rights
*   to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
*   copies of the Software, and to permit persons to whom the Software is
*   furnished to do so, subject to the following conditions:
*   
*   The above copyright notice and this permission notice shall be included in all
*   copies or substantial portions of the Software.
*   
*   THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
*   IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
*   FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
*   AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
*   LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
*   OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
*   SOFTWARE.
*/

/*
    Author: Mikk
*/

class BlackOpsFlashbang : EntityOverriden
{
    const string& get_Name() {
        return "blackops_flashbang";
    }

    float throw_flash_cooldown;

    void Parse( dictionary@ json ) override
    {
        bool active;

        if( json.get( "active", active ) && !active )
            return;

        if( !json.get( "throw_flash_cooldown", throw_flash_cooldown ) )
            throw_flash_cooldown = 30;

        this.nextthink = 0.4f;
        g_Game.PrecacheModel( "models/bts_rc/weapons/w_fgrenade.mdl" );
    }

    void AddEntity( uint index, CBaseEntity@ entity, CustomKeyvalues@ ckv, CBaseMonster@ monster ) override
    {
        if( ckv.GetKeyvalue( "$i_use_flashbang" ).GetInteger() == 1 )
            EntityOverriden::AddEntity( index, entity, ckv, monster );
    }

    float flLastGrenadeThrown;

    void TrackGrenade( EHandle hOwner )
    {
        CBaseEntity@ owner = null;

        if( !hOwner.IsValid() || ( @owner = hOwner.GetEntity() ) is null || !owner.IsAlive() )
        {
            this.flLastGrenadeThrown = 0; // Try again with someone else
            return;
        }

        edict_t@ ownerEdict = owner.edict();
        CBaseEntity@ grenade = null;

        while( ( @grenade = g_EntityFuncs.FindEntityByClassname( grenade, "grenade" ) ) !is null && grenade.pev.owner is ownerEdict )
        {
            g_EntityFuncs.SetModel( grenade, "models/bts_rc/weapons/w_fgrenade.mdl" );
            g_Scheduler.SetTimeout( @this, "FlashbangThink", 0.1f, EHandle(grenade) );
            return;
        }

        g_Scheduler.SetTimeout( @this, "TrackGrenade", 0.1f, EHandle(owner) );
    }

    void FlashbangThink( EHandle hFlashbang )
    {
    }

    bool EntityThink( uint index, CBaseEntity@ entity, CBaseMonster@ monster ) override
    {
        if( this.flLastGrenadeThrown > g_Engine.time || monster is null || !monster.IsAlive() )
            return false;

        if( monster.m_hEnemy.IsValid() )
        {
            // Force somebody to throw a grenade.
            if( this.flLastGrenadeThrown < g_Engine.time && monster.pev.sequence != 6 )
            {
                monster.SetActivity( ACT_RANGE_ATTACK2 );
                this.flLastGrenadeThrown = g_Engine.time + this.throw_flash_cooldown;
                g_Scheduler.SetTimeout( @this, "TrackGrenade", 0.1f, EHandle(entity) );
            }
        }

        return true;
    }
}

BlackOpsFlashbang gpBlackopsFlashbangs;
