# Runner

A versatile turtle which does a bunch of misc tasks to support other, active turtles.

## Pickup

A pickup request is simple, the manager will dispatch a job which says "pick up this at these coordinates".
The runner will then move to the coordinates and mine the object. It then moves back and unloads it's inventory into the unloading chest.

## Resupply

A resupply is slightly more complicated, when another turtle requests a resupply it'll wait for a runner to arrive with the requested supplies.

