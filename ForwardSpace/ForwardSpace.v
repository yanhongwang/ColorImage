`include	"./Definition.v"

// RGB2XYZ
`define		RGB2XYZ1	106	// 0.412453 * `ScaleNumber = 105.587968
`define		RGB2XYZ2	92	// 0.357580 * `ScaleNumber = 91.54048
`define		RGB2XYZ3	46	// 0.180423 * `ScaleNumber = 46.188288
`define		RGB2XYZ4	54	// 0.212671 * `ScaleNumber = 54.443776
`define		RGB2XYZ5	183	// 0.715160 * `ScaleNumber = 183.08096
`define		RGB2XYZ6	18	// 0.072169 * `ScaleNumber = 18.475264
`define		RGB2XYZ7	5	// 0.019334 * `ScaleNumber = 4.949504
`define		RGB2XYZ8	31	// 0.119193 * `ScaleNumber = 30.513408
`define		RGB2XYZ9	243	// 0.950227 * `ScaleNumber = 243.258112
//16 * 6.3496042078727978990068225569719 * `ScaleNumber = 26007.978835446980194331945193353
`define		pow_16_256_1_3	26008

`define		RGB2LabLimit	2	// 0.008856 * ScaleNumber = 2.267136

module ForwardSpace
(
	
	input[ `size_int - 1 : 0 ]R,
	input[ `size_int - 1 : 0 ]G,
	input[ `size_int - 1 : 0 ]B,
	
	output wire[ `size_int - 1 : 0 ]CIEL,
	output wire signed[ `size_int - 1 : 0 ]CIEa,
	output wire signed[ `size_int - 1 : 0 ]CIEb
	
);
	
	reg[ `size_int - 1 : 0 ]X;
	reg[ `size_int - 1 : 0 ]Y;
	reg[ `size_int - 1 : 0 ]Z;
	
	reg[ `size_int - 1 : 0 ]fX;
	reg[ `size_int - 1 : 0 ]fY;
	reg[ `size_int - 1 : 0 ]fZ;
	
	always@( R or G or B )
	begin
		
		// 256 * 0.950456 * 256
		X = ( R * `RGB2XYZ1 + G * `RGB2XYZ2 + B * `RGB2XYZ3 ) >> ( `ScaleBit + `ScaleBit );
		X = ( X * 269 ) >> `ScaleBit;	// 256 / 0.950456 = 269
		
		Y = ( R * `RGB2XYZ4 + G * `RGB2XYZ5 + B * `RGB2XYZ6 ) >> ( `ScaleBit + `ScaleBit );
		
		// 256 * 1.088754 * 256
		Z = ( R * `RGB2XYZ7 + G * `RGB2XYZ8 + B * `RGB2XYZ9 ) >> ( `ScaleBit + `ScaleBit );
		Z = ( Z * 235 ) >> `ScaleBit;	// 256 / 1.088754 = 235
		
		// avoid extreme case of Y
		if( Y < `RGB2LabLimit )
			Y = `RGB2LabLimit;
		
		// avoid extreme case of X
		if( X < `RGB2LabLimit )
			X = `RGB2LabLimit;
		
		// avoid extreme case of Z
		if( Z < `RGB2LabLimit )
			Z = `RGB2LabLimit;
		
		fX = LUTPow033( X );
		fY = LUTPow033( Y );
		fZ = LUTPow033( Z );
		
	end
	
	assign CIEL = 116 * fX - `pow_16_256_1_3;
	assign CIEa = 500 * ( fX - fY );
	assign CIEb = 200 * ( fY - fZ );
	
	function[ `size_int - 1 : 0 ]LUTPow033;
	
	input[ `size_int - 1 : 0 ]Index;
	
	begin
		
		case( Index )
			
			0 : LUTPow033 = 0;
			1 : LUTPow033 = 256;
			2 : LUTPow033 = 322;
			3 : LUTPow033 = 369;
			4 : LUTPow033 = 406;
			5 : LUTPow033 = 437;
			6 : LUTPow033 = 465;
			7 : LUTPow033 = 489;
			8 : LUTPow033 = 511;
			9 : LUTPow033 = 532;
			10 : LUTPow033 = 551;
			11 : LUTPow033 = 569;
			12 : LUTPow033 = 586;
			13 : LUTPow033 = 601;
			14 : LUTPow033 = 616;
			15 : LUTPow033 = 631;
			16 : LUTPow033 = 645;
			17 : LUTPow033 = 658;
			18 : LUTPow033 = 670;
			19 : LUTPow033 = 683;
			20 : LUTPow033 = 694;
			21 : LUTPow033 = 706;
			22 : LUTPow033 = 717;
			23 : LUTPow033 = 728;
			24 : LUTPow033 = 738;
			25 : LUTPow033 = 748;
			26 : LUTPow033 = 758;
			27 : LUTPow033 = 767;
			28 : LUTPow033 = 777;
			29 : LUTPow033 = 786;
			30 : LUTPow033 = 795;
			31 : LUTPow033 = 804;
			32 : LUTPow033 = 812;
			33 : LUTPow033 = 821;
			34 : LUTPow033 = 829;
			35 : LUTPow033 = 837;
			36 : LUTPow033 = 845;
			37 : LUTPow033 = 853;
			38 : LUTPow033 = 860;
			39 : LUTPow033 = 868;
			40 : LUTPow033 = 875;
			41 : LUTPow033 = 882;
			42 : LUTPow033 = 889;
			43 : LUTPow033 = 896;
			44 : LUTPow033 = 903;
			45 : LUTPow033 = 910;
			46 : LUTPow033 = 917;
			47 : LUTPow033 = 923;
			48 : LUTPow033 = 930;
			49 : LUTPow033 = 936;
			50 : LUTPow033 = 943;
			51 : LUTPow033 = 949;
			52 : LUTPow033 = 955;
			53 : LUTPow033 = 961;
			54 : LUTPow033 = 967;
			55 : LUTPow033 = 973;
			56 : LUTPow033 = 979;
			57 : LUTPow033 = 985;
			58 : LUTPow033 = 990;
			59 : LUTPow033 = 996;
			60 : LUTPow033 = 1002;
			61 : LUTPow033 = 1007;
			62 : LUTPow033 = 1013;
			63 : LUTPow033 = 1018;
			64 : LUTPow033 = 1023;
			65 : LUTPow033 = 1029;
			66 : LUTPow033 = 1034;
			67 : LUTPow033 = 1039;
			68 : LUTPow033 = 1044;
			69 : LUTPow033 = 1050;
			70 : LUTPow033 = 1055;
			71 : LUTPow033 = 1060;
			72 : LUTPow033 = 1065;
			73 : LUTPow033 = 1069;
			74 : LUTPow033 = 1074;
			75 : LUTPow033 = 1079;
			76 : LUTPow033 = 1084;
			77 : LUTPow033 = 1089;
			78 : LUTPow033 = 1093;
			79 : LUTPow033 = 1098;
			80 : LUTPow033 = 1103;
			81 : LUTPow033 = 1107;
			82 : LUTPow033 = 1112;
			83 : LUTPow033 = 1116;
			84 : LUTPow033 = 1121;
			85 : LUTPow033 = 1125;
			86 : LUTPow033 = 1129;
			87 : LUTPow033 = 1134;
			88 : LUTPow033 = 1138;
			89 : LUTPow033 = 1142;
			90 : LUTPow033 = 1147;
			91 : LUTPow033 = 1151;
			92 : LUTPow033 = 1155;
			93 : LUTPow033 = 1159;
			94 : LUTPow033 = 1163;
			95 : LUTPow033 = 1168;
			96 : LUTPow033 = 1172;
			97 : LUTPow033 = 1176;
			98 : LUTPow033 = 1180;
			99 : LUTPow033 = 1184;
			100 : LUTPow033 = 1188;
			101 : LUTPow033 = 1192;
			102 : LUTPow033 = 1196;
			103 : LUTPow033 = 1200;
			104 : LUTPow033 = 1203;
			105 : LUTPow033 = 1207;
			106 : LUTPow033 = 1211;
			107 : LUTPow033 = 1215;
			108 : LUTPow033 = 1219;
			109 : LUTPow033 = 1222;
			110 : LUTPow033 = 1226;
			111 : LUTPow033 = 1230;
			112 : LUTPow033 = 1233;
			113 : LUTPow033 = 1237;
			114 : LUTPow033 = 1241;
			115 : LUTPow033 = 1244;
			116 : LUTPow033 = 1248;
			117 : LUTPow033 = 1252;
			118 : LUTPow033 = 1255;
			119 : LUTPow033 = 1259;
			120 : LUTPow033 = 1262;
			121 : LUTPow033 = 1266;
			122 : LUTPow033 = 1269;
			123 : LUTPow033 = 1273;
			124 : LUTPow033 = 1276;
			125 : LUTPow033 = 1279;
			126 : LUTPow033 = 1283;
			127 : LUTPow033 = 1286;
			128 : LUTPow033 = 1290;
			129 : LUTPow033 = 1293;
			130 : LUTPow033 = 1296;
			131 : LUTPow033 = 1300;
			132 : LUTPow033 = 1303;
			133 : LUTPow033 = 1306;
			134 : LUTPow033 = 1310;
			135 : LUTPow033 = 1313;
			136 : LUTPow033 = 1316;
			137 : LUTPow033 = 1319;
			138 : LUTPow033 = 1322;
			139 : LUTPow033 = 1326;
			140 : LUTPow033 = 1329;
			141 : LUTPow033 = 1332;
			142 : LUTPow033 = 1335;
			143 : LUTPow033 = 1338;
			144 : LUTPow033 = 1341;
			145 : LUTPow033 = 1344;
			146 : LUTPow033 = 1348;
			147 : LUTPow033 = 1351;
			148 : LUTPow033 = 1354;
			149 : LUTPow033 = 1357;
			150 : LUTPow033 = 1360;
			151 : LUTPow033 = 1363;
			152 : LUTPow033 = 1366;
			153 : LUTPow033 = 1369;
			154 : LUTPow033 = 1372;
			155 : LUTPow033 = 1375;
			156 : LUTPow033 = 1378;
			157 : LUTPow033 = 1381;
			158 : LUTPow033 = 1383;
			159 : LUTPow033 = 1386;
			160 : LUTPow033 = 1389;
			161 : LUTPow033 = 1392;
			162 : LUTPow033 = 1395;
			163 : LUTPow033 = 1398;
			164 : LUTPow033 = 1401;
			165 : LUTPow033 = 1404;
			166 : LUTPow033 = 1406;
			167 : LUTPow033 = 1409;
			168 : LUTPow033 = 1412;
			169 : LUTPow033 = 1415;
			170 : LUTPow033 = 1418;
			171 : LUTPow033 = 1420;
			172 : LUTPow033 = 1423;
			173 : LUTPow033 = 1426;
			174 : LUTPow033 = 1429;
			175 : LUTPow033 = 1431;
			176 : LUTPow033 = 1434;
			177 : LUTPow033 = 1437;
			178 : LUTPow033 = 1440;
			179 : LUTPow033 = 1442;
			180 : LUTPow033 = 1445;
			181 : LUTPow033 = 1448;
			182 : LUTPow033 = 1450;
			183 : LUTPow033 = 1453;
			184 : LUTPow033 = 1456;
			185 : LUTPow033 = 1458;
			186 : LUTPow033 = 1461;
			187 : LUTPow033 = 1463;
			188 : LUTPow033 = 1466;
			189 : LUTPow033 = 1469;
			190 : LUTPow033 = 1471;
			191 : LUTPow033 = 1474;
			192 : LUTPow033 = 1476;
			193 : LUTPow033 = 1479;
			194 : LUTPow033 = 1481;
			195 : LUTPow033 = 1484;
			196 : LUTPow033 = 1487;
			197 : LUTPow033 = 1489;
			198 : LUTPow033 = 1492;
			199 : LUTPow033 = 1494;
			200 : LUTPow033 = 1497;
			201 : LUTPow033 = 1499;
			202 : LUTPow033 = 1502;
			203 : LUTPow033 = 1504;
			204 : LUTPow033 = 1507;
			205 : LUTPow033 = 1509;
			206 : LUTPow033 = 1511;
			207 : LUTPow033 = 1514;
			208 : LUTPow033 = 1516;
			209 : LUTPow033 = 1519;
			210 : LUTPow033 = 1521;
			211 : LUTPow033 = 1524;
			212 : LUTPow033 = 1526;
			213 : LUTPow033 = 1528;
			214 : LUTPow033 = 1531;
			215 : LUTPow033 = 1533;
			216 : LUTPow033 = 1535;
			217 : LUTPow033 = 1538;
			218 : LUTPow033 = 1540;
			219 : LUTPow033 = 1543;
			220 : LUTPow033 = 1545;
			221 : LUTPow033 = 1547;
			222 : LUTPow033 = 1550;
			223 : LUTPow033 = 1552;
			224 : LUTPow033 = 1554;
			225 : LUTPow033 = 1557;
			226 : LUTPow033 = 1559;
			227 : LUTPow033 = 1561;
			228 : LUTPow033 = 1563;
			229 : LUTPow033 = 1566;
			230 : LUTPow033 = 1568;
			231 : LUTPow033 = 1570;
			232 : LUTPow033 = 1573;
			233 : LUTPow033 = 1575;
			234 : LUTPow033 = 1577;
			235 : LUTPow033 = 1579;
			236 : LUTPow033 = 1582;
			237 : LUTPow033 = 1584;
			238 : LUTPow033 = 1586;
			239 : LUTPow033 = 1588;
			240 : LUTPow033 = 1590;
			241 : LUTPow033 = 1593;
			242 : LUTPow033 = 1595;
			243 : LUTPow033 = 1597;
			244 : LUTPow033 = 1599;
			245 : LUTPow033 = 1601;
			246 : LUTPow033 = 1604;
			247 : LUTPow033 = 1606;
			248 : LUTPow033 = 1608;
			249 : LUTPow033 = 1610;
			250 : LUTPow033 = 1612;
			251 : LUTPow033 = 1614;
			252 : LUTPow033 = 1616;
			253 : LUTPow033 = 1619;
			254 : LUTPow033 = 1621;
			255 : LUTPow033 = 1623;
			256 : LUTPow033 = 1625;
			
		endcase
		
	end
	
	endfunction
	
endmodule

module ForwardSpace_testbench;
	
	reg[ `size_int - 1 : 0 ]R;
	reg[ `size_int - 1 : 0 ]G;
	reg[ `size_int - 1 : 0 ]B;
	
	wire[ `size_int - 1 : 0 ]CIEL;
	wire signed[ `size_int - 1 : 0 ]CIEa;
	wire signed[ `size_int - 1 : 0 ]CIEb;
	
	ForwardSpace ForwardSpace_test( R, G, B, CIEL, CIEa, CIEb );
	
	initial
	begin
		
		$monitor( "R = %d, G = %d, B = %d, CIEL = %d, CIEa = %d, CIEb = %d",
				R, G, B, CIEL, CIEa, CIEb );
		
		#100
		begin
			R = 50 << `ScaleBit;	// 12800
			G = 70 << `ScaleBit;	// 17920
			B = 40 << `ScaleBit;	// 10240
		end
		
		#100
		begin
			R = 29 << `ScaleBit;	// 7424
			G = 85 << `ScaleBit;	// 21760
			B = 89 << `ScaleBit;	// 22784
		end
		
		#100    $stop;
		#100    $finish;
		
	end
	
endmodule

