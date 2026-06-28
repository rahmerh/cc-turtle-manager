# Turtle manager

Computer craft turtle manager. Async, role based and distributed. Designed for efficiency and to be managed remotely.

## Getting started

All roles depend on GPS, make sure you have a working GPS setup running.

First get the bootstrap script onto the turtle or computer:

```sh
wget https://raw.githubusercontent.com/rahmerh/cc-turtle-manager/refs/heads/main/bootstrap.lua
```

Next bootstrap the turtle/computer, you can select from the following roles:

- Manager `bootstrap manager`
- Quarry `bootstrap quarry`
- Runner `bootstrap runner`

Below describes how to quickly get up and running, in depth documentation can be found in `docs/`.

## Roles

### Manager

This is the central computer and should always be running, 
if a turtle can't find the manager (either not running or not chunk loaded) it won't be able to start up.

It is responsible for receiving heartbeats/metadata from all turtles. Also receives and distributes tasks.

If you want to see the current turtles, attach a monitor (minimum 2x2).

### Quarry

Turtle which will quarry an area all the way down from the starting position down to bedrock.

To start simply run `prepare` and input the coordinates to start from and the dimensions of the quarry. 
When done, reboot the turtle and it'll request it's initial supplies and head off to the location.

The quarry turtle requires a pickaxe and modem.

### Runner

A runner is a very general helper role which assists others. It can do the following jobs:

- `pickup` picks up a chest located at the received coordinates.
- `resupply` receives a list of required items, retrieves them and brings them to the requesting turtle.

To start run `prepare` and input the coordinates of the supply and unloading chest. When done just reboot.

The supply chest should always contain coal and chests, at the moment it's up to you to ensure these are always there.
Recommended to use an AE2 interface with these items.

The unloading chest is where it dumps all the items from pick jobs, at the moment it's up to you to ensure it gets emptied automatically.
Recommended to use AE2 and simply import all items from this chest.

The quarry turtle requires a pickaxe and modem.

## TODO

- Dashboard
  - Edit quarry settings page.
  - Error pages
    - General errors.
    - Monitor too small.
    - Multiple managers.
- Better fail state handling
  - Notifications to manager dashboard
  - Runners wait for resupply materials
- Turtles redistribute tasks.
- Continue quarry while waiting for supplies.
- Improve unstuck methods + report turtle is stuck on the dashboard.
- Turtle waiting bay + shared unloading/supply stations.
- Different fuel types support
- More roles:
  - Logger (tree farm)
  - Farmer (generic crop farmer)

## Development

To work around the github cache there's a script to set up a turtle locally.
Simply provide the role and computer id and it'll symlink in all required lua files.
Minecraft disallows symlinks in world folders so you'll have to allow it (Replace placeholder with full, absolute path):
`printf '[prefix]<PATH_TO_REPO>/cc-turtle-manager/' > ~/.minecraft/allowed_symlinks.txt`
