//// Modul untuk validasi & pembuatan handshake websocket.

import gleam/erlang/process.{type Subject}
import types.{
  type ClientMessage, HandshakeAccepted, HandshakeData, HandshakeRejected,
}

/// Data mentah yang dikirim client saat awal konek (sebelum divalidasi).
pub type IncomingHandshake {
  IncomingHandshake(username: String, token: String)
}

/// TODO: ganti dengan validasi asli (JWT, session db, dll).
fn is_token_valid(token: String) -> Bool {
  token != ""
}

/// Validasi handshake dari client.
/// Kalau diterima -> return HandshakeAccepted beserta struct data-nya.
/// Kalau ditolak -> return HandshakeRejected beserta alasan.
pub fn validate(
  incoming: IncomingHandshake,
  client_id: String,
  subject: Subject(ClientMessage),
  now: Int,
) -> types.HandshakeResult {
  case is_token_valid(incoming.token) {
    True ->
      HandshakeAccepted(HandshakeData(
        client_id: client_id,
        username: incoming.username,
        token: incoming.token,
        connected_at: now,
        subject: subject,
      ))
    False -> HandshakeRejected(reason: "invalid_token")
  }
}
