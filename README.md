# Perfect Party

An addon for the game Garry's Mod that introduces a simple and easy to use partying system.

<img src="https://i.imgur.com/u1lbTwu.png" align="left" height="240">
<img src="https://i.imgur.com/i4G43Nr.png" height="240">

Below is information about the **configuration**, **chat commands**, **party settings**,  **installation** and **licencing**.

# Configuration

The configuration settings are stored in the `pConfig` variable in `/lua/shared.lua`.

| Settings Name | Default Value | Description |
|-|-|-|
| `prefix` | `!` | The prefix for chat commands. See the *Chat Commands* section. |
| `maxPartySize` | `4` | The maximum amount of players allowed in any one party. |
| `listBackground` | `true` | On-screen party list dark background. |
| `width` | `200` | The width of each players' information box. |
| `height` | `60` | The height of each players' information box. |
| `padding` | `10` | The padding (Inner margin) of each players' information box. |
| `spacing` | `5` | The vertical spacing in-between each players' information box. |
| `offsetLeft` | `50` | The x-axis offset of each players' information box. |
| `offsetTop` | `20` | The y-axis offset of each players' information box. |
| `bgDefault` | `Color(250, 250, 250)` | The background colour of each players' information box.<br>This changes to `Color(255, 160, 160)` when the player is dead. |
| `statsBg` | `Color(160, 160, 160)` | The background colour of the bar *behind* the players' health and armour statbar. |
| `statsDrawText` | `true` | Display the actual value of the players' health and armour as text over their respective statsbar. |

# Chat Commands

| Command | Parameters  | Requires leader? | Description | Example Usage |
|-|-|:-:|-|-|
| `pcreate` | `<Party Name>` | No | Create a party with the given name. | `!pcreate The Cool Mafia` |
| `pname` | `<Party Name>` | **Yes** | Rename your current party. | `!pname The Cooler Mafia` |
| `pdisband` | | **Yes** | Disband your current party. Makes everyone leave including yourself. | `!pdisband` |
| `pinvite` | `<Player Name>` | **Yes** | Sends a party invite to another player. | `!pinvite Freddy101` |
| `paccept` | | No | Accepts the last sent party invitation.<br>(Invitations are queued. You can accept and decline in the order of receiving invitations). | `!paccept` |
| `pdecline` | | No | Declines the last sent party invitation. | `!pdecline` |
| `pleave` | | No | Leaves the currently joined party. Party leaders cannot directly leave. | `!pleave` |
| `pkick` | `<Player Name>` | **Yes** | Kicks a target player from the party. | `!pkick Freddy101` |
| `pinfo` | | No | Provides information in chat about your party name and its member list. | `!pinfo` |
| `pset` | `<Setting Name> <Setting Value>` | **Yes** | Set the value of a party setting for your party.<br>See the *Party Settings* section. | `!pset ff on` |

# Party Settings

These are settings for each individual party that can be altered by the party's leader.

| Name | Settings Name | Default Value | Description |
|-|-|-|-|
| Friendly Fire | `ff` or `friendlyfire` | `off` | Whether players of in the same party can damage eachother or not. |
| Head Indicator | `hi` or `headindicator` | `on` | Display a small icon above fellow party members' heads to easily identify them. |

# Installation

1. Create a new folder in your `/addons/` directory in your server called `PerfectParty`.
2. Create a new directory `/lua/autorun/` inside the newly created directory.
3. Insert the contents of the `/lua/` folder in this directory into the `./autorun/` directory.

# Licence

This project uses the **Mozilla Public License 2.0**.
