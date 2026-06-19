# ===================================================================
# ===================================================================
# Purpose:
#   Check validation of AngelScript IConfigurableContext::GetSchema
# ===================================================================
# ===================================================================

from typing import Any

from Tests.PyBuilder import PyBuilder;

Github = False  # global

class SchemaCheck( PyBuilder ):

    def Build(self) -> bool:

        import os;
        import pathlib;
        import re
        import json

        classRegex = re.compile( r'class\s+([A-Za-z_]\w*)\s*:\s*([^{};]*\bIConfigurableContext\b[^{};]*)', re.MULTILINE );
        schemaRegex = re.compile( r'GetSchema\s*\(\s*\)\s*const\s*(?:override\s*)?\{\s*return\s*"""(.*?)"""', re.DOTALL );

        invalidSchemasTotal: int = 0;
        invalidFiles: int = 0;

        scriptFilesPath: str = os.path.join( self.Workspace, "scripts", "maps", "bts_rc" );

        for path in pathlib.Path( scriptFilesPath ).rglob( f"*.as" ):

            if not path.is_file():
                continue;

            content: str = None;

            with open( path, "r", encoding="utf-8" ) as fStream:
                content: str = fStream.read();
                fStream.close();

            invalidSchemas: int = 0;

            for classMatch in classRegex.finditer( content ):

                className = classMatch.group(1);

                schemaMatch = schemaRegex.search( content, classMatch.end() );

                if not schemaMatch:
                    print(f"{path.relative_to(self.Workspace)} > class \"{className}\" has no raw string at GetSchema()" );
                    invalidSchemas += 1;
                    continue;

                rawJson: str = schemaMatch.group(1)

                try:
                    parsed = json.loads( rawJson );
                except json.JSONDecodeError as e:
                    lines: int = len( content[ 0 : schemaMatch.span(1)[0] ].splitlines() ) - 2;
                    self.Log( f"{path.relative_to(self.Workspace)} > invalid JSON in {className}: {e.msg} at line {e.lineno + lines}:{e.colno}" );
                    invalidSchemas += 1;
                    continue;

                if self.Type == PyBuilder.BuildType.Release:
                    compact: str = json.dumps( parsed, separators=( ",", ":" ) );
                    start, end = schemaMatch.span(1);
                    content = content[ : start ] + compact + content[ end : ];
                    with open( path, "w", encoding="utf-8" ) as fStream:
                        fStream.write(content);

            if invalidSchemas > 0:
                invalidSchemasTotal += invalidSchemas;
                invalidFiles += 1;

        self.Log( "All AngelScript configuration schemas checked" );

        return ( invalidFiles == 0 );

SchemaCheck();
