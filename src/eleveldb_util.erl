%% yaoxinming@gmail.com
%%
%% iterate db count record
%%
-module(eleveldb_util).
-export([itera_end/2,zxid_fold/5]).
-include("zabe_main.hrl").



zxid_fold(Ref,Fun,Acc,Start,Prefix)->

    Key=zabe_util:encode_key(zabe_util:encode_zxid(Start),Prefix),
    fold(Ref,
	      Fun,Acc,[],Prefix,list_to_binary(Key),itera_end).



fold(Ref, Fun, Acc0, Opts,Prefix,Key,EndFun) ->
    {ok, Itr} = eleveldb:iterator(Ref, Opts),
    do_fold(Itr, Fun, Acc0, Opts,Prefix,Key,EndFun).

do_fold(Itr, Fun, Acc0, _Opts,Prefix,Key,EndFun) ->
    try
        %% Extract {first_key, binary()} and seek to that key as a starting
        %% point for the iteration. The folding function should use throw if it
        %% wishes to terminate before the end of the fold.

        fold_loop(eleveldb:iterator_move(Itr,Key), Itr, Fun, Acc0,Prefix,EndFun)
    after
        eleveldb:iterator_close(Itr)
    end.

fold_loop({error, invalid_iterator}, _Itr, _Fun, Acc0,_Prefix,_EndFun) ->
    Acc0;
fold_loop({ok, _K, _V}, _Itr,_Fun, Acc0={_,0},_Prefix,_EndFun) ->
    Acc0;
fold_loop({ok, K, V}, Itr, Fun, Acc0,Prefix,EndFun) ->
    case apply(?MODULE,EndFun,[K,Prefix]) of
	false->
	    Acc0;
	true->
	    K1=zabe_util:decode_zxid(zabe_util:decode_key(binary_to_list(K),Prefix)),
	    Acc = Fun({K1, binary_to_term(V)},Acc0),
	   % io:format("~p ~p ~n",[K1,Acc]),
	    fold_loop(eleveldb:iterator_move(Itr, next), Itr, Fun, Acc,Prefix,EndFun)
    end.

itera_end(K,Prefix)->
    K1=binary_to_list(K),
    P=zabe_util:prefix_match(K1,Prefix),
    Len=length(K1)-length(Prefix),
    (P andalso Len==30) %todo fix magic number
        .
	

 
    
