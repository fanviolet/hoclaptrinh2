# Arena provider boundary (v1)

The shipped provider is an explicitly labelled offline, score-simulating bot. Easy,
Normal and Hard use different cadence and success rates. A match lasts 90 seconds;
collapse immediately loses, otherwise score decides (equal score draws). A win
awards 100 coins exactly once. Menus suspend both players' simulation clocks.

`arena_session.gd` exposes `start(seed, difficulty)`, `tick(delta)`,
`opponent_updated(height, score)`, `match_finished`, `snapshot()` and
`human_connection_status()`. Gameplay observes this boundary rather than managing
a transport. Version 1 snapshots contain protocol, seed, remaining, opponent_height,
opponent_score and provider. The human entry point is disabled until configured.

For online play, implement a server provider at this boundary using authenticated
WebSocket messages. A server must issue match IDs and shared block seeds, own the
clock, validate ordered placement events, handle disconnect/rejoin, and issue an
idempotent result/reward receipt. Never trust a remote client's raw score or use a
client-supplied reward. Add matchmaking, account authentication, replay validation,
and server-side persistence before exposing human matchmaking. The current bot
simulation is not an authoritative competitive server and does not claim to be one.
