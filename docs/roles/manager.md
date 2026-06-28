# Manager

The core computer responsible for distributing tasks to turtles and receiving heartbeats. 
When a monitor is attached, will display an interactive dashboard to view and control turtles.

You cannot run multiple managers, any other manager that starts will fail.

Stores all running turtles in a local turtle store file (`turtle_store.json`). 
When you're migrating managers either copy over this file or just use 1 manager and move it when required.
You're able to remove this file, but then every turtle needs to register again. 
This can easily be done by rebooting the turtle or leaving/entering your world.

## Heartbeat

Each turtle should run a heartbeat loop so the manager knows when a turtle has quit and/or is alive.
Each heartbeat contains information about the turtle, including location, type and more.
This information is then used in the dashboard to display where the turtle is more.

Whenever a turtle doesn't send a heartbeat for 2 seconds it's marked as 'stale'. 
When no heartbeat received for 15 seconds it's marked as 'offline'.

Offline turtles can be recovered by a runner turtle.

## Turtle registering

When a turtle first starts up it registers itself at the manager. 
The manager will then send back `accept` and store the turtle's information in a local json file.

Every heartbeat will update the turtle's metadata in this store.

## Job dispatching

A manager will receive jobs from active turtles. It will then take a look at the turtles in it's store and try to dispatch it.
When it finds multiple runners it'll dispatch the job to the one with the least jobs queued.

If it couldn't dispatch because there are no runners available, it'll maintain a local queue. 
Whenever a runner registers it'll dispatch all queued jobs to this turtle.

## Turtle actions

It's possible some somewhat control a turtle from a distance, you can pause, kill and recover a turtle remotely.
