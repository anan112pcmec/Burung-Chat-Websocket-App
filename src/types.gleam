//// Shared types dipakai di seluruh project.

import gleam/erlang/process.{type Subject}

/// ID unik untuk setiap client yang terkoneksi.
pub type ClientId =
  String

/// ID unik untuk setiap shard.
pub type ShardId =
  Int

/// Data hasil handshake yang akan disimpan ke dalam shard array.
pub type HandshakeData {
  HandshakeData(
    client_id: ClientId,
    username: String,
    token: String,
    connected_at: Int,
    subject: Subject(ClientMessage),
  )
}

/// Pesan yang dikirim ke actor client (mailbox tiap koneksi).
pub type ClientMessage {
  Send(payload: String)
  Close
}

/// Hasil dari proses handshake.
pub type HandshakeResult {
  HandshakeAccepted(data: HandshakeData)
  HandshakeRejected(reason: String)
}

/// Pesan yang dikirim ke shard actor.
pub type ShardMessage {
  PushHandshake(data: HandshakeData)
  RemoveClient(client_id: ClientId)
  Broadcast(payload: String)
  GetClientCount(reply_to: Subject(Int))
}

/// Pesan untuk shard manager (mengatur banyak shard).
pub type ManagerMessage {
  RegisterClient(data: HandshakeData)
  UnregisterClient(client_id: ClientId, shard_id: ShardId)
  BroadcastAll(payload: String)
}
