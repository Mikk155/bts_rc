mixin class CBaseMelee
{
    protected TraceResult m_trHit;
    protected int m_iSwing = 0;

    void PrimaryAttack()
    {
        if( !Swing( true ) )
        {
            SetThink( ThinkFunction( this.SwingAgain ) );
            pev.nextthink = g_Engine.time + 0.1f;
        }
    }

    protected void SwingAgain()
    {
        Swing( false );
    }

    protected void Smack()
    {
        g_WeaponFuncs.DecalGunshot(m_trHit, BULLET_PLAYER_CROWBAR);
    }
}
