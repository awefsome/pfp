
-module(crawler).
-compile(export_all).

crawler() ->
    Data = crawl:crawl('http://chalmers.se/', 3),
    case dets:open_file('web.dat') of
        {ok, Ref} ->
            Ref:insert()
        {error, Reaseon} ->

    end.
