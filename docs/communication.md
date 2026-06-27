# Communication

## Protocols

When using rednet to send/receive messages, all turtles enforce a protocol to make listening to certain messages more explicit.

The following protocols are used:

- `telemetry` used for heartbeat messages.
- `registry` used when a turtle registers itself with a manager.
- `settings` used to set settings on turtles.
- `job` used to update job status at the manager, used to notify a job is completed, for instance.
- `pickup` used to send messages regarding pickup jobs, including assigning and accepting jobs.
- `resupply` used to send messages regarding resupply jobs, including assigning, accepting, and "handshake" messages when a runner tries to resupply.
- `turtle_commands` used for meta commands to control a turtle remotely. For example a pause or kill command.

An operation is giving to indicate what the message is about, for a pickup request this is `pickup:request`.

## Operations

You can consider an operation a sub type of a protocol. 
Each operation should be prefixed with the protocol and end with the operation type, for example `pickup:request` requests a pickup at the manager.

## Receiving messages

When receiving messages you'll have to create a `router`, 
a router is responsible for receiving and routing messages to handlers.

In the main loop of the turtle, the router's loop should also be ran.

You can register a handler on the router by giving a protocol to listen to and an operation to filter on.
The callback you provide is the action that's invoked for every message received that matches the operation.
