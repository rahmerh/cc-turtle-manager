# Turtle manager

Collection of my own scripts for working with CC: Tweaked's turtles. Includes generic pathfinding, dashboards, the works.

## Getting started

All roles depend on GPS, make sure you have working GPS setup configured.

First get the bootstrap script onto the turtle or computer:

```sh
wget https://raw.githubusercontent.com/rahmerh/cc-turtle-manager/refs/heads/main/bootstrap.lua
```

Next bootstrap the turtle/computer, you can select from the following roles:

- Manager `bootstrap manager`
- Quarry `bootstrap quarry`
- Runner `bootstrap runner`

## Usage

### Manager

This is the central computer and should always be running. After bootstrap simply reboot, it'll configure itself.

If you want to see the current turtles, attach a monitor (minimum 2x2).

### Quarry

First you have to prepare the job by running `prepare` and entering the quarry dimensions.

This will create a file called `job.conf` which contains the quarry's boundaries and progress. 
This file shouldn't be edited manually, it allows the turtle to keep track of it's own progress.

### Runner

A runner is a very general helper role which assists others. It can do the following jobs:

- `pickup` picks up a chest located at the received coordinates. Will pick it up and unload at configured "unloading" chest.
- `resupply` receives a list of required items, retrieves them and brings them to the requesting turtle.

It has 2 chests that are important, the unloading and resupply chest. 
The unloading chest is where it dumps it's items and the resupply chest is where it gets it's supplies.

Due to turtle limitations, it can't directly suck up a specified item from a chest
which is why it requires an additional "buffer" chest on top. 
This means the resupply chest's setup should look like this:

```
[buffer chest]
[air]
[supply chest]
```

The turtles only request coal, chests and cobblestone, 
so make sure to always have these supplies in your supply chest. 
Personal recommendation is to either have an AE2 interface which always has 64 coal and chests or use another mod to always have those items in the supply chest.

A runner will always pause on top of the unloading chest, waiting for it's next command. So make sure each runner has it's own unloading chest.

## TODO

- Dashboard
  - Edit quarry settings page.
  - Map/radar page.
- Retry failed tasks (both from turtles and manager).
- Turtles redistribute tasks.
- Continue quarry while waiting for supplies.
- Improve unstuck methods + report turtle is stuck on the dashboard.
- Turtle waiting bay + shared unloading/supply stations.
- Different fuel types support
- Dashboard error screen for:
  - General errors.
  - Monitor too small.
  - Multiple managers.
- More roles:
  - Logger (tree farm)
  - Farmer (generic crop farmer)

## Development

To work around the github cache there's a local setup script set up. 
Simply provide the role and computer id and it'll symlink in all required lua files.
Minecraft disallows symlinks but you can work around this by setting this:
`printf '[prefix]/home/bas/projects/cc-turtle-manager/' > ~/.minecraft/allowed_symlinks.txt`
