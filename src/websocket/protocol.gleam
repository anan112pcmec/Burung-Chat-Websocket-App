//// Protokol pesan websocket, format JSON.
////
//// Skema wire (satu object per frame, field "type" wajib ada):
////   {"type": "handshake", "username": "...", "token": "..."}
////   {"type": "message", "text": "..."}
////   {"type": "ping"}
////   {"type": "pong"}
////
//// Frame yang "type"-nya tidak dikenal -> PacketUnknown (bukan error keras,
//// biar server bisa pilih mau di-drop atau di-log).
//// Frame yang bukan JSON valid / field wajib hilang -> PacketInvalid, ini
//// HARUS ditangani beda dari PacketUnknown oleh caller (client.gleam),
//// karena artinya client kirim data korup/salah format, bukan cuma jenis
//// pesan baru yang belum didukung.
////
//// CATATAN: ditulis berdasar API gleam_json + gleam/dynamic/decode yang
//// saya tahu (decode.field, decode.string, decode.success, decode.failure).
//// Saya TIDAK bisa compile-test (sandbox gak ada toolchain Gleam/akses
//// hex.pm). Kalau versi gleam_json/gleam_stdlib kamu beda dan API decode-nya
//// berubah, sesuaikan bagian packet_decoder() di bawah — cek dengan
//// `gleam docs build`.

import gleam/dynamic/decode
import gleam/json

pub type Packet {
  PacketHandshake(username: String, token: String)
  PacketMessage(text: String)
  PacketPing
  PacketPong
  PacketUnknown(raw_type: String)
  PacketInvalid(reason: String)
}

/// Decoder untuk body JSON, di-dispatch berdasar field "type".
fn packet_decoder() -> decode.Decoder(Packet) {
  use type_ <- decode.field("type", decode.string)
  case type_ {
    "handshake" -> {
      use username <- decode.field("username", decode.string)
      use token <- decode.field("token", decode.string)
      decode.success(PacketHandshake(username: username, token: token))
    }
    "message" -> {
      use text <- decode.field("text", decode.string)
      decode.success(PacketMessage(text: text))
    }
    "ping" -> decode.success(PacketPing)
    "pong" -> decode.success(PacketPong)
    other -> decode.success(PacketUnknown(raw_type: other))
  }
}

/// Decode raw text frame (JSON) menjadi Packet.
/// Gak pernah panic: JSON rusak atau field wajib hilang -> PacketInvalid.
pub fn decode(raw: String) -> Packet {
  case json.parse(raw, packet_decoder()) {
    Ok(packet) -> packet
    Error(_) -> PacketInvalid(reason: "malformed_json_or_missing_field")
  }
}

/// Encode Packet menjadi JSON string untuk dikirim ke client.
pub fn encode(packet: Packet) -> String {
  let body = case packet {
    PacketHandshake(username, token) ->
      json.object([
        #("type", json.string("handshake")),
        #("username", json.string(username)),
        #("token", json.string(token)),
      ])
    PacketMessage(text) ->
      json.object([
        #("type", json.string("message")),
        #("text", json.string(text)),
      ])
    PacketPing -> json.object([#("type", json.string("ping"))])
    PacketPong -> json.object([#("type", json.string("pong"))])
    PacketUnknown(raw_type) ->
      json.object([
        #("type", json.string("unknown")),
        #("raw_type", json.string(raw_type)),
      ])
    PacketInvalid(reason) ->
      json.object([
        #("type", json.string("error")),
        #("reason", json.string(reason)),
      ])
  }
  json.to_string(body)
}
