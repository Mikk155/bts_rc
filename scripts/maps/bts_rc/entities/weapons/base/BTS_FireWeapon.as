abstract class BTS_FireWeapon : BTS_Weapon
{
    float Accuracy( float tr, float def, float trd, float defd )
    {
        auto player = this.owner;

        if( util::IsTrainedPersonal( player ) )
        {
            if( ( player.pev.button & IN_DUCK ) != 0 )
            {
                return trd;
            }
            return tr;
        }
        else if( ( player.pev.button & IN_DUCK ) != 0 )
        {
            return defd;
        }
        return def;
    }
}
