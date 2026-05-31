DECLARE SUB Main ()
DECLARE SUB RenderCliUi (Index%, Total%, Id$, Phase$, OkCount%, FailedCount%, LastMessage$)
DECLARE SUB DownloadAudio (VideoId$, OutPath$, UseBgutil%, Success%, Reason$)
DECLARE SUB WriteCenteredLine (Text$, Width%, ColorName$)
DECLARE FUNCTION FitText$ (Text$, MaxLen%)
DECLARE FUNCTION BgutilAlive% ()
DECLARE FUNCTION ExtractChannel$ (Url$)
DECLARE FUNCTION ExtractVideoId$ (Url$)

TYPE FailedEntry
    Id AS STRING * 11
    Reason AS STRING * 255
END TYPE

DIM SHARED Failed(1 TO 9999) AS FailedEntry
DIM SHARED FailedCount%

CALL Main

SUB Main
    DIM Url$
    DIM StartFromId$
    DIM Channel$
    DIM OutPath$
    DIM LastMessage$
    DIM Ids$(1 TO 9999)

    CLS
    COLOR 15

    INPUT "YouTube URL: ", Url$
    INPUT "Start From ID: ", StartFromId$

    IF Url$ = "" THEN
        PRINT "URL missing"
        END
    END IF

    Channel$ = ExtractChannel$(Url$)

    IF Channel$ <> "" THEN
        SHELL "mkdir " + Channel$
        SHELL "yt-dlp --flat-playlist --skip-download --print id " + Url$ + " > ids.txt"
        OPEN "ids.txt" FOR INPUT AS #1

        Total% = 0
        DO UNTIL EOF(1)
            LINE INPUT #1, CurrentId$
            IF LEN(CurrentId$) = 11 THEN
                Total% = Total% + 1
                Ids$(Total%) = CurrentId$
            END IF
        LOOP

        CLOSE #1
    ELSE
        Total% = 1
        Ids$(1) = ExtractVideoId$(Url$)
    END IF

    IF Total% = 0 THEN
        PRINT "No videos found to process."
        END
    END IF

    StartIndex% = 1

    IF StartFromId$ <> "" THEN
        Found% = 0

        FOR I% = 1 TO Total%
            IF Ids$(I%) = StartFromId$ THEN
                StartIndex% = I%
                Found% = -1
            END IF
        NEXT I%

        IF Found% = 0 THEN
            PRINT "startFromId not found: "; StartFromId$
            END
        END IF
    END IF

    IF Channel$ <> "" THEN
        OutPath$ = Channel$ + "\%(title)s [%(id)s].%(ext)s"
    ELSE
        OutPath$ = "%(title)s [%(id)s].%(ext)s"
    END IF

    OkCount% = 0
    LastMessage$ = "Waiting..."

    CALL RenderCliUi(StartIndex%, Total%, "", "Initializing", OkCount%, FailedCount%, LastMessage$)

    FOR Index% = StartIndex% TO Total%
        CurrentId$ = Ids$(Index%)

        CALL RenderCliUi(Index%, Total%, CurrentId$, "Downloading", OkCount%, FailedCount%, LastMessage$)

        CALL DownloadAudio(CurrentId$, OutPath$, 0, Success%, Reason$)

        IF Success% = 0 AND BgutilAlive% THEN
            CALL RenderCliUi(Index%, Total%, CurrentId$, "Retry bgutil", OkCount%, FailedCount%, LastMessage$)
            CALL DownloadAudio(CurrentId$, OutPath$, -1, Success%, Reason$)
        END IF

        IF Success% THEN
            OkCount% = OkCount% + 1
            LastMessage$ = "OK " + CurrentId$
        ELSE
            FailedCount% = FailedCount% + 1
            Failed(FailedCount%).Id = CurrentId$
            Failed(FailedCount%).Reason = Reason$
            LastMessage$ = "FAILED " + CurrentId$
        END IF
    NEXT Index%

    CALL RenderCliUi(Total% + 1, Total%, "", "Completed", OkCount%, FailedCount%, "Done")

    OPEN "failed-ids.txt" FOR OUTPUT AS #2
    FOR I% = 1 TO FailedCount%
        PRINT #2, RTRIM$(Failed(I%).Id); CHR$(9); RTRIM$(Failed(I%).Reason)
    NEXT I%
    CLOSE #2

    PRINT
    PRINT "Summary: total="; Total%; " ok="; OkCount%; " failed="; FailedCount%
    PRINT "Failed IDs file: failed-ids.txt"
END SUB

SUB DownloadAudio (VideoId$, OutPath$, UseBgutil%, Success%, Reason$)
    Command$ = "yt-dlp -f bestaudio --js-runtimes node --extract-audio --audio-format mp3 "
    Command$ = Command$ + "--audio-quality 0 --download-archive dwndlist.txt "
    Command$ = Command$ + "--remote-components ejs:github --print after_move:filepath "
    Command$ = Command$ + "--no-simulate -o " + CHR$(34) + OutPath$ + CHR$(34) + " "

    IF UseBgutil% THEN
        Command$ = Command$ + "--extractor-args "
        Command$ = Command$ + CHR$(34) + "youtube:player_client=default;youtube:po_token=bgutil" + CHR$(34) + " "
    END IF

    Command$ = Command$ + CHR$(34) + "https://www.youtube.com/watch?v=" + VideoId$ + CHR$(34)

    SHELL Command$

    Success% = -1
    Reason$ = "ok"
END SUB

FUNCTION BgutilAlive%
    Port$ = ENVIRON$("BGUTIL_PORT")

    IF Port$ = "" THEN
        BgutilAlive% = 0
    ELSE
        SHELL "curl http://127.0.0.1:" + Port$ + "/ping"
        BgutilAlive% = -1
    END IF
END FUNCTION

SUB RenderCliUi (Index%, Total%, Id$, Phase$, OkCount%, FailedCount%, LastMessage$)
    Done% = Index% - 1

    IF Done% < 0 THEN Done% = 0
    IF Done% > Total% THEN Done% = Total%

    IF Total% > 0 THEN
        Percent% = INT((Done% / Total%) * 100)
    ELSE
        Percent% = 0
    END IF

    BarWidth% = 32
    Filled% = INT((Done% * BarWidth%) / Total%)
    Empty% = BarWidth% - Filled%

    Bar$ = STRING$(Filled%, "=") + STRING$(Empty%, ".")

    CLS

    PRINT
    PRINT
    CALL WriteCenteredLine("Y T   A U D I O   D O W N L O A D E R", 80, "White")
    CALL WriteCenteredLine(FitText$(UCASE$(Phase$) + " [" + Bar$ + "] " + STR$(Percent%) + "%  " + STR$(Done%) + "/" + STR$(Total%), 80), 80, "Cyan")
    CALL WriteCenteredLine(FitText$("ID   : " + Id$, 80), 80, "Gray")
    CALL WriteCenteredLine(FitText$("STAT : OK " + STR$(OkCount%) + "   FAILED " + STR$(FailedCount%), 80), 80, "Green")
    CALL WriteCenteredLine(FitText$("LAST : " + LastMessage$, 80), 80, "DarkGray")

    IF FailedCount% > 0 THEN
        PRINT
        CALL WriteCenteredLine("FAILED LIST", 80, "Red")

        FOR I% = 1 TO FailedCount%
            CALL WriteCenteredLine(FitText$("FAILED  " + RTRIM$(Failed(I%).Id) + "  " + RTRIM$(Failed(I%).Reason), 80), 80, "Red")
        NEXT I%
    END IF
END SUB

SUB WriteCenteredLine (Text$, Width%, ColorName$)
    Padding% = INT((Width% - LEN(Text$)) / 2)

    IF Padding% < 0 THEN Padding% = 0

    SELECT CASE ColorName$
        CASE "White": COLOR 15
        CASE "Cyan": COLOR 11
        CASE "Gray": COLOR 8
        CASE "Green": COLOR 10
        CASE "Yellow": COLOR 14
        CASE "Red": COLOR 12
        CASE ELSE: COLOR 7
    END SELECT

    PRINT SPACE$(Padding%); Text$
END SUB

FUNCTION FitText$ (Text$, MaxLen%)
    IF LEN(Text$) <= MaxLen% THEN
        FitText$ = Text$
    ELSE
        FitText$ = LEFT$(Text$, MaxLen% - 3) + "..."
    END IF
END FUNCTION

FUNCTION ExtractChannel$ (Url$)
    Pos% = INSTR(Url$, "youtube.com/@")

    IF Pos% = 0 THEN
        ExtractChannel$ = ""
    ELSE
        Start% = Pos% + LEN("youtube.com/@")
        StopAt% = INSTR(Start%, Url$, "/")

        IF StopAt% = 0 THEN StopAt% = LEN(Url$) + 1

        ExtractChannel$ = MID$(Url$, Start%, StopAt% - Start%)
    END IF
END FUNCTION

FUNCTION ExtractVideoId$ (Url$)
    Pos% = INSTR(Url$, "v=")

    IF Pos% > 0 THEN
        ExtractVideoId$ = MID$(Url$, Pos% + 2, 11)
    ELSE
        Pos% = INSTR(Url$, "youtu.be/")
        ExtractVideoId$ = MID$(Url$, Pos% + 9, 11)
    END IF
END FUNCTION
