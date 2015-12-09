/*
null = [] execVM "ns_PrivateBox\pb_client.sqf";


^ call from initPlayerLocal.sqf ^

Аргументов нет
*/

waitUntil {sleep 1;  !(isNull player) };	

player addEventHandler ["InventoryOpened", {
	_result = false;
	_unit = _this select 0;
	_container = _this select 1; 
	
	if !(_container isKindOf "Thing") then {
		{
			if (_x in hmg_privateBoxes) then {_container = _x;};
		} forEach ((position _unit) nearEntities ["Thing", 2]);
	};
	
	// hint format ["%1\n%2\n%3", _container, _container distance _unit, !(_container isKindOf "Thing")];		// <-- Для отладки
	
	if ((_container in hmg_privateBoxes)) then {
		_tArray = (_container getVariable "hmg_boxOwnedBy");
		_str = "";
		{
			if (!isNull(_tArray select _forEachIndex)) then {
				_str = _str + groupId (_tArray select _forEachIndex) + " (" + str (side (_tArray select _forEachIndex)) + ")<br/>(Ком.: " + name leader (_tArray select _forEachIndex) + ")<br/><br/>";
			} else {_str = "Н/Д";};
		} forEach _tArray;
		if !(group _unit in _tArray ) then {
			_result = true;
			hint parseText format ["<t color='#ff0000'>У вас нет доступа.</t><br/><br/>Ящик принадлежит:<br/>%1", _str];
			null = [_container] execVM "ns_PrivateBox\pb_showBoxContents_HintC.sqf";														// Реализация без зависимостей от платформ или модов (через hintC)
			// null = [_container] execVM "ns_PrivateBox\pb_showBoxContents_ACE.sqf";													// ЗАВИСИМОСТЬ ОТ ФУНКЦИЙ AGM: ACE_Interaction_fnc_ 	
		} else {
			hint parseText format ["Ящик принадлежит:<br/>%1", _str];
		}; 
	};
	_result
}];