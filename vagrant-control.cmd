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

SETLOCAL ENABLEEXTENSIONS ENABLEDELAYEDEXPANSION

SET count=0
SET firstTime=0
SET machineId=0
SET commandId=0

:ReadData
	SET /a count=0
	FOR /F "skip=2 USEBACKQ tokens=1,4,5" %%g IN (`vagrant global-status`) DO (
		IF "%%g"=="The" (
			IF %firstTime% EQU 0 (
				GOTO :DisplayInfo
			) ELSE (
				GOTO :DisplayInfo2
			)
		)
		SET /a count=!count!+1
	  	SET id!count!=%%g
	  	SET status!count!=%%h
  		SET location!count!=%%i
	)
	rem Should never go here
	GOTO :DisplayInfo

:DisplayInfo
	ECHO.
	ECHO There are %count% machines
	FOR /L %%i IN (1,1,%count%) DO (
		ECHO %%i. !id%%i! !status%%i! !location%%i!
	)
	ECHO.
	GOTO :ChoiceCommand

:DisplayInfo2
	ECHO.
	ECHO Choose machine to process
	FOR /L %%i IN (1,1,%count%) DO (
		ECHO %%i. !id%%i! !status%%i! !location%%i!
	)
	ECHO.
	GOTO :ChoiceMachine

:ChoiceCommand
	SET /a firstTime=1
	ECHO 1. Start a machine
	ECHO 2. SSH a machine
	ECHO 3. Halt a machine
	ECHO 4. Halt all
	ECHO 5. Halt all and shutdown
	ECHO 6. Terminal

	SET /P choice="Your choice: "

	IF %choice% EQU 1 (
		SET /a commandId=1
		GOTO :ReadData
	) ELSE IF %choice% EQU 2 (
		SET /a commandId=2
		GOTO :ReadData
	) ELSE IF %choice% EQU 3 (
		SET /a commandId=3
		GOTO :ReadData
	) ELSE IF %choice% EQU 4 (
		GOTO :ShutdownAll
	) ELSE IF %choice% EQU 5 (
		GOTO :ShutdownComputer
	) ELSE IF %choice% EQU 6 (
		GOTO :End
	) ELSE (
		GOTO :ChoiceCommand
	)

:ChoiceMachine
	SET /a firstTime=0
	SET /P choice="Machine: "	
	SET /a machineId=%choice%
	IF %commandId% EQU 1 (
		GOTO :StartMachine
	) ELSE IF %commandId% EQU 2 (
		GOTO :SshMachine
	) ELSE IF %commandId% EQU 3 (
		GOTO :HaltMachine
	) ELSE (
		rem should never go here
		GOTO :End
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

:ShutdownAll
	SET /a firstTime=0
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

PAUSE