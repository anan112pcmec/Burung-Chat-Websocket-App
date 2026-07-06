//// Penyimpanan in-memory untuk data handshake di dalam satu shard.
//// Pakai Dict (bukan List) supaya push/remove/lookup O(1) rata-rata,
//// bukan O(n) kayak list.filter — penting begitu satu shard nampung
//// ribuan/puluhan ribu client. Sebagai bonus, key by client_id juga
//// otomatis nyegah duplicate entry kalau ada double-handshake dari
//// client_id yang sama.

import gleam/dict.{type Dict}
import types.{type ClientId, type HandshakeData}

pub type Storage {
  Storage(clients: Dict(ClientId, HandshakeData))
}

pub fn new() -> Storage {
  Storage(clients: dict.new())
}

/// Push (atau replace kalau client_id sama) data handshake ke storage.
pub fn push(storage: Storage, data: HandshakeData) -> Storage {
  Storage(clients: dict.insert(storage.clients, data.client_id, data))
}

/// Hapus client dari storage berdasarkan client_id. O(1) rata-rata,
/// bukan full scan kayak sebelumnya.
pub fn remove(storage: Storage, client_id: ClientId) -> Storage {
  Storage(clients: dict.delete(storage.clients, client_id))
}

/// Lookup langsung satu client tanpa perlu narik semua isi storage.
pub fn get(storage: Storage, client_id: ClientId) -> Result(HandshakeData, Nil) {
  dict.get(storage.clients, client_id)
}

pub fn count(storage: Storage) -> Int {
  dict.size(storage.clients)
}

pub fn all(storage: Storage) -> List(HandshakeData) {
  dict.values(storage.clients)
}
