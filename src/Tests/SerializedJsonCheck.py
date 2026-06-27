# ===================================================================
# ===================================================================
# Purpose:
#   Generate release information changelog and tags from AS semantic version
# ===================================================================
# ===================================================================

import re;
import json;

from Tests.PyBuilder import PyBuilder

class SerializedJsonCheck( PyBuilder ):

    def Build(self) -> bool:

        tripleRegex = re.compile( r'"""(.*?)"""', re.DOTALL );

        invalidSchemasTotal: int = 0;
        invalidFiles: int = 0;

        totalCharacters = 0;
        newTotalCharacters = 0;

        for script in self.Scripts:

            invalidSchemas: int = 0;
            content: str = script.Content;

            matches = list( tripleRegex.finditer( content ) );

            newContent = content;
            delta = 0;

            for match in matches:

                if len(match.groups()) <= 0:
                    continue;

                rawJson: str = match.group(1);

                if '\n' not in rawJson:
                    continue;

                stripped = rawJson.lstrip();

                if len(stripped) == 0:
                    continue;

                if stripped[0] != '{' and stripped[0] != '[':
                    continue;

                try:
                    parsed = json.loads( stripped );
                except json.JSONDecodeError as e:
                    lineOffset: int = len( content[ 0 : match.start(1) ].splitlines() ) - 2;
                    self.Log( "{} > invalid JSON: {} at line {}:{}", script.Path, e.msg, e.lineno + lineOffset, e.colno );
                    invalidSchemas += 1;
                    continue;

                if self.Type == PyBuilder.BuildType.Release and invalidSchemas == 0 and invalidSchemasTotal == 0:
                    compact: str = json.dumps( parsed, separators=( ",", ":" ) );
                    start = match.start(1) + delta;
                    end   = match.end(1) + delta;
                    newContent = newContent[ : start ] + compact + newContent[ end : ];
                    delta += len(compact) - (match.end(1) - match.start(1));
                    self.Log( "Compact json {} -> {} chars at {}", len(rawJson), len(compact), script.Path );
                    totalCharacters += len(rawJson);
                    newTotalCharacters += len(compact);

            script.Content = newContent;

            if invalidSchemas > 0:
                invalidSchemasTotal += invalidSchemas;
                invalidFiles += 1;

        if self.Type == PyBuilder.BuildType.Release and invalidSchemas == 0 and invalidSchemasTotal == 0:
            self.Log( "Removed {} characters from schemas. Total: {} -> {} {}% percent optimized.",
                ( totalCharacters - newTotalCharacters ),
                totalCharacters,
                newTotalCharacters,
                int( ( newTotalCharacters / totalCharacters ) * 100 )
            );

        self.Log( "All AngelScript json string literals checked" );

        return ( invalidFiles == 0 )

SerializedJsonCheck();
