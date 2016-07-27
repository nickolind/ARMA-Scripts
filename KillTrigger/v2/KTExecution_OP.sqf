//null = [_tName, _cveh, crew _cveh select _y] execVM "KTExecution_OP.sqf"; 

//Выполняется на клиентской машине
private ["_tName","_cvek","_victim","_timeToWait","_timeToWaitParam","_tHight","_mNotify","_message","_destroyVeh","_time","_timeToKill","_prefix"];

_tName = _this select 0;
_cvek = _this select 1;
_victim = _this select 2;
_timeToWait = _this select 3;
_tHight = _this select 4;
_mNotify = _this select 5;
_message = _this select 6;



/* ------------------------------- Этот код хорошо бы вынести в отдельный файл -------------------------------------- */
if ( (_message == "inner") ) exitWith {		// Попадение во внутренний радиус - ускорение таймера (остальную часть скрипта - не выполняем)
	
	waitUntil {
		sleep 0.5; 
		if (_victim getVariable ["NSA_KT_Sent",0] == 0) exitWith {true};
		if (_victim getVariable ["NSA_KT_SentInner",0] == -1) exitWith {
			
			_victim setVariable ["NSA_KT_SentInner", 1, true];

			_time = serverTime;
			
			waitUntil  { 							//подождать пока а) игрок выйдет из триггера, б) выйдет время			

				_victim setVariable ["NSA_KT_TimeToKill", (_victim getVariable ["NSA_KT_TimeToKill",0.0]) + ((serverTime - _time) / _timeToWait), true];
				_time = serverTime;
				
				if (
					( !(_victim in list _tName) && !((_cvek in list _tName) && (_victim in crew _cvek)) )
					|| 
					( !((getPosATL _victim select 2) <= _tHight) && !(((getPosATL _cvek select 2) <= _tHight) && (_victim in crew _cvek)) )
					||
					(_victim getVariable ["NSA_KT_Sent",0] == 0)
					||
					!(alive _victim)
				) exitWith {true};
				
				sleep 0.5;
				
			};
			
		_victim setVariable ["NSA_KT_SentInner", 0, true];
		true 
		};
	
	};
};
/* --------------------------------------------------------------------- */



waitUntil {sleep 0.5; _victim getVariable "NSA_KT_Sent" == -1};

_victim setVariable ["NSA_KT_Sent", 1, true];

if (isNil{_victim getVariable "NSA_KT_TimeToKill"}) then {_victim setVariable ["NSA_KT_TimeToKill", 0.0, true]};

_timeToKill = 0.0;
_time = serverTime;



/* ----------- Авто создание маркера на позиции где зашли на КТ ------- */
if (_mNotify >= 1) then {
	[_victim, _tName] spawn {

		private ["_i","_ns_mark","_s_victim","_mrk_text","_s_time"];
		_s_victim = _this select 0;
		_i = 0;
		_mrk_text = format ["%1:%2", 
						side group _s_victim, 
						getText (configFile >> "CfgVehicles" >> (typeof vehicle _s_victim) >> "displayName")
					];
		_ns_mark = if ( getMarkerColor ("NSA_KT_" + (name _s_victim)) == "" ) then {
			createMarker ["NSA_KT_" + (name _s_victim), position _s_victim ];
		} else { 
			("NSA_KT_" + (name _s_victim));
		};
		
		// _ns_mark setMarkerPos (position _s_victim);
		_ns_mark setMarkerSize [0.7, 0.7];
		_ns_mark setMarkerType "mil_warning";
		_ns_mark setMarkerColor "ColorCIV";
		// _ns_mark setMarkerText ( format ["%1(%2)", _mrk_text, ([daytime, "HH:MM:SS"] call BIS_fnc_timeToString)] );
		
		[[[], {
			["<t color='#FFA500' size = '.6'>Пересечение зоны КТ (карта обновлена)</t>",0,0.9,5,0.7,0,789] call bis_fnc_dynamictext;
		}],"BIS_fnc_call"] call BIS_fnc_MP;
		
		waitUntil {
		
			_ns_mark setMarkerPos (position _s_victim);
			_ns_mark setMarkerText ( format ["%1(%2)", _mrk_text, ([daytime, "HH:MM:SS"] call BIS_fnc_timeToString)] );
			
			sleep 10;
			if !(alive _s_victim) exitWith {
				_ns_mark setMarkerColor "ColorBlack";
				_ns_mark setMarkerText ( format ["%1(%2) - Уничтожен", _mrk_text, ([daytime, "HH:MM:SS"] call BIS_fnc_timeToString)] );	
				true
			};
			if (_s_victim getVariable ["NSA_KT_Sent",0] == 0) exitWith { 
				_ns_mark setMarkerText ( format ["%1(%2)", _mrk_text, ([daytime, "HH:MM:SS"] call BIS_fnc_timeToString)] );
				true
			};
		};
		_ns_mark setMarkerPos (position _s_victim);
		_s_time = serverTime;
		
		waitUntil {
			sleep 5;
			
			if (_s_victim getVariable ["NSA_KT_Sent",0] != 0) exitWith { true };
			if ((serverTime - _s_time) >= _tHight)  exitWith {deleteMarker _ns_mark; true};
				
		};

	};
};
/* --------------------------------------------------------------------- */


			
/* ----------- Код только для режима = 2 (целевой КТ на технику) ------- */
if (_victim in vehicles) exitWith {
	[[[_message, _victim, _tName], {
		private ["_victim"];
		_victim = _this select 1;
		waitUntil  { 		
			if ( !(_victim in list (_this select 2)) || !(player in crew _victim) || !(alive _victim) || !((getPosATL _victim select 2) <= _tHight) ) exitWith {true};
			_prefix = if (_victim getVariable ["NSA_KT_SentInner",0] == 1) then { ">>> ОПАСНОСТЬ! <<<\nТаймер ускорен! Вернитесь!!" } else {""};
			// titleText [ format ["%1\n%2\nОсталось: %3%4", _prefix, _this select 0, 100 - (round (_timeToKill * 1000) / 10),"% (0% - смерть)"], "PLAIN"];
			titleText [ format ["%1\n%2\nОсталось:\n\n%3с.", _prefix, _message,  0 max (round (_timeToWait - (_timeToKill * _timeToWait)))], "PLAIN"];
			sleep 0.5;
		};
	} ],"BIS_fnc_call", crew _victim] call BIS_fnc_MP;
	
	waitUntil  { 
		_timeToKill = (_victim getVariable "NSA_KT_TimeToKill") + ((serverTime - _time) / _timeToWait);
		if ( !(_victim in list _tName) || !((getPosATL _victim select 2) <= _tHight) || ( _timeToKill >= 1.0) ) exitWith { _victim setVariable ["NSA_KT_TimeToKill", _timeToKill, true]; true};
		sleep 0.5;
	};
			
	if ( _timeToKill >= 1 ) then {		
		_victim setDammage 1;		
	} else {
		[[[], {
			sleep 1;
			titleText ["Все хорошо - вы в безопасности", "PLAIN"];
		} ],"BIS_fnc_call", crew _victim] call BIS_fnc_MP;
	};
	
};

/* --------------------------------------------------------------------- */



waitUntil  { 							//подождать пока а) игрок выйдет из триггера, б) выйдет время
	_timeToKill = (_victim getVariable "NSA_KT_TimeToKill") + ((serverTime - _time) / _timeToWait);
	
	if (player == _victim) then {
		_prefix = if (_victim getVariable ["NSA_KT_SentInner",0] == 1) then { ">>> ОПАСНОСТЬ! <<<\nТаймер ускорен!" } else {""};
		// titleText [ format ["%1\n%2\nОсталось: %3%4", _prefix, _message, 100 - (round (_timeToKill * 1000) / 10),"% (0% - смерть)"], "PLAIN"];
		// titleText [ format ["%1\n%2\nОсталось: %3с.", _prefix, _message,  round ((_timeToWait - (_timeToKill * _timeToWait)) * 10) / 10], "PLAIN"];
		titleText [ format ["%1\n%2\nОсталось:\n\n%3с.", _prefix, _message,  0 max (round (_timeToWait - (_timeToKill * _timeToWait)))], "PLAIN"];
	};
	
	if (
		( !(_victim in list _tName) && !((_cvek in list _tName) && (_victim in crew _cvek)) )
		|| 
		( !((getPosATL _victim select 2) <= _tHight) && !(((getPosATL _cvek select 2) <= _tHight) && (_victim in crew _cvek)) )
	) exitWith {_victim setVariable ["NSA_KT_TimeToKill", _timeToKill, true]; true};
	if ( _timeToKill >= 1 ) exitWith {_victim setVariable ["NSA_KT_TimeToKill", _timeToKill, true]; true};		//Продолжительность предупреждения прежде чем КТ убьет игрока (в секундах)
	sleep 0.5;
};


if (_timeToKill >= 1) then {				// ... и если все еще в триггере - активация
	_victim setDammage 1;		//Убиваем...
	if (vehicle _victim isKindOf "Tank") then {vehicle _victim setDammage 1};		// И взрываем технику (если это танк)
} else {
	if (player == _victim) then {titleText ["Все хорошо - вы в безопасности", "PLAIN"];};
};


_victim setVariable ["NSA_KT_TimeToKill", _timeToKill, true];
_victim setVariable ["NSA_KT_Sent", 0, true];

[_victim] spawn {		// 5 сек задержки, прежде чем обнулить таймер - защита против быстрого пересечения череды КТ.
	private ["_victimL","_timeL"];
	_victimL = _this select 0;
	_timeL = serverTime;
	
	waitUntil {
		sleep 0.2;
		
		if (_victimL getVariable ["NSA_KT_Sent",0] != 0) exitWith { true };
		
		if ((serverTime - _timeL) >= 5) exitWith { _victimL setVariable ["NSA_KT_TimeToKill", 0.0, true]; };	
	};
	
};


