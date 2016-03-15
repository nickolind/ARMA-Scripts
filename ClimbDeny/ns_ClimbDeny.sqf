// null = [] execVM "ns_ClimbDeny.sqf";

/*

Свои значения проходимости (может задать картодел в init.sqf):
	ns_cd_custom_vehPassability = [ ["rhs_sprut_vdv",35], ["rhs_2s3_tv",30] ];

*/


/* ToDo

- Закончить составление таблицы классов техники
- эффект "рытья земли" когда буксуют и сползают
- ns_cd_vehPassabilityArray - вынести в отдельный файл для удобства
- Сделать мод из скрипта

*/

// блок для тестирования
ns_cd_surfaseHumidity = nil;
ns_cd_testing = false;
sleep 4;
ns_cd_testing = true;
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
	
	["rhs_2s3_tv",			27],
	
	// Модель с множеством модификаций или копий с другим класнеймом - обозначать с решеткой-префиксом и только заглавными буквами + цифрами
	// Модификации располагать в порядке: ( длиннейший индекс сначала, ... , базовая модель - последней )

	// ["#T72BA",			23],
	// ["#T72BB",			23],
	// ["#T72BC",			23],
	// ["#T72BD",			23],
	// ["#T80U",			23],
	// ["#T80",			23],
	// ["#T90A",			23],
	// ["#T90",			23],
	
	// ["#ZSU234",			23],
	// ["#BRM1K",			23],
	// ["#PRP3",			23],
	// ["#PTS",			23],
	// ["#9K79",			23], // Точка-У
	
	// ["#BMD4MA",			23],
	// ["#BMD4M",			23],
	// ["#BMD4",			23],
	
	// ["#BMD2M",			23],
	// ["#BMD2K",			23],
	// ["#BMD2",			23],
	
	// ["#BMD1PK",			23],
	// ["#BMD1P",			25],
	// ["#BMD1K",			26],
	// ["#BMD1R",			26],
	// ["#BMD1",			30],
	
	// ["#BMP3M",			29],
	// ["#BMP3",			29],
	
	// ["#BMP2K",			29],
	// ["#BMP2E",			29],
	// ["#BMP2D",			29],
	// ["#BMP2",			29],
	
	// ["#BMP1P",			29],
	// ["#BMP1K",			29],
	// ["#BMP1D",			29],
	// ["#BMP1",			25],
	
	// ["#BTR80A",			25],
	// ["#BTR80",			25],
	// ["#BTR70",			25],
	// ["#BTR60",			25],
	
	// ["#BRDM2",			25],
	
	// ["#BM21",			25],
	
	// ["#TYPHOON",		25],
	// ["#URAL",			25],
	// ["#GAZ66",			35],
	
	// ["#UAZ",			25],
	// ["#TIGR",			25],

	// ["DEFAULT",			31]
	
	["#SPRUT",			31],    	//спрут
	["#BMD4",			31],    	//бмд4
	["#BMD",			29],    	//бмд1 и 2, а так же машины на их базе
	["#BMP3",			27],		//БМП3
	["#BMP2D",			27],		//БМП2Д
	["#BMP1D",			27],		//БМП1Д
	["#BMP",			31],		//все первые и вторые БМПшки
	["#PRP3",			31],		//ПРП на базе первой БМП
	["#PTS",			27],		//ПТС
	["#ZSU",			27],		//зсу
	["#9K79",			27], 		// Точка-У
	["#BTR",			27],		//БТРы
	["#BRDM",			27],		//БРДМы
	["#BM21",			27],		
	["#URAL",			27],		//манишы наследуемые от УРАЛа
	["#TYPHOON",		22],		//Kamaz63968
	["#GAZ66",			31],		//ГАЗ66
	["#KAMAZ",			31],		
	["#UAZ",			31],		//уазики
	["#TIGR_STS",		27],		//тигр СТС с 5ым классом бронирования
	["#TIGR",			45],		//тигр и тигр-М (двннные взяты с 2 левых сайтов, по тигр-м практически ничего)
	
	["#T72",			27],
	["#T80",			29],
	["#T90",			27],
	["#T34",			27],
	["#T55",			29],

	["#COYOTE",			31],
	["#HEMTT",			31],
	["#HMMWV",			31],
	["#JACKAL",			31],
	["#FMTV",			31],
	["#LAV25",			31],
	["#M1126",			31],
	["#M1128",			31],
	["#M1129",			31],
	["#M1130",			31],
	["#M1133",			31],
	["#M1135",			31],
	["#MK23",			31],
	["#MK27",			31],
	["#MaxxPro",		31],
	["#RG33",			31],
	["#OFFROAD",		31],		//условный ванильный Offroad
	["#QUADBIKE",		22],		//условный ванильный Quadbike (взято максимально значение с форумов владельцев граждански АТВ)
	["#HILUX",			27],		//точных данных не нашел, написанно по форумным перепискам.
	["#LANDROVER",		45],
	["#CARS_LR",		45],		//ландроверы Масси
	
	["#M109",			31],
	["#M113",			31],
	["#M1A",			31],
	["#M2A",			31],

	["#TRUCK",			31],
	
	["DEFAULT",			31]
];

ns_cd_slippingActive = false;
ns_cd_escapeVeh = false;

private ["_curVeh"];

_curVeh = objNull;




ns_cd_calculate_MSA = {
	private ["_vehicle","_vehPassability","_terrainCoef","_humidityCoef","_isOnRoad"];
	
	_vehicle = _this select 0;	
	_vehPassability = _this select 1;
	_terrainCoef = 0;
	_humidityCoef = 0;
	
	while {ns_cd_testing && !ns_cd_escapeVeh} do {
		
		_isOnRoad = if (count ((_vehicle) nearRoads 15) != 0) then {1} else {0};
		
		if (_isOnRoad == 1) then 
			{ _terrainCoef = 1; } else { _terrainCoef = _vehPassability * 0.1 };
			
		if ( _vehicle isKindOf "Tank" ) then { _humidityCoef = _vehPassability * 0.15 } else { _humidityCoef = _vehPassability * 0.25 };
		
		ns_cd_maxSlopeAngle = (_vehPassability * 0.9) - ( 		// -10% от паспортных данных машины
				(_terrainCoef) 
				+ 
				(_humidityCoef * ns_cd_surfaseHumidity * (0.5 * (1 + (1 - _isOnRoad)))) 
														// на дороге - 	0.5 * (1 + (1-1)) = 0.5 * 1 = 0.5 - эффект влажной поверхности действует на 50%
														// не на дороге - 	0.5 * (1 + (1-0)) = 0.5 * 2 = 1 - эффект влажной поверхности действует на 100%		
			);
		sleep 0.43;
	};
};

ns_getVehClassname = {
	private ["_vehicle","_vcn_found","_vcn_result"];
	
	_vehicle = _this select 0;
	
	_vcn_found = false;
	_vcn_result = [];
	
	if (!(_vcn_found) && !(isNil"ns_cd_custom_vehPassability")) then {
		
		{	
			if ( (_x select 0) == typeof _vehicle ) exitWith {_vcn_found = true; _vcn_result = _x};	
		} forEach ns_cd_custom_vehPassability;
	};

	if !(_vcn_found) then {
		{	
			if ( (_x select 0) == typeof _vehicle ) exitWith {_vcn_found = true; _vcn_result = _x};	
		} forEach ns_cd_vehPassabilityArray;
	};

	if !(_vcn_found) then {
		{	
			if ( 
				(((toArray(_x select 0)) select 0) == 35) // 35 = "#"
				&& 
				( ( toUpper(typeof _vehicle) find ((_x select 0) select [1]) ) != -1 )
			
			) exitWith {_vcn_found = true; _vcn_result = _x};	
			
		} forEach ns_cd_vehPassabilityArray;
	};

	if (!(_vcn_found) ) then {
		_vcn_found = true; 
		_vcn_result = ns_cd_vehPassabilityArray select (count ns_cd_vehPassabilityArray - 1);	// ["DEFAULT",			31]
	};
	
	_vcn_result
};


ns_climbAngleLimitExceeded = {
	private ["_return"];
	_return = if (acos ((vectorUp (_this select 0)) vectorDotProduct ([0,0,1]) ) > (_this select 1)) then {true} else {false};
	_return
};


ns_spReduceSoft = {	 
	while {ns_cd_testing && !ns_cd_escapeVeh} do {
		sleep 0.05;
		
		ns_cd_limit = (ns_cd_limit - 1) max 0;												// Линейное замедление
		// ns_cd_limit = (ns_cd_limit - (3 * (2 / (ns_cd_limit max 4)))) max 0;				// Нелинейное замедление (не подобрана функция)
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
	private ["_timeToSlip"];
	
	_timeToSlip = 6;
	
	while {ns_cd_testing && !ns_cd_escapeVeh} do {
		
		if (ns_cd_gl_counter <= 0) exitWith {ns_cd_slippingActive = false;};
		
		if ( (ns_cd_gl_counter >= _timeToSlip) && !(ns_cd_slippingActive) ) then {
			ns_cd_slippingActive = true;
		} else {
			if ( abs(speed (_this select 0)) < 5 ) then {
				ns_cd_gl_counter = (ns_cd_gl_counter + 1) min _timeToSlip;
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
				
		[_curVeh, ( [_curVeh] call ns_getVehClassname ) select 1 ] spawn ns_cd_calculate_MSA;

		
		["ns_ClimbDeny_loop", "onEachFrame", {
		
			private ["_vehicle","_speed","_surfaceAngle"];
			
			_vehicle = _this select 0;
			
			// убрать hint
			
			hint format ["%1\n%2\n%3\n%4\n%5\n%6\n%7\n%8\n%9\n%10", 
				( [_vehicle] call ns_getVehClassname ),
				ns_cd_maxSlopeAngle,
				acos ((vectorUp _vehicle) vectorDotProduct ([0,0,1])),
				(acos ((surfaceNormal position _vehicle) vectorDotProduct ([0,0,1]) )),
				ns_cd_limit,
				speed _vehicle,
				velocity _vehicle,
				ns_lc_coef,
				ns_lc_tick,
				ns_cd_gl_counter
			];
			

			if ( (player != driver _vehicle) || !(ns_cd_testing) ) then {
				["ns_ClimbDeny_loop", "onEachFrame"] call BIS_fnc_removeStackedEventHandler;
				ns_cd_escapeVeh = true;
				hint ""; // убрать hint
			};

			_speed = abs(speed _vehicle);
			_surfaceAngle = acos ((surfaceNormal position _vehicle) vectorDotProduct ([0,0,1]) );
					
				
			
			
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
				
				
			} else {ns_cd_gl_counter = -1; ns_cd_limit = 999; ns_cd_slippingActive = false;};
			
			if ( (ns_cd_slippingActive) && (_surfaceAngle > ns_cd_maxSlopeAngle) && (_surfaceAngle > 25) && (_speed < 5) ) then {
				if (ns_cd_loop_ticker >= 1) then {
				
					// _slipVector = ((surfaceNormal (position _vehicle)) vectorDiff [0,0,1]) vectorMultiply 0.2;
					_slipVector = ( ((surfaceNormal (position _vehicle)) vectorDiff [0,0,1]) vectorAdd [0,0,-0.5]) vectorMultiply 0.19;
					
					if ((velocity _vehicle) select 2 > 0) then {
						if (ns_lc_coef == 0 ) then {ns_lc_tick = 0.0; ns_lc_coef = -1.2; [_vehicle] spawn ns_slipForce};
						_slipVector = _slipVector vectorAdd ((velocity _vehicle) vectorMultiply ns_lc_coef);
					};
					if (ns_lc_coef != 0) then { ns_lc_tick = ns_lc_tick + ((velocity _vehicle) select 2)};
					
					_vehicle setVelocity ((velocity _vehicle) vectorAdd _slipVector);
				};
			};	
			
			if (ns_cd_loop_ticker >= 1) then {
				ns_cd_loop_ticker = 0;
			} else {ns_cd_loop_ticker = ns_cd_loop_ticker + 1};
			
		}, [_curVeh]] call BIS_fnc_addStackedEventHandler;
		
		
		waitUntil {sleep 0.5; ns_cd_escapeVeh || !ns_cd_testing};
	};
	
	sleep 2;
};


