//// Entry point aplikasi. Menyalakan shard & (nantinya) server HTTP/WS.
//// NOTE: starter project — belum fully wired ke library HTTP/WS asli (mist/glisten).
//// Silakan sesuaikan dengan library pilihan kamu.

import gleam/io
import shard/manager
import websocket/client
import websocket/handshake.{IncomingHandshake}

pub fn main() {
  io.println("🐦 burung-chat-app-ws starting...")

  // 1. Nyalakan semua shard di awal, simpan registry-nya.
  let registry = manager.start_all()

  // 2. TODO: nyalakan HTTP/WS server (mist.serve / glisten.serve) di sini.
  //    Di dalam handler upgrade websocket, jalankan alur berikut:
  //
  //    Connect
  //      -> WebSocket Handshake (baca packet awal, misal JSON {username, token})
  //      -> client.on_connect(registry, client_id, IncomingHandshake(username, token))
  //           -> True  -> lanjut terima frame -> client.on_message(client_id, frame)
  //           -> False -> tutup koneksi
  //
  //    Saat koneksi tertutup -> client.on_close(registry, client_id, shard_id)

  simulate_flow(registry)
}

/// Simulasi alur handshake -> shard, tanpa server sungguhan.
/// Berguna buat ngetes struktur project ini sebelum di-wire ke server asli.
fn simulate_flow(registry: manager.Registry) -> Nil {
  let accepted =
    client.on_connect(
      registry,
      "client-123",
      IncomingHandshake(username: "budi", token: "abc123"),
    )

  case accepted {
    True -> io.println("✅ handshake sukses, client masuk ke shard array")
    False -> io.println("❌ handshake ditolak")
  }
}
