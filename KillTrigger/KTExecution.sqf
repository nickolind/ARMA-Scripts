//null = [_tName, _cveh, crew _cveh select _y] execVM "KTExecution.sqf"; 

//Выполняется на клиентской машине
private ["_tName","_cvek","_victim","_willKill","_timeToWait","_message","_destroyVeh","_time"];

_tName = _this select 0;
_cvek = _this select 1;
_victim = _this select 2;
_willKill = _this select 3;
_timeToWait = _this select 4;
_message = _this select 5;
// _destroyVeh = if (count _this >= 7) then {_this select 6} else {false};

waitUntil {sleep 0.5; _victim getVariable "sent" == -1};

_victim setVariable ["sent", 1, true];

_time = serverTime;

if (_victim in vehicles) then {
	[[[_message, _victim, _tName], {
		private ["_victim"];
		_victim = _this select 1;
		waitUntil  { 		
			if ( !(_victim in list (_this select 2)) || !(player in crew _victim) || !(alive _victim) ) exitWith {true};
			titleText [_this select 0, "PLAIN"];
			sleep 0.5;
		};
	} ],"BIS_fnc_call", crew _victim] call BIS_fnc_MP;
	
	waitUntil  { 					
		if ( !(_victim in list _tName) ) exitWith {true};
		if (serverTime - _time >= _timeToWait) exitWith {true};	
		sleep 0.5;
	};
	
	if ( (_victim in list _tName) ) then {		
		if (_willKill == 1) then {
			_victim setDammage 1;		
		} else {
			_victim setVelocity [0,0,0];
			sleep 1;
			{moveOut _x;} forEach crew _victim;
			[[ [_victim], {
				(_this select 0) setVehicleLock "LOCKED";
			}],"BIS_fnc_call",_victim] call BIS_fnc_MP;
		};
	} else {
		[[[], {
			sleep 1;
			titleText ["Все хорошо - вы в безопасности", "PLAIN"];
		} ],"BIS_fnc_call", crew _victim] call BIS_fnc_MP;
	};
	
} else {

	waitUntil  { 							//подождать пока а) игрок выйдет из триггера, б) выйдет время
		if (player == _victim) then {titleText [_message, "PLAIN"];};
		// if (_victim in vehicles) then { [[[_message], {titleText [_this select 0, "PLAIN"]} ],"BIS_fnc_call", crew _victim] call BIS_fnc_MP };
		
		if (!(_victim in list _tName) && !((_cvek in list _tName) && (_victim in crew _cvek))) exitWith {true};
		if (serverTime - _time >= _timeToWait) exitWith {true};		//Продолжительность предупреждения прежде чем КТ убьет игрока (в секундах)
		sleep 0.5;
	};

	if ((_victim in list _tName) || ((_cvek in list _tName) && (_victim in crew _cvek))) then {				// ... и если все еще в триггере - активация
		if (_willKill == 1) then {
			_victim setDammage 1;		//Убиваем...
		} else {
			[_victim, true, 60] call ace_medical_fnc_setUnconscious;
			// [_victim, 60] call AGM_Medical_fnc_knockOut;		//Переход на ACE
			sleep 10;
			[_victim, true] call ACE_captives_fnc_setHandcuffed;
			// [_victim, true] call AGM_Captives_fnc_setCaptive;		//Переход на ACE
			moveOut _victim;
			sleep 5;
			
			if (alive _victim) then {
				[_victim] spawn {
					private ["_i","_ns_mark","_s_victim"];
					_s_victim = _this select 0;
					_i = 0;
					_ns_mark = createMarker [name _s_victim, position _s_victim ];
					_ns_mark setMarkerSize [0.7, 0.7];
					_ns_mark setMarkerType "mil_warning";
					_ns_mark setMarkerColor "ColorOrange";
					_ns_mark setMarkerText ("Нарушитель взят в плен");
					while {(_i < 60)} do {
						sleep 5;
						// _ns_mark setMarkerPos (position _s_victim);
						if ( (_s_victim getVariable ["ace_captives_ishandcuffed", false]) ) then {_ns_mark setMarkerPos (position _s_victim);};
						// if ( (_s_victim getVariable [QGVAR(isHandcuffed), false]) ) then {_ns_mark setMarkerPos (position _s_victim);};
						// if (alive _s_victim) then {_ns_mark setMarkerPos (position _s_victim);};
						_i = _i + 1;
					};
					deleteMarker _ns_mark;
				};
			};
			
			
			// _victim setDammage 0.4;		//или не убиваем, но сильно портим здоровье
			// _victim setHitPointDamage ["HitLeftArm", 1];
			// _victim setHitPointDamage ["HitRightArm", 1];		
			// [_victim, "", 1, objNull, objNull] call AGM_Medical_fnc_handleDamage;
			// if (random 10 >= 7.5) then { 		//Бессознанка с вероятностью в 25%
			// [_victim, (5 + (floor random 25))] call AGM_Medical_fnc_knockOut;
		};
	} else {
		if (player == _victim) then {titleText ["Все хорошо - вы в безопасности", "PLAIN"];};
	};
};

_victim setVariable ["sent", 0, true];