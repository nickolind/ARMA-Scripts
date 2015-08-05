/*
null = [this, 1] execVM "nss_shapeMission.sqf";

Unit init field: 	runs on every machine

*/
if (isServer) then {

	private ["_unit","_neededThreshold","_selectedThreshold", "_thVars","_markerstr"];
	
	_thVars = ["30-60", "60-100",	"100-130",	"130-160"];
	
	_selectedThreshold = "PlayersCount" call BIS_fnc_getParamValue;
	_unit = _this select 0;
	_neededThreshold = _this select 1;
	
	_markerstr = createMarker ["mrkShapeInfo", [0, -200]];
	_markerstr  setMarkerColor "ColorRed";
	// _markerstr  setMarkerText ("Выбрана версия миссии для " + (_thVars select _selectedThreshold) + " игроков.");
	_markerstr  setMarkerType "mil_warning";
	
	if (_selectedThreshold == 666) then {
		_markerstr  setMarkerText ("Выбрана версия миссии для ОТЛАДКИ");
		ns_sm_debug = true;
		publicVariable "ns_sm_debug";
	} else {
		_markerstr  setMarkerText ("Выбрана версия миссии для " + (_thVars select _selectedThreshold) + " игроков.");
		if (_selectedThreshold < _neededThreshold) then {
			deleteVehicle _unit;
		};
	};
	

};