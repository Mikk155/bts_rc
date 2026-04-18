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

class item_bts_skeleton : item_bts_armorvest
{
    const string& get_m_Model() override {
        return "models/bts_rc/items/skeleton_guard.mdl";
    }

    bool m_IsEmpty = false;

    void Precache()
    {
        g_Game.PrecacheModel( self, "models/skeleton.mdl" );
        BTS_Item::Precache();
    }

    void Spawn()
    {
        BTS_Item::Spawn();
        self.pev.spawnflags |= 1; // Don't kill
    }

    bool AddAmmo( CBaseEntity@ other )
    {
        if( !m_IsEmpty && item_bts_armorvest::AddAmmo( other ) )
        {
            m_IsEmpty = true;
            self.pev.model = "models/skeleton.mdl";
            g_EntityFuncs.SetModel( self, this.model );
        }

        return false;
    }
}
