//// Wrapper tipis ke primitif native BEAM (lewat burung_ffi.erl).
//// Dipisah ke modul sendiri supaya gampang di-mock/diganti kalau perlu.

/// Hash native Erlang (`:erlang.phash2/2`), jauh lebih cepat & distribusinya
/// jauh lebih merata dibanding hash manual di gleam. Hasilnya sudah dibatasi
/// ke rentang [0, range).
@external(erlang, "burung_ffi", "phash2")
pub fn phash2(term: a, range: Int) -> Int

/// Jumlah scheduler BEAM yang aktif (kira-kira = jumlah core CPU yang
/// dipakai runtime). Dipakai buat nentuin jumlah shard default supaya
/// otomatis nyesuain mesin, gak hardcode angka mati.
@external(erlang, "burung_ffi", "schedulers_online")
pub fn schedulers_online() -> Int

/// Unix timestamp (detik) asli, buat `connected_at`.
@external(erlang, "burung_ffi", "system_time_seconds")
pub fn now_seconds() -> Int
