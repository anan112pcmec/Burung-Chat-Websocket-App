//// Lifecycle handler untuk tiap koneksi websocket individual.
//// Flow: on_connect (handshake) -> jika diterima -> push ke shard -> loop terima packet.

import gleam/erlang/process
import gleam/io
import shard/manager.{type Registry}
import types.{HandshakeAccepted, HandshakeRejected}
import util/native
import websocket/handshake.{type IncomingHandshake}
import websocket/protocol

/// Dipanggil saat koneksi baru masuk & client mengirim handshake pertamanya.
/// Return: True kalau berhasil (diterima & sudah masuk shard array),
///         False kalau ditolak (server harus tutup koneksi).
pub fn on_connect(
  registry: Registry,
  client_id: String,
  incoming: IncomingHandshake,
) -> Bool {
  let subject = process.new_subject()
  let now = native.now_seconds()

  case handshake.validate(incoming, client_id, subject, now) {
    HandshakeAccepted(data) -> {
      // Handshake diterima -> return berhasil -> taruh data ke shard array
      manager.register(registry, data)
      io.println("[client] handshake accepted: " <> client_id)
      True
    }
    HandshakeRejected(reason) -> {
      io.println("[client] handshake rejected (" <> reason <> "): " <> client_id)
      False
    }
  }
}

/// Dipanggil setiap kali ada frame masuk dari client yang sudah terkoneksi.
/// TODO: kirim balasan (Pong, dsb) ke client lewat subject-nya di
/// shard/manager, saat ini baru di-log. Ini di luar scope "parsing JSON",
/// jangan lupa disambung pas wiring mist beneran.
pub fn on_message(client_id: String, raw: String) -> Nil {
  case protocol.decode(raw) {
    protocol.PacketMessage(text) -> {
      io.println("[client] pesan dari " <> client_id <> ": " <> text)
      Nil
    }
    protocol.PacketPing -> {
      io.println("[client] ping dari " <> client_id <> ", harusnya balas pong")
      Nil
    }
    protocol.PacketPong -> {
      io.println("[client] pong dari " <> client_id)
      Nil
    }
    protocol.PacketHandshake(..) -> {
      // Handshake kedua/susulan setelah koneksi diterima, biasanya invalid
      // di titik ini (handshake cuma sekali di awal via on_connect).
      io.println("[client] handshake susulan dari " <> client_id <> ", diabaikan")
      Nil
    }
    protocol.PacketUnknown(raw_type) -> {
      io.println("[client] tipe pesan tidak dikenal (" <> raw_type <> ") dari " <> client_id)
      Nil
    }
    protocol.PacketInvalid(reason) -> {
      io.println("[client] JSON tidak valid dari " <> client_id <> ": " <> reason)
      Nil
    }
  }
}

/// Dipanggil saat koneksi ditutup (client disconnect / server tutup paksa).
pub fn on_close(registry: Registry, client_id: String, shard_id: Int) -> Nil {
  manager.unregister(registry, client_id, shard_id)
  io.println("[client] disconnected: " <> client_id)
}
