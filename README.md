# HighStack 3D

A real-time 3D mobile stacking game prototype/production foundation built with Godot 4.7.2 and Blender-generated assets.

## Art direction
Original stylized mobile 3D: glossy rounded forms, bright readable materials, soft shadows, toy-like props, and an original mascot. Inspired by the level of polish common to successful casual mobile games, without copying proprietary characters/assets/branding.

## Core systems
- 3D physics stacking
- Height/score/coin progression
- Perfect placement combo
- 5 wooden-block skill upgrades
- 3 rescue items: Stabilizer, Safety Platform, Undo Crane
- Casual and Ranked modes
- Rank ladder and local/simulated rivals
- Rewarded-rescue demo service
- Shop/economy shell ready for production AdMob/IAP adapters
- Android portrait build

## Build
GitHub Actions generates 3D GLB assets through Blender, imports them in Godot, then exports a signed debug APK artifact.
