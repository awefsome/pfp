%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% This is a very simple implementation of map-reduce, in both
%% sequential and parallel versions.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

-module(map_reduce).
-compile(export_all).

%% We begin with a simple sequential implementation, just to define
%% the semantics of map-reduce.

%% The input is a collection of key-value pairs. The map function maps
%% each key value pair to a list of key-value pairs. The reduce
%% function is then applied to each key and list of corresponding
%% values, and generates in turn a list of key-value pairs. These are
%% the result.

map_reduce_seq(Map,Reduce,Input) ->
    Mapped = [{K2,V2}
	      || {K,V} <- Input,
		 {K2,V2} <- Map(K,V)],
    reduce_seq(Reduce,Mapped).

reduce_seq(Reduce,KVs) ->
    [KV || {K,Vs} <- group(lists:sort(KVs)),
	   KV <- Reduce(K,Vs)].

group([]) ->
    [];
group([{K,V}|Rest]) ->
    group(K,[V],Rest).

group(K,Vs,[{K,V}|Rest]) ->
    group(K,[V|Vs],Rest);
group(K,Vs,Rest) ->
    [{K,lists:reverse(Vs)}|group(Rest)].

map_reduce_par(Map,M,Reduce,R,Input) ->
    Parent = self(),
    Splits = split_into(M,Input),
    Mappers =
	[spawn_mapper(Parent,Map,R,Split)
	 || Split <- Splits],
    Mappeds =
	[receive {Pid,L} -> L end || Pid <- Mappers],
    Reducers =
	[spawn_reducer(Parent,Reduce,I,Mappeds)
	 || I <- lists:seq(0,R-1)],
    Reduceds =
	[receive {Pid,L} -> L end || Pid <- Reducers],
    lists:sort(lists:flatten(Reduceds)).

map_reduce_dist_par(Map, M, Reduce, R, Input) ->
    Parent = self(),
    Nodes = [node() | nodes()],
    UseNode = [lists:nth(I rem length(Nodes) + 1, Nodes) || I <- lists:seq(1, M)],
    Splits = split_into(M,Input),
    Mappers =
	[spawn_mapper(Node,Parent,Map,R,Split)
	 || {Node, Split} <- lists:zip(UseNode, Splits)],
    Mappeds =
	[receive {Pid,L} -> L end || Pid <- Mappers],
    Rseq = lists:seq(0,R-1),
    UseNode = [lists:nth((I + 1) rem length(Nodes) + 1, Nodes) || I <- Rseq],
    Reducers =
	[spawn_reducer(Node, Parent,Reduce,I,Mappeds)
	 || {Node,I} <- lists:zip(UseNode, Rseq)],
    Reduceds =
	[receive {Pid,L} -> L end || Pid <- Reducers],
    lists:sort(lists:flatten(Reduceds)).

% Workpool
map_reduce_dist_wp(Map,M,Reduce,R,Input) ->
    Splits = split_into(M, Input),
    MapFuns = [fun() ->
                    Mapped = [{erlang:phash2(K2,R),{K2,V2}}
                                || {K,V} <- Split,
                                    {K2,V2} <- Map(K,V)],
                    group(lists:sort(Mapped))
               end
              || Split <- Splits],
    Mappeds = pool(MapFuns),
    Datas = lists:map(fun(I) -> get_reduce_i(Mappeds, I) end, lists:seq(0, R-1)),
    ReduceFuns = [fun() -> reduce_seq(Reduce,Data) end ||
        Data <- Datas],
    Reduced = pool(ReduceFuns),
    lists:sort(lists:flatten(Reduced)).

% Fault Tolerant
% TODO

pool(Funs) ->
    Parent = self(),
    Nodes = [node() | nodes()],
    Workers = [spawn_link(Node, map_reduce, workers, [Parent]) || Node <- Nodes],
    FunsMap = lists:zip(lists:seq(1, length(Funs)), Funs),
    pool(maps:new(), length(FunsMap), FunsMap, Workers).

pool(Results, 0, [], Workers) ->
    maps:values(Results);

pool(Results, Pending, Todo, Workers) ->
    receive
        {request, Pid} ->
            case Todo of
                [] -> Pid ! exit,
                    pool(Results, Pending, Todo, Workers);
                [Job | Jobs] -> Pid ! {work, Job},
                    pool(Results, Pending, Jobs ++ [Job], Workers)
            end;
        {done, Id, Res} ->
            case maps:is_key(Id, Results) of
                true -> pool(Results, Pending, Todo, Workers);
                false ->
                    %pool(maps:put(Id, Res, Results), Pending - 1, Todo, Workers)
                    case lists:keytake(Id, 1, Todo) of
                        {value, _, Jobs} ->
                            pool(maps:put(Id, Res, Results), Pending - 1, Jobs, Workers);
                        false ->
                            pool(Results, Pending, Todo, Workers)
                    end
            end
    end.

workers(Relay) ->
    Workers = [spawn_link(map_reduce, worker, [Relay]) || _ <- lists:seq(0, 7)],
    receive
        exit -> [Worker ! exit || Worker <- Workers]
    end.

worker(Relay) ->
    Relay ! {request, self()},
    receive
        {work, {Id,Fun}} ->
            Relay ! {done, Id, Fun()},
            worker(Relay);
        exit -> []
    end.

get_reduce_i(Mappeds, I) ->
    [KV ||
        Mapped <- Mappeds,
		{J,KVs} <- Mapped,
		I == J,
		KV <- KVs].

spawn_mapper(Parent,Map,R,Split) ->
    spawn_mapper(node(), Parent, Map, R, Split).

spawn_mapper(Node, Parent, Map, R, Split) ->
    spawn_link(Node, fun() ->
			Mapped = [{erlang:phash2(K2,R),{K2,V2}}
				  || {K,V} <- Split,
				     {K2,V2} <- Map(K,V)],
			Parent ! {self(),group(lists:sort(Mapped))}
		end).

split_into(N,L) ->
    split_into(N,L,length(L)).

split_into(1,L,_) ->
    [L];
split_into(N,L,Len) ->
    {Pre,Suf} = lists:split(Len div N,L),
    [Pre|split_into(N-1,Suf,Len-(Len div N))].

spawn_reducer(Parent,Reduce,I,Mappeds) ->
    spawn_reducer(node(), Parent, Reduce, I, Mappeds).

spawn_reducer(Node, Parent, Reduce, I, Mappeds) ->
    Inputs = [KV
	      || Mapped <- Mappeds,
		 {J,KVs} <- Mapped,
		 I==J,
		 KV <- KVs],
    spawn_link(Node, fun() -> Parent ! {self(),reduce_seq(Reduce,Inputs)} end).
