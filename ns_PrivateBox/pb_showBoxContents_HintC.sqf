/*
null = [_container] execVM "ns_PrivateBox\pb_showBoxContents_HintC.sqf";
Вызвается из pb_client.sqf

*/
private ["_unit", "_listedItemClasses", "_allGear", "_compText"];

_unit = _this select 0;

_allGear = [];
_listedItemClasses = [];

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

_compText = composeText [parseText "<t size='1.2' align='center' underline='true' shadow='2'>Содержимое ящика:<br/></t>"];

{
  if (!(_x in _listedItemClasses)) then {
    private ["_item","_itemImage","_itemName","_invItem"];
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
	_itemImage = getText(_item >> "picture"); 
	_itemName = getText(_item >> "displayName");
	_invItem = composeText [parseText "<br/>", image _itemImage, " ", _itemName];
	_compText = composeText [_compText, _invItem];
    _listedItemClasses pushBack _x;
  };
} forEach (_allGear);


sleep 0.01;
"" hintC _compText;

hintC_arr_EH = findDisplay 72 displayAddEventHandler ["unload", {
	0 = _this spawn {
		_this select 0 displayRemoveEventHandler ["unload", hintC_arr_EH];
		hintSilent "";
	};
}];