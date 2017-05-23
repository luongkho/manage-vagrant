@ECHO off
REM Set echo off to less verbose output

REM Enable extensions and delayexpansion to use array
REM such as id!count! = [id1, id2, id3, ...]
SETLOCAL ENABLEEXTENSIONS ENABLEDELAYEDEXPANSION

REM Commands instruction
REM If OR example
REM 	IF <condition> 			SET flag=1
REM		If <other_condition>	SET flag=1
REM		IF %flag% == 1 (command)
REM
REM FOR /F to loop through <command>
REM 	skip=0 to set number of lines to skip
REM		USEBACKQ to set type of quota, this help to valid quote in `command`
REM 	tokens=* tokens=1,4,5 tokens=1-4 to determine which elements will be capture
REM			default is 1: only fetch first element
REM			elements are seperate by [space] by default, to modify use {delim}
REM			To capture tokens, use sequent Latin letter
REM				example: tokens=1,4,5 %%g ===> %%g mean first token, %%h mean second, %%i mean third one,...
REM
REM	FOR /L to normal loop through number of times
REM		FOR /L %%i IN (start, step, end)
REM
REM	SET /P variable=<message> to show <message> and wait for user input, input will be store in variable
REM SET /A Arithmetic expression (add, subtract, ...)
REM 
REM CHOICE  /T 	time in second
REM			/C  possible key user can press. Default is YN: [y] key and [n] key
REM			/N 	Not display posible key to user (in case has many keys, message become verbose )
REM			/CS Make choice key case sensitive
REM			/D 	Default key if user not choose after time out
REM			/m 	"Describe message"
REM		Key order after /C is important for detect errorlevel after command.
REM			Eg. /C ynabpm mean user can press [y],[n],[a],[b],[p],[m]
REM				errorlevel: [y] = 1, [n] = 2, [a] = 3, ...
REM				Catch errorlevel: IF errorlevel 5 doSomething
REM								  IF errorlevel 4 doOtherThing
REM			Higher errorlevel should be caught earlier,
REM				because 'errorlevel x' will return TRUE for any errorlevel y >= x

SET machineId=0
SET commandId=0

:ReadData
	SET count=0
	FOR /F "skip=2 USEBACKQ tokens=1,4,5" %%g IN (`vagrant global-status`) DO (
		IF "%%g"=="The" (
			GOTO :MainMenu
		)
		SET /a count=!count!+1
	  	SET id!count!=%%g
	  	SET status!count!=%%h
  		SET location!count!=%%i
	)
	REM Should never go here
	GOTO :MainMenu

:MainMenu
	ECHO.
	ECHO There are %count% machines
	FOR /L %%i IN (1,1,%count%) DO (
		ECHO %%i. !id%%i! !status%%i! !location%%i!
	)
	ECHO.
	ECHO 1. Choice Machine
	ECHO 2. Halt all
	ECHO 3. Halt all and shutdown
	ECHO 4. Terminate
	GOTO :FirstChoice

:FirstChoice
	SET /P choice="Command: "
	IF %choice% EQU 1 (
		ECHO.
		GOTO :ChoiceMachine
	) ELSE IF %choice% EQU 2 (
		GOTO :ShutdownAll
	) ELSE IF %choice% EQU 3 (
		GOTO :ShutdownComputer
	) ELSE IF %choice% EQU 4 (
		GOTO :End
	) ELSE (
		GOTO :FirstChoice
	)

:ShutdownAll
	FOR /L %%i IN (1,1,%count%) DO (
		vagrant halt !id%%i!
	)
	GOTO :ReadData

:ShutdownComputer
	FOR /L %%i IN (1,1,%count%) DO (
		vagrant halt !id%%i!
	)

	ECHO.
	ECHO DANGER, PREPARE TO SHUTDOWN
	CHOICE /T 10 /C 1234567890qwertyuiopasdfghjklzxcvbnm /N /D 1 /m "Press any key except [1] to cancel: "
	IF errorlevel 2 (
		ECHO Shutdown canceled.
		GOTO :ReadData
	)
	IF errorlevel 1 (
		SHUTDOWN.EXE -s -t 20
		EXIT
	)

:End
	ENDLOCAL
	PAUSE
	EXIT

:ChoiceMachine
	SET /P choice="Machine: "
	IF "!id%choice%!"=="" (
		GOTO :ChoiceMachine
	) ELSE (
		SET machineId=%choice%
		ECHO.
		ECHO Machine !id%choice%! !status%choice%! !location%choice%!
		ECHO 1. Start machine
		ECHO 2. SSH machine
		ECHO 3. Halt machine
		ECHO 0. Back
		GOTO :ChoiceCommand
	)

:ChoiceCommand
	SET /P choice="Your choice: "
	IF %choice% EQU 1 (
		GOTO :StartMachine
	) ELSE IF %choice% EQU 2 (
		GOTO :SshMachine
	) ELSE IF %choice% EQU 3 (
		GOTO :HaltMachine
	) ELSE IF %choice% EQU 0 (
		GOTO :MainMenu
	) ELSE (
		GOTO :ChoiceCommand
	)

:StartMachine
	SET command=vagrant up !id%machineId%!
	%command%
	GOTO :ReadData

:SshMachine
	SET command=vagrant ssh !id%machineId%!
	%command%
	GOTO :ReadData

:HaltMachine
	SET command=vagrant halt !id%machineId%!
	%command%
	GOTO :ReadData

PAUSE