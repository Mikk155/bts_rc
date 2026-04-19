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

enum AttackType
{
    Primary = 0,
    Secondary,
    Tertriary
};

// Base class for all weapons
abstract class BTS_Weapon : ScriptBasePlayerWeaponEntity
{
    ASWeaponConfig@ get_config() {
        if( g_Logger.critical )
            g_Logger.critical = snprintf( glog, "%1 does not override ASWeaponConfig@ BTS_Weapon::get_config()" );
        return null;
    }

    CBasePlayer@ m_owner = null;

    /// Get the player owning this weapon
    CBasePlayer@ get_owner()
    {
        if( m_owner is null || m_owner !is self.m_hPlayer.GetEntity() )
        {
            @m_owner = cast<CBasePlayer>( self.m_hPlayer.GetEntity() );
        }
        return @m_owner;
    }

    void Spawn()
    {
        g_EntityFuncs.SetModel( self, this.config.world_model );
        self.FallInit();
    }

    bool Deploy() {
        return weapons::Deploy( self, this.owner, this.config );
    }

    bool GetItemInfo( ItemInfo& out info )
    {
        info.iMaxAmmo1 = this.config.primary_maxammo;
        info.iAmmo1Drop = this.config.primary_dropammo;
        info.iMaxAmmo2 = this.config.secondary_maxammo;
        info.iAmmo2Drop = this.config.secondary_dropammo;
        info.iMaxClip = this.config.max_clip;
        info.iSlot = this.config.slot;
        info.iPosition = this.config.position;
        info.iWeight = this.config.weight;
        info.iId = g_ItemRegistry.GetIdForName( self.pev.classname );
        info.iFlags = gpDefaultWeaponFlags; // -TODO To "weapons" context?
        return true;
    }

    // Called on weapon idle. return the next call time
    float Idle()
    {
        return 60.0f;
    }

    void WeaponIdle()
    {
        if( self.m_flTimeWeaponIdle < g_Engine.time )
        {
            self.m_flTimeWeaponIdle = Idle();
        }
    }

    bool AddToPlayer( CBasePlayer@ player )
    {
        if( !BaseClass.AddToPlayer( player ) )
            return false;

        NetworkMessage msg( MSG_ONE, NetworkMessages::WeapPickup, player.edict() );
            msg.WriteLong( g_ItemRegistry.GetIdForName( self.pev.classname ) );
        msg.End();

        return true;
    }

    protected array<CScheduledFunction@> __Callbacks__;

    // Use g_Scheduler.SetTimeout as value and the resulting callback object will be stored in the weapon base and cleared if the weapon is removed or holstered
    void StartSchedule( CScheduledFunction@ value )
    {
        __Callbacks__.insertLast( @value );
    }

    void ClearTimerList()
    {
        uint length = __Callbacks__.length();

        for( uint ui = 0; ui < length; ui++ )
        {
            auto callback = __Callbacks__[ui];

            if( callback !is null )
            {
                g_Scheduler.RemoveTimer( @callback );
            }
        }

        __Callbacks__.resize(0);
    }

    void UpdateOnRemove()
    {
        ClearTimerList();
        BaseClass.UpdateOnRemove();
    }

    void Holster( int skiplocal = 0 )
    {
        ClearTimerList();
        BaseClass.Holster( skiplocal );
    }

    // Set weapon cooldown
    void SetCooldown( bool is_trained_personal, AttackType type ) {
        weapons::SetCooldown( self, config.GetCooldown( is_trained_personal, type ) );
    }

    // Play the given animation for this weapon. if player_attack_animation is true (by default) it makes the player animation to PLAYER_ATTACK1
    void PlayAnim( uint8 animation, bool player_attack_animation = true )
    {
        self.SendWeaponAnim( animation, 0, pev.body );

        if( player_attack_animation )
            this.owner.SetAnimation( PLAYER_ANIM::PLAYER_ATTACK1 );
    }

    // Force a sequence type animation on the player
    void ForcePlayerAnim( int iStandSequence, int iDuckSequence )
    {
        int iGaitSequence;

        auto player = this.owner;

        switch( player.m_Activity )
        {
            case ACT_HOVER:
            case ACT_SWIM:
            case ACT_HOP:
            case ACT_LEAP:
            case ACT_DIESIMPLE:
                break;
            default:
                iGaitSequence = player.pev.gaitsequence;
                player.m_Activity = ACT_RELOAD;
                player.pev.sequence = ( ( player.pev.flags & FL_DUCKING ) != 0 ) ? iDuckSequence : iStandSequence;
                player.pev.gaitsequence = iGaitSequence;
                player.pev.frame = 0.0f;
                player.ResetSequenceInfo();
                break;
        }
    }

    void TraceEffects( TraceResult &in tr, Bullet bullet = Bullet::BULLET_NONE ) {
        weapons::TraceEffects( self, this.owner, this.config, tr, bullet );
    }

    protected uint8 __last_random__ = 0;

    // Get a random number between 0 and max. if RandomUint was called before the result will be stored in __last_random__ to avoid repeating the same number in a row
    uint8 RandomUint( uint8 max )
    {
        if( max == 0 )
        {
            if( g_Logger.critical )
                g_Logger.critical = snprintf( glog, "RandomUint called with an argument of zero!" );
            return 0;
        }

        uint8 rand;

        do{ rand = Math.RandomLong( 0, max ); }
        while( rand == this.__last_random__ );

        this.__last_random__ = rand;

        return rand;
    }

    // Play the given sound uses EmitSoundDyn at the weapon location
    void PlaySound( const string&in soundName, float volume = 1.0f, int pitch = PITCH_NORM, float attenuation = ATTN_NORM )
    {
        g_SoundSystem.EmitSoundDyn( self.edict(), SOUND_CHANNEL::CHAN_WEAPON, soundName, volume, attenuation, 0, pitch );
    }

    // weapon attack
    void Attack( CBasePlayer@ player, AttackType type )
    {
    }

    // Return whatever this is a solid entity or worldspawn
    bool IsBrush( CBaseEntity@ hit )
    {
        return true;
    }

    // Return whatever this is a flesh body
    bool IsFlesh( CBaseEntity@ hit )
    {
        return ( hit !is null && hit.pev.takedamage > DAMAGE_NO && ( hit.IsMonster() || hit.IsPlayer() ) && hit.Classify() != CLASS_MACHINE );
    }

    private void __Attack__( AttackType type )
    {
        Attack( this.owner, type );
    }

    void PrimaryAttack()
    {
        __Attack__( AttackType::Primary );
    }

    void SecondaryAttack()
    {
        __Attack__( AttackType::Secondary );
    }
}
