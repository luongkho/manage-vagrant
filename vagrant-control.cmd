REM Set echo off to less verbose output
@ECHO off

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

SET machineId=0
SET commandId=0

:ReadData
	SET count=0
	FOR /F "skip=2 USEBACKQ tokens=1,4,5" %%g IN (`vagrant global-status`) DO (
		if "%%g"=="The" (
			goto :MainMenu
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
	echo 1. Choice Machine
	ECHO 2. Halt all
	ECHO 3. Halt all and shutdown
	ECHO 4. Terminate
	GOTO :FirstChoice

:FirstChoice
	set /P choice="Command: "
	if %choice% equ 1 (
		echo.
		goto :ChoiceMachine
	) else if %choice% equ 2 (
		goto :ShutdownAll
	) else if %choice% equ 3 (
		goto :ShutdownComputer
	) else if %choice% equ 4 (
		goto :End
	) else (
		goto :FirstChoice
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
	TIMEOUT /T 10
	SHUTDOWN.EXE -s -t 20
	exit

:End
	ENDLOCAL
	PAUSE
	EXIT

:ChoiceMachine
	SET /P choice="Machine: "
	if "!id%choice%!"=="" (
		goto :ChoiceMachine
	) else (
		SET machineId=%choice%
		echo.
		echo Machine !id%choice%! !status%choice%! !location%choice%!
		ECHO 1. Start machine
		ECHO 2. SSH machine
		ECHO 3. Halt machine
		echo 0. Back
		goto :ChoiceCommand
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