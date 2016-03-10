// null = [] execVM "ns_ClimbDeny.sqf";

/*

Свои значения проходимости (может задать картодел в init.sqf):
	ns_cd_custom_vehPassability = [ ["rhs_sprut_vdv",35], ["rhs_2s3_tv",30] ];

*/


/* ToDo

- эффект "рытья земли" когда буксуют и сползают
- Локализовать переменные где это возможно
- ns_cd_vehPassabilityArray - вынести в отдельный файл для удобства

*/

// убрать блок по окончании тестирования: 
ns_cd_surfaseHumidity = nil;
ns_cd_testing = false;
sleep 4;
ns_cd_testing = true;
ns_spolz_hint = "-"; // убрать ns_spolz_hint
// -------------------------------------


waitUntil {sleep 1; time > 0 };

if (isServer) then {
	ns_cd_surfaseHumidity = rain;
	publicVariable "ns_cd_surfaseHumidity";
};

if (isDedicated) exitWith {};

waitUntil {sleep 1; !isNil{ns_cd_surfaseHumidity} };



ns_cd_vehPassabilityArray = [
	
	// Классы уникальной техники (без модификаций или копий):
	
	["rhs_sprut_vdv",		35],
	["rhs_2s3_tv",			30],
	
	// Модель с множеством модификаций или копий с другим класнеймом - обозначать с решеткой-префиксом и только заглавными буквами + цифрами
	// Модификации располагать в порядке: ( длиннейший индекс сначала, ... , базовая модель - последней )

	["#T72BA",			23],
	["#T72BB",			23],
	["#T72BC",			23],
	["#T72BD",			23],
	["#T80U",			23],
	["#T80",			23],
	["#T90A",			23],
	["#T90",			23],
	
	["#ZSU234",			23],
	["#BRM1K",			23],
	["#PRP3",			23],
	["#PTS",			23],
	["#9K79",			23], // Точка-У
	
	["#BMD4MA",			23],
	["#BMD4M",			23],
	["#BMD4",			23],
	
	["#BMD2M",			23],
	["#BMD2K",			23],
	["#BMD2",			23],
	
	["#BMD1PK",			23],
	["#BMD1P",			25],
	["#BMD1K",			26],
	["#BMD1R",			26],
	["#BMD1",			30],
	
	["#BMP3M",			29],
	["#BMP3",			29],
	
	["#BMP2K",			29],
	["#BMP2E",			29],
	["#BMP2D",			29],
	["#BMP2",			29],
	
	["#BMP1P",			29],
	["#BMP1K",			29],
	["#BMP1D",			29],
	["#BMP1",			25],
	
	["#BTR80A",			25],
	["#BTR80",			25],
	["#BTR70",			25],
	["#BTR60",			25],
	
	["#BRDM2",			25],
	
	["#BM21",			25],
	
	["#TYPHOON",		25],
	["#URAL",			25],
	["#GAZ66",			35],
	
	["#UAZ",			25],
	["#TIGR",			25],

	["DEFAULT",			31]
];

ns_cd_slippingActive = false;
ns_cd_vehPassability = ( ns_cd_vehPassabilityArray select (count ns_cd_vehPassabilityArray - 1) ) select 1;
ns_cd_timeToSlip = 6;
ns_cd_escapeVeh = false;

private ["_curVeh"];


ns_cd_calculate_MSA = {
	private ["_terrainCoef"];
	
	// _vehicle = _this select 0;	
	// _vehPassability = _this select 1;
	_terrainCoef = 0;
	
	while {ns_cd_testing && !ns_cd_escapeVeh} do {
		
		
		if (count ((_this select 0) nearRoads 15) == 0) then 
			{ _terrainCoef = 5; } else { _terrainCoef = 1; };
		
		ns_cd_maxSlopeAngle = (_this select 1) - ( (_terrainCoef) + (6 * ns_cd_surfaseHumidity) );
		
		sleep 0.43;
	};
};

ns_getVehClassname = {
	private ["_vehicle"];
	
	_vehicle = _this select 0;
	
	ns_vcn_found = false;
	ns_vcn_result = [];
	
	if (!(ns_vcn_found) && !(isNil"ns_cd_custom_vehPassability")) then {
		
		{	
			if ( (_x select 0) == typeof _vehicle ) exitWith {ns_vcn_found = true; ns_vcn_result = _x};	
		} forEach ns_cd_custom_vehPassability;
	};

	if !(ns_vcn_found) then {
		{	
			if ( (_x select 0) == typeof _vehicle ) exitWith {ns_vcn_found = true; ns_vcn_result = _x};	
		} forEach ns_cd_vehPassabilityArray;
	};

	if !(ns_vcn_found) then {
		{	
			if ( 
				(((toArray(_x select 0)) select 0) == 35) // 35 = "#"
				&& 
				( ( toUpper(typeof _vehicle) find ((_x select 0) select [1]) ) != -1 )
			
			) exitWith {ns_vcn_found = true; ns_vcn_result = _x};	
			
		} forEach ns_cd_vehPassabilityArray;
	};

	if (!(ns_vcn_found) ) then {
		ns_vcn_found = true; 
		ns_vcn_result = ns_cd_vehPassabilityArray select (count ns_cd_vehPassabilityArray - 1);	// ["DEFAULT",			31]
	};
	
	ns_vcn_result
};


ns_climbAngleLimitExceeded = {
	private ["_return"];
	_return = if (acos ((vectorUp (_this select 0)) vectorDotProduct ([0,0,1]) ) > (_this select 1)) then {true} else {false};
	_return
};


ns_spReduceSoft = {	 
	while {ns_cd_testing && !ns_cd_escapeVeh} do {
		sleep 0.05;
		ns_cd_limit = (ns_cd_limit - 1) max 0;
		// ns_cd_limit = (ns_cd_limit - (3 * (2 / (ns_cd_limit max 4)))) max 0;
		if ( 
			(ns_cd_limit <= (_this select 1)) 
			|| 
			!([(_this select 0), ns_cd_maxSlopeAngle] call ns_climbAngleLimitExceeded) 
			|| 
			!((velocity (_this select 0)) select 2 > 0) 
		) exitWith { ns_srsState = 1};
		// ns_srsState = 0 -- Undone
		// ns_srsState = 1 -- Done
	};
};


ns_gripLose = {
	while {ns_cd_testing && !ns_cd_escapeVeh} do {
		
		if (ns_cd_gl_counter <= 0) exitWith {ns_cd_slippingActive = false; ns_spolz_hint = "-";};	// убрать ns_spolz_hint
		
		if ( (ns_cd_gl_counter >= ns_cd_timeToSlip) && !(ns_cd_slippingActive) ) then {
			ns_cd_slippingActive = true;
		} else {
			if ( abs(speed (_this select 0)) < 5 ) then {
				ns_cd_gl_counter = (ns_cd_gl_counter + 1) min ns_cd_timeToSlip;
			} else {ns_cd_gl_counter = 1};
		};

		sleep 1;
	};
};


ns_slipForce = {
	while {ns_cd_testing && !ns_cd_escapeVeh} do {
		
		if !(ns_cd_slippingActive) exitWith {ns_lc_coef = 0;};
		
		if (ns_lc_tick > 0.01) then {
			ns_lc_coef = (ns_lc_coef - 0.1) max -3;
		};
		
		ns_lc_tick = 0.0;
		sleep 1;
	};
};




while {ns_cd_testing} do {
	if ( (player != vehicle player ) && (player == driver vehicle player) && (vehicle player isKindOf "Land") ) then {
		ns_cd_escapeVeh = false;
		_curVeh = vehicle player;

		ns_cd_limit = 999;
		ns_srsState = 1;
		ns_cd_loop_ticker = 0;
		ns_cd_gl_counter = 0;
		ns_lc_coef = 0;
				
		ns_cd_vehPassability = ( [_curVeh] call ns_getVehClassname ) select 1;

		[_curVeh, ns_cd_vehPassability] spawn ns_cd_calculate_MSA;

		
		["ns_ClimbDeny_loop", "onEachFrame", {
		
			private ["_driver","_vehicle","_speed"];
			
			_driver = _this select 0;
			_vehicle = _this select 1;
			
			// убрать hint
			hint format ["%1\n%2\n%3\n%4\n%5\n%6\n%7\n%8\n%9\n%10", 
				ns_vcn_result,
				acos ((vectorUp _vehicle) vectorDotProduct ([0,0,1])),
				(acos ((surfaceNormal position _vehicle) vectorDotProduct ([0,0,1]) )),
				ns_cd_limit,
				speed _vehicle,
				velocity _vehicle,
				ns_lc_coef,
				ns_lc_tick,
				ns_cd_gl_counter,
				ns_spolz_hint
			];

			if ( (_driver != driver _vehicle) || !(ns_cd_testing) ) then {
				["ns_ClimbDeny_loop", "onEachFrame"] call BIS_fnc_removeStackedEventHandler;
				ns_cd_escapeVeh = true;
				hint ""; // убрать hint
			};

			_speed = abs(speed _vehicle);
			
					
			if ( (ns_cd_slippingActive) && (acos ((surfaceNormal position _vehicle) vectorDotProduct ([0,0,1]) ) > ns_cd_maxSlopeAngle) && (_speed < 5) ) then {
				if (ns_cd_loop_ticker >= 1) then {
				
					// _slipVector = ((surfaceNormal (position _vehicle)) vectorDiff [0,0,1]) vectorMultiply 0.2;
					_slipVector = ( ((surfaceNormal (position _vehicle)) vectorDiff [0,0,1]) vectorAdd [0,0,-0.5]) vectorMultiply 0.19;
					
					if ((velocity _vehicle) select 2 > 0) then {
						// if (ns_lc_coef == 0 ) then {ns_lc_tick = false; ns_lc_coef = -1.2; [_vehicle] spawn ns_slipForce} else { if ((velocity _vehicle) select 2 > 0) then {ns_lc_tick = true}};
						if (ns_lc_coef == 0 ) then {ns_lc_tick = 0.0; ns_lc_coef = -1.2; [_vehicle] spawn ns_slipForce};
						_slipVector = _slipVector vectorAdd ((velocity _vehicle) vectorMultiply ns_lc_coef);
					};
					if (ns_lc_coef != 0) then { ns_lc_tick = ns_lc_tick + ((velocity _vehicle) select 2)};
					
					_vehicle setVelocity ((velocity _vehicle) vectorAdd _slipVector);
					ns_spolz_hint = "Сползание"; // убрать hint
				} else {ns_spolz_hint = "-"}; // убрать hint
			};		
			
			
			if ( ([_vehicle, ns_cd_maxSlopeAngle] call ns_climbAngleLimitExceeded) ) then {
			
				if ( (ns_cd_gl_counter <= 0) ) then {ns_cd_gl_counter = 1; [_vehicle] spawn ns_gripLose};

				if (ns_srsState == 1) then {
					if ( ((velocity _vehicle) select 2 > 0) && (ns_cd_limit > 0) ) then {
								ns_srsState = 0;
								ns_cd_limit = abs(speed _vehicle) + 1;
								[_vehicle, 0] spawn ns_spReduceSoft; 
					};
					if ( ((velocity _vehicle) select 2 < 0) ) then {
						ns_cd_limit = 999;
					};
				};
				
				
				if ( (_speed > 0) && ((velocity _vehicle) select 2 > 0) )  then {
					
					if (ns_cd_loop_ticker >= 1) then {
						_vehicle setVelocity ((velocity _vehicle) vectorMultiply (0 max ( (1 min (ns_cd_limit / _speed)) - 0.00001)) );						
					};
				};
				
				
			} else {ns_cd_gl_counter = -1; ns_cd_limit = 999; ns_cd_slippingActive = false; ns_spolz_hint = "-"};	// убрать ns_spolz_hint
			
			if (ns_cd_loop_ticker >= 1) then {
				ns_cd_loop_ticker = 0;
			} else {ns_cd_loop_ticker = ns_cd_loop_ticker + 1};
			
		}, [player, _curVeh]] call BIS_fnc_addStackedEventHandler;
		
		
		waitUntil {sleep 0.5; ns_cd_escapeVeh || !ns_cd_testing};
	};
	
	sleep 2;
};


