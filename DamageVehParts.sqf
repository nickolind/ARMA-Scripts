//null=[position,"type",radius] execvm "DamageVehParts.sqf";
//
//null=[this,"landvehicle",1] execvm "DamageVehParts.sqf";
//
// position    = game logic over area
// "type"      = "landvehicle", "air","car","tank","boat"  possible types
// radius      = the area where your going to damage the objects.  
// zbran - weapon (gun)
// vez - turret mechanism
// "motor","pas_L","pas_P"

private ["_blgs", "_blg", "_blgtyp", "_scts", "_hitmx", "_sctcl", "_sct"];

_pos       =  _this select 0;
_what      =  _this select 1;
_radius    =  _this select 2;

_scts = [];
_blgs = nearestObjects [_pos, [_what],_radius];		//List of nearest vehicles

{ 
	_blg = _x; 		//Current Vehicle
	_blgtyp = typeOf _blg;
	
	_hitmx = (count (configFile >> "CfgVehicles" >> _blgtyp >> "HitPoints"))- 1 ;
	
	for "_i" from 0 to _hitmx do {
		_sctcl = (configFile >> "CfgVehicles" >> _blgtyp >> "HitPoints") select _i;
		_sct = getText(_sctcl >> "name");
		_scts = _scts + [_sct];
        copytoClipboard str _scts	
	};
	 //_x setHit ["engine_hit",0];// Damage defined vehicle part

/*{
   _blg setHit[_x,random (0.7) + 0.5];		//Damage random shit in Vehicle
 } forEach _scts;
 */

} forEach _blgs; 