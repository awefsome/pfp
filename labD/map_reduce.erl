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
    Mapped = map_seq(Map,Input),
    reduce_seq(Reduce,Mapped).

map_seq(Map,Input) ->
    [{K2, V2}
    || {K,V} <- Input,
    {K2,V2} <- Map(K,V)].

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

map_reduce_dist_wp(Map,M,Reduce,R,Input) ->
    Nodes = nodes(),
    NumNodes = length(Nodes),
    Splits = split_into(M, Input),
    Splits.





map_reduce_dist_par(Map,M,Reduce,R,Input) ->
    Nodes = nodes() ,
    NumNodes = length(Nodes),
    Splits = split_into(NumNodes, Input),
    ChunksPerNode = M div NumNodes,
    Mappeds =
    lists:append([rpc:call(Node, map_reduce, map_par, [Map,ChunksPerNode,R,Split])
     || {Node, Split} <- lists:zip(Nodes,Splits)]),
    Reduceds =
    [ rpc:call( Node
                , map_reduce
                , reduce_par
                , [ Reduce
                  , I * ChunksPerNode
                  , (I+1) * ChunksPerNode
                  , Mappeds
                  ]
                )
        || {Node, I} <- lists:zip(Nodes, lists:seq(0,NumNodes-1))],
    lists:sort(lists:flatten(Reduceds)).

map_par(Map,M,R,Input) ->
    Parent = self(),
    Splits = split_into(M, Input),
    Mappers =
	[spawn_mapper(Parent,Map,R,Split)
	 || Split <- Splits],
	[receive {Pid,L} -> L end || Pid <- Mappers].

reduce_par(Reduce,LR,UR,Mappeds) ->
    Parent = self(),
    Indexes = lists:seq(LR,UR-1),
    Reducers =
	[spawn_reducer(Parent,Reduce,I,Mappeds)
	 || I <- Indexes],
	[receive {Pid,L} -> L end || Pid <- Reducers].

map_reduce_par(Map,M,Reduce,R,Input) ->
    Mappeds = map_par(Map,M,R,Input),
    Reduceds = reduce_par(Reduce,0,R,Mappeds),
    lists:sort(lists:flatten(Reduceds)).

spawn_mapper(Parent,Map,R,Split) ->
    spawn_link(fun() ->
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
    Inputs = [KV
	      || Mapped <- Mappeds,
		 {J,KVs} <- Mapped,
		 I==J,
		 KV <- KVs],
    spawn_link(fun() ->
        Parent ! {self(),reduce_seq(Reduce,Inputs)}
    end).
