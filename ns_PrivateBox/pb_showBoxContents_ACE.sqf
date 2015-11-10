/*
null = [_container] execVM "ns_PrivateBox\pb_showBoxContents_ACE.sqf";
Вызвается из pb_client.sqf

Скрипт зависит от функций ACE Interaction - без этого компонента, вызывать скрипт не стоит.
*/
private ["_unit", "_listedItemClasses", "_actions", "_allGear"];

_unit = _this select 0;

_listedItemClasses = [];

_actions = ["Содержимое ящика:", localize ""] call ACE_Interaction_fnc_prepareSelectMenu;

_allGear = [];

if (count (weaponCargo _unit) > 0) then {
  _allGear = _allGear + (weaponCargo _unit);
};
if (count (itemCargo _unit) > 0) then {
  _allGear = _allGear + (itemCargo _unit);
};
if (count (magazineCargo _unit) > 0) then {
  _allGear = _allGear + (magazineCargo _unit);
};
if (count (backpackCargo _unit) > 0) then {
  _allGear = _allGear + (backpackCargo _unit);
};

{
  if (!(_x in _listedItemClasses)) then {
    private "_item";
    _item = configFile >> "CfgMagazines" >> _x;
    if (isNil "_item" || str _item == "") then {
      _item = configFile >> "CfgWeapons" >> _x;
    };
	if (isNil "_item" || str _item == "") then {
      _item = configFile >> "CfgGlasses" >> _x;
    };
	if (isNil "_item" || str _item == "") then { 
      _item = configFile >> "CfgVehicles" >> _x;
    };
    _actions = [_actions, getText(_item >> "displayName"), getText(_item >> "picture"), _x] call ACE_Interaction_fnc_addSelectableItem;
    _listedItemClasses pushBack _x;
  };
} forEach (_allGear);

[_actions, {call ACE_Interaction_fnc_hideMenu;}, {call ACE_Interaction_fnc_hideMenu;}] call ACE_Interaction_fnc_openSelectMenu;

// don't need an "Ok" Button
ctrlShow [8860, false];