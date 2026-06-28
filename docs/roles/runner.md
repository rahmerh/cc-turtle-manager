# Runner

A versatile turtle which does a bunch of misc tasks to support other, active turtles.

## Pickup

A pickup request is simple, the manager will dispatch a job which says "pick up this at these coordinates".
The runner will then move to the coordinates and mine the object. It then moves back and unloads it's inventory into the unloading chest.

## Resupply

This job is slightly more complicated, when another turtle requests a resupply it'll wait for a runner to arrive with the requested supplies.
A resupply job usually looks like this:

- A runner turtle receives a message asking for items
- The runner goes to the resupply chest and retrieves items
- It then goes to the location in the job message
- Upon arriving it sends an "arrived" message to the turtle who requested the items
- The requesting turtle clears inventory slots into the runner (if required) and sends "ready"
- The runner then drops the requested items into the requesting turtle and sends "done"
  - The requesting turtle will continue after a "done" message.
- The runner goes back to the unloading chest and drops off any items received (if required)

This "dance" is required since you can't know the state of the inventory of the requesting turtle.
For example if it's a quarry turtle it's possible it filled it's whole inventory before requesting a resupply of new chests.
This is why the requesting turtle has to clear inventory slots to be able to receive the items.

Due to turtle limitations, it is not possible to filter and pull items from another inventory.
We solve this by wrapping both inventories as [peripherals](https://tweaked.cc/generic_peripheral/inventory.html#v:pushItems) and pushing any requested items into the buffer chest.
It is then able to simply pull all these items from the buffer chest into it's own inventory. 
The resupply chest should look like this:

```
[buffer chest]
[air block]
[resupply chest]
```

## Resupply self

Not exactly a task, but when a runner has less than 16 coal in it's inventory it'll resupply itself by the resupply chest.
