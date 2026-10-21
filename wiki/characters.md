# Playable characters and view-model hands

The player classification and the view-model hand style are separate values.

## Player classifications

| Name | Value | AngelScript | Description |
|---|---:|---|---|
| Unset | -1 | `Classification::Unset` | No class selected. |
| Security | 0 | `Classification::Security` | Security officer. |
| Scientist | 1 | `Classification::Scientist` | Science team member. |
| Maintenance | 2 | `Classification::Maintenance` | Maintenance worker. |
| HEV | 3 | `Classification::HEV` | Player in an HEV suit. |
| Hazard | 4 | `Classification::Hazard` | Player in a hazard suit. |
| Operative | 5 | `Classification::Operative` | Gray-uniform security operative. |

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
    HEV,
    // Hazard suit
    Hazard,
    // Operative security officer
    Operative,
    // End marker used as the enum size.
    __Size__
};
```

</details>

## Player view-model hands

| Name | Value | AngelScript | Description |
|---|---:|---|---|
| Unset | -1 | `Hands::Unset` | No hand style selected. |
| Blue | 0 | `Hands::Blue` | Blue security sleeves. |
| White | 1 | `Hands::White` | White scientist sleeves. |
| Orange | 2 | `Hands::Orange` | Orange maintenance sleeves. |
| WhiteBlackHands | 3 | `Hands::WhiteBlackHands` | White sleeves with black hands. |
| Hevsuit | 4 | `Hands::Hevsuit` | HEV suit sleeves. |
| Cleansuit | 5 | `Hands::Cleansuit` | Hazard clean-suit sleeves. |
| Gray | 6 | `Hands::Gray` | Gray operative sleeves. |
| BlueBlackHands | 7 | `Hands::BlueBlackHands` | Blue sleeves with black hands. |
| Green | 8 | `Hands::Green` | Green maintenance sleeves. |
| GrayGloves | 9 | `Hands::GrayGloves` | Gray operative sleeves with gloves. |

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
    // End marker used as the enum size.
    __Size__
};
```

</details>
