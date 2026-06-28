# Quarry

A quarry turtle which will dig an area from the starting location all the way down to bedrock.

A quarry always needs coal in slot 1 and chests in slot 2 of it's inventory. If it runs out it'll request a resupply at the manager.

## Resupply

When low/out of chests or coal it'll stop and request supplies at the manager.
It will then way for an hour until it gets it's resupply from a runner. Will exit out if none arrived.

## Unloading

Instead of moving all the way to the top of the quarry and dropping it's inventory in a dropoff chest
a quarry turtle will drop it's inventory in a chest at it's current location and send a pickup request to a manager.
It'll then continue mining to minimize downtime.
The manager will then send a runner turtle to pick it up.
