# ===================================================================
# ===================================================================
# Purpose:
#   Check validation of AngelScript IConfigurable::GetSchema
# ===================================================================
# ===================================================================

import re;
import json;

from Tests.PyBuilder import PyBuilder

class SchemaCheck( PyBuilder ):

    def Build(self) -> bool:

        classRegex = re.compile( r'class\s+([A-Za-z_]\w*)\s*:\s*([^{};]*\bIConfigurable\b[^{};]*)', re.MULTILINE );
        methodRegex = re.compile( r'GetSchema\s*\(\s*\)\s*const\s*(?:override\s*)?\s*\{' );
        tripleRegex = re.compile( r'"""(.*?)"""', re.DOTALL );

        invalidSchemasTotal: int = 0;
        invalidFiles: int = 0;

        for script in self.Scripts:

            invalidSchemas: int = 0;
            content: str = script.Content;

            for classMatch in classRegex.finditer( content ):

                className = classMatch.group(1);

                methodMatch = methodRegex.search( content, classMatch.end() );

                if not methodMatch:
                    self.Log( "{} > class \"{}\" has no GetSchema()", script.Path, className );
                    invalidSchemas += 1;
                    continue;

                blockStart = methodMatch.end() - 1;

                def extractBlock( content: str, startPos: int ) -> int:
                    depth = 0;
                    for i in range( startPos, len( content ) ):
                        c = content[i];
                        if c == '{':
                            depth += 1;
                        elif c == '}':
                            depth -= 1;
                            if depth == 0:
                                return i;
                    return -1

                blockEnd = extractBlock( content, blockStart );

                if blockEnd == -1:
                    self.Log( "{} > class \"{}\" malformed GetSchema()", script.Path, className );
                    invalidSchemas += 1;
                    continue;

                methodBody = content[ blockStart + 1 : blockEnd ];
                methodOffset = blockStart + 1;

                matches = list( tripleRegex.finditer( methodBody ) );

                if len( matches ) == 0:
                    if not "\"" in methodBody:
                        if "return String::EMPTY_STRING" in methodBody:
                            continue;
                    self.Log( "{} > class \"{}\" has no triple-quoted JSON.", script.Path, className );
                    invalidSchemas += 1;
                    continue;

                for match in matches:

                    rawJson: str = match.group(1);

                    try:
                        parsed = json.loads( rawJson );
                    except json.JSONDecodeError as e:
                        lineOffset = len( content[ : methodOffset + match.start(1) ].splitlines() ) - 1;
                        self.Log( "{} > invalid JSON in {}: {} at line {}:{}", script.Path, className, e.msg, e.lineno + lineOffset, e.colno );
                        invalidSchemas += 1;
                        continue;

            if invalidSchemas > 0:
                invalidSchemasTotal += invalidSchemas;
                invalidFiles += 1;

        self.Log( "All AngelScript configuration schemas checked" );

        return ( invalidFiles == 0 );

SchemaCheck();
