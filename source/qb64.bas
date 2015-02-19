'All variables will be of type LONG unless explicitly defined
DEFLNG A-Z

'All arrays will be dynamically allocated so they can be REDIM-ed
'$DYNAMIC

'We need console access to support command-line compilation via the -x command line compile option
$CONSOLE

'Initially the "SCREEN" will be hidden, if the -x option is used it will never be created
$SCREENHIDE

'$INCLUDE:'global\version.bas'
'$INCLUDE:'global\settings.bas'
'$INCLUDE:'global\constants.bas'
'$INCLUDE:'subs_functions\extensions\opengl\opengl_global.bas'

'-------- Optional IDE Component (1/2) --------
'$INCLUDE:'ide\ide_global.bas'

REDIM SHARED OName(0) AS STRING 'Operation Name
REDIM SHARED PL(0) AS INTEGER 'Priority Level
DIM SHARED QuickReturn AS INTEGER
Set_OrderOfOperations 'This will also make certain our directories are valid, and if not make them.

DIM SHARED MakeAndroid 'build an Android project (refer to SUB UseAndroid)

'refactor patch
DIM SHARED Refactor_Source AS STRING
DIM SHARED Refactor_Dest AS STRING
IF _FILEEXISTS("refactor.txt") THEN
    fh = FREEFILE
    OPEN "refactor.txt" FOR BINARY AS #fh
    LINE INPUT #fh, Refactor_Source
    LINE INPUT #fh, Refactor_Dest
    CLOSE fh
END IF

IF _DIREXISTS("internal") = 0 THEN
    _SCREENSHOW
    PRINT "QB64 cannot locate the 'internal' folder"
    PRINT
    PRINT "Check that QB64 has been extracted properly."
    PRINT "For MacOSX, launch 'qb64_start.command' or enter './qb64' in Terminal."
    PRINT "For Linux, in the console enter './qb64'."
    DO
        _LIMIT 1
    LOOP UNTIL INKEY$ <> ""
    SYSTEM
END IF

DIM SHARED Include_GDB_Debugging_Info 'set using "options.bin"

DIM SHARED DEPENDENCY_LAST
CONST DEPENDENCY_LOADFONT = 1: DEPENDENCY_LAST = DEPENDENCY_LAST + 1
CONST DEPENDENCY_AUDIO_CONVERSION = 2: DEPENDENCY_LAST = DEPENDENCY_LAST + 1
CONST DEPENDENCY_AUDIO_DECODE = 3: DEPENDENCY_LAST = DEPENDENCY_LAST + 1
CONST DEPENDENCY_AUDIO_OUT = 4: DEPENDENCY_LAST = DEPENDENCY_LAST + 1
CONST DEPENDENCY_GL = 5: DEPENDENCY_LAST = DEPENDENCY_LAST + 1
CONST DEPENDENCY_IMAGE_CODEC = 6: DEPENDENCY_LAST = DEPENDENCY_LAST + 1
CONST DEPENDENCY_USER_MODS = 7: DEPENDENCY_LAST = DEPENDENCY_LAST + 1
CONST DEPENDENCY_CONSOLE_ONLY = 8: DEPENDENCY_LAST = DEPENDENCY_LAST + 1 '=2 if via -g switch, =1 if via metacommand $CONSOLE:ONLY
CONST DEPENDENCY_SOCKETS = 9: DEPENDENCY_LAST = DEPENDENCY_LAST + 1
CONST DEPENDENCY_PRINTER = 10: DEPENDENCY_LAST = DEPENDENCY_LAST + 1
CONST DEPENDENCY_ICON = 11: DEPENDENCY_LAST = DEPENDENCY_LAST + 1
CONST DEPENDENCY_SCREENIMAGE = 12: DEPENDENCY_LAST = DEPENDENCY_LAST + 1
CONST DEPENDENCY_DEVICEINPUT = 13: DEPENDENCY_LAST = DEPENDENCY_LAST + 1 'removes support for gamepad input if not present




DIM SHARED DEPENDENCY(1 TO DEPENDENCY_LAST)

DIM SHARED UseGL 'declared SUB _GL (no params)


DIM SHARED OS_BITS AS LONG
OS_BITS = 64: IF INSTR(_OS$, "[32BIT]") THEN OS_BITS = 32

IF OS_BITS = 32 THEN _TITLE "QB64 x32" ELSE _TITLE "QB64 x64"

DIM SHARED ConsoleMode, No_C_Compile_Mode, Cloud, NoIDEMode
DIM SHARED CMDLineFile AS STRING
CMDLineFile = ParseCMDLineArgs$

IF ConsoleMode THEN
    _DEST _CONSOLE
ELSE
    _CONSOLE OFF
    _SCREENSHOW
    _ICON
END IF

DIM SHARED NoChecks

DIM SHARED Console
DIM SHARED ScreenHide
DIM SHARED OptMax AS LONG
OptMax = 256
REDIM SHARED Opt(1 TO OptMax, 1 TO 10) AS STRING * 256
'   (1,1)="READ"
'   (1,2)="WRITE"
'   (1,3)="READ WRITE"
REDIM SHARED OptWords(1 TO OptMax, 1 TO 10) AS INTEGER 'The number of words of each opt () element
'   (1,1)=1 '"READ"
'   (1,2)=1 '"WRITE"
'   (1,3)=2 '"READ WRITE"
REDIM SHARED T(1 TO OptMax) AS INTEGER 'The type of the entry
'   t is 0 for ? opts
'   ---------- 0 means ? , 1+ means a symbol or {}block ----------
'   t is 1 for symbol opts
'   t is the number of rhs opt () index enteries for {READ|WRITE|READ WRITE} like opts
REDIM SHARED Lev(1 TO OptMax) AS INTEGER 'The indwelling level of each opt () element (the lowest is 0)
REDIM SHARED EntryLev(1 TO OptMax) AS INTEGER 'The level required from which this opt () can be validly be entered/checked-for
REDIM SHARED DitchLev(1 TO OptMax) AS INTEGER 'The lowest level recorded between the previous Opt and this Opt
REDIM SHARED DontPass(1 TO OptMax) AS INTEGER 'Set to 1 or 0, with 1 meaning don't pass
'Determines whether the opt () entry needs to actually be passed to the C++ sub/function
REDIM SHARED TempList(1 TO OptMax) AS INTEGER
REDIM SHARED PassRule(1 TO OptMax) AS LONG
'0 means no pass rule
'negative values refer to an opt () element
'positive values refer to a flag value
REDIM SHARED LevelEntered(OptMax) 'up to 64 levels supported
REDIM SHARED separgs(OptMax + 1) AS STRING
REDIM SHARED separgslayout(OptMax + 1) AS STRING
REDIM SHARED separgs2(OptMax + 1) AS STRING
REDIM SHARED separgslayout2(OptMax + 1) AS STRING





DIM SHARED E










DIM SHARED ResolveStaticFunctions
REDIM SHARED ResolveStaticFunction_File(1 TO 100) AS STRING
REDIM SHARED ResolveStaticFunction_Name(1 TO 100) AS STRING
REDIM SHARED ResolveStaticFunction_Method(1 TO 100) AS LONG





DIM SHARED Error_Happened AS LONG
DIM SHARED Error_Message AS STRING

DIM SHARED os AS STRING
os$ = "WIN"
IF INSTR(_OS$, "[LINUX]") THEN os$ = "LNX"

DIM SHARED MacOSX AS LONG
IF INSTR(_OS$, "[MACOSX]") THEN MacOSX = 1

DIM SHARED inline_DATA
IF MacOSX THEN inline_DATA = 1

DIM SHARED BATCHFILE_EXTENSION AS STRING
BATCHFILE_EXTENSION = ".bat"
IF os$ = "LNX" THEN BATCHFILE_EXTENSION = ".sh"
IF MacOSX THEN BATCHFILE_EXTENSION = ".command"


DIM inlinedatastr(255) AS STRING
FOR i = 0 TO 255
    inlinedatastr(i) = str2$(i) + ","
NEXT


DIM SHARED extension AS STRING
extension$ = ".exe"
IF os$ = "LNX" THEN extension$ = "" 'no extension under Linux

DIM SHARED pathsep AS STRING * 1
pathsep$ = "\"
IF os$ = "LNX" THEN pathsep$ = "/"
'note: QB64 handles OS specific path separators automatically except under SHELL calls

ON ERROR GOTO qberror_test

DIM SHARED tmpdir AS STRING, tmpdir2 AS STRING
IF os$ = "WIN" THEN tmpdir$ = ".\internal\temp\": tmpdir2$ = "..\\temp\\"
IF os$ = "LNX" THEN tmpdir$ = "./internal/temp/": tmpdir2$ = "../temp/"

DIM SHARED tempfolderindex
E = 0
i = 1
OPEN tmpdir$ + "temp.bin" FOR OUTPUT LOCK WRITE AS #26
DO WHILE E
    i = i + 1
    IF i = 1000 THEN PRINT "Unable to locate the 'internal' folder": END
    MKDIR ".\internal\temp" + str2$(i)
    IF os$ = "WIN" THEN tmpdir$ = ".\internal\temp" + str2$(i) + "\": tmpdir2$ = "..\\temp" + str2$(i) + "\\"
    IF os$ = "LNX" THEN tmpdir$ = "./internal/temp" + str2$(i) + "/": tmpdir2$ = "../temp" + str2$(i) + "/"
    E = 0
    OPEN tmpdir$ + "temp.bin" FOR OUTPUT LOCK WRITE AS #26
LOOP
'temp folder established
tempfolderindex = i
IF i > 1 THEN
    'create modified version of qbx.cpp
    OPEN ".\internal\c\qbx" + str2$(i) + ".cpp" FOR OUTPUT AS #2
    OPEN ".\internal\c\qbx.cpp" FOR BINARY AS #1
    DO UNTIL EOF(1)
        LINE INPUT #1, a$
        x = INSTR(a$, "..\\temp\\"): IF x THEN a$ = LEFT$(a$, x - 1) + "..\\temp" + str2$(i) + "\\" + RIGHT$(a$, LEN(a$) - (x + 9))
        x = INSTR(a$, "../temp/"): IF x THEN a$ = LEFT$(a$, x - 1) + "../temp" + str2$(i) + "/" + RIGHT$(a$, LEN(a$) - (x + 7))
        PRINT #2, a$
    LOOP
    CLOSE #1, #2
END IF

IF Debug THEN OPEN tmpdir$ + "debug.txt" FOR OUTPUT AS #9

ON ERROR GOTO qberror



DIM SHARED tempfolderindexstr AS STRING 'appended to "Untitled"
DIM SHARED tempfolderindexstr2 AS STRING
IF tempfolderindex <> 1 THEN tempfolderindexstr$ = "(" + str2$(tempfolderindex) + ")": tempfolderindexstr2$ = str2$(tempfolderindex)


DIM SHARED idedebuginfo
DIM SHARED seperateargs_error
DIM SHARED seperateargs_error_message AS STRING

DIM SHARED compfailed

DIM SHARED reginternalsubfunc
DIM SHARED reginternalvariable


DIM SHARED symboltype_size
symboltype_size = 0

DIM SHARED use_global_byte_elements
use_global_byte_elements = 0

'compiler-side IDE data & definitions
'SHARED variables "passed" to/from the compiler & IDE
DIM SHARED idecommand AS STRING 'a 1 byte message-type code, followed by optional string data
DIM SHARED idereturn AS STRING 'used to pass formatted-lines and return information back to the IDE
DIM SHARED ideerror AS LONG
DIM SHARED idecompiled AS LONG
DIM SHARED idemode '1 if using the IDE to compile
DIM SHARED ideerrorline AS LONG 'set by qb64-error(...) to the line number it would have reported, this number
'is later passed to the ide in message #8
DIM SHARED idemessage AS STRING 'set by qb64-error(...) to the error message to be reported, this
'is later passed to the ide in message #8

'the function ?=ide(?) should always be passed 0, it returns a message code number, any further information
'is passed back in idereturn

'message code numbers:
'0  no ide present  (auto defined array ide() return 0)

'1  launch ide & with passed filename (compiler->ide)

'2  begin new compilation with returned line of code (compiler<-ide)
'   [2][line of code]

'3  request next line (compiler->ide)
'   [3]

'4  next line of code returned (compiler<-ide)
'   [4][line of code]

'5  no more lines of code exist (compiler<-ide)
'   [5]

'6  code is OK/ready (compiler->ide)
'   [6]

'7  repass the code from the beginning (compiler->ide)
'   [7]

'8  an error has occurred with 'this' message on 'this' line(compiler->ide)
'   [8][error message][line as LONG]

'9  C++ compile (if necessary) and run with 'this' name (compiler<-ide)
'   [9][name(no path, no .bas)]

'10 The line requires more time to process
'       Pass-back 'line of code' using method [4] when ready
'   [10][line of code]

'11 ".EXE file created" message

'12     The name of the exe I'll create is '...' (compiler->ide)
'   [12][exe name without .exe]

'255    A qb error happened in the IDE (compiler->ide)
'   note: detected by the fact that ideerror was not set to 0
'   [255]




'ref: options.bin
'SEEK 1
'[2]   ideautolayout(=1)
'[2]   ideautoindent(=1)
'[2]   ideautoindentsize(=4)
'SEEK 7
'[2]   idewx(=80)
'[2]   idewy(=25)
'[2]   idecustomfont(=0)
'[1024]idecustomfontfile(=c:\windows\fonts\lucon.ttf)
'[2]   idecustomfontheight(=21)
'SEEK 1039
'[2]   ideupdatecheck(=1) ***deprecated***
'[2]   ideupdatedaily(=1) ***deprecated***
'[2]   ideupdateauto(=0)  ***deprecated***
'[4]   ideupdatelast(=0)  ***deprecated***
'SEEK 1049
'[2]   codepage(=0)
'SEEK 1051
'[4]   backupsize(=100)
'SEEK 1055
'[2]   embed debug info
'total bytes: 1056

OPEN ".\internal\temp\options.bin" FOR BINARY AS #150

'remake options with defaults?
IF LOF(150) < 1048 THEN
    CLOSE #150
    OPEN ".\internal\temp\options.bin" FOR OUTPUT AS #150: CLOSE #150
    OPEN ".\internal\temp\options.bin" FOR BINARY AS #150
    v% = 1: PUT #150, , v% 'layout
    v% = 1: PUT #150, , v% 'indent
    v% = 4: PUT #150, , v% 'indentsize
    v% = 80: PUT #150, , v% 'w
    v% = 25: PUT #150, , v% 'h
    v% = 0: PUT #150, , v% 'use custom font?
    v$ = SPACE$(1024): MID$(v$, 1) = "c:\windows\fonts\lucon.ttf": PUT #150, , v$
    v% = 21: PUT #150, , v% 'custom font height
    v% = 1: PUT #150, , v% 'update-check
    v% = 1: PUT #150, , v% 'update-daily
    v% = 0: PUT #150, , v% 'update-autoapply
    ideupdatelast& = 0: PUT #150, , ideupdatelast& 'update-datestamp(last)
END IF
IF LOF(150) < 1050 THEN
    SEEK #150, 1049
    v% = 0: PUT #150, , v% 'codepage
END IF
IF LOF(150) < 1054 THEN
    SEEK #150, 1051
    v& = 100: PUT #150, , v& 'backup-size(mb)
END IF
IF LOF(150) < 1056 THEN
    SEEK #150, 1055
    v% = 0: PUT #150, , v% 'idedebuginfo
END IF

'@1056
IF LOF(150) < 1056 + 2 + 256 + 256 THEN
    SEEK #150, 1057
    v% = 0: PUT #150, , v% 'IdeAndroidMenu
    a$ = "programs\android\start_android.bat"
    a$ = a$ + SPACE$(256 - LEN(a$))
    PUT #150, , a$ 'IdeAndroidStartScript
    a$ = "programs\android\make_android.bat"
    a$ = a$ + SPACE$(256 - LEN(a$))
    PUT #150, , a$ 'IdeAndroidMakeScript
END IF

'load options
SEEK #150, 1
'layout:
GET #150, , v%: IF v% <> 0 THEN v% = 1
ideautolayout = v%
GET #150, , v%: IF v% <> 0 THEN v% = 1
ideautoindent = v%
GET #150, , v%: IF v% < 0 OR v% > 64 THEN v% = 4
ideautoindentsize = v%
'display:
GET #150, , v%: IF v% < 80 OR v% > 1000 THEN v% = 80
idewx = v%
GET #150, , v%: IF v% < 25 OR v% > 1000 THEN v% = 25
idewy = v%
GET #150, , v%: IF v% <> 0 THEN v% = 1
idecustomfont = v%
v$ = SPACE$(1024): GET #150, , v$: idecustomfontfile$ = RTRIM$(v$)
GET #150, , v%: IF v% < 8 OR v% > 100 THEN v% = 21
idecustomfontheight = v%
GET #150, , v%: IF v% < 0 OR v% > 1 THEN v% = 1
ideupdatecheck = v%
GET #150, , v%: IF v% < 0 OR v% > 1 THEN v% = 1
ideupdatedaily = v%
GET #150, , v%: IF v% < 0 OR v% > 1 THEN v% = 1
ideupdateauto = v%
GET #150, , v&
ideupdatelast = v&
GET #150, , v%: IF v% < 0 OR v% > idecpnum THEN v% = 0
idecpindex = v%
GET #150, , v&: IF v& < 10 OR v& > 2000 THEN v& = 100
idebackupsize = v&
GET #150, , v%: IF v% < 0 OR v% > 1 THEN v% = 0
idedebuginfo = v%
Include_GDB_Debugging_Info = idedebuginfo
GET #150, , v%: IF v% < 0 OR v% > 1 THEN v% = 0
IdeAndroidMenu = v%
a$ = SPACE$(256)
GET #150, , a$
a$ = RTRIM$(a$)
IdeAndroidStartScript$ = a$
a$ = SPACE$(256)
GET #150, , a$
a$ = RTRIM$(a$)
IdeAndroidMakeScript$ = a$
CLOSE #150




'hash table data
TYPE HashListItem
    Flags AS LONG
    Reference AS LONG
    NextItem AS LONG
    PrevItem AS LONG
    LastItem AS LONG 'note: this value is only valid on the first item in the list
    'note: name is stored in a seperate array of strings
END TYPE
DIM SHARED HashFind_NextListItem AS LONG
DIM SHARED HashFind_Reverse AS LONG
DIM SHARED HashFind_SearchFlags AS LONG
DIM SHARED HashFind_Name AS STRING
DIM SHARED HashRemove_LastFound AS LONG
DIM SHARED HashListSize AS LONG
DIM SHARED HashListNext AS LONG
DIM SHARED HashListFreeSize AS LONG
DIM SHARED HashListFreeLast AS LONG
'hash lookup tables
DIM SHARED hash1char(255) AS INTEGER
DIM SHARED hash2char(65535) AS INTEGER
FOR x = 1 TO 26
    hash1char(64 + x) = x
    hash1char(96 + x) = x
NEXT
hash1char(95) = 27 '_
hash1char(48) = 28 '0
hash1char(49) = 29 '1
hash1char(50) = 30 '2
hash1char(51) = 31 '3
hash1char(52) = 23 '4 'note: x, y, z and beginning alphabet letters avoided because of common usage (eg. a2, y3)
hash1char(53) = 22 '5
hash1char(54) = 20 '6
hash1char(55) = 19 '7
hash1char(56) = 18 '8
hash1char(57) = 17 '9
FOR c1 = 0 TO 255
    FOR c2 = 0 TO 255
        hash2char(c1 + c2 * 256) = hash1char(c1) + hash1char(c2) * 32
    NEXT
NEXT
'init
HashListSize = 65536
HashListNext = 1
HashListFreeSize = 1024
HashListFreeLast = 0
REDIM SHARED HashList(1 TO HashListSize) AS HashListItem
REDIM SHARED HashListName(1 TO HashListSize) AS STRING * 256
REDIM SHARED HashListFree(1 TO HashListFreeSize) AS LONG
REDIM SHARED HashTable(16777215) AS LONG '64MB lookup table with indexes to the hashlist

CONST HASHFLAG_LABEL = 2
CONST HASHFLAG_TYPE = 4
CONST HASHFLAG_RESERVED = 8
CONST HASHFLAG_OPERATOR = 16
CONST HASHFLAG_CUSTOMSYNTAX = 32
CONST HASHFLAG_SUB = 64
CONST HASHFLAG_FUNCTION = 128
CONST HASHFLAG_UDT = 256
CONST HASHFLAG_UDTELEMENT = 512
CONST HASHFLAG_CONSTANT = 1024
CONST HASHFLAG_VARIABLE = 2048
CONST HASHFLAG_ARRAY = 4096
CONST HASHFLAG_XELEMENTNAME = 8192
CONST HASHFLAG_XTYPENAME = 16384

TYPE Label_Type
    State AS _UNSIGNED _BYTE '0=label referenced, 1=label created
    cn AS STRING * 256
    Scope AS LONG
    Data_Offset AS _INTEGER64 'offset within data
    Data_Referenced AS _UNSIGNED _BYTE 'set to 1 if data is referenced (data_offset will be used to create the data offset variable)
    Error_Line AS LONG 'the line number to reference on errors
    Scope_Restriction AS LONG 'cannot exist inside this scope (post checked)
END TYPE
DIM SHARED nLabels, Labels_Ubound
Labels_Ubound = 100
REDIM SHARED Labels(1 TO Labels_Ubound) AS Label_Type
DIM SHARED Empty_Label AS Label_Type

DIM SHARED PossibleSubNameLabels AS STRING 'format: name+sp+name+sp+name <-ucase$'d
DIM SHARED SubNameLabels AS STRING 'format: name+sp+name+sp+name <-ucase$'d
DIM SHARED CreatingLabel AS LONG

DIM SHARED AllowLocalName AS LONG

DIM SHARED DataOffset

DIM SHARED prepass


DIM SHARED autoarray

DIM SHARED ontimerid, onkeyid, onstrigid

DIM SHARED revertmaymusthave(1 TO 10000)
DIM SHARED revertmaymusthaven

DIM SHARED linecontinuation

DIM SHARED dim2typepassback AS STRING 'passes back correct case sensitive version of type


DIM SHARED inclevel
DIM SHARED incname(100) AS STRING 'must be full path as given
DIM SHARED inclinenumber(100) AS LONG
DIM SHARED incerror AS STRING


DIM SHARED fix046 AS STRING
fix046$ = "__" + "ASCII" + "_" + "CHR" + "_" + "046" + "__" 'broken up to avoid detection for layout reversion

DIM SHARED layout AS STRING 'passed to IDE
DIM SHARED layoutok AS LONG 'tracks status of entire line

DIM SHARED layoutcomment AS STRING

DIM SHARED tlayout AS STRING 'temporary layout string set by supporting functions
DIM SHARED layoutdone AS LONG 'tracks status of single command


DIM SHARED fooindwel

DIM SHARED alphanumeric(255)
FOR i = 48 TO 57
    alphanumeric(i) = -1
NEXT
FOR i = 65 TO 90
    alphanumeric(i) = -1
NEXT
FOR i = 97 TO 122
    alphanumeric(i) = -1
NEXT
'_ is treated as an alphabet letter
alphanumeric(95) = -1

DIM SHARED isalpha(255)
FOR i = 65 TO 90
    isalpha(i) = -1
NEXT
FOR i = 97 TO 122
    isalpha(i) = -1
NEXT
'_ is treated as an alphabet letter
isalpha(95) = -1

DIM SHARED isnumeric(255)
FOR i = 48 TO 57
    isnumeric(i) = -1
NEXT


DIM SHARED lfsinglechar(255)
lfsinglechar(40) = 1 '(
lfsinglechar(41) = 1 ')
lfsinglechar(42) = 1 '*
lfsinglechar(43) = 1 '+
lfsinglechar(45) = 1 '-
lfsinglechar(47) = 1 '/
lfsinglechar(60) = 1 '<
lfsinglechar(61) = 1 '=
lfsinglechar(62) = 1 '>
lfsinglechar(92) = 1 '\
lfsinglechar(94) = 1 '^

lfsinglechar(44) = 1 ',
lfsinglechar(46) = 1 '.
lfsinglechar(58) = 1 ':
lfsinglechar(59) = 1 ';

lfsinglechar(35) = 1 '# (file no only)
lfsinglechar(36) = 1 '$ (metacommand only)
lfsinglechar(63) = 1 '? (print macro)
lfsinglechar(95) = 1 '_










DIM SHARED nextrunlineindex AS LONG

DIM SHARED lineinput3buffer AS STRING
DIM SHARED lineinput3index AS LONG

DIM SHARED dimstatic AS LONG

DIM SHARED staticarraylist AS STRING
DIM SHARED staticarraylistn AS LONG
DIM SHARED commonarraylist AS STRING
DIM SHARED commonarraylistn AS LONG

'CONST support
DIM SHARED constmax AS LONG
constmax = 100
DIM SHARED constlast AS LONG
constlast = -1
REDIM SHARED constname(constmax) AS STRING
REDIM SHARED constcname(constmax) AS STRING
REDIM SHARED constnamesymbol(constmax) AS STRING 'optional name symbol
' `1 and `no-number must be handled correctly
'DIM SHARED constlastshared AS LONG 'so any defined inside a sub/function after this index can be "forgotten" when sub/function exits
'constlastshared = -1
REDIM SHARED consttype(constmax) AS LONG 'variable type number
'consttype determines storage
REDIM SHARED constinteger(constmax) AS _INTEGER64
REDIM SHARED constuinteger(constmax) AS _UNSIGNED _INTEGER64
REDIM SHARED constfloat(constmax) AS _FLOAT
REDIM SHARED conststring(constmax) AS STRING
REDIM SHARED constsubfunc(constmax) AS LONG
REDIM SHARED constdefined(constmax) AS LONG

'UDT
'names
DIM SHARED lasttype AS LONG
DIM SHARED udtxname(1000) AS STRING * 256
DIM SHARED udtxcname(1000) AS STRING * 256
DIM SHARED udtxsize(1000) AS LONG
DIM SHARED udtxbytealign(1000) AS INTEGER 'first element MUST be on a byte alignment & size is a multiple of 8
DIM SHARED udtxnext(1000) AS LONG
'elements
DIM SHARED lasttypeelement AS LONG
DIM SHARED udtename(1000) AS STRING * 256
DIM SHARED udtecname(1000) AS STRING * 256
DIM SHARED udtebytealign(1000) AS INTEGER
DIM SHARED udtesize(1000) AS LONG
DIM SHARED udtetype(1000) AS LONG
DIM SHARED udtetypesize(1000) AS LONG
DIM SHARED udtearrayelements(1000) AS LONG
DIM SHARED udtenext(1000) AS LONG

TYPE idstruct

    n AS STRING * 256 'name
    cn AS STRING * 256 'case sensitive version of n

    arraytype AS LONG 'similar to t
    arrayelements AS INTEGER
    staticarray AS INTEGER 'set for arrays declared in the main module with static elements

    mayhave AS STRING * 8 'mayhave and musthave are exclusive of each other
    musthave AS STRING * 8
    t AS LONG 'type

    tsize AS LONG


    subfunc AS INTEGER 'if function=1, sub=2 (max 100 arguments)
    Dependency AS INTEGER
    internal_subfunc AS INTEGER

    callname AS STRING * 256
    ccall AS INTEGER
    args AS INTEGER
    arg AS STRING * 400 'similar to t
    argsize AS STRING * 400 'similar to tsize (used for fixed length strings)
    specialformat AS STRING * 256
    secondargmustbe AS STRING * 256
    secondargcantbe AS STRING * 256
    ret AS LONG 'the value it returns if it is a function (again like t)

    insubfunc AS STRING * 256
    insubfuncn AS LONG

    share AS INTEGER
    nele AS STRING * 100
    nelereq AS STRING * 100
    linkid AS LONG
    linkarg AS INTEGER
    staticscope AS INTEGER
    'For variables which are arguments passed to a sub/function
    sfid AS LONG 'id number of variable's parent sub/function
    sfarg AS INTEGER 'argument/parameter # within call (1=first)

    NoCloud AS INTEGER
END TYPE

DIM SHARED id AS idstruct

DIM SHARED idn AS LONG
DIM SHARED ids_max AS LONG
ids_max = 1024
REDIM SHARED ids(1 TO ids_max) AS idstruct
REDIM SHARED cmemlist(1 TO ids_max + 1) AS INTEGER 'variables that must be in cmem
REDIM SHARED sfcmemargs(1 TO ids_max + 1) AS STRING * 100 's/f arg that must be in cmem
REDIM SHARED arrayelementslist(1 TO ids_max + 1) AS INTEGER 'arrayelementslist (like cmemlist) helps to resolve the number of elements in arrays with an unknown number of elements. Note: arrays with an unknown number of elements have .arrayelements=-1


'create blank id template for idclear to copy (stops strings being set to chr$(0))
DIM SHARED cleariddata AS idstruct
cleariddata.cn = ""
cleariddata.n = ""
cleariddata.mayhave = ""
cleariddata.musthave = ""
cleariddata.callname = ""
cleariddata.arg = ""
cleariddata.argsize = ""
cleariddata.specialformat = ""
cleariddata.secondargmustbe = ""
cleariddata.secondargcantbe = ""
cleariddata.insubfunc = ""
cleariddata.nele = ""
cleariddata.nelereq = ""

DIM SHARED ISSTRING AS LONG
DIM SHARED ISFLOAT AS LONG
DIM SHARED ISUNSIGNED AS LONG
DIM SHARED ISPOINTER AS LONG
DIM SHARED ISFIXEDLENGTH AS LONG
DIM SHARED ISINCONVENTIONALMEMORY AS LONG
DIM SHARED ISOFFSETINBITS AS LONG
DIM SHARED ISARRAY AS LONG
DIM SHARED ISREFERENCE AS LONG
DIM SHARED ISUDT AS LONG
DIM SHARED ISOFFSET AS LONG

DIM SHARED STRINGTYPE AS LONG
DIM SHARED BITTYPE AS LONG
DIM SHARED UBITTYPE AS LONG
DIM SHARED BYTETYPE AS LONG
DIM SHARED UBYTETYPE AS LONG
DIM SHARED INTEGERTYPE AS LONG
DIM SHARED UINTEGERTYPE AS LONG
DIM SHARED LONGTYPE AS LONG
DIM SHARED ULONGTYPE AS LONG
DIM SHARED INTEGER64TYPE AS LONG
DIM SHARED UINTEGER64TYPE AS LONG
DIM SHARED SINGLETYPE AS LONG
DIM SHARED DOUBLETYPE AS LONG
DIM SHARED FLOATTYPE AS LONG
DIM SHARED OFFSETTYPE AS LONG
DIM SHARED UOFFSETTYPE AS LONG
DIM SHARED UDTTYPE AS LONG

DIM SHARED gosubid AS LONG
DIM SHARED redimoption AS INTEGER
DIM SHARED dimoption AS INTEGER
DIM SHARED arraydesc AS INTEGER
DIM SHARED qberrorhappened AS INTEGER
DIM SHARED qberrorcode AS INTEGER
DIM SHARED qberrorline AS INTEGER
'COMMON SHARED defineaz() AS STRING
'COMMON SHARED defineextaz() AS STRING

DIM SHARED sourcefile AS STRING 'the full path and filename
DIM SHARED file AS STRING 'name of the file (without .bas or path)

'COMMON SHARED separgs() AS STRING

DIM SHARED constequation AS INTEGER
DIM SHARED DynamicMode AS INTEGER
DIM SHARED findidsecondarg AS STRING
DIM SHARED findanotherid AS INTEGER
DIM SHARED findidinternal AS LONG
DIM SHARED currentid AS LONG 'is the index of the last ID accessed
DIM SHARED linenumber AS LONG
DIM SHARED wholeline AS STRING
DIM SHARED linefragment AS STRING
'COMMON SHARED bitmask() AS _INTEGER64
'COMMON SHARED bitmaskinv() AS _INTEGER64

DIM SHARED arrayprocessinghappened AS INTEGER
DIM SHARED stringprocessinghappened AS INTEGER
DIM SHARED cleanupstringprocessingcall AS STRING
DIM SHARED recompile AS INTEGER 'forces recompilation
'COMMON SHARED cmemlist() AS INTEGER
DIM SHARED optionbase AS INTEGER

DIM SHARED addmetastatic AS INTEGER
DIM SHARED addmetadynamic AS INTEGER
DIM SHARED addmetainclude AS STRING

DIM SHARED closedmain AS INTEGER
DIM SHARED module AS STRING

DIM SHARED subfunc AS STRING
DIM SHARED subfuncn AS LONG
DIM SHARED subfuncid AS LONG

DIM SHARED defdatahandle AS INTEGER
DIM SHARED dimsfarray AS INTEGER
DIM SHARED dimshared AS INTEGER

'Allows passing of known elements to recompilation
DIM SHARED sflistn AS INTEGER
'COMMON SHARED sfidlist() AS LONG
'COMMON SHARED sfarglist() AS INTEGER
'COMMON SHARED sfelelist() AS INTEGER
DIM SHARED glinkid AS LONG
DIM SHARED glinkarg AS INTEGER
DIM SHARED typname2typsize AS LONG
DIM SHARED uniquenumbern AS LONG

'CLEAR , , 16384


DIM SHARED bitmask(1 TO 56) AS _INTEGER64
DIM SHARED bitmaskinv(1 TO 56) AS _INTEGER64

DIM SHARED defineextaz(1 TO 27) AS STRING
DIM SHARED defineaz(1 TO 27) AS STRING '27 is an underscore

ISSTRING = 1073741824
ISFLOAT = 536870912
ISUNSIGNED = 268435456
ISPOINTER = 134217728
ISFIXEDLENGTH = 67108864 'only set for strings with pointer flag
ISINCONVENTIONALMEMORY = 33554432
ISOFFSETINBITS = 16777216
ISARRAY = 8388608
ISREFERENCE = 4194304
ISUDT = 2097152
ISOFFSET = 1048576

STRINGTYPE = ISSTRING + ISPOINTER
BITTYPE = 1& + ISPOINTER + ISOFFSETINBITS
UBITTYPE = 1& + ISPOINTER + ISUNSIGNED + ISOFFSETINBITS 'QB64 will also support BIT*n, eg. DIM bitarray[10] AS _UNSIGNED _BIT*10
BYTETYPE = 8& + ISPOINTER
UBYTETYPE = 8& + ISPOINTER + ISUNSIGNED
INTEGERTYPE = 16& + ISPOINTER
UINTEGERTYPE = 16& + ISPOINTER + ISUNSIGNED
LONGTYPE = 32& + ISPOINTER
ULONGTYPE = 32& + ISPOINTER + ISUNSIGNED
INTEGER64TYPE = 64& + ISPOINTER
UINTEGER64TYPE = 64& + ISPOINTER + ISUNSIGNED
SINGLETYPE = 32& + ISFLOAT + ISPOINTER
DOUBLETYPE = 64& + ISFLOAT + ISPOINTER
FLOATTYPE = 256& + ISFLOAT + ISPOINTER '8-32 bytes
OFFSETTYPE = 64& + ISOFFSET + ISPOINTER: IF OS_BITS = 32 THEN OFFSETTYPE = 32& + ISOFFSET + ISPOINTER
UOFFSETTYPE = 64& + ISOFFSET + ISUNSIGNED + ISPOINTER: IF OS_BITS = 32 THEN UOFFSETTYPE = 32& + ISOFFSET + ISUNSIGNED + ISPOINTER
UDTTYPE = ISUDT + ISPOINTER






DIM SHARED statementn AS LONG





DIM controllevel AS INTEGER '0=not in a control block
DIM controltype(1000) AS INTEGER
'1=IF (awaiting END IF)
'2=FOR (awaiting NEXT)
'3=DO (awaiting LOOP [UNTIL|WHILE param])
'4=DO WHILE/UNTIL (awaiting LOOP)
'5=WHILE (awaiting WEND)
'10=SELECT CASE qbs (awaiting END SELECT/CASE)
'11=SELECT CASE int64 (awaiting END SELECT/CASE)
'12=SELECT CASE uint64 (awaiting END SELECT/CASE)
'13=SELECT CASE LONG double (awaiting END SELECT/CASE/CASE ELSE)
'14=SELECT CASE float ...
'15=SELECT CASE double
'16=SELECT CASE int32
'17=SELECT CASE uint32
'18=CASE (awaiting END SELECT/CASE/CASE ELSE)
'19=CASE ELSE (awaiting END SELECT)
DIM controlid(1000) AS LONG
DIM controlvalue(1000) AS LONG
DIM controlstate(1000) AS INTEGER
DIM controlref(1000) AS LONG 'the line number the control was created on





ON ERROR GOTO qberror

i2&& = 1
FOR i&& = 1 TO 56
    bitmask(i&&) = i2&&
    bitmaskinv(i&&) = NOT i2&&
    i2&& = i2&& + 2 ^ i&&
NEXT

DIM id2 AS idstruct

cleanupstringprocessingcall$ = "qbs_cleanup(qbs_tmp_base,"

DIM SHARED sfidlist(1000) AS LONG
DIM SHARED sfarglist(1000) AS INTEGER
DIM SHARED sfelelist(1000) AS INTEGER















'----------------ripgl.bas--------------------------------------------------------------------------------
gl_scan_header
'----------------ripgl.bas--------------------------------------------------------------------------------







'-----------------------QB64 COMPILER ONCE ONLY SETUP CODE ENDS HERE---------------------------------------

IF NoIDEMode THEN GOTO noide
idemode = 1
sendc$ = "" 'no initial message
IF CMDLineFile <> "" THEN sendc$ = CHR$(1) + CMDLineFile
sendcommand:
idecommand$ = sendc$
C = ide(0)
ideerror = 0
IF C = 0 THEN idemode = 0: GOTO noide
c$ = idereturn$

IF C = 2 THEN 'begin
    ideerrorline = 0 'addresses invalid prepass error line numbers being reported
    idepass = 1
    GOTO fullrecompile
    ideret1:
    wholeline$ = c$
    GOTO ideprepass
    ideret2:
    sendc$ = CHR$(3) 'request next line
    GOTO sendcommand
END IF

IF C = 4 THEN 'next line
    IF idepass = 1 THEN
        wholeline$ = c$
        GOTO ideprepass
        '(returns to ideret2: above)
    END IF
    'assume idepass>1
    a3$ = c$
    continuelinefrom = 0
    GOTO ide4
    ideret4:
    sendc$ = CHR$(3) 'request next line
    GOTO sendcommand
END IF

IF C = 5 THEN 'end of program reached
    IF idepass = 1 THEN
        'prepass complete
        idepass = 2
        GOTO ide3
        ideret3:
        sendc$ = CHR$(7) 'repass request
        GOTO sendcommand
    END IF
    'assume idepass=2
    'finalize program
    GOTO ide5
    ideret5: 'note: won't return here if a recompile was required!
    sendc$ = CHR$(6) 'ready
    idecompiled = 0
    GOTO sendcommand
END IF

IF C = 9 THEN 'run

    IF idecompiled = 0 THEN 'exe needs to be compiled
        file$ = c$

        'locate accessible file and truncate
        f$ = file$
        i = 1
        nextexeindex:
        IF _FILEEXISTS(file$ + extension$) THEN
            E = 0
            ON ERROR GOTO qberror_test
            KILL file$ + extension$
            ON ERROR GOTO qberror
            IF E = 1 THEN
                i = i + 1
                file$ = f$ + "(" + str2$(i) + ")"
                GOTO nextexeindex
            END IF
        END IF

        'inform IDE of name change if necessary (IDE will respond with message 9 and corrected name)
        IF i <> 1 THEN
            sendc$ = CHR$(12) + file$
            GOTO sendcommand
        END IF

        ideerrorline = 0 'addresses C++ comp. error's line number
        GOTO ide6
        ideret6:
        idecompiled = 1
    END IF


    IF MakeAndroid THEN


        'generate program name


        pf$ = "programs\android\" + file$

        IF _DIREXISTS(pf$) = 0 THEN
            'once only setup

            COLOR 7, 1: LOCATE idewy - 3, 2: PRINT SPACE$(idewx - 2);: LOCATE idewy - 2, 2: PRINT SPACE$(idewx - 2);: LOCATE idewy - 1, 2: PRINT SPACE$(idewx - 2); 'clear status window
            LOCATE idewy - 3, 2: PRINT "Initializing project [programs\android\" + file$ + "]...";
            PCOPY 3, 0


            MKDIR pf$
            SHELL _HIDE "cmd /c xcopy /e programs\android\project_template\*.* " + pf$
            SHELL _HIDE "cmd /c xcopy /e programs\android\eclipse_template\*.* " + pf$

            'modify templates
            fr_fh = FREEFILE
            OPEN pf$ + "\AndroidManifest.xml" FOR BINARY AS #fr_fh
            a$ = SPACE$(LOF(fr_fh))
            GET #fr_fh, , a$
            CLOSE fr_fh
            OPEN pf$ + "\AndroidManifest.xml" FOR OUTPUT AS #fr_fh
            ss$ = CHR$(34) + "com.example.native_activity" + CHR$(34)
            file_namespace$ = LCASE$(file$)
            a = ASC(file_namespace$)
            IF a >= 48 AND a <= 57 THEN file_namespace$ = "ns_" + file_namespace$
            i = INSTR(a$, ss$)
            a$ = LEFT$(a$, i - 1) + CHR$(34) + "com.example." + file_namespace$ + CHR$(34) + RIGHT$(a$, LEN(a$) - i - LEN(ss$) + 1)
            PRINT #fr_fh, a$;
            CLOSE fr_fh

            fr_fh = FREEFILE
            OPEN pf$ + "\res\values\strings.xml" FOR BINARY AS #fr_fh
            a$ = SPACE$(LOF(fr_fh))
            GET #fr_fh, , a$
            CLOSE fr_fh
            OPEN pf$ + "\res\values\strings.xml" FOR OUTPUT AS #fr_fh
            ss$ = ">NativeActivity<"
            i = INSTR(a$, ss$)
            a$ = LEFT$(a$, i - 1) + ">" + file$ + "<" + RIGHT$(a$, LEN(a$) - i - LEN(ss$) + 1)
            PRINT #fr_fh, a$;
            CLOSE fr_fh

            fr_fh = FREEFILE
            OPEN pf$ + "\.project" FOR BINARY AS #fr_fh
            a$ = SPACE$(LOF(fr_fh))
            GET #fr_fh, , a$
            CLOSE fr_fh
            OPEN pf$ + "\.project" FOR OUTPUT AS #fr_fh
            ss$ = "<name>NativeActivity</name>"
            i = INSTR(a$, ss$)
            a$ = LEFT$(a$, i - 1) + "<name>" + file$ + "</name>" + RIGHT$(a$, LEN(a$) - i - LEN(ss$) + 1)
            PRINT #fr_fh, a$;
            CLOSE fr_fh

            IF _DIREXISTS(pf$ + "\jni\temp") = 0 THEN MKDIR pf$ + "\jni\temp"

            IF _DIREXISTS(pf$ + "\jni\c") = 0 THEN MKDIR pf$ + "\jni\c"

            'c
            ex_fh = FREEFILE
            OPEN "internal\temp\xcopy_exclude.txt" FOR OUTPUT AS #ex_fh
            PRINT #ex_fh, "c_compiler\"
            CLOSE ex_fh
            SHELL _HIDE "cmd /c xcopy /e /EXCLUDE:internal\temp\xcopy_exclude.txt internal\c\*.* " + pf$ + "\jni\c"

        ELSE

            COLOR 7, 1: LOCATE idewy - 3, 2: PRINT SPACE$(idewx - 2);: LOCATE idewy - 2, 2: PRINT SPACE$(idewx - 2);: LOCATE idewy - 1, 2: PRINT SPACE$(idewx - 2); 'clear status window
            LOCATE idewy - 3, 2: PRINT "Updating project [programs\android\" + file$ + "]...";
            PCOPY 3, 0

        END IF

        'temp
        SHELL _HIDE "cmd /c del " + pf$ + "\jni\temp\*.txt"
        SHELL _HIDE "cmd /c copy " + tmpdir$ + "*.txt " + pf$ + "\jni\temp"

        'touch main.cpp (for ndk)
        fr_fh = FREEFILE
        OPEN pf$ + "\jni\main.cpp" FOR BINARY AS #fr_fh
        a$ = SPACE$(LOF(fr_fh))
        GET #fr_fh, , a$
        CLOSE fr_fh
        OPEN pf$ + "\jni\main.cpp" FOR OUTPUT AS #fr_fh
        IF ASC(a$, LEN(a$)) <> 32 THEN a$ = a$ + " " ELSE a$ = LEFT$(a$, LEN(a$) - 1)
        PRINT #fr_fh, a$;
        CLOSE fr_fh

        'note: .bat files affect the directory they are called from
        CHDIR pf$
        IF INSTR(IdeAndroidStartScript$, ":") THEN
            SHELL _HIDE IdeAndroidMakeScript$
        ELSE
            SHELL _HIDE "..\..\..\" + IdeAndroidMakeScript$
        END IF
        CHDIR "..\..\.."

        ''touch manifest (for Eclipse)
        'fr_fh = FREEFILE
        'OPEN pf$ + "\AndroidManifest.xml" FOR BINARY AS #fr_fh
        'a$ = SPACE$(LOF(fr_fh))
        'GET #fr_fh, , a$
        'CLOSE fr_fh
        'OPEN pf$ + "\AndroidManifest.xml" FOR OUTPUT AS #fr_fh
        'IF ASC(a$, LEN(a$)) <> 32 THEN a$ = a$ + " " ELSE a$ = LEFT$(a$, LEN(a$) - 1)
        'PRINT #fr_fh, a$;
        'CLOSE fr_fh
        '^^^^above inconsistent^^^^

        'clear the gen folder (for Eclipse)
        IF _DIREXISTS(pf$ + "\gen") THEN
            SHELL _HIDE "cmd /c rmdir /s /q " + pf$ + "\gen"
            SHELL _HIDE "cmd /c md " + pf$ + "\gen"
        END IF

        sendc$ = CHR$(11) '".EXE file created" aka "Android project created"
        GOTO sendcommand

    END IF


    IF iderunmode = 2 THEN
        sendc$ = CHR$(11) '.EXE file created
        GOTO sendcommand
    END IF

    'hack! (a new message should be sent to the IDE stating C++ compilation was successful)
    COLOR 7, 1: LOCATE idewy - 3, 2: PRINT SPACE$(idewx - 2);: LOCATE idewy - 2, 2: PRINT SPACE$(idewx - 2);: LOCATE idewy - 1, 2: PRINT SPACE$(idewx - 2); 'clear status window
    LOCATE idewy - 3, 2: PRINT "Starting program...";
    PCOPY 3, 0

    'execute program

    IF iderunmode = 1 THEN
        IF os$ = "WIN" THEN SHELL _DONTWAIT QuotedFilename$(CHR$(34) + file$ + extension$ + CHR$(34))
        IF os$ = "LNX" THEN SHELL _DONTWAIT QuotedFilename$("./" + file$ + extension$)
    ELSE
        IF os$ = "WIN" THEN SHELL QuotedFilename$(CHR$(34) + file$ + extension$ + CHR$(34))
        IF os$ = "LNX" THEN SHELL QuotedFilename$("./" + file$ + extension$)
    END IF

    sendc$ = CHR$(6) 'ready
    GOTO sendcommand
END IF

PRINT "Invalid IDE message": END

ideerror:
sendc$ = CHR$(8) + idemessage$ + MKL$(ideerrorline)
GOTO sendcommand


noide:
PRINT "QB64 COMPILER V" + Version$

IF CMDLineFile = "" THEN
    LINE INPUT ; "COMPILE (.bas)>", f$
ELSE
    f$ = CMDLineFile
END IF

f$ = LTRIM$(RTRIM$(f$))

IF FileHasExtension(f$) = 0 THEN f$ = f$ + ".bas"

sourcefile$ = f$
'derive name from sourcefile
f$ = RemoveFileExtension$(f$)

FOR x = LEN(f$) TO 1 STEP -1
    a$ = MID$(f$, x, 1)
    IF a$ = "/" OR a$ = "\" THEN
        f$ = RIGHT$(f$, LEN(f$) - x)
        EXIT FOR
    END IF
NEXT
file$ = f$

'if cmemlist(currentid+1)<>0 before calling regid the variable
'MUST be defined in cmem!

fullrecompile:

BU_DEPENDENCY_CONSOLE_ONLY = DEPENDENCY(DEPENDENCY_CONSOLE_ONLY)
FOR i = 1 TO UBOUND(Dependency): DEPENDENCY(i) = 0: NEXT
DEPENDENCY(DEPENDENCY_CONSOLE_ONLY) = BU_DEPENDENCY_CONSOLE_ONLY AND 2 'Restore -g switch if used

Error_Happened = 0

FOR closeall = 1 TO 255: CLOSE closeall: NEXT

OPEN tmpdir$ + "temp.bin" FOR OUTPUT LOCK WRITE AS #26 'relock

fh = FREEFILE: OPEN tmpdir$ + "dyninfo.txt" FOR OUTPUT AS #fh: CLOSE #fh

IF Debug THEN CLOSE #9: OPEN tmpdir$ + "debug.txt" FOR OUTPUT AS #9


FOR i = 1 TO ids_max + 1
    arrayelementslist(i) = 0
    cmemlist(i) = 0
    sfcmemargs(i) = ""
NEXT


'erase cmemlist
'erase sfcmemargs

lastunresolved = -1 'first pass
sflistn = -1 'no entries

SubNameLabels = sp 'QB64 will perform a repass to resolve sub names used as labels

recompile:

Resize = 0
Resize_Scale = 0

UseGL = 0

Error_Happened = 0

HashClear 'clear the hash table

'add reserved words to hashtable

f = HASHFLAG_TYPE + HASHFLAG_RESERVED
HashAdd "_UNSIGNED", f, 0
HashAdd "_BIT", f, 0
HashAdd "_BYTE", f, 0
HashAdd "INTEGER", f, 0
HashAdd "LONG", f, 0
HashAdd "_INTEGER64", f, 0
HashAdd "_OFFSET", f, 0
HashAdd "SINGLE", f, 0
HashAdd "DOUBLE", f, 0
HashAdd "_FLOAT", f, 0
HashAdd "STRING", f, 0
HashAdd "ANY", f, 0

f = HASHFLAG_OPERATOR + HASHFLAG_RESERVED
HashAdd "NOT", f, 0
HashAdd "IMP", f, 0
HashAdd "EQV", f, 0
HashAdd "AND", f, 0
HashAdd "OR", f, 0
HashAdd "XOR", f, 0
HashAdd "MOD", f, 0

f = HASHFLAG_RESERVED + HASHFLAG_CUSTOMSYNTAX
HashAdd "LIST", f, 0
HashAdd "BASE", f, 0
HashAdd "AS", f, 0
HashAdd "IS", f, 0
HashAdd "OFF", f, 0
HashAdd "ON", f, 0
HashAdd "STOP", f, 0
HashAdd "TO", f, 0
HashAdd "USING", f, 0
'PUT(graphics) statement:
HashAdd "PRESET", f, 0
HashAdd "PSET", f, 0
'OPEN statement:
HashAdd "FOR", f, 0
HashAdd "OUTPUT", f, 0
HashAdd "RANDOM", f, 0
HashAdd "BINARY", f, 0
HashAdd "APPEND", f, 0
HashAdd "SHARED", f, 0
HashAdd "ACCESS", f, 0
HashAdd "LOCK", f, 0
HashAdd "READ", f, 0
HashAdd "WRITE", f, 0
'LINE statement:
HashAdd "STEP", f, 0
'WIDTH statement:
HashAdd "LPRINT", f, 0
'VIEW statement:
HashAdd "PRINT", f, 0

f = HASHFLAG_RESERVED + HASHFLAG_XELEMENTNAME + HASHFLAG_XTYPENAME
'A
'B
'C
HashAdd "COMMON", f, 0
HashAdd "CALL", f, 0
HashAdd "CASE", f - HASHFLAG_XELEMENTNAME, 0
HashAdd "COM", f, 0 '(ON...)
HashAdd "CONST", f, 0
'D
HashAdd "DATA", f, 0
HashAdd "DECLARE", f, 0
HashAdd "DEF", f, 0
HashAdd "DEFDBL", f, 0
HashAdd "DEFINT", f, 0
HashAdd "DEFLNG", f, 0
HashAdd "DEFSNG", f, 0
HashAdd "DEFSTR", f, 0
HashAdd "DIM", f, 0
HashAdd "DO", f - HASHFLAG_XELEMENTNAME, 0
'E
HashAdd "ERROR", f - HASHFLAG_XELEMENTNAME, 0 '(ON ...)
HashAdd "ELSE", f, 0
HashAdd "ELSEIF", f, 0
HashAdd "EXIT", f - HASHFLAG_XELEMENTNAME, 0
'F
HashAdd "FIELD", f - HASHFLAG_XELEMENTNAME, 0
HashAdd "FUNCTION", f, 0
'G
HashAdd "GOSUB", f, 0
HashAdd "GOTO", f, 0
'H
'I
HashAdd "INPUT", f - HASHFLAG_XELEMENTNAME - HASHFLAG_XTYPENAME, 0 '(INPUT$ function exists, so conflicts if allowed as custom syntax)
HashAdd "IF", f, 0
'K
HashAdd "KEY", f - HASHFLAG_XELEMENTNAME - HASHFLAG_XTYPENAME, 0 '(ON...)
'L
HashAdd "LET", f - HASHFLAG_XELEMENTNAME, 0
HashAdd "LOOP", f - HASHFLAG_XELEMENTNAME, 0
HashAdd "LEN", f - HASHFLAG_XELEMENTNAME, 0 '(LEN function exists, so conflicts if allowed as custom syntax)
'M
'N
HashAdd "NEXT", f - HASHFLAG_XELEMENTNAME, 0
'O
'P
HashAdd "PLAY", f - HASHFLAG_XELEMENTNAME - HASHFLAG_XTYPENAME, 0 '(ON...)
HashAdd "PEN", f - HASHFLAG_XELEMENTNAME - HASHFLAG_XTYPENAME, 0 '(ON...)
'Q
'R
HashAdd "REDIM", f, 0
HashAdd "REM", f, 0
HashAdd "RESTORE", f - HASHFLAG_XELEMENTNAME, 0
HashAdd "RESUME", f - HASHFLAG_XELEMENTNAME, 0
HashAdd "RETURN", f - HASHFLAG_XELEMENTNAME, 0
HashAdd "RUN", f - HASHFLAG_XELEMENTNAME, 0
'S
HashAdd "STATIC", f, 0
HashAdd "STRIG", f, 0 '(ON...)
HashAdd "SEG", f, 0
HashAdd "SELECT", f - HASHFLAG_XELEMENTNAME - HASHFLAG_XTYPENAME, 0
HashAdd "SUB", f, 0
HashAdd "SCREEN", f - HASHFLAG_XELEMENTNAME - HASHFLAG_XTYPENAME, 0
'T
HashAdd "THEN", f, 0
HashAdd "TIMER", f - HASHFLAG_XELEMENTNAME - HASHFLAG_XTYPENAME, 0 '(ON...)
HashAdd "TYPE", f - HASHFLAG_XELEMENTNAME, 0
'U
HashAdd "UNTIL", f, 0
HashAdd "UEVENT", f, 0
'V
'W
HashAdd "WEND", f, 0
HashAdd "WHILE", f, 0
'X
'Y
'Z







'clear/init variables
Console = 0
ScreenHide = 0
ResolveStaticFunctions = 0
dynamiclibrary = 0
dimsfarray = 0
dimstatic = 0
AllowLocalName = 0
PossibleSubNameLabels = sp 'QB64 will perform a repass to resolve sub names used as labels
use_global_byte_elements = 0
dimshared = 0: dimmethod = 0: dimoption = 0: redimoption = 0: commonoption = 0
mylib$ = "": mylibopt$ = ""
declaringlibrary = 0
nLabels = 0
dynscope = 0
elsefollowup = 0
ontimerid = 0: onkeyid = 0: onstrigid = 0
commonarraylist = "": commonarraylistn = 0
staticarraylist = "": staticarraylistn = 0
fooindwel = 0
layout = ""
layoutok = 0
NoChecks = 0
inclevel = 0
addmetainclude$ = ""
nextrunlineindex = 1
lasttype = 0
lasttypeelement = 0
definingtype = 0
constlast = -1
'constlastshared = -1
defdatahandle = 18
closedmain = 0
addmetastatic = 0
addmetadynamic = 0
DynamicMode = 0
optionbase = 0
DataOffset = 0
statementn = 0
qberrorhappened = 0: qberrorcode = 0: qberrorline = 0
FOR i = 1 TO 27: defineaz(i) = "SINGLE": defineextaz(i) = "!": NEXT
controllevel = 0
findidsecondarg$ = "": findanotherid = 0: findidinternal = 0: currentid = 0
linenumber = 0
wholeline$ = ""
linefragment$ = ""
idn = 0
arrayprocessinghappened = 0
stringprocessinghappened = 0
subfuncn = 0
subfunc = ""

''create a type for storing memory blocks
''UDT
''names
'DIM SHARED lasttype AS LONG
'DIM SHARED udtxname(1000) AS STRING * 256
'DIM SHARED udtxcname(1000) AS STRING * 256
'DIM SHARED udtxsize(1000) AS LONG
'DIM SHARED udtxbytealign(1000) AS INTEGER 'first element MUST be on a byte alignment & size is a multiple of 8
'DIM SHARED udtxnext(1000) AS LONG
''elements
'DIM SHARED lasttypeelement AS LONG
'DIM SHARED udtename(1000) AS STRING * 256
'DIM SHARED udtecname(1000) AS STRING * 256
'DIM SHARED udtebytealign(1000) AS INTEGER
'DIM SHARED udtesize(1000) AS LONG
'DIM SHARED udtetype(1000) AS LONG
'DIM SHARED udtetypesize(1000) AS LONG
'DIM SHARED udtearrayelements(1000) AS LONG
'DIM SHARED udtenext(1000) AS LONG

'import _MEM type
ptrsz = OS_BITS \ 8

IF Cloud = 0 THEN
    lasttype = lasttype + 1: i = lasttype
    udtxname(i) = "_MEM"
    udtxcname(i) = "_MEM"
    udtxsize(i) = ((ptrsz) * 4 + (4) * 2 + (8) * 1) * 8
    udtxbytealign(i) = 1
    lasttypeelement = lasttypeelement + 1: i2 = lasttypeelement
    udtename(i2) = "OFFSET"
    udtecname(i2) = "OFFSET"
    udtebytealign(i2) = 1
    udtetype(i2) = OFFSETTYPE: udtesize(i2) = ptrsz * 8
    udtetypesize(i2) = 0 'tsize
    udtxnext(i) = i2
    i3 = i2
    lasttypeelement = lasttypeelement + 1: i2 = lasttypeelement
    udtename(i2) = "SIZE"
    udtecname(i2) = "SIZE"
    udtebytealign(i2) = 1
    udtetype(i2) = OFFSETTYPE: udtesize(i2) = ptrsz * 8
    udtetypesize(i2) = 0 'tsize
    udtenext(i3) = i2
    i3 = i2
    lasttypeelement = lasttypeelement + 1: i2 = lasttypeelement
    udtename(i2) = "$_LOCK_ID"
    udtecname(i2) = "$_LOCK_ID"
    udtebytealign(i2) = 1
    udtetype(i2) = INTEGER64TYPE: udtesize(i2) = 64
    udtetypesize(i2) = 0 'tsize
    udtenext(i3) = i2
    i3 = i2
    lasttypeelement = lasttypeelement + 1: i2 = lasttypeelement
    udtename(i2) = "$_LOCK_OFFSET"
    udtecname(i2) = "$_LOCK_OFFSET"
    udtebytealign(i2) = 1
    udtetype(i2) = OFFSETTYPE: udtesize(i2) = ptrsz * 8
    udtetypesize(i2) = 0 'tsize
    udtenext(i3) = i2
    i3 = i2
    lasttypeelement = lasttypeelement + 1: i2 = lasttypeelement
    udtename(i2) = "TYPE"
    udtecname(i2) = "TYPE"
    udtebytealign(i2) = 1
    udtetype(i2) = LONGTYPE: udtesize(i2) = 32
    udtetypesize(i2) = 0 'tsize
    udtenext(i3) = i2
    i3 = i2
    lasttypeelement = lasttypeelement + 1: i2 = lasttypeelement
    udtename(i2) = "ELEMENTSIZE"
    udtecname(i2) = "ELEMENTSIZE"
    udtebytealign(i2) = 1
    udtetype(i2) = OFFSETTYPE: udtesize(i2) = ptrsz * 8
    udtetypesize(i2) = 0 'tsize
    udtenext(i3) = i2
    udtenext(i2) = 0
    i3 = i2
    lasttypeelement = lasttypeelement + 1: i2 = lasttypeelement
    udtename(i2) = "IMAGE"
    udtecname(i2) = "IMAGE"
    udtebytealign(i2) = 1
    udtetype(i2) = LONGTYPE: udtesize(i2) = 32
    udtetypesize(i2) = 0 'tsize
    udtenext(i3) = i2
    udtenext(i2) = 0


END IF 'cloud = 0










'begin compilation
FOR closeall = 1 TO 255: CLOSE closeall: NEXT
OPEN tmpdir$ + "temp.bin" FOR OUTPUT LOCK WRITE AS #26 'relock


IF Debug THEN CLOSE #9: OPEN tmpdir$ + "debug.txt" FOR APPEND AS #9

IF idemode = 0 THEN
    qberrorhappened = -1
    OPEN sourcefile$ FOR INPUT AS #1
    qberrorhappened1:
    IF qberrorhappened = 1 THEN
        PRINT
        PRINT "CANNOT LOCATE SOURCE FILE:" + sourcefile$
        IF ConsoleMode THEN SYSTEM 1
        END 1
    ELSE
        CLOSE #1
    END IF
    qberrorhappened = 0
END IF

reginternal


OPEN tmpdir$ + "global.txt" FOR OUTPUT AS #18
IF Cloud THEN PRINT #18, "int32 cloud_app=1;" ELSE PRINT #18, "int32 cloud_app=0;"

IF iderecompile THEN
    iderecompile = 0
    idepass = 1 'prepass must be done again
    sendc$ = CHR$(7) 'repass request
    GOTO sendcommand
END IF

IF idemode THEN GOTO ideret1

lineinput3load sourcefile$

DO

    stevewashere: '### STEVE EDIT FOR CONST EXPANSION 10/11/2013

    wholeline$ = lineinput3$
    IF wholeline$ = CHR$(13) THEN EXIT DO
    ideprepass:

    wholestv$ = wholeline$ '### STEVE EDIT FOR CONST EXPANSION 10/11/2013

    prepass = 1
    layout = ""
    layoutok = 0

    linenumber = linenumber + 1
    IF LEN(wholeline$) THEN

        wholeline$ = lineformat(wholeline$)
        IF Error_Happened THEN GOTO errmes

        cwholeline$ = wholeline$
        wholeline$ = eleucase$(wholeline$) '********REMOVE THIS LINE LATER********


        addmetadynamic = 0: addmetastatic = 0
        wholelinen = numelements(wholeline$)

        IF wholelinen THEN

            wholelinei = 1

            'skip line number?
            e$ = getelement$(wholeline$, 1)
            IF (ASC(e$) >= 48 AND ASC(e$) <= 59) OR ASC(e$) = 46 THEN wholelinei = 2: GOTO ppskpl

            'skip 'POSSIBLE' line label?
            IF wholelinen >= 2 THEN
                x2 = INSTR(wholeline$, sp + ":" + sp): x3 = x2 + 2
                IF x2 = 0 THEN
                    IF RIGHT$(wholeline$, 2) = sp + ":" THEN x2 = LEN(wholeline$) - 1: x3 = x2 + 1
                END IF

                IF x2 THEN
                    e$ = LEFT$(wholeline$, x2 - 1)
                    IF validlabel(e$) THEN
                        wholeline$ = RIGHT$(wholeline$, LEN(wholeline$) - x3)
                        cwholeline$ = RIGHT$(cwholeline$, LEN(wholeline$) - x3)
                        wholelinen = numelements(wholeline$)
                        GOTO ppskpl
                    END IF 'valid
                END IF 'includes ":"
            END IF 'wholelinen>=2

            ppskpl:
            IF wholelinei <= wholelinen THEN
                '----------------------------------------
                a$ = ""
                ca$ = ""
                ppblda:
                e$ = getelement$(wholeline$, wholelinei)
                ce$ = getelement$(cwholeline$, wholelinei)
                IF e$ = ":" OR e$ = "ELSE" OR e$ = "THEN" OR e$ = "" THEN
                    IF LEN(a$) THEN
                        IF Debug THEN PRINT #9, "PP[" + a$ + "]"
                        n = numelements(a$)
                        firstelement$ = getelement(a$, 1)
                        secondelement$ = getelement(a$, 2)
                        thirdelement$ = getelement(a$, 3)
                        '========================================

                        'declare library
                        IF declaringlibrary THEN

                            IF firstelement$ = "END" THEN
                                IF n <> 2 OR secondelement$ <> "DECLARE" THEN a$ = "Expected END DECLARE": GOTO errmes
                                declaringlibrary = 0
                                GOTO finishedlinepp
                            END IF 'end declare

                            declaringlibrary = 2

                            IF firstelement$ = "SUB" OR firstelement$ = "FUNCTION" THEN subfuncn = subfuncn - 1: GOTO declaresubfunc

                            a$ = "Expected SUB/FUNCTION definition or END DECLARE (#2)": GOTO errmes
                        END IF

                        'UDT TYPE definition
                        IF definingtype THEN
                            i = definingtype

                            IF n >= 1 THEN
                                IF firstelement$ = "END" THEN
                                    IF n <> 2 OR secondelement$ <> "TYPE" THEN a$ = "Expected END TYPE": GOTO errmes
                                    IF udtxnext(i) = 0 THEN a$ = "No elements defined in TYPE": GOTO errmes
                                    definingtype = 0

                                    'create global buffer for SWAP space
                                    siz$ = str2$(udtxsize(i) \ 8)
                                    PRINT #18, "char *g_tmp_udt_" + RTRIM$(udtxname(i)) + "=(char*)malloc(" + siz$ + ");"

                                    'print "END TYPE";udtxsize(i);udtxbytealign(i)
                                    GOTO finishedlinepp
                                END IF
                            END IF

                            lasttypeelement = lasttypeelement + 1
                            i2 = lasttypeelement
                            udtenext(i2) = 0

                            IF n < 3 THEN a$ = "Expected variablename AS type or END TYPE": GOTO errmes
                            n$ = firstelement$

                            ii = 2

                            udtearrayelements(i2) = 0

                            IF ii >= n OR getelement$(a$, ii) <> "AS" THEN a$ = "Expected variablename AS type or END TYPE": GOTO errmes
                            t$ = getelements$(a$, ii + 1, n)

                            typ = typname2typ(t$)
                            IF Error_Happened THEN GOTO errmes
                            IF typ = 0 THEN a$ = "Undefined type": GOTO errmes
                            typsize = typname2typsize

                            IF validname(n$) = 0 THEN a$ = "Invalid name": GOTO errmes
                            udtename(i2) = n$

                            udtecname(i2) = getelement$(ca$, 1)
                            udtetype(i2) = typ
                            udtetypesize(i2) = typsize

                            hashname$ = n$

                            'check for name conflicts (any similar reserved or element from current UDT)
                            hashchkflags = HASHFLAG_RESERVED + HASHFLAG_UDTELEMENT
                            hashres = HashFind(hashname$, hashchkflags, hashresflags, hashresref)
                            DO WHILE hashres
                                IF hashresflags AND HASHFLAG_UDTELEMENT THEN
                                    IF hashresref = i THEN a$ = "Name already in use": GOTO errmes
                                END IF
                                IF hashresflags AND HASHFLAG_RESERVED THEN
                                    IF hashresflags AND (HASHFLAG_TYPE + HASHFLAG_CUSTOMSYNTAX + HASHFLAG_OPERATOR + HASHFLAG_XELEMENTNAME) THEN a$ = "Name already in use": GOTO errmes
                                END IF
                                IF hashres <> 1 THEN hashres = HashFindCont(hashresflags, hashresref) ELSE hashres = 0
                            LOOP
                            'add to hash table
                            HashAdd hashname$, HASHFLAG_UDTELEMENT, i

                            'Calculate element's size
                            IF typ AND ISUDT THEN
                                u = typ AND 511
                                udtesize(i2) = udtxsize(u)
                                IF udtxbytealign(u) THEN udtxbytealign(i) = 1: udtebytealign(i2) = 1
                            ELSE
                                IF (typ AND ISSTRING) THEN
                                    IF (typ AND ISFIXEDLENGTH) = 0 THEN a$ = "Expected STRING *": GOTO errmes
                                    udtesize(i2) = typsize * 8
                                    udtxbytealign(i) = 1: udtebytealign(i2) = 1
                                ELSE
                                    udtesize(i2) = typ AND 511
                                    IF (typ AND ISOFFSETINBITS) = 0 THEN udtxbytealign(i) = 1: udtebytealign(i2) = 1
                                END IF
                            END IF

                            'Increase block size
                            IF udtebytealign(i2) THEN
                                IF udtxsize(i) MOD 8 THEN
                                    udtxsize(i) = udtxsize(i) + (8 - (udtxsize(i) MOD 8))
                                END IF
                            END IF
                            udtxsize(i) = udtxsize(i) + udtesize(i2)

                            'Link element to previous element
                            IF udtxnext(i) = 0 THEN
                                udtxnext(i) = i2
                            ELSE
                                udtenext(i2 - 1) = i2
                            END IF

                            'print "+"+rtrim$(udtename(i2));udtesize(i2);udtebytealign(i2);udtxsize(i)

                            GOTO finishedlinepp

                        END IF 'definingtype

                        IF definingtype AND n >= 1 THEN a$ = "Expected END TYPE": GOTO errmes

                        IF n >= 1 THEN
                            IF firstelement$ = "TYPE" THEN
                                IF n <> 2 THEN a$ = "Expected TYPE typename": GOTO errmes
                                lasttype = lasttype + 1
                                definingtype = lasttype
                                i = definingtype
                                IF validname(secondelement$) = 0 THEN a$ = "Invalid name": GOTO errmes
                                udtxname(i) = secondelement$
                                udtxcname(i) = getelement(ca$, 2)
                                udtxnext(i) = 0
                                udtxsize(i) = 0

                                hashname$ = secondelement$
                                hashflags = HASHFLAG_UDT
                                'check for name conflicts (any similar reserved/sub/function/UDT name)
                                hashchkflags = HASHFLAG_RESERVED + HASHFLAG_SUB + HASHFLAG_FUNCTION + HASHFLAG_UDT
                                hashres = HashFind(hashname$, hashchkflags, hashresflags, hashresref)
                                DO WHILE hashres
                                    allow = 0
                                    IF hashresflags AND (HASHFLAG_SUB + HASHFLAG_FUNCTION) THEN
                                        allow = 1
                                    END IF
                                    IF hashresflags AND HASHFLAG_RESERVED THEN
                                        IF (hashresflags AND (HASHFLAG_TYPE + HASHFLAG_OPERATOR + HASHFLAG_CUSTOMSYNTAX + HASHFLAG_XTYPENAME)) = 0 THEN allow = 1
                                    END IF
                                    IF allow = 0 THEN a$ = "Name already in use": GOTO errmes
                                    IF hashres <> 1 THEN hashres = HashFindCont(hashresflags, hashresref) ELSE hashres = 0
                                LOOP

                                'add to hash table
                                HashAdd hashname$, hashflags, i

                                GOTO finishedlinepp
                            END IF
                        END IF





                        stevewashere2: ' ### STEVE EDIT ON 10/11/2013 (Const Expansion)


                        IF n >= 1 AND firstelement$ = "CONST" THEN
                            'l$ = "CONST"
                            'DEF... do not change type, the expression is stored in a suitable type
                            'based on its value if type isn't forced/specified





                            'convert periods to _046_
                            i2 = INSTR(a$, sp + "." + sp)
                            IF i2 THEN
                                DO
                                    a$ = LEFT$(a$, i2 - 1) + fix046$ + RIGHT$(a$, LEN(a$) - i2 - 2)
                                    ca$ = LEFT$(ca$, i2 - 1) + fix046$ + RIGHT$(ca$, LEN(ca$) - i2 - 2)
                                    i2 = INSTR(a$, sp + "." + sp)
                                LOOP UNTIL i2 = 0
                                n = numelements(a$)
                                firstelement$ = getelement(a$, 1): secondelement$ = getelement(a$, 2): thirdelement$ = getelement(a$, 3)
                            END IF


                            'Steve Tweak to add _RGB32 and _MATH support to CONST
                            'Our alteration to allow for multiple uses of RGB and RGBA inside a CONST //SMcNeill
                            altered = 0

                            'Edit 02/23/2014 to add space between = and _ for statements like CONST x=_RGB(123,0,0) and stop us from gettting an error.
                            DO
                                l = INSTR(wholestv$, "=_")
                                IF l THEN
                                    wholestv$ = LEFT$(wholestv$, l) + " " + MID$(wholestv$, l + 1)
                                END IF
                            LOOP UNTIL l = 0
                            'End of Edit on 02/23/2014

                            DO
                                finished = -1
                                l = INSTR(l + 1, UCASE$(wholestv$), " _RGBA")
                                IF l > 0 THEN
                                    altered = -1
                                    l$ = LEFT$(wholestv$, l - 1)
                                    vp = INSTR(l, wholestv$, "(")
                                    IF vp > 0 THEN
                                        E = INSTR(vp + 1, wholestv$, ")")
                                        IF E > 0 THEN
                                            'get our 3 colors or 4 if we need RGBA values
                                            first = INSTR(vp, wholestv$, ",")
                                            second = INSTR(first + 1, wholestv$, ",")
                                            third = INSTR(second + 1, wholestv$, ",")
                                            fourth = INSTR(third + 1, wholestv$, ",") 'If we need RGBA we need this one as well
                                            red$ = MID$(wholestv$, vp + 1, first - vp - 1)
                                            green$ = MID$(wholestv$, first + 1, second - first - 1)
                                            blue$ = MID$(wholestv$, second + 1, third - second - 1)
                                            alpha$ = MID$(wholestv$, third + 1)
                                            IF MID$(wholestv$, l + 6, 2) = "32" THEN
                                                val$ = "32"
                                            ELSE
                                                val$ = MID$(wholestv$, fourth + 1)
                                            END IF
                                            SELECT CASE VAL(val$)
                                                CASE 0, 1, 2, 7, 8, 9, 10, 11, 12, 13, 256
                                                    wi& = _NEWIMAGE(240, 120, VAL(val$))
                                                    clr~& = _RGBA(VAL(red$), VAL(green$), VAL(blue$), VAL(alpha$), wi&)
                                                    _FREEIMAGE wi&
                                                CASE 32
                                                    clr~& = _RGBA32(VAL(red$), VAL(green$), VAL(blue$), VAL(alpha$))
                                                CASE ELSE
                                                    a$ = "Invalid Screen Mode.": GOTO errmes
                                            END SELECT

                                            wholestv$ = l$ + STR$(clr~&) + RIGHT$(wholestv$, LEN(wholestv$) - E)
                                            finished = 0
                                        ELSE
                                            'no finishing bracket
                                            a$ = ") Expected": GOTO errmes
                                        END IF
                                    ELSE
                                        'no starting bracket
                                        a$ = "( Expected": GOTO errmes
                                    END IF
                                END IF
                            LOOP UNTIL finished

                            DO
                                finished = -1
                                l = INSTR(l + 1, UCASE$(wholestv$), " _RGB")
                                IF l > 0 THEN
                                    altered = -1
                                    l$ = LEFT$(wholestv$, l - 1)
                                    vp = INSTR(l, wholestv$, "(")
                                    IF vp > 0 THEN
                                        E = INSTR(vp + 1, wholestv$, ")")
                                        IF E > 0 THEN
                                            first = INSTR(vp, wholestv$, ",")
                                            second = INSTR(first + 1, wholestv$, ",")
                                            third = INSTR(second + 1, wholestv$, ",")
                                            red$ = MID$(wholestv$, vp + 1, first - vp - 1)
                                            green$ = MID$(wholestv$, first + 1, second - first - 1)
                                            blue$ = MID$(wholestv$, second + 1)
                                            IF MID$(wholestv$, l + 5, 2) = "32" THEN
                                                val$ = "32"
                                            ELSE
                                                val$ = MID$(wholestv$, third + 1)
                                            END IF

                                            SELECT CASE VAL(val$)
                                                CASE 0, 1, 2, 7, 8, 9, 10, 11, 12, 13, 256
                                                    wi& = _NEWIMAGE(240, 120, VAL(val$))
                                                    clr~& = _RGB(VAL(red$), VAL(green$), VAL(blue$), wi&)
                                                    _FREEIMAGE wi&
                                                CASE 32
                                                    clr~& = _RGB32(VAL(red$), VAL(green$), VAL(blue$))
                                                CASE ELSE
                                                    a$ = "Invalid Screen Mode.": GOTO errmes
                                            END SELECT

                                            wholestv$ = l$ + STR$(clr~&) + RIGHT$(wholestv$, LEN(wholestv$) - E)
                                            finished = 0
                                        ELSE
                                            a$ = ") Expected": GOTO errmes
                                        END IF
                                    ELSE
                                        a$ = "( Expected": GOTO errmes
                                    END IF
                                END IF
                            LOOP UNTIL finished

                            ' ### END OF STEVE EDIT FOR EXPANDED CONST SUPPORT ###

                            'New Edit by Steve on 02/23/2014 to add support for the new Math functions

                            l = 0: Emergency_Exit = 0 'A counter where if we're inside the same DO-Loop for more than 10,000 times, we assume it's an endless loop that didn't process properly and toss out an error message instead of locking up the program.
                            DO
                                l = INSTR(l + 1, wholestv$, "=")
                                IF l THEN
                                    l2 = INSTR(l + 1, wholestv$, ",") 'Look for a comma after that
                                    IF l2 = 0 THEN 'If there's no comma, then we're working to the end of the line
                                        l2 = LEN(wholestv$)
                                    ELSE
                                        l2 = l2 - 1 'else we only want to take what's before that comma and see if we can use it
                                    END IF
                                    temp$ = RTRIM$(LTRIM$(MID$(wholestv$, l + 1, l2 - l)))
                                    temp1$ = RTRIM$(LTRIM$(Evaluate_Expression$(temp$)))
                                    IF LEFT$(temp1$, 5) <> "ERROR" AND temp$ <> temp1$ THEN
                                        'The math routine should have did its replacement for us.
                                        altered = -1
                                        wholestv$ = LEFT$(wholestv$, l) + temp1$ + MID$(wholestv$, l2 + 1)
                                    ELSE
                                        'We should leave it as it is and let the normal CONST routine handle things from here on out and see if it passes the rest of the error checks.
                                    END IF
                                    l = l + 1
                                END IF
                                Emergency_Exit = Emergency_Exit + 1
                                IF Emergency_Exit > 10000 THEN a$ = "CONST ERROR: Attempting to process MATH Function caused Endless Loop.  Please recheck your math formula.": GOTO errmes
                            LOOP UNTIL l = 0
                            'End of Math Support Edit


                            'Steve edit to update the CONST with the Math and _RGB functions
                            IF altered THEN
                                altered = 0
                                wholeline$ = wholestv$
                                linenumber = linenumber - 1
                                GOTO ideprepass
                            END IF
                            'End of Final Edits to CONST




                            IF n < 3 THEN a$ = "Expected CONST name = value/expression": GOTO errmes
                            i = 2
                            constdefpendingpp:
                            pending = 0

                            n$ = getelement$(ca$, i): i = i + 1
                            'l$ = l$ + sp + n$ + sp + "="
                            typeoverride = 0
                            s$ = removesymbol$(n$)
                            IF Error_Happened THEN GOTO errmes
                            IF s$ <> "" THEN
                                typeoverride = typname2typ(s$)
                                IF Error_Happened THEN GOTO errmes
                                IF typeoverride AND ISFIXEDLENGTH THEN a$ = "Invalid constant type": GOTO errmes
                                IF typeoverride = 0 THEN a$ = "Invalid constant type": GOTO errmes
                            END IF

                            IF getelement$(a$, i) <> "=" THEN a$ = "Expected =": GOTO errmes
                            i = i + 1

                            'get expression
                            e$ = ""
                            B = 0
                            FOR i2 = i TO n
                                e2$ = getelement$(ca$, i2)
                                IF e2$ = "(" THEN B = B + 1
                                IF e2$ = ")" THEN B = B - 1
                                IF e2$ = "," AND B = 0 THEN
                                    pending = 1
                                    i = i2 + 1
                                    IF i > n - 2 THEN a$ = "Expected CONST ... , name = value/expression": GOTO errmes
                                    EXIT FOR
                                END IF
                                IF LEN(e$) = 0 THEN e$ = e2$ ELSE e$ = e$ + sp + e2$
                            NEXT

                            e$ = fixoperationorder(e$)
                            IF Error_Happened THEN GOTO errmes
                            'l$ = l$ + sp + tlayout$
                            e$ = evaluateconst(e$, t)
                            IF Error_Happened THEN GOTO errmes

                            IF t AND ISSTRING THEN 'string type

                                IF typeoverride THEN
                                    IF (typeoverride AND ISSTRING) = 0 THEN a$ = "Type mismatch": GOTO errmes
                                END IF

                            ELSE 'not a string type

                                IF typeoverride THEN
                                    IF typeoverride AND ISSTRING THEN a$ = "Type mismatch": GOTO errmes
                                END IF

                                IF t AND ISFLOAT THEN
                                    constval## = _CV(_FLOAT, e$)
                                    constval&& = constval##
                                    constval~&& = constval&&
                                ELSE
                                    IF (t AND ISUNSIGNED) AND (t AND 511) = 64 THEN
                                        constval~&& = _CV(_UNSIGNED _INTEGER64, e$)
                                        constval&& = constval~&&
                                        constval## = constval&&
                                    ELSE
                                        constval&& = _CV(_INTEGER64, e$)
                                        constval## = constval&&
                                        constval~&& = constval&&
                                    END IF
                                END IF

                                'override type?
                                IF typeoverride THEN
                                    'range check required here (noted in todo)
                                    t = typeoverride
                                END IF

                            END IF 'not a string type

                            constlast = constlast + 1
                            IF constlast > constmax THEN
                                constmax = constmax * 2
                                REDIM _PRESERVE constname(constmax) AS STRING
                                REDIM _PRESERVE constcname(constmax) AS STRING
                                REDIM _PRESERVE constnamesymbol(constmax) AS STRING 'optional name symbol
                                REDIM _PRESERVE consttype(constmax) AS LONG 'variable type number
                                REDIM _PRESERVE constinteger(constmax) AS _INTEGER64
                                REDIM _PRESERVE constuinteger(constmax) AS _UNSIGNED _INTEGER64
                                REDIM _PRESERVE constfloat(constmax) AS _FLOAT
                                REDIM _PRESERVE conststring(constmax) AS STRING
                                REDIM _PRESERVE constsubfunc(constmax) AS LONG
                                REDIM _PRESERVE constdefined(constmax) AS LONG
                            END IF

                            i2 = constlast

                            constsubfunc(i2) = subfuncn
                            'IF subfunc = "" THEN constlastshared = i2

                            IF validname(n$) = 0 THEN a$ = "Invalid name": GOTO errmes
                            constname(i2) = UCASE$(n$)

                            hashname$ = n$
                            'check for name conflicts (any similar: reserved, sub, function, constant)

                            allow = 0
                            const_recheck:
                            hashchkflags = HASHFLAG_RESERVED + HASHFLAG_SUB + HASHFLAG_FUNCTION + HASHFLAG_CONSTANT
                            hashres = HashFind(hashname$, hashchkflags, hashresflags, hashresref)
                            DO WHILE hashres
                                IF hashresflags AND HASHFLAG_CONSTANT THEN
                                    IF constsubfunc(hashresref) = subfuncn THEN a$ = "Name already in use": GOTO errmes
                                END IF
                                IF hashresflags AND HASHFLAG_RESERVED THEN
                                    a$ = "Name already in use": GOTO errmes
                                END IF
                                IF hashresflags AND (HASHFLAG_SUB + HASHFLAG_FUNCTION) THEN
                                    IF ids(hashresref).internal_subfunc = 0 OR RTRIM$(ids(hashresref).musthave) <> "$" THEN a$ = "Name already in use": GOTO errmes
                                    IF t AND ISSTRING THEN a$ = "Name already in use": GOTO errmes
                                END IF
                                IF hashres <> 1 THEN hashres = HashFindCont(hashresflags, hashresref) ELSE hashres = 0
                            LOOP

                            'add to hash table
                            HashAdd hashname$, HASHFLAG_CONSTANT, i2





                            constdefined(i2) = 1
                            constcname(i2) = n$
                            constnamesymbol(i2) = typevalue2symbol$(t)
                            IF Error_Happened THEN GOTO errmes
                            consttype(i2) = t
                            IF t AND ISSTRING THEN
                                conststring(i2) = e$
                            ELSE
                                IF t AND ISFLOAT THEN
                                    constfloat(i2) = constval##
                                ELSE
                                    IF t AND ISUNSIGNED THEN
                                        constuinteger(i2) = constval~&&
                                    ELSE
                                        constinteger(i2) = constval&&
                                    END IF
                                END IF
                            END IF

                            IF pending THEN
                                'l$ = l$ + sp2 + ","
                                GOTO constdefpendingpp
                            END IF

                            'layoutdone = 1: IF LEN(layout$) THEN layout$ = layout$ + sp + l$ ELSE layout$ = l$

                            GOTO finishedlinepp
                        END IF



                        'DEFINE
                        d = 0
                        IF firstelement$ = "DEFINT" THEN d = 1
                        IF firstelement$ = "DEFLNG" THEN d = 1
                        IF firstelement$ = "DEFSNG" THEN d = 1
                        IF firstelement$ = "DEFDBL" THEN d = 1
                        IF firstelement$ = "DEFSTR" THEN d = 1
                        IF firstelement$ = "_DEFINE" THEN d = 1
                        IF d THEN
                            predefining = 1: GOTO predefine
                            predefined: predefining = 0
                            GOTO finishedlinepp
                        END IF

                        'declare library
                        IF firstelement$ = "DECLARE" THEN
                            IF secondelement$ = "LIBRARY" OR secondelement$ = "DYNAMIC" OR secondelement$ = "CUSTOMTYPE" OR secondelement$ = "STATIC" THEN
                                IF Cloud THEN a$ = "Feature not supported on QLOUD": GOTO errmes '***NOCLOUD***
                                declaringlibrary = 1
                                indirectlibrary = 0
                                IF secondelement$ = "CUSTOMTYPE" OR secondelement$ = "DYNAMIC" THEN indirectlibrary = 1
                                GOTO finishedlinepp
                            END IF
                        END IF

                        'SUB/FUNCTION
                        dynamiclibrary = 0
                        declaresubfunc:
                        firstelement$ = getelement$(a$, 1)
                        sf = 0
                        IF firstelement$ = "FUNCTION" THEN sf = 1
                        IF firstelement$ = "SUB" THEN sf = 2
                        IF sf THEN

                            subfuncn = subfuncn + 1

                            IF n = 1 THEN a$ = "Expected name after SUB/FUNCTION": GOTO errmes

                            'convert periods to _046_
                            i2 = INSTR(a$, sp + "." + sp)
                            IF i2 THEN
                                DO
                                    a$ = LEFT$(a$, i2 - 1) + fix046$ + RIGHT$(a$, LEN(a$) - i2 - 2)
                                    ca$ = LEFT$(ca$, i2 - 1) + fix046$ + RIGHT$(ca$, LEN(ca$) - i2 - 2)
                                    i2 = INSTR(a$, sp + "." + sp)
                                LOOP UNTIL i2 = 0
                                n = numelements(a$)
                                firstelement$ = getelement(a$, 1): secondelement$ = getelement(a$, 2): thirdelement$ = getelement(a$, 3)
                            END IF

                            n$ = getelement$(ca$, 2)
                            symbol$ = removesymbol$(n$)
                            IF Error_Happened THEN GOTO errmes
                            IF sf = 2 AND symbol$ <> "" THEN a$ = "Type symbols after a SUB name are invalid": GOTO errmes

                            'remove STATIC (which is ignored)
                            e$ = getelement$(a$, n): IF e$ = "STATIC" THEN a$ = LEFT$(a$, LEN(a$) - 7): ca$ = LEFT$(ca$, LEN(ca$) - 7): n = n - 1

                            'check for ALIAS
                            aliasname$ = n$ 'use given name by default
                            IF n > 2 THEN
                                e$ = getelement$(a$, 3)
                                IF e$ = "ALIAS" THEN
                                    IF declaringlibrary = 0 THEN a$ = "ALIAS can only be used with DECLARE LIBRARY": GOTO errmes
                                    IF n = 3 THEN a$ = "Expected ALIAS name-in-library": GOTO errmes
                                    e$ = getelement$(ca$, 4)
                                    'strip string content (optional)
                                    IF LEFT$(e$, 1) = CHR$(34) THEN
                                        e$ = RIGHT$(e$, LEN(e$) - 1)
                                        x = INSTR(e$, CHR$(34)): IF x = 0 THEN a$ = "Expected " + CHR$(34): GOTO errmes
                                        e$ = LEFT$(e$, x - 1)
                                    END IF
                                    'strip fix046$ (created by unquoted periods)
                                    DO WHILE INSTR(e$, fix046$)
                                        x = INSTR(e$, fix046$): e$ = LEFT$(e$, x - 1) + "." + RIGHT$(e$, LEN(e$) - x + 1 - LEN(fix046$))
                                    LOOP
                                    'validate alias name
                                    IF LEN(e$) = 0 THEN a$ = "Expected ALIAS name-in-library": GOTO errmes
                                    FOR x = 1 TO LEN(e$)
                                        a = ASC(e$, x)
                                        IF alphanumeric(a) = 0 AND a <> ASC_FULLSTOP AND a <> ASC_COLON THEN a$ = "Expected ALIAS name-in-library": GOTO errmes
                                    NEXT
                                    aliasname$ = e$
                                    'remove ALIAS section from line
                                    IF n <= 4 THEN a$ = getelements(a$, 1, 2)
                                    IF n >= 5 THEN a$ = getelements(a$, 1, 2) + sp + getelements(a$, 5, n)
                                    IF n <= 4 THEN ca$ = getelements(ca$, 1, 2)
                                    IF n >= 5 THEN ca$ = getelements(ca$, 1, 2) + sp + getelements(ca$, 5, n)
                                    n = n - 2
                                END IF
                            END IF

                            IF declaringlibrary THEN
                                IF indirectlibrary THEN
                                    aliasname$ = n$ 'override the alias name
                                END IF
                            END IF

                            params = 0
                            params$ = ""
                            paramsize$ = ""
                            nele$ = ""
                            nelereq$ = ""
                            IF n > 2 THEN
                                e$ = getelement$(a$, 3)
                                IF e$ <> "(" THEN a$ = "Expected (": GOTO errmes
                                e$ = getelement$(a$, n)
                                IF e$ <> ")" THEN a$ = "Expected )": GOTO errmes
                                IF n < 4 THEN a$ = "Expected ( ... )": GOTO errmes
                                IF n = 4 THEN GOTO nosfparams
                                B = 0
                                a2$ = ""
                                FOR i = 4 TO n - 1
                                    e$ = getelement$(a$, i)
                                    IF e$ = "(" THEN B = B + 1
                                    IF e$ = ")" THEN B = B - 1
                                    IF e$ = "," AND B = 0 THEN
                                        IF i = n - 1 THEN a$ = "Expected , ... )": GOTO errmes
                                        getlastparam:
                                        IF a2$ = "" THEN a$ = "Expected ... ,": GOTO errmes
                                        a2$ = LEFT$(a2$, LEN(a2$) - 1)
                                        'possible format: [BYVAL]a[%][(1)][AS][type]
                                        n2 = numelements(a2$)
                                        array = 0
                                        t2$ = ""

                                        i2 = 1
                                        e$ = getelement$(a2$, i2): i2 = i2 + 1

                                        byvalue = 0
                                        IF e$ = "BYVAL" THEN
                                            IF declaringlibrary = 0 THEN a$ = "BYVAL can currently only be used with DECLARE LIBRARY": GOTO errmes
                                            e$ = getelement$(a2$, i2): i2 = i2 + 1: byvalue = 1
                                        END IF

                                        n2$ = e$
                                        symbol2$ = removesymbol$(n2$)
                                        IF validname(n2$) = 0 THEN a$ = "Invalid name": GOTO errmes

                                        IF Error_Happened THEN GOTO errmes
                                        m = 0
                                        FOR i2 = i2 TO n2
                                            e$ = getelement$(a2$, i2)
                                            IF e$ = "(" THEN
                                                IF m <> 0 THEN a$ = "Syntax error": GOTO errmes
                                                m = 1
                                                array = 1
                                                GOTO gotaa
                                            END IF
                                            IF e$ = ")" THEN
                                                IF m <> 1 THEN a$ = "Syntax error": GOTO errmes
                                                m = 2
                                                GOTO gotaa
                                            END IF
                                            IF e$ = "AS" THEN
                                                IF m <> 0 AND m <> 2 THEN a$ = "Syntax error": GOTO errmes
                                                m = 3
                                                GOTO gotaa
                                            END IF
                                            IF m = 1 THEN GOTO gotaa 'ignore contents of bracket
                                            IF m <> 3 THEN a$ = "Syntax error": GOTO errmes
                                            IF t2$ = "" THEN t2$ = e$ ELSE t2$ = t2$ + " " + e$
                                            gotaa:
                                        NEXT i2

                                        params = params + 1: IF params > 100 THEN a$ = "SUB/FUNCTION exceeds 100 parameter limit": GOTO errmes

                                        argnelereq = 0

                                        IF symbol2$ <> "" AND t2$ <> "" THEN a$ = "Syntax error": GOTO errmes
                                        IF t2$ = "" THEN t2$ = symbol2$
                                        IF t2$ = "" THEN
                                            IF LEFT$(n2$, 1) = "_" THEN v = 27 ELSE v = ASC(UCASE$(n2$)) - 64
                                            t2$ = defineaz(v)
                                        END IF

                                        paramsize = 0
                                        IF array = 1 THEN
                                            t = typname2typ(t2$)
                                            IF Error_Happened THEN GOTO errmes
                                            IF t = 0 THEN a$ = "Illegal SUB/FUNCTION parameter": GOTO errmes
                                            IF (t AND ISFIXEDLENGTH) THEN paramsize = typname2typsize
                                            t = t + ISARRAY
                                            'check for recompilation override
                                            FOR i10 = 0 TO sflistn
                                                IF sfidlist(i10) = idn + 1 THEN
                                                    IF sfarglist(i10) = params THEN
                                                        argnelereq = sfelelist(i10)
                                                    END IF
                                                END IF
                                            NEXT
                                        ELSE
                                            t = typname2typ(t2$)
                                            IF Error_Happened THEN GOTO errmes
                                            IF t = 0 THEN a$ = "Illegal SUB/FUNCTION parameter": GOTO errmes
                                            IF (t AND ISFIXEDLENGTH) THEN paramsize = typname2typsize

                                            IF byvalue THEN
                                                IF t AND ISPOINTER THEN t = t - ISPOINTER
                                            END IF

                                        END IF
                                        nelereq$ = nelereq$ + CHR$(argnelereq)

                                        'consider changing 0 in following line too!
                                        nele$ = nele$ + CHR$(0)

                                        paramsize$ = paramsize$ + MKL$(paramsize)
                                        params$ = params$ + MKL$(t)
                                        a2$ = ""
                                    ELSE
                                        a2$ = a2$ + e$ + sp
                                        IF i = n - 1 THEN GOTO getlastparam
                                    END IF
                                NEXT i
                            END IF 'n>2
                            nosfparams:

                            IF sf = 1 THEN
                                'function
                                clearid
                                id.n = n$
                                id.subfunc = 1

                                id.callname = "FUNC_" + UCASE$(n$)
                                IF declaringlibrary THEN
                                    id.ccall = 1
                                    IF indirectlibrary = 0 THEN id.callname = aliasname$
                                END IF
                                id.args = params
                                id.arg = params$
                                id.argsize = paramsize$
                                id.nele = nele$
                                id.nelereq = nelereq$
                                IF symbol$ <> "" THEN
                                    id.ret = typname2typ(symbol$)
                                    IF Error_Happened THEN GOTO errmes
                                ELSE
                                    IF LEFT$(n$, 1) = "_" THEN v = 27 ELSE v = ASC(UCASE$(n$)) - 64
                                    symbol$ = defineaz(v)
                                    id.ret = typname2typ(symbol$)
                                    IF Error_Happened THEN GOTO errmes
                                END IF
                                IF id.ret = 0 THEN a$ = "Invalid FUNCTION return type": GOTO errmes

                                IF declaringlibrary THEN

                                    ctype$ = typ2ctyp$(id.ret, "")
                                    IF Error_Happened THEN GOTO errmes
                                    IF ctype$ = "qbs" THEN ctype$ = "char*"
                                    id.callname = "(  " + ctype$ + "  )" + RTRIM$(id.callname)

                                END IF

                                s$ = LEFT$(symbol$, 1)
                                IF s$ <> "~" AND s$ <> "`" AND s$ <> "%" AND s$ <> "&" AND s$ <> "!" AND s$ <> "#" AND s$ <> "$" THEN
                                    symbol$ = type2symbol$(symbol$)
                                    IF Error_Happened THEN GOTO errmes
                                END IF
                                id.mayhave = symbol$
                                IF id.ret AND ISPOINTER THEN
                                    IF (id.ret AND ISSTRING) = 0 THEN id.ret = id.ret - ISPOINTER
                                END IF
                                regid
                                IF Error_Happened THEN GOTO errmes
                            ELSE
                                'sub
                                clearid
                                id.n = n$
                                id.subfunc = 2
                                id.callname = "SUB_" + UCASE$(n$)
                                IF declaringlibrary THEN
                                    id.ccall = 1
                                    IF indirectlibrary = 0 THEN id.callname = aliasname$
                                END IF
                                id.args = params
                                id.arg = params$
                                id.argsize = paramsize$
                                id.nele = nele$
                                id.nelereq = nelereq$

                                IF UCASE$(n$) = "_GL" AND params = 0 AND UseGL = 0 THEN reginternalsubfunc = 1: UseGL = 1: id.n = "_GL": DEPENDENCY(DEPENDENCY_GL) = 1
                                regid
                                reginternalsubfunc = 0

                                IF Error_Happened THEN GOTO errmes
                            END IF


                        END IF

                        '========================================
                        finishedlinepp:
                    END IF
                    a$ = ""
                    ca$ = ""
                ELSE
                    IF a$ = "" THEN a$ = e$: ca$ = ce$ ELSE a$ = a$ + sp + e$: ca$ = ca$ + sp + ce$
                END IF
                IF wholelinei <= wholelinen THEN wholelinei = wholelinei + 1: GOTO ppblda
                '----------------------------------------
            END IF 'wholelinei<=wholelinen
        END IF 'wholelinen
    END IF 'len(wholeline$)

    'Include Manager #1



    IF LEN(addmetainclude$) THEN
        IF Debug THEN PRINT #9, "Pre-pass:INCLUDE$-ing file:'" + addmetainclude$ + "':On line"; linenumber
        a$ = addmetainclude$: addmetainclude$ = "" 'read/clear message
        IF inclevel = 100 THEN a$ = "Too many indwelling INCLUDE files": GOTO errmes
        '1. Verify file exists (location is either (a)relative to source file or (b)absolute)
        fh = 99 + inclevel + 1
        FOR try = 1 TO 2
            IF try = 1 THEN
                IF inclevel = 0 THEN
                    IF idemode THEN p$ = idepath$ + pathsep$ ELSE p$ = getfilepath$(sourcefile$)
                ELSE
                    p$ = getfilepath$(incname(inclevel))
                END IF
                f$ = p$ + a$
            END IF
            IF try = 2 THEN f$ = a$
            IF _FILEEXISTS(f$) THEN
                qberrorhappened = -3
                'We're using the faster LINE INPUT, which requires a BINARY open.
                OPEN f$ FOR BINARY AS #fh
                'And another line below edited
                qberrorhappened3:
                IF qberrorhappened = -3 THEN EXIT FOR
            END IF
            qberrorhappened = 0
        NEXT
        IF qberrorhappened <> -3 THEN qberrorhappened = 0: a$ = "File " + a$ + " not found": GOTO errmes
        inclevel = inclevel + 1: incname$(inclevel) = f$: inclinenumber(inclevel) = 0
    END IF 'fall through to next section...
    '--------------------
    DO WHILE inclevel

        fh = 99 + inclevel
        '2. Feed next line
        IF EOF(fh) = 0 THEN
            LINE INPUT #fh, x$
            wholeline$ = x$
            inclinenumber(inclevel) = inclinenumber(inclevel) + 1
            'create extended error string 'incerror$'
            e$ = " in line " + str2(inclinenumber(inclevel)) + " of " + incname$(inclevel) + " included"
            IF inclevel > 1 THEN
                e$ = e$ + " (through "
                FOR x = 1 TO inclevel - 1 STEP 1
                    e$ = e$ + incname$(x)
                    IF x < inclevel - 1 THEN 'a sep is req
                        IF x = inclevel - 2 THEN
                            e$ = e$ + " then "
                        ELSE
                            e$ = e$ + ", "
                        END IF
                    END IF
                NEXT
                e$ = e$ + ")"
            END IF
            incerror$ = e$
            linenumber = linenumber - 1 'lower official linenumber to counter later increment

            IF Debug THEN PRINT #9, "Pre-pass:Feeding INCLUDE$ line:[" + wholeline$ + "]"
            IF idemode THEN sendc$ = CHR$(10) + wholeline$: GOTO sendcommand 'passback
            GOTO ideprepass
        END IF
        '3. Close & return control
        CLOSE #fh
        inclevel = inclevel - 1
    LOOP
    '(end manager)



    IF idemode THEN GOTO ideret2
LOOP
IF definingtype THEN definingtype = 0 'ignore this error so that auto-formatting can be performed and catch it again later
IF declaringlibrary THEN declaringlibrary = 0 'ignore this error so that auto-formatting can be performed and catch it again later

'prepass finished

lineinput3index = 1 'reset input line

'ide specific
ide3:


addmetainclude$ = "" 'reset stray meta-includes

'reset altered variables
DataOffset = 0
inclevel = 0
subfuncn = 0

FOR i = 0 TO constlast: constdefined(i) = 0: NEXT 'undefine constants

FOR i = 1 TO 27: defineaz(i) = "SINGLE": defineextaz(i) = "!": NEXT

OPEN tmpdir$ + "data.bin" FOR OUTPUT AS #16: CLOSE #16
OPEN tmpdir$ + "data.bin" FOR BINARY AS #16


OPEN tmpdir$ + "main.txt" FOR OUTPUT AS #12
OPEN tmpdir$ + "maindata.txt" FOR OUTPUT AS #13

OPEN tmpdir$ + "regsf.txt" FOR OUTPUT AS #17

OPEN tmpdir$ + "mainfree.txt" FOR OUTPUT AS #19
OPEN tmpdir$ + "runline.txt" FOR OUTPUT AS #21

OPEN tmpdir$ + "mainerr.txt" FOR OUTPUT AS #14 'main error handler
'i. check the value of error_line
'ii. jump to the appropriate label
errorlabels = 0
PRINT #14, "if (error_occurred){ error_occurred=0;"

OPEN tmpdir$ + "chain.txt" FOR OUTPUT AS #22: CLOSE #22 'will be appended to as necessary
OPEN tmpdir$ + "inpchain.txt" FOR OUTPUT AS #23: CLOSE #23 'will be appended to as necessary
'*** #22 & #23 are reserved for usage by chain & inpchain ***

OPEN tmpdir$ + "ontimer.txt" FOR OUTPUT AS #24
OPEN tmpdir$ + "ontimerj.txt" FOR OUTPUT AS #25

'*****#26 used for locking qb64

OPEN tmpdir$ + "onkey.txt" FOR OUTPUT AS #27
OPEN tmpdir$ + "onkeyj.txt" FOR OUTPUT AS #28

OPEN tmpdir$ + "onstrig.txt" FOR OUTPUT AS #29
OPEN tmpdir$ + "onstrigj.txt" FOR OUTPUT AS #30

gosubid = 1
'to be included whenever return without a label is called

'return [label] in QBASIC was not possible in a sub/function, but QB64 will support this
'special codes will represent special return conditions:
'0=return from main to calling sub/function/proc by return [NULL];
'1... a global number representing a return point after a gosub
'note: RETURN [label] should fail if a "return [NULL];" type return is required
OPEN tmpdir$ + "ret0.txt" FOR OUTPUT AS #15
PRINT #15, "if (next_return_point){"
PRINT #15, "next_return_point--;"
PRINT #15, "switch(return_point[next_return_point]){"
PRINT #15, "case 0:"

PRINT #15, "return;"

PRINT #15, "break;"

continueline = 0
endifs = 0
lineelseused = 0
continuelinefrom = 0
linenumber = 0
declaringlibrary = 0

PRINT #12, "S_0:;" 'note: REQUIRED by run statement

IF UseGL THEN gl_include_content


'ide specific
IF idemode THEN GOTO ideret3

DO
    ide4:
    includeline:
    prepass = 0

    stringprocessinghappened = 0

    IF continuelinefrom THEN
        start = continuelinefrom
        continuelinefrom = 0
        GOTO contline
    END IF

    'begin a new line

    impliedendif = 0
    THENGOTO = 0
    continueline = 0
    endifs = 0
    lineelseused = 0
    newif = 0

    'apply metacommands from previous line
    IF addmetadynamic = 1 THEN addmetadynamic = 0: DynamicMode = 1
    IF addmetastatic = 1 THEN addmetastatic = 0: DynamicMode = 0

    'a3$ is passed in idemode and when using $include
    IF idemode = 0 AND inclevel = 0 THEN a3$ = lineinput3$
    IF a3$ = CHR$(13) THEN EXIT DO
    linenumber = linenumber + 1

    layout = ""
    layoutok = 1

    IF idemode = 0 THEN
        IF LEN(a3$) THEN
            dotlinecount = dotlinecount + 1: IF dotlinecount >= 100 THEN dotlinecount = 0: PRINT ".";
        END IF
    END IF

    a3$ = LTRIM$(RTRIM$(a3$))
    wholeline = a3$

    layoutoriginal$ = a3$
    layoutcomment$ = "" 'clear any previous layout comment
    lhscontrollevel = controllevel

    linefragment = "[INFORMATION UNAVAILABLE]"
    IF LEN(a3$) = 0 THEN GOTO finishednonexec
    IF Debug THEN PRINT #9, "########" + a3$ + "########"

    layoutdone = 1 'validates layout of any following goto finishednonexec/finishedline

    'QB64 Metacommands
    IF ASC(a3$) = 36 THEN '$

        a3u$ = UCASE$(a3$)

        IF a3u$ = "$CHECKING:OFF" THEN
            IF Cloud THEN a$ = "Feature not supported on QLOUD": GOTO errmes '***NOCLOUD***
            layout$ = "$CHECKING:OFF"
            NoChecks = 1
            GOTO finishednonexec
        END IF

        IF a3u$ = "$CHECKING:ON" THEN
            layout$ = "$CHECKING:ON"
            NoChecks = 0
            GOTO finishednonexec
        END IF

        IF a3u$ = "$CONSOLE" THEN
            IF Cloud THEN a$ = "Feature not supported on QLOUD": GOTO errmes '***NOCLOUD***
            layout$ = "$CONSOLE"
            Console = 1
            GOTO finishednonexec
        END IF

        IF a3u$ = "$CONSOLE:ONLY" THEN
            layout$ = "$CONSOLE:ONLY"
            DEPENDENCY(DEPENDENCY_CONSOLE_ONLY) = DEPENDENCY(DEPENDENCY_CONSOLE_ONLY) OR 1
            Console = 1
            GOTO finishednonexec
        END IF

        IF a3u$ = "$SCREENHIDE" THEN
            layout$ = "$SCREENHIDE"
            ScreenHide = 1
            GOTO finishednonexec
        END IF
        IF a3u$ = "$SCREENSHOW" THEN
            IF Cloud THEN a$ = "Feature not supported on QLOUD": GOTO errmes '***NOCLOUD***
            layout$ = "$SCREENSHOW"
            ScreenHide = 0
            GOTO finishednonexec
        END IF

        IF a3u$ = "$RESIZE:OFF" THEN
            IF Cloud THEN a$ = "Feature not supported on QLOUD": GOTO errmes '***NOCLOUD***
            layout$ = "$RESIZE:OFF"
            Resize = 0: Resize_Scale = 0
            GOTO finishednonexec
        END IF
        IF a3u$ = "$RESIZE:ON" THEN
            IF Cloud THEN a$ = "Feature not supported on QLOUD": GOTO errmes '***NOCLOUD***
            layout$ = "$RESIZE:ON"
            Resize = 1: Resize_Scale = 0
            GOTO finishednonexec
        END IF

        IF a3u$ = "$RESIZE:STRETCH" THEN
            IF Cloud THEN a$ = "Feature not supported on QLOUD": GOTO errmes '***NOCLOUD***
            layout$ = "$RESIZE:STRETCH"
            Resize = 1: Resize_Scale = 1
            GOTO finishednonexec
        END IF
        IF a3u$ = "$RESIZE:SMOOTH" THEN
            IF Cloud THEN a$ = "Feature not supported on QLOUD": GOTO errmes '***NOCLOUD***
            layout$ = "$RESIZE:SMOOTH"
            Resize = 1: Resize_Scale = 2
            GOTO finishednonexec
        END IF



    END IF 'QB64 Metacommands

    linedataoffset = DataOffset

    entireline$ = lineformat(a3$): IF LEN(entireline$) = 0 THEN GOTO finishednonexec
    IF Error_Happened THEN GOTO errmes
    u$ = UCASE$(entireline$)

    newif = 0

    'Convert "CASE ELSE" to "CASE C-EL" to avoid confusing compiler
    'note: CASE does not have to begin on a new line
    s = 1
    i = INSTR(s, u$, "CASE" + sp + "ELSE")
    DO WHILE i
        skip = 0
        IF i <> 1 THEN
            IF MID$(u$, i - 1, 1) <> sp THEN skip = 1
        END IF
        IF i <> LEN(u$) - 8 THEN
            IF MID$(u$, i + 9, 1) <> sp THEN skip = 1
        END IF
        IF skip = 0 THEN
            MID$(entireline$, i) = "CASE" + sp + "C-EL"
            u$ = UCASE$(entireline$)
        END IF
        s = i + 9
        i = INSTR(s, u$, "CASE" + sp + "ELSE")
    LOOP

    n = numelements(entireline$)

    'line number?
    a = ASC(entireline$)
    IF (a >= 48 AND a <= 57) OR a = 46 THEN 'numeric
        label$ = getelement(entireline$, 1)
        IF validlabel(label$) THEN

            v = HashFind(label$, HASHFLAG_LABEL, ignore, r)
            addlabchk100:
            IF v THEN
                s = Labels(r).Scope
                IF s = subfuncn OR s = -1 THEN 'same scope?
                    IF s = -1 THEN Labels(r).Scope = subfuncn 'acquire scope
                    IF Labels(r).State = 1 THEN a$ = "Duplicate label": GOTO errmes
                    'aquire state 0 types
                    tlayout$ = RTRIM$(Labels(r).cn)
                    GOTO addlabaq100
                END IF 'same scope
                IF v = 2 THEN v = HashFindCont(ignore, r): GOTO addlabchk100
            END IF

            'does not exist
            nLabels = nLabels + 1: IF nLabels > Labels_Ubound THEN Labels_Ubound = Labels_Ubound * 2: REDIM _PRESERVE Labels(1 TO Labels_Ubound) AS Label_Type
            Labels(nLabels) = Empty_Label
            HashAdd label$, HASHFLAG_LABEL, nLabels
            r = nLabels
            Labels(r).cn = tlayout$
            Labels(r).Scope = subfuncn
            addlabaq100:
            Labels(r).State = 1
            Labels(r).Data_Offset = linedataoffset

            layout$ = tlayout$
            PRINT #12, "LABEL_" + label$ + ":;"


            IF INSTR(label$, "p") THEN MID$(label$, INSTR(label$, "p"), 1) = "."
            IF RIGHT$(label$, 1) = "d" OR RIGHT$(label$, 1) = "s" THEN label$ = LEFT$(label$, LEN(label$) - 1)
            PRINT #12, "last_line=" + label$ + ";"
            IF NoChecks = 0 THEN
                PRINT #12, "if(qbevent){evnt(" + str2$(linenumber) + ");r=0;}"
            END IF
            IF n = 1 THEN GOTO finishednonexec
            entireline$ = getelements(entireline$, 2, n): u$ = UCASE$(entireline$): n = n - 1
            'note: fall through, numeric labels can be followed by alphanumeric label
        END IF 'validlabel
    END IF 'numeric
    'it wasn't a line number

    'label?
    'note: ignores possibility that this could be a single command SUB/FUNCTION (as in QBASIC?)
    IF n >= 2 THEN
        x2 = INSTR(entireline$, sp + ":")
        IF x2 THEN
            IF x2 = LEN(entireline$) - 1 THEN x3 = x2 + 1 ELSE x3 = x2 + 2
            a$ = LEFT$(entireline$, x2 - 1)

            CreatingLabel = 1
            IF validlabel(a$) THEN

                IF validname(a$) = 0 THEN a$ = "Invalid name": GOTO errmes

                v = HashFind(a$, HASHFLAG_LABEL, ignore, r)
                addlabchk:
                IF v THEN
                    s = Labels(r).Scope
                    IF s = subfuncn OR s = -1 THEN 'same scope?
                        IF s = -1 THEN Labels(r).Scope = subfuncn 'acquire scope
                        IF Labels(r).State = 1 THEN a$ = "Duplicate label": GOTO errmes
                        'aquire state 0 types
                        tlayout$ = RTRIM$(Labels(r).cn)
                        GOTO addlabaq
                    END IF 'same scope
                    IF v = 2 THEN v = HashFindCont(ignore, r): GOTO addlabchk
                END IF
                'does not exist
                nLabels = nLabels + 1: IF nLabels > Labels_Ubound THEN Labels_Ubound = Labels_Ubound * 2: REDIM _PRESERVE Labels(1 TO Labels_Ubound) AS Label_Type
                Labels(nLabels) = Empty_Label
                HashAdd a$, HASHFLAG_LABEL, nLabels
                r = nLabels
                Labels(r).cn = tlayout$
                Labels(r).Scope = subfuncn
                addlabaq:
                Labels(r).State = 1
                Labels(r).Data_Offset = linedataoffset


                IF LEN(layout$) THEN layout$ = layout$ + sp + tlayout$ + ":" ELSE layout$ = tlayout$ + ":"

                PRINT #12, "LABEL_" + a$ + ":;"
                IF NoChecks = 0 THEN
                    PRINT #12, "if(qbevent){evnt(" + str2$(linenumber) + ");r=0;}"
                END IF
                entireline$ = RIGHT$(entireline$, LEN(entireline$) - x3): u$ = UCASE$(entireline$)
                n = numelements(entireline$): IF n = 0 THEN GOTO finishednonexec
            END IF 'valid
        END IF 'includes sp+":"
    END IF 'n>=2

    'remove leading ":"
    DO WHILE ASC(u$) = 58 '":"
        IF LEN(layout$) THEN layout$ = layout$ + sp2 + ":" ELSE layout$ = ":"
        IF LEN(u$) = 1 THEN GOTO finishednonexec
        entireline$ = getelements(entireline$, 2, n): u$ = UCASE$(entireline$): n = n - 1
    LOOP

    'ELSE at the beginning of a line
    IF ASC(u$) = 69 THEN '"E"

        e1$ = getelement(u$, 1)

        IF e1$ = "ELSE" THEN
            a$ = "ELSE"
            IF n > 1 THEN continuelinefrom = 2
            GOTO gotcommand
        END IF

        IF e1$ = "ELSEIF" THEN
            IF n < 3 THEN a$ = "Expected ... THEN": GOTO errmes
            IF getelement(u$, n) = "THEN" THEN a$ = entireline$: GOTO gotcommand
            FOR i = 3 TO n - 1
                IF getelement(u$, i) = "THEN" THEN
                    a$ = getelements(entireline$, 1, i)
                    continuelinefrom = i + 1
                    GOTO gotcommand
                END IF
            NEXT
            a$ = "Expected THEN": GOTO errmes
        END IF

    END IF '"E"

    start = 1

    GOTO skipcontinit

    contline:

    n = numelements(entireline$)
    u$ = UCASE$(entireline$)

    skipcontinit:

    'jargon:
    'lineelseused - counts how many line ELSEs can POSSIBLY follow
    'endifs - how many C++ endifs "}" need to be added at the end of the line
    'lineelseused - counts the number of indwelling ELSE statements on a line
    'impliedendif - stops autoformat from adding "END IF"

    a$ = ""

    FOR i = start TO n
        e$ = getelement(u$, i)


        IF e$ = ":" THEN
            IF i = start THEN
                layoutdone = 1: IF LEN(layout$) THEN layout$ = layout$ + sp2 + ":" ELSE layout$ = ":"
                IF i <> n THEN continuelinefrom = i + 1
                GOTO finishednonexec
            END IF
            IF i <> n THEN continuelinefrom = i
            GOTO gotcommand
        END IF


        'begin scanning an 'IF' statement
        IF e$ = "IF" AND a$ = "" THEN newif = 1


        IF e$ = "THEN" OR (e$ = "GOTO" AND newif = 1) THEN
            IF newif = 0 THEN a$ = "THEN without IF": GOTO errmes
            newif = 0
            IF lineelseused > 0 THEN lineelseused = lineelseused - 1
            IF e$ = "GOTO" THEN
                IF i = n THEN a$ = "Expected IF expression GOTO label": GOTO errmes
                i = i - 1
            END IF
            a$ = a$ + sp + e$ '+"THEN"/"GOTO"
            IF i <> n THEN continuelinefrom = i + 1: endifs = endifs + 1
            GOTO gotcommand
        END IF


        IF e$ = "ELSE" THEN

            IF start = i THEN
                IF lineelseused >= 1 THEN
                    'note: more than one else used (in a row) on this line, so close first if with an 'END IF' first
                    'note: parses 'END IF' then (after continuelinefrom) parses 'ELSE'
                    'consider the following: (square brackets make reading easier)
                    'eg. if a=1 then [if b=2 then c=2 else d=2] else e=3
                    impliedendif = 1: a$ = "END" + sp + "IF"
                    endifs = endifs - 1
                    continuelinefrom = i
                    lineelseused = lineelseused - 1
                    GOTO gotcommand
                END IF
                'follow up previously encountered 'ELSE' by applying 'ELSE'
                a$ = "ELSE": continuelinefrom = i + 1
                lineelseused = lineelseused + 1
                GOTO gotcommand
            END IF 'start=i

            'apply everything up to (but not including) 'ELSE'
            continuelinefrom = i
            GOTO gotcommand
        END IF '"ELSE"


        e$ = getelement(entireline$, i): IF a$ = "" THEN a$ = e$ ELSE a$ = a$ + sp + e$
    NEXT


    'we're reached the end of the line
    IF endifs > 0 THEN
        endifs = endifs - 1
        impliedendif = 1: entireline$ = entireline$ + sp + ":" + sp + "END" + sp + "IF": n = n + 3
        i = i + 1 'skip the ":" (i is now equal to n+2)
        continuelinefrom = i
        GOTO gotcommand
    END IF


    gotcommand:

    dynscope = 0

    ca$ = a$
    a$ = eleucase$(ca$) '***REVISE THIS SECTION LATER***


    layoutdone = 0

    linefragment = a$
    IF Debug THEN PRINT #9, a$
    n = numelements(a$)
    IF n = 0 THEN GOTO finishednonexec

    'convert non-UDT dimensioned periods to _046_
    IF INSTR(ca$, sp + "." + sp) THEN
        a3$ = getelement(ca$, 1)
        except = 0
        aa$ = a3$ + sp 'rebuilt a$ (always has a trailing spacer)
        lastfuse = -1
        FOR x = 2 TO n
            a2$ = getelement(ca$, x)
            IF except = 1 THEN except = 2: GOTO udtperiod 'skip element name
            IF a2$ = "." AND x <> n THEN
                IF except = 2 THEN except = 1: GOTO udtperiod 'sub-element of UDT

                IF a3$ = ")" THEN
                    'assume it was something like typevar(???).x and treat as a UDT
                    except = 1
                    GOTO udtperiod
                END IF

                'find an ID of that type
                try = findid(UCASE$(a3$))
                IF Error_Happened THEN GOTO errmes
                DO WHILE try
                    IF ((id.t AND ISUDT) <> 0) OR ((id.arraytype AND ISUDT) <> 0) THEN
                        except = 1
                        GOTO udtperiod
                    END IF
                    IF try = 2 THEN findanotherid = 1: try = findid(UCASE$(a3$)) ELSE try = 0
                    IF Error_Happened THEN GOTO errmes
                LOOP
                'not a udt; fuse lhs & rhs with _046_
                IF isalpha(ASC(a3$)) = 0 AND lastfuse <> x - 2 THEN a$ = "Invalid '.'": GOTO errmes
                aa$ = LEFT$(aa$, LEN(aa$) - 1) + fix046$
                lastfuse = x
                GOTO periodfused
            END IF '"."
            except = 0
            udtperiod:
            aa$ = aa$ + a2$ + sp
            periodfused:
            a3$ = a2$
        NEXT
        a$ = LEFT$(aa$, LEN(aa$) - 1)
        ca$ = a$
        a$ = eleucase$(ca$)
        n = numelements(a$)
    END IF

    arrayprocessinghappened = 0

    firstelement$ = getelement(a$, 1)
    secondelement$ = getelement(a$, 2)
    thirdelement$ = getelement(a$, 3)

    'non-executable section

    IF n = 1 THEN
        IF firstelement$ = "'" THEN layoutdone = 1: GOTO finishednonexec 'nop
    END IF

    IF n <= 2 THEN
        IF firstelement$ = "DATA" THEN
            l$ = firstelement$
            IF n = 2 THEN

                e$ = SPACE$((LEN(secondelement$) - 1) \ 2)
                FOR x = 1 TO LEN(e$)
                    v1 = ASC(secondelement$, x * 2)
                    v2 = ASC(secondelement$, x * 2 + 1)
                    IF v1 < 65 THEN v1 = v1 - 48 ELSE v1 = v1 - 55
                    IF v2 < 65 THEN v2 = v2 - 48 ELSE v2 = v2 - 55
                    ASC(e$, x) = v1 + v2 * 16
                NEXT
                l$ = l$ + sp + e$
            END IF 'n=2

            layoutdone = 1: IF LEN(layout$) THEN layout$ = layout$ + sp + l$ ELSE layout$ = l$

            GOTO finishednonexec
        END IF
    END IF



    'declare library
    IF declaringlibrary THEN

        IF firstelement$ = "END" THEN
            IF n <> 2 OR secondelement$ <> "DECLARE" THEN a$ = "Expected END DECLARE": GOTO errmes
            declaringlibrary = 0
            l$ = "END" + sp + "DECLARE"
            layoutdone = 1: IF LEN(layout$) THEN layout$ = layout$ + sp + l$ ELSE layout$ = l$
            GOTO finishednonexec
        END IF 'end declare

        declaringlibrary = 2

        IF firstelement$ = "SUB" OR firstelement$ = "FUNCTION" THEN
            GOTO declaresubfunc2
        END IF

        a$ = "Expected SUB/FUNCTION definition or END DECLARE": GOTO errmes
    END IF 'declaringlibrary

    'check TYPE declarations (created on prepass)
    IF definingtype THEN

        IF firstelement$ = "END" THEN
            IF n <> 2 OR secondelement$ <> "TYPE" THEN a$ = "Expected END TYPE": GOTO errmes
            definingtype = 0
            l$ = "END" + sp + "TYPE"
            layoutdone = 1: IF LEN(layout$) THEN layout$ = layout$ + sp + l$ ELSE layout$ = l$
            GOTO finishednonexec
        END IF

        IF n < 3 OR secondelement$ <> "AS" THEN a$ = "Expected element-name AS type-name": GOTO errmes
        definingtype = 2
        l$ = getelement(ca$, 1) + sp + "AS"
        t$ = getelements$(a$, 3, n)
        typ = typname2typ(t$)
        IF Error_Happened THEN GOTO errmes
        IF typ = 0 THEN a$ = "Undefined type": GOTO errmes
        IF typ AND ISUDT THEN
            t$ = RTRIM$(udtxcname(typ AND 511))
        END IF
        l$ = l$ + sp + t$
        layoutdone = 1: IF LEN(layout$) THEN layout$ = layout$ + sp + l$ ELSE layout$ = l$
        GOTO finishednonexec

    END IF 'defining type

    IF firstelement$ = "TYPE" THEN
        IF n <> 2 THEN a$ = "Expected TYPE type-name": GOTO errmes
        l$ = "TYPE" + sp + getelement(ca$, 2)
        layoutdone = 1: IF LEN(layout$) THEN layout$ = layout$ + sp + l$ ELSE layout$ = l$
        definingtype = 1
        definingtypeerror = linenumber
        GOTO finishednonexec
    END IF

    'skip DECLARE SUB/FUNCTION
    IF n >= 1 THEN
        IF firstelement$ = "DECLARE" THEN

            IF secondelement$ = "LIBRARY" OR secondelement$ = "DYNAMIC" OR secondelement$ = "CUSTOMTYPE" OR secondelement$ = "STATIC" THEN

                declaringlibrary = 1
                dynamiclibrary = 0
                customtypelibrary = 0
                indirectlibrary = 0
                staticlinkedlibrary = 0

                x = 3
                l$ = "DECLARE" + sp + "LIBRARY"

                IF secondelement$ = "DYNAMIC" THEN
                    e$ = getelement$(a$, 3): IF e$ <> "LIBRARY" THEN a$ = "Expected DYNAMIC LIBRARY " + CHR$(34) + "..." + CHR$(34): GOTO errmes
                    dynamiclibrary = 1
                    x = 4
                    l$ = "DECLARE" + sp + "DYNAMIC" + sp + "LIBRARY"
                    IF n = 3 THEN a$ = "Expected DECLARE DYNAMIC LIBRARY " + CHR$(34) + "..." + CHR$(34): GOTO errmes
                    indirectlibrary = 1
                END IF

                IF secondelement$ = "CUSTOMTYPE" THEN
                    e$ = getelement$(a$, 3): IF e$ <> "LIBRARY" THEN a$ = "Expected CUSTOMTYPE LIBRARY": GOTO errmes
                    customtypelibrary = 1
                    x = 4
                    l$ = "DECLARE" + sp + "CUSTOMTYPE" + sp + "LIBRARY"
                    indirectlibrary = 1
                END IF

                IF secondelement$ = "STATIC" THEN
                    e$ = getelement$(a$, 3): IF e$ <> "LIBRARY" THEN a$ = "Expected STATIC LIBRARY": GOTO errmes
                    x = 4
                    l$ = "DECLARE" + sp + "STATIC" + sp + "LIBRARY"
                    staticlinkedlibrary = 1
                END IF

                sfdeclare = 0: sfheader = 0

                IF n >= x THEN

                    sfdeclare = 1

                    addlibrary:

                    libname$ = ""
                    headername$ = ""


                    'assume library name in double quotes follows
                    'assume library is in main qb64 folder
                    x$ = getelement$(ca$, x)
                    IF ASC(x$) <> 34 THEN a$ = "Expected LIBRARY " + CHR$(34) + "..." + CHR$(34): GOTO errmes
                    x$ = RIGHT$(x$, LEN(x$) - 1)
                    z = INSTR(x$, CHR$(34))
                    IF z = 0 THEN a$ = "Expected LIBRARY " + CHR$(34) + "..." + CHR$(34): GOTO errmes
                    x$ = LEFT$(x$, z - 1)

                    IF dynamiclibrary <> 0 AND LEN(x$) = 0 THEN a$ = "Expected DECLARE DYNAMIC LIBRARY " + CHR$(34) + "..." + CHR$(34): GOTO errmes
                    IF customtypelibrary <> 0 AND LEN(x$) = 0 THEN a$ = "Expected DECLARE CUSTOMTYPE LIBRARY " + CHR$(34) + "..." + CHR$(34): GOTO errmes













                    'convert '\\' to '\'
                    WHILE INSTR(x$, "\\")
                        z = INSTR(x$, "\\")
                        x$ = LEFT$(x$, z - 1) + RIGHT$(x$, LEN(x$) - z)
                    WEND

                    autoformat_x$ = x$ 'used for autolayout purposes

                    'Remove version number from library name
                    'Eg. libname:1.0 becomes libname <-> 1.0 which later becomes libname.so.1.0
                    v$ = ""
                    striplibver:
                    FOR z = LEN(x$) TO 1 STEP -1
                        a = ASC(x$, z)
                        IF a = ASC_BACKSLASH OR a = ASC_FORWARDSLASH THEN EXIT FOR
                        IF a = ASC_FULLSTOP OR a = ASC_COLON THEN
                            IF isuinteger(RIGHT$(x$, LEN(x$) - z)) THEN
                                IF LEN(v$) THEN v$ = RIGHT$(x$, LEN(x$) - z) + "." + v$ ELSE v$ = RIGHT$(x$, LEN(x$) - z)
                                x$ = LEFT$(x$, z - 1)
                                IF a = ASC_COLON THEN EXIT FOR
                                GOTO striplibver
                            ELSE
                                EXIT FOR
                            END IF
                        END IF
                    NEXT
                    libver$ = v$


                    IF os$ = "WIN" THEN
                        'convert forward-slashes to back-slashes
                        DO WHILE INSTR(x$, "/")
                            z = INSTR(x$, "/")
                            x$ = LEFT$(x$, z - 1) + "\" + RIGHT$(x$, LEN(x$) - z)
                        LOOP
                    END IF

                    IF os$ = "LNX" THEN
                        'convert any back-slashes to forward-slashes
                        DO WHILE INSTR(x$, "\")
                            z = INSTR(x$, "\")
                            x$ = LEFT$(x$, z - 1) + "/" + RIGHT$(x$, LEN(x$) - z)
                        LOOP
                    END IF

                    'Seperate path from name
                    libpath$ = ""
                    FOR z = LEN(x$) TO 1 STEP -1
                        a = ASC(x$, z)
                        IF a = 47 OR a = 92 THEN '\ or /
                            libpath$ = LEFT$(x$, z)
                            x$ = RIGHT$(x$, LEN(x$) - z)
                            EXIT FOR
                        END IF
                    NEXT

                    'Create a path which can be used for inline code (uses \\ instead of \)
                    libpath_inline$ = ""
                    FOR z = 1 TO LEN(libpath$)
                        a = ASC(libpath$, z)
                        libpath_inline$ = libpath_inline$ + CHR$(a)
                        IF a = 92 THEN libpath_inline$ = libpath_inline$ + "\"
                    NEXT

                    IF LEN(x$) THEN
                        IF dynamiclibrary = 0 THEN
                            'Static library

                            IF os$ = "WIN" THEN
                                'check for .lib
                                IF LEN(libname$) = 0 THEN
                                    IF _FILEEXISTS(libpath$ + x$ + ".lib") THEN
                                        libname$ = libpath$ + x$ + ".lib"
                                        inlinelibname$ = libpath_inline$ + x$ + ".lib"
                                    END IF
                                END IF
                                'check for .a
                                IF LEN(libname$) = 0 THEN
                                    IF _FILEEXISTS(libpath$ + x$ + ".a") THEN
                                        libname$ = libpath$ + x$ + ".a"
                                        inlinelibname$ = libpath_inline$ + x$ + ".a"
                                    END IF
                                END IF
                                'check for .o
                                IF LEN(libname$) = 0 THEN
                                    IF _FILEEXISTS(libpath$ + x$ + ".o") THEN
                                        libname$ = libpath$ + x$ + ".o"
                                        inlinelibname$ = libpath_inline$ + x$ + ".o"
                                    END IF
                                END IF
                                'check for .lib
                                IF LEN(libname$) = 0 THEN
                                    IF _FILEEXISTS(x$ + ".lib") THEN
                                        libname$ = x$ + ".lib"
                                        inlinelibname$ = x$ + ".lib"
                                    END IF
                                END IF
                                'check for .a
                                IF LEN(libname$) = 0 THEN
                                    IF _FILEEXISTS(x$ + ".a") THEN
                                        libname$ = x$ + ".a"
                                        inlinelibname$ = x$ + ".a"
                                    END IF
                                END IF
                                'check for .o
                                IF LEN(libname$) = 0 THEN
                                    IF _FILEEXISTS(x$ + ".o") THEN
                                        libname$ = x$ + ".o"
                                        inlinelibname$ = x$ + ".o"
                                    END IF
                                END IF
                            END IF 'Windows

                            IF os$ = "LNX" THEN
                                IF staticlinkedlibrary = 0 THEN

                                    IF MacOSX THEN 'dylib support
                                        'check for .dylib (direct)
                                        IF LEN(libname$) = 0 THEN
                                            IF _FILEEXISTS(libpath$ + "lib" + x$ + "." + libver$ + ".dylib") THEN
                                                libname$ = libpath$ + "lib" + x$ + "." + libver$ + ".dylib"
                                                inlinelibname$ = libpath_inline$ + "lib" + x$ + "." + libver$ + ".dylib"
                                                IF LEN(libpath$) THEN mylibopt$ = mylibopt$ + " -Wl,-rpath " + libpath$ + " " ELSE mylibopt$ = mylibopt$ + " -Wl,-rpath ./ "
                                            END IF
                                        END IF
                                        IF LEN(libname$) = 0 THEN
                                            IF _FILEEXISTS(libpath$ + "lib" + x$ + ".dylib") THEN
                                                libname$ = libpath$ + "lib" + x$ + ".dylib"
                                                inlinelibname$ = libpath_inline$ + "lib" + x$ + ".dylib"
                                                IF LEN(libpath$) THEN mylibopt$ = mylibopt$ + " -Wl,-rpath " + libpath$ + " " ELSE mylibopt$ = mylibopt$ + " -Wl,-rpath ./ "
                                            END IF
                                        END IF
                                    END IF

                                    'check for .so (direct)
                                    IF LEN(libname$) = 0 THEN
                                        IF _FILEEXISTS(libpath$ + "lib" + x$ + ".so." + libver$) THEN
                                            libname$ = libpath$ + "lib" + x$ + ".so." + libver$
                                            inlinelibname$ = libpath_inline$ + "lib" + x$ + ".so." + libver$
                                            IF LEN(libpath$) THEN mylibopt$ = mylibopt$ + " -Wl,-rpath " + libpath$ + " " ELSE mylibopt$ = mylibopt$ + " -Wl,-rpath ./ "
                                        END IF
                                    END IF
                                    IF LEN(libname$) = 0 THEN
                                        IF _FILEEXISTS(libpath$ + "lib" + x$ + ".so") THEN
                                            libname$ = libpath$ + "lib" + x$ + ".so"
                                            inlinelibname$ = libpath_inline$ + "lib" + x$ + ".so"
                                            IF LEN(libpath$) THEN mylibopt$ = mylibopt$ + " -Wl,-rpath " + libpath$ + " " ELSE mylibopt$ = mylibopt$ + " -Wl,-rpath ./ "
                                        END IF
                                    END IF
                                END IF
                                'check for .a (direct)
                                IF LEN(libname$) = 0 THEN
                                    IF _FILEEXISTS(libpath$ + "lib" + x$ + ".a") THEN
                                        libname$ = libpath$ + "lib" + x$ + ".a"
                                        inlinelibname$ = libpath_inline$ + "lib" + x$ + ".a"
                                    END IF
                                END IF
                                'check for .o (direct)
                                IF LEN(libname$) = 0 THEN
                                    IF _FILEEXISTS(libpath$ + "lib" + x$ + ".o") THEN
                                        libname$ = libpath$ + "lib" + x$ + ".o"
                                        inlinelibname$ = libpath_inline$ + "lib" + x$ + ".o"
                                    END IF
                                END IF
                                IF staticlinkedlibrary = 0 THEN
                                    'check for .so (usr/lib64)
                                    IF LEN(libname$) = 0 THEN
                                        IF _FILEEXISTS("/usr/lib64/" + libpath$ + "lib" + x$ + ".so." + libver$) THEN
                                            libname$ = "/usr/lib64/" + libpath$ + "lib" + x$ + ".so." + libver$
                                            inlinelibname$ = "/usr/lib64/" + libpath_inline$ + "lib" + x$ + ".so." + libver$
                                            IF LEN(libpath$) THEN mylibopt$ = mylibopt$ + " -Wl,-rpath /usr/lib64/" + libpath$ + " " ELSE mylibopt$ = mylibopt$ + " -Wl,-rpath /usr/lib64/ "
                                        END IF
                                    END IF
                                    IF LEN(libname$) = 0 THEN
                                        IF _FILEEXISTS("/usr/lib64/" + libpath$ + "lib" + x$ + ".so") THEN
                                            libname$ = "/usr/lib64/" + libpath$ + "lib" + x$ + ".so"
                                            inlinelibname$ = "/usr/lib64/" + libpath_inline$ + "lib" + x$ + ".so"
                                            IF LEN(libpath$) THEN mylibopt$ = mylibopt$ + " -Wl,-rpath /usr/lib64/" + libpath$ + " " ELSE mylibopt$ = mylibopt$ + " -Wl,-rpath /usr/lib64/ "
                                        END IF
                                    END IF
                                END IF
                                'check for .a (usr/lib64)
                                IF LEN(libname$) = 0 THEN
                                    IF _FILEEXISTS("/usr/lib64/" + libpath$ + "lib" + x$ + ".a") THEN
                                        libname$ = "/usr/lib64/" + libpath$ + "lib" + x$ + ".a"
                                        inlinelibname$ = "/usr/lib64/" + libpath_inline$ + "lib" + x$ + ".a"
                                    END IF
                                END IF
                                IF staticlinkedlibrary = 0 THEN

                                    IF MacOSX THEN 'dylib support
                                        'check for .dylib (usr/lib)
                                        IF LEN(libname$) = 0 THEN
                                            IF _FILEEXISTS("/usr/lib/" + libpath$ + "lib" + x$ + "." + libver$ + ".dylib") THEN
                                                libname$ = "/usr/lib/" + libpath$ + "lib" + x$ + "." + libver$ + ".dylib"
                                                inlinelibname$ = "/usr/lib/" + libpath_inline$ + "lib" + x$ + "." + libver$ + ".dylib"
                                                IF LEN(libpath$) THEN mylibopt$ = mylibopt$ + " -Wl,-rpath /usr/lib/" + libpath$ + " " ELSE mylibopt$ = mylibopt$ + " -Wl,-rpath /usr/lib/ "
                                            END IF
                                        END IF
                                        IF LEN(libname$) = 0 THEN
                                            IF _FILEEXISTS("/usr/lib/" + libpath$ + "lib" + x$ + ".dylib") THEN
                                                libname$ = "/usr/lib/" + libpath$ + "lib" + x$ + ".dylib"
                                                inlinelibname$ = "/usr/lib/" + libpath_inline$ + "lib" + x$ + ".dylib"
                                                IF LEN(libpath$) THEN mylibopt$ = mylibopt$ + " -Wl,-rpath /usr/lib/" + libpath$ + " " ELSE mylibopt$ = mylibopt$ + " -Wl,-rpath /usr/lib/ "
                                            END IF
                                        END IF
                                    END IF

                                    'check for .so (usr/lib)
                                    IF LEN(libname$) = 0 THEN
                                        IF _FILEEXISTS("/usr/lib/" + libpath$ + "lib" + x$ + ".so." + libver$) THEN
                                            libname$ = "/usr/lib/" + libpath$ + "lib" + x$ + ".so." + libver$
                                            inlinelibname$ = "/usr/lib/" + libpath_inline$ + "lib" + x$ + ".so." + libver$
                                            IF LEN(libpath$) THEN mylibopt$ = mylibopt$ + " -Wl,-rpath /usr/lib/" + libpath$ + " " ELSE mylibopt$ = mylibopt$ + " -Wl,-rpath /usr/lib/ "
                                        END IF
                                    END IF
                                    IF LEN(libname$) = 0 THEN
                                        IF _FILEEXISTS("/usr/lib/" + libpath$ + "lib" + x$ + ".so") THEN
                                            libname$ = "/usr/lib/" + libpath$ + "lib" + x$ + ".so"
                                            inlinelibname$ = "/usr/lib/" + libpath_inline$ + "lib" + x$ + ".so"
                                            IF LEN(libpath$) THEN mylibopt$ = mylibopt$ + " -Wl,-rpath /usr/lib/" + libpath$ + " " ELSE mylibopt$ = mylibopt$ + " -Wl,-rpath /usr/lib/ "
                                        END IF
                                    END IF
                                END IF
                                'check for .a (usr/lib)
                                IF LEN(libname$) = 0 THEN
                                    IF _FILEEXISTS("/usr/lib/" + libpath$ + "lib" + x$ + ".a") THEN
                                        libname$ = "/usr/lib/" + libpath$ + "lib" + x$ + ".a"
                                        inlinelibname$ = "/usr/lib/" + libpath_inline$ + "lib" + x$ + ".a"
                                    END IF
                                END IF
                                '--------------------------(without path)------------------------------
                                IF staticlinkedlibrary = 0 THEN

                                    IF MacOSX THEN 'dylib support
                                        'check for .dylib (direct)
                                        IF LEN(libname$) = 0 THEN
                                            IF _FILEEXISTS("lib" + x$ + "." + libver$ + ".dylib") THEN
                                                libname$ = "lib" + x$ + "." + libver$ + ".dylib"
                                                inlinelibname$ = "lib" + x$ + "." + libver$ + ".dylib"
                                                mylibopt$ = mylibopt$ + " -Wl,-rpath ./ "
                                            END IF
                                        END IF
                                        IF LEN(libname$) = 0 THEN
                                            IF _FILEEXISTS("lib" + x$ + ".dylib") THEN
                                                libname$ = "lib" + x$ + ".dylib"
                                                inlinelibname$ = "lib" + x$ + ".dylib"
                                                mylibopt$ = mylibopt$ + " -Wl,-rpath ./ "
                                            END IF
                                        END IF
                                    END IF

                                    'check for .so (direct)
                                    IF LEN(libname$) = 0 THEN
                                        IF _FILEEXISTS("lib" + x$ + ".so." + libver$) THEN
                                            libname$ = "lib" + x$ + ".so." + libver$
                                            inlinelibname$ = "lib" + x$ + ".so." + libver$
                                            mylibopt$ = mylibopt$ + " -Wl,-rpath ./ "
                                        END IF
                                    END IF
                                    IF LEN(libname$) = 0 THEN
                                        IF _FILEEXISTS("lib" + x$ + ".so") THEN
                                            libname$ = "lib" + x$ + ".so"
                                            inlinelibname$ = "lib" + x$ + ".so"
                                            mylibopt$ = mylibopt$ + " -Wl,-rpath ./ "
                                        END IF
                                    END IF
                                END IF
                                'check for .a (direct)
                                IF LEN(libname$) = 0 THEN
                                    IF _FILEEXISTS("lib" + x$ + ".a") THEN
                                        libname$ = "lib" + x$ + ".a"
                                        inlinelibname$ = "lib" + x$ + ".a"
                                    END IF
                                END IF
                                'check for .o (direct)
                                IF LEN(libname$) = 0 THEN
                                    IF _FILEEXISTS("lib" + x$ + ".o") THEN
                                        libname$ = "lib" + x$ + ".o"
                                        inlinelibname$ = "lib" + x$ + ".o"
                                    END IF
                                END IF
                                IF staticlinkedlibrary = 0 THEN
                                    'check for .so (usr/lib64)
                                    IF LEN(libname$) = 0 THEN
                                        IF _FILEEXISTS("/usr/lib64/" + "lib" + x$ + ".so." + libver$) THEN
                                            libname$ = "/usr/lib64/" + "lib" + x$ + ".so." + libver$
                                            inlinelibname$ = "/usr/lib64/" + "lib" + x$ + ".so." + libver$
                                            mylibopt$ = mylibopt$ + " -Wl,-rpath /usr/lib64/ "
                                        END IF
                                    END IF
                                    IF LEN(libname$) = 0 THEN
                                        IF _FILEEXISTS("/usr/lib64/" + "lib" + x$ + ".so") THEN
                                            libname$ = "/usr/lib64/" + "lib" + x$ + ".so"
                                            inlinelibname$ = "/usr/lib64/" + "lib" + x$ + ".so"
                                            mylibopt$ = mylibopt$ + " -Wl,-rpath /usr/lib64/ "
                                        END IF
                                    END IF
                                END IF
                                'check for .a (usr/lib64)
                                IF LEN(libname$) = 0 THEN
                                    IF _FILEEXISTS("/usr/lib64/" + "lib" + x$ + ".a") THEN
                                        libname$ = "/usr/lib64/" + "lib" + x$ + ".a"
                                        inlinelibname$ = "/usr/lib64/" + "lib" + x$ + ".a"
                                    END IF
                                END IF
                                IF staticlinkedlibrary = 0 THEN

                                    IF MacOSX THEN 'dylib support
                                        'check for .dylib (usr/lib)
                                        IF LEN(libname$) = 0 THEN
                                            IF _FILEEXISTS("/usr/lib/" + "lib" + x$ + "." + libver$ + ".dylib") THEN
                                                libname$ = "/usr/lib/" + "lib" + x$ + "." + libver$ + ".dylib"
                                                inlinelibname$ = "/usr/lib/" + "lib" + x$ + "." + libver$ + ".dylib"
                                            END IF
                                        END IF
                                        IF LEN(libname$) = 0 THEN
                                            IF _FILEEXISTS("/usr/lib/" + "lib" + x$ + ".dylib") THEN
                                                libname$ = "/usr/lib/" + "lib" + x$ + ".dylib"
                                                inlinelibname$ = "/usr/lib/" + "lib" + x$ + ".dylib"
                                                mylibopt$ = mylibopt$ + " -Wl,-rpath /usr/lib/ "
                                            END IF
                                        END IF
                                    END IF

                                    'check for .so (usr/lib)
                                    IF LEN(libname$) = 0 THEN
                                        IF _FILEEXISTS("/usr/lib/" + "lib" + x$ + ".so." + libver$) THEN
                                            libname$ = "/usr/lib/" + "lib" + x$ + ".so." + libver$
                                            inlinelibname$ = "/usr/lib/" + "lib" + x$ + ".so." + libver$
                                        END IF
                                    END IF
                                    IF LEN(libname$) = 0 THEN
                                        IF _FILEEXISTS("/usr/lib/" + "lib" + x$ + ".so") THEN
                                            libname$ = "/usr/lib/" + "lib" + x$ + ".so"
                                            inlinelibname$ = "/usr/lib/" + "lib" + x$ + ".so"
                                            mylibopt$ = mylibopt$ + " -Wl,-rpath /usr/lib/ "
                                        END IF
                                    END IF
                                END IF
                                'check for .a (usr/lib)
                                IF LEN(libname$) = 0 THEN
                                    IF _FILEEXISTS("/usr/lib/" + "lib" + x$ + ".a") THEN
                                        libname$ = "/usr/lib/" + "lib" + x$ + ".a"
                                        inlinelibname$ = "/usr/lib/" + "lib" + x$ + ".a"
                                        mylibopt$ = mylibopt$ + " -Wl,-rpath /usr/lib/ "
                                    END IF
                                END IF
                            END IF 'Linux


                            'check for header
                            IF LEN(headername$) = 0 THEN
                                IF os$ = "WIN" THEN
                                    IF _FILEEXISTS(libpath$ + x$ + ".h") THEN
                                        headername$ = libpath_inline$ + x$ + ".h"
                                        IF customtypelibrary = 0 THEN sfdeclare = 0
                                        sfheader = 1
                                        GOTO GotHeader
                                    END IF
                                    IF _FILEEXISTS(libpath$ + x$ + ".hpp") THEN
                                        headername$ = libpath_inline$ + x$ + ".hpp"
                                        IF customtypelibrary = 0 THEN sfdeclare = 0
                                        sfheader = 1
                                        GOTO GotHeader
                                    END IF
                                    '--------------------------(without path)------------------------------
                                    IF _FILEEXISTS(x$ + ".h") THEN
                                        headername$ = x$ + ".h"
                                        IF customtypelibrary = 0 THEN sfdeclare = 0
                                        sfheader = 1
                                        GOTO GotHeader
                                    END IF
                                    IF _FILEEXISTS(x$ + ".hpp") THEN
                                        headername$ = x$ + ".hpp"
                                        IF customtypelibrary = 0 THEN sfdeclare = 0
                                        sfheader = 1
                                        GOTO GotHeader
                                    END IF
                                END IF 'Windows

                                IF os$ = "LNX" THEN
                                    IF _FILEEXISTS(libpath$ + x$ + ".h") THEN
                                        headername$ = libpath_inline$ + x$ + ".h"
                                        IF customtypelibrary = 0 THEN sfdeclare = 0
                                        sfheader = 1
                                        GOTO GotHeader
                                    END IF
                                    IF _FILEEXISTS(libpath$ + x$ + ".hpp") THEN
                                        headername$ = libpath_inline$ + x$ + ".hpp"
                                        IF customtypelibrary = 0 THEN sfdeclare = 0
                                        sfheader = 1
                                        GOTO GotHeader
                                    END IF
                                    IF _FILEEXISTS("/usr/include/" + libpath$ + x$ + ".h") THEN
                                        headername$ = "/usr/include/" + libpath_inline$ + x$ + ".h"
                                        IF customtypelibrary = 0 THEN sfdeclare = 0
                                        sfheader = 1
                                        GOTO GotHeader
                                    END IF
                                    IF _FILEEXISTS("/usr/include/" + libpath$ + x$ + ".hpp") THEN
                                        headername$ = "/usr/include/" + libpath_inline$ + x$ + ".hpp"
                                        IF customtypelibrary = 0 THEN sfdeclare = 0
                                        sfheader = 1
                                        GOTO GotHeader
                                    END IF
                                    '--------------------------(without path)------------------------------
                                    IF _FILEEXISTS(x$ + ".h") THEN
                                        headername$ = x$ + ".h"
                                        IF customtypelibrary = 0 THEN sfdeclare = 0
                                        sfheader = 1
                                        GOTO GotHeader
                                    END IF
                                    IF _FILEEXISTS(x$ + ".hpp") THEN
                                        headername$ = x$ + ".hpp"
                                        IF customtypelibrary = 0 THEN sfdeclare = 0
                                        sfheader = 1
                                        GOTO GotHeader
                                    END IF
                                    IF _FILEEXISTS("/usr/include/" + x$ + ".h") THEN
                                        headername$ = "/usr/include/" + x$ + ".h"
                                        IF customtypelibrary = 0 THEN sfdeclare = 0
                                        sfheader = 1
                                        GOTO GotHeader
                                    END IF
                                    IF _FILEEXISTS("/usr/include/" + x$ + ".hpp") THEN
                                        headername$ = "/usr/include/" + x$ + ".hpp"
                                        IF customtypelibrary = 0 THEN sfdeclare = 0
                                        sfheader = 1
                                        GOTO GotHeader
                                    END IF
                                END IF 'Linux

                                GotHeader:
                            END IF

                        ELSE
                            'dynamic library

                            IF os$ = "WIN" THEN
                                'check for .dll (direct)
                                IF LEN(libname$) = 0 THEN
                                    IF _FILEEXISTS(libpath$ + x$ + ".dll") THEN
                                        libname$ = libpath$ + x$ + ".dll"
                                        inlinelibname$ = libpath_inline$ + x$ + ".dll"
                                    END IF
                                END IF
                                'check for .dll (system32)
                                IF LEN(libname$) = 0 THEN
                                    IF _FILEEXISTS(ENVIRON$("SYSTEMROOT") + "\System32\" + libpath$ + x$ + ".dll") THEN
                                        libname$ = libpath$ + x$ + ".dll"
                                        inlinelibname$ = libpath_inline$ + x$ + ".dll"
                                    END IF
                                END IF
                                '--------------------------(without path)------------------------------
                                'check for .dll (direct)
                                IF LEN(libname$) = 0 THEN
                                    IF _FILEEXISTS(x$ + ".dll") THEN
                                        libname$ = x$ + ".dll"
                                        inlinelibname$ = x$ + ".dll"
                                    END IF
                                END IF
                                'check for .dll (system32)
                                IF LEN(libname$) = 0 THEN
                                    IF _FILEEXISTS(ENVIRON$("SYSTEMROOT") + "\System32\" + x$ + ".dll") THEN
                                        libname$ = x$ + ".dll"
                                        inlinelibname$ = x$ + ".dll"
                                    END IF
                                END IF
                            END IF 'Windows

                            IF os$ = "LNX" THEN
                                'Note: STATIC libraries (.a/.o) cannot be loaded as dynamic objects


                                IF MacOSX THEN 'dylib support
                                    'check for .dylib (direct)
                                    IF LEN(libname$) = 0 THEN
                                        IF _FILEEXISTS(libpath$ + "lib" + x$ + "." + libver$ + ".dylib") THEN
                                            libname$ = libpath$ + "lib" + x$ + "." + libver$ + ".dylib"
                                            inlinelibname$ = libpath_inline$ + "lib" + x$ + "." + libver$ + ".dylib"
                                            IF LEFT$(libpath$, 1) <> "/" THEN libname$ = "./" + libname$: inlinelibname$ = "./" + inlinelibname$
                                        END IF
                                    END IF
                                    IF LEN(libname$) = 0 THEN
                                        IF _FILEEXISTS(libpath$ + "lib" + x$ + ".dylib") THEN
                                            libname$ = libpath$ + "lib" + x$ + ".dylib"
                                            inlinelibname$ = libpath_inline$ + "lib" + x$ + ".dylib"
                                            IF LEFT$(libpath$, 1) <> "/" THEN libname$ = "./" + libname$: inlinelibname$ = "./" + inlinelibname$
                                        END IF
                                    END IF
                                END IF

                                'check for .so (direct)
                                IF LEN(libname$) = 0 THEN
                                    IF _FILEEXISTS(libpath$ + "lib" + x$ + ".so." + libver$) THEN
                                        libname$ = libpath$ + "lib" + x$ + ".so." + libver$
                                        inlinelibname$ = libpath_inline$ + "lib" + x$ + ".so." + libver$
                                        IF LEFT$(libpath$, 1) <> "/" THEN libname$ = "./" + libname$: inlinelibname$ = "./" + inlinelibname$
                                    END IF
                                END IF
                                IF LEN(libname$) = 0 THEN
                                    IF _FILEEXISTS(libpath$ + "lib" + x$ + ".so") THEN
                                        libname$ = libpath$ + "lib" + x$ + ".so"
                                        inlinelibname$ = libpath_inline$ + "lib" + x$ + ".so"
                                        IF LEFT$(libpath$, 1) <> "/" THEN libname$ = "./" + libname$: inlinelibname$ = "./" + inlinelibname$
                                    END IF
                                END IF
                                'check for .so (usr/lib64)
                                IF LEN(libname$) = 0 THEN
                                    IF _FILEEXISTS("/usr/lib64/" + libpath$ + "lib" + x$ + ".so." + libver$) THEN
                                        libname$ = "/usr/lib64/" + libpath$ + "lib" + x$ + ".so." + libver$
                                        inlinelibname$ = "/usr/lib64/" + libpath_inline$ + "lib" + x$ + ".so." + libver$
                                    END IF
                                END IF
                                IF LEN(libname$) = 0 THEN
                                    IF _FILEEXISTS("/usr/lib64/" + libpath$ + "lib" + x$ + ".so") THEN
                                        libname$ = "/usr/lib64/" + libpath$ + "lib" + x$ + ".so"
                                        inlinelibname$ = "/usr/lib64/" + libpath_inline$ + "lib" + x$ + ".so"
                                    END IF
                                END IF

                                IF MacOSX THEN 'dylib support
                                    'check for .dylib (usr/lib)
                                    IF LEN(libname$) = 0 THEN
                                        IF _FILEEXISTS("/usr/lib/" + libpath$ + "lib" + x$ + "." + libver$ + ".dylib") THEN
                                            libname$ = "/usr/lib/" + libpath$ + "lib" + x$ + "." + libver$ + ".dylib"
                                            inlinelibname$ = "/usr/lib/" + libpath_inline$ + "lib" + x$ + "." + libver$ + ".dylib"
                                        END IF
                                    END IF
                                    IF LEN(libname$) = 0 THEN
                                        IF _FILEEXISTS("/usr/lib/" + libpath$ + "lib" + x$ + ".dylib") THEN
                                            libname$ = "/usr/lib/" + libpath$ + "lib" + x$ + ".dylib"
                                            inlinelibname$ = "/usr/lib/" + libpath_inline$ + "lib" + x$ + ".dylib"
                                        END IF
                                    END IF
                                END IF

                                'check for .so (usr/lib)
                                IF LEN(libname$) = 0 THEN
                                    IF _FILEEXISTS("/usr/lib/" + libpath$ + "lib" + x$ + ".so." + libver$) THEN
                                        libname$ = "/usr/lib/" + libpath$ + "lib" + x$ + ".so." + libver$
                                        inlinelibname$ = "/usr/lib/" + libpath_inline$ + "lib" + x$ + ".so." + libver$
                                    END IF
                                END IF
                                IF LEN(libname$) = 0 THEN
                                    IF _FILEEXISTS("/usr/lib/" + libpath$ + "lib" + x$ + ".so") THEN
                                        libname$ = "/usr/lib/" + libpath$ + "lib" + x$ + ".so"
                                        inlinelibname$ = "/usr/lib/" + libpath_inline$ + "lib" + x$ + ".so"
                                    END IF
                                END IF
                                '--------------------------(without path)------------------------------
                                IF MacOSX THEN 'dylib support
                                    'check for .dylib (direct)
                                    IF LEN(libname$) = 0 THEN
                                        IF _FILEEXISTS("lib" + x$ + "." + libver$ + ".dylib") THEN
                                            libname$ = "lib" + x$ + "." + libver$ + ".dylib"
                                            inlinelibname$ = "lib" + x$ + "." + libver$ + ".dylib"
                                            libname$ = "./" + libname$: inlinelibname$ = "./" + inlinelibname$
                                        END IF
                                    END IF
                                    IF LEN(libname$) = 0 THEN
                                        IF _FILEEXISTS("lib" + x$ + ".dylib") THEN
                                            libname$ = "lib" + x$ + ".dylib"
                                            inlinelibname$ = "lib" + x$ + ".dylib"
                                            libname$ = "./" + libname$: inlinelibname$ = "./" + inlinelibname$
                                        END IF
                                    END IF
                                END IF

                                'check for .so (direct)
                                IF LEN(libname$) = 0 THEN
                                    IF _FILEEXISTS("lib" + x$ + ".so." + libver$) THEN
                                        libname$ = "lib" + x$ + ".so." + libver$
                                        inlinelibname$ = "lib" + x$ + ".so." + libver$
                                        libname$ = "./" + libname$: inlinelibname$ = "./" + inlinelibname$
                                    END IF
                                END IF
                                IF LEN(libname$) = 0 THEN
                                    IF _FILEEXISTS("lib" + x$ + ".so") THEN
                                        libname$ = "lib" + x$ + ".so"
                                        inlinelibname$ = "lib" + x$ + ".so"
                                        libname$ = "./" + libname$: inlinelibname$ = "./" + inlinelibname$
                                    END IF
                                END IF
                                'check for .so (usr/lib64)
                                IF LEN(libname$) = 0 THEN
                                    IF _FILEEXISTS("/usr/lib64/" + "lib" + x$ + ".so." + libver$) THEN
                                        libname$ = "/usr/lib64/" + "lib" + x$ + ".so." + libver$
                                        inlinelibname$ = "/usr/lib64/" + "lib" + x$ + ".so." + libver$
                                    END IF
                                END IF
                                IF LEN(libname$) = 0 THEN
                                    IF _FILEEXISTS("/usr/lib64/" + "lib" + x$ + ".so") THEN
                                        libname$ = "/usr/lib64/" + "lib" + x$ + ".so"
                                        inlinelibname$ = "/usr/lib64/" + "lib" + x$ + ".so"
                                    END IF
                                END IF

                                IF MacOSX THEN 'dylib support
                                    'check for .dylib (usr/lib)
                                    IF LEN(libname$) = 0 THEN
                                        IF _FILEEXISTS("/usr/lib/" + "lib" + x$ + "." + libver$ + ".dylib") THEN
                                            libname$ = "/usr/lib/" + "lib" + x$ + "." + libver$ + ".dylib"
                                            inlinelibname$ = "/usr/lib/" + "lib" + x$ + "." + libver$ + ".dylib"
                                        END IF
                                    END IF
                                    IF LEN(libname$) = 0 THEN
                                        IF _FILEEXISTS("/usr/lib/" + "lib" + x$ + ".dylib") THEN
                                            libname$ = "/usr/lib/" + "lib" + x$ + ".dylib"
                                            inlinelibname$ = "/usr/lib/" + "lib" + x$ + ".dylib"
                                        END IF
                                    END IF
                                END IF

                                'check for .so (usr/lib)
                                IF LEN(libname$) = 0 THEN
                                    IF _FILEEXISTS("/usr/lib/" + "lib" + x$ + ".so." + libver$) THEN
                                        libname$ = "/usr/lib/" + "lib" + x$ + ".so." + libver$
                                        inlinelibname$ = "/usr/lib/" + "lib" + x$ + ".so." + libver$
                                    END IF
                                END IF
                                IF LEN(libname$) = 0 THEN
                                    IF _FILEEXISTS("/usr/lib/" + "lib" + x$ + ".so") THEN
                                        libname$ = "/usr/lib/" + "lib" + x$ + ".so"
                                        inlinelibname$ = "/usr/lib/" + "lib" + x$ + ".so"
                                    END IF
                                END IF
                            END IF 'Linux

                        END IF 'Dynamic

                        'library found?
                        IF dynamiclibrary <> 0 AND LEN(libname$) = 0 THEN a$ = "DYNAMIC LIBRARY not found": GOTO errmes
                        IF LEN(libname$) = 0 AND LEN(headername$) = 0 THEN a$ = "LIBRARY not found": GOTO errmes

                        '***actual method should cull redundant header and library entries***

                        IF dynamiclibrary = 0 THEN

                            'static
                            IF LEN(libname$) THEN
                                IF os$ = "WIN" THEN
                                    mylib$ = mylib$ + " ..\..\" + libname$ + " "
                                END IF
                                IF os$ = "LNX" THEN
                                    IF LEFT$(libname$, 1) = "/" THEN
                                        mylib$ = mylib$ + " " + libname$ + " "
                                    ELSE
                                        mylib$ = mylib$ + " ../../" + libname$ + " "
                                    END IF
                                END IF

                            END IF

                        ELSE

                            'dynamic
                            IF LEN(headername$) = 0 THEN 'no header

                                IF subfuncn THEN
                                    f = FREEFILE
                                    OPEN tmpdir$ + "maindata.txt" FOR APPEND AS #f
                                ELSE
                                    f = 13
                                END IF

                                'make name a C-appropriate variable name
                                'by converting everything except numbers and
                                'letters to underscores
                                x2$ = x$
                                FOR x2 = 1 TO LEN(x2$)
                                    IF ASC(x2$, x2) < 48 THEN ASC(x2$, x2) = 95
                                    IF ASC(x2$, x2) > 57 AND ASC(x2$, x2) < 65 THEN ASC(x2$, x2) = 95
                                    IF ASC(x2$, x2) > 90 AND ASC(x2$, x2) < 97 THEN ASC(x2$, x2) = 95
                                    IF ASC(x2$, x2) > 122 THEN ASC(x2$, x2) = 95
                                NEXT
                                DLLname$ = x2$

                                IF sfdeclare THEN

                                    IF os$ = "WIN" THEN
                                        PRINT #17, "HINSTANCE DLL_" + x2$ + "=NULL;"
                                        PRINT #f, "if (!DLL_" + x2$ + "){"
                                        PRINT #f, "DLL_" + x2$ + "=LoadLibrary(" + CHR$(34) + inlinelibname$ + CHR$(34) + ");"
                                        PRINT #f, "if (!DLL_" + x2$ + ") error(259);"
                                        PRINT #f, "}"
                                    END IF

                                    IF os$ = "LNX" THEN
                                        PRINT #17, "void *DLL_" + x2$ + "=NULL;"
                                        PRINT #f, "if (!DLL_" + x2$ + "){"
                                        PRINT #f, "DLL_" + x2$ + "=dlopen(" + CHR$(34) + inlinelibname$ + CHR$(34) + ",RTLD_LAZY);"
                                        PRINT #f, "if (!DLL_" + x2$ + ") error(259);"
                                        PRINT #f, "}"
                                    END IF


                                END IF

                                IF subfuncn THEN CLOSE #f

                            END IF 'no header

                        END IF 'dynamiclibrary

                        IF LEN(headername$) THEN
                            IF os$ = "WIN" THEN
                                PRINT #17, "#include " + CHR$(34) + "..\\..\\" + headername$ + CHR$(34)
                            END IF
                            IF os$ = "LNX" THEN

                                IF LEFT$(headername$, 1) = "/" THEN
                                    PRINT #17, "#include " + CHR$(34) + headername$ + CHR$(34)
                                ELSE
                                    PRINT #17, "#include " + CHR$(34) + "../../" + headername$ + CHR$(34)
                                END IF

                            END IF
                        END IF

                    END IF

                    l$ = l$ + sp + CHR$(34) + autoformat_x$ + CHR$(34)

                    IF n > x THEN
                        IF dynamiclibrary THEN a$ = "Cannot specify multiple DYNAMIC LIBRARY names in a single DECLARE statement": GOTO errmes
                        x = x + 1: x2$ = getelement$(a$, x): IF x2$ <> "," THEN a$ = "Expected ,": GOTO errmes
                        l$ = l$ + sp2 + ","
                        x = x + 1: IF x > n THEN a$ = "Expected , ...": GOTO errmes
                        GOTO addlibrary
                    END IF

                END IF 'n>=x

                layoutdone = 1: IF LEN(layout$) THEN layout$ = layout$ + sp + l$ ELSE layout$ = l$
                GOTO finishednonexec
            END IF

            GOTO finishednonexec 'note: no layout required
        END IF
    END IF

    'begin SUB/FUNCTION
    IF n >= 1 THEN
        dynamiclibrary = 0
        declaresubfunc2:
        sf = 0
        IF firstelement$ = "FUNCTION" THEN sf = 1
        IF firstelement$ = "SUB" THEN sf = 2
        IF sf THEN

            IF declaringlibrary = 0 THEN
                IF LEN(subfunc) THEN a$ = "Expected END SUB/FUNCTION before " + firstelement$: GOTO errmes
            END IF

            IF n = 1 THEN a$ = "Expected name after SUB/FUNCTION": GOTO errmes
            e$ = getelement$(ca$, 2)
            symbol$ = removesymbol$(e$) '$,%,etc.
            IF Error_Happened THEN GOTO errmes
            IF sf = 2 AND symbol$ <> "" THEN a$ = "Type symbols after a SUB name are invalid": GOTO errmes
            try = findid(e$)
            IF Error_Happened THEN GOTO errmes
            DO WHILE try
                IF id.subfunc = sf THEN GOTO createsf
                IF try = 2 THEN findanotherid = 1: try = findid(e$) ELSE try = 0
                IF Error_Happened THEN GOTO errmes
            LOOP
            a$ = "Unregistered SUB/FUNCTION encountered": GOTO errmes
            createsf:
            IF UCASE$(e$) = "_GL" THEN e$ = "_GL"
            l$ = firstelement$ + sp + e$ + symbol$
            id2 = id
            targetid = currentid

            'check for ALIAS
            aliasname$ = RTRIM$(id.cn)
            IF n > 2 THEN
                ee$ = getelement$(a$, 3)
                IF ee$ = "ALIAS" THEN
                    IF declaringlibrary = 0 THEN a$ = "ALIAS can only be used with DECLARE LIBRARY": GOTO errmes
                    IF n = 3 THEN a$ = "Expected ALIAS name-in-library": GOTO errmes
                    ee$ = getelement$(ca$, 4)

                    'strip string content (optional)
                    IF LEFT$(ee$, 1) = CHR$(34) THEN
                        ee$ = RIGHT$(ee$, LEN(ee$) - 1)
                        x = INSTR(ee$, CHR$(34)): IF x = 0 THEN a$ = "Expected " + CHR$(34): GOTO errmes
                        ee$ = LEFT$(ee$, x - 1)
                        l$ = l$ + sp + "ALIAS" + sp + CHR_QUOTE + ee$ + CHR_QUOTE
                    ELSE
                        l$ = l$ + sp + "ALIAS" + sp + ee$
                    END IF

                    'strip fix046$ (created by unquoted periods)
                    DO WHILE INSTR(ee$, fix046$)
                        x = INSTR(ee$, fix046$): ee$ = LEFT$(ee$, x - 1) + "." + RIGHT$(ee$, LEN(ee$) - x + 1 - LEN(fix046$))
                    LOOP
                    aliasname$ = ee$
                    'remove ALIAS section from line
                    IF n <= 4 THEN a$ = getelements(a$, 1, 2)
                    IF n >= 5 THEN a$ = getelements(a$, 1, 2) + sp + getelements(a$, 5, n)
                    IF n <= 4 THEN ca$ = getelements(ca$, 1, 2)
                    IF n >= 5 THEN ca$ = getelements(ca$, 1, 2) + sp + getelements(ca$, 5, n)
                    n = n - 2
                END IF
            END IF

            IF declaringlibrary THEN GOTO declibjmp1


            IF closedmain = 0 THEN closemain

            'check for open controls (copy #2)
            IF controllevel THEN
                x = controltype(controllevel)
                IF x = 1 THEN a$ = "IF without END IF"
                IF x = 2 THEN a$ = "FOR without NEXT"
                IF x = 3 OR x = 4 THEN a$ = "DO without LOOP"
                IF x = 5 THEN a$ = "WHILE without WEND"
                IF (x >= 10 AND x <= 17) OR x = 18 OR x = 19 THEN a$ = "SELECT CASE without END SELECT"
                linenumber = controlref(controllevel)
                GOTO errmes
            END IF

            subfunc = RTRIM$(id.callname) 'SUB_..."
            subfuncn = subfuncn + 1
            subfuncid = targetid

            subfuncret$ = ""

            CLOSE #13: OPEN tmpdir$ + "data" + str2$(subfuncn) + ".txt" FOR OUTPUT AS #13
            CLOSE #19: OPEN tmpdir$ + "free" + str2$(subfuncn) + ".txt" FOR OUTPUT AS #19
            CLOSE #15: OPEN tmpdir$ + "ret" + str2$(subfuncn) + ".txt" FOR OUTPUT AS #15
            PRINT #15, "if (next_return_point){"
            PRINT #15, "next_return_point--;"
            PRINT #15, "switch(return_point[next_return_point]){"
            PRINT #15, "case 0:"
            PRINT #15, "error(3);" 'return without gosub!
            PRINT #15, "break;"
            defdatahandle = 13

            declibjmp1:

            IF declaringlibrary THEN
                IF sfdeclare = 0 AND indirectlibrary = 0 THEN
                    CLOSE #17
                    OPEN tmpdir$ + "regsf_ignore.txt" FOR OUTPUT AS #17
                END IF
                IF sfdeclare = 1 AND customtypelibrary = 0 AND dynamiclibrary = 0 AND indirectlibrary = 0 THEN
                    PRINT #17, "#include " + CHR$(34) + "externtype" + str2(ResolveStaticFunctions + 1) + ".txt" + CHR$(34)
                    fh = FREEFILE: OPEN tmpdir$ + "externtype" + str2(ResolveStaticFunctions + 1) + ".txt" FOR OUTPUT AS #fh: CLOSE #fh
                END IF
            END IF




            IF sf = 1 THEN
                rettyp = id.ret
                t$ = typ2ctyp$(id.ret, "")
                IF Error_Happened THEN GOTO errmes
                IF t$ = "qbs" THEN t$ = "qbs*"

                IF declaringlibrary THEN
                    IF rettyp AND ISSTRING THEN
                        t$ = "char*"
                    END IF
                END IF

                IF declaringlibrary <> 0 AND dynamiclibrary <> 0 THEN
                    IF os$ = "WIN" THEN
                        PRINT #17, "typedef " + t$ + " (CALLBACK* DLLCALL_" + removecast$(RTRIM$(id.callname)) + ")(";
                    END IF
                    IF os$ = "LNX" THEN
                        PRINT #17, "typedef " + t$ + " (*DLLCALL_" + removecast$(RTRIM$(id.callname)) + ")(";
                    END IF
                ELSEIF declaringlibrary <> 0 AND customtypelibrary <> 0 THEN
                    PRINT #17, "typedef " + t$ + " CUSTOMCALL_" + removecast$(RTRIM$(id.callname)) + "(";
                ELSE
                    PRINT #17, t$ + " " + removecast$(RTRIM$(id.callname)) + "(";
                END IF
                IF declaringlibrary THEN GOTO declibjmp2
                PRINT #12, t$ + " " + removecast$(RTRIM$(id.callname)) + "(";

                'create variable to return result
                'if type wasn't specified, define it
                IF symbol$ = "" THEN
                    a = ASC(UCASE$(e$)): IF a = 95 THEN a = 91
                    a = a - 64 'so A=1, Z=27 and _=28
                    symbol$ = defineextaz(a)
                END IF
                reginternalvariable = 1
                ignore = dim2(e$, symbol$, 0, "")
                IF Error_Happened THEN GOTO errmes
                reginternalvariable = 0
                'the following line stops the return variable from being free'd before being returned
                CLOSE #19: OPEN tmpdir$ + "free" + str2$(subfuncn) + ".txt" FOR OUTPUT AS #19
                'create return
                IF (rettyp AND ISSTRING) THEN
                    r$ = refer$(str2$(currentid), id.t, 1)
                    IF Error_Happened THEN GOTO errmes
                    subfuncret$ = subfuncret$ + "qbs_maketmp(" + r$ + ");"
                    subfuncret$ = subfuncret$ + "return " + r$ + ";"
                ELSE
                    r$ = refer$(str2$(currentid), id.t, 0)
                    IF Error_Happened THEN GOTO errmes
                    subfuncret$ = "return " + r$ + ";"
                END IF
            ELSE

                IF declaringlibrary <> 0 AND dynamiclibrary <> 0 THEN
                    IF os$ = "WIN" THEN
                        PRINT #17, "typedef void (CALLBACK* DLLCALL_" + removecast$(RTRIM$(id.callname)) + ")(";
                    END IF
                    IF os$ = "LNX" THEN
                        PRINT #17, "typedef void (*DLLCALL_" + removecast$(RTRIM$(id.callname)) + ")(";
                    END IF
                ELSEIF declaringlibrary <> 0 AND customtypelibrary <> 0 THEN
                    PRINT #17, "typedef void CUSTOMCALL_" + removecast$(RTRIM$(id.callname)) + "(";
                ELSE
                    PRINT #17, "void " + removecast$(RTRIM$(id.callname)) + "(";
                END IF
                IF declaringlibrary THEN GOTO declibjmp2
                PRINT #12, "void " + removecast$(RTRIM$(id.callname)) + "(";
            END IF
            declibjmp2:

            addstatic2layout = 0
            staticsf = 0
            e$ = getelement$(a$, n)
            IF e$ = "STATIC" THEN
                IF declaringlibrary THEN a$ = "STATIC cannot be used in a library declaration": GOTO errmes
                addstatic2layout = 1
                staticsf = 2
                a$ = LEFT$(a$, LEN(a$) - 7): n = n - 1 'remove STATIC
            END IF

            'check items to pass
            params = 0
            AllowLocalName = 1
            IF n > 2 THEN
                e$ = getelement$(a$, 3)
                IF e$ <> "(" THEN a$ = "Expected (": GOTO errmes
                e$ = getelement$(a$, n)
                IF e$ <> ")" THEN a$ = "Expected )": GOTO errmes
                l$ = l$ + sp + "("
                IF n = 4 THEN GOTO nosfparams2
                IF n < 4 THEN a$ = "Expected ( ... )": GOTO errmes
                B = 0
                a2$ = ""
                FOR i = 4 TO n - 1
                    e$ = getelement$(ca$, i)
                    IF e$ = "(" THEN B = B + 1
                    IF e$ = ")" THEN B = B - 1
                    IF e$ = "," AND B = 0 THEN
                        IF i = n - 1 THEN a$ = "Expected , ... )": GOTO errmes
                        getlastparam2:
                        IF a2$ = "" THEN a$ = "Expected ... ,": GOTO errmes
                        a2$ = LEFT$(a2$, LEN(a2$) - 1)
                        'possible format: [BYVAL]a[%][(1)][AS][type]
                        params = params + 1
                        glinkid = targetid
                        glinkarg = params



                        IF params > 1 THEN
                            PRINT #17, ",";

                            IF declaringlibrary = 0 THEN
                                PRINT #12, ",";
                            END IF

                        END IF
                        n2 = numelements(a2$)
                        array = 0
                        t2$ = ""
                        e$ = getelement$(a2$, 1)

                        byvalue = 0
                        IF UCASE$(e$) = "BYVAL" THEN
                            IF declaringlibrary = 0 THEN a$ = "BYVAL can currently only be used with DECLARE LIBRARY": GOTO errmes
                            byvalue = 1: a2$ = RIGHT$(a2$, LEN(a2$) - 6)
                            IF RIGHT$(l$, 1) = "(" THEN l$ = l$ + sp2 + "BYVAL" ELSE l$ = l$ + sp + "BYVAL"
                            n2 = numelements(a2$): e$ = getelement$(a2$, 1)
                        END IF

                        IF RIGHT$(l$, 1) = "(" THEN l$ = l$ + sp2 + e$ ELSE l$ = l$ + sp + e$

                        n2$ = e$
                        dimmethod = 0


                        symbol2$ = removesymbol$(n2$)
                        IF validname(n2$) = 0 THEN a$ = "Invalid name": GOTO errmes

                        IF Error_Happened THEN GOTO errmes
                        IF symbol2$ <> "" THEN dimmethod = 1
                        m = 0
                        FOR i2 = 2 TO n2
                            e$ = getelement$(a2$, i2)
                            IF e$ = "(" THEN
                                IF m <> 0 THEN a$ = "Syntax error": GOTO errmes
                                m = 1
                                array = 1
                                l$ = l$ + sp2 + "("
                                GOTO gotaa2
                            END IF
                            IF e$ = ")" THEN
                                IF m <> 1 THEN a$ = "Syntax error": GOTO errmes
                                m = 2
                                l$ = l$ + sp2 + ")"
                                GOTO gotaa2
                            END IF
                            IF UCASE$(e$) = "AS" THEN
                                IF m <> 0 AND m <> 2 THEN a$ = "Syntax error": GOTO errmes
                                m = 3
                                l$ = l$ + sp + "AS"
                                GOTO gotaa2
                            END IF
                            IF m = 1 THEN l$ = l$ + sp + e$: GOTO gotaa2 'ignore contents of option bracket telling how many dimensions (add to layout as is)
                            IF m <> 3 THEN a$ = "Syntax error": GOTO errmes
                            IF t2$ = "" THEN t2$ = e$ ELSE t2$ = t2$ + " " + e$
                            gotaa2:
                        NEXT i2
                        IF symbol2$ <> "" AND t2$ <> "" THEN a$ = "Syntax error": GOTO errmes


                        IF LEN(t2$) THEN 'add type-name after AS
                            t2$ = UCASE$(t2$)
                            t3$ = t2$
                            typ = typname2typ(t3$)
                            IF Error_Happened THEN GOTO errmes
                            IF typ = 0 THEN a$ = "Undefined type": GOTO errmes
                            IF typ AND ISUDT THEN
                                t3$ = RTRIM$(udtxcname(typ AND 511))
                            ELSE
                                FOR t3i = 1 TO LEN(t3i)
                                    IF ASC(t3$, t3i) = 32 THEN ASC(t3$, t3i) = ASC(sp)
                                NEXT
                            END IF
                            l$ = l$ + sp + t3$
                        END IF

                        IF t2$ = "" THEN t2$ = symbol2$
                        IF t2$ = "" THEN
                            IF LEFT$(n2$, 1) = "_" THEN v = 27 ELSE v = ASC(UCASE$(n2$)) - 64
                            t2$ = defineaz(v)
                            dimmethod = 1
                        END IF




                        IF array = 1 THEN
                            IF declaringlibrary THEN a$ = "Arrays cannot be passed to a library": GOTO errmes
                            dimsfarray = 1
                            'note: id2.nele is currently 0
                            nelereq = ASC(MID$(id2.nelereq, params, 1))
                            IF nelereq THEN
                                nele = nelereq
                                MID$(id2.nele, params, 1) = CHR$(nele)

                                ids(targetid) = id2

                                ignore = dim2(n2$, t2$, dimmethod, str2$(nele))
                                IF Error_Happened THEN GOTO errmes
                            ELSE
                                nele = 1
                                MID$(id2.nele, params, 1) = CHR$(nele)

                                ids(targetid) = id2

                                ignore = dim2(n2$, t2$, dimmethod, "?")
                                IF Error_Happened THEN GOTO errmes
                            END IF

                            dimsfarray = 0
                            r$ = refer$(str2$(currentid), id.t, 1)
                            IF Error_Happened THEN GOTO errmes
                            PRINT #17, "ptrszint*" + r$;
                            PRINT #12, "ptrszint*" + r$;
                        ELSE

                            IF declaringlibrary THEN
                                'is it a udt?
                                FOR xx = 1 TO lasttype
                                    IF t2$ = RTRIM$(udtxname(xx)) THEN
                                        PRINT #17, "void*"
                                        GOTO decudt
                                    END IF
                                NEXT
                                t$ = typ2ctyp$(0, t2$)

                                IF Error_Happened THEN GOTO errmes
                                IF t$ = "qbs" THEN
                                    t$ = "char*"
                                    IF byvalue = 1 THEN a$ = "STRINGs cannot be passed using BYVAL": GOTO errmes
                                    byvalue = 1 'use t$ as is
                                END IF
                                IF byvalue THEN PRINT #17, t$; ELSE PRINT #17, t$ + "*";
                                decudt:
                                GOTO declibjmp3
                            END IF

                            dimsfarray = 1
                            ignore = dim2(n2$, t2$, dimmethod, "")
                            IF Error_Happened THEN GOTO errmes


                            dimsfarray = 0
                            t$ = ""
                            typ = id.t 'the typ of the ID created by dim2

                            t$ = typ2ctyp$(typ, "")
                            IF Error_Happened THEN GOTO errmes



                            IF t$ = "" THEN a$ = "Cannot find C type to return array data": GOTO errmes
                            'searchpoint
                            'get the name of the variable
                            r$ = refer$(str2$(currentid), id.t, 1)
                            IF Error_Happened THEN GOTO errmes
                            PRINT #17, t$ + "*" + r$;
                            PRINT #12, t$ + "*" + r$;
                            IF t$ = "qbs" THEN
                                u$ = str2$(uniquenumber)
                                PRINT #13, "qbs*oldstr" + u$ + "=NULL;"
                                PRINT #13, "if(" + r$ + "->tmp||" + r$ + "->fixed||" + r$ + "->readonly){"
                                PRINT #13, "oldstr" + u$ + "=" + r$ + ";"

                                PRINT #13, "if (oldstr" + u$ + "->cmem_descriptor){"
                                PRINT #13, r$ + "=qbs_new_cmem(oldstr" + u$ + "->len,0);"
                                PRINT #13, "}else{"
                                PRINT #13, r$ + "=qbs_new(oldstr" + u$ + "->len,0);"
                                PRINT #13, "}"

                                PRINT #13, "memcpy(" + r$ + "->chr,oldstr" + u$ + "->chr,oldstr" + u$ + "->len);"
                                PRINT #13, "}"

                                PRINT #19, "if(oldstr" + u$ + "){"
                                PRINT #19, "if(oldstr" + u$ + "->fixed)qbs_set(oldstr" + u$ + "," + r$ + ");"
                                PRINT #19, "qbs_free(" + r$ + ");"
                                PRINT #19, "}"
                            END IF
                        END IF
                        declibjmp3:
                        IF i <> n - 1 THEN l$ = l$ + sp2 + ","

                        a2$ = ""
                    ELSE
                        a2$ = a2$ + e$ + sp
                        IF i = n - 1 THEN GOTO getlastparam2
                    END IF
                NEXT i
                nosfparams2:
                l$ = l$ + sp2 + ")"
            END IF 'n>2
            AllowLocalName = 0

            IF addstatic2layout THEN l$ = l$ + sp + "STATIC"
            layoutdone = 1: IF LEN(layout$) THEN layout$ = layout$ + sp + l$ ELSE layout$ = l$

            PRINT #17, ");"

            IF declaringlibrary THEN GOTO declibjmp4

            PRINT #12, "){"
            PRINT #12, "qbs *tqbs;"
            PRINT #12, "ptrszint tmp_long;"
            PRINT #12, "int32 tmp_fileno;"
            PRINT #12, "uint32 qbs_tmp_base=qbs_tmp_list_nexti;"
            PRINT #12, "uint8 *tmp_mem_static_pointer=mem_static_pointer;"
            PRINT #12, "uint32 tmp_cmem_sp=cmem_sp;"
            PRINT #12, "#include " + CHR$(34) + "data" + str2$(subfuncn) + ".txt" + CHR$(34)

            'create new _MEM lock for this scope
            PRINT #12, "mem_lock *sf_mem_lock;" 'MUST not be static for recursion reasons
            PRINT #12, "new_mem_lock();"
            PRINT #12, "sf_mem_lock=mem_lock_tmp;"
            PRINT #12, "sf_mem_lock->type=3;"

            PRINT #12, "if (new_error) goto exit_subfunc;"

            'statementn = statementn + 1
            'if nochecks=0 then PRINT #12, "S_" + str2$(statementn) + ":;"

            dimstatic = staticsf

            declibjmp4:

            IF declaringlibrary THEN

                IF customtypelibrary THEN

                    callname$ = removecast$(RTRIM$(id2.callname))

                    PRINT #17, "CUSTOMCALL_" + callname$ + " *" + callname$ + "=NULL;"

                    IF subfuncn THEN
                        f = FREEFILE
                        OPEN tmpdir$ + "maindata.txt" FOR APPEND AS #f
                    ELSE
                        f = 13
                    END IF


                    PRINT #f, callname$ + "=(CUSTOMCALL_" + callname$ + "*)&" + aliasname$ + ";"

                    IF subfuncn THEN CLOSE #f

                    'if no header exists to make the external function available, the function definition must be found
                    IF sfheader = 0 AND sfdeclare <> 0 THEN
                        ResolveStaticFunctions = ResolveStaticFunctions + 1
                        'expand array if necessary
                        IF ResolveStaticFunctions > UBOUND(ResolveStaticFunction_Name) THEN
                            REDIM _PRESERVE ResolveStaticFunction_Name(1 TO ResolveStaticFunctions + 100) AS STRING
                            REDIM _PRESERVE ResolveStaticFunction_File(1 TO ResolveStaticFunctions + 100) AS STRING
                            REDIM _PRESERVE ResolveStaticFunction_Method(1 TO ResolveStaticFunctions + 100) AS LONG
                        END IF
                        ResolveStaticFunction_File(ResolveStaticFunctions) = libname$
                        ResolveStaticFunction_Name(ResolveStaticFunctions) = aliasname$
                        ResolveStaticFunction_Method(ResolveStaticFunctions) = 1
                    END IF 'sfheader=0

                END IF

                IF dynamiclibrary THEN
                    IF sfdeclare THEN

                        PRINT #17, "DLLCALL_" + removecast$(RTRIM$(id2.callname)) + " " + removecast$(RTRIM$(id2.callname)) + "=NULL;"

                        IF subfuncn THEN
                            f = FREEFILE
                            OPEN tmpdir$ + "maindata.txt" FOR APPEND AS #f
                        ELSE
                            f = 13
                        END IF

                        PRINT #f, "if (!" + removecast$(RTRIM$(id2.callname)) + "){"
                        IF os$ = "WIN" THEN
                            PRINT #f, removecast$(RTRIM$(id2.callname)) + "=(DLLCALL_" + removecast$(RTRIM$(id2.callname)) + ")GetProcAddress(DLL_" + DLLname$ + "," + CHR$(34) + aliasname$ + CHR$(34) + ");"
                            PRINT #f, "if (!" + removecast$(RTRIM$(id2.callname)) + ") error(260);"
                        END IF
                        IF os$ = "LNX" THEN
                            PRINT #f, removecast$(RTRIM$(id2.callname)) + "=(DLLCALL_" + removecast$(RTRIM$(id2.callname)) + ")dlsym(DLL_" + DLLname$ + "," + CHR$(34) + aliasname$ + CHR$(34) + ");"
                            PRINT #f, "if (dlerror()) error(260);"
                        END IF
                        PRINT #f, "}"

                        IF subfuncn THEN CLOSE #f

                    END IF 'sfdeclare
                END IF 'dynamic

                IF sfdeclare = 1 AND customtypelibrary = 0 AND dynamiclibrary = 0 AND indirectlibrary = 0 THEN
                    ResolveStaticFunctions = ResolveStaticFunctions + 1
                    'expand array if necessary
                    IF ResolveStaticFunctions > UBOUND(ResolveStaticFunction_Name) THEN
                        REDIM _PRESERVE ResolveStaticFunction_Name(1 TO ResolveStaticFunctions + 100) AS STRING
                        REDIM _PRESERVE ResolveStaticFunction_File(1 TO ResolveStaticFunctions + 100) AS STRING
                        REDIM _PRESERVE ResolveStaticFunction_Method(1 TO ResolveStaticFunctions + 100) AS LONG
                    END IF
                    ResolveStaticFunction_File(ResolveStaticFunctions) = libname$
                    ResolveStaticFunction_Name(ResolveStaticFunctions) = aliasname$
                    ResolveStaticFunction_Method(ResolveStaticFunctions) = 2
                END IF

                IF sfdeclare = 0 AND indirectlibrary = 0 THEN
                    CLOSE #17
                    OPEN tmpdir$ + "regsf.txt" FOR APPEND AS #17
                END IF

            END IF 'declaring library

            GOTO finishednonexec
        END IF
    END IF

    'END SUB/FUNCTION
    IF n = 2 THEN
        IF firstelement$ = "END" THEN
            sf = 0
            IF secondelement$ = "FUNCTION" THEN sf = 1
            IF secondelement$ = "SUB" THEN sf = 2
            IF sf THEN

                IF LEN(subfunc) = 0 THEN a$ = "END " + secondelement$ + " without " + secondelement$: GOTO errmes

                'check for open controls (copy #3)
                IF controllevel THEN
                    x = controltype(controllevel)
                    IF x = 1 THEN a$ = "IF without END IF"
                    IF x = 2 THEN a$ = "FOR without NEXT"
                    IF x = 3 OR x = 4 THEN a$ = "DO without LOOP"
                    IF x = 5 THEN a$ = "WHILE without WEND"
                    IF (x >= 10 AND x <= 17) OR x = 18 OR x = 19 THEN a$ = "SELECT CASE without END SELECT"
                    linenumber = controlref(controllevel)
                    GOTO errmes
                END IF

                l$ = firstelement$ + sp + secondelement$
                layoutdone = 1: IF LEN(layout$) THEN layout$ = layout$ + sp + l$ ELSE layout$ = l$

                staticarraylist = "": staticarraylistn = 0 'remove previously listed arrays
                dimstatic = 0
                PRINT #12, "exit_subfunc:;"

                'release _MEM lock for this scope
                PRINT #12, "free_mem_lock(sf_mem_lock);"

                PRINT #12, "#include " + CHR$(34) + "free" + str2$(subfuncn) + ".txt" + CHR$(34)
                PRINT #12, "if ((tmp_mem_static_pointer>=mem_static)&&(tmp_mem_static_pointer<=mem_static_limit)) mem_static_pointer=tmp_mem_static_pointer; else mem_static_pointer=mem_static;"
                PRINT #12, "cmem_sp=tmp_cmem_sp;"
                IF subfuncret$ <> "" THEN PRINT #12, subfuncret$

                PRINT #12, "}" 'skeleton sub
                'ret???.txt
                PRINT #15, "}" 'end case
                PRINT #15, "}"
                PRINT #15, "error(3);" 'no valid return possible
                subfunc = ""

                'unshare temp. shared variables
                FOR i = 1 TO idn
                    IF ids(i).share AND 2 THEN ids(i).share = ids(i).share - 2
                NEXT

                FOR i = 1 TO revertmaymusthaven
                    x = revertmaymusthave(i)
                    SWAP ids(x).musthave, ids(x).mayhave
                NEXT
                revertmaymusthaven = 0

                'undeclare constants in sub/function's scope
                'constlast = constlastshared
                GOTO finishednonexec

            END IF
        END IF
    END IF



    IF n >= 1 AND firstelement$ = "CONST" THEN
        l$ = "CONST"
        'DEF... do not change type, the expression is stored in a suitable type
        'based on its value if type isn't forced/specified
        IF n < 3 THEN a$ = "Expected CONST name = value/expression": GOTO errmes
        i = 2

        constdefpending:
        pending = 0

        n$ = getelement$(ca$, i): i = i + 1
        l$ = l$ + sp + n$ + sp + "="
        typeoverride = 0
        s$ = removesymbol$(n$)
        IF Error_Happened THEN GOTO errmes
        IF s$ <> "" THEN
            typeoverride = typname2typ(s$)
            IF Error_Happened THEN GOTO errmes
            IF typeoverride AND ISFIXEDLENGTH THEN a$ = "Invalid constant type": GOTO errmes
            IF typeoverride = 0 THEN a$ = "Invalid constant type": GOTO errmes
        END IF

        IF getelement$(a$, i) <> "=" THEN a$ = "Expected =": GOTO errmes
        i = i + 1

        'get expression
        e$ = ""
        B = 0
        FOR i2 = i TO n
            e2$ = getelement$(ca$, i2)
            IF e2$ = "(" THEN B = B + 1
            IF e2$ = ")" THEN B = B - 1
            IF e2$ = "," AND B = 0 THEN
                pending = 1
                i = i2 + 1
                IF i > n - 2 THEN a$ = "Expected CONST ... , name = value/expression": GOTO errmes
                EXIT FOR
            END IF
            IF LEN(e$) = 0 THEN e$ = e2$ ELSE e$ = e$ + sp + e2$
        NEXT

        e$ = fixoperationorder(e$)
        IF Error_Happened THEN GOTO errmes
        l$ = l$ + sp + tlayout$

        'Note: Actual CONST definition handled in prepass

        'Set CONST as defined
        hashname$ = n$
        hashchkflags = HASHFLAG_CONSTANT
        hashres = HashFind(hashname$, hashchkflags, hashresflags, hashresref)
        DO WHILE hashres
            IF constsubfunc(hashresref) = subfuncn THEN constdefined(hashresref) = 1: EXIT DO
            IF hashres <> 1 THEN hashres = HashFindCont(hashresflags, hashresref) ELSE hashres = 0
        LOOP

        IF pending THEN l$ = l$ + sp2 + ",": GOTO constdefpending

        layoutdone = 1: IF LEN(layout$) THEN layout$ = layout$ + sp + l$ ELSE layout$ = l$

        GOTO finishednonexec
    END IF

    predefine:
    IF n >= 2 THEN
        asreq = 0
        IF firstelement$ = "DEFINT" THEN a$ = a$ + sp + "AS" + sp + "INTEGER": n = n + 2: GOTO definetype
        IF firstelement$ = "DEFLNG" THEN a$ = a$ + sp + "AS" + sp + "LONG": n = n + 2: GOTO definetype
        IF firstelement$ = "DEFSNG" THEN a$ = a$ + sp + "AS" + sp + "SINGLE": n = n + 2: GOTO definetype
        IF firstelement$ = "DEFDBL" THEN a$ = a$ + sp + "AS" + sp + "DOUBLE": n = n + 2: GOTO definetype
        IF firstelement$ = "DEFSTR" THEN a$ = a$ + sp + "AS" + sp + "STRING": n = n + 2: GOTO definetype
        IF firstelement$ = "_DEFINE" THEN
            asreq = 1
            definetype:
            l$ = firstelement$
            'get type from rhs
            typ$ = ""
            typ2$ = ""
            t$ = ""
            FOR i = n TO 2 STEP -1
                t$ = getelement$(a$, i)
                IF t$ = "AS" THEN EXIT FOR
                typ$ = t$ + " " + typ$
                typ2$ = t$ + sp + typ2$
            NEXT
            typ$ = RTRIM$(typ$)
            IF t$ <> "AS" THEN a$ = "_DEFINE: Expected ... AS ...": GOTO errmes
            IF i = n OR i = 2 THEN a$ = "_DEFINE: Expected ... AS ...": GOTO errmes


            n = i - 1
            'the data is from element 2 to element n
            i = 2 - 1
            definenext:
            'expects an alphabet letter or underscore
            i = i + 1: e$ = getelement$(a$, i): E = ASC(UCASE$(e$))
            IF LEN(e$) > 1 THEN a$ = "_DEFINE: Expected an alphabet letter or the underscore character (_)": GOTO errmes
            IF E <> 95 AND (E > 90 OR E < 65) THEN a$ = "_DEFINE: Expected an alphabet letter or the underscore character (_)": GOTO errmes
            IF E = 95 THEN E = 27 ELSE E = E - 64
            defineaz(E) = typ$
            defineextaz(E) = type2symbol(typ$)
            IF Error_Happened THEN GOTO errmes
            firste = E
            l$ = l$ + sp + e$

            IF i = n THEN
                IF predefining = 1 THEN GOTO predefined
                IF asreq THEN l$ = l$ + sp + "AS" + sp + typ2$
                layoutdone = 1: IF LEN(layout$) THEN layout$ = layout$ + sp + l$ ELSE layout$ = l$
                GOTO finishednonexec
            END IF

            'expects "-" or ","
            i = i + 1: e$ = getelement$(a$, i)
            IF e$ <> "-" AND e$ <> "," THEN a$ = "_DEFINE: Expected - or ,": GOTO errmes
            IF e$ = "-" THEN
                l$ = l$ + sp2 + "-"
                IF i = n THEN a$ = "_DEFINE: Syntax incomplete": GOTO errmes
                'expects an alphabet letter or underscore
                i = i + 1: e$ = getelement$(a$, i): E = ASC(UCASE$(e$))
                IF LEN(e$) > 1 THEN a$ = "_DEFINE: Expected an alphabet letter or the underscore character (_)": GOTO errmes
                IF E <> 95 AND (E > 90 OR E < 65) THEN a$ = "_DEFINE: Expected an alphabet letter or the underscore character (_)": GOTO errmes
                IF E = 95 THEN E = 27 ELSE E = E - 64
                IF firste > E THEN SWAP E, firste
                FOR e2 = firste TO E
                    defineaz(e2) = typ$
                    defineextaz(e2) = type2symbol(typ$)
                    IF Error_Happened THEN GOTO errmes
                NEXT
                l$ = l$ + sp2 + e$
                IF i = n THEN
                    IF predefining = 1 THEN GOTO predefined
                    IF asreq THEN l$ = l$ + sp + "AS" + sp + typ2$
                    layoutdone = 1: IF LEN(layout$) THEN layout$ = layout$ + sp + l$ ELSE layout$ = l$
                    GOTO finishednonexec
                END IF
                'expects ","
                i = i + 1: e$ = getelement$(a$, i)
                IF e$ <> "," THEN a$ = "_DEFINE: Expected ,": GOTO errmes
            END IF
            l$ = l$ + sp2 + ","
            GOTO definenext
        END IF '_DEFINE
    END IF '2
    IF predefining = 1 THEN GOTO predefined

    IF closedmain <> 0 AND subfunc = "" THEN a$ = "Statement cannot be placed between SUB/FUNCTIONs": GOTO errmes

    'executable section:

    statementn = statementn + 1


    IF n >= 1 THEN
        IF firstelement$ = "NEXT" THEN

            l$ = "NEXT"
            IF n = 1 THEN GOTO simplenext
            v$ = ""
            FOR i = 2 TO n
                a2$ = getelement(ca$, i)

                IF a2$ = "," THEN

                    lastnextele:
                    e$ = fixoperationorder(v$)
                    IF Error_Happened THEN GOTO errmes
                    IF LEN(l$) = 4 THEN l$ = l$ + sp + tlayout$ ELSE l$ = l$ + sp2 + "," + sp + tlayout$
                    e$ = evaluate(e$, typ)
                    IF Error_Happened THEN GOTO errmes
                    IF (typ AND ISREFERENCE) THEN
                        getid VAL(e$)
                        IF Error_Happened THEN GOTO errmes
                        IF (id.t AND ISPOINTER) THEN
                            IF (id.t AND ISSTRING) = 0 THEN
                                IF (id.t AND ISOFFSETINBITS) = 0 THEN
                                    IF (id.t AND ISARRAY) = 0 THEN
                                        GOTO fornextfoundvar2
                                    END IF
                                END IF
                            END IF
                        END IF
                    END IF
                    a$ = "Unsupported variable after NEXT": GOTO errmes
                    fornextfoundvar2:
                    simplenext:
                    IF controltype(controllevel) <> 2 THEN a$ = "NEXT without FOR": GOTO errmes
                    IF n <> 1 AND controlvalue(controllevel) <> currentid THEN a$ = "Incorrect variable after NEXT": GOTO errmes
                    PRINT #12, "}"
                    PRINT #12, "fornext_exit_" + str2$(controlid(controllevel)) + ":;"
                    controllevel = controllevel - 1
                    IF n = 1 THEN EXIT FOR
                    v$ = ""

                ELSE

                    IF LEN(v$) THEN v$ = v$ + sp + a2$ ELSE v$ = a2$
                    IF i = n THEN GOTO lastnextele

                END IF

            NEXT

            layoutdone = 1: IF LEN(layout$) THEN layout$ = layout$ + sp + l$ ELSE layout$ = l$
            GOTO finishednonexec '***no error causing code, event checking done by FOR***
        END IF
    END IF



    IF n >= 1 THEN
        IF firstelement$ = "WHILE" THEN
            IF NoChecks = 0 THEN PRINT #12, "S_" + str2$(statementn) + ":;": dynscope = 1

            controllevel = controllevel + 1
            controlref(controllevel) = linenumber
            controltype(controllevel) = 5
            controlid(controllevel) = uniquenumber
            IF n >= 2 THEN
                e$ = fixoperationorder(getelements$(ca$, 2, n))
                IF Error_Happened THEN GOTO errmes
                l$ = "WHILE" + sp + tlayout$
                layoutdone = 1: IF LEN(layout$) THEN layout$ = layout$ + sp + l$ ELSE layout$ = l$
                e$ = evaluate(e$, typ)
                IF Error_Happened THEN GOTO errmes
                IF (typ AND ISREFERENCE) THEN e$ = refer$(e$, typ, 0)
                IF Error_Happened THEN GOTO errmes
                IF stringprocessinghappened THEN e$ = cleanupstringprocessingcall$ + e$ + ")"
                IF (typ AND ISSTRING) THEN a$ = "WHILE ERROR! Cannot accept a STRING type.": GOTO errmes
                PRINT #12, "while((" + e$ + ")||new_error){"
            ELSE
                a$ = "WHILE ERROR! Expected expression after WHILE.": GOTO errmes
            END IF

            GOTO finishedline
        END IF
    END IF

    IF n = 1 THEN
        IF firstelement$ = "WEND" THEN


            IF controltype(controllevel) <> 5 THEN a$ = "WEND without WHILE": GOTO errmes
            PRINT #12, "}"
            PRINT #12, "ww_exit_" + str2$(controlid(controllevel)) + ":;"
            controllevel = controllevel - 1
            l$ = "WEND"
            layoutdone = 1: IF LEN(layout$) THEN layout$ = layout$ + sp + l$ ELSE layout$ = l$
            GOTO finishednonexec '***no error causing code, event checking done by WHILE***
        END IF
    END IF





    IF n >= 1 THEN
        IF firstelement$ = "DO" THEN
            IF NoChecks = 0 THEN PRINT #12, "S_" + str2$(statementn) + ":;": dynscope = 1
            controllevel = controllevel + 1
            controlref(controllevel) = linenumber
            l$ = "DO"
            IF n >= 2 THEN
                whileuntil = 0
                IF secondelement$ = "WHILE" THEN whileuntil = 1: l$ = l$ + sp + "WHILE"
                IF secondelement$ = "UNTIL" THEN whileuntil = 2: l$ = l$ + sp + "UNTIL"
                IF whileuntil = 0 THEN a$ = "DO ERROR! Expected WHILE or UNTIL after DO.": GOTO errmes
                e$ = fixoperationorder(getelements$(ca$, 3, n))
                IF Error_Happened THEN GOTO errmes
                l$ = l$ + sp + tlayout$
                e$ = evaluate(e$, typ)
                IF Error_Happened THEN GOTO errmes
                IF (typ AND ISREFERENCE) THEN e$ = refer$(e$, typ, 0)
                IF Error_Happened THEN GOTO errmes
                IF stringprocessinghappened THEN e$ = cleanupstringprocessingcall$ + e$ + ")"
                IF (typ AND ISSTRING) THEN a$ = "DO ERROR! Cannot accept a STRING type.": GOTO errmes
                IF whileuntil = 1 THEN PRINT #12, "while((" + e$ + ")||new_error){" ELSE PRINT #12, "while((!(" + e$ + "))||new_error){"
                controltype(controllevel) = 4
            ELSE
                controltype(controllevel) = 3
                PRINT #12, "do{"
            END IF
            controlid(controllevel) = uniquenumber
            layoutdone = 1: IF LEN(layout$) THEN layout$ = layout$ + sp + l$ ELSE layout$ = l$
            GOTO finishedline
        END IF
    END IF

    IF n >= 1 THEN
        IF firstelement$ = "LOOP" THEN
            l$ = "LOOP"
            IF controltype(controllevel) <> 3 AND controltype(controllevel) <> 4 THEN a$ = "PROGRAM FLOW ERROR!": GOTO errmes
            IF n >= 2 THEN
                IF NoChecks = 0 THEN PRINT #12, "S_" + str2$(statementn) + ":;": dynscope = 1
                IF controltype(controllevel) = 4 THEN a$ = "PROGRAM FLOW ERROR!": GOTO errmes
                whileuntil = 0
                IF secondelement$ = "WHILE" THEN whileuntil = 1: l$ = l$ + sp + "WHILE"
                IF secondelement$ = "UNTIL" THEN whileuntil = 2: l$ = l$ + sp + "UNTIL"
                IF whileuntil = 0 THEN a$ = "LOOP ERROR! Expected WHILE or UNTIL after LOOP.": GOTO errmes
                e$ = fixoperationorder(getelements$(ca$, 3, n))
                IF Error_Happened THEN GOTO errmes
                l$ = l$ + sp + tlayout$
                e$ = evaluate(e$, typ)
                IF Error_Happened THEN GOTO errmes
                IF (typ AND ISREFERENCE) THEN e$ = refer$(e$, typ, 0)
                IF Error_Happened THEN GOTO errmes
                IF stringprocessinghappened THEN e$ = cleanupstringprocessingcall$ + e$ + ")"
                IF (typ AND ISSTRING) THEN a$ = "LOOP ERROR! Cannot accept a STRING type.": GOTO errmes
                IF whileuntil = 1 THEN PRINT #12, "}while((" + e$ + ")&&(!new_error));" ELSE PRINT #12, "}while((!(" + e$ + "))&&(!new_error));"
            ELSE
                IF controltype(controllevel) = 4 THEN
                    PRINT #12, "}"
                ELSE
                    PRINT #12, "}while(1);" 'infinite loop!
                END IF
            END IF
            PRINT #12, "dl_exit_" + str2$(controlid(controllevel)) + ":;"
            controllevel = controllevel - 1
            layoutdone = 1: IF LEN(layout$) THEN layout$ = layout$ + sp + l$ ELSE layout$ = l$
            IF n = 1 THEN GOTO finishednonexec '***no error causing code, event checking done by DO***
            GOTO finishedline
        END IF
    END IF









    IF n >= 1 THEN
        IF firstelement$ = "FOR" THEN
            IF NoChecks = 0 THEN PRINT #12, "S_" + str2$(statementn) + ":;": dynscope = 1

            l$ = "FOR"
            controllevel = controllevel + 1
            controlref(controllevel) = linenumber
            controltype(controllevel) = 2
            controlid(controllevel) = uniquenumber

            v$ = ""
            startvalue$ = ""
            p3$ = "1": stepused = 0
            p2$ = ""
            mode = 0
            E = 0
            FOR i = 2 TO n
                e$ = getelement$(a$, i)
                IF e$ = "=" THEN
                    IF mode <> 0 THEN E = 1: EXIT FOR
                    mode = 1
                    v$ = getelements$(ca$, 2, i - 1)
                    equpos = i
                END IF
                IF e$ = "TO" THEN
                    IF mode <> 1 THEN E = 1: EXIT FOR
                    mode = 2
                    startvalue$ = getelements$(ca$, equpos + 1, i - 1)
                    topos = i
                END IF
                IF e$ = "STEP" THEN
                    IF mode <> 2 THEN E = 1: EXIT FOR
                    mode = 3
                    stepused = 1
                    p2$ = getelements$(ca$, topos + 1, i - 1)
                    p3$ = getelements$(ca$, i + 1, n)
                    EXIT FOR
                END IF
            NEXT
            IF mode < 2 THEN E = 1
            IF p2$ = "" THEN p2$ = getelements$(ca$, topos + 1, n)
            IF LEN(v$) = 0 OR LEN(startvalue$) = 0 OR LEN(p2$) = 0 THEN E = 1
            IF E <> 0 AND mode < 3 THEN a$ = "Expected FOR name = start TO end": GOTO errmes
            IF E THEN a$ = "Expected FOR name = start TO end STEP increment": GOTO errmes

            e$ = fixoperationorder(v$)
            IF Error_Happened THEN GOTO errmes
            l$ = l$ + sp + tlayout$
            e$ = evaluate(e$, typ)
            IF Error_Happened THEN GOTO errmes
            IF (typ AND ISREFERENCE) THEN
                getid VAL(e$)
                IF Error_Happened THEN GOTO errmes
                IF (id.t AND ISPOINTER) THEN
                    IF (id.t AND ISSTRING) = 0 THEN
                        IF (id.t AND ISOFFSETINBITS) = 0 THEN
                            IF (id.t AND ISARRAY) = 0 THEN
                                GOTO fornextfoundvar
                            END IF
                        END IF
                    END IF
                END IF
            END IF
            a$ = "Unsupported variable used in FOR statement": GOTO errmes
            fornextfoundvar:
            controlvalue(controllevel) = currentid
            v$ = e$

            'find C++ datatype to match variable
            'markup to cater for greater range/accuracy
            ctype$ = ""
            ctyp = typ - ISPOINTER
            bits = typ AND 511
            IF (typ AND ISFLOAT) THEN
                IF bits = 32 THEN ctype$ = "double": ctyp = 64& + ISFLOAT
                IF bits = 64 THEN ctype$ = "long double": ctyp = 256& + ISFLOAT
                IF bits = 256 THEN ctype$ = "long double": ctyp = 256& + ISFLOAT
            ELSE
                IF bits = 8 THEN ctype$ = "int16": ctyp = 16&
                IF bits = 16 THEN ctype$ = "int32": ctyp = 32&
                IF bits = 32 THEN ctype$ = "int64": ctyp = 64&
                IF bits = 64 THEN ctype$ = "int64": ctyp = 64&
            END IF
            IF ctype$ = "" THEN a$ = "Unsupported variable used in FOR statement": GOTO errmes
            u$ = str2(uniquenumber)

            IF subfunc = "" THEN
                PRINT #13, "static " + ctype$ + " fornext_value" + u$ + ";"
                PRINT #13, "static " + ctype$ + " fornext_finalvalue" + u$ + ";"
                PRINT #13, "static " + ctype$ + " fornext_step" + u$ + ";"
                PRINT #13, "static uint8 fornext_step_negative" + u$ + ";"
            ELSE
                PRINT #13, ctype$ + " fornext_value" + u$ + ";"
                PRINT #13, ctype$ + " fornext_finalvalue" + u$ + ";"
                PRINT #13, ctype$ + " fornext_step" + u$ + ";"
                PRINT #13, "uint8 fornext_step_negative" + u$ + ";"
            END IF

            'calculate start
            e$ = fixoperationorder$(startvalue$)
            IF Error_Happened THEN GOTO errmes
            l$ = l$ + sp + "=" + sp + tlayout$
            e$ = evaluatetotyp$(e$, ctyp)
            IF Error_Happened THEN GOTO errmes
            PRINT #12, "fornext_value" + u$ + "=" + e$ + ";"

            'final
            e$ = fixoperationorder$(p2$)
            IF Error_Happened THEN GOTO errmes
            l$ = l$ + sp + "TO" + sp + tlayout$
            e$ = evaluatetotyp(e$, ctyp)
            IF Error_Happened THEN GOTO errmes
            PRINT #12, "fornext_finalvalue" + u$ + "=" + e$ + ";"

            'step
            e$ = fixoperationorder$(p3$)
            IF Error_Happened THEN GOTO errmes
            IF stepused = 1 THEN l$ = l$ + sp + "STEP" + sp + tlayout$
            e$ = evaluatetotyp(e$, ctyp)
            IF Error_Happened THEN GOTO errmes
            PRINT #12, "fornext_step" + u$ + "=" + e$ + ";"
            PRINT #12, "if (fornext_step" + u$ + "<0) fornext_step_negative" + u$ + "=1; else fornext_step_negative" + u$ + "=0;"

            PRINT #12, "if (new_error) goto fornext_error" + u$ + ";"
            PRINT #12, "goto fornext_entrylabel" + u$ + ";"
            PRINT #12, "while(1){"
            typbak = typ
            PRINT #12, "fornext_value" + u$ + "=fornext_step" + u$ + "+(" + refer$(v$, typ, 0) + ");"
            IF Error_Happened THEN GOTO errmes
            typ = typbak
            PRINT #12, "fornext_entrylabel" + u$ + ":"
            setrefer v$, typ, "fornext_value" + u$, 1
            IF Error_Happened THEN GOTO errmes
            PRINT #12, "if (fornext_step_negative" + u$ + "){"
            PRINT #12, "if (fornext_value" + u$ + "<fornext_finalvalue" + u$ + ") break;"
            PRINT #12, "}else{"
            PRINT #12, "if (fornext_value" + u$ + ">fornext_finalvalue" + u$ + ") break;"
            PRINT #12, "}"
            PRINT #12, "fornext_error" + u$ + ":;"

            layoutdone = 1: IF LEN(layout$) THEN layout$ = layout$ + sp + l$ ELSE layout$ = l$

            GOTO finishedline
        END IF
    END IF


    IF n = 1 THEN
        IF firstelement$ = "ELSE" THEN

            'Routine to add error checking for ELSE so we'll no longer be able to do things like the following:
            'IF x = 1 THEN
            '    SELECT CASE s
            '        CASE 1
            '    END SELECT ELSE y = 2
            'END IF
            'Notice the ELSE with the SELECT CASE?  Before this patch, commands like those were considered valid QB64 code.
            temp$ = UCASE$(LTRIM$(RTRIM$(wholeline)))
            goodelse = 0 'a check to see if it's a good else
            IF LEFT$(temp$, 2) = "IF" THEN goodelse = -1: GOTO skipelsecheck 'If we have an IF, the else is probably good
            IF LEFT$(temp$, 4) = "ELSE" THEN goodelse = -1: GOTO skipelsecheck 'If it's an else by itself,then we'll call it good too at this point and let the rest of the syntax checking check for us
            DO
                spacelocation = INSTR(temp$, " ")
                IF spacelocation THEN temp$ = LEFT$(temp$, spacelocation - 1) + MID$(temp$, spacelocation + 1)
            LOOP UNTIL spacelocation = 0
            IF INSTR(temp$, ":ELSE") OR INSTR(temp$, ":IF") THEN goodelse = -1: GOTO skipelsecheck 'I personally don't like the idea of a :ELSE statement, but this checks for that and validates it as well.  YUCK!  (I suppose this might be useful if there's a label where the ELSE is, like thisline: ELSE
            count = 0
            DO
                count = count + 1
                SELECT CASE MID$(temp$, count, 1)
                    CASE IS = "1", "2", "3", "4", "5", "6", "7", "8", "9", "0", ":"
                    CASE ELSE: EXIT DO
                END SELECT
            LOOP UNTIL count >= LEN(temp$)
            IF MID$(temp$, count, 4) = "ELSE" OR MID$(temp$, count, 2) = "IF" THEN goodelse = -1 'We only had numbers before our else
            IF NOT goodelse THEN a$ = "Invalid Syntax for ELSE": GOTO errmes
            skipelsecheck:
            'End of ELSE Error checking
            FOR i = controllevel TO 1 STEP -1
                t = controltype(i)
                IF t = 1 THEN
                    IF controlstate(controllevel) = 2 THEN a$ = "IF-THEN already contains an ELSE statement": GOTO errmes
                    PRINT #12, "}else{"
                    controlstate(controllevel) = 2
                    IF lineelseused = 0 THEN lhscontrollevel = lhscontrollevel - 1
                    l$ = "ELSE"
                    layoutdone = 1: IF LEN(layout$) THEN layout$ = layout$ + sp + l$ ELSE layout$ = l$
                    GOTO finishednonexec '***no error causing code, event checking done by IF***
                END IF
            NEXT
            a$ = "ELSE without IF": GOTO errmes
        END IF
    END IF

    IF n >= 3 THEN
        IF firstelement$ = "ELSEIF" THEN
            IF NoChecks = 0 THEN PRINT #12, "S_" + str2$(statementn) + ":;": dynscope = 1

            FOR i = controllevel TO 1 STEP -1
                t = controltype(i)
                IF t = 1 THEN
                    IF controlstate(controllevel) = 2 THEN a$ = "ELSEIF invalid after ELSE": GOTO errmes
                    controlstate(controllevel) = 1
                    controlvalue(controllevel) = controlvalue(controllevel) + 1
                    e$ = getelement$(a$, n)
                    IF e$ <> "THEN" THEN a$ = "Expected ELSEIF expression THEN": GOTO errmes
                    PRINT #12, "}else{"
                    e$ = fixoperationorder$(getelements$(ca$, 2, n - 1))
                    IF Error_Happened THEN GOTO errmes
                    l$ = "ELSEIF" + sp + tlayout$ + sp + "THEN"
                    layoutdone = 1: IF LEN(layout$) THEN layout$ = layout$ + sp + l$ ELSE layout$ = l$
                    e$ = evaluate(e$, typ)
                    IF Error_Happened THEN GOTO errmes
                    IF (typ AND ISREFERENCE) THEN e$ = refer$(e$, typ, 0)
                    IF Error_Happened THEN GOTO errmes
                    IF typ AND ISSTRING THEN
                        a$ = "Expected ELSEIF LEN(stringexpression) THEN": GOTO errmes
                    END IF
                    IF stringprocessinghappened THEN
                        PRINT #12, "if (" + cleanupstringprocessingcall$ + e$ + ")){"
                    ELSE
                        PRINT #12, "if (" + e$ + "){"
                    END IF
                    lhscontrollevel = lhscontrollevel - 1
                    GOTO finishedline
                END IF
            NEXT
            a$ = "ELSEIF without IF": GOTO errmes
        END IF
    END IF

    IF n >= 3 THEN
        IF firstelement$ = "IF" THEN
            IF NoChecks = 0 THEN PRINT #12, "S_" + str2$(statementn) + ":;": dynscope = 1

            e$ = getelement(a$, n)
            iftype = 0
            IF e$ = "THEN" THEN iftype = 1
            IF e$ = "GOTO" THEN iftype = 2
            IF iftype = 0 THEN a$ = "Expected IF expression THEN/GOTO": GOTO errmes

            controllevel = controllevel + 1
            controlref(controllevel) = linenumber
            controltype(controllevel) = 1
            controlvalue(controllevel) = 0 'number of extra closing } required at END IF
            controlstate(controllevel) = 0

            e$ = fixoperationorder$(getelements(ca$, 2, n - 1))
            IF Error_Happened THEN GOTO errmes
            l$ = "IF" + sp + tlayout$
            e$ = evaluate(e$, typ)
            IF Error_Happened THEN GOTO errmes
            IF (typ AND ISREFERENCE) THEN e$ = refer$(e$, typ, 0)
            IF Error_Happened THEN GOTO errmes

            IF typ AND ISSTRING THEN
                a$ = "Expected IF LEN(stringexpression) THEN": GOTO errmes
            END IF

            IF stringprocessinghappened THEN
                PRINT #12, "if ((" + cleanupstringprocessingcall$ + e$ + "))||new_error){"
            ELSE
                PRINT #12, "if ((" + e$ + ")||new_error){"
            END IF

            IF iftype = 1 THEN l$ = l$ + sp + "THEN" 'note: 'GOTO' will be added when iftype=2
            layoutdone = 1: IF LEN(layout$) = 0 THEN layout$ = l$ ELSE layout$ = layout$ + sp + l$

            IF iftype = 2 THEN 'IF ... GOTO
                GOTO finishedline
            END IF

            THENGOTO = 1 'possible: IF a=1 THEN 10
            GOTO finishedline2
        END IF
    END IF


    'END IF
    IF n = 2 THEN
        IF getelement(a$, 1) = "END" AND getelement(a$, 2) = "IF" THEN


            IF controltype(controllevel) <> 1 THEN a$ = "END IF without IF": GOTO errmes
            layoutdone = 1
            IF impliedendif = 0 THEN
                l$ = "END" + sp + "IF"
                IF LEN(layout$) = 0 THEN layout$ = l$ ELSE layout$ = layout$ + sp + l$
            END IF

            PRINT #12, "}"
            FOR i = 1 TO controlvalue(controllevel)
                PRINT #12, "}"
            NEXT
            controllevel = controllevel - 1
            GOTO finishednonexec '***no error causing code, event checking done by IF***
        END IF
    END IF



    'SELECT CASE
    IF n >= 1 THEN
        IF firstelement$ = "SELECT" THEN
            IF NoChecks = 0 THEN PRINT #12, "S_" + str2$(statementn) + ":;": dynscope = 1

            IF n = 1 OR secondelement$ <> "CASE" THEN a$ = "Expected CASE": GOTO errmes
            IF n = 2 THEN a$ = "Expected SELECT CASE expression": GOTO errmes
            e$ = fixoperationorder(getelements$(ca$, 3, n))
            IF Error_Happened THEN GOTO errmes
            l$ = "SELECT" + sp + "CASE" + sp + tlayout$
            layoutdone = 1: IF LEN(layout$) THEN layout$ = layout$ + sp + l$ ELSE layout$ = l$
            e$ = evaluate(e$, typ)
            IF Error_Happened THEN GOTO errmes
            u = uniquenumber

            controllevel = controllevel + 1
            controlvalue(controllevel) = 0 'id



            t$ = ""
            IF (typ AND ISSTRING) THEN
                t = 0
                IF (typ AND ISUDT) = 0 AND (typ AND ISARRAY) = 0 AND (typ AND ISREFERENCE) <> 0 THEN
                    controlvalue(controllevel) = VAL(e$)
                ELSE
                    IF (typ AND ISREFERENCE) THEN e$ = refer(e$, typ, 0)
                    IF Error_Happened THEN GOTO errmes
                    PRINT #13, "static qbs *sc_" + str2$(u) + "=qbs_new(0,0);"
                    PRINT #12, "qbs_set(sc_" + str2$(u) + "," + e$ + ");"
                    IF stringprocessinghappened THEN PRINT #12, cleanupstringprocessingcall$ + "0);"
                END IF

            ELSE

                IF (typ AND ISFLOAT) THEN

                    IF (typ AND 511) > 64 THEN t = 3: t$ = "long double"
                    IF (typ AND 511) = 32 THEN t = 4: t$ = "float"
                    IF (typ AND 511) = 64 THEN t = 5: t$ = "double"
                    IF (typ AND ISUDT) = 0 AND (typ AND ISARRAY) = 0 AND (typ AND ISREFERENCE) <> 0 THEN
                        controlvalue(controllevel) = VAL(e$)
                    ELSE
                        IF (typ AND ISREFERENCE) THEN e$ = refer(e$, typ, 0)
                        IF Error_Happened THEN GOTO errmes

                        PRINT #13, "static " + t$ + " sc_" + str2$(u) + ";"
                        PRINT #12, "sc_" + str2$(u) + "=" + e$ + ";"
                        IF stringprocessinghappened THEN PRINT #12, cleanupstringprocessingcall$ + "0);"
                    END IF

                ELSE

                    'non-float
                    t = 1: t$ = "int64"
                    IF (typ AND ISUNSIGNED) THEN
                        IF (typ AND 511) <= 32 THEN t = 7: t$ = "uint32"
                        IF (typ AND 511) > 32 THEN t = 2: t$ = "uint64"
                    ELSE
                        IF (typ AND 511) <= 32 THEN t = 6: t$ = "int32"
                        IF (typ AND 511) > 32 THEN t = 1: t$ = "int64"
                    END IF
                    IF (typ AND ISUDT) = 0 AND (typ AND ISARRAY) = 0 AND (typ AND ISREFERENCE) <> 0 THEN
                        controlvalue(controllevel) = VAL(e$)
                    ELSE
                        IF (typ AND ISREFERENCE) THEN e$ = refer(e$, typ, 0)
                        IF Error_Happened THEN GOTO errmes
                        PRINT #13, "static " + t$ + " sc_" + str2$(u) + ";"
                        PRINT #12, "sc_" + str2$(u) + "=" + e$ + ";"
                        IF stringprocessinghappened THEN PRINT #12, cleanupstringprocessingcall$ + "0);"
                    END IF

                END IF
            END IF



            controlref(controllevel) = linenumber
            controltype(controllevel) = 10 + t
            controlid(controllevel) = u

            GOTO finishedline
        END IF
    END IF


    'END SELECT
    IF n = 2 THEN
        IF firstelement$ = "END" AND secondelement$ = "SELECT" THEN


            'complete current case if necessary
            '18=CASE (awaiting END SELECT/CASE/CASE ELSE)
            '19=CASE ELSE (awaiting END SELECT)
            IF controltype(controllevel) = 18 THEN
                controllevel = controllevel - 1
                PRINT #12, "goto sc_" + str2$(controlid(controllevel)) + "_end;"
                PRINT #12, "}"
            END IF
            IF controltype(controllevel) = 19 THEN
                controllevel = controllevel - 1
            END IF
            PRINT #12, "sc_" + str2$(controlid(controllevel)) + "_end:;"
            IF controltype(controllevel) < 10 OR controltype(controllevel) > 17 THEN a$ = "END SELECT without SELECT CASE": GOTO errmes
            controllevel = controllevel - 1
            l$ = "END" + sp + "SELECT"
            layoutdone = 1: IF LEN(layout$) THEN layout$ = layout$ + sp + l$ ELSE layout$ = l$
            GOTO finishednonexec '***no error causing code, event checking done by SELECT CASE***
        END IF
    END IF

    'Steve Edit on 07-05-2014 to generate an error message if someone inserts code between SELECT CASE and CASE such as:
    'SELECT CASE x
    'm = 3
    'CASE 1
    'END SELECT
    'The above used to give no errors, but this one line fix should correct that.  (I hope)
    IF n >= 1 AND firstelement$ <> "CASE" AND controltype(controllevel) >= 10 AND controltype(controllevel) < 17 THEN a$ = "Expected CASE expression": GOTO errmes
    'End of Edit


    'CASE
    IF n >= 1 THEN
        IF firstelement$ = "CASE" THEN

            l$ = "CASE"
            'complete current case if necessary
            '18=CASE (awaiting END SELECT/CASE/CASE ELSE)
            '19=CASE ELSE (awaiting END SELECT)
            IF controltype(controllevel) = 19 THEN a$ = "Expected END SELECT": GOTO errmes
            IF controltype(controllevel) = 18 THEN
                lhscontrollevel = lhscontrollevel - 1
                controllevel = controllevel - 1
                PRINT #12, "goto sc_" + str2$(controlid(controllevel)) + "_end;"
                PRINT #12, "}"
                'following line fixes problem related to RESUME after error
                'statementn = statementn + 1
                'if nochecks=0 then PRINT #12, "S_" + str2$(statementn) + ":;"
            END IF

            IF controltype(controllevel) < 10 OR controltype(controllevel) > 17 THEN a$ = "CASE without SELECT CASE": GOTO errmes
            IF n = 1 THEN a$ = "Expected CASE expression": GOTO errmes



            'upgrade:
            '#1: variables can be referred to directly by storing an id in 'controlref'
            '    (but not if part of an array etc.)
            'DIM controlvalue(1000) AS LONG
            '#2: more types will be available
            '    +SINGLE
            '    +DOUBLE
            '    -LONG DOUBLE
            '    +INT32
            '    +UINT32
            '14=SELECT CASE float ...
            '15=SELECT CASE double
            '16=SELECT CASE int32
            '17=SELECT CASE uint32

            '10=SELECT CASE qbs (awaiting END SELECT/CASE)
            '11=SELECT CASE int64 (awaiting END SELECT/CASE)
            '12=SELECT CASE uint64 (awaiting END SELECT/CASE)
            '13=SELECT CASE LONG double (awaiting END SELECT/CASE/CASE ELSE)
            '14=SELECT CASE float ...
            '15=SELECT CASE double
            '16=SELECT CASE int32
            '17=SELECT CASE uint32

            '    bits = targettyp AND 511
            '                                IF bits <= 16 THEN e$ = "qbr_float_to_long(" + e$ + ")"
            '                                IF bits > 16 AND bits < 32 THEN e$ = "qbr_double_to_long(" + e$ + ")"
            '                                IF bits >= 32 THEN e$ = "qbr(" + e$ + ")"


            t = controltype(controllevel) - 10
            'get required type cast, and float options
            flt = 0
            IF t = 0 THEN tc$ = ""
            IF t = 1 THEN tc$ = ""
            IF t = 2 THEN tc$ = ""
            IF t = 3 THEN tc$ = "": flt = 1
            IF t = 4 THEN tc$ = "(float)": flt = 1
            IF t = 5 THEN tc$ = "(double)": flt = 1
            IF t = 6 THEN tc$ = ""
            IF t = 7 THEN tc$ = ""

            n$ = "sc_" + str2$(controlid(controllevel))
            cv = controlvalue(controllevel)
            IF cv THEN
                n$ = refer$(str2$(cv), 0, 0)
                IF Error_Happened THEN GOTO errmes
            END IF

            'CASE ELSE
            IF n = 2 THEN
                IF getelement$(a$, 2) = "C-EL" THEN
                    controllevel = controllevel + 1: controltype(controllevel) = 19
                    controlref(controllevel) = controlref(controllevel - 1)
                    l$ = l$ + sp + "ELSE"
                    layoutdone = 1: IF LEN(layout$) THEN layout$ = layout$ + sp + l$ ELSE layout$ = l$
                    GOTO finishednonexec '***no error causing code, event checking done by SELECT CASE***
                END IF
            END IF

            IF NoChecks = 0 THEN PRINT #12, "S_" + str2$(statementn) + ":;": dynscope = 1



            f12$ = ""

            nexp = 0
            B = 0
            e$ = ""
            FOR i = 2 TO n
                e2$ = getelement$(ca$, i)
                IF e2$ = "(" THEN B = B + 1
                IF e2$ = ")" THEN B = B - 1
                IF i = n THEN e$ = e$ + sp + e2$
                IF i = n OR (e2$ = "," AND B = 0) THEN
                    IF nexp <> 0 THEN l$ = l$ + sp2 + ",": f12$ = f12$ + "||"
                    IF e$ = "" THEN a$ = "Expected expression": GOTO errmes
                    e$ = RIGHT$(e$, LEN(e$) - 1)



                    'TYPE 1? ... TO ...
                    n2 = numelements(e$)
                    b2 = 0
                    el$ = "": er$ = ""
                    usedto = 0
                    FOR i2 = 1 TO n2
                        e3$ = getelement$(e$, i2)
                        IF e3$ = "(" THEN b2 = b2 + 1
                        IF e3$ = ")" THEN b2 = b2 - 1
                        IF b2 = 0 AND UCASE$(e3$) = "TO" THEN
                            usedto = 1
                        ELSE
                            IF usedto = 0 THEN el$ = el$ + sp + e3$ ELSE er$ = er$ + sp + e3$
                        END IF
                    NEXT
                    IF usedto = 1 THEN
                        IF el$ = "" OR er$ = "" THEN a$ = "Expected expression TO expression": GOTO errmes
                        el$ = RIGHT$(el$, LEN(el$) - 1): er$ = RIGHT$(er$, LEN(er$) - 1)
                        'evaluate each side
                        FOR i2 = 1 TO 2
                            IF i2 = 1 THEN e$ = el$ ELSE e$ = er$
                            e$ = fixoperationorder(e$)
                            IF Error_Happened THEN GOTO errmes
                            IF i2 = 1 THEN l$ = l$ + sp + tlayout$ ELSE l$ = l$ + sp + "TO" + sp + tlayout$
                            e$ = evaluate(e$, typ)
                            IF Error_Happened THEN GOTO errmes
                            IF (typ AND ISREFERENCE) THEN e$ = refer(e$, typ, 0)
                            IF Error_Happened THEN GOTO errmes
                            IF t = 0 THEN
                                IF (typ AND ISSTRING) = 0 THEN a$ = "Expected string expression": GOTO errmes
                                IF i2 = 1 THEN f12$ = f12$ + "(qbs_greaterorequal(" + n$ + "," + e$ + ")&&qbs_lessorequal(" + n$ + ","
                                IF i2 = 2 THEN f12$ = f12$ + e$ + "))"
                            ELSE
                                IF (typ AND ISSTRING) THEN a$ = "Expected numeric expression": GOTO errmes
                                'round to integer?
                                IF (typ AND ISFLOAT) THEN
                                    IF t = 1 THEN e$ = "qbr(" + e$ + ")"
                                    IF t = 2 THEN e$ = "qbr_longdouble_to_uint64(" + e$ + ")"
                                    IF t = 6 OR t = 7 THEN e$ = "qbr_double_to_long(" + e$ + ")"
                                END IF
                                'cast result?
                                IF LEN(tc$) THEN e$ = tc$ + "(" + e$ + ")"
                                IF i2 = 1 THEN f12$ = f12$ + "((" + n$ + ">=(" + e$ + "))&&(" + n$ + "<=("
                                IF i2 = 2 THEN f12$ = f12$ + e$ + ")))"
                            END IF
                        NEXT
                        GOTO addedexp
                    END IF

                    '10=SELECT CASE qbs (awaiting END SELECT/CASE)
                    '11=SELECT CASE int64 (awaiting END SELECT/CASE)
                    '12=SELECT CASE uint64 (awaiting END SELECT/CASE)
                    '13=SELECT CASE LONG double (awaiting END SELECT/CASE/CASE ELSE)
                    '14=SELECT CASE float ...
                    '15=SELECT CASE double
                    '16=SELECT CASE int32
                    '17=SELECT CASE uint32

                    '    bits = targettyp AND 511
                    '                                IF bits <= 16 THEN e$ = "qbr_float_to_long(" + e$ + ")"
                    '                                IF bits > 16 AND bits < 32 THEN e$ = "qbr_double_to_long(" + e$ + ")"
                    '                                IF bits >= 32 THEN e$ = "qbr(" + e$ + ")"






                    o$ = "==" 'used by type 3

                    'TYPE 2?
                    x$ = getelement$(e$, 1)
                    IF isoperator(x$) THEN 'non-standard usage correction
                        IF x$ = "=" OR x$ = "<>" OR x$ = ">" OR x$ = "<" OR x$ = ">=" OR x$ = "<=" THEN
                            e$ = "IS" + sp + e$
                            x$ = "IS"
                        END IF
                    END IF
                    IF UCASE$(x$) = "IS" THEN
                        n2 = numelements(e$)
                        IF n2 < 3 THEN a$ = "Expected IS =,<>,>,<,>=,<= expression": GOTO errmes
                        o$ = getelement$(e$, 2)
                        o2$ = o$
                        o = 0
                        IF o$ = "=" THEN o$ = "==": o = 1
                        IF o$ = "<>" THEN o$ = "!=": o = 1
                        IF o$ = ">" THEN o = 1
                        IF o$ = "<" THEN o = 1
                        IF o$ = ">=" THEN o = 1
                        IF o$ = "<=" THEN o = 1
                        IF o <> 1 THEN a$ = "Expected IS =,<>,>,<,>=,<= expression": GOTO errmes
                        l$ = l$ + sp + "IS" + sp + o2$
                        e$ = getelements$(e$, 3, n2)
                        'fall through to type 3 using modified e$ & o$
                    END IF

                    'TYPE 3? simple expression
                    e$ = fixoperationorder(e$)
                    IF Error_Happened THEN GOTO errmes
                    l$ = l$ + sp + tlayout$
                    e$ = evaluate(e$, typ)
                    IF Error_Happened THEN GOTO errmes
                    IF (typ AND ISREFERENCE) THEN e$ = refer(e$, typ, 0)
                    IF Error_Happened THEN GOTO errmes
                    IF t = 0 THEN
                        'string comparison
                        IF (typ AND ISSTRING) = 0 THEN a$ = "Expected string expression": GOTO errmes
                        IF o$ = "==" THEN o$ = "qbs_equal"
                        IF o$ = "!=" THEN o$ = "qbs_notequal"
                        IF o$ = ">" THEN o$ = "qbs_greaterthan"
                        IF o$ = "<" THEN o$ = "qbs_lessthan"
                        IF o$ = ">=" THEN o$ = "qbs_greaterorequal"
                        IF o$ = "<=" THEN o$ = "qbs_lessorequal"
                        f12$ = f12$ + o$ + "(" + n$ + "," + e$ + ")"
                    ELSE
                        'numeric
                        IF (typ AND ISSTRING) THEN a$ = "Expected numeric expression": GOTO errmes
                        'round to integer?
                        IF (typ AND ISFLOAT) THEN
                            IF t = 1 THEN e$ = "qbr(" + e$ + ")"
                            IF t = 2 THEN e$ = "qbr_longdouble_to_uint64(" + e$ + ")"
                            IF t = 6 OR t = 7 THEN e$ = "qbr_double_to_long(" + e$ + ")"
                        END IF
                        'cast result?
                        IF LEN(tc$) THEN e$ = tc$ + "(" + e$ + ")"
                        f12$ = f12$ + "(" + n$ + o$ + "(" + e$ + "))"
                    END IF

                    addedexp:
                    e$ = ""
                    nexp = nexp + 1
                ELSE
                    e$ = e$ + sp + e2$
                END IF
            NEXT

            IF stringprocessinghappened THEN
                PRINT #12, "if ((" + cleanupstringprocessingcall$ + f12$ + "))||new_error){"
            ELSE
                PRINT #12, "if ((" + f12$ + ")||new_error){"
            END IF

            layoutdone = 1: IF LEN(layout$) THEN layout$ = layout$ + sp + l$ ELSE layout$ = l$
            controllevel = controllevel + 1
            controlref(controllevel) = controlref(controllevel - 1)
            controltype(controllevel) = 18
            GOTO finishedline
        END IF
    END IF












    'static scope commands:

    IF NoChecks = 0 THEN
        PRINT #12, "do{"
        'PRINT #12, "S_" + str2$(statementn) + ":;"
    END IF


    IF n > 1 THEN
        IF firstelement$ = "PALETTE" THEN
            IF secondelement$ = "USING" THEN
                l$ = "PALETTE" + sp + "USING" + sp
                IF n < 3 THEN a$ = "Expected PALETTE USING array-name": GOTO errmes
                'check array
                e$ = getelement$(ca$, 3)
                IF FindArray(e$) THEN
                    IF Error_Happened THEN GOTO errmes
                    z = 1
                    t = id.arraytype
                    IF (t AND 511) <> 16 AND (t AND 511) <> 32 THEN z = 0
                    IF t AND ISFLOAT THEN z = 0
                    IF t AND ISOFFSETINBITS THEN z = 0
                    IF t AND ISSTRING THEN z = 0
                    IF t AND ISUDT THEN z = 0
                    IF t AND ISUNSIGNED THEN z = 0
                    IF z = 0 THEN a$ = "Array must be of type INTEGER or LONG": GOTO errmes
                    bits = t AND 511
                    GOTO pu_gotarray
                END IF
                IF Error_Happened THEN GOTO errmes
                a$ = "Expected PALETTE USING array-name": GOTO errmes
                pu_gotarray:
                'add () if index not specified
                IF n = 3 THEN
                    e$ = e$ + sp + "(" + sp + ")"
                ELSE
                    IF n = 4 OR getelement$(a$, 4) <> "(" OR getelement$(a$, n) <> ")" THEN a$ = "Expected PALETTE USING array-name(...)": GOTO errmes
                    e$ = e$ + sp + getelements$(ca$, 4, n)
                END IF
                e$ = fixoperationorder$(e$)
                IF Error_Happened THEN GOTO errmes
                l$ = l$ + tlayout$
                e$ = evaluatetotyp(e$, -2)
                IF Error_Happened THEN GOTO errmes
                PRINT #12, "sub_paletteusing(" + e$ + "," + str2(bits) + ");"
                layoutdone = 1: IF LEN(layout$) THEN layout$ = layout$ + sp + l$ ELSE layout$ = l$
                GOTO finishedline
            END IF 'using
        END IF 'palette
    END IF 'n>1


    IF firstelement$ = "KEY" THEN
        IF n = 1 THEN a$ = "Expected KEY ...": GOTO errmes
        l$ = "KEY" + sp
        IF secondelement$ = "OFF" THEN
            IF n > 2 THEN a$ = "Expected KEY OFF only": GOTO errmes
            l$ = l$ + "OFF": layoutdone = 1: IF LEN(layout$) THEN layout$ = layout$ + sp + l$ ELSE layout$ = l$
            PRINT #12, "key_off();"
            GOTO finishedline
        END IF
        IF secondelement$ = "ON" THEN
            IF n > 2 THEN a$ = "Expected KEY ON only": GOTO errmes
            l$ = l$ + "ON": layoutdone = 1: IF LEN(layout$) THEN layout$ = layout$ + sp + l$ ELSE layout$ = l$
            PRINT #12, "key_on();"
            GOTO finishedline
        END IF
        IF secondelement$ = "LIST" THEN
            IF n > 2 THEN a$ = "Expected KEY LIST only": GOTO errmes
            l$ = l$ + "LIST": layoutdone = 1: IF LEN(layout$) THEN layout$ = layout$ + sp + l$ ELSE layout$ = l$
            PRINT #12, "key_list();"
            GOTO finishedline
        END IF
        'search for comma to indicate assignment
        B = 0: e$ = ""
        FOR i = 2 TO n
            e2$ = getelement(ca$, i)
            IF e2$ = "(" THEN B = B + 1
            IF e2$ = ")" THEN B = B - 1
            IF e2$ = "," AND B = 0 THEN
                i = i + 1: GOTO key_assignment
            END IF
            IF LEN(e$) THEN e$ = e$ + sp + e2$ ELSE e$ = e2$
        NEXT
        'assume KEY(x) ON/OFF/STOP and handle as a sub
        GOTO key_fallthrough
        key_assignment:
        'KEY x, "string"
        'index
        e$ = fixoperationorder(e$)
        IF Error_Happened THEN GOTO errmes
        l$ = l$ + tlayout$ + sp2 + "," + sp
        e$ = evaluatetotyp(e$, 32&)
        IF Error_Happened THEN GOTO errmes
        PRINT #12, "key_assign(" + e$ + ",";
        'string
        e$ = getelements$(ca$, i, n)
        e$ = fixoperationorder(e$)
        IF Error_Happened THEN GOTO errmes
        l$ = l$ + tlayout$
        e$ = evaluatetotyp(e$, ISSTRING)
        IF Error_Happened THEN GOTO errmes
        PRINT #12, e$ + ");"
        layoutdone = 1: IF LEN(layout$) THEN layout$ = layout$ + sp + l$ ELSE layout$ = l$
        GOTO finishedline
    END IF 'KEY
    key_fallthrough:




    IF firstelement$ = "FIELD" THEN

        'get filenumber
        B = 0: e$ = ""
        FOR i = 2 TO n
            e2$ = getelement(ca$, i)
            IF e2$ = "(" THEN B = B + 1
            IF e2$ = ")" THEN B = B - 1
            IF e2$ = "," AND B = 0 THEN
                i = i + 1: GOTO fieldgotfn
            END IF
            IF LEN(e$) THEN e$ = e$ + sp + e2$ ELSE e$ = e2$
        NEXT
        GOTO fielderror
        fieldgotfn:
        IF e$ = "#" OR LEN(e$) = 0 THEN GOTO fielderror
        IF LEFT$(e$, 2) = "#" + sp THEN e$ = RIGHT$(e$, LEN(e$) - 2): l$ = "FIELD" + sp + "#" + sp2 ELSE l$ = "FIELD" + sp
        e$ = fixoperationorder(e$)
        IF Error_Happened THEN GOTO errmes
        l$ = l$ + tlayout$ + sp2 + "," + sp
        e$ = evaluatetotyp(e$, 32&)
        IF Error_Happened THEN GOTO errmes
        PRINT #12, "field_new(" + e$ + ");"

        fieldnext:

        'get fieldwidth
        IF i > n THEN GOTO fielderror
        B = 0: e$ = ""
        FOR i = i TO n
            e2$ = getelement(ca$, i)
            IF e2$ = "(" THEN B = B + 1
            IF e2$ = ")" THEN B = B - 1
            IF UCASE$(e2$) = "AS" AND B = 0 THEN
                i = i + 1: GOTO fieldgotfw
            END IF
            IF LEN(e$) THEN e$ = e$ + sp + e2$ ELSE e$ = e2$
        NEXT
        GOTO fielderror
        fieldgotfw:
        IF LEN(e$) = 0 THEN GOTO fielderror
        e$ = fixoperationorder(e$)
        IF Error_Happened THEN GOTO errmes
        l$ = l$ + tlayout$ + sp + "AS" + sp
        sizee$ = evaluatetotyp(e$, 32&)
        IF Error_Happened THEN GOTO errmes

        'get variable name
        IF i > n THEN GOTO fielderror
        B = 0: e$ = ""
        FOR i = i TO n
            e2$ = getelement(ca$, i)
            IF e2$ = "(" THEN B = B + 1
            IF e2$ = ")" THEN B = B - 1
            IF (i = n OR e2$ = ",") AND B = 0 THEN
                IF e2$ = "," THEN i = i - 1
                IF i = n THEN
                    IF LEN(e$) THEN e$ = e$ + sp + e2$ ELSE e$ = e2$
                END IF
                GOTO fieldgotfname
            END IF
            IF LEN(e$) THEN e$ = e$ + sp + e2$ ELSE e$ = e2$
        NEXT
        GOTO fielderror
        fieldgotfname:
        IF LEN(e$) = 0 THEN GOTO fielderror
        'evaluate it to check it is a STRING
        e$ = fixoperationorder(e$)
        IF Error_Happened THEN GOTO errmes
        l$ = l$ + tlayout$
        e$ = evaluate(e$, typ)
        IF Error_Happened THEN GOTO errmes
        IF (typ AND ISSTRING) = 0 THEN GOTO fielderror
        IF typ AND ISFIXEDLENGTH THEN a$ = "Fixed length strings cannot be used in a FIELD statement": GOTO errmes
        IF (typ AND ISREFERENCE) = 0 THEN GOTO fielderror
        e$ = refer(e$, typ, 0)
        IF Error_Happened THEN GOTO errmes
        PRINT #12, "field_add(" + e$ + "," + sizee$ + ");"

        IF i < n THEN
            i = i + 1
            e$ = getelement(a$, i)
            IF e$ <> "," THEN a$ = "Expected ,": GOTO errmes
            l$ = l$ + sp2 + "," + sp
            i = i + 1
            GOTO fieldnext
        END IF

        layoutdone = 1: IF LEN(layout$) THEN layout$ = layout$ + sp + l$ ELSE layout$ = l$
        GOTO finishedline

        fielderror: a$ = "Expected FIELD #filenumber, characters AS variable$, ...": GOTO errmes
    END IF





    '1=IF (awaiting END IF)
    '2=FOR (awaiting NEXT)
    '3=DO (awaiting LOOP [UNTIL|WHILE param])
    '4=DO WHILE/UNTIL (awaiting LOOP)
    '5=WHILE (awaiting WEND)

    IF n = 2 THEN
        IF firstelement$ = "EXIT" THEN

            l$ = firstelement$ + sp + secondelement$

            IF secondelement$ = "DO" THEN
                'scan backwards until previous control level reached
                FOR i = controllevel TO 1 STEP -1
                    t = controltype(i)
                    IF t = 3 OR t = 4 THEN
                        PRINT #12, "goto dl_exit_" + str2$(controlid(i)) + ";"
                        layoutdone = 1: IF LEN(layout$) THEN layout$ = layout$ + sp + l$ ELSE layout$ = l$
                        GOTO finishedline
                    END IF
                NEXT
                a$ = "EXIT DO without DO": GOTO errmes
            END IF

            IF secondelement$ = "FOR" THEN
                'scan backwards until previous control level reached
                FOR i = controllevel TO 1 STEP -1
                    t = controltype(i)
                    IF t = 2 THEN
                        PRINT #12, "goto fornext_exit_" + str2$(controlid(i)) + ";"
                        layoutdone = 1: IF LEN(layout$) THEN layout$ = layout$ + sp + l$ ELSE layout$ = l$
                        GOTO finishedline
                    END IF
                NEXT
                a$ = "EXIT FOR without FOR": GOTO errmes
            END IF

            IF secondelement$ = "WHILE" THEN
                'scan backwards until previous control level reached
                FOR i = controllevel TO 1 STEP -1
                    t = controltype(i)
                    IF t = 5 THEN
                        PRINT #12, "goto ww_exit_" + str2$(controlid(i)) + ";"
                        layoutdone = 1: IF LEN(layout$) THEN layout$ = layout$ + sp + l$ ELSE layout$ = l$
                        GOTO finishedline
                    END IF
                NEXT
                a$ = "EXIT WHILE without WHILE": GOTO errmes
            END IF

        END IF
    END IF








    IF n >= 2 THEN
        IF firstelement$ = "ON" AND secondelement$ = "STRIG" THEN
            DEPENDENCY(DEPENDENCY_DEVICEINPUT) = 1
            i = 3
            IF i > n THEN a$ = "Expected (": GOTO errmes
            a2$ = getelement$(ca$, i): i = i + 1
            IF a2$ <> "(" THEN a$ = "Expected (": GOTO errmes
            l$ = "ON" + sp + "STRIG" + sp2 + "("
            IF i > n THEN a$ = "Expected ...": GOTO errmes
            B = 0
            x = 0
            e2$ = ""
            e3$ = ""
            FOR i = i TO n
                e$ = getelement$(ca$, i)
                a = ASC(e$)
                IF a = 40 THEN B = B + 1
                IF a = 41 THEN B = B - 1
                IF B = -1 THEN GOTO onstriggotarg
                IF a = 44 AND B = 0 THEN
                    x = x + 1
                    IF x > 1 THEN a$ = "Expected )": GOTO errmes
                    IF e2$ = "" THEN a$ = "Expected ... ,": GOTO errmes
                    e3$ = e2$
                    e2$ = ""
                ELSE
                    IF LEN(e2$) THEN e2$ = e2$ + sp + e$ ELSE e2$ = e$
                END IF
            NEXT
            a$ = "Expected )": GOTO errmes
            onstriggotarg:
            IF e2$ = "" THEN a$ = "Expected ... )": GOTO errmes
            PRINT #12, "onstrig_setup(";

            'sort scanned results
            IF LEN(e3$) THEN
                optI$ = e3$
                optController$ = e2$
                optPassed$ = "1"
            ELSE
                optI$ = e2$
                optController$ = "0"
                optPassed$ = "0"
            END IF

            'i
            e$ = fixoperationorder$(optI$): IF Error_Happened THEN GOTO errmes
            l$ = l$ + sp2 + tlayout$
            e$ = evaluatetotyp(e$, 32&): IF Error_Happened THEN GOTO errmes
            PRINT #12, e$ + ",";

            'controller , passed
            IF optPassed$ = "1" THEN
                e$ = fixoperationorder$(optController$): IF Error_Happened THEN GOTO errmes
                l$ = l$ + sp2 + "," + sp + tlayout$
                e$ = evaluatetotyp(e$, 32&): IF Error_Happened THEN GOTO errmes
            ELSE
                e$ = optController$
            END IF
            PRINT #12, e$ + "," + optPassed$ + ",";

            l$ = l$ + sp2 + ")" + sp 'close brackets

            i = i + 1
            IF i > n THEN a$ = "Expected GOSUB/sub-name": GOTO errmes
            a2$ = getelement$(a$, i): i = i + 1
            onstrigid = onstrigid + 1
            PRINT #12, str2$(onstrigid) + ",";

            IF a2$ = "GOSUB" THEN
                IF i > n THEN a$ = "Expected linenumber/label": GOTO errmes
                a2$ = getelement$(ca$, i): i = i + 1

                PRINT #12, "0);"

                IF validlabel(a2$) = 0 THEN a$ = "Invalid label": GOTO errmes

                v = HashFind(a2$, HASHFLAG_LABEL, ignore, r)
                x = 1
                labchk60z:
                IF v THEN
                    s = Labels(r).Scope
                    IF s = 0 OR s = -1 THEN 'main scope?
                        IF s = -1 THEN Labels(r).Scope = 0 'acquire scope
                        x = 0 'already defined
                        tlayout$ = RTRIM$(Labels(r).cn)
                        Labels(r).Scope_Restriction = subfuncn
                        Labels(r).Error_Line = linenumber
                    ELSE
                        IF v = 2 THEN v = HashFindCont(ignore, r): GOTO labchk60z
                    END IF
                END IF
                IF x THEN
                    'does not exist
                    nLabels = nLabels + 1: IF nLabels > Labels_Ubound THEN Labels_Ubound = Labels_Ubound * 2: REDIM _PRESERVE Labels(1 TO Labels_Ubound) AS Label_Type
                    Labels(nLabels) = Empty_Label
                    HashAdd a2$, HASHFLAG_LABEL, nLabels
                    r = nLabels
                    Labels(r).State = 0
                    Labels(r).cn = tlayout$
                    Labels(r).Scope = 0
                    Labels(r).Error_Line = linenumber
                    Labels(r).Scope_Restriction = subfuncn
                END IF 'x
                l$ = l$ + "GOSUB" + sp + tlayout$

                PRINT #30, "if(strig_event_id==" + str2$(onstrigid) + ")goto LABEL_" + a2$ + ";"

                PRINT #29, "case " + str2$(onstrigid) + ":"
                PRINT #29, "strig_event_occurred++;"
                PRINT #29, "strig_event_id=" + str2$(onstrigid) + ";"
                PRINT #29, "strig_event_occurred++;"
                PRINT #29, "return_point[next_return_point++]=0;"
                PRINT #29, "if (next_return_point>=return_points) more_return_points();"
                PRINT #29, "QBMAIN(NULL);"
                PRINT #29, "break;"

                IF LEN(layout$) = 0 THEN layout$ = l$ ELSE layout$ = layout$ + sp + l$
                layoutdone = 1
                GOTO finishedline

            ELSE

                'establish whether sub a2$ exists using try
                x = 0
                try = findid(a2$)
                IF Error_Happened THEN GOTO errmes
                DO WHILE try
                    IF id.subfunc = 2 THEN x = 1: EXIT DO
                    IF try = 2 THEN findanotherid = 1: try = findid(a2$) ELSE try = 0
                    IF Error_Happened THEN GOTO errmes
                LOOP
                IF x = 0 THEN a$ = "Expected GOSUB/sub": GOTO errmes

                l$ = l$ + RTRIM$(id.cn)

                PRINT #29, "case " + str2$(onstrigid) + ":"
                PRINT #29, RTRIM$(id.callname) + "(";

                IF id.args > 1 THEN a$ = "SUB requires more than one argument": GOTO errmes

                IF i > n THEN

                    IF id.args = 1 THEN a$ = "Expected argument after SUB": GOTO errmes
                    PRINT #12, "0);"
                    PRINT #29, ");"

                ELSE

                    IF id.args = 0 THEN a$ = "SUB has no arguments": GOTO errmes

                    t = CVL(id.arg)
                    B = t AND 511
                    IF B = 0 OR (t AND ISARRAY) <> 0 OR (t AND ISFLOAT) <> 0 OR (t AND ISSTRING) <> 0 OR (t AND ISOFFSETINBITS) <> 0 THEN a$ = "Only SUB arguments of integer-type allowed": GOTO errmes
                    IF B = 8 THEN ct$ = "int8"
                    IF B = 16 THEN ct$ = "int16"
                    IF B = 32 THEN ct$ = "int32"
                    IF B = 64 THEN ct$ = "int64"
                    IF t AND ISOFFSET THEN ct$ = "ptrszint"
                    IF t AND ISUNSIGNED THEN ct$ = "u" + ct$
                    PRINT #29, "(" + ct$ + "*)&i64);"

                    e$ = getelements$(ca$, i, n)
                    e$ = fixoperationorder$(e$)
                    IF Error_Happened THEN GOTO errmes
                    l$ = l$ + sp + tlayout$
                    e$ = evaluatetotyp(e$, INTEGER64TYPE - ISPOINTER)
                    IF Error_Happened THEN GOTO errmes
                    PRINT #12, e$ + ");"

                END IF

                PRINT #29, "break;"
                IF LEN(layout$) = 0 THEN layout$ = l$ ELSE layout$ = layout$ + sp + l$
                layoutdone = 1
                GOTO finishedline
            END IF

        END IF
    END IF












    IF n >= 2 THEN
        IF firstelement$ = "ON" AND secondelement$ = "TIMER" THEN
            i = 3
            IF i > n THEN a$ = "Expected (": GOTO errmes
            a2$ = getelement$(ca$, i): i = i + 1
            IF a2$ <> "(" THEN a$ = "Expected (": GOTO errmes
            l$ = "ON" + sp + "TIMER" + sp2 + "("
            IF i > n THEN a$ = "Expected ...": GOTO errmes
            B = 0
            x = 0
            e2$ = ""
            e3$ = ""
            FOR i = i TO n
                e$ = getelement$(ca$, i)
                a = ASC(e$)
                IF a = 40 THEN B = B + 1
                IF a = 41 THEN B = B - 1
                IF B = -1 THEN GOTO ontimgotarg
                IF a = 44 AND B = 0 THEN
                    x = x + 1
                    IF x > 1 THEN a$ = "Expected )": GOTO errmes
                    IF e2$ = "" THEN a$ = "Expected ... ,": GOTO errmes
                    e3$ = e2$
                    e2$ = ""
                ELSE
                    IF LEN(e2$) THEN e2$ = e2$ + sp + e$ ELSE e2$ = e$
                END IF
            NEXT
            a$ = "Expected )": GOTO errmes
            ontimgotarg:
            IF e2$ = "" THEN a$ = "Expected ... )": GOTO errmes
            PRINT #12, "ontimer_setup(";
            'i
            IF LEN(e3$) THEN
                e$ = fixoperationorder$(e3$)
                IF Error_Happened THEN GOTO errmes
                l$ = l$ + sp2 + tlayout$ + "," + sp
                e$ = evaluatetotyp(e$, 32&)
                IF Error_Happened THEN GOTO errmes
                PRINT #12, e$ + ",";
            ELSE
                PRINT #12, "0,";
                l$ = l$ + sp2
            END IF
            'sec
            e$ = fixoperationorder$(e2$)
            IF Error_Happened THEN GOTO errmes
            l$ = l$ + tlayout$ + sp2 + ")" + sp
            e$ = evaluatetotyp(e$, DOUBLETYPE - ISPOINTER)
            IF Error_Happened THEN GOTO errmes
            PRINT #12, e$ + ",";
            i = i + 1
            IF i > n THEN a$ = "Expected GOSUB/sub-name": GOTO errmes
            a2$ = getelement$(a$, i): i = i + 1
            ontimerid = ontimerid + 1
            PRINT #12, str2$(ontimerid) + ",";

            IF a2$ = "GOSUB" THEN
                IF i > n THEN a$ = "Expected linenumber/label": GOTO errmes
                a2$ = getelement$(ca$, i): i = i + 1

                PRINT #12, "0);"

                IF validlabel(a2$) = 0 THEN a$ = "Invalid label": GOTO errmes

                v = HashFind(a2$, HASHFLAG_LABEL, ignore, r)
                x = 1
                labchk60:
                IF v THEN
                    s = Labels(r).Scope
                    IF s = 0 OR s = -1 THEN 'main scope?
                        IF s = -1 THEN Labels(r).Scope = 0 'acquire scope
                        x = 0 'already defined
                        tlayout$ = RTRIM$(Labels(r).cn)
                        Labels(r).Scope_Restriction = subfuncn
                        Labels(r).Error_Line = linenumber
                    ELSE
                        IF v = 2 THEN v = HashFindCont(ignore, r): GOTO labchk60
                    END IF
                END IF
                IF x THEN
                    'does not exist
                    nLabels = nLabels + 1: IF nLabels > Labels_Ubound THEN Labels_Ubound = Labels_Ubound * 2: REDIM _PRESERVE Labels(1 TO Labels_Ubound) AS Label_Type
                    Labels(nLabels) = Empty_Label
                    HashAdd a2$, HASHFLAG_LABEL, nLabels
                    r = nLabels
                    Labels(r).State = 0
                    Labels(r).cn = tlayout$
                    Labels(r).Scope = 0
                    Labels(r).Error_Line = linenumber
                    Labels(r).Scope_Restriction = subfuncn
                END IF 'x
                l$ = l$ + "GOSUB" + sp + tlayout$

                PRINT #25, "if(timer_event_id==" + str2$(ontimerid) + ")goto LABEL_" + a2$ + ";"

                PRINT #24, "case " + str2$(ontimerid) + ":"
                PRINT #24, "timer_event_occurred++;"
                PRINT #24, "timer_event_id=" + str2$(ontimerid) + ";"
                PRINT #24, "timer_event_occurred++;"
                PRINT #24, "return_point[next_return_point++]=0;"
                PRINT #24, "if (next_return_point>=return_points) more_return_points();"
                PRINT #24, "QBMAIN(NULL);"
                PRINT #24, "break;"



                'call validlabel (to validate the label) [see goto]
                'increment ontimerid
                'use ontimerid to generate the jumper routine
                'etc.


                IF LEN(layout$) = 0 THEN layout$ = l$ ELSE layout$ = layout$ + sp + l$
                layoutdone = 1
                GOTO finishedline
            ELSE

                'establish whether sub a2$ exists using try
                x = 0
                try = findid(a2$)
                IF Error_Happened THEN GOTO errmes
                DO WHILE try
                    IF id.subfunc = 2 THEN x = 1: EXIT DO
                    IF try = 2 THEN findanotherid = 1: try = findid(a2$) ELSE try = 0
                    IF Error_Happened THEN GOTO errmes
                LOOP
                IF x = 0 THEN a$ = "Expected GOSUB/sub": GOTO errmes

                l$ = l$ + RTRIM$(id.cn)

                PRINT #24, "case " + str2$(ontimerid) + ":"
                PRINT #24, RTRIM$(id.callname) + "(";

                IF id.args > 1 THEN a$ = "SUB requires more than one argument": GOTO errmes

                IF i > n THEN

                    IF id.args = 1 THEN a$ = "Expected argument after SUB": GOTO errmes
                    PRINT #12, "0);"
                    PRINT #24, ");"

                ELSE

                    IF id.args = 0 THEN a$ = "SUB has no arguments": GOTO errmes

                    t = CVL(id.arg)
                    B = t AND 511
                    IF B = 0 OR (t AND ISARRAY) <> 0 OR (t AND ISFLOAT) <> 0 OR (t AND ISSTRING) <> 0 OR (t AND ISOFFSETINBITS) <> 0 THEN a$ = "Only SUB arguments of integer-type allowed": GOTO errmes
                    IF B = 8 THEN ct$ = "int8"
                    IF B = 16 THEN ct$ = "int16"
                    IF B = 32 THEN ct$ = "int32"
                    IF B = 64 THEN ct$ = "int64"
                    IF t AND ISOFFSET THEN ct$ = "ptrszint"
                    IF t AND ISUNSIGNED THEN ct$ = "u" + ct$
                    PRINT #24, "(" + ct$ + "*)&i64);"

                    e$ = getelements$(ca$, i, n)
                    e$ = fixoperationorder$(e$)
                    IF Error_Happened THEN GOTO errmes
                    l$ = l$ + sp + tlayout$
                    e$ = evaluatetotyp(e$, INTEGER64TYPE - ISPOINTER)
                    IF Error_Happened THEN GOTO errmes
                    PRINT #12, e$ + ");"

                END IF

                PRINT #24, "break;"
                IF LEN(layout$) = 0 THEN layout$ = l$ ELSE layout$ = layout$ + sp + l$
                layoutdone = 1
                GOTO finishedline
            END IF

        END IF
    END IF




    IF n >= 2 THEN
        IF firstelement$ = "ON" AND secondelement$ = "KEY" THEN
            i = 3
            IF i > n THEN a$ = "Expected (": GOTO errmes
            a2$ = getelement$(ca$, i): i = i + 1
            IF a2$ <> "(" THEN a$ = "Expected (": GOTO errmes
            l$ = "ON" + sp + "KEY" + sp2 + "("
            IF i > n THEN a$ = "Expected ...": GOTO errmes
            B = 0
            x = 0
            e2$ = ""
            FOR i = i TO n
                e$ = getelement$(ca$, i)
                a = ASC(e$)


                IF a = 40 THEN B = B + 1
                IF a = 41 THEN B = B - 1
                IF B = -1 THEN EXIT FOR
                IF LEN(e2$) THEN e2$ = e2$ + sp + e$ ELSE e2$ = e$
            NEXT
            IF i = n + 1 THEN a$ = "Expected )": GOTO errmes
            IF e2$ = "" THEN a$ = "Expected ... )": GOTO errmes

            e$ = fixoperationorder$(e2$)
            IF Error_Happened THEN GOTO errmes
            l$ = l$ + tlayout$ + sp2 + ")" + sp
            e$ = evaluatetotyp(e$, DOUBLETYPE - ISPOINTER)
            IF Error_Happened THEN GOTO errmes
            PRINT #12, "onkey_setup(" + e$ + ",";

            i = i + 1
            IF i > n THEN a$ = "Expected GOSUB/sub-name": GOTO errmes
            a2$ = getelement$(a$, i): i = i + 1
            onkeyid = onkeyid + 1
            PRINT #12, str2$(onkeyid) + ",";

            IF a2$ = "GOSUB" THEN
                IF i > n THEN a$ = "Expected linenumber/label": GOTO errmes
                a2$ = getelement$(ca$, i): i = i + 1

                PRINT #12, "0);"

                IF validlabel(a2$) = 0 THEN a$ = "Invalid label": GOTO errmes

                v = HashFind(a2$, HASHFLAG_LABEL, ignore, r)
                x = 1
                labchk61:
                IF v THEN
                    s = Labels(r).Scope
                    IF s = 0 OR s = -1 THEN 'main scope?
                        IF s = -1 THEN Labels(r).Scope = 0 'acquire scope
                        x = 0 'already defined
                        tlayout$ = RTRIM$(Labels(r).cn)
                        Labels(r).Scope_Restriction = subfuncn
                        Labels(r).Error_Line = linenumber
                    ELSE
                        IF v = 2 THEN v = HashFindCont(ignore, r): GOTO labchk61
                    END IF
                END IF
                IF x THEN
                    'does not exist
                    nLabels = nLabels + 1: IF nLabels > Labels_Ubound THEN Labels_Ubound = Labels_Ubound * 2: REDIM _PRESERVE Labels(1 TO Labels_Ubound) AS Label_Type
                    Labels(nLabels) = Empty_Label
                    HashAdd a2$, HASHFLAG_LABEL, nLabels
                    r = nLabels
                    Labels(r).State = 0
                    Labels(r).cn = tlayout$
                    Labels(r).Scope = 0
                    Labels(r).Error_Line = linenumber
                    Labels(r).Scope_Restriction = subfuncn
                END IF 'x
                l$ = l$ + "GOSUB" + sp + tlayout$

                PRINT #28, "if(key_event_id==" + str2$(onkeyid) + ")goto LABEL_" + a2$ + ";"

                PRINT #27, "case " + str2$(onkeyid) + ":"
                PRINT #27, "key_event_occurred++;"
                PRINT #27, "key_event_id=" + str2$(onkeyid) + ";"
                PRINT #27, "key_event_occurred++;"
                PRINT #27, "return_point[next_return_point++]=0;"
                PRINT #27, "if (next_return_point>=return_points) more_return_points();"
                PRINT #27, "QBMAIN(NULL);"
                PRINT #27, "break;"

                IF LEN(layout$) = 0 THEN layout$ = l$ ELSE layout$ = layout$ + sp + l$
                layoutdone = 1
                GOTO finishedline
            ELSE

                'establish whether sub a2$ exists using try
                x = 0
                try = findid(a2$)
                IF Error_Happened THEN GOTO errmes
                DO WHILE try
                    IF id.subfunc = 2 THEN x = 1: EXIT DO
                    IF try = 2 THEN findanotherid = 1: try = findid(a2$) ELSE try = 0
                    IF Error_Happened THEN GOTO errmes
                LOOP
                IF x = 0 THEN a$ = "Expected GOSUB/sub": GOTO errmes

                l$ = l$ + RTRIM$(id.cn)

                PRINT #27, "case " + str2$(onkeyid) + ":"
                PRINT #27, RTRIM$(id.callname) + "(";

                IF id.args > 1 THEN a$ = "SUB requires more than one argument": GOTO errmes

                IF i > n THEN

                    IF id.args = 1 THEN a$ = "Expected argument after SUB": GOTO errmes
                    PRINT #12, "0);"
                    PRINT #27, ");"

                ELSE

                    IF id.args = 0 THEN a$ = "SUB has no arguments": GOTO errmes

                    t = CVL(id.arg)
                    B = t AND 511
                    IF B = 0 OR (t AND ISARRAY) <> 0 OR (t AND ISFLOAT) <> 0 OR (t AND ISSTRING) <> 0 OR (t AND ISOFFSETINBITS) <> 0 THEN a$ = "Only SUB arguments of integer-type allowed": GOTO errmes
                    IF B = 8 THEN ct$ = "int8"
                    IF B = 16 THEN ct$ = "int16"
                    IF B = 32 THEN ct$ = "int32"
                    IF B = 64 THEN ct$ = "int64"
                    IF t AND ISOFFSET THEN ct$ = "ptrszint"
                    IF t AND ISUNSIGNED THEN ct$ = "u" + ct$
                    PRINT #27, "(" + ct$ + "*)&i64);"

                    e$ = getelements$(ca$, i, n)
                    e$ = fixoperationorder$(e$)
                    IF Error_Happened THEN GOTO errmes
                    l$ = l$ + sp + tlayout$
                    e$ = evaluatetotyp(e$, INTEGER64TYPE - ISPOINTER)
                    IF Error_Happened THEN GOTO errmes
                    PRINT #12, e$ + ");"

                END IF

                PRINT #27, "break;"
                IF LEN(layout$) = 0 THEN layout$ = l$ ELSE layout$ = layout$ + sp + l$
                layoutdone = 1
                GOTO finishedline
            END IF

        END IF
    END IF



























    'SHARED (SUB)
    IF n >= 1 THEN
        IF firstelement$ = "SHARED" THEN
            IF n = 1 THEN a$ = "Expected SHARED ...": GOTO errmes
            i = 2
            IF subfuncn = 0 THEN a$ = "SHARED must be used within a SUB/FUNCTION": GOTO errmes



            l$ = "SHARED"
            subfuncshr:

            'get variable name
            n$ = getelement$(ca$, i): i = i + 1

            IF n$ = "" THEN a$ = "Expected SHARED variable-name": GOTO errmes

            s$ = removesymbol(n$)
            IF Error_Happened THEN GOTO errmes
            l2$ = s$ 'either symbol or nothing

            'array?
            a = 0
            IF getelement$(a$, i) = "(" THEN
                IF getelement$(a$, i + 1) <> ")" THEN a$ = "Expected ()": GOTO errmes
                i = i + 2
                a = 1
                l2$ = l2$ + sp2 + "(" + sp2 + ")"
            END IF

            method = 1

            'specific type?
            t$ = ""
            ts$ = ""
            t3$ = ""
            IF getelement$(a$, i) = "AS" THEN
                l2$ = l2$ + sp + "AS"
                getshrtyp:
                i = i + 1
                t2$ = getelement$(a$, i)
                IF t2$ <> "," AND t2$ <> "" THEN
                    IF t$ = "" THEN t$ = t2$ ELSE t$ = t$ + " " + t2$
                    IF t3$ = "" THEN t3$ = t2$ ELSE t3$ = t3$ + sp + t2$
                    GOTO getshrtyp
                END IF
                IF t$ = "" THEN a$ = "Expected AS type": GOTO errmes

                t = typname2typ(t$)
                IF Error_Happened THEN GOTO errmes
                IF t AND ISINCONVENTIONALMEMORY THEN t = t - ISINCONVENTIONALMEMORY
                IF t AND ISPOINTER THEN t = t - ISPOINTER
                IF t AND ISREFERENCE THEN t = t - ISREFERENCE
                tsize = typname2typsize
                method = 0
                IF (t AND ISUDT) = 0 THEN ts$ = type2symbol$(t$) ELSE t3$ = RTRIM$(udtxcname(t AND 511))
                IF Error_Happened THEN GOTO errmes
                l2$ = l2$ + sp + t3$

            END IF 'as

            IF LEN(s$) <> 0 AND LEN(t$) <> 0 THEN a$ = "Expected symbol or AS type after variable name": GOTO errmes

            'no symbol of type specified, apply default
            IF s$ = "" AND t$ = "" THEN
                IF LEFT$(n$, 1) = "_" THEN v = 27 ELSE v = ASC(UCASE$(n$)) - 64
                s$ = defineextaz(v)
            END IF

            'switch to main module
            oldsubfunc$ = subfunc$
            subfunc$ = ""
            defdatahandle = 18
            CLOSE #13: OPEN tmpdir$ + "maindata.txt" FOR APPEND AS #13
            CLOSE #19: OPEN tmpdir$ + "mainfree.txt" FOR APPEND AS #19

            'use 'try' to locate the variable (if it already exists)
            n2$ = n$ + s$ + ts$ 'note: either ts$ or s$ will exist unless it is a UDT
            try = findid(n2$)
            IF Error_Happened THEN GOTO errmes
            DO WHILE try
                IF a THEN
                    'an array

                    IF id.arraytype THEN
                        IF LEN(t$) = 0 THEN GOTO shrfound
                        t2 = id.arraytype: t2size = id.tsize
                        IF t2 AND ISINCONVENTIONALMEMORY THEN t2 = t2 - ISINCONVENTIONALMEMORY
                        IF t2 AND ISPOINTER THEN t2 = t2 - ISPOINTER
                        IF t2 AND ISREFERENCE THEN t2 = t2 - ISREFERENCE
                        IF t = t2 AND tsize = t2size THEN GOTO shrfound
                    END IF

                ELSE
                    'not an array

                    IF id.t THEN
                        IF LEN(t$) = 0 THEN GOTO shrfound
                        t2 = id.t: t2size = id.tsize
                        IF t2 AND ISINCONVENTIONALMEMORY THEN t2 = t2 - ISINCONVENTIONALMEMORY
                        IF t2 AND ISPOINTER THEN t2 = t2 - ISPOINTER
                        IF t2 AND ISREFERENCE THEN t2 = t2 - ISREFERENCE

                        IF Debug THEN PRINT #9, "SHARED:comparing:"; t; t2, tsize; t2size

                        IF t = t2 AND tsize = t2size THEN GOTO shrfound
                    END IF

                END IF

                IF try = 2 THEN findanotherid = 1: try = findid(n2$) ELSE try = 0
                IF Error_Happened THEN GOTO errmes
            LOOP
            'unknown variable
            IF a THEN a$ = "Array not defined": GOTO errmes
            'create variable
            IF LEN(s$) THEN typ$ = s$ ELSE typ$ = t$
            retval = dim2(n$, typ$, method, "")
            IF Error_Happened THEN GOTO errmes
            'note: variable created!

            shrfound:
            l$ = l$ + sp + RTRIM$(id.cn) + l2$

            ids(currentid).share = ids(currentid).share OR 2 'set as temporarily shared

            'method must apply to the current sub/function regardless of how the variable was defined in 'main'
            lmay = LEN(RTRIM$(id.mayhave)): lmust = LEN(RTRIM$(id.musthave))
            IF lmay <> 0 OR lmust <> 0 THEN
                IF (method = 1 AND lmust = 0) OR (method = 0 AND lmay = 0) THEN
                    revertmaymusthaven = revertmaymusthaven + 1
                    revertmaymusthave(revertmaymusthaven) = currentid
                    SWAP ids(currentid).musthave, ids(currentid).mayhave
                END IF
            END IF

            'switch back to sub/func
            subfunc$ = oldsubfunc$
            defdatahandle = 13
            CLOSE #13: OPEN tmpdir$ + "data" + str2$(subfuncn) + ".txt" FOR APPEND AS #13
            CLOSE #19: OPEN tmpdir$ + "free" + str2$(subfuncn) + ".txt" FOR APPEND AS #19

            IF getelement$(a$, i) = "," THEN i = i + 1: l$ = l$ + sp2 + ",": GOTO subfuncshr
            IF getelement$(a$, i) <> "" THEN a$ = "Expected ,": GOTO errmes

            layoutdone = 1: IF LEN(layout$) THEN layout$ = layout$ + sp + l$ ELSE layout$ = l$
            GOTO finishedline
        END IF
    END IF

    'EXIT SUB/FUNCTION
    IF n = 2 THEN
        IF firstelement$ = "EXIT" THEN
            sf = 0
            IF secondelement$ = "FUNCTION" THEN sf = 1
            IF secondelement$ = "SUB" THEN sf = 2
            IF sf THEN

                IF LEN(subfunc) = 0 THEN a$ = "EXIT " + secondelement$ + " must be used within a SUB/FUNCTION": GOTO errmes

                PRINT #12, "goto exit_subfunc;"
                l$ = firstelement$ + sp + secondelement$
                layoutdone = 1: IF LEN(layout$) THEN layout$ = layout$ + sp + l$ ELSE layout$ = l$
                GOTO finishedline
            END IF
        END IF
    END IF





    'ASC statement (fully inline)
    IF n >= 1 THEN
        IF firstelement$ = "ASC" THEN
            IF getelement$(a$, 2) <> "(" THEN a$ = "Expected ( after ASC": GOTO errmes

            'calculate 3 parts
            useposition = 0
            part = 1
            i = 3
            a3$ = ""
            stringvariable$ = ""
            position$ = ""
            B = 0
            DO

                IF i > n THEN 'got part 3
                    IF part <> 3 OR LEN(a3$) = 0 THEN a$ = "Expected ASC ( ... , ... ) = ...": GOTO errmes
                    expression$ = a3$
                    EXIT DO
                END IF

                a2$ = getelement$(ca$, i)
                IF a2$ = "(" THEN B = B + 1
                IF a2$ = ")" THEN B = B - 1

                IF B = -1 THEN

                    IF part = 1 THEN 'eg. ASC(a$)=65
                        IF getelement$(a$, i + 1) <> "=" THEN a$ = "Expected =": GOTO errmes
                        stringvariable$ = a3$
                        position$ = "1"
                        part = 3: a3$ = "": i = i + 1: GOTO ascgotpart
                    END IF

                    IF part = 2 THEN 'eg. ASC(a$,i)=65
                        IF getelement$(a$, i + 1) <> "=" THEN a$ = "Expected =": GOTO errmes
                        useposition = 1
                        position$ = a3$
                        part = 3: a3$ = "": i = i + 1: GOTO ascgotpart
                    END IF

                    'fall through, already in part 3

                END IF

                IF a2$ = "," AND B = 0 THEN
                    IF part = 1 THEN stringvariable$ = a3$: part = 2: a3$ = "": GOTO ascgotpart
                END IF

                IF LEN(a3$) THEN a3$ = a3$ + sp + a2$ ELSE a3$ = a2$
                ascgotpart:
                i = i + 1
            LOOP
            IF LEN(stringvariable$) = 0 OR LEN(position$) = 0 THEN a$ = "Expected ASC ( ... , ... ) = ...": GOTO errmes

            'validate stringvariable$
            stringvariable$ = fixoperationorder$(stringvariable$)
            IF Error_Happened THEN GOTO errmes
            l$ = "ASC" + sp2 + "(" + sp2 + tlayout$

            e$ = evaluate(stringvariable$, sourcetyp)
            IF Error_Happened THEN GOTO errmes
            IF (sourcetyp AND ISREFERENCE) = 0 OR (sourcetyp AND ISSTRING) = 0 THEN a$ = "Expected ASC ( string-variable , ...": GOTO errmes
            stringvariable$ = evaluatetotyp(stringvariable$, ISSTRING)
            IF Error_Happened THEN GOTO errmes



            IF position$ = "1" THEN
                IF useposition THEN l$ = l$ + sp2 + "," + sp + "1" + sp2 + ")" + sp + "=" ELSE l$ = l$ + sp2 + ")" + sp + "="

                PRINT #12, "tqbs=" + stringvariable$ + "; if (!new_error){"
                e$ = fixoperationorder$(expression$)
                IF Error_Happened THEN GOTO errmes
                l$ = l$ + sp + tlayout$
                e$ = evaluatetotyp(e$, 32&)
                IF Error_Happened THEN GOTO errmes
                PRINT #12, "tmp_long=" + e$ + "; if (!new_error){"
                PRINT #12, "if (tqbs->len){tqbs->chr[0]=tmp_long;}else{error(5);}"
                PRINT #12, "}}"

            ELSE

                PRINT #12, "tqbs=" + stringvariable$ + "; if (!new_error){"
                e$ = fixoperationorder$(position$)
                IF Error_Happened THEN GOTO errmes
                l$ = l$ + sp2 + "," + sp + tlayout$ + sp2 + ")" + sp + "="
                e$ = evaluatetotyp(e$, 32&)
                IF Error_Happened THEN GOTO errmes
                PRINT #12, "tmp_fileno=" + e$ + "; if (!new_error){"
                e$ = fixoperationorder$(expression$)
                IF Error_Happened THEN GOTO errmes
                l$ = l$ + sp + tlayout$
                e$ = evaluatetotyp(e$, 32&)
                IF Error_Happened THEN GOTO errmes
                PRINT #12, "tmp_long=" + e$ + "; if (!new_error){"
                PRINT #12, "if ((tmp_fileno>0)&&(tmp_fileno<=tqbs->len)){tqbs->chr[tmp_fileno-1]=tmp_long;}else{error(5);}"
                PRINT #12, "}}}"

            END IF
            layoutdone = 1: IF LEN(layout$) THEN layout$ = layout$ + sp + l$ ELSE layout$ = l$
            GOTO finishedline
        END IF
    END IF




    'MID$ statement
    IF n >= 1 THEN
        IF firstelement$ = "MID$" THEN
            IF getelement$(a$, 2) <> "(" THEN a$ = "Expected ( after MID$": GOTO errmes
            'calculate 4 parts
            length$ = ""
            part = 1
            i = 3
            a3$ = ""
            stringvariable$ = ""
            start$ = ""
            B = 0
            DO
                IF i > n THEN
                    IF part <> 4 OR a3$ = "" THEN a$ = "Expected MID$(...)=...": GOTO errmes
                    stringexpression$ = a3$
                    EXIT DO
                END IF
                a2$ = getelement$(ca$, i)
                IF a2$ = "(" THEN B = B + 1
                IF a2$ = ")" THEN B = B - 1
                IF B = -1 THEN
                    IF part = 2 THEN
                        IF getelement$(a$, i + 1) <> "=" THEN a$ = "Expected = after )": GOTO errmes
                        start$ = a3$: part = 4: a3$ = "": i = i + 1: GOTO midgotpart
                    END IF
                    IF part = 3 THEN
                        IF getelement$(a$, i + 1) <> "=" THEN a$ = "Expected = after )": GOTO errmes
                        IF a3$ = "" THEN a$ = "Omit , before ) if omitting length in MID$ statement": GOTO errmes
                        length$ = a3$: part = 4: a3$ = "": i = i + 1: GOTO midgotpart
                    END IF
                END IF
                IF a2$ = "," AND B = 0 THEN
                    IF part = 1 THEN stringvariable$ = a3$: part = 2: a3$ = "": GOTO midgotpart
                    IF part = 2 THEN start$ = a3$: part = 3: a3$ = "": GOTO midgotpart
                END IF
                IF LEN(a3$) THEN a3$ = a3$ + sp + a2$ ELSE a3$ = a2$
                midgotpart:
                i = i + 1
            LOOP
            IF stringvariable$ = "" THEN a$ = "Syntax error": GOTO errmes
            IF start$ = "" THEN a$ = "Syntax error": GOTO errmes
            'check if it is a valid source string
            stringvariable$ = fixoperationorder$(stringvariable$)
            IF Error_Happened THEN GOTO errmes
            l$ = "MID$" + sp2 + "(" + sp2 + tlayout$
            e$ = evaluate(stringvariable$, sourcetyp)
            IF Error_Happened THEN GOTO errmes
            IF (sourcetyp AND ISREFERENCE) = 0 OR (sourcetyp AND ISSTRING) = 0 THEN a$ = "MID$ expects a string variable/array-element as its first argument": GOTO errmes
            stringvariable$ = evaluatetotyp(stringvariable$, ISSTRING)
            IF Error_Happened THEN GOTO errmes

            start$ = evaluatetotyp(fixoperationorder$(start$), 32&)
            IF Error_Happened THEN GOTO errmes
            l$ = l$ + sp2 + "," + sp + tlayout$

            stringexpression$ = fixoperationorder$(stringexpression$)
            IF Error_Happened THEN GOTO errmes
            l2$ = tlayout$
            stringexpression$ = evaluatetotyp(stringexpression$, ISSTRING)
            IF Error_Happened THEN GOTO errmes

            IF LEN(length$) THEN
                length$ = fixoperationorder$(length$)
                IF Error_Happened THEN GOTO errmes
                l$ = l$ + sp2 + "," + sp + tlayout$
                length$ = evaluatetotyp(length$, 32&)
                IF Error_Happened THEN GOTO errmes
                PRINT #12, "sub_mid(" + stringvariable$ + "," + start$ + "," + length$ + "," + stringexpression$ + ",1);"
            ELSE
                PRINT #12, "sub_mid(" + stringvariable$ + "," + start$ + ",0," + stringexpression$ + ",0);"
            END IF

            l$ = l$ + sp2 + ")" + sp + "=" + sp + l2$
            layoutdone = 1: IF LEN(layout$) THEN layout$ = layout$ + sp + l$ ELSE layout$ = l$
            GOTO finishedline
        END IF
    END IF


    IF n >= 2 THEN
        IF firstelement$ = "ERASE" THEN
            i = 2
            l$ = "ERASE"
            erasenextarray:
            var$ = getelement$(ca$, i)
            x$ = var$: ls$ = removesymbol(x$)
            IF Error_Happened THEN GOTO errmes

            IF FindArray(var$) THEN
                IF Error_Happened THEN GOTO errmes
                l$ = l$ + sp + RTRIM$(id.cn) + ls$
                'erase the array
                clearerase:
                n$ = RTRIM$(id.callname)
                bytesperelement$ = str2((id.arraytype AND 511) \ 8)
                IF id.arraytype AND ISSTRING THEN bytesperelement$ = str2(id.tsize)
                IF id.arraytype AND ISOFFSETINBITS THEN bytesperelement$ = str2((id.arraytype AND 511)) + "/8+1"
                IF id.arraytype AND ISUDT THEN
                    bytesperelement$ = str2(udtxsize(id.arraytype AND 511) \ 8)
                END IF
                PRINT #12, "if (" + n$ + "[2]&1){" 'array is defined
                PRINT #12, "if (" + n$ + "[2]&2){" 'array is static
                IF (id.arraytype AND ISSTRING) <> 0 AND (id.arraytype AND ISFIXEDLENGTH) = 0 THEN
                    PRINT #12, "tmp_long=";
                    FOR i2 = 1 TO ABS(id.arrayelements)
                        IF i2 <> 1 THEN PRINT #12, "*";
                        PRINT #12, n$ + "[" + str2(i2 * 4 - 4 + 5) + "]";
                    NEXT
                    PRINT #12, ";"
                    PRINT #12, "while(tmp_long--){"
                    PRINT #12, "((qbs*)(((uint64*)(" + n$ + "[0]))[tmp_long]))->len=0;"
                    PRINT #12, "}"
                ELSE
                    'numeric
                    'clear array
                    PRINT #12, "memset((void*)(" + n$ + "[0]),0,";
                    FOR i2 = 1 TO ABS(id.arrayelements)
                        IF i2 <> 1 THEN PRINT #12, "*";
                        PRINT #12, n$ + "[" + str2(i2 * 4 - 4 + 5) + "]";
                    NEXT
                    PRINT #12, "*" + bytesperelement$ + ");"
                END IF
                PRINT #12, "}else{" 'array is dynamic
                '1. free memory & any allocated strings
                IF (id.arraytype AND ISSTRING) <> 0 AND (id.arraytype AND ISFIXEDLENGTH) = 0 THEN
                    'free strings
                    PRINT #12, "tmp_long=";
                    FOR i2 = 1 TO ABS(id.arrayelements)
                        IF i2 <> 1 THEN PRINT #12, "*";
                        PRINT #12, n$ + "[" + str2(i2 * 4 - 4 + 5) + "]";
                    NEXT
                    PRINT #12, ";"
                    PRINT #12, "while(tmp_long--){"
                    PRINT #12, "qbs_free((qbs*)(((uint64*)(" + n$ + "[0]))[tmp_long]));"
                    PRINT #12, "}"
                    'free memory
                    PRINT #12, "free((void*)(" + n$ + "[0]));"
                ELSE
                    'free memory
                    PRINT #12, "if (" + n$ + "[2]&4){" 'cmem array
                    PRINT #12, "cmem_dynamic_free((uint8*)(" + n$ + "[0]));"
                    PRINT #12, "}else{" 'non-cmem array
                    PRINT #12, "free((void*)(" + n$ + "[0]));"
                    PRINT #12, "}"
                END IF
                '2. set array (and its elements) as undefined
                PRINT #12, n$ + "[2]^=1;" 'remove defined flag, keeping other flags (such as cmem)
                'set dimensions as undefined
                FOR i2 = 1 TO ABS(id.arrayelements)
                    B = i2 * 4
                    PRINT #12, n$ + "[" + str2(B) + "]=2147483647;" 'base
                    PRINT #12, n$ + "[" + str2(B + 1) + "]=0;" 'num. index
                    PRINT #12, n$ + "[" + str2(B + 2) + "]=0;" 'multiplier
                NEXT
                IF (id.arraytype AND ISSTRING) <> 0 AND (id.arraytype AND ISFIXEDLENGTH) = 0 THEN
                    PRINT #12, n$ + "[0]=(ptrszint)&nothingstring;"
                ELSE
                    PRINT #12, n$ + "[0]=(ptrszint)nothingvalue;"
                END IF
                PRINT #12, "}" 'static/dynamic
                PRINT #12, "}" 'array is defined
                IF clearerasereturn = 1 THEN clearerasereturn = 0: GOTO clearerasereturned
                GOTO erasedarray
            END IF
            IF Error_Happened THEN GOTO errmes
            a$ = "Undefined array passed to ERASE": GOTO errmes

            erasedarray:
            IF i < n THEN
                i = i + 1: n$ = getelement$(a$, i): IF n$ <> "," THEN a$ = "Expected ,": GOTO errmes
                l$ = l$ + sp2 + ","
                i = i + 1: IF i > n THEN a$ = "Expected , ...": GOTO errmes
                GOTO erasenextarray
            END IF

            layoutdone = 1: IF LEN(layout$) THEN layout$ = layout$ + sp + l$ ELSE layout$ = l$
            GOTO finishedline
        END IF
    END IF


    'DIM/REDIM/STATIC
    IF n >= 2 THEN
        dimoption = 0: redimoption = 0: commonoption = 0
        IF firstelement$ = "DIM" THEN dimoption = 1
        IF firstelement$ = "REDIM" THEN
            dimoption = 2: redimoption = 1
            IF secondelement$ = "_PRESERVE" THEN
                redimoption = 2
                IF n = 2 THEN a$ = "Expected REDIM _PRESERVE ...": GOTO errmes
            END IF
        END IF
        IF firstelement$ = "STATIC" THEN dimoption = 3
        IF firstelement$ = "COMMON" THEN dimoption = 1: commonoption = 1
        IF dimoption THEN

            l$ = firstelement$

            IF dimoption = 3 AND subfuncn = 0 THEN a$ = "STATIC must be used within a SUB/FUNCTION": GOTO errmes
            IF commonoption = 1 AND subfuncn <> 0 THEN a$ = "COMMON cannot be used within a SUB/FUNCTION": GOTO errmes

            i = 2
            IF redimoption = 2 THEN i = 3: l$ = l$ + sp + "_PRESERVE"

            IF dimoption <> 3 THEN 'shared cannot be static
                a2$ = getelement(a$, i)
                IF a2$ = "SHARED" THEN
                    IF subfuncn <> 0 THEN a$ = "DIM/REDIM SHARED invalid within a SUB/FUNCTION": GOTO errmes
                    dimshared = 1
                    i = i + 1
                    l$ = l$ + sp + a2$
                END IF
            END IF

            IF dimoption = 3 THEN dimstatic = 1: AllowLocalName = 1

            dimnext:
            notype = 0
            listarray = 0


            'old chain code
            'chaincommonarray=0

            varname$ = getelement(ca$, i): i = i + 1
            IF varname$ = "" THEN a$ = "Expected variable-name": GOTO errmes

            'get the next element
            IF i >= n + 1 THEN e$ = "" ELSE e$ = getelement(a$, i): i = i + 1

            'check if next element is a ( to create an array
            elements$ = ""

            IF e$ = "(" THEN
                B = 1
                FOR i = i TO n
                    e$ = getelement(ca$, i)
                    IF e$ = "(" THEN B = B + 1
                    IF e$ = ")" THEN B = B - 1
                    IF B = 0 THEN EXIT FOR
                    IF LEN(elements$) THEN elements$ = elements$ + sp + e$ ELSE elements$ = e$
                NEXT
                IF B <> 0 THEN a$ = "Expected )": GOTO errmes
                i = i + 1 'set i to point to the next element

                IF commonoption THEN elements$ = "?"


                IF Debug THEN PRINT #9, "DIM2:array:elements$:[" + elements$ + "]"

                'arrayname() means list array to it will automatically be static when it is formally dimensioned later
                'note: listed arrays are always created in dynamic memory, but their contents are not erased
                '      this differs from static arrays from SUB...STATIC and the unique QB64 method -> STATIC arrayname(100)
                IF dimoption = 3 THEN 'STATIC used
                    IF LEN(elements$) = 0 THEN 'nothing between brackets
                        listarray = 1 'add to static list
                    END IF
                END IF

                'last element was ")"
                'get next element
                IF i >= n + 1 THEN e$ = "" ELSE e$ = getelement(a$, i): i = i + 1
            END IF 'e$="("
            d$ = e$

            dimmethod = 0

            appendname$ = "" 'the symbol to append to name returned by dim2
            appendtype$ = "" 'eg. sp+AS+spINTEGER
            dim2typepassback$ = ""

            'does varname have an appended symbol?
            s$ = removesymbol$(varname$)
            IF Error_Happened THEN GOTO errmes
            IF validname(varname$) = 0 THEN a$ = "Invalid variable name": GOTO errmes

            IF s$ <> "" THEN
                typ$ = s$
                dimmethod = 1
                appendname$ = typ$
                GOTO dimgottyp
            END IF

            IF d$ = "AS" THEN
                appendtype$ = sp + "AS"
                typ$ = ""
                FOR i = i TO n
                    d$ = getelement(a$, i)
                    IF d$ = "," THEN i = i + 1: EXIT FOR
                    typ$ = typ$ + d$ + " "
                    appendtype$ = appendtype$ + sp + d$
                    d$ = ""
                NEXT
                appendtype$ = UCASE$(appendtype$) 'capitalise default types (udt override this later if necessary)
                typ$ = RTRIM$(typ$)
                GOTO dimgottyp
            END IF

            'auto-define type based on name
            notype = 1
            IF LEFT$(varname$, 1) = "_" THEN v = 27 ELSE v = ASC(UCASE$(varname$)) - 64
            typ$ = defineaz(v)
            dimmethod = 1
            GOTO dimgottyp

            dimgottyp:
            IF d$ <> "" AND d$ <> "," THEN a$ = "DIM: Expected comma!": GOTO errmes

            'In QBASIC, if no type info is given it can refer to an expeicit/formally defined array
            IF notype <> 0 AND dimoption <> 3 AND dimoption <> 1 THEN 'not DIM or STATIC which only create new content
                IF LEN(elements$) THEN 'an array
                    IF FindArray(varname$) THEN
                        IF LEN(RTRIM$(id.mayhave)) THEN 'explict/formally defined
                            typ$ = id2fulltypename$ 'adopt type
                            dimmethod = 0 'set as formally defined
                        END IF
                    END IF
                END IF
            END IF

            IF dimoption = 3 AND LEN(elements$) THEN 'eg. STATIC a(100)
                'does a conflicting array exist? (use findarray) if so again this should lead to duplicate definition
                typ2$ = symbol2fulltypename$(typ$)
                t = typname2typ(typ2$): ts = typname2typsize
                'try name without any extension
                IF FindArray(varname$) THEN 'name without any symbol
                    IF id.insubfuncn = subfuncn THEN 'global cannot conflict with static
                        IF LEN(RTRIM$(id.musthave)) THEN
                            'if types match then fail
                            IF (id.arraytype AND (ISFLOAT + ISUDT + 511 + ISUNSIGNED + ISSTRING + ISFIXEDLENGTH)) = (t AND (ISFLOAT + ISUDT + 511 + ISUNSIGNED + ISSTRING + ISFIXEDLENGTH)) THEN
                                IF ts = id.tsize THEN
                                    a$ = "Name already in use": GOTO errmes
                                END IF
                            END IF
                        ELSE
                            IF dimmethod = 0 THEN
                                a$ = "Name already in use": GOTO errmes 'explicit over explicit
                            ELSE
                                'if types match then fail
                                IF (id.arraytype AND (ISFLOAT + ISUDT + 511 + ISUNSIGNED + ISSTRING + ISFIXEDLENGTH)) = (t AND (ISFLOAT + ISUDT + 511 + ISUNSIGNED + ISSTRING + ISFIXEDLENGTH)) THEN
                                    IF ts = id.tsize THEN
                                        a$ = "Name already in use": GOTO errmes
                                    END IF
                                END IF
                            END IF
                        END IF
                    END IF
                END IF
                'add extension (if possible)
                IF (t AND ISUDT) = 0 THEN
                    s2$ = type2symbol$(typ2$)
                    IF Error_Happened THEN GOTO errmes
                    IF FindArray(varname$ + s2$) THEN
                        IF id.insubfuncn = subfuncn THEN 'global cannot conflict with static
                            IF LEN(RTRIM$(id.musthave)) THEN
                                'if types match then fail
                                IF (id.arraytype AND (ISFLOAT + ISUDT + 511 + ISUNSIGNED + ISSTRING + ISFIXEDLENGTH)) = (t AND (ISFLOAT + ISUDT + 511 + ISUNSIGNED + ISSTRING + ISFIXEDLENGTH)) THEN
                                    IF ts = id.tsize THEN
                                        a$ = "Name already in use": GOTO errmes
                                    END IF
                                END IF
                            ELSE
                                IF dimmethod = 0 THEN
                                    a$ = "Name already in use": GOTO errmes 'explicit over explicit
                                ELSE
                                    'if types match then fail
                                    IF (id.arraytype AND (ISFLOAT + ISUDT + 511 + ISUNSIGNED + ISSTRING + ISFIXEDLENGTH)) = (t AND (ISFLOAT + ISUDT + 511 + ISUNSIGNED + ISSTRING + ISFIXEDLENGTH)) THEN
                                        IF ts = id.tsize THEN
                                            a$ = "Name already in use": GOTO errmes
                                        END IF
                                    END IF
                                END IF
                            END IF
                        END IF
                    END IF
                END IF 'not a UDT
            END IF

            IF listarray THEN 'eg. STATIC a()
                'note: list is cleared by END SUB/FUNCTION

                'is a conflicting array already listed? if so this should cause a duplicate definition error
                'check for conflict within list:
                xi = 1
                FOR x = 1 TO staticarraylistn
                    varname2$ = getelement$(staticarraylist, xi): xi = xi + 1
                    typ2$ = getelement$(staticarraylist, xi): xi = xi + 1
                    dimmethod2 = VAL(getelement$(staticarraylist, xi)): xi = xi + 1
                    'check if they are similar
                    IF UCASE$(varname$) = UCASE$(varname2$) THEN
                        IF dimmethod2 = 1 THEN
                            'old using symbol
                            IF symbol2fulltypename$(typ$) = typ2$ THEN a$ = "Name already in use": GOTO errmes
                        ELSE
                            'old using AS
                            IF dimmethod = 0 THEN
                                a$ = "Name already in use": GOTO errmes
                            ELSE
                                IF symbol2fulltypename$(typ$) = typ2$ THEN a$ = "Name already in use": GOTO errmes
                            END IF
                        END IF
                    END IF
                NEXT

                'does a conflicting array exist? (use findarray) if so again this should lead to duplicate definition
                typ2$ = symbol2fulltypename$(typ$)
                t = typname2typ(typ2$): ts = typname2typsize
                'try name without any extension
                IF FindArray(varname$) THEN 'name without any symbol
                    IF id.insubfuncn = subfuncn THEN 'global cannot conflict with static
                        IF LEN(RTRIM$(id.musthave)) THEN
                            'if types match then fail
                            IF (id.arraytype AND (ISFLOAT + ISUDT + 511 + ISUNSIGNED + ISSTRING + ISFIXEDLENGTH)) = (t AND (ISFLOAT + ISUDT + 511 + ISUNSIGNED + ISSTRING + ISFIXEDLENGTH)) THEN
                                IF ts = id.tsize THEN
                                    a$ = "Name already in use": GOTO errmes
                                END IF
                            END IF
                        ELSE
                            IF dimmethod = 0 THEN
                                a$ = "Name already in use": GOTO errmes 'explicit over explicit
                            ELSE
                                'if types match then fail
                                IF (id.arraytype AND (ISFLOAT + ISUDT + 511 + ISUNSIGNED + ISSTRING + ISFIXEDLENGTH)) = (t AND (ISFLOAT + ISUDT + 511 + ISUNSIGNED + ISSTRING + ISFIXEDLENGTH)) THEN
                                    IF ts = id.tsize THEN
                                        a$ = "Name already in use": GOTO errmes
                                    END IF
                                END IF
                            END IF
                        END IF
                    END IF
                END IF
                'add extension (if possible)
                IF (t AND ISUDT) = 0 THEN
                    s2$ = type2symbol$(typ2$)
                    IF Error_Happened THEN GOTO errmes
                    IF FindArray(varname$ + s2$) THEN
                        IF id.insubfuncn = subfuncn THEN 'global cannot conflict with static
                            IF LEN(RTRIM$(id.musthave)) THEN
                                'if types match then fail
                                IF (id.arraytype AND (ISFLOAT + ISUDT + 511 + ISUNSIGNED + ISSTRING + ISFIXEDLENGTH)) = (t AND (ISFLOAT + ISUDT + 511 + ISUNSIGNED + ISSTRING + ISFIXEDLENGTH)) THEN
                                    IF ts = id.tsize THEN
                                        a$ = "Name already in use": GOTO errmes
                                    END IF
                                END IF
                            ELSE
                                IF dimmethod = 0 THEN
                                    a$ = "Name already in use": GOTO errmes 'explicit over explicit
                                ELSE
                                    'if types match then fail
                                    IF (id.arraytype AND (ISFLOAT + ISUDT + 511 + ISUNSIGNED + ISSTRING + ISFIXEDLENGTH)) = (t AND (ISFLOAT + ISUDT + 511 + ISUNSIGNED + ISSTRING + ISFIXEDLENGTH)) THEN
                                        IF ts = id.tsize THEN
                                            a$ = "Name already in use": GOTO errmes
                                        END IF
                                    END IF
                                END IF
                            END IF
                        END IF
                    END IF
                END IF 'not a UDT

                'note: static list arrays cannot be created until they are formally [or informally] (RE)DIM'd later
                IF LEN(staticarraylist) THEN staticarraylist = staticarraylist + sp
                staticarraylist = staticarraylist + varname$ + sp + symbol2fulltypename$(typ$) + sp + str2(dimmethod)
                IF Error_Happened THEN GOTO errmes
                staticarraylistn = staticarraylistn + 1
                l$ = l$ + sp + varname$ + appendname$ + sp2 + "(" + sp2 + ")" + appendtype$
                'note: none of the following code is run, dim2 call is also skipped

            ELSE

                olddimstatic = dimstatic

                'check if varname is on the static list
                IF LEN(elements$) THEN 'it's an array
                    IF subfuncn THEN 'it's in a sub/function
                        xi = 1
                        FOR x = 1 TO staticarraylistn
                            varname2$ = getelement$(staticarraylist, xi): xi = xi + 1
                            typ2$ = getelement$(staticarraylist, xi): xi = xi + 1
                            dimmethod2 = VAL(getelement$(staticarraylist, xi)): xi = xi + 1
                            'check if they are similar
                            IF UCASE$(varname$) = UCASE$(varname2$) THEN
                                IF symbol2fulltypename$(typ$) = typ2$ THEN
                                    IF Error_Happened THEN GOTO errmes
                                    IF dimmethod = dimmethod2 THEN
                                        'match found!
                                        varname$ = varname2$
                                        dimstatic = 3
                                        IF dimoption = 3 THEN a$ = "Array already listed as STATIC": GOTO errmes
                                    END IF
                                END IF 'typ
                            END IF 'varname
                        NEXT
                    END IF
                END IF

                'COMMON exception
                'note: COMMON alone does not imply SHARED
                '      if either(or both) COMMON & later DIM have SHARED, variable becomes shared
                IF commonoption THEN
                    IF LEN(elements$) THEN

                        'add array to list
                        IF LEN(commonarraylist) THEN commonarraylist = commonarraylist + sp
                        'note: dimmethod distinguishes between a%(...) vs a(...) AS INTEGER
                        commonarraylist = commonarraylist + varname$ + sp + symbol2fulltypename$(typ$) + sp + str2(dimmethod) + sp + str2(dimshared)
                        IF Error_Happened THEN GOTO errmes
                        commonarraylistn = commonarraylistn + 1
                        IF Debug THEN PRINT #9, "common listed:" + varname$ + sp + symbol2fulltypename$(typ$) + sp + str2(dimmethod) + sp + str2(dimshared)
                        IF Error_Happened THEN GOTO errmes

                        x = 0

                        v$ = varname$
                        IF dimmethod = 1 THEN v$ = v$ + typ$
                        try = findid(v$)
                        IF Error_Happened THEN GOTO errmes
                        DO WHILE try
                            IF id.arraytype THEN

                                t = typname2typ(typ$)
                                IF Error_Happened THEN GOTO errmes
                                s = typname2typsize
                                match = 1
                                'note: dimmethod 2 is already matched
                                IF dimmethod = 0 THEN
                                    t2 = id.arraytype
                                    s2 = id.tsize
                                    IF (t AND ISFLOAT) <> (t2 AND ISFLOAT) THEN match = 0
                                    IF (t AND ISUNSIGNED) <> (t2 AND ISUNSIGNED) THEN match = 0
                                    IF (t AND ISSTRING) <> (t2 AND ISSTRING) THEN match = 0
                                    IF (t AND ISFIXEDLENGTH) <> (t2 AND ISFIXEDLENGTH) THEN match = 0
                                    IF (t AND ISOFFSETINBITS) <> (t2 AND ISOFFSETINBITS) THEN match = 0
                                    IF (t AND ISUDT) <> (t2 AND ISUDT) THEN match = 0
                                    IF (t AND 511) <> (t2 AND 511) THEN match = 0
                                    IF s <> s2 THEN match = 0
                                    'check for implicit/explicit declaration match
                                    oldmethod = 0: IF LEN(RTRIM$(id.musthave)) THEN oldmethod = 1
                                    IF oldmethod <> dimmethod THEN match = 0
                                END IF

                                IF match THEN
                                    x = currentid
                                    IF dimshared THEN ids(x).share = 1 'share if necessary
                                    tlayout$ = RTRIM$(id.cn) + sp + "(" + sp2 + ")"

                                    IF dimmethod = 0 THEN
                                        IF t AND ISUDT THEN
                                            dim2typepassback$ = RTRIM$(udtxcname(t AND 511))
                                        ELSE
                                            dim2typepassback$ = typ$
                                            DO WHILE INSTR(dim2typepassback$, " ")
                                                ASC(dim2typepassback$, INSTR(dim2typepassback$, " ")) = ASC(sp)
                                            LOOP
                                            dim2typepassback$ = UCASE$(dim2typepassback$)
                                        END IF
                                    END IF 'method 0

                                    EXIT DO
                                END IF 'match

                            END IF 'arraytype
                            IF try = 2 THEN findanotherid = 1: try = findid(v$) ELSE try = 0
                            IF Error_Happened THEN GOTO errmes
                        LOOP

                        IF x = 0 THEN x = idn + 1

                        'note: the following code only adds include directives, everything else is defered
                        OPEN tmpdir$ + "chain.txt" FOR APPEND AS #22
                        'include directive
                        PRINT #22, "#include " + CHR$(34) + "chain" + str2$(x) + ".txt" + CHR$(34)
                        CLOSE #22
                        'create/clear include file
                        OPEN tmpdir$ + "chain" + str2$(x) + ".txt" FOR OUTPUT AS #22: CLOSE #22

                        OPEN tmpdir$ + "inpchain.txt" FOR APPEND AS #22
                        'include directive
                        PRINT #22, "#include " + CHR$(34) + "inpchain" + str2$(x) + ".txt" + CHR$(34)
                        CLOSE #22
                        'create/clear include file
                        OPEN tmpdir$ + "inpchain" + str2$(x) + ".txt" FOR OUTPUT AS #22: CLOSE #22

                        'note: elements$="?"
                        IF x <> idn + 1 THEN GOTO skipdim 'array already exists
                        GOTO dimcommonarray

                    END IF
                END IF

                'is varname on common list?
                '******
                IF LEN(elements$) THEN 'it's an array
                    IF subfuncn = 0 THEN 'not in a sub/function

                        IF Debug THEN PRINT #9, "common checking:" + varname$

                        xi = 1
                        FOR x = 1 TO commonarraylistn
                            varname2$ = getelement$(commonarraylist, xi): xi = xi + 1
                            typ2$ = getelement$(commonarraylist, xi): xi = xi + 1
                            dimmethod2 = VAL(getelement$(commonarraylist, xi)): xi = xi + 1
                            dimshared2 = VAL(getelement$(commonarraylist, xi)): xi = xi + 1
                            IF Debug THEN PRINT #9, "common checking against:" + varname2$ + sp + typ2$ + sp + str2(dimmethod2) + sp + str2(dimshared2)
                            'check if they are similar
                            IF varname$ = varname2$ THEN
                                IF symbol2fulltypename$(typ$) = typ2$ THEN
                                    IF Error_Happened THEN GOTO errmes
                                    IF dimmethod = dimmethod2 THEN

                                        'match found!
                                        'enforce shared status (if necessary)
                                        IF dimshared2 THEN dimshared = dimshared OR 2 'temp force SHARED

                                        'old chain code
                                        'chaincommonarray=x

                                    END IF 'method
                                END IF 'typ
                            END IF 'varname
                        NEXT
                    END IF
                END IF

                dimcommonarray:
                retval = dim2(varname$, typ$, dimmethod, elements$)
                IF Error_Happened THEN GOTO errmes
                skipdim:
                IF dimshared >= 2 THEN dimshared = dimshared - 2

                'non-array COMMON variable
                IF commonoption <> 0 AND LEN(elements$) = 0 THEN

                    'CHAIN.TXT (save)

                    use_global_byte_elements = 1

                    'switch output from main.txt to chain.txt
                    CLOSE #12
                    OPEN tmpdir$ + "chain.txt" FOR APPEND AS #12
                    l2$ = tlayout$

                    PRINT #12, "int32val=1;" 'simple variable
                    PRINT #12, "sub_put(FF,NULL,byte_element((uint64)&int32val,4," + NewByteElement$ + "),0);"

                    t = id.t
                    bits = t AND 511
                    IF t AND ISUDT THEN bits = udtxsize(t AND 511)
                    IF t AND ISSTRING THEN
                        IF t AND ISFIXEDLENGTH THEN
                            bits = id.tsize * 8
                        ELSE
                            PRINT #12, "int64val=__STRING_" + RTRIM$(id.n) + "->len*8;"
                            bits = 0
                        END IF
                    END IF

                    IF bits THEN
                        PRINT #12, "int64val=" + str2$(bits) + ";" 'size in bits
                    END IF
                    PRINT #12, "sub_put(FF,NULL,byte_element((uint64)&int64val,8," + NewByteElement$ + "),0);"

                    'put the variable
                    e$ = RTRIM$(id.n)

                    IF (t AND ISUDT) = 0 THEN
                        IF t AND ISFIXEDLENGTH THEN
                            e$ = e$ + "$" + str2$(id.tsize)
                        ELSE
                            e$ = e$ + typevalue2symbol$(t)
                            IF Error_Happened THEN GOTO errmes
                        END IF
                    END IF
                    e$ = evaluatetotyp(fixoperationorder$(e$), -4)
                    IF Error_Happened THEN GOTO errmes

                    PRINT #12, "sub_put(FF,NULL," + e$ + ",0);"

                    tlayout$ = l2$
                    'revert output to main.txt
                    CLOSE #12
                    OPEN tmpdir$ + "main.txt" FOR APPEND AS #12


                    'INPCHAIN.TXT (load)

                    'switch output from main.txt to chain.txt
                    CLOSE #12
                    OPEN tmpdir$ + "inpchain.txt" FOR APPEND AS #12
                    l2$ = tlayout$


                    PRINT #12, "if (int32val==1){"
                    'get the size in bits
                    PRINT #12, "sub_get(FF,NULL,byte_element((uint64)&int64val,8," + NewByteElement$ + "),0);"
                    '***assume correct size***

                    e$ = RTRIM$(id.n)
                    t = id.t
                    IF (t AND ISUDT) = 0 THEN
                        IF t AND ISFIXEDLENGTH THEN
                            e$ = e$ + "$" + str2$(id.tsize)
                        ELSE
                            e$ = e$ + typevalue2symbol$(t)
                            IF Error_Happened THEN GOTO errmes
                        END IF
                    END IF

                    IF t AND ISSTRING THEN
                        IF (t AND ISFIXEDLENGTH) = 0 THEN
                            PRINT #12, "tqbs=qbs_new(int64val>>3,1);"
                            PRINT #12, "qbs_set(__STRING_" + RTRIM$(id.n) + ",tqbs);"
                            'now that the string is the correct size, the following GET command will work correctly...
                        END IF
                    END IF

                    e$ = evaluatetotyp(fixoperationorder$(e$), -4)
                    IF Error_Happened THEN GOTO errmes
                    PRINT #12, "sub_get(FF,NULL," + e$ + ",0);"

                    PRINT #12, "sub_get(FF,NULL,byte_element((uint64)&int32val,4," + NewByteElement$ + "),0);" 'get next command
                    PRINT #12, "}"

                    tlayout$ = l2$
                    'revert output to main.txt
                    CLOSE #12
                    OPEN tmpdir$ + "main.txt" FOR APPEND AS #12

                    use_global_byte_elements = 0

                END IF

                commonarraylisted:

                n2 = numelements(tlayout$)
                l$ = l$ + sp + getelement$(tlayout$, 1) + appendname$
                IF n2 > 1 THEN
                    l$ = l$ + sp2 + getelements$(tlayout$, 2, n2)
                END IF

                IF LEN(appendtype$) THEN
                    IF LEN(dim2typepassback$) THEN appendtype$ = sp + "AS" + sp + dim2typepassback$
                    l$ = l$ + appendtype$
                END IF

                'modify first element name to include symbol

                dimstatic = olddimstatic

            END IF 'listarray=0

            IF d$ = "," THEN l$ = l$ + sp2 + ",": GOTO dimnext

            dimoption = 0
            dimshared = 0
            redimoption = 0
            IF dimstatic = 1 THEN dimstatic = 0
            AllowLocalName = 0

            layoutdone = 1
            IF LEN(layout$) = 0 THEN layout$ = l$ ELSE layout$ = layout$ + sp + l$

            GOTO finishedline
        END IF
    END IF











    'THEN [GOTO] linenumber?
    IF THENGOTO = 1 THEN
        IF n = 1 THEN
            l$ = ""
            a = ASC(LEFT$(firstelement$, 1))
            IF a = 46 OR (a >= 48 AND a <= 57) THEN a2$ = ca$: GOTO THENGOTO
        END IF
    END IF

    'goto
    IF n = 2 THEN
        IF getelement$(a$, 1) = "GOTO" THEN
            l$ = "GOTO"
            a2$ = getelement$(ca$, 2)
            THENGOTO:
            IF validlabel(a2$) = 0 THEN a$ = "Invalid label!": GOTO errmes

            v = HashFind(a2$, HASHFLAG_LABEL, ignore, r)
            x = 1
            labchk2:
            IF v THEN
                s = Labels(r).Scope
                IF s = subfuncn OR s = -1 THEN 'same scope?
                    IF s = -1 THEN Labels(r).Scope = subfuncn 'acquire scope
                    x = 0 'already defined
                    tlayout$ = RTRIM$(Labels(r).cn)
                ELSE
                    IF v = 2 THEN v = HashFindCont(ignore, r): GOTO labchk2
                END IF
            END IF
            IF x THEN
                'does not exist
                nLabels = nLabels + 1: IF nLabels > Labels_Ubound THEN Labels_Ubound = Labels_Ubound * 2: REDIM _PRESERVE Labels(1 TO Labels_Ubound) AS Label_Type
                Labels(nLabels) = Empty_Label
                HashAdd a2$, HASHFLAG_LABEL, nLabels
                r = nLabels
                Labels(r).State = 0
                Labels(r).cn = tlayout$
                Labels(r).Scope = subfuncn
                Labels(r).Error_Line = linenumber
            END IF 'x

            IF LEN(l$) THEN l$ = l$ + sp + tlayout$ ELSE l$ = tlayout$
            layoutdone = 1: IF LEN(layout$) THEN layout$ = layout$ + sp + l$ ELSE layout$ = l$
            PRINT #12, "goto LABEL_" + a2$ + ";"
            GOTO finishedline
        END IF
    END IF



    IF firstelement$ = "RUN" THEN 'RUN
        l$ = "RUN"
        IF n = 1 THEN
            'no parameters
            PRINT #12, "sub_run_init();" 'note: called first to free up screen-locked image handles
            PRINT #12, "sub_clear(NULL,NULL,NULL,NULL);" 'use functionality of CLEAR
            IF LEN(subfunc$) THEN
                PRINT #12, "QBMAIN(NULL);"
            ELSE
                PRINT #12, "goto S_0;"
            END IF
        ELSE
            'parameter passed
            e$ = getelements$(ca$, 2, n)
            e$ = fixoperationorder$(e$)
            IF Error_Happened THEN GOTO errmes
            l2$ = tlayout$
            ignore$ = evaluate(e$, typ)
            IF Error_Happened THEN GOTO errmes
            IF n = 2 AND ((typ AND ISSTRING) = 0) THEN
                'assume it's a label or line number
                lbl$ = getelement$(ca$, 2)
                IF validlabel(lbl$) = 0 THEN a$ = "Invalid label!": GOTO errmes 'invalid label

                v = HashFind(lbl$, HASHFLAG_LABEL, ignore, r)
                x = 1
                labchk501:
                IF v THEN
                    s = Labels(r).Scope
                    IF s = 0 OR s = -1 THEN 'main scope?
                        IF s = -1 THEN Labels(r).Scope = 0 'acquire scope
                        x = 0 'already defined
                        tlayout$ = RTRIM$(Labels(r).cn)
                        Labels(r).Scope_Restriction = subfuncn
                        Labels(r).Error_Line = linenumber
                    ELSE
                        IF v = 2 THEN v = HashFindCont(ignore, r): GOTO labchk501
                    END IF
                END IF
                IF x THEN
                    'does not exist
                    nLabels = nLabels + 1: IF nLabels > Labels_Ubound THEN Labels_Ubound = Labels_Ubound * 2: REDIM _PRESERVE Labels(1 TO Labels_Ubound) AS Label_Type
                    Labels(nLabels) = Empty_Label
                    HashAdd lbl$, HASHFLAG_LABEL, nLabels
                    r = nLabels
                    Labels(r).State = 0
                    Labels(r).cn = tlayout$
                    Labels(r).Scope = 0
                    Labels(r).Error_Line = linenumber
                    Labels(r).Scope_Restriction = subfuncn
                END IF 'x

                l$ = l$ + sp + tlayout$
                PRINT #12, "sub_run_init();" 'note: called first to free up screen-locked image handles
                PRINT #12, "sub_clear(NULL,NULL,NULL,NULL);" 'use functionality of CLEAR
                IF LEN(subfunc$) THEN
                    PRINT #21, "if (run_from_line==" + str2(nextrunlineindex) + "){run_from_line=0;goto LABEL_" + lbl$ + ";}"
                    PRINT #12, "run_from_line=" + str2(nextrunlineindex) + ";"
                    nextrunlineindex = nextrunlineindex + 1
                    PRINT #12, "QBMAIN(NULL);"
                ELSE
                    PRINT #12, "goto LABEL_" + lbl$ + ";"
                END IF
            ELSE
                'assume it's a string containing a filename to execute
                IF Cloud THEN a$ = "Feature not supported on QLOUD": GOTO errmes '***NOCLOUD***
                e$ = evaluatetotyp(e$, ISSTRING)
                IF Error_Happened THEN GOTO errmes
                PRINT #12, "sub_run(" + e$ + ");"
                l$ = l$ + sp + l2$
            END IF 'isstring
        END IF 'n=1
        layoutdone = 1: IF LEN(layout$) THEN layout$ = layout$ + sp + l$ ELSE layout$ = l$
        GOTO finishedline
    END IF 'run





    IF firstelement$ = "END" THEN
        l$ = "END"
        IF n > 1 THEN
            e$ = getelements$(ca$, 2, n)
            e$ = fixoperationorder$(e$): IF Error_Happened THEN GOTO errmes
            l2$ = tlayout$
            e$ = evaluatetotyp(e$, ISINTEGER64): IF Error_Happened THEN GOTO errmes
            PRINT #12, "if(qbevent){evnt(" + str2$(linenumber) + ");}" 'non-resumable error check (cannot exit without handling errors)
            PRINT #12, "exit_code=" + e$ + ";"
            l$ = l$ + sp + l2$
        END IF
        xend
        layoutdone = 1: IF LEN(layout$) THEN layout$ = layout$ + sp + l$ ELSE layout$ = l$
        GOTO finishedline
    END IF

    IF firstelement$ = "SYSTEM" THEN
        l$ = "SYSTEM"
        IF n > 1 THEN
            e$ = getelements$(ca$, 2, n)
            e$ = fixoperationorder$(e$): IF Error_Happened THEN GOTO errmes
            l2$ = tlayout$
            e$ = evaluatetotyp(e$, ISINTEGER64): IF Error_Happened THEN GOTO errmes
            PRINT #12, "if(qbevent){evnt(" + str2$(linenumber) + ");}" 'non-resumable error check (cannot exit without handling errors)
            PRINT #12, "exit_code=" + e$ + ";"
            l$ = l$ + sp + l2$
        END IF


        PRINT #12, "if (sub_gl_called) error(271);"
        PRINT #12, "close_program=1;"
        PRINT #12, "end();"
        layoutdone = 1: IF LEN(layout$) THEN layout$ = layout$ + sp + l$ ELSE layout$ = l$
        GOTO finishedline
    END IF

    IF n >= 1 THEN
        IF firstelement$ = "STOP" THEN
            l$ = "STOP"
            IF n > 1 THEN
                e$ = getelements$(ca$, 2, n)
                e$ = fixoperationorder$(e$)
                IF Error_Happened THEN GOTO errmes
                l$ = "STOP" + sp + tlayout$
                e$ = evaluatetotyp(e$, 64)
                IF Error_Happened THEN GOTO errmes
                'note: this value is currently ignored but evaluated for checking reasons
            END IF
            layoutdone = 1: IF LEN(layout$) THEN layout$ = layout$ + sp + l$ ELSE layout$ = l$
            PRINT #12, "close_program=1;"
            PRINT #12, "end();"
            GOTO finishedline
        END IF
    END IF

    IF n = 2 THEN
        IF firstelement$ = "GOSUB" THEN
            xgosub ca$, n
            IF Error_Happened THEN GOTO errmes
            'note: layout implemented in xgosub
            GOTO finishedline
        END IF
    END IF

    IF n >= 1 THEN
        IF firstelement$ = "RETURN" THEN
            IF n = 1 THEN
                PRINT #12, "#include " + CHR$(34) + "ret" + str2$(subfuncn) + ".txt" + CHR$(34)
                l$ = "RETURN"
                layoutdone = 1: IF LEN(layout$) THEN layout$ = layout$ + sp + l$ ELSE layout$ = l$
                GOTO finishedline
            ELSE
                'label/linenumber follows
                IF subfuncn <> 0 THEN a$ = "RETURN linelabel/linenumber invalid within a SUB/FUNCTION": GOTO errmes
                IF n > 2 THEN a$ = "Expected linelabel/linenumber after RETURN": GOTO errmes
                PRINT #12, "if (!next_return_point) error(3);" 'check return point available
                PRINT #12, "next_return_point--;" 'destroy return point
                a2$ = getelement$(ca$, 2)
                IF validlabel(a2$) = 0 THEN a$ = "Invalid label!": GOTO errmes

                v = HashFind(a2$, HASHFLAG_LABEL, ignore, r)
                x = 1
                labchk505:
                IF v THEN
                    s = Labels(r).Scope
                    IF s = subfuncn OR s = -1 THEN 'same scope?
                        IF s = -1 THEN Labels(r).Scope = subfuncn 'acquire scope
                        x = 0 'already defined
                        tlayout$ = RTRIM$(Labels(r).cn)
                    ELSE
                        IF v = 2 THEN v = HashFindCont(ignore, r): GOTO labchk505
                    END IF
                END IF
                IF x THEN
                    'does not exist
                    nLabels = nLabels + 1: IF nLabels > Labels_Ubound THEN Labels_Ubound = Labels_Ubound * 2: REDIM _PRESERVE Labels(1 TO Labels_Ubound) AS Label_Type
                    Labels(nLabels) = Empty_Label
                    HashAdd a2$, HASHFLAG_LABEL, nLabels
                    r = nLabels
                    Labels(r).State = 0
                    Labels(r).cn = tlayout$
                    Labels(r).Scope = subfuncn
                    Labels(r).Error_Line = linenumber
                END IF 'x

                PRINT #12, "goto LABEL_" + a2$ + ";"
                l$ = "RETURN" + sp + tlayout$
                layoutdone = 1: IF LEN(layout$) THEN layout$ = layout$ + sp + l$ ELSE layout$ = l$
                GOTO finishedline
            END IF
        END IF
    END IF

    IF n >= 1 THEN
        IF firstelement$ = "RESUME" THEN
            l$ = "RESUME"
            IF n = 1 THEN
                resumeprev:


                PRINT #12, "if (!error_handling){error(20);}else{error_retry=1; qbevent=1; error_handling=0; error_err=0; return;}"

                layoutdone = 1: IF LEN(layout$) THEN layout$ = layout$ + sp + l$ ELSE layout$ = l$
                GOTO finishedline
            END IF
            IF n > 2 THEN a$ = "Too many parameters": GOTO errmes
            s$ = getelement$(ca$, 2)
            IF UCASE$(s$) = "NEXT" THEN


                PRINT #12, "if (!error_handling){error(20);}else{error_handling=0; error_err=0; return;}"

                l$ = l$ + sp + "NEXT"
                layoutdone = 1: IF LEN(layout$) THEN layout$ = layout$ + sp + l$ ELSE layout$ = l$
                GOTO finishedline
            END IF
            IF s$ = "0" THEN l$ = l$ + sp + "0": GOTO resumeprev
            IF validlabel(s$) = 0 THEN a$ = "Invalid label passed to RESUME": GOTO errmes

            v = HashFind(s$, HASHFLAG_LABEL, ignore, r)
            x = 1
            labchk506:
            IF v THEN
                s = Labels(r).Scope
                IF s = subfuncn OR s = -1 THEN 'same scope?
                    IF s = -1 THEN Labels(r).Scope = subfuncn 'acquire scope
                    x = 0 'already defined
                    tlayout$ = RTRIM$(Labels(r).cn)
                ELSE
                    IF v = 2 THEN v = HashFindCont(ignore, r): GOTO labchk506
                END IF
            END IF
            IF x THEN
                'does not exist
                nLabels = nLabels + 1: IF nLabels > Labels_Ubound THEN Labels_Ubound = Labels_Ubound * 2: REDIM _PRESERVE Labels(1 TO Labels_Ubound) AS Label_Type
                Labels(nLabels) = Empty_Label
                HashAdd s$, HASHFLAG_LABEL, nLabels
                r = nLabels
                Labels(r).State = 0
                Labels(r).cn = tlayout$
                Labels(r).Scope = subfuncn
                Labels(r).Error_Line = linenumber
            END IF 'x

            l$ = l$ + sp + tlayout$
            layoutdone = 1: IF LEN(layout$) THEN layout$ = layout$ + sp + l$ ELSE layout$ = l$
            PRINT #12, "if (!error_handling){error(20);}else{error_handling=0; error_err=0; goto LABEL_" + s$ + ";}"
            GOTO finishedline
        END IF
    END IF

    IF n = 4 THEN
        IF getelements(a$, 1, 3) = "ON" + sp + "ERROR" + sp + "GOTO" THEN
            l$ = "ON" + sp + "ERROR" + sp + "GOTO"
            lbl$ = getelement$(ca$, 4)
            IF lbl$ = "0" THEN
                PRINT #12, "error_goto_line=0;"
                l$ = l$ + sp + "0"
                layoutdone = 1: IF LEN(layout$) THEN layout$ = layout$ + sp + l$ ELSE layout$ = l$
                GOTO finishedline
            END IF
            IF validlabel(lbl$) = 0 THEN a$ = "Invalid label": GOTO errmes

            v = HashFind(lbl$, HASHFLAG_LABEL, ignore, r)
            x = 1
            labchk6:
            IF v THEN
                s = Labels(r).Scope
                IF s = 0 OR s = -1 THEN 'main scope?
                    IF s = -1 THEN Labels(r).Scope = 0 'acquire scope
                    x = 0 'already defined
                    tlayout$ = RTRIM$(Labels(r).cn)
                    Labels(r).Scope_Restriction = subfuncn
                    Labels(r).Error_Line = linenumber
                ELSE
                    IF v = 2 THEN v = HashFindCont(ignore, r): GOTO labchk6
                END IF
            END IF
            IF x THEN
                'does not exist
                nLabels = nLabels + 1: IF nLabels > Labels_Ubound THEN Labels_Ubound = Labels_Ubound * 2: REDIM _PRESERVE Labels(1 TO Labels_Ubound) AS Label_Type
                Labels(nLabels) = Empty_Label
                HashAdd lbl$, HASHFLAG_LABEL, nLabels
                r = nLabels
                Labels(r).State = 0
                Labels(r).cn = tlayout$
                Labels(r).Scope = 0
                Labels(r).Error_Line = linenumber
                Labels(r).Scope_Restriction = subfuncn
            END IF 'x


            l$ = l$ + sp + tlayout$
            layoutdone = 1: IF LEN(layout$) THEN layout$ = layout$ + sp + l$ ELSE layout$ = l$
            errorlabels = errorlabels + 1
            PRINT #12, "error_goto_line=" + str2(errorlabels) + ";"
            PRINT #14, "if (error_goto_line==" + str2(errorlabels) + "){error_handling=1; goto LABEL_" + lbl$ + ";}"
            GOTO finishedline
        END IF
    END IF

    IF n >= 1 THEN
        IF firstelement$ = "RESTORE" THEN
            l$ = "RESTORE"
            IF n = 1 THEN
                PRINT #12, "data_offset=0;"
            ELSE
                IF n > 2 THEN a$ = "Syntax error": GOTO errmes
                lbl$ = getelement$(ca$, 2)
                IF validlabel(lbl$) = 0 THEN a$ = "Invalid label": GOTO errmes

                'rule: a RESTORE label has no scope, therefore, only one instance of that label may exist
                'how: enforced by a post check for duplicates
                v = HashFind(lbl$, HASHFLAG_LABEL, ignore, r)
                x = 1
                IF v THEN 'already defined
                    x = 0
                    tlayout$ = RTRIM$(Labels(r).cn)
                    Labels(r).Data_Referenced = 1 'make sure the data referenced flag is set
                    IF Labels(r).Error_Line = 0 THEN Labels(r).Error_Line = linenumber
                END IF
                IF x THEN
                    nLabels = nLabels + 1: IF nLabels > Labels_Ubound THEN Labels_Ubound = Labels_Ubound * 2: REDIM _PRESERVE Labels(1 TO Labels_Ubound) AS Label_Type
                    Labels(nLabels) = Empty_Label
                    HashAdd lbl$, HASHFLAG_LABEL, nLabels
                    r = nLabels
                    Labels(r).State = 0
                    Labels(r).cn = tlayout$
                    Labels(r).Scope = -1 'modifyable scope
                    Labels(r).Error_Line = linenumber
                    Labels(r).Data_Referenced = 1
                END IF 'x

                l$ = l$ + sp + tlayout$
                PRINT #12, "data_offset=data_at_LABEL_" + lbl$ + ";"
            END IF
            layoutdone = 1: IF LEN(layout$) THEN layout$ = layout$ + sp + l$ ELSE layout$ = l$
            GOTO finishedline
        END IF
    END IF



    'ON ... GOTO/GOSUB
    IF n >= 1 THEN
        IF firstelement$ = "ON" THEN
            xongotogosub a$, ca$, n
            IF Error_Happened THEN GOTO errmes
            GOTO finishedline
        END IF
    END IF


    '(_MEM) _MEMPUT _MEMGET
    IF n >= 1 THEN
        IF firstelement$ = "_MEMGET" THEN
            IF Cloud THEN a$ = "Feature not supported on QLOUD": GOTO errmes '***NOCLOUD***
            'get expressions
            e$ = ""
            B = 0
            ne = 0
            FOR i2 = 2 TO n
                e2$ = getelement$(ca$, i2)
                IF e2$ = "(" THEN B = B + 1
                IF e2$ = ")" THEN B = B - 1
                IF e2$ = "," AND B = 0 THEN
                    ne = ne + 1
                    IF ne = 1 THEN blk$ = e$: e$ = ""
                    IF ne = 2 THEN offs$ = e$: e$ = ""
                    IF ne = 3 THEN a$ = "Syntax error": GOTO errmes
                ELSE
                    IF LEN(e$) = 0 THEN e$ = e2$ ELSE e$ = e$ + sp + e2$
                END IF
            NEXT
            var$ = e$
            IF e$ = "" OR ne <> 2 THEN a$ = "Expected _MEMGET mem-reference,offset,variable": GOTO errmes

            l$ = "_MEMGET" + sp

            e$ = fixoperationorder$(blk$): IF Error_Happened THEN GOTO errmes
            l$ = l$ + tlayout$

            test$ = evaluate(e$, typ): IF Error_Happened THEN GOTO errmes
            IF (typ AND ISUDT) = 0 OR (typ AND 511) <> 1 THEN a$ = "Expected _MEM type": GOTO errmes
            blkoffs$ = evaluatetotyp(e$, -6)

            '            IF typ AND ISREFERENCE THEN e$ = refer(e$, typ, 0)


            'PRINT #12, blkoffs$ '???

            e$ = fixoperationorder$(offs$): IF Error_Happened THEN GOTO errmes
            l$ = l$ + sp2 + "," + sp + tlayout$
            e$ = evaluatetotyp(e$, OFFSETTYPE - ISPOINTER): IF Error_Happened THEN GOTO errmes
            offs$ = e$
            'PRINT #12, e$ '???

            e$ = fixoperationorder$(var$): IF Error_Happened THEN GOTO errmes
            l$ = l$ + sp2 + "," + sp + tlayout$
            varsize$ = evaluatetotyp(e$, -5): IF Error_Happened THEN GOTO errmes
            varoffs$ = evaluatetotyp(e$, -6): IF Error_Happened THEN GOTO errmes


            'PRINT #12, varoffs$ '???
            'PRINT #12, varsize$ '???

            'what do we do next
            'need to know offset of variable and its size

            'known sizes will be handled by designated command casts, otherwise use memmove
            s = 0
            IF varsize$ = "1" THEN s = 1: st$ = "int8"
            IF varsize$ = "2" THEN s = 2: st$ = "int16"
            IF varsize$ = "4" THEN s = 4: st$ = "int32"
            IF varsize$ = "8" THEN s = 8: st$ = "int64"

            IF NoChecks THEN
                'fast version:
                IF s THEN
                    PRINT #12, "*(" + st$ + "*)" + varoffs$ + "=*(" + st$ + "*)(" + offs$ + ");"
                ELSE
                    PRINT #12, "memmove(" + varoffs$ + ",(void*)" + offs$ + "," + varsize$ + ");"
                END IF
            ELSE
                'safe version:
                PRINT #12, "tmp_long=" + offs$ + ";"
                'is mem block init?
                PRINT #12, "if ( ((mem_block*)(" + blkoffs$ + "))->lock_offset ){"
                'are region and id valid?
                PRINT #12, "if ("
                PRINT #12, "tmp_long < ((mem_block*)(" + blkoffs$ + "))->offset  ||"
                PRINT #12, "(tmp_long+(" + varsize$ + ")) > ( ((mem_block*)(" + blkoffs$ + "))->offset + ((mem_block*)(" + blkoffs$ + "))->size)  ||"
                PRINT #12, "((mem_lock*)((mem_block*)(" + blkoffs$ + "))->lock_offset)->id != ((mem_block*)(" + blkoffs$ + "))->lock_id  ){"
                'diagnose error
                PRINT #12, "if (" + "((mem_lock*)((mem_block*)(" + blkoffs$ + "))->lock_offset)->id != ((mem_block*)(" + blkoffs$ + "))->lock_id" + ") error(308); else error(300);"
                PRINT #12, "}else{"
                IF s THEN
                    PRINT #12, "*(" + st$ + "*)" + varoffs$ + "=*(" + st$ + "*)tmp_long;"
                ELSE
                    PRINT #12, "memmove(" + varoffs$ + ",(void*)tmp_long," + varsize$ + ");"
                END IF
                PRINT #12, "}"
                PRINT #12, "}else error(309);"
            END IF

            layoutdone = 1: IF LEN(layout$) THEN layout$ = layout$ + sp + l$ ELSE layout$ = l$
            GOTO finishedline

        END IF
    END IF




    IF n >= 1 THEN
        IF firstelement$ = "_MEMPUT" THEN
            IF Cloud THEN a$ = "Feature not supported on QLOUD": GOTO errmes '***NOCLOUD***
            'get expressions
            typ$ = ""
            e$ = ""
            B = 0
            ne = 0
            FOR i2 = 2 TO n
                e2$ = getelement$(ca$, i2)
                IF e2$ = "(" THEN B = B + 1
                IF e2$ = ")" THEN B = B - 1
                IF (e2$ = "," OR UCASE$(e2$) = "AS") AND B = 0 THEN
                    ne = ne + 1
                    IF ne = 1 THEN blk$ = e$: e$ = ""
                    IF ne = 2 THEN offs$ = e$: e$ = ""
                    IF ne = 3 THEN var$ = e$: e$ = ""
                    IF (UCASE$(e2$) = "AS" AND ne <> 3) OR (ne = 3 AND UCASE$(e2$) <> "AS") OR ne = 4 THEN a$ = "Expected _MEMPUT mem-reference,offset,variable|value[AS type]": GOTO errmes
                ELSE
                    IF LEN(e$) = 0 THEN e$ = e2$ ELSE e$ = e$ + sp + e2$
                END IF
            NEXT
            IF ne < 2 OR e$ = "" THEN a$ = "Expected _MEMPUT mem-reference,offset,variable|value[AS type]": GOTO errmes
            IF ne = 2 THEN var$ = e$ ELSE typ$ = UCASE$(e$)

            l$ = "_MEMPUT" + sp

            e$ = fixoperationorder$(blk$): IF Error_Happened THEN GOTO errmes
            l$ = l$ + tlayout$

            test$ = evaluate(e$, typ): IF Error_Happened THEN GOTO errmes
            IF (typ AND ISUDT) = 0 OR (typ AND 511) <> 1 THEN a$ = "Expected _MEM type": GOTO errmes
            blkoffs$ = evaluatetotyp(e$, -6)

            e$ = fixoperationorder$(offs$): IF Error_Happened THEN GOTO errmes
            l$ = l$ + sp2 + "," + sp + tlayout$
            e$ = evaluatetotyp(e$, OFFSETTYPE - ISPOINTER): IF Error_Happened THEN GOTO errmes
            offs$ = e$

            IF ne = 2 THEN
                e$ = fixoperationorder$(var$): IF Error_Happened THEN GOTO errmes
                l$ = l$ + sp2 + "," + sp + tlayout$

                test$ = evaluate(e$, t)
                IF (t AND ISREFERENCE) = 0 AND (t AND ISSTRING) THEN
                    PRINT #12, "g_tmp_str=" + test$ + ";"
                    varsize$ = "g_tmp_str->len"
                    varoffs$ = "g_tmp_str->chr"
                ELSE
                    varsize$ = evaluatetotyp(e$, -5): IF Error_Happened THEN GOTO errmes
                    varoffs$ = evaluatetotyp(e$, -6): IF Error_Happened THEN GOTO errmes
                END IF

                'known sizes will be handled by designated command casts, otherwise use memmove
                s = 0
                IF varsize$ = "1" THEN s = 1: st$ = "int8"
                IF varsize$ = "2" THEN s = 2: st$ = "int16"
                IF varsize$ = "4" THEN s = 4: st$ = "int32"
                IF varsize$ = "8" THEN s = 8: st$ = "int64"

                IF NoChecks THEN
                    'fast version:
                    IF s THEN
                        PRINT #12, "*(" + st$ + "*)(" + offs$ + ")=*(" + st$ + "*)" + varoffs$ + ";"
                    ELSE
                        PRINT #12, "memmove((void*)" + offs$ + "," + varoffs$ + "," + varsize$ + ");"
                    END IF
                ELSE
                    'safe version:
                    PRINT #12, "tmp_long=" + offs$ + ";"
                    'is mem block init?
                    PRINT #12, "if ( ((mem_block*)(" + blkoffs$ + "))->lock_offset ){"
                    'are region and id valid?
                    PRINT #12, "if ("
                    PRINT #12, "tmp_long < ((mem_block*)(" + blkoffs$ + "))->offset  ||"
                    PRINT #12, "(tmp_long+(" + varsize$ + ")) > ( ((mem_block*)(" + blkoffs$ + "))->offset + ((mem_block*)(" + blkoffs$ + "))->size)  ||"
                    PRINT #12, "((mem_lock*)((mem_block*)(" + blkoffs$ + "))->lock_offset)->id != ((mem_block*)(" + blkoffs$ + "))->lock_id  ){"
                    'diagnose error
                    PRINT #12, "if (" + "((mem_lock*)((mem_block*)(" + blkoffs$ + "))->lock_offset)->id != ((mem_block*)(" + blkoffs$ + "))->lock_id" + ") error(308); else error(300);"
                    PRINT #12, "}else{"
                    IF s THEN
                        PRINT #12, "*(" + st$ + "*)tmp_long=*(" + st$ + "*)" + varoffs$ + ";"
                    ELSE
                        PRINT #12, "memmove((void*)tmp_long," + varoffs$ + "," + varsize$ + ");"
                    END IF
                    PRINT #12, "}"
                    PRINT #12, "}else error(309);"
                END IF

            ELSE

                '... AS type method
                'FUNCTION typname2typ& (t2$)
                'typname2typsize = 0 'the default
                t = typname2typ(typ$)
                IF t = 0 THEN a$ = "Invalid type": GOTO errmes
                IF (t AND ISOFFSETINBITS) <> 0 OR (t AND ISUDT) <> 0 OR (t AND ISSTRING) THEN a$ = "_MEMPUT requires numeric type": GOTO errmes
                IF (t AND ISPOINTER) THEN t = t - ISPOINTER
                'attempt conversion...
                e$ = fixoperationorder$(var$): IF Error_Happened THEN GOTO errmes
                l$ = l$ + sp2 + "," + sp + tlayout$ + sp + "AS" + sp + typ$
                e$ = evaluatetotyp(e$, t): IF Error_Happened THEN GOTO errmes
                st$ = typ2ctyp$(t, "")
                varsize$ = str2((t AND 511) \ 8)
                IF NoChecks THEN
                    'fast version:
                    PRINT #12, "*(" + st$ + "*)(" + offs$ + ")=" + e$ + ";"
                ELSE
                    'safe version:
                    PRINT #12, "tmp_long=" + offs$ + ";"
                    'is mem block init?
                    PRINT #12, "if ( ((mem_block*)(" + blkoffs$ + "))->lock_offset ){"
                    'are region and id valid?
                    PRINT #12, "if ("
                    PRINT #12, "tmp_long < ((mem_block*)(" + blkoffs$ + "))->offset  ||"
                    PRINT #12, "(tmp_long+(" + varsize$ + ")) > ( ((mem_block*)(" + blkoffs$ + "))->offset + ((mem_block*)(" + blkoffs$ + "))->size)  ||"
                    PRINT #12, "((mem_lock*)((mem_block*)(" + blkoffs$ + "))->lock_offset)->id != ((mem_block*)(" + blkoffs$ + "))->lock_id  ){"
                    'diagnose error
                    PRINT #12, "if (" + "((mem_lock*)((mem_block*)(" + blkoffs$ + "))->lock_offset)->id != ((mem_block*)(" + blkoffs$ + "))->lock_id" + ") error(308); else error(300);"
                    PRINT #12, "}else{"
                    PRINT #12, "*(" + st$ + "*)tmp_long=" + e$ + ";"
                    PRINT #12, "}"
                    PRINT #12, "}else error(309);"
                END IF

            END IF

            layoutdone = 1: IF LEN(layout$) THEN layout$ = layout$ + sp + l$ ELSE layout$ = l$
            GOTO finishedline

        END IF
    END IF





    IF n >= 1 THEN
        IF firstelement$ = "_MEMFILL" THEN
            IF Cloud THEN a$ = "Feature not supported on QLOUD": GOTO errmes '***NOCLOUD***
            'get expressions
            typ$ = ""
            e$ = ""
            B = 0
            ne = 0
            FOR i2 = 2 TO n
                e2$ = getelement$(ca$, i2)
                IF e2$ = "(" THEN B = B + 1
                IF e2$ = ")" THEN B = B - 1
                IF (e2$ = "," OR UCASE$(e2$) = "AS") AND B = 0 THEN
                    ne = ne + 1
                    IF ne = 1 THEN blk$ = e$: e$ = ""
                    IF ne = 2 THEN offs$ = e$: e$ = ""
                    IF ne = 3 THEN bytes$ = e$: e$ = ""
                    IF ne = 4 THEN var$ = e$: e$ = ""
                    IF (UCASE$(e2$) = "AS" AND ne <> 4) OR (ne = 4 AND UCASE$(e2$) <> "AS") OR ne = 5 THEN a$ = "Expected _MEMFILL mem-reference,offset,bytes,variable|value[AS type]": GOTO errmes
                ELSE
                    IF LEN(e$) = 0 THEN e$ = e2$ ELSE e$ = e$ + sp + e2$
                END IF
            NEXT
            IF ne < 3 OR e$ = "" THEN a$ = "Expected _MEMFILL mem-reference,offset,bytes,variable|value[AS type]": GOTO errmes
            IF ne = 3 THEN var$ = e$ ELSE typ$ = UCASE$(e$)

            l$ = "_MEMFILL" + sp

            e$ = fixoperationorder$(blk$): IF Error_Happened THEN GOTO errmes
            l$ = l$ + tlayout$

            test$ = evaluate(e$, typ): IF Error_Happened THEN GOTO errmes
            IF (typ AND ISUDT) = 0 OR (typ AND 511) <> 1 THEN a$ = "Expected _MEM type": GOTO errmes
            blkoffs$ = evaluatetotyp(e$, -6)

            e$ = fixoperationorder$(offs$): IF Error_Happened THEN GOTO errmes
            l$ = l$ + sp2 + "," + sp + tlayout$
            e$ = evaluatetotyp(e$, OFFSETTYPE - ISPOINTER): IF Error_Happened THEN GOTO errmes
            offs$ = e$

            e$ = fixoperationorder$(bytes$): IF Error_Happened THEN GOTO errmes
            l$ = l$ + sp2 + "," + sp + tlayout$
            e$ = evaluatetotyp(e$, OFFSETTYPE - ISPOINTER): IF Error_Happened THEN GOTO errmes
            bytes$ = e$

            IF ne = 3 THEN 'no AS
                e$ = fixoperationorder$(var$): IF Error_Happened THEN GOTO errmes
                l$ = l$ + sp2 + "," + sp + tlayout$
                test$ = evaluate(e$, t)
                IF (t AND ISREFERENCE) = 0 AND (t AND ISSTRING) THEN
                    PRINT #12, "tmp_long=(ptrszint)" + test$ + ";"
                    varsize$ = "((qbs*)tmp_long)->len"
                    varoffs$ = "((qbs*)tmp_long)->chr"
                ELSE
                    varsize$ = evaluatetotyp(e$, -5): IF Error_Happened THEN GOTO errmes
                    varoffs$ = evaluatetotyp(e$, -6): IF Error_Happened THEN GOTO errmes
                END IF

                IF NoChecks THEN
                    PRINT #12, "sub__memfill_nochecks(" + offs$ + "," + bytes$ + ",(ptrszint)" + varoffs$ + "," + varsize$ + ");"
                ELSE
                    PRINT #12, "sub__memfill((mem_block*)" + blkoffs$ + "," + offs$ + "," + bytes$ + ",(ptrszint)" + varoffs$ + "," + varsize$ + ");"
                END IF

            ELSE

                '... AS type method
                t = typname2typ(typ$)
                IF t = 0 THEN a$ = "Invalid type": GOTO errmes
                IF (t AND ISOFFSETINBITS) <> 0 OR (t AND ISUDT) <> 0 OR (t AND ISSTRING) THEN a$ = "_MEMFILL requires numeric type": GOTO errmes
                IF (t AND ISPOINTER) THEN t = t - ISPOINTER
                'attempt conversion...
                e$ = fixoperationorder$(var$): IF Error_Happened THEN GOTO errmes
                l$ = l$ + sp2 + "," + sp + tlayout$ + sp + "AS" + sp + typ$
                e$ = evaluatetotyp(e$, t): IF Error_Happened THEN GOTO errmes

                c$ = "sub__memfill_"
                IF NoChecks THEN c$ = "sub__memfill_nochecks_"
                IF t AND ISOFFSET THEN
                    c$ = c$ + "OFFSET"
                ELSE
                    IF t AND ISFLOAT THEN
                        IF (t AND 511) = 32 THEN c$ = c$ + "SINGLE"
                        IF (t AND 511) = 64 THEN c$ = c$ + "DOUBLE"
                        IF (t AND 511) = 256 THEN c$ = c$ + "FLOAT" 'padded variable
                    ELSE
                        c$ = c$ + str2((t AND 511) \ 8)
                    END IF
                END IF
                c$ = c$ + "("
                IF NoChecks = 0 THEN c$ = c$ + "(mem_block*)" + blkoffs$ + ","
                PRINT #12, c$ + offs$ + "," + bytes$ + "," + e$ + ");"
            END IF

            layoutdone = 1: IF LEN(layout$) THEN layout$ = layout$ + sp + l$ ELSE layout$ = l$
            GOTO finishedline

        END IF
    END IF













    'note: ABSOLUTE cannot be used without CALL
    cispecial = 0
    IF n > 1 THEN
        IF firstelement$ = "INTERRUPT" OR firstelement$ = "INTERRUPTX" THEN
            a$ = "CALL" + sp + firstelement$ + sp + "(" + sp + getelements$(a$, 2, n) + sp + ")"
            ca$ = "CALL" + sp + firstelement$ + sp + "(" + sp + getelements$(ca$, 2, n) + sp + ")"
            n = n + 3
            firstelement$ = "CALL"
            cispecial = 1
            'fall through
        END IF
    END IF

    usecall = 0
    IF firstelement$ = "CALL" THEN
        usecall = 1
        IF n = 1 THEN a$ = "Expected CALL sub-name [(...)]": GOTO errmes
        cn$ = getelement$(ca$, 2): n$ = UCASE$(cn$)

        IF n > 2 THEN

            IF n <= 4 THEN a$ = "Expected CALL sub-name (...)": GOTO errmes
            IF getelement$(a$, 3) <> "(" OR getelement$(a$, n) <> ")" THEN a$ = "Expected CALL sub-name (...)": GOTO errmes
            a$ = n$ + sp + getelements$(a$, 4, n - 1)
            ca$ = cn$ + sp + getelements$(ca$, 4, n - 1)


            IF n$ = "INTERRUPT" OR n$ = "INTERRUPTX" THEN 'assume CALL INTERRUPT[X] request
                'print "CI: call interrupt command reached":sleep 1
                IF n$ = "INTERRUPT" THEN PRINT #12, "call_interrupt("; ELSE PRINT #12, "call_interruptx(";
                argn = 0
                n = numelements(a$)
                B = 0
                e$ = ""
                FOR i = 2 TO n
                    e2$ = getelement$(ca$, i)
                    IF e2$ = "(" THEN B = B + 1
                    IF e2$ = ")" THEN B = B - 1
                    IF (e2$ = "," AND B = 0) OR i = n THEN
                        IF i = n THEN
                            IF e$ = "" THEN e$ = e2$ ELSE e$ = e$ + sp + e2$
                        END IF
                        argn = argn + 1
                        IF argn = 1 THEN 'interrupt number
                            e$ = fixoperationorder$(e$)
                            IF Error_Happened THEN GOTO errmes
                            l$ = "CALL" + sp + n$ + sp2 + "(" + sp2 + tlayout$
                            IF cispecial = 1 THEN l$ = n$ + sp + tlayout$
                            e$ = evaluatetotyp(e$, 64&)
                            IF Error_Happened THEN GOTO errmes
                            'print "CI: evaluated interrupt number as ["+e$+"]":sleep 1
                            PRINT #12, e$;
                        END IF
                        IF argn = 2 OR argn = 3 THEN 'inregs, outregs
                            e$ = fixoperationorder$(e$)
                            IF Error_Happened THEN GOTO errmes
                            l$ = l$ + sp2 + "," + sp + tlayout$
                            e2$ = e$
                            e$ = evaluatetotyp(e$, -2) 'offset+size
                            IF Error_Happened THEN GOTO errmes
                            'print "CI: evaluated in/out regs ["+e2$+"] as ["+e$+"]":sleep 1
                            PRINT #12, "," + e$;
                        END IF
                        e$ = ""
                    ELSE
                        IF e$ = "" THEN e$ = e2$ ELSE e$ = e$ + sp + e2$
                    END IF
                NEXT
                IF argn <> 3 THEN a$ = "Expected CALL INTERRUPT (interrupt-no, inregs, outregs)": GOTO errmes
                PRINT #12, ");"
                IF cispecial = 0 THEN l$ = l$ + sp2 + ")"
                layoutdone = 1: IF LEN(layout$) THEN layout$ = layout$ + sp + l$ ELSE layout$ = l$
                'print "CI: done":sleep 1
                GOTO finishedline
            END IF 'call interrupt








            'call to CALL ABSOLUTE beyond reasonable doubt
            IF n$ = "ABSOLUTE" THEN
                l$ = "CALL" + sp + "ABSOLUTE" + sp2 + "(" + sp2
                argn = 0
                n = numelements(a$)
                B = 0
                e$ = ""
                FOR i = 2 TO n
                    e2$ = getelement$(ca$, i)
                    IF e2$ = "(" THEN B = B + 1
                    IF e2$ = ")" THEN B = B - 1
                    IF (e2$ = "," AND B = 0) OR i = n THEN
                        IF i < n THEN
                            IF e$ = "" THEN a$ = "Expected expression before , or )": GOTO errmes
                            '1. variable or value?
                            e$ = fixoperationorder$(e$)
                            IF Error_Happened THEN GOTO errmes
                            l$ = l$ + tlayout$ + sp2 + "," + sp
                            ignore$ = evaluate(e$, typ)
                            IF Error_Happened THEN GOTO errmes

                            IF (typ AND ISPOINTER) <> 0 AND (typ AND ISREFERENCE) <> 0 THEN

                                'assume standard variable
                                'assume not string/array/udt/etc
                                e$ = "VARPTR" + sp + "(" + sp + e$ + sp + ")"
                                e$ = evaluatetotyp(e$, UINTEGERTYPE - ISPOINTER)
                                IF Error_Happened THEN GOTO errmes

                            ELSE

                                'assume not string
                                'single, double or integer64?
                                IF typ AND ISFLOAT THEN
                                    IF (typ AND 511) = 32 THEN
                                        e$ = evaluatetotyp(e$, SINGLETYPE - ISPOINTER)
                                        IF Error_Happened THEN GOTO errmes
                                        v$ = "pass" + str2$(uniquenumber)
                                        PRINT #defdatahandle, "float *" + v$ + "=NULL;"
                                        PRINT #13, "if(" + v$ + "==NULL){"
                                        PRINT #13, "cmem_sp-=4;"
                                        PRINT #13, v$ + "=(float*)(dblock+cmem_sp);"
                                        PRINT #13, "if (cmem_sp<qbs_cmem_sp) error(257);"
                                        PRINT #13, "}"
                                        e$ = "(uint16)(((uint8*)&(*" + v$ + "=" + e$ + "))-((uint8*)dblock))"
                                    ELSE
                                        e$ = evaluatetotyp(e$, DOUBLETYPE - ISPOINTER)
                                        IF Error_Happened THEN GOTO errmes
                                        v$ = "pass" + str2$(uniquenumber)
                                        PRINT #defdatahandle, "double *" + v$ + "=NULL;"
                                        PRINT #13, "if(" + v$ + "==NULL){"
                                        PRINT #13, "cmem_sp-=8;"
                                        PRINT #13, v$ + "=(double*)(dblock+cmem_sp);"
                                        PRINT #13, "if (cmem_sp<qbs_cmem_sp) error(257);"
                                        PRINT #13, "}"
                                        e$ = "(uint16)(((uint8*)&(*" + v$ + "=" + e$ + "))-((uint8*)dblock))"
                                    END IF
                                ELSE
                                    e$ = evaluatetotyp(e$, INTEGER64TYPE - ISPOINTER)
                                    IF Error_Happened THEN GOTO errmes
                                    v$ = "pass" + str2$(uniquenumber)
                                    PRINT #defdatahandle, "int64 *" + v$ + "=NULL;"
                                    PRINT #13, "if(" + v$ + "==NULL){"
                                    PRINT #13, "cmem_sp-=8;"
                                    PRINT #13, v$ + "=(int64*)(dblock+cmem_sp);"
                                    PRINT #13, "if (cmem_sp<qbs_cmem_sp) error(257);"
                                    PRINT #13, "}"
                                    e$ = "(uint16)(((uint8*)&(*" + v$ + "=" + e$ + "))-((uint8*)dblock))"
                                END IF

                            END IF

                            PRINT #12, "call_absolute_offsets[" + str2$(argn) + "]=" + e$ + ";"
                        ELSE
                            IF e$ = "" THEN e$ = e2$ ELSE e$ = e$ + sp + e2$
                            e$ = fixoperationorder(e$)
                            IF Error_Happened THEN GOTO errmes
                            l$ = l$ + tlayout$ + sp2 + ")"
                            e$ = evaluatetotyp(e$, UINTEGERTYPE - ISPOINTER)
                            IF Error_Happened THEN GOTO errmes
                            PRINT #12, "call_absolute(" + str2$(argn) + "," + e$ + ");"
                        END IF
                        argn = argn + 1
                        e$ = ""
                    ELSE
                        IF e$ = "" THEN e$ = e2$ ELSE e$ = e$ + sp + e2$
                    END IF
                NEXT
                layoutdone = 1: IF LEN(layout$) THEN layout$ = layout$ + sp + l$ ELSE layout$ = l$
                GOTO finishedline
            END IF

        ELSE 'n>2

            a$ = n$
            ca$ = cn$
            usecall = 2

        END IF 'n>2

        n = numelements(a$)
        firstelement$ = getelement$(a$, 1)

        'valid SUB name
        validsub = 0
        findidsecondarg = "": IF n >= 2 THEN findidsecondarg = getelement$(a$, 2)
        try = findid(firstelement$)
        IF Error_Happened THEN GOTO errmes
        DO WHILE try
            IF id.subfunc = 2 THEN validsub = 1: EXIT DO
            IF try = 2 THEN
                findidsecondarg = "": IF n >= 2 THEN findidsecondarg = getelement$(a$, 2)
                findanotherid = 1
                try = findid(firstelement$)
                IF Error_Happened THEN GOTO errmes
            ELSE
                try = 0
            END IF
        LOOP
        IF validsub = 0 THEN a$ = "Expected CALL sub-name [(...)]": GOTO errmes
    END IF

    'sub?
    IF n >= 1 THEN

        IF firstelement$ = "?" THEN firstelement$ = "PRINT"

        findidsecondarg = "": IF n >= 2 THEN findidsecondarg = getelement$(a$, 2)
        try = findid(firstelement$)
        IF Error_Happened THEN GOTO errmes
        DO WHILE try
            IF id.subfunc = 2 THEN

                'check symbol
                s$ = removesymbol$(firstelement$ + "")
                IF Error_Happened THEN GOTO errmes
                IF ASC(id.musthave) = 36 THEN '="$"
                    IF s$ <> "$" THEN GOTO notsubcall 'missing musthave "$"
                ELSE
                    IF LEN(s$) THEN GOTO notsubcall 'unrequired symbol added
                END IF
                'check for variable assignment
                IF n > 1 THEN
                    IF ASC(id.specialformat) <> 61 THEN '<>"="
                        IF ASC(getelement$(a$, 2)) = 61 THEN GOTO notsubcall 'assignment, not sub call
                    END IF
                END IF
                'check for array assignment
                IF n > 2 THEN
                    IF firstelement$ <> "PRINT" AND firstelement$ <> "LPRINT" THEN
                        IF getelement$(a$, 2) = "(" THEN
                            B = 1
                            FOR i = 3 TO n
                                e$ = getelement$(a$, i)
                                IF e$ = "(" THEN B = B + 1
                                IF e$ = ")" THEN
                                    B = B - 1
                                    IF B = 0 THEN
                                        IF i = n THEN EXIT FOR
                                        IF getelement$(a$, i + 1) = "=" THEN GOTO notsubcall
                                    END IF
                                END IF
                            NEXT
                        END IF
                    END IF
                END IF


                IF id.NoCloud THEN
                    IF Cloud THEN a$ = "Feature not supported on QLOUD": GOTO errmes '***NOCLOUD***
                END IF

                'generate error on driect _GL call
                IF firstelement$ = "_GL" THEN a$ = "Cannot call SUB _GL directly": GOTO errmes

                IF firstelement$ = "OPEN" THEN
                    'gwbasic or qbasic version?
                    B = 0
                    FOR x = 2 TO n
                        a2$ = getelement$(a$, x)
                        IF a2$ = "(" THEN B = B + 1
                        IF a2$ = ")" THEN B = B - 1
                        IF a2$ = "FOR" OR a2$ = "AS" THEN EXIT FOR 'qb style open verified
                        IF B = 0 AND a2$ = "," THEN 'the gwbasic version includes a comma after the first string expression
                            findanotherid = 1
                            try = findid(firstelement$) 'id of sub_open_gwbasic
                            IF Error_Happened THEN GOTO errmes
                            EXIT FOR
                        END IF
                    NEXT
                END IF


                'IF findid(firstelement$) THEN
                'IF id.subfunc = 2 THEN


                IF firstelement$ = "CLOSE" OR firstelement$ = "RESET" THEN
                    IF firstelement$ = "RESET" THEN
                        IF n > 1 THEN a$ = "Syntax error": GOTO errmes
                    END IF
                    l$ = firstelement$
                    IF n = 1 THEN
                        PRINT #12, "sub_close(NULL,0);" 'closes all files
                    ELSE
                        l$ = l$ + sp
                        B = 0
                        s = 0
                        a3$ = ""
                        FOR x = 2 TO n
                            a2$ = getelement$(ca$, x)
                            IF a2$ = "(" THEN B = B + 1
                            IF a2$ = ")" THEN B = B - 1
                            IF a2$ = "#" AND B = 0 THEN
                                IF s = 0 THEN s = 1 ELSE a$ = "Unexpected #": GOTO errmes
                                l$ = l$ + "#" + sp2
                                GOTO closenexta
                            END IF

                            IF a2$ = "," AND B = 0 THEN
                                IF s = 2 THEN
                                    e$ = fixoperationorder$(a3$)
                                    IF Error_Happened THEN GOTO errmes
                                    l$ = l$ + tlayout$ + sp2 + "," + sp
                                    e$ = evaluatetotyp(e$, 64&)
                                    IF Error_Happened THEN GOTO errmes
                                    PRINT #12, "sub_close(" + e$ + ",1);"
                                    a3$ = ""
                                    s = 0
                                    GOTO closenexta
                                ELSE
                                    a$ = "Expected expression before ,": GOTO errmes
                                END IF
                            END IF

                            s = 2
                            IF a3$ = "" THEN a3$ = a2$ ELSE a3$ = a3$ + sp + a2$

                            closenexta:
                        NEXT

                        IF s = 2 THEN
                            e$ = fixoperationorder$(a3$)
                            IF Error_Happened THEN GOTO errmes
                            l$ = l$ + tlayout$
                            e$ = evaluatetotyp(e$, 64&)
                            IF Error_Happened THEN GOTO errmes
                            PRINT #12, "sub_close(" + e$ + ",1);"
                        ELSE
                            l$ = LEFT$(l$, LEN(l$) - 1)
                        END IF

                    END IF
                    layoutdone = 1: IF LEN(layout$) THEN layout$ = layout$ + sp + l$ ELSE layout$ = l$
                    GOTO finishedline
                END IF 'close
















                'data, restore, read
                IF firstelement$ = "READ" THEN 'file input
                    xread ca$, n
                    IF Error_Happened THEN GOTO errmes
                    'note: layout done in xread sub
                    GOTO finishedline
                END IF 'read





































                lineinput = 0
                IF n >= 2 THEN
                    IF firstelement$ = "LINE" AND secondelement$ = "INPUT" THEN
                        lineinput = 1
                        a$ = RIGHT$(a$, LEN(a$) - 5): ca$ = RIGHT$(ca$, LEN(ca$) - 5): n = n - 1 'remove "LINE"
                        firstelement$ = "INPUT"
                    END IF
                END IF

                IF firstelement$ = "INPUT" THEN 'file input
                    IF n > 1 THEN
                        IF getelement$(a$, 2) = "#" THEN
                            l$ = "INPUT" + sp + "#": IF lineinput THEN l$ = "LINE" + sp + l$

                            u$ = str2$(uniquenumber)
                            'which file?
                            IF n = 2 THEN a$ = "Expected # ... , ...": GOTO errmes
                            a3$ = ""
                            B = 0
                            FOR i = 3 TO n
                                a2$ = getelement$(ca$, i)
                                IF a2$ = "(" THEN B = B + 1
                                IF a2$ = ")" THEN B = B - 1
                                IF a2$ = "," AND B = 0 THEN
                                    IF a3$ = "" THEN a$ = "Expected # ... , ...": GOTO errmes
                                    GOTO inputgotfn
                                END IF
                                IF a3$ = "" THEN a3$ = a2$ ELSE a3$ = a3$ + sp + a2$
                            NEXT
                            inputgotfn:
                            e$ = fixoperationorder$(a3$)
                            IF Error_Happened THEN GOTO errmes
                            l$ = l$ + sp2 + tlayout$
                            e$ = evaluatetotyp(e$, 64&)
                            IF Error_Happened THEN GOTO errmes
                            PRINT #12, "tmp_fileno=" + e$ + ";"
                            PRINT #12, "if (new_error) goto skip" + u$ + ";"
                            i = i + 1
                            IF i > n THEN a$ = "Expected , ...": GOTO errmes
                            a3$ = ""
                            B = 0
                            FOR i = i TO n
                                a2$ = getelement$(ca$, i)
                                IF a2$ = "(" THEN B = B + 1
                                IF a2$ = ")" THEN B = B - 1
                                IF i = n THEN
                                    IF a3$ = "" THEN a3$ = a2$ ELSE a3$ = a3$ + sp + a2$
                                    a2$ = ",": B = 0
                                END IF
                                IF a2$ = "," AND B = 0 THEN
                                    IF a3$ = "" THEN a$ = "Expected , ...": GOTO errmes
                                    e$ = fixoperationorder$(a3$)
                                    IF Error_Happened THEN GOTO errmes
                                    l$ = l$ + sp2 + "," + sp + tlayout$
                                    e$ = evaluate(e$, t)
                                    IF Error_Happened THEN GOTO errmes
                                    IF (t AND ISREFERENCE) = 0 THEN a$ = "Expected variable-name": GOTO errmes
                                    IF (t AND ISSTRING) THEN
                                        e$ = refer(e$, t, 0)
                                        IF Error_Happened THEN GOTO errmes
                                        IF lineinput THEN
                                            PRINT #12, "sub_file_line_input_string(tmp_fileno," + e$ + ");"
                                            PRINT #12, "if (new_error) goto skip" + u$ + ";"
                                        ELSE
                                            PRINT #12, "sub_file_input_string(tmp_fileno," + e$ + ");"
                                            PRINT #12, "if (new_error) goto skip" + u$ + ";"
                                        END IF
                                        stringprocessinghappened = 1
                                    ELSE
                                        IF lineinput THEN a$ = "Expected string-variable": GOTO errmes

                                        'numeric variable
                                        IF (t AND ISFLOAT) <> 0 OR (t AND 511) <> 64 THEN
                                            IF (t AND ISOFFSETINBITS) THEN
                                                setrefer e$, t, "((int64)func_file_input_float(tmp_fileno," + str2(t) + "))", 1
                                                IF Error_Happened THEN GOTO errmes
                                            ELSE
                                                setrefer e$, t, "func_file_input_float(tmp_fileno," + str2(t) + ")", 1
                                                IF Error_Happened THEN GOTO errmes
                                            END IF
                                        ELSE
                                            IF t AND ISUNSIGNED THEN
                                                setrefer e$, t, "func_file_input_uint64(tmp_fileno)", 1
                                                IF Error_Happened THEN GOTO errmes
                                            ELSE
                                                setrefer e$, t, "func_file_input_int64(tmp_fileno)", 1
                                                IF Error_Happened THEN GOTO errmes
                                            END IF
                                        END IF

                                        PRINT #12, "if (new_error) goto skip" + u$ + ";"

                                    END IF
                                    IF i = n THEN EXIT FOR
                                    IF lineinput THEN a$ = "Too many variables": GOTO errmes
                                    a3$ = "": a2$ = ""
                                END IF
                                IF a3$ = "" THEN a3$ = a2$ ELSE a3$ = a3$ + sp + a2$
                            NEXT
                            PRINT #12, "skip" + u$ + ":"
                            PRINT #12, "revert_input_check();"
                            IF stringprocessinghappened THEN PRINT #12, cleanupstringprocessingcall$ + "0);"
                            layoutdone = 1: IF LEN(layout$) THEN layout$ = layout$ + sp + l$ ELSE layout$ = l$
                            GOTO finishedline
                        END IF
                    END IF
                END IF 'input#


                IF firstelement$ = "INPUT" THEN
                    l$ = "INPUT": IF lineinput THEN l$ = "LINE" + sp + l$
                    commaneeded = 0
                    i = 2

                    newline = 1: IF getelement$(a$, i) = ";" THEN newline = 0: i = i + 1: l$ = l$ + sp + ";"

                    a2$ = getelement$(ca$, i)
                    IF LEFT$(a2$, 1) = CHR$(34) THEN
                        e$ = fixoperationorder$(a2$): l$ = l$ + sp + tlayout$
                        IF Error_Happened THEN GOTO errmes
                        PRINT #12, "qbs_print(qbs_new_txt_len(" + a2$ + "),0);"
                        i = i + 1
                        'MUST be followed by a ; or ,
                        a2$ = getelement$(ca$, i)
                        i = i + 1
                        l$ = l$ + sp2 + a2$
                        IF a2$ = ";" THEN
                            IF lineinput THEN GOTO finishedpromptstring
                            PRINT #12, "qbs_print(qbs_new_txt(" + CHR$(34) + "? " + CHR$(34) + "),0);"
                            GOTO finishedpromptstring
                        END IF
                        IF a2$ = "," THEN
                            GOTO finishedpromptstring
                        END IF
                        a$ = "INPUT STATEMENT: SYNTAX ERROR!": GOTO errmes
                    END IF
                    'there was no promptstring, so print a ?
                    IF lineinput = 0 THEN PRINT #12, "qbs_print(qbs_new_txt(" + CHR$(34) + "? " + CHR$(34) + "),0);"
                    finishedpromptstring:
                    numvar = 0
                    FOR i = i TO n
                        IF commaneeded = 1 THEN
                            a2$ = getelement$(ca$, i)
                            IF a2$ <> "," THEN a$ = "INPUT STATEMENT: SYNTAX ERROR! (COMMA EXPECTED)": GOTO errmes
                        ELSE

                            B = 0
                            e$ = ""
                            FOR i2 = i TO n
                                e2$ = getelement$(ca$, i2)
                                IF e2$ = "(" THEN B = B + 1
                                IF e2$ = ")" THEN B = B - 1
                                IF e2$ = "," AND B = 0 THEN i2 = i2 - 1: EXIT FOR
                                e$ = e$ + sp + e2$
                            NEXT
                            i = i2: IF i > n THEN i = n
                            IF e$ = "" THEN a$ = "Expected variable": GOTO errmes
                            e$ = RIGHT$(e$, LEN(e$) - 1)
                            e$ = fixoperationorder$(e$)
                            IF Error_Happened THEN GOTO errmes
                            l$ = l$ + sp + tlayout$: IF i <> n THEN l$ = l$ + sp2 + ","
                            e$ = evaluate(e$, t)
                            IF Error_Happened THEN GOTO errmes
                            IF (t AND ISREFERENCE) = 0 THEN a$ = "Expected variable": GOTO errmes

                            IF (t AND ISSTRING) THEN
                                e$ = refer(e$, t, 0)
                                IF Error_Happened THEN GOTO errmes
                                numvar = numvar + 1
                                IF lineinput THEN
                                    PRINT #12, "qbs_input_variabletypes[" + str2(numvar) + "]=ISSTRING+512;"
                                ELSE
                                    PRINT #12, "qbs_input_variabletypes[" + str2(numvar) + "]=ISSTRING;"
                                END IF
                                PRINT #12, "qbs_input_variableoffsets[" + str2(numvar) + "]=" + e$ + ";"
                                GOTO gotinputvar
                            END IF

                            IF lineinput THEN a$ = "Expected string variable": GOTO errmes
                            IF (t AND ISARRAY) THEN
                                IF (t AND ISOFFSETINBITS) THEN
                                    a$ = "INPUT cannot handle BIT array elements yet": GOTO errmes
                                END IF
                            END IF
                            e$ = "&(" + refer(e$, t, 0) + ")"
                            IF Error_Happened THEN GOTO errmes

                            'remove assumed/unnecessary flags
                            IF (t AND ISPOINTER) THEN t = t - ISPOINTER
                            IF (t AND ISINCONVENTIONALMEMORY) THEN t = t - ISINCONVENTIONALMEMORY
                            IF (t AND ISREFERENCE) THEN t = t - ISREFERENCE

                            'IF (t AND ISOFFSETINBITS) THEN
                            'numvar = numvar + 1
                            'consider storing the bit offset in unused bits of t
                            'PRINT #12, "qbs_input_variabletypes[" + str2(numvar) + "]=" + str2(t) + ";"
                            'PRINT #12, "qbs_input_variableoffsets[" + str2(numvar) + "]=" + refer(ref$, typ, 1) + ";"
                            'GOTO gotinputvar
                            'END IF

                            'assume it is a regular variable
                            numvar = numvar + 1
                            PRINT #12, "qbs_input_variabletypes[" + str2(numvar) + "]=" + str2$(t) + ";"
                            PRINT #12, "qbs_input_variableoffsets[" + str2(numvar) + "]=" + e$ + ";"
                            GOTO gotinputvar

                        END IF
                        gotinputvar:
                        commaneeded = commaneeded + 1: IF commaneeded = 2 THEN commaneeded = 0
                    NEXT
                    IF numvar = 0 THEN a$ = "INPUT STATEMENT: SYNTAX ERROR! (NO VARIABLES LISTED FOR INPUT)": GOTO errmes
                    IF lineinput = 1 AND numvar > 1 THEN a$ = "Too many variables": GOTO errmes
                    PRINT #12, "qbs_input(" + str2(numvar) + "," + str2$(newline) + ");"
                    PRINT #12, "if (stop_program) end();"
                    PRINT #12, cleanupstringprocessingcall$ + "0);"
                    layoutdone = 1: IF LEN(layout$) THEN layout$ = layout$ + sp + l$ ELSE layout$ = l$
                    GOTO finishedline
                END IF



                IF firstelement$ = "WRITE" THEN 'file write
                    IF n > 1 THEN
                        IF getelement$(a$, 2) = "#" THEN
                            xfilewrite ca$, n
                            IF Error_Happened THEN GOTO errmes
                            GOTO finishedline
                        END IF '#
                    END IF 'n>1
                END IF '"write"

                IF firstelement$ = "WRITE" THEN 'write
                    xwrite ca$, n
                    IF Error_Happened THEN GOTO errmes
                    GOTO finishedline
                END IF '"write"

                IF firstelement$ = "PRINT" THEN 'file print
                    IF n > 1 THEN
                        IF getelement$(a$, 2) = "#" THEN
                            xfileprint a$, ca$, n
                            IF Error_Happened THEN GOTO errmes
                            l$ = tlayout$
                            layoutdone = 1: IF LEN(layout$) THEN layout$ = layout$ + sp + l$ ELSE layout$ = l$
                            GOTO finishedline
                        END IF '#
                    END IF 'n>1
                END IF '"print"

                IF firstelement$ = "PRINT" OR firstelement$ = "LPRINT" THEN
                    xprint a$, ca$, n
                    IF Error_Happened THEN GOTO errmes
                    l$ = tlayout$
                    layoutdone = 1: IF LEN(layout$) THEN layout$ = layout$ + sp + l$ ELSE layout$ = l$
                    GOTO finishedline
                END IF

                IF firstelement$ = "CLEAR" THEN
                    IF subfunc$ <> "" THEN a$ = "CLEAR cannot be used inside a SUB/FUNCTION": GOTO errmes
                END IF

                'LSET/RSET
                IF firstelement$ = "LSET" OR firstelement$ = "RSET" THEN
                    IF n = 1 THEN a$ = "Expected " + firstelement$ + " ...": GOTO errmes
                    l$ = firstelement$
                    dest$ = ""
                    source$ = ""
                    part = 1
                    i = 2
                    a3$ = ""
                    B = 0
                    DO
                        IF i > n THEN
                            IF part <> 2 OR a3$ = "" THEN a$ = "Expected LSET/RSET stringvariable=string": GOTO errmes
                            source$ = a3$
                            EXIT DO
                        END IF
                        a2$ = getelement$(ca$, i)
                        IF a2$ = "(" THEN B = B + 1
                        IF a2$ = ")" THEN B = B - 1
                        IF a2$ = "=" AND B = 0 THEN
                            IF part = 1 THEN dest$ = a3$: part = 2: a3$ = "": GOTO lrsetgotpart
                        END IF
                        IF LEN(a3$) THEN a3$ = a3$ + sp + a2$ ELSE a3$ = a2$
                        lrsetgotpart:
                        i = i + 1
                    LOOP
                    IF dest$ = "" THEN a$ = "Expected LSET/RSET stringvariable=string": GOTO errmes
                    'check if it is a valid source string
                    f$ = fixoperationorder$(dest$)
                    IF Error_Happened THEN GOTO errmes
                    l$ = l$ + sp + tlayout$ + sp + "="
                    e$ = evaluate(f$, sourcetyp)
                    IF Error_Happened THEN GOTO errmes
                    IF (sourcetyp AND ISREFERENCE) = 0 OR (sourcetyp AND ISSTRING) = 0 THEN a$ = "LSET/RSET expects a string variable/array-element as its first argument": GOTO errmes
                    dest$ = evaluatetotyp(f$, ISSTRING)
                    IF Error_Happened THEN GOTO errmes
                    source$ = fixoperationorder$(source$)
                    IF Error_Happened THEN GOTO errmes
                    l$ = l$ + sp + tlayout$
                    layoutdone = 1: IF LEN(layout$) THEN layout$ = layout$ + sp + l$ ELSE layout$ = l$
                    source$ = evaluatetotyp(source$, ISSTRING)
                    IF Error_Happened THEN GOTO errmes
                    IF firstelement$ = "LSET" THEN
                        PRINT #12, "sub_lset(" + dest$ + "," + source$ + ");"
                    ELSE
                        PRINT #12, "sub_rset(" + dest$ + "," + source$ + ");"
                    END IF
                    GOTO finishedline
                END IF

                'SWAP
                IF firstelement$ = "SWAP" THEN
                    IF n < 4 THEN a$ = "Expected SWAP ... , ...": GOTO errmes
                    B = 0
                    ele = 1
                    e1$ = ""
                    e2$ = ""
                    FOR i = 2 TO n
                        e$ = getelement$(ca$, i)
                        IF e$ = "(" THEN B = B + 1
                        IF e$ = ")" THEN B = B - 1
                        IF e$ = "," AND B = 0 THEN
                            IF ele = 2 THEN a$ = "Expected SWAP ... , ...": GOTO errmes
                            ele = 2
                        ELSE
                            IF ele = 1 THEN e1$ = e1$ + sp + e$ ELSE e2$ = e2$ + sp + e$
                        END IF
                    NEXT
                    IF e2$ = "" THEN a$ = "Expected SWAP ... , ...": GOTO errmes
                    e1$ = RIGHT$(e1$, LEN(e1$) - 1): e2$ = RIGHT$(e2$, LEN(e2$) - 1)

                    e1$ = fixoperationorder(e1$)
                    IF Error_Happened THEN GOTO errmes
                    e1l$ = tlayout$
                    e2$ = fixoperationorder(e2$)
                    IF Error_Happened THEN GOTO errmes
                    e2l$ = tlayout$
                    e1$ = evaluate(e1$, e1typ): e2$ = evaluate(e2$, e2typ)
                    IF Error_Happened THEN GOTO errmes
                    IF (e1typ AND ISREFERENCE) = 0 OR (e2typ AND ISREFERENCE) = 0 THEN a$ = "Expected variable": GOTO errmes

                    layoutdone = 1
                    l$ = "SWAP" + sp + e1l$ + sp2 + "," + sp + e2l$
                    IF LEN(layout$) = 0 THEN layout$ = l$ ELSE layout$ = layout$ + sp + l$

                    'swap strings?
                    IF (e1typ AND ISSTRING) THEN
                        IF (e2typ AND ISSTRING) = 0 THEN a$ = "Type mismatch": GOTO errmes
                        e1$ = refer(e1$, e1typ, 0): e2$ = refer(e2$, e2typ, 0)
                        IF Error_Happened THEN GOTO errmes
                        PRINT #12, "swap_string(" + e1$ + "," + e2$ + ");"
                        GOTO finishedline
                    END IF

                    'swap UDT?
                    'note: entire UDTs, unlike thier elements cannot be swapped like standard variables
                    '      as UDT sizes may vary, and to avoid a malloc operation, QB64 should allocate a buffer
                    '      in global.txt for the purpose of swapping each UDT type

                    IF e1typ AND ISUDT THEN
                        a$ = e1$
                        'retrieve ID
                        i = INSTR(a$, sp3)
                        IF i THEN
                            idnumber = VAL(LEFT$(a$, i - 1)): a$ = RIGHT$(a$, LEN(a$) - i)
                            getid idnumber
                            IF Error_Happened THEN GOTO errmes
                            u = VAL(a$)
                            i = INSTR(a$, sp3): a$ = RIGHT$(a$, LEN(a$) - i): E = VAL(a$)
                            i = INSTR(a$, sp3): o$ = RIGHT$(a$, LEN(a$) - i)
                            n$ = "UDT_" + RTRIM$(id.n): IF id.t = 0 THEN n$ = "ARRAY_" + n$ + "[0]"
                            IF E = 0 THEN 'not an element of UDT u
                                lhsscope$ = scope$
                                e$ = e2$: t2 = e2typ
                                IF (t2 AND ISUDT) = 0 THEN a$ = "Expected SWAP with similar user defined type": GOTO errmes
                                idnumber2 = VAL(e$)
                                getid idnumber2
                                IF Error_Happened THEN GOTO errmes
                                n2$ = "UDT_" + RTRIM$(id.n): IF id.t = 0 THEN n2$ = "ARRAY_" + n2$ + "[0]"
                                i = INSTR(e$, sp3): e$ = RIGHT$(e$, LEN(e$) - i): u2 = VAL(e$)
                                i = INSTR(e$, sp3): e$ = RIGHT$(e$, LEN(e$) - i): e2 = VAL(e$)

                                i = INSTR(e$, sp3): o2$ = RIGHT$(e$, LEN(e$) - i)
                                'WARNING: u2 may need minor modifications based on e to see if they are the same
                                IF u <> u2 OR e2 <> 0 THEN a$ = "Expected SWAP with similar user defined type": GOTO errmes
                                dst$ = "(((char*)" + lhsscope$ + n$ + ")+(" + o$ + "))"
                                src$ = "(((char*)" + scope$ + n2$ + ")+(" + o2$ + "))"
                                B = udtxsize(u) \ 8
                                siz$ = str2$(B)
                                IF B = 1 THEN PRINT #12, "swap_8(" + src$ + "," + dst$ + ");"
                                IF B = 2 THEN PRINT #12, "swap_16(" + src$ + "," + dst$ + ");"
                                IF B = 4 THEN PRINT #12, "swap_32(" + src$ + "," + dst$ + ");"
                                IF B = 8 THEN PRINT #12, "swap_64(" + src$ + "," + dst$ + ");"
                                IF B <> 1 AND B <> 2 AND B <> 4 AND B <> 8 THEN PRINT #12, "swap_block(" + src$ + "," + dst$ + "," + siz$ + ");"
                                GOTO finishedline
                            END IF 'e=0
                        END IF 'i
                    END IF 'isudt

                    'cull irrelavent flags to make comparison possible
                    e1typc = e1typ
                    IF e1typc AND ISPOINTER THEN e1typc = e1typc - ISPOINTER
                    IF e1typc AND ISINCONVENTIONALMEMORY THEN e1typc = e1typc - ISINCONVENTIONALMEMORY
                    IF e1typc AND ISARRAY THEN e1typc = e1typc - ISARRAY
                    IF e1typc AND ISUNSIGNED THEN e1typc = e1typc - ISUNSIGNED
                    IF e1typc AND ISUDT THEN e1typc = e1typc - ISUDT
                    e2typc = e2typ
                    IF e2typc AND ISPOINTER THEN e2typc = e2typc - ISPOINTER
                    IF e2typc AND ISINCONVENTIONALMEMORY THEN e2typc = e2typc - ISINCONVENTIONALMEMORY
                    IF e2typc AND ISARRAY THEN e2typc = e2typc - ISARRAY
                    IF e2typc AND ISUNSIGNED THEN e2typc = e2typc - ISUNSIGNED
                    IF e2typc AND ISUDT THEN e2typc = e2typc - ISUDT
                    IF e1typc <> e2typc THEN a$ = "Type mismatch": GOTO errmes
                    t = e1typ
                    IF t AND ISOFFSETINBITS THEN a$ = "Cannot SWAP bit-length variables": GOTO errmes
                    B = t AND 511
                    t$ = str2$(B): IF B > 64 THEN t$ = "longdouble"
                    PRINT #12, "swap_" + t$ + "(&" + refer(e1$, e1typ, 0) + ",&" + refer(e2$, e2typ, 0) + ");"
                    IF Error_Happened THEN GOTO errmes
                    GOTO finishedline
                END IF

                IF firstelement$ = "OPTION" THEN
                    IF n <> 3 THEN a$ = "Expected OPTION BASE 0 or 1": GOTO errmes
                    IF getelement$(a$, 2) <> "BASE" THEN a$ = "Expected OPTION BASE 0 or 1": GOTO errmes
                    l$ = getelement$(a$, 3)
                    IF l$ <> "0" AND l$ <> "1" THEN a$ = "Expected OPTION BASE 0 or 1": GOTO errmes
                    IF l$ = "1" THEN optionbase = 1 ELSE optionbase = 0
                    l$ = "OPTION" + sp + "BASE" + sp + l$
                    layoutdone = 1: IF LEN(layout$) THEN layout$ = layout$ + sp + l$ ELSE layout$ = l$
                    GOTO finishedline
                END IF

                'any other "unique" subs can be processed above

                id2 = id

                targetid = currentid

                IF RTRIM$(id2.callname) = "sub_stub" THEN a$ = "Command not implemented": GOTO errmes

                IF n > 1 THEN
                    IF id2.args = 0 THEN a$ = "SUB does not require any arguments": GOTO errmes
                END IF

                SetDependency id2.Dependency

                seperateargs_error = 0
                passedneeded = seperateargs(getelements(a$, 2, n), getelements(ca$, 2, n), passed&)
                IF seperateargs_error THEN a$ = seperateargs_error_message: GOTO errmes

                'backup args to local string array space before calling evaluate
                FOR i = 1 TO OptMax: separgs2(i) = "": NEXT 'save space!
                FOR i = 1 TO OptMax + 1: separgslayout2(i) = "": NEXT
                FOR i = 1 TO id2.args: separgs2(i) = separgs(i): NEXT
                FOR i = 1 TO id2.args + 1: separgslayout2(i) = separgslayout(i): NEXT



                IF Debug THEN
                    PRINT #9, "separgs:": FOR i = 1 TO id2.args: PRINT #9, i, separgs2(i): NEXT
                    PRINT #9, "separgslayout:": FOR i = 1 TO id2.args + 1: PRINT #9, i, separgslayout2(i): NEXT
                END IF



                'note: seperateargs finds the arguments to pass and sets passed& as necessary
                '      FIXOPERTIONORDER is not called on these args yet
                '      what we need it to do is build a second array of layout info at the same time
                '   ref:DIM SHARED separgslayout(100) AS STRING
                '   the above array stores what layout info (if any) goes BEFORE the arg in question
                '       it has one extra index which is the arg after

                IF usecall THEN
                    IF usecall = 1 THEN l$ = "CALL" + sp + RTRIM$(id.cn) + RTRIM$(id.musthave) + sp2 + "(" + sp2
                    IF usecall = 2 THEN l$ = "CALL" + sp + RTRIM$(id.cn) + RTRIM$(id.musthave) + sp 'sp at end for easy parsing
                ELSE
                    l$ = RTRIM$(id.cn) + RTRIM$(id.musthave) + sp
                END IF

                subcall$ = RTRIM$(id.callname) + "("
                addedlayout = 0

                fieldcall = 0
                'GET/PUT field exception
                IF RTRIM$(id2.callname) = "sub_get" OR RTRIM$(id2.callname) = "sub_put" THEN
                    IF passed AND 2 THEN
                        'regular GET/PUT call with variable provided
                        passed = passed - 2 'for complience with existing methods, remove 'passed' flag for the passing of a variable
                    ELSE
                        'FIELD GET/PUT call with variable omited
                        IF RTRIM$(id2.callname) = "sub_get" THEN
                            fieldcall = 1
                            subcall$ = "field_get("
                        ELSE
                            fieldcall = 2
                            subcall$ = "field_put("
                        END IF
                    END IF
                END IF 'field exception

                IF RTRIM$(id2.callname) = "sub_timer" OR RTRIM$(id2.callname) = "sub_key" THEN 'spacing exception
                    IF usecall = 0 THEN
                        l$ = LEFT$(l$, LEN(l$) - 1) + sp2
                    END IF
                END IF

                FOR i = 1 TO id2.args
                    targettyp = CVL(MID$(id2.arg, -3 + i * 4, 4))
                    nele = ASC(MID$(id2.nele, i, 1))
                    nelereq = ASC(MID$(id2.nelereq, i, 1))

                    addlayout = 1 'omits option values in layout (eg. BINARY="2")
                    convertspacing = 0 'if an 'equation' is next, it will be preceeded by a space
                    x$ = separgslayout2$(i)
                    DO WHILE LEN(x$)
                        x = ASC(x$)
                        IF x THEN
                            convertspacing = 0
                            x2$ = MID$(x$, 2, x)
                            x$ = RIGHT$(x$, LEN(x$) - x - 1)

                            s = 0
                            an = 0
                            x3$ = RIGHT$(l$, 1)
                            IF x3$ = sp THEN s = 1
                            IF x3$ = sp2 THEN
                                s = 2
                                IF alphanumeric(ASC(RIGHT$(l$, 2))) THEN an = 1
                            ELSE
                                IF alphanumeric(ASC(x3$)) THEN an = 1
                            END IF
                            s1 = s

                            IF alphanumeric(ASC(x2$)) THEN convertspacing = 1


                            IF x2$ = "LPRINT" THEN

                                'x2$="LPRINT"
                                'x$=CHR$(0)
                                'x3$=[sp] from WIDTH[sp]
                                'therefore...
                                's=1
                                'an=0
                                'convertspacing=1


                                'if debug=1 then
                                'print #9,"LPRINT:"
                                'print #9,s
                                'print #9,an
                                'print #9,l$
                                'print #9,x2$
                                'end if

                            END IF




                            IF (an = 1 OR addedlayout = 1) AND alphanumeric(ASC(x2$)) <> 0 THEN



                                s = 1 'force space
                                x2$ = x2$ + sp2
                                GOTO customlaychar
                            END IF

                            IF x2$ = "=" THEN
                                s = 1
                                x2$ = x2$ + sp
                                GOTO customlaychar
                            END IF

                            IF x2$ = "#" THEN
                                s = 1
                                x2$ = x2$ + sp2
                                GOTO customlaychar
                            END IF

                            IF x2$ = "," THEN x2$ = x2$ + sp: GOTO customlaychar


                            IF x$ = CHR$(0) THEN 'substitution
                                IF x2$ = "STEP" THEN x2$ = x2$ + sp2: GOTO customlaychar
                                x2$ = x2$ + sp: GOTO customlaychar
                            END IF

                            'default solution sp2+?+sp2
                            x2$ = x2$ + sp2





                            customlaychar:
                            IF s = 0 THEN s = 2
                            IF s <> s1 THEN
                                IF s1 THEN l$ = LEFT$(l$, LEN(l$) - 1)
                                IF s = 1 THEN l$ = l$ + sp
                                IF s = 2 THEN l$ = l$ + sp2
                            END IF

                            IF (RTRIM$(id2.callname) = "sub_timer" OR RTRIM$(id2.callname) = "sub_key") AND i = id2.args THEN 'spacing exception
                                IF x2$ <> ")" + sp2 THEN
                                    l$ = LEFT$(l$, LEN(l$) - 1) + sp
                                END IF
                            END IF

                            l$ = l$ + x2$

                        ELSE
                            addlayout = 0
                            x$ = RIGHT$(x$, LEN(x$) - 1)
                        END IF
                        addedlayout = 0
                    LOOP



                    '---better sub syntax checking begins here---



                    IF targettyp = -3 THEN
                        IF separgs2(i) = "NULL" THEN a$ = "Expected array name": GOTO errmes
                        'names of numeric arrays have ( ) automatically appended (nothing else)
                        e$ = separgs2(i)

                        IF INSTR(e$, sp) = 0 THEN 'one element only
                            try_string$ = e$
                            try = findid(try_string$)
                            IF Error_Happened THEN GOTO errmes
                            DO
                                IF try THEN
                                    IF id.arraytype THEN
                                        IF (id.arraytype AND ISSTRING) = 0 THEN
                                            e$ = e$ + sp + "(" + sp + ")"
                                            EXIT DO
                                        END IF
                                    END IF
                                    '---
                                    IF try = 2 THEN findanotherid = 1: try = findid(try_string$) ELSE try = 0
                                    IF Error_Happened THEN GOTO errmes
                                END IF 'if try
                                IF try = 0 THEN 'add symbol?
                                    IF LEN(removesymbol$(try_string$)) = 0 THEN
                                        IF Error_Happened THEN GOTO errmes
                                        a = ASC(try_string$)
                                        IF a >= 97 AND a <= 122 THEN a = a - 32
                                        IF a = 95 THEN a = 91
                                        a = a - 64
                                        IF LEN(defineextaz(a)) THEN try_string$ = try_string$ + defineextaz(a): try = findid(try_string$)
                                        IF Error_Happened THEN GOTO errmes
                                    END IF
                                END IF 'try=0
                            LOOP UNTIL try = 0
                        END IF 'one element only



                        e$ = fixoperationorder$(e$)
                        IF Error_Happened THEN GOTO errmes
                        IF convertspacing = 1 AND addlayout = 1 THEN l$ = LEFT$(l$, LEN(l$) - 1) + sp
                        IF addlayout THEN l$ = l$ + tlayout$: addedlayout = 1
                        e$ = evaluatetotyp(e$, -2)
                        IF Error_Happened THEN GOTO errmes
                        GOTO sete
                    END IF '-3


                    IF targettyp = -2 THEN
                        e$ = fixoperationorder$(e$)
                        IF Error_Happened THEN GOTO errmes
                        IF convertspacing = 1 AND addlayout = 1 THEN l$ = LEFT$(l$, LEN(l$) - 1) + sp
                        IF addlayout THEN l$ = l$ + tlayout$: addedlayout = 1
                        e$ = evaluatetotyp(e$, -2)
                        IF Error_Happened THEN GOTO errmes
                        GOTO sete
                    END IF '-2

                    IF targettyp = -4 THEN

                        IF fieldcall THEN
                            i = id2.args + 1
                            EXIT FOR
                        END IF

                        IF separgs2(i) = "NULL" THEN a$ = "Expected variable name/array element": GOTO errmes
                        e$ = fixoperationorder$(separgs2(i))
                        IF Error_Happened THEN GOTO errmes
                        IF convertspacing = 1 AND addlayout = 1 THEN l$ = LEFT$(l$, LEN(l$) - 1) + sp
                        IF addlayout THEN l$ = l$ + tlayout$: addedlayout = 1

                        'GET/PUT RANDOM-ACCESS override
                        IF firstelement$ = "GET" OR firstelement$ = "PUT" THEN
                            e2$ = e$ 'backup
                            e$ = evaluate(e$, sourcetyp)
                            IF Error_Happened THEN GOTO errmes
                            IF (sourcetyp AND ISSTRING) THEN
                                IF (sourcetyp AND ISFIXEDLENGTH) = 0 THEN
                                    'replace name of sub to call
                                    subcall$ = RIGHT$(subcall$, LEN(subcall$) - 7) 'delete original name
                                    'note: GET2 & PUT2 take differing input, following code is correct
                                    IF firstelement$ = "GET" THEN
                                        subcall$ = "sub_get2" + subcall$
                                        e$ = refer(e$, sourcetyp, 0) 'pass a qbs pointer instead
                                        IF Error_Happened THEN GOTO errmes
                                        GOTO sete
                                    ELSE
                                        subcall$ = "sub_put2" + subcall$
                                        'no goto sete required, fall through
                                    END IF
                                END IF
                            END IF
                            e$ = e2$ 'restore
                        END IF 'override

                        e$ = evaluatetotyp(e$, -4)
                        IF Error_Happened THEN GOTO errmes
                        GOTO sete
                    END IF '-4

                    IF separgs2(i) = "NULL" THEN
                        e$ = "NULL"
                    ELSE

                        e2$ = fixoperationorder$(separgs2(i))
                        IF Error_Happened THEN GOTO errmes
                        IF convertspacing = 1 AND addlayout = 1 THEN l$ = LEFT$(l$, LEN(l$) - 1) + sp
                        IF addlayout THEN l$ = l$ + tlayout$: addedlayout = 1

                        e$ = evaluate(e2$, sourcetyp)
                        IF Error_Happened THEN GOTO errmes

                        IF sourcetyp AND ISOFFSET THEN
                            IF (targettyp AND ISOFFSET) = 0 THEN
                                IF id2.internal_subfunc = 0 THEN a$ = "Cannot convert _OFFSET type to other types": GOTO errmes
                            END IF
                        END IF

                        IF RTRIM$(id2.callname) = "sub_paint" THEN
                            IF i = 3 THEN
                                IF (sourcetyp AND ISSTRING) THEN
                                    targettyp = ISSTRING
                                END IF
                            END IF
                        END IF

                        IF LEFT$(separgs2(i), 2) = "(" + sp THEN dereference = 1 ELSE dereference = 0

                        'pass by reference
                        IF (targettyp AND ISPOINTER) THEN
                            IF dereference = 0 THEN 'check deferencing wasn't used

                                'note: array pointer
                                IF (targettyp AND ISARRAY) THEN
                                    IF (sourcetyp AND ISREFERENCE) = 0 THEN a$ = "Expected arrayname()": GOTO errmes
                                    IF (sourcetyp AND ISARRAY) = 0 THEN a$ = "Expected arrayname()": GOTO errmes
                                    IF Debug THEN PRINT #9, "sub:array reference:[" + e$ + "]"

                                    'check arrays are of same type
                                    targettyp2 = targettyp: sourcetyp2 = sourcetyp
                                    targettyp2 = targettyp2 AND (511 + ISOFFSETINBITS + ISUDT + ISSTRING + ISFIXEDLENGTH + ISFLOAT)
                                    sourcetyp2 = sourcetyp2 AND (511 + ISOFFSETINBITS + ISUDT + ISSTRING + ISFIXEDLENGTH + ISFLOAT)
                                    IF sourcetyp2 <> targettyp2 THEN a$ = "Incorrect array type passed to sub": GOTO errmes

                                    'check arrayname was followed by '()'
                                    IF targettyp AND ISUDT THEN
                                        IF Debug THEN PRINT #9, "sub:array reference:udt reference:[" + e$ + "]"
                                        'get UDT info
                                        udtrefid = VAL(e$)
                                        getid udtrefid
                                        IF Error_Happened THEN GOTO errmes
                                        udtrefi = INSTR(e$, sp3) 'end of id
                                        udtrefi2 = INSTR(udtrefi + 1, e$, sp3) 'end of u
                                        udtrefu = VAL(MID$(e$, udtrefi + 1, udtrefi2 - udtrefi - 1))
                                        udtrefi3 = INSTR(udtrefi2 + 1, e$, sp3) 'skip e
                                        udtrefe = VAL(MID$(e$, udtrefi2 + 1, udtrefi3 - udtrefi2 - 1))
                                        o$ = RIGHT$(e$, LEN(e$) - udtrefi3)
                                        'note: most of the UDT info above is not required
                                        IF LEFT$(o$, 4) <> "(0)*" THEN a$ = "Expected arrayname()": GOTO errmes
                                    ELSE
                                        IF RIGHT$(e$, 2) <> sp3 + "0" THEN a$ = "Expected arrayname()": GOTO errmes
                                    END IF

                                    idnum = VAL(LEFT$(e$, INSTR(e$, sp3) - 1))
                                    getid idnum
                                    IF Error_Happened THEN GOTO errmes

                                    IF targettyp AND ISFIXEDLENGTH THEN
                                        targettypsize = CVL(MID$(id2.argsize, i * 4 - 4 + 1, 4))
                                        IF id.tsize <> targettypsize THEN a$ = "Incorrect array type passed to sub": GOTO errmes
                                    END IF

                                    IF MID$(sfcmemargs(targetid), i, 1) = CHR$(1) THEN 'cmem required?
                                        IF cmemlist(idnum) = 0 THEN
                                            cmemlist(idnum) = 1
                                            recompile = 1
                                        END IF
                                    END IF

                                    IF id.linkid = 0 THEN
                                        'if id.linkid is 0, it means the number of array elements is definietly
                                        'known of the array being passed, this is not some "fake"/unknown array.
                                        'using the numer of array elements of a fake array would be dangerous!


                                        IF nelereq = 0 THEN
                                            'only continue if the number of array elements required is unknown
                                            'and it needs to be set

                                            IF id.arrayelements > 0 THEN '2009

                                                nelereq = id.arrayelements
                                                MID$(id2.nelereq, i, 1) = CHR$(nelereq)

                                            END IF

                                            'print rtrim$(id2.n)+">nelereq=";nelereq

                                            ids(targetid) = id2

                                        ELSE

                                            'the number of array elements required is known AND
                                            'the number of elements in the array to be passed is known

                                            IF id.arrayelements <> nelereq THEN a$ = "Passing arrays with a differing number of elements to a SUB/FUNCTION is not supported (yet)": GOTO errmes


                                        END IF
                                    END IF

                                    e$ = refer(e$, sourcetyp, 1)
                                    IF Error_Happened THEN GOTO errmes
                                    GOTO sete

                                END IF 'target is an array

                                'note: not an array...
                                'target is not an array

                                IF (targettyp AND ISSTRING) = 0 THEN
                                    IF (sourcetyp AND ISREFERENCE) THEN
                                        idnum = VAL(LEFT$(e$, INSTR(e$, sp3) - 1)) 'id# of sourcetyp

                                        targettyp2 = targettyp: sourcetyp2 = sourcetyp

                                        'get info about source/target
                                        arr = 0: IF (sourcetyp2 AND ISARRAY) THEN arr = 1
                                        passudtelement = 0: IF (targettyp2 AND ISUDT) = 0 AND (sourcetyp2 AND ISUDT) <> 0 THEN passudtelement = 1: sourcetyp2 = sourcetyp2 - ISUDT

                                        'remove flags irrelevant for comparison... ISPOINTER,ISREFERENCE,ISINCONVENTIONALMEMORY,ISARRAY
                                        targettyp2 = targettyp2 AND (511 + ISOFFSETINBITS + ISUDT + ISFLOAT + ISSTRING)
                                        sourcetyp2 = sourcetyp2 AND (511 + ISOFFSETINBITS + ISUDT + ISFLOAT + ISSTRING)

                                        'compare types
                                        IF sourcetyp2 = targettyp2 THEN

                                            IF sourcetyp AND ISUDT THEN
                                                'udt/udt array

                                                'get info
                                                udtrefid = VAL(e$)
                                                getid udtrefid
                                                IF Error_Happened THEN GOTO errmes
                                                udtrefi = INSTR(e$, sp3) 'end of id
                                                udtrefi2 = INSTR(udtrefi + 1, e$, sp3) 'end of u
                                                udtrefu = VAL(MID$(e$, udtrefi + 1, udtrefi2 - udtrefi - 1))
                                                udtrefi3 = INSTR(udtrefi2 + 1, e$, sp3) 'skip e
                                                udtrefe = VAL(MID$(e$, udtrefi2 + 1, udtrefi3 - udtrefi2 - 1))
                                                o$ = RIGHT$(e$, LEN(e$) - udtrefi3)
                                                'note: most of the UDT info above is not required

                                                IF arr THEN
                                                    n$ = scope$ + "ARRAY_UDT_" + RTRIM$(id.n) + "[0]"
                                                ELSE
                                                    n$ = scope$ + "UDT_" + RTRIM$(id.n)
                                                END IF

                                                e$ = "(void*)( ((char*)(" + n$ + ")) + (" + o$ + ") )"

                                                'convert void* to target type*
                                                IF passudtelement THEN e$ = "(" + typ2ctyp$(targettyp2 + (targettyp AND ISUNSIGNED), "") + "*)" + e$
                                                IF Error_Happened THEN GOTO errmes

                                            ELSE
                                                'not a udt
                                                IF arr THEN
                                                    IF (sourcetyp2 AND ISOFFSETINBITS) THEN a$ = "Cannot pass BIT array offsets yet": GOTO errmes
                                                    e$ = "(&(" + refer(e$, sourcetyp, 0) + "))"
                                                    IF Error_Happened THEN GOTO errmes
                                                ELSE
                                                    e$ = refer(e$, sourcetyp, 1)
                                                    IF Error_Happened THEN GOTO errmes
                                                END IF

                                                'note: signed/unsigned mismatch requires casting
                                                IF (sourcetyp AND ISUNSIGNED) <> (targettyp AND ISUNSIGNED) THEN
                                                    e$ = "(" + typ2ctyp$(targettyp2 + (targettyp AND ISUNSIGNED), "") + "*)" + e$
                                                    IF Error_Happened THEN GOTO errmes
                                                END IF

                                            END IF 'udt?

                                            IF MID$(sfcmemargs(targetid), i, 1) = CHR$(1) THEN 'cmem required?
                                                IF cmemlist(idnum) = 0 THEN
                                                    cmemlist(idnum) = 1
                                                    recompile = 1
                                                END IF
                                            END IF

                                            GOTO sete
                                        END IF 'similar
                                    END IF 'reference
                                ELSE 'not a string
                                    'its a string
                                    IF (sourcetyp AND ISREFERENCE) THEN
                                        idnum = VAL(LEFT$(e$, INSTR(e$, sp3) - 1)) 'id# of sourcetyp
                                        IF MID$(sfcmemargs(targetid), i, 1) = CHR$(1) THEN 'cmem required?
                                            IF cmemlist(idnum) = 0 THEN
                                                cmemlist(idnum) = 1
                                                recompile = 1
                                            END IF
                                        END IF
                                    END IF 'reference
                                END IF 'its a string

                            END IF 'dereference check
                        END IF 'target is a pointer

                        'note: Target is not a pointer...

                        'String-numeric mismatch?
                        IF targettyp AND ISSTRING THEN
                            IF (sourcetyp AND ISSTRING) = 0 THEN
                                nth = i
                                IF ids(targetid).args = 1 THEN a$ = "String required for sub": GOTO errmes
                                a$ = str_nth$(nth) + " sub argument requires a string": GOTO errmes
                            END IF
                        END IF
                        IF (targettyp AND ISSTRING) = 0 THEN
                            IF sourcetyp AND ISSTRING THEN
                                nth = i
                                IF ids(targetid).args = 1 THEN a$ = "Number required for sub": GOTO errmes
                                a$ = str_nth$(nth) + " sub argument requires a number": GOTO errmes
                            END IF
                        END IF

                        'change to "non-pointer" value
                        IF (sourcetyp AND ISREFERENCE) THEN
                            e$ = refer(e$, sourcetyp, 0)
                            IF Error_Happened THEN GOTO errmes
                        END IF

                        IF explicitreference = 0 THEN
                            IF targettyp AND ISUDT THEN
                                nth = i
                                x$ = "'" + RTRIM$(udtxcname(targettyp AND 511)) + "'"
                                IF ids(targetid).args = 1 THEN a$ = "TYPE " + x$ + " required for sub": GOTO errmes
                                a$ = str_nth$(nth) + " sub argument requires TYPE " + x$: GOTO errmes
                            END IF
                        ELSE
                            IF sourcetyp AND ISUDT THEN a$ = "Number required for sub": GOTO errmes
                        END IF

                        'round to integer if required
                        IF (sourcetyp AND ISFLOAT) THEN
                            IF (targettyp AND ISFLOAT) = 0 THEN
                                '**32 rounding fix
                                bits = targettyp AND 511
                                IF bits <= 16 THEN e$ = "qbr_float_to_long(" + e$ + ")"
                                IF bits > 16 AND bits < 32 THEN e$ = "qbr_double_to_long(" + e$ + ")"
                                IF bits >= 32 THEN e$ = "qbr(" + e$ + ")"
                            END IF
                        END IF

                        IF (targettyp AND ISPOINTER) THEN 'pointer required
                            IF (targettyp AND ISSTRING) THEN GOTO sete 'no changes required
                            t$ = typ2ctyp$(targettyp, "")
                            IF Error_Happened THEN GOTO errmes
                            v$ = "pass" + str2$(uniquenumber)
                            'assume numeric type
                            IF MID$(sfcmemargs(targetid), i, 1) = CHR$(1) THEN 'cmem required?
                                bytesreq = ((targettyp AND 511) + 7) \ 8
                                PRINT #defdatahandle, t$ + " *" + v$ + "=NULL;"
                                PRINT #13, "if(" + v$ + "==NULL){"
                                PRINT #13, "cmem_sp-=" + str2(bytesreq) + ";"
                                PRINT #13, v$ + "=(" + t$ + "*)(dblock+cmem_sp);"
                                PRINT #13, "if (cmem_sp<qbs_cmem_sp) error(257);"
                                PRINT #13, "}"
                                e$ = "&(*" + v$ + "=" + e$ + ")"
                            ELSE
                                PRINT #13, t$ + " " + v$ + ";"
                                e$ = "&(" + v$ + "=" + e$ + ")"
                            END IF
                            GOTO sete
                        END IF

                    END IF 'not "NULL"

                    sete:

                    IF RTRIM$(id2.callname) = "sub_paint" THEN
                        IF i = 3 THEN
                            IF (sourcetyp AND ISSTRING) THEN
                                e$ = "(qbs*)" + e$
                            ELSE
                                e$ = "(uint32)" + e$
                            END IF
                        END IF
                    END IF

                    IF id2.ccall THEN

                        'if a forced cast from a returned ccall function is in e$, remove it
                        IF LEFT$(e$, 3) = "(  " THEN
                            e$ = removecast$(e$)
                        END IF

                        IF targettyp AND ISSTRING THEN
                            e$ = "(char*)(" + e$ + ")->chr"
                        END IF

                        IF LTRIM$(RTRIM$(e$)) = "0" THEN e$ = "NULL"

                    END IF

                    IF i <> 1 THEN subcall$ = subcall$ + ","
                    subcall$ = subcall$ + e$
                NEXT

                'note: i=id.args+1
                x$ = separgslayout2$(i)
                DO WHILE LEN(x$)
                    x = ASC(x$)
                    IF x THEN
                        x2$ = MID$(x$, 2, x)
                        x$ = RIGHT$(x$, LEN(x$) - x - 1)

                        s = 0
                        an = 0
                        x3$ = RIGHT$(l$, 1)
                        IF x3$ = sp THEN s = 1
                        IF x3$ = sp2 THEN
                            s = 2
                            IF alphanumeric(ASC(RIGHT$(l$, 2))) THEN an = 1
                            'if asc(right$(l$,2))=34 then an=1
                        ELSE
                            IF alphanumeric(ASC(x3$)) THEN an = 1
                            'if asc(x3$)=34 then an=1
                        END IF
                        s1 = s

                        IF (an = 1 OR addedlayout = 1) AND alphanumeric(ASC(x2$)) <> 0 THEN
                            s = 1 'force space
                            x2$ = x2$ + sp2
                            GOTO customlaychar2
                        END IF

                        IF x2$ = "=" THEN
                            s = 1
                            x2$ = x2$ + sp
                            GOTO customlaychar2
                        END IF

                        IF x2$ = "#" THEN
                            s = 1
                            x2$ = x2$ + sp2
                            GOTO customlaychar2
                        END IF

                        IF x2$ = "," THEN x2$ = x2$ + sp: GOTO customlaychar2

                        IF x$ = CHR$(0) THEN 'substitution
                            IF x2$ = "STEP" THEN x2$ = x2$ + sp2: GOTO customlaychar2
                            x2$ = x2$ + sp: GOTO customlaychar2
                        END IF

                        'default solution sp2+?+sp2
                        x2$ = x2$ + sp2
                        customlaychar2:
                        IF s = 0 THEN s = 2
                        IF s <> s1 THEN
                            IF s1 THEN l$ = LEFT$(l$, LEN(l$) - 1)
                            IF s = 1 THEN l$ = l$ + sp
                            IF s = 2 THEN l$ = l$ + sp2
                        END IF
                        l$ = l$ + x2$

                    ELSE
                        addlayout = 0
                        x$ = RIGHT$(x$, LEN(x$) - 1)
                    END IF
                    addedlayout = 0
                LOOP






                IF passedneeded THEN
                    subcall$ = subcall$ + "," + str2$(passed&)
                END IF
                subcall$ = subcall$ + ");"
                PRINT #12, subcall$
                subcall$ = ""
                IF stringprocessinghappened THEN PRINT #12, cleanupstringprocessingcall$ + "0);"

                layoutdone = 1
                x$ = RIGHT$(l$, 1): IF x$ = sp OR x$ = sp2 THEN l$ = LEFT$(l$, LEN(l$) - 1)
                IF usecall = 1 THEN l$ = l$ + sp2 + ")"
                IF Debug THEN PRINT #9, "SUB layout:[" + l$ + "]"
                IF LEN(layout$) = 0 THEN layout$ = l$ ELSE layout$ = layout$ + sp + l$
                GOTO finishedline


            END IF

            IF try = 2 THEN
                findidsecondarg = "": IF n >= 2 THEN findidsecondarg = getelement$(a$, 2)
                findanotherid = 1
                try = findid(firstelement$)
                IF Error_Happened THEN GOTO errmes
            ELSE
                try = 0
            END IF
        LOOP

    END IF

    notsubcall:

    IF n >= 1 THEN
        IF firstelement$ = "LET" THEN
            IF n = 1 THEN a$ = "Syntax error": GOTO errmes
            ca$ = RIGHT$(ca$, LEN(ca$) - 4)
            n = n - 1
            l$ = "LET"
            IF LEN(layout$) THEN layout$ = layout$ + sp + l$ ELSE layout$ = l$
            'note: layoutdone=1 will be set later
            GOTO letused
        END IF
    END IF

    'LET ???=???
    IF n >= 3 THEN
        IF INSTR(a$, sp + "=" + sp) THEN
            letused:
            assign ca$, n
            IF Error_Happened THEN GOTO errmes
            layoutdone = 1
            IF LEN(layout$) = 0 THEN layout$ = tlayout$ ELSE layout$ = layout$ + sp + tlayout$
            GOTO finishedline
        END IF
    END IF '>=3
    IF RIGHT$(a$, 2) = sp + "=" THEN a$ = "Expected ... = expression": GOTO errmes

    'Syntax error
    a$ = "Syntax error": GOTO errmes

    finishedline:
    THENGOTO = 0
    finishedline2:

    IF arrayprocessinghappened = 1 THEN arrayprocessinghappened = 0

    IF NoChecks = 0 THEN
        IF dynscope THEN
            dynscope = 0
            PRINT #12, "if(qbevent){evnt(" + str2$(linenumber) + ");if(r)goto S_" + str2$(statementn) + ";}"
        ELSE
            PRINT #12, "if(!qbevent)break;evnt(" + str2$(linenumber) + ");}while(r);"
        END IF
    END IF

    finishednonexec:

    IF layoutdone = 0 THEN layoutok = 0 'invalidate layout if not handled

    IF continuelinefrom = 0 THEN 'note: manager #2 requires this condition

        'Include Manager #2 '***
        IF LEN(addmetainclude$) THEN

            IF inclevel = 0 THEN
                'backup line formatting
                layoutcomment_backup$ = layoutcomment$
                layoutok_backup = layoutok
                layout_backup$ = layout$
            END IF

            a$ = addmetainclude$: addmetainclude$ = "" 'read/clear message
            IF inclevel = 100 THEN a$ = "Too many indwelling INCLUDE files": GOTO errmes
            '1. Verify file exists (location is either (a)relative to source file or (b)absolute)
            fh = 99 + inclevel + 1
            FOR try = 1 TO 2
                IF try = 1 THEN
                    IF inclevel = 0 THEN
                        IF idemode THEN p$ = idepath$ + pathsep$ ELSE p$ = getfilepath$(sourcefile$)
                    ELSE
                        p$ = getfilepath$(incname(inclevel))
                    END IF
                    f$ = p$ + a$
                END IF
                IF try = 2 THEN f$ = a$
                IF _FILEEXISTS(f$) THEN
                    qberrorhappened = -2 '***
                    OPEN f$ FOR BINARY AS #fh
                    qberrorhappened2: '***
                    IF qberrorhappened = -2 THEN EXIT FOR '***
                END IF
                qberrorhappened = 0
            NEXT
            IF qberrorhappened <> -2 THEN qberrorhappened = 0: a$ = "File " + a$ + " not found": GOTO errmes
            inclevel = inclevel + 1: incname$(inclevel) = f$: inclinenumber(inclevel) = 0
        END IF 'fall through to next section...
        '--------------------
        DO WHILE inclevel
            fh = 99 + inclevel
            '2. Feed next line
            IF EOF(fh) = 0 THEN
                LINE INPUT #fh, x$
                a3$ = x$
                continuelinefrom = 0
                inclinenumber(inclevel) = inclinenumber(inclevel) + 1
                'create extended error string 'incerror$'
                e$ = " in line " + str2(inclinenumber(inclevel)) + " of " + incname$(inclevel) + " included"
                IF inclevel > 1 THEN
                    e$ = e$ + " (through "
                    FOR x = 1 TO inclevel - 1 STEP 1
                        e$ = e$ + incname$(x)
                        IF x < inclevel - 1 THEN 'a sep is req
                            IF x = inclevel - 2 THEN
                                e$ = e$ + " then "
                            ELSE
                                e$ = e$ + ", "
                            END IF
                        END IF
                    NEXT
                    e$ = e$ + ")"
                END IF
                incerror$ = e$
                linenumber = linenumber - 1 'lower official linenumber to counter later increment
                IF idemode THEN sendc$ = CHR$(10) + a3$: GOTO sendcommand 'passback
                GOTO includeline
            END IF
            '3. Close & return control
            CLOSE #fh
            inclevel = inclevel - 1
            IF inclevel = 0 THEN
                'restore line formatting
                layoutok = layoutok_backup
                layout$ = layout_backup$
                layoutcomment$ = layoutcomment_backup$
            END IF
        LOOP 'fall through to next section...
        '(end manager)



    END IF 'continuelinefrom=0


    IF Debug THEN
        PRINT #9, "[layout check]"
        PRINT #9, "[" + layoutoriginal$ + "]"
        PRINT #9, "[" + layout$ + "]"
        PRINT #9, layoutok
        PRINT #9, "[end layout check]"
    END IF




    IF idemode THEN
        IF continuelinefrom <> 0 THEN GOTO ide4 'continue processing other commands on line

        IF LEN(layoutcomment$) THEN
            IF LEN(layout$) THEN layout$ = layout$ + sp + layoutcomment$ ELSE layout$ = layoutcomment$
        END IF

        IF layoutok = 0 THEN
            layout$ = layoutoriginal$
        ELSE

            'reverse '046' changes present in autolayout
            'replace fix046$ with .
            i = INSTR(layout$, fix046$)
            DO WHILE i
                layout$ = LEFT$(layout$, i - 1) + "." + RIGHT$(layout$, LEN(layout$) - (i + LEN(fix046$) - 1))
                i = INSTR(layout$, fix046$)
            LOOP

        END IF
        x = lhscontrollevel: IF controllevel < lhscontrollevel THEN x = controllevel
        IF definingtype = 2 THEN x = x + 1
        IF declaringlibrary = 2 THEN x = x + 1
        layout$ = SPACE$(x) + layout$
        IF linecontinuation THEN layout$ = ""

        GOTO ideret4 'return control to IDE
    END IF

    'layout is not currently used by the compiler (as appose to the IDE), if it was it would be used here

LOOP

ide5:
linenumber = 0

IF closedmain = 0 THEN closemain

IF definingtype THEN linenumber = definingtypeerror: a$ = "TYPE without END TYPE": GOTO errmes

'check for open controls (copy #1)
IF controllevel THEN
    x = controltype(controllevel)
    IF x = 1 THEN a$ = "IF without END IF"
    IF x = 2 THEN a$ = "FOR without NEXT"
    IF x = 3 OR x = 4 THEN a$ = "DO without LOOP"
    IF x = 5 THEN a$ = "WHILE without WEND"
    IF (x >= 10 AND x <= 17) OR x = 18 OR x = 19 THEN a$ = "SELECT CASE without END SELECT"
    linenumber = controlref(controllevel)
    GOTO errmes
END IF

IF LEN(subfunc) THEN a$ = "SUB/FUNCTION without END SUB/FUNCTION": GOTO errmes

'close the error handler (cannot be put in 'closemain' because subs/functions can also add error jumps to this file)
PRINT #14, "exit(99);" 'in theory this line should never be run!
PRINT #14, "}" 'close error jump handler

'create CLEAR method "CLEAR"
CLOSE #12 'close code handle
OPEN tmpdir$ + "clear.txt" FOR OUTPUT AS #12 'direct code to clear.txt

FOR i = 1 TO idn

    IF ids(i).staticscope THEN 'static scope?
        subfunc = RTRIM$(ids(i).insubfunc) 'set static scope
        GOTO clearstaticscope
    END IF

    a = ASC(ids(i).insubfunc)
    IF a = 0 OR a = 32 THEN 'global scope?
        subfunc = "" 'set global scope
        clearstaticscope:

        IF ids(i).arraytype THEN 'an array
            getid i
            IF Error_Happened THEN GOTO errmes
            IF id.arrayelements = -1 THEN GOTO clearerasereturned 'cannot erase non-existant array
            clearerasereturn = 1: GOTO clearerase
        END IF 'array

        IF ids(i).t THEN 'non-array variable
            getid i
            IF Error_Happened THEN GOTO errmes
            bytes$ = variablesize$(-1)
            IF Error_Happened THEN GOTO errmes
            'create a reference
            typ = id.t + ISREFERENCE
            IF typ AND ISUDT THEN
                e$ = str2(i) + sp3 + str2(typ AND 511) + sp3 + "0" + sp3 + "0"
            ELSE
                e$ = str2(i)
            END IF
            e$ = refer$(e$, typ, 1)
            IF Error_Happened THEN GOTO errmes
            IF typ AND ISSTRING THEN
                IF typ AND ISFIXEDLENGTH THEN
                    PRINT #12, "memset((void*)(" + e$ + "->chr),0," + bytes$ + ");"
                    GOTO cleared
                ELSE
                    PRINT #12, e$ + "->len=0;"
                    GOTO cleared
                END IF
            END IF
            IF typ AND ISUDT THEN
                PRINT #12, "memset((void*)" + e$ + ",0," + bytes$ + ");"
            ELSE
                PRINT #12, "*" + e$ + "=0;"
            END IF
            GOTO cleared
        END IF 'non-array variable

    END IF 'scope

    cleared:
    clearerasereturned:
NEXT
CLOSE #12

IF Debug THEN
    PRINT #9, "finished making program!"
    PRINT #9, "recompile="; recompile
END IF

'Set cmem flags for subs/functions requiring data passed in cmem
FOR i = 1 TO idn
    IF cmemlist(i) THEN 'must be in cmem

        getid i
        IF Error_Happened THEN GOTO errmes

        IF Debug THEN PRINT #9, "recompiling cmem sf! checking:"; RTRIM$(id.n)

        IF id.sfid THEN 'it is an argument of a sub/function

            IF Debug THEN PRINT #9, "recompiling cmem sf! It's a sub/func arg!"

            i2 = id.sfid
            x = id.sfarg

            IF Debug THEN PRINT #9, "recompiling cmem sf! values:"; i2; x

            'check if cmem flag is set, if not then set it & force recompile
            IF MID$(sfcmemargs(i2), x, 1) <> CHR$(1) THEN
                MID$(sfcmemargs(i2), x, 1) = CHR$(1)


                IF Debug THEN PRINT #9, "recompiling cmem sf! setting:"; i2; x


                recompile = 1
            END IF
        END IF
    END IF
NEXT i

unresolved = 0
FOR i = 1 TO idn
    getid i
    IF Error_Happened THEN GOTO errmes

    IF Debug THEN PRINT #9, "checking id named:"; id.n

    IF id.subfunc THEN
        FOR i2 = 1 TO id.args
            t = CVL(MID$(id.arg, i2 * 4 - 3, 4))
            IF t > 0 THEN
                IF (t AND ISPOINTER) THEN
                    IF (t AND ISARRAY) THEN

                        IF Debug THEN PRINT #9, "checking argument "; i2; " of "; id.args

                        nele = ASC(MID$(id.nele, i2, 1))
                        nelereq = ASC(MID$(id.nelereq, i2, 1))

                        IF Debug THEN PRINT #9, "nele="; nele
                        IF Debug THEN PRINT #9, "nelereq="; nelereq

                        IF nele <> nelereq THEN

                            IF Debug THEN PRINT #9, "mismatch detected!"

                            unresolved = unresolved + 1
                            sflistn = sflistn + 1
                            sfidlist(sflistn) = i
                            sfarglist(sflistn) = i2
                            sfelelist(sflistn) = nelereq '0 means still unknown
                        END IF
                    END IF
                END IF
            END IF
        NEXT
    END IF
NEXT

'is recompilation required to resolve this?
IF unresolved > 0 THEN
    IF lastunresolved = -1 THEN
        'first pass
        recompile = 1
        IF Debug THEN
            PRINT #9, "recompiling to resolve array elements (first time)"
            PRINT #9, "sflistn="; sflistn
            PRINT #9, "oldsflistn="; oldsflistn
        END IF
    ELSE
        'not first pass
        IF unresolved < lastunresolved THEN
            recompile = 1
            IF Debug THEN
                PRINT #9, "recompiling to resolve array elements (not first time)"
                PRINT #9, "sflistn="; sflistn
                PRINT #9, "oldsflistn="; oldsflistn
            END IF
        END IF
    END IF
END IF 'unresolved
lastunresolved = unresolved

'IDEA!
'have a flag to record if anything gets resolved in a pass
'if not then it's time to stop
'the problem is the same amount of new problems may be created by a
'resolve as those that get fixed
'also/or.. could it be that previous fixes are overridden in a recompile
'          by a new fix? if so, it would give these effects



'could recompilation resolve this?
'IF sflistn <> -1 THEN
'IF sflistn <> oldsflistn THEN
'recompile = 1
'
'if debug then
'print #9,"recompile set to 1 to resolve array elements"
'print #9,"sflistn=";sflistn
'print #9,"oldsflistn=";oldsflistn
'end if
'
'END IF
'END IF

IF Debug THEN PRINT #9, "Beginning COMMON array list check..."
xi = 1
FOR x = 1 TO commonarraylistn
    varname$ = getelement$(commonarraylist, xi): xi = xi + 1
    typ$ = getelement$(commonarraylist, xi): xi = xi + 1
    dimmethod2 = VAL(getelement$(commonarraylist, xi)): xi = xi + 1
    dimshared2 = VAL(getelement$(commonarraylist, xi)): xi = xi + 1
    'find the array ID (try method)
    t = typname2typ(typ$)
    IF Error_Happened THEN GOTO errmes
    IF (t AND ISUDT) = 0 THEN varname$ = varname$ + type2symbol$(typ$)
    IF Error_Happened THEN GOTO errmes

    IF Debug THEN PRINT #9, "Checking for array '" + varname$ + "'..."

    try = findid(varname$)
    IF Error_Happened THEN GOTO errmes
    DO WHILE try
        IF id.arraytype THEN GOTO foundcommonarray2
        IF try = 2 THEN findanotherid = 1: try = findid(varname$) ELSE try = 0
        IF Error_Happened THEN GOTO errmes
    LOOP
    foundcommonarray2:

    IF Debug THEN PRINT #9, "Found array '" + varname$ + "!"

    IF id.arrayelements = -1 THEN
        IF arrayelementslist(currentid) <> 0 THEN recompile = 1
        IF Debug THEN PRINT #9, "Recompiling to resolve elements of:" + varname$
    END IF
NEXT
IF Debug THEN PRINT #9, "Finished COMMON array list check!"

IF recompile THEN
    do_recompile:
    IF Debug THEN PRINT #9, "Recompile required!"
    recompile = 0
    IF idemode THEN iderecompile = 1
    FOR closeall = 1 TO 255: CLOSE closeall: NEXT
    OPEN tmpdir$ + "temp.bin" FOR OUTPUT LOCK WRITE AS #26 'relock
    GOTO recompile
END IF

IF Debug THEN PRINT #9, "Beginning label check..."
FOR r = 1 TO nLabels

    IF Labels(r).Scope_Restriction THEN
        a$ = RTRIM$(Labels(r).cn)
        ignore = validlabel(a$)
        v = HashFind(a$, HASHFLAG_LABEL, ignore, r2)
        addlabchk7:
        IF v THEN
            IF Labels(r2).Scope = Labels(r).Scope_Restriction THEN
                linenumber = Labels(r).Error_Line: a$ = "Common label within a SUB/FUNCTION": GOTO errmes
            END IF
            IF v = 2 THEN v = HashFindCont(ignore, r2): GOTO addlabchk7
        END IF 'v
    END IF 'restriction

    'check for undefined labels
    IF Labels(r).State = 0 THEN

        IF INSTR(PossibleSubNameLabels$, sp + UCASE$(RTRIM$(Labels(r).cn)) + sp) THEN
            IF INSTR(SubNameLabels$, sp + UCASE$(RTRIM$(Labels(r).cn)) + sp) = 0 THEN 'not already added
                SubNameLabels$ = SubNameLabels$ + UCASE$(RTRIM$(Labels(r).cn)) + sp
                IF Debug THEN PRINT #9, "Recompiling to resolve label:"; RTRIM$(Labels(r).cn)
                GOTO do_recompile
            END IF
        END IF

        linenumber = Labels(r).Error_Line: a$ = "Label not defined": GOTO errmes
    END IF


    IF Labels(r).Data_Referenced THEN

        'check for ambiguous RESTORE reference
        x = 0
        a$ = RTRIM$(Labels(r).cn)
        ignore = validlabel(a$)
        v = HashFind(a$, HASHFLAG_LABEL, ignore, r2)
        addlabchk4:
        IF v THEN
            x = x + 1
            IF v = 2 THEN v = HashFindCont(ignore, r2): GOTO addlabchk4
        END IF 'v
        IF x <> 1 THEN linenumber = Labels(r).Error_Line: a$ = "Ambiguous DATA label": GOTO errmes

        'add global data offset variable
        PRINT #18, "ptrszint data_at_LABEL_" + a$ + "=" + str2(Labels(r).Data_Offset) + ";"

    END IF 'data referenced

NEXT
IF Debug THEN PRINT #9, "Finished check!"


'if targettyp=-4 or targettyp=-5 then '? -> byte_element(offset,element size in bytes)
' IF (sourcetyp AND ISREFERENCE) = 0 THEN a$ = "Expected variable name/array element": GOTO errmes


'create include files for COMMON arrays

CLOSE #12

'return to 'main'
subfunc$ = ""
defdatahandle = 18
CLOSE #13: OPEN tmpdir$ + "maindata.txt" FOR APPEND AS #13
CLOSE #19: OPEN tmpdir$ + "mainfree.txt" FOR APPEND AS #19

IF Console THEN
    PRINT #18, "int32 console=1;"
ELSE
    PRINT #18, "int32 console=0;"
END IF

IF ScreenHide THEN
    PRINT #18, "int32 screen_hide_startup=1;"
ELSE
    PRINT #18, "int32 screen_hide_startup=0;"
END IF

fh = FREEFILE
OPEN tmpdir$ + "dyninfo.txt" FOR APPEND AS #fh
IF Resize THEN
    PRINT #fh, "ScreenResize=1;"
END IF
IF Resize_Scale THEN
    PRINT #fh, "ScreenResizeScale=" + str2(Resize_Scale) + ";"
END IF
CLOSE #fh

'DATA_finalize
PRINT #18, "ptrszint data_size=" + str2(DataOffset) + ";"
IF DataOffset = 0 THEN

    PRINT #18, "uint8 *data=(uint8*)calloc(1,1);"

ELSE

    IF inline_DATA = 0 THEN
        IF os$ = "WIN" THEN
            IF OS_BITS = 32 THEN
                x$ = CHR$(0): PUT #16, , x$
                PRINT #18, "extern " + CHR$(34) + "C" + CHR$(34) + "{"
                PRINT #18, "extern char *binary_____temp" + tempfolderindexstr2$ + "__data_bin_start;"
                PRINT #18, "}"
                PRINT #18, "uint8 *data=(uint8*)&binary_____temp" + tempfolderindexstr2$ + "__data_bin_start;"
            ELSE
                x$ = CHR$(0): PUT #16, , x$
                PRINT #18, "extern " + CHR$(34) + "C" + CHR$(34) + "{"
                PRINT #18, "extern char *_binary_____temp" + tempfolderindexstr2$ + "__data_bin_start;"
                PRINT #18, "}"
                PRINT #18, "uint8 *data=(uint8*)&_binary_____temp" + tempfolderindexstr2$ + "__data_bin_start;"
            END IF
        END IF
        IF os$ = "LNX" THEN
            x$ = CHR$(0): PUT #16, , x$
            PRINT #18, "extern " + CHR$(34) + "C" + CHR$(34) + "{"
            PRINT #18, "extern char *_binary____temp" + tempfolderindexstr2$ + "_data_bin_start;"
            PRINT #18, "}"
            PRINT #18, "uint8 *data=(uint8*)&_binary____temp" + tempfolderindexstr2$ + "_data_bin_start;"
        END IF
    ELSE
        'inline data
        CLOSE #16
        ff = FREEFILE
        OPEN tmpdir$ + "data.bin" FOR BINARY AS #ff
        x$ = SPACE$(LOF(ff))
        GET #ff, , x$
        CLOSE #ff
        x2$ = "uint8 inline_data[]={"
        FOR i = 1 TO LEN(x$)
            x2$ = x2$ + inlinedatastr$(ASC(x$, i))
        NEXT
        x2$ = x2$ + "0};"
        PRINT #18, x2$
        PRINT #18, "uint8 *data=&inline_data[0];"
        x$ = "": x2$ = ""
    END IF
END IF

IF Debug THEN PRINT #9, "Beginning generation of code for saving/sharing common array data..."
use_global_byte_elements = 1
ncommontmp = 0
xi = 1
FOR x = 1 TO commonarraylistn
    varname$ = getelement$(commonarraylist, xi): xi = xi + 1
    typ$ = getelement$(commonarraylist, xi): xi = xi + 1
    dimmethod2 = VAL(getelement$(commonarraylist, xi)): xi = xi + 1
    dimshared2 = VAL(getelement$(commonarraylist, xi)): xi = xi + 1

    'find the array ID (try method)
    purevarname$ = varname$
    t = typname2typ(typ$)
    IF Error_Happened THEN GOTO errmes
    IF (t AND ISUDT) = 0 THEN varname$ = varname$ + type2symbol$(typ$)
    IF Error_Happened THEN GOTO errmes
    try = findid(varname$)
    IF Error_Happened THEN GOTO errmes
    DO WHILE try
        IF id.arraytype THEN GOTO foundcommonarray
        IF try = 2 THEN findanotherid = 1: try = findid(varname$) ELSE try = 0
        IF Error_Happened THEN GOTO errmes
    LOOP
    a$ = "COMMON array unlocatable": GOTO errmes 'should never happen
    foundcommonarray:
    IF Debug THEN PRINT #9, "Found common array '" + varname$ + "'!"

    i = currentid
    arraytype = id.arraytype
    arrayelements = id.arrayelements
    e$ = RTRIM$(id.n)
    IF (t AND ISUDT) = 0 THEN e$ = e$ + typevalue2symbol$(t)
    IF Error_Happened THEN GOTO errmes
    n$ = e$
    n2$ = RTRIM$(id.callname)
    tsize = id.tsize

    'select command
    command = 3 'fixed length elements
    IF t AND ISSTRING THEN
        IF (t AND ISFIXEDLENGTH) = 0 THEN
            command = 4 'var-len elements
        END IF
    END IF


    'if...
    'i) array elements are still undefined (ie. arrayelements=-1) pass the input content along
    '   if any existed or an array-placeholder
    'ii) if the array's elements were defined, any input content would have been loaded so the
    '    array (in whatever state it currently is) should be passed. If it is currently erased
    '    then it should be passed as a placeholder

    IF arrayelements = -1 THEN

        'load array (copies the array, if any, into a buffer for later)



        OPEN tmpdir$ + "inpchain" + str2$(i) + ".txt" FOR OUTPUT AS #12
        PRINT #12, "if (int32val==2){" 'array place-holder
        'create buffer to store array as-is in global.txt
        x$ = str2$(uniquenumber)
        x1$ = "chainarraybuf" + x$
        x2$ = "chainarraybufsiz" + x$
        PRINT #18, "static uint8 *" + x1$ + "=(uint8*)malloc(1);"
        PRINT #18, "static int64 " + x2$ + "=0;"
        'read next command
        PRINT #12, "sub_get(FF,NULL,byte_element((uint64)&int32val,4," + NewByteElement$ + "),0);"

        IF command = 3 THEN PRINT #12, "if (int32val==3){" 'fixed-length-element array
        IF command = 4 THEN PRINT #12, "if (int32val==4){" 'var-length-element array
        PRINT #12, x2$ + "+=4; " + x1$ + "=(uint8*)realloc(" + x1$ + "," + x2$ + "); *(int32*)(" + x1$ + "+" + x2$ + "-4)=int32val;"

        IF command = 3 THEN
            'read size in bits of one element, convert it to bytes
            PRINT #12, "sub_get(FF,NULL,byte_element((uint64)&int64val,8," + NewByteElement$ + "),0);"
            PRINT #12, x2$ + "+=8; " + x1$ + "=(uint8*)realloc(" + x1$ + "," + x2$ + "); *(int64*)(" + x1$ + "+" + x2$ + "-8)=int64val;"
            PRINT #12, "bytes=int64val>>3;"
        END IF 'com=3

        IF command = 4 THEN PRINT #12, "bytes=1;" 'bytes used to calculate number of elements

        'read number of dimensions
        PRINT #12, "sub_get(FF,NULL,byte_element((uint64)&int32val,4," + NewByteElement$ + "),0);"
        PRINT #12, x2$ + "+=4; " + x1$ + "=(uint8*)realloc(" + x1$ + "," + x2$ + "); *(int32*)(" + x1$ + "+" + x2$ + "-4)=int32val;"

        'read size of dimensions & calculate the size of the array in bytes
        PRINT #12, "while(int32val--){"
        PRINT #12, "sub_get(FF,NULL,byte_element((uint64)&int64val,8," + NewByteElement$ + "),0);" 'lbound
        PRINT #12, x2$ + "+=8; " + x1$ + "=(uint8*)realloc(" + x1$ + "," + x2$ + "); *(int64*)(" + x1$ + "+" + x2$ + "-8)=int64val;"
        PRINT #12, "sub_get(FF,NULL,byte_element((uint64)&int64val2,8," + NewByteElement$ + "),0);" 'ubound
        PRINT #12, x2$ + "+=8; " + x1$ + "=(uint8*)realloc(" + x1$ + "," + x2$ + "); *(int64*)(" + x1$ + "+" + x2$ + "-8)=int64val2;"
        PRINT #12, "bytes*=(int64val2-int64val+1);"
        PRINT #12, "}"

        IF command = 3 THEN
            'read the array data
            PRINT #12, x2$ + "+=bytes; " + x1$ + "=(uint8*)realloc(" + x1$ + "," + x2$ + ");"
            PRINT #12, "sub_get(FF,NULL,byte_element((uint64)(" + x1$ + "+" + x2$ + "-bytes),bytes," + NewByteElement$ + "),0);"
        END IF 'com=3

        IF command = 4 THEN
            PRINT #12, "bytei=0;"
            PRINT #12, "while(bytei<bytes){"
            PRINT #12, "sub_get(FF,NULL,byte_element((uint64)&int64val,8," + NewByteElement$ + "),0);" 'get size
            PRINT #12, x2$ + "+=8; " + x1$ + "=(uint8*)realloc(" + x1$ + "," + x2$ + "); *(int64*)(" + x1$ + "+" + x2$ + "-8)=int64val;"
            PRINT #12, x2$ + "+=(int64val>>3); " + x1$ + "=(uint8*)realloc(" + x1$ + "," + x2$ + ");"
            PRINT #12, "sub_get(FF,NULL,byte_element((uint64)(" + x1$ + "+" + x2$ + "-(int64val>>3)),(int64val>>3)," + NewByteElement$ + "),0);"
            PRINT #12, "bytei++;"
            PRINT #12, "}"
        END IF

        'get next command
        PRINT #12, "sub_get(FF,NULL,byte_element((uint64)&int32val,4," + NewByteElement$ + "),0);"
        PRINT #12, "}" 'command=3 or 4

        PRINT #12, "}" 'array place-holder
        CLOSE #12


        'save array (saves the buffered data, if any, for later)

        OPEN tmpdir$ + "chain" + str2$(i) + ".txt" FOR OUTPUT AS #12
        PRINT #12, "int32val=2;" 'placeholder
        PRINT #12, "sub_put(FF,NULL,byte_element((uint64)&int32val,4," + NewByteElement$ + "),0);"

        PRINT #12, "sub_put(FF,NULL,byte_element((uint64)" + x1$ + "," + x2$ + "," + NewByteElement$ + "),0);"
        CLOSE #12




    ELSE
        'note: arrayelements<>-1

        'load array

        OPEN tmpdir$ + "inpchain" + str2$(i) + ".txt" FOR OUTPUT AS #12

        PRINT #12, "if (int32val==2){" 'array place-holder
        PRINT #12, "sub_get(FF,NULL,byte_element((uint64)&int32val,4," + NewByteElement$ + "),0);"

        IF command = 3 THEN PRINT #12, "if (int32val==3){" 'fixed-length-element array
        IF command = 4 THEN PRINT #12, "if (int32val==4){" 'var-length-element array

        IF command = 3 THEN
            'get size in bits
            PRINT #12, "sub_get(FF,NULL,byte_element((uint64)&int64val,8," + NewByteElement$ + "),0);"
            '***assume correct***
        END IF

        'get number of elements
        PRINT #12, "sub_get(FF,NULL,byte_element((uint64)&int32val,4," + NewByteElement$ + "),0);"
        '***assume correct***

        e$ = ""
        IF command = 4 THEN PRINT #12, "bytes=1;" 'bytes counts the number of total elements
        FOR x2 = 1 TO arrayelements

            'create 'secret' variables to assist in passing common arrays
            IF x2 > ncommontmp THEN
                ncommontmp = ncommontmp + 1

                IF Debug THEN PRINT #9, "Calling DIM2(...)..."
                IF Error_Happened THEN GOTO errmes
                retval = dim2("___RESERVED_COMMON_LBOUND" + str2$(ncommontmp), "_INTEGER64", 0, "")
                IF Error_Happened THEN GOTO errmes
                retval = dim2("___RESERVED_COMMON_UBOUND" + str2$(ncommontmp), "_INTEGER64", 0, "")
                IF Error_Happened THEN GOTO errmes
                IF Debug THEN PRINT #9, "Finished calling DIM2(...)!"
                IF Error_Happened THEN GOTO errmes


            END IF

            PRINT #12, "sub_get(FF,NULL,byte_element((uint64)&int64val,8," + NewByteElement$ + "),0);"
            PRINT #12, "*__INTEGER64____RESERVED_COMMON_LBOUND" + str2$(x2) + "=int64val;"
            PRINT #12, "sub_get(FF,NULL,byte_element((uint64)&int64val2,8," + NewByteElement$ + "),0);"
            PRINT #12, "*__INTEGER64____RESERVED_COMMON_UBOUND" + str2$(x2) + "=int64val2;"
            IF command = 4 THEN PRINT #12, "bytes*=(int64val2-int64val+1);"
            IF x2 > 1 THEN e$ = e$ + sp + "," + sp
            e$ = e$ + "___RESERVED_COMMON_LBOUND" + str2$(x2) + sp + "TO" + sp + "___RESERVED_COMMON_UBOUND" + str2$(x2)
        NEXT

        IF Debug THEN PRINT #9, "Calling DIM2(" + purevarname$ + "," + typ$ + ",0," + e$ + ")..."
        IF Error_Happened THEN GOTO errmes
        'Note: purevarname$ is simply varname$ without the type symbol after it
        redimoption = 1
        retval = dim2(purevarname$, typ$, 0, e$)
        IF Error_Happened THEN GOTO errmes
        redimoption = 0
        IF Debug THEN PRINT #9, "Finished calling DIM2(" + purevarname$ + "," + typ$ + ",0," + e$ + ")!"
        IF Error_Happened THEN GOTO errmes

        IF command = 3 THEN
            'use get to load in the array data
            varname$ = varname$ + sp + "(" + sp + ")"
            e$ = evaluatetotyp(fixoperationorder$(varname$), -4)
            IF Error_Happened THEN GOTO errmes
            PRINT #12, "sub_get(FF,NULL," + e$ + ",0);"
        END IF

        IF command = 4 THEN
            PRINT #12, "bytei=0;"
            PRINT #12, "while(bytei<bytes){"
            PRINT #12, "sub_get(FF,NULL,byte_element((uint64)&int64val,8," + NewByteElement$ + "),0);" 'get size
            PRINT #12, "tqbs=((qbs*)(((uint64*)(" + n2$ + "[0]))[bytei]));" 'get element
            PRINT #12, "qbs_set(tqbs,qbs_new(int64val>>3,1));" 'change string size
            PRINT #12, "sub_get(FF,NULL,byte_element((uint64)tqbs->chr,int64val>>3," + NewByteElement$ + "),0);" 'get size
            PRINT #12, "bytei++;"
            PRINT #12, "}"
        END IF

        'get next command
        PRINT #12, "sub_get(FF,NULL,byte_element((uint64)&int32val,4," + NewByteElement$ + "),0);"
        PRINT #12, "}"
        PRINT #12, "}"
        CLOSE #12

        'save array

        OPEN tmpdir$ + "chain" + str2$(i) + ".txt" FOR OUTPUT AS #12

        PRINT #12, "int32val=2;" 'placeholder
        PRINT #12, "sub_put(FF,NULL,byte_element((uint64)&int32val,4," + NewByteElement$ + "),0);"

        PRINT #12, "if (" + n2$ + "[2]&1){" 'don't add unless defined

        IF command = 3 THEN PRINT #12, "int32val=3;"
        IF command = 4 THEN PRINT #12, "int32val=4;"
        PRINT #12, "sub_put(FF,NULL,byte_element((uint64)&int32val,4," + NewByteElement$ + "),0);"

        IF command = 3 THEN
            'size of each element in bits
            bits = t AND 511
            IF t AND ISUDT THEN bits = udtxsize(t AND 511)
            IF t AND ISSTRING THEN bits = tsize * 8
            PRINT #12, "int64val=" + str2$(bits) + ";" 'size in bits
            PRINT #12, "sub_put(FF,NULL,byte_element((uint64)&int64val,8," + NewByteElement$ + "),0);"
        END IF 'com=3

        PRINT #12, "int32val=" + str2$(arrayelements) + ";" 'number of dimensions
        PRINT #12, "sub_put(FF,NULL,byte_element((uint64)&int32val,4," + NewByteElement$ + "),0);"

        IF command = 3 THEN

            FOR x2 = 1 TO arrayelements
                'simulate calls to lbound/ubound
                e$ = "LBOUND" + sp + "(" + sp + n$ + sp + "," + sp + str2$(x2) + sp + ")"
                e$ = evaluatetotyp(fixoperationorder$(e$), 64)
                IF Error_Happened THEN GOTO errmes
                PRINT #12, "int64val=" + e$ + ";"
                PRINT #12, "sub_put(FF,NULL,byte_element((uint64)&int64val,8," + NewByteElement$ + "),0);"
                e$ = "UBOUND" + sp + "(" + sp + n$ + sp + "," + sp + str2$(x2) + sp + ")"
                e$ = evaluatetotyp(fixoperationorder$(e$), 64)
                IF Error_Happened THEN GOTO errmes
                PRINT #12, "int64val=" + e$ + ";"
                PRINT #12, "sub_put(FF,NULL,byte_element((uint64)&int64val,8," + NewByteElement$ + "),0);"
            NEXT

            'array data
            e$ = evaluatetotyp(fixoperationorder$(n$ + sp + "(" + sp + ")"), -4)
            IF Error_Happened THEN GOTO errmes
            PRINT #12, "sub_put(FF,NULL," + e$ + ",0);"

        END IF 'com=3

        IF command = 4 THEN

            'store LBOUND/UBOUND values and calculate number of total elements/strings
            PRINT #12, "bytes=1;" 'note: bytes is actually the total number of elements
            FOR x2 = 1 TO arrayelements
                e$ = "LBOUND" + sp + "(" + sp + n$ + sp + "," + sp + str2$(x2) + sp + ")"
                e$ = evaluatetotyp(fixoperationorder$(e$), 64)
                IF Error_Happened THEN GOTO errmes
                PRINT #12, "int64val=" + e$ + ";"
                PRINT #12, "sub_put(FF,NULL,byte_element((uint64)&int64val,8," + NewByteElement$ + "),0);"
                e$ = "UBOUND" + sp + "(" + sp + n$ + sp + "," + sp + str2$(x2) + sp + ")"
                e$ = evaluatetotyp(fixoperationorder$(e$), 64)
                IF Error_Happened THEN GOTO errmes
                PRINT #12, "int64val2=" + e$ + ";"
                PRINT #12, "sub_put(FF,NULL,byte_element((uint64)&int64val2,8," + NewByteElement$ + "),0);"
                PRINT #12, "bytes*=(int64val2-int64val+1);"
            NEXT

            PRINT #12, "bytei=0;"
            PRINT #12, "while(bytei<bytes){"
            PRINT #12, "tqbs=((qbs*)(((uint64*)(" + n2$ + "[0]))[bytei]));" 'get element
            PRINT #12, "int64val=tqbs->len; int64val<<=3;"
            PRINT #12, "sub_put(FF,NULL,byte_element((uint64)&int64val,8," + NewByteElement$ + "),0);" 'size of element
            PRINT #12, "sub_put(FF,NULL,byte_element((uint64)tqbs->chr,tqbs->len," + NewByteElement$ + "),0);" 'element data
            PRINT #12, "bytei++;"
            PRINT #12, "}"

        END IF 'com=4

        PRINT #12, "}" 'don't add unless defined

        CLOSE #12




        'if chaincommonarray then
        'l2$=tlayout$
        'x=chaincommonarray
        '
        ''chain???.txt
        'open tmpdir$ + "chain" + str2$(x) + ".txt" for append as #22
        'if lof(22) then close #22: goto chaindone 'only add this once
        ''***assume non-var-len-string array***
        'print #22,"int32val=3;" 'non-var-len-element array
        'print #22,"sub_put(FF,NULL,byte_element((uint64)&int32val,4,"+NewByteElement$+"),0);"
        't=id.arraytype
        ''***check for UDT size if necessary***
        ''***check for string length if necessary***
        'bits=t and 511
        'print #22,"int64val="+str2$(bits)+";" 'size in bits
        'print #22,"sub_put(FF,NULL,byte_element((uint64)&int64val,8,"+NewByteElement$+"),0);"
        'print #22,"int32val="+str2$(id.arrayelements)+";" 'number of elements
        'print #22,"sub_put(FF,NULL,byte_element((uint64)&int32val,4,"+NewByteElement$+"),0);"
        'e$=rtrim$(id.n)
        'if (t and ISUDT)=0 then e$=e$+typevalue2symbol$(t)
        'n$=e$
        'for x2=1 to id.arrayelements
        ''simulate calls to lbound/ubound
        'e$="LBOUND"+sp+"("+sp+n$+sp+","+sp+str2$(x2)+sp+")"
        'e$=evaluatetotyp(fixoperationorder$(e$),64)
        'print #22,"int64val="+e$+";"'LBOUND
        'print #22,"sub_put(FF,NULL,byte_element((uint64)&int64val,8,"+NewByteElement$+"),0);"
        'e$="UBOUND"+sp+"("+sp+n$+sp+","+sp+str2$(x2)+sp+")"
        'e$=evaluatetotyp(fixoperationorder$(e$),64)
        'print #22,"int64val="+e$+";"'LBOUND
        'print #22,"sub_put(FF,NULL,byte_element((uint64)&int64val,8,"+NewByteElement$+"),0);"
        'next
        ''add array data
        'e$=evaluatetotyp(fixoperationorder$(n$+sp+"("+sp+")"),-4)
        'print #22,"sub_put(FF,NULL,"+e$+",0);"
        'close #22
        '
        ''inpchain???.txt
        'open tmpdir$ + "chain" + str2$(x) + ".txt" for append as #22
        'print #22,"if (int32val==1){" 'common declaration of an array
        'print #22,"sub_get(FF,NULL,byte_element((uint64)&int32val,4,"+NewByteElement$+"),0);"
        'print #22,"if (int32val==3){" 'fixed-length-element array
        '
        'print #22,"sub_get(FF,NULL,byte_element((uint64)&int64val,8,"+NewByteElement$+"),0);"
        ''***assume size correct and continue***
        '
        ''get number of elements
        'print #22,"sub_get(FF,NULL,byte_element((uint64)&int32val,4,"+NewByteElement$+"),0);"
        '
        ''call dim2 and tell it to redim an array
        '
        ''*********this should happen BEFORE the array (above) is actually dimensioned,
        ''*********where the common() declaration is
        '
        ''****although, if you never reference the array.............
        ''****ARGH! you can access an undimmed array just like in a sub/function
        '
        '
        '
        '
        'print #22,"}"
        'print #22,"}"
        'close #22
        '
        'chaindone:
        'tlayout$=l2$
        'end if 'chaincommonarray




        'OPEN tmpdir$ + "chain.txt" FOR APPEND AS #22
        ''include directive
        'print #22, "#include " + CHR$(34) + "chain" + str2$(x) + ".txt" + CHR$(34)
        'close #22
        ''create/clear include file
        'open tmpdir$ + "chain" + str2$(x) + ".txt" for output as #22:close #22
        '
        'OPEN tmpdir$ + "inpchain.txt" FOR APPEND AS #22
        ''include directive
        'print #22, "#include " + CHR$(34) + "inpchain" + str2$(x) + ".txt" + CHR$(34)
        'close #22
        ''create/clear include file
        'open tmpdir$ + "inpchain" + str2$(x) + ".txt" for output as #22:close #22






    END IF 'id.arrayelements=-1

NEXT
use_global_byte_elements = 0
IF Debug THEN PRINT #9, "Finished generation of code for saving/sharing common array data!"


FOR closeall = 1 TO 255: CLOSE closeall: NEXT
OPEN tmpdir$ + "temp.bin" FOR OUTPUT LOCK WRITE AS #26 'relock








IF idemode THEN GOTO ideret5
ide6:



IF idemode = 0 AND No_C_Compile_Mode = 0 THEN
    PRINT
    IF os$ = "LNX" THEN
        PRINT "COMPILING C++ CODE INTO EXECUTABLE..."
    ELSE
        PRINT "COMPILING C++ CODE INTO EXE..."
    END IF
    IF _FILEEXISTS(file$ + extension$) THEN
        E = 0
        ON ERROR GOTO qberror_test
        KILL file$ + extension$
        ON ERROR GOTO qberror
        IF E = 1 THEN
            a$ = "CANNOT CREATE " + CHR$(34) + file$ + extension$ + CHR$(34) + " BECAUSE THE FILE IS ALREADY IN USE!": GOTO errmes
        END IF
    END IF
END IF


'Update dependencies

o$ = LCASE$(os$)
win = 0: IF os$ = "WIN" THEN win = 1
lnx = 0: IF os$ = "LNX" THEN lnx = 1
mac = 0: IF MacOSX THEN mac = 1: o$ = "osx"
defines$ = "": defines_header$ = " -D "
ver$ = Version$ 'eg. "0.123"
x = INSTR(ver$, "."): IF x THEN ASC(ver$, x) = 95 'change "." to "_"
libs$ = ""

IF DEPENDENCY(DEPENDENCY_GL) THEN
    IF Cloud THEN a$ = "GL not supported on QLOUD": GOTO errmes '***NOCLOUD***
    defines$ = defines$ + defines_header$ + "DEPENDENCY_GL"
END IF

IF DEPENDENCY(DEPENDENCY_SCREENIMAGE) THEN
    DEPENDENCY(DEPENDENCY_IMAGE_CODEC) = 1 'used by OSX to read in screen capture files
END IF

IF DEPENDENCY(DEPENDENCY_IMAGE_CODEC) THEN
    defines$ = defines$ + defines_header$ + "DEPENDENCY_IMAGE_CODEC"
END IF

IF DEPENDENCY(DEPENDENCY_CONSOLE_ONLY) THEN
    defines$ = defines$ + defines_header$ + "DEPENDENCY_CONSOLE_ONLY"
END IF

IF DEPENDENCY(DEPENDENCY_SOCKETS) THEN
    defines$ = defines$ + defines_header$ + "DEPENDENCY_SOCKETS"
ELSE
    defines$ = defines$ + defines_header$ + "DEPENDENCY_NO_SOCKETS"
END IF

IF DEPENDENCY(DEPENDENCY_PRINTER) THEN
    defines$ = defines$ + defines_header$ + "DEPENDENCY_PRINTER"
ELSE
    defines$ = defines$ + defines_header$ + "DEPENDENCY_NO_PRINTER"
END IF

IF DEPENDENCY(DEPENDENCY_ICON) THEN
    defines$ = defines$ + defines_header$ + "DEPENDENCY_ICON"
ELSE
    defines$ = defines$ + defines_header$ + "DEPENDENCY_NO_ICON"
END IF

IF DEPENDENCY(DEPENDENCY_SCREENIMAGE) THEN
    defines$ = defines$ + defines_header$ + "DEPENDENCY_SCREENIMAGE"
ELSE
    defines$ = defines$ + defines_header$ + "DEPENDENCY_NO_SCREENIMAGE"
END IF

IF DEPENDENCY(DEPENDENCY_LOADFONT) THEN
    d$ = "internal\c\parts\video\font\ttf\"
    'rebuild?
    IF _FILEEXISTS(d$ + "os\" + o$ + "\src.o") = 0 THEN
        Build d$ + "os\" + o$
    END IF
    defines$ = defines$ + defines_header$ + "DEPENDENCY_LOADFONT"
    libs$ = libs$ + " " + "parts\video\font\ttf\os\" + o$ + "\src.o"
END IF

localpath$ = "internal\c\"

IF DEPENDENCY(DEPENDENCY_DEVICEINPUT) THEN
    defines$ = defines$ + defines_header$ + "DEPENDENCY_DEVICEINPUT"
    libname$ = "input\game_controller"
    libpath$ = "parts\" + libname$ + "\os\" + o$
    libfile$ = libpath$ + "\src.a"
    IF _FILEEXISTS(localpath$ + libfile$) = 0 THEN Build localpath$ + libpath$ 'rebuild?
    libs$ = libs$ + " " + libfile$
END IF

IF DEPENDENCY(DEPENDENCY_AUDIO_DECODE) THEN DEPENDENCY(DEPENDENCY_AUDIO_CONVERSION) = 1
IF DEPENDENCY(DEPENDENCY_AUDIO_CONVERSION) THEN DEPENDENCY(DEPENDENCY_AUDIO_OUT) = 1
IF DEPENDENCY(DEPENDENCY_AUDIO_DECODE) THEN DEPENDENCY(DEPENDENCY_AUDIO_OUT) = 1


IF DEPENDENCY(DEPENDENCY_AUDIO_CONVERSION) THEN
    defines$ = defines$ + defines_header$ + "DEPENDENCY_AUDIO_CONVERSION"

    d1$ = "parts\audio\conversion"
    d2$ = d1$ + "\os\" + o$
    d3$ = "internal\c\" + d2$
    IF _FILEEXISTS(d3$ + "\src.a") = 0 THEN 'rebuild?
        Build d3$
    END IF
    libs$ = libs$ + " " + d2$ + "\src.a"

    d1$ = "parts\audio\libresample"
    d2$ = d1$ + "\os\" + o$
    d3$ = "internal\c\" + d2$
    IF _FILEEXISTS(d3$ + "\src.a") = 0 THEN 'rebuild?
        Build d3$
    END IF
    libs$ = libs$ + " " + d2$ + "\src.a"

END IF

IF DEPENDENCY(DEPENDENCY_AUDIO_DECODE) THEN
    'General decoder
    defines$ = defines$ + defines_header$ + "DEPENDENCY_AUDIO_DECODE"
    'MP3 decoder (deprecated)
    d1$ = "parts\audio\decode\mp3"
    d2$ = d1$ + "\os\" + o$
    d3$ = "internal\c\" + d2$
    IF _FILEEXISTS(d3$ + "\src.a") = 0 THEN 'rebuild?
        Build d3$
    END IF
    libs$ = libs$ + " " + d2$ + "\src.a"
    'MINI_MP3 decoder
    d1$ = "parts\audio\decode\mp3_mini"
    d2$ = d1$ + "\os\" + o$
    d3$ = "internal\c\" + d2$
    IF _FILEEXISTS(d3$ + "\src.a") = 0 THEN 'rebuild?
        Build d3$
    END IF
    libs$ = libs$ + " " + d2$ + "\src.a"
    'OGG decoder
    d1$ = "parts\audio\decode\ogg"
    d2$ = d1$ + "\os\" + o$
    d3$ = "internal\c\" + d2$
    IF _FILEEXISTS(d3$ + "\src.o") = 0 THEN 'rebuild?
        Build d3$
    END IF
    libs$ = libs$ + " " + d2$ + "\src.o"
    'WAV decoder
    '(no action required)
END IF

IF DEPENDENCY(DEPENDENCY_AUDIO_OUT) THEN
    defines$ = defines$ + defines_header$ + "DEPENDENCY_AUDIO_OUT"
    d1$ = "parts\audio\out"
    d2$ = d1$ + "\os\" + o$
    d3$ = "internal\c\" + d2$
    IF _FILEEXISTS(d3$ + "\src.a") = 0 THEN 'rebuild?
        Build d3$
    END IF
    libs$ = libs$ + " " + d2$ + "\src.a"
END IF

IF DEPENDENCY(DEPENDENCY_USER_MODS) THEN
    defines$ = defines$ + defines_header$ + "DEPENDENCY_USER_MODS"
    d1$ = "parts\user_mods"
    d2$ = d1$ + "\os\" + o$
    d3$ = "internal\c\" + d2$
    IF _FILEEXISTS(d3$ + "\src.a") = 0 THEN
        Build d3$
    END IF
    libs$ = libs$ + " " + d2$ + "\src.a"
END IF

'finalize libs$ and defines$ strings
IF LEN(libs$) THEN libs$ = libs$ + " "
PATH_SLASH_CORRECT libs$
IF LEN(defines$) THEN defines$ = defines$ + " "

'Build core?
IF mac = 0 THEN 'macosx uses Apple's GLUT not FreeGLUT
    d1$ = "parts\core"
    d2$ = d1$ + "\os\" + o$
    d3$ = "internal\c\" + d2$
    IF _FILEEXISTS(d3$ + "\src.a") = 0 THEN 'rebuild?
        Build d3$
    END IF
END IF 'mac = 0

'Build libqb?
depstr$ = ver$ + "_"
FOR i = 1 TO DEPENDENCY_LAST
    IF DEPENDENCY(i) THEN depstr$ = depstr$ + "1" ELSE depstr$ = depstr$ + "0"
NEXT
libqb$ = " libqb\os\" + o$ + "\libqb_" + depstr$ + ".o "
PATH_SLASH_CORRECT libqb$
IF _FILEEXISTS("internal\c\" + LTRIM$(RTRIM$(libqb$))) = 0 THEN
    CHDIR "internal\c"
    IF os$ = "WIN" THEN
        SHELL _HIDE GDB_Fix("cmd /c c_compiler\bin\g++ -c -s -w -Wall libqb.cpp -D FREEGLUT_STATIC " + defines$ + " -o libqb\os\" + o$ + "\libqb_" + depstr$ + ".o")
    ELSE
        IF mac THEN
            SHELL _HIDE GDB_Fix("g++ -c -s -w -Wall libqb.cpp " + defines$ + " -o libqb/os/" + o$ + "/libqb_" + depstr$ + ".o")
        ELSE
            SHELL _HIDE GDB_Fix("g++ -c -s -w -Wall libqb.cpp -D FREEGLUT_STATIC " + defines$ + " -o libqb/os/" + o$ + "/libqb_" + depstr$ + ".o")
        END IF
    END IF
    CHDIR "..\.."
END IF

'link-time only defines
IF DEPENDENCY(DEPENDENCY_AUDIO_OUT) THEN
    IF mac THEN defines$ = defines$ + " -framework AudioUnit -framework AudioToolbox "
END IF
























IF MakeAndroid THEN







    GOTO Skip_Build
END IF

IF os$ = "WIN" THEN

    'resolve static function definitions and add to global.txt
    FOR x = 1 TO ResolveStaticFunctions
        IF LEN(ResolveStaticFunction_File(x)) THEN

            n = 0
            SHELL _HIDE "internal\c\c_compiler\bin\nm.exe " + CHR$(34) + ResolveStaticFunction_File(x) + CHR$(34) + " --demangle -g >internal\temp\nm_output.txt"
            fh = FREEFILE
            s$ = " " + ResolveStaticFunction_Name(x) + "("
            OPEN "internal\temp\nm_output.txt" FOR BINARY AS #fh
            DO UNTIL EOF(fh)
                LINE INPUT #fh, a$
                IF LEN(a$) THEN
                    'search for SPACE+functionname+LEFTBRACKET
                    x1 = INSTR(a$, s$)
                    IF x1 THEN
                        IF ResolveStaticFunction_Method(x) = 1 THEN
                            x1 = x1 + 1
                            x2 = INSTR(x1, a$, ")")
                            fh2 = FREEFILE
                            OPEN tmpdir$ + "global.txt" FOR APPEND AS #fh2
                            PRINT #fh2, "extern void " + MID$(a$, x1, x2 - x1 + 1) + ";"
                            CLOSE #fh2
                        END IF
                        n = n + 1
                    END IF 'x1
                END IF '<>""
            LOOP
            CLOSE #fh
            IF n > 1 THEN a$ = "Unable to resolve multiple instances of sub/function '" + ResolveStaticFunction_Name(x) + "' in '" + ResolveStaticFunction_File(x) + "'": GOTO errmes

            IF n = 0 THEN 'attempt to locate simple function name without brackets
                fh = FREEFILE
                s$ = " " + ResolveStaticFunction_Name(x)
                OPEN "internal\temp\nm_output.txt" FOR BINARY AS #fh
                DO UNTIL EOF(fh)
                    LINE INPUT #fh, a$
                    IF LEN(a$) THEN
                        'search for SPACE+functionname
                        x1 = INSTR(a$, s$)
                        IF RIGHT$(a$, LEN(s$)) = s$ THEN
                            fh2 = FREEFILE
                            IF ResolveStaticFunction_Method(x) = 1 THEN
                                OPEN tmpdir$ + "global.txt" FOR APPEND AS #fh2
                                PRINT #fh2, "extern " + CHR$(34) + "C" + CHR$(34) + "{"
                                PRINT #fh2, "extern void " + s$ + "(void);"
                                PRINT #fh2, "}"
                            ELSE
                                OPEN tmpdir$ + "externtype" + str2(x) + ".txt" FOR OUTPUT AS #fh2
                                PRINT #fh2, "extern " + CHR$(34) + "C" + CHR$(34) + " "
                            END IF
                            CLOSE #fh2
                            n = n + 1
                            EXIT DO
                        END IF 'x1
                    END IF '<>""
                LOOP
                CLOSE #fh
            END IF

            IF n = 0 THEN 'a C++ dynamic object library?
                SHELL _HIDE "internal\c\c_compiler\bin\nm " + CHR$(34) + ResolveStaticFunction_File(x) + CHR$(34) + " -D --demangle -g >.\internal\temp\nm_output_dynamic.txt"
                fh = FREEFILE
                s$ = " " + ResolveStaticFunction_Name(x) + "("
                OPEN "internal\temp\nm_output_dynamic.txt" FOR BINARY AS #fh
                DO UNTIL EOF(fh)
                    LINE INPUT #fh, a$
                    IF LEN(a$) THEN
                        'search for SPACE+functionname+LEFTBRACKET
                        x1 = INSTR(a$, s$)
                        IF x1 THEN
                            IF ResolveStaticFunction_Method(x) = 1 THEN
                                x1 = x1 + 1
                                x2 = INSTR(x1, a$, ")")
                                fh2 = FREEFILE
                                OPEN tmpdir$ + "global.txt" FOR APPEND AS #fh2
                                PRINT #fh2, "extern void " + MID$(a$, x1, x2 - x1 + 1) + ";"
                                CLOSE #fh2
                            END IF
                            n = n + 1
                        END IF 'x1
                    END IF '<>""
                LOOP
                CLOSE #fh
                IF n > 1 THEN a$ = "Unable to resolve multiple instances of sub/function '" + ResolveStaticFunction_Name(x) + "' in '" + ResolveStaticFunction_File(x) + "'": GOTO errmes
            END IF

            IF n = 0 THEN 'a C dynamic object library?
                fh = FREEFILE
                s$ = " " + ResolveStaticFunction_Name(x)
                OPEN "internal\temp\nm_output_dynamic.txt" FOR BINARY AS #fh
                DO UNTIL EOF(fh)
                    LINE INPUT #fh, a$
                    IF LEN(a$) THEN
                        'search for SPACE+functionname
                        x1 = INSTR(a$, s$)
                        IF RIGHT$(a$, LEN(s$)) = s$ THEN
                            fh2 = FREEFILE
                            IF ResolveStaticFunction_Method(x) = 1 THEN
                                OPEN tmpdir$ + "global.txt" FOR APPEND AS #fh2
                                PRINT #fh2, "extern " + CHR$(34) + "C" + CHR$(34) + "{"
                                PRINT #fh2, "extern void " + s$ + "(void);"
                                PRINT #fh2, "}"
                            ELSE
                                OPEN tmpdir$ + "externtype" + str2(x) + ".txt" FOR OUTPUT AS #fh2
                                PRINT #fh2, "extern " + CHR$(34) + "C" + CHR$(34) + " "
                            END IF
                            CLOSE #fh2
                            n = n + 1
                            EXIT DO
                        END IF 'x1
                    END IF '<>""
                LOOP
                CLOSE #fh
                IF n = 0 THEN a$ = "Could not find sub/function '" + ResolveStaticFunction_Name(x) + "' in '" + ResolveStaticFunction_File(x) + "'": GOTO errmes
            END IF

        END IF
    NEXT

    IF inline_DATA = 0 THEN
        IF DataOffset THEN
            IF OS_BITS = 32 THEN
                OPEN ".\internal\c\makedat_win32.txt" FOR BINARY AS #150: LINE INPUT #150, a$: CLOSE #150
            ELSE
                OPEN ".\internal\c\makedat_win64.txt" FOR BINARY AS #150: LINE INPUT #150, a$: CLOSE #150
            END IF
            a$ = a$ + " " + tmpdir2$ + "data.bin " + tmpdir2$ + "data.o"
            CHDIR ".\internal\c"
            SHELL _HIDE a$
            CHDIR "..\.."
        END IF
    END IF




    OPEN ".\internal\c\makeline_win.txt" FOR BINARY AS #150
    LINE INPUT #150, a$: a$ = GDB_Fix(a$)
    CLOSE #150
    IF RIGHT$(a$, 7) = " ..\..\" THEN a$ = LEFT$(a$, LEN(a$) - 6) 'makeline.txt patch (line will become unrequired in later versions)
    'change qbx.cpp to qbx999.cpp?
    x = INSTR(a$, "qbx.cpp"): IF x <> 0 AND tempfolderindex <> 1 THEN a$ = LEFT$(a$, x - 1) + "qbx" + str2$(tempfolderindex) + ".cpp" + RIGHT$(a$, LEN(a$) - (x + 6))

    IF Console THEN
        x = INSTR(a$, " -s"): a$ = LEFT$(a$, x - 1) + " -mconsole" + RIGHT$(a$, LEN(a$) - x + 1)
    END IF

    IF DEPENDENCY(DEPENDENCY_CONSOLE_ONLY) THEN
        a$ = StrRemove(a$, "-mwindows")
        a$ = StrRemove(a$, "-lopengl32")
        a$ = StrRemove(a$, "-lglu32")
        a$ = StrRemove(a$, "parts\core\os\win\src.a")
        a$ = StrRemove(a$, "-D FREEGLUT_STATIC")
        a$ = StrRemove(a$, "-D GLEW_STATIC")
    END IF

    a$ = StrRemove(a$, "-lws2_32")
    IF DEPENDENCY(DEPENDENCY_SOCKETS) THEN
        x = INSTR(a$, " -o"): a$ = LEFT$(a$, x - 1) + " -lws2_32" + RIGHT$(a$, LEN(a$) - x + 1)
    END IF

    a$ = StrRemove(a$, "-lwinspool")
    IF DEPENDENCY(DEPENDENCY_PRINTER) THEN
        x = INSTR(a$, " -o"): a$ = LEFT$(a$, x - 1) + " -lwinspool" + RIGHT$(a$, LEN(a$) - x + 1)
    END IF

    a$ = StrRemove(a$, "-lwinmm")
    IF DEPENDENCY(DEPENDENCY_AUDIO_OUT) <> 0 OR DEPENDENCY(DEPENDENCY_CONSOLE_ONLY) = 0 THEN
        x = INSTR(a$, " -o"): a$ = LEFT$(a$, x - 1) + " -lwinmm" + RIGHT$(a$, LEN(a$) - x + 1)
    END IF

    a$ = StrRemove(a$, "-lksguid")
    IF DEPENDENCY(DEPENDENCY_AUDIO_OUT) THEN
        x = INSTR(a$, " -o"): a$ = LEFT$(a$, x - 1) + " -lksguid" + RIGHT$(a$, LEN(a$) - x + 1)
    END IF

    a$ = StrRemove(a$, "-ldxguid")
    IF DEPENDENCY(DEPENDENCY_AUDIO_OUT) THEN
        x = INSTR(a$, " -o"): a$ = LEFT$(a$, x - 1) + " -ldxguid" + RIGHT$(a$, LEN(a$) - x + 1)
    END IF

    a$ = StrRemove(a$, "-lole32")
    IF DEPENDENCY(DEPENDENCY_AUDIO_OUT) THEN
        x = INSTR(a$, " -o"): a$ = LEFT$(a$, x - 1) + " -lole32" + RIGHT$(a$, LEN(a$) - x + 1)
    END IF

    a$ = StrRemove(a$, "-lgdi32")
    IF DEPENDENCY(DEPENDENCY_ICON) <> 0 OR DEPENDENCY(DEPENDENCY_SCREENIMAGE) <> 0 OR DEPENDENCY(DEPENDENCY_PRINTER) <> 0 THEN
        x = INSTR(a$, " -o"): a$ = LEFT$(a$, x - 1) + " -lgdi32" + RIGHT$(a$, LEN(a$) - x + 1)
    END IF

    IF inline_DATA = 0 THEN
        'add data.o?
        IF DataOffset THEN
            x = INSTR(a$, ".cpp ")
            IF x THEN
                x = x + 3
                a$ = LEFT$(a$, x) + " " + tmpdir2$ + "data.o" + " " + RIGHT$(a$, LEN(a$) - x)
            END IF
        END IF
    END IF

    'add custom libraries
    'mylib$="..\..\"+x$+".lib"
    IF LEN(mylib$) THEN
        x = INSTR(a$, ".cpp ")
        IF x THEN
            x = x + 3
            a$ = LEFT$(a$, x) + " " + mylib$ + " " + RIGHT$(a$, LEN(a$) - x)
        END IF
    END IF


    'add dependent libraries
    IF LEN(libs$) THEN
        x = INSTR(a$, ".cpp ")
        IF x THEN
            x = x + 5
            a$ = LEFT$(a$, x - 1) + libs$ + RIGHT$(a$, LEN(a$) - x + 1)
        END IF
    END IF

    'add dependency defines
    IF LEN(defines$) THEN
        x = INSTR(a$, ".cpp ")
        IF x THEN
            x = x + 5
            a$ = LEFT$(a$, x - 1) + defines$ + RIGHT$(a$, LEN(a$) - x + 1)
        END IF
    END IF

    'add libqb
    x = INSTR(a$, ".cpp ")
    IF x THEN
        x = x + 5
        a$ = LEFT$(a$, x - 1) + libqb$ + RIGHT$(a$, LEN(a$) - x + 1)
    END IF

    a$ = a$ + QuotedFilename$("..\..\" + file$ + extension$)

    ffh = FREEFILE
    OPEN tmpdir$ + "recompile_win.bat" FOR OUTPUT AS #ffh
    PRINT #ffh, "@echo off"
    PRINT #ffh, "cd %0\..\"
    PRINT #ffh, "echo Recompiling..."
    PRINT #ffh, "cd ../c"
    PRINT #ffh, a$
    PRINT #ffh, "pause"
    CLOSE ffh

    ffh = FREEFILE
    OPEN tmpdir$ + "debug_win.bat" FOR OUTPUT AS #ffh
    PRINT #ffh, "@echo off"
    PRINT #ffh, "cd %0\..\"
    PRINT #ffh, "cd ../.."
    PRINT #ffh, "echo C++ Debugging: " + file$ + extension$ + " using gdb.exe"
    PRINT #ffh, "echo Debugger commands:"
    PRINT #ffh, "echo After the debugger launches type 'run' to start your program"
    PRINT #ffh, "echo After your program crashes type 'list' to find where the problem is and fix/report it"
    PRINT #ffh, "echo Type 'quit' to exit"
    PRINT #ffh, "echo (the GDB debugger has many other useful commands, this advice is for beginners)"
    PRINT #ffh, "pause"
    PRINT #ffh, "internal\c\c_compiler\bin\gdb.exe " + CHR$(34) + file$ + extension$ + CHR$(34)
    PRINT #ffh, "pause"
    CLOSE ffh

    IF No_C_Compile_Mode = 0 THEN
        CHDIR ".\internal\c"
        SHELL _HIDE a$
        CHDIR "..\.."
    END IF 'No_C_Compile_Mode=0

END IF

IF os$ = "LNX" THEN
    FOR x = 1 TO ResolveStaticFunctions
        IF LEN(ResolveStaticFunction_File(x)) THEN

            n = 0
            IF MacOSX = 0 THEN SHELL _HIDE "nm " + CHR$(34) + ResolveStaticFunction_File(x) + CHR$(34) + " --demangle -g >./internal/temp/nm_output.txt 2>./internal/temp/nm_error.txt"
            IF MacOSX THEN SHELL _HIDE "nm " + CHR$(34) + ResolveStaticFunction_File(x) + CHR$(34) + " >./internal/temp/nm_output.txt 2>./internal/temp/nm_error.txt"

            IF MacOSX = 0 THEN 'C++ name demangling not supported in MacOSX
                fh = FREEFILE
                s$ = " " + ResolveStaticFunction_Name(x) + "("
                OPEN "internal\temp\nm_output.txt" FOR BINARY AS #fh
                DO UNTIL EOF(fh)
                    LINE INPUT #fh, a$
                    IF LEN(a$) THEN
                        'search for SPACE+functionname+LEFTBRACKET
                        x1 = INSTR(a$, s$)
                        IF x1 THEN
                            IF ResolveStaticFunction_Method(x) = 1 THEN
                                x1 = x1 + 1
                                x2 = INSTR(x1, a$, ")")
                                fh2 = FREEFILE
                                OPEN tmpdir$ + "global.txt" FOR APPEND AS #fh2
                                PRINT #fh2, "extern void " + MID$(a$, x1, x2 - x1 + 1) + ";"
                                CLOSE #fh2
                            END IF
                            n = n + 1
                        END IF 'x1
                    END IF '<>""
                LOOP
                CLOSE #fh
                IF n > 1 THEN a$ = "Unable to resolve multiple instances of sub/function '" + ResolveStaticFunction_Name(x) + "' in '" + ResolveStaticFunction_File(x) + "'": GOTO errmes
            END IF 'macosx=0

            IF n = 0 THEN 'attempt to locate simple function name without brackets
                fh = FREEFILE
                s$ = " " + ResolveStaticFunction_Name(x): s2$ = s$
                IF MacOSX THEN s$ = " _" + ResolveStaticFunction_Name(x) 'search for C mangled name
                OPEN "internal\temp\nm_output.txt" FOR BINARY AS #fh
                DO UNTIL EOF(fh)
                    LINE INPUT #fh, a$
                    IF LEN(a$) THEN
                        'search for SPACE+functionname
                        x1 = INSTR(a$, s$)
                        IF RIGHT$(a$, LEN(s$)) = s$ THEN
                            fh2 = FREEFILE
                            IF ResolveStaticFunction_Method(x) = 1 THEN
                                OPEN tmpdir$ + "global.txt" FOR APPEND AS #fh2
                                PRINT #fh2, "extern " + CHR$(34) + "C" + CHR$(34) + "{"
                                PRINT #fh2, "extern void " + s2$ + "(void);"
                                PRINT #fh2, "}"
                            ELSE
                                OPEN tmpdir$ + "externtype" + str2(x) + ".txt" FOR OUTPUT AS #fh2
                                PRINT #fh2, "extern " + CHR$(34) + "C" + CHR$(34) + " "
                            END IF
                            CLOSE #fh2
                            n = n + 1
                            EXIT DO
                        END IF 'x1
                    END IF '<>""
                LOOP
                CLOSE #fh
            END IF

            IF n = 0 THEN 'a C++ dynamic object library?
                IF MacOSX THEN GOTO macosx_libfind_failed
                SHELL _HIDE "nm " + CHR$(34) + ResolveStaticFunction_File(x) + CHR$(34) + " -D --demangle -g >./internal/temp/nm_output_dynamic.txt 2>./internal/temp/nm_error.txt"
                fh = FREEFILE
                s$ = " " + ResolveStaticFunction_Name(x) + "("
                OPEN "internal\temp\nm_output_dynamic.txt" FOR BINARY AS #fh
                DO UNTIL EOF(fh)
                    LINE INPUT #fh, a$
                    IF LEN(a$) THEN
                        'search for SPACE+functionname+LEFTBRACKET
                        x1 = INSTR(a$, s$)
                        IF x1 THEN
                            IF ResolveStaticFunction_Method(x) = 1 THEN
                                x1 = x1 + 1
                                x2 = INSTR(x1, a$, ")")
                                fh2 = FREEFILE
                                OPEN tmpdir$ + "global.txt" FOR APPEND AS #fh2
                                PRINT #fh2, "extern void " + MID$(a$, x1, x2 - x1 + 1) + ";"
                                CLOSE #fh2
                            END IF
                            n = n + 1
                        END IF 'x1
                    END IF '<>""
                LOOP
                CLOSE #fh
                IF n > 1 THEN a$ = "Unable to resolve multiple instances of sub/function '" + ResolveStaticFunction_Name(x) + "' in '" + ResolveStaticFunction_File(x) + "'": GOTO errmes
            END IF

            IF n = 0 THEN 'a C dynamic object library?
                fh = FREEFILE
                s$ = " " + ResolveStaticFunction_Name(x)
                OPEN "internal\temp\nm_output_dynamic.txt" FOR BINARY AS #fh
                DO UNTIL EOF(fh)
                    LINE INPUT #fh, a$
                    IF LEN(a$) THEN
                        'search for SPACE+functionname
                        x1 = INSTR(a$, s$)
                        IF RIGHT$(a$, LEN(s$)) = s$ THEN
                            fh2 = FREEFILE
                            IF ResolveStaticFunction_Method(x) = 1 THEN
                                OPEN tmpdir$ + "global.txt" FOR APPEND AS #fh2
                                PRINT #fh2, "extern " + CHR$(34) + "C" + CHR$(34) + "{"
                                PRINT #fh2, "extern void " + s$ + "(void);"
                                PRINT #fh2, "}"
                            ELSE
                                OPEN tmpdir$ + "externtype" + str2(x) + ".txt" FOR OUTPUT AS #fh2
                                PRINT #fh2, "extern " + CHR$(34) + "C" + CHR$(34) + " "
                            END IF
                            CLOSE #fh2
                            n = n + 1
                            EXIT DO
                        END IF 'x1
                    END IF '<>""
                LOOP
                CLOSE #fh
                macosx_libfind_failed:
                IF n = 0 THEN a$ = "Could not find sub/function '" + ResolveStaticFunction_Name(x) + "' in '" + ResolveStaticFunction_File(x) + "'": GOTO errmes
            END IF

        END IF
    NEXT

    IF inline_DATA = 0 THEN
        IF DataOffset THEN
            IF INSTR(_OS$, "[32BIT]") THEN b$ = "32" ELSE b$ = "64"
            OPEN ".\internal\c\makedat_lnx" + b$ + ".txt" FOR BINARY AS #150: LINE INPUT #150, a$: CLOSE #150
            a$ = a$ + " " + tmpdir2$ + "data.bin " + tmpdir2$ + "data.o"
            CHDIR ".\internal\c"
            SHELL _HIDE a$
            CHDIR "..\.."
        END IF
    END IF

    IF INSTR(_OS$, "[MACOSX]") THEN
        OPEN "./internal/c/makeline_osx.txt" FOR INPUT AS #150
    ELSE
        OPEN "./internal/c/makeline_lnx.txt" FOR INPUT AS #150
    END IF

    LINE INPUT #150, a$: a$ = GDB_Fix(a$)
    CLOSE #150
    'change qbx.cpp to qbx999.cpp?
    x = INSTR(a$, "qbx.cpp"): IF x <> 0 AND tempfolderindex <> 1 THEN a$ = LEFT$(a$, x - 1) + "qbx" + str2$(tempfolderindex) + ".cpp" + RIGHT$(a$, LEN(a$) - (x + 6))

    IF inline_DATA = 0 THEN
        'add data.o?
        IF DataOffset THEN
            x = INSTR(a$, "-lX11")
            IF x THEN
                a$ = LEFT$(a$, x - 1) + " " + tmpdir2$ + "data.o " + RIGHT$(a$, LEN(a$) - x + 1)
            END IF
        END IF
    END IF


    'add custom libraries
    IF LEN(mylib$) THEN
        x = INSTR(a$, ".cpp ")
        IF x THEN
            x = x + 5
            a$ = LEFT$(a$, x - 1) + " " + mylibopt$ + " " + mylib$ + " " + RIGHT$(a$, LEN(a$) - x + 1)
        END IF
    END IF

    'add dependent libraries
    IF LEN(libs$) THEN
        x = INSTR(a$, ".cpp ")
        IF x THEN
            x = x + 5
            a$ = LEFT$(a$, x - 1) + libs$ + RIGHT$(a$, LEN(a$) - x + 1)
        END IF
    END IF

    'add dependency defines
    IF LEN(defines$) THEN
        x = INSTR(a$, ".cpp ")
        IF x THEN
            x = x + 5
            a$ = LEFT$(a$, x - 1) + defines$ + RIGHT$(a$, LEN(a$) - x + 1)
        END IF
    END IF

    'add libqb
    x = INSTR(a$, ".cpp ")
    IF x THEN
        x = x + 5
        a$ = LEFT$(a$, x - 1) + libqb$ + RIGHT$(a$, LEN(a$) - x + 1)
    END IF








    a$ = a$ + QuotedFilename$("../../" + file$ + extension$)

    IF INSTR(_OS$, "[MACOSX]") THEN

        ffh = FREEFILE
        OPEN tmpdir$ + "recompile_osx.command" FOR OUTPUT AS #ffh
        PRINT #ffh, "cd " + CHR_QUOTE + "$(dirname " + CHR_QUOTE + "$0" + CHR_QUOTE + ")" + CHR_QUOTE + CHR$(10);
        PRINT #ffh, "echo " + CHR_QUOTE + "Recompiling..." + CHR_QUOTE + CHR$(10);
        PRINT #ffh, "cd ../c" + CHR$(10);
        PRINT #ffh, a$ + CHR$(10);
        PRINT #ffh, "read -p " + CHR_QUOTE + "Press ENTER to exit..." + CHR_QUOTE + CHR$(10);
        CLOSE ffh
        SHELL _HIDE "chmod +x " + tmpdir$ + "recompile_osx.command"

        ffh = FREEFILE
        OPEN tmpdir$ + "debug_osx.command" FOR OUTPUT AS #ffh
        PRINT #ffh, "cd " + CHR_QUOTE + "$(dirname " + CHR_QUOTE + "$0" + CHR_QUOTE + ")" + CHR_QUOTE + CHR$(10);
        PRINT #ffh, "Pause()" + CHR$(10);
        PRINT #ffh, "{" + CHR$(10);
        PRINT #ffh, "OLDCONFIG=`stty -g`" + CHR$(10);
        PRINT #ffh, "stty -icanon -echo min 1 time 0" + CHR$(10);
        PRINT #ffh, "dd count=1 2>/dev/null" + CHR$(10);
        PRINT #ffh, "stty $OLDCONFIG" + CHR$(10);
        PRINT #ffh, "}" + CHR$(10);
        PRINT #ffh, "echo " + CHR_QUOTE + "C++ Debugging: " + file$ + extension$ + " using GDB" + CHR_QUOTE + CHR$(10);
        PRINT #ffh, "echo " + CHR_QUOTE + "Debugger commands:" + CHR_QUOTE + CHR$(10);
        PRINT #ffh, "echo " + CHR_QUOTE + "After the debugger launches type 'run' to start your program" + CHR_QUOTE + CHR$(10);
        PRINT #ffh, "echo " + CHR_QUOTE + "After your program crashes type 'list' to find where the problem is and fix/report it" + CHR_QUOTE + CHR$(10);
        PRINT #ffh, "echo " + CHR_QUOTE + "(the GDB debugger has many other useful commands, this advice is for beginners)" + CHR_QUOTE + CHR$(10);
        PRINT #ffh, "gdb " + CHR$(34) + "../../" + file$ + extension$ + CHR$(34) + CHR$(10);
        PRINT #ffh, "Pause" + CHR$(10);
        CLOSE ffh
        SHELL _HIDE "chmod +x " + tmpdir$ + "debug_osx.command"

    ELSE

        ffh = FREEFILE
        OPEN tmpdir$ + "recompile_lnx.sh" FOR OUTPUT AS #ffh
        PRINT #ffh, "#!/bin/sh" + CHR$(10);
        PRINT #ffh, "Pause()" + CHR$(10);
        PRINT #ffh, "{" + CHR$(10);
        PRINT #ffh, "OLDCONFIG=`stty -g`" + CHR$(10);
        PRINT #ffh, "stty -icanon -echo min 1 time 0" + CHR$(10);
        PRINT #ffh, "dd count=1 2>/dev/null" + CHR$(10);
        PRINT #ffh, "stty $OLDCONFIG" + CHR$(10);
        PRINT #ffh, "}" + CHR$(10);
        PRINT #ffh, "echo " + CHR_QUOTE + "Recompiling..." + CHR_QUOTE + CHR$(10);
        PRINT #ffh, "cd ../c" + CHR$(10);
        PRINT #ffh, a$ + CHR$(10);
        PRINT #ffh, "echo " + CHR_QUOTE + "Press ENTER to exit..." + CHR_QUOTE + CHR$(10);
        PRINT #ffh, "Pause" + CHR$(10);
        CLOSE ffh
        SHELL _HIDE "chmod +x " + tmpdir$ + "recompile_lnx.sh"

        ffh = FREEFILE
        OPEN tmpdir$ + "debug_lnx.sh" FOR OUTPUT AS #ffh
        PRINT #ffh, "#!/bin/sh" + CHR$(10);
        PRINT #ffh, "Pause()" + CHR$(10);
        PRINT #ffh, "{" + CHR$(10);
        PRINT #ffh, "OLDCONFIG=`stty -g`" + CHR$(10);
        PRINT #ffh, "stty -icanon -echo min 1 time 0" + CHR$(10);
        PRINT #ffh, "dd count=1 2>/dev/null" + CHR$(10);
        PRINT #ffh, "stty $OLDCONFIG" + CHR$(10);
        PRINT #ffh, "}" + CHR$(10);
        PRINT #ffh, "echo " + CHR_QUOTE + "C++ Debugging: " + file$ + extension$ + " using GDB" + CHR_QUOTE + CHR$(10);
        PRINT #ffh, "echo " + CHR_QUOTE + "Debugger commands:" + CHR_QUOTE + CHR$(10);
        PRINT #ffh, "echo " + CHR_QUOTE + "After the debugger launches type 'run' to start your program" + CHR_QUOTE + CHR$(10);
        PRINT #ffh, "echo " + CHR_QUOTE + "After your program crashes type 'list' to find where the problem is and fix/report it" + CHR_QUOTE + CHR$(10);
        PRINT #ffh, "echo " + CHR_QUOTE + "(the GDB debugger has many other useful commands, this advice is for beginners)" + CHR_QUOTE + CHR$(10);
        PRINT #ffh, "gdb " + CHR$(34) + "../../" + file$ + extension$ + CHR$(34) + CHR$(10);
        PRINT #ffh, "Pause" + CHR$(10);
        CLOSE ffh
        SHELL _HIDE "chmod +x " + tmpdir$ + "debug_lnx.sh"

    END IF

    IF No_C_Compile_Mode = 0 THEN
        CHDIR "./internal/c"
        SHELL _HIDE a$
        CHDIR "../.."
    END IF

    IF INSTR(_OS$, "[MACOSX]") THEN
        ff = FREEFILE
        OPEN file$ + extension$ + "_start.command" FOR OUTPUT AS #ff
        PRINT #ff, "cd " + CHR$(34) + "$(dirname " + CHR$(34) + "$0" + CHR$(34) + ")" + CHR$(34);
        PRINT #ff, CHR$(10);
        PRINT #ff, "./" + file$ + extension$;
        PRINT #ff, CHR$(10);
        CLOSE #ff
        SHELL _HIDE "chmod +x " + file$ + extension$ + "_start.command"
    END IF

END IF

IF No_C_Compile_Mode THEN compfailed = 0: GOTO No_C_Compile
IF _FILEEXISTS(file$ + extension$) THEN compfailed = 0 ELSE compfailed = 1 'detect compilation failure

IF compfailed THEN
    IF idemode THEN
        idemessage$ = "C++ Compilation failed"
        GOTO ideerror
    END IF
    IF compfailed THEN PRINT "C++ COMPILATION FAILED!"
END IF



Skip_Build:



IF idemode THEN GOTO ideret6

No_C_Compile:

IF compfailed <> 0 AND ConsoleMode = 0 THEN END 1
IF compfailed <> 0 THEN SYSTEM 1
SYSTEM 0

qberror_test:
E = 1
RESUME NEXT

qberror:

IF ideerror THEN 'error happened inside the IDE
    fh = FREEFILE
    OPEN "internal\temp\ideerror.txt" FOR OUTPUT AS #fh
    PRINT #fh, ERR
    PRINT #fh, _ERRORLINE
    CLOSE #fh
    sendc$ = CHR$(255) 'a runtime error has occurred
    RESUME sendcommand 'allow IDE to handle error recovery
END IF

qberrorhappenedvalue = qberrorhappened
qberrorhappened = 1

IF Debug THEN PRINT #9, "QB ERROR!"
IF Debug THEN PRINT #9, "ERR="; ERR
IF Debug THEN PRINT #9, "ERL="; ERL

IF idemode AND qberrorhappenedvalue >= 0 THEN
    'real qb error occurred
    ideerrorline = linenumber
    idemessage$ = "Compiler error (check for syntax errors) (Reference:" + str2$(ERR) + "-" + str2$(_ERRORLINE) + ")"
    IF inclevel > 0 THEN idemessage$ = idemessage$ + incerror$
    RESUME ideerror
END IF

IF qberrorhappenedvalue >= 0 THEN
    a$ = "UNEXPECTED INTERNAL COMPILER ERROR!": GOTO errmes 'internal comiler error
END IF


qberrorcode = ERR
qberrorline = ERL
IF qberrorhappenedvalue = -1 THEN RESUME qberrorhappened1
IF qberrorhappenedvalue = -2 THEN RESUME qberrorhappened2
IF qberrorhappenedvalue = -3 THEN RESUME qberrorhappened3
END

errmes: 'set a$ to message
IF Error_Happened THEN a$ = Error_Message: Error_Happened = 0
layout$ = "": layoutok = 0 'invalidate layout
IF inclevel > 0 THEN a$ = a$ + incerror$
IF idemode THEN
    ideerrorline = linenumber
    idemessage$ = a$
    GOTO ideerror 'infinitely preferable to RESUME
END IF
'non-ide mode output
PRINT
PRINT a$
FOR i = 1 TO LEN(linefragment)
    IF MID$(linefragment, i, 1) = sp$ THEN MID$(linefragment, i, 1) = " "
NEXT
FOR i = 1 TO LEN(wholeline)
    IF MID$(wholeline, i, 1) = sp$ THEN MID$(wholeline, i, 1) = " "
NEXT
PRINT "Caused by (or after):" + linefragment
PRINT "LINE " + str2(linenumber) + ":" + wholeline

IF ConsoleMode THEN SYSTEM 1
END 1

FUNCTION ParseCMDLineArgs$ ()
'Recall that COMMAND$ is a concatenation of argv[] elements, so we don't have
'to worry about more than one space between things (unless they used quotes,
'in which case they're simply asking for trouble).
cmdline$ = LTRIM$(RTRIM$(COMMAND$))
tpos = 1
DO
    token$ = MID$(cmdline$, tpos, 2) '))
    SELECT CASE token$
        CASE "-g" 'non-GUI environment (uses $CONSOLE:ONLY)
            DEPENDENCY(DEPENDENCY_CONSOLE_ONLY) = DEPENDENCY(DEPENDENCY_CONSOLE_ONLY) OR 2
            NoIDEMode = 1 'Implies -c
            Console = 1
        CASE "-q" 'Building a Qloud program
            Cloud = 1
            ConsoleMode = 1 'Implies -x
            NoIDEMode = 1 'Imples -c
        CASE "-z" 'Not compiling C code
            No_C_Compile_Mode = 1
            ConsoleMode = 1 'Implies -x
            NoIDEMode = 1 'Implies -c
        CASE "-x" 'Use the console
            ConsoleMode = 1
            NoIDEMode = 1 'Implies -c
        CASE "-c" 'Compile instead of edit
            NoIDEMode = 1
        CASE "--" 'Signifies the end of options; the rest of the line is a filename (allows compilation of -crapfile.bas and -xtreme.bas etc.)
            tpos = tpos + 3 'Do it manually here
            EXIT DO
        CASE ELSE 'Something we don't recognise, assume it's a filename
            EXIT DO
    END SELECT
    tpos = tpos + 3
LOOP
'tpos should now point to the filename (the rest of the command line). This means options *must* come before the file.
ParseCMDLineArgs$ = MID$(cmdline$, tpos)
END FUNCTION

FUNCTION Type2MemTypeValue (t1)
t = 0
IF t1 AND ISARRAY THEN t = t + 65536
IF t1 AND ISUDT THEN
    IF (t1 AND 511) = 1 THEN
        t = t + 4096 '_MEM type
    ELSE
        t = t + 32768
    END IF
ELSE
    IF t1 AND ISSTRING THEN
        t = t + 512 'string
    ELSE
        IF t1 AND ISFLOAT THEN
            t = t + 256 'float
        ELSE
            t = t + 128 'integer
            IF t1 AND ISUNSIGNED THEN t = t + 1024
            IF t1 AND ISOFFSET THEN t = t + 8192 'offset type
        END IF
        t1s = (t1 AND 511) \ 8
        IF t1s = 1 THEN t = t + t1s
        IF t1s = 2 THEN t = t + t1s
        IF t1s = 4 THEN t = t + t1s
        IF t1s = 8 THEN t = t + t1s
        IF t1s = 16 THEN t = t + t1s
        IF t1s = 32 THEN t = t + t1s
        IF t1s = 64 THEN t = t + t1s
    END IF
END IF
Type2MemTypeValue = t
END FUNCTION

FUNCTION FileHasExtension (f$)
FOR i = LEN(f$) TO 1 STEP -1
    a = ASC(f$, i)
    IF a = 47 OR a = 92 THEN EXIT FOR
    IF a = 46 THEN FileHasExtension = -1: EXIT FUNCTION
NEXT
END FUNCTION

FUNCTION RemoveFileExtension$ (f$) 'returns f$ without extension
FOR i = LEN(f$) TO 1 STEP -1
    a = ASC(f$, i)
    IF a = 47 OR a = 92 THEN EXIT FOR
    IF a = 46 THEN RemoveFileExtension$ = LEFT$(f$, i - 1): EXIT FUNCTION
NEXT
RemoveFileExtension$ = f$
END FUNCTION






FUNCTION allocarray (n2$, elements$, elementsize)
dimsharedlast = dimshared: dimshared = 0

IF autoarray = 1 THEN autoarray = 0: autoary = 1 'clear global value & set local value

f12$ = ""

'changelog:
'added 4 to [2] to indicate cmem array where appropriate

e$ = elements$: n$ = n2$
IF elementsize = -2147483647 THEN stringarray = 1: elementsize = 8

IF ASC(e$) = 63 THEN '?
    l$ = "(" + sp2 + ")"
    undefined = -1
    nume = 1
    IF LEN(e$) = 1 THEN GOTO undefinedarray
    undefined = 1
    nume = VAL(RIGHT$(e$, LEN(e$) - 1))
    GOTO undefinedarray
END IF


'work out how many elements there are (critical to later calculations)
nume = 1
n = numelements(e$)
FOR i = 1 TO n
    e2$ = getelement(e$, i)
    IF e2$ = "(" THEN b = b + 1
    IF b = 0 AND e2$ = "," THEN nume = nume + 1
    IF e2$ = ")" THEN b = b - 1
NEXT
IF Debug THEN PRINT #9, "numelements count:"; nume

descstatic = 0
IF arraydesc THEN
    IF id.arrayelements <> nume THEN

        IF id.arrayelements = -1 THEN 'unknown
            IF arrayelementslist(currentid) <> 0 AND nume <> arrayelementslist(currentid) THEN Give_Error "Cannot change the number of elements an array has!": EXIT FUNCTION
            IF nume = 1 THEN id.arrayelements = 1: ids(currentid).arrayelements = 1 'lucky guess!
            arrayelementslist(currentid) = nume
        ELSE
            Give_Error "Cannot change the number of elements an array has!": EXIT FUNCTION
        END IF

    END IF
    IF id.staticarray THEN descstatic = 1
END IF

l$ = "(" + sp2

cr$ = CHR$(13) + CHR$(10)
sd$ = ""
constdimensions = 1
ei = 4 + nume * 4 - 4
cure = 1
e3$ = "": e3base$ = ""
FOR i = 1 TO n
    e2$ = getelement(e$, i)
    IF e2$ = "(" THEN b = b + 1
    IF (e2$ = "," AND b = 0) OR i = n THEN
        IF i = n THEN e3$ = e3$ + sp + e2$
        e3$ = RIGHT$(e3$, LEN(e3$) - 1)
        IF e3base$ <> "" THEN e3base$ = RIGHT$(e3base$, LEN(e3base$) - 1)
        'PRINT e3base$ + "[TO]" + e3$
        'set the base

        basegiven = 1
        IF e3base$ = "" THEN e3base$ = str2$(optionbase + 0): basegiven = 0
        constequation = 1

        e3base$ = fixoperationorder$(e3base$)
        IF Error_Happened THEN EXIT FUNCTION
        IF basegiven THEN l$ = l$ + tlayout$ + sp + "TO" + sp
        e3base$ = evaluatetotyp$(e3base$, 64&)
        IF Error_Happened THEN EXIT FUNCTION

        IF constequation = 0 THEN constdimensions = 0
        sd$ = sd$ + n$ + "[" + str2(ei) + "]=" + e3base$ + ";" + cr$
        'set the number of indexes
        constequation = 1

        e3$ = fixoperationorder$(e3$)
        IF Error_Happened THEN EXIT FUNCTION
        l$ = l$ + tlayout$ + sp2
        IF i = n THEN l$ = l$ + ")" ELSE l$ = l$ + "," + sp
        e3$ = evaluatetotyp$(e3$, 64&)
        IF Error_Happened THEN EXIT FUNCTION

        IF constequation = 0 THEN constdimensions = 0
        ei = ei + 1
        sd$ = sd$ + n$ + "[" + str2(ei) + "]=(" + e3$ + ")-" + n$ + "[" + str2(ei - 1) + "]+1;" + cr$
        ei = ei + 1
        'calc muliplier
        IF cure = 1 THEN
            'set only for the purpose of the calculating correct multipliers
            sd$ = sd$ + n$ + "[" + str2(ei) + "]=1;" + cr$
        ELSE
            sd$ = sd$ + n$ + "[" + str2(ei) + "]=" + n$ + "[" + str2(ei + 4) + "]*" + n$ + "[" + str2(ei + 3) + "];" + cr$
        END IF
        ei = ei + 1
        ei = ei + 1 'skip reserved
        ei = ei - 8
        cure = cure + 1
        e3$ = "": e3base$ = ""
        GOTO aanexte
    END IF
    IF e2$ = ")" THEN b = b - 1
    IF UCASE$(e2$) = "TO" AND b = 0 THEN
        e3base$ = e3$
        e3$ = ""
    ELSE
        e3$ = e3$ + sp + e2$
    END IF
    aanexte:
NEXT
sd$ = LEFT$(sd$, LEN(sd$) - 2)

undefinedarray:

'calc cmem
cmem = 0
IF arraydesc = 0 THEN
    IF cmemlist(idn + 1) THEN cmem = 1
ELSE
    IF cmemlist(arraydesc) THEN cmem = 1
END IF

staticarray = constdimensions
IF subfuncn <> 0 AND dimstatic = 0 THEN staticarray = 0 'arrays in SUBS/FUNCTIONS are DYNAMIC
IF dimstatic = 3 THEN staticarray = 0 'STATIC arrayname() listed arrays keep thier values but are dynamic in memory
IF DynamicMode THEN staticarray = 0
IF redimoption THEN staticarray = 0
IF dimoption = 3 THEN staticarray = 0 'STATIC a(100) arrays are still dynamic

IF arraydesc THEN
    IF staticarray = 1 THEN
        IF descstatic THEN Give_Error "Cannot redefine a static array!": EXIT FUNCTION
        staticarray = 0
    END IF
END IF






bytesperelement$ = str2(elementsize)
IF elementsize < 0 THEN
    elementsize = -elementsize
    bytesperelement$ = str2(elementsize) + "/8+1"
END IF


'Begin creation of array descriptor (if array has not been defined yet)
IF arraydesc = 0 THEN
    PRINT #defdatahandle, "ptrszint *" + n$ + "=NULL;"
    PRINT #13, "if (!" + n$ + "){"
    PRINT #13, n$ + "=(ptrszint*)mem_static_malloc(" + str2(4 * nume + 4 + 1) + "*ptrsz);" '+1 is for the lock
    'create _MEM lock
    PRINT #13, "new_mem_lock();"
    PRINT #13, "mem_lock_tmp->type=4;"
    PRINT #13, "((ptrszint*)" + n$ + ")[" + str2(4 * nume + 4 + 1 - 1) + "]=(ptrszint)mem_lock_tmp;"
END IF

'generate sizestr$ & elesizestr$ (both are used in various places in following code)
sizestr$ = ""
FOR i = 1 TO nume
    IF i <> 1 THEN sizestr$ = sizestr$ + "*"
    sizestr$ = sizestr$ + n$ + "[" + str2(i * 4 - 4 + 5) + "]"
NEXT
elesizestr$ = sizestr$ 'elements in entire array
sizestr$ = sizestr$ + "*" + bytesperelement$ 'bytes in entire array



'------------------STATIC ARRAY CREATION--------------------------------
IF staticarray THEN
    'STATIC memory
    PRINT #13, sd$ 'setup new array dimension ranges
    'Example of sd$ for DIM a(10):
    '__ARRAY_SINGLE_A[4]= 0 ;
    '__ARRAY_SINGLE_A[5]=( 10 )-__ARRAY_SINGLE_A[4]+1;
    '__ARRAY_SINGLE_A[6]=1;
    IF cmem AND stringarray = 0 THEN
        'Note: A string array's pointers are always stored in 64bit memory
        '(static)CONVENTINAL memory
        PRINT #13, n$ + "[0]=(ptrszint)cmem_static_pointer;"
        'alloc mem & check if static memory boundry has oversteped dynamic memory boundry
        PRINT #13, "if ((cmem_static_pointer+=((" + sizestr$ + ")+15)&-16)>cmem_dynamic_base) error(257);"
        '64K check
        PRINT #13, "if ((" + sizestr$ + ")>65536) error(257);"
        'clear array
        PRINT #13, "memset((void*)(" + n$ + "[0]),0," + sizestr$ + ");"
        'set flags
        PRINT #13, n$ + "[2]=1+2+4;" 'init+static+cmem
    ELSE
        '64BIT MEMORY
        PRINT #13, n$ + "[0]=(ptrszint)mem_static_malloc(" + sizestr$ + ");"
        IF stringarray THEN
            'Init string pointers in the array
            PRINT #13, "tmp_long=" + elesizestr$ + ";"
            PRINT #13, "while(tmp_long--){"
            IF cmem THEN
                PRINT #13, "((uint64*)(" + n$ + "[0]))[tmp_long]=(uint64)qbs_new_cmem(0,0);"
            ELSE
                PRINT #13, "((uint64*)(" + n$ + "[0]))[tmp_long]=(uint64)qbs_new(0,0);"
            END IF
            PRINT #13, "}"
        ELSE
            'clear array
            PRINT #13, "memset((void*)(" + n$ + "[0]),0," + sizestr$ + ");"
        END IF
        PRINT #13, n$ + "[2]=1+2;" 'init+static
    END IF
    'Close static array desc
    PRINT #13, "}"
    allocarray = nume + 65536
END IF
'------------------END OF STATIC ARRAY CREATION-------------------------

'------------------DYNAMIC ARRAY CREATION-------------------------------
IF staticarray = 0 THEN

    IF undefined = 0 THEN



        'Generate error if array is static
        f12$ = f12$ + CRLF + "if (" + n$ + "[2]&2){" 'static array
        f12$ = f12$ + CRLF + "error(10);" 'cannot redefine a static array!
        f12$ = f12$ + CRLF + "}else{"
        'Note: Array is either undefined or dynamically defined at this point


        'REDIM (not DIM) must be used to redefine an array
        IF redimoption = 0 THEN
            f12$ = f12$ + CRLF + "if (" + n$ + "[2]&1){" 'array is defined
            f12$ = f12$ + CRLF + "error(10);" 'cannot redefine an array without using REDIM!
            f12$ = f12$ + CRLF + "}else{"
        ELSE
            '--------ERASE EXISTING ARRAY IF NECESSARY--------

            'IMPORTANT: If array is not going to be preserved, it should be cleared before
            '           creating the new array for memory considerations

            'refresh lock ID (_MEM)
            f12$ = f12$ + CRLF + "((mem_lock*)((ptrszint*)" + n$ + ")[" + str2(4 * nume + 4 + 1 - 1) + "])->id=(++mem_lock_id);"

            IF redimoption = 2 THEN
                f12$ = f12$ + CRLF + "static int32 preserved_elements;" 'must be put here for scope considerations
            END IF

            'If array is defined, it must be destroyed first
            f12$ = f12$ + CRLF + "if (" + n$ + "[2]&1){" 'array is defined

            IF redimoption = 2 THEN
                f12$ = f12$ + CRLF + "preserved_elements=" + elesizestr$ + ";"
                GOTO skiperase
            END IF

            'Note: pointers to strings must be freed before array can be freed
            IF stringarray THEN
                f12$ = f12$ + CRLF + "tmp_long=" + elesizestr$ + ";"
                f12$ = f12$ + CRLF + "while(tmp_long--) qbs_free((qbs*)((uint64*)(" + n$ + "[0]))[tmp_long]);"
            END IF
            'Free array's memory
            IF stringarray THEN
                'Note: String arrays are never in cmem
                f12$ = f12$ + CRLF + "free((void*)(" + n$ + "[0]));"
            ELSE
                'Note: Array may be in cmem!
                f12$ = f12$ + CRLF + "if (" + n$ + "[2]&4){" 'array is in cmem
                f12$ = f12$ + CRLF + "cmem_dynamic_free((uint8*)(" + n$ + "[0]));"
                f12$ = f12$ + CRLF + "}else{" 'not in cmem
                f12$ = f12$ + CRLF + "free((void*)(" + n$ + "[0]));"
                f12$ = f12$ + CRLF + "}"
            END IF

            skiperase:

            f12$ = f12$ + CRLF + "}" 'array was defined
            IF redimoption = 2 THEN
                f12$ = f12$ + CRLF + "else preserved_elements=0;" 'if array wasn't defined, no elements are preserved
            END IF


            '--------ERASED ARRAY AS NECESSARY--------
        END IF 'redim specified


        '--------CREATE ARRAY & CLEAN-UP CODE--------
        'Overwrite existing array dimension sizes/ranges
        f12$ = f12$ + CRLF + sd$
        IF stringarray THEN

            'Note: String arrays are always created in 64bit memory

            IF redimoption = 2 THEN
                f12$ = f12$ + CRLF + "if (preserved_elements){"

                f12$ = f12$ + CRLF + "static ptrszint tmp_long2;"

                'free any qbs strings which will be lost in the realloc
                f12$ = f12$ + CRLF + "tmp_long=" + elesizestr$ + ";"
                f12$ = f12$ + CRLF + "if (tmp_long<preserved_elements){"
                f12$ = f12$ + CRLF + "for(tmp_long2=tmp_long;tmp_long2<preserved_elements;tmp_long2++) qbs_free((qbs*)((uint64*)(" + n$ + "[0]))[tmp_long2]);"
                f12$ = f12$ + CRLF + "}"
                'reallocate the array
                f12$ = f12$ + CRLF + n$ + "[0]=(ptrszint)realloc((void*)(" + n$ + "[0]),tmp_long*" + bytesperelement$ + ");"
                f12$ = f12$ + CRLF + "if (!" + n$ + "[0]) error(257);" 'not enough memory
                f12$ = f12$ + CRLF + "if (preserved_elements<tmp_long){"
                f12$ = f12$ + CRLF + "for(tmp_long2=preserved_elements;tmp_long2<tmp_long;tmp_long2++){"
                f12$ = f12$ + CRLF + "if (" + n$ + "[2]&4){" 'array is in cmem
                f12$ = f12$ + CRLF + "((uint64*)(" + n$ + "[0]))[tmp_long2]=(uint64)qbs_new_cmem(0,0);"
                f12$ = f12$ + CRLF + "}else{" 'not in cmem
                f12$ = f12$ + CRLF + "((uint64*)(" + n$ + "[0]))[tmp_long2]=(uint64)qbs_new(0,0);"
                f12$ = f12$ + CRLF + "}" 'not in cmem
                f12$ = f12$ + CRLF + "}"
                f12$ = f12$ + CRLF + "}"

                f12$ = f12$ + CRLF + "}else{"
            END IF

            '1. Create string array
            f12$ = f12$ + CRLF + n$ + "[0]=(ptrszint)malloc(" + sizestr$ + ");"
            f12$ = f12$ + CRLF + "if (!" + n$ + "[0]) error(257);" 'not enough memory
            f12$ = f12$ + CRLF + n$ + "[2]|=1;" 'ADD initialized flag
            f12$ = f12$ + CRLF + "tmp_long=" + elesizestr$ + ";"


            'init individual strings
            f12$ = f12$ + CRLF + "if (" + n$ + "[2]&4){" 'array is in cmem
            f12$ = f12$ + CRLF + "while(tmp_long--) ((uint64*)(" + n$ + "[0]))[tmp_long]=(uint64)qbs_new_cmem(0,0);"
            f12$ = f12$ + CRLF + "}else{" 'not in cmem
            f12$ = f12$ + CRLF + "while(tmp_long--) ((uint64*)(" + n$ + "[0]))[tmp_long]=(uint64)qbs_new(0,0);"
            f12$ = f12$ + CRLF + "}" 'not in cmem

            IF redimoption = 2 THEN
                f12$ = f12$ + CRLF + "}"
            END IF


            '2. Generate "clean up" code (called when EXITING A SUB/FUNCTION)
            IF arraydesc = 0 THEN 'only add for first declaration of the array
                PRINT #19, "if (" + n$ + "[2]&1){" 'initialized?
                PRINT #19, "tmp_long=" + elesizestr$ + ";"
                PRINT #19, "while(tmp_long--) qbs_free((qbs*)((uint64*)(" + n$ + "[0]))[tmp_long]);"
                PRINT #19, "free((void*)(" + n$ + "[0]));"
                PRINT #19, "}"
                'free lock (_MEM)
                PRINT #19, "free_mem_lock( (mem_lock*)((ptrszint*)" + n$ + ")[" + str2(4 * nume + 4 + 1 - 1) + "] );"
            END IF


        ELSE 'not string array

            '1. Create array
            f12$ = f12$ + CRLF + "if (" + n$ + "[2]&4){" 'array will be in cmem

            IF redimoption = 2 THEN
                f12$ = f12$ + CRLF + "if (preserved_elements){"

                'reallocation method
                'backup data
                f12$ = f12$ + CRLF + "memcpy(redim_preserve_cmem_buffer,(void*)(" + n$ + "[0]),preserved_elements*" + bytesperelement$ + ");"
                'free old array
                f12$ = f12$ + CRLF + "cmem_dynamic_free((uint8*)(" + n$ + "[0]));"
                f12$ = f12$ + CRLF + "tmp_long=" + elesizestr$ + ";"
                f12$ = f12$ + CRLF + n$ + "[0]=(ptrszint)cmem_dynamic_malloc(tmp_long*" + bytesperelement$ + ");"
                f12$ = f12$ + CRLF + "memcpy((void*)(" + n$ + "[0]),redim_preserve_cmem_buffer,preserved_elements*" + bytesperelement$ + ");"
                f12$ = f12$ + CRLF + "if (preserved_elements<tmp_long) ZeroMemory(((uint8*)(" + n$ + "[0]))+preserved_elements*" + bytesperelement$ + ",(tmp_long*" + bytesperelement$ + ")-(preserved_elements*" + bytesperelement$ + "));"

                f12$ = f12$ + CRLF + "}else{"
            END IF

            'standard cmem method
            f12$ = f12$ + CRLF + n$ + "[0]=(ptrszint)cmem_dynamic_malloc(" + sizestr$ + ");"
            'clear array
            f12$ = f12$ + CRLF + "memset((void*)(" + n$ + "[0]),0," + sizestr$ + ");"

            IF redimoption = 2 THEN
                f12$ = f12$ + CRLF + "}"
            END IF


            f12$ = f12$ + CRLF + "}else{" 'not in cmem

            IF redimoption = 2 THEN
                f12$ = f12$ + CRLF + "if (preserved_elements){"
                'reallocation method
                f12$ = f12$ + CRLF + "tmp_long=" + elesizestr$ + ";"
                f12$ = f12$ + CRLF + n$ + "[0]=(ptrszint)realloc((void*)(" + n$ + "[0]),tmp_long*" + bytesperelement$ + ");"
                f12$ = f12$ + CRLF + "if (!" + n$ + "[0]) error(257);" 'not enough memory
                f12$ = f12$ + CRLF + "if (preserved_elements<tmp_long) ZeroMemory(((uint8*)(" + n$ + "[0]))+preserved_elements*" + bytesperelement$ + ",(tmp_long*" + bytesperelement$ + ")-(preserved_elements*" + bytesperelement$ + "));"

                f12$ = f12$ + CRLF + "}else{"
            END IF
            'standard allocation method
            f12$ = f12$ + CRLF + n$ + "[0]=(ptrszint)calloc(" + sizestr$ + ",1);"
            f12$ = f12$ + CRLF + "if (!" + n$ + "[0]) error(257);" 'not enough memory
            IF redimoption = 2 THEN
                f12$ = f12$ + CRLF + "}"
            END IF

            f12$ = f12$ + CRLF + "}" 'not in cmem
            f12$ = f12$ + CRLF + n$ + "[2]|=1;" 'ADD initialized flag

            '2. Generate "clean up" code (called when EXITING A SUB/FUNCTION)
            IF arraydesc = 0 THEN 'only add for first declaration of the array
                PRINT #19, "if (" + n$ + "[2]&1){" 'initialized?
                PRINT #19, "if (" + n$ + "[2]&4){" 'array is in cmem
                PRINT #19, "cmem_dynamic_free((uint8*)(" + n$ + "[0]));"
                PRINT #19, "}else{"
                PRINT #19, "free((void*)(" + n$ + "[0]));"
                PRINT #19, "}" 'cmem
                PRINT #19, "}" 'init
                'free lock (_MEM)
                PRINT #19, "free_mem_lock( (mem_lock*)((ptrszint*)" + n$ + ")[" + str2(4 * nume + 4 + 1 - 1) + "] );"
            END IF
        END IF 'not string array

    END IF 'undefined=0

    '----FINISH ARRAY DESCRIPTOR IF DEFINING FOR THE FIRST TIME----
    IF arraydesc = 0 THEN
        'Note: Array is init as undefined (& possibly a cmem flag)
        IF cmem THEN PRINT #13, n$ + "[2]=4;" ELSE PRINT #13, n$ + "[2]=0;"
        'set dimensions as undefined
        FOR i = 1 TO nume
            b = i * 4
            PRINT #13, n$ + "[" + str2(b) + "]=2147483647;" 'base
            PRINT #13, n$ + "[" + str2(b + 1) + "]=0;" 'num. index
            PRINT #13, n$ + "[" + str2(b + 2) + "]=0;" 'multiplier
        NEXT
        IF stringarray THEN
            'set array's data offset to the offset of the offset to nothingstring
            PRINT #13, n$ + "[0]=(ptrszint)&nothingstring;"
        ELSE
            'set array's data offset to "nothing"
            PRINT #13, n$ + "[0]=(ptrszint)nothingvalue;"
        END IF
        PRINT #13, "}" 'close array descriptor
    END IF 'arraydesc = 0

    IF undefined = 0 THEN

        IF redimoption = 0 THEN f12$ = f12$ + CRLF + "}" 'if REDIM not specified the above is conditional
        f12$ = f12$ + CRLF + "}" 'not static

    END IF 'undefined=0

    allocarray = nume
    IF undefined = -1 THEN allocarray = -1

END IF

IF autoary = 0 THEN
    IF dimoption = 3 THEN 'STATIC a(100) puts creation code in main
        fh = FREEFILE: OPEN tmpdir$ + "maindata.txt" FOR APPEND AS #fh: PRINT #fh, f12$: CLOSE #fh
    ELSE
        PRINT #12, f12$
    END IF
END IF

'[8] offset of data
'[8] reserved (could be used to store a bit offset)
'(the following repeats depending on the number of elements)
'[4] base-offset
'[4] number of indexes
'[4] multiplier (the last multiplier doesn't actually exist)
'[4] reserved

dimshared = dimsharedlast

tlayout$ = l$
END FUNCTION

FUNCTION arrayreference$ (indexes$, typ)
arrayprocessinghappened = 1
'*returns an array reference: idnumber�index$
'*does not take into consideration the type of the array

'*expects array id to be passed in the global id structure





idnumber$ = str2(currentid)

DIM id2 AS idstruct

id2 = id

a$ = indexes$
typ = id2.arraytype + ISARRAY + ISREFERENCE
n$ = RTRIM$(id2.callname)

IF a$ = "" THEN 'no indexes passed eg. a()
    r$ = "0"
    GOTO gotarrayindex
END IF

n = numelements(a$)

'find number of elements supplied
elements = 1
b = 0
FOR i = 1 TO n
    a = ASC(getelement(a$, i))
    IF a = 40 THEN b = b + 1
    IF a = 41 THEN b = b - 1
    IF a = 44 AND b = 0 THEN elements = elements + 1
NEXT

IF id2.arrayelements = -1 THEN
    IF arrayelementslist(currentid) <> 0 AND elements <> arrayelementslist(currentid) THEN Give_Error "Cannot change the number of elements an array has!": EXIT FUNCTION
    IF elements = 1 THEN id2.arrayelements = 1: ids(currentid).arrayelements = 1 'lucky guess
    arrayelementslist(currentid) = elements
ELSE
    IF elements <> id2.arrayelements THEN Give_Error "Cannot change the number of elements an array has!": EXIT FUNCTION
END IF

curarg = 1
firsti = 1
FOR i = 1 TO n
    l$ = getelement(a$, i)
    IF l$ = "(" THEN b = b + 1
    IF l$ = ")" THEN b = b - 1
    IF (l$ = "," AND b = 0) OR (i = n) THEN
        IF i = n THEN
            IF l$ = "," THEN Give_Error "Array index missing": EXIT FUNCTION
            e$ = evaluatetotyp(getelements$(a$, firsti, i), 64&)
            IF Error_Happened THEN EXIT FUNCTION
        ELSE
            e$ = evaluatetotyp(getelements$(a$, firsti, i - 1), 64&)
            IF Error_Happened THEN EXIT FUNCTION
        END IF
        IF e$ = "" THEN Give_Error "Array index missing": EXIT FUNCTION
        argi = (elements - curarg) * 4 + 4
        IF curarg = 1 THEN
            r$ = r$ + "array_check((" + e$ + ")-" + n$ + "[" + str2(argi) + "]," + n$ + "[" + str2(argi + 1) + "])+"
        ELSE
            r$ = r$ + "array_check((" + e$ + ")-" + n$ + "[" + str2(argi) + "]," + n$ + "[" + str2(argi + 1) + "])*" + n$ + "[" + str2(argi + 2) + "]+"
        END IF
        firsti = i + 1
        curarg = curarg + 1
    END IF
NEXT
r$ = LEFT$(r$, LEN(r$) - 1) 'remove trailing +
gotarrayindex:

r$ = idnumber$ + sp3 + r$
arrayreference$ = r$
'PRINT "arrayreference returning:" + r$

END FUNCTION

SUB assign (a$, n)
FOR i = 1 TO n
    c = ASC(getelement$(a$, i))
    IF c = 40 THEN b = b + 1 '(
    IF c = 41 THEN b = b - 1 ')
    IF c = 61 AND b = 0 THEN '=
        IF i = 1 THEN Give_Error "Expected ... =": EXIT SUB
        IF i = n THEN Give_Error "Expected = ...": EXIT SUB

        a2$ = fixoperationorder(getelements$(a$, 1, i - 1))
        IF Error_Happened THEN EXIT SUB
        l$ = tlayout$ + sp + "=" + sp

        'note: evaluating a2$ will fail if it is setting a function's return value without this check (as the function, not the return-variable) will be found by evaluate)
        IF i = 2 THEN 'lhs has only 1 element
            try = findid(a2$)
            IF Error_Happened THEN EXIT SUB
            DO WHILE try
                IF id.t THEN
                    IF subfuncn = id.insubfuncn THEN 'avoid global before local
                        IF (id.t AND ISUDT) = 0 THEN
                            makeidrefer a2$, typ
                            GOTO assignsimplevariable
                        END IF
                    END IF
                END IF
                IF try = 2 THEN findanotherid = 1: try = findid(a2$) ELSE try = 0
                IF Error_Happened THEN EXIT SUB
            LOOP
        END IF

        a2$ = evaluate$(a2$, typ): IF Error_Happened THEN EXIT SUB
        assignsimplevariable:
        IF (typ AND ISREFERENCE) = 0 THEN Give_Error "Expected variable =": EXIT SUB
        setrefer a2$, typ, getelements$(a$, i + 1, n), 0
        IF Error_Happened THEN EXIT SUB
        tlayout$ = l$ + tlayout$

        EXIT SUB

    END IF '=,b=0
NEXT
Give_Error "Expected =": EXIT SUB
END SUB

SUB clearid
id = cleariddata
END SUB

SUB closemain
xend

PRINT #12, "return;"

PRINT #12, "}"
PRINT #15, "}" 'end case
PRINT #15, "}"
PRINT #15, "error(3);" 'no valid return possible

closedmain = 1

END SUB

FUNCTION countelements (a$)
n = numelements(a$)
c = 1
FOR i = 1 TO n
    e$ = getelement$(a$, i)
    IF e$ = "(" THEN b = b + 1
    IF e$ = ")" THEN b = b - 1
    IF b < 0 THEN Give_Error "Unexpected ) encountered": EXIT FUNCTION
    IF e$ = "," AND b = 0 THEN c = c + 1
NEXT
countelements = c
END FUNCTION



FUNCTION dim2 (varname$, typ2$, method, elements$)

'notes: (DO NOT REMOVE THESE IMPORTANT USAGE NOTES)
'
'(shared)dimsfarray: Creates an ID only (no C++ code)
'                    Adds an index/'link' to the sub/function's argument
'                        ID.sfid=glinkid
'                        ID.sfarg=glinkarg
'                    Sets arrayelements=-1 'unknown' (if elements$="?") otherwise val(elements$)
'                    ***Does not refer to arrayelementslist()***
'
'(argument)method: 0 being created by a DIM name AS type
'                  1 being created by a DIM name+symbol
'                  or automatically without the use of DIM
'
'elements$="?": (see also dimsfarray for that special case)
'               Checks arrayelementslist() and;
'               if unknown(=0), creates an ID only
'               if known, creates a DYNAMIC array's C++ initialization code so it can be used later

typ$ = typ2$
dim2 = 1 'success

IF Debug THEN PRINT #9, "dim2 called", method

cvarname$ = varname$
l$ = cvarname$
varname$ = UCASE$(varname$)

IF dimsfarray = 1 THEN f = 0 ELSE f = 1

IF dimstatic <> 0 AND dimshared = 0 THEN
    'name will have include the sub/func name in its scope
    'variable/array will be created in main on startup
    defdatahandle = 18 'change from 13 to 18(global.txt)
    CLOSE #13: OPEN tmpdir$ + "maindata.txt" FOR APPEND AS #13
    CLOSE #19: OPEN tmpdir$ + "mainfree.txt" FOR APPEND AS #19
END IF


scope2$ = module$ + "_" + subfunc$ + "_"
'Note: when REDIMing a SHARED array in dynamic memory scope2$ must be modified

IF LEN(typ$) = 0 THEN Give_Error "DIM2: No type specified!": EXIT FUNCTION

'UDT
'is it a udt?
FOR i = 1 TO lasttype
    IF typ$ = RTRIM$(udtxname(i)) THEN
        dim2typepassback$ = RTRIM$(udtxcname(i))

        n$ = "UDT_" + varname$

        'array of UDTs
        IF elements$ <> "" THEN
            arraydesc = 0
            IF f = 1 THEN
                try = findid(varname$)
                IF Error_Happened THEN EXIT FUNCTION
                DO WHILE try
                    IF (id.arraytype) THEN
                        l$ = RTRIM$(id.cn)
                        arraydesc = currentid: scope2$ = scope$
                        EXIT DO
                    END IF
                    IF try = 2 THEN findanotherid = 1: try = findid(varname$) ELSE try = 0
                    IF Error_Happened THEN EXIT FUNCTION
                LOOP
            END IF
            n$ = scope2$ + "ARRAY_" + n$
            bits = udtxsize(i)
            IF udtxbytealign(i) THEN
                IF bits MOD 8 THEN bits = bits + 8 - (bits MOD 8)
            END IF

            IF f = 1 THEN

                IF LEN(elements$) = 1 AND ASC(elements$) = 63 THEN '"?"
                    E = arrayelementslist(idn + 1): IF E THEN elements$ = elements$ + str2$(E) 'eg. "?3" for a 3 dimensional array
                END IF
                nume = allocarray(n$, elements$, -bits)
                IF Error_Happened THEN EXIT FUNCTION
                l$ = l$ + sp + tlayout$
                IF arraydesc THEN GOTO dim2exitfunc
                clearid

            ELSE
                clearid
                IF elements$ = "?" THEN
                    nume = -1
                    id.linkid = glinkid
                    id.linkarg = glinkarg
                ELSE
                    nume = VAL(elements$)
                END IF
            END IF

            id.arraytype = UDTTYPE + i
            IF cmemlist(idn + 1) THEN id.arraytype = id.arraytype + ISINCONVENTIONALMEMORY
            id.n = cvarname$

            IF nume > 65536 THEN nume = nume - 65536: id.staticarray = 1

            id.arrayelements = nume
            id.callname = n$
            regid
            IF Error_Happened THEN EXIT FUNCTION
            GOTO dim2exitfunc
        END IF

        'not an array of UDTs
        bits = udtxsize(i): bytes = bits \ 8
        IF bits MOD 8 THEN
            bytes = bytes + 1
        END IF
        n$ = scope2$ + n$
        IF f THEN PRINT #defdatahandle, "void *" + n$ + "=NULL;"
        clearid
        id.n = cvarname$
        id.t = UDTTYPE + i
        IF cmemlist(idn + 1) THEN
            id.t = id.t + ISINCONVENTIONALMEMORY
            IF f THEN PRINT #13, "if(" + n$ + "==NULL){"
            IF f THEN PRINT #13, "cmem_sp-=" + str2(bytes) + ";"
            IF f THEN PRINT #13, "if (cmem_sp<qbs_cmem_sp) error(257);"
            IF f THEN PRINT #13, n$ + "=(void*)(dblock+cmem_sp);"
            IF f THEN PRINT #13, "memset(" + n$ + ",0," + str2(bytes) + ");"
            IF f THEN PRINT #13, "}"
        ELSE
            IF f THEN PRINT #13, "if(" + n$ + "==NULL){"
            IF f THEN PRINT #13, n$ + "=(void*)mem_static_malloc(" + str2$(bytes) + ");"
            IF f THEN PRINT #13, "memset(" + n$ + ",0," + str2(bytes) + ");"
            IF f THEN PRINT #13, "}"
        END IF
        regid
        IF Error_Happened THEN EXIT FUNCTION
        GOTO dim2exitfunc
    END IF
NEXT i
'it isn't a udt

typ$ = symbol2fulltypename$(typ$)
IF Error_Happened THEN EXIT FUNCTION

'check if _UNSIGNED was specified
unsgn = 0
IF LEFT$(typ$, 10) = "_UNSIGNED " THEN
    unsgn = 1
    typ$ = RIGHT$(typ$, LEN(typ$) - 10)
    IF LEN(typ$) = 0 THEN Give_Error "Expected more type information after _UNSIGNED!": EXIT FUNCTION
END IF

n$ = "" 'n$ is assumed to be "" after branching into the code for each type

IF LEFT$(typ$, 6) = "STRING" THEN

    IF LEN(typ$) > 6 THEN
        IF LEFT$(typ$, 9) <> "STRING * " THEN Give_Error "Expected STRING * number/constant": EXIT FUNCTION

        c$ = RIGHT$(typ$, LEN(typ$) - 9)

        'constant check 2011
        hashfound = 0
        hashname$ = c$
        hashchkflags = HASHFLAG_CONSTANT
        hashres = HashFindRev(hashname$, hashchkflags, hashresflags, hashresref)
        DO WHILE hashres
            IF constsubfunc(hashresref) = subfuncn OR constsubfunc(hashresref) = 0 THEN
                IF constdefined(hashresref) THEN
                    hashfound = 1
                    EXIT DO
                END IF
            END IF
            IF hashres <> 1 THEN hashres = HashFindCont(hashresflags, hashresref) ELSE hashres = 0
        LOOP
        IF hashfound THEN
            i2 = hashresref
            t = consttype(i2)
            IF t AND ISSTRING THEN Give_Error "Expected STRING * numeric-constant": EXIT FUNCTION
            'convert value to general formats
            IF t AND ISFLOAT THEN
                v## = constfloat(i2)
                v&& = v##
                v~&& = v&&
            ELSE
                IF t AND ISUNSIGNED THEN
                    v~&& = constuinteger(i2)
                    v&& = v~&&
                    v## = v&&
                ELSE
                    v&& = constinteger(i2)
                    v## = v&&
                    v~&& = v&&
                END IF
            END IF
            IF v&& < 1 OR v&& > 9999999999 THEN Give_Error "STRING * out-of-range constant": EXIT FUNCTION
            bytes = v&&
            GOTO constantlenstr
        END IF

        IF isuinteger(c$) = 0 THEN Give_Error "Number/Constant expected after *": EXIT FUNCTION
        IF LEN(c$) > 10 THEN Give_Error "Too many characters in number after *": EXIT FUNCTION
        bytes = VAL(c$)
        IF bytes = 0 THEN Give_Error "Cannot create a fixed string of length 0": EXIT FUNCTION
        constantlenstr:
        n$ = "STRING" + str2(bytes) + "_" + varname$

        'array of fixed length strings
        IF elements$ <> "" THEN
            arraydesc = 0
            IF f = 1 THEN
                try = findid(varname$ + "$")
                IF Error_Happened THEN EXIT FUNCTION
                DO WHILE try
                    IF (id.arraytype) THEN
                        l$ = RTRIM$(id.cn)
                        arraydesc = currentid: scope2$ = scope$
                        EXIT DO
                    END IF
                    IF try = 2 THEN findanotherid = 1: try = findid(varname$ + "$") ELSE try = 0
                    IF Error_Happened THEN EXIT FUNCTION
                LOOP
            END IF
            n$ = scope2$ + "ARRAY_" + n$

            'nume = allocarray(n$, elements$, bytes)
            'IF arraydesc THEN goto dim2exitfunc 'id already exists!
            'clearid

            IF f = 1 THEN

                IF LEN(elements$) = 1 AND ASC(elements$) = 63 THEN '"?"
                    E = arrayelementslist(idn + 1): IF E THEN elements$ = elements$ + str2$(E) 'eg. "?3" for a 3 dimensional array
                END IF
                nume = allocarray(n$, elements$, bytes)
                IF Error_Happened THEN EXIT FUNCTION
                l$ = l$ + sp + tlayout$
                IF arraydesc THEN GOTO dim2exitfunc
                clearid

            ELSE
                clearid
                IF elements$ = "?" THEN
                    nume = -1
                    id.linkid = glinkid
                    id.linkarg = glinkarg
                ELSE
                    nume = VAL(elements$)
                END IF
            END IF

            id.arraytype = STRINGTYPE + ISFIXEDLENGTH
            IF cmemlist(idn + 1) THEN id.arraytype = id.arraytype + ISINCONVENTIONALMEMORY
            id.n = cvarname$
            IF nume > 65536 THEN nume = nume - 65536: id.staticarray = 1

            id.arrayelements = nume
            id.callname = n$
            id.tsize = bytes
            IF method = 0 THEN
                id.mayhave = "$" + str2(bytes)
            END IF
            IF method = 1 THEN
                id.musthave = "$" + str2(bytes)
            END IF
            regid
            IF Error_Happened THEN EXIT FUNCTION
            GOTO dim2exitfunc
        END IF

        'standard fixed length string
        n$ = scope2$ + n$
        IF f THEN PRINT #defdatahandle, "qbs *" + n$ + "=NULL;"
        IF f THEN PRINT #19, "qbs_free(" + n$ + ");" 'so descriptor can be freed
        clearid
        id.n = cvarname$
        id.t = STRINGTYPE + ISFIXEDLENGTH
        IF cmemlist(idn + 1) THEN
            id.t = id.t + ISINCONVENTIONALMEMORY
            IF f THEN PRINT #13, "if(" + n$ + "==NULL){"
            IF f THEN PRINT #13, "cmem_sp-=" + str2(bytes) + ";"
            IF f THEN PRINT #13, "if (cmem_sp<qbs_cmem_sp) error(257);"
            IF f THEN PRINT #13, n$ + "=qbs_new_fixed((uint8*)(dblock+cmem_sp)," + str2(bytes) + ",0);"
            IF f THEN PRINT #13, "memset(" + n$ + "->chr,0," + str2(bytes) + ");"
            IF f THEN PRINT #13, "}"
        ELSE
            IF f THEN PRINT #13, "if(" + n$ + "==NULL){"
            o$ = "(uint8*)mem_static_malloc(" + str2$(bytes) + ")"
            IF f THEN PRINT #13, n$ + "=qbs_new_fixed(" + o$ + "," + str2$(bytes) + ",0);"
            IF f THEN PRINT #13, "memset(" + n$ + "->chr,0," + str2$(bytes) + ");"
            IF f THEN PRINT #13, "}"
        END IF
        id.tsize = bytes
        IF method = 0 THEN
            id.mayhave = "$" + str2(bytes)
        END IF
        IF method = 1 THEN
            id.musthave = "$" + str2(bytes)
        END IF
        regid
        IF Error_Happened THEN EXIT FUNCTION
        GOTO dim2exitfunc
    END IF

    'variable length string processing
    n$ = "STRING_" + varname$

    'array of variable length strings
    IF elements$ <> "" THEN
        arraydesc = 0
        IF f = 1 THEN
            try = findid(varname$ + "$")
            IF Error_Happened THEN EXIT FUNCTION
            DO WHILE try
                IF (id.arraytype) THEN
                    l$ = RTRIM$(id.cn)
                    arraydesc = currentid: scope2$ = scope$
                    EXIT DO
                END IF
                IF try = 2 THEN findanotherid = 1: try = findid(varname$ + "$") ELSE try = 0
                IF Error_Happened THEN EXIT FUNCTION
            LOOP
        END IF
        n$ = scope2$ + "ARRAY_" + n$

        'nume = allocarray(n$, elements$, -2147483647) '-2147483647=STRING
        'IF arraydesc THEN goto dim2exitfunc 'id already exists!
        'clearid

        IF f = 1 THEN

            IF LEN(elements$) = 1 AND ASC(elements$) = 63 THEN '"?"
                E = arrayelementslist(idn + 1): IF E THEN elements$ = elements$ + str2$(E) 'eg. "?3" for a 3 dimensional array
            END IF
            nume = allocarray(n$, elements$, -2147483647)
            IF Error_Happened THEN EXIT FUNCTION
            l$ = l$ + sp + tlayout$
            IF arraydesc THEN GOTO dim2exitfunc
            clearid

        ELSE
            clearid
            IF elements$ = "?" THEN
                nume = -1
                id.linkid = glinkid
                id.linkarg = glinkarg
            ELSE
                nume = VAL(elements$)
            END IF
        END IF

        id.n = cvarname$
        id.arraytype = STRINGTYPE
        IF cmemlist(idn + 1) THEN id.arraytype = id.arraytype + ISINCONVENTIONALMEMORY
        IF nume > 65536 THEN nume = nume - 65536: id.staticarray = 1

        id.arrayelements = nume
        id.callname = n$
        IF method = 0 THEN
            id.mayhave = "$"
        END IF
        IF method = 1 THEN
            id.musthave = "$"
        END IF
        regid
        IF Error_Happened THEN EXIT FUNCTION
        GOTO dim2exitfunc
    END IF

    'standard variable length string
    n$ = scope2$ + n$
    clearid
    id.n = cvarname$
    id.t = STRINGTYPE
    IF cmemlist(idn + 1) THEN
        IF f THEN PRINT #defdatahandle, "qbs *" + n$ + "=NULL;"
        IF f THEN PRINT #13, "if (!" + n$ + ")" + n$ + "=qbs_new_cmem(0,0);"
        id.t = id.t + ISINCONVENTIONALMEMORY
    ELSE
        IF f THEN PRINT #defdatahandle, "qbs *" + n$ + "=NULL;"
        IF f THEN PRINT #13, "if (!" + n$ + ")" + n$ + "=qbs_new(0,0);"
    END IF
    IF f THEN PRINT #19, "qbs_free(" + n$ + ");"
    IF method = 0 THEN
        id.mayhave = "$"
    END IF
    IF method = 1 THEN
        id.musthave = "$"
    END IF
    regid
    IF Error_Happened THEN EXIT FUNCTION
    GOTO dim2exitfunc
END IF

IF LEFT$(typ$, 4) = "_BIT" THEN
    IF LEN(typ$) > 4 THEN
        IF LEFT$(typ$, 7) <> "_BIT * " THEN Give_Error "Expected _BIT * number": EXIT FUNCTION
        c$ = RIGHT$(typ$, LEN(typ$) - 7)
        IF isuinteger(c$) = 0 THEN Give_Error "Number expected after *": EXIT FUNCTION
        IF LEN(c$) > 2 THEN Give_Error "Too many characters in number after *": EXIT FUNCTION
        bits = VAL(c$)
        IF bits = 0 THEN Give_Error "Cannot create a bit variable of size 0 bits": EXIT FUNCTION
        IF bits > 57 THEN Give_Error "Cannot create a bit variable of size > 24 bits": EXIT FUNCTION
    ELSE
        bits = 1
    END IF
    IF bits <= 32 THEN ct$ = "int32" ELSE ct$ = "int64"
    IF unsgn THEN n$ = "U": ct$ = "u" + ct$
    n$ = n$ + "BIT" + str2(bits) + "_" + varname$

    'array of bit-length variables
    IF elements$ <> "" THEN
        arraydesc = 0
        cmps$ = varname$: IF unsgn THEN cmps$ = cmps$ + "~"
        cmps$ = cmps$ + "`" + str2(bits)
        IF f = 1 THEN
            try = findid(cmps$)
            IF Error_Happened THEN EXIT FUNCTION
            DO WHILE try
                IF (id.arraytype) THEN
                    l$ = RTRIM$(id.cn)
                    arraydesc = currentid: scope2$ = scope$
                    EXIT DO
                END IF
                IF try = 2 THEN findanotherid = 1: try = findid(cmps$) ELSE try = 0
                IF Error_Happened THEN EXIT FUNCTION
            LOOP
        END IF
        n$ = scope2$ + "ARRAY_" + n$

        'nume = allocarray(n$, elements$, -bits) 'passing a negative element size signifies bits not bytes
        'IF arraydesc THEN goto dim2exitfunc 'id already exists!
        'clearid

        IF f = 1 THEN

            IF LEN(elements$) = 1 AND ASC(elements$) = 63 THEN '"?"
                E = arrayelementslist(idn + 1): IF E THEN elements$ = elements$ + str2$(E) 'eg. "?3" for a 3 dimensional array
            END IF
            nume = allocarray(n$, elements$, -bits)
            IF Error_Happened THEN EXIT FUNCTION
            l$ = l$ + sp + tlayout$
            IF arraydesc THEN GOTO dim2exitfunc
            clearid

        ELSE
            clearid
            IF elements$ = "?" THEN
                nume = -1
                id.linkid = glinkid
                id.linkarg = glinkarg
            ELSE
                nume = VAL(elements$)
            END IF
        END IF

        id.n = cvarname$
        id.arraytype = BITTYPE - 1 + bits
        IF unsgn THEN id.arraytype = id.arraytype + ISUNSIGNED
        IF cmemlist(idn + 1) THEN id.arraytype = id.arraytype + ISINCONVENTIONALMEMORY
        IF nume > 65536 THEN nume = nume - 65536: id.staticarray = 1

        id.arrayelements = nume
        id.callname = n$
        IF method = 0 THEN
            IF unsgn THEN id.mayhave = "~`" + str2(bits) ELSE id.mayhave = "`" + str2(bits)
        END IF
        IF method = 1 THEN
            IF unsgn THEN id.musthave = "~`" + str2(bits) ELSE id.musthave = "`" + str2(bits)
        END IF
        regid
        IF Error_Happened THEN EXIT FUNCTION
        GOTO dim2exitfunc
    END IF
    'standard bit-length variable
    n$ = scope2$ + n$
    PRINT #defdatahandle, ct$ + " *" + n$ + "=NULL;"
    PRINT #13, "if(" + n$ + "==NULL){"
    PRINT #13, "cmem_sp-=4;"
    PRINT #13, "if (cmem_sp<qbs_cmem_sp) error(257);"
    PRINT #13, n$ + "=(" + ct$ + "*)(dblock+cmem_sp);"
    PRINT #13, "*" + n$ + "=0;"
    PRINT #13, "}"
    clearid
    id.n = cvarname$
    id.t = BITTYPE - 1 + bits + ISINCONVENTIONALMEMORY: IF unsgn THEN id.t = id.t + ISUNSIGNED
    IF method = 0 THEN
        IF unsgn THEN id.mayhave = "~`" + str2(bits) ELSE id.mayhave = "`" + str2(bits)
    END IF
    IF method = 1 THEN
        IF unsgn THEN id.musthave = "~`" + str2(bits) ELSE id.musthave = "`" + str2(bits)
    END IF
    regid
    IF Error_Happened THEN EXIT FUNCTION
    GOTO dim2exitfunc
END IF

IF typ$ = "_BYTE" THEN
    ct$ = "int8"
    IF unsgn THEN n$ = "U": ct$ = "u" + ct$
    n$ = n$ + "BYTE_" + varname$
    IF elements$ <> "" THEN
        arraydesc = 0
        cmps$ = varname$: IF unsgn THEN cmps$ = cmps$ + "~"
        cmps$ = cmps$ + "%%"
        IF f = 1 THEN
            try = findid(cmps$)
            IF Error_Happened THEN EXIT FUNCTION
            DO WHILE try
                IF (id.arraytype) THEN
                    l$ = RTRIM$(id.cn)
                    arraydesc = currentid: scope2$ = scope$
                    EXIT DO
                END IF
                IF try = 2 THEN findanotherid = 1: try = findid(cmps$) ELSE try = 0
                IF Error_Happened THEN EXIT FUNCTION
            LOOP

        END IF
        n$ = scope2$ + "ARRAY_" + n$

        'nume = allocarray(n$, elements$, 1)
        'IF arraydesc THEN goto dim2exitfunc
        'clearid

        IF f = 1 THEN

            IF LEN(elements$) = 1 AND ASC(elements$) = 63 THEN '"?"
                E = arrayelementslist(idn + 1): IF E THEN elements$ = elements$ + str2$(E) 'eg. "?3" for a 3 dimensional array
            END IF
            nume = allocarray(n$, elements$, 1)
            IF Error_Happened THEN EXIT FUNCTION
            l$ = l$ + sp + tlayout$
            IF arraydesc THEN GOTO dim2exitfunc
            clearid

        ELSE
            clearid
            IF elements$ = "?" THEN
                nume = -1
                id.linkid = glinkid
                id.linkarg = glinkarg
            ELSE
                nume = VAL(elements$)
            END IF
        END IF

        id.arraytype = BYTETYPE: IF unsgn THEN id.arraytype = id.arraytype + ISUNSIGNED
        IF cmemlist(idn + 1) THEN id.arraytype = id.arraytype + ISINCONVENTIONALMEMORY
        IF nume > 65536 THEN nume = nume - 65536: id.staticarray = 1

        id.arrayelements = nume
        id.callname = n$
    ELSE
        n$ = scope2$ + n$
        clearid
        id.t = BYTETYPE: IF unsgn THEN id.t = id.t + ISUNSIGNED
        IF f = 1 THEN PRINT #defdatahandle, ct$ + " *" + n$ + "=NULL;"
        IF f = 1 THEN PRINT #13, "if(" + n$ + "==NULL){"
        IF cmemlist(idn + 1) THEN
            id.t = id.t + ISINCONVENTIONALMEMORY
            IF f = 1 THEN PRINT #13, "cmem_sp-=1;"
            IF f = 1 THEN PRINT #13, n$ + "=(" + ct$ + "*)(dblock+cmem_sp);"
            IF f = 1 THEN PRINT #13, "if (cmem_sp<qbs_cmem_sp) error(257);"
        ELSE
            IF f = 1 THEN PRINT #13, n$ + "=(" + ct$ + "*)mem_static_malloc(1);"
        END IF
        IF f = 1 THEN PRINT #13, "*" + n$ + "=0;"
        IF f = 1 THEN PRINT #13, "}"
    END IF
    id.n = cvarname$
    IF method = 0 THEN
        IF unsgn THEN id.mayhave = "~%%" ELSE id.mayhave = "%%"
    END IF
    IF method = 1 THEN
        IF unsgn THEN id.musthave = "~%%" ELSE id.musthave = "%%"
    END IF
    regid
    IF Error_Happened THEN EXIT FUNCTION
    GOTO dim2exitfunc
END IF

IF typ$ = "INTEGER" THEN
    ct$ = "int16"
    IF unsgn THEN n$ = "U": ct$ = "u" + ct$
    n$ = n$ + "INTEGER_" + varname$

    IF elements$ <> "" THEN
        arraydesc = 0
        cmps$ = varname$: IF unsgn THEN cmps$ = cmps$ + "~"
        cmps$ = cmps$ + "%"
        IF f = 1 THEN
            try = findid(cmps$)
            IF Error_Happened THEN EXIT FUNCTION
            DO WHILE try
                IF (id.arraytype) THEN
                    l$ = RTRIM$(id.cn)
                    arraydesc = currentid: scope2$ = scope$
                    EXIT DO
                END IF
                IF try = 2 THEN findanotherid = 1: try = findid(cmps$) ELSE try = 0
                IF Error_Happened THEN EXIT FUNCTION
            LOOP
        END IF
        n$ = scope2$ + "ARRAY_" + n$

        IF f = 1 THEN

            IF LEN(elements$) = 1 AND ASC(elements$) = 63 THEN '"?"
                E = arrayelementslist(idn + 1): IF E THEN elements$ = elements$ + str2$(E) 'eg. "?3" for a 3 dimensional array
            END IF
            nume = allocarray(n$, elements$, 2)
            IF Error_Happened THEN EXIT FUNCTION
            l$ = l$ + sp + tlayout$
            IF arraydesc THEN GOTO dim2exitfunc
            clearid

        ELSE
            clearid
            IF elements$ = "?" THEN
                nume = -1
                id.linkid = glinkid
                id.linkarg = glinkarg
            ELSE
                nume = VAL(elements$)
            END IF
        END IF


        id.arraytype = INTEGERTYPE: IF unsgn THEN id.arraytype = id.arraytype + ISUNSIGNED
        IF cmemlist(idn + 1) THEN id.arraytype = id.arraytype + ISINCONVENTIONALMEMORY
        IF nume > 65536 THEN nume = nume - 65536: id.staticarray = 1

        id.arrayelements = nume
        id.callname = n$
    ELSE
        n$ = scope2$ + n$
        clearid
        id.t = INTEGERTYPE: IF unsgn THEN id.t = id.t + ISUNSIGNED
        IF f = 1 THEN PRINT #defdatahandle, ct$ + " *" + n$ + "=NULL;"
        IF f = 1 THEN PRINT #13, "if(" + n$ + "==NULL){"
        IF cmemlist(idn + 1) THEN
            id.t = id.t + ISINCONVENTIONALMEMORY
            IF f = 1 THEN PRINT #13, "cmem_sp-=2;"
            IF f = 1 THEN PRINT #13, n$ + "=(" + ct$ + "*)(dblock+cmem_sp);"
            IF f = 1 THEN PRINT #13, "if (cmem_sp<qbs_cmem_sp) error(257);"
        ELSE
            IF f = 1 THEN PRINT #13, n$ + "=(" + ct$ + "*)mem_static_malloc(2);"
        END IF
        IF f = 1 THEN PRINT #13, "*" + n$ + "=0;"
        IF f = 1 THEN PRINT #13, "}"
    END IF
    id.n = cvarname$
    IF method = 0 THEN
        IF unsgn THEN id.mayhave = "~%" ELSE id.mayhave = "%"
    END IF
    IF method = 1 THEN
        IF unsgn THEN id.musthave = "~%" ELSE id.musthave = "%"
    END IF
    regid
    IF Error_Happened THEN EXIT FUNCTION
    GOTO dim2exitfunc
END IF








IF typ$ = "_OFFSET" THEN
    ct$ = "ptrszint"
    IF unsgn THEN n$ = "U": ct$ = "u" + ct$
    n$ = n$ + "OFFSET_" + varname$
    IF elements$ <> "" THEN
        arraydesc = 0
        cmps$ = varname$: IF unsgn THEN cmps$ = cmps$ + "~"
        cmps$ = cmps$ + "%&"
        IF f = 1 THEN
            try = findid(cmps$)
            IF Error_Happened THEN EXIT FUNCTION
            DO WHILE try
                IF (id.arraytype) THEN
                    l$ = RTRIM$(id.cn)
                    arraydesc = currentid: scope2$ = scope$
                    EXIT DO
                END IF
                IF try = 2 THEN findanotherid = 1: try = findid(cmps$) ELSE try = 0
                IF Error_Happened THEN EXIT FUNCTION
            LOOP
        END IF
        n$ = scope2$ + "ARRAY_" + n$

        IF f = 1 THEN

            IF LEN(elements$) = 1 AND ASC(elements$) = 63 THEN '"?"
                E = arrayelementslist(idn + 1): IF E THEN elements$ = elements$ + str2$(E) 'eg. "?3" for a 3 dimensional array
            END IF
            nume = allocarray(n$, elements$, OS_BITS \ 8)
            IF Error_Happened THEN EXIT FUNCTION
            l$ = l$ + sp + tlayout$
            IF arraydesc THEN GOTO dim2exitfunc
            clearid

        ELSE
            clearid
            IF elements$ = "?" THEN
                nume = -1
                id.linkid = glinkid
                id.linkarg = glinkarg
            ELSE
                nume = VAL(elements$)
            END IF
        END IF

        id.arraytype = OFFSETTYPE: IF unsgn THEN id.arraytype = id.arraytype + ISUNSIGNED
        IF cmemlist(idn + 1) THEN id.arraytype = id.arraytype + ISINCONVENTIONALMEMORY
        IF nume > 65536 THEN nume = nume - 65536: id.staticarray = 1

        id.arrayelements = nume
        id.callname = n$
    ELSE
        n$ = scope2$ + n$
        clearid
        id.t = OFFSETTYPE: IF unsgn THEN id.t = id.t + ISUNSIGNED
        IF f = 1 THEN PRINT #defdatahandle, ct$ + " *" + n$ + "=NULL;"
        IF f = 1 THEN PRINT #13, "if(" + n$ + "==NULL){"
        IF cmemlist(idn + 1) THEN
            id.t = id.t + ISINCONVENTIONALMEMORY
            IF f = 1 THEN PRINT #13, "cmem_sp-=" + str2(OS_BITS \ 8) + ";"
            IF f = 1 THEN PRINT #13, n$ + "=(" + ct$ + "*)(dblock+cmem_sp);"
            IF f = 1 THEN PRINT #13, "if (cmem_sp<qbs_cmem_sp) error(257);"
        ELSE
            IF f = 1 THEN PRINT #13, n$ + "=(" + ct$ + "*)mem_static_malloc(" + str2(OS_BITS \ 8) + ");"
        END IF
        IF f = 1 THEN PRINT #13, "*" + n$ + "=0;"
        IF f = 1 THEN PRINT #13, "}"
    END IF
    id.n = cvarname$
    IF method = 0 THEN
        IF unsgn THEN id.mayhave = "~%&" ELSE id.mayhave = "%&"
    END IF
    IF method = 1 THEN
        IF unsgn THEN id.musthave = "~%&" ELSE id.musthave = "%&"
    END IF
    regid
    IF Error_Happened THEN EXIT FUNCTION
    GOTO dim2exitfunc
END IF

IF typ$ = "LONG" THEN
    ct$ = "int32"
    IF unsgn THEN n$ = "U": ct$ = "u" + ct$
    n$ = n$ + "LONG_" + varname$
    IF elements$ <> "" THEN
        arraydesc = 0
        cmps$ = varname$: IF unsgn THEN cmps$ = cmps$ + "~"
        cmps$ = cmps$ + "&"
        IF f = 1 THEN
            try = findid(cmps$)
            IF Error_Happened THEN EXIT FUNCTION
            DO WHILE try
                IF (id.arraytype) THEN
                    l$ = RTRIM$(id.cn)
                    arraydesc = currentid: scope2$ = scope$
                    EXIT DO
                END IF
                IF try = 2 THEN findanotherid = 1: try = findid(cmps$) ELSE try = 0
                IF Error_Happened THEN EXIT FUNCTION
            LOOP
        END IF
        n$ = scope2$ + "ARRAY_" + n$

        'nume = allocarray(n$, elements$, 4)
        'IF arraydesc THEN goto dim2exitfunc
        'clearid

        IF f = 1 THEN

            IF LEN(elements$) = 1 AND ASC(elements$) = 63 THEN '"?"
                E = arrayelementslist(idn + 1): IF E THEN elements$ = elements$ + str2$(E) 'eg. "?3" for a 3 dimensional array
            END IF
            nume = allocarray(n$, elements$, 4)
            IF Error_Happened THEN EXIT FUNCTION
            l$ = l$ + sp + tlayout$
            IF arraydesc THEN GOTO dim2exitfunc
            clearid

        ELSE
            clearid
            IF elements$ = "?" THEN
                nume = -1
                id.linkid = glinkid
                id.linkarg = glinkarg
            ELSE
                nume = VAL(elements$)
            END IF
        END IF

        id.arraytype = LONGTYPE: IF unsgn THEN id.arraytype = id.arraytype + ISUNSIGNED
        IF cmemlist(idn + 1) THEN id.arraytype = id.arraytype + ISINCONVENTIONALMEMORY
        IF nume > 65536 THEN nume = nume - 65536: id.staticarray = 1

        id.arrayelements = nume
        id.callname = n$
    ELSE
        n$ = scope2$ + n$
        clearid
        id.t = LONGTYPE: IF unsgn THEN id.t = id.t + ISUNSIGNED
        IF f = 1 THEN PRINT #defdatahandle, ct$ + " *" + n$ + "=NULL;"
        IF f = 1 THEN PRINT #13, "if(" + n$ + "==NULL){"
        IF cmemlist(idn + 1) THEN
            id.t = id.t + ISINCONVENTIONALMEMORY
            IF f = 1 THEN PRINT #13, "cmem_sp-=4;"
            IF f = 1 THEN PRINT #13, n$ + "=(" + ct$ + "*)(dblock+cmem_sp);"
            IF f = 1 THEN PRINT #13, "if (cmem_sp<qbs_cmem_sp) error(257);"
        ELSE
            IF f = 1 THEN PRINT #13, n$ + "=(" + ct$ + "*)mem_static_malloc(4);"
        END IF
        IF f = 1 THEN PRINT #13, "*" + n$ + "=0;"
        IF f = 1 THEN PRINT #13, "}"
    END IF
    id.n = cvarname$
    IF method = 0 THEN
        IF unsgn THEN id.mayhave = "~&" ELSE id.mayhave = "&"
    END IF
    IF method = 1 THEN
        IF unsgn THEN id.musthave = "~&" ELSE id.musthave = "&"
    END IF
    regid
    IF Error_Happened THEN EXIT FUNCTION
    GOTO dim2exitfunc
END IF

IF typ$ = "_INTEGER64" THEN
    ct$ = "int64"
    IF unsgn THEN n$ = "U": ct$ = "u" + ct$
    n$ = n$ + "INTEGER64_" + varname$
    IF elements$ <> "" THEN
        arraydesc = 0
        cmps$ = varname$: IF unsgn THEN cmps$ = cmps$ + "~"
        cmps$ = cmps$ + "&&"
        IF f = 1 THEN
            try = findid(cmps$)
            IF Error_Happened THEN EXIT FUNCTION
            DO WHILE try
                IF (id.arraytype) THEN
                    l$ = RTRIM$(id.cn)
                    arraydesc = currentid: scope2$ = scope$
                    EXIT DO
                END IF
                IF try = 2 THEN findanotherid = 1: try = findid(cmps$) ELSE try = 0
                IF Error_Happened THEN EXIT FUNCTION
            LOOP
        END IF
        n$ = scope2$ + "ARRAY_" + n$

        'nume = allocarray(n$, elements$, 8)
        'IF arraydesc THEN goto dim2exitfunc
        'clearid

        IF f = 1 THEN

            IF LEN(elements$) = 1 AND ASC(elements$) = 63 THEN '"?"
                E = arrayelementslist(idn + 1): IF E THEN elements$ = elements$ + str2$(E) 'eg. "?3" for a 3 dimensional array
            END IF
            nume = allocarray(n$, elements$, 8)
            IF Error_Happened THEN EXIT FUNCTION
            l$ = l$ + sp + tlayout$
            IF arraydesc THEN GOTO dim2exitfunc
            clearid

        ELSE
            clearid
            IF elements$ = "?" THEN
                nume = -1
                id.linkid = glinkid
                id.linkarg = glinkarg
            ELSE
                nume = VAL(elements$)
            END IF
        END IF

        id.arraytype = INTEGER64TYPE: IF unsgn THEN id.arraytype = id.arraytype + ISUNSIGNED
        IF cmemlist(idn + 1) THEN id.arraytype = id.arraytype + ISINCONVENTIONALMEMORY
        IF nume > 65536 THEN nume = nume - 65536: id.staticarray = 1

        id.arrayelements = nume
        id.callname = n$
    ELSE
        n$ = scope2$ + n$
        clearid
        id.t = INTEGER64TYPE: IF unsgn THEN id.t = id.t + ISUNSIGNED
        IF f = 1 THEN PRINT #defdatahandle, ct$ + " *" + n$ + "=NULL;"
        IF f = 1 THEN PRINT #13, "if(" + n$ + "==NULL){"
        IF cmemlist(idn + 1) THEN
            id.t = id.t + ISINCONVENTIONALMEMORY
            IF f = 1 THEN PRINT #13, "cmem_sp-=8;"
            IF f = 1 THEN PRINT #13, n$ + "=(" + ct$ + "*)(dblock+cmem_sp);"
            IF f = 1 THEN PRINT #13, "if (cmem_sp<qbs_cmem_sp) error(257);"
        ELSE
            IF f = 1 THEN PRINT #13, n$ + "=(" + ct$ + "*)mem_static_malloc(8);"
        END IF
        IF f = 1 THEN PRINT #13, "*" + n$ + "=0;"
        IF f = 1 THEN PRINT #13, "}"
    END IF
    id.n = cvarname$
    IF method = 0 THEN
        IF unsgn THEN id.mayhave = "~&&" ELSE id.mayhave = "&&"
    END IF
    IF method = 1 THEN
        IF unsgn THEN id.musthave = "~&&" ELSE id.musthave = "&&"
    END IF
    regid
    IF Error_Happened THEN EXIT FUNCTION
    GOTO dim2exitfunc
END IF

IF unsgn = 1 THEN Give_Error "Type cannot be unsigned": EXIT FUNCTION

IF typ$ = "SINGLE" THEN
    ct$ = "float"
    n$ = n$ + "SINGLE_" + varname$
    IF elements$ <> "" THEN
        arraydesc = 0
        cmps$ = varname$ + "!"
        IF f = 1 THEN
            try = findid(cmps$)
            IF Error_Happened THEN EXIT FUNCTION
            DO WHILE try
                IF (id.arraytype) THEN
                    l$ = RTRIM$(id.cn)
                    arraydesc = currentid: scope2$ = scope$
                    EXIT DO
                END IF
                IF try = 2 THEN findanotherid = 1: try = findid(cmps$) ELSE try = 0
                IF Error_Happened THEN EXIT FUNCTION
            LOOP
        END IF
        n$ = scope2$ + "ARRAY_" + n$

        'nume = allocarray(n$, elements$, 4)
        'IF arraydesc THEN goto dim2exitfunc
        'clearid

        IF f = 1 THEN

            IF LEN(elements$) = 1 AND ASC(elements$) = 63 THEN '"?"
                E = arrayelementslist(idn + 1): IF E THEN elements$ = elements$ + str2$(E) 'eg. "?3" for a 3 dimensional array
            END IF
            nume = allocarray(n$, elements$, 4)
            IF Error_Happened THEN EXIT FUNCTION
            l$ = l$ + sp + tlayout$
            IF arraydesc THEN GOTO dim2exitfunc
            clearid

        ELSE
            clearid
            IF elements$ = "?" THEN
                nume = -1
                id.linkid = glinkid
                id.linkarg = glinkarg
            ELSE
                nume = VAL(elements$)
            END IF
        END IF

        id.arraytype = SINGLETYPE
        IF cmemlist(idn + 1) THEN id.arraytype = id.arraytype + ISINCONVENTIONALMEMORY
        IF nume > 65536 THEN nume = nume - 65536: id.staticarray = 1

        id.arrayelements = nume
        id.callname = n$
    ELSE
        n$ = scope2$ + n$
        clearid
        id.t = SINGLETYPE
        IF f = 1 THEN PRINT #defdatahandle, ct$ + " *" + n$ + "=NULL;"
        IF f = 1 THEN PRINT #13, "if(" + n$ + "==NULL){"
        IF cmemlist(idn + 1) THEN
            id.t = id.t + ISINCONVENTIONALMEMORY
            IF f = 1 THEN PRINT #13, "cmem_sp-=4;"
            IF f = 1 THEN PRINT #13, n$ + "=(" + ct$ + "*)(dblock+cmem_sp);"
            IF f = 1 THEN PRINT #13, "if (cmem_sp<qbs_cmem_sp) error(257);"
        ELSE
            IF f = 1 THEN PRINT #13, n$ + "=(" + ct$ + "*)mem_static_malloc(4);"
        END IF
        IF f = 1 THEN PRINT #13, "*" + n$ + "=0;"
        IF f = 1 THEN PRINT #13, "}"
    END IF
    id.n = cvarname$
    IF method = 0 THEN
        id.mayhave = "!"
    END IF
    IF method = 1 THEN
        id.musthave = "!"
    END IF
    regid
    IF Error_Happened THEN EXIT FUNCTION
    GOTO dim2exitfunc
END IF

IF typ$ = "DOUBLE" THEN
    ct$ = "double"
    n$ = n$ + "DOUBLE_" + varname$
    IF elements$ <> "" THEN
        arraydesc = 0
        cmps$ = varname$ + "#"
        IF f = 1 THEN
            try = findid(cmps$)
            IF Error_Happened THEN EXIT FUNCTION
            DO WHILE try
                IF (id.arraytype) THEN
                    l$ = RTRIM$(id.cn)
                    arraydesc = currentid: scope2$ = scope$
                    EXIT DO
                END IF
                IF try = 2 THEN findanotherid = 1: try = findid(cmps$) ELSE try = 0
                IF Error_Happened THEN EXIT FUNCTION
            LOOP
        END IF
        n$ = scope2$ + "ARRAY_" + n$

        'nume = allocarray(n$, elements$, 8)
        'IF arraydesc THEN goto dim2exitfunc
        'clearid

        IF f = 1 THEN

            IF LEN(elements$) = 1 AND ASC(elements$) = 63 THEN '"?"
                E = arrayelementslist(idn + 1): IF E THEN elements$ = elements$ + str2$(E) 'eg. "?3" for a 3 dimensional array
            END IF
            nume = allocarray(n$, elements$, 8)
            IF Error_Happened THEN EXIT FUNCTION
            l$ = l$ + sp + tlayout$
            IF arraydesc THEN GOTO dim2exitfunc
            clearid

        ELSE
            clearid
            IF elements$ = "?" THEN
                nume = -1
                id.linkid = glinkid
                id.linkarg = glinkarg
            ELSE
                nume = VAL(elements$)
            END IF
        END IF

        id.arraytype = DOUBLETYPE
        IF cmemlist(idn + 1) THEN id.arraytype = id.arraytype + ISINCONVENTIONALMEMORY
        IF nume > 65536 THEN nume = nume - 65536: id.staticarray = 1

        id.arrayelements = nume
        id.callname = n$
    ELSE
        n$ = scope2$ + n$
        clearid
        id.t = DOUBLETYPE
        IF f = 1 THEN PRINT #defdatahandle, ct$ + " *" + n$ + "=NULL;"
        IF f = 1 THEN PRINT #13, "if(" + n$ + "==NULL){"
        IF cmemlist(idn + 1) THEN
            id.t = id.t + ISINCONVENTIONALMEMORY
            IF f = 1 THEN PRINT #13, "cmem_sp-=8;"
            IF f = 1 THEN PRINT #13, n$ + "=(" + ct$ + "*)(dblock+cmem_sp);"
            IF f = 1 THEN PRINT #13, "if (cmem_sp<qbs_cmem_sp) error(257);"
        ELSE
            IF f = 1 THEN PRINT #13, n$ + "=(" + ct$ + "*)mem_static_malloc(8);"
        END IF
        IF f = 1 THEN PRINT #13, "*" + n$ + "=0;"
        IF f = 1 THEN PRINT #13, "}"
    END IF
    id.n = cvarname$
    IF method = 0 THEN
        id.mayhave = "#"
    END IF
    IF method = 1 THEN
        id.musthave = "#"
    END IF
    regid
    IF Error_Happened THEN EXIT FUNCTION
    GOTO dim2exitfunc
END IF

IF typ$ = "_FLOAT" THEN
    ct$ = "long double"
    n$ = n$ + "FLOAT_" + varname$
    IF elements$ <> "" THEN
        arraydesc = 0
        cmps$ = varname$ + "##"
        IF f = 1 THEN
            try = findid(cmps$)
            IF Error_Happened THEN EXIT FUNCTION
            DO WHILE try
                IF (id.arraytype) THEN
                    l$ = RTRIM$(id.cn)
                    arraydesc = currentid: scope2$ = scope$
                    EXIT DO
                END IF
                IF try = 2 THEN findanotherid = 1: try = findid(cmps$) ELSE try = 0
                IF Error_Happened THEN EXIT FUNCTION
            LOOP
        END IF
        n$ = scope2$ + "ARRAY_" + n$

        'nume = allocarray(n$, elements$, 32)
        'IF arraydesc THEN goto dim2exitfunc
        'clearid

        IF f = 1 THEN

            IF LEN(elements$) = 1 AND ASC(elements$) = 63 THEN '"?"
                E = arrayelementslist(idn + 1): IF E THEN elements$ = elements$ + str2$(E) 'eg. "?3" for a 3 dimensional array
            END IF
            nume = allocarray(n$, elements$, 32)
            IF Error_Happened THEN EXIT FUNCTION
            l$ = l$ + sp + tlayout$
            IF arraydesc THEN GOTO dim2exitfunc
            clearid

        ELSE
            clearid
            IF elements$ = "?" THEN
                nume = -1
                id.linkid = glinkid
                id.linkarg = glinkarg
            ELSE
                nume = VAL(elements$)
            END IF
        END IF

        id.arraytype = FLOATTYPE
        IF cmemlist(idn + 1) THEN id.arraytype = id.arraytype + ISINCONVENTIONALMEMORY
        IF nume > 65536 THEN nume = nume - 65536: id.staticarray = 1

        id.arrayelements = nume
        id.callname = n$
    ELSE
        n$ = scope2$ + n$
        clearid
        id.t = FLOATTYPE
        IF f THEN PRINT #defdatahandle, ct$ + " *" + n$ + "=NULL;"
        IF f THEN PRINT #13, "if(" + n$ + "==NULL){"
        IF cmemlist(idn + 1) THEN
            id.t = id.t + ISINCONVENTIONALMEMORY
            IF f THEN PRINT #13, "cmem_sp-=32;"
            IF f THEN PRINT #13, n$ + "=(" + ct$ + "*)(dblock+cmem_sp);"
            IF f THEN PRINT #13, "if (cmem_sp<qbs_cmem_sp) error(257);"
        ELSE
            IF f THEN PRINT #13, n$ + "=(" + ct$ + "*)mem_static_malloc(32);"
        END IF
        IF f THEN PRINT #13, "*" + n$ + "=0;"
        IF f THEN PRINT #13, "}"
    END IF
    id.n = cvarname$
    IF method = 0 THEN
        id.mayhave = "##"
    END IF
    IF method = 1 THEN
        id.musthave = "##"
    END IF
    regid
    IF Error_Happened THEN EXIT FUNCTION
    GOTO dim2exitfunc
END IF

Give_Error "Unknown type": EXIT FUNCTION
dim2exitfunc:

IF dimsfarray THEN
    ids(idn).sfid = glinkid
    ids(idn).sfarg = glinkarg
END IF

'restore STATIC state
IF dimstatic <> 0 AND dimshared = 0 THEN
    defdatahandle = 13
    CLOSE #13: OPEN tmpdir$ + "data" + str2$(subfuncn) + ".txt" FOR APPEND AS #13
    CLOSE #19: OPEN tmpdir$ + "free" + str2$(subfuncn) + ".txt" FOR APPEND AS #19
END IF

tlayout$ = l$

END FUNCTION


FUNCTION udtreference$ (o$, a$, typ AS LONG)
'UDT REFERENCE FORMAT
'idno|udtno|udtelementno|byteoffset
'     ^udt of the element, not of the id

obak$ = o$

'PRINT "called udtreference!"


r$ = str2$(currentid) + sp3


o = 0 'the fixed/known part of the offset

incmem = 0
IF id.t THEN
    u = id.t AND 511
    IF id.t AND ISINCONVENTIONALMEMORY THEN incmem = 1
ELSE
    u = id.arraytype AND 511
    IF id.arraytype AND ISINCONVENTIONALMEMORY THEN incmem = 1
END IF
E = 0

n = numelements(a$)
IF n = 0 THEN GOTO fulludt

i = 1
udtfindelenext:
IF getelement$(a$, i) <> "." THEN Give_Error "Expected .": EXIT FUNCTION
i = i + 1
n$ = getelement$(a$, i)
nsym$ = removesymbol(n$): IF LEN(nsym$) THEN ntyp = typname2typ(nsym$): ntypsize = typname2typsize
IF Error_Happened THEN EXIT FUNCTION

IF n$ = "" THEN Give_Error "Expected .elementname": EXIT FUNCTION
udtfindele:
IF E = 0 THEN E = udtxnext(u) ELSE E = udtenext(E)
IF E = 0 THEN Give_Error "Element not defined": EXIT FUNCTION
n2$ = RTRIM$(udtename(E))
IF udtebytealign(E) THEN
    IF o MOD 8 THEN o = o + (8 - (o MOD 8))
END IF

IF n$ <> n2$ THEN
    'increment fixed offset
    o = o + udtesize(E)
    GOTO udtfindele
END IF

'check symbol after element's name (if given) is correct
IF LEN(nsym$) THEN

    IF udtetype(E) AND ISUDT THEN Give_Error "Invalid symbol after user defined type": EXIT FUNCTION
    IF ntyp <> udtetype(E) OR ntypsize <> udtetypesize(E) THEN
        IF nsym$ = "$" AND ((udtetype(E) AND ISFIXEDLENGTH) <> 0) THEN GOTO correctsymbol
        Give_Error "Incorrect symbol after element name": EXIT FUNCTION
    END IF
END IF
correctsymbol:

'Move into another UDT structure?
IF i <> n THEN
    IF (udtetype(E) AND ISUDT) = 0 THEN Give_Error "Expected user defined type": EXIT FUNCTION
    u = udtetype(E) AND 511
    E = 0
    i = i + 1
    GOTO udtfindelenext
END IF

'Change e reference to u�0 reference?
IF udtetype(E) AND ISUDT THEN
    u = udtetype(E) AND 511
    E = 0
END IF

fulludt:

r$ = r$ + str2$(u) + sp3 + str2$(E) + sp3

IF o MOD 8 THEN Give_Error "QB64 cannot handle bit offsets within user defined types yet": EXIT FUNCTION
o = o \ 8

IF o$ <> "" THEN
    IF o <> 0 THEN 'dont add an unnecessary 0
        o$ = o$ + "+" + str2$(o)
    END IF
ELSE
    o$ = str2$(o)
END IF

r$ = r$ + o$

udtreference$ = r$
typ = udtetype(E) + ISUDT + ISREFERENCE

'full udt override:
IF E = 0 THEN
    typ = u + ISUDT + ISREFERENCE
END IF

IF obak$ <> "" THEN typ = typ + ISARRAY
IF incmem THEN typ = typ + ISINCONVENTIONALMEMORY

'print "UDTREF:"+r$+","+str2$(typ)

END FUNCTION

FUNCTION evaluate$ (a2$, typ AS LONG)
DIM block(1000) AS STRING
DIM evaledblock(1000) AS INTEGER
DIM blocktype(1000) AS LONG
'typ IS A RETURN VALUE
'''DIM cli(15) AS INTEGER
a$ = a2$
typ = -1

IF Debug THEN PRINT #9, "evaluating:[" + a2$ + "]"






'''cl$ = classify(a$)

blockn = 0
n = numelements(a$)
b = 0 'bracketting level
FOR i = 1 TO n

    reevaluate:




    l$ = getelement(a$, i)


    IF Debug THEN PRINT #9, "#*#*#* reevaluating:" + l$, i


    IF i <> n THEN nextl$ = getelement(a$, i + 1) ELSE nextl$ = ""

    '''getclass cl$, i, cli()

    IF b = 0 THEN 'don't evaluate anything within brackets

        IF Debug THEN PRINT #9, l$

        l2$ = l$ 'pure version of l$
        FOR try_method = 1 TO 4
            l$ = l2$
            IF try_method = 2 OR try_method = 4 THEN
                IF Error_Happened THEN EXIT FUNCTION
                dtyp$ = removesymbol(l$): IF Error_Happened THEN dtyp$ = "": Error_Happened = 0
                IF LEN(dtyp$) = 0 THEN
                    IF isoperator(l$) = 0 THEN
                        IF isvalidvariable(l$) THEN
                            IF LEFT$(l$, 1) = "_" THEN v = 27 ELSE v = ASC(UCASE$(l$)) - 64
                            l$ = l$ + defineextaz(v)
                        END IF
                    END IF
                ELSE
                    l$ = l2$
                END IF
            END IF
            try = findid(l$)
            IF Error_Happened THEN EXIT FUNCTION
            DO WHILE try

                IF Debug THEN PRINT #9, try

                'is l$ an array?
                IF nextl$ = "(" THEN
                    IF id.arraytype THEN
                        IF (subfuncn = id.insubfuncn AND try_method <= 2) OR try_method >= 3 THEN
                            arrayid = currentid
                            constequation = 0
                            i2 = i + 2
                            b2 = 0
                            evalnextele3:
                            l2$ = getelement(a$, i2)
                            IF l2$ = "(" THEN b2 = b2 + 1
                            IF l2$ = ")" THEN
                                b2 = b2 - 1
                                IF b2 = -1 THEN
                                    c$ = arrayreference(getelements$(a$, i + 2, i2 - 1), typ2)
                                    IF Error_Happened THEN EXIT FUNCTION
                                    i = i2

                                    'UDT
                                    IF typ2 AND ISUDT THEN
                                        'print "arrayref returned:"+c$
                                        getid arrayid
                                        IF Error_Happened THEN EXIT FUNCTION
                                        o$ = RIGHT$(c$, LEN(c$) - INSTR(c$, sp3))
                                        'change o$ to a byte offset if necessary
                                        u = typ2 AND 511
                                        s = udtxsize(u)
                                        IF udtxbytealign(u) THEN
                                            IF s MOD 8 THEN s = s + (8 - (s MOD 8)) 'round up to nearest byte
                                            s = s \ 8
                                        END IF
                                        o$ = "(" + o$ + ")*" + str2$(s)
                                        'print "calling evaludt with o$:"+o$
                                        GOTO evaludt
                                    END IF

                                    GOTO evalednextele3
                                END IF
                            END IF
                            i2 = i2 + 1
                            GOTO evalnextele3
                            evalednextele3:
                            blockn = blockn + 1
                            block(blockn) = c$
                            evaledblock(blockn) = 2
                            blocktype(blockn) = typ2
                            IF (typ2 AND ISSTRING) THEN stringprocessinghappened = 1
                            GOTO evaled
                        END IF
                    END IF

                ELSE
                    'not followed by "("

                    'is l$ a simple variable?
                    IF id.t <> 0 AND (id.t AND ISUDT) = 0 THEN
                        IF (subfuncn = id.insubfuncn AND try_method <= 2) OR try_method >= 3 THEN
                            constequation = 0
                            blockn = blockn + 1
                            makeidrefer block(blockn), blocktype(blockn)
                            IF (blocktype(blockn) AND ISSTRING) THEN stringprocessinghappened = 1
                            evaledblock(blockn) = 2
                            GOTO evaled
                        END IF
                    END IF

                    'is l$ a UDT?
                    IF id.t AND ISUDT THEN
                        IF (subfuncn = id.insubfuncn AND try_method <= 2) OR try_method >= 3 THEN
                            constequation = 0
                            o$ = ""
                            evaludt:
                            b2 = 0
                            i3 = i + 1
                            FOR i2 = i3 TO n
                                e2$ = getelement(a$, i2)
                                IF e2$ = "(" THEN b2 = b2 + 1
                                IF b2 = 0 THEN
                                    IF e2$ = ")" OR isoperator(e2$) THEN
                                        i4 = i2 - 1
                                        GOTO gotudt
                                    END IF
                                END IF
                                IF e2$ = ")" THEN b2 = b2 - 1
                            NEXT
                            i4 = n
                            gotudt:
                            IF i4 < i3 THEN e$ = "" ELSE e$ = getelements$(a$, i3, i4)
                            'PRINT "UDTREFERENCE:";l$; e$
                            e$ = udtreference(o$, e$, typ2)
                            IF Error_Happened THEN EXIT FUNCTION
                            i = i4
                            blockn = blockn + 1
                            block(blockn) = e$
                            evaledblock(blockn) = 2
                            blocktype(blockn) = typ2
                            'is the following next necessary?
                            'IF (typ2 AND ISSTRING) THEN stringprocessinghappened = 1
                            GOTO evaled
                        END IF
                    END IF

                END IF '"(" or no "("

                'is l$ a function?
                IF id.subfunc = 1 THEN
                    constequation = 0
                    IF getelement(a$, i + 1) = "(" THEN
                        i2 = i + 2
                        b2 = 0
                        args = 1
                        evalnextele:
                        l2$ = getelement(a$, i2)
                        IF l2$ = "(" THEN b2 = b2 + 1
                        IF l2$ = ")" THEN
                            b2 = b2 - 1
                            IF b2 = -1 THEN
                                IF i2 = i + 2 THEN Give_Error "Expected (...)": EXIT FUNCTION
                                c$ = evaluatefunc(getelements$(a$, i + 2, i2 - 1), args, typ2)
                                IF Error_Happened THEN EXIT FUNCTION
                                i = i2
                                GOTO evalednextele
                            END IF
                        END IF
                        IF l2$ = "," AND b2 = 0 THEN args = args + 1
                        i2 = i2 + 1
                        GOTO evalnextele
                    ELSE
                        'no brackets
                        c$ = evaluatefunc("", 0, typ2)
                        IF Error_Happened THEN EXIT FUNCTION
                    END IF
                    evalednextele:
                    blockn = blockn + 1
                    block(blockn) = c$
                    evaledblock(blockn) = 2
                    blocktype(blockn) = typ2
                    IF (typ2 AND ISSTRING) THEN stringprocessinghappened = 1
                    GOTO evaled
                END IF

                IF try = 2 THEN findanotherid = 1: try = findid(l$) ELSE try = 0
                IF Error_Happened THEN EXIT FUNCTION
            LOOP
        NEXT 'try method (1-4)

        'assume l$ an undefined array?

        IF i <> n THEN
            IF getelement$(a$, i + 1) = "(" THEN
                IF isoperator(l$) = 0 THEN
                    IF isvalidvariable(l$) THEN
                        IF Debug THEN
                            PRINT #9, "**************"
                            PRINT #9, "about to auto-create array:" + l$, i
                            PRINT #9, "**************"
                        END IF
                        dtyp$ = removesymbol(l$)
                        IF Error_Happened THEN EXIT FUNCTION
                        'count the number of elements
                        nume = 1
                        b2 = 0
                        FOR i2 = i + 2 TO n
                            e$ = getelement(a$, i2)
                            IF e$ = "(" THEN b2 = b2 + 1
                            IF b2 = 0 AND e$ = "," THEN nume = nume + 1
                            IF e$ = ")" THEN b2 = b2 - 1
                            IF b2 = -1 THEN EXIT FOR
                        NEXT
                        fakee$ = "10": FOR i2 = 2 TO nume: fakee$ = fakee$ + sp + "," + sp + "10": NEXT
                        IF Debug THEN PRINT #9, "evaluate:creating undefined array using dim2(" + l$ + "," + dtyp$ + ",1," + fakee$ + ")"
                        IF Error_Happened THEN EXIT FUNCTION
                        olddimstatic = dimstatic
                        method = 1
                        IF subfuncn THEN
                            autoarray = 1 'move dimensioning of auto array to data???.txt from inline
                            'static array declared by STATIC name()?
                            'check if varname is on the static list
                            xi = 1
                            FOR x = 1 TO staticarraylistn
                                varname2$ = getelement$(staticarraylist, xi): xi = xi + 1
                                typ2$ = getelement$(staticarraylist, xi): xi = xi + 1
                                dimmethod2 = VAL(getelement$(staticarraylist, xi)): xi = xi + 1
                                'check if they are similar
                                IF UCASE$(l$) = UCASE$(varname2$) THEN
                                    l3$ = l2$: s$ = removesymbol(l3$)
                                    IF symbol2fulltypename$(dtyp$) = typ2$ OR (dimmethod2 = 0 AND s$ = "") THEN
                                        IF Error_Happened THEN EXIT FUNCTION
                                        'adopt properties
                                        l$ = varname2$
                                        dtyp$ = typ2$
                                        method = dimmethod2
                                        dimstatic = 3
                                    END IF 'typ
                                    IF Error_Happened THEN EXIT FUNCTION
                                END IF 'varname
                            NEXT
                        END IF 'subfuncn
                        ignore = dim2(l$, dtyp$, method, fakee$)
                        IF Error_Happened THEN EXIT FUNCTION
                        dimstatic = olddimstatic
                        IF Debug THEN PRINT #9, "#*#*#* dim2 has returned!!!"
                        GOTO reevaluate
                    END IF
                END IF
            END IF
        END IF

        l$ = l2$ 'restore l$

    END IF 'b=0

    IF l$ = "(" THEN
        IF b = 0 THEN i1 = i + 1
        b = b + 1
    END IF

    IF b = 0 THEN
        blockn = blockn + 1
        block(blockn) = l$
        evaledblock(blockn) = 0
    END IF

    IF l$ = ")" THEN
        b = b - 1
        IF b = 0 THEN
            c$ = evaluate(getelements$(a$, i1, i - 1), typ2)
            IF Error_Happened THEN EXIT FUNCTION
            IF (typ2 AND ISSTRING) THEN stringprocessinghappened = 1
            blockn = blockn + 1
            IF (typ2 AND ISPOINTER) THEN
                block(blockn) = c$
            ELSE
                block(blockn) = "(" + c$ + ")"
            END IF
            evaledblock(blockn) = 1
            blocktype(blockn) = typ2
        END IF
    END IF
    evaled:
NEXT

r$ = "" 'return value

IF Debug THEN PRINT #9, "evaluated blocks:";
FOR i = 1 TO blockn
    IF i <> blockn THEN
        IF Debug THEN PRINT #9, block(i) + CHR$(219);
    ELSE
        IF Debug THEN PRINT #9, block(i)
    END IF
NEXT



'identify any referencable values
FOR i = 1 TO blockn
    IF isoperator(block(i)) = 0 THEN
        IF evaledblock(i) = 0 THEN

            'a number?
            c = ASC(LEFT$(block(i), 1))
            IF c = 45 OR (c >= 48 AND c <= 57) THEN
                num$ = block(i)
                'a float?
                f = 0
                x = INSTR(num$, "E")
                IF x THEN
                    f = 1: blocktype(i) = SINGLETYPE - ISPOINTER
                ELSE
                    x = INSTR(num$, "D")
                    IF x THEN
                        f = 2: blocktype(i) = DOUBLETYPE - ISPOINTER
                    ELSE
                        x = INSTR(num$, "F")
                        IF x THEN
                            f = 3: blocktype(i) = FLOATTYPE - ISPOINTER
                        END IF
                    END IF
                END IF
                IF f THEN
                    'float
                    IF f = 2 OR f = 3 THEN MID$(num$, x, 1) = "E" 'D,F invalid in C++
                    IF f = 3 THEN num$ = num$ + "L" 'otherwise number is rounded to a double
                ELSE
                    'integer
                    blocktype(i) = typname2typ(removesymbol$(num$))
                    IF Error_Happened THEN EXIT FUNCTION
                    IF blocktype(i) AND ISPOINTER THEN blocktype(i) = blocktype(i) - ISPOINTER
                    IF (blocktype(i) AND 511) > 32 THEN
                        IF blocktype(i) AND ISUNSIGNED THEN num$ = num$ + "ull" ELSE num$ = num$ + "ll"
                    END IF
                END IF
                block(i) = " " + num$ + " " 'pad with spaces to avoid C++ computation errors
                evaledblock(i) = 1
                GOTO evaledblock
            END IF

            'number?
            'fc = ASC(LEFT$(block(i), 1))
            'IF fc = 45 OR (fc >= 48 AND fc <= 57) THEN '- or 0-9
            ''it's a number
            ''check for an extension, if none, assume integer
            'blocktype(i) = INTEGER64TYPE - ISPOINTER
            'tblock$ = " " + block(i)
            'IF RIGHT$(tblock$, 2) = "##" THEN blocktype(i) = FLOATTYPE - ISPOINTER: block(i) = LEFT$(block(i), LEN(block$(i)) - 2): GOTO evfltnum
            'IF RIGHT$(tblock$, 1) = "#" THEN blocktype(i) = DOUBLETYPE - ISPOINTER: block(i) = LEFT$(block(i), LEN(block$(i)) - 1): GOTO evfltnum
            'IF RIGHT$(tblock$, 1) = "!" THEN blocktype(i) = SINGLETYPE - ISPOINTER: block(i) = LEFT$(block(i), LEN(block$(i)) - 1): GOTO evfltnum
            '
            ''C++ 32bit unsigned to signed 64bit
            'IF INSTR(block(i),".")=0 THEN
            '
            'negated=0
            'if left$(block(i),1)="-" then block(i)=right$(block(i),len(block(i))-1):negated=1
            '
            'if left$(block(i),2)="0x" then 'hex
            'if len(block(i))=10 then
            'if block(i)>="0x80000000" and block(i)<="0xFFFFFFFF" then block(i)="(int64)"+block(i): goto evnum
            'end if
            'if len(block(i))>10 then block(i)=block(i)+"ll": goto evnum
            'goto evnum
            'end if
            '
            'if left$(block(i),1)="0" then 'octal
            'if len(block(i))=12 then
            'if block(i)>="020000000000" and block(i)<="037777777777" then block(i)="(int64)"+block(i): goto evnum
            'if block(i)>"037777777777" then block(i)=block(i)+"ll": goto evnum
            'end if
            'if len(block(i))>12 then block(i)=block(i)+"ll": goto evnum
            'goto evnum
            'end if
            '
            ''decimal
            'if len(block(i))=10 then
            'if block(i)>="2147483648" and block(i)<="4294967295" then block(i)="(int64)"+block(i): goto evnum
            'if block(i)>"4294967295" then block(i)=block(i)+"ll": goto evnum
            'end if
            'if len(block(i))>10 then block(i)=block(i)+"ll"
            '
            'evnum:
            '
            'if negated=1 then block(i)="-"+block(i)
            '
            'END IF
            '
            'evfltnum:
            '
            'block(i) = " " + block(i)+" "
            'evaledblock(i) = 1
            'GOTO evaledblock
            'END IF

            'a typed string in ""
            IF LEFT$(block(i), 1) = CHR$(34) THEN
                IF RIGHT$(block(i), 1) <> CHR$(34) THEN
                    block(i) = "qbs_new_txt_len(" + block(i) + ")"
                ELSE
                    block(i) = "qbs_new_txt(" + block(i) + ")"
                END IF
                blocktype(i) = ISSTRING
                evaledblock(i) = 1
                stringprocessinghappened = 1
                GOTO evaledblock
            END IF

            'create variable
            IF isvalidvariable(block(i)) THEN
                x$ = block(i)

                typ$ = removesymbol$(x$)
                IF Error_Happened THEN EXIT FUNCTION

                'add symbol extension if none given
                IF LEN(typ$) = 0 THEN
                    IF LEFT$(x$, 1) = "_" THEN v = 27 ELSE v = ASC(UCASE$(x$)) - 64
                    typ$ = defineextaz(v)
                END IF

                'check that it hasn't just been created within this loop (a=b+b)
                try = findid(x$ + typ$)
                IF Error_Happened THEN EXIT FUNCTION
                DO WHILE try
                    IF Debug THEN PRINT #9, try
                    IF id.t <> 0 AND (id.t AND ISUDT) = 0 THEN 'is x$ a simple variable?
                        GOTO simplevarfound
                    END IF
                    IF try = 2 THEN findanotherid = 1: try = findid(x$ + typ$) ELSE try = 0
                    IF Error_Happened THEN EXIT FUNCTION
                LOOP

                IF Debug THEN PRINT #9, "CREATING VARIABLE:" + x$
                retval = dim2(x$, typ$, 1, "")
                IF Error_Happened THEN EXIT FUNCTION

                simplevarfound:
                constequation = 0
                makeidrefer block(i), blocktype(i)
                IF (blocktype(i) AND ISSTRING) THEN stringprocessinghappened = 1
                IF blockn = 1 THEN
                    IF (blocktype(i) AND ISREFERENCE) THEN GOTO returnpointer
                END IF
                'reference value
                block(i) = refer(block(i), blocktype(i), 0): IF Error_Happened THEN EXIT FUNCTION
                evaledblock(i) = 1
                GOTO evaledblock
            END IF
            Give_Error "Invalid expression": EXIT FUNCTION

        ELSE
            IF (blocktype(i) AND ISREFERENCE) THEN
                IF blockn = 1 THEN GOTO returnpointer

                'if blocktype(i) and ISUDT then PRINT "UDT passed to refer by evaluate"

                block(i) = refer(block(i), blocktype(i), 0)
                IF Error_Happened THEN EXIT FUNCTION

            END IF

        END IF
    END IF
    evaledblock:
NEXT


'return a POINTER if possible
IF blockn = 1 THEN
    IF evaledblock(1) THEN
        IF (blocktype(1) AND ISREFERENCE) THEN
            returnpointer:
            IF (blocktype(1) AND ISSTRING) THEN stringprocessinghappened = 1
            IF Debug THEN PRINT #9, "evaluated reference:" + block(1)
            typ = blocktype(1)
            evaluate$ = block(1)
            EXIT FUNCTION
        END IF
    END IF
END IF
'it cannot be returned as a pointer








IF Debug THEN PRINT #9, "applying operators:";


IF typ = -1 THEN
    typ = blocktype(1) 'init typ with first blocktype


    IF isoperator(block(1)) THEN 'but what if it starts with a UNARY operator?
        typ = blocktype(2) 'init typ with second blocktype
    END IF
END IF

nonop = 0
FOR i = 1 TO blockn

    IF evaledblock(i) = 0 THEN
        isop = isoperator(block(i))
        IF isop THEN
            nonop = 0

            constequation = 0

            'operator found
            o$ = block(i)
            u = operatorusage(o$, typ, i$, lhstyp, rhstyp, result)

            IF u <> 5 THEN 'not unary
                nonop = 1
                IF i = 1 OR evaledblock(i - 1) = 0 THEN
                    IF i = 1 AND blockn = 1 AND o$ = "-" THEN Give_Error "Expected variable/value after '" + UCASE$(o$) + "'": EXIT FUNCTION 'guess - is neg in this case
                    Give_Error "Expected variable/value before '" + UCASE$(o$) + "'": EXIT FUNCTION
                END IF
            END IF
            IF i = blockn OR evaledblock(i + 1) = 0 THEN Give_Error "Expected variable/value after '" + UCASE$(o$) + "'": EXIT FUNCTION

            'lhstyp & rhstyp bit-field values
            '1=integeral
            '2=floating point
            '4=string
            '8=bool *only used for result

            oldtyp = typ
            newtyp = blocktype(i + 1)

            'IF block(i - 1) = "6" THEN
            'PRINT o$
            'PRINT oldtyp AND ISFLOAT
            'PRINT blocktype(i - 1) AND ISFLOAT
            'END
            'END IF



            'numeric->string is illegal!
            IF (typ AND ISSTRING) = 0 AND (newtyp AND ISSTRING) <> 0 THEN
                Give_Error "Cannot convert number to string": EXIT FUNCTION
            END IF

            'Offset protection: Override conversion rules for operator as necessary
            offsetmode = 0
            offsetcvi = 0
            IF (oldtyp AND ISOFFSET) <> 0 OR (newtyp AND ISOFFSET) <> 0 THEN
                offsetmode = 2
                IF newtyp AND ISOFFSET THEN
                    IF (newtyp AND ISUNSIGNED) = 0 THEN offsetmode = 1
                END IF
                IF oldtyp AND ISOFFSET THEN
                    IF (oldtyp AND ISUNSIGNED) = 0 THEN offsetmode = 1
                END IF

                'depending on the operater we may do things differently
                'the default method is convert both sides to integer first
                'but these operators are different: * / ^
                IF o$ = "*" OR o$ = "/" OR o$ = "^" THEN
                    IF o$ = "*" OR o$ = "^" THEN
                        'for mult, if either side is a float cast integers to 'long double's first
                        IF (newtyp AND ISFLOAT) <> 0 OR (oldtyp AND ISFLOAT) <> 0 THEN
                            offsetcvi = 1
                            IF (oldtyp AND ISFLOAT) = 0 THEN lhstyp = 2
                            IF (newtyp AND ISFLOAT) = 0 THEN rhstyp = 2
                        END IF
                    END IF
                    IF o$ = "/" OR o$ = "^" THEN
                        'for division or exponentials, to prevent integer division cast integers to 'long double's
                        offsetcvi = 1
                        IF (oldtyp AND ISFLOAT) = 0 THEN lhstyp = 2
                        IF (newtyp AND ISFLOAT) = 0 THEN rhstyp = 2
                    END IF
                ELSE
                    IF lhstyp AND 2 THEN lhstyp = 1 'force lhs and rhs to be integer values
                    IF rhstyp AND 2 THEN rhstyp = 1
                END IF

                IF result = 2 THEN result = 1 'force integer result
                'note: result=1 just sets typ&=64 if typ is a float

            END IF

            'STEP 1: convert oldtyp and/or newtyp if required for the operator
            'convert lhs
            IF (oldtyp AND ISSTRING) THEN
                IF (lhstyp AND 4) = 0 THEN Give_Error "Cannot convert string to number": EXIT FUNCTION
            ELSE
                'oldtyp is numeric
                IF lhstyp = 4 THEN Give_Error "Cannot convert number to string": EXIT FUNCTION
                IF (oldtyp AND ISFLOAT) THEN
                    IF (lhstyp AND 2) = 0 THEN
                        'convert float to int
                        block(i - 1) = "qbr(" + block(i - 1) + ")"
                        oldtyp = 64&
                    END IF
                ELSE
                    'oldtyp is an int
                    IF (lhstyp AND 1) = 0 THEN
                        'convert int to float
                        block(i - 1) = "((long double)(" + block(i - 1) + "))"
                        oldtyp = 256& + ISFLOAT
                    END IF
                END IF
            END IF
            'convert rhs
            IF (newtyp AND ISSTRING) THEN
                IF (rhstyp AND 4) = 0 THEN Give_Error "Cannot convert string to number": EXIT FUNCTION
            ELSE
                'newtyp is numeric
                IF rhstyp = 4 THEN Give_Error "Cannot convert number to string": EXIT FUNCTION
                IF (newtyp AND ISFLOAT) THEN
                    IF (rhstyp AND 2) = 0 THEN
                        'convert float to int
                        block(i + 1) = "qbr(" + block(i + 1) + ")"
                        newtyp = 64&
                    END IF
                ELSE
                    'newtyp is an int
                    IF (rhstyp AND 1) = 0 THEN
                        'convert int to float
                        block(i + 1) = "((long double)(" + block(i + 1) + "))"
                        newtyp = 256& + ISFLOAT
                    END IF
                END IF
            END IF

            'Reduce floating point values to common base for comparison?
            IF isop = 7 THEN 'comparitive operator
                'Corrects problems encountered such as:
                '    S = 2.1
                '    IF S = 2.1 THEN PRINT "OK" ELSE PRINT "ERROR S PRINTS AS"; S; "BUT IS SEEN BY QB64 AS..."
                '    IF S < 2.1 THEN PRINT "LESS THAN 2.1"
                'concerns:
                '1. Return value from TIMER will be reduced to a SINGLE in direct comparisons
                'solution: assess, and only apply to SINGLE variables/arrays
                '2. Comparison of a double higher/lower than single range may fail
                'solution: out of range values convert to +/-1.#INF, making comparison still possible
                IF (oldtyp AND ISFLOAT) <> 0 AND (newtyp AND ISFLOAT) <> 0 THEN 'both floating point
                    s1 = oldtyp AND 511: s2 = newtyp AND 511
                    IF s2 < s1 THEN s1 = s2
                    IF s1 = 32 THEN
                        block(i - 1) = "((float)(" + block(i - 1) + "))": oldtyp = 32& + ISFLOAT
                        block(i + 1) = "((float)(" + block(i + 1) + "))": newtyp = 32& + ISFLOAT
                    END IF
                    IF s1 = 64 THEN
                        block(i - 1) = "((double)(" + block(i - 1) + "))": oldtyp = 64& + ISFLOAT
                        block(i + 1) = "((double)(" + block(i + 1) + "))": newtyp = 64& + ISFLOAT
                    END IF
                END IF 'both floating point
            END IF 'comparitive operator

            typ = newtyp

            'STEP 2: markup typ
            '        if either side is a float, markup typ to largest float
            '        if either side is integer, markup typ
            'Note: A markup is a GUESS of what the return type will be,
            '      'result' can override this markup
            IF (oldtyp AND ISSTRING) = 0 AND (newtyp AND ISSTRING) = 0 THEN
                IF (oldtyp AND ISFLOAT) <> 0 OR (newtyp AND ISFLOAT) <> 0 THEN
                    'float
                    b = 0: IF (oldtyp AND ISFLOAT) THEN b = oldtyp AND 511
                    IF (newtyp AND ISFLOAT) THEN
                        b2 = newtyp AND 511: IF b2 > b THEN b = b2
                    END IF
                    typ = ISFLOAT + b
                ELSE
                    'integer
                    '***THIS IS THE IDEAL MARKUP FOR A 64-BIT SYSTEM***
                    'In reality 32-bit C++ only marks-up to 32-bit integers
                    b = oldtyp AND 511: b2 = newtyp AND 511: IF b2 > b THEN b = b2
                    typ = 64&
                    IF b = 64 THEN
                        IF (oldtyp AND ISUNSIGNED) <> 0 AND (newtyp AND ISUNSIGNED) <> 0 THEN typ = 64& + ISUNSIGNED
                    END IF
                END IF
            END IF

            IF result = 1 THEN
                IF (typ AND ISFLOAT) <> 0 OR (typ AND ISSTRING) <> 0 THEN typ = 64 'otherwise keep markuped integer type
            END IF
            IF result = 2 THEN
                IF (typ AND ISFLOAT) = 0 THEN typ = ISFLOAT + 256
            END IF
            IF result = 4 THEN
                typ = ISSTRING
            END IF
            IF result = 8 THEN 'bool
                typ = 32
            END IF

            'Offset protection: Force result to be an offset type with correct signage
            IF offsetmode THEN
                IF result <> 8 THEN 'boolean comparison results are allowed
                    typ = OFFSETTYPE - ISPOINTER: IF offsetmode = 2 THEN typ = typ + ISUNSIGNED
                END IF
            END IF

            'override typ=ISFLOAT+256 to typ=ISFLOAT+64 for ^ operator's result
            IF u = 2 THEN
                IF i$ = "pow2" THEN

                    IF offsetmode THEN Give_Error "Operator '^' cannot be used with an _OFFSET": EXIT FUNCTION

                    'QB-like conversion of math functions returning floating point values
                    'reassess oldtype & newtype
                    b = oldtyp AND 511
                    IF oldtyp AND ISFLOAT THEN
                        'no change to b
                    ELSE
                        IF b > 16 THEN b = 64 'larger than INTEGER? return DOUBLE
                        IF b > 32 THEN b = 256 'larger than LONG? return FLOAT
                        IF b <= 16 THEN b = 32
                    END IF
                    b2 = newtyp AND 511
                    IF newtyp AND ISFLOAT THEN
                        IF b2 > b THEN b = b2
                    ELSE
                        b3 = 32
                        IF b2 > 16 THEN b3 = 64 'larger than INTEGER? return DOUBLE
                        IF b2 > 32 THEN b3 = 256 'larger than LONG? return FLOAT
                        IF b3 > b THEN b = b3
                    END IF
                    typ = ISFLOAT + b

                END IF 'pow2
            END IF 'u=2

            'STEP 3: apply operator appropriately

            IF u = 5 THEN
                block(i + 1) = i$ + "(" + block(i + 1) + ")"
                block(i) = "": i = i + 1: GOTO operatorapplied
            END IF

            'binary operators

            IF u = 1 THEN
                block(i + 1) = block(i - 1) + i$ + block(i + 1)
                block(i - 1) = "": block(i) = "": i = i + 1: GOTO operatorapplied
            END IF

            IF u = 2 THEN
                block(i + 1) = i$ + "(" + block(i - 1) + "," + block(i + 1) + ")"
                block(i - 1) = "": block(i) = "": i = i + 1: GOTO operatorapplied
            END IF

            IF u = 3 THEN
                block(i + 1) = "-(" + block(i - 1) + i$ + block(i + 1) + ")"
                block(i - 1) = "": block(i) = "": i = i + 1: GOTO operatorapplied
            END IF

            IF u = 4 THEN
                block(i + 1) = "~" + block(i - 1) + i$ + block(i + 1)
                block(i - 1) = "": block(i) = "": i = i + 1: GOTO operatorapplied
            END IF

            '...more?...

            Give_Error "ERROR: Operator could not be applied correctly!": EXIT FUNCTION '<--should never happen!
            operatorapplied:

            IF offsetcvi THEN block(i) = "qbr(" + block(i) + ")": offsetcvi = 0
            offsetmode = 0

        ELSE
            nonop = nonop + 1
        END IF
    ELSE
        nonop = nonop + 1
    END IF
    IF nonop > 1 THEN Give_Error "Expected operator in equation": EXIT FUNCTION
NEXT
IF Debug THEN PRINT #9, ""

'join blocks
FOR i = 1 TO blockn
    r$ = r$ + block(i)
NEXT

IF Debug THEN
    PRINT #9, "evaluated:" + r$ + " AS TYPE:";
    IF (typ AND ISSTRING) THEN PRINT #9, "[ISSTRING]";
    IF (typ AND ISFLOAT) THEN PRINT #9, "[ISFLOAT]";
    IF (typ AND ISUNSIGNED) THEN PRINT #9, "[ISUNSIGNED]";
    IF (typ AND ISPOINTER) THEN PRINT #9, "[ISPOINTER]";
    IF (typ AND ISFIXEDLENGTH) THEN PRINT #9, "[ISFIXEDLENGTH]";
    IF (typ AND ISINCONVENTIONALMEMORY) THEN PRINT #9, "[ISINCONVENTIONALMEMORY]";
    PRINT #9, "(size in bits=" + str2$(typ AND 511) + ")"
END IF


evaluate$ = r$



END FUNCTION




FUNCTION evaluatefunc$ (a2$, args AS LONG, typ AS LONG)
a$ = a2$

IF Debug THEN PRINT #9, "evaluatingfunction:" + RTRIM$(id.n) + ":" + a$

DIM id2 AS idstruct

id2 = id
n$ = RTRIM$(id2.n)
typ = id2.ret
targetid = currentid

IF RTRIM$(id2.callname) = "func_stub" THEN Give_Error "Command not implemented": EXIT FUNCTION

SetDependency id2.Dependency

passomit = 0
omitarg_first = 0: omitarg_last = 0

f$ = RTRIM$(id2.specialformat)
IF LEN(f$) THEN 'special format given

    'count omittable args
    sqb = 0
    a = 0
    FOR fi = 1 TO LEN(f$)
        fa = ASC(f$, fi)
        IF fa = ASC_QUESTIONMARK THEN
            a = a + 1
            IF sqb <> 0 AND omitarg_first = 0 THEN omitarg_first = a
        END IF
        IF fa = ASC_LEFTSQUAREBRACKET THEN sqb = 1
        IF fa = ASC_RIGHTSQUAREBRACKET THEN sqb = 0: omitarg_last = a
    NEXT
    omitargs = omitarg_last - omitarg_first + 1

    IF args <> id2.args - omitargs AND args <> id2.args THEN Give_Error "Incorrect number of arguments passed to function": EXIT FUNCTION

    passomit = 1 'pass omit flags param to function

    IF id2.args = args THEN omitarg_first = 0: omitarg_last = 0 'all arguments were passed!

ELSE 'no special format given

    IF n$ = "ASC" AND args = 2 THEN GOTO skipargnumchk
    IF id2.args <> args THEN Give_Error "Incorrect number of arguments passed to function": EXIT FUNCTION

END IF

skipargnumchk:

IF id2.NoCloud THEN
    IF Cloud THEN Give_Error "Feature not supported on QLOUD" '***NOCLOUD***
END IF

r$ = RTRIM$(id2.callname) + "("


IF id2.args <> 0 THEN

    curarg = 1
    firsti = 1

    n = numelements(a$)
    IF n = 0 THEN i = 0: GOTO noargs

    FOR i = 1 TO n



        IF curarg >= omitarg_first AND curarg <= omitarg_last THEN
            noargs:
            targettyp = CVL(MID$(id2.arg, curarg * 4 - 4 + 1, 4))

            'IF (targettyp AND ISSTRING) THEN Give_Error "QB64 doesn't support optional string arguments for functions yet!": EXIT FUNCTION

            FOR fi = 1 TO omitargs - 1: r$ = r$ + "NULL,": NEXT: r$ = r$ + "NULL"
            curarg = curarg + omitargs
            IF i = n THEN EXIT FOR
            r$ = r$ + ","
        END IF

        l$ = getelement(a$, i)
        IF l$ = "(" THEN b = b + 1
        IF l$ = ")" THEN b = b - 1
        IF (l$ = "," AND b = 0) OR (i = n) THEN

            targettyp = CVL(MID$(id2.arg, curarg * 4 - 4 + 1, 4))
            nele = ASC(MID$(id2.nele, curarg, 1))
            nelereq = ASC(MID$(id2.nelereq, curarg, 1))

            IF i = n THEN
                e$ = getelements$(a$, firsti, i)
            ELSE
                e$ = getelements$(a$, firsti, i - 1)
            END IF

            IF LEFT$(e$, 2) = "(" + sp THEN dereference = 1 ELSE dereference = 0



            '*special case CVI,CVL,CVS,CVD,_CV (part #1)
            IF n$ = "_CV" THEN
                IF curarg = 1 THEN
                    cvtype$ = type2symbol$(e$)
                    IF Error_Happened THEN EXIT FUNCTION
                    e$ = ""
                    GOTO dontevaluate
                END IF
            END IF

            '*special case MKI,MKL,MKS,MKD,_MK (part #1)

            IF n$ = "_MK" THEN
                IF RTRIM$(id2.musthave) = "$" THEN
                    IF curarg = 1 THEN
                        mktype$ = type2symbol$(e$)
                        IF Error_Happened THEN EXIT FUNCTION
                        IF Debug THEN PRINT #9, "_MK:[" + e$ + "]:[" + mktype$ + "]"
                        e$ = ""
                        GOTO dontevaluate
                    END IF
                END IF
            END IF

            IF n$ = "UBOUND" OR n$ = "LBOUND" THEN
                IF curarg = 1 THEN
                    'perform a "fake" evaluation of the array
                    e$ = e$ + sp + "(" + sp + ")"
                    e$ = evaluate(e$, sourcetyp)
                    IF Error_Happened THEN EXIT FUNCTION
                    IF (sourcetyp AND ISREFERENCE) = 0 THEN Give_Error "Expected array-name": EXIT FUNCTION
                    IF (sourcetyp AND ISARRAY) = 0 THEN Give_Error "Expected array-name": EXIT FUNCTION
                    'make a note of the array's index for later
                    ulboundarray$ = e$
                    ulboundarraytyp = sourcetyp
                    e$ = ""
                    r$ = ""
                    GOTO dontevaluate
                END IF
            END IF


            '*special case: INPUT$ function
            IF n$ = "INPUT" THEN
                IF RTRIM$(id2.musthave) = "$" THEN
                    IF curarg = 2 THEN
                        IF LEFT$(e$, 2) = "#" + sp THEN e$ = RIGHT$(e$, LEN(e$) - 2)
                    END IF
                END IF
            END IF


            '*special case*
            IF n$ = "ASC" THEN
                IF curarg = 2 THEN
                    e$ = evaluatetotyp$(e$, 32&)
                    IF Error_Happened THEN EXIT FUNCTION
                    typ& = LONGTYPE - ISPOINTER
                    r$ = r$ + e$ + ")"
                    GOTO evalfuncspecial
                END IF
            END IF


            'PRINT #12, "n$="; n$
            'PRINT #12, "curarg="; curarg
            'PRINT #12, "e$="; e$
            'PRINT #12, "r$="; r$

            '*special case*
            IF n$ = "_MEMGET" THEN
                IF curarg = 1 THEN
                    memget_blk$ = e$
                END IF
                IF curarg = 2 THEN
                    memget_offs$ = e$
                END IF
                IF curarg = 3 THEN
                    e$ = UCASE$(e$)
                    IF INSTR(e$, sp + "*" + sp) THEN 'multiplier will have an appended %,& or && symbol
                        IF RIGHT$(e$, 2) = "&&" THEN
                            e$ = LEFT$(e$, LEN(e$) - 2)
                        ELSE
                            IF RIGHT$(e$, 1) = "&" OR RIGHT$(e$, 1) = "%" THEN e$ = LEFT$(e$, LEN(e$) - 1)
                        END IF
                    END IF
                    t = typname2typ(e$)
                    IF t = 0 THEN Give_Error "Invalid TYPE name": EXIT FUNCTION
                    IF t AND ISOFFSETINBITS THEN Give_Error "_BIT TYPE unsupported": EXIT FUNCTION
                    memget_size = typname2typsize
                    IF t AND ISSTRING THEN
                        IF (t AND ISFIXEDLENGTH) = 0 THEN Give_Error "Expected STRING * ...": EXIT FUNCTION
                        memget_ctyp$ = "qbs*"
                    ELSE
                        IF t AND ISUDT THEN
                            memget_size = udtxsize(t AND 511) \ 8
                            memget_ctyp$ = "void*"
                        ELSE
                            memget_size = (t AND 511) \ 8
                            memget_ctyp$ = typ2ctyp$(t, "")
                        END IF
                    END IF





                    'assume checking off
                    offs$ = evaluatetotyp(memget_offs$, OFFSETTYPE - ISPOINTER)
                    blkoffs$ = evaluatetotyp(memget_blk$, -6)
                    IF NoChecks = 0 THEN
                        'change offs$ to be the return of the safe version
                        offs$ = "func__memget((mem_block*)" + blkoffs$ + "," + offs$ + "," + str2(memget_size) + ")"
                    END IF
                    IF t AND ISSTRING THEN
                        r$ = "qbs_new_txt_len((char*)" + offs$ + "," + str2(memget_size) + ")"
                    ELSE
                        IF t AND ISUDT THEN
                            r$ = "((void*)+" + offs$ + ")"
                            t = ISUDT + ISPOINTER + (t AND 511)
                        ELSE
                            r$ = "*(" + memget_ctyp$ + "*)(" + offs$ + ")"
                            IF t AND ISPOINTER THEN t = t - ISPOINTER
                        END IF
                    END IF







                    typ& = t


                    GOTO evalfuncspecial
                END IF
            END IF

            '------------------------------------------------------------------------------------------------------------
            e2$ = e$
            e$ = evaluate(e$, sourcetyp)
            IF Error_Happened THEN EXIT FUNCTION
            '------------------------------------------------------------------------------------------------------------

            '***special case***
            IF n$ = "_MEM" THEN
                IF curarg = 1 THEN
                    IF args = 1 THEN
                        targettyp = -7
                    END IF
                    IF args = 2 THEN
                        r$ = RTRIM$(id2.callname) + "_at_offset" + RIGHT$(r$, LEN(r$) - LEN(RTRIM$(id2.callname)))
                        IF (sourcetyp AND ISOFFSET) = 0 THEN Give_Error "Expected _MEM(_OFFSET-value,...)": EXIT FUNCTION
                    END IF
                END IF
            END IF

            '*special case*
            IF n$ = "_OFFSET" THEN
                IF (sourcetyp AND ISREFERENCE) = 0 THEN
                    Give_Error "_OFFSET expects the name of a variable/array": EXIT FUNCTION
                END IF
                IF (sourcetyp AND ISARRAY) THEN
                    IF (sourcetyp AND ISOFFSETINBITS) THEN Give_Error "_OFFSET cannot reference _BIT type arrays": EXIT FUNCTION
                END IF
                r$ = "((uptrszint)(" + evaluatetotyp$(e2$, -6) + "))"
                IF Error_Happened THEN EXIT FUNCTION
                typ& = UOFFSETTYPE - ISPOINTER
                GOTO evalfuncspecial
            END IF '_OFFSET

            '*_OFFSET exceptions*
            IF sourcetyp AND ISOFFSET THEN
                IF n$ = "MKSMBF" AND RTRIM$(id2.musthave) = "$" THEN Give_Error "Cannot convert _OFFSET type to other types": EXIT FUNCTION
                IF n$ = "MKDMBF" AND RTRIM$(id2.musthave) = "$" THEN Give_Error "Cannot convert _OFFSET type to other types": EXIT FUNCTION
            END IF

            '*special case*
            IF n$ = "ENVIRON" THEN
                IF sourcetyp AND ISSTRING THEN
                    IF sourcetyp AND ISREFERENCE THEN e$ = refer(e$, sourcetyp, 0)
                    IF Error_Happened THEN EXIT FUNCTION
                    GOTO dontevaluate
                END IF
            END IF

            '*special case*
            IF n$ = "LEN" THEN
                typ& = LONGTYPE - ISPOINTER
                IF (sourcetyp AND ISREFERENCE) = 0 THEN
                    'could be a string expression
                    IF sourcetyp AND ISSTRING THEN
                        r$ = "((int32)(" + e$ + ")->len)"
                        GOTO evalfuncspecial
                    END IF
                    Give_Error "String expression or variable name required in LEN statement": EXIT FUNCTION
                END IF
                r$ = evaluatetotyp$(e2$, -5) 'use evaluatetotyp to get 'element' size
                IF Error_Happened THEN EXIT FUNCTION
                GOTO evalfuncspecial
            END IF

            '*special case*
            IF n$ = "OCT" THEN
                IF RTRIM$(id2.musthave) = "$" THEN
                    bits = sourcetyp AND 511

                    IF (sourcetyp AND ISSTRING) THEN Give_Error "Expected numeric value": EXIT FUNCTION
                    wasref = 0
                    IF (sourcetyp AND ISREFERENCE) THEN e$ = refer(e$, sourcetyp, 0): wasref = 1
                    IF Error_Happened THEN EXIT FUNCTION
                    bits = sourcetyp AND 511
                    IF (sourcetyp AND ISOFFSETINBITS) THEN
                        e$ = "func_oct(" + e$ + "," + str2$(bits) + ")"
                    ELSE
                        IF (sourcetyp AND ISFLOAT) THEN
                            e$ = "func_oct_float(" + e$ + ")"
                        ELSE
                            IF bits = 64 THEN
                                IF wasref = 0 THEN bits = 0
                            END IF
                            e$ = "func_oct(" + e$ + "," + str2$(bits) + ")"
                        END IF
                    END IF
                    typ& = STRINGTYPE - ISPOINTER
                    r$ = e$
                    GOTO evalfuncspecial
                END IF
            END IF



            '*special case*
            IF n$ = "HEX" THEN
                IF RTRIM$(id2.musthave) = "$" THEN
                    bits = sourcetyp AND 511
                    IF (sourcetyp AND ISSTRING) THEN Give_Error "Expected numeric value": EXIT FUNCTION
                    wasref = 0
                    IF (sourcetyp AND ISREFERENCE) THEN e$ = refer(e$, sourcetyp, 0): wasref = 1
                    IF Error_Happened THEN EXIT FUNCTION
                    bits = sourcetyp AND 511
                    IF (sourcetyp AND ISOFFSETINBITS) THEN
                        chars = (bits + 3) \ 4
                        e$ = "func_hex(" + e$ + "," + str2$(chars) + ")"
                    ELSE
                        IF (sourcetyp AND ISFLOAT) THEN
                            e$ = "func_hex_float(" + e$ + ")"
                        ELSE
                            IF bits = 8 THEN chars = 2
                            IF bits = 16 THEN chars = 4
                            IF bits = 32 THEN chars = 8
                            IF bits = 64 THEN
                                IF wasref = 1 THEN chars = 16 ELSE chars = 0
                            END IF
                            e$ = "func_hex(" + e$ + "," + str2$(chars) + ")"
                        END IF
                    END IF
                    typ& = STRINGTYPE - ISPOINTER
                    r$ = e$
                    GOTO evalfuncspecial
                END IF
            END IF









            '*special case*
            IF n$ = "EXP" THEN
                bits = sourcetyp AND 511
                IF (sourcetyp AND ISSTRING) THEN Give_Error "Expected numeric value": EXIT FUNCTION
                IF (sourcetyp AND ISREFERENCE) THEN e$ = refer(e$, sourcetyp, 0)
                IF Error_Happened THEN EXIT FUNCTION
                bits = sourcetyp AND 511
                typ& = SINGLETYPE - ISPOINTER
                IF (sourcetyp AND ISFLOAT) THEN
                    IF bits = 32 THEN e$ = "func_exp_single(" + e$ + ")" ELSE e$ = "func_exp_float(" + e$ + ")": typ& = FLOATTYPE - ISPOINTER
                ELSE
                    IF (sourcetyp AND ISOFFSETINBITS) THEN
                        e$ = "func_exp_float(" + e$ + ")": typ& = FLOATTYPE - ISPOINTER
                    ELSE
                        IF bits <= 16 THEN e$ = "func_exp_single(" + e$ + ")" ELSE e$ = "func_exp_float(" + e$ + ")": typ& = FLOATTYPE - ISPOINTER
                    END IF
                END IF
                r$ = e$
                GOTO evalfuncspecial
            END IF

            '*special case*
            IF n$ = "INT" THEN
                IF (sourcetyp AND ISSTRING) THEN Give_Error "Expected numeric value": EXIT FUNCTION
                IF (sourcetyp AND ISREFERENCE) THEN e$ = refer(e$, sourcetyp, 0)
                IF Error_Happened THEN EXIT FUNCTION
                'establish which function (if any!) should be used
                IF (sourcetyp AND ISFLOAT) THEN e$ = "floor(" + e$ + ")" ELSE e$ = "(" + e$ + ")"
                r$ = e$
                typ& = sourcetyp
                GOTO evalfuncspecial
            END IF

            '*special case*
            IF n$ = "FIX" THEN
                IF (sourcetyp AND ISSTRING) THEN Give_Error "Expected numeric value": EXIT FUNCTION
                IF (sourcetyp AND ISREFERENCE) THEN e$ = refer(e$, sourcetyp, 0)
                IF Error_Happened THEN EXIT FUNCTION
                'establish which function (if any!) should be used
                bits = sourcetyp AND 511
                IF (sourcetyp AND ISFLOAT) THEN
                    IF bits > 64 THEN e$ = "func_fix_float(" + e$ + ")" ELSE e$ = "func_fix_double(" + e$ + ")"
                ELSE
                    e$ = "(" + e$ + ")"
                END IF
                r$ = e$
                typ& = sourcetyp
                GOTO evalfuncspecial
            END IF

            '*special case*
            IF n$ = "_ROUND" THEN
                IF (sourcetyp AND ISSTRING) THEN Give_Error "Expected numeric value": EXIT FUNCTION
                IF (sourcetyp AND ISREFERENCE) THEN e$ = refer(e$, sourcetyp, 0)
                IF Error_Happened THEN EXIT FUNCTION
                'establish which function (if any!) should be used
                IF (sourcetyp AND ISFLOAT) THEN
                    bits = sourcetyp AND 511
                    IF bits > 64 THEN e$ = "func_round_float(" + e$ + ")" ELSE e$ = "func_round_double(" + e$ + ")"
                ELSE
                    e$ = "(" + e$ + ")"
                END IF
                r$ = e$
                typ& = 64&
                IF (sourcetyp AND ISOFFSET) THEN
                    IF sourcetyp AND ISUNSIGNED THEN typ& = UOFFSETTYPE - ISPOINTER ELSE typ& = OFFSETTYPE - ISPOINTER
                END IF
                GOTO evalfuncspecial
            END IF


            '*special case*
            IF n$ = "CDBL" THEN
                IF (sourcetyp AND ISOFFSET) THEN Give_Error "Cannot convert _OFFSET type to other types": EXIT FUNCTION
                IF (sourcetyp AND ISSTRING) THEN Give_Error "Expected numeric value": EXIT FUNCTION
                IF (sourcetyp AND ISREFERENCE) THEN e$ = refer(e$, sourcetyp, 0)
                IF Error_Happened THEN EXIT FUNCTION
                'establish which function (if any!) should be used
                bits = sourcetyp AND 511
                IF (sourcetyp AND ISFLOAT) THEN
                    IF bits > 64 THEN e$ = "func_cdbl_float(" + e$ + ")"
                ELSE
                    e$ = "((double)(" + e$ + "))"
                END IF
                r$ = e$
                typ& = DOUBLETYPE - ISPOINTER
                GOTO evalfuncspecial
            END IF

            '*special case*
            IF n$ = "CSNG" THEN
                IF (sourcetyp AND ISOFFSET) THEN Give_Error "Cannot convert _OFFSET type to other types": EXIT FUNCTION
                IF (sourcetyp AND ISSTRING) THEN Give_Error "Expected numeric value": EXIT FUNCTION
                IF (sourcetyp AND ISREFERENCE) THEN e$ = refer(e$, sourcetyp, 0)
                IF Error_Happened THEN EXIT FUNCTION
                'establish which function (if any!) should be used
                bits = sourcetyp AND 511
                IF (sourcetyp AND ISFLOAT) THEN
                    IF bits = 64 THEN e$ = "func_csng_double(" + e$ + ")"
                    IF bits > 64 THEN e$ = "func_csng_float(" + e$ + ")"
                ELSE
                    e$ = "((double)(" + e$ + "))"
                END IF
                r$ = e$
                typ& = SINGLETYPE - ISPOINTER
                GOTO evalfuncspecial
            END IF


            '*special case*
            IF n$ = "CLNG" THEN
                IF (sourcetyp AND ISOFFSET) THEN Give_Error "Cannot convert _OFFSET type to other types": EXIT FUNCTION
                IF (sourcetyp AND ISSTRING) THEN Give_Error "Expected numeric value": EXIT FUNCTION
                IF (sourcetyp AND ISREFERENCE) THEN e$ = refer(e$, sourcetyp, 0)
                IF Error_Happened THEN EXIT FUNCTION
                'establish which function (if any!) should be used
                bits = sourcetyp AND 511
                IF (sourcetyp AND ISFLOAT) THEN
                    IF bits > 64 THEN e$ = "func_clng_float(" + e$ + ")" ELSE e$ = "func_clng_double(" + e$ + ")"
                ELSE 'integer
                    IF (sourcetyp AND ISUNSIGNED) THEN
                        IF bits = 32 THEN e$ = "func_clng_ulong(" + e$ + ")"
                        IF bits > 32 THEN e$ = "func_clng_uint64(" + e$ + ")"
                    ELSE 'signed
                        IF bits > 32 THEN e$ = "func_clng_int64(" + e$ + ")"
                    END IF
                END IF
                r$ = e$
                typ& = 32&
                GOTO evalfuncspecial
            END IF

            '*special case*
            IF n$ = "CINT" THEN
                IF (sourcetyp AND ISOFFSET) THEN Give_Error "Cannot convert _OFFSET type to other types": EXIT FUNCTION
                IF (sourcetyp AND ISSTRING) THEN Give_Error "Expected numeric value": EXIT FUNCTION
                IF (sourcetyp AND ISREFERENCE) THEN e$ = refer(e$, sourcetyp, 0)
                IF Error_Happened THEN EXIT FUNCTION
                'establish which function (if any!) should be used
                bits = sourcetyp AND 511
                IF (sourcetyp AND ISFLOAT) THEN
                    IF bits > 64 THEN e$ = "func_cint_float(" + e$ + ")" ELSE e$ = "func_cint_double(" + e$ + ")"
                ELSE 'integer
                    IF (sourcetyp AND ISUNSIGNED) THEN
                        IF bits > 15 AND bits <= 32 THEN e$ = "func_cint_ulong(" + e$ + ")"
                        IF bits > 32 THEN e$ = "func_cint_uint64(" + e$ + ")"
                    ELSE 'signed
                        IF bits > 16 AND bits <= 32 THEN e$ = "func_cint_long(" + e$ + ")"
                        IF bits > 32 THEN e$ = "func_cint_int64(" + e$ + ")"
                    END IF
                END IF
                r$ = e$
                typ& = 16&
                GOTO evalfuncspecial
            END IF

            '*special case MKI,MKL,MKS,MKD,_MK (part #2)
            mktype = 0
            size = 0
            IF n$ = "MKI" THEN mktype = 1: mktype$ = "%"
            IF n$ = "MKL" THEN mktype = 2: mktype$ = "&"
            IF n$ = "MKS" THEN mktype = 3: mktype$ = "!"
            IF n$ = "MKD" THEN mktype = 4: mktype$ = "#"
            IF n$ = "_MK" THEN mktype = -1
            IF mktype THEN
                IF mktype <> -1 OR curarg = 2 THEN
                    IF (sourcetyp AND ISOFFSET) THEN Give_Error "Cannot convert _OFFSET type to other types": EXIT FUNCTION
                    'both _MK and trad. process the following
                    qtyp& = 0
                    IF mktype$ = "%%" THEN ctype$ = "b": qtyp& = BYTETYPE - ISPOINTER
                    IF mktype$ = "~%%" THEN ctype$ = "ub": qtyp& = UBYTETYPE - ISPOINTER
                    IF mktype$ = "%" THEN ctype$ = "i": qtyp& = INTEGERTYPE - ISPOINTER
                    IF mktype$ = "~%" THEN ctype$ = "ui": qtyp& = UINTEGERTYPE - ISPOINTER
                    IF mktype$ = "&" THEN ctype$ = "l": qtyp& = LONGTYPE - ISPOINTER
                    IF mktype$ = "~&" THEN ctype$ = "ul": qtyp& = ULONGTYPE - ISPOINTER
                    IF mktype$ = "&&" THEN ctype$ = "i64": qtyp& = INTEGER64TYPE - ISPOINTER
                    IF mktype$ = "~&&" THEN ctype$ = "ui64": qtyp& = UINTEGER64TYPE - ISPOINTER
                    IF mktype$ = "!" THEN ctype$ = "s": qtyp& = SINGLETYPE - ISPOINTER
                    IF mktype$ = "#" THEN ctype$ = "d": qtyp& = DOUBLETYPE - ISPOINTER
                    IF mktype$ = "##" THEN ctype$ = "f": qtyp& = FLOATTYPE - ISPOINTER
                    IF LEFT$(mktype$, 2) = "~`" THEN ctype$ = "ubit": qtyp& = UINTEGER64TYPE - ISPOINTER: size = VAL(RIGHT$(mktype$, LEN(mktype$) - 2))
                    IF LEFT$(mktype$, 1) = "`" THEN ctype$ = "bit": qtyp& = INTEGER64TYPE - ISPOINTER: size = VAL(RIGHT$(mktype$, LEN(mktype$) - 1))
                    IF qtyp& = 0 THEN Give_Error "_MK only accepts numeric types": EXIT FUNCTION
                    IF size THEN
                        r$ = ctype$ + "2string(" + str2(size) + ","
                    ELSE
                        r$ = ctype$ + "2string("
                    END IF
                    nocomma = 1
                    targettyp = qtyp&
                END IF
            END IF

            '*special case CVI,CVL,CVS,CVD,_CV (part #2)
            cvtype = 0
            IF n$ = "CVI" THEN cvtype = 1: cvtype$ = "%"
            IF n$ = "CVL" THEN cvtype = 2: cvtype$ = "&"
            IF n$ = "CVS" THEN cvtype = 3: cvtype$ = "!"
            IF n$ = "CVD" THEN cvtype = 4: cvtype$ = "#"
            IF n$ = "_CV" THEN cvtype = -1
            IF cvtype THEN
                IF cvtype <> -1 OR curarg = 2 THEN
                    IF (sourcetyp AND ISSTRING) = 0 THEN Give_Error n$ + " requires a STRING argument": EXIT FUNCTION
                    IF (sourcetyp AND ISREFERENCE) THEN e$ = refer(e$, sourcetyp, 0)
                    IF Error_Happened THEN EXIT FUNCTION
                    typ& = 0
                    IF cvtype$ = "%%" THEN ctype$ = "b": typ& = BYTETYPE - ISPOINTER
                    IF cvtype$ = "~%%" THEN ctype$ = "ub": typ& = UBYTETYPE - ISPOINTER
                    IF cvtype$ = "%" THEN ctype$ = "i": typ& = INTEGERTYPE - ISPOINTER
                    IF cvtype$ = "~%" THEN ctype$ = "ui": typ& = UINTEGERTYPE - ISPOINTER
                    IF cvtype$ = "&" THEN ctype$ = "l": typ& = LONGTYPE - ISPOINTER
                    IF cvtype$ = "~&" THEN ctype$ = "ul": typ& = ULONGTYPE - ISPOINTER
                    IF cvtype$ = "&&" THEN ctype$ = "i64": typ& = INTEGER64TYPE - ISPOINTER
                    IF cvtype$ = "~&&" THEN ctype$ = "ui64": typ& = UINTEGER64TYPE - ISPOINTER
                    IF cvtype$ = "!" THEN ctype$ = "s": typ& = SINGLETYPE - ISPOINTER
                    IF cvtype$ = "#" THEN ctype$ = "d": typ& = DOUBLETYPE - ISPOINTER
                    IF cvtype$ = "##" THEN ctype$ = "f": typ& = FLOATTYPE - ISPOINTER
                    IF LEFT$(cvtype$, 2) = "~`" THEN ctype$ = "ubit": typ& = UINTEGER64TYPE - ISPOINTER: size = VAL(RIGHT$(cvtype$, LEN(cvtype$) - 2))
                    IF LEFT$(cvtype$, 1) = "`" THEN ctype$ = "bit": typ& = INTEGER64TYPE - ISPOINTER: size = VAL(RIGHT$(cvtype$, LEN(cvtype$) - 1))
                    IF typ& = 0 THEN Give_Error "_CV cannot return STRING type!": EXIT FUNCTION
                    IF ctype$ = "bit" OR ctype$ = "ubit" THEN
                        r$ = "string2" + ctype$ + "(" + e$ + "," + str2(size) + ")"
                    ELSE
                        r$ = "string2" + ctype$ + "(" + e$ + ")"
                    END IF
                    GOTO evalfuncspecial
                END IF
            END IF

            '*special case
            IF RTRIM$(id2.n) = "STRING" THEN
                IF curarg = 2 THEN
                    IF (sourcetyp AND ISSTRING) THEN
                        IF (sourcetyp AND ISREFERENCE) THEN e$ = refer(e$, sourcetyp, 0)
                        IF Error_Happened THEN EXIT FUNCTION
                        sourcetyp = 64&
                        e$ = "(" + e$ + "->chr[0])"
                    END IF
                END IF
            END IF

            '*special case
            IF RTRIM$(id2.n) = "SADD" THEN
                IF (sourcetyp AND ISREFERENCE) = 0 THEN
                    Give_Error "SADD only accepts variable-length string variables": EXIT FUNCTION
                END IF
                IF (sourcetyp AND ISFIXEDLENGTH) THEN
                    Give_Error "SADD only accepts variable-length string variables": EXIT FUNCTION
                END IF
                IF (sourcetyp AND ISINCONVENTIONALMEMORY) = 0 THEN
                    recompile = 1
                    cmemlist(VAL(e$)) = 1
                    r$ = "[CONVENTIONAL_MEMORY_REQUIRED]"
                    typ& = 64&
                    GOTO evalfuncspecial
                END IF
                r$ = refer(e$, sourcetyp, 0)
                IF Error_Happened THEN EXIT FUNCTION
                r$ = "((unsigned short)(" + r$ + "->chr-&cmem[1280]))"
                typ& = 64&
                GOTO evalfuncspecial
            END IF

            '*special case
            IF RTRIM$(id2.n) = "VARPTR" THEN
                IF (sourcetyp AND ISREFERENCE) = 0 THEN
                    Give_Error "Expected reference to a variable/array": EXIT FUNCTION
                END IF

                IF RTRIM$(id2.musthave) = "$" THEN
                    IF (sourcetyp AND ISINCONVENTIONALMEMORY) = 0 THEN
                        recompile = 1
                        cmemlist(VAL(e$)) = 1
                        r$ = "[CONVENTIONAL_MEMORY_REQUIRED]"
                        typ& = ISSTRING
                        GOTO evalfuncspecial
                    END IF

                    IF (sourcetyp AND ISARRAY) THEN
                        IF (sourcetyp AND ISSTRING) = 0 THEN Give_Error "VARPTR$ only accepts variable-length string arrays": EXIT FUNCTION
                        IF (sourcetyp AND ISFIXEDLENGTH) THEN Give_Error "VARPTR$ only accepts variable-length string arrays": EXIT FUNCTION
                    END IF

                    'must be a simple variable
                    '!assuming it is in cmem in DBLOCK
                    r$ = refer(e$, sourcetyp, 1)
                    IF Error_Happened THEN EXIT FUNCTION
                    IF (sourcetyp AND ISSTRING) THEN
                        IF (sourcetyp AND ISARRAY) THEN r$ = refer(e$, sourcetyp, 0)
                        IF Error_Happened THEN EXIT FUNCTION
                        r$ = r$ + "->cmem_descriptor_offset"
                        t = 3
                    ELSE
                        r$ = "((unsigned short)(((uint8*)" + r$ + ")-&cmem[1280]))"
                        '*top bit on=unsigned
                        '*second top bit on=bit-value (lower bits indicate the size)
                        'BYTE=1
                        'INTEGER=2
                        'STRING=3
                        'SINGLE=4
                        'INT64=5
                        'FLOAT=6
                        'DOUBLE=8
                        'LONG=20
                        'BIT=64+n
                        t = 0
                        IF (sourcetyp AND ISUNSIGNED) THEN t = t + 128
                        IF (sourcetyp AND ISOFFSETINBITS) THEN
                            t = t + 64
                            t = t + (sourcetyp AND 63)
                        ELSE
                            bits = sourcetyp AND 511
                            IF (sourcetyp AND ISFLOAT) THEN
                                IF bits = 32 THEN t = t + 4
                                IF bits = 64 THEN t = t + 8
                                IF bits = 256 THEN t = t + 6
                            ELSE
                                IF bits = 8 THEN t = t + 1
                                IF bits = 16 THEN t = t + 2
                                IF bits = 32 THEN t = t + 20
                                IF bits = 64 THEN t = t + 5
                            END IF
                        END IF
                    END IF
                    r$ = "func_varptr_helper(" + str2(t) + "," + r$ + ")"
                    typ& = ISSTRING
                    GOTO evalfuncspecial
                END IF 'end of varptr$











                'VARPTR
                IF (sourcetyp AND ISINCONVENTIONALMEMORY) = 0 THEN
                    recompile = 1
                    cmemlist(VAL(e$)) = 1
                    r$ = "[CONVENTIONAL_MEMORY_REQUIRED]"
                    typ& = 64&
                    GOTO evalfuncspecial
                END IF

                IF (sourcetyp AND ISARRAY) THEN
                    IF (sourcetyp AND ISOFFSETINBITS) THEN Give_Error "VARPTR cannot reference _BIT type arrays": EXIT FUNCTION

                    'string array?
                    IF (sourcetyp AND ISSTRING) THEN
                        IF (sourcetyp AND ISFIXEDLENGTH) THEN
                            getid VAL(e$)
                            IF Error_Happened THEN EXIT FUNCTION
                            m = id.tsize
                            index$ = RIGHT$(e$, LEN(e$) - INSTR(e$, sp3))
                            typ = 64&
                            r$ = "((" + index$ + ")*" + str2(m) + ")"
                            GOTO evalfuncspecial
                        ELSE
                            'return the offset of the string's descriptor
                            r$ = refer(e$, sourcetyp, 0)
                            IF Error_Happened THEN EXIT FUNCTION
                            r$ = r$ + "->cmem_descriptor_offset"
                            typ = 64&
                            GOTO evalfuncspecial
                        END IF
                    END IF

                    IF sourcetyp AND ISUDT THEN
                        e$ = RIGHT$(e$, LEN(e$) - INSTR(e$, sp3)) 'skip idnumber
                        e$ = RIGHT$(e$, LEN(e$) - INSTR(e$, sp3)) 'skip u
                        o$ = RIGHT$(e$, LEN(e$) - INSTR(e$, sp3)) 'skip e
                        typ = 64&
                        r$ = "(" + o$ + ")"
                        GOTO evalfuncspecial
                    END IF

                    'non-UDT array
                    m = (sourcetyp AND 511) \ 8 'calculate size multiplier
                    index$ = RIGHT$(e$, LEN(e$) - INSTR(e$, sp3))
                    typ = 64&
                    r$ = "((" + index$ + ")*" + str2(m) + ")"
                    GOTO evalfuncspecial

                END IF

                'not an array

                IF sourcetyp AND ISUDT THEN
                    r$ = refer(e$, sourcetyp, 1)
                    IF Error_Happened THEN EXIT FUNCTION
                    e$ = RIGHT$(e$, LEN(e$) - INSTR(e$, sp3)) 'skip idnumber
                    e$ = RIGHT$(e$, LEN(e$) - INSTR(e$, sp3)) 'skip u
                    o$ = RIGHT$(e$, LEN(e$) - INSTR(e$, sp3)) 'skip e
                    typ = 64&

                    'if sub/func arg, may not be in DBLOCK
                    getid VAL(e$)
                    IF Error_Happened THEN EXIT FUNCTION
                    IF id.sfarg THEN 'could be in DBLOCK
                        'note: segment could be the closest segment to UDT element or the base of DBLOCK
                        r$ = "varptr_dblock_check(((uint8*)" + r$ + ")+(" + o$ + "))"
                    ELSE 'definitely in DBLOCK
                        'give offset relative to DBLOCK
                        r$ = "((unsigned short)(((uint8*)" + r$ + ") - &cmem[1280] + (" + o$ + ") ))"
                    END IF

                    GOTO evalfuncspecial
                END IF

                typ = 64&
                r$ = refer(e$, sourcetyp, 1)
                IF Error_Happened THEN EXIT FUNCTION
                IF (sourcetyp AND ISSTRING) THEN
                    IF (sourcetyp AND ISFIXEDLENGTH) THEN

                        'if sub/func arg, may not be in DBLOCK
                        getid VAL(e$)
                        IF Error_Happened THEN EXIT FUNCTION
                        IF id.sfarg THEN 'could be in DBLOCK
                            r$ = "varptr_dblock_check(" + r$ + "->chr)"
                        ELSE 'definitely in DBLOCK
                            r$ = "((unsigned short)(" + r$ + "->chr-&cmem[1280]))"
                        END IF

                    ELSE
                        r$ = r$ + "->cmem_descriptor_offset"
                    END IF
                    GOTO evalfuncspecial
                END IF

                'single, simple variable
                'if sub/func arg, may not be in DBLOCK
                getid VAL(e$)
                IF Error_Happened THEN EXIT FUNCTION
                IF id.sfarg THEN 'could be in DBLOCK
                    r$ = "varptr_dblock_check((uint8*)" + r$ + ")"
                ELSE 'definitely in DBLOCK
                    r$ = "((unsigned short)(((uint8*)" + r$ + ")-&cmem[1280]))"
                END IF

                GOTO evalfuncspecial
            END IF

            '*special case*
            IF RTRIM$(id2.n) = "VARSEG" THEN
                IF (sourcetyp AND ISREFERENCE) = 0 THEN
                    Give_Error "Expected reference to a variable/array": EXIT FUNCTION
                END IF
                IF (sourcetyp AND ISINCONVENTIONALMEMORY) = 0 THEN
                    recompile = 1
                    cmemlist(VAL(e$)) = 1
                    r$ = "[CONVENTIONAL_MEMORY_REQUIRED]"
                    typ& = 64&
                    GOTO evalfuncspecial
                END IF
                'array?
                IF (sourcetyp AND ISARRAY) THEN
                    IF (sourcetyp AND ISFIXEDLENGTH) = 0 THEN
                        IF (sourcetyp AND ISSTRING) THEN
                            r$ = "80"
                            typ = 64&
                            GOTO evalfuncspecial
                        END IF
                    END IF
                    typ = 64&
                    r$ = "( ( ((ptrszint)(" + refer(e$, sourcetyp, 1) + "[0])) - ((ptrszint)(&cmem[0])) ) /16)"
                    IF Error_Happened THEN EXIT FUNCTION
                    GOTO evalfuncspecial
                END IF

                'single variable/(var-len)string/udt? (usually stored in DBLOCK)
                typ = 64&
                'if sub/func arg, may not be in DBLOCK
                getid VAL(e$)
                IF Error_Happened THEN EXIT FUNCTION
                IF id.sfarg <> 0 AND (sourcetyp AND ISSTRING) = 0 THEN
                    IF sourcetyp AND ISUDT THEN
                        r$ = refer(e$, sourcetyp, 1)
                        IF Error_Happened THEN EXIT FUNCTION
                        e$ = RIGHT$(e$, LEN(e$) - INSTR(e$, sp3)) 'skip idnumber
                        e$ = RIGHT$(e$, LEN(e$) - INSTR(e$, sp3)) 'skip u
                        o$ = RIGHT$(e$, LEN(e$) - INSTR(e$, sp3)) 'skip e
                        r$ = "varseg_dblock_check(((uint8*)" + r$ + ")+(" + o$ + "))"
                    ELSE
                        r$ = "varseg_dblock_check((uint8*)" + refer(e$, sourcetyp, 1) + ")"
                        IF Error_Happened THEN EXIT FUNCTION
                    END IF
                ELSE
                    'can be assumed to be in DBLOCK
                    r$ = "80"
                END IF
                GOTO evalfuncspecial
            END IF 'varseg















            'note: this code has already been called...
            '------------------------------------------------------------------------------------------------------------
            'e2$ = e$
            'e$ = evaluate(e$, sourcetyp)
            '------------------------------------------------------------------------------------------------------------

            'note: this comment makes no sense...
            'any numeric variable, but it must be type-speficied

            IF targettyp = -2 THEN
                e$ = evaluatetotyp(e2$, -2)
                IF Error_Happened THEN EXIT FUNCTION
                GOTO dontevaluate
            END IF '-2

            IF targettyp = -7 THEN
                e$ = evaluatetotyp(e2$, -7)
                IF Error_Happened THEN EXIT FUNCTION
                GOTO dontevaluate
            END IF '-7

            IF targettyp = -8 THEN
                e$ = evaluatetotyp(e2$, -8)
                IF Error_Happened THEN EXIT FUNCTION
                GOTO dontevaluate
            END IF '-8

            IF sourcetyp AND ISOFFSET THEN
                IF (targettyp AND ISOFFSET) = 0 THEN
                    IF id2.internal_subfunc = 0 THEN Give_Error "Cannot convert _OFFSET type to other types": EXIT FUNCTION
                END IF
            END IF

            'note: this is used for functions like STR(...) which accept all types...
            explicitreference = 0
            IF targettyp = -1 THEN
                explicitreference = 1
                IF (sourcetyp AND ISSTRING) THEN Give_Error "Number required for function": EXIT FUNCTION
                targettyp = sourcetyp
                IF (targettyp AND ISPOINTER) THEN targettyp = targettyp - ISPOINTER
            END IF

            'pointer?
            IF (targettyp AND ISPOINTER) THEN
                IF dereference = 0 THEN 'check deferencing wasn't used



                    'note: array pointer
                    IF (targettyp AND ISARRAY) THEN
                        IF (sourcetyp AND ISREFERENCE) = 0 THEN Give_Error "Expected arrayname()": EXIT FUNCTION
                        IF (sourcetyp AND ISARRAY) = 0 THEN Give_Error "Expected arrayname()": EXIT FUNCTION
                        IF Debug THEN PRINT #9, "evaluatefunc:array reference:[" + e$ + "]"

                        'check arrays are of same type
                        targettyp2 = targettyp: sourcetyp2 = sourcetyp
                        targettyp2 = targettyp2 AND (511 + ISOFFSETINBITS + ISUDT + ISSTRING + ISFIXEDLENGTH + ISFLOAT)
                        sourcetyp2 = sourcetyp2 AND (511 + ISOFFSETINBITS + ISUDT + ISSTRING + ISFIXEDLENGTH + ISFLOAT)
                        IF sourcetyp2 <> targettyp2 THEN Give_Error "Incorrect array type passed to function": EXIT FUNCTION

                        'check arrayname was followed by '()'
                        IF targettyp AND ISUDT THEN
                            IF Debug THEN PRINT #9, "evaluatefunc:array reference:udt reference:[" + e$ + "]"
                            'get UDT info
                            udtrefid = VAL(e$)
                            getid udtrefid
                            IF Error_Happened THEN EXIT FUNCTION
                            udtrefi = INSTR(e$, sp3) 'end of id
                            udtrefi2 = INSTR(udtrefi + 1, e$, sp3) 'end of u
                            udtrefu = VAL(MID$(e$, udtrefi + 1, udtrefi2 - udtrefi - 1))
                            udtrefi3 = INSTR(udtrefi2 + 1, e$, sp3) 'skip e
                            udtrefe = VAL(MID$(e$, udtrefi2 + 1, udtrefi3 - udtrefi2 - 1))
                            o$ = RIGHT$(e$, LEN(e$) - udtrefi3)
                            'note: most of the UDT info above is not required
                            IF LEFT$(o$, 4) <> "(0)*" THEN Give_Error "Expected arrayname()": EXIT FUNCTION
                        ELSE
                            IF RIGHT$(e$, 2) <> sp3 + "0" THEN Give_Error "Expected arrayname()": EXIT FUNCTION
                        END IF


                        idnum = VAL(LEFT$(e$, INSTR(e$, sp3) - 1))
                        getid idnum
                        IF Error_Happened THEN EXIT FUNCTION

                        IF targettyp AND ISFIXEDLENGTH THEN
                            targettypsize = CVL(MID$(id2.argsize, curarg * 4 - 4 + 1, 4))
                            IF id.tsize <> targettypsize THEN Give_Error "Incorrect array type passed to function": EXIT FUNCTION
                        END IF

                        IF MID$(sfcmemargs(targetid), curarg, 1) = CHR$(1) THEN 'cmem required?
                            IF cmemlist(idnum) = 0 THEN
                                cmemlist(idnum) = 1

                                recompile = 1
                            END IF
                        END IF



                        IF id.linkid = 0 THEN
                            'if id.linkid is 0, it means the number of array elements is definietly
                            'known of the array being passed, this is not some "fake"/unknown array.
                            'using the numer of array elements of a fake array would be dangerous!

                            IF nelereq = 0 THEN
                                'only continue if the number of array elements required is unknown
                                'and it needs to be set

                                IF id.arrayelements <> -1 THEN
                                    nelereq = id.arrayelements
                                    MID$(id2.nelereq, curarg, 1) = CHR$(nelereq)
                                END IF

                                ids(targetid) = id2

                            ELSE

                                'the number of array elements required is known AND
                                'the number of elements in the array to be passed is known



                                'REMOVE FOR TESTING PURPOSES ONLY!!! SHOULD BE UNREM'd!
                                'print id.arrayelements,nelereq
                                '             1       ,  2

                                IF id.arrayelements <> nelereq THEN Give_Error "Passing arrays with a differing number of elements to a SUB/FUNCTION is not supported (yet)": EXIT FUNCTION



                            END IF
                        END IF


                        e$ = refer(e$, sourcetyp, 1)
                        IF Error_Happened THEN EXIT FUNCTION
                        GOTO dontevaluate
                    END IF












                    'note: not an array...

                    'target is not an array

                    IF (targettyp AND ISSTRING) = 0 THEN
                        IF (sourcetyp AND ISREFERENCE) THEN
                            idnum = VAL(LEFT$(e$, INSTR(e$, sp3) - 1)) 'id# of sourcetyp

                            targettyp2 = targettyp: sourcetyp2 = sourcetyp

                            'get info about source/target
                            arr = 0: IF (sourcetyp2 AND ISARRAY) THEN arr = 1
                            passudtelement = 0: IF (targettyp2 AND ISUDT) = 0 AND (sourcetyp2 AND ISUDT) <> 0 THEN passudtelement = 1: sourcetyp2 = sourcetyp2 - ISUDT

                            'remove flags irrelevant for comparison... ISPOINTER,ISREFERENCE,ISINCONVENTIONALMEMORY,ISARRAY
                            targettyp2 = targettyp2 AND (511 + ISOFFSETINBITS + ISUDT + ISFLOAT + ISSTRING)
                            sourcetyp2 = sourcetyp2 AND (511 + ISOFFSETINBITS + ISUDT + ISFLOAT + ISSTRING)

                            'compare types
                            IF sourcetyp2 = targettyp2 THEN

                                IF sourcetyp AND ISUDT THEN
                                    'udt/udt array

                                    'get info
                                    udtrefid = VAL(e$)
                                    getid udtrefid
                                    IF Error_Happened THEN EXIT FUNCTION
                                    udtrefi = INSTR(e$, sp3) 'end of id
                                    udtrefi2 = INSTR(udtrefi + 1, e$, sp3) 'end of u
                                    udtrefu = VAL(MID$(e$, udtrefi + 1, udtrefi2 - udtrefi - 1))
                                    udtrefi3 = INSTR(udtrefi2 + 1, e$, sp3) 'skip e
                                    udtrefe = VAL(MID$(e$, udtrefi2 + 1, udtrefi3 - udtrefi2 - 1))
                                    o$ = RIGHT$(e$, LEN(e$) - udtrefi3)
                                    'note: most of the UDT info above is not required

                                    IF arr THEN
                                        n2$ = scope$ + "ARRAY_UDT_" + RTRIM$(id.n) + "[0]"
                                    ELSE
                                        n2$ = scope$ + "UDT_" + RTRIM$(id.n)
                                    END IF

                                    e$ = "(void*)( ((char*)(" + n2$ + ")) + (" + o$ + ") )"

                                    'convert void* to target type*
                                    IF passudtelement THEN e$ = "(" + typ2ctyp$(targettyp2 + (targettyp AND ISUNSIGNED), "") + "*)" + e$
                                    IF Error_Happened THEN EXIT FUNCTION

                                ELSE
                                    'not a udt
                                    IF arr THEN
                                        IF (sourcetyp2 AND ISOFFSETINBITS) THEN Give_Error "Cannot pass BIT array offsets yet": EXIT FUNCTION
                                        e$ = "(&(" + refer(e$, sourcetyp, 0) + "))"
                                        IF Error_Happened THEN EXIT FUNCTION
                                    ELSE
                                        e$ = refer(e$, sourcetyp, 1)
                                        IF Error_Happened THEN EXIT FUNCTION
                                    END IF

                                    'note: signed/unsigned mismatch requires casting
                                    IF (sourcetyp AND ISUNSIGNED) <> (targettyp AND ISUNSIGNED) THEN
                                        e$ = "(" + typ2ctyp$(targettyp2 + (targettyp AND ISUNSIGNED), "") + "*)" + e$
                                        IF Error_Happened THEN EXIT FUNCTION
                                    END IF

                                END IF 'udt?

                                'force recompile if target needs to be in cmem and the source is not
                                IF MID$(sfcmemargs(targetid), curarg, 1) = CHR$(1) THEN 'cmem required?
                                    IF cmemlist(idnum) = 0 THEN
                                        cmemlist(idnum) = 1
                                        recompile = 1
                                    END IF
                                END IF

                                GOTO dontevaluate
                            END IF 'similar

                            'IF sourcetyp2 = targettyp2 THEN
                            'IF arr THEN
                            'IF (sourcetyp2 AND ISOFFSETINBITS) THEN Give_Error "Cannot pass BIT array offsets yet": EXIT FUNCTION
                            'e$ = "(&(" + refer(e$, sourcetyp, 0) + "))"
                            'ELSE
                            'e$ = refer(e$, sourcetyp, 1)
                            'END IF
                            'GOTO dontevaluate
                            'END IF

                        END IF 'source is a reference

                    ELSE 'string
                        'its a string

                        IF (sourcetyp AND ISREFERENCE) THEN
                            idnum = VAL(LEFT$(e$, INSTR(e$, sp3) - 1)) 'id# of sourcetyp
                            IF MID$(sfcmemargs(targetid), curarg, 1) = CHR$(1) THEN 'cmem required?
                                IF cmemlist(idnum) = 0 THEN
                                    cmemlist(idnum) = 1
                                    recompile = 1
                                END IF
                            END IF
                        END IF 'reference

                    END IF 'string

                END IF 'dereference was not used
            END IF 'pointer


            'note: Target is not a pointer...

            'IF (targettyp AND ISSTRING) = 0 THEN
            'IF (sourcetyp AND ISREFERENCE) THEN
            'targettyp2 = targettyp: sourcetyp2 = sourcetyp - ISREFERENCE
            'IF (sourcetyp2 AND ISINCONVENTIONALMEMORY) THEN sourcetyp2 = sourcetyp2 - ISINCONVENTIONALMEMORY
            'IF sourcetyp2 = targettyp2 THEN e$ = refer(e$, sourcetyp, 1): GOTO dontevaluate
            'END IF
            'END IF
            'END IF

            'String-numeric mismatch?
            IF targettyp AND ISSTRING THEN
                IF (sourcetyp AND ISSTRING) = 0 THEN
                    nth = curarg
                    IF omitarg_last <> 0 AND nth > omitarg_last THEN nth = nth - 1
                    IF ids(targetid).args = 1 THEN Give_Error "String required for function": EXIT FUNCTION
                    Give_Error str_nth$(nth) + " function argument requires a string": EXIT FUNCTION
                END IF
            END IF
            IF (targettyp AND ISSTRING) = 0 THEN
                IF sourcetyp AND ISSTRING THEN
                    nth = curarg
                    IF omitarg_last <> 0 AND nth > omitarg_last THEN nth = nth - 1
                    IF ids(targetid).args = 1 THEN Give_Error "Number required for function": EXIT FUNCTION
                    Give_Error str_nth$(nth) + " function argument requires a number": EXIT FUNCTION
                END IF
            END IF

            'change to "non-pointer" value
            IF (sourcetyp AND ISREFERENCE) THEN
                e$ = refer(e$, sourcetyp, 0)
                IF Error_Happened THEN EXIT FUNCTION
            END IF

            IF explicitreference = 0 THEN
                IF targettyp AND ISUDT THEN
                    nth = curarg
                    IF omitarg_last <> 0 AND nth > omitarg_last THEN nth = nth - 1
                    x$ = "'" + RTRIM$(udtxcname(targettyp AND 511)) + "'"
                    IF ids(targetid).args = 1 THEN Give_Error "TYPE " + x$ + " required for function": EXIT FUNCTION
                    Give_Error str_nth$(nth) + " function argument requires TYPE " + x$: EXIT FUNCTION
                END IF
            ELSE
                IF sourcetyp AND ISUDT THEN Give_Error "Number required for function": EXIT FUNCTION
            END IF

            'round to integer if required
            IF (sourcetyp AND ISFLOAT) THEN
                IF (targettyp AND ISFLOAT) = 0 THEN
                    '**32 rounding fix
                    bits = targettyp AND 511
                    IF bits <= 16 THEN e$ = "qbr_float_to_long(" + e$ + ")"
                    IF bits > 16 AND bits < 32 THEN e$ = "qbr_double_to_long(" + e$ + ")"
                    IF bits >= 32 THEN e$ = "qbr(" + e$ + ")"
                END IF
            END IF

            IF explicitreference THEN
                IF (targettyp AND ISOFFSETINBITS) THEN
                    'integer value can fit inside int64
                    e$ = "(int64)(" + e$ + ")"
                ELSE
                    IF (targettyp AND ISFLOAT) THEN
                        IF (targettyp AND 511) = 32 THEN e$ = "(float)(" + e$ + ")"
                        IF (targettyp AND 511) = 64 THEN e$ = "(double)(" + e$ + ")"
                        IF (targettyp AND 511) = 256 THEN e$ = "(long double)(" + e$ + ")"
                    ELSE
                        IF (targettyp AND ISUNSIGNED) THEN
                            IF (targettyp AND 511) = 8 THEN e$ = "(uint8)(" + e$ + ")"
                            IF (targettyp AND 511) = 16 THEN e$ = "(uint16)(" + e$ + ")"
                            IF (targettyp AND 511) = 32 THEN e$ = "(uint32)(" + e$ + ")"
                            IF (targettyp AND 511) = 64 THEN e$ = "(uint64)(" + e$ + ")"
                        ELSE
                            IF (targettyp AND 511) = 8 THEN e$ = "(int8)(" + e$ + ")"
                            IF (targettyp AND 511) = 16 THEN e$ = "(int16)(" + e$ + ")"
                            IF (targettyp AND 511) = 32 THEN e$ = "(int32)(" + e$ + ")"
                            IF (targettyp AND 511) = 64 THEN e$ = "(int64)(" + e$ + ")"
                        END IF
                    END IF 'float?
                END IF 'offset in bits?
            END IF 'explicit?


            IF (targettyp AND ISPOINTER) THEN 'pointer required
                IF (targettyp AND ISSTRING) THEN GOTO dontevaluate 'no changes required
                '20090703
                t$ = typ2ctyp$(targettyp, "")
                IF Error_Happened THEN EXIT FUNCTION
                v$ = "pass" + str2$(uniquenumber)
                'assume numeric type
                IF MID$(sfcmemargs(targetid), curarg, 1) = CHR$(1) THEN 'cmem required?
                    bytesreq = ((targettyp AND 511) + 7) \ 8
                    PRINT #defdatahandle, t$ + " *" + v$ + "=NULL;"
                    PRINT #13, "if(" + v$ + "==NULL){"
                    PRINT #13, "cmem_sp-=" + str2(bytesreq) + ";"
                    PRINT #13, v$ + "=(" + t$ + "*)(dblock+cmem_sp);"
                    PRINT #13, "if (cmem_sp<qbs_cmem_sp) error(257);"
                    PRINT #13, "}"
                    e$ = "&(*" + v$ + "=" + e$ + ")"
                ELSE
                    PRINT #13, t$ + " " + v$ + ";"
                    e$ = "&(" + v$ + "=" + e$ + ")"
                END IF
                GOTO dontevaluate
            END IF

            dontevaluate:

            IF id2.ccall THEN

                'if a forced cast from a returned ccall function is in e$, remove it
                IF LEFT$(e$, 3) = "(  " THEN
                    e$ = removecast$(e$)
                END IF

                IF targettyp AND ISSTRING THEN
                    e$ = "(char*)(" + e$ + ")->chr"
                END IF

                IF LTRIM$(RTRIM$(e$)) = "0" THEN e$ = "NULL"

            END IF

            r$ = r$ + e$

            '***special case****
            IF n$ = "_MEM" THEN
                IF args = 1 THEN
                    IF curarg = 1 THEN r$ = r$ + ")": GOTO evalfuncspecial
                END IF
                IF args = 2 THEN
                    IF curarg = 2 THEN r$ = r$ + ")": GOTO evalfuncspecial
                END IF
            END IF

            IF i <> n AND nocomma = 0 THEN r$ = r$ + ","
            nocomma = 0
            firsti = i + 1
            curarg = curarg + 1
        END IF

        IF (curarg >= omitarg_first AND curarg <= omitarg_last) AND i = n THEN
            targettyp = CVL(MID$(id2.arg, curarg * 4 - 4 + 1, 4))
            'IF (targettyp AND ISSTRING) THEN Give_Error "QB64 doesn't support optional string arguments for functions yet!": EXIT FUNCTION
            FOR fi = 1 TO omitargs: r$ = r$ + ",NULL": NEXT
            curarg = curarg + omitargs
        END IF

    NEXT
END IF

IF n$ = "UBOUND" OR n$ = "LBOUND" THEN
    IF r$ = ",NULL" THEN r$ = ",1"
    IF n$ = "UBOUND" THEN r2$ = "func_ubound(" ELSE r2$ = "func_lbound("
    e$ = refer$(ulboundarray$, sourcetyp, 1)
    IF Error_Happened THEN EXIT FUNCTION
    'note: ID contins refer'ed array info

    arrayelements = id.arrayelements '2009
    IF arrayelements = -1 THEN arrayelements = 1 '2009

    r$ = r2$ + e$ + r$ + "," + str2$(arrayelements) + ")"
    typ& = INTEGER64TYPE - ISPOINTER
    GOTO evalfuncspecial
END IF

IF passomit THEN
    IF omitarg_first THEN r$ = r$ + ",0" ELSE r$ = r$ + ",1"
END IF
r$ = r$ + ")"

evalfuncspecial:

IF n$ = "ABS" THEN typ& = sourcetyp 'ABS Note: ABS() returns argument #1's type

'QB-like conversion of math functions returning floating point values
IF n$ = "SIN" OR n$ = "COS" OR n$ = "TAN" OR n$ = "ATN" OR n$ = "SQR" OR n$ = "LOG" THEN
    b = sourcetyp AND 511
    IF sourcetyp AND ISFLOAT THEN
        'Default is FLOATTYPE
        IF b = 64 THEN typ& = DOUBLETYPE - ISPOINTER
        IF b = 32 THEN typ& = SINGLETYPE - ISPOINTER
    ELSE
        'Default is FLOATTYPE
        IF b <= 32 THEN typ& = DOUBLETYPE - ISPOINTER
        IF b <= 16 THEN typ& = SINGLETYPE - ISPOINTER
    END IF
END IF

IF id2.ret = ISUDT + (1) THEN
    '***special case***
    v$ = "func" + str2$(uniquenumber)
    PRINT #defdatahandle, "mem_block " + v$ + ";"
    r$ = "(" + v$ + "=" + r$ + ")"
END IF

IF id2.ccall THEN
    IF LEFT$(r$, 11) = "(  char*  )" THEN
        r$ = "qbs_new_txt(" + r$ + ")"
    END IF
END IF

IF Debug THEN PRINT #9, "evaluatefunc:out:"; r$
evaluatefunc$ = r$
END FUNCTION

FUNCTION variablesize$ (i AS LONG) 'ID or -1 (if ID already 'loaded')
'Note: assumes whole bytes, no bit offsets/sizes
IF i <> -1 THEN getid i
IF Error_Happened THEN EXIT FUNCTION
'find base size from type
t = id.t: IF t = 0 THEN t = id.arraytype
bytes = (t AND 511) \ 8

IF t AND ISUDT THEN 'correct size for UDTs
    u = t AND 511
    bytes = udtxsize(u) \ 8
END IF

IF t AND ISSTRING THEN 'correct size for strings
    IF t AND ISFIXEDLENGTH THEN
        bytes = id.tsize
    ELSE
        IF id.arraytype THEN Give_Error "Cannot determine size of variable-length string array": EXIT FUNCTION
        variablesize$ = scope$ + "STRING_" + RTRIM$(id.n) + "->len"
        EXIT FUNCTION
    END IF
END IF

IF id.arraytype THEN 'multiply size for arrays
    n$ = RTRIM$(id.callname)
    s$ = str2(bytes) + "*(" + n$ + "[2]&1)" 'note: multiplying by 0 if array not currently defined (affects dynamic arrays)
    arrayelements = id.arrayelements: IF arrayelements = -1 THEN arrayelements = 1 '2009
    FOR i2 = 1 TO arrayelements
        s$ = s$ + "*" + n$ + "[" + str2(i2 * 4 - 4 + 5) + "]"
    NEXT
    variablesize$ = "(" + s$ + ")"
    EXIT FUNCTION
END IF

variablesize$ = str2(bytes)
END FUNCTION



FUNCTION evaluatetotyp$ (a2$, targettyp AS LONG)
'note: 'evaluatetotyp' no longer performs 'fixoperationorder' on a2$ (in many cases, this has already been done)
a$ = a2$
e$ = evaluate(a$, sourcetyp)
IF Error_Happened THEN EXIT FUNCTION

'Offset protection:
IF sourcetyp AND ISOFFSET THEN
    IF (targettyp AND ISOFFSET) = 0 AND targettyp >= 0 THEN
        Give_Error "Cannot convert _OFFSET type to other types": EXIT FUNCTION
    END IF
END IF

'-5 size
'-6 offset
IF targettyp = -4 OR targettyp = -5 OR targettyp = -6 THEN '? -> byte_element(offset,element size in bytes)
    IF (sourcetyp AND ISREFERENCE) = 0 THEN Give_Error "Expected variable name/array element": EXIT FUNCTION
    IF (sourcetyp AND ISOFFSETINBITS) THEN Give_Error "Variable/element cannot be BIT aligned": EXIT FUNCTION

    ' print "-4: evaluated as ["+e$+"]":sleep 1

    IF (sourcetyp AND ISUDT) THEN 'User Defined Type -> byte_element(offset,bytes)
        idnumber = VAL(e$)
        i = INSTR(e$, sp3): e$ = RIGHT$(e$, LEN(e$) - i)
        u = VAL(e$) 'closest parent
        i = INSTR(e$, sp3): e$ = RIGHT$(e$, LEN(e$) - i)
        E = VAL(e$)
        i = INSTR(e$, sp3): e$ = RIGHT$(e$, LEN(e$) - i)
        o$ = e$
        getid idnumber
        IF Error_Happened THEN EXIT FUNCTION
        n$ = "UDT_" + RTRIM$(id.n)
        IF id.arraytype THEN
            n$ = "ARRAY_" + n$ + "[0]"
            'whole array reference examplename()?
            IF LEFT$(o$, 3) = "(0)" THEN
                'use -2 type method
                GOTO method2usealludt
            END IF
        END IF
        'determine size of element
        IF E = 0 THEN 'no specific element, use size of entire type
            bytes$ = str2(udtxsize(u) \ 8)
        ELSE 'a specific element
            bytes$ = str2(udtesize(E) \ 8)
        END IF
        dst$ = "(((char*)" + scope$ + n$ + ")+(" + o$ + "))"
        evaluatetotyp$ = "byte_element((uint64)" + dst$ + "," + bytes$ + "," + NewByteElement$ + ")"
        IF targettyp = -5 THEN evaluatetotyp$ = bytes$
        IF targettyp = -6 THEN evaluatetotyp$ = dst$
        EXIT FUNCTION
    END IF

    IF (sourcetyp AND ISARRAY) THEN 'Array reference -> byte_element(offset,bytes)
        'whole array reference examplename()?
        IF RIGHT$(e$, 2) = sp3 + "0" THEN
            'use -2 type method
            IF sourcetyp AND ISSTRING THEN
                IF (sourcetyp AND ISFIXEDLENGTH) = 0 THEN
                    Give_Error "Cannot pass array of variable-length strings": EXIT FUNCTION
                END IF
            END IF
            GOTO method2useall
        END IF
        'assume a specific element
        IF sourcetyp AND ISSTRING THEN
            IF sourcetyp AND ISFIXEDLENGTH THEN
                idnumber = VAL(e$)
                getid idnumber
                IF Error_Happened THEN EXIT FUNCTION
                bytes$ = str2(id.tsize)
                e$ = refer(e$, sourcetyp, 0)
                IF Error_Happened THEN EXIT FUNCTION
                evaluatetotyp$ = "byte_element((uint64)" + e$ + "->chr," + bytes$ + "," + NewByteElement$ + ")"
                IF targettyp = -5 THEN evaluatetotyp$ = bytes$
                IF targettyp = -6 THEN evaluatetotyp$ = e$ + "->chr"
            ELSE
                e$ = refer(e$, sourcetyp, 0)
                IF Error_Happened THEN EXIT FUNCTION

                evaluatetotyp$ = "byte_element((uint64)" + e$ + "->chr," + e$ + "->len," + NewByteElement$ + ")"
                IF targettyp = -5 THEN evaluatetotyp$ = e$ + "->len"
                IF targettyp = -6 THEN evaluatetotyp$ = e$ + "->chr"
            END IF
            EXIT FUNCTION
        END IF
        e$ = refer(e$, sourcetyp, 0)
        IF Error_Happened THEN EXIT FUNCTION
        e$ = "(&(" + e$ + "))"
        bytes$ = str2((sourcetyp AND 511) \ 8)
        evaluatetotyp$ = "byte_element((uint64)" + e$ + "," + bytes$ + "," + NewByteElement$ + ")"
        IF targettyp = -5 THEN evaluatetotyp$ = bytes$
        IF targettyp = -6 THEN evaluatetotyp$ = e$
        EXIT FUNCTION
    END IF

    IF sourcetyp AND ISSTRING THEN 'String -> byte_element(offset,bytes)
        IF sourcetyp AND ISFIXEDLENGTH THEN
            idnumber = VAL(e$)
            getid idnumber
            IF Error_Happened THEN EXIT FUNCTION
            bytes$ = str2(id.tsize)
            e$ = refer(e$, sourcetyp, 0)
            IF Error_Happened THEN EXIT FUNCTION
        ELSE
            e$ = refer(e$, sourcetyp, 0)
            IF Error_Happened THEN EXIT FUNCTION
            bytes$ = e$ + "->len"
        END IF
        evaluatetotyp$ = "byte_element((uint64)" + e$ + "->chr," + bytes$ + "," + NewByteElement$ + ")"
        IF targettyp = -5 THEN evaluatetotyp$ = bytes$
        IF targettyp = -6 THEN evaluatetotyp$ = e$ + "->chr"
        EXIT FUNCTION
    END IF

    'Standard variable -> byte_element(offset,bytes)
    e$ = refer(e$, sourcetyp, 1) 'get the variable's formal name
    IF Error_Happened THEN EXIT FUNCTION
    size = (sourcetyp AND 511) \ 8 'calculate its size in bytes
    evaluatetotyp$ = "byte_element((uint64)" + e$ + "," + str2(size) + "," + NewByteElement$ + ")"
    IF targettyp = -5 THEN evaluatetotyp$ = str2(size)
    IF targettyp = -6 THEN evaluatetotyp$ = e$
    EXIT FUNCTION

END IF '-4, -5, -6




IF targettyp = -8 THEN '? -> _MEM structure helper {offset, fullsize, typeval, elementsize, sf_mem_lock|???}
    IF (sourcetyp AND ISREFERENCE) = 0 THEN Give_Error "Expected variable name/array element": EXIT FUNCTION
    IF (sourcetyp AND ISOFFSETINBITS) THEN Give_Error "Variable/element cannot be BIT aligned": EXIT FUNCTION


    IF (sourcetyp AND ISUDT) THEN 'User Defined Type -> byte_element(offset,bytes)
        idnumber = VAL(e$)
        i = INSTR(e$, sp3): e$ = RIGHT$(e$, LEN(e$) - i)
        u = VAL(e$) 'closest parent
        i = INSTR(e$, sp3): e$ = RIGHT$(e$, LEN(e$) - i)
        E = VAL(e$)
        i = INSTR(e$, sp3): e$ = RIGHT$(e$, LEN(e$) - i)
        o$ = e$
        getid idnumber
        IF Error_Happened THEN EXIT FUNCTION
        n$ = "UDT_" + RTRIM$(id.n)
        IF id.arraytype THEN
            n$ = "ARRAY_" + n$ + "[0]"
            'whole array reference examplename()?
            IF LEFT$(o$, 3) = "(0)" THEN
                'use -7 type method
                GOTO method2usealludt__7
            END IF
        END IF
        'determine size of element
        IF E = 0 THEN 'no specific element, use size of entire type
            bytes$ = str2(udtxsize(u) \ 8)
            t1 = ISUDT + udtetype(u)
        ELSE 'a specific element
            bytes$ = str2(udtesize(E) \ 8)
            t1 = udtetype(E)
        END IF
        dst$ = "(((char*)" + scope$ + n$ + ")+(" + o$ + "))"
        'evaluatetotyp$ = "byte_element((uint64)" + dst$ + "," + bytes$ + "," + NewByteElement$ + ")"
        'IF targettyp = -5 THEN evaluatetotyp$ = bytes$
        'IF targettyp = -6 THEN evaluatetotyp$ = dst$

        t = Type2MemTypeValue(t1)
        evaluatetotyp$ = "(ptrszint)" + dst$ + "," + bytes$ + "," + str2(t) + "," + bytes$ + ",sf_mem_lock"

        EXIT FUNCTION
    END IF

    IF (sourcetyp AND ISARRAY) THEN 'Array reference -> byte_element(offset,bytes)
        'whole array reference examplename()?
        IF RIGHT$(e$, 2) = sp3 + "0" THEN
            'use -7 type method
            IF sourcetyp AND ISSTRING THEN
                IF (sourcetyp AND ISFIXEDLENGTH) = 0 THEN
                    Give_Error "Cannot pass array of variable-length strings": EXIT FUNCTION
                END IF
            END IF
            GOTO method2useall__7
        END IF

        idnumber = VAL(e$)
        getid idnumber
        IF Error_Happened THEN EXIT FUNCTION
        n$ = RTRIM$(id.callname)
        lk$ = "(mem_lock*)((ptrszint*)" + n$ + ")[" + str2(4 * id.arrayelements + 4 + 1 - 1) + "]"

        'assume a specific element

        IF sourcetyp AND ISSTRING THEN
            IF sourcetyp AND ISFIXEDLENGTH THEN
                bytes$ = str2(id.tsize)
                e$ = refer(e$, sourcetyp, 0)
                IF Error_Happened THEN EXIT FUNCTION
                'evaluatetotyp$ = "byte_element((uint64)" + e$ + "->chr," + bytes$ + "," + NewByteElement$ + ")"
                'IF targettyp = -5 THEN evaluatetotyp$ = bytes$
                'IF targettyp = -6 THEN evaluatetotyp$ = e$ + "->chr"

                t = Type2MemTypeValue(sourcetyp)
                evaluatetotyp$ = "(ptrszint)" + e$ + "->chr," + bytes$ + "," + str2(t) + "," + bytes$ + "," + lk$

            ELSE

                Give_Error "_MEMELEMENT cannot reference variable-length strings": EXIT FUNCTION

            END IF
            EXIT FUNCTION
        END IF

        e$ = refer(e$, sourcetyp, 0)
        IF Error_Happened THEN EXIT FUNCTION
        e$ = "(&(" + e$ + "))"
        bytes$ = str2((sourcetyp AND 511) \ 8)
        'evaluatetotyp$ = "byte_element((uint64)" + e$ + "," + bytes$ + "," + NewByteElement$ + ")"
        'IF targettyp = -5 THEN evaluatetotyp$ = bytes$
        'IF targettyp = -6 THEN evaluatetotyp$ = e$

        t = Type2MemTypeValue(sourcetyp)
        evaluatetotyp$ = "(ptrszint)" + e$ + "," + bytes$ + "," + str2(t) + "," + bytes$ + "," + lk$

        EXIT FUNCTION
    END IF 'isarray

    IF sourcetyp AND ISSTRING THEN 'String -> byte_element(offset,bytes)
        IF sourcetyp AND ISFIXEDLENGTH THEN
            idnumber = VAL(e$)
            getid idnumber
            IF Error_Happened THEN EXIT FUNCTION
            bytes$ = str2(id.tsize)
            e$ = refer(e$, sourcetyp, 0)
            IF Error_Happened THEN EXIT FUNCTION
        ELSE
            Give_Error "_MEMELEMENT cannot reference variable-length strings": EXIT FUNCTION
        END IF

        'evaluatetotyp$ = "byte_element((uint64)" + e$ + "->chr," + bytes$ + "," + NewByteElement$ + ")"
        'IF targettyp = -5 THEN evaluatetotyp$ = bytes$
        'IF targettyp = -6 THEN evaluatetotyp$ = e$ + "->chr"

        t = Type2MemTypeValue(sourcetyp)
        evaluatetotyp$ = "(ptrszint)" + e$ + "->chr," + bytes$ + "," + str2(t) + "," + bytes$ + ",sf_mem_lock"

        EXIT FUNCTION
    END IF

    'Standard variable -> byte_element(offset,bytes)
    e$ = refer(e$, sourcetyp, 1) 'get the variable's formal name
    IF Error_Happened THEN EXIT FUNCTION
    size = (sourcetyp AND 511) \ 8 'calculate its size in bytes
    'evaluatetotyp$ = "byte_element((uint64)" + e$ + "," + str2(size) + "," + NewByteElement$ + ")"
    'IF targettyp = -5 THEN evaluatetotyp$ = str2(size)
    'IF targettyp = -6 THEN evaluatetotyp$ = e$

    t = Type2MemTypeValue(sourcetyp)
    evaluatetotyp$ = "(ptrszint)" + e$ + "," + str2(size) + "," + str2(t) + "," + str2(size) + ",sf_mem_lock"

    EXIT FUNCTION

END IF '-8










IF targettyp = -7 THEN '? -> _MEM structure helper {offset, fullsize, typeval, elementsize, sf_mem_lock|???}
    method2useall__7:
    IF (sourcetyp AND ISREFERENCE) = 0 THEN Give_Error "Expected variable name/array element": EXIT FUNCTION
    IF (sourcetyp AND ISOFFSETINBITS) THEN Give_Error "Variable/element cannot be BIT aligned": EXIT FUNCTION

    'User Defined Type
    IF (sourcetyp AND ISUDT) THEN
        '           print "CI: -2 type from a UDT":sleep 1
        idnumber = VAL(e$)
        i = INSTR(e$, sp3): e$ = RIGHT$(e$, LEN(e$) - i)
        u = VAL(e$) 'closest parent
        i = INSTR(e$, sp3): e$ = RIGHT$(e$, LEN(e$) - i)
        E = VAL(e$)
        i = INSTR(e$, sp3): e$ = RIGHT$(e$, LEN(e$) - i)

        o$ = e$
        getid idnumber
        IF Error_Happened THEN EXIT FUNCTION
        n$ = "UDT_" + RTRIM$(id.n): IF id.arraytype THEN n$ = "ARRAY_" + n$ + "[0]"
        method2usealludt__7:
        bytes$ = variablesize$(-1) + "-(" + o$ + ")"
        IF Error_Happened THEN EXIT FUNCTION
        dst$ = "(((char*)" + scope$ + n$ + ")+(" + o$ + "))"


        'evaluatetotyp$ = "byte_element((uint64)" + dst$ + "," + bytes$ + "," + NewByteElement$ + ")"

        'note: myudt.myelement results in a size of 1 because it is a continuous run of no consistent granularity
        IF E <> 0 THEN size = 1 ELSE size = udtxsize(u) \ 8

        t = Type2MemTypeValue(sourcetyp)
        evaluatetotyp$ = "(ptrszint)" + dst$ + "," + bytes$ + "," + str2(t) + "," + str2(size) + ",sf_mem_lock"

        EXIT FUNCTION
    END IF

    'Array reference
    IF (sourcetyp AND ISARRAY) THEN
        IF sourcetyp AND ISSTRING THEN
            IF (sourcetyp AND ISFIXEDLENGTH) = 0 THEN
                Give_Error "_MEM cannot reference variable-length strings": EXIT FUNCTION
            END IF
        END IF

        idnumber = VAL(e$)
        getid idnumber
        IF Error_Happened THEN EXIT FUNCTION

        n$ = RTRIM$(id.callname)
        lk$ = "(mem_lock*)((ptrszint*)" + n$ + ")[" + str2(4 * id.arrayelements + 4 + 1 - 1) + "]"

        tsize = id.tsize 'used later to determine element size of fixed length strings
        'note: array references consist of idnumber|unmultiplied-element-index
        index$ = RIGHT$(e$, LEN(e$) - INSTR(e$, sp3)) 'get element index
        bytes$ = variablesize$(-1)
        IF Error_Happened THEN EXIT FUNCTION
        e$ = refer(e$, sourcetyp, 0)
        IF Error_Happened THEN EXIT FUNCTION

        IF sourcetyp AND ISSTRING THEN
            e$ = "((" + e$ + ")->chr)" '[2013] handle fixed string arrays differently because they are already pointers
        ELSE
            e$ = "(&(" + e$ + "))"
        END IF

        '           print "CI: array: e$["+e$+"], bytes$["+bytes$+"]":sleep 1
        'calculate size of elements
        IF sourcetyp AND ISSTRING THEN
            bytes = tsize
        ELSE
            bytes = (sourcetyp AND 511) \ 8
        END IF
        bytes$ = bytes$ + "-(" + str2(bytes) + "*(" + index$ + "))"

        t = Type2MemTypeValue(sourcetyp)
        evaluatetotyp$ = "(ptrszint)" + e$ + "," + bytes$ + "," + str2(t) + "," + str2(bytes) + "," + lk$

        EXIT FUNCTION
    END IF

    'String
    IF sourcetyp AND ISSTRING THEN
        IF (sourcetyp AND ISFIXEDLENGTH) = 0 THEN Give_Error "_MEM cannot reference variable-length strings": EXIT FUNCTION

        idnumber = VAL(e$)
        getid idnumber: IF Error_Happened THEN EXIT FUNCTION
        bytes$ = str2(id.tsize)
        e$ = refer(e$, sourcetyp, 0): IF Error_Happened THEN EXIT FUNCTION

        t = Type2MemTypeValue(sourcetyp)
        evaluatetotyp$ = "(ptrszint)" + e$ + "->chr," + bytes$ + "," + str2(t) + "," + bytes$ + ",sf_mem_lock"

        EXIT FUNCTION
    END IF

    'Standard variable -> byte_element(offset,bytes)
    e$ = refer(e$, sourcetyp, 1) 'get the variable's formal name
    IF Error_Happened THEN EXIT FUNCTION
    size = (sourcetyp AND 511) \ 8 'calculate its size in bytes

    t = Type2MemTypeValue(sourcetyp)
    evaluatetotyp$ = "(ptrszint)" + e$ + "," + str2(size) + "," + str2(t) + "," + str2(size) + ",sf_mem_lock"

    EXIT FUNCTION

END IF '-7 _MEM structure helper


IF targettyp = -2 THEN '? -> byte_element(offset,max possible bytes)
    method2useall:
    ' print "CI: eval2typ detected target type of -2 for ["+a2$+"] evaluated as ["+e$+"]":sleep 1

    IF (sourcetyp AND ISREFERENCE) = 0 THEN Give_Error "Expected variable name/array element": EXIT FUNCTION
    IF (sourcetyp AND ISOFFSETINBITS) THEN Give_Error "Variable/element cannot be BIT aligned": EXIT FUNCTION

    'User Defined Type -> byte_element(offset,bytes)
    IF (sourcetyp AND ISUDT) THEN
        '           print "CI: -2 type from a UDT":sleep 1
        idnumber = VAL(e$)
        i = INSTR(e$, sp3): e$ = RIGHT$(e$, LEN(e$) - i)
        u = VAL(e$) 'closest parent
        i = INSTR(e$, sp3): e$ = RIGHT$(e$, LEN(e$) - i)
        E = VAL(e$)
        i = INSTR(e$, sp3): e$ = RIGHT$(e$, LEN(e$) - i)
        o$ = e$
        getid idnumber
        IF Error_Happened THEN EXIT FUNCTION
        n$ = "UDT_" + RTRIM$(id.n): IF id.arraytype THEN n$ = "ARRAY_" + n$ + "[0]"
        method2usealludt:
        bytes$ = variablesize$(-1) + "-(" + o$ + ")"
        IF Error_Happened THEN EXIT FUNCTION
        dst$ = "(((char*)" + scope$ + n$ + ")+(" + o$ + "))"
        evaluatetotyp$ = "byte_element((uint64)" + dst$ + "," + bytes$ + "," + NewByteElement$ + ")"
        IF targettyp = -5 THEN evaluatetotyp$ = bytes$
        IF targettyp = -6 THEN evaluatetotyp$ = dst$
        EXIT FUNCTION
    END IF

    'Array reference -> byte_element(offset,bytes)
    IF (sourcetyp AND ISARRAY) THEN
        'array of variable length strings (special case, can only refer to single element)
        IF sourcetyp AND ISSTRING THEN
            IF (sourcetyp AND ISFIXEDLENGTH) = 0 THEN
                e$ = refer(e$, sourcetyp, 0)
                IF Error_Happened THEN EXIT FUNCTION
                evaluatetotyp$ = "byte_element((uint64)" + e$ + "->chr," + e$ + "->len," + NewByteElement$ + ")"
                IF targettyp = -5 THEN evaluatetotyp$ = e$ + "->len"
                IF targettyp = -6 THEN evaluatetotyp$ = e$ + "->chr"
                EXIT FUNCTION
            END IF
        END IF
        idnumber = VAL(e$)
        getid idnumber
        IF Error_Happened THEN EXIT FUNCTION
        tsize = id.tsize 'used later to determine element size of fixed length strings
        'note: array references consist of idnumber|unmultiplied-element-index
        index$ = RIGHT$(e$, LEN(e$) - INSTR(e$, sp3)) 'get element index
        bytes$ = variablesize$(-1)
        IF Error_Happened THEN EXIT FUNCTION
        e$ = refer(e$, sourcetyp, 0)
        IF Error_Happened THEN EXIT FUNCTION
        e$ = "(&(" + e$ + "))"
        '           print "CI: array: e$["+e$+"], bytes$["+bytes$+"]":sleep 1
        'calculate size of elements
        IF sourcetyp AND ISSTRING THEN
            bytes = tsize
        ELSE
            bytes = (sourcetyp AND 511) \ 8
        END IF
        bytes$ = bytes$ + "-(" + str2(bytes) + "*(" + index$ + "))"
        evaluatetotyp$ = "byte_element((uint64)" + e$ + "," + bytes$ + "," + NewByteElement$ + ")"
        IF targettyp = -5 THEN evaluatetotyp$ = bytes$
        IF targettyp = -6 THEN evaluatetotyp$ = e$
        '           print "CI: array ->["+"byte_element((uint64)" + e$ + "," + bytes$+ ","+NewByteElement$+")"+"]":sleep 1
        EXIT FUNCTION
    END IF

    'String -> byte_element(offset,bytes)
    IF sourcetyp AND ISSTRING THEN
        IF sourcetyp AND ISFIXEDLENGTH THEN
            idnumber = VAL(e$)
            getid idnumber
            IF Error_Happened THEN EXIT FUNCTION
            bytes$ = str2(id.tsize)
            e$ = refer(e$, sourcetyp, 0)
            IF Error_Happened THEN EXIT FUNCTION
        ELSE
            e$ = refer(e$, sourcetyp, 0)
            IF Error_Happened THEN EXIT FUNCTION
            bytes$ = e$ + "->len"
        END IF
        evaluatetotyp$ = "byte_element((uint64)" + e$ + "->chr," + bytes$ + "," + NewByteElement$ + ")"
        IF targettyp = -5 THEN evaluatetotyp$ = bytes$
        IF targettyp = -6 THEN evaluatetotyp$ = e$ + "->chr"
        EXIT FUNCTION
    END IF

    'Standard variable -> byte_element(offset,bytes)
    e$ = refer(e$, sourcetyp, 1) 'get the variable's formal name
    IF Error_Happened THEN EXIT FUNCTION
    size = (sourcetyp AND 511) \ 8 'calculate its size in bytes
    evaluatetotyp$ = "byte_element((uint64)" + e$ + "," + str2(size) + "," + NewByteElement$ + ")"
    IF targettyp = -5 THEN evaluatetotyp$ = str2(size)
    IF targettyp = -6 THEN evaluatetotyp$ = e$
    EXIT FUNCTION

END IF '-2 byte_element(offset,bytes)



'string?
IF (sourcetyp AND ISSTRING) <> (targettyp AND ISSTRING) THEN
    Give_Error "Illegal string-number conversion": EXIT FUNCTION
END IF

IF (sourcetyp AND ISSTRING) THEN
    evaluatetotyp$ = e$
    IF (sourcetyp AND ISREFERENCE) THEN
        evaluatetotyp$ = refer(e$, sourcetyp, 0)
        IF Error_Happened THEN EXIT FUNCTION
    END IF
    EXIT FUNCTION
END IF

'pointer required?
IF (targettyp AND ISPOINTER) THEN
    Give_Error "evaluatetotyp received a request for a pointer! (as yet unsupported)": EXIT FUNCTION
    '...
    Give_Error "Invalid pointer": EXIT FUNCTION
END IF

'change to "non-pointer" value
IF (sourcetyp AND ISREFERENCE) THEN
    e$ = refer(e$, sourcetyp, 0)
    IF Error_Happened THEN EXIT FUNCTION
END IF
'check if successful
IF (sourcetyp AND ISPOINTER) THEN
    Give_Error "evaluatetotyp couldn't convert pointer type!": EXIT FUNCTION
END IF

'round to integer if required
IF (sourcetyp AND ISFLOAT) THEN
    IF (targettyp AND ISFLOAT) = 0 THEN
        bits = targettyp AND 511
        '**32 rounding fix
        IF bits <= 16 THEN e$ = "qbr_float_to_long(" + e$ + ")"
        IF bits > 16 AND bits < 32 THEN e$ = "qbr_double_to_long(" + e$ + ")"
        IF bits >= 32 THEN e$ = "qbr(" + e$ + ")"
    END IF
END IF

evaluatetotyp$ = e$
END FUNCTION

FUNCTION findid& (n2$)
n$ = UCASE$(n2$) 'case insensitive

'return all strings as 'not found'
IF ASC(n$) = 34 THEN GOTO noid

'if findidsecondarg was set, it will be used for finding the name of a sub (not a func or variable)
secondarg$ = findidsecondarg: findidsecondarg = ""

'if findanotherid was set, findid will continue scan from last index, otherwise, it will begin a new search
findanother = findanotherid: findanotherid = 0
IF findanother <> 0 AND findidinternal <> 2 THEN Give_Error "FINDID() ERROR: Invalid repeat search requested!": EXIT FUNCTION 'cannot continue search, no more indexes left!
IF Error_Happened THEN EXIT FUNCTION
'(the above should never happen)
findid& = 2 '2=not finished searching all indexes

'seperate symbol from name (if a symbol has been added), this is the only way symbols can be passed to findid
i = 0
i = INSTR(n$, "~"): IF i THEN GOTO gotsc
i = INSTR(n$, "`"): IF i THEN GOTO gotsc
i = INSTR(n$, "%"): IF i THEN GOTO gotsc
i = INSTR(n$, "&"): IF i THEN GOTO gotsc
i = INSTR(n$, "!"): IF i THEN GOTO gotsc
i = INSTR(n$, "#"): IF i THEN GOTO gotsc
i = INSTR(n$, "$"): IF i THEN GOTO gotsc
gotsc:
IF i THEN
    sc$ = RIGHT$(n$, LEN(n$) - i + 1): n$ = LEFT$(n$, i - 1)
    IF sc$ = "`" OR sc$ = "~`" THEN sc$ = sc$ + "1" 'clarify abbreviated 1 bit reference
ELSE
    '''    'no symbol passed, so check what symbol could be assumed under the current DEF...
    '''    v = ASC(n$): IF v = 95 THEN v = 27 ELSE v = v - 64
    '''    IF v >= 1 AND v <= 27 THEN 'safeguard against n$ not being a standard name
    '''        couldhavesc$ = defineextaz(v)
    '''        IF couldhavesc$ = "`" OR couldhavesc$ = "~`" THEN couldhavesc$ = couldhavesc$ + "1" 'clarify abbreviated 1 bit reference
    '''    END IF 'safeguard
END IF

'optomizations for later comparisons
insf$ = subfunc + SPACE$(256 - LEN(subfunc))
secondarg$ = secondarg$ + SPACE$(256 - LEN(secondarg$))
IF LEN(sc$) THEN scpassed = 1: sc$ = sc$ + SPACE$(8 - LEN(sc$)) ELSE scpassed = 0
'''IF LEN(couldhavesc$) THEN couldhavesc$ = couldhavesc$ + SPACE$(8 - LEN(couldhavesc$)): couldhavescpassed = 1 ELSE couldhavescpassed = 0
IF LEN(n$) < 256 THEN n$ = n$ + SPACE$(256 - LEN(n$))

'FUNCTION HashFind (a$, searchflags, resultflags, resultreference)
'(0,1,2)z=hashfind[rev]("RUMI",Hashflag_label,resflag,resref)
'0=doesn't exist
'1=found, no more items to scan
'2=found, more items still to scan

'NEW HASH SYSTEM
n$ = RTRIM$(n$)
IF findanother THEN
    hashretry:
    z = HashFindCont(unrequired, i)
ELSE
    z = HashFindRev(n$, 1, unrequired, i)
END IF
findidinternal = z
IF z = 0 THEN GOTO noid
findid = z


'continue from previous position?
''IF findanother THEN start = findidinternal ELSE start = idn

''FOR i = start TO 1 STEP -1

''    findidinternal = i - 1
''    IF findidinternal = 0 THEN findid& = 1 '1=found id, but no more to search

''    IF ids(i).n = n$ THEN 'same name?

'in scope?
IF ids(i).subfunc = 0 AND ids(i).share = 0 THEN 'scope check required (not a shared variable or the name of a sub/function)
    IF ids(i).insubfunc <> insf$ THEN GOTO findidnomatch
END IF

'some subs require a second argument (eg. PUT #, DEF SEG, etc.)
IF ids(i).subfunc = 2 THEN
    IF ASC(ids(i).secondargmustbe) <> 32 THEN 'exists?
        IF secondarg$ <> ids(i).secondargmustbe THEN GOTO findidnomatch
    END IF
    IF ASC(ids(i).secondargcantbe) <> 32 THEN 'exists?
        IF secondarg$ = ids(i).secondargcantbe THEN GOTO findidnomatch
    END IF
END IF 'second sub argument possible

'must have symbol?
'typically for variables defined automatically or by a symbol and not the full type name
imusthave = CVI(ids(i).musthave) 'speed up checks of first 2 characters
amusthave = imusthave AND 255 'speed up checks of first character
IF amusthave <> 32 THEN
    IF scpassed THEN
        IF sc$ = ids(i).musthave THEN GOTO findidok
    END IF
    '''    IF couldhavescpassed THEN
    '''        IF couldhavesc$ = ids(i).musthave THEN GOTO findidok
    '''    END IF
    'Q: why is the above triple-commented?
    'A: because if something must have a symbol to refer to it, then a could-have is
    '   not sufficient, and it could mask shared variables in global scope

    'note: symbol defined fixed length strings cannot be referred to by $ without an extension
    'note: sc$ and couldhavesc$ are already changed from ` to `1 to match stored musthave
    GOTO findidnomatch
END IF

'may have symbol?
'typically for variables formally dim'd
'note: couldhavesc$ needn't be considered for mayhave checks
IF scpassed THEN 'symbol was passed, so it must match the mayhave symbol
    imayhave = CVI(ids(i).mayhave) 'speed up checks of first 2 characters
    amayhave = imayhave AND 255 'speed up checks of first character
    IF amayhave = 32 THEN GOTO findidnomatch 'it cannot have the symbol passed (nb. musthave symbols have already been ok'd)
    'note: variable length strings are not a problem here, as they can only have one possible extension

    IF amayhave = 36 THEN '"$"
        IF imayhave <> 8228 THEN '"$ "
            'it is a fixed length string
            IF CVI(sc$) = 8228 THEN GOTO findidok 'allow myvariable$ to become myvariable$10
            'allow later comparison to verify if extension is correct
        END IF
    END IF
    IF sc$ <> ids(i).mayhave THEN GOTO findidnomatch
END IF 'scpassed

'return id
findidok:

id = ids(i)

currentid = i
EXIT FUNCTION

'END IF 'same name
findidnomatch:
'NEXT
IF z = 2 THEN GOTO hashretry

'totally unclassifiable
noid:
findid& = 0
currentid = -1
END FUNCTION

FUNCTION FindArray (secure$)
FindArray = -1
n$ = secure$
IF Debug THEN PRINT #9, "func findarray:in:" + n$
IF alphanumeric(ASC(n$)) = 0 THEN FindArray = 0: EXIT FUNCTION

'establish whether n$ includes an extension
i = INSTR(n$, "~"): IF i THEN sc$ = RIGHT$(n$, LEN(n$) - i + 1): n$ = LEFT$(n$, i - 1): GOTO gotsc2
i = INSTR(n$, "`"): IF i THEN sc$ = RIGHT$(n$, LEN(n$) - i + 1): n$ = LEFT$(n$, i - 1): GOTO gotsc2
i = INSTR(n$, "%"): IF i THEN sc$ = RIGHT$(n$, LEN(n$) - i + 1): n$ = LEFT$(n$, i - 1): GOTO gotsc2
i = INSTR(n$, "&"): IF i THEN sc$ = RIGHT$(n$, LEN(n$) - i + 1): n$ = LEFT$(n$, i - 1): GOTO gotsc2
i = INSTR(n$, "!"): IF i THEN sc$ = RIGHT$(n$, LEN(n$) - i + 1): n$ = LEFT$(n$, i - 1): GOTO gotsc2
i = INSTR(n$, "#"): IF i THEN sc$ = RIGHT$(n$, LEN(n$) - i + 1): n$ = LEFT$(n$, i - 1): GOTO gotsc2
i = INSTR(n$, "$"): IF i THEN sc$ = RIGHT$(n$, LEN(n$) - i + 1): n$ = LEFT$(n$, i - 1): GOTO gotsc2
gotsc2:
n2$ = n$ + sc$

IF sc$ <> "" THEN
    'has an extension
    'note! findid must unambiguify ` to `5 or $ to $10 where applicable
    try = findid(n2$): IF Error_Happened THEN EXIT FUNCTION
    DO WHILE try
        IF id.arraytype THEN
            EXIT FUNCTION
        END IF
        IF try = 2 THEN findanotherid = 1: try = findid(n2$) ELSE try = 0
        IF Error_Happened THEN EXIT FUNCTION
    LOOP

ELSE
    'no extension

    '1. pass as is, without any extension (local)
    try = findid(n2$): IF Error_Happened THEN EXIT FUNCTION
    DO WHILE try
        IF id.arraytype THEN
            IF subfuncn = 0 THEN EXIT FUNCTION
            IF id.insubfuncn = subfuncn THEN EXIT FUNCTION
        END IF
        IF try = 2 THEN findanotherid = 1: try = findid(n2$) ELSE try = 0
        IF Error_Happened THEN EXIT FUNCTION
    LOOP

    '2. that failed, so apply the _define'd extension and pass (local)
    a = ASC(UCASE$(n$)): IF a = 95 THEN a = 91
    a = a - 64 'so A=1, Z=27 and _=28
    n2$ = n$ + defineextaz(a)
    try = findid(n2$): IF Error_Happened THEN EXIT FUNCTION
    DO WHILE try
        IF id.arraytype THEN
            IF subfuncn = 0 THEN EXIT FUNCTION
            IF id.insubfuncn = subfuncn THEN EXIT FUNCTION
            EXIT FUNCTION
        END IF
        IF try = 2 THEN findanotherid = 1: try = findid(n2$) ELSE try = 0
        IF Error_Happened THEN EXIT FUNCTION
    LOOP

    '3. pass as is, without any extension (global)
    n2$ = n$
    try = findid(n2$): IF Error_Happened THEN EXIT FUNCTION
    DO WHILE try
        IF id.arraytype THEN
            EXIT FUNCTION
        END IF
        IF try = 2 THEN findanotherid = 1: try = findid(n2$) ELSE try = 0
        IF Error_Happened THEN EXIT FUNCTION
    LOOP

    '4. that failed, so apply the _define'd extension and pass (global)
    a = ASC(UCASE$(n$)): IF a = 95 THEN a = 91
    a = a - 64 'so A=1, Z=27 and _=28
    n2$ = n$ + defineextaz(a)
    try = findid(n2$): IF Error_Happened THEN EXIT FUNCTION
    DO WHILE try
        IF id.arraytype THEN
            EXIT FUNCTION
        END IF
        IF try = 2 THEN findanotherid = 1: try = findid(n2$) ELSE try = 0
        IF Error_Happened THEN EXIT FUNCTION
    LOOP

END IF
FindArray = 0
END FUNCTION




FUNCTION fixoperationorder$ (savea$)
a$ = savea$
IF Debug THEN PRINT #9, "fixoperationorder:in:" + a$

fooindwel = fooindwel + 1

n = numelements(a$) 'n is maintained throughout function

IF fooindwel = 1 THEN 'actions to take on initial call only

    '----------------A. 'Quick' mismatched brackets check----------------
    b = 0
    a2$ = sp + a$ + sp
    b1$ = sp + "(" + sp
    b2$ = sp + ")" + sp
    i = 1
    findmmb:
    i1 = INSTR(i, a2$, b1$)
    i2 = INSTR(i, a2$, b2$)
    i3 = i1
    IF i2 THEN
        IF i1 = 0 THEN
            i3 = i2
        ELSE
            IF i2 < i1 THEN i3 = i2
        END IF
    END IF
    IF i3 THEN
        IF i3 = i1 THEN b = b + 1
        IF i3 = i2 THEN b = b - 1
        i = i3 + 2
        IF b < 0 THEN Give_Error "Missing (": EXIT FUNCTION
        GOTO findmmb
    END IF
    IF b > 0 THEN Give_Error "Missing )": EXIT FUNCTION

    '----------------B. 'Quick' correction of over-use of +,- ----------------
    'note: the results of this change are beneficial to foolayout
    a2$ = sp + a$ + sp

    'rule 1: change ++ to +
    rule1:
    i = INSTR(a2$, sp + "+" + sp + "+" + sp)
    IF i THEN
        a2$ = LEFT$(a2$, i + 2) + RIGHT$(a2$, LEN(a2$) - i - 4)
        a$ = MID$(a2$, 2, LEN(a2$) - 2)
        n = n - 1
        IF Debug THEN PRINT #9, "fixoperationorder:+/-:" + a$
        GOTO rule1
    END IF

    'rule 2: change -+ to -
    rule2:
    i = INSTR(a2$, sp + "-" + sp + "+" + sp)
    IF i THEN
        a2$ = LEFT$(a2$, i + 2) + RIGHT$(a2$, LEN(a2$) - i - 4)
        a$ = MID$(a2$, 2, LEN(a2$) - 2)
        n = n - 1
        IF Debug THEN PRINT #9, "fixoperationorder:+/-:" + a$
        GOTO rule2
    END IF

    'rule 3: change anyoperator-- to anyoperator
    rule3:
    IF INSTR(a2$, sp + "-" + sp + "-" + sp) THEN
        FOR i = 1 TO n - 2
            IF isoperator(getelement(a$, i)) THEN
                IF getelement(a$, i + 1) = "-" THEN
                    IF getelement(a$, i + 2) = "-" THEN
                        removeelements a$, i + 1, i + 2, 0
                        a2$ = sp + a$ + sp
                        n = n - 2
                        IF Debug THEN PRINT #9, "fixoperationorder:+/-:" + a$
                        GOTO rule3
                    END IF
                END IF
            END IF
        NEXT
    END IF 'rule 3



    '----------------C. 'Quick' location of negation----------------
    'note: the results of this change are beneficial to foolayout

    'for numbers...
    'before: anyoperator,-,number
    'after:  anyoperator,-number

    'for variables...
    'before: anyoperator,-,variable
    'after:  anyoperator,�,variable

    'exception for numbers followed by ^... (they will be bracketed up along with the ^ later)
    'before: anyoperator,-,number,^
    'after:  anyoperator,�,number,^

    FOR i = 1 TO n - 1
        IF i > n - 1 THEN EXIT FOR 'n changes, so manually exit if required

        IF ASC(getelement(a$, i)) = 45 THEN '-

            neg = 0
            IF i = 1 THEN
                neg = 1
            ELSE
                a2$ = getelement(a$, i - 1)
                c = ASC(a2$)
                IF c = 40 OR c = 44 THEN '(,
                    neg = 1
                ELSE
                    IF isoperator(a2$) THEN neg = 1
                END IF '()
            END IF 'i=1
            IF neg = 1 THEN

                a2$ = getelement(a$, i + 1)
                c = ASC(a2$)
                IF c >= 48 AND c <= 57 THEN
                    c2 = 0: IF i < n - 1 THEN c2 = ASC(getelement(a$, i + 2))
                    IF c2 <> 94 THEN 'not ^
                        'number...
                        i2 = INSTR(a2$, ",")
                        IF i2 AND ASC(a2$, i2 + 1) <> 38 THEN '&H/&O/&B values don't need the assumed negation
                            a2$ = "-" + LEFT$(a2$, i2) + "-" + RIGHT$(a2$, LEN(a2$) - i2)
                        ELSE
                            a2$ = "-" + a2$
                        END IF
                        removeelements a$, i, i + 1, 0
                        insertelements a$, i - 1, a2$
                        n = n - 1
                        IF Debug THEN PRINT #9, "fixoperationorder:negation:" + a$

                        GOTO negdone

                    END IF
                END IF


                'not a number (or for exceptions)...
                removeelements a$, i, i, 0
                insertelements a$, i - 1, "�"
                IF Debug THEN PRINT #9, "fixoperationorder:negation:" + a$

            END IF 'isoperator
        END IF '-
        negdone:
    NEXT



END IF 'fooindwel=1



'----------------D. 'Quick' Add 'power of' with negation {}bracketing to bottom bracket level----------------
pownegused = 0
powneg:
IF INSTR(a$, "^" + sp + "�") THEN 'quick check
    b = 0
    b1 = 0
    FOR i = 1 TO n
        a2$ = getelement(a$, i)
        c = ASC(a2$)
        IF c = 40 THEN b = b + 1
        IF c = 41 THEN b = b - 1
        IF b = 0 THEN
            IF b1 THEN
                IF isoperator(a2$) THEN
                    IF a2$ <> "^" AND a2$ <> "�" THEN
                        insertelements a$, i - 1, "}"
                        insertelements a$, b1, "{"
                        n = n + 2
                        IF Debug THEN PRINT #9, "fixoperationorder:^-:" + a$
                        GOTO powneg
                        pownegused = 1
                    END IF
                END IF
            END IF
            IF c = 94 THEN '^
                IF getelement$(a$, i + 1) = "�" THEN b1 = i: i = i + 1
            END IF
        END IF 'b=0
    NEXT i
    IF b1 THEN
        insertelements a$, b1, "{"
        a$ = a$ + sp + "}"
        n = n + 2
        IF Debug THEN PRINT #9, "fixoperationorder:^-:" + a$
        pownegused = 1
        GOTO powneg
    END IF

END IF 'quick check


'----------------E. Find lowest & highest operator level in bottom bracket level----------------
NOT_recheck:
lco = 255
hco = 0
b = 0
FOR i = 1 TO n
    a2$ = getelement(a$, i)
    c = ASC(a2$)
    IF c = 40 OR c = 123 THEN b = b + 1
    IF c = 41 OR c = 125 THEN b = b - 1
    IF b = 0 THEN
        op = isoperator(a2$)
        IF op THEN
            IF op < lco THEN lco = op
            IF op > hco THEN hco = op
        END IF
    END IF
NEXT

'----------------F. Add operator {}bracketting----------------
'apply bracketting only if required
IF hco <> 0 THEN 'operators were used
    IF lco <> hco THEN
        'brackets needed

        IF lco = 6 THEN 'NOT exception
            'Step 1: Add brackets as follows ~~~ ( NOT ( ~~~ NOT ~~~ NOT ~~~ NOT ~~~ ))
            'Step 2: Recheck line from beginning
            IF n = 1 THEN Give_Error "Expected NOT ...": EXIT FUNCTION
            b = 0
            FOR i = 1 TO n
                a2$ = getelement(a$, i)
                c = ASC(a2$)
                IF c = 40 OR c = 123 THEN b = b + 1
                IF c = 41 OR c = 125 THEN b = b - 1
                IF b = 0 THEN
                    IF UCASE$(a2$) = "NOT" THEN
                        IF i = n THEN Give_Error "Expected NOT ...": EXIT FUNCTION
                        IF i = 1 THEN a$ = "NOT" + sp + "{" + sp + getelements$(a$, 2, n) + sp + "}": n = n + 2: GOTO lco_bracketting_done
                        a$ = getelements$(a$, 1, i - 1) + sp + "{" + sp + "NOT" + sp + "{" + sp + getelements$(a$, i + 1, n) + sp + "}" + sp + "}"
                        n = n + 4
                        GOTO NOT_recheck
                    END IF 'not
                END IF 'b=0
            NEXT
        END IF 'NOT exception

        n2 = n
        b = 0
        a3$ = "{"
        n = 1
        FOR i = 1 TO n2
            a2$ = getelement(a$, i)
            c = ASC(a2$)
            IF c = 40 OR c = 123 THEN b = b + 1
            IF c = 41 OR c = 125 THEN b = b - 1
            IF b = 0 THEN
                op = isoperator(a2$)
                IF op = lco THEN
                    IF i = 1 THEN
                        a3$ = a2$ + sp + "{"
                        n = 2
                    ELSE
                        IF i = n2 THEN Give_Error "Expected variable/value after '" + UCASE$(a2$) + "'": EXIT FUNCTION
                        a3$ = a3$ + sp + "}" + sp + a2$ + sp + "{"
                        n = n + 3
                    END IF
                    GOTO fixop0
                END IF

            END IF 'b=0
            a3$ = a3$ + sp + a2$
            n = n + 1
            fixop0:
        NEXT
        a3$ = a3$ + sp + "}"
        n = n + 1
        a$ = a3$

        lco_bracketting_done:
        IF Debug THEN PRINT #9, "fixoperationorder:lco bracketing["; lco; ","; hco; "]:" + a$

        '--------(F)G. Remove indwelling {}bracketting from power-negation--------
        IF pownegused THEN
            b = 0
            i = 0
            DO WHILE i <= n
                i = i + 1
                c = ASC(getelement(a$, i))
                IF c = 41 OR c = 125 THEN b = b - 1
                IF (c = 123 OR c = 125) AND b <> 0 THEN
                    removeelements a$, i, i, 0
                    n = n - 1
                    i = i - 1
                    IF Debug THEN PRINT #9, "fixoperationorder:^- {} removed:" + a$
                END IF
                IF c = 40 OR c = 123 THEN b = b + 1
            LOOP
        END IF 'pownegused

    END IF 'lco <> hco
END IF 'hco <> 0

'--------Bracketting of multiple NOT/negation unary operators--------
IF LEFT$(a$, 4) = "�" + sp + "�" + sp THEN
    a$ = "�" + sp + "{" + sp + getelements$(a$, 2, n) + sp + "}": n = n + 2
END IF
IF UCASE$(LEFT$(a$, 8)) = "NOT" + sp + "NOT" + sp THEN
    a$ = "NOT" + sp + "{" + sp + getelements$(a$, 2, n) + sp + "}": n = n + 2
END IF

'----------------H. Identification/conversion of elements within bottom bracket level----------------
'actions performed:
'   ->builds f$(tlayout)
'   ->adds symbols to all numbers
'   ->evaluates constants to numbers

f$ = ""
b = 0
c = 0
lastt = 0: lastti = 0
FOR i = 1 TO n
    f2$ = getelement(a$, i)
    lastc = c
    c = ASC(f2$)

    IF c = 40 OR c = 123 THEN
        IF c <> 40 OR b <> 0 THEN f2$ = "" 'skip temporary & indwelling  brackets
        b = b + 1
        GOTO classdone
    END IF
    IF c = 41 OR c = 125 THEN

        b = b - 1

        'check for "("+sp+")" after literal-string, operator, number or nothing
        IF b = 0 THEN 'must be within the lowest level
            IF c = 41 THEN
                IF lastc = 40 THEN
                    IF lastti = i - 2 OR lastti = 0 THEN
                        IF lastt >= 0 AND lastt <= 3 THEN
                            Give_Error "Unexpected (": EXIT FUNCTION
                        END IF
                    END IF
                END IF
            END IF
        END IF

        IF c <> 41 OR b <> 0 THEN f2$ = "" 'skip temporary & indwelling  brackets
        GOTO classdone
    END IF

    IF b = 0 THEN

        'classifications/conversions:
        '1. quoted string ("....)
        '2. number
        '3. operator
        '4. constant
        '5. variable/array/udt/function (note: nothing can share the same name as a function except a label)


        'quoted string?
        IF c = 34 THEN '"
            lastt = 1: lastti = i

            'convert \\ to \
            'convert \??? to CHR$(&O???)
            x2 = 1
            x = INSTR(x2, f2$, "\")
            DO WHILE x
                c2 = ASC(f2$, x + 1)
                IF c2 = 92 THEN '\\
                    f2$ = LEFT$(f2$, x) + RIGHT$(f2$, LEN(f2$) - x - 1) 'remove second \
                    x2 = x + 1
                ELSE
                    'octal triplet value
                    c3 = (ASC(f2$, x + 3) - 48) + (ASC(f2$, x + 2) - 48) * 8 + (ASC(f2$, x + 1) - 48) * 64
                    f2$ = LEFT$(f2$, x - 1) + CHR$(c3) + RIGHT$(f2$, LEN(f2$) - x - 3)
                    x2 = x + 1
                END IF
                x = INSTR(x2, f2$, "\")
            LOOP
            'remove ',len' (if it exists)
            x = INSTR(2, f2$, CHR$(34) + ","): IF x THEN f2$ = LEFT$(f2$, x)
            GOTO classdone
        END IF

        'number?
        IF (c >= 48 AND c <= 57) OR c = 45 THEN
            lastt = 2: lastti = i

            x = INSTR(f2$, ",")
            IF x THEN
                removeelements a$, i, i, 0: insertelements a$, i - 1, LEFT$(f2$, x - 1)
                f2$ = RIGHT$(f2$, LEN(f2$) - x)
            END IF

            IF x = 0 THEN
                c2 = ASC(f2$, LEN(f2$))
                IF c2 < 48 OR c2 > 57 THEN
                    x = 1 'extension given
                ELSE
                    x = INSTR(f2$, "`")
                END IF
            END IF

            'add appropriate integer symbol if none present
            IF x = 0 THEN
                f3$ = f2$
                s$ = ""
                IF c = 45 THEN
                    s$ = "&&"
                    IF (f3$ < "-2147483648" AND LEN(f3$) = 11) OR LEN(f3$) < 11 THEN s$ = "&"
                    IF (f3$ <= "-32768" AND LEN(f3$) = 6) OR LEN(f3$) < 6 THEN s$ = "%"
                ELSE
                    s$ = "~&&"
                    IF (f3$ <= "9223372036854775807" AND LEN(f3$) = 19) OR LEN(f3$) < 19 THEN s$ = "&&"
                    IF (f3$ <= "2147483647" AND LEN(f3$) = 10) OR LEN(f3$) < 10 THEN s$ = "&"
                    IF (f3$ <= "32767" AND LEN(f3$) = 5) OR LEN(f3$) < 5 THEN s$ = "%"
                END IF
                f3$ = f3$ + s$
                removeelements a$, i, i, 0: insertelements a$, i - 1, f3$
            END IF 'x=0

            GOTO classdone
        END IF

        'operator?
        IF isoperator(f2$) THEN
            lastt = 3: lastti = i
            IF LEN(f2$) > 1 THEN
                IF f2$ <> UCASE$(f2$) THEN
                    f2$ = UCASE$(f2$)
                    removeelements a$, i, i, 0
                    insertelements a$, i - 1, f2$
                END IF
            END IF
            'append negation
            IF f2$ = "�" THEN f$ = f$ + sp + "-": GOTO classdone_special
            GOTO classdone
        END IF


        IF alphanumeric(c) THEN
            lastt = 4: lastti = i

            IF i < n THEN nextc = ASC(getelement(a$, i + 1)) ELSE nextc = 0

            ' a constant?
            IF nextc <> 40 THEN '<>"(" (not an array)
                IF lastc <> 46 THEN '<>"." (not an element of a UDT)

                    e$ = UCASE$(f2$)
                    es$ = removesymbol$(e$)
                    IF Error_Happened THEN EXIT FUNCTION

                    hashfound = 0
                    hashname$ = e$
                    hashchkflags = HASHFLAG_CONSTANT
                    hashres = HashFindRev(hashname$, hashchkflags, hashresflags, hashresref)
                    DO WHILE hashres
                        IF constsubfunc(hashresref) = subfuncn OR constsubfunc(hashresref) = 0 THEN
                            IF constdefined(hashresref) THEN
                                hashfound = 1
                                EXIT DO
                            END IF
                        END IF
                        IF hashres <> 1 THEN hashres = HashFindCont(hashresflags, hashresref) ELSE hashres = 0
                    LOOP

                    IF hashfound THEN
                        i2 = hashresref
                        'FOR i2 = constlast TO 0 STEP -1
                        'IF e$ = constname(i2) THEN





                        'is a STATIC variable overriding this constant?
                        staticvariable = 0
                        try = findid(e$ + es$)
                        IF Error_Happened THEN EXIT FUNCTION
                        DO WHILE try
                            IF id.arraytype = 0 THEN staticvariable = 1: EXIT DO 'if it's not an array, it's probably a static variable
                            IF try = 2 THEN findanotherid = 1: try = findid(e$ + es$) ELSE try = 0
                            IF Error_Happened THEN EXIT FUNCTION
                        LOOP
                        'add symbol and try again
                        IF staticvariable = 0 THEN
                            IF LEN(es$) = 0 THEN
                                a = ASC(UCASE$(e$)): IF a = 95 THEN a = 91
                                a = a - 64 'so A=1, Z=27 and _=28
                                es2$ = defineextaz(a)
                                try = findid(e$ + es2$)
                                IF Error_Happened THEN EXIT FUNCTION
                                DO WHILE try
                                    IF id.arraytype = 0 THEN staticvariable = 1: EXIT DO 'if it's not an array, it's probably a static variable
                                    IF try = 2 THEN findanotherid = 1: try = findid(e$ + es2$) ELSE try = 0
                                    IF Error_Happened THEN EXIT FUNCTION
                                LOOP
                            END IF
                        END IF

                        IF staticvariable = 0 THEN

                            t = consttype(i2)
                            IF t AND ISSTRING THEN
                                IF LEN(es$) > 0 AND es$ <> "$" THEN Give_Error "Type mismatch": EXIT FUNCTION
                                e$ = conststring(i2)
                            ELSE 'not a string
                                IF LEN(es$) THEN et = typname2typ(es$) ELSE et = 0
                                IF Error_Happened THEN EXIT FUNCTION
                                IF et AND ISSTRING THEN Give_Error "Type mismatch": EXIT FUNCTION
                                'convert value to general formats
                                IF t AND ISFLOAT THEN
                                    v## = constfloat(i2)
                                    v&& = v##
                                    v~&& = v&&
                                ELSE
                                    IF t AND ISUNSIGNED THEN
                                        v~&& = constuinteger(i2)
                                        v&& = v~&&
                                        v## = v&&
                                    ELSE
                                        v&& = constinteger(i2)
                                        v## = v&&
                                        v~&& = v&&
                                    END IF
                                END IF
                                'apply type conversion if necessary
                                IF et THEN t = et
                                '(todo: range checking)
                                'convert value into string for returning
                                IF t AND ISFLOAT THEN
                                    e$ = LTRIM$(RTRIM$(STR$(v##)))
                                ELSE
                                    IF t AND ISUNSIGNED THEN
                                        e$ = LTRIM$(RTRIM$(STR$(v~&&)))
                                    ELSE
                                        e$ = LTRIM$(RTRIM$(STR$(v&&)))
                                    END IF
                                END IF

                                'floats returned by str$ must be converted to qb64 standard format
                                IF t AND ISFLOAT THEN
                                    t2 = t AND 511
                                    'find E,D or F
                                    s$ = ""
                                    IF INSTR(e$, "E") THEN s$ = "E"
                                    IF INSTR(e$, "D") THEN s$ = "D"
                                    IF INSTR(e$, "F") THEN s$ = "F"
                                    IF LEN(s$) THEN
                                        'E,D,F found
                                        x = INSTR(e$, s$)
                                        'as incorrect type letter may have been returned by STR$, override it
                                        IF t2 = 32 THEN s$ = "E"
                                        IF t2 = 64 THEN s$ = "D"
                                        IF t2 = 256 THEN s$ = "F"
                                        MID$(e$, x, 1) = s$
                                        IF INSTR(e$, ".") = 0 THEN e$ = LEFT$(e$, x - 1) + ".0" + RIGHT$(e$, LEN(e$) - x + 1): x = x + 2
                                        IF LEFT$(e$, 1) = "." THEN e$ = "0" + e$
                                        IF LEFT$(e$, 2) = "-." THEN e$ = "-0" + RIGHT$(e$, LEN(e$) - 1)
                                        IF INSTR(e$, "+") = 0 AND INSTR(e$, "-") = 0 THEN
                                            e$ = LEFT$(e$, x) + "+" + RIGHT$(e$, LEN(e$) - x)
                                        END IF
                                    ELSE
                                        'E,D,F not found
                                        IF INSTR(e$, ".") = 0 THEN e$ = e$ + ".0"
                                        IF LEFT$(e$, 1) = "." THEN e$ = "0" + e$
                                        IF LEFT$(e$, 2) = "-." THEN e$ = "-0" + RIGHT$(e$, LEN(e$) - 1)
                                        IF t2 = 32 THEN e$ = e$ + "E+0"
                                        IF t2 = 64 THEN e$ = e$ + "D+0"
                                        IF t2 = 256 THEN e$ = e$ + "F+0"
                                    END IF
                                ELSE
                                    s$ = typevalue2symbol$(t)
                                    IF Error_Happened THEN EXIT FUNCTION
                                    e$ = e$ + s$ 'simply append symbol to integer
                                END IF

                            END IF 'not a string

                            removeelements a$, i, i, 0
                            insertelements a$, i - 1, e$
                            'alter f2$ here to original casing
                            f2$ = constcname(i2) + es$
                            GOTO classdone

                        END IF 'not static
                        'END IF 'same name
                        'NEXT
                    END IF 'hashfound
                END IF 'not udt element
            END IF 'not array

            'variable/array/udt?
            u$ = f2$

            try_string$ = f2$
            try_string2$ = try_string$ 'pure version of try_string$

            FOR try_method = 1 TO 4
                try_string$ = try_string2$
                IF try_method = 2 OR try_method = 4 THEN
                    dtyp$ = removesymbol(try_string$)
                    IF LEN(dtyp$) = 0 THEN
                        IF isoperator(try_string$) = 0 THEN
                            IF isvalidvariable(try_string$) THEN
                                IF LEFT$(try_string$, 1) = "_" THEN v = 27 ELSE v = ASC(UCASE$(try_string$)) - 64
                                try_string$ = try_string$ + defineextaz(v)
                            END IF
                        END IF
                    ELSE
                        try_string$ = try_string2$
                    END IF
                END IF
                try = findid(try_string$)
                IF Error_Happened THEN EXIT FUNCTION
                DO WHILE try
                    IF (subfuncn = id.insubfuncn AND try_method <= 2) OR try_method >= 3 THEN

                        IF Debug THEN PRINT #9, "found id matching " + f2$

                        IF nextc = 40 THEN '(

                            'function or array?
                            IF id.arraytype <> 0 OR id.subfunc = 1 THEN
                                'note: even if it's an array of UDTs, the bracketted index will follow immediately

                                'correct name
                                f3$ = f2$
                                s$ = removesymbol$(f3$)
                                IF Error_Happened THEN EXIT FUNCTION
                                f2$ = RTRIM$(id.cn) + s$
                                removeelements a$, i, i, 0
                                insertelements a$, i - 1, UCASE$(f2$)
                                f$ = f$ + f2$ + sp + "(" + sp

                                'skip (but record with nothing inside them) brackets
                                b2 = 1 'already in first bracket
                                FOR i2 = i + 2 TO n
                                    c2 = ASC(getelement(a$, i2))
                                    IF c2 = 40 THEN b2 = b2 + 1
                                    IF c2 = 41 THEN b2 = b2 - 1
                                    IF b2 = 0 THEN EXIT FOR 'note: mismatched brackets check ensures this always succeeds
                                    f$ = f$ + sp
                                NEXT

                                'adjust i accordingly
                                i = i2

                                f$ = f$ + ")"

                                'jump to UDT section if array is of UDT type (and elements are referenced)
                                IF id.arraytype AND ISUDT THEN
                                    IF i < n THEN nextc = ASC(getelement(a$, i + 1)) ELSE nextc = 0
                                    IF nextc = 46 THEN t = id.arraytype: GOTO fooudt
                                END IF

                                f$ = f$ + sp
                                GOTO classdone_special
                            END IF 'id.arraytype
                        END IF 'nextc "("

                        IF nextc <> 40 THEN 'not "(" (this avoids confusing simple variables with arrays)
                            IF id.t <> 0 OR id.subfunc = 1 THEN 'simple variable or function (without parameters)

                                IF id.t AND ISUDT THEN
                                    'note: it may or may not be followed by a period (eg. if whole udt is being referred to)
                                    'check if next item is a period

                                    'correct name
                                    f2$ = RTRIM$(id.cn) + removesymbol$(f2$)
                                    IF Error_Happened THEN EXIT FUNCTION
                                    removeelements a$, i, i, 0
                                    insertelements a$, i - 1, UCASE$(f2$)
                                    f$ = f$ + f2$



                                    IF nextc <> 46 THEN f$ = f$ + sp: GOTO classdone_special 'no sub-elements referenced
                                    t = id.t

                                    fooudt:

                                    f$ = f$ + sp + "." + sp
                                    E = udtxnext(t AND 511) 'next element to check
                                    i = i + 2

                                    'loop

                                    '"." encountered, i must be an element
                                    IF i > n THEN Give_Error "Expected .element": EXIT FUNCTION
                                    f2$ = getelement(a$, i)
                                    s$ = removesymbol$(f2$)
                                    IF Error_Happened THEN EXIT FUNCTION
                                    u$ = UCASE$(f2$) + SPACE$(256 - LEN(f2$)) 'fast scanning

                                    'is f$ the same as element e?
                                    fooudtnexte:
                                    IF udtename(E) = u$ THEN
                                        'match found
                                        'todo: check symbol(s$) matches element's type

                                        'correct name
                                        f2$ = RTRIM$(udtecname(E)) + s$
                                        removeelements a$, i, i, 0
                                        insertelements a$, i - 1, UCASE$(f2$)
                                        f$ = f$ + f2$

                                        IF i = n THEN f$ = f$ + sp: GOTO classdone_special
                                        nextc = ASC(getelement(a$, i + 1))
                                        IF nextc <> 46 THEN f$ = f$ + sp: GOTO classdone_special 'no sub-elements referenced
                                        'sub-element exists
                                        t = udtetype(E)
                                        IF (t AND ISUDT) = 0 THEN Give_Error "Invalid . after element": EXIT FUNCTION
                                        GOTO fooudt

                                    END IF 'match found

                                    'no, so check next element
                                    E = udtenext(E)
                                    IF E = 0 THEN Give_Error "Element not defined": EXIT FUNCTION
                                    GOTO fooudtnexte

                                END IF 'udt

                                'non array/udt based variable
                                f3$ = f2$
                                s$ = removesymbol$(f3$)
                                IF Error_Happened THEN EXIT FUNCTION
                                f2$ = RTRIM$(id.cn) + s$
                                'change was is returned to uppercase
                                removeelements a$, i, i, 0
                                insertelements a$, i - 1, UCASE$(f2$)
                                GOTO CouldNotClassify
                            END IF 'id.t

                        END IF 'nextc not "("

                    END IF
                    IF try = 2 THEN findanotherid = 1: try = findid(try_string$) ELSE try = 0
                    IF Error_Happened THEN EXIT FUNCTION
                LOOP
            NEXT 'try method (1-4)
            CouldNotClassify:

            'alphanumeric, but item name is unknown... is it an internal type? if so, use capitals
            f3$ = UCASE$(f2$)
            internaltype = 0
            IF f3$ = "STRING" THEN internaltype = 1
            IF f3$ = "_UNSIGNED" THEN internaltype = 1
            IF f3$ = "_BIT" THEN internaltype = 1
            IF f3$ = "_BYTE" THEN internaltype = 1
            IF f3$ = "INTEGER" THEN internaltype = 1
            IF f3$ = "LONG" THEN internaltype = 1
            IF f3$ = "_INTEGER64" THEN internaltype = 1
            IF f3$ = "SINGLE" THEN internaltype = 1
            IF f3$ = "DOUBLE" THEN internaltype = 1
            IF f3$ = "_FLOAT" THEN internaltype = 1
            IF f3$ = "_OFFSET" THEN internaltype = 1
            IF internaltype = 1 THEN
                f2$ = f3$
                removeelements a$, i, i, 0
                insertelements a$, i - 1, f3$
                GOTO classdone
            END IF

            GOTO classdone
        END IF 'alphanumeric

        classdone:
        f$ = f$ + f2$
    END IF 'b=0
    f$ = f$ + sp
    classdone_special:
NEXT
IF LEN(f$) THEN f$ = LEFT$(f$, LEN(f$) - 1) 'remove trailing 'sp'

IF Debug THEN PRINT #9, "fixoperationorder:identification:" + a$, n
IF Debug THEN PRINT #9, "fixoperationorder:identification(layout):" + f$, n



'----------------I. Pass (){}bracketed items (if any) to fixoperationorder & build return----------------
'note: items seperated by commas are done seperately

ff$ = ""
b = 0
b2 = 0
p1 = 0 'where level 1 began
aa$ = ""
n = numelements(a$)
FOR i = 1 TO n

    openbracket = 0

    a2$ = getelement(a$, i)

    c = ASC(a2$)



    IF c = 40 OR c = 123 THEN '({
        b = b + 1

        IF b = 1 THEN




            p1 = i + 1
            aa$ = aa$ + "(" + sp

        END IF

        openbracket = 1

        GOTO foopass

    END IF '({

    IF c = 44 THEN ',
        IF b = 1 THEN
            GOTO foopassit
        END IF
    END IF

    IF c = 41 OR c = 125 THEN ')}
        b = b - 1

        IF b = 0 THEN
            foopassit:
            IF p1 <> i THEN
                foo$ = fixoperationorder(getelements(a$, p1, i - 1))
                IF Error_Happened THEN EXIT FUNCTION
                IF LEN(foo$) THEN
                    aa$ = aa$ + foo$ + sp
                    IF c = 125 THEN ff$ = ff$ + tlayout$ + sp ELSE ff$ = ff$ + tlayout$ + sp2 'spacing between ) } , varies
                END IF
            END IF
            IF c = 44 THEN aa$ = aa$ + "," + sp: ff$ = ff$ + "," + sp ELSE aa$ = aa$ + ")" + sp
            p1 = i + 1
        END IF

        GOTO foopass
    END IF ')}




    IF b = 0 THEN aa$ = aa$ + a2$ + sp


    foopass:

    f2$ = getelementspecial(f$, i)
    IF Error_Happened THEN EXIT FUNCTION
    IF LEN(f2$) THEN

        'use sp2 to join items connected by a period
        IF c = 46 THEN '"."
            IF i > 1 AND i < n THEN 'stupidity check
                IF LEN(ff$) THEN MID$(ff$, LEN(ff$), 1) = sp2 'convert last spacer to a sp2
                ff$ = ff$ + "." + sp2
                GOTO fooloopnxt
            END IF
        END IF

        'spacing just before (
        IF openbracket THEN

            'convert last spacer?
            IF i <> 1 THEN
                IF isoperator(getelement$(a$, i - 1)) = 0 THEN
                    MID$(ff$, LEN(ff$), 1) = sp2
                END IF
            END IF
            ff$ = ff$ + f2$ + sp2
        ELSE 'not openbracket
            ff$ = ff$ + f2$ + sp
        END IF

    END IF 'len(f2$)

    fooloopnxt:

NEXT

IF LEN(aa$) THEN aa$ = LEFT$(aa$, LEN(aa$) - 1)
IF LEN(ff$) THEN ff$ = LEFT$(ff$, LEN(ff$) - 1)

IF Debug THEN PRINT #9, "fixoperationorder:return:" + aa$
IF Debug THEN PRINT #9, "fixoperationorder:layout:" + ff$
tlayout$ = ff$
fixoperationorder$ = aa$

fooindwel = fooindwel - 1
END FUNCTION




FUNCTION getelementspecial$ (savea$, elenum)
a$ = savea$
IF a$ = "" THEN EXIT FUNCTION 'no elements!

n = 1
p = 1
getelementspecialnext:
i = INSTR(p, a$, sp)

'avoid sp inside "..."
i2 = INSTR(p, a$, CHR$(34))
IF i2 < i AND i2 <> 0 THEN
    i3 = INSTR(i2 + 1, a$, CHR$(34)): IF i3 = 0 THEN Give_Error "Expected " + CHR$(34): EXIT FUNCTION
    i = INSTR(i3, a$, sp)
END IF

IF elenum = n THEN
    IF i THEN
        getelementspecial$ = MID$(a$, p, i - p)
    ELSE
        getelementspecial$ = RIGHT$(a$, LEN(a$) - p + 1)
    END IF
    EXIT FUNCTION
END IF

IF i = 0 THEN EXIT FUNCTION 'no more elements!
n = n + 1
p = i + 1
GOTO getelementspecialnext
END FUNCTION



FUNCTION getelement$ (a$, elenum)
IF a$ = "" THEN EXIT FUNCTION 'no elements!

n = 1
p = 1
getelementnext:
i = INSTR(p, a$, sp)

IF elenum = n THEN
    IF i THEN
        getelement$ = MID$(a$, p, i - p)
    ELSE
        getelement$ = RIGHT$(a$, LEN(a$) - p + 1)
    END IF
    EXIT FUNCTION
END IF

IF i = 0 THEN EXIT FUNCTION 'no more elements!
n = n + 1
p = i + 1
GOTO getelementnext
END FUNCTION

FUNCTION getelements$ (a$, i1, i2)
IF i2 < i1 THEN getelements$ = "": EXIT FUNCTION
n = 1
p = 1
getelementsnext:
i = INSTR(p, a$, sp)
IF n = i1 THEN
    i1pos = p
END IF
IF n = i2 THEN
    IF i THEN
        getelements$ = MID$(a$, i1pos, i - i1pos)
    ELSE
        getelements$ = RIGHT$(a$, LEN(a$) - i1pos + 1)
    END IF
    EXIT FUNCTION
END IF
n = n + 1
p = i + 1
GOTO getelementsnext
END FUNCTION

SUB getid (i AS LONG)
IF i = -1 THEN Give_Error "-1 passed to getid!": EXIT SUB

id = ids(i)

currentid = i
END SUB

SUB insertelements (a$, i, elements$)
IF i = 0 THEN
    IF a$ = "" THEN
        a$ = elements$
        EXIT SUB
    END IF
    a$ = elements$ + sp + a$
    EXIT SUB
END IF

a2$ = ""
n = numelements(a$)




FOR i2 = 1 TO n
    IF i2 > 1 THEN a2$ = a2$ + sp
    a2$ = a2$ + getelement$(a$, i2)
    IF i = i2 THEN a2$ = a2$ + sp + elements$
NEXT

a$ = a2$

END SUB

FUNCTION isnumber (a$)
IF LEN(a$) = 0 THEN EXIT FUNCTION
FOR i = 1 TO LEN(a$)
    a = ASC(MID$(a$, i, 1))
    IF a = 45 THEN
        IF i <> 1 THEN EXIT FUNCTION
        GOTO isnumok
    END IF
    IF a = 46 THEN
        IF dp = 1 THEN EXIT FUNCTION
        dp = 1
        GOTO isnumok
    END IF
    IF a >= 48 AND a <= 57 THEN v = 1: GOTO isnumok
    EXIT FUNCTION
    isnumok:
NEXT
isnumber = 1
END FUNCTION

FUNCTION isoperator (a2$)
a$ = UCASE$(a2$)
l = 0
l = l + 1: IF a$ = "IMP" THEN GOTO opfound
l = l + 1: IF a$ = "EQV" THEN GOTO opfound
l = l + 1: IF a$ = "XOR" THEN GOTO opfound
l = l + 1: IF a$ = "OR" THEN GOTO opfound
l = l + 1: IF a$ = "AND" THEN GOTO opfound
l = l + 1: IF a$ = "NOT" THEN GOTO opfound
l = l + 1
IF a$ = "=" THEN GOTO opfound
IF a$ = ">" THEN GOTO opfound
IF a$ = "<" THEN GOTO opfound
IF a$ = "<>" THEN GOTO opfound
IF a$ = "<=" THEN GOTO opfound
IF a$ = ">=" THEN GOTO opfound
l = l + 1
IF a$ = "+" THEN GOTO opfound
IF a$ = "-" THEN GOTO opfound '!CAREFUL! could be negation
l = l + 1: IF a$ = "MOD" THEN GOTO opfound
l = l + 1: IF a$ = "\" THEN GOTO opfound
l = l + 1
IF a$ = "*" THEN GOTO opfound
IF a$ = "/" THEN GOTO opfound
'NEGATION LEVEL (MUST BE SET AFTER CALLING ISOPERATOR BY CONTEXT)
l = l + 1: IF a$ = "�" THEN GOTO opfound
l = l + 1: IF a$ = "^" THEN GOTO opfound
EXIT FUNCTION
opfound:
isoperator = l
END FUNCTION

FUNCTION isuinteger (i$)
IF LEN(i$) = 0 THEN EXIT FUNCTION
IF ASC(i$, 1) = 48 AND LEN(i$) > 1 THEN EXIT FUNCTION
FOR c = 1 TO LEN(i$)
    v = ASC(i$, c)
    IF v < 48 OR v > 57 THEN EXIT FUNCTION
NEXT
isuinteger = -1
END FUNCTION

FUNCTION isvalidvariable (a$)
FOR i = 1 TO LEN(a$)
    c = ASC(a$, i)
    t = 0
    IF c >= 48 AND c <= 57 THEN t = 1 'numeric
    IF c >= 65 AND c <= 90 THEN t = 2 'uppercase
    IF c >= 97 AND c <= 122 THEN t = 2 'lowercase
    IF c = 95 THEN t = 2 '_ underscore
    IF t = 2 OR (t = 1 AND i > 1) THEN
        'valid (continue)
    ELSE
        IF i = 1 THEN isvalidvariable = 0: EXIT FUNCTION
        EXIT FOR
    END IF
NEXT

isvalidvariable = 1
IF i > n THEN EXIT FUNCTION
e$ = RIGHT$(a$, LEN(a$) - i - 1)
IF e$ = "%%" OR e$ = "~%%" THEN EXIT FUNCTION
IF e$ = "%" OR e$ = "~%" THEN EXIT FUNCTION
IF e$ = "&" OR e$ = "~&" THEN EXIT FUNCTION
IF e$ = "&&" OR e$ = "~&&" THEN EXIT FUNCTION
IF e$ = "!" OR e$ = "#" OR e$ = "##" THEN EXIT FUNCTION
IF e$ = "$" THEN EXIT FUNCTION
IF e$ = "`" THEN EXIT FUNCTION
IF LEFT$(e$, 1) <> "$" AND LEFT$(e$, 1) <> "`" THEN isvalidvariable = 0: EXIT FUNCTION
e$ = RIGHT$(e$, LEN(e$) - 1)
IF isuinteger(e$) THEN isvalidvariable = 1: EXIT FUNCTION
isvalidvariable = 0
END FUNCTION




FUNCTION lineformat$ (a$)
a2$ = ""
linecontinuation = 0

continueline:

a$ = a$ + "  " 'add 2 extra spaces to make reading next char easier

ca$ = a$
a$ = UCASE$(a$)

n = LEN(a$)
i = 1
lineformatnext:
IF i >= n THEN GOTO lineformatdone

c = ASC(a$, i)
c$ = CHR$(c) '***remove later***

'----------------quoted string----------------
IF c = 34 THEN '"
    a2$ = a2$ + sp + CHR$(34)
    p1 = i + 1
    FOR i2 = i + 1 TO n - 2
        c2 = ASC(a$, i2)

        IF c2 = 34 THEN
            a2$ = a2$ + MID$(ca$, p1, i2 - p1 + 1) + "," + str2$(i2 - (i + 1))
            i = i2 + 1
            EXIT FOR
        END IF

        IF c2 = 92 THEN '\
            a2$ = a2$ + MID$(ca$, p1, i2 - p1) + "\\"
            p1 = i2 + 1
        END IF

        IF c2 < 32 OR c2 > 126 THEN
            o$ = OCT$(c2)
            IF LEN(o$) < 3 THEN
                o$ = "0" + o$
                IF LEN(o$) < 3 THEN o$ = "0" + o$
            END IF
            a2$ = a2$ + MID$(ca$, p1, i2 - p1) + "\" + o$
            p1 = i2 + 1
        END IF

    NEXT

    IF i2 = n - 1 THEN 'no closing "
        a2$ = a2$ + MID$(ca$, p1, (n - 2) - p1 + 1) + CHR$(34) + "," + str2$((n - 2) - (i + 1) + 1)
        i = n - 1
    END IF

    GOTO lineformatnext

END IF

'----------------number----------------
firsti = i
IF c = 46 THEN
    c2$ = MID$(a$, i + 1, 1): c2 = ASC(c2$)
    IF (c2 >= 48 AND c2 <= 57) THEN GOTO lfnumber
END IF
IF (c >= 48 AND c <= 57) THEN '0-9
    lfnumber:

    'handle 'IF a=1 THEN a=2 ELSE 100' by assuming numeric after ELSE to be a
    IF RIGHT$(a2$, 5) = sp + "ELSE" THEN
        a2$ = a2$ + sp + "GOTO"
    END IF

    'Number will be converted to the following format:
    ' 999999  .        99999  E        +         999
    '[whole$][dp(0/1)][frac$][ed(1/2)][pm(1/-1)][ex$]
    ' 0                1               2         3    <-mode

    mode = 0
    whole$ = ""
    dp = 0
    frac$ = ""
    ed = 0 'E=1, D=2, F=3
    pm = 1
    ex$ = ""




    lfreadnumber:
    valid = 0

    IF c = 46 THEN
        IF mode = 0 THEN valid = 1: dp = 1: mode = 1
    END IF

    IF c >= 48 AND c <= 57 THEN '0-9
        valid = 1
        IF mode = 0 THEN whole$ = whole$ + c$
        IF mode = 1 THEN frac$ = frac$ + c$
        IF mode = 2 THEN mode = 3
        IF mode = 3 THEN ex$ = ex$ + c$
    END IF

    IF c = 69 OR c = 68 OR c = 70 THEN 'E,D,F
        IF mode < 2 THEN
            valid = 1
            IF c = 69 THEN ed = 1
            IF c = 68 THEN ed = 2
            IF c = 70 THEN ed = 3
            mode = 2
        END IF
    END IF

    IF c = 43 OR c = 45 THEN '+,-
        IF mode = 2 THEN
            valid = 1
            IF c = 45 THEN pm = -1
            mode = 3
        END IF
    END IF

    IF valid THEN
        IF i <= n THEN i = i + 1: c$ = MID$(a$, i, 1): c = ASC(c$): GOTO lfreadnumber
    END IF



    'cull leading 0s off whole$
    DO WHILE LEFT$(whole$, 1) = "0": whole$ = RIGHT$(whole$, LEN(whole$) - 1): LOOP
    'cull trailing 0s off frac$
    DO WHILE RIGHT$(frac$, 1) = "0": frac$ = LEFT$(frac$, LEN(frac$) - 1): LOOP
    'cull leading 0s off ex$
    DO WHILE LEFT$(ex$, 1) = "0": ex$ = RIGHT$(ex$, LEN(ex$) - 1): LOOP

    IF dp <> 0 OR ed <> 0 THEN float = 1 ELSE float = 0

    extused = 1

    IF ed THEN e$ = "": GOTO lffoundext 'no extensions valid after E/D/F specified

    '3-character extensions
    IF i <= n - 2 THEN
        e$ = MID$(a$, i, 3)
        IF e$ = "~%%" AND float = 0 THEN i = i + 3: GOTO lffoundext
        IF e$ = "~&&" AND float = 0 THEN i = i + 3: GOTO lffoundext
        IF e$ = "~%&" AND float = 0 THEN Give_Error "Cannot use _OFFSET symbols after numbers": EXIT FUNCTION
    END IF
    '2-character extensions
    IF i <= n - 1 THEN
        e$ = MID$(a$, i, 2)
        IF e$ = "%%" AND float = 0 THEN i = i + 2: GOTO lffoundext
        IF e$ = "~%" AND float = 0 THEN i = i + 2: GOTO lffoundext
        IF e$ = "&&" AND float = 0 THEN i = i + 2: GOTO lffoundext
        IF e$ = "~&" AND float = 0 THEN i = i + 2: GOTO lffoundext
        IF e$ = "%&" AND float = 0 THEN Give_Error "Cannot use _OFFSET symbols after numbers": EXIT FUNCTION
        IF e$ = "##" THEN
            i = i + 2
            ed = 3
            e$ = ""
            GOTO lffoundext
        END IF
        IF e$ = "~`" THEN
            i = i + 2
            GOTO lffoundbitext
        END IF
    END IF
    '1-character extensions
    IF i <= n THEN
        e$ = MID$(a$, i, 1)
        IF e$ = "%" AND float = 0 THEN i = i + 1: GOTO lffoundext
        IF e$ = "&" AND float = 0 THEN i = i + 1: GOTO lffoundext
        IF e$ = "!" THEN
            i = i + 1
            ed = 1
            e$ = ""
            GOTO lffoundext
        END IF
        IF e$ = "#" THEN
            i = i + 1
            ed = 2
            e$ = ""
            GOTO lffoundext
        END IF
        IF e$ = "`" THEN
            i = i + 1
            lffoundbitext:
            bitn$ = ""
            DO WHILE i <= n
                c2 = ASC(MID$(a$, i, 1))
                IF c2 >= 48 AND c2 <= 57 THEN
                    bitn$ = bitn$ + CHR$(c2)
                    i = i + 1
                ELSE
                    EXIT DO
                END IF
            LOOP
            IF bitn$ = "" THEN bitn$ = "1"
            'cull leading 0s off bitn$
            DO WHILE LEFT$(bitn$, 1) = "0": bitn$ = RIGHT$(bitn$, LEN(bitn$) - 1): LOOP
            e$ = e$ + bitn$
            GOTO lffoundext
        END IF
    END IF

    IF float THEN 'floating point types CAN be assumed
        'calculate first significant digit offset & number of significant digits
        IF whole$ <> "" THEN
            offset = LEN(whole$) - 1
            sigdigits = LEN(whole$) + LEN(frac$)
        ELSE
            IF frac$ <> "" THEN
                offset = -1
                sigdigits = LEN(frac$)
                FOR i2 = 1 TO LEN(frac$)
                    IF MID$(frac$, i2, 1) <> "0" THEN EXIT FOR
                    offset = offset - 1
                    sigdigits = sigdigits - 1
                NEXT
            ELSE
                'number is 0
                offset = 0
                sigdigits = 0
            END IF
        END IF
        sigdig$ = RIGHT$(whole$ + frac$, sigdigits)
        'SINGLE?
        IF sigdigits <= 7 THEN 'QBASIC interprets anything with more than 7 sig. digits as a DOUBLE
            IF offset <= 38 AND offset >= -38 THEN 'anything outside this range cannot be represented as a SINGLE
                IF offset = 38 THEN
                    IF sigdig$ > "3402823" THEN GOTO lfxsingle
                END IF
                IF offset = -38 THEN
                    IF sigdig$ < "1175494" THEN GOTO lfxsingle
                END IF
                ed = 1
                e$ = ""
                GOTO lffoundext
            END IF
        END IF
        lfxsingle:
        'DOUBLE?
        IF sigdigits <= 16 THEN 'QB64 handles DOUBLES with 16-digit precision
            IF offset <= 308 AND offset >= -308 THEN 'anything outside this range cannot be represented as a DOUBLE
                IF offset = 308 THEN
                    IF sigdig$ > "1797693134862315" THEN GOTO lfxdouble
                END IF
                IF offset = -308 THEN
                    IF sigdig$ < "2225073858507201" THEN GOTO lfxdouble
                END IF
                ed = 2
                e$ = ""
                GOTO lffoundext
            END IF
        END IF
        lfxdouble:
        'assume _FLOAT
        ed = 3
        e$ = "": GOTO lffoundext
    END IF

    extused = 0
    e$ = ""
    lffoundext:

    'make sure a leading numberic character exists
    IF whole$ = "" THEN whole$ = "0"
    'if a float, ensure frac$<>"" and dp=1
    IF float THEN
        dp = 1
        IF frac$ = "" THEN frac$ = "0"
    END IF
    'if ed is specified, make sure ex$ exists
    IF ed <> 0 AND ex$ = "" THEN ex$ = "0"

    a2$ = a2$ + sp
    a2$ = a2$ + whole$
    IF dp THEN a2$ = a2$ + "." + frac$
    IF ed THEN
        IF ed = 1 THEN a2$ = a2$ + "E"
        IF ed = 2 THEN a2$ = a2$ + "D"
        IF ed = 3 THEN a2$ = a2$ + "F"
        IF pm = -1 AND ex$ <> "0" THEN a2$ = a2$ + "-" ELSE a2$ = a2$ + "+"
        a2$ = a2$ + ex$
    END IF
    a2$ = a2$ + e$

    IF extused THEN a2$ = a2$ + "," + MID$(a$, firsti, i - firsti)

    GOTO lineformatnext
END IF

'----------------(number)&H...----------------
'note: the final value, not the number of hex characters, sets the default type
IF c = 38 THEN '&
    IF MID$(a$, i + 1, 1) = "H" THEN
        i = i + 2
        hx$ = ""
        lfreadhex:
        IF i <= n THEN
            c$ = MID$(a$, i, 1): c = ASC(c$)
            IF (c >= 48 AND c <= 57) OR (c >= 65 AND c <= 70) THEN hx$ = hx$ + c$: i = i + 1: GOTO lfreadhex
        END IF
        fullhx$ = "&H" + hx$

        'cull leading 0s off hx$
        DO WHILE LEFT$(hx$, 1) = "0": hx$ = RIGHT$(hx$, LEN(hx$) - 1): LOOP
        IF hx$ = "" THEN hx$ = "0"

        bitn$ = ""
        '3-character extensions
        IF i <= n - 2 THEN
            e$ = MID$(a$, i, 3)
            IF e$ = "~%%" THEN i = i + 3: GOTO lfhxext
            IF e$ = "~&&" THEN i = i + 3: GOTO lfhxext
            IF e$ = "~%&" THEN Give_Error "Cannot use _OFFSET symbols after numbers": EXIT FUNCTION
        END IF
        '2-character extensions
        IF i <= n - 1 THEN
            e$ = MID$(a$, i, 2)
            IF e$ = "%%" THEN i = i + 2: GOTO lfhxext
            IF e$ = "~%" THEN i = i + 2: GOTO lfhxext
            IF e$ = "&&" THEN i = i + 2: GOTO lfhxext
            IF e$ = "%&" THEN Give_Error "Cannot use _OFFSET symbols after numbers": EXIT FUNCTION
            IF e$ = "~&" THEN i = i + 2: GOTO lfhxext
            IF e$ = "~`" THEN
                i = i + 2
                GOTO lfhxbitext
            END IF
        END IF
        '1-character extensions
        IF i <= n THEN
            e$ = MID$(a$, i, 1)
            IF e$ = "%" THEN i = i + 1: GOTO lfhxext
            IF e$ = "&" THEN i = i + 1: GOTO lfhxext
            IF e$ = "`" THEN
                i = i + 1
                lfhxbitext:
                DO WHILE i <= n
                    c2 = ASC(MID$(a$, i, 1))
                    IF c2 >= 48 AND c2 <= 57 THEN
                        bitn$ = bitn$ + CHR$(c2)
                        i = i + 1
                    ELSE
                        EXIT DO
                    END IF
                LOOP
                IF bitn$ = "" THEN bitn$ = "1"
                'cull leading 0s off bitn$
                DO WHILE LEFT$(bitn$, 1) = "0": bitn$ = RIGHT$(bitn$, LEN(bitn$) - 1): LOOP
                GOTO lfhxext
            END IF
        END IF
        'if no valid extension context was given, assume one
        'note: leading 0s have been culled, so LEN(hx$) reflects its values size
        e$ = "&&"
        IF LEN(hx$) <= 8 THEN e$ = "&" 'as in QBASIC, signed values must be used
        IF LEN(hx$) <= 4 THEN e$ = "%" 'as in QBASIC, signed values must be used
        GOTO lfhxext2
        lfhxext:
        fullhx$ = fullhx$ + e$ + bitn$
        lfhxext2:

        'build 8-byte unsigned integer rep. of hx$
        IF LEN(hx$) > 16 THEN Give_Error "Overflow": EXIT FUNCTION
        v~&& = 0
        FOR i2 = 1 TO LEN(hx$)
            v2 = ASC(MID$(hx$, i2, 1))
            IF v2 <= 57 THEN v2 = v2 - 48 ELSE v2 = v2 - 65 + 10
            v~&& = v~&& * 16 + v2
        NEXT

        finishhexoctbin:
        num$ = str2u64$(v~&&) 'correct for unsigned values (overflow of unsigned can be checked later)
        IF LEFT$(e$, 1) <> "~" THEN 'note: range checking will be performed later in fixop.order
            'signed

            IF e$ = "%%" THEN
                IF v~&& > 127 THEN
                    IF v~&& > 255 THEN Give_Error "Overflow": EXIT FUNCTION
                    v~&& = ((NOT v~&&) AND 255) + 1
                    num$ = "-" + sp + str2u64$(v~&&)
                END IF
            END IF

            IF e$ = "%" THEN
                IF v~&& > 32767 THEN
                    IF v~&& > 65535 THEN Give_Error "Overflow": EXIT FUNCTION
                    v~&& = ((NOT v~&&) AND 65535) + 1
                    num$ = "-" + sp + str2u64$(v~&&)
                END IF
            END IF

            IF e$ = "&" THEN
                IF v~&& > 2147483647 THEN
                    IF v~&& > 4294967295 THEN Give_Error "Overflow": EXIT FUNCTION
                    v~&& = ((NOT v~&&) AND 4294967295) + 1
                    num$ = "-" + sp + str2u64$(v~&&)
                END IF
            END IF

            IF e$ = "&&" THEN
                IF v~&& > 9223372036854775807 THEN
                    'note: no error checking necessary
                    v~&& = (NOT v~&&) + 1
                    num$ = "-" + sp + str2u64$(v~&&)
                END IF
            END IF

            IF e$ = "`" THEN
                vbitn = VAL(bitn$)
                h~&& = 1: FOR i2 = 1 TO vbitn - 1: h~&& = h~&& * 2: NEXT: h~&& = h~&& - 1 'build h~&&
                IF v~&& > h~&& THEN
                    h~&& = 1: FOR i2 = 1 TO vbitn: h~&& = h~&& * 2: NEXT: h~&& = h~&& - 1 'build h~&&
                    IF v~&& > h~&& THEN Give_Error "Overflow": EXIT FUNCTION
                    v~&& = ((NOT v~&&) AND h~&&) + 1
                    num$ = "-" + sp + str2u64$(v~&&)
                END IF
            END IF

        END IF '<>"~"

        a2$ = a2$ + sp + num$ + e$ + bitn$ + "," + fullhx$

        GOTO lineformatnext
    END IF
END IF

'----------------(number)&O...----------------
'note: the final value, not the number of oct characters, sets the default type
IF c = 38 THEN '&
    IF MID$(a$, i + 1, 1) = "O" THEN
        i = i + 2
        'note: to avoid mistakes, hx$ is used instead of 'ot$'
        hx$ = ""
        lfreadoct:
        IF i <= n THEN
            c$ = MID$(a$, i, 1): c = ASC(c$)
            IF c >= 48 AND c <= 55 THEN hx$ = hx$ + c$: i = i + 1: GOTO lfreadoct
        END IF
        fullhx$ = "&O" + hx$

        'cull leading 0s off hx$
        DO WHILE LEFT$(hx$, 1) = "0": hx$ = RIGHT$(hx$, LEN(hx$) - 1): LOOP
        IF hx$ = "" THEN hx$ = "0"

        bitn$ = ""
        '3-character extensions
        IF i <= n - 2 THEN
            e$ = MID$(a$, i, 3)
            IF e$ = "~%%" THEN i = i + 3: GOTO lfotext
            IF e$ = "~&&" THEN i = i + 3: GOTO lfotext
            IF e$ = "~%&" THEN Give_Error "Cannot use _OFFSET symbols after numbers": EXIT FUNCTION
        END IF
        '2-character extensions
        IF i <= n - 1 THEN
            e$ = MID$(a$, i, 2)
            IF e$ = "%%" THEN i = i + 2: GOTO lfotext
            IF e$ = "~%" THEN i = i + 2: GOTO lfotext
            IF e$ = "&&" THEN i = i + 2: GOTO lfotext
            IF e$ = "%&" THEN Give_Error "Cannot use _OFFSET symbols after numbers": EXIT FUNCTION
            IF e$ = "~&" THEN i = i + 2: GOTO lfotext
            IF e$ = "~`" THEN
                i = i + 2
                GOTO lfotbitext
            END IF
        END IF
        '1-character extensions
        IF i <= n THEN
            e$ = MID$(a$, i, 1)
            IF e$ = "%" THEN i = i + 1: GOTO lfotext
            IF e$ = "&" THEN i = i + 1: GOTO lfotext
            IF e$ = "`" THEN
                i = i + 1
                lfotbitext:
                bitn$ = ""
                DO WHILE i <= n
                    c2 = ASC(MID$(a$, i, 1))
                    IF c2 >= 48 AND c2 <= 57 THEN
                        bitn$ = bitn$ + CHR$(c2)
                        i = i + 1
                    ELSE
                        EXIT DO
                    END IF
                LOOP
                IF bitn$ = "" THEN bitn$ = "1"
                'cull leading 0s off bitn$
                DO WHILE LEFT$(bitn$, 1) = "0": bitn$ = RIGHT$(bitn$, LEN(bitn$) - 1): LOOP
                GOTO lfotext
            END IF
        END IF
        'if no valid extension context was given, assume one
        'note: leading 0s have been culled, so LEN(hx$) reflects its values size
        e$ = "&&"
        '37777777777
        IF LEN(hx$) <= 11 THEN
            IF LEN(hx$) < 11 OR ASC(LEFT$(hx$, 1)) <= 51 THEN e$ = "&"
        END IF
        '177777
        IF LEN(hx$) <= 6 THEN
            IF LEN(hx$) < 6 OR LEFT$(hx$, 1) = "1" THEN e$ = "%"
        END IF

        GOTO lfotext2
        lfotext:
        fullhx$ = fullhx$ + e$ + bitn$
        lfotext2:

        'build 8-byte unsigned integer rep. of hx$
        '1777777777777777777777 (22 digits)
        IF LEN(hx$) > 22 THEN Give_Error "Overflow": EXIT FUNCTION
        IF LEN(hx$) = 22 THEN
            IF LEFT$(hx$, 1) <> "1" THEN Give_Error "Overflow": EXIT FUNCTION
        END IF
        '********change v& to v~&&********
        v~&& = 0
        FOR i2 = 1 TO LEN(hx$)
            v2 = ASC(MID$(hx$, i2, 1))
            v2 = v2 - 48
            v~&& = v~&& * 8 + v2
        NEXT

        GOTO finishhexoctbin
    END IF
END IF

'----------------(number)&B...----------------
'note: the final value, not the number of bin characters, sets the default type
IF c = 38 THEN '&
    IF MID$(a$, i + 1, 1) = "B" THEN
        i = i + 2
        'note: to avoid mistakes, hx$ is used instead of 'bi$'
        hx$ = ""
        lfreadbin:
        IF i <= n THEN
            c$ = MID$(a$, i, 1): c = ASC(c$)
            IF c >= 48 AND c <= 49 THEN hx$ = hx$ + c$: i = i + 1: GOTO lfreadbin
        END IF
        fullhx$ = "&B" + hx$

        'cull leading 0s off hx$
        DO WHILE LEFT$(hx$, 1) = "0": hx$ = RIGHT$(hx$, LEN(hx$) - 1): LOOP
        IF hx$ = "" THEN hx$ = "0"

        bitn$ = ""
        '3-character extensions
        IF i <= n - 2 THEN
            e$ = MID$(a$, i, 3)
            IF e$ = "~%%" THEN i = i + 3: GOTO lfbiext
            IF e$ = "~&&" THEN i = i + 3: GOTO lfbiext
            IF e$ = "~%&" THEN Give_Error "Cannot use _OFFSET symbols after numbers": EXIT FUNCTION
        END IF
        '2-character extensions
        IF i <= n - 1 THEN
            e$ = MID$(a$, i, 2)
            IF e$ = "%%" THEN i = i + 2: GOTO lfbiext
            IF e$ = "~%" THEN i = i + 2: GOTO lfbiext
            IF e$ = "&&" THEN i = i + 2: GOTO lfbiext
            IF e$ = "%&" THEN Give_Error "Cannot use _OFFSET symbols after numbers": EXIT FUNCTION
            IF e$ = "~&" THEN i = i + 2: GOTO lfbiext
            IF e$ = "~`" THEN
                i = i + 2
                GOTO lfbibitext
            END IF
        END IF


        '1-character extensions
        IF i <= n THEN
            e$ = MID$(a$, i, 1)
            IF e$ = "%" THEN i = i + 1: GOTO lfbiext
            IF e$ = "&" THEN i = i + 1: GOTO lfbiext
            IF e$ = "`" THEN
                i = i + 1
                lfbibitext:
                bitn$ = ""
                DO WHILE i <= n
                    c2 = ASC(MID$(a$, i, 1))
                    IF c2 >= 48 AND c2 <= 57 THEN
                        bitn$ = bitn$ + CHR$(c2)
                        i = i + 1
                    ELSE
                        EXIT DO
                    END IF
                LOOP
                IF bitn$ = "" THEN bitn$ = "1"
                'cull leading 0s off bitn$
                DO WHILE LEFT$(bitn$, 1) = "0": bitn$ = RIGHT$(bitn$, LEN(bitn$) - 1): LOOP
                GOTO lfbiext
            END IF
        END IF
        'if no valid extension context was given, assume one
        'note: leading 0s have been culled, so LEN(hx$) reflects its values size
        e$ = "&&"
        IF LEN(hx$) <= 32 THEN e$ = "&"
        IF LEN(hx$) <= 16 THEN e$ = "%"

        GOTO lfbiext2
        lfbiext:
        fullhx$ = fullhx$ + e$ + bitn$
        lfbiext2:

        'build 8-byte unsigned integer rep. of hx$
        IF LEN(hx$) > 64 THEN Give_Error "Overflow": EXIT FUNCTION

        v~&& = 0
        FOR i2 = 1 TO LEN(hx$)
            v2 = ASC(MID$(hx$, i2, 1))
            v2 = v2 - 48
            v~&& = v~&& * 2 + v2
        NEXT

        GOTO finishhexoctbin
    END IF
END IF


'----------------(number)&H??? error----------------
IF c = 38 THEN Give_Error "Expected &H... or &O...": EXIT FUNCTION

'----------------variable/name----------------
'*trailing _ is treated as a seperate line extension*
IF (c >= 65 AND c <= 90) OR c = 95 THEN 'A-Z(a-z) or _
    IF c = 95 THEN p2 = 0 ELSE p2 = i
    FOR i2 = i + 1 TO n
        c2 = ASC(a$, i2)
        IF NOT alphanumeric(c2) THEN EXIT FOR
        IF c2 <> 95 THEN p2 = i2
    NEXT
    IF p2 THEN 'not just underscores!
        'char is from i to p2
        n2 = p2 - i + 1
        a3$ = MID$(a$, i, n2)

        '----(variable/name)rem----
        IF n2 = 3 THEN
            IF a3$ = "REM" THEN
                i = i + n2
                'note: In QBASIC 'IF cond THEN REM comment' counts as a single line IF statement, however use of ' instead of REM does not
                IF UCASE$(RIGHT$(a2$, 5)) = sp + "THEN" THEN a2$ = a2$ + sp + "'" 'add nop
                layoutcomment = "REM"
                GOTO comment
            END IF
        END IF

        '----(variable/name)data----
        IF n2 = 4 THEN
            IF a3$ = "DATA" THEN
                x$ = ""
                i = i + n2
                scan = 0
                speechmarks = 0
                commanext = 0
                finaldata = 0
                e$ = ""
                p1 = 0
                p2 = 0
                nextdatachr:
                IF i < n THEN
                    c = ASC(a$, i)

                    IF c = 9 OR c = 32 THEN
                        IF scan = 0 THEN GOTO skipwhitespace
                    END IF

                    IF c = 58 THEN '":"
                        IF speechmarks = 0 THEN finaldata = 1: GOTO adddata
                    END IF

                    IF c = 44 THEN '","
                        IF speechmarks = 0 THEN
                            adddata:
                            IF prepass = 0 THEN
                                IF p1 THEN
                                    'FOR i2 = p1 TO p2
                                    '    DATA_add ASC(ca$, i2)
                                    'NEXT
                                    x$ = x$ + MID$(ca$, p1, p2 - p1 + 1)
                                END IF
                                'assume closing "
                                IF speechmarks THEN
                                    'DATA_add 34
                                    x$ = x$ + CHR$(34)
                                END IF
                                'append comma
                                'DATA_add 44
                                x$ = x$ + CHR$(44)
                            END IF
                            IF finaldata = 1 THEN GOTO finisheddata
                            e$ = ""
                            p1 = 0
                            p2 = 0
                            speechmarks = 0
                            scan = 0
                            commanext = 0
                            i = i + 1
                            GOTO nextdatachr
                        END IF
                    END IF '","

                    IF commanext = 1 THEN
                        IF c <> 32 AND c <> 9 THEN Give_Error "Expected , after quoted string in DATA statement": EXIT FUNCTION
                    END IF

                    IF c = 34 THEN
                        IF speechmarks = 1 THEN
                            commanext = 1
                            speechmarks = 0
                        END IF
                        IF scan = 0 THEN speechmarks = 1
                    END IF

                    scan = 1

                    IF p1 = 0 THEN p1 = i: p2 = i
                    IF c <> 9 AND c <> 32 THEN p2 = i

                    skipwhitespace:
                    i = i + 1: GOTO nextdatachr
                END IF 'i<n
                finaldata = 1: GOTO adddata
                finisheddata:
                e$ = ""
                IF prepass = 0 THEN
                    PUT #16, , x$
                    DataOffset = DataOffset + LEN(x$)

                    e$ = SPACE$((LEN(x$) - 1) * 2)
                    FOR ec = 1 TO LEN(x$) - 1
                        '2 chr hex encode each character
                        v1 = ASC(x$, ec)
                        v2 = v1 \ 16: IF v2 <= 9 THEN v2 = v2 + 48 ELSE v2 = v2 + 55
                        v1 = v1 AND 15: IF v1 <= 9 THEN v1 = v1 + 48 ELSE v1 = v1 + 55
                        ASC(e$, ec * 2 - 1) = v1
                        ASC(e$, ec * 2) = v2
                    NEXT

                END IF

                a2$ = a2$ + sp + "DATA": IF LEN(e$) THEN a2$ = a2$ + sp + "_" + e$
                GOTO lineformatnext
            END IF
        END IF

        a2$ = a2$ + sp + MID$(ca$, i, n2)
        i = i + n2

        '----(variable/name)extensions----
        extcheck:
        IF n2 > 40 THEN Give_Error "Identifier longer than 40 character limit": EXIT FUNCTION
        c3 = ASC(a$, i)
        m = 0
        IF c3 = 126 THEN '"~"
            e2$ = MID$(a$, i + 1, 2)
            IF e2$ = "&&" THEN e2$ = "~&&": GOTO lfgetve
            IF e2$ = "%%" THEN e2$ = "~%%": GOTO lfgetve
            IF e2$ = "%&" THEN e2$ = "~%&": GOTO lfgetve
            e2$ = CHR$(ASC(e2$))
            IF e2$ = "&" THEN e2$ = "~&": GOTO lfgetve
            IF e2$ = "%" THEN e2$ = "~%": GOTO lfgetve
            IF e2$ = "`" THEN m = 1: e2$ = "~`": GOTO lfgetve
        END IF
        IF c3 = 37 THEN
            c4 = ASC(a$, i + 1)
            IF c4 = 37 THEN e2$ = "%%": GOTO lfgetve
            IF c4 = 38 THEN e2$ = "%&": GOTO lfgetve
            e2$ = "%": GOTO lfgetve
        END IF
        IF c3 = 38 THEN
            c4 = ASC(a$, i + 1)
            IF c4 = 38 THEN e2$ = "&&": GOTO lfgetve
            e2$ = "&": GOTO lfgetve
        END IF
        IF c3 = 33 THEN e2$ = "!": GOTO lfgetve
        IF c3 = 35 THEN
            c4 = ASC(a$, i + 1)
            IF c4 = 35 THEN e2$ = "##": GOTO lfgetve
            e2$ = "#": GOTO lfgetve
        END IF
        IF c3 = 36 THEN m = 1: e2$ = "$": GOTO lfgetve
        IF c3 = 96 THEN m = 1: e2$ = "`": GOTO lfgetve
        '(no symbol)

        'cater for unusual names/labels (eg a.0b%)
        IF ASC(a$, i) = 46 THEN '"."
            c2 = ASC(a$, i + 1)
            IF c2 >= 48 AND c2 <= 57 THEN
                'scan until no further alphanumerics
                p2 = i + 1
                FOR i2 = i + 2 TO n
                    c = ASC(a$, i2)

                    IF NOT alphanumeric(c) THEN EXIT FOR
                    IF c <> 95 THEN p2 = i2 'don't including trailing _
                NEXT
                a2$ = a2$ + sp + "." + sp + MID$(ca$, i + 1, p2 - (i + 1) + 1) 'case sensitive
                n2 = n2 + 1 + (p2 - (i + 1) + 1)
                i = p2 + 1
                GOTO extcheck 'it may have an extension or be continued with another "."
            END IF
        END IF

        GOTO lineformatnext

        lfgetve:
        i = i + LEN(e2$)
        a2$ = a2$ + e2$
        IF m THEN 'allow digits after symbol
            lfgetvd:
            IF i < n THEN
                c = ASC(a$, i)
                IF c >= 48 AND c <= 57 THEN a2$ = a2$ + CHR$(c): i = i + 1: GOTO lfgetvd
            END IF
        END IF 'm

        GOTO lineformatnext

    END IF 'p2
END IF 'variable/name
'----------------variable/name end----------------

'----------------spacing----------------
IF c = 32 OR c = 9 THEN i = i + 1: GOTO lineformatnext

'----------------symbols----------------
'--------single characters--------
IF lfsinglechar(c) THEN

    count = 0
    DO
        count = count + 1
    LOOP UNTIL ASC(a$, i + count) <> 32
    c2 = ASC(a$, i + count)
    IF c = 60 THEN '<
        IF c2 = 61 THEN a2$ = a2$ + sp + "<=": i = i + count + 1: GOTO lineformatnext
        IF c2 = 62 THEN a2$ = a2$ + sp + "<>": i = i + count + 1: GOTO lineformatnext
    END IF
    IF c = 62 THEN '>
        IF c2 = 61 THEN a2$ = a2$ + sp + ">=": i = i + count + 1: GOTO lineformatnext
        IF c2 = 60 THEN a2$ = a2$ + sp + "<>": i = i + count + 1: GOTO lineformatnext '>< to <>
    END IF
    IF c = 61 THEN '=
        c2 = ASC(a$, i + 1)
        IF c2 = 62 THEN a2$ = a2$ + sp + ">=": i = i + count + 1: GOTO lineformatnext '=> to >=
        IF c2 = 60 THEN a2$ = a2$ + sp + "<=": i = i + count + 1: GOTO lineformatnext '=< to <=
    END IF

    IF c = 36 AND LEN(a2$) THEN GOTO badusage '$


    a2$ = a2$ + sp + CHR$(c)
    i = i + 1
    GOTO lineformatnext
END IF
badusage:

IF c <> 39 THEN Give_Error "Unexpected character on line": EXIT FUNCTION 'invalid symbol encountered

'----------------comment(')----------------
layoutcomment = "'"
i = i + 1
comment:
IF i >= n THEN GOTO lineformatdone2
c$ = RIGHT$(a$, LEN(a$) - i + 1)
cc$ = RIGHT$(ca$, LEN(ca$) - i + 1)
IF LEN(c$) = 0 THEN GOTO lineformatdone2
layoutcomment$ = RTRIM$(layoutcomment$ + cc$)

c$ = LTRIM$(c$)
IF LEN(c$) = 0 THEN GOTO lineformatdone2
ac = ASC(c$)
IF ac <> 36 THEN GOTO lineformatdone2
nocasec$ = LTRIM$(RIGHT$(ca$, LEN(ca$) - i + 1))
memmode = 0
FOR x = 1 TO LEN(c$)
    mcnext:
    IF MID$(c$, x, 1) = "$" THEN

        'note: $STATICksdcdweh$DYNAMIC is valid!

        IF MID$(c$, x, 7) = "$STATIC" THEN
            memmode = 1
            xx = INSTR(x + 1, c$, "$")
            if xx=0 then exit for else
            x = xx: GOTO mcnext
        END IF

        IF MID$(c$, x, 8) = "$DYNAMIC" THEN
            memmode = 2
            xx = INSTR(x + 1, c$, "$")
            IF xx = 0 THEN EXIT FOR
            x = xx: GOTO mcnext
        END IF

        IF MID$(c$, x, 8) = "$INCLUDE" THEN
            IF Cloud THEN Give_Error "Feature not supported on QLOUD": EXIT FUNCTION
            'note: INCLUDE adds the file AFTER the line it is on has been processed
            'note: No other metacommands can follow the INCLUDE metacommand!
            'skip spaces until :
            FOR xx = x + 8 TO LEN(c$)
                ac = ASC(MID$(c$, xx, 1))
                IF ac = 58 THEN EXIT FOR ':
                IF ac <> 32 AND ac <> 9 THEN Give_Error "Expected $INCLUDE:'filename'": EXIT FUNCTION
            NEXT
            x = xx
            'skip spaces until '
            FOR xx = x + 1 TO LEN(c$)
                ac = ASC(MID$(c$, xx, 1))
                IF ac = 39 THEN EXIT FOR 'character:'
                IF ac <> 32 AND ac <> 9 THEN Give_Error "Expected $INCLUDE:'filename'": EXIT FUNCTION
            NEXT
            x = xx
            xx = INSTR(x + 1, c$, "'")
            IF xx = 0 THEN Give_Error "Expected $INCLUDE:'filename'": EXIT FUNCTION
            addmetainclude$ = MID$(nocasec$, x + 1, xx - x - 1)
            IF addmetainclude$ = "" THEN Give_Error "Expected $INCLUDE:'filename'": EXIT FUNCTION
            GOTO mcfinal
        END IF

        'add more metacommands here

    END IF '$
NEXT
mcfinal:

IF memmode = 1 THEN addmetastatic = 1
IF memmode = 2 THEN addmetadynamic = 1

GOTO lineformatdone2



lineformatdone:

'line continuation?
'note: line continuation in idemode is illegal
IF LEN(a2$) THEN
    IF RIGHT$(a2$, 1) = "_" THEN

        linecontinuation = 1 'avoids auto-format glitches
        layout$ = ""

        'remove _ from the end of the building string
        IF LEN(a2$) >= 2 THEN
            IF RIGHT$(a2$, 2) = sp + "_" THEN a2$ = LEFT$(a2$, LEN(a2$) - 1)
        END IF
        a2$ = LEFT$(a2$, LEN(a2$) - 1)

        IF inclevel THEN
            fh = 99 + inclevel
            IF EOF(fh) THEN GOTO lineformatdone2
            LINE INPUT #fh, a$
            inclinenumber(inclevel) = inclinenumber(inclevel) + 1
            GOTO includecont 'note: should not increase linenumber
        END IF

        IF idemode THEN
            idecommand$ = CHR$(100)
            ignore = ide(0)
            ideerror = 0
            a$ = idereturn$
            IF a$ = "" THEN GOTO lineformatdone2
        ELSE
            a$ = lineinput3$
            IF a$ = CHR$(13) THEN GOTO lineformatdone2
        END IF

        linenumber = linenumber + 1

        includecont:

        contline = 1
        GOTO continueline
    END IF
END IF

lineformatdone2:
IF LEFT$(a2$, 1) = sp THEN a2$ = RIGHT$(a2$, LEN(a2$) - 1)

'fix for trailing : error
IF RIGHT$(a2$, 1) = ":" THEN a2$ = a2$ + sp + "'" 'add nop

IF Debug THEN PRINT #9, "lineformat():return:" + a2$
IF Error_Happened THEN EXIT FUNCTION
lineformat$ = a2$

END FUNCTION


SUB makeidrefer (ref$, typ AS LONG)
ref$ = str2$(currentid)
typ = id.t + ISREFERENCE
END SUB

FUNCTION numelements (a$)
IF a$ = "" THEN EXIT FUNCTION
n = 1
p = 1
numelementsnext:
i = INSTR(p, a$, sp)
IF i = 0 THEN numelements = n: EXIT FUNCTION
n = n + 1
p = i + 1
GOTO numelementsnext
END FUNCTION

FUNCTION operatorusage (operator$, typ AS LONG, info$, lhs AS LONG, rhs AS LONG, result AS LONG)
lhs = 7: rhs = 7: result = 0
'return values
'1 = use info$ as the operator without any other changes
'2 = use the function returned in info$ to apply this operator
'    upon left and right side of equation
'3=  bracket left and right side with negation and change operator to info$
'4=  BINARY NOT l.h.s, then apply operator in info$
'5=  UNARY, bracket up rhs, apply operator info$ to left, rebracket again

'lhs & rhs bit-field values
'1=integeral
'2=floating point
'4=string
'8=bool

'string operator
IF (typ AND ISSTRING) THEN
    lhs = 4: rhs = 4
    result = 4
    IF operator$ = "+" THEN info$ = "qbs_add": operatorusage = 2: EXIT FUNCTION
    result = 8
    IF operator$ = "=" THEN info$ = "qbs_equal": operatorusage = 2: EXIT FUNCTION
    IF operator$ = "<>" THEN info$ = "qbs_notequal": operatorusage = 2: EXIT FUNCTION
    IF operator$ = ">" THEN info$ = "qbs_greaterthan": operatorusage = 2: EXIT FUNCTION
    IF operator$ = "<" THEN info$ = "qbs_lessthan": operatorusage = 2: EXIT FUNCTION
    IF operator$ = ">=" THEN info$ = "qbs_greaterorequal": operatorusage = 2: EXIT FUNCTION
    IF operator$ = "<=" THEN info$ = "qbs_lessorequal": operatorusage = 2: EXIT FUNCTION
    IF Debug THEN PRINT #9, "INVALID STRING OPERATOR!": END
END IF

'assume numeric operator
lhs = 1 + 2: rhs = 1 + 2
IF operator$ = "^" THEN result = 2: info$ = "pow2": operatorusage = 2: EXIT FUNCTION
IF operator$ = "�" THEN info$ = "-": operatorusage = 5: EXIT FUNCTION
IF operator$ = "/" THEN
    info$ = "/ ": operatorusage = 1
    'for / division, either the lhs or the rhs must be a float to make
    'c++ return a result in floating point form
    IF (typ AND ISFLOAT) THEN
        'lhs is a float
        lhs = 2
        rhs = 1 + 2
    ELSE
        'lhs isn't a float!
        lhs = 1 + 2
        rhs = 2
    END IF
    result = 2
    EXIT FUNCTION
END IF
IF operator$ = "*" THEN info$ = "*": operatorusage = 1: EXIT FUNCTION
IF operator$ = "+" THEN info$ = "+": operatorusage = 1: EXIT FUNCTION
IF operator$ = "-" THEN info$ = "-": operatorusage = 1: EXIT FUNCTION

result = 8
IF operator$ = "=" THEN info$ = "==": operatorusage = 3: EXIT FUNCTION
IF operator$ = ">" THEN info$ = ">": operatorusage = 3: EXIT FUNCTION
IF operator$ = "<" THEN info$ = "<": operatorusage = 3: EXIT FUNCTION
IF operator$ = "<>" THEN info$ = "!=": operatorusage = 3: EXIT FUNCTION
IF operator$ = "<=" THEN info$ = "<=": operatorusage = 3: EXIT FUNCTION
IF operator$ = ">=" THEN info$ = ">=": operatorusage = 3: EXIT FUNCTION

lhs = 1: rhs = 1: result = 1
IF operator$ = "MOD" THEN info$ = "%": operatorusage = 1: EXIT FUNCTION
IF operator$ = "\" THEN info$ = "/ ": operatorusage = 1: EXIT FUNCTION
IF operator$ = "IMP" THEN info$ = "|": operatorusage = 4: EXIT FUNCTION
IF operator$ = "EQV" THEN info$ = "^": operatorusage = 4: EXIT FUNCTION
IF operator$ = "XOR" THEN info$ = "^": operatorusage = 1: EXIT FUNCTION
IF operator$ = "OR" THEN info$ = "|": operatorusage = 1: EXIT FUNCTION
IF operator$ = "AND" THEN info$ = "&": operatorusage = 1: EXIT FUNCTION

lhs = 7
IF operator$ = "NOT" THEN info$ = "~": operatorusage = 5: EXIT FUNCTION

IF Debug THEN PRINT #9, "INVALID NUMBERIC OPERATOR!": END

END FUNCTION

FUNCTION refer$ (a2$, typ AS LONG, method AS LONG)
typbak = typ
'method: 0 return an equation which calculates the value of the "variable"
'        1 return the C name of the variable, typ will be left unchanged

a$ = a2$

'retrieve ID
i = INSTR(a$, sp3)
IF i THEN
    idnumber = VAL(LEFT$(a$, i - 1)): a$ = RIGHT$(a$, LEN(a$) - i)
ELSE
    idnumber = VAL(a$)
END IF
getid idnumber
IF Error_Happened THEN EXIT FUNCTION

'UDT?
IF typ AND ISUDT THEN
    IF method = 1 THEN
        n$ = "UDT_" + RTRIM$(id.n)
        IF id.t = 0 THEN n$ = "ARRAY_" + n$
        n$ = scope$ + n$
        refer$ = n$
        EXIT FUNCTION
    END IF

    'print "UDTSUBSTRING[idX|u|e|o]:"+a$

    u = VAL(a$)
    i = INSTR(a$, sp3): a$ = RIGHT$(a$, LEN(a$) - i): E = VAL(a$)
    i = INSTR(a$, sp3): o$ = RIGHT$(a$, LEN(a$) - i)
    n$ = "UDT_" + RTRIM$(id.n): IF id.t = 0 THEN n$ = "ARRAY_" + n$ + "[0]"
    IF E = 0 THEN Give_Error "User defined types in expressions are invalid": EXIT FUNCTION
    IF typ AND ISOFFSETINBITS THEN Give_Error "Cannot resolve bit-length variables inside user defined types yet": EXIT FUNCTION

    IF typ AND ISSTRING THEN
        o2$ = "(((uint8*)" + scope$ + n$ + ")+(" + o$ + "))"
        r$ = "qbs_new_fixed(" + o2$ + "," + str2(udtetypesize(E)) + ",1)"
        typ = STRINGTYPE + ISFIXEDLENGTH 'ISPOINTER retained, it is still a pointer!
    ELSE
        typ = typ - ISUDT - ISREFERENCE - ISPOINTER
        IF typ AND ISARRAY THEN typ = typ - ISARRAY
        t$ = typ2ctyp$(typ, "")
        IF Error_Happened THEN EXIT FUNCTION
        o2$ = "(((char*)" + scope$ + n$ + ")+(" + o$ + "))"
        r$ = "*" + "(" + t$ + "*)" + o2$
    END IF

    'print "REFER:"+r$+","+str2$(typ)
    refer$ = r$
    EXIT FUNCTION
END IF


'array?
IF id.arraytype THEN

    n$ = RTRIM$(id.callname)
    IF method = 1 THEN
        refer$ = n$
        typ = typbak
        EXIT FUNCTION
    END IF
    typ = typ - ISPOINTER - ISREFERENCE 'typ now looks like a regular value

    IF (typ AND ISSTRING) THEN
        IF (typ AND ISFIXEDLENGTH) THEN
            offset$ = "&((uint8*)(" + n$ + "[0]))[(" + a$ + ")*" + str2(id.tsize) + "]"
            r$ = "qbs_new_fixed(" + offset$ + "," + str2(id.tsize) + ",1)"
        ELSE
            r$ = "((qbs*)(((uint64*)(" + n$ + "[0]))[" + a$ + "]))"
        END IF
        stringprocessinghappened = 1
        refer$ = r$
        EXIT FUNCTION
    END IF

    IF (typ AND ISOFFSETINBITS) THEN
        'IF (typ AND ISUNSIGNED) THEN r$ = "getubits_" ELSE r$ = "getbits_"
        'r$ = r$ + str2(typ AND 511) + "("
        IF (typ AND ISUNSIGNED) THEN r$ = "getubits" ELSE r$ = "getbits"
        r$ = r$ + "(" + str2(typ AND 511) + ","
        r$ = r$ + "(uint8*)(" + n$ + "[0])" + ","
        r$ = r$ + a$ + ")"
        refer$ = r$
        EXIT FUNCTION
    ELSE
        t$ = ""
        IF (typ AND ISFLOAT) THEN
            IF (typ AND 511) = 32 THEN t$ = "float"
            IF (typ AND 511) = 64 THEN t$ = "double"
            IF (typ AND 511) = 256 THEN t$ = "long double"
        ELSE
            IF (typ AND ISUNSIGNED) THEN
                IF (typ AND 511) = 8 THEN t$ = "uint8"
                IF (typ AND 511) = 16 THEN t$ = "uint16"
                IF (typ AND 511) = 32 THEN t$ = "uint32"
                IF (typ AND 511) = 64 THEN t$ = "uint64"
                IF typ AND ISOFFSET THEN t$ = "uptrszint"
            ELSE
                IF (typ AND 511) = 8 THEN t$ = "int8"
                IF (typ AND 511) = 16 THEN t$ = "int16"
                IF (typ AND 511) = 32 THEN t$ = "int32"
                IF (typ AND 511) = 64 THEN t$ = "int64"
                IF typ AND ISOFFSET THEN t$ = "ptrszint"
            END IF
        END IF
    END IF
    IF t$ = "" THEN Give_Error "Cannot find C type to return array data": EXIT FUNCTION
    r$ = "((" + t$ + "*)(" + n$ + "[0]))[" + a$ + "]"
    refer$ = r$
    EXIT FUNCTION
END IF 'array

'variable?
IF id.t THEN
    r$ = RTRIM$(id.n)
    t = id.t
    'remove irrelavant flags
    IF (t AND ISINCONVENTIONALMEMORY) THEN t = t - ISINCONVENTIONALMEMORY
    'string?
    IF (t AND ISSTRING) THEN
        IF (t AND ISFIXEDLENGTH) THEN
            r$ = scope$ + "STRING" + str2(id.tsize) + "_" + r$: GOTO ref
        END IF
        r$ = scope$ + "STRING_" + r$: GOTO ref
    END IF
    'bit-length single variable?
    IF (t AND ISOFFSETINBITS) THEN
        IF (t AND ISUNSIGNED) THEN
            r$ = "*" + scope$ + "UBIT" + str2(t AND 511) + "_" + r$
        ELSE
            r$ = "*" + scope$ + "BIT" + str2(t AND 511) + "_" + r$
        END IF
        GOTO ref
    END IF
    IF t = BYTETYPE THEN r$ = "*" + scope$ + "BYTE_" + r$: GOTO ref
    IF t = UBYTETYPE THEN r$ = "*" + scope$ + "UBYTE_" + r$: GOTO ref
    IF t = INTEGERTYPE THEN r$ = "*" + scope$ + "INTEGER_" + r$: GOTO ref
    IF t = UINTEGERTYPE THEN r$ = "*" + scope$ + "UINTEGER_" + r$: GOTO ref
    IF t = LONGTYPE THEN r$ = "*" + scope$ + "LONG_" + r$: GOTO ref
    IF t = ULONGTYPE THEN r$ = "*" + scope$ + "ULONG_" + r$: GOTO ref
    IF t = INTEGER64TYPE THEN r$ = "*" + scope$ + "INTEGER64_" + r$: GOTO ref
    IF t = UINTEGER64TYPE THEN r$ = "*" + scope$ + "UINTEGER64_" + r$: GOTO ref
    IF t = SINGLETYPE THEN r$ = "*" + scope$ + "SINGLE_" + r$: GOTO ref
    IF t = DOUBLETYPE THEN r$ = "*" + scope$ + "DOUBLE_" + r$: GOTO ref
    IF t = FLOATTYPE THEN r$ = "*" + scope$ + "FLOAT_" + r$: GOTO ref
    IF t = OFFSETTYPE THEN r$ = "*" + scope$ + "OFFSET_" + r$: GOTO ref
    IF t = UOFFSETTYPE THEN r$ = "*" + scope$ + "UOFFSET_" + r$: GOTO ref
    ref:
    IF (t AND ISSTRING) THEN stringprocessinghappened = 1
    IF (t AND ISPOINTER) THEN t = t - ISPOINTER
    typ = t
    IF method = 1 THEN
        IF LEFT$(r$, 1) = "*" THEN r$ = RIGHT$(r$, LEN(r$) - 1)
        typ = typbak
    END IF
    refer$ = r$
    EXIT FUNCTION
END IF 'variable



END FUNCTION

SUB regid
idn = idn + 1

IF idn > ids_max THEN
    ids_max = ids_max * 2
    REDIM _PRESERVE ids(1 TO ids_max) AS idstruct
    REDIM _PRESERVE cmemlist(1 TO ids_max + 1) AS INTEGER
    REDIM _PRESERVE sfcmemargs(1 TO ids_max + 1) AS STRING * 100
    REDIM _PRESERVE arrayelementslist(1 TO ids_max + 1) AS INTEGER
END IF

n$ = RTRIM$(id.n)

IF reginternalsubfunc = 0 THEN
    IF validname(n$) = 0 THEN Give_Error "Invalid name": EXIT SUB
END IF

'register case sensitive name if none given
IF ASC(id.cn) = 32 THEN
    n$ = RTRIM$(id.n)
    id.n = UCASE$(n$)
    id.cn = n$
END IF

IF LEN(Refactor_Source) THEN
    n$ = RTRIM$(id.n)
    IF UCASE$(n$) = UCASE$(Refactor_Source) THEN
        id.cn = Refactor_Dest
    END IF
END IF


id.insubfunc = subfunc
id.insubfuncn = subfuncn

'note: cannot be STATIC and SHARED at the same time
IF dimshared THEN
    id.share = dimshared
ELSE
    IF dimstatic THEN id.staticscope = 1
END IF

ids(idn) = id

currentid = idn

'prepare hash flags and check for conflicts
hashflags = 1

'sub/function?
'Note: QBASIC does not allow: Internal type names (INTEGER,LONG,...)
IF id.subfunc THEN
    ids(currentid).internal_subfunc = reginternalsubfunc
    IF id.subfunc = 1 THEN hashflags = hashflags + HASHFLAG_FUNCTION ELSE hashflags = hashflags + HASHFLAG_SUB
    IF reginternalsubfunc = 0 THEN 'allow internal definition of subs/functions without checks
        hashchkflags = HASHFLAG_RESERVED + HASHFLAG_CONSTANT
        IF id.subfunc = 1 THEN hashchkflags = hashchkflags + HASHFLAG_FUNCTION ELSE hashchkflags = hashchkflags + HASHFLAG_SUB
        hashres = HashFind(n$, hashchkflags, hashresflags, hashresref)
        DO WHILE hashres
            IF hashres THEN
                'Note: Numeric sub/function names like 'mid' do not clash with Internal string sub/function names
                '      like 'MID$' because MID$ always requires a '$'. For user defined string sub/function names
                '      the '$' would be optional so the rule should not be applied there.
                allow = 0
                IF hashresflags AND (HASHFLAG_FUNCTION + HASHFLAG_SUB) THEN
                    IF RTRIM$(ids(hashresref).musthave) = "$" THEN
                        IF INSTR(ids(currentid).mayhave, "$") = 0 THEN allow = 1
                    END IF
                END IF
                IF allow = 0 THEN Give_Error "Name already in use": EXIT SUB
            END IF 'hashres
            IF hashres <> 1 THEN hashres = HashFindCont(hashresflags, hashresref) ELSE hashres = 0
        LOOP
    END IF 'reginternalsubfunc = 0
END IF

'variable?
IF id.t THEN
    hashflags = hashflags + HASHFLAG_VARIABLE
    IF reginternalvariable = 0 THEN
        allow = 0
        var_recheck:
        IF ASC(id.musthave) = 32 THEN astype2 = 1 '"AS type" declaration?
        scope2 = subfuncn
        hashchkflags = HASHFLAG_RESERVED + HASHFLAG_SUB + HASHFLAG_FUNCTION + HASHFLAG_CONSTANT + HASHFLAG_VARIABLE
        hashres = HashFind(n$, hashchkflags, hashresflags, hashresref)
        DO WHILE hashres

            'conflict with reserved word?
            IF hashresflags AND HASHFLAG_RESERVED THEN
                musthave$ = RTRIM$(id.musthave)
                IF INSTR(musthave$, "$") THEN
                    'All reserved words can be used as variables in QBASIC if "$" is appended to the variable name!
                    '(allow)
                ELSE
                    Give_Error "Name already in use": EXIT SUB 'Conflicts with reserved word
                END IF
            END IF 'HASHFLAG_RESERVED

            'conflict with sub/function?
            IF hashresflags AND (HASHFLAG_FUNCTION + HASHFLAG_SUB) THEN
                IF ids(hashresref).internal_subfunc = 0 THEN Give_Error "Name already in use": EXIT SUB 'QBASIC doesn't allow a variable of the same name as a user-defined sub/func
                IF RTRIM$(id.n) = "WIDTH" AND ids(hashresref).subfunc = 2 THEN GOTO varname_exception
                musthave$ = RTRIM$(id.musthave)
                IF LEN(musthave$) = 0 THEN
                    IF RTRIM$(ids(hashresref).musthave) = "$" THEN
                        'a sub/func requiring "$" can co-exist with implicit numeric variables
                        IF INSTR(id.mayhave, "$") THEN Give_Error "Name already in use": EXIT SUB
                    ELSE
                        Give_Error "Name already in use": EXIT SUB 'Implicitly defined variables cannot conflict with sub/func names
                    END IF
                END IF 'len(musthave$)=0
                IF INSTR(musthave$, "$") THEN
                    IF RTRIM$(ids(hashresref).musthave) = "$" THEN Give_Error "Name already in use": EXIT SUB 'A sub/function name already exists as a string
                    '(allow)
                ELSE
                    IF RTRIM$(ids(hashresref).musthave) <> "$" THEN Give_Error "Name already in use": EXIT SUB 'A non-"$" sub/func name already exists with this name
                END IF
            END IF 'HASHFLAG_FUNCTION + HASHFLAG_SUB

            'conflict with constant?
            IF hashresflags AND HASHFLAG_CONSTANT THEN
                scope1 = constsubfunc(hashresref)
                IF (scope1 = 0 AND AllowLocalName = 0) OR scope1 = scope2 THEN Give_Error "Name already in use": EXIT SUB
            END IF

            'conflict with variable?
            IF hashresflags AND HASHFLAG_VARIABLE THEN
                astype1 = 0: IF ASC(ids(hashresref).musthave) = 32 THEN astype1 = 1
                scope1 = ids(hashresref).insubfuncn
                IF astype1 = 1 AND astype2 = 1 THEN
                    IF scope1 = scope2 THEN Give_Error "Name already in use": EXIT SUB
                END IF
                'same type?
                IF id.t = ids(hashresref).t THEN
                    IF id.tsize = ids(hashresref).tsize THEN
                        IF scope1 = scope2 THEN Give_Error "Name already in use": EXIT SUB
                    END IF
                END IF
                'will astype'd fixed STRING-variable mask a non-fixed string?
                IF id.t AND ISFIXEDLENGTH THEN
                    IF astype2 = 1 THEN
                        IF ids(hashresref).t AND ISSTRING THEN
                            IF (ids(hashresref).t AND ISFIXEDLENGTH) = 0 THEN
                                IF scope1 = scope2 THEN Give_Error "Name already in use": EXIT SUB
                            END IF
                        END IF
                    END IF
                END IF
            END IF

            varname_exception:
            IF hashres <> 1 THEN hashres = HashFindCont(hashresflags, hashresref) ELSE hashres = 0
        LOOP
    END IF 'reginternalvariable
END IF 'variable

'array?
IF id.arraytype THEN
    hashflags = hashflags + HASHFLAG_ARRAY
    allow = 0
    ary_recheck:
    scope2 = subfuncn
    IF ASC(id.musthave) = 32 THEN astype2 = 1 '"AS type" declaration?
    hashchkflags = HASHFLAG_RESERVED + HASHFLAG_SUB + HASHFLAG_FUNCTION + HASHFLAG_ARRAY
    hashres = HashFind(n$, hashchkflags, hashresflags, hashresref)
    DO WHILE hashres

        'conflict with reserved word?
        IF hashresflags AND HASHFLAG_RESERVED THEN
            musthave$ = RTRIM$(id.musthave)
            IF INSTR(musthave$, "$") THEN
                'All reserved words can be used as variables in QBASIC if "$" is appended to the variable name!
                '(allow)
            ELSE
                Give_Error "Name already in use": EXIT SUB 'Conflicts with reserved word
            END IF
        END IF 'HASHFLAG_RESERVED

        'conflict with sub/function?
        IF hashresflags AND (HASHFLAG_FUNCTION + HASHFLAG_SUB) THEN
            IF ids(hashresref).internal_subfunc = 0 THEN Give_Error "Name already in use": EXIT SUB 'QBASIC doesn't allow a variable of the same name as a user-defined sub/func
            IF RTRIM$(id.n) = "WIDTH" AND ids(hashresref).subfunc = 2 THEN GOTO arrayname_exception
            musthave$ = RTRIM$(id.musthave)

            IF LEN(musthave$) = 0 THEN
                IF RTRIM$(ids(hashresref).musthave) = "$" THEN
                    'a sub/func requiring "$" can co-exist with implicit numeric variables
                    IF INSTR(id.mayhave, "$") THEN Give_Error "Name already in use": EXIT SUB
                ELSE
                    Give_Error "Name already in use": EXIT SUB 'Implicitly defined variables cannot conflict with sub/func names
                END IF
            END IF 'len(musthave$)=0
            IF INSTR(musthave$, "$") THEN
                IF RTRIM$(ids(hashresref).musthave) = "$" THEN Give_Error "Name already in use": EXIT SUB 'A sub/function name already exists as a string
                '(allow)
            ELSE
                IF RTRIM$(ids(hashresref).musthave) <> "$" THEN Give_Error "Name already in use": EXIT SUB 'A non-"$" sub/func name already exists with this name
            END IF
        END IF 'HASHFLAG_FUNCTION + HASHFLAG_SUB

        'conflict with array?
        IF hashresflags AND HASHFLAG_ARRAY THEN
            astype1 = 0: IF ASC(ids(hashresref).musthave) = 32 THEN astype1 = 1
            scope1 = ids(hashresref).insubfuncn
            IF astype1 = 1 AND astype2 = 1 THEN
                IF scope1 = scope2 THEN Give_Error "Name already in use": EXIT SUB
            END IF
            'same type?
            IF id.arraytype = ids(hashresref).arraytype THEN
                IF id.tsize = ids(hashresref).tsize THEN
                    IF scope1 = scope2 THEN Give_Error "Name already in use": EXIT SUB
                END IF
            END IF
            'will astype'd fixed STRING-variable mask a non-fixed string?
            IF id.arraytype AND ISFIXEDLENGTH THEN
                IF astype2 = 1 THEN
                    IF ids(hashresref).arraytype AND ISSTRING THEN
                        IF (ids(hashresref).arraytype AND ISFIXEDLENGTH) = 0 THEN
                            IF scope1 = scope2 THEN Give_Error "Name already in use": EXIT SUB
                        END IF
                    END IF
                END IF
            END IF
        END IF

        arrayname_exception:
        IF hashres <> 1 THEN hashres = HashFindCont(hashresflags, hashresref) ELSE hashres = 0
    LOOP
END IF 'array

'add it to the hash table
HashAdd n$, hashflags, currentid

END SUB

SUB reginternal
reginternalsubfunc = 1
'$INCLUDE:'subs_functions\subs_functions.bas'
'$INCLUDE:'subs_functions\extensions\extension_list.bas'
reginternalsubfunc = 0
END SUB

'this sub is faulty atm!
'sub replacelement (a$, i, newe$)
''note: performs no action for out of range values of i
'e=1
's=1
'do
'x=instr(s,a$,sp)
'if x then
'if e=i then
'a1$=left$(a$,s-1): a2$=right$(a$,len(a$)-x+1)
'a$=a1$+sp+newe$+a2$ 'note: a2 includes spacer
'exit sub
'end if
's=x+1
'e=e+1
'end if
'loop until x=0
'if e=i then
'a$=left$(a$,s-1)+sp+newe$
'end if
'end sub


SUB removeelements (a$, first, last, keepindexing)
a2$ = ""
'note: first and last MUST be valid
'      keepindexing means the number of elements will stay the same
'       but some elements will be equal to ""

n = numelements(a$)
FOR i = 1 TO n
    IF i < first OR i > last THEN
        a2$ = a2$ + sp + getelement(a$, i)
    ELSE
        IF keepindexing THEN a2$ = a2$ + sp
    END IF
NEXT
IF LEFT$(a2$, 1) = sp THEN a2$ = RIGHT$(a2$, LEN(a2$) - 1)

a$ = a2$

END SUB



FUNCTION symboltype (s$) 'returns type or 0(not a valid symbol)
'note: sets symboltype_size for fixed length strings
'created: 2011 (fast & comprehensive)
IF LEN(s$) = 0 THEN EXIT FUNCTION
'treat common cases first
a = ASC(s$)
l = LEN(s$)
IF a = 37 THEN '%
    IF l = 1 THEN symboltype = 16: EXIT FUNCTION
    IF l > 2 THEN EXIT FUNCTION
    IF ASC(s$, 2) = 37 THEN symboltype = 8: EXIT FUNCTION
    IF ASC(s$, 2) = 38 THEN symboltype = OFFSETTYPE - ISPOINTER: EXIT FUNCTION '%&
    EXIT FUNCTION
END IF
IF a = 38 THEN '&
    IF l = 1 THEN symboltype = 32: EXIT FUNCTION
    IF l > 2 THEN EXIT FUNCTION
    IF ASC(s$, 2) = 38 THEN symboltype = 64: EXIT FUNCTION
    EXIT FUNCTION
END IF
IF a = 33 THEN '!
    IF l = 1 THEN symboltype = 32 + ISFLOAT: EXIT FUNCTION
    EXIT FUNCTION
END IF
IF a = 35 THEN '#
    IF l = 1 THEN symboltype = 64 + ISFLOAT: EXIT FUNCTION
    IF l > 2 THEN EXIT FUNCTION
    IF ASC(s$, 2) = 35 THEN symboltype = 64 + ISFLOAT: EXIT FUNCTION
    EXIT FUNCTION
END IF
IF a = 36 THEN '$
    IF l = 1 THEN symboltype = ISSTRING: EXIT FUNCTION
    IF isuinteger(RIGHT$(s$, l - 1)) THEN
        IF l >= (1 + 10) THEN
            IF l > (1 + 10) THEN EXIT FUNCTION
            IF s$ > "$2147483647" THEN EXIT FUNCTION
        END IF
        symboltype_size = VAL(RIGHT$(s$, l - 1))
        symboltype = ISSTRING + ISFIXEDLENGTH
        EXIT FUNCTION
    END IF
    EXIT FUNCTION
END IF
IF a = 96 THEN '`
    IF l = 1 THEN symboltype = 1 + ISOFFSETINBITS: EXIT FUNCTION
    IF isuinteger(RIGHT$(s$, l - 1)) THEN
        IF l > 3 THEN EXIT FUNCTION
        n = VAL(RIGHT$(s$, l - 1))
        IF n > 56 THEN EXIT FUNCTION
        symboltype = n + ISOFFSETINBITS: EXIT FUNCTION
    END IF
    EXIT FUNCTION
END IF
IF a = 126 THEN '~
    IF l = 1 THEN EXIT FUNCTION
    a = ASC(s$, 2)
    IF a = 37 THEN '%
        IF l = 2 THEN symboltype = 16 + ISUNSIGNED: EXIT FUNCTION
        IF l > 3 THEN EXIT FUNCTION
        IF ASC(s$, 3) = 37 THEN symboltype = 8 + ISUNSIGNED: EXIT FUNCTION
        IF ASC(s$, 3) = 38 THEN symboltype = UOFFSETTYPE - ISPOINTER: EXIT FUNCTION '~%&
        EXIT FUNCTION
    END IF
    IF a = 38 THEN '&
        IF l = 2 THEN symboltype = 32 + ISUNSIGNED: EXIT FUNCTION
        IF l > 3 THEN EXIT FUNCTION
        IF ASC(s$, 3) = 38 THEN symboltype = 64 + ISUNSIGNED: EXIT FUNCTION
        EXIT FUNCTION
    END IF
    IF a = 96 THEN '`
        IF l = 2 THEN symboltype = 1 + ISOFFSETINBITS + ISUNSIGNED: EXIT FUNCTION
        IF isuinteger(RIGHT$(s$, l - 2)) THEN
            IF l > 4 THEN EXIT FUNCTION
            n = VAL(RIGHT$(s$, l - 2))
            IF n > 56 THEN EXIT FUNCTION
            symboltype = n + ISOFFSETINBITS + ISUNSIGNED: EXIT FUNCTION
        END IF
        EXIT FUNCTION
    END IF
END IF '~
END FUNCTION

FUNCTION removesymbol$ (varname$)
i = INSTR(varname$, "~"): IF i THEN GOTO foundsymbol
i = INSTR(varname$, "`"): IF i THEN GOTO foundsymbol
i = INSTR(varname$, "%"): IF i THEN GOTO foundsymbol
i = INSTR(varname$, "&"): IF i THEN GOTO foundsymbol
i = INSTR(varname$, "!"): IF i THEN GOTO foundsymbol
i = INSTR(varname$, "#"): IF i THEN GOTO foundsymbol
i = INSTR(varname$, "$"): IF i THEN GOTO foundsymbol
EXIT FUNCTION
foundsymbol:
IF i = 1 THEN Give_Error "Expected variable name before symbol": EXIT FUNCTION
symbol$ = RIGHT$(varname$, LEN(varname$) - i + 1)
IF symboltype(symbol$) = 0 THEN Give_Error "Invalid symbol": EXIT FUNCTION
removesymbol$ = symbol$
varname$ = LEFT$(varname$, i - 1)
END FUNCTION

FUNCTION scope$
IF id.share THEN scope$ = module$ + "__": EXIT FUNCTION
scope$ = module$ + "_" + subfunc$ + "_"
END FUNCTION

FUNCTION seperateargs (a$, ca$, pass&)
pass& = 0

FOR i = 1 TO OptMax: separgs(i) = "": NEXT
FOR i = 1 TO OptMax + 1: separgslayout(i) = "": NEXT
FOR i = 1 TO OptMax
    Lev(i) = 0
    EntryLev(i) = 0
    DitchLev(i) = 0
    DontPass(i) = 0
    TempList(i) = 0
    PassRule(i) = 0
    LevelEntered(i) = 0
NEXT

DIM id2 AS idstruct

id2 = id

IF id2.args = 0 THEN EXIT FUNCTION 'no arguments!


s$ = id2.specialformat
s$ = RTRIM$(s$)

'build a special format if none exists
IF s$ = "" THEN
    FOR i = 1 TO id2.args
        IF i <> 1 THEN s$ = s$ + ",?" ELSE s$ = "?"
    NEXT
END IF

'note: dim'd arrays moved to global to prevent high recreation cost

PassFlag = 1
nextentrylevel = 0
nextentrylevelset = 1
level = 0
lastt = 0
ditchlevel = 0
FOR i = 1 TO LEN(s$)
    s2$ = MID$(s$, i, 1)

    IF s2$ = "[" THEN
        level = level + 1
        LevelEntered(level) = 0
        GOTO nextsymbol
    END IF

    IF s2$ = "]" THEN
        level = level - 1
        IF level < ditchlevel THEN ditchlevel = level
        GOTO nextsymbol
    END IF

    IF s2$ = "{" THEN
        lastt = lastt + 1: Lev(lastt) = level: PassRule(lastt) = 0
        DitchLev(lastt) = ditchlevel: ditchlevel = level 'store & reset ditch level
        i = i + 1
        i2 = INSTR(i, s$, "}")
        numopts = 0
        nextopt:
        numopts = numopts + 1
        i3 = INSTR(i + 1, s$, "|")
        IF i3 <> 0 AND i3 < i2 THEN
            Opt(lastt, numopts) = MID$(s$, i, i3 - i)
            i = i3 + 1: GOTO nextopt
        END IF
        Opt(lastt, numopts) = MID$(s$, i, i2 - i)
        T(lastt) = numopts
        'calculate words in each option
        FOR x = 1 TO T(lastt)
            w = 1
            x2 = 1
            newword:
            IF INSTR(x2, RTRIM$(Opt(lastt, x)), " ") THEN w = w + 1: x2 = INSTR(x2, RTRIM$(Opt(lastt, x)), " ") + 1: GOTO newword
            OptWords(lastt, x) = w
        NEXT
        i = i2

        'set entry level routine
        EntryLev(lastt) = level 'default level when continuing a previously entered level
        IF LevelEntered(level) = 0 THEN
            EntryLev(lastt) = 0
            FOR i2 = 1 TO level - 1
                IF LevelEntered(i2) = 1 THEN EntryLev(lastt) = i2
            NEXT
        END IF
        LevelEntered(level) = 1

        GOTO nextsymbol
    END IF

    IF s2$ = "?" THEN
        lastt = lastt + 1: Lev(lastt) = level: PassRule(lastt) = 0
        DitchLev(lastt) = ditchlevel: ditchlevel = level 'store & reset ditch level
        T(lastt) = 0
        'set entry level routine
        EntryLev(lastt) = level 'default level when continuing a previously entered level
        IF LevelEntered(level) = 0 THEN
            EntryLev(lastt) = 0
            FOR i2 = 1 TO level - 1
                IF LevelEntered(i2) = 1 THEN EntryLev(lastt) = i2
            NEXT
        END IF
        LevelEntered(level) = 1

        GOTO nextsymbol
    END IF

    'assume "special" character (like ( ) , . - etc.)
    lastt = lastt + 1: Lev(lastt) = level: PassRule(lastt) = 0
    DitchLev(lastt) = ditchlevel: ditchlevel = level 'store & reset ditch level
    T(lastt) = 1: Opt(lastt, 1) = s2$: OptWords(lastt, 1) = 1: DontPass(lastt) = 1

    'set entry level routine
    EntryLev(lastt) = level 'default level when continuing a previously entered level
    IF LevelEntered(level) = 0 THEN
        EntryLev(lastt) = 0
        FOR i2 = 1 TO level - 1
            IF LevelEntered(i2) = 1 THEN EntryLev(lastt) = i2
        NEXT
    END IF
    LevelEntered(level) = 1

    GOTO nextsymbol

    nextsymbol:
NEXT


IF Debug THEN
    PRINT #9, "--------SEPERATE ARGUMENTS REPORT #1:1--------"
    FOR i = 1 TO lastt
        PRINT #9, i, "OPT=" + CHR$(34) + RTRIM$(Opt(i, 1)) + CHR$(34)
        PRINT #9, i, "OPTWORDS="; OptWords(i, 1)
        PRINT #9, i, "T="; T(i)
        PRINT #9, i, "DONTPASS="; DontPass(i)
        PRINT #9, i, "PASSRULE="; PassRule(i)
        PRINT #9, i, "LEV="; Lev(i)
        PRINT #9, i, "ENTRYLEV="; EntryLev(i)
    NEXT
END IF


'Any symbols already have dontpass() set to 1
'This sets any {}blocks with only one option/word (eg. {PRINT}) at the lowest level to dontpass()=1
'because their content is manadatory and there is no choice as to which word to use
FOR x = 1 TO lastt
    IF Lev(x) = 0 THEN
        IF T(x) = 1 THEN DontPass(x) = 1
    END IF
NEXT

IF Debug THEN
    PRINT #9, "--------SEPERATE ARGUMENTS REPORT #1:2--------"
    FOR i = 1 TO lastt
        PRINT #9, i, "OPT=" + CHR$(34) + RTRIM$(Opt(i, 1)) + CHR$(34)
        PRINT #9, i, "OPTWORDS="; OptWords(i, 1)
        PRINT #9, i, "T="; T(i)
        PRINT #9, i, "DONTPASS="; DontPass(i)
        PRINT #9, i, "PASSRULE="; PassRule(i)
        PRINT #9, i, "LEV="; Lev(i)
        PRINT #9, i, "ENTRYLEV="; EntryLev(i)
    NEXT
END IF




x1 = 0 'the 'x' position of the beginning element of the current levelled block
MustPassOpt = 0 'the 'x' position of the FIRST opt () in the block which must be passed
MustPassOptNeedsFlag = 0 '{}blocks don't need a flag, ? blocks do

'Note: For something like [{HELLO}x] a choice between passing 'hello' or passing a flag to signify x was specified
'      has to be made, in such cases, a flag is preferable to wasting a full new int32 on 'hello'

templistn = 0
FOR l = 1 TO 32767
    scannextlevel = 0
    FOR x = 1 TO lastt
        IF Lev(x) > l THEN scannextlevel = 1

        IF x1 THEN
            IF EntryLev(x) < l THEN 'end of block reached
                IF MustPassOpt THEN
                    'If there's an opt () which must be passed that will be identified,
                    'all the 1 option {}blocks can be assumed...
                    IF MustPassOptNeedsFlag THEN
                        'The MustPassOpt requires a flag, so use the same flag for everything
                        FOR x2 = 1 TO templistn
                            PassRule(TempList(x2)) = PassFlag
                        NEXT
                        PassFlag = PassFlag * 2
                    ELSE
                        'The MustPassOpt is a {}block which doesn't need a flag, so everything else needs to
                        'reference it
                        FOR x2 = 1 TO templistn
                            IF TempList(x2) <> MustPassOpt THEN PassRule(TempList(x2)) = -MustPassOpt
                        NEXT
                    END IF
                ELSE
                    'if not, use a unique flag for everything in this block
                    FOR x2 = 1 TO templistn: PassRule(TempList(x2)) = PassFlag: NEXT
                    IF templistn <> 0 THEN PassFlag = PassFlag * 2
                END IF
                x1 = 0
            END IF
        END IF


        IF Lev(x) = l THEN 'on same level
            IF EntryLev(x) < l THEN 'just (re)entered this level (not continuing along it)
                x1 = x 'set x1 to the starting element of this level
                MustPassOpt = 0
                templistn = 0
            END IF
        END IF

        IF x1 THEN
            IF Lev(x) = l THEN 'same level

                IF T(x) <> 1 THEN
                    'It isn't a symbol or a {}block with only one option therefore this opt () must be passed
                    IF MustPassOpt = 0 THEN
                        MustPassOpt = x 'Only record the first instance (it MAY require a flag)
                        IF T(x) = 0 THEN MustPassOptNeedsFlag = 1 ELSE MustPassOptNeedsFlag = 0
                    ELSE
                        'Update current MustPassOpt to non-flag-based {}block if possible (to save flag usage)
                        '(Consider [{A|B}?], where a flag is not required)
                        IF MustPassOptNeedsFlag = 1 THEN
                            IF T(x) > 1 THEN
                                MustPassOpt = x: MustPassOptNeedsFlag = 0
                            END IF
                        END IF
                    END IF
                    'add to list
                    templistn = templistn + 1: TempList(templistn) = x
                END IF

                IF T(x) = 1 THEN
                    'It is a symbol or a {}block with only one option
                    'a {}block with only one option MAY not need to be passed
                    'depending on if anything else is in this block could make the existance of this opt () assumed
                    'Note: Symbols which are not encapsulated inside a {}block never need to be passed
                    '      Symbols already have dontpass() set to 1
                    IF DontPass(x) = 0 THEN templistn = templistn + 1: TempList(templistn) = x: DontPass(x) = 1
                END IF

            END IF
        END IF

    NEXT

    'scan last run (mostly just a copy of code from above)
    IF x1 THEN
        IF MustPassOpt THEN
            'If there's an opt () which must be passed that will be identified,
            'all the 1 option {}blocks can be assumed...
            IF MustPassOptNeedsFlag THEN
                'The MustPassOpt requires a flag, so use the same flag for everything
                FOR x2 = 1 TO templistn
                    PassRule(TempList(x2)) = PassFlag
                NEXT
                PassFlag = PassFlag * 2
            ELSE
                'The MustPassOpt is a {}block which doesn't need a flag, so everything else needs to
                'reference it
                FOR x2 = 1 TO templistn
                    IF TempList(x2) <> MustPassOpt THEN PassRule(TempList(x2)) = -MustPassOpt
                NEXT
            END IF
        ELSE
            'if not, use a unique flag for everything in this block
            FOR x2 = 1 TO templistn: PassRule(TempList(x2)) = PassFlag: NEXT
            IF templistn <> 0 THEN PassFlag = PassFlag * 2
        END IF
        x1 = 0
    END IF

    IF scannextlevel = 0 THEN EXIT FOR
NEXT

IF Debug THEN
    PRINT #9, "--------SEPERATE ARGUMENTS REPORT #1:3--------"
    FOR i = 1 TO lastt
        PRINT #9, i, "OPT=" + CHR$(34) + RTRIM$(Opt(i, 1)) + CHR$(34)
        PRINT #9, i, "OPTWORDS="; OptWords(i, 1)
        PRINT #9, i, "T="; T(i)
        PRINT #9, i, "DONTPASS="; DontPass(i)
        PRINT #9, i, "PASSRULE="; PassRule(i)
        PRINT #9, i, "LEV="; Lev(i)
        PRINT #9, i, "ENTRYLEV="; EntryLev(i)
    NEXT
END IF



FOR i = 1 TO lastt: separgs(i) = "null": NEXT




'Consider: "?,[?]"
'Notes: The comma is mandatory but the second ? is entirely optional
'Consider: "[?[{B}?]{A}]?"
'Notes: As unlikely as the above is, it is still valid, but pivots on the outcome of {A} being present
'Consider: "[?]{A}"
'Consider: "[?{A}][?{B}][?{C}]?"
'Notes: The trick here is to realize {A} has greater priority than {B}, so all lines of enquiry must
'       be exhausted before considering {B}

'Use inquiry approach to solve format
'Each line of inquiry must be exhausted
'An expression ("?") simply means a branch where you can scan ahead

Branches = 0
DIM BranchFormatPos(1 TO 100) AS LONG
DIM BranchTaken(1 TO 100) AS LONG
'1=taken (this usually involves moving up a level)
'0=not taken
DIM BranchInputPos(1 TO 100) AS LONG
DIM BranchWithExpression(1 TO 100) AS LONG
'non-zero=expression expected before next item for format item value represents
'0=no expression allowed before next item
DIM BranchLevel(1 TO 100) AS LONG 'Level before this branch was/wasn't taken

n = numelements(ca$)
i = 1 'Position within ca$

level = 0
Expression = 0
FOR x = 1 TO lastt

    ContinueScan:

    IF DitchLev(x) < level THEN 'dropping down to a lower level
        'we can only go as low as the 'ditch' will allow us, which will limit our options
        level = DitchLev(x)
    END IF

    IF EntryLev(x) <= level THEN 'possible to enter level

        'But was this optional or were we forced to be on this level?
        IF EntryLev(x) < Lev(x) THEN
            optional = 1
            IF level > EntryLev(x) THEN optional = 0
        ELSE
            'entrylev=lev
            optional = 0
        END IF

        t = T(x)

        IF t = 0 THEN 'A "?" expression
            IF Expression THEN
                '*********backtrack************
                'We are tracking an expression which we assumed would be present but was not
                GOTO Backtrack
                '******************************
            END IF
            IF optional THEN
                Branches = Branches + 1
                BranchFormatPos(Branches) = x
                BranchTaken(Branches) = 1
                BranchInputPos(Branches) = i
                BranchWithExpression(Branches) = 0
                BranchLevel(Branches) = level
                level = Lev(x)
            END IF
            Expression = x
        END IF 'A "?" expression

        IF t THEN

            currentlev = level

            'Add new branch if new level will be entered
            IF optional THEN
                Branches = Branches + 1
                BranchFormatPos(Branches) = x
                BranchTaken(Branches) = 1
                BranchInputPos(Branches) = i
                BranchWithExpression(Branches) = Expression
                BranchLevel(Branches) = level
            END IF

            'Scan for Opt () options
            i1 = i: i2 = i
            IF Expression THEN i2 = n
            'Scan a$ for opt () x
            'Note: Finding the closest opt option is necessary
            'Note: This needs to be bracket sensitive
            OutOfRange = 2147483647
            position = OutOfRange
            which = 0
            IF i <= n THEN 'Past end of contect check
                FOR o = 1 TO t
                    words = OptWords(x, o)
                    b = 0
                    FOR i3 = i1 TO i2
                        IF i3 + words - 1 <= n THEN 'enough elements exist
                            c$ = getelement$(a$, i3)
                            IF b = 0 THEN
                                'Build comparison string (spacing elements)
                                FOR w = 2 TO words
                                    c$ = c$ + " " + getelement$(a$, i3 + w - 1)
                                NEXT w
                                'Compare
                                IF c$ = RTRIM$(Opt(x, o)) THEN
                                    'Record Match
                                    IF i3 < position THEN
                                        position = i3
                                        which = o
                                        bvalue = b
                                        EXIT FOR 'Exit the i3 loop
                                    END IF 'position check
                                END IF 'match
                            END IF

                            IF ASC(c$) = 44 AND b = 0 THEN
                                EXIT FOR 'Expressions cannot contain a "," in their base level
                                'Because this wasn't interceppted by the above code it isn't the Opt either
                            END IF
                            IF ASC(c$) = 40 THEN
                                b = b + 1
                            END IF
                            IF ASC(c$) = 41 THEN
                                b = b - 1
                                IF b = -1 THEN EXIT FOR 'Exited current bracketting level, making any following match invalid
                            END IF

                        END IF 'enough elements exist
                    NEXT i3
                NEXT o
            END IF 'Past end of contect check

            IF position <> OutOfRange THEN 'Found?
                'Found...
                level = Lev(x) 'Adjust level
                IF Expression THEN
                    'Found...Expression...
                    'Has an expression been provided?
                    IF position > i AND bvalue = 0 THEN
                        'Found...Expression...Provided...
                        separgs(Expression) = getelements$(ca$, i, position - 1)
                        Expression = 0
                        i = position
                    ELSE
                        'Found...Expression...Omitted...
                        '*********backtrack************
                        GOTO OptCheckBacktrack
                        '******************************
                    END IF
                END IF 'Expression
                i = i + OptWords(x, which)
                separgslayout(x) = CHR$(LEN(RTRIM$(Opt(x, which)))) + RTRIM$(Opt(x, which))
                separgs(x) = CHR$(0) + str2(which)
            ELSE
                'Not Found...
                '*********backtrack************
                OptCheckBacktrack:
                'Was this optional?
                IF Lev(x) > EntryLev(x) THEN 'Optional Opt ()?
                    'Not Found...Optional...
                    'Simply don't enter the optional higher level and continue as normal
                    BranchTaken(Branches) = 0
                    level = currentlev 'We aren't entering the level after all, so our level should remain at the opt's entrylevel
                ELSE
                    Backtrack:
                    'Not Found...Mandatory...
                    '1)Erase previous branches where both options have been tried
                    FOR branch = Branches TO 1 STEP -1 'Remove branches until last taken branch is found
                        IF BranchTaken(branch) THEN EXIT FOR
                        Branches = Branches - 1 'Remove branch (it has already been tried with both possible combinations)
                    NEXT
                    IF Branches = 0 THEN 'All options have been exhausted
                        seperateargs_error = 1
                        seperateargs_error_message = "Syntax error"
                        EXIT FUNCTION
                    END IF
                    '2)Toggle taken branch to untaken and revert
                    BranchTaken(Branches) = 0 'toggle branch to untaken
                    Expression = BranchWithExpression(Branches)
                    i = BranchInputPos(Branches)
                    x = BranchFormatPos(Branches)
                    level = BranchLevel(Branches)
                    '3)Erase any content created after revert position
                    IF Expression THEN separgs(Expression) = "null"
                    FOR x2 = x TO lastt
                        separgs(x2) = "null"
                        separgslayout(x2) = ""
                    NEXT
                END IF 'Optional Opt ()?
                '******************************

            END IF 'Found?

        END IF 't

    END IF 'possible to enter level

NEXT x

'Final expression?
IF Expression THEN
    IF i <= n THEN
        separgs(Expression) = getelements$(ca$, i, n)

        'can this be an expression?
        'check it passes bracketting and comma rules
        b = 0
        FOR i2 = i TO n
            c$ = getelement$(a$, i2)
            IF ASC(c$) = 44 AND b = 0 THEN
                GOTO Backtrack
            END IF
            IF ASC(c$) = 40 THEN
                b = b + 1
            END IF
            IF ASC(c$) = 41 THEN
                b = b - 1
                IF b = -1 THEN GOTO Backtrack
            END IF
        NEXT
        IF b <> 0 THEN GOTO Backtrack

        i = n + 1 'So it passes the test below
    ELSE
        GOTO Backtrack
    END IF
END IF 'Expression

IF i <> n + 1 THEN GOTO Backtrack 'Trailing content?

IF Debug THEN
    PRINT #9, "--------SEPERATE ARGUMENTS REPORT #2--------"
    FOR i = 1 TO lastt
        PRINT #9, i, separgs(i)
    NEXT
END IF

'   DIM PassRule(1 TO 100) AS LONG
'   '0 means no pass rule
'   'negative values refer to an opt () element
'   'positive values refer to a flag value
'   PassFlag = 1


IF PassFlag <> 1 THEN seperateargs = 1 'Return whether a 'passed' flags variable is required
pass& = 0 'The 'passed' value (shared by argument reference)

'Note: The separgs() elements will be compacted to the C++ function arguments
x = 1 'The new index to move compacted content to within separgs()

FOR i = 1 TO lastt

    IF DontPass(i) = 0 THEN

        IF PassRule(i) > 0 THEN
            IF separgs(i) <> "null" THEN pass& = pass& OR PassRule(i) 'build 'passed' flags
        END IF

        separgs(x) = separgs(i)
        separgslayout(x) = separgslayout(i)

        IF LEN(separgs(x)) THEN
            IF ASC(separgs(x)) = 0 THEN
                'switch omit layout tag from item to layout info
                separgs(x) = RIGHT$(separgs(x), LEN(separgs(x)) - 1)
                separgslayout(x) = separgslayout(x) + CHR$(0)
            END IF
        END IF

        IF separgs(x) = "null" THEN separgs(x) = "NULL"
        x = x + 1

    ELSE
        'its gonna be skipped!
        'add layout to the next one to be safe

        'for syntax such as [{HELLO}] which uses a flag instead of being passed
        IF PassRule(i) > 0 THEN
            IF separgs(i) <> "null" THEN pass& = pass& OR PassRule(i) 'build 'passed' flags
        END IF

        separgslayout(i + 1) = separgslayout(i) + separgslayout(i + 1)

    END IF
NEXT
separgslayout(x) = separgslayout(i) 'set final layout

'x = x - 1
'PRINT "total arguments:"; x
'PRINT "pass omit (0/1):"; omit
'PRINT "pass&="; pass&

END FUNCTION

SUB setrefer (a2$, typ2 AS LONG, e2$, method AS LONG)
a$ = a2$: typ = typ2: e$ = e2$
IF method <> 1 THEN e$ = fixoperationorder$(e$)
IF Error_Happened THEN EXIT SUB
tl$ = tlayout$

'method: 0 evaulatetotyp e$
'        1 skip evaluation of e$ and use as is
'*due to the complexity of setting a reference with a value/string
' this function handles the problem

'retrieve ID
i = INSTR(a$, sp3)
IF i THEN
    idnumber = VAL(LEFT$(a$, i - 1)): a$ = RIGHT$(a$, LEN(a$) - i)
ELSE
    idnumber = VAL(a$)
END IF
getid idnumber
IF Error_Happened THEN EXIT SUB


'UDT?
IF typ AND ISUDT THEN

    'print "setrefer-ing a UDT!"
    u = VAL(a$)
    i = INSTR(a$, sp3): a$ = RIGHT$(a$, LEN(a$) - i): E = VAL(a$)
    i = INSTR(a$, sp3): o$ = RIGHT$(a$, LEN(a$) - i)
    n$ = "UDT_" + RTRIM$(id.n): IF id.t = 0 THEN n$ = "ARRAY_" + n$ + "[0]"

    IF Cloud = 0 THEN
        IF E <> 0 AND u = 1 THEN 'Setting _MEM type elements is not allowed!
            Give_Error "Cannot set read-only element of _MEM TYPE": EXIT SUB
        END IF
    END IF

    IF E = 0 THEN
        'use u and u's size

        IF method <> 0 THEN Give_Error "Unexpected internal code reference to UDT": EXIT SUB
        lhsscope$ = scope$
        e$ = evaluate(e$, t2)
        IF Error_Happened THEN EXIT SUB
        IF (t2 AND ISUDT) = 0 THEN Give_Error "Expected = similar user defined type": EXIT SUB

        IF (t2 AND ISREFERENCE) = 0 THEN
            IF t2 AND ISPOINTER THEN
                src$ = "((char*)" + e$ + ")"
                e2 = 0: u2 = t2 AND 511
            ELSE
                src$ = "((char*)&" + e$ + ")"
                e2 = 0: u2 = t2 AND 511
            END IF
            GOTO directudt
        END IF

        '****problem****
        idnumber2 = VAL(e$)
        getid idnumber2


        IF Error_Happened THEN EXIT SUB
        n2$ = "UDT_" + RTRIM$(id.n): IF id.t = 0 THEN n2$ = "ARRAY_" + n2$ + "[0]"
        i = INSTR(e$, sp3): e$ = RIGHT$(e$, LEN(e$) - i): u2 = VAL(e$)
        i = INSTR(e$, sp3): e$ = RIGHT$(e$, LEN(e$) - i): e2 = VAL(e$)
        i = INSTR(e$, sp3): o2$ = RIGHT$(e$, LEN(e$) - i)
        'WARNING: u2 may need minor modifications based on e to see if they are the same

        'we have now established we have 2 pointers to similar data types!
        'ASSUME BYTE TYPE!!!
        src$ = "(((char*)" + scope$ + n2$ + ")+(" + o2$ + "))"
        directudt:
        IF u <> u2 OR e2 <> 0 THEN Give_Error "Expected = similar user defined type": EXIT SUB

        dst$ = "(((char*)" + lhsscope$ + n$ + ")+(" + o$ + "))"
        siz$ = str2$(udtxsize(u) \ 8)

        PRINT #12, "memcpy(" + dst$ + "," + src$ + "," + siz$ + ");"

        'print "setFULLUDTrefer!"

        tlayout$ = tl$
        EXIT SUB

    END IF 'e=0

    IF typ AND ISOFFSETINBITS THEN Give_Error "Cannot resolve bit-length variables inside user defined types yet": EXIT SUB
    IF typ AND ISSTRING THEN
        o2$ = "(((uint8*)" + scope$ + n$ + ")+(" + o$ + "))"
        r$ = "qbs_new_fixed(" + o2$ + "," + str2(udtetypesize(E)) + ",1)"
        IF method = 0 THEN e$ = evaluatetotyp(e$, STRINGTYPE - ISPOINTER)
        IF Error_Happened THEN EXIT SUB
        PRINT #12, "qbs_set(" + r$ + "," + e$ + ");"
    ELSE
        typ = typ - ISUDT - ISREFERENCE - ISPOINTER
        IF typ AND ISARRAY THEN typ = typ - ISARRAY
        t$ = typ2ctyp$(typ, "")
        IF Error_Happened THEN EXIT SUB
        o2$ = "(((char*)" + scope$ + n$ + ")+(" + o$ + "))"
        r$ = "*" + "(" + t$ + "*)" + o2$
        IF method = 0 THEN e$ = evaluatetotyp(e$, typ)
        IF Error_Happened THEN EXIT SUB
        PRINT #12, r$ + "=" + e$ + ";"
    END IF

    'print "setUDTrefer:"+r$,e$
    tlayout$ = tl$
    EXIT SUB
END IF


'array?
IF id.arraytype THEN
    n$ = RTRIM$(id.callname)
    typ = typ - ISPOINTER - ISREFERENCE 'typ now looks like a regular value

    IF (typ AND ISSTRING) THEN
        IF (typ AND ISFIXEDLENGTH) THEN
            offset$ = "&((uint8*)(" + n$ + "[0]))[tmp_long*" + str2(id.tsize) + "]"
            r$ = "qbs_new_fixed(" + offset$ + "," + str2(id.tsize) + ",1)"
            PRINT #12, "tmp_long=" + a$ + ";"
            IF method = 0 THEN
                l$ = "if (!new_error) qbs_set(" + r$ + "," + evaluatetotyp(e$, typ) + ");"
                IF Error_Happened THEN EXIT SUB
            ELSE
                l$ = "if (!new_error) qbs_set(" + r$ + "," + e$ + ");"
            END IF
            PRINT #12, l$
        ELSE
            PRINT #12, "tmp_long=" + a$ + ";"
            IF method = 0 THEN
                l$ = "if (!new_error) qbs_set( ((qbs*)(((uint64*)(" + n$ + "[0]))[tmp_long]))," + evaluatetotyp(e$, typ) + ");"
                IF Error_Happened THEN EXIT SUB
            ELSE
                l$ = "if (!new_error) qbs_set( ((qbs*)(((uint64*)(" + n$ + "[0]))[tmp_long]))," + e$ + ");"
            END IF
            PRINT #12, l$
        END IF
        stringprocessinghappened = 1
        tlayout$ = tl$
        EXIT SUB
    END IF

    IF (typ AND ISOFFSETINBITS) THEN
        'r$ = "setbits_" + str2(typ AND 511) + "("
        r$ = "setbits(" + str2(typ AND 511) + ","
        r$ = r$ + "(uint8*)(" + n$ + "[0])" + ",tmp_long,"
        PRINT #12, "tmp_long=" + a$ + ";"
        IF method = 0 THEN
            l$ = "if (!new_error) " + r$ + evaluatetotyp(e$, typ) + ");"
            IF Error_Happened THEN EXIT SUB
        ELSE
            l$ = "if (!new_error) " + r$ + e$ + ");"
        END IF
        PRINT #12, l$
        tlayout$ = tl$
        EXIT SUB
    ELSE
        t$ = ""
        IF (typ AND ISFLOAT) THEN
            IF (typ AND 511) = 32 THEN t$ = "float"
            IF (typ AND 511) = 64 THEN t$ = "double"
            IF (typ AND 511) = 256 THEN t$ = "long double"
        ELSE
            IF (typ AND ISUNSIGNED) THEN
                IF (typ AND 511) = 8 THEN t$ = "uint8"
                IF (typ AND 511) = 16 THEN t$ = "uint16"
                IF (typ AND 511) = 32 THEN t$ = "uint32"
                IF (typ AND 511) = 64 THEN t$ = "uint64"
                IF typ AND ISOFFSET THEN t$ = "uptrszint"
            ELSE
                IF (typ AND 511) = 8 THEN t$ = "int8"
                IF (typ AND 511) = 16 THEN t$ = "int16"
                IF (typ AND 511) = 32 THEN t$ = "int32"
                IF (typ AND 511) = 64 THEN t$ = "int64"
                IF typ AND ISOFFSET THEN t$ = "ptrszint"
            END IF
        END IF
    END IF
    IF t$ = "" THEN Give_Error "Cannot find C type to return array data": EXIT SUB
    PRINT #12, "tmp_long=" + a$ + ";"
    IF method = 0 THEN
        l$ = "if (!new_error) ((" + t$ + "*)(" + n$ + "[0]))[tmp_long]=" + evaluatetotyp(e$, typ) + ";"
        IF Error_Happened THEN EXIT SUB
    ELSE
        l$ = "if (!new_error) ((" + t$ + "*)(" + n$ + "[0]))[tmp_long]=" + e$ + ";"
    END IF

    PRINT #12, l$
    tlayout$ = tl$
    EXIT SUB
END IF 'array

'variable?
IF id.t THEN
    r$ = RTRIM$(id.n)
    t = id.t
    'remove irrelavant flags
    IF (t AND ISINCONVENTIONALMEMORY) THEN t = t - ISINCONVENTIONALMEMORY
    typ = t

    'string variable?
    IF (t AND ISSTRING) THEN
        IF (t AND ISFIXEDLENGTH) THEN
            r$ = scope$ + "STRING" + str2(id.tsize) + "_" + r$
        ELSE
            r$ = scope$ + "STRING_" + r$
        END IF
        IF method = 0 THEN e$ = evaluatetotyp(e$, ISSTRING)
        IF Error_Happened THEN EXIT SUB
        PRINT #12, "qbs_set(" + r$ + "," + e$ + ");"
        PRINT #12, cleanupstringprocessingcall$ + "0);"
        IF arrayprocessinghappened THEN arrayprocessinghappened = 0
        tlayout$ = tl$
        EXIT SUB
    END IF

    'bit-length variable?
    IF (t AND ISOFFSETINBITS) THEN
        b = t AND 511
        IF (t AND ISUNSIGNED) THEN
            r$ = "*" + scope$ + "UBIT" + str2(t AND 511) + "_" + r$
            IF method = 0 THEN e$ = evaluatetotyp(e$, 64& + ISUNSIGNED)
            IF Error_Happened THEN EXIT SUB
            l$ = r$ + "=(" + e$ + ")&" + str2(bitmask(b)) + ";"
            PRINT #12, l$
        ELSE
            r$ = "*" + scope$ + "BIT" + str2(t AND 511) + "_" + r$
            IF method = 0 THEN e$ = evaluatetotyp(e$, 64&)
            IF Error_Happened THEN EXIT SUB
            l$ = "if ((" + r$ + "=" + e$ + ")&" + str2(2 ^ (b - 1)) + "){"
            PRINT #12, l$
            'signed bit is set
            l$ = r$ + "|=" + str2(bitmaskinv(b)) + ";"
            PRINT #12, l$
            PRINT #12, "}else{"
            'signed bit is not set
            l$ = r$ + "&=" + str2(bitmask(b)) + ";"
            PRINT #12, l$
            PRINT #12, "}"
        END IF
        IF stringprocessinghappened THEN PRINT #12, cleanupstringprocessingcall$ + "0);": stringprocessinghappened = 0
        IF arrayprocessinghappened THEN arrayprocessinghappened = 0
        tlayout$ = tl$
        EXIT SUB
    END IF

    'standard variable?
    IF t = BYTETYPE THEN r$ = "*" + scope$ + "BYTE_" + r$: GOTO sref
    IF t = UBYTETYPE THEN r$ = "*" + scope$ + "UBYTE_" + r$: GOTO sref
    IF t = INTEGERTYPE THEN r$ = "*" + scope$ + "INTEGER_" + r$: GOTO sref
    IF t = UINTEGERTYPE THEN r$ = "*" + scope$ + "UINTEGER_" + r$: GOTO sref
    IF t = LONGTYPE THEN r$ = "*" + scope$ + "LONG_" + r$: GOTO sref
    IF t = ULONGTYPE THEN r$ = "*" + scope$ + "ULONG_" + r$: GOTO sref
    IF t = INTEGER64TYPE THEN r$ = "*" + scope$ + "INTEGER64_" + r$: GOTO sref
    IF t = UINTEGER64TYPE THEN r$ = "*" + scope$ + "UINTEGER64_" + r$: GOTO sref
    IF t = SINGLETYPE THEN r$ = "*" + scope$ + "SINGLE_" + r$: GOTO sref
    IF t = DOUBLETYPE THEN r$ = "*" + scope$ + "DOUBLE_" + r$: GOTO sref
    IF t = FLOATTYPE THEN r$ = "*" + scope$ + "FLOAT_" + r$: GOTO sref
    IF t = OFFSETTYPE THEN r$ = "*" + scope$ + "OFFSET_" + r$: GOTO sref
    IF t = UOFFSETTYPE THEN r$ = "*" + scope$ + "UOFFSET_" + r$: GOTO sref
    sref:
    t2 = t - ISPOINTER
    IF method = 0 THEN e$ = evaluatetotyp(e$, t2)
    IF Error_Happened THEN EXIT SUB
    l$ = r$ + "=" + e$ + ";"
    PRINT #12, l$
    IF stringprocessinghappened THEN PRINT #12, cleanupstringprocessingcall$ + "0);": stringprocessinghappened = 0
    IF arrayprocessinghappened THEN arrayprocessinghappened = 0
    tlayout$ = tl$
    EXIT SUB
END IF 'variable

tlayout$ = tl$
END SUB

FUNCTION str2$ (v AS LONG)
str2$ = LTRIM$(RTRIM$(STR$(v)))
END FUNCTION

FUNCTION str2u64$ (v~&&)
str2u64$ = LTRIM$(RTRIM$(STR$(v~&&)))
END FUNCTION

FUNCTION str2i64$ (v&&)
str2i64$ = LTRIM$(RTRIM$(STR$(v&&)))
END FUNCTION

FUNCTION typ2ctyp$ (t AS LONG, tstr AS STRING)
ctyp$ = ""
'typ can be passed as either: (the unused value is ignored)
'i. as a typ value in t
'ii. as a typ symbol (eg. "~%") in tstr
'iii. as a typ name (eg. _UNSIGNED INTEGER) in tstr
IF tstr$ = "" THEN
    IF (t AND ISARRAY) THEN EXIT FUNCTION 'cannot return array types
    IF (t AND ISSTRING) THEN typ2ctyp$ = "qbs": EXIT FUNCTION
    b = t AND 511
    IF (t AND ISUDT) THEN typ2ctyp$ = "void": EXIT FUNCTION
    IF (t AND ISOFFSETINBITS) THEN
        IF b <= 32 THEN ctyp$ = "int32" ELSE ctyp$ = "int64"
        IF (t AND ISUNSIGNED) THEN ctyp$ = "u" + ctyp$
        typ2ctyp$ = ctyp$: EXIT FUNCTION
    END IF
    IF (t AND ISFLOAT) THEN
        IF b = 32 THEN ctyp$ = "float"
        IF b = 64 THEN ctyp$ = "double"
        IF b = 256 THEN ctyp$ = "long double"
    ELSE
        IF b = 8 THEN ctyp$ = "int8"
        IF b = 16 THEN ctyp$ = "int16"
        IF b = 32 THEN ctyp$ = "int32"
        IF b = 64 THEN ctyp$ = "int64"
        IF typ AND ISOFFSET THEN ctyp$ = "ptrszint"
        IF (t AND ISUNSIGNED) THEN ctyp$ = "u" + ctyp$
    END IF
    IF t AND ISOFFSET THEN
        ctyp$ = "ptrszint": IF (t AND ISUNSIGNED) THEN ctyp$ = "uptrszint"
    END IF
    typ2ctyp$ = ctyp$: EXIT FUNCTION
END IF

ts$ = tstr$
'is ts$ a symbol?
IF ts$ = "$" THEN ctyp$ = "qbs"
IF ts$ = "!" THEN ctyp$ = "float"
IF ts$ = "#" THEN ctyp$ = "double"
IF ts$ = "##" THEN ctyp$ = "long double"
IF LEFT$(ts$, 1) = "~" THEN unsgn = 1: ts$ = RIGHT$(ts$, LEN(ts$) - 1)
IF LEFT$(ts$, 1) = "`" THEN
    n$ = RIGHT$(ts$, LEN(ts$) - 1)
    b = 1
    IF n$ <> "" THEN
        IF isuinteger(n$) = 0 THEN Give_Error "Invalid index after _BIT type": EXIT FUNCTION
        b = VAL(n$)
        IF b > 57 THEN Give_Error "Invalid index after _BIT type": EXIT FUNCTION
    END IF
    IF b <= 32 THEN ctyp$ = "int32" ELSE ctyp$ = "int64"
    IF unsgn THEN ctyp$ = "u" + ctyp$
    typ2ctyp$ = ctyp$: EXIT FUNCTION
END IF
IF ts$ = "%&" THEN
    typ2ctyp$ = "ptrszint": IF (t AND ISUNSIGNED) THEN typ2ctyp$ = "uptrszint"
    EXIT FUNCTION
END IF
IF ts$ = "%%" THEN ctyp$ = "int8"
IF ts$ = "%" THEN ctyp$ = "int16"
IF ts$ = "&" THEN ctyp$ = "int32"
IF ts$ = "&&" THEN ctyp$ = "int64"
IF ctyp$ <> "" THEN
    IF unsgn THEN ctyp$ = "u" + ctyp$
    typ2ctyp$ = ctyp$: EXIT FUNCTION
END IF
'is tstr$ a named type? (eg. 'LONG')
s$ = type2symbol$(tstr$)
IF Error_Happened THEN EXIT FUNCTION
IF LEN(s$) THEN
    typ2ctyp$ = typ2ctyp$(0, s$)
    IF Error_Happened THEN EXIT FUNCTION
    EXIT FUNCTION
END IF

Give_Error "Invalid type": EXIT FUNCTION

END FUNCTION

FUNCTION type2symbol$ (typ$)
t$ = typ$
FOR i = 1 TO LEN(t$)
    IF MID$(t$, i, 1) = sp THEN MID$(t$, i, 1) = " "
NEXT
e$ = "Cannot convert type (" + typ$ + ") to symbol"
t2$ = "_UNSIGNED _BIT": s$ = "~`1": IF LEFT$(t$, LEN(t2$)) = t2$ THEN GOTO t2sfound
t2$ = "_UNSIGNED _BYTE": s$ = "~%%": IF LEFT$(t$, LEN(t2$)) = t2$ THEN GOTO t2sfound
t2$ = "_UNSIGNED INTEGER": s$ = "~%": IF LEFT$(t$, LEN(t2$)) = t2$ THEN GOTO t2sfound
t2$ = "_UNSIGNED LONG": s$ = "~&": IF LEFT$(t$, LEN(t2$)) = t2$ THEN GOTO t2sfound
t2$ = "_UNSIGNED _INTEGER64": s$ = "~&&": IF LEFT$(t$, LEN(t2$)) = t2$ THEN GOTO t2sfound
t2$ = "_UNSIGNED _OFFSET": s$ = "~%&": IF LEFT$(t$, LEN(t2$)) = t2$ THEN GOTO t2sfound
t2$ = "_BIT": s$ = "`1": IF LEFT$(t$, LEN(t2$)) = t2$ THEN GOTO t2sfound
t2$ = "_BYTE": s$ = "%%": IF LEFT$(t$, LEN(t2$)) = t2$ THEN GOTO t2sfound
t2$ = "INTEGER": s$ = "%": IF LEFT$(t$, LEN(t2$)) = t2$ THEN GOTO t2sfound
t2$ = "LONG": s$ = "&": IF LEFT$(t$, LEN(t2$)) = t2$ THEN GOTO t2sfound
t2$ = "_INTEGER64": s$ = "&&": IF LEFT$(t$, LEN(t2$)) = t2$ THEN GOTO t2sfound
t2$ = "_OFFSET": s$ = "%&": IF LEFT$(t$, LEN(t2$)) = t2$ THEN GOTO t2sfound
t2$ = "SINGLE": s$ = "!": IF LEFT$(t$, LEN(t2$)) = t2$ THEN GOTO t2sfound
t2$ = "DOUBLE": s$ = "#": IF LEFT$(t$, LEN(t2$)) = t2$ THEN GOTO t2sfound
t2$ = "_FLOAT": s$ = "##": IF LEFT$(t$, LEN(t2$)) = t2$ THEN GOTO t2sfound
t2$ = "STRING": s$ = "$": IF LEFT$(t$, LEN(t2$)) = t2$ THEN GOTO t2sfound
Give_Error e$: EXIT FUNCTION
t2sfound:
type2symbol$ = s$
IF LEN(t2$) <> LEN(t$) THEN
    IF s$ <> "$" AND s$ <> "~`1" AND s$ <> "`1" THEN Give_Error e$: EXIT FUNCTION
    t$ = RIGHT$(t$, LEN(t$) - LEN(t2$))
    IF LEFT$(t$, 3) <> " * " THEN Give_Error e$: EXIT FUNCTION
    t$ = RIGHT$(t$, LEN(t$) - 3)
    IF isuinteger(t$) = 0 THEN Give_Error e$: EXIT FUNCTION
    v = VAL(t$)
    IF v = 0 THEN Give_Error e$: EXIT FUNCTION
    IF s$ <> "$" AND v > 56 THEN Give_Error e$: EXIT FUNCTION
    IF s$ = "$" THEN
        s$ = s$ + str2$(v)
    ELSE
        s$ = LEFT$(s$, LEN(s$) - 1) + str2$(v)
    END IF
    type2symbol$ = s$
END IF
END FUNCTION

'Strips away bits/indentifiers which make locating a variables source difficult
FUNCTION typecomp (typ)
typ2 = typ
IF (typ2 AND ISINCONVENTIONALMEMORY) THEN typ2 = typ2 - ISINCONVENTIONALMEMORY
typecomp = typ2
END FUNCTION

FUNCTION typname2typ& (t2$)
typname2typsize = 0 'the default

t$ = t2$

'symbol?
ts$ = t$
IF ts$ = "$" THEN typname2typ& = STRINGTYPE: EXIT FUNCTION
IF ts$ = "!" THEN typname2typ& = SINGLETYPE: EXIT FUNCTION
IF ts$ = "#" THEN typname2typ& = DOUBLETYPE: EXIT FUNCTION
IF ts$ = "##" THEN typname2typ& = FLOATTYPE: EXIT FUNCTION

'fixed length string?
IF LEFT$(ts$, 1) = "$" THEN
    n$ = RIGHT$(ts$, LEN(ts$) - 1)
    IF isuinteger(n$) = 0 THEN Give_Error "Invalid index after STRING * type": EXIT FUNCTION
    b = VAL(n$)
    IF b = 0 THEN Give_Error "Invalid index after STRING * type": EXIT FUNCTION
    typname2typsize = b
    typname2typ& = STRINGTYPE + ISFIXEDLENGTH
    EXIT FUNCTION
END IF

'unsigned?
IF LEFT$(ts$, 1) = "~" THEN unsgn = 1: ts$ = RIGHT$(ts$, LEN(ts$) - 1)

'bit-type?
IF LEFT$(ts$, 1) = "`" THEN
    n$ = RIGHT$(ts$, LEN(ts$) - 1)
    b = 1
    IF n$ <> "" THEN
        IF isuinteger(n$) = 0 THEN Give_Error "Invalid index after _BIT type": EXIT FUNCTION
        b = VAL(n$)
        IF b > 56 THEN Give_Error "Invalid index after _BIT type": EXIT FUNCTION
    END IF
    IF unsgn THEN typname2typ& = UBITTYPE + (b - 1) ELSE typname2typ& = BITTYPE + (b - 1)
    EXIT FUNCTION
END IF

t = 0
IF ts$ = "%%" THEN t = BYTETYPE
IF ts$ = "%" THEN t = INTEGERTYPE
IF ts$ = "&" THEN t = LONGTYPE
IF ts$ = "&&" THEN t = INTEGER64TYPE
IF ts$ = "%&" THEN t = OFFSETTYPE

IF t THEN
    IF unsgn THEN t = t + ISUNSIGNED
    typname2typ& = t: EXIT FUNCTION
END IF
'not a valid symbol

'type name?
FOR i = 1 TO LEN(t$)
    IF MID$(t$, i, 1) = sp THEN MID$(t$, i, 1) = " "
NEXT
IF t$ = "STRING" THEN typname2typ& = STRINGTYPE: EXIT FUNCTION

IF LEFT$(t$, 9) = "STRING * " THEN

    n$ = RIGHT$(t$, LEN(t$) - 9)

    'constant check 2011
    hashfound = 0
    hashname$ = n$
    hashchkflags = HASHFLAG_CONSTANT
    hashres = HashFindRev(hashname$, hashchkflags, hashresflags, hashresref)
    DO WHILE hashres
        IF constsubfunc(hashresref) = subfuncn OR constsubfunc(hashresref) = 0 THEN
            IF constdefined(hashresref) THEN
                hashfound = 1
                EXIT DO
            END IF
        END IF
        IF hashres <> 1 THEN hashres = HashFindCont(hashresflags, hashresref) ELSE hashres = 0
    LOOP
    IF hashfound THEN
        i2 = hashresref
        t = consttype(i2)
        IF t AND ISSTRING THEN Give_Error "Expected STRING * numeric-constant": EXIT FUNCTION
        'convert value to general formats
        IF t AND ISFLOAT THEN
            v## = constfloat(i2)
            v&& = v##
            v~&& = v&&
        ELSE
            IF t AND ISUNSIGNED THEN
                v~&& = constuinteger(i2)
                v&& = v~&&
                v## = v&&
            ELSE
                v&& = constinteger(i2)
                v## = v&&
                v~&& = v&&
            END IF
        END IF
        IF v&& < 1 OR v&& > 9999999999 THEN Give_Error "STRING * out-of-range constant": EXIT FUNCTION
        b = v&&
        GOTO constantlenstr
    END IF

    IF isuinteger(n$) = 0 OR LEN(n$) > 10 THEN Give_Error "Invalid number/constant after STRING * type": EXIT FUNCTION
    b = VAL(n$)
    IF b = 0 OR LEN(n$) > 10 THEN Give_Error "Invalid number after STRING * type": EXIT FUNCTION
    constantlenstr:
    typname2typsize = b
    typname2typ& = STRINGTYPE + ISFIXEDLENGTH
    EXIT FUNCTION
END IF

IF t$ = "SINGLE" THEN typname2typ& = SINGLETYPE: EXIT FUNCTION
IF t$ = "DOUBLE" THEN typname2typ& = DOUBLETYPE: EXIT FUNCTION
IF t$ = "_FLOAT" THEN typname2typ& = FLOATTYPE: EXIT FUNCTION
IF LEFT$(t$, 10) = "_UNSIGNED " THEN u = 1: t$ = RIGHT$(t$, LEN(t$) - 10)
IF LEFT$(t$, 4) = "_BIT" THEN
    IF t$ = "_BIT" THEN
        IF u THEN typname2typ& = UBITTYPE ELSE typname2typ& = BITTYPE
        EXIT FUNCTION
    END IF
    IF LEFT$(t$, 7) <> "_BIT * " THEN Give_Error "Expected _BIT * number": EXIT FUNCTION

    n$ = RIGHT$(t$, LEN(t$) - 7)
    IF isuinteger(n$) = 0 THEN Give_Error "Invalid size after _BIT *": EXIT FUNCTION
    b = VAL(n$)
    IF b = 0 OR b > 56 THEN Give_Error "Invalid size after _BIT *": EXIT FUNCTION
    t = BITTYPE - 1 + b: IF u THEN t = t + ISUNSIGNED
    typname2typ& = t
    EXIT FUNCTION
END IF

t = 0
IF t$ = "_BYTE" THEN t = BYTETYPE
IF t$ = "INTEGER" THEN t = INTEGERTYPE
IF t$ = "LONG" THEN t = LONGTYPE
IF t$ = "_INTEGER64" THEN t = INTEGER64TYPE
IF t$ = "_OFFSET" THEN t = OFFSETTYPE
IF t THEN
    IF u THEN t = t + ISUNSIGNED
    typname2typ& = t
    EXIT FUNCTION
END IF
IF u THEN EXIT FUNCTION '_UNSIGNED (nothing)

'UDT?
FOR i = 1 TO lasttype
    IF t$ = RTRIM$(udtxname(i)) THEN
        typname2typ& = ISUDT + ISPOINTER + i
        EXIT FUNCTION
    END IF
NEXT

'return 0 (failed)
END FUNCTION

FUNCTION uniquenumber&
uniquenumbern = uniquenumbern + 1
uniquenumber& = uniquenumbern
END FUNCTION

FUNCTION validlabel (LABEL2$)
create = CreatingLabel: CreatingLabel = 0
validlabel = 0
IF LEN(LABEL2$) = 0 THEN EXIT FUNCTION
clabel$ = LABEL2$
label$ = UCASE$(LABEL2$)

n = numelements(label$)

IF n = 1 THEN

    'Note: Reserved words and internal sub/function names are invalid
    hashres = HashFind(label$, HASHFLAG_RESERVED + HASHFLAG_SUB + HASHFLAG_FUNCTION, hashresflags, hashresref)
    DO WHILE hashres
        IF hashresflags AND (HASHFLAG_SUB + HASHFLAG_FUNCTION) THEN
            IF ids(hashresref).internal_subfunc THEN EXIT FUNCTION

            IF hashresflags AND HASHFLAG_SUB THEN 'could be a label or a sub call!

                'analyze format
                IF ASC(ids(hashresref).specialformat) = 32 THEN
                    IF ids(hashresref).args = 0 THEN onecommandsub = 1 ELSE onecommandsub = 0
                ELSE
                    IF ASC(ids(hashresref).specialformat) <> 91 THEN '"["
                        onecommandsub = 0
                    ELSE
                        onecommandsub = 1
                        a$ = RTRIM$(ids(hashresref).specialformat)
                        b = 1
                        FOR x = 2 TO LEN(a$)
                            a = ASC(a$, x)
                            IF a = 91 THEN b = b + 1
                            IF a = 93 THEN b = b - 1
                            IF b = 0 AND x <> LEN(a$) THEN onecommandsub = 0: EXIT FOR
                        NEXT
                    END IF
                END IF
                IF create <> 0 AND onecommandsub = 1 THEN
                    IF INSTR(SubNameLabels$, sp + UCASE$(label$) + sp) = 0 THEN PossibleSubNameLabels$ = PossibleSubNameLabels$ + UCASE$(label$) + sp: EXIT FUNCTION 'treat as sub call
                END IF

            END IF 'sub name

        ELSE
            'reserved
            EXIT FUNCTION
        END IF
        IF hashres <> 1 THEN hashres = HashFindCont(hashresflags, hashresref) ELSE hashres = 0
    LOOP

    'Numeric label?
    'quasi numbers are possible, but:
    'a) They may only have one decimal place
    'b) They must be typed with the exact same characters to match
    t$ = label$
    'numeric?
    a = ASC(t$)
    IF (a >= 48 AND a <= 57) OR a = 46 THEN

        'refer to original formatting if possible (eg. 1.10 not 1.1)
        x = INSTR(t$, CHR$(44))
        IF x THEN
            t$ = RIGHT$(t$, LEN(t$) - x)
        END IF

        'note: The symbols ! and # are valid trailing symbols in QBASIC, regardless of the number's size,
        '      so they are allowed in QB64 for compatibility reasons
        addsymbol$ = removesymbol$(t$)
        IF Error_Happened THEN EXIT FUNCTION
        IF LEN(addsymbol$) THEN
            IF INSTR(addsymbol$, "$") THEN EXIT FUNCTION
            IF addsymbol$ <> "#" AND addsymbol$ <> "!" THEN addsymbol$ = ""
        END IF

        IF a = 46 THEN dp = 1
        FOR x = 2 TO LEN(t$)
            a = ASC(MID$(t$, x, 1))
            IF a = 46 THEN dp = dp + 1
            IF (a < 48 OR a > 57) AND a <> 46 THEN EXIT FUNCTION 'not numeric
        NEXT x
        IF dp > 1 THEN EXIT FUNCTION 'too many decimal points
        IF dp = 1 AND LEN(t$) = 1 THEN EXIT FUNCTION 'cant have '.' as a label

        tlayout$ = t$ + addsymbol$

        i = INSTR(t$, "."): IF i THEN MID$(t$, i, 1) = "p"
        IF addsymbol$ = "#" THEN t$ = t$ + "d"
        IF addsymbol$ = "!" THEN t$ = t$ + "s"

        IF LEN(t$) > 40 THEN EXIT FUNCTION

        LABEL2$ = t$
        validlabel = 1
        EXIT FUNCTION
    END IF 'numeric

END IF 'n=1

'Alpha-numeric label?
'Build label

'structure check (???.???.???.???)
IF (n AND 1) = 0 THEN EXIT FUNCTION 'must be an odd number of elements
FOR nx = 2 TO n - 1 STEP 2
    a$ = getelement$(LABEL2$, nx)
    IF a$ <> "." THEN EXIT FUNCTION 'every 2nd element must be a period
NEXT

'cannot begin with numeric
c = ASC(clabel$): IF c >= 48 AND c <= 57 THEN EXIT FUNCTION

'elements check
label3$ = ""
FOR nx = 1 TO n STEP 2
    label$ = getelement$(clabel$, nx)

    'alpha-numeric?
    FOR x = 1 TO LEN(label$)
        IF alphanumeric(ASC(label$, x)) = 0 THEN EXIT FUNCTION
    NEXT

    'build label
    IF label3$ = "" THEN label3$ = UCASE$(label$): tlayout$ = label$ ELSE label3$ = label3$ + fix046$ + UCASE$(label$): tlayout$ = tlayout$ + "." + label$
NEXT nx

validlabel = 1
LABEL2$ = label3$

END FUNCTION

SUB xend

'1. locate bottomline,1
'PRINT #12, "display_page->cursor_y=print_holding_cursor=0; qbg_cursor_x=1; qbg_cursor_y=qbg_height_in_characters;"

'2. print a message in the screen's width
'PRINT #12, "if (qbg_width_in_characters==80){"
'PRINT #12, "qbs_print(qbs_new_txt(" + CHR$(34) + "Press any key to continue" + SPACE$(80 - 25) + CHR$(34) + "),0);"
'PRINT #12, "}else{"
'PRINT #12, "qbs_print(qbs_new_txt(" + CHR$(34) + "Press any key to continue" + SPACE$(40 - 25) + CHR$(34) + "),0);"
'PRINT #12, "}"

'3. wait for a key to be pressed
'PRINT #12, "do{"
'PRINT #12, "SDL_Delay(0);"
'PRINT #12, "if (stop_program) end();"
'PRINT #12, "}while(qbs_cleanup(qbs_tmp_base,qbs_equal(qbs_inkey(),
'            qbs_new_txt(" + CHR$(34) + CHR$(34) + "))));"
'4. quit
'PRINT #12, "close_program=1;"
'PRINT #12, "end();"
PRINT #12, "sub_end();"
END SUB

SUB xfileprint (a$, ca$, n)
u$ = str2$(uniquenumber)
PRINT #12, "tab_spc_cr_size=2;"
IF n = 2 THEN Give_Error "Expected # ... , ...": EXIT SUB
a3$ = ""
b = 0
FOR i = 3 TO n
    a2$ = getelement$(ca$, i)
    IF a2$ = "(" THEN b = b + 1
    IF a2$ = ")" THEN b = b - 1
    IF a2$ = "," AND b = 0 THEN
        IF a3$ = "" THEN Give_Error "Expected # ... , ...": EXIT SUB
        GOTO printgotfn
    END IF
    IF a3$ = "" THEN a3$ = a2$ ELSE a3$ = a3$ + sp + a2$
NEXT
Give_Error "Expected # ... ,": EXIT SUB
printgotfn:
e$ = fixoperationorder$(a3$)
IF Error_Happened THEN EXIT SUB
l$ = "PRINT" + sp + "#" + sp2 + tlayout$ + sp2 + ","
e$ = evaluatetotyp(e$, 64&)
IF Error_Happened THEN EXIT SUB
PRINT #12, "tab_fileno=tmp_fileno=" + e$ + ";"
PRINT #12, "if (new_error) goto skip" + u$ + ";"
i = i + 1

'PRINT USING? (file)
IF n >= i THEN
    IF getelement(a$, i) = "USING" THEN
        'get format string
        fpujump:
        l$ = l$ + sp + "USING"
        e$ = "": b = 0: puformat$ = ""
        FOR i = i + 1 TO n
            a2$ = getelement(ca$, i)
            IF a2$ = "(" THEN b = b + 1
            IF a2$ = ")" THEN b = b - 1
            IF b = 0 THEN
                IF a2$ = "," THEN Give_Error "Expected PRINT USING #filenumber, formatstring ; ...": EXIT SUB
                IF a2$ = ";" THEN
                    e$ = fixoperationorder$(e$)
                    IF Error_Happened THEN EXIT SUB
                    l$ = l$ + sp + tlayout$ + sp2 + ";"
                    e$ = evaluate(e$, typ)
                    IF Error_Happened THEN EXIT SUB
                    IF (typ AND ISREFERENCE) THEN e$ = refer(e$, typ, 0)
                    IF Error_Happened THEN EXIT SUB
                    IF (typ AND ISSTRING) = 0 THEN Give_Error "Expected PRINT USING #filenumber, formatstring ; ...": EXIT SUB
                    puformat$ = e$
                    EXIT FOR
                END IF ';
            END IF 'b
            IF LEN(e$) THEN e$ = e$ + sp + a2$ ELSE e$ = a2$
        NEXT
        IF puformat$ = "" THEN Give_Error "Expected PRINT USING #filenumber, formatstring ; ...": EXIT SUB
        IF i = n THEN Give_Error "Expected PRINT USING #filenumber, formatstring ; ...": EXIT SUB
        'create build string
        PRINT #12, "tqbs=qbs_new(0,0);"
        'set format start/index variable
        PRINT #12, "tmp_long=0;" 'scan format from beginning
        'create string to hold format in for multiple references
        puf$ = "print_using_format" + u$
        IF subfunc = "" THEN
            PRINT #13, "static qbs *" + puf$ + ";"
        ELSE
            PRINT #13, "qbs *" + puf$ + ";"
        END IF
        PRINT #12, puf$ + "=qbs_new(0,0); qbs_set(" + puf$ + "," + puformat$ + ");"
        PRINT #12, "if (new_error) goto skip" + u$ + ";"
        'print expressions
        b = 0
        e$ = ""
        last = 0
        FOR i = i + 1 TO n
            a2$ = getelement(ca$, i)
            IF a2$ = "(" THEN b = b + 1
            IF a2$ = ")" THEN b = b - 1
            IF b = 0 THEN
                IF a2$ = ";" OR a2$ = "," THEN
                    fprintulast:
                    e$ = fixoperationorder$(e$)
                    IF Error_Happened THEN EXIT SUB
                    IF last THEN l$ = l$ + sp + tlayout$ ELSE l$ = l$ + sp + tlayout$ + sp2 + a2$
                    e$ = evaluate(e$, typ)
                    IF Error_Happened THEN EXIT SUB
                    IF (typ AND ISREFERENCE) THEN e$ = refer(e$, typ, 0)
                    IF Error_Happened THEN EXIT SUB
                    IF typ AND ISSTRING THEN

                        IF LEFT$(e$, 9) = "func_tab(" OR LEFT$(e$, 9) = "func_spc(" THEN

                            'TAB/SPC exception
                            'note: position in format-string must be maintained
                            '-print any string up until now
                            PRINT #12, "sub_file_print(tmp_fileno,tqbs,0,0,0);"
                            '-print e$
                            PRINT #12, "qbs_set(tqbs," + e$ + ");"
                            PRINT #12, "if (new_error) goto skip_pu" + u$ + ";"
                            PRINT #12, "sub_file_print(tmp_fileno,tqbs,0,0,0);"
                            '-set length of tqbs to 0
                            PRINT #12, "tqbs->len=0;"

                        ELSE

                            'regular string
                            PRINT #12, "tmp_long=print_using(" + puf$ + ",tmp_long,tqbs," + e$ + ");"

                        END IF

                    ELSE 'not a string
                        IF typ AND ISFLOAT THEN
                            IF (typ AND 511) = 32 THEN PRINT #12, "tmp_long=print_using_single(" + puf$ + "," + e$ + ",tmp_long,tqbs);"
                            IF (typ AND 511) = 64 THEN PRINT #12, "tmp_long=print_using_double(" + puf$ + "," + e$ + ",tmp_long,tqbs);"
                            IF (typ AND 511) > 64 THEN PRINT #12, "tmp_long=print_using_float(" + puf$ + "," + e$ + ",tmp_long,tqbs);"
                        ELSE
                            IF ((typ AND 511) = 64) AND (typ AND ISUNSIGNED) <> 0 THEN
                                PRINT #12, "tmp_long=print_using_uinteger64(" + puf$ + "," + e$ + ",tmp_long,tqbs);"
                            ELSE
                                PRINT #12, "tmp_long=print_using_integer64(" + puf$ + "," + e$ + ",tmp_long,tqbs);"
                            END IF
                        END IF
                    END IF 'string/not string
                    PRINT #12, "if (new_error) goto skip_pu" + u$ + ";"
                    e$ = ""
                    IF last THEN EXIT FOR
                    GOTO fprintunext
                END IF
            END IF
            IF LEN(e$) THEN e$ = e$ + sp + a2$ ELSE e$ = a2$
            fprintunext:
        NEXT
        IF e$ <> "" THEN a2$ = "": last = 1: GOTO fprintulast
        PRINT #12, "skip_pu" + u$ + ":"
        'check for errors
        PRINT #12, "if (new_error){"
        PRINT #12, "g_tmp_long=new_error; new_error=0; sub_file_print(tmp_fileno,tqbs,0,0,0); new_error=g_tmp_long;"
        PRINT #12, "}else{"
        IF a2$ = "," OR a2$ = ";" THEN nl = 0 ELSE nl = 1 'note: a2$ is set to the last element of a$
        PRINT #12, "sub_file_print(tmp_fileno,tqbs,0,0," + str2$(nl) + ");"
        PRINT #12, "}"
        PRINT #12, "qbs_free(tqbs);"
        PRINT #12, "qbs_free(" + puf$ + ");"
        PRINT #12, "skip" + u$ + ":"
        PRINT #12, cleanupstringprocessingcall$ + "0);"
        PRINT #12, "tab_spc_cr_size=1;"
        tlayout$ = l$
        EXIT SUB
    END IF
END IF
'end of print using code

IF i > n THEN
    PRINT #12, "sub_file_print(tmp_fileno,nothingstring,0,0,1);"
    GOTO printblankline
END IF
b = 0
e$ = ""
last = 0
FOR i = i TO n
    a2$ = getelement(ca$, i)
    IF a2$ = "(" THEN b = b + 1
    IF a2$ = ")" THEN b = b - 1
    IF b = 0 THEN
        IF a2$ = ";" OR a2$ = "," OR UCASE$(a2$) = "USING" THEN
            printfilelast:

            IF UCASE$(a2$) = "USING" THEN
                IF e$ <> "" THEN gotofpu = 1 ELSE GOTO fpujump
            END IF

            IF a2$ = "," THEN usetab = 1 ELSE usetab = 0
            IF last = 1 THEN newline = 1 ELSE newline = 0
            extraspace = 0

            IF LEN(e$) THEN
                ebak$ = e$
                pnrtnum = 0
                printfilenumber:
                e$ = fixoperationorder$(e$)
                IF Error_Happened THEN EXIT SUB
                IF pnrtnum = 0 THEN
                    IF last THEN l$ = l$ + sp + tlayout$ ELSE l$ = l$ + sp + tlayout$ + sp2 + a2$
                END IF
                e$ = evaluate(e$, typ)
                IF Error_Happened THEN EXIT SUB
                IF (typ AND ISSTRING) = 0 THEN
                    e$ = "STR$" + sp + "(" + sp + ebak$ + sp + ")"
                    extraspace = 1
                    pnrtnum = 1
                    GOTO printfilenumber 'force re-evaluation
                END IF
                IF (typ AND ISREFERENCE) THEN e$ = refer(e$, typ, 0)
                IF Error_Happened THEN EXIT SUB
                'format: string, (1/0) extraspace, (1/0) tab, (1/0)begin a new line
                PRINT #12, "sub_file_print(tmp_fileno," + e$ + ","; extraspace; ","; usetab; ","; newline; ");"
            ELSE 'len(e$)=0
                IF a2$ = "," THEN l$ = l$ + sp + a2$
                IF a2$ = ";" THEN
                    IF RIGHT$(l$, 1) <> ";" THEN l$ = l$ + sp + a2$ 'concat ;; to ;
                END IF
                IF usetab THEN PRINT #12, "sub_file_print(tmp_fileno,nothingstring,0,1,0);"
            END IF 'len(e$)
            PRINT #12, "if (new_error) goto skip" + u$ + ";"

            e$ = ""
            IF gotofpu THEN GOTO fpujump
            IF last THEN EXIT FOR
            GOTO printfilenext
        END IF ', or ;
    END IF 'b=0
    IF e$ <> "" THEN e$ = e$ + sp + a2$ ELSE e$ = a2$
    printfilenext:
NEXT
IF e$ <> "" THEN a2$ = "": last = 1: GOTO printfilelast
printblankline:
PRINT #12, "skip" + u$ + ":"
PRINT #12, cleanupstringprocessingcall$ + "0);"
PRINT #12, "tab_spc_cr_size=1;"
tlayout$ = l$
END SUB

SUB xfilewrite (ca$, n)
l$ = "WRITE" + sp + "#"
u$ = str2$(uniquenumber)
PRINT #12, "tab_spc_cr_size=2;"
IF n = 2 THEN Give_Error "Expected # ...": EXIT SUB
a3$ = ""
b = 0
FOR i = 3 TO n
    a2$ = getelement$(ca$, i)
    IF a2$ = "(" THEN b = b + 1
    IF a2$ = ")" THEN b = b - 1
    IF a2$ = "," AND b = 0 THEN
        IF a3$ = "" THEN Give_Error "Expected # ... , ...": EXIT SUB
        GOTO writegotfn
    END IF
    IF a3$ = "" THEN a3$ = a2$ ELSE a3$ = a3$ + sp + a2$
NEXT
Give_Error "Expected # ... ,": EXIT SUB
writegotfn:
e$ = fixoperationorder$(a3$)
IF Error_Happened THEN EXIT SUB
l$ = l$ + sp2 + tlayout$ + sp2 + ","
e$ = evaluatetotyp(e$, 64&)
IF Error_Happened THEN EXIT SUB
PRINT #12, "tab_fileno=tmp_fileno=" + e$ + ";"
PRINT #12, "if (new_error) goto skip" + u$ + ";"
i = i + 1
IF i > n THEN
    PRINT #12, "sub_file_print(tmp_fileno,nothingstring,0,0,1);"
    GOTO writeblankline
END IF
b = 0
e$ = ""
last = 0
FOR i = i TO n
    a2$ = getelement(ca$, i)
    IF a2$ = "(" THEN b = b + 1
    IF a2$ = ")" THEN b = b - 1
    IF b = 0 THEN
        IF a2$ = "," THEN
            writefilelast:
            IF last = 1 THEN newline = 1 ELSE newline = 0
            ebak$ = e$
            reevaled = 0
            writefilenumber:
            e$ = fixoperationorder$(e$)
            IF Error_Happened THEN EXIT SUB
            IF reevaled = 0 THEN
                l$ = l$ + sp + tlayout$
                IF last = 0 THEN l$ = l$ + sp2 + ","
            END IF
            e$ = evaluate(e$, typ)
            IF Error_Happened THEN EXIT SUB
            IF reevaled = 0 THEN
                IF (typ AND ISSTRING) = 0 THEN
                    e$ = "LTRIM$" + sp + "(" + sp + "STR$" + sp + "(" + sp + ebak$ + sp + ")" + sp + ")"
                    IF last = 0 THEN e$ = e$ + sp + "+" + sp + CHR$(34) + "," + CHR$(34) + ",1"
                    reevaled = 1
                    GOTO writefilenumber 'force re-evaluation
                ELSE
                    e$ = CHR$(34) + "\042" + CHR$(34) + ",1" + sp + "+" + sp + ebak$ + sp + "+" + sp + CHR$(34) + "\042" + CHR$(34) + ",1"
                    IF last = 0 THEN e$ = e$ + sp + "+" + sp + CHR$(34) + "," + CHR$(34) + ",1"
                    reevaled = 1
                    GOTO writefilenumber 'force re-evaluation
                END IF
            END IF
            IF (typ AND ISREFERENCE) THEN e$ = refer(e$, typ, 0)
            IF Error_Happened THEN EXIT SUB
            'format: string, (1/0) extraspace, (1/0) tab, (1/0)begin a new line
            PRINT #12, "sub_file_print(tmp_fileno," + e$ + ",0,0,"; newline; ");"
            PRINT #12, "if (new_error) goto skip" + u$ + ";"
            e$ = ""
            IF last THEN EXIT FOR
            GOTO writefilenext
        END IF ',
    END IF 'b=0
    IF e$ <> "" THEN e$ = e$ + sp + a2$ ELSE e$ = a2$
    writefilenext:
NEXT
IF e$ <> "" THEN a2$ = ",": last = 1: GOTO writefilelast
writeblankline:
'print #12, "}"'new_error
PRINT #12, "skip" + u$ + ":"
PRINT #12, cleanupstringprocessingcall$ + "0);"
PRINT #12, "tab_spc_cr_size=1;"
layoutdone = 1: IF LEN(layout$) THEN layout$ = layout$ + sp + l$ ELSE layout$ = l$
END SUB

SUB xgosub (ca$, n&)
a2$ = getelement(ca$, 2)
IF validlabel(a2$) = 0 THEN Give_Error "Invalid label": EXIT SUB

v = HashFind(a2$, HASHFLAG_LABEL, ignore, r)
x = 1
labchk200:
IF v THEN
    s = Labels(r).Scope
    IF s = subfuncn OR s = -1 THEN 'same scope?
        IF s = -1 THEN Labels(r).Scope = subfuncn 'acquire scope
        x = 0 'already defined
        tlayout$ = RTRIM$(Labels(r).cn)
    ELSE
        IF v = 2 THEN v = HashFindCont(ignore, r): GOTO labchk200
    END IF
END IF
IF x THEN
    'does not exist
    nLabels = nLabels + 1: IF nLabels > Labels_Ubound THEN Labels_Ubound = Labels_Ubound * 2: REDIM _PRESERVE Labels(1 TO Labels_Ubound) AS Label_Type
    Labels(nLabels) = Empty_Label
    HashAdd a2$, HASHFLAG_LABEL, nLabels
    r = nLabels
    Labels(r).State = 0
    Labels(r).cn = tlayout$
    Labels(r).Scope = subfuncn
    Labels(r).Error_Line = linenumber
END IF 'x

l$ = "GOSUB" + sp + tlayout$
layoutdone = 1: IF LEN(layout$) THEN layout$ = layout$ + sp + l$ ELSE layout$ = l$
'note: This code fragment also used by ON ... GOTO/GOSUB
'assume label is reachable (revise)
PRINT #12, "return_point[next_return_point++]=" + str2(gosubid) + ";"
PRINT #12, "if (next_return_point>=return_points) more_return_points();"
PRINT #12, "goto LABEL_" + a2$ + ";"
'add return point jump
PRINT #15, "case " + str2(gosubid) + ":"
PRINT #15, "goto RETURN_" + str2(gosubid) + ";"
PRINT #15, "break;"
PRINT #12, "RETURN_" + str2(gosubid) + ":;"
gosubid = gosubid + 1
END SUB

SUB xongotogosub (a$, ca$, n)
IF n < 4 THEN Give_Error "Expected ON expression GOTO/GOSUB label,label,...": EXIT SUB
l$ = "ON"
b = 0
FOR i = 2 TO n
    e2$ = getelement$(a$, i)
    IF e2$ = "(" THEN b = b + 1
    IF e2$ = ")" THEN b = b - 1
    IF e2$ = "GOTO" OR e2$ = "GOSUB" THEN EXIT FOR
NEXT
IF i >= n OR i = 2 THEN Give_Error "Expected ON expression GOTO/GOSUB label,label,...": EXIT SUB
e$ = getelements$(ca$, 2, i - 1)

g = 0: IF e2$ = "GOSUB" THEN g = 1
e$ = fixoperationorder(e$)
IF Error_Happened THEN EXIT SUB
l$ = l$ + sp + tlayout$
e$ = evaluate(e$, typ)
IF Error_Happened THEN EXIT SUB
IF (typ AND ISREFERENCE) THEN e$ = refer(e$, typ, 0)
IF Error_Happened THEN EXIT SUB
IF (typ AND ISSTRING) THEN Give_Error "Expected numeric expression": EXIT SUB
IF (typ AND ISFLOAT) THEN
    e$ = "qbr_float_to_long(" + e$ + ")"
END IF
l$ = l$ + sp + e2$
u$ = str2$(uniquenumber)
PRINT #13, "static int32 ongo_" + u$ + "=0;"
PRINT #12, "ongo_" + u$ + "=" + e$ + ";"
ln = 1
labelwaslast = 0
FOR i = i + 1 TO n
    e$ = getelement$(ca$, i)
    IF e$ = "," THEN
        l$ = l$ + sp2 + ","
        IF i = n THEN Give_Error "Trailing , invalid": EXIT SUB
        ln = ln + 1
        labelwaslast = 0
    ELSE
        IF labelwaslast THEN Give_Error "Expected ,": EXIT SUB
        IF validlabel(e$) = 0 THEN Give_Error "Invalid label!": EXIT SUB

        v = HashFind(e$, HASHFLAG_LABEL, ignore, r)
        x = 1
        labchk507:
        IF v THEN
            s = Labels(r).Scope
            IF s = subfuncn OR s = -1 THEN 'same scope?
                IF s = -1 THEN Labels(r).Scope = subfuncn 'acquire scope
                x = 0 'already defined
                tlayout$ = RTRIM$(Labels(r).cn)
            ELSE
                IF v = 2 THEN v = HashFindCont(ignore, r): GOTO labchk507
            END IF
        END IF
        IF x THEN
            'does not exist
            nLabels = nLabels + 1: IF nLabels > Labels_Ubound THEN Labels_Ubound = Labels_Ubound * 2: REDIM _PRESERVE Labels(1 TO Labels_Ubound) AS Label_Type
            Labels(nLabels) = Empty_Label
            HashAdd e$, HASHFLAG_LABEL, nLabels
            r = nLabels
            Labels(r).State = 0
            Labels(r).cn = tlayout$
            Labels(r).Scope = subfuncn
            Labels(r).Error_Line = linenumber
        END IF 'x

        l$ = l$ + sp + tlayout$
        IF g THEN 'gosub
            lb$ = e$
            PRINT #12, "if (ongo_" + u$ + "==" + str2$(ln) + "){"
            'note: This code fragment also used by ON ... GOTO/GOSUB
            'assume label is reachable (revise)
            PRINT #12, "return_point[next_return_point++]=" + str2(gosubid) + ";"
            PRINT #12, "if (next_return_point>=return_points) more_return_points();"
            PRINT #12, "goto LABEL_" + lb$ + ";"
            'add return point jump
            PRINT #15, "case " + str2(gosubid) + ":"
            PRINT #15, "goto RETURN_" + str2(gosubid) + ";"
            PRINT #15, "break;"
            PRINT #12, "RETURN_" + str2(gosubid) + ":;"
            gosubid = gosubid + 1
            PRINT #12, "goto ongo_" + u$ + "_skip;"
            PRINT #12, "}"
        ELSE 'goto
            PRINT #12, "if (ongo_" + u$ + "==" + str2$(ln) + ") goto LABEL_" + e$ + ";"
        END IF
        labelwaslast = 1
    END IF
NEXT
PRINT #12, "if (ongo_" + u$ + "<0) error(5);"
IF g = 1 THEN PRINT #12, "ongo_" + u$ + "_skip:;"
layoutdone = 1: IF LEN(layout$) THEN layout$ = layout$ + sp + l$ ELSE layout$ = l$
END SUB

SUB xprint (a$, ca$, n)
u$ = str2$(uniquenumber)

l$ = "PRINT"
IF ASC(a$) = 76 THEN lp = 1: lp$ = "l": l$ = "LPRINT": PRINT #12, "tab_LPRINT=1;": DEPENDENCY(DEPENDENCY_PRINTER) = 1 '"L"

'PRINT USING?
IF n >= 2 THEN
    IF getelement(a$, 2) = "USING" THEN
        'get format string
        i = 3
        pujump:
        l$ = l$ + sp + "USING"
        e$ = "": b = 0: puformat$ = ""
        FOR i = i TO n
            a2$ = getelement(ca$, i)
            IF a2$ = "(" THEN b = b + 1
            IF a2$ = ")" THEN b = b - 1
            IF b = 0 THEN
                IF a2$ = "," THEN Give_Error "Expected PRINT USING formatstring ; ...": EXIT SUB
                IF a2$ = ";" THEN
                    e$ = fixoperationorder$(e$)
                    IF Error_Happened THEN EXIT SUB
                    l$ = l$ + sp + tlayout$ + sp2 + ";"
                    e$ = evaluate(e$, typ)
                    IF Error_Happened THEN EXIT SUB
                    IF (typ AND ISREFERENCE) THEN e$ = refer(e$, typ, 0)
                    IF Error_Happened THEN EXIT SUB
                    IF (typ AND ISSTRING) = 0 THEN Give_Error "Expected PRINT USING formatstring ; ...": EXIT SUB
                    puformat$ = e$
                    EXIT FOR
                END IF ';
            END IF 'b
            IF LEN(e$) THEN e$ = e$ + sp + a2$ ELSE e$ = a2$
        NEXT
        IF puformat$ = "" THEN Give_Error "Expected PRINT USING formatstring ; ...": EXIT SUB
        IF i = n THEN Give_Error "Expected PRINT USING formatstring ; ...": EXIT SUB
        'create build string
        PRINT #12, "tqbs=qbs_new(0,0);"
        'set format start/index variable
        PRINT #12, "tmp_long=0;" 'scan format from beginning


        'create string to hold format in for multiple references
        puf$ = "print_using_format" + u$
        IF subfunc = "" THEN
            PRINT #13, "static qbs *" + puf$ + ";"
        ELSE
            PRINT #13, "qbs *" + puf$ + ";"
        END IF
        PRINT #12, puf$ + "=qbs_new(0,0); qbs_set(" + puf$ + "," + puformat$ + ");"
        PRINT #12, "if (new_error) goto skip_pu" + u$ + ";"

        'print expressions
        b = 0
        e$ = ""
        last = 0
        FOR i = i + 1 TO n
            a2$ = getelement(ca$, i)
            IF a2$ = "(" THEN b = b + 1
            IF a2$ = ")" THEN b = b - 1
            IF b = 0 THEN
                IF a2$ = ";" OR a2$ = "," THEN
                    printulast:
                    e$ = fixoperationorder$(e$)
                    IF Error_Happened THEN EXIT SUB
                    IF last THEN l$ = l$ + sp + tlayout$ ELSE l$ = l$ + sp + tlayout$ + sp2 + a2$
                    e$ = evaluate(e$, typ)
                    IF Error_Happened THEN EXIT SUB
                    IF (typ AND ISREFERENCE) THEN e$ = refer(e$, typ, 0)
                    IF Error_Happened THEN EXIT SUB
                    IF typ AND ISSTRING THEN

                        IF LEFT$(e$, 9) = "func_tab(" OR LEFT$(e$, 9) = "func_spc(" THEN

                            'TAB/SPC exception
                            'note: position in format-string must be maintained
                            '-print any string up until now
                            PRINT #12, "qbs_" + lp$ + "print(tqbs,0);"
                            '-print e$
                            PRINT #12, "qbs_set(tqbs," + e$ + ");"
                            PRINT #12, "if (new_error) goto skip_pu" + u$ + ";"
                            IF lp THEN PRINT #12, "lprint_makefit(tqbs);" ELSE PRINT #12, "makefit(tqbs);"
                            PRINT #12, "qbs_" + lp$ + "print(tqbs,0);"
                            '-set length of tqbs to 0
                            PRINT #12, "tqbs->len=0;"

                        ELSE

                            'regular string
                            PRINT #12, "tmp_long=print_using(" + puf$ + ",tmp_long,tqbs," + e$ + ");"

                        END IF



                    ELSE 'not a string
                        IF typ AND ISFLOAT THEN
                            IF (typ AND 511) = 32 THEN PRINT #12, "tmp_long=print_using_single(" + puf$ + "," + e$ + ",tmp_long,tqbs);"
                            IF (typ AND 511) = 64 THEN PRINT #12, "tmp_long=print_using_double(" + puf$ + "," + e$ + ",tmp_long,tqbs);"
                            IF (typ AND 511) > 64 THEN PRINT #12, "tmp_long=print_using_float(" + puf$ + "," + e$ + ",tmp_long,tqbs);"
                        ELSE
                            IF ((typ AND 511) = 64) AND (typ AND ISUNSIGNED) <> 0 THEN
                                PRINT #12, "tmp_long=print_using_uinteger64(" + puf$ + "," + e$ + ",tmp_long,tqbs);"
                            ELSE
                                PRINT #12, "tmp_long=print_using_integer64(" + puf$ + "," + e$ + ",tmp_long,tqbs);"
                            END IF
                        END IF
                    END IF 'string/not string
                    PRINT #12, "if (new_error) goto skip_pu" + u$ + ";"
                    e$ = ""
                    IF last THEN EXIT FOR
                    GOTO printunext
                END IF
            END IF
            IF LEN(e$) THEN e$ = e$ + sp + a2$ ELSE e$ = a2$
            printunext:
        NEXT
        IF e$ <> "" THEN a2$ = "": last = 1: GOTO printulast
        PRINT #12, "skip_pu" + u$ + ":"
        'check for errors
        PRINT #12, "if (new_error){"
        PRINT #12, "g_tmp_long=new_error; new_error=0; qbs_" + lp$ + "print(tqbs,0); new_error=g_tmp_long;"
        PRINT #12, "}else{"
        IF a2$ = "," OR a2$ = ";" THEN nl = 0 ELSE nl = 1 'note: a2$ is set to the last element of a$
        PRINT #12, "qbs_" + lp$ + "print(tqbs," + str2$(nl) + ");"
        PRINT #12, "}"
        PRINT #12, "qbs_free(tqbs);"
        PRINT #12, "qbs_free(" + puf$ + ");"
        PRINT #12, "skip" + u$ + ":"
        PRINT #12, cleanupstringprocessingcall$ + "0);"
        IF lp THEN PRINT #12, "tab_LPRINT=0;"
        tlayout$ = l$
        EXIT SUB
    END IF
END IF
'end of print using code

b = 0
e$ = ""
last = 0
FOR i = 2 TO n
    a2$ = getelement(ca$, i)
    IF a2$ = "(" THEN b = b + 1
    IF a2$ = ")" THEN b = b - 1
    IF b = 0 THEN
        IF a2$ = ";" OR a2$ = "," OR UCASE$(a2$) = "USING" THEN
            printlast:

            IF UCASE$(a2$) = "USING" THEN
                IF e$ <> "" THEN gotopu = 1 ELSE i = i + 1: GOTO pujump
            END IF

            IF LEN(e$) THEN
                ebak$ = e$
                pnrtnum = 0
                printnumber:
                e$ = fixoperationorder$(e$)
                IF Error_Happened THEN EXIT SUB
                IF pnrtnum = 0 THEN
                    IF last THEN l$ = l$ + sp + tlayout$ ELSE l$ = l$ + sp + tlayout$ + sp2 + a2$
                END IF
                e$ = evaluate(e$, typ)
                IF Error_Happened THEN EXIT SUB
                IF (typ AND ISSTRING) = 0 THEN
                    'not a string expresion!
                    e$ = "STR$" + sp + "(" + sp + ebak$ + sp + ")" + sp + "+" + sp + CHR$(34) + " " + CHR$(34)
                    pnrtnum = 1
                    GOTO printnumber
                END IF
                IF (typ AND ISREFERENCE) THEN e$ = refer(e$, typ, 0)
                IF Error_Happened THEN EXIT SUB
                PRINT #12, "tqbs=qbs_new(0,0);"
                PRINT #12, "qbs_set(tqbs," + e$ + ");"
                PRINT #12, "if (new_error) goto skip" + u$ + ";"
                IF lp THEN PRINT #12, "lprint_makefit(tqbs);" ELSE PRINT #12, "makefit(tqbs);"
                PRINT #12, "qbs_" + lp$ + "print(tqbs,0);"
                PRINT #12, "qbs_free(tqbs);"
            ELSE
                IF a2$ = "," THEN l$ = l$ + sp + a2$
                IF a2$ = ";" THEN
                    IF RIGHT$(l$, 1) <> ";" THEN l$ = l$ + sp + a2$ 'concat ;; to ;
                END IF
            END IF 'len(e$)
            IF a2$ = "," THEN PRINT #12, "tab();"
            e$ = ""

            IF gotopu THEN i = i + 1: GOTO pujump

            IF last THEN
                PRINT #12, "qbs_" + lp$ + "print(nothingstring,1);" 'go to new line
                EXIT FOR
            END IF

            GOTO printnext
        END IF 'a2$
    END IF 'b=0

    IF LEN(e$) THEN e$ = e$ + sp + a2$ ELSE e$ = a2$
    printnext:
NEXT
IF LEN(e$) THEN a2$ = "": last = 1: GOTO printlast
IF n = 1 THEN PRINT #12, "qbs_" + lp$ + "print(nothingstring,1);"
PRINT #12, "skip" + u$ + ":"
PRINT #12, cleanupstringprocessingcall$ + "0);"
IF lp THEN PRINT #12, "tab_LPRINT=0;"
tlayout$ = l$
END SUB




SUB xread (ca$, n)
l$ = "READ"
IF n = 1 THEN Give_Error "Expected variable": EXIT SUB
i = 2
IF i > n THEN Give_Error "Expected , ...": EXIT SUB
a3$ = ""
b = 0
FOR i = i TO n
    a2$ = getelement$(ca$, i)
    IF a2$ = "(" THEN b = b + 1
    IF a2$ = ")" THEN b = b - 1
    IF (a2$ = "," AND b = 0) OR i = n THEN
        IF i = n THEN
            IF a3$ = "" THEN a3$ = a2$ ELSE a3$ = a3$ + sp + a2$
        END IF
        IF a3$ = "" THEN Give_Error "Expected , ...": EXIT SUB
        e$ = fixoperationorder$(a3$)
        IF Error_Happened THEN EXIT SUB
        l$ = l$ + sp + tlayout$: IF i <> n THEN l$ = l$ + sp2 + ","
        e$ = evaluate(e$, t)
        IF Error_Happened THEN EXIT SUB
        IF (t AND ISREFERENCE) = 0 THEN Give_Error "Expected variable": EXIT SUB

        IF (t AND ISSTRING) THEN
            e$ = refer(e$, t, 0)
            IF Error_Happened THEN EXIT SUB
            PRINT #12, "sub_read_string(data,&data_offset,data_size," + e$ + ");"
            stringprocessinghappened = 1
        ELSE
            'numeric variable
            IF (t AND ISFLOAT) <> 0 OR (t AND 511) <> 64 THEN
                IF (t AND ISOFFSETINBITS) THEN
                    setrefer e$, t, "((int64)func_read_float(data,&data_offset,data_size," + str2(t) + "))", 1
                    IF Error_Happened THEN EXIT SUB
                ELSE
                    setrefer e$, t, "func_read_float(data,&data_offset,data_size," + str2(t) + ")", 1
                    IF Error_Happened THEN EXIT SUB
                END IF
            ELSE
                IF t AND ISUNSIGNED THEN
                    setrefer e$, t, "func_read_uint64(data,&data_offset,data_size)", 1
                    IF Error_Happened THEN EXIT SUB
                ELSE
                    setrefer e$, t, "func_read_int64(data,&data_offset,data_size)", 1
                    IF Error_Happened THEN EXIT SUB
                END IF
            END IF
        END IF 'string/numeric
        IF i = n THEN EXIT FOR
        a3$ = "": a2$ = ""
    END IF
    IF a3$ = "" THEN a3$ = a2$ ELSE a3$ = a3$ + sp + a2$
NEXT
IF stringprocessinghappened THEN PRINT #12, cleanupstringprocessingcall$ + "0);"
layoutdone = 1: IF LEN(layout$) THEN layout$ = layout$ + sp + l$ ELSE layout$ = l$
END SUB

SUB xwrite (ca$, n)
l$ = "WRITE"
u$ = str2$(uniquenumber)
IF n = 1 THEN
    PRINT #12, "qbs_print(nothingstring,1);"
    GOTO writeblankline2
END IF
b = 0
e$ = ""
last = 0
FOR i = 2 TO n
    a2$ = getelement(ca$, i)
    IF a2$ = "(" THEN b = b + 1
    IF a2$ = ")" THEN b = b - 1
    IF b = 0 THEN
        IF a2$ = "," THEN
            writelast:
            IF last = 1 THEN newline = 1 ELSE newline = 0
            ebak$ = e$
            reevaled = 0
            writechecked:
            e$ = fixoperationorder$(e$)
            IF Error_Happened THEN EXIT SUB
            IF reevaled = 0 THEN
                l$ = l$ + sp + tlayout$
                IF last = 0 THEN l$ = l$ + sp2 + ","
            END IF
            e$ = evaluate(e$, typ)
            IF Error_Happened THEN EXIT SUB
            IF reevaled = 0 THEN
                IF (typ AND ISSTRING) = 0 THEN
                    e$ = "LTRIM$" + sp + "(" + sp + "STR$" + sp + "(" + sp + ebak$ + sp + ")" + sp + ")"
                    IF last = 0 THEN e$ = e$ + sp + "+" + sp + CHR$(34) + "," + CHR$(34) + ",1"
                    reevaled = 1
                    GOTO writechecked 'force re-evaluation
                ELSE
                    e$ = CHR$(34) + "\042" + CHR$(34) + ",1" + sp + "+" + sp + ebak$ + sp + "+" + sp + CHR$(34) + "\042" + CHR$(34) + ",1"
                    IF last = 0 THEN e$ = e$ + sp + "+" + sp + CHR$(34) + "," + CHR$(34) + ",1"
                    reevaled = 1
                    GOTO writechecked 'force re-evaluation
                END IF
            END IF
            IF (typ AND ISREFERENCE) THEN e$ = refer(e$, typ, 0)
            IF Error_Happened THEN EXIT SUB
            'format: string, (1/0) extraspace, (1/0) tab, (1/0)begin a new line
            PRINT #12, "qbs_print(" + e$ + ","; newline; ");"
            PRINT #12, "if (new_error) goto skip" + u$ + ";"
            e$ = ""
            IF last THEN EXIT FOR
            GOTO writenext
        END IF ',
    END IF 'b=0
    IF e$ <> "" THEN e$ = e$ + sp + a2$ ELSE e$ = a2$
    writenext:
NEXT
IF e$ <> "" THEN a2$ = ",": last = 1: GOTO writelast
writeblankline2:
PRINT #12, "skip" + u$ + ":"
PRINT #12, cleanupstringprocessingcall$ + "0);"
layoutdone = 1: IF LEN(layout$) THEN layout$ = layout$ + sp + l$ ELSE layout$ = l$
END SUB

FUNCTION evaluateconst$ (a2$, t AS LONG)
a$ = a2$
IF Debug THEN PRINT #9, "evaluateconst:in:" + a$


DIM block(1000) AS STRING
DIM status(1000) AS INTEGER
'0=unprocessed (can be "")
'1=processed
DIM btype(1000) AS LONG 'for status=1 blocks

'put a$ into blocks
n = numelements(a$)
FOR i = 1 TO n
    block(i) = getelement$(a$, i)
NEXT

evalconstevalbrack:

'find highest bracket level
l = 0
b = 0
FOR i = 1 TO n
    IF block(i) = "(" THEN b = b + 1
    IF block(i) = ")" THEN b = b - 1
    IF b > l THEN l = b
NEXT

'if brackets exist, evaluate that item first
IF l THEN

    b = 0
    e$ = ""
    FOR i = 1 TO n

        IF block(i) = ")" THEN
            IF b = l THEN block(i) = "": EXIT FOR
            b = b - 1
        END IF

        IF b >= l THEN
            IF LEN(e$) = 0 THEN e$ = block(i) ELSE e$ = e$ + sp + block(i)
            block(i) = ""
        END IF

        IF block(i) = "(" THEN
            b = b + 1
            IF b = l THEN i2 = i: block(i) = ""
        END IF

    NEXT i

    status(i) = 1
    block(i) = evaluateconst$(e$, btype(i))
    IF Error_Happened THEN EXIT FUNCTION
    GOTO evalconstevalbrack

END IF 'l

'linear equation remains with some pre-calculated & non-pre-calc blocks

'problem: type QBASIC assumes and type required to store calc. value may
'         differ dramatically. in qbasic, this would have caused an overflow,
'         but in qb64 it MUST work. eg. 32767% * 32767%
'solution: all interger calc. will be performed using a signed _INTEGER64
'          all float calc. will be performed using a _FLOAT

'convert non-calc block numbers into binary form with QBASIC-like type
FOR i = 1 TO n
    IF status(i) = 0 THEN
        IF LEN(block(i)) THEN

            a = ASC(block(i))
            IF (a = 45 AND LEN(block(i)) > 1) OR (a >= 48 AND a <= 57) THEN 'number?

                'integers
                e$ = RIGHT$(block(i), 3)
                IF e$ = "~&&" THEN btype(i) = UINTEGER64TYPE - ISPOINTER: GOTO gotconstblkityp
                IF e$ = "~%%" THEN btype(i) = UBYTETYPE - ISPOINTER: GOTO gotconstblkityp
                e$ = RIGHT$(block(i), 2)
                IF e$ = "&&" THEN btype(i) = INTEGER64TYPE - ISPOINTER: GOTO gotconstblkityp
                IF e$ = "%%" THEN btype(i) = BYTETYPE - ISPOINTER: GOTO gotconstblkityp
                IF e$ = "~%" THEN btype(i) = UINTEGERTYPE - ISPOINTER: GOTO gotconstblkityp
                IF e$ = "~&" THEN btype(i) = ULONGTYPE - ISPOINTER: GOTO gotconstblkityp
                e$ = RIGHT$(block(i), 1)
                IF e$ = "%" THEN btype(i) = INTEGERTYPE - ISPOINTER: GOTO gotconstblkityp
                IF e$ = "&" THEN btype(i) = LONGTYPE - ISPOINTER: GOTO gotconstblkityp

                'ubit-type?
                IF INSTR(block(i), "~`") THEN
                    x = INSTR(block(i), "~`")
                    IF x = LEN(block(i)) - 1 THEN block(i) = block(i) + "1"
                    btype(i) = UBITTYPE - ISPOINTER - 1 + VAL(RIGHT$(block(i), LEN(block(i)) - x - 1))
                    block(i) = _MK$(_INTEGER64, VAL(LEFT$(block(i), x - 1)))
                    status(i) = 1
                    GOTO gotconstblktyp
                END IF

                'bit-type?
                IF INSTR(block(i), "`") THEN
                    x = INSTR(block(i), "`")
                    IF x = LEN(block(i)) THEN block(i) = block(i) + "1"
                    btype(i) = BITTYPE - ISPOINTER - 1 + VAL(RIGHT$(block(i), LEN(block(i)) - x))
                    block(i) = _MK$(_INTEGER64, VAL(LEFT$(block(i), x - 1)))
                    status(i) = 1
                    GOTO gotconstblktyp
                END IF

                'floats
                IF INSTR(block(i), "E") THEN
                    block(i) = _MK$(_FLOAT, VAL(block(i)))
                    btype(i) = SINGLETYPE - ISPOINTER
                    status(i) = 1
                    GOTO gotconstblktyp
                END IF
                IF INSTR(block(i), "D") THEN
                    block(i) = _MK$(_FLOAT, VAL(block(i)))
                    btype(i) = DOUBLETYPE - ISPOINTER
                    status(i) = 1
                    GOTO gotconstblktyp
                END IF
                IF INSTR(block(i), "F") THEN
                    block(i) = _MK$(_FLOAT, VAL(block(i)))
                    btype(i) = FLOATTYPE - ISPOINTER
                    status(i) = 1
                    GOTO gotconstblktyp
                END IF

                Give_Error "Invalid CONST expression.1": EXIT FUNCTION

                gotconstblkityp:
                block(i) = LEFT$(block(i), LEN(block(i)) - LEN(e$))
                block(i) = _MK$(_INTEGER64, VAL(block(i)))
                status(i) = 1
                gotconstblktyp:

            END IF 'a

            IF a = 34 THEN 'string?
                'no changes need to be made to block(i) which is of format "CHARACTERS",size
                btype(i) = STRINGTYPE - ISPOINTER
                status(i) = 1
            END IF

        END IF 'len<>0
    END IF 'status
NEXT

'remove NULL blocks
n2 = 0
FOR i = 1 TO n
    IF block(i) <> "" THEN
        n2 = n2 + 1
        block(n2) = block(i)
        status(n2) = status(i)
        btype(n2) = btype(i)
    END IF
NEXT
n = n2

'only one block?
IF n = 1 THEN
    IF status(1) = 0 THEN Give_Error "Invalid CONST expression.2": EXIT FUNCTION
    t = btype(1)
    evaluateconst$ = block(1)
    EXIT FUNCTION
END IF 'n=1

'evaluate equation (equation cannot contain any STRINGs)

'[negation/not][variable]
e$ = block(1)
IF status(1) = 0 THEN
    IF n <> 2 THEN Give_Error "Invalid CONST expression.4": EXIT FUNCTION
    IF status(2) = 0 THEN Give_Error "Invalid CONST expression.5": EXIT FUNCTION
    IF btype(2) AND ISSTRING THEN Give_Error "Invalid CONST expression.6": EXIT FUNCTION
    o$ = block(1)

    IF o$ = "�" THEN
        IF btype(2) AND ISFLOAT THEN
            r## = -_CV(_FLOAT, block(2))
            evaluateconst$ = _MK$(_FLOAT, r##)
        ELSE
            r&& = -_CV(_INTEGER64, block(2))
            evaluateconst$ = _MK$(_INTEGER64, r&&)
        END IF
        t = btype(2)
        EXIT FUNCTION
    END IF

    IF o$ = "NOT" THEN
        IF btype(2) AND ISFLOAT THEN
            r&& = _CV(_FLOAT, block(2))
        ELSE
            r&& = _CV(_INTEGER64, block(2))
        END IF
        r&& = NOT r&&
        t = btype(2)
        IF t AND ISFLOAT THEN t = LONGTYPE - ISPOINTER 'markdown to LONG
        evaluateconst$ = _MK$(_INTEGER64, r&&)
        EXIT FUNCTION
    END IF

    Give_Error "Invalid CONST expression.7": EXIT FUNCTION
END IF

'[variable][bool-operator][variable]...

'get first variable
et = btype(1)
ev$ = block(1)

i = 2

evalconstequ:

'get operator
IF i >= n THEN Give_Error "Invalid CONST expression.8": EXIT FUNCTION
o$ = block(i)
i = i + 1
IF isoperator(o$) = 0 THEN Give_Error "Invalid CONST expression.9": EXIT FUNCTION
IF i > n THEN Give_Error "Invalid CONST expression.10": EXIT FUNCTION

'string/numeric mismatch?
IF (btype(i) AND ISSTRING) <> (et AND ISSTRING) THEN Give_Error "Invalid CONST expression.11": EXIT FUNCTION

IF et AND ISSTRING THEN
    IF o$ <> "+" THEN Give_Error "Invalid CONST expression.12": EXIT FUNCTION
    'concat strings
    s1$ = RIGHT$(ev$, LEN(ev$) - 1)
    s1$ = LEFT$(s1$, INSTR(s1$, CHR$(34)) - 1)
    s1size = VAL(RIGHT$(ev$, LEN(ev$) - LEN(s1$) - 3))
    s2$ = RIGHT$(block(i), LEN(block(i)) - 1)
    s2$ = LEFT$(s2$, INSTR(s2$, CHR$(34)) - 1)
    s2size = VAL(RIGHT$(block(i), LEN(block(i)) - LEN(s2$) - 3))
    ev$ = CHR$(34) + s1$ + s2$ + CHR$(34) + "," + str2$(s1size + s2size)
    GOTO econstmarkedup
END IF

'prepare left and right values
IF et AND ISFLOAT THEN
    linteger = 0
    l## = _CV(_FLOAT, ev$)
    l&& = l##
ELSE
    linteger = 1
    l&& = _CV(_INTEGER64, ev$)
    l## = l&&
END IF
IF btype(i) AND ISFLOAT THEN
    rinteger = 0
    r## = _CV(_FLOAT, block(i))
    r&& = r##
ELSE
    rinteger = 1
    r&& = _CV(_INTEGER64, block(i))
    r## = r&&
END IF

IF linteger = 1 AND rinteger = 1 THEN
    IF o$ = "+" THEN r&& = l&& + r&&: GOTO econstmarkupi
    IF o$ = "-" THEN r&& = l&& - r&&: GOTO econstmarkupi
    IF o$ = "*" THEN r&& = l&& * r&&: GOTO econstmarkupi
    IF o$ = "^" THEN r## = l&& ^ r&&: GOTO econstmarkupf
    IF o$ = "/" THEN r## = l&& / r&&: GOTO econstmarkupf
    IF o$ = "\" THEN r&& = l&& \ r&&: GOTO econstmarkupi
    IF o$ = "MOD" THEN r&& = l&& MOD r&&: GOTO econstmarkupi
    IF o$ = "=" THEN r&& = l&& = r&&: GOTO econstmarkupi16
    IF o$ = ">" THEN r&& = l&& > r&&: GOTO econstmarkupi16
    IF o$ = "<" THEN r&& = l&& < r&&: GOTO econstmarkupi16
    IF o$ = ">=" THEN r&& = l&& >= r&&: GOTO econstmarkupi16
    IF o$ = "<=" THEN r&& = l&& <= r&&: GOTO econstmarkupi16
    IF o$ = "<>" THEN r&& = l&& <> r&&: GOTO econstmarkupi16
    IF o$ = "IMP" THEN r&& = l&& IMP r&&: GOTO econstmarkupi
    IF o$ = "EQV" THEN r&& = l&& EQV r&&: GOTO econstmarkupi
    IF o$ = "XOR" THEN r&& = l&& XOR r&&: GOTO econstmarkupi
    IF o$ = "OR" THEN r&& = l&& OR r&&: GOTO econstmarkupi
    IF o$ = "AND" THEN r&& = l&& AND r&&: GOTO econstmarkupi
END IF

IF o$ = "+" THEN r## = l## + r##: GOTO econstmarkupf
IF o$ = "-" THEN r## = l## - r##: GOTO econstmarkupf
IF o$ = "*" THEN r## = l## * r##: GOTO econstmarkupf
IF o$ = "^" THEN r## = l## ^ r##: GOTO econstmarkupf
IF o$ = "/" THEN r## = l## / r##: GOTO econstmarkupf
IF o$ = "\" THEN r&& = l## \ r##: GOTO econstmarkupi32
IF o$ = "MOD" THEN r&& = l## MOD r##: GOTO econstmarkupi32
IF o$ = "=" THEN r&& = l## = r##: GOTO econstmarkupi16
IF o$ = ">" THEN r&& = l## > r##: GOTO econstmarkupi16
IF o$ = "<" THEN r&& = l## < r##: GOTO econstmarkupi16
IF o$ = ">=" THEN r&& = l## >= r##: GOTO econstmarkupi16
IF o$ = "<=" THEN r&& = l## <= r##: GOTO econstmarkupi16
IF o$ = "<>" THEN r&& = l## <> r##: GOTO econstmarkupi16
IF o$ = "IMP" THEN r&& = l## IMP r##: GOTO econstmarkupi32
IF o$ = "EQV" THEN r&& = l## EQV r##: GOTO econstmarkupi32
IF o$ = "XOR" THEN r&& = l## XOR r##: GOTO econstmarkupi32
IF o$ = "OR" THEN r&& = l## OR r##: GOTO econstmarkupi32
IF o$ = "AND" THEN r&& = l## AND r##: GOTO econstmarkupi32

Give_Error "Invalid CONST expression.13": EXIT FUNCTION

econstmarkupi16:
et = INTEGERTYPE - ISPOINTER
ev$ = _MK$(_INTEGER64, r&&)
GOTO econstmarkedup

econstmarkupi32:
et = LONGTYPE - ISPOINTER
ev$ = _MK$(_INTEGER64, r&&)
GOTO econstmarkedup

econstmarkupi:
IF et <> btype(i) THEN
    'keep unsigned?
    u = 0: IF (et AND ISUNSIGNED) <> 0 AND (btype(i) AND ISUNSIGNED) <> 0 THEN u = 1
    lb = et AND 511: rb = btype(i) AND 511
    ob = 0
    IF lb = rb THEN
        IF (et AND ISOFFSETINBITS) <> 0 AND (btype(i) AND ISOFFSETINBITS) <> 0 THEN ob = 1
        b = lb
    END IF
    IF lb > rb THEN
        IF (et AND ISOFFSETINBITS) <> 0 THEN ob = 1
        b = lb
    END IF
    IF lb < rb THEN
        IF (btype(i) AND ISOFFSETINBITS) <> 0 THEN ob = 1
        b = rb
    END IF
    et = b
    IF ob THEN et = et + ISOFFSETINBITS
    IF u THEN et = et + ISUNSIGNED
END IF
ev$ = _MK$(_INTEGER64, r&&)
GOTO econstmarkedup

econstmarkupf:
lfb = 0: rfb = 0
lib = 0: rib = 0
IF et AND ISFLOAT THEN lfb = et AND 511 ELSE lib = et AND 511
IF btype(i) AND ISFLOAT THEN rfb = btype(i) AND 511 ELSE rib = btype(i) AND 511
f = 32
IF lib > 16 OR rib > 16 THEN f = 64
IF lfb > 32 OR rfb > 32 THEN f = 64
IF lib > 32 OR rib > 32 THEN f = 256
IF lfb > 64 OR rfb > 64 THEN f = 256
et = ISFLOAT + f
ev$ = _MK$(_FLOAT, r##)

econstmarkedup:

i = i + 1

IF i <= n THEN GOTO evalconstequ

t = et
evaluateconst$ = ev$

END FUNCTION

FUNCTION typevalue2symbol$ (t)

IF t AND ISSTRING THEN
    IF t AND ISFIXEDLENGTH THEN Give_Error "Cannot convert expression type to symbol": EXIT FUNCTION
    typevalue2symbol$ = "$"
    EXIT FUNCTION
END IF

s$ = ""

IF t AND ISUNSIGNED THEN s$ = "~"

b = t AND 511

IF t AND ISOFFSETINBITS THEN
    IF b > 1 THEN s$ = s$ + "`" + str2$(b) ELSE s$ = s$ + "`"
    typevalue2symbol$ = s$
    EXIT FUNCTION
END IF

IF t AND ISFLOAT THEN
    IF b = 32 THEN s$ = "!"
    IF b = 64 THEN s$ = "#"
    IF b = 256 THEN s$ = "##"
    typevalue2symbol$ = s$
    EXIT FUNCTION
END IF

IF b = 8 THEN s$ = s$ + "%%"
IF b = 16 THEN s$ = s$ + "%"
IF b = 32 THEN s$ = s$ + "&"
IF b = 64 THEN s$ = s$ + "&&"
typevalue2symbol$ = s$

END FUNCTION


FUNCTION id2fulltypename$
t = id.t
IF t = 0 THEN t = id.arraytype
size = id.tsize
bits = t AND 511
IF t AND ISUDT THEN
    a$ = RTRIM$(udtxcname(t AND 511))
    id2fulltypename$ = a$: EXIT FUNCTION
END IF
IF t AND ISSTRING THEN
    IF t AND ISFIXEDLENGTH THEN a$ = "STRING * " + str2(size) ELSE a$ = "STRING"
    id2fulltypename$ = a$: EXIT FUNCTION
END IF
IF t AND ISOFFSETINBITS THEN
    IF bits > 1 THEN a$ = "_BIT * " + str2(bits) ELSE a$ = "_BIT"
    IF t AND ISUNSIGNED THEN a$ = "_UNSIGNED " + a$
    id2fulltypename$ = a$: EXIT FUNCTION
END IF
IF t AND ISFLOAT THEN
    IF bits = 32 THEN a$ = "SINGLE"
    IF bits = 64 THEN a$ = "DOUBLE"
    IF bits = 256 THEN a$ = "_FLOAT"
ELSE 'integer-based
    IF bits = 8 THEN a$ = "_BYTE"
    IF bits = 16 THEN a$ = "INTEGER"
    IF bits = 32 THEN a$ = "LONG"
    IF bits = 64 THEN a$ = "_INTEGER64"
    IF t AND ISUNSIGNED THEN a$ = "_UNSIGNED " + a$
END IF
id2fulltypename$ = a$
END FUNCTION

FUNCTION symbol2fulltypename$ (s2$)
'note: accepts both symbols and type names
s$ = s2$

IF LEFT$(s$, 1) = "~" THEN
    u = 1
    IF LEN(typ$) = 1 THEN Give_Error "Expected ~...": EXIT FUNCTION
    s$ = RIGHT$(s$, LEN(s$) - 1)
    u$ = "_UNSIGNED "
END IF

IF s$ = "%%" THEN t$ = u$ + "_BYTE": GOTO gotsym2typ
IF s$ = "%" THEN t$ = u$ + "INTEGER": GOTO gotsym2typ
IF s$ = "&" THEN t$ = u$ + "LONG": GOTO gotsym2typ
IF s$ = "&&" THEN t$ = u$ + "_INTEGER64": GOTO gotsym2typ
IF s$ = "%&" THEN t$ = u$ + "_OFFSET": GOTO gotsym2typ

IF LEFT$(s$, 1) = "`" THEN
    IF LEN(s$) = 1 THEN
        t$ = u$ + "_BIT * 1"
        GOTO gotsym2typ
    END IF
    n$ = RIGHT$(s$, LEN(s$) - 1)
    IF isuinteger(n$) = 0 THEN Give_Error "Expected number after symbol `": EXIT FUNCTION
    t$ = u$ + "_BIT * " + n$
    GOTO gotsym2typ
END IF

IF u = 1 THEN Give_Error "Expected type symbol after ~": EXIT FUNCTION

IF s$ = "!" THEN t$ = "SINGLE": GOTO gotsym2typ
IF s$ = "#" THEN t$ = "DOUBLE": GOTO gotsym2typ
IF s$ = "##" THEN t$ = "_FLOAT": GOTO gotsym2typ
IF s$ = "$" THEN t$ = "STRING": GOTO gotsym2typ

IF LEFT$(s$, 1) = "$" THEN
    n$ = RIGHT$(s$, LEN(s$) - 1)
    IF isuinteger(n$) = 0 THEN Give_Error "Expected number after symbol $": EXIT FUNCTION
    t$ = "STRING * " + n$
    GOTO gotsym2typ
END IF

t$ = s$

gotsym2typ:

IF RIGHT$(" " + t$, 5) = " _BIT" THEN t$ = t$ + " * 1" 'clarify (_UNSIGNED) _BIT as (_UNSIGNED) _BIT * 1

FOR i = 1 TO LEN(t$)
    IF ASC(t$, i) = ASC(sp) THEN ASC(t$, i) = 32
NEXT

symbol2fulltypename$ = t$

END FUNCTION

SUB lineinput3load (f$)
OPEN f$ FOR BINARY AS #1
l = LOF(1)
lineinput3buffer$ = SPACE$(l)
GET #1, , lineinput3buffer$
IF LEN(lineinput3buffer$) THEN IF RIGHT$(lineinput3buffer$, 1) = CHR$(26) THEN lineinput3buffer$ = LEFT$(lineinput3buffer$, LEN(lineinput3buffer$) - 1)
CLOSE #1
lineinput3index = 1
END SUB

FUNCTION lineinput3$
'returns CHR$(13) if no more lines are available
l = LEN(lineinput3buffer$)
IF lineinput3index > l THEN lineinput3$ = CHR$(13): EXIT FUNCTION
c13 = INSTR(lineinput3index, lineinput3buffer$, CHR$(13))
c10 = INSTR(lineinput3index, lineinput3buffer$, CHR$(10))
IF c10 = 0 AND c13 = 0 THEN
    lineinput3$ = MID$(lineinput3buffer$, lineinput3index, l - lineinput3index + 1)
    lineinput3index = l + 1
    EXIT FUNCTION
END IF
IF c10 = 0 THEN c10 = 2147483647
IF c13 = 0 THEN c13 = 2147483647
IF c10 < c13 THEN
    '10 before 13
    lineinput3$ = MID$(lineinput3buffer$, lineinput3index, c10 - lineinput3index)
    lineinput3index = c10 + 1
    IF lineinput3index <= l THEN
        IF ASC(MID$(lineinput3buffer$, lineinput3index, 1)) = 13 THEN lineinput3index = lineinput3index + 1
    END IF
ELSE
    '13 before 10
    lineinput3$ = MID$(lineinput3buffer$, lineinput3index, c13 - lineinput3index)
    lineinput3index = c13 + 1
    IF lineinput3index <= l THEN
        IF ASC(MID$(lineinput3buffer$, lineinput3index, 1)) = 10 THEN lineinput3index = lineinput3index + 1
    END IF
END IF
END FUNCTION

FUNCTION getfilepath$ (f$)
FOR i = LEN(f$) TO 1 STEP -1
    a$ = MID$(f$, i, 1)
    IF a$ = "/" OR a$ = "\" THEN
        getfilepath$ = LEFT$(f$, i)
        EXIT FUNCTION
    END IF
NEXT
getfilepath$ = ""
END FUNCTION

FUNCTION eleucase$ (a$)
'this function upper-cases all elements except for quoted strings
'check first element
IF LEN(a$) = 0 THEN EXIT FUNCTION
i = 1
IF ASC(a$) = 34 THEN
    i2 = INSTR(a$, sp)
    IF i2 = 0 THEN eleucase$ = a$: EXIT FUNCTION
    a2$ = LEFT$(a$, i2 - 1)
    i = i2
END IF
'check other elements
sp34$ = sp + CHR$(34)
IF i < LEN(a$) THEN
    DO WHILE INSTR(i, a$, sp34$)
        i2 = INSTR(i, a$, sp34$)
        a2$ = a2$ + UCASE$(MID$(a$, i, i2 - i + 1)) 'everything prior including spacer
        i3 = INSTR(i2 + 1, a$, sp): IF i3 = 0 THEN i3 = LEN(a$) ELSE i3 = i3 - 1
        a2$ = a2$ + MID$(a$, i2 + 1, i3 - (i2 + 1) + 1) 'everything from " to before next spacer or end
        i = i3 + 1
        IF i > LEN(a$) THEN EXIT DO
    LOOP
END IF
a2$ = a2$ + UCASE$(MID$(a$, i, LEN(a$) - i + 1))
eleucase$ = a2$
END FUNCTION


SUB SetDependency (requirement)
IF requirement THEN
    DEPENDENCY(requirement) = 1
END IF
END SUB

SUB Build (path$)

'Count the separators in the path
depth = 1
FOR x = 1 TO LEN(path$)
    IF ASC(path$, x) = 92 OR ASC(path$, x) = 47 THEN depth = depth + 1
NEXT
CHDIR path$

bfh = FREEFILE

OPEN "build" + BATCHFILE_EXTENSION FOR BINARY AS #bfh
DO UNTIL EOF(bfh)
    LINE INPUT #bfh, c$
    use = 0
    IF LEN(c$) THEN use = 1
    IF c$ = "pause" THEN use = 0
    IF LEFT$(c$, 1) = "#" THEN use = 0 'eg. #!/bin/sh
    IF LEFT$(c$, 13) = "cd " + CHR$(34) + "$(dirname" THEN use = 0 'eg. cd "$(dirname "$0")"
    IF INSTR(LCASE$(c$), "press any key") THEN EXIT DO
    c$ = GDB_Fix$(c$)
    IF use THEN
        IF os$ = "WIN" THEN
            SHELL _HIDE "cmd /C " + c$
        ELSE
            SHELL _HIDE c$
        END IF
    END IF
LOOP
CLOSE #bfh

return_path$ = ".."
FOR x = 2 TO depth
    return_path$ = return_path$ + "\.."
NEXT
CHDIR return_path$

END SUB

FUNCTION GDB_Fix$ (g_command$) 'edit a gcc/g++ command line to include debugging info
c$ = g_command$
IF Include_GDB_Debugging_Info THEN
    IF LEFT$(c$, 4) = "gcc " OR LEFT$(c$, 4) = "g++ " THEN
        c$ = LEFT$(c$, 4) + " -g " + RIGHT$(c$, LEN(c$) - 4)
        GOTO added_gdb_flag
    END IF
    FOR o = 1 TO 6
        IF o = 1 THEN o$ = "\g++ "
        IF o = 2 THEN o$ = "/g++ "
        IF o = 3 THEN o$ = "\gcc "
        IF o = 4 THEN o$ = "/gcc "
        IF o = 5 THEN o$ = " gcc "
        IF o = 6 THEN o$ = " g++ "
        x = INSTR(UCASE$(c$), UCASE$(o$))
        'note: -g adds debug symbols
        IF x THEN c$ = LEFT$(c$, x - 1) + o$ + " -g " + RIGHT$(c$, LEN(c$) - x - (LEN(o$) - 1)): EXIT FOR
    NEXT
    added_gdb_flag:
    'note: -s strips all debug symbols which is good for size but not for debugging
    x = INSTR(c$, " -s "): IF x THEN c$ = LEFT$(c$, x - 1) + " " + RIGHT$(c$, LEN(c$) - x - 3)
END IF
GDB_Fix$ = c$
END FUNCTION


SUB PATH_SLASH_CORRECT (a$)
IF os$ = "WIN" THEN
    FOR x = 1 TO LEN(a$)
        IF ASC(a$, x) = 47 THEN ASC(a$, x) = 92
    NEXT
ELSE
    FOR x = 1 TO LEN(a$)
        IF ASC(a$, x) = 92 THEN ASC(a$, x) = 47
    NEXT
END IF
END SUB

SUB UseAndroid (Yes)

STATIC inline_DATA_backup
STATIC inline_DATA_backup_set
IF inline_DATA_backup_set = 0 THEN
    inline_DATA_backup_set = 1
    inline_DATA_backup = inline_DATA
END IF

IF Yes THEN
    IF MakeAndroid = 0 THEN
        MakeAndroid = 1
        inline_DATA = 1
        idechangemade = 1
        IDEBuildModeChanged = 1
    END IF
ELSE
    IF MakeAndroid THEN
        MakeAndroid = 0
        inline_DATA = inline_DATA_backup
        idechangemade = 1
        IDEBuildModeChanged = 1
    END IF
END IF

END SUB

'Steve Subs/Functins for _MATH support with CONST
FUNCTION Evaluate_Expression$ (e$)
t$ = e$ 'So we preserve our original data, we parse a temp copy of it

b = INSTR(UCASE$(e$), "EQL") 'take out assignment before the preparser sees it
IF b THEN t$ = MID$(e$, b + 3): var$ = UCASE$(LTRIM$(RTRIM$(MID$(e$, 1, b - 1))))

QuickReturn = 0
PreParse t$

IF QuickReturn THEN Evaluate_Expression$ = t$: EXIT FUNCTION

IF LEFT$(t$, 5) = "ERROR" THEN Evaluate_Expression$ = t$: EXIT FUNCTION

'Deal with brackets first
exp$ = "(" + t$ + ")" 'Starting and finishing brackets for our parse routine.

DO
    Eval_E = INSTR(exp$, ")")
    IF Eval_E > 0 THEN
        c = 0
        DO UNTIL Eval_E - c <= 0
            c = c + 1
            IF Eval_E THEN
                IF MID$(exp$, Eval_E - c, 1) = "(" THEN EXIT DO
            END IF
        LOOP
        s = Eval_E - c + 1
        IF s < 1 THEN PRINT "ERROR -- BAD () Count": END
        eval$ = " " + MID$(exp$, s, Eval_E - s) + " " 'pad with a space before and after so the parser can pick up the values properly.
        ParseExpression eval$

        eval$ = LTRIM$(RTRIM$(eval$))
        IF LEFT$(eval$, 5) = "ERROR" THEN Evaluate_Expression$ = eval$: EXIT SUB
        exp$ = DWD(LEFT$(exp$, s - 2) + eval$ + MID$(exp$, Eval_E + 1))
        IF MID$(exp$, 1, 1) = "N" THEN MID$(exp$, 1) = "-"

        temppp$ = DWD(LEFT$(exp$, s - 2) + " ## " + eval$ + " ## " + MID$(exp$, E + 1))
    END IF
LOOP UNTIL Eval_E = 0
c = 0
DO
    c = c + 1
    SELECT CASE MID$(exp$, c, 1)
        CASE "0" TO "9", ".", "-" 'At this point, we should only have number values left.
        CASE ELSE: Evaluate_Expression$ = "ERROR - Unknown Diagnosis: (" + exp$ + ") ": EXIT SUB
    END SELECT
LOOP UNTIL c >= LEN(exp$)

Evaluate_Expression$ = exp$
END FUNCTION



SUB ParseExpression (exp$)
DIM num(10) AS STRING
'We should now have an expression with no () to deal with
IF MID$(exp$, 2, 1) = "-" THEN exp$ = "0+" + MID$(exp$, 2)
FOR J = 1 TO 250
    lowest = 0
    DO UNTIL lowest = LEN(exp$)
        lowest = LEN(exp$): OpOn = 0
        FOR P = 1 TO UBOUND(OName)
            'Look for first valid operator
            IF J = PL(P) THEN 'Priority levels match
                IF LEFT$(exp$, 1) = "-" THEN op = INSTR(2, exp$, OName(P)) ELSE op = INSTR(exp$, OName(P))
                IF op > 0 AND op < lowest THEN lowest = op: OpOn = P
            END IF
        NEXT
        IF OpOn = 0 THEN EXIT DO 'We haven't gotten to the proper PL for this OP to be processed yet.
        IF LEFT$(exp$, 1) = "-" THEN op = INSTR(2, exp$, OName(OpOn)) ELSE op = INSTR(exp$, OName(OpOn))
        numset = 0

        '*** SPECIAL OPERATION RULESETS
        IF OName(OpOn) = "-" THEN 'check for BOOLEAN operators before the -
            SELECT CASE MID$(exp$, op - 3, 3)
                CASE "NOT", "XOR", "AND", "EQV", "IMP"
                    EXIT DO 'Not an operator, it's a negative
            END SELECT
            IF MID$(exp$, op - 3, 2) = "OR" THEN EXIT DO 'Not an operator, it's a negative
        END IF

        IF op THEN
            c = LEN(OName(OpOn)) - 1
            DO
                SELECT CASE MID$(exp$, op + c + 1, 1)
                    CASE "0", "1", "2", "3", "4", "5", "6", "7", "8", "9", ".", "N": numset = -1 'Valid digit
                    CASE "-" 'We need to check if it's a minus or a negative
                        IF OName(OpOn) = "PI" OR numset THEN EXIT DO
                    CASE ELSE 'Not a valid digit, we found our separator
                        EXIT DO
                END SELECT
                c = c + 1
            LOOP UNTIL op + c >= LEN(exp$)
            E = op + c

            c = 0
            DO
                c = c + 1
                SELECT CASE MID$(exp$, op - c, 1)
                    CASE "0", "1", "2", "3", "4", "5", "6", "7", "8", "9", ".", "N" 'Valid digit
                    CASE "-" 'We need to check if it's a minus or a negative
                        c1 = c
                        bad = 0
                        DO
                            c1 = c1 + 1
                            SELECT CASE MID$(exp$, op - c1, 1)
                                CASE "0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "."
                                    bad = -1
                                    EXIT DO 'It's a minus sign
                                CASE ELSE
                                    'It's a negative sign and needs to count as part of our numbers
                            END SELECT
                        LOOP UNTIL op - c1 <= 0
                        IF bad THEN EXIT DO 'We found our seperator
                    CASE ELSE 'Not a valid digit, we found our separator
                        EXIT DO
                END SELECT
            LOOP UNTIL op - c <= 0
            s = op - c
            num(1) = MID$(exp$, s + 1, op - s - 1) 'Get our first number
            num(2) = MID$(exp$, op + LEN(OName(OpOn)), E - op - LEN(OName(OpOn)) + 1) 'Get our second number
            IF MID$(num(1), 1, 1) = "N" THEN MID$(num(1), 1) = "-"
            IF MID$(num(2), 1, 1) = "N" THEN MID$(num(2), 1) = "-"
            num(3) = EvaluateNumbers(OpOn, num())
            IF MID$(num(3), 1, 1) = "-" THEN MID$(num(3), 1) = "N"
            'PRINT "*************"
            'PRINT num(1), OName(OpOn), num(2), num(3), exp$
            IF LEFT$(num(3), 5) = "ERROR" THEN exp$ = num(3): EXIT SUB
            exp$ = LTRIM$(N2S(DWD(LEFT$(exp$, s) + RTRIM$(LTRIM$(num(3))) + MID$(exp$, E + 1))))
            'PRINT exp$
        END IF
        op = 0
    LOOP
NEXT

END SUB



SUB Set_OrderOfOperations
'PL sets our priortity level. 1 is highest to 65535 for the lowest.
'I used a range here so I could add in new priority levels as needed.
'OName ended up becoming the name of our commands, as I modified things.... Go figure!  LOL!

'Constants get evaluated first, with a Priority Level of 1
i = i + 1: REDIM _PRESERVE OName(i): OName(i) = "PI"
REDIM _PRESERVE PL(i): PL(i) = 1
'I'm not certain where exactly percentages should go.  They kind of seem like a special case to me.  COS10% should be COS.1 I'd think...
'I'm putting it here for now, and if anyone knows someplace better for it in our order of operations, let me know.
i = i + 1: REDIM _PRESERVE OName(i): OName(i) = "%"
REDIM _PRESERVE PL(i): PL(i) = 5
'Then Functions with PL 10
i = i + 1: REDIM _PRESERVE OName(i): OName(i) = "ARCCOS"
REDIM _PRESERVE PL(i): PL(i) = 10
i = i + 1: REDIM _PRESERVE OName(i): OName(i) = "ARCSIN"
REDIM _PRESERVE PL(i): PL(i) = 10
i = i + 1: REDIM _PRESERVE OName(i): OName(i) = "ARCSEC"
REDIM _PRESERVE PL(i): PL(i) = 10
i = i + 1: REDIM _PRESERVE OName(i): OName(i) = "ARCCSC"
REDIM _PRESERVE PL(i): PL(i) = 10
i = i + 1: REDIM _PRESERVE OName(i): OName(i) = "ARCCOT"
REDIM _PRESERVE PL(i): PL(i) = 10
i = i + 1: REDIM _PRESERVE OName(i): OName(i) = "SECH"
REDIM _PRESERVE PL(i): PL(i) = 10
i = i + 1: REDIM _PRESERVE OName(i): OName(i) = "CSCH"
REDIM _PRESERVE PL(i): PL(i) = 10
i = i + 1: REDIM _PRESERVE OName(i): OName(i) = "COTH"
REDIM _PRESERVE PL(i): PL(i) = 10
i = i + 1: REDIM _PRESERVE OName(i): OName(i) = "COS"
REDIM _PRESERVE PL(i): PL(i) = 10
i = i + 1: REDIM _PRESERVE OName(i): OName(i) = "SIN"
REDIM _PRESERVE PL(i): PL(i) = 10
i = i + 1: REDIM _PRESERVE OName(i): OName(i) = "TAN"
REDIM _PRESERVE PL(i): PL(i) = 10
i = i + 1: REDIM _PRESERVE OName(i): OName(i) = "LOG"
REDIM _PRESERVE PL(i): PL(i) = 10
i = i + 1: REDIM _PRESERVE OName(i): OName(i) = "EXP"
REDIM _PRESERVE PL(i): PL(i) = 10
i = i + 1: REDIM _PRESERVE OName(i): OName(i) = "ATN"
REDIM _PRESERVE PL(i): PL(i) = 10
i = i + 1: REDIM _PRESERVE OName(i): OName(i) = "D2R"
REDIM _PRESERVE PL(i): PL(i) = 10
i = i + 1: REDIM _PRESERVE OName(i): OName(i) = "D2G"
REDIM _PRESERVE PL(i): PL(i) = 10
i = i + 1: REDIM _PRESERVE OName(i): OName(i) = "R2D"
REDIM _PRESERVE PL(i): PL(i) = 10
i = i + 1: REDIM _PRESERVE OName(i): OName(i) = "R2G"
REDIM _PRESERVE PL(i): PL(i) = 10
i = i + 1: REDIM _PRESERVE OName(i): OName(i) = "G2D"
REDIM _PRESERVE PL(i): PL(i) = 10
i = i + 1: REDIM _PRESERVE OName(i): OName(i) = "G2R"
REDIM _PRESERVE PL(i): PL(i) = 10
i = i + 1: REDIM _PRESERVE OName(i): OName(i) = "ABS"
REDIM _PRESERVE PL(i): PL(i) = 10
i = i + 1: REDIM _PRESERVE OName(i): OName(i) = "SGN"
REDIM _PRESERVE PL(i): PL(i) = 10
i = i + 1: REDIM _PRESERVE OName(i): OName(i) = "INT"
REDIM _PRESERVE PL(i): PL(i) = 10
i = i + 1: REDIM _PRESERVE OName(i): OName(i) = "_ROUND"
REDIM _PRESERVE PL(i): PL(i) = 10
i = i + 1: REDIM _PRESERVE OName(i): OName(i) = "FIX"
REDIM _PRESERVE PL(i): PL(i) = 10
i = i + 1: REDIM _PRESERVE OName(i): OName(i) = "SEC"
REDIM _PRESERVE PL(i): PL(i) = 10
i = i + 1: REDIM _PRESERVE OName(i): OName(i) = "CSC"
REDIM _PRESERVE PL(i): PL(i) = 10
i = i + 1: REDIM _PRESERVE OName(i): OName(i) = "COT"
REDIM _PRESERVE PL(i): PL(i) = 10
'Exponents with PL 20
i = i + 1: REDIM _PRESERVE OName(i): OName(i) = "^"
REDIM _PRESERVE PL(i): PL(i) = 20
i = i + 1: REDIM _PRESERVE OName(i): OName(i) = "SQR"
REDIM _PRESERVE PL(i): PL(i) = 20
i = i + 1: REDIM _PRESERVE OName(i): OName(i) = "ROOT"
REDIM _PRESERVE PL(i): PL(i) = 20
'Multiplication and Division PL 30
i = i + 1: REDIM _PRESERVE OName(i): OName(i) = "*"
REDIM _PRESERVE PL(i): PL(i) = 30
i = i + 1: REDIM _PRESERVE OName(i): OName(i) = "/"
REDIM _PRESERVE PL(i): PL(i) = 30
i = i + 1: REDIM _PRESERVE OName(i): OName(i) = "BTM"
REDIM _PRESERVE PL(i): PL(i) = 30
'Integer Division PL 40
i = i + 1: REDIM _PRESERVE OName(i): OName(i) = "\"
REDIM _PRESERVE PL(i): PL(i) = 40
'MOD PL 50
i = i + 1: REDIM _PRESERVE OName(i): OName(i) = "MOD"
REDIM _PRESERVE PL(i): PL(i) = 50
'Addition and Subtraction PL 60
i = i + 1: REDIM _PRESERVE OName(i): OName(i) = "+"
REDIM _PRESERVE PL(i): PL(i) = 60
i = i + 1: REDIM _PRESERVE OName(i): OName(i) = "-"
REDIM _PRESERVE PL(i): PL(i) = 60
i = i + 1: REDIM _PRESERVE OName(i): OName(i) = "BTA"
REDIM _PRESERVE PL(i): PL(i) = 60
i = i + 1: REDIM _PRESERVE OName(i): OName(i) = "BTS"
REDIM _PRESERVE PL(i): PL(i) = 60

'Relational Operators =, >, <, <>, <=, >=   PL 70
i = i + 1: REDIM _PRESERVE OName(i): OName(i) = "<>"
REDIM _PRESERVE PL(i): PL(i) = 70
i = i + 1: REDIM _PRESERVE OName(i): OName(i) = "><" 'These next three are just reversed symbols as an attempt to help process a common typo
REDIM _PRESERVE PL(i): PL(i) = 70
i = i + 1: REDIM _PRESERVE OName(i): OName(i) = "<="
REDIM _PRESERVE PL(i): PL(i) = 70
i = i + 1: REDIM _PRESERVE OName(i): OName(i) = ">="
REDIM _PRESERVE PL(i): PL(i) = 70
i = i + 1: REDIM _PRESERVE OName(i): OName(i) = "=<" 'I personally can never keep these things straight.  Is it < = or = <...
REDIM _PRESERVE PL(i): PL(i) = 70
i = i + 1: REDIM _PRESERVE OName(i): OName(i) = "=>" 'Who knows, check both!
REDIM _PRESERVE PL(i): PL(i) = 70
i = i + 1: REDIM _PRESERVE OName(i): OName(i) = ">"
REDIM _PRESERVE PL(i): PL(i) = 70
i = i + 1: REDIM _PRESERVE OName(i): OName(i) = "<"
REDIM _PRESERVE PL(i): PL(i) = 70
i = i + 1: REDIM _PRESERVE OName(i): OName(i) = "="
REDIM _PRESERVE PL(i): PL(i) = 70
'Logical Operations PL 80+
i = i + 1: REDIM _PRESERVE OName(i): OName(i) = "NOT"
REDIM _PRESERVE PL(i): PL(i) = 80
i = i + 1: REDIM _PRESERVE OName(i): OName(i) = "AND"
REDIM _PRESERVE PL(i): PL(i) = 90
i = i + 1: REDIM _PRESERVE OName(i): OName(i) = "OR"
REDIM _PRESERVE PL(i): PL(i) = 100
i = i + 1: REDIM _PRESERVE OName(i): OName(i) = "XOR"
REDIM _PRESERVE PL(i): PL(i) = 110
i = i + 1: REDIM _PRESERVE OName(i): OName(i) = "EQV"
REDIM _PRESERVE PL(i): PL(i) = 120
i = i + 1: REDIM _PRESERVE OName(i): OName(i) = "IMP"
REDIM _PRESERVE PL(i): PL(i) = 130

END SUB

FUNCTION EvaluateNumbers$ (p, num() AS STRING)
DIM n1 AS _FLOAT, n2 AS _FLOAT, n3 AS _FLOAT
SELECT CASE OName(p) 'Depending on our operator..
    CASE "PI"
        n1 = 3.14159265358979323846264338327950288## 'Future compatable in case something ever stores extra digits for PI
    CASE "%" 'Note percent is a special case and works with the number BEFORE the % command and not after
        IF num(1) = "" THEN EvaluateNumbers$ = "ERROR - Attemping to get percent of NULL string": EXIT FUNCTION
        n1 = (VAL(num(1))) / 100
    CASE "ARCCOS"
        IF num(2) = "" THEN EvaluateNumbers$ = "ERROR - Attemping to get ARCCOS of NULL string": EXIT FUNCTION
        n1 = VAL(num(2))
        IF n1 > 1 THEN EvaluateNumbers$ = "ERROR - Attemping to get ARCCOS from value >1, which is Invalid": EXIT FUNCTION
        IF n1 < -1 THEN EvaluateNumbers$ = "ERROR - Attemping to get ARCCOS from value <-1, which is Invalid": EXIT FUNCTION
        IF n1 = 1 THEN EvaluateNumbers$ = "0": EXIT FUNCTION
        n1 = (2 * ATN(1)) - ATN(n1 / SQR(1 - n1 * n1))
    CASE "ARCSIN"
        IF num(2) = "" THEN EvaluateNumbers$ = "ERROR - Attemping to get ARCSIN of NULL string": EXIT FUNCTION
        n1 = VAL(num(2))
        IF n1 > 1 THEN EvaluateNumbers$ = "ERROR - Attemping to get ARCSIN from value >1, which is Invalid": EXIT FUNCTION
        IF n1 < -1 THEN EvaluateNumbers$ = "ERROR - Attemping to get ARCSIN from value <-1, which is Invalid": EXIT FUNCTION
        n1 = ATN(n1 / SQR(1 - (n1 * n1)))
    CASE "ARCSEC"
        IF num(2) = "" THEN EvaluateNumbers$ = "ERROR - Attemping to get ARCSEC of NULL string": EXIT FUNCTION
        n1 = VAL(num(2))
        IF n1 > 1 THEN EvaluateNumbers$ = "ERROR - Attemping to get ARCSEC from value > 1, which is Invalid": EXIT FUNCTION
        IF n1 < -1 THEN EvaluateNumbers$ = "ERROR - Attemping to get ARCSEC from value < -1, which is Invalid": EXIT FUNCTION
        n1 = ATN(n1 / SQR(1 - n1 * n1)) + (SGN(n1) - 1) * (2 * ATN(1))
    CASE "ARCCSC"
        IF num(2) = "" THEN EvaluateNumbers$ = "ERROR - Attemping to get ARCCSC of NULL string": EXIT FUNCTION
        n1 = VAL(num(2))
        IF n1 > 1 THEN EvaluateNumbers$ = "ERROR - Attemping to get ARCCSC from value >=1, which is Invalid": EXIT FUNCTION
        IF n1 < -1 THEN EvaluateNumbers$ = "ERROR - Attemping to get ARCCSC from value <-1, which is Invalid": EXIT FUNCTION
        n1 = ATN(1 / SQR(1 - n1 * n1)) + (SGN(n1) - 1) * (2 * ATN(1))
    CASE "ARCCOT"
        IF num(2) = "" THEN EvaluateNumbers$ = "ERROR - Attemping to get ARCCOT of NULL string": EXIT FUNCTION
        n1 = VAL(num(2))
        n1 = (2 * ATN(1)) - ATN(n1)
    CASE "SECH"
        IF num(2) = "" THEN EvaluateNumbers$ = "ERROR - Attemping to get SECH of NULL string": EXIT FUNCTION
        n1 = VAL(num(2))
        IF n1 > 88.02969 OR (EXP(n1) + EXP(-n1)) = 0 THEN EvaluateNumbers$ = "ERROR - Bad SECH command": EXIT FUNCTION
        n1 = 2 / (EXP(n1) + EXP(-n1))
    CASE "CSCH"
        IF num(2) = "" THEN EvaluateNumbers$ = "ERROR - Attemping to get CSCH of NULL string": EXIT FUNCTION
        n1 = VAL(num(2))
        IF n1 > 88.02969 OR (EXP(n1) - EXP(-n1)) = 0 THEN EvaluateNumbers$ = "ERROR - Bad CSCH command": EXIT FUNCTION
        n1 = 2 / (EXP(n1) - EXP(-n1))
    CASE "COTH"
        IF num(2) = "" THEN EvaluateNumbers$ = "ERROR - Attemping to get COTH of NULL string": EXIT FUNCTION
        n1 = VAL(num(2))
        IF 2 * n1 > 88.02969 OR EXP(2 * n1) - 1 = 0 THEN EvaluateNumbers$ = "ERROR - Bad COTH command": EXIT FUNCTION
        n1 = (EXP(2 * n1) + 1) / (EXP(2 * n1) - 1)
    CASE "COS"
        IF num(2) = "" THEN EvaluateNumbers$ = "ERROR - Attemping to get COS of NULL string": EXIT FUNCTION
        n1 = COS(VAL(num(2)))
    CASE "SIN"
        IF num(2) = "" THEN EvaluateNumbers$ = "ERROR - Attemping to get SIN of NULL string": EXIT FUNCTION
        n1 = SIN(VAL(num(2)))
    CASE "TAN"
        IF num(2) = "" THEN EvaluateNumbers$ = "ERROR - Attemping to get TAN of NULL string": EXIT FUNCTION
        n1 = TAN(VAL(num(2)))
    CASE "LOG"
        IF num(2) = "" THEN EvaluateNumbers$ = "ERROR - Attemping to get LOG of NULL string": EXIT FUNCTION
        n1 = LOG(VAL(num(2)))
    CASE "EXP"
        IF num(2) = "" THEN EvaluateNumbers$ = "ERROR - Attemping to get EXP of NULL string": EXIT FUNCTION
        n1 = EXP(VAL(num(2)))
    CASE "ATN"
        IF num(2) = "" THEN EvaluateNumbers$ = "ERROR - Attemping to get ATN of NULL string": EXIT FUNCTION
        n1 = ATN(VAL(num(2)))
    CASE "D2R"
        IF num(2) = "" THEN EvaluateNumbers$ = "ERROR - Attemping to get Radian of NULL Degree value": EXIT FUNCTION
        n1 = 0.0174532925 * (VAL(num(2)))
    CASE "D2G"
        IF num(2) = "" THEN EvaluateNumbers$ = "ERROR - Attemping to get Grad of NULL Degree string": EXIT FUNCTION
        n1 = 1.1111111111 * (VAL(num(2)))
    CASE "R2D"
        IF num(2) = "" THEN EvaluateNumbers$ = "ERROR - Attemping to get Degree of NULL Radian string": EXIT FUNCTION
        n1 = 57.2957795 * (VAL(num(2)))
    CASE "R2G"
        IF num(2) = "" THEN EvaluateNumbers$ = "ERROR - Attemping to get Grad of NULL Radian string": EXIT FUNCTION
        n1 = 0.015707963 * (VAL(num(2)))
    CASE "G2D"
        IF num(2) = "" THEN EvaluateNumbers$ = "ERROR - Attemping to get Degree of NULL Gradian string": EXIT FUNCTION
        n1 = 0.9 * (VAL(num(2)))
    CASE "G2R"
        IF num(2) = "" THEN EvaluateNumbers$ = "ERROR - Attemping to get Radian of NULL Grad string": EXIT FUNCTION
        n1 = 63.661977237 * (VAL(num(2)))
    CASE "ABS"
        IF num(2) = "" THEN EvaluateNumbers$ = "ERROR - Attemping to get ABS of NULL string": EXIT FUNCTION
        n1 = ABS(VAL(num(2)))
    CASE "SGN"
        IF num(2) = "" THEN EvaluateNumbers$ = "ERROR - Attemping to get SGN of NULL string": EXIT FUNCTION
        n1 = SGN(VAL(num(2)))
    CASE "INT"
        IF num(2) = "" THEN EvaluateNumbers$ = "ERROR - Attemping to get INT of NULL string": EXIT FUNCTION
        n1 = INT(VAL(num(2)))
    CASE "_ROUND"
        IF num(2) = "" THEN EvaluateNumbers$ = "ERROR - Attemping to _ROUND a NULL string": EXIT FUNCTION
        n1 = _ROUND(VAL(num(2)))
    CASE "FIX"
        IF num(2) = "" THEN EvaluateNumbers$ = "ERROR - Attemping to FIX a NULL string": EXIT FUNCTION
        n1 = FIX(VAL(num(2)))
    CASE "SEC"
        IF num(2) = "" THEN EvaluateNumbers$ = "ERROR - Attemping to get SEC of NULL string": EXIT FUNCTION
        n1 = COS(VAL(num(2)))
        IF n1 = 0 THEN EvaluateNumbers$ = "ERROR - COS value is 0, thus SEC is 1/0 which is Invalid": EXIT FUNCTION
        n1 = 1 / n1
    CASE "CSC"
        IF num(2) = "" THEN EvaluateNumbers$ = "ERROR - Attemping to get CSC of NULL string": EXIT FUNCTION
        n1 = SIN(VAL(num(2)))
        IF n1 = 0 THEN EvaluateNumbers$ = "ERROR - SIN value is 0, thus CSC is 1/0 which is Invalid": EXIT FUNCTION
        n1 = 1 / n1
    CASE "COT"
        IF num(2) = "" THEN EvaluateNumbers$ = "ERROR - Attemping to get COT of NULL string": EXIT FUNCTION
        n1 = COS(VAL(num(2)))
        IF n1 = 0 THEN EvaluateNumbers$ = "ERROR - TAN value is 0, thus COT is 1/0 which is Invalid": EXIT FUNCTION
        n1 = 1 / n1
    CASE "BTA"
        IF num(2) = "" OR num(1) = "" THEN EvaluateNumbers$ = "ERROR - BTA": EXIT FUNCTION
        EvaluateNumbers$ = BTen$(num(1), "+", num(2)): EXIT FUNCTION
    CASE "BTS"
        IF num(2) = "" OR num(1) = "" THEN EvaluateNumbers$ = "ERROR - BTS": EXIT FUNCTION
        EvaluateNumbers$ = BTen$(num(1), "-", num(2)): EXIT FUNCTION
    CASE "BTM"
        IF num(2) = "" OR num(1) = "" THEN EvaluateNumbers$ = "ERROR - BTM": EXIT FUNCTION
        EvaluateNumbers$ = BTen$(num(1), "*", num(2)): EXIT FUNCTION
    CASE "^"
        IF num(1) = "" THEN EvaluateNumbers$ = "ERROR - Attemping to raise NULL string to exponent": EXIT FUNCTION
        IF num(2) = "" THEN EvaluateNumbers$ = "ERROR - Attemping to raise number to NULL exponent": EXIT FUNCTION
        n1 = VAL(num(1)) ^ VAL(num(2))
    CASE "SQR"
        IF num(2) = "" THEN EvaluateNumbers$ = "ERROR - Attemping to get SQR of NULL string": EXIT FUNCTION
        IF VAL(num(2)) < 0 THEN EvaluateNumbers$ = "ERROR - Cannot take take SQR of numbers < 0.  I'm a computer, I have a poor imagination.": EXIT FUNCTION
        n1 = SQR(VAL(num(2)))
    CASE "ROOT"
        IF num(1) = "" THEN EvaluateNumbers$ = "ERROR - Attemping to get ROOT of a NULL string": EXIT FUNCTION
        IF num(2) = "" THEN EvaluateNumbers$ = "ERROR - Attemping to get NULL ROOT of a string": EXIT FUNCTION
        n1 = VAL(num(1)): n2 = VAL(num(2))
        IF n2 = 1 THEN EvaluateNumbers$ = RTRIM$(LTRIM$(STR$(n1))): EXIT FUNCTION
        IF n2 = 0 THEN EvaluateNumbers$ = "ERROR - There is no such thing as a 0 ROOT of a number": EXIT FUNCTION
        IF n1 < 0 AND n2 MOD 2 = 0 AND n2 > 1 THEN EvaluateNumbers$ = "ERROR - Cannot take take an EVEN ROOT of numbers < 0.  I'm a computer, I have a poor imagination.": EXIT FUNCTION
        IF n1 < 0 AND n2 >= 1 THEN sign = -1: n1 = -n1 ELSE sign = 1
        n3 = 1## / n2
        IF n3 <> INT(n3) AND n2 < 1 THEN sign = SGN(n1): n1 = ABS(n1)
        n1 = sign * (n1 ^ n3)
    CASE "*"
        IF num(1) = "" OR num(2) = "" THEN EvaluateNumbers$ = "ERROR - Attemping to multiply NULL string ": EXIT FUNCTION
        n1 = VAL(num(1)) * VAL(num(2))
    CASE "/":
        IF num(1) = "" OR num(2) = "" THEN EvaluateNumbers$ = "ERROR - Attemping to divide NULL string ": EXIT FUNCTION
        IF VAL(num(2)) = 0 THEN EvaluateNumbers$ = "ERROR - Division by 0": EXIT FUNCTION
        n1 = VAL(num(1)) / VAL(num(2))
    CASE "\"
        IF num(1) = "" OR num(2) = "" THEN EvaluateNumbers$ = "ERROR - Attemping to divide NULL string ": EXIT FUNCTION
        IF VAL(num(2)) = 0 THEN EvaluateNumbers$ = "ERROR - Division by 0": EXIT FUNCTION
        n1 = VAL(num(1)) \ VAL(num(2))
    CASE "MOD"
        IF num(1) = "" OR num(2) = "" THEN EvaluateNumbers$ = "ERROR - Attemping to MOD with NULL string ": EXIT FUNCTION
        IF VAL(num(2)) = 0 THEN EvaluateNumbers$ = "ERROR - Division by 0": EXIT FUNCTION
        n1 = VAL(num(1)) MOD VAL(num(2))
    CASE "+": n1 = VAL(num(1)) + VAL(num(2))
    CASE "-": n1 = VAL(num(1)) - VAL(num(2))
    CASE "=": n1 = VAL(num(1)) = VAL(num(2))
    CASE ">": n1 = VAL(num(1)) > VAL(num(2))
    CASE "<": n1 = VAL(num(1)) < VAL(num(2))
    CASE "<>", "><": n1 = VAL(num(1)) <> VAL(num(2))
    CASE "<=", "=<": n1 = VAL(num(1)) <= VAL(num(2))
    CASE ">=", "=>": n1 = VAL(num(1)) >= VAL(num(2))
    CASE "NOT": n1 = NOT VAL(num(2))
    CASE "AND": n1 = VAL(num(1)) AND VAL(num(2))
    CASE "OR": n1 = VAL(num(1)) OR VAL(num(2))
    CASE "XOR": n1 = VAL(num(1)) XOR VAL(num(2))
    CASE "EQV": n1 = VAL(num(1)) EQV VAL(num(2))
    CASE "IMP": n1 = VAL(num(1)) IMP VAL(num(2))
    CASE ELSE
        EvaluateNumbers$ = "ERROR - Bad operation (We shouldn't see this)" 'Let's say we're bad...
END SELECT
EvaluateNumbers$ = RTRIM$(LTRIM$(STR$(n1)))
END FUNCTION

FUNCTION DWD$ (exp$) 'Deal With Duplicates
'To deal with duplicate operators in our code.
'Such as --  becomes a +
'++ becomes a +
'+- becomes a -
'-+ becomes a -
t$ = exp$
DO
    bad = 0
    DO
        l = INSTR(t$, "++")
        IF l THEN t$ = LEFT$(t$, l - 1) + "+" + MID$(t$, l + 2): bad = -1
    LOOP UNTIL l = 0
    DO
        l = INSTR(t$, "+-")
        IF l THEN t$ = LEFT$(t$, l - 1) + "-" + MID$(t$, l + 2): bad = -1
    LOOP UNTIL l = 0
    DO
        l = INSTR(t$, "-+")
        IF l THEN t$ = LEFT$(t$, l - 1) + "-" + MID$(t$, l + 2): bad = -1
    LOOP UNTIL l = 0
    DO
        l = INSTR(t$, "--")
        IF l THEN t$ = LEFT$(t$, l - 1) + "+" + MID$(t$, l + 2): bad = -1
    LOOP UNTIL l = 0
LOOP UNTIL NOT bad
DWD$ = t$
VerifyString t$
END FUNCTION

SUB PreParse (e$)
DIM f AS _FLOAT

t$ = e$

'First strip all spaces
t$ = ""
FOR i = 1 TO LEN(e$)
    IF MID$(e$, i, 1) <> " " THEN t$ = t$ + MID$(e$, i, 1)
NEXT

t$ = UCASE$(t$)
IF t$ = "" THEN e$ = "ERROR -- NULL string; nothing to evaluate": EXIT SUB

'ERROR CHECK by counting our brackets
l = 0
DO
    l = INSTR(l + 1, t$, "("): IF l THEN c = c + 1
LOOP UNTIL l = 0
l = 0
DO
    l = INSTR(l + 1, t$, ")"): IF l THEN c1 = c1 + 1
LOOP UNTIL l = 0
IF c <> c1 THEN e$ = "ERROR -- Bad Parenthesis:" + STR$(c) + "( vs" + STR$(c1) + ")": EXIT SUB

'Modify so that NOT will process properly
l = 0
DO
    l = INSTR(l + 1, t$, "NOT")
    IF l THEN
        'We need to work magic on the statement so it looks pretty.
        ' 1 + NOT 2 + 1 is actually processed as 1 + (NOT 2 + 1)
        'Look for something not proper
        l1 = INSTR(l + 1, t$, "AND")
        IF l1 = 0 OR (INSTR(l + 1, t$, "OR") > 0 AND INSTR(l + 1, t$, "OR") < l1) THEN l1 = INSTR(l + 1, t$, "OR")
        IF l1 = 0 OR (INSTR(l + 1, t$, "XOR") > 0 AND INSTR(l + 1, t$, "XOR") < l1) THEN l1 = INSTR(l + 1, t$, "XOR")
        IF l1 = 0 OR (INSTR(l + 1, t$, "EQV") > 0 AND INSTR(l + 1, t$, "EQV") < l1) THEN l1 = INSTR(l + 1, t$, "EQV")
        IF l1 = 0 OR (INSTR(l + 1, t$, "IMP") > 0 AND INSTR(l + 1, t$, "IMP") < l1) THEN l1 = INSTR(l + 1, t$, "IMP")
        IF l1 = 0 THEN l1 = LEN(t$) + 1
        t$ = LEFT$(t$, l - 1) + "(" + MID$(t$, l, l1 - l) + ")" + MID$(t$, l + l1 - l)
        l = l + 3
        'PRINT t$
    END IF
LOOP UNTIL l = 0

'Check for bad operators before a ( bracket
l = 0
DO
    l = INSTR(l + 1, t$, "(")
    IF l AND l > 2 THEN 'Don't check the starting bracket; there's nothing before it.
        good = 0
        FOR i = 1 TO UBOUND(OName)
            IF MID$(t$, l - LEN(OName(i)), LEN(OName(i))) = OName(i) AND PL(i) > 1 AND PL(i) <= 250 THEN good = -1: EXIT FOR 'We found an operator after our ), and it's not a CONST (like PI)
        NEXT
        IF NOT good THEN e$ = "ERROR - Improper operations before (.": EXIT SUB
        l = l + 1
    END IF
LOOP UNTIL l = 0

'Check for bad operators after a ) bracket
l = 0
DO
    l = INSTR(l + 1, t$, ")")
    IF l AND l < LEN(t$) THEN
        good = 0
        FOR i = 1 TO UBOUND(OName)
            IF MID$(t$, l + 1, LEN(OName(i))) = OName(i) AND PL(i) > 1 AND PL(i) <= 250 THEN good = -1: EXIT FOR 'We found an operator after our ), and it's not a CONST (like PI)
        NEXT
        IF MID$(t$, l + 1, 1) = ")" THEN good = -1
        IF NOT good THEN e$ = "ERROR - Improper operations after ).": EXIT SUB
        l = l + 1
    END IF
LOOP UNTIL l = 0 OR l = LEN(t$) 'last symbol is a bracket

'Turn all &H (hex) numbers into decimal values for the program to process properly
l = 0
DO
    l = INSTR(t$, "&H")
    IF l THEN
        E = l + 1: finished = 0
        DO
            E = E + 1
            comp$ = MID$(t$, E, 1)
            SELECT CASE comp$
                CASE "0" TO "9", "A" TO "F" 'All is good, our next digit is a number, continue to add to the hex$
                CASE ELSE
                    good = 0
                    FOR i = 1 TO UBOUND(OName)
                        IF MID$(t$, E, LEN(OName(i))) = OName(i) AND PL(i) > 1 AND PL(i) <= 250 THEN good = -1: EXIT FOR 'We found an operator after our ), and it's not a CONST (like PI)
                    NEXT
                    IF NOT good THEN e$ = "ERROR - Improper &H value. (" + comp$ + ")": EXIT SUB
                    E = E - 1
                    finished = -1
            END SELECT
        LOOP UNTIL finished OR E = LEN(t$)
        t$ = LEFT$(t$, l - 1) + LTRIM$(RTRIM$(STR$(VAL(MID$(t$, l, E - l + 1))))) + MID$(t$, E + 1)
    END IF
LOOP UNTIL l = 0

'Turn all &B (binary) numbers into decimal values for the program to process properly
l = 0
DO
    l = INSTR(t$, "&B")
    IF l THEN
        E = l + 1: finished = 0
        DO
            E = E + 1
            comp$ = MID$(t$, E, 1)
            SELECT CASE comp$
                CASE "0", "1" 'All is good, our next digit is a number, continue to add to the hex$
                CASE ELSE
                    good = 0
                    FOR i = 1 TO UBOUND(OName)
                        IF MID$(t$, E, LEN(OName(i))) = OName(i) AND PL(i) > 1 AND PL(i) <= 250 THEN good = -1: EXIT FOR 'We found an operator after our ), and it's not a CONST (like PI)
                    NEXT
                    IF NOT good THEN e$ = "ERROR - Improper &B value. (" + comp$ + ")": EXIT SUB
                    E = E - 1
                    finished = -1
            END SELECT
        LOOP UNTIL finished OR E = LEN(t$)
        bin$ = MID$(t$, l + 2, E - l - 1)
        FOR i = 1 TO LEN(bin$)
            IF MID$(bin$, i, 1) = "1" THEN f = f + 2 ^ (LEN(bin$) - i)
        NEXT
        t$ = LEFT$(t$, l - 1) + LTRIM$(RTRIM$(STR$(f))) + MID$(t$, E + 1)
    END IF
LOOP UNTIL l = 0

t$ = N2S(t$)
VerifyString t$

e$ = t$
END SUB



SUB VerifyString (t$)
'ERROR CHECK for unrecognized operations
j = 1
DO
    comp$ = MID$(t$, j, 1)
    SELECT CASE comp$
        CASE "0" TO "9", ".", "(", ")": j = j + 1
        CASE ELSE
            good = 0
            FOR i = 1 TO UBOUND(OName)
                IF MID$(t$, j, LEN(OName(i))) = OName(i) THEN good = -1: EXIT FOR 'We found an operator after our ), and it's not a CONST (like PI)
            NEXT
            IF NOT good THEN t$ = "ERROR - Bad Operational value. (" + comp$ + ")": EXIT SUB
            j = j + LEN(OName(i))
    END SELECT
LOOP UNTIL j > LEN(t$)
END SUB


FUNCTION BTen$ (InTop AS STRING, Op AS STRING, InBot AS STRING)
REM $DYNAMIC

InTop = LTRIM$(RTRIM$(InTop))
InBot = LTRIM$(RTRIM$(InBot))

l = INSTR(InTop, "-")
IF l = 0 THEN l = INSTR(InTop, "+")
IF l = 0 THEN InTop = "+" + InTop
l = INSTR(InBot, "-")
IF l = 0 THEN l = INSTR(InBot, "+")
IF l = 0 THEN InBot = "+" + InBot

l = INSTR(InTop, ".")
IF l = 0 THEN InTop = InTop + "."
l = INSTR(InBot, ".")
IF l = 0 THEN InBot = InBot + "."

IF Op$ = "-" THEN
    Op$ = "+"
    IF MID$(InBot, 1, 1) = "-" THEN MID$(InBot, 1, 1) = "+" ELSE MID$(InBot, 1, 1) = "-"
END IF


TDP& = Check&(10, InTop$)
BDP& = Check&(10, InBot$)

IF TDP& < 0 OR BDP& < 0 THEN EXIT FUNCTION

TSign% = Check&(11, InTop$)
BSign% = Check&(11, InBot$)

' Calculate Array Size

IF Op$ = CHR$(43) OR Op$ = CHR$(45) THEN
    '     "+" (Add)   OR    "-" (Subtract)
    Temp& = 9
ELSEIF Op$ = CHR$(42) OR Op$ = CHR$(50) THEN
    '      "*" (Multiply) OR "2" (SQRT Multiply)
    Temp& = 7
ELSE
    EXIT FUNCTION
END IF

' LSA (Left Side of Array)
LSA& = TDP& - 2
TLS& = LSA& \ Temp&
IF LSA& MOD Temp& > 0 THEN
    TLS& = TLS& + 1
    DO WHILE (TLPad& + LSA&) MOD Temp& > 0
        TLPad& = TLPad& + 1
    LOOP
END IF
LSA& = BDP& - 2
BLS& = LSA& \ Temp&
IF LSA& MOD Temp& > 0 THEN
    BLS& = BLS& + 1
    DO WHILE (BLPad& + LSA&) MOD Temp& > 0
        BLPad& = BLPad& + 1
    LOOP
END IF
IF TLS& >= BLS& THEN LSA& = TLS& ELSE LSA& = BLS&

' RSA (Right Side of Array)
RSA& = LEN(InTop$) - TDP&
TRS& = RSA& \ Temp&
IF RSA& MOD Temp& > 0 THEN
    TRS& = TRS& + 1
    DO WHILE (TRPad& + RSA&) MOD Temp& > 0
        TRPad& = TRPad& + 1
    LOOP
END IF
RSA& = LEN(InBot$) - BDP&
BRS& = RSA& \ Temp&
IF RSA& MOD Temp& > 0 THEN
    BRS& = BRS& + 1
    DO WHILE (BRPad& + RSA&) MOD Temp& > 0
        BRPad& = BRPad& + 1
    LOOP
END IF
IF TRS& >= BRS& THEN RSA& = TRS& ELSE RSA& = BRS&



IF Op$ = CHR$(43) OR Op$ = CHR$(45) THEN
    '     "+" (Add)   OR    "-" (Subtract)

    DIM Result(1 TO (LSA& + RSA&)) AS LONG

    IF (Op$ = CHR$(43) AND TSign% = BSign%) OR (Op$ = CHR$(45) AND TSign% <> BSign%) THEN
        ' Add Absolute Values and Return Top Sign

        ' Left Side
        FOR I& = 1 TO LSA&
            ' Top
            IF I& <= (LSA& - TLS&) THEN
                ''' Result(I&) = Result(I&) + 0
            ELSEIF I& = (1 + LSA& - TLS&) THEN
                Result(I&) = VAL(MID$(InTop$, 2, (9 - TLPad&)))
                TDP& = 11 - TLPad&
            ELSE
                Result(I&) = VAL(MID$(InTop$, TDP&, 9))
                TDP& = TDP& + 9
            END IF
            ' Bottom
            IF I& <= (LSA& - BLS&) THEN
                ''' Result(I&) = Result(I&) + 0
            ELSEIF I& = (1 + LSA& - BLS&) THEN
                Result(I&) = Result(I&) + VAL(MID$(InBot$, 2, (9 - BLPad&)))
                BDP& = 11 - BLPad&
            ELSE
                Result(I&) = Result(I&) + VAL(MID$(InBot$, BDP&, 9))
                BDP& = BDP& + 9
            END IF
        NEXT I&

        ' Right Side
        TDP& = TDP& + 1: BDP& = BDP& + 1
        FOR I& = (LSA& + 1) TO (LSA& + RSA&)
            ' Top
            IF I& > (LSA& + TRS&) THEN
                ''' Result(I&) = Result(I&) + 0
            ELSEIF I& = (LSA& + TRS&) THEN
                Result(I&) = (10 ^ TRPad&) * VAL(RIGHT$(InTop$, (9 - TRPad&)))
            ELSE
                Result(I&) = VAL(MID$(InTop$, TDP&, 9))
                TDP& = TDP& + 9
            END IF
            ' Bottom
            IF I& > (LSA& + BRS&) THEN
                ''' Result(I&) = Result(I&) + 0
            ELSEIF I& = (LSA& + BRS&) THEN
                Result(I&) = Result(I&) + (10 ^ BRPad&) * VAL(RIGHT$(InBot$, (9 - BRPad&)))
            ELSE
                Result(I&) = Result(I&) + VAL(MID$(InBot$, BDP&, 9))
                BDP& = BDP& + 9
            END IF
        NEXT I&

        ' Carry
        FOR I& = (LSA& + RSA&) TO 2 STEP -1
            IF Result(I&) >= 1000000000 THEN
                Result(I& - 1) = Result(I& - 1) + 1
                Result(I&) = Result(I&) - 1000000000
            END IF
        NEXT I&

        ' Return Sign
        IF TSign% = 1 THEN RetStr$ = CHR$(43) ELSE RetStr$ = CHR$(45)

    ELSE
        ' Compare Absolute Values

        IF TDP& > BDP& THEN
            Compare& = 1
        ELSEIF TDP& < BDP& THEN
            Compare& = -1
        ELSE
            IF LEN(InTop$) > LEN(InBot$) THEN Compare& = LEN(InBot$) ELSE Compare& = LEN(InTop$)
            FOR I& = 2 TO Compare&
                IF VAL(MID$(InTop$, I&, 1)) > VAL(MID$(InBot$, I&, 1)) THEN
                    Compare& = 1
                    EXIT FOR
                ELSEIF VAL(MID$(InTop$, I&, 1)) < VAL(MID$(InBot$, I&, 1)) THEN
                    Compare& = -1
                    EXIT FOR
                END IF
            NEXT I&
            IF Compare& > 1 THEN
                IF LEN(InTop$) > LEN(InBot$) THEN
                    Compare& = 1
                ELSEIF LEN(InTop$) < LEN(InBot$) THEN
                    Compare& = -1
                ELSE
                    Compare& = 0
                END IF
            END IF
        END IF

        ' Conditional Subtraction

        IF Compare& = 1 THEN
            ' Subtract Bottom from Top and Return Top Sign

            ' Top
            Result(1) = VAL(MID$(InTop$, 2, (9 - TLPad&)))
            TDP& = 11 - TLPad&
            FOR I& = 2 TO LSA&
                Result(I&) = VAL(MID$(InTop$, TDP&, 9))
                TDP& = TDP& + 9
            NEXT I&
            TDP& = TDP& + 1
            FOR I& = (LSA& + 1) TO (LSA& + TRS& - 1)
                Result(I&) = VAL(MID$(InTop$, TDP&, 9))
                TDP& = TDP& + 9
            NEXT I&
            Result(LSA& + TRS&) = 10& ^ TRPad& * VAL(RIGHT$(InTop$, (9 - TRPad&)))

            ' Bottom
            BDP& = (LEN(InBot$) - 17) + BRPad&
            FOR I& = (LSA& + BRS&) TO (1 + LSA& - BLS&) STEP -1
                IF I& = LSA& THEN BDP& = BDP& - 1
                IF I& = (LSA& + BRS&) THEN
                    Temp& = (10& ^ BRPad&) * VAL(RIGHT$(InBot$, (9 - BRPad&)))
                ELSEIF I& = (1 + LSA& - BLS&) THEN
                    Temp& = VAL(MID$(InBot$, 2, (9 - BLPad&)))
                ELSE
                    Temp& = VAL(MID$(InBot$, BDP&, 9))
                    BDP& = BDP& - 9
                END IF
                IF Result(I&) < Temp& THEN
                    ' Borrow
                    FOR J& = (I& - 1) TO 1 STEP -1
                        IF Result(J&) = 0 THEN
                            Result(J&) = 999999999
                        ELSE
                            Result(J&) = Result(J&) - 1
                            EXIT FOR
                        END IF
                    NEXT J&
                    Result(I&) = Result(I&) + 1000000000
                END IF
                Result(I&) = Result(I&) - Temp&
            NEXT I&

            ' Return Sign
            IF TSign% = 1 THEN RetStr$ = CHR$(43) ELSE RetStr$ = CHR$(45)

        ELSEIF Compare& = -1 THEN
            ' Subtract Top from Bottom and Return Bottom Sign

            ' Bottom
            Result(1) = VAL(MID$(InBot$, 2, (9 - BLPad&)))
            BDP& = 11 - BLPad&
            FOR I& = 2 TO LSA&
                Result(I&) = VAL(MID$(InBot$, BDP&, 9))
                BDP& = BDP& + 9
            NEXT I&
            BDP& = BDP& + 1
            FOR I& = (LSA& + 1) TO (LSA& + BRS& - 1)
                Result(I&) = VAL(MID$(InBot$, BDP&, 9))
                BDP& = BDP& + 9
            NEXT I&
            Result(LSA& + BRS&) = 10& ^ BRPad& * VAL(RIGHT$(InBot$, (9 - BRPad&)))

            ' Top
            TDP& = (LEN(InTop$) - 17) + TRPad&
            FOR I& = (LSA& + TRS&) TO (1 + LSA& - TLS&) STEP -1
                IF I& = LSA& THEN TDP& = TDP& - 1
                IF I& = (LSA& + TRS&) THEN
                    Temp& = (10& ^ TRPad&) * VAL(RIGHT$(InTop$, (9 - TRPad&)))
                ELSEIF I& = (1 + LSA& - TLS&) THEN
                    Temp& = VAL(MID$(InTop$, 2, (9 - TLPad&)))
                ELSE
                    Temp& = VAL(MID$(InTop$, TDP&, 9))
                    TDP& = TDP& - 9
                END IF
                IF Result(I&) < Temp& THEN
                    ' Borrow
                    FOR J& = (I& - 1) TO 1 STEP -1
                        IF Result(J&) = 0 THEN
                            Result(J&) = 999999999
                        ELSE
                            Result(J&) = Result(J&) - 1
                            EXIT FOR
                        END IF
                    NEXT J&
                    Result(I&) = Result(I&) + 1000000000
                END IF
                Result(I&) = Result(I&) - Temp&
            NEXT I&

            ' Build Return Sign
            IF BSign% = 1 THEN RetStr$ = CHR$(43) ELSE RetStr$ = CHR$(45)

        ELSE
            ' Result will always be 0

            LSA& = 1: RSA& = 1
            RetStr$ = CHR$(43)

        END IF
    END IF

    ' Generate Return String
    RetStr$ = RetStr$ + LTRIM$(STR$(Result(1)))
    FOR I& = 2 TO LSA&
        RetStr$ = RetStr$ + RIGHT$(STRING$(8, 48) + LTRIM$(STR$(Result(I&))), 9)
    NEXT I&
    RetStr$ = RetStr$ + CHR$(46)
    FOR I& = (LSA& + 1) TO (LSA& + RSA&)
        RetStr$ = RetStr$ + RIGHT$(STRING$(8, 48) + LTRIM$(STR$(Result(I&))), 9)
    NEXT I&

    ERASE Result

ELSEIF Op$ = CHR$(42) THEN
    ' * (Multiply)

    DIM TArray(1 TO (LSA& + RSA&)) AS LONG
    DIM BArray(1 TO (LSA& + RSA&)) AS LONG
    DIM ResDBL(0 TO (LSA& + RSA&)) AS DOUBLE

    ' Push String Data Into Array
    FOR I& = 1 TO LSA&
        IF I& <= (LSA& - TLS&) THEN
            ''' TArray(I&) = TArray(I&) + 0
        ELSEIF I& = (1 + LSA& - TLS&) THEN
            TArray(I&) = VAL(MID$(InTop$, 2, (7 - TLPad&)))
            TDP& = 9 - TLPad&
        ELSE
            TArray(I&) = VAL(MID$(InTop$, TDP&, 7))
            TDP& = TDP& + 7
        END IF
        IF I& <= (LSA& - BLS&) THEN
            ''' BArray(I&) = BArray(I&) + 0
        ELSEIF I& = (1 + LSA& - BLS&) THEN
            BArray(I&) = VAL(MID$(InBot$, 2, (7 - BLPad&)))
            BDP& = 9 - BLPad&
        ELSE
            BArray(I&) = VAL(MID$(InBot$, BDP&, 7))
            BDP& = BDP& + 7
        END IF
    NEXT I&
    TDP& = TDP& + 1: BDP& = BDP& + 1
    FOR I& = (LSA& + 1) TO (LSA& + RSA&)
        IF I& > (LSA& + TRS&) THEN
            ''' TArray(I&) = TArray(I&) + 0
        ELSEIF I& = (LSA& + TRS&) THEN
            TArray(I&) = 10 ^ TRPad& * VAL(RIGHT$(InTop$, (7 - TRPad&)))
        ELSE
            TArray(I&) = VAL(MID$(InTop$, TDP&, 7))
            TDP& = TDP& + 7
        END IF
        IF I& > (LSA& + BRS&) THEN
            ''' BArray(I&) = BArray(I&) + 0
        ELSEIF I& = (LSA& + BRS&) THEN
            BArray(I&) = 10 ^ BRPad& * VAL(RIGHT$(InBot$, (7 - BRPad&)))
        ELSE
            BArray(I&) = VAL(MID$(InBot$, BDP&, 7))
            BDP& = BDP& + 7
        END IF
    NEXT I&

    ' Multiply from Arrays to Array
    FOR I& = (LSA& + TRS&) TO (1 + LSA& - TLS&) STEP -1
        FOR J& = (LSA& + BRS&) TO (1 + LSA& - BLS&) STEP -1
            Temp# = 1# * TArray(I&) * BArray(J&)
            IF (I& + J&) MOD 2 = 0 THEN
                TL& = INT(Temp# / 10000000)
                TR& = Temp# - 10000000# * TL&
                ResDBL(((I& + J&) \ 2) - 1) = ResDBL(((I& + J&) \ 2) - 1) + TL&
                ResDBL((I& + J&) \ 2) = ResDBL((I& + J&) \ 2) + 10000000# * TR&
            ELSE
                ResDBL((I& + J&) \ 2) = ResDBL((I& + J&) \ 2) + Temp#
            END IF
            IF ResDBL((I& + J&) \ 2) >= 100000000000000# THEN
                Temp# = ResDBL((I& + J&) \ 2)
                TL& = INT(Temp# / 100000000000000#)
                ResDBL(((I& + J&) \ 2) - 1) = ResDBL(((I& + J&) \ 2) - 1) + TL&
                ResDBL((I& + J&) \ 2) = Temp# - 100000000000000# * TL&
            END IF
        NEXT J&
    NEXT I&

    ERASE TArray, BArray

    ' Generate Return String
    IF (TSign% * BSign%) = 1 THEN RetStr$ = CHR$(43) ELSE RetStr$ = CHR$(45)
    RetStr$ = RetStr$ + LTRIM$(STR$(ResDBL(0)))
    FOR I& = 1 TO (LSA&)
        RetStr$ = RetStr$ + RIGHT$(STRING$(13, 48) + LTRIM$(STR$(ResDBL(I&))), 14)
    NEXT I&
    RetStr$ = LEFT$(RetStr$, LEN(RetStr$) - 7) + CHR$(46) + RIGHT$(RetStr$, 7)
    FOR I& = (LSA& + 1) TO (LSA& + RSA&)
        RetStr$ = RetStr$ + RIGHT$(STRING$(13, 48) + LTRIM$(STR$(ResDBL(I&))), 14)
    NEXT I&

    ERASE ResDBL

ELSEIF Op$ = CHR$(50) THEN
    ' 2 (SQRT Multiply)

    DIM IArray(1 TO (LSA& + RSA&)) AS LONG
    DIM ResDBL(0 TO (LSA& + RSA&)) AS DOUBLE

    ' Push String Data Into Array
    FOR I& = 1 TO LSA&
        IF I& <= (LSA& - TLS&) THEN
            ''' IArray(I&) = IArray(I&) + 0
        ELSEIF I& = (1 + LSA& - TLS&) THEN
            IArray(I&) = VAL(MID$(InTop$, 2, (7 - TLPad&)))
            TDP& = 9 - TLPad&
        ELSE
            IArray(I&) = VAL(MID$(InTop$, TDP&, 7))
            TDP& = TDP& + 7
        END IF
    NEXT I&
    TDP& = TDP& + 1
    FOR I& = (LSA& + 1) TO (LSA& + RSA&)
        IF I& > (LSA& + TRS&) THEN
            ''' IArray(I&) = IArray(I&) + 0
        ELSEIF I& = (LSA& + TRS&) THEN
            IArray(I&) = 10 ^ TRPad& * VAL(RIGHT$(InTop$, (7 - TRPad&)))
        ELSE
            IArray(I&) = VAL(MID$(InTop$, TDP&, 7))
            TDP& = TDP& + 7
        END IF
    NEXT I&

    ' SQRT Multiply from Array to Array
    FOR I& = (LSA& + TRS&) TO 1 STEP -1
        FOR J& = I& TO 1 STEP -1
            Temp# = 1# * IArray(I&) * IArray(J&)
            IF I& <> J& THEN Temp# = Temp# * 2
            IF (I& + J&) MOD 2 = 0 THEN
                TL& = INT(Temp# / 10000000)
                TR& = Temp# - 10000000# * TL&
                ResDBL(((I& + J&) \ 2) - 1) = ResDBL(((I& + J&) \ 2) - 1) + TL&
                ResDBL((I& + J&) \ 2) = ResDBL((I& + J&) \ 2) + 10000000# * TR&
            ELSE
                ResDBL((I& + J&) \ 2) = ResDBL((I& + J&) \ 2) + Temp#
            END IF
            IF ResDBL((I& + J&) \ 2) >= 100000000000000# THEN
                Temp# = ResDBL((I& + J&) \ 2)
                TL& = INT(Temp# / 100000000000000#)
                ResDBL(((I& + J&) \ 2) - 1) = ResDBL(((I& + J&) \ 2) - 1) + TL&
                ResDBL((I& + J&) \ 2) = Temp# - 100000000000000# * TL&
            END IF
        NEXT J&
    NEXT I&

    ERASE IArray

    ' Generate Return String
    IF (TSign% * BSign%) = 1 THEN RetStr$ = CHR$(43) ELSE RetStr$ = CHR$(45)
    RetStr$ = RetStr$ + LTRIM$(STR$(ResDBL(0)))
    FOR I& = 1 TO (LSA&)
        RetStr$ = RetStr$ + RIGHT$(STRING$(13, 48) + LTRIM$(STR$(ResDBL(I&))), 14)
    NEXT I&
    RetStr$ = LEFT$(RetStr$, LEN(RetStr$) - 7) + CHR$(46) + RIGHT$(RetStr$, 7)
    ' Don't usually want the full right side for this, just enough to check the
    ' actual result against the expected result, which is probably an integer.
    ' Uncomment the three lines below when trying to find an oddball square root.
    'FOR I& = (LSA& + 1) TO (LSA& + RSA&)
    '    RetStr$ = RetStr$ + RIGHT$(STRING$(13, 48) + LTRIM$(STR$(ResDBL(I&))), 14)
    'NEXT I&

    ERASE ResDBL

END IF

' Trim Leading and Trailing Zeroes
DO WHILE MID$(RetStr$, 2, 1) = CHR$(48) AND MID$(RetStr$, 3, 1) <> CHR$(46)
    RetStr$ = LEFT$(RetStr$, 1) + RIGHT$(RetStr$, LEN(RetStr$) - 2)
LOOP
DO WHILE RIGHT$(RetStr$, 1) = CHR$(48) AND RIGHT$(RetStr$, 2) <> CHR$(46) + CHR$(48)
    RetStr$ = LEFT$(RetStr$, LEN(RetStr$) - 1)
LOOP


IF MID$(RetStr$, 1, 1) = "+" THEN MID$(RetStr$, 1, 1) = " "
DO
    r$ = RIGHT$(RetStr$, 1)
    IF r$ = "0" THEN RetStr$ = LEFT$(RetStr$, LEN(RetStr$) - 1)
LOOP UNTIL r$ <> "0"

r$ = RIGHT$(RetStr$, 1)
IF r$ = "." THEN RetStr$ = LEFT$(RetStr$, LEN(RetStr$) - 1)

BTen$ = RetStr$
END FUNCTION
REM $STATIC
' ---------------------------------------------------------------------------
' FUNCTION Check& (Op&, InString$)                Multi-Purpose String Tester
' ---------------------------------------------------------------------------
'
' *   Op&   = Type of string to expect and/or operation to perform
'
'   { 00A } = (10) Test Base-10-Format String  ( *!* ALTERS InString$ *!* )
'   { 00B } = (11) Read Sign ("+", "-", or "�")
'
'   Unlisted values are not used and will return [ Check& = 0 - Op& ].
'   Different Op& values produce various return values.
'   Refer to the in-code comments for details.
'
' ---------------------------------------------------------------------------
' FUNCTION Check& (Op&, InString$)                Multi-Purpose String Tester
' ---------------------------------------------------------------------------
FUNCTION Check& (Op AS LONG, InString AS STRING)
REM $DYNAMIC

RetVal& = LEN(InString$)

SELECT CASE Op&

    CASE 10
        ' {00A} Test String for Base-10-Format ( *!* ALTERS InString$ *!* )
        ' Returns:
        ' {& > 0} = DP offset; {& < 0} = FAILED at negative offset
        '
        ' After testing passes, the string is trimmed
        ' of nonessential leading and trailing zeroes.

        IF RetVal& = 0 THEN
            RetVal& = -1
        ELSE
            SELECT CASE ASC(LEFT$(InString$, 1))
                CASE 43, 45 ' "+", "-"
                    FOR I& = 2 TO RetVal&
                        SELECT CASE ASC(MID$(InString$, I&, 1))
                            CASE 46 ' "."
                                IF DPC% > 0 THEN
                                    RetVal& = 0 - I&
                                    EXIT FOR
                                ELSE
                                    DPC% = DPC% + 1
                                    RetVal& = I&
                                END IF
                            CASE 48 TO 57
                                ' keep going
                            CASE ELSE
                                RetVal& = 0 - I&
                                EXIT FOR
                        END SELECT
                    NEXT I&
                CASE ELSE
                    RetVal& = -1
            END SELECT
            IF DPC% = 0 AND RetVal& > 0 THEN
                RetVal& = 0 - RetVal&
            ELSEIF RetVal& = 2 THEN
                InString$ = LEFT$(InString$, 1) + CHR$(48) + RIGHT$(InString$, LEN(InString$) - 1)
                RetVal& = RetVal& + 1
            END IF
            IF RetVal& = LEN(InString$) THEN InString$ = InString$ + CHR$(48)
            DO WHILE ASC(RIGHT$(InString$, 1)) = 48 AND RetVal& < (LEN(InString$) - 1)
                InString$ = LEFT$(InString$, LEN(InString$) - 1)
            LOOP
            DO WHILE ASC(MID$(InString$, 2, 1)) = 48 AND RetVal& > 3
                InString$ = LEFT$(InString$, 1) + RIGHT$(InString$, LEN(InString$) - 2)
                RetVal& = RetVal& - 1
            LOOP
        END IF


    CASE 11
        ' {00B} Read Sign ("+", "-", or "�")
        ' Returns:
        ' Explicit: +1 = Positive; -1 = Negative; 0 = Unsigned;
        ' Implied: +64 = Positive; -64 = NULL String

        IF RetVal& = 0 THEN RetVal& = -64
        FOR I& = 1 TO RetVal&
            SELECT CASE ASC(MID$(InString$, I&, 1))
                CASE 32
                    RetVal& = 64
                    ' keep going
                CASE 43
                    RetVal& = 1
                    EXIT FOR
                CASE 45
                    RetVal& = -1
                    EXIT FOR
                CASE 241
                    RetVal& = 0
                    EXIT FOR
                CASE ELSE
                    RetVal& = 64
                    EXIT FOR
            END SELECT
        NEXT I&


    CASE ELSE

        RetVal& = 0 - Op&

END SELECT

Check& = RetVal&
END FUNCTION

FUNCTION N2S$ (exp$) 'scientific Notation to String
t$ = LTRIM$(RTRIM$(exp$))
IF LEFT$(t$, 1) = "-" THEN sign$ = "-": t$ = MID$(t$, 2)

dp = INSTR(t$, "D+"): dm = INSTR(t$, "D-")
ep = INSTR(t$, "E+"): em = INSTR(t$, "E-")
check1 = SGN(dp) + SGN(dm) + SGN(ep) + SGN(em)
IF check1 < 1 OR check1 > 1 THEN N2S = exp$: EXIT SUB 'If no scientic notation is found, or if we find more than 1 type, it's not SN!

SELECT CASE l 'l now tells us where the SN starts at.
    CASE IS < dp: l = dp
    CASE IS < dm: l = dm
    CASE IS < ep: l = ep
    CASE IS < em: l = em
END SELECT

l$ = LEFT$(t$, l - 1) 'The left of the SN
r$ = MID$(t$, l + 1): r&& = VAL(r$) 'The right of the SN, turned into a workable long


IF INSTR(l$, ".") THEN 'Location of the decimal, if any
    IF r&& > 0 THEN
        r&& = r&& - LEN(l$) + 2
    ELSE
        r&& = r&& + 1
    END IF
    l$ = LEFT$(l$, 1) + MID$(l$, 3)
END IF

SELECT CASE r&&
    CASE 0 'what the heck? We solved it already?
        'l$ = l$
    CASE IS < 0
        FOR i = 1 TO -r&&
            l$ = "0" + l$
        NEXT
        l$ = "0." + l$
    CASE ELSE
        FOR i = 1 TO r&&
            l$ = l$ + "0"
        NEXT
END SELECT

N2S$ = sign$ + l$
END SUB


FUNCTION QuotedFilename$ (f$)

IF os$ = "WIN" THEN
    QuotedFilename$ = CHR$(34) + f$ + CHR$(34)
    EXIT FUNCTION
END IF

IF os$ = "LNX" THEN
    QuotedFilename$ = "'" + f$ + "'"
    EXIT FUNCTION
END IF

END FUNCTION


FUNCTION HashValue& (a$) 'returns the hash table value of a string
'[5(first)][5(second)][5(last)][5(2nd-last)][3(length AND 7)][1(first char is underscore)]
l = LEN(a$)
IF l = 0 THEN EXIT FUNCTION 'an (invalid) NULL string equates to 0
a = ASC(a$)
IF a <> 95 THEN 'does not begin with underscore
    SELECT CASE l
        CASE 1
            HashValue& = hash1char(a) + 1048576
            EXIT FUNCTION
        CASE 2
            HashValue& = hash2char(CVI(a$)) + 2097152
            EXIT FUNCTION
        CASE 3
            HashValue& = hash2char(CVI(a$)) + hash1char(ASC(a$, 3)) * 1024 + 3145728
            EXIT FUNCTION
        CASE ELSE
            HashValue& = hash2char(CVI(a$)) + hash2char(ASC(a$, l) + ASC(a$, l - 1) * 256) * 1024 + (l AND 7) * 1048576
            EXIT FUNCTION
    END SELECT
ELSE 'does begin with underscore
    SELECT CASE l
        CASE 1
            HashValue& = (1048576 + 8388608): EXIT FUNCTION 'note: underscore only is illegal in QB64 but supported by hash
        CASE 2
            HashValue& = hash1char(ASC(a$, 2)) + (2097152 + 8388608)
            EXIT FUNCTION
        CASE 3
            HashValue& = hash2char(ASC(a$, 2) + ASC(a$, 3) * 256) + (3145728 + 8388608)
            EXIT FUNCTION
        CASE 4
            HashValue& = hash2char((CVL(a$) AND &HFFFF00) \ 256) + hash1char(ASC(a$, 4)) * 1024 + (4194304 + 8388608)
            EXIT FUNCTION
        CASE ELSE
            HashValue& = hash2char((CVL(a$) AND &HFFFF00) \ 256) + hash2char(ASC(a$, l) + ASC(a$, l - 1) * 256) * 1024 + (l AND 7) * 1048576 + 8388608
            EXIT FUNCTION
    END SELECT
END IF
END FUNCTION

SUB HashAdd (a$, flags, reference)

'find the index to use
IF HashListFreeLast > 0 THEN
    'take from free list
    i = HashListFree(HashListFreeLast)
    HashListFreeLast = HashListFreeLast - 1
ELSE
    IF HashListNext > HashListSize THEN
        'double hash list size
        HashListSize = HashListSize * 2
        REDIM _PRESERVE HashList(1 TO HashListSize) AS HashListItem
        REDIM _PRESERVE HashListName(1 TO HashListSize) AS STRING * 256
    END IF
    i = HashListNext
    HashListNext = HashListNext + 1
END IF

'setup links to index
x = HashValue(a$)
i2 = HashTable(x)
IF i2 THEN
    i3 = HashList(i2).LastItem
    HashList(i2).LastItem = i
    HashList(i3).NextItem = i
    HashList(i).PrevItem = i3
ELSE
    HashTable(x) = i
    HashList(i).PrevItem = 0
    HashList(i).LastItem = i
END IF
HashList(i).NextItem = 0

'set common hashlist values
HashList(i).Flags = flags
HashList(i).Reference = reference
HashListName(i) = UCASE$(a$)

END SUB

FUNCTION HashFind (a$, searchflags, resultflags, resultreference)
'(0,1,2)z=hashfind[rev]("RUMI",Hashflag_label,resflag,resref)
'0=doesn't exist
'1=found, no more items to scan
'2=found, more items still to scan
i = HashTable(HashValue(a$))
IF i THEN
    ua$ = UCASE$(a$) + SPACE$(256 - LEN(a$))
    hashfind_next:
    f = HashList(i).Flags
    IF searchflags AND f THEN 'flags in common
        IF HashListName(i) = ua$ THEN
            resultflags = f
            resultreference = HashList(i).Reference
            i2 = HashList(i).NextItem
            IF i2 THEN
                HashFind = 2
                HashFind_NextListItem = i2
                HashFind_Reverse = 0
                HashFind_SearchFlags = searchflags
                HashFind_Name = ua$
                HashRemove_LastFound = i
                EXIT FUNCTION
            ELSE
                HashFind = 1
                HashRemove_LastFound = i
                EXIT FUNCTION
            END IF
        END IF
    END IF
    i = HashList(i).NextItem
    IF i THEN GOTO hashfind_next
END IF
END FUNCTION

FUNCTION HashFindRev (a$, searchflags, resultflags, resultreference)
'(0,1,2)z=hashfind[rev]("RUMI",Hashflag_label,resflag,resref)
'0=doesn't exist
'1=found, no more items to scan
'2=found, more items still to scan
i = HashTable(HashValue(a$))
IF i THEN
    i = HashList(i).LastItem
    ua$ = UCASE$(a$) + SPACE$(256 - LEN(a$))
    hashfindrev_next:
    f = HashList(i).Flags
    IF searchflags AND f THEN 'flags in common
        IF HashListName(i) = ua$ THEN
            resultflags = f
            resultreference = HashList(i).Reference
            i2 = HashList(i).PrevItem
            IF i2 THEN
                HashFindRev = 2
                HashFind_NextListItem = i2
                HashFind_Reverse = 1
                HashFind_SearchFlags = searchflags
                HashFind_Name = ua$
                HashRemove_LastFound = i
                EXIT FUNCTION
            ELSE
                HashFindRev = 1
                HashRemove_LastFound = i
                EXIT FUNCTION
            END IF
        END IF
    END IF
    i = HashList(i).PrevItem
    IF i THEN GOTO hashfindrev_next
END IF
END FUNCTION

FUNCTION HashFindCont (resultflags, resultreference)
'(0,1,2)z=hashfind[rev](resflag,resref)
'0=no more items exist
'1=found, no more items to scan
'2=found, more items still to scan
IF HashFind_Reverse THEN

    i = HashFind_NextListItem
    hashfindrevc_next:
    f = HashList(i).Flags
    IF HashFind_SearchFlags AND f THEN 'flags in common
        IF HashListName(i) = HashFind_Name THEN
            resultflags = f
            resultreference = HashList(i).Reference
            i2 = HashList(i).PrevItem
            IF i2 THEN
                HashFindCont = 2
                HashFind_NextListItem = i2
                HashRemove_LastFound = i
                EXIT FUNCTION
            ELSE
                HashFindCont = 1
                HashRemove_LastFound = i
                EXIT FUNCTION
            END IF
        END IF
    END IF
    i = HashList(i).PrevItem
    IF i THEN GOTO hashfindrevc_next
    EXIT FUNCTION

ELSE

    i = HashFind_NextListItem
    hashfindc_next:
    f = HashList(i).Flags
    IF HashFind_SearchFlags AND f THEN 'flags in common
        IF HashListName(i) = HashFind_Name THEN
            resultflags = f
            resultreference = HashList(i).Reference
            i2 = HashList(i).NextItem
            IF i2 THEN
                HashFindCont = 2
                HashFind_NextListItem = i2
                HashRemove_LastFound = i
                EXIT FUNCTION
            ELSE
                HashFindCont = 1
                HashRemove_LastFound = i
                EXIT FUNCTION
            END IF
        END IF
    END IF
    i = HashList(i).NextItem
    IF i THEN GOTO hashfindc_next
    EXIT FUNCTION

END IF
END FUNCTION

SUB HashRemove

i = HashRemove_LastFound

'add to free list
HashListFreeLast = HashListFreeLast + 1
IF HashListFreeLast > HashListFreeSize THEN
    HashListFreeSize = HashListFreeSize * 2
    REDIM _PRESERVE HashListFree(1 TO HashListFreeSize) AS LONG
END IF
HashListFree(HashListFreeLast) = i

'unlink
i1 = HashList(i).PrevItem
IF i1 THEN
    'not first item in list
    i2 = HashList(i).NextItem
    IF i2 THEN
        '(not first and) not last item
        HashList(i1).NextItem = i2
        HashList(i2).LastItem = i1
    ELSE
        'last item
        x = HashTable(HashValue(HashListName$(i)))
        HashList(x).LastItem = i1
        HashList(i1).NextItem = 0
    END IF
ELSE
    'first item in list
    x = HashTable(HashValue(HashListName$(i)))
    i2 = HashList(i).NextItem
    IF i2 THEN
        '(first item but) not last item
        HashTable(x) = i2
        HashList(i2).PrevItem = 0
        HashList(i2).LastItem = HashList(i).LastItem
    ELSE
        '(first and) last item
        HashTable(x) = 0
    END IF
END IF

END SUB

SUB HashDump 'used for debugging purposes
fh = FREEFILE
OPEN "hashdump.txt" FOR OUTPUT AS #fh
b$ = "12345678901234567890123456789012}"
FOR x = 0 TO 16777215
    IF HashTable(x) THEN

        PRINT #fh, "START HashTable("; x; "):"
        i = HashTable(x)

        'validate
        lasti = HashList(i).LastItem
        IF HashList(i).LastItem = 0 OR HashList(i).PrevItem <> 0 OR HashValue(HashListName(i)) <> x THEN GOTO corrupt

        PRINT #fh, "  HashList("; i; ").LastItem="; HashList(i).LastItem
        hashdumpnextitem:
        x$ = "  [" + STR$(i) + "]" + HashListName(i)

        f = HashList(i).Flags
        x$ = x$ + ",.Flags=" + STR$(f) + "{"
        FOR z = 1 TO 32
            ASC(b$, z) = (f AND 1) + 48
            f = f \ 2
        NEXT
        x$ = x$ + b$

        x$ = x$ + ",.Reference=" + STR$(HashList(i).Reference)

        PRINT #fh, x$

        'validate
        i1 = HashList(i).PrevItem
        i2 = HashList(i).NextItem
        IF i1 THEN
            IF HashList(i1).NextItem <> i THEN GOTO corrupt
        END IF
        IF i2 THEN
            IF HashList(i2).PrevItem <> i THEN GOTO corrupt
        END IF
        IF i2 = 0 THEN
            IF lasti <> i THEN GOTO corrupt
        END IF

        i = HashList(i).NextItem
        IF i THEN GOTO hashdumpnextitem

        PRINT #fh, "END HashTable("; x; ")"
    END IF
NEXT
CLOSE #fh

EXIT SUB
corrupt:
PRINT #fh, "HASH TABLE CORRUPT!" 'should never happen
CLOSE #fh

END SUB

SUB HashClear 'clear entire hash table

HashListSize = 65536
HashListNext = 1
HashListFreeSize = 1024
HashListFreeLast = 0
REDIM HashList(1 TO HashListSize) AS HashListItem
REDIM HashListName(1 TO HashListSize) AS STRING * 256
REDIM HashListFree(1 TO HashListFreeSize) AS LONG
REDIM HashTable(16777215) AS LONG '64MB lookup table with indexes to the hashlist

HashFind_NextListItem = 0
HashFind_Reverse = 0
HashFind_SearchFlags = 0
HashFind_Name = ""
HashRemove_LastFound = 0

END SUB

FUNCTION removecast$ (a$)
removecast$ = a$
IF INSTR(a$, "  )") THEN
    removecast$ = RIGHT$(a$, LEN(a$) - INSTR(a$, "  )") - 2)
END IF
END FUNCTION

FUNCTION converttabs$ (a2$)
IF ideautoindent THEN s = ideautoindentsize ELSE s = 4
a$ = a2$
DO WHILE INSTR(a$, CHR_TAB)
    x = INSTR(a$, CHR_TAB)
    a$ = LEFT$(a$, x - 1) + SPACE$(s - ((x - 1) MOD s)) + RIGHT$(a$, LEN(a$) - x)
LOOP
converttabs$ = a$
END FUNCTION


FUNCTION NewByteElement$
a$ = "byte_element_" + str2$(uniquenumber)
NewByteElement$ = a$
IF use_global_byte_elements THEN
    PRINT #18, "byte_element_struct *" + a$ + "=(byte_element_struct*)malloc(12);"
ELSE
    PRINT #13, "byte_element_struct *" + a$ + "=NULL;"
    PRINT #13, "if (!" + a$ + "){"
    PRINT #13, "if ((mem_static_pointer+=12)<mem_static_limit) " + a$ + "=(byte_element_struct*)(mem_static_pointer-12); else " + a$ + "=(byte_element_struct*)mem_static_malloc(12);"
    PRINT #13, "}"
END IF
END FUNCTION

FUNCTION validname (a$)
'notes:
'1) '_1' is invalid because it has no alphabet letters
'2) 'A_' is invalid because it has a trailing _
'3) '_1A' is invalid because it contains a number before the first alphabet letter
'4) names cannot be longer than 40 characters
l = LEN(a$)

IF l = 0 OR l > 40 THEN
    IF l = 0 THEN EXIT FUNCTION
    'Note: variable names with periods need to be obfuscated, and this affects their length
    i = INSTR(a$, fix046$)
    DO WHILE i
        l = l - LEN(fix046$) + 1
        i = INSTR(i + 1, a$, fix046$)
    LOOP
    IF l > 40 THEN EXIT FUNCTION
    l = LEN(a$)
END IF

'check for single, leading underscore
IF l >= 2 THEN
    IF ASC(a$, 1) = 95 AND ASC(a$, 2) <> 95 THEN EXIT FUNCTION
END IF

FOR i = 1 TO l
    a = ASC(a$, i)
    IF alphanumeric(a) = 0 THEN EXIT FUNCTION
    IF isnumeric(a) THEN
        trailingunderscore = 0
        IF alphabetletter = 0 THEN EXIT FUNCTION
    ELSE
        IF a = 95 THEN
            trailingunderscore = 1
        ELSE
            alphabetletter = 1
            trailingunderscore = 0
        END IF
    END IF
NEXT
IF trailingunderscore THEN EXIT FUNCTION
validname = 1
END FUNCTION

FUNCTION str_nth$ (x)
IF x = 1 THEN str_nth$ = "1st": EXIT FUNCTION
IF x = 2 THEN str_nth$ = "2nd": EXIT FUNCTION
IF x = 3 THEN str_nth$ = "3rd": EXIT FUNCTION
str_nth$ = str2(x) + "th"
END FUNCTION

SUB Give_Error (a$)
Error_Happened = 1
Error_Message = a$
END SUB

FUNCTION StrRemove$ (myString$, whatToRemove$) 'noncase sensitive
a$ = myString$
b$ = LCASE$(whatToRemove$)
i = INSTR(LCASE$(a$), b$)
DO WHILE i
    a$ = LEFT$(a$, i - 1) + RIGHT$(a$, LEN(a$) - i - LEN(b$) + 1)
    i = INSTR(LCASE$(a$), b$)
LOOP
StrRemove$ = a$
END FUNCTION

FUNCTION StrReplace$ (myString$, find$, replaceWith$) 'noncase sensitive
IF LEN(myString$) = 0 THEN EXIT FUNCTION
a$ = myString$
b$ = LCASE$(find$)
basei = 1
i = INSTR(basei, LCASE$(a$), b$)
DO WHILE i
    a$ = LEFT$(a$, i - 1) + replaceWith$ + RIGHT$(a$, LEN(a$) - i - LEN(b$) + 1)
    basei = i + LEN(replaceWith$)
    i = INSTR(basei, LCASE$(a$), b$)
LOOP
StrReplace$ = a$
END FUNCTION


'$INCLUDE:'subs_functions\extensions\opengl\opengl_methods.bas'

'-------- Optional IDE Component (2/2) --------
'$INCLUDE:'ide\ide_methods.bas'
