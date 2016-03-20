// #include "vehPassabilityRef.sqf"

NSA_CD_vehPassabilityArray = [
	
	// Классы уникальной техники (без модификаций или копий):
	
	["rhs_2s3_tv",			30],		// Акация
	// ["RHS_M6",				31],		// M6A2
	// ["RHS_M6_wd",			31],		
	// ["rhsusf_m109d_usarmy",	31],
	// ["rhsusf_m109_usarmy",	31],
	// ["DAR_4X4",	31],				// MTVR 4x4
	["sub_ins_weu_offroad",	33],		// M998 HMMWV
	["sub_ins_weu_van",	33],		// M998 HMMWV
	
	
	// Модель с множеством модификаций или копий с другим класнеймом - обозначать с решеткой-префиксом и только заглавными буквами + цифрами
	// Модификации располагать в порядке: ( длиннейший индекс сначала, ... , базовая модель - последней )
	
// Tanks
	// ["#M1A",			31],		// Abrams family
	["#SPRUT",			35],    	// 2S25 Sprut
	["#T34",			30],
	["#T55",			32],
	["#T72",			30],
	["#T80",			32],
	["#T90",			30],

	
// IFVs	
	["#BMD4",			35],    	//бмд4
	["#BMD",			32],    	//бмд1 и 2, а так же машины на их базе
	["#BMP3",			30],		//БМП3
	["#BMP2D",			30],		//БМП2Д
	["#BMP1D",			30],		//БМП1Д
	["#BMP",			35],		//все первые и вторые БМПшки
	["#BRM1",			35],		//ПРП на базе первой БМП
	// ["#M2A",			31],		// Bradley family
	["#PRP3",			35],		//ПРП на базе первой БМП

	
// APCs	
	["#BTR",			30],		// BTR-60-70-80	
	// ["#LAV25",			31],
	// ["#M113A3",			31],
	// ["#M112",			31],		// Striker family 1
	// ["#M113",			31],		// Striker family 2
	
	
// Trucks
	["#BM21",			30],		// BM-21 Grad (Ural)
	["#GAZ66",			35],	
	// ["#TRUCK_01",		31],	// HEMTT	
	// ["#KAMAZ",			31],		
	// ["#TRUCK_02",		31],		// Kamaz Vanilla
	// ["#MK23",			31],		// MTVR family 1
	// ["#MK27",			31],		// MTVR family 2
	// ["#DAR_LHS",		31],		// MTVR family 3
	// ["#M1078",			31],		// FMTV 
	// ["#M1083",			31],		// FMTV 
	["#TYPHOON",		25],		//Kamaz63968
	["#TRUCK_03",		25],		//Kamaz63968
	["#TRUCK",			28],		// Vanilla Truck
	["#VAN",			28],		// Vanilla Truck
	["#URAL",			30],		

	
// Cars
	// ["#COYOTE",			31],
	["#GAZ24",		25],
	["#GOLF4",		25],
	["#HATCHBACK",		25],
	["#HILUX",			35],
	// ["#HMMWV",			31],		// M1025 HMMWV family
	// ["#M1025",			31],		// M1025 HMMWV family
	["#M998",			33],		// M998 HMMWV family
	
	["#IKARUS",			25],
	// ["#JACKAL",			31],
	["#LANDROVER",		45],
	["#CARS_LR",		45],		// Land Rover (mas)
	["#LADA",		25],
	// ["#MAXXPRO",		31],
	// ["#OFFROAD",		31],	
	["#OCTAVIA",		25],	
	["#QUADBIKE",		25],
	// ["#RG33",			31],
	["#S1203",			25],
	["#TIGR_STS",		35],		//тигр СТС с 5ым классом бронирования
	["#TIGR",			41],		//тигр и тигр-М (двннные взяты с 2 левых сайтов, по тигр-м практически ничего)
	// ["#UAZ",			31],		
	
	
// Other Vehicles
	["#9K79",			30], 		// Точка-У
	["#BRDM",			30],		//БРДМы
	["#PTS",			30],		//ПТС
	["#ZSU",			30],		//зсу

	
	["DEFAULT",			31]
];