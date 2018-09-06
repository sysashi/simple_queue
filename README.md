# Simple Queue

## Requirements

* Elixir >= 1.7
* OTP >= 21.0

## Configuration

You can configure path for the mnesia database at `config/config.exs`, default
path is `'.mnesia/#{Mix.env}/#{node()}'`

There are two options how messages will be handled when you `ack` them:
    1. `delete` - deletes message from the store
    2. `mark` - marks messages with provided status

To configure this behaviour simply add

```
config :simple_queue, :queue,
  mark_completed: true,
  mark_with: :completed
```

Queue also supports different store which implements `SQ.Store` behaviour

```
config :simple_queue, :queue,
  store: MyStore
```

_Default store is **mnesia**_

## Building

    1. Clone the project, `git clone $url`
    2. Inside project's root run `mix do deps.get, compile`
    3. Create mnesia database `mix amnesia.create -d SQ.Mnesia.Database --disk`
       (otherwise messages will be stored in memory)

## Tests

To run tests, simply execute `mix test` from the root of the projects

## Overview

__Queue__ is a process which you can put under your supervision tree, e.g.

```
    Supervisor.start_link(
      [
        {SQ.Queue, [name: MyQueue]}
      ],
      strategy: :one_for_one,
      name: MyApp.Supervisor
    )
```

or use with something like __DynamicSupervisor__

Store should support atomic and isolated transactions. (default store, mnesia, does) 
to avoid race conditions.

Using single process for queue is not a great idea, in our case GenServer does
not support backpressure (it does in theory, and that is processes mailbox), so
realistically one would implement an interface similar to [poolboy](https://github.com/devinus/poolboy),
distributing load across multiple processes (queues)

## Running

There is a simple interface `SQ` to test program in the iex.

After you have created the database, execute `iex -S mix run` to get into the repl.

```
iex> SQ.create! # creates a single named queue process
```
Available commands: 

    * `iex> SQ.add(message) # => :ok` 
    * `iex> SQ.get() # => {message_id, message} | :empty`, 
    * `iex> SQ.ack(message_id) # => :ok | {:error, :not_found}`
    * `iex> SQ.reject(message_id) # => :ok | {:error, :not_found}`

Messages that have not been acknowledged will persists across node and process restarts

Rejected messages will be inserted at the rear of the queue and in the store again, given new id.

