# ===================================================================
# ===================================================================
# Purpose:
#   Apply license to all the script headers
# ===================================================================
# ===================================================================

import os;

gpBuilders = []
gpWorkspace: str = os.path.dirname( os.path.dirname( __file__ ) );

from Tests.PyBuilder import PyBuilder;

print( "Updating license headers..." );

import Tests.LicenseCheck;
Tests.LicenseCheck.LicenseCheck().apply_license(True);

input( "All done!" );
