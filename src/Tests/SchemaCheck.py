# ===================================================================
# ===================================================================
# Purpose:
#   Check validation of AngelScript IConfigurableContext::GetSchema
# ===================================================================
# ===================================================================

import re
import json

from Tests.PyBuilder import PyBuilder;

class SchemaCheck( PyBuilder ):

    def Build(self) -> bool:

        classRegex = re.compile( r'class\s+([A-Za-z_]\w*)\s*:\s*([^{};]*\bIConfigurableContext\b[^{};]*)', re.MULTILINE );
        schemaRegex = re.compile( r'GetSchema\s*\(\s*\)\s*const\s*(?:override\s*)?\{\s*return\s*"""(.*?)"""', re.DOTALL );

        invalidSchemasTotal: int = 0;
        invalidFiles: int = 0;

        for script in self.Scripts:

            invalidSchemas: int = 0;

            for classMatch in classRegex.finditer( script.Content ):

                className = classMatch.group(1);

                schemaMatch = schemaRegex.search( script.Content, classMatch.end() );

                if not schemaMatch:
                    print(f"{script.Path} > class \"{className}\" has no raw string at GetSchema()" );
                    invalidSchemas += 1;
                    continue;

                rawJson: str = schemaMatch.group(1)

                try:
                    parsed = json.loads( rawJson );
                except json.JSONDecodeError as e:
                    lines: int = len( script.Content[ 0 : schemaMatch.span(1)[0] ].splitlines() ) - 2;
                    self.Log( f"{script.Path} > invalid JSON in {className}: {e.msg} at line {e.lineno + lines}:{e.colno}" );
                    invalidSchemas += 1;
                    continue;

                if self.Type == PyBuilder.BuildType.Release and invalidSchemas == 0 and invalidSchemasTotal == 0:
                    compact: str = json.dumps( parsed, separators=( ",", ":" ) );
                    start, end = schemaMatch.span(1);
                    script.Content = script.Content[ : start ] + compact + script.Content[ end : ];

            if invalidSchemas > 0:
                invalidSchemasTotal += invalidSchemas;
                invalidFiles += 1;

        self.Log( "All AngelScript configuration schemas checked" );

        return ( invalidFiles == 0 );

SchemaCheck();
