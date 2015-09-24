/*
//null = [180, trg1, 1] execVM "nss_FrzTimeForWMT.sqf";

//ServerSide Script

Описание:
Скрипт добавляет дополнительный фризтайм к основному (WMT платформы). Фризтайм применяется только к юнитам, которые находились в триггере на момент запуска миссии. Транспорт блокируется, а солдаты (если mode = 1) не могут отойти от центра триггера дальше дистанции, указанной в параметре distance. 

Как использовать:
1. Создать в редакторе триггер. Параметр 'Activation' выставить на 'ANYBODY', включена кнопка 'Repeatedly', а так же включена 'Present'. Ввести триггеру корректное имя (например trg1 );
2. Расположить триггер в месте, где юниты должны быть заблокированы фризтаймом
3. Расположить на триггере юнитов (если юнит внутри зоны триггера, то а)если он - техника - он будет заблокирован, б) если он - солдат - он не сможет уйти дальше значения distance от цетра данного триггера.
4. Положить файл скрипта в папку с миссией
5. Вызвать скрипт в ините миссии:

Вызов из initServer.sqf строкой:

null = [Time, triggerName, Mode, Distance] execVM "nss_FrzTimeForWMT.sqf";

Или вызов из init.sqf строкой:

if (isServer) then {
	null = [Time, triggerName, Mode, Distance] execVM "nss_FrzTimeForWMT.sqf";
};

Параметры:
Time - время фризтайма в секундах (таймер стартует после окончания основного фризтайма WMT)
triggerName - имя триггера, к которому скрипт привязывается
(Mode) - (не обязательно) Режим работы. Варианты: 
				0 - блокируется только техника, пехота может убежать. 
				1 - блокируется техника и пехота. 
				(По умолчанию - 0)
(Distance) - (не обязательно - используется при mode=1) Дистанция от центра зоны триггера, на которую игрокам можно отходить. (По умолчанию - наибольшая дистанция от центра до края триггера)

	
*/
private["_ttw","_trig","_tMode","_frzDist","_tLeft","_frzStartPos","_frzMaxDist","_vehList","_playersList"];

waitUntil {sleep 1; time > 0};

if (missionNamespace getVariable ["ns_sm_debug", false]) exitWith {};

_ttw = _this select 0;
_trig = _this select 1;
_tMode = 0;
_frzDist = if (triggerArea _trig select 3) then {sqrt (((triggerArea _trig select 0) ^ 2) + ((triggerArea _trig select 1) ^ 2))} else {if ((triggerArea _trig select 0) > (triggerArea _trig select 1)) then {triggerArea _trig select 0} else {triggerArea _trig select 1};  }; 
if ((count _this) >= 3) then {_tMode = _this select 2;};
if ((count _this) >= 4) then {_frzDist = _this select 3;};
_tLeft = _ttw;
_frzStartPos = position _trig;
_frzMaxDist = _frzDist + (_frzDist * 0.25);

_trig setVariable ["ns_vehFreeze", 1, true];
_trig setVariable ["ns_timeLeft", _tLeft];

		//Поиск юнитов в триггере
_vehList = [];
_playersList = [];
{
	if ( (_x isKindof "Ship" || _x isKindof "Air" || _x isKindof "LandVehicle") ) then {
		_vehList pushBack _x;
	};	
	if (_x in crew _x) then {
		_playersList pushBack _x;
	};
} forEach list _trig;

{
	// _x setVehicleLock "LOCKED";
	_x lockDriver true;
	// sleep 0.01;
} forEach _vehList;

if (_tMode == 1) then {
	[_trig, _frzStartPos, _frzDist, _playersList] spawn {
		_trigS = _this select 0;
		_frzStartPosS = _this select 1;
		_frzDistS = _this select 2;
		_playersListS = _this select 3;
		_frzMaxDistS = _frzDistS + 20;
		
		while {_trigS getVariable "ns_vehFreeze" == 1} do {					
			{
					_dist = _x distance _frzStartPosS;
					if ( (_dist > _frzDistS) && (_dist < _frzMaxDistS) && (isPlayer _x) ) then {
						[[ [], {
							_msg = "<t size='0.75' color='#ff0000'>"+localize "STR_WMT_FreezeZoneFlee" +"</t>";
							[_msg, 0, 0.25, 3, 0, 0, 27] spawn bis_fnc_dynamicText;
						}],"BIS_fnc_call", _x] call BIS_fnc_MP;
					};
					if (_dist > _frzMaxDistS) then {
						_x setVelocity [0,0,0];
						_x setPos (_frzStartPosS findEmptyPosition [1,_frzDistS, typeOf _x]);
					};
				
				sleep 0.1;
				
			} forEach _playersListS;
			sleep 1;
		};
	};
};

{
	if (isPlayer _x) then {
		[[ [_tMode], {
			if (_this select 0 == 1) then {
				hint "Включен дополнительный фризтайм.\n\nИгрокам, находящимся в зоне, запрещено ее покидать.\n\nТехника внутри зоны заблокирована.";
			} else {
				hint "Включен дополнительный фризтайм.\n\nТехника внутри зоны заблокирована.";
			};
		}],"BIS_fnc_call", _x] call BIS_fnc_MP;
	};
	sleep 0.05;
} forEach list _trig;

waitUntil {sleep 1; WMT_pub_frzState >= 3}; //==3 when freeze over, ==1 when freeze up

					//----------------------Система уведомления подошедших солдат о состоянии фризтайма
[_trig] spawn {
	_trig = _this select 0;
	while {_trig getVariable "ns_vehFreeze" == 1} do {					//Пока фризтайм включен...
		{																	//Для каждого юнита в триггере...
			if ((_x in crew _x) && (isPlayer _x) && (isNil {_x getVariable "ns_warned"}) ) then {	//Если юнит - человек И еще не получал уведомление...	
				
		//------Клиентский блок кода
				[[ [_trig, _trig getVariable "ns_timeLeft"], {								//Сервер отправляет код для локального выполнения клиенту, которому принадлежит текущий солдат.
					_trigL = _this select 0;													
					_ttwL = _this select 1;														//Передаем актуальное время таймера с сервера клиенту, а дальше клиент делает парралельное вычисление для отображение локально
					_tLeftL = _ttwL;															//Локальный таймер будет удален, когда игрок выйдет из зоны.
																								//Цель - не нагружать сетевой канал посекундными запросами об актуальном времени сервера	
					player setVariable ["ns_warned", 1, true];									//Отмечаем, что солдат "Уведомлен"
					_timeL = serverTime;																				
					
					while { (_trigL getVariable "ns_vehFreeze" == 1) && (!isNil {player getVariable "ns_warned"}) } do {		//Пока фризтайм включен и солдат в состоянии "уведомлен" - делаем свои дела...
						
						_tLeftL = _ttwL - (serverTime - _timeL);
						
						hint format ['Дополнительный фризтайм.\nДо разблокировки техники:\n\n%1', [_tLeftL,"MM:SS"] call BIS_fnc_secondsToString];
						
						if !(player in list _trigL) exitWith {																//Если юнит вышел из триггера, убираем у него состояние "уведомлен" и выходим из цикла, завершая клиентский блок кода
							player setVariable ["ns_warned", nil, true];
							hint "Зона фризтайма покинута";
						};
						sleep 1;
					};
				}],"BIS_fnc_call", _x] call BIS_fnc_MP;
		//------Конец клиентского блока кода
				
			};
		} forEach list _trig;
		sleep 1;
	};	
};

		//Ждем, когда время фризтайма выйдет
_frzTime = serverTime;
waitUntil  { 

	_tLeft = _ttw - (serverTime - _frzTime);
	_trig setVariable ["ns_timeLeft", _tLeft];
	
	if (_trig getVariable "ns_vehFreeze" == 0) exitWith {true};
	
	if (_tLeft < 0) exitWith {
		_trig setVariable ["ns_vehFreeze", 0, true];
		true
	};
	sleep 1;
};

		//------------------------------------Фризтайм окончен:
{
	// _x setVehicleLock "UNLOCKED";
	[[ [_x], {
		(_this select 0) lockDriver false;
	}],"BIS_fnc_call",_x] call BIS_fnc_MP;
		
	// sleep 0.01;
} forEach _vehList;
{
	_x setVariable ["ns_warned", nil, true];
	if (isPlayer _x) then {
		[[ [], {
			sleep 2;
			hint "Фризтайм окончен";
		}],"BIS_fnc_call", _x] call BIS_fnc_MP;
	};
	sleep 0.05;
} forEach list _trig;