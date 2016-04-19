/* Not working properly with drones
Вызов из триггера, в поле OnActivation:
null = [thislist, thisTrigger, (timeToWait), (TriggerMode), [(objList)], [(groupList)], (customText)] execVM "KillTrigger_OP.sqf";

Параметры по умолчанию:
null = [thislist, thisTrigger, 15, 0, [], [], "Вы зашли в запретную зону. Вернитесь немедленно!"] execVM "KillTrigger_OP.sqf";

---
Принцип работы:
Создайте триггер в редакторе миссий. Триггеру обязательно назначьте имя (Name). В триггере выберите настройки активации - на синих (west), красных (east), всех (anybody) и т.п. Строка вызова скрипта помещается в поле "Активация (On Activation)" триггера. Включить режим "Repeatedly".

Как только в триггер заходит юнит, удовлетворяющий условиям триггера, триггер активируается, вызовет этот скрипт. Далее в соответствии с выбранным режимом.


---
Параметры:
- thislist : не изменять (список объектов в вызвавшем триггере)
- thisTrigger : не изменять (имя вызвавшего триггера)

- timeToWait (опционально) : продолжительность (в секундах) предупреждения об опасности, затем сработает скрипт наказания (убийство/нелетально). ПО УМОЛЧАНИЮ = 15
- TriggerMode (опционально) : режим работы скрипта (см.ниже). ПО УМОЛЧАНИЮ = 0
- [objList] (опционально) : список объектов по имени, которые будут включены/исключены из проверки скриптом (в зависимости от режима работы)
- [groupList] (опционально) : список групп по имени, которые будут включены/исключены из проверки скриптом (в зависимости от режима работы)
- customText (опционально) : собственный текст предупреждения об опасности (до срабатывания наказания).


---
Режимы работы скрипта:
0 - срабатывает на всех, удовлетворивших условие вызвавшего триггера. Убивать будет только людей. Если люди в транспорте - они умрут внутри, а машина останется нетронутой.
1 - исключает из обрабатываемых группы юнитов и объекты, указанные в соотв. параметрах. Если жертва в машине - жертва умрет, машина не пострадает. Если в списке исключения машина, то она будет "защищать" свой экипаж - экипаж будет игнорировать скрипт, пока он в этой машине.
2 - срабатывает исключительно на юнитов (людей) и группы юнитов, указанные в соотв. параметрах. Не реагирует на что-либо кроме юнитов-людей под контролем игроков.
8 - внутренний радиус - ускоряет таймер до убийства (время складывается от уже двух КТ). Ставить КТ с таким режимом только внутри другого КТ. Время может быть произвольным. Логично делать его меньше внешнего КТ. Например: внешний - 60 сек, внутренний - 10. При заходе во внутренний смерть наступит приблизительно за 7 секунд. При вызове скрипта в этом режиме параметры [objList], [groupList], willKill, customText - игнорируются (заполнить произвольными значениями (например нулями).


---
Пример вызова:

null = [thislist, thisTrigger, 10, 1, [], [grpSPN, grpDRG, grpTerminators]] execVM "KillTrigger_OP.sqf";
скрипт будет предупреждать в течении 10 секунд об опасности, а потом убьет всех, кроме членов групп grpSPN, grpDRG и grpTerminators

null = [thislist, thisTrigger, 25, 1, [superPlane, indestructableTank, RemboSoldier, BoxWithNarcotics], [], "Шеф, все пропало!"] execVM "KillTrigger_OP.sqf";
Скрипт будет предупреждать об опасности в течении 25 секунд с текстом "Шеф, все пропало!", у потом убьет/уничтожит всех, кроме объектов superPlane, indestructableTank, RemboSoldier, BoxWithNarcotics.


								by Nickorr
*/
if (isServer) then {

	if (missionNamespace getVariable ["ns_sm_debug", false]) exitWith {};

	private ["_thisList","_tName","_tMode","_objList","_grpList","_timeToWait","_message","_cveh","_isInGrp","_vehToKill","_y","_z"];

	_thisList = _this select 0;												// Использовать для ручного ввода параметров прямо в скрипт (при условии что скрипт был вызван следующей строкой):
	_tName = _this select 1;												// null = [thislist, thisTrigger] execVM "KillTrigger_OP.sqf"
	
	_timeToWait = 15;														//  	<-----------------------Время ожидания
	_tMode = 0;
	_objList = [];															//  	<-----------------------Список имен объектов ВПИСЫВАТЬ СЮДА (если вручную)
	_grpList = [];															//  	<-----------------------Список имен групп ВПИСЫВАТЬ СЮДА (если вручную)
	_message = "Вы зашли в запретную зону. Вернитесь немедленно!";			//  	<-----------------------Свое сообщение-предупреждение
	
	
	switch (count _this) do {
		CASE 3:
		{
			_timeToWait = _this select 2;
		};
		CASE 4:
		{
			_timeToWait = _this select 2;
			_tMode = _this select 3;
		};
		CASE 5:
		{
			_timeToWait = _this select 2;
			_tMode = _this select 3;
			_objList = _this select 4;
		};
		CASE 6:
		{
			_timeToWait = _this select 2;
			_tMode = _this select 3;
			_objList = _this select 4;
			_grpList = _this select 5;
		};
		CASE 7:
		{
			_timeToWait = _this select 2;
			_tMode = _this select 3;
			_objList = _this select 4;
			_grpList = _this select 5;
			_message = _this select 6;
		};
	};
	
	if ('(x2)' in triggerText _tName) then { _timeToWait = round(_timeToWait / 2) };
	
	
	switch (_tMode) do {
		CASE 1:		//Режим = 1 -  наказываем всех, кроме списков перечисленных
		{
			while {triggerActivated _tName} do {
				{
					_cveh = list _tName select _forEachIndex;
					
					if ( !(_cveh in _objList) && ( (getPosATL _cveh select 2) <= 50 ) ) then {		//Проверка на машину-контейнер-безопасности - не учитывать ее и всех пассажиров, если она в списке	
						
						for [{_y=0},{_y<(count (crew _cveh))},{_y=_y+1}] do {			//скан списка пассажиров юнита, вошедшего в триггер. Если юнит это транспорт - массив экипажа. Если это боец - он сам.
							_isInGrp = false;
						
							for [{_z=0},{_z<(count _grpList)},{_z=_z+1}] do {
								if ((crew _cveh select _y) in units (_grpList select _z)) exitWith {_isInGrp = true};
							}; 
							
							if ( !(_isInGrp) && !((crew _cveh select _y) in _objList) ) then {			//если не пренадлежит избранной группе и не является юнитом из списка исключений _objList, то наказать
			
								if ((crew _cveh select _y) getVariable "NSA_KT_Sent" != 0) exitWith {}; 		//Если у текущего юнита статус sentinel = 1, значит этого юнита уже обрабатывает скрипт - выходим из цикла
									
								(crew _cveh select _y) setVariable ["NSA_KT_Sent", -1, true];
								[[[_tName, _cveh, crew _cveh select _y, _timeToWait, _message],"KTExecution_OP.sqf"],"BIS_fnc_execVM", crew _cveh select _y] call BIS_fnc_MP;
							};
						};
					};
				} forEach _thisList;	//скан списка юнитов, вошедших в триггер
				sleep 1;
			};
		};
		
		CASE 2:		//Режим = 2 -  наказываем только перечисленных в списках
		{
			while {triggerActivated _tName} do {
			
				{
					_cveh = list _tName select _forEachIndex;
					
					if ( (getPosATL _cveh select 2) <= 50 ) then {
					
						if (_cveh in _objList) exitWith {
							// _vehToKill = 1;
							if (_cveh getVariable "NSA_KT_Sent" != 0) exitWith {}; 		//Если у текущего юнита статус sentinel = 1, значит этого юнита уже обрабатывает скрипт - выходим из цикла
								
							_cveh setVariable ["NSA_KT_Sent", -1, true];
							[[[_tName, _cveh, _cveh, _timeToWait, _message],"KTExecution_OP.sqf"],"BIS_fnc_execVM", _cveh] call BIS_fnc_MP;
						};
						

						for [{_y=0},{_y<(count (crew _cveh))},{_y=_y+1}] do {			//скан списка пассажиров юнита, вошедшего в триггер. Если юнит это транспорт - массив экипажа. Если это боец - он сам.
							_isInGrp = false;
						
							for [{_z=0},{_z<(count _grpList)},{_z=_z+1}] do {
									if ((crew _cveh select _y) in units (_grpList select _z)) exitWith {_isInGrp = true};
							}; 
							
							if ( (_isInGrp) || ((crew _cveh select _y) in _objList) ) then {			//если  пренадлежит избранной группе или является юнитом из списка исключений _objList, то наказать
			
								if ((crew _cveh select _y) getVariable "NSA_KT_Sent" != 0) exitWith {}; 		//Если у текущего юнита статус sentinel = 1, значит этого юнита уже обрабатывает скрипт - выходим из цикла
									
								(crew _cveh select _y) setVariable ["NSA_KT_Sent", -1, true];
								[[[_tName, _cveh, crew _cveh select _y, _timeToWait, _message],"KTExecution_OP.sqf"],"BIS_fnc_execVM", crew _cveh select _y] call BIS_fnc_MP;
							};
						};
					};
					
				} forEach _thisList;	//скан списка юнитов, вошедших в триггер
				sleep 1;
			};
		};
		
		CASE 8:		//Режим = 8 -  Внутренний радиус - ускорение таймера. Ускоряет таймер только тем юнитам, которые уже под активированным таймером КТ (NSA_KT_Sent != 0).
		{
			while {triggerActivated _tName} do {
			
				{
					_cveh = list _tName select _forEachIndex;
					
						for [{_y=0},{_y<(count (crew _cveh))},{_y=_y+1}] do {			//скан списка пассажиров юнита, вошедшего в триггер. Если юнит это транспорт - массив экипажа. Если это боец - он сам.

							if ( ((crew _cveh select _y) getVariable "NSA_KT_Sent" != 0) && ((crew _cveh select _y) getVariable ["NSA_KT_SentInner",0] == 0) ) then {
							
								(crew _cveh select _y) setVariable ["NSA_KT_SentInner", -1, true];
								[[[_tName, _cveh, crew _cveh select _y, _timeToWait, "inner"],"KTExecution_OP.sqf"],"BIS_fnc_execVM", crew _cveh select _y] call BIS_fnc_MP;
							
							}; 
						};
				} forEach _thisList;	//скан списка юнитов, вошедших в триггер
				sleep 1;
			};
		};

		DEFAULT		//Режим = 0 (по умолчанию) - наказываем всех
		{	
			while {triggerActivated _tName} do {
				{
					_cveh = list _tName select _forEachIndex;
						
					if ( (getPosATL _cveh select 2) <= 50 ) then {
						for [{_y=0},{_y<(count (crew _cveh))},{_y=_y+1}] do {			//скан списка пассажиров юнита, вошедшего в триггер. Если юнит это транспорт - массив экипажа. Если это боец - он сам.
						
							if ((crew _cveh select _y) getVariable "NSA_KT_Sent" != 0) exitWith {}; 		//Если у текущего юнита статус sentinel = 1, значит этого юнита уже обрабатывает скрипт - выходим из цикла
								
							(crew _cveh select _y) setVariable ["NSA_KT_Sent", -1, true];
							[[[_tName, _cveh, crew _cveh select _y, _timeToWait, _message],"KTExecution_OP.sqf"],"BIS_fnc_execVM", crew _cveh select _y] call BIS_fnc_MP;
						};
					};
				} forEach _thisList;	//скан списка юнитов, вошедших в триггер
				sleep 1;
			};
		};
	};
};