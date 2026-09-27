# ===================================================================
# ===================================================================
# Purpose:
#   Download dependancies
# ===================================================================
# ===================================================================

import os;
import sys;

gpWorkspace: str = os.path.dirname( os.path.dirname( os.path.dirname( __file__ ) ) );
gpBuilders = []

sys.path.append( os.path.join( gpWorkspace, "src" ) );

import Tests.DependancyCheck;
Tests.DependancyCheck.DependancyCheck().Build();

input( "All done!" );
