# The Great Machine Design Notes and Whatnot

## Game Design
Once the players have connected to the match, each player is given a unique name and unique set of controls. As the match progresses, random tasks are selected and broadcast to a random player. The player with the appropriate controls needs to satisfy the tasks as quickly as possible. As the match progresses, the longer it takes each player to complete the tasks, The Great Machine's Upkeep Value continues to drop. Once the Upkeep Value reaches 0, the match ends. Performing an incorrect action reduces the Upkeep Value exponentially. The player with the most tasks completed and the player with the most tasks failed/incorrect inputs are highlighted at the end of the match.

### MVP
- 1 player can connect to a server, get a display of controls, can be sent tasks, and can complete a match.

### MVP+
- 2+ players can cannect to the same server, be sent a unique set of controls, be sent tasks, and can complete a match.

### MVP++
- Keep track of number of errors and failed tasks as well as successess and present them at the end of the match.
- Difficulty setting which varies match length and number of generated widgets

## Technical Design
### Server States
- Lobby : Channel
- Match : Channel

### Server Requirements
- Lobby for connected Players awaiting a Match
- Matchmaking
- Track Players in a Match

### Client States
- Matchmaking
- Match Starting
- Match In Progress
- Match Over

