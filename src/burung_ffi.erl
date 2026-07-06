%% FFI kecil buat akses primitif native Erlang/BEAM yang gak ada di
%% gleam_stdlib/gleam_erlang, dipakai untuk optimasi sharding.
-module(burung_ffi).
-export([phash2/2, schedulers_online/0, system_time_seconds/0]).

%% Hash asli Erlang (bukan stub) — jauh lebih cepat & merata dibanding
%% hash manual, dan langsung bisa dibatasi ke [0, range).
phash2(Term, Range) ->
    erlang:phash2(Term, Range).

%% Jumlah scheduler online = jumlah core yang BEAM pakai buat jalanin
%% proses. Dipakai supaya jumlah shard nyesuain mesin (bukan angka mati).
schedulers_online() ->
    erlang:system_info(schedulers_online).

%% Timestamp asli (detik, wall clock) buat connected_at.
system_time_seconds() ->
    erlang:system_time(second).
