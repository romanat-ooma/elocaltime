%% Enumerate the same OS TZif files used by CCTZ, including IANA aliases.
-module(elocaltime_zoneinfo).
-include_lib("kernel/include/file.hrl").
-export([timezones/0]).

-spec timezones() -> {ok, [binary()]} | {error, term()}.
timezones() ->
    Directory = case os:getenv("TZDIR") of
        false -> "/usr/share/zoneinfo";
        "" -> "/usr/share/zoneinfo";
        Value -> Value
    end,
    case file:list_dir(Directory) of
        {ok, Files} -> {ok, lists:usort(walk(Directory, "", Files))};
        Error -> Error
    end.

walk(_Directory, _Prefix, []) -> [];
walk(Directory, Prefix, [File | Rest]) ->
    Name = case Prefix of "" -> File; _ -> Prefix ++ "/" ++ File end,
    Path = filename:join(Directory, File),
    Here = case Name of
        "posix" -> [];
        "right" -> [];
        "localtime" -> [];
        "posixrules" -> [];
        _ -> entry(Path, Name)
    end,
    Here ++ walk(Directory, Prefix, Rest).

entry(Path, Name) ->
    case file:read_link_info(Path) of
        {ok, #file_info{type = directory}} ->
            case file:list_dir(Path) of
                {ok, Files} -> walk(Path, Name, Files);
                _ -> []
            end;
        {ok, #file_info{type = Type}} when Type =:= regular; Type =:= symlink ->
            %% Do not follow directory symlinks (some OS trees link back to
            %% their root). File aliases are retained after checking TZif magic.
            case filelib:is_dir(Path) of
                true -> [];
                false -> tzif(Path, Name)
            end;
        _ -> []
    end.

tzif(Path, Name) ->
    case file:open(Path, [read, binary, raw]) of
        {ok, File} ->
            Result = file:read(File, 4),
            ok = file:close(File),
            case Result of
                {ok, <<"TZif">>} -> [list_to_binary(Name)];
                _ -> []
            end;
        _ -> []
    end.
