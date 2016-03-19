// null = [] execVM "fn_ClimbDeny_Main.sqf";

/*

Свои значения проходимости (может задать картодел в init.sqf):
	NSA_CD_custom_vehPassability = [ ["rhs_sprut_vdv",35], ["rhs_2s3_tv",30] ];

*/


/* ToDo

- Закончить составление таблицы классов техники
- эффект "рытья земли" когда буксуют и сползают

*/

#include "vehPassabilityRef.sqf"



// блок для тестирования
NSA_CD_surfaseHumidity = nil;
NSA_CD_active = false;
sleep 4;
NSA_CD_active = true;
// -------------------------------------



waitUntil {sleep 1; time > 0 };

if (isServer) then {
	NSA_CD_surfaseHumidity = rain;
	publicVariable "NSA_CD_surfaseHumidity";
};

if (isDedicated) exitWith {};

waitUntil {sleep 1; !isNil{NSA_CD_surfaseHumidity} };



NSA_CD_slippingActive = false;
NSA_CD_escapeVeh = false;

private ["_curVeh"];

_curVeh = objNull;




NSA_CD_fn_calculate_MSA = {
	private ["_vehicle","_vehPassability","_terrainCoef","_humidityCoef","_isOnRoad"];
	
	_vehicle = _this select 0;	
	_vehPassability = _this select 1;
	_terrainCoef = 0;
	_humidityCoef = 0;
	
	while {NSA_CD_active && !NSA_CD_escapeVeh} do {
		
		_isOnRoad = if (count ((_vehicle) nearRoads 15) != 0) then {1} else {0};
		
		if (_isOnRoad == 1) then 
			{ _terrainCoef = 1; } else { _terrainCoef = _vehPassability * 0.1 };
			
		if ( _vehicle isKindOf "Tank" ) then { _humidityCoef = _vehPassability * 0.15 } else { _humidityCoef = _vehPassability * 0.25 };
		
		NSA_CD_maxSlopeAngle = (_vehPassability * 0.9) - ( 		// -10% от паспортных данных машины
				(_terrainCoef) 
				+ 
				(_humidityCoef * NSA_CD_surfaseHumidity * (0.5 * (1 + (1 - _isOnRoad)))) 
														// на дороге - 	0.5 * (1 + (1-1)) = 0.5 * 1 = 0.5 - эффект влажной поверхности действует на 50%
														// не на дороге - 	0.5 * (1 + (1-0)) = 0.5 * 2 = 1 - эффект влажной поверхности действует на 100%		
			);
		sleep 0.43;
	};
};

NSA_CD_fn_getVehClassname = {
	private ["_vehicle","_vcn_found","_vcn_result"];
	
	_vehicle = _this select 0;
	
	_vcn_found = false;
	_vcn_result = [];
	
	if (!(_vcn_found) && !(isNil"NSA_CD_custom_vehPassability")) then {
		
		{	
			if ( (_x select 0) == typeof _vehicle ) exitWith {_vcn_found = true; _vcn_result = _x};	
		} forEach NSA_CD_custom_vehPassability;
	};

	if !(_vcn_found) then {
		{	
			if ( (_x select 0) == typeof _vehicle ) exitWith {_vcn_found = true; _vcn_result = _x};	
		} forEach NSA_CD_vehPassabilityArray;
	};

	if !(_vcn_found) then {
		{	
			if ( 
				(((toArray(_x select 0)) select 0) == 35) // 35 = "#"
				&& 
				( ( toUpper(typeof _vehicle) find ((_x select 0) select [1]) ) != -1 )
			
			) exitWith {_vcn_found = true; _vcn_result = _x};	
			
		} forEach NSA_CD_vehPassabilityArray;
	};

	if (!(_vcn_found) ) then {
		_vcn_found = true; 
		_vcn_result = NSA_CD_vehPassabilityArray select (count NSA_CD_vehPassabilityArray - 1);	// ["DEFAULT",			31]
	};
	
	_vcn_result
};


NSA_CD_fn_climbAngleLimitExceeded = {
	private ["_return"];
	_return = if (acos ((vectorUp (_this select 0)) vectorDotProduct ([0,0,1]) ) > (_this select 1)) then {true} else {false};
	_return
};


NSA_CD_fn_spReduceSoft = {	 
	while {NSA_CD_active && !NSA_CD_escapeVeh} do {
		sleep 0.05;
		
		NSA_CD_limit = (NSA_CD_limit - 1) max 0;												// Линейное замедление
		// NSA_CD_limit = (NSA_CD_limit - (3 * (2 / (NSA_CD_limit max 4)))) max 0;				// Нелинейное замедление (не подобрана функция)
		if ( 
			(NSA_CD_limit <= (_this select 1)) 
			|| 
			!([(_this select 0), NSA_CD_maxSlopeAngle] call NSA_CD_fn_climbAngleLimitExceeded) 
			|| 
			!((velocity (_this select 0)) select 2 > 0) 
		) exitWith { NSA_CD_srsState = 1};
		// NSA_CD_srsState = 0 -- Undone
		// NSA_CD_srsState = 1 -- Done
	};
};


NSA_CD_fn_gripLose = {
	private ["_timeToSlip"];
	
	_timeToSlip = 6;
	
	while {NSA_CD_active && !NSA_CD_escapeVeh} do {
		
		if (NSA_CD_gl_counter <= 0) exitWith {NSA_CD_slippingActive = false;};
		
		if ( (NSA_CD_gl_counter >= _timeToSlip) && !(NSA_CD_slippingActive) ) then {
			NSA_CD_slippingActive = true;
		} else {
			if ( abs(speed (_this select 0)) < 5 ) then {
				NSA_CD_gl_counter = (NSA_CD_gl_counter + 1) min _timeToSlip;
			} else {NSA_CD_gl_counter = 1};
		};

		sleep 1;
	};
};


NSA_CD_fn_slipForce = {
	while {NSA_CD_active && !NSA_CD_escapeVeh} do {
		
		if !(NSA_CD_slippingActive) exitWith {NSA_CD_lcCoef = 0;};
		
		if (NSA_CD_lcTick > 0.01) then {
			NSA_CD_lcCoef = (NSA_CD_lcCoef - 0.1) max -3;
		};
		
		NSA_CD_lcTick = 0.0;
		sleep 1;
	};
};






while {NSA_CD_active} do {
	if ( (player != vehicle player ) && (player == driver vehicle player) && (vehicle player isKindOf "Land") ) then {
		NSA_CD_escapeVeh = false;
		_curVeh = vehicle player;

		NSA_CD_limit = 999;
		NSA_CD_srsState = 1;
		NSA_CD_loop_ticker = 0;
		NSA_CD_gl_counter = 0;
		NSA_CD_lcCoef = 0;
				
		[_curVeh, ( [_curVeh] call NSA_CD_fn_getVehClassname ) select 1 ] spawn NSA_CD_fn_calculate_MSA;

		
		["NSA_ClimbDeny_loop", "onEachFrame", {
		
			private ["_vehicle","_speed","_surfaceAngle"];
			
			_vehicle = _this select 0;
			
			// убрать hint
			// hint format ["%1\n%2\n%3\n%4\n%5\n%6\n%7\n%8\n%9\n%10", 
				// ( [_vehicle] call NSA_CD_fn_getVehClassname ),
				// NSA_CD_maxSlopeAngle,
				// acos ((vectorUp _vehicle) vectorDotProduct ([0,0,1])),
				// (acos ((surfaceNormal position _vehicle) vectorDotProduct ([0,0,1]) )),
				// NSA_CD_limit,
				// speed _vehicle,
				// velocity _vehicle,
				// NSA_CD_lcCoef,
				// NSA_CD_lcTick,
				// NSA_CD_gl_counter
			// ];
			

			if ( (player != driver _vehicle) || !(NSA_CD_active) ) then {
				["NSA_ClimbDeny_loop", "onEachFrame"] call BIS_fnc_removeStackedEventHandler;
				NSA_CD_escapeVeh = true;
				// hint ""; // убрать hint
			};

			_speed = abs(speed _vehicle);
			_surfaceAngle = acos ((surfaceNormal position _vehicle) vectorDotProduct ([0,0,1]) );
					
				
			
			
			if ( ([_vehicle, NSA_CD_maxSlopeAngle] call NSA_CD_fn_climbAngleLimitExceeded) ) then {
			
				if ( (NSA_CD_gl_counter <= 0) ) then {NSA_CD_gl_counter = 1; [_vehicle] spawn NSA_CD_fn_gripLose};

				if (NSA_CD_srsState == 1) then {
					if ( ((velocity _vehicle) select 2 > 0) && (NSA_CD_limit > 0) ) then {
								NSA_CD_srsState = 0;
								NSA_CD_limit = abs(speed _vehicle) + 1;
								[_vehicle, 0] spawn NSA_CD_fn_spReduceSoft; 
					};
					if ( ((velocity _vehicle) select 2 < 0) ) then {
						NSA_CD_limit = 999;
					};
				};
				
				
				if ( (_speed > 0) && ((velocity _vehicle) select 2 > 0) )  then {
					
					if (NSA_CD_loop_ticker >= 1) then {
						_vehicle setVelocity ((velocity _vehicle) vectorMultiply (0 max ( (1 min (NSA_CD_limit / _speed)) - 0.00001)) );						
					};
				};
				
				
			} else {NSA_CD_gl_counter = -1; NSA_CD_limit = 999; NSA_CD_slippingActive = false;};
			
			if ( (NSA_CD_slippingActive) && (_surfaceAngle > NSA_CD_maxSlopeAngle) && (_surfaceAngle > 25) && (_speed < 5) ) then {
				if (NSA_CD_loop_ticker >= 1) then {
				
					// _slipVector = ((surfaceNormal (position _vehicle)) vectorDiff [0,0,1]) vectorMultiply 0.2;
					_slipVector = ( ((surfaceNormal (position _vehicle)) vectorDiff [0,0,1]) vectorAdd [0,0,-0.5]) vectorMultiply 0.19;
					
					if ((velocity _vehicle) select 2 > 0) then {
						if (NSA_CD_lcCoef == 0 ) then {NSA_CD_lcTick = 0.0; NSA_CD_lcCoef = -1.2; [_vehicle] spawn NSA_CD_fn_slipForce};
						_slipVector = _slipVector vectorAdd ((velocity _vehicle) vectorMultiply NSA_CD_lcCoef);
					};
					if (NSA_CD_lcCoef != 0) then { NSA_CD_lcTick = NSA_CD_lcTick + ((velocity _vehicle) select 2)};
					
					_vehicle setVelocity ((velocity _vehicle) vectorAdd _slipVector);
				};
			};	
			
			if (NSA_CD_loop_ticker >= 1) then {
				NSA_CD_loop_ticker = 0;
			} else {NSA_CD_loop_ticker = NSA_CD_loop_ticker + 1};
			
		}, [_curVeh]] call BIS_fnc_addStackedEventHandler;
		
		
		waitUntil {sleep 0.5; NSA_CD_escapeVeh || !NSA_CD_active};
	};
	
	sleep 2;
};


