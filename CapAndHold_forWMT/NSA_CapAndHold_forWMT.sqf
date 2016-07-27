/* 

1. Поставить модуль WMT: Capture Points
	а) в init модуля вписать:
		NSA_MC_Captured = false;
	б) в поле Condition вписать:
		NSA_MC_Captured

2. В файл init.sqf вписать:
	null = ["zoneMarker", zoneTrigger, int_time, sideToCapture] execVM "NSA_CapAndHold_forWMT.sqf";
	
	Где:
		"zoneMarker" 	- имя маркера зоны (обязательно в кавычках)
		zoneTrigger 	- имя триггера зоны (параметры триггера: Activation - Anybody; Repeatable - включить; Расположение и размеры триггера должны совпадать с таковыми у маркера зоны).
		int_time 		- продолжительность в секундах
		sideToCapture	- сторона, которой нужно захватить и удерживать зону (должно совпадать с настройкой модуля WMT Capture Points - Winner Side).
						Возможные варианты:
							EAST
							WEST
							RESISTANCE
							CIVILIAN 	(может не работать)

	Пример:
		null = ["mZone_0", trg_mZone_0, 600, RESISTANCE] execVM "NSA_CapAndHold_forWMT.sqf";
		
3. Остальное - как обычно.
*/

if (isServer) then {

	private ["_TEM","_ttw","_trig","_colorToSide","_time","_timeElapsed","_timeElapsedMark","_cappingSide"];

	_TEM = 10;	// Период обновления таймера (в целях уменьшения нагрузки на трафик)
	_trig = _this select 1;
	_ttw = _this select 2;
	_cappingSide = _this select 3;

	waitUntil {sleep 1; !isNil{NSA_MC_Captured} };

	_colorToSide = {
		switch (_this) do 
			{
				case "ColorBlufor":		{WEST};
				case "ColorBLUFOR":		{WEST};
				case "ColorWEST":		{WEST};
				case "ColorOpfor":		{EAST};
				case "ColorOPFOR":		{EAST};
				case "ColorEAST":		{EAST};
				case "ColorIndependent":{RESISTANCE};
				case "ColorGUER":		{RESISTANCE};
				case "ColorCivilian":	{CIVILIAN};
				case "ColorCIV":		{CIVILIAN};
				default 		{sideLogic}
			};
	};



	
	while {!NSA_MC_Captured} do {
		_time = serverTime;
		_timeElapsed = 0;
		_timeElapsedMark = _TEM;

		while {( ((getMarkerColor (_this select 0)) call _colorToSide) == _cappingSide)} do {
			
			_timeElapsed = _timeElapsed + (serverTime - _time);
			_time = serverTime;
			
			if ( (_timeElapsed >= _timeElapsedMark) ) then {
				_timeElapsedMark = _timeElapsedMark + _TEM;
				
				{
					if ( (_x in list _trig) || !(alive _x) ) then {
						[[ [_ttw, _timeElapsed], {	
							hint format ['Необходимо удерживать зону еще:\n\n%1', [0 max ((_this select 0)-(_this select 1)),"MM:SS"] call BIS_fnc_secondsToString];
						}],"BIS_fnc_call", _x] call BIS_fnc_MP;
					};
				} forEach playableUnits;
				
			};
			
			if (
					(_timeElapsed >= _ttw)
				) exitWith {
					NSA_MC_Captured = true;
					publicVariable "NSA_MC_Captured";
				};
			
			sleep 1;
		};

		
		sleep 1;
	};
	
};



