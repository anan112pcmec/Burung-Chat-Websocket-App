//// Mengatur banyak shard (array of shards) & mendistribusikan client ke shard.
//// TODO: registry di bawah ini idealnya disimpan secara global (mis. via
//// gleam/erlang/process.register, persistent_term, atau OTP supervisor),
//// bukan cuma dikembalikan sebagai value biasa seperti di starter ini.

import gleam/erlang/process.{type Subject}
import gleam/list
import shard/shard
import types.{type HandshakeData, type ShardMessage, Broadcast}
import util/native

pub type Registry {
  Registry(shards: List(Subject(ShardMessage)), total: Int)
}

/// Panggil sekali saat startup untuk membuat semua shard.
/// Jumlah shard default = jumlah scheduler BEAM yang aktif (~jumlah core),
/// supaya otomatis nyesuain mesin yang jalanin, bukan angka mati kayak
/// sebelumnya (hardcode 8). Kalau mau paksa jumlah tertentu (mis. buat
/// testing), pakai `start_with/1`.
pub fn start_all() -> Registry {
  start_with(native.schedulers_online())
}

/// Sama seperti `start_all`, tapi jumlah shard ditentukan manual.
pub fn start_with(total_shards: Int) -> Registry {
  let total = case total_shards {
    n if n > 0 -> n
    _ -> 1
  }
  let shards =
    list.range(0, total - 1)
    |> list.map(fn(id) {
      case shard.start(id) {
        Ok(subject) -> subject
        Error(_) -> panic as "gagal start shard"
      }
    })
  Registry(shards: shards, total: total)
}

/// Tentukan shard tujuan pakai hash native Erlang (`:erlang.phash2/2`).
/// Ini FIX dari bug sebelumnya: `simple_hash` versi lama (pakai
/// `pop_grapheme` stub) selalu balikin nilai yang sama buat semua
/// client_id non-empty, jadi SEMUA client jatuh ke shard yang sama —
/// sharding-nya gak jalan sama sekali walau actor-nya udah dibikin
/// terpisah. `phash2` native jauh lebih cepat (dieksekusi di level BEAM,
/// bukan rekursi Gleam) dan distribusinya merata ke semua shard.
pub fn shard_index_for(client_id: String, total: Int) -> Int {
  native.phash2(client_id, total)
}

/// Push handshake data ke shard yang sesuai di dalam registry.
pub fn register(registry: Registry, data: HandshakeData) -> Nil {
  let idx = shard_index_for(data.client_id, registry.total)
  case list_at(registry.shards, idx) {
    Ok(shard_subject) -> process.send(shard_subject, types.PushHandshake(data))
    Error(_) -> Nil
  }
}

/// Hapus client dari shard tertentu (berdasarkan index shard).
pub fn unregister(registry: Registry, client_id: String, shard_id: Int) -> Nil {
  case list_at(registry.shards, shard_id) {
    Ok(shard_subject) ->
      process.send(shard_subject, types.RemoveClient(client_id))
    Error(_) -> Nil
  }
}

/// Broadcast payload ke semua shard (yang nanti diteruskan ke semua client).
pub fn broadcast_all(registry: Registry, payload: String) -> Nil {
  list.each(registry.shards, fn(s) { process.send(s, Broadcast(payload)) })
}

fn list_at(items: List(a), index: Int) -> Result(a, Nil) {
  case items, index {
    [item, ..], 0 -> Ok(item)
    [_, ..rest], i if i > 0 -> list_at(rest, i - 1)
    _, _ -> Error(Nil)
  }
}
