# Enshrouded

Enshrouded is a survival action RPG set in a voxel-based open world. Up to 16 players can play together on a dedicated server.

**Server Environment**

The dedicated server is Windows only. It runs under Proton using the `ghcr.io/parkervcp/steamcmd:proton` image, which also updates the server on boot when `AUTO_UPDATE` is enabled.

**Server Ports**

| Port  | Default | Protocol |
| ----- | ------- | -------- |
| Query | 15637   | UDP      |

Enshrouded only uses the query port. The separate game port was removed in a game update, so you only need one allocation.

**Server Startup Command**

```bash
xvfb-run -a proton run ./enshrouded_server.exe
```

See [startup.sh](./startup.sh) for the full command. It tails the server log, because the server does not write to stdout under Proton.

The server runs inside `xvfb-run` because newer Proton releases (GE-Proton 11+) hang on startup when no display is available.

## Environment Variables

| Variable | Default | Description | Example |
| -------- | ------- | ----------- | ------- |
| SERVER_NAME | `Enshrouded Server` | Server name shown in the server browser | `My Server` |
| MAX_PLAYERS | `16` | Maximum number of players (1-16) | `8` |
| GAME_PRESET | `Default` | Difficulty preset: `Default`, `Relaxed`, `Hard`, `Survival` or `Custom` | `Hard` |
| ADMIN_PASSWORD | | Password for the Admin group (can kick/ban, edit and extend bases, access inventories) | `hunter2` |
| FRIEND_PASSWORD | | Password for the Friend group (can edit bases and access inventories) | `friends` |
| GUEST_PASSWORD | | Password for the Guest group (cannot touch bases or inventories) | `guests` |
| ENABLE_VOICE_CHAT | `0` | Enable in-game voice chat | `1` |
| VOICE_CHAT_MODE | `Proximity` | `Proximity` (only nearby players hear you) or `Global` (everyone hears everyone) | `Global` |
| ENABLE_TEXT_CHAT | `0` | Enable in-game text chat | `1` |
| AUTO_UPDATE | `1` | Update the server on boot | `0` |

A player's password decides which group they join as. If a group's password is empty, anyone can join with that group's permissions. That's why the egg requires `ADMIN_PASSWORD`.

## Configuration

The install script creates `enshrouded_server.json` if it does not already exist. It never overwrites an existing config.

On every boot, Pelican writes the server name, port, slot count, difficulty preset, chat settings and group passwords into the config. The passwords are set by array index (`userGroups.0` = Admin, `userGroups.1` = Friend, `userGroups.2` = Guest), so keep those three groups first if you edit the groups by hand.

### Custom difficulty

To fine-tune difficulty, set `GAME_PRESET` to `Custom` and edit the `gameSettings` object in `enshrouded_server.json`. It has factors for player health, mana and stamina, enemy and boss damage and health, XP, resource drops, day and night length, and more. The server ignores `gameSettings` with any other preset. Pelican doesn't touch `gameSettings`, so your edits are kept.

### Upgrading from an older egg version

Pelican only writes the chat toggles as true/false values if the keys already exist in the config. If your config was created before these variables were added, add these keys to `enshrouded_server.json` once, with the server stopped:

```json
"enableVoiceChat": false,
"voiceChatMode": "Proximity",
"enableTextChat": false,
```
