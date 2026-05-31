DECLARE FUNCTION Q$ (s$)
DECLARE FUNCTION Fit$ (s$, n%)
DECLARE FUNCTION Rep$ (s$, n%)
DECLARE FUNCTION Center$ (s$, w%)
DECLARE FUNCTION ExtractChannel$ (u$)
DECLARE FUNCTION ExtractVideoId$ (u$)
DECLARE FUNCTION NextArg$ (cmd$, p%)
DECLARE FUNCTION ValidId% (id$)
DECLARE FUNCTION ReadExit% (path$)
DECLARE FUNCTION LastErr$ (path$)
DECLARE FUNCTION BgutilAlive%
DECLARE FUNCTION HasMp3% (dir$, id$)

DECLARE SUB SafeKill (path$)
DECLARE SUB RunCmd (cmd$, outFile$, exitFile$)
DECLARE SUB Render (idx%, total%, id$, phase$, ok%, failed%, msg$)
DECLARE SUB AddFail (id$, reason$)

OPTION BASE 1

DIM SHARED failIds$(1 TO 10000)
DIM SHARED failReasons$(1 TO 10000)
DIM SHARED failCount%

DIM ids$(1 TO 10000)

cmdLine$ = COMMAND$
p% = 1
url$ = NextArg$(cmdLine$, p%)
startFromId$ = NextArg$(cmdLine$, p%)

IF LEN(url$) = 0 THEN
    INPUT "URL: ", url$
    INPUT "Start from ID: ", startFromId$
END IF

IF LEN(url$) = 0 THEN
    PRINT "URL missing"
    SYSTEM
END IF

channel$ = ExtractChannel$(url$)

IF LEN(channel$) > 0 THEN
    SHELL "cmd /c if not exist " + Q$(channel$) + " mkdir " + Q$(channel$)
    RunCmd "yt-dlp --flat-playlist --skip-download --print id " + Q$(url$), "_ids.out", "_ids.exit"

    IF ReadExit%("_ids.exit") <> 0 THEN
        PRINT LastErr$("_ids.out")
        SYSTEM
    END IF

    f% = FREEFILE
    OPEN "_ids.out" FOR INPUT AS #f%
    DO WHILE NOT EOF(f%)
        LINE INPUT #f%, id$
        id$ = LTRIM$(RTRIM$(id$))
        IF ValidId%(id$) THEN
            exists% = 0
            FOR i% = 1 TO total%
                IF ids$(i%) = id$ THEN exists% = 1
            NEXT
            IF exists% = 0 THEN
                total% = total% + 1
                ids$(total%) = id$
            END IF
        END IF
    LOOP
    CLOSE #f%
ELSE
    id$ = ExtractVideoId$(url$)
    IF NOT ValidId%(id$) THEN
        PRINT "Invalid URL"
        SYSTEM
    END IF
    total% = 1
    ids$(1) = id$
END IF

IF total% = 0 THEN
    PRINT "No videos found to process."
    SYSTEM
END IF

startOffset% = 1
IF LEN(startFromId$) > 0 THEN
    found% = 0
    FOR i% = 1 TO total%
        IF ids$(i%) = startFromId$ THEN
            startOffset% = i%
            found% = 1
            EXIT FOR
        END IF
    NEXT

    IF found% = 0 THEN
        PRINT "startFromId not found: "; startFromId$
        SYSTEM
    END IF
END IF

IF LEN(channel$) > 0 THEN
    outPath$ = channel$ + "\%(title)s [%(id)s].%(ext)s"
    searchDir$ = channel$
ELSE
    outPath$ = "%(title)s [%(id)s].%(ext)s"
    searchDir$ = "."
END IF

ok% = 0
lastMessage$ = "Waiting..."

Render startOffset%, total%, "", "Initializing", ok%, failCount%, lastMessage$

FOR i% = startOffset% TO total%
    id$ = ids$(i%)
    Render i%, total%, id$, "Downloading", ok%, failCount%, lastMessage$

    yt$ = "yt-dlp -f bestaudio --js-runtimes node --extract-audio --audio-format mp3 --audio-quality 0 --download-archive dwndlist.txt --remote-components ejs:github --print after_move:filepath --no-simulate -o " + Q$(outPath$) + " " + Q$("https://www.youtube.com/watch?v=" + id$)

    RunCmd yt$, "_yt.out", "_yt.exit"
    code% = ReadExit%("_yt.exit")

    IF code% <> 0 AND BgutilAlive% THEN
        Render i%, total%, id$, "Retry bgutil", ok%, failCount%, lastMessage$
        yt2$ = "yt-dlp -f bestaudio --js-runtimes node --extract-audio --audio-format mp3 --audio-quality 0 --download-archive dwndlist.txt --remote-components ejs:github --print after_move:filepath --no-simulate -o " + Q$(outPath$) + " --extractor-args " + Q$("youtube:player_client=default;youtube:po_token=bgutil") + " " + Q$("https://www.youtube.com/watch?v=" + id$)
        RunCmd yt2$, "_yt.out", "_yt.exit"
        code% = ReadExit%("_yt.exit")
    END IF

    IF code% = 0 THEN
        IF HasMp3%(searchDir$, id$) THEN
            ok% = ok% + 1
            lastMessage$ = "OK " + id$
        ELSE
            AddFail id$, "File not found after success"
            lastMessage$ = "MISSING " + id$
        END IF
    ELSE
        AddFail id$, LastErr$("_yt.out")
        lastMessage$ = "FAILED " + id$
    END IF
NEXT

Render total% + 1, total%, "", "Completed", ok%, failCount%, "Done: ok=" + LTRIM$(STR$(ok%)) + " failed=" + LTRIM$(STR$(failCount%))

IF LEN(channel$) > 0 THEN
    failedLog$ = channel$ + "\failed-ids.txt"
ELSE
    failedLog$ = "failed-ids.txt"
END IF

f% = FREEFILE
OPEN failedLog$ FOR OUTPUT AS #f%
FOR i% = 1 TO failCount%
    PRINT #f%, failIds$(i%) + CHR$(9) + failReasons$(i%)
NEXT
CLOSE #f%

PRINT
PRINT "Summary: total="; total%; " processed="; total% - startOffset% + 1; " ok="; ok%; " failed="; failCount%
IF LEN(startFromId$) > 0 THEN PRINT "Started from ID: "; startFromId$
PRINT "Failed IDs file: "; failedLog$

SYSTEM

FUNCTION Q$ (s$)
    Q$ = CHR$(34) + s$ + CHR$(34)
END FUNCTION

FUNCTION Fit$ (s$, n%)
    IF LEN(s$) <= n% THEN
        Fit$ = s$
    ELSEIF n% <= 3 THEN
        Fit$ = LEFT$(s$, n%)
    ELSE
        Fit$ = LEFT$(s$, n% - 3) + "..."
    END IF
END FUNCTION

FUNCTION Rep$ (s$, n%)
    r$ = ""
    FOR i% = 1 TO n%
        r$ = r$ + s$
    NEXT
    Rep$ = r$
END FUNCTION

FUNCTION Center$ (s$, w%)
    pad% = (w% - LEN(s$)) \ 2
    IF pad% < 0 THEN pad% = 0
    Center$ = SPACE$(pad%) + s$
END FUNCTION

FUNCTION ExtractChannel$ (u$)
    p% = INSTR(u$, "youtube.com/@")
    IF p% = 0 THEN
        ExtractChannel$ = ""
        EXIT FUNCTION
    END IF

    s% = p% + LEN("youtube.com/@")
    e% = INSTR(s%, u$, "/")
    IF e% = 0 THEN e% = LEN(u$) + 1
    ExtractChannel$ = MID$(u$, s%, e% - s%)
END FUNCTION

FUNCTION ExtractVideoId$ (u$)
    p% = INSTR(u$, "youtube.com/watch?v=")
    IF p% > 0 THEN
        s% = p% + LEN("youtube.com/watch?v=")
    ELSE
        p% = INSTR(u$, "youtu.be/")
        IF p% = 0 THEN
            ExtractVideoId$ = ""
            EXIT FUNCTION
        END IF
        s% = p% + LEN("youtu.be/")
    END IF

    e1% = INSTR(s%, u$, "&")
    e2% = INSTR(s%, u$, "/")
    e% = LEN(u$) + 1

    IF e1% > 0 AND e1% < e% THEN e% = e1%
    IF e2% > 0 AND e2% < e% THEN e% = e2%

    ExtractVideoId$ = MID$(u$, s%, e% - s%)
END FUNCTION

FUNCTION NextArg$ (cmd$, p%)
    WHILE p% <= LEN(cmd$) AND MID$(cmd$, p%, 1) = " "
        p% = p% + 1
    WEND

    IF p% > LEN(cmd$) THEN
        NextArg$ = ""
        EXIT FUNCTION
    END IF

    IF MID$(cmd$, p%, 1) = CHR$(34) THEN
        p% = p% + 1
        s% = p%
        WHILE p% <= LEN(cmd$) AND MID$(cmd$, p%, 1) <> CHR$(34)
            p% = p% + 1
        WEND
        NextArg$ = MID$(cmd$, s%, p% - s%)
        p% = p% + 1
    ELSE
        s% = p%
        WHILE p% <= LEN(cmd$) AND MID$(cmd$, p%, 1) <> " "
            p% = p% + 1
        WEND
        NextArg$ = MID$(cmd$, s%, p% - s%)
    END IF
END FUNCTION

FUNCTION ValidId% (id$)
    IF LEN(id$) <> 11 THEN
        ValidId% = 0
        EXIT FUNCTION
    END IF

    FOR i% = 1 TO 11
        c$ = MID$(id$, i%, 1)
        ok% = c$ >= "a" AND c$ <= "z" OR c$ >= "A" AND c$ <= "Z" OR c$ >= "0" AND c$ <= "9" OR c$ = "_" OR c$ = "-"
        IF NOT ok% THEN
            ValidId% = 0
            EXIT FUNCTION
        END IF
    NEXT

    ValidId% = 1
END FUNCTION

SUB SafeKill (path$)
    ON ERROR GOTO done
    KILL path$
done:
    ON ERROR GOTO 0
END SUB

SUB RunCmd (cmd$, outFile$, exitFile$)
    bat$ = "_run_" + LTRIM$(STR$(INT(RND * 30000))) + ".bat"

    SafeKill outFile$
    SafeKill exitFile$
    SafeKill bat$

    f% = FREEFILE
    OPEN bat$ FOR OUTPUT AS #f%
    PRINT #f%, "@echo off"
    PRINT #f%, cmd$ + " 1>" + Q$(outFile$) + " 2>&1"
    PRINT #f%, "echo %errorlevel%>" + Q$(exitFile$)
    CLOSE #f%

    SHELL "cmd /c " + Q$(bat$)
    SafeKill bat$
END SUB

FUNCTION ReadExit% (path$)
    ON ERROR GOTO bad
    f% = FREEFILE
    OPEN path$ FOR INPUT AS #f%
    LINE INPUT #f%, s$
    CLOSE #f%
    ReadExit% = VAL(s$)
    EXIT FUNCTION
bad:
    ReadExit% = 1
    ON ERROR GOTO 0
END FUNCTION

FUNCTION LastErr$ (path$)
    ON ERROR GOTO bad
    f% = FREEFILE
    OPEN path$ FOR INPUT AS #f%

    e$ = ""
    last$ = ""

    DO WHILE NOT EOF(f%)
        LINE INPUT #f%, s$
        last$ = s$
        IF LEFT$(s$, 6) = "ERROR:" OR INSTR(s$, "[download] ERROR:") > 0 THEN e$ = s$
    LOOP

    CLOSE #f%

    IF LEN(e$) = 0 THEN e$ = last$
    IF LEN(e$) = 0 THEN e$ = "yt-dlp failed"
    LastErr$ = e$
    EXIT FUNCTION
bad:
    LastErr$ = "yt-dlp failed"
    ON ERROR GOTO 0
END FUNCTION

FUNCTION BgutilAlive%
    port$ = ENVIRON$("BGUTIL_PORT")
    IF LEN(port$) = 0 THEN
        BgutilAlive% = 0
        EXIT FUNCTION
    END IF

    RunCmd "curl -fsS --max-time 2 " + Q$("http://127.0.0.1:" + port$ + "/ping"), "_bg.out", "_bg.exit"
    BgutilAlive% = ReadExit%("_bg.exit") = 0
END FUNCTION

FUNCTION HasMp3% (dir$, id$)
    RunCmd "dir /b " + Q$(dir$ + "\*.mp3"), "_files.out", "_files.exit"

    IF ReadExit%("_files.exit") <> 0 THEN
        HasMp3% = 0
        EXIT FUNCTION
    END IF

    f% = FREEFILE
    OPEN "_files.out" FOR INPUT AS #f%
    needle$ = "[" + id$ + "].mp3"

    DO WHILE NOT EOF(f%)
        LINE INPUT #f%, s$
        IF INSTR(s$, needle$) > 0 THEN
            CLOSE #f%
            HasMp3% = 1
            EXIT FUNCTION
        END IF
    LOOP

    CLOSE #f%
    HasMp3% = 0
END FUNCTION

SUB AddFail (id$, reason$)
    IF LEN(reason$) = 0 THEN reason$ = "unknown error"

    FOR i% = 1 TO failCount%
        IF failIds$(i%) = id$ THEN
            failReasons$(i%) = reason$
            EXIT SUB
        END IF
    NEXT

    failCount% = failCount% + 1
    failIds$(failCount%) = id$
    failReasons$(failCount%) = reason$
END SUB

SUB Render (idx%, total%, id$, phase$, ok%, failed%, msg$)
    done% = idx% - 1
    IF done% < 0 THEN done% = 0
    IF done% > total% THEN done% = total%

    IF total% > 0 THEN percent% = INT(done% * 100 / total%) ELSE percent% = 0

    barWidth% = 32
    IF total% > 0 THEN filled% = INT(done% * barWidth% / total%) ELSE filled% = 0
    empty% = barWidth% - filled%

    bar$ = Rep$("=", filled%) + Rep$(".", empty%)

    CLS
    PRINT
    PRINT Center$("Y T   A U D I O   D O W N L O A D E R", 80)
    PRINT Center$(Fit$(UCASE$(phase$) + " [" + bar$ + "] " + LTRIM$(STR$(percent%)) + "% " + LTRIM$(STR$(done%)) + "/" + LTRIM$(STR$(total%)), 76), 80)
    PRINT Center$(Fit$("ID   : " + IIF$(LEN(id$) > 0, id$, "-"), 76), 80)
    PRINT Center$(Fit$("STAT : OK " + LTRIM$(STR$(ok%)) + "   FAILED " + LTRIM$(STR$(failed%)), 76), 80)
    PRINT Center$(Fit$("LAST : " + msg$, 76), 80)
END SUB
