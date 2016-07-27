/*

null = ["Name1", "create", 60] call compile preprocessFileLineNumbers "NSA_Timer.sqf";

NSA_Timer = compile preprocessFileLineNumbers "NSA_Timer.sqf";
["timerName", action, TimeToWait] call NSA_Timer;

When a timer reaches 0, it updates public var: 		publicVariable "NSA_timer_Alert";
	This can be used to fire addPublicVariableEventHandler

When creating timer - the name must be unique String.


Actions:
	
	null = ["Name1", "create", TimeToWait] call compile preprocessFileLineNumbers "NSA_Timer.sqf";
		-- Create new timer. 			
			Parameters: [<String>, "create", <int>] 		
			Return: (Nothing)
	
	null = ["Name1", "get"] call compile preprocessFileLineNumbers "NSA_Timer.sqf";
		-- Get timer full info.			
			Parameters: [<String>, "get"] 					
			Return: (Array) [ID, ["Name",TimeToWait, timeLeft, state]]
				state options:
					0 - finished (timer reached 0)
					1 - running
					2 - paused
	
	null = ["Name1", "getTime"] call compile preprocessFileLineNumbers "NSA_Timer.sqf";
		-- Get TimeLeft of the timer			
			Parameters: [<String>, "getTime"] 					
			Return: (Int) TimeLeft (in seconds)
	
	null = ["Name1", "pause"] call compile preprocessFileLineNumbers "NSA_Timer.sqf";
		-- Pause timer		
			Parameters: [<String>, "pause"] 					
			Return: (Int) Timer ID - if successful; -1 - if timer name not found
	
	null = ["Name1", "resume"] call compile preprocessFileLineNumbers "NSA_Timer.sqf";
		-- Resume timer		
			Parameters: [<String>, "resume"] 					
			Return: (Int) Timer ID - if successful; -1 - if timer name not found
	
	null = ["Name1", "delete"] call compile preprocessFileLineNumbers "NSA_Timer.sqf";
		-- Delete timer		
			Parameters: [<String>, "delete"] 					
			Return: (Int) 1 - if successful; -1 - if timer name not found

	
	-- by Nickorr

*/




NSA_Timer = compile preprocessFileLineNumbers "NSA_Timer.sqf";


private ["_timerName","_timerAction","_ttw","_return","_errorReporter","_timeRunner"];

_timerName = _this select 0;
_timerAction = _this select 1;
_ttw = 0;
_return = [];

if (isNil{NSA_timer_Array}) then { NSA_timer_Array = [] };

_errorReporter = {
	private ["_msg"];
	
	_msg = ("NSA_Timer ERROR! :: " + (_this select 0));
	diag_log _msg;
	hint _msg;
};

_timeRunner = {
	private ["_timerName","_timeLeft","_state","_curTimer","_timerID","_time"];
							
	_timerName = _this  select 0;
	_timeLeft = _this select 1;
	_state = _this select 2;
	_time = serverTime;
	_timerID = -1;

	while {(_timeLeft > 0) && (_state == 1)} do {
		_curTimer = [_timerName, "get"] call NSA_Timer;		// [ID, ["Name",ttw, timeLeft, state]]
		_timerID = _curTimer select 0;						// ID
		_curTimer = _curTimer select 1;						// ["Name",ttw, timeLeft, state]
		if (_timerID == -1) exitWith {};	// Timer is not in the array anymore. Terminate this scope.
		_state = _curTimer select 3;
		if (_state != 1) exitWith {};

		_timeLeft = ((_curTimer select 2) - (serverTime - _time)) max 0;
		_time = serverTime;
		
		
		if (((NSA_timer_Array select _timerID) select 0) == (_curTimer select 0)) then { (NSA_timer_Array select _timerID) set [2, _timeLeft]; };
	
		sleep 1;
	};
	
	_curTimer = [_timerName, "get"] call NSA_Timer;
	_timerID = _curTimer select 0;
	if (_timerID == -1) exitWith {};
	
	if ((_timeLeft <= 0)) then {
		(NSA_timer_Array select _timerID) set [2, 0];
		(NSA_timer_Array select _timerID) set [3, 0];
		
		NSA_timer_Alert = (NSA_timer_Array select _timerID) select 0;
		publicVariable "NSA_timer_Alert";
	};
};

switch (_timerAction) do {

	CASE "create" : {
		if ((count _this) >= 3) then {_ttw = _this select 2} else { ["TimeToWait parameter not specified"] call _errorReporter };
		if ( (([_timerName, "get"] call NSA_Timer) select 0) != -1 ) exitWith { ["Duplicate timer name!"] call _errorReporter };
		
		NSA_timer_Array pushBack [_timerName, _ttw, _ttw, 1];
		
		[_timerName, _ttw, 1] spawn _timeRunner;
	};
	
	CASE "get" : {
		if (count NSA_timer_Array > 0 ) then {
			{
				if ( (_x select 0) == _timerName) exitWith {
					_return = [_forEachIndex, _x];	// [1, ["Name",60, 10, 1]]
				};
				_return = [-1, []];	
			} forEach NSA_timer_Array;
		} else { _return = [-1, []]; };
		
	};
	
	CASE "getTime" : {
		if (count NSA_timer_Array > 0 ) then {
			{
				if ( (_x select 0) == _timerName) exitWith {
					_return = _x select 2;
				};
				_return = -1;
			} forEach NSA_timer_Array;
		} else { _return = -1; };
	};
	
	CASE "pause" : {
		if (count NSA_timer_Array > 0 ) then {
			{
				if ( (_x select 0) == _timerName) exitWith {
					
					if ((_x select 3) >= 1) then {
						_x set [3, 2];		// 2 - paused
					};
					_return = _forEachIndex;
				};
				_return = -1;
			} forEach NSA_timer_Array;
		} else { _return = -1; };
	};
	
	CASE "resume" : {
		if (count NSA_timer_Array > 0 ) then {	
			{
				if ( (_x select 0) == _timerName) exitWith {
					
					if ((_x select 3) > 1) then {
						_x set [3, 1];		// 2 - paused
						
						[_x select 0, _x select 2, _x select 3] spawn _timeRunner;
					};
					
					_return = _forEachIndex;
					
				};
				_return = -1;
			} forEach NSA_timer_Array;
		} else { _return = -1; };
	};
	
	CASE "delete" : {
		if (count NSA_timer_Array > 0 ) then {
			{
				if ( (_x select 0) == _timerName) exitWith {
					
					NSA_timer_Array deleteAt _forEachIndex;
					_return = 1;
					
				};
				_return = -1;
			} forEach NSA_timer_Array;
		} else { _return = -1; };
	};

};

_return










