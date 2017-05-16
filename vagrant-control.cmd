@ECHO off
rem Enable extensions and delayexpansion to use array
rem such as id!count! = [id1, id2, id3, ...]
rem
rem Set echo off to less verbose output
rem
rem If OR example
rem 	IF <condition> 			SET flag=1
rem		If <other_condition>	SET flag=1
rem		IF %flag% == 1 (command)
rem
rem FOR /F to loop through <command>
rem 	skip=0 to set number of lines to skip
rem		USEBACKQ to set type of quota, this help to valid quote in `command`
rem 	tokens=* tokens=1,4,5 tokens=1-4 to determine which elements will be capture
rem			default is 1: only fetch first element
rem			elements is seperate by [space] by default, to modify use {delim}
rem			To get elements, use sequent Latin letter
rem				example: tokens=1,4,5 %%g => %%g mean first token, %%h mean second, %%i mean third one
rem
rem	FOR /L to normal loop through number of times
rem		FOR /L %%i IN (start, step, end)
rem
rem	SET /P variable=<message> to show <message> and wait for user input, input will be store in variable
rem SET /A Arithmetic expression (add, subtract, ...)

SETLOCAL ENABLEEXTENSIONS ENABLEDELAYEDEXPANSION

rem SET firstTime=0
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
	rem Should never go here
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
	rem SET /a firstTime=0
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
	rem SET /a firstTime=0
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