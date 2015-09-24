/*
v. 2.01

by Nickorr


//-------------------------------------------------------------------------//

null = [] execVM "ns_PrivateBox\pb_server.sqf";

^ call from initServer.sqf ^

Аргументов нет

//-------------------------------------------------------------------------//
Описание:
1. Скрипт привязывает ящики к конкретной группе/отделению (или несколькоим группам). Использовать ящик смогут только члены привязанных групп. Все остальные смогут только узнать примерное содержимое ящика. Так же хинтом дается информация кому ящик принадлежит.

2. Если ящик привязан к отделению, а к началу миссии отделение было занято менее чем наполовину, то ящик будет удален. Если ящик привязан к нескольким отделениям, то будет учитываться сумма всех занявших слоты бойцов из привязанных групп, относительно общего номинального числа солдат в группах.


//-------------------------------------------------------------------------//
Инструкция по использованию:
1. В редакторе: поставить юнита/группу юнитов, поставить ящик;

2. В редакторе: Связать группу с ящиком с помощью Синхронизации (Synchronisation (F5));

3. 	Вызвать основную часть скрипта из файла initServer.sqf строкой:
		
		null = [] execVM "ns_PrivateBox\pb_server.sqf";
	
	Либо вызвать основную часть из файла init.sqf строкой:
		
		if (isServer) then {
			null = [] execVM "ns_PrivateBox\pb_server.sqf";
		};

4. 	Вызвать клиентскую часть скрипта из файла initPlayerLocal.sqf строкой:
		
		null = [] execVM "ns_PrivateBox\pb_client.sqf";
	
5. Готово.


//-------------------------------------------------------------------------//
Дополнительная информация:
- К данному ящику можно привязать произвольное количество юнитов/групп;
- К данному юниту/отделению можно привязать произвольное количество ящиков;
- Ящики, не синхронизированные ни с одним живым юнитом, будут общедоступными;
- Лучше не ставить ближе 1-го метров от закрытого ящика никаких других предметов (ящики, технику, предметы инвентаря) - чтобы избежать ошибок, глюков и эксплоитов со стороны игроков;
- Лучше не ставить ближе 2-х метров от закрытого ящика другой закрытый ящик - по тем же причинам.



*/

if (isNil "hmg_privateBoxes") then {hmg_privateBoxes = [];};

if (missionNamespace getVariable ["ns_sm_debug", false]) exitWith {};

{
	_y = _x;
	{
		if (_x isKindOf "Thing") then {
			if !(_x in hmg_privateBoxes) then {
				hmg_privateBoxes pushBack _x; 
			};
			
			if (isNil {_x getVariable "hmg_boxOwnedBy"}) then {
				_x setVariable ["hmg_boxOwnedBy", [], true];
				_x getVariable "hmg_boxOwnedBy" pushBack group _y; 							//Добавляем элемент в конец массива
				_x setVariable ["hmg_boxOwnedBy", _x getVariable "hmg_boxOwnedBy", true];	//Броадкастим значение для всех
			} else { 
				if !(group _y in (_x getVariable "hmg_boxOwnedBy")) then {
					_x getVariable "hmg_boxOwnedBy" pushBack group _y; 
					_x setVariable ["hmg_boxOwnedBy", _x getVariable "hmg_boxOwnedBy", true];
				};
			};
		};
	} forEach synchronizedObjects _y;
} forEach allUnits;
publicVariable "hmg_privateBoxes";


//Удаление ящиков для отделений занятых менее чем наполовину:
//---------------------------
// waitUntil {sleep 1; time > 0};

// {
	// if (_x isKindOf "Thing") then {
		// _unit = _x;
		// _playersNum = 0;
		// _ownGrps = _unit getVariable "hmg_boxOwnedBy";
		
		// {
			// _playersNum = _playersNum + ({isPlayer _x} count units _x);
		// } forEach _ownGrps;
		// if (_playersNum < ( ({count units _x} forEach _ownGrps) / 2) ) then {
			// _unit setVariable ["hmg_boxOwnedBy", nil, true];
			// deleteVehicle _unit;
		// };
	// };
// } forEach hmg_privateBoxes;
//----------------------------