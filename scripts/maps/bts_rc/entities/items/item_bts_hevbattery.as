namespace items
{
    class item_bts_hevbattery : BTS_Item
    {
        const string& get_m_PlaySound() override {
            return "items/gunpickup2.wav";
        }

        CSprite@ m_Sprite;

        protected const string& GetModel() override {
            return "models/bts_rc/weapons/w_battery.mdl";
        }

        bool AddAmmo( CBaseEntity@ other )
        {
            if( !IsValid( other ) || other.pev.armorvalue >= other.pev.armortype )
                return false;

            CBasePlayer@ player = cast<CBasePlayer@>( other );

            auto character = GetCharacter(player);

            if( player is null || character is null || !( character.IsHEV || character.IsHazard ) || !player.TakeArmor( Math.RandomFloat( 10, 25 ), DMG_GENERIC ) )
                return false;

            if( character.IsHEV )
            {
                int pct = int( float( player.pev.armorvalue * 100.0 ) * ( 1.0 / 100 ) + 0.5 );

                pct = ( pct / 5 );

                if( pct > 0 )
                    pct--;

                string szcharge;
                snprintf( szcharge, "!HEV_%1P", pct );

                player.SetSuitUpdate( szcharge, false, 30 );
            }

            g_EntityFuncs.Remove( m_Sprite );

            PickupObject( player, "item_battery" );

            return true;
        }

        void UpdateOnRemove()
        {
            g_EntityFuncs.Remove( m_Sprite );
        }

        void Think()
        {
            if( !gpBatteryLighting )
                return;

            self.pev.nextthink = g_Engine.time + 0.1f;

            if( m_Sprite is null )
            {
                @m_Sprite = g_EntityFuncs.CreateSprite( "sprites/glow01.spr", g_vecZero, true );
                m_Sprite.pev.rendermode = kRenderGlow;
                m_Sprite.pev.renderamt = 255;
                m_Sprite.pev.rendercolor.x = 50;
                m_Sprite.pev.rendercolor.y = 100;
                m_Sprite.pev.rendercolor.z = 255;
            }

            m_Sprite.pev.origin = self.pev.origin;
            m_Sprite.pev.origin.z += 4;

            // Unreliable, PVS
            NetworkMessage message( MSG_PVS, NetworkMessages::SVC_TEMPENTITY );
                message.WriteByte( TE_DLIGHT );
                message.WriteCoord( m_Sprite.pev.origin.x );
                message.WriteCoord( m_Sprite.pev.origin.y );
                message.WriteCoord( m_Sprite.pev.origin.z );
                message.WriteByte( 4 );   // radius
                message.WriteByte( 50 ); // R
                message.WriteByte( 100 );   // G
                message.WriteByte( 255 );   // B
                message.WriteByte( 30 );   // life in 0.1's
                message.WriteByte( 1 );   // decay in 0.1's
            message.End();
        }
    }
}
