# Playable characters

### Classify
| Name | Value | AngelScript | Description |
|---|---|---|---|
| Security | 0 | ``Classification::Security`` | Security guard officer (Blue) |
| Scientist | 1 | ``Classification::Scientist`` | Scientist |
| Maintenance | 2 | ``Classification::Maintenance`` | Maintenance |
| Maintenance | 4 | ``Classification::HEV`` | Player is wearing a HEV suit |
| Hazard | 5 | ``Classification::Hazard`` | Player is wearing a HAZARD suit |
| Operative | 6 | ``Classification::Operative`` | Gray security guard |

<details>
<summary>AngelScript enumeration</summary>

```angelscript
// Players classification
enum Classification
{
    // Player not currently set to any class
    Unset = -1,
    // Security officer
    Security,
    // Science team
    Scientist,
    // Maintenance
    Maintenance,
    // HEV suit
    HEV = 4,
    // Hazard suit
    Hazard,
    // Operative security officer
    Operative,
    // Just a end of enum for size reference.
    __Size__
};
```

</details>

# Player view hands

### Classify
| Name | Value | AngelScript | Description |
|---|---|---|---|
| Blue | 0 | ``Hands::Blue`` | Security guard officer (Blue clothing) |
| White | 1 | ``Hands::White`` | Scientist arms (White clothing) |
| Orange | 2 | ``Hands::Orange`` | Maintenance arms (Orange clothing) |
| WhiteBlackHands | 3 | ``Hands::WhiteBlackHands`` | Black Scientist arms (White clothing) |
| Hevsuit | 4 | ``Hands::Hevsuit`` | HEV suit arms |
| Cleansuit | 5 | ``Hands::Cleansuit`` | Hazard clean suit arms |
| Gray | 6 | ``Hands::Gray`` | Operative arms (Gray clothing) |
| BlueBlackHands | 7 | ``Hands::BlueBlackHands`` | Black Security arms (Blue clothing) |
| Green | 8 | ``Hands::Green`` | Maintenance arms (Green clothing) |
| GrayGloves | 9 | ``Hands::GrayGloves`` | Operative with gloves arms (Gray clothing) |

<details>
<summary>AngelScript enumeration</summary>

```angelscript
// View model hands bodygroups
enum Hands
{
    Unset = -1,
    Blue = 0,
    White,
    Orange,
    WhiteBlackHands,
    Hevsuit,
    Cleansuit,
    Gray,
    BlueBlackHands,
    Green,
    GrayGloves,
    // Just a end of enum for size reference.
    __Size__
};
```

</details>
