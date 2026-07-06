//// Satu shard = satu actor yang memegang sebagian client (dibagi rata oleh manager).
//// Tujuannya supaya broadcast/receive packet tidak bottleneck di satu proses saja.

import gleam/erlang/process.{type Subject}
import gleam/otp/actor
import shard/storage.{type Storage}
import types.{
  type HandshakeData, type ShardMessage, Broadcast, GetClientCount,
  PushHandshake, RemoveClient, Send,
}

pub type State {
  State(id: Int, storage: Storage)
}

fn handle_message(
  state: State,
  message: ShardMessage,
) -> actor.Next(ShardMessage, State) {
  case message {
    PushHandshake(data) -> {
      let new_storage = storage.push(state.storage, data)
      actor.continue(State(..state, storage: new_storage))
    }

    RemoveClient(client_id) -> {
      let new_storage = storage.remove(state.storage, client_id)
      actor.continue(State(..state, storage: new_storage))
    }

    Broadcast(payload) -> {
      broadcast_to(storage.all(state.storage), payload)
      actor.continue(state)
    }

    GetClientCount(reply_to) -> {
      process.send(reply_to, storage.count(state.storage))
      actor.continue(state)
    }
  }
}

fn broadcast_to(clients: List(HandshakeData), payload: String) -> Nil {
  case clients {
    [] -> Nil
    [client, ..rest] -> {
      process.send(client.subject, Send(payload))
      broadcast_to(rest, payload)
    }
  }
}

/// Start satu shard baru dengan id tertentu.
pub fn start(id: Int) -> Result(Subject(ShardMessage), actor.StartError) {
  actor.start(State(id: id, storage: storage.new()), handle_message)
}
