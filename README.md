# Perfect Party

An addon for the game Garry's Mod that introduces a simple and easy to use partying system.

<img src="https://i.imgur.com/u1lbTwu.png" align="left" height="240">
<img src="https://i.imgur.com/i4G43Nr.png" height="240">

Below is information about the **configuration**, **chat commands**, **party settings**,  **installation** and **licencing**.

# Configuration

The configuration settings are stored in the `pConfig` variable in `/lua/shared.lua`.

| Settings Name | Default Value | Description |
|-|:-:|-|
| `prefix` | `!` | Prefix for chat commands. See the *Chat Commands* section. |
| `maxPartySize` | `4` | Maximum amount of players allowed in any one party. |
| `listBackground` | `true` | On-screen party list dark background. |
| `width` | `200` | Width of each players' information box. |
| `height` | `60` | Height of each players' information box. |
| `padding` | `10` | Padding (Inner margin) of each players' information box. |
| `spacing` | `5` | Vertical spacing in-between each players' information box. |
| `offsetLeft` | `50` | X-axis offset of each players' information box. |
| `offsetTop` | `20` | Y-axis offset of each players' information box. |
| `bgDefault` | `Color(250, 250, 250)` | Background colour of each players' information box.<br>This changes to `Color(255, 160, 160)` when the player is dead. |
| `statsBg` | `Color(160, 160, 160)` | Background colour of the bar *behind* the players' health and armour statbar. |
| `statsDrawText` | `true` | Display the actual value of the players' health and armour as text over their respective statsbar. |
| `defaultColour` | `Color(255, 255, 255)` | Default chat colour that should be used if no special one is being applied. |
| `logoColour` | `Color(220, 0, 0)` | Colour of the `[PParty]` logo that is prepended to all party chat messages. |
| `nameColour` | `Color(120, 255, 120)` | Highlight colour of player names in chat. |
| `partyColour` | `Color(60, 60, 255)` | Highlight colour of party names in chat. |
| `commandColour` | `Color(200, 200, 200)` | Highlight colour of command names and parameters in chat. |

# Chat Commands

| Command | Parameters  | Requires leader? | Description | Example Usage |
|-|-|:-:|-|-|
| `pcreate` | `<Party Name>` | No | Creates a party with the given name. | `!pcreate The Cool Mafia` |
| `pname` | `<Party Name>` | **Yes** | Renames your current party. | `!pname The Cooler Mafia` |
| `pdisband` | | **Yes** | Disbands your current party. Makes everyone leave including yourself. | `!pdisband` |
| `pinvite` | `<Player Name>` | **Yes** | Sends a party invite to another player. | `!pinvite Freddy101` |
| `paccept` | | No | Accepts the last sent party invitation.<br>(Invitations are queued. You can accept and decline in the order of receiving invitations). | `!paccept` |
| `pdecline` | | No | Declines the last sent party invitation. | `!pdecline` |
| `pdeclineall` | | No | Declines all currently pending invitations. | `!pdeclineall` |
| `pinvites` | | No | Lists all currently pending invitations in the order of receiving them. | `!pinvites` |
| `pleave` | | No | Leaves the currently joined party. Party leaders cannot directly leave. | `!pleave` |
| `pchat` OR `pc` | `<Message Text>` | No | Sends a chat message to everyone in the currently joined party. | `!pchat Hi everyone!` |
| `pkick` | `<Player Name>` | **Yes** | Kicks a target player from the party. | `!pkick Freddy101` |
| `pinfo` | | No | Provides information in chat about your party name and its member list. | `!pinfo` |
| `pset` | `<Setting Name> <Setting Value>` | **Yes** | Sets the value of a party setting for your party.<br>See the *Party Settings* section. | `!pset ff on` |

# Party Settings

These are settings for each individual party that can be altered by the party's leader.

| Name | Settings Name | Default Value | Description |
|-|-|-|-|
| Friendly Fire | `ff` or `friendlyfire` | `off` | Players of in the same party can damage eachother. |
| Head Indicator | `hi` or `headindicator` | `on` | Display a small icon above fellow party members' heads to easily identify them. |

# Installation

Simply create a new folder in your `/addons/` directory on your server called `PerfectParty` and then drag-and-drop the `/lua/` folder from this repository into the newly made directory.

# Licence

This project uses the **Mozilla Public License 2.0**.
