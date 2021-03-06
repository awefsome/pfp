-module(sudoku).
%-include_lib("eqc/include/eqc.hrl").
-compile(export_all).

%% %% generators

%% matrix(M,N) ->
%%     vector(M,vector(N,nat())).

%% matrix transpose

transpose([Row]) ->
    [[X] || X <- Row];
transpose([Row|M]) ->
    [[X|Xs] || {X,Xs} <- lists:zip(Row,transpose(M))].

%% prop_transpose() ->
%%     ?FORALL({M,N},{nat(),nat()},
%% 	    ?FORALL(Mat,matrix(M+1,N+1),
%% 		    transpose(transpose(Mat)) == Mat)).

%% map a matrix to a list of 3x3 blocks, each represented by the list
%% of elements in row order

triples([A,B,C|D]) ->
    [[A,B,C]|triples(D)];
triples([]) ->
    [].

blocks(M) ->
    Blocks = [triples(X) || X <- transpose([triples(Row) || Row <- M])],
    lists:append(
      lists:map(fun(X)->
			lists:map(fun lists:append/1, X)
		end,
		Blocks)).

unblocks(M) ->
    lists:map(
      fun lists:append/1,
      transpose(
	lists:map(
	  fun lists:append/1,
	  lists:map(
	    fun(X)->lists:map(fun triples/1,X) end,
	    triples(M))))).

%% prop_blocks() ->
%%     ?FORALL(M,matrix(9,9),
%% 	    unblocks(blocks(M)) == M).

%% decide whether a position is safe

entries(Row) ->
    [X || X <- Row,
	  1 =< X andalso X =< 9].

safe_entries(Row) ->
    Entries = entries(Row),
    lists:sort(Entries) == lists:usort(Entries).

safe_rows(M) ->
    lists:all(fun safe_entries/1,M).

safe(M) ->
    safe_rows(M) andalso
	safe_rows(transpose(M)) andalso
	safe_rows(blocks(M)).

%% fill blank entries with a list of all possible values 1..9

fill(M) ->
    Nine = lists:seq(1,9),
    [[if 1=<X, X=<9 ->
	      X;
	 true ->
	      Nine
      end
      || X <- Row]
     || Row <- M].

%% refine entries which are lists by removing numbers they are known
%% not to be

refine(M) ->
    NewM =
	refine_rows(
	  transpose(
	    refine_rows(
	      transpose(
		unblocks(
		  refine_rows(
		    blocks(M))))))),
    if M==NewM ->
	    M;
       true ->
	    refine(NewM)
    end.

refine_rows(M) ->
    lists:map(fun refine_row/1,M).

%%%%%%%%%%%%%%Task 2%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%"
parallel_refine(M) ->
    NewM =
	parallel_refine_rows(
	  transpose(
	    parallel_refine_rows(
	      transpose(
		unblocks(
		  parallel_refine_rows(
		    blocks(M))))))),
    if M==NewM ->
	    M;
       true ->
	    parallel_refine(NewM)
    end.

parallel_refine_rows(M) ->
	Parent = self(),
	Reflist = [{make_ref(), E} || E <- M],
	[spawn_link(fun() -> Parent ! {Ref, catch refine_row(Row)} end) || {Ref, Row} <- Reflist],
	[receive
		{_, {'EXIT', no_solution}} -> 
			exit(no_solution);
		{Ref, Row} -> Row
	end || {Ref, _} <- Reflist].

%%%%%%%%%%%%%%Task 2%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%"

refine_row(Row) ->
    Entries = entries(Row),
    NewRow =
	[if is_list(X) ->
		 case X--Entries of
		     [] ->
			 exit(no_solution);
		     [Y] ->
			 Y;
		     NewX ->
			 NewX
		 end;
	    true ->
		 X
	 end
	 || X <- Row],
    NewEntries = entries(NewRow),
    %% check we didn't create a duplicate entry
    case length(lists:usort(NewEntries)) == length(NewEntries) of
	true ->
	    NewRow;
	false ->
	    exit(no_solution)
    end.

is_exit({'EXIT',_}) ->
    true;
is_exit(_) ->
    false.

%% is a puzzle solved?

solved(M) ->
    lists:all(fun solved_row/1,M).

solved_row(Row) ->
    lists:all(fun(X)-> 1=<X andalso X=<9 end, Row).

%% how hard is the puzzle?

hard(M) ->		      
    lists:sum(
      [lists:sum(
	 [if is_list(X) ->
		  length(X);
	     true ->
		  0
	  end
	  || X <- Row])
       || Row <- M]).

%% choose a position {I,J,Guesses} to guess an element, with the
%% fewest possible choices

guess(M) ->
    Nine = lists:seq(1,9),
    {_,I,J,X} =
	lists:min([{length(X),I,J,X}
		   || {I,Row} <- lists:zip(Nine,M),
		      {J,X} <- lists:zip(Nine,Row),
		      is_list(X)]),
    {I,J,X}.

%% given a matrix, guess an element to form a list of possible
%% extended matrices, easiest problem first.

guesses(M) ->
    {I,J,Guesses} = guess(M),
    Ms = [catch refine(update_element(M,I,J,G)) || G <- Guesses],
    SortedGuesses =
	lists:sort(
	  [{hard(NewM),NewM}
	   || NewM <- Ms,
	      not is_exit(NewM)]),
    [G || {_,G} <- SortedGuesses].


%%%%%%%%%%%%%%%Task 3%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
parallel_guesses(M) ->
	Parent = self(),
    {I,J,Guesses} = guess(M),
    RefList = [{make_ref(), Guess} || Guess <- Guesses],
    [spawn_link(fun() -> Parent ! {Ref, catch refine(update_element(M,I,J,Guess))}  end) || {Ref, Guess} <- RefList],
    Ms = [receive
    	{_, {'Exit', no_solution}} ->
    		exit(no_solution);
    	{Ref, Solution} ->
    		Solution
    	end || {Ref, _} <- RefList],
    SortedGuesses =
	lists:sort(
	  [{hard(NewM),NewM}
	   || NewM <- Ms,
	      not is_exit(NewM)]),
    [G || {_,G} <- SortedGuesses].
%%%%%%%%%%%%%%%Task 3%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

update_element(M,I,J,G) ->
    update_nth(I,update_nth(J,G,lists:nth(I,M)),M).

update_nth(I,X,Xs) ->
    {Pre,[_|Post]} = lists:split(I-1,Xs),
    Pre++[X|Post].

%% prop_update() ->
%%     ?FORALL(L,list(int()),
%% 	    ?IMPLIES(L/=[],
%% 		     ?FORALL(I,choose(1,length(L)),
%% 			     update_nth(I,lists:nth(I,L),L) == L))).

%% solve a puzzle

solve(M) ->
    Filled = refine(fill(M)),
    Pid = self(),
    [W|Ws] = [spawn(fun() -> worker(Pid) end) || _ <- lists:seq(1, erlang:system_info(schedulers)-1)],
    Ref = make_ref(),
    W ! {Filled, Ref},
    receive
      Ref ->
        Solution = pool(Ws, [W|Ws]),
        Solution
    end.

worker(Parent) ->
  receive
    {M, Ref} ->
      Parent ! Ref,

      case catch solve_refined(Parent, M) of
        {'EXIT', no_solution} ->
          Parent ! {done, self()};
        Solution ->
          case valid_solution(Solution) of
            true ->
              Parent ! {solution, Solution};
            false ->
              Parent ! {done, self()}
          end
      end
  end,
  worker(Parent).

solve_refined(Parent, M) ->
    case solved(M) of
    true ->
        M;
    false ->
        solve_one(Parent, guesses(M))
    end.

solve_one(_, []) ->
    exit(no_solution);

solve_one(Parent, [M]) ->
    solve_refined(Parent, M);

solve_one(Parent, [M|Ms]) ->
    Parent ! {speculate, M, self()},
    receive
      {yes} -> solve_one(Parent, Ms);
      {no} ->
        case catch solve_refined(Parent, M) of
        {'EXIT', no_solution} ->
            solve_one(Parent, Ms);
        Solution ->
            Solution
        end
    end.

pool(Available, All) ->
  receive
    {solution, Solution} ->
      [exit(Child, done)|| Child <- All],
      Solution;
    {speculate, M, Brancher} ->
        case Available of
          [] -> Brancher ! {no},
                pool([], All);
          [X|Xs] -> Ref = make_ref(),
                    X ! {M, Ref},
                    receive
                      Ref -> 
                          Brancher ! {yes},
                          pool(Xs, All)
                    after 100 ->
                        Brancher ! {no},
                        pool([], All)
                    end
        end;
    {done, Pid} ->
        case lists:usort([Pid|Available]) == lists:usort(All) of
          true -> exit(workers_done);
          false ->
            pool([Pid|Available], All)
        end
  end.


%% benchmarks

-define(EXECUTIONS,100).

bm(F) ->
    {T,_} = timer:tc(?MODULE,repeat,[F]),
    T/?EXECUTIONS/1000.

repeat(F) ->
    [F() || _ <- lists:seq(1,?EXECUTIONS)].

benchmarks(Puzzles) ->
    [{Name,bm(fun()->solve(M) end)} || {Name,M} <- Puzzles].


%%%%%%%%%Task 1%%%%%%%%%%%%%%%%%%
parallel_benchmarks([{Name, M}|Puzzles]) ->
    Parent = self(),
    Ref = make_ref(),
    spawn_link(fun()->
        Parent ! 
        	{Ref, bm(fun()->solve(M) end)}
    end),
    Bms = parallel_benchmarks(Puzzles),
    receive
        {Ref, Solution} ->
            [{Name, Solution} | Bms]
    end;

parallel_benchmarks([]) ->
    [].

%%%%%%%%%Task 1%%%%%%%%%%%%%%%%%%

benchmarks() ->
  {ok,Puzzles} = file:consult("problems.txt"),
  timer:tc(?MODULE,benchmarks,[Puzzles]).
		      
%% check solutions for validity

valid_rows(M) ->
    lists:all(fun valid_row/1,M).

valid_row(Row) ->
    lists:usort(Row) == lists:seq(1,9).

valid_solution(M) ->
    valid_rows(M) andalso valid_rows(transpose(M)) andalso valid_rows(blocks(M)).


