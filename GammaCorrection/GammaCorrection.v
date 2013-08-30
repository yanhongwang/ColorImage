`include	"./Definition.v"

module GammaCorrection
(
	
	input[ `size_int - 1 : 0 ]source,
	
	output reg[ `size_int - 1 : 0 ]target
	
);
	
	always@( source )
		target = LUTPow045( source >> `ScaleBit );
	
	function[ `size_int - 1 : 0 ]LUTPow045;
	
	input[ `size_int - 1 : 0 ]source;
	
	begin
		
		case( source )
			
			// ( ( RGB / 256 ) ^ 0.45 ) * 256 * 256
			0 : LUTPow045 = 0;
			1 : LUTPow045 = 5404;
			2 : LUTPow045 = 7383;
			3 : LUTPow045 = 8860;
			4 : LUTPow045 = 10085;
			5 : LUTPow045 = 11150;
			6 : LUTPow045 = 12104;
			7 : LUTPow045 = 12973;
			8 : LUTPow045 = 13777;
			9 : LUTPow045 = 14527;
			10 : LUTPow045 = 15232;
			11 : LUTPow045 = 15900;
			12 : LUTPow045 = 16534;
			13 : LUTPow045 = 17141;
			14 : LUTPow045 = 17722;
			15 : LUTPow045 = 18281;
			16 : LUTPow045 = 18820;
			17 : LUTPow045 = 19340;
			18 : LUTPow045 = 19844;
			19 : LUTPow045 = 20333;
			20 : LUTPow045 = 20808;
			21 : LUTPow045 = 21270;
			22 : LUTPow045 = 21720;
			23 : LUTPow045 = 22158;
			24 : LUTPow045 = 22587;
			25 : LUTPow045 = 23006;
			26 : LUTPow045 = 23415;
			27 : LUTPow045 = 23816;
			28 : LUTPow045 = 24209;
			29 : LUTPow045 = 24595;
			30 : LUTPow045 = 24973;
			31 : LUTPow045 = 25344;
			32 : LUTPow045 = 25709;
			33 : LUTPow045 = 26067;
			34 : LUTPow045 = 26420;
			35 : LUTPow045 = 26767;
			36 : LUTPow045 = 27108;
			37 : LUTPow045 = 27444;
			38 : LUTPow045 = 27776;
			39 : LUTPow045 = 28102;
			40 : LUTPow045 = 28424;
			41 : LUTPow045 = 28742;
			42 : LUTPow045 = 29055;
			43 : LUTPow045 = 29365;
			44 : LUTPow045 = 29670;
			45 : LUTPow045 = 29972;
			46 : LUTPow045 = 30270;
			47 : LUTPow045 = 30564;
			48 : LUTPow045 = 30855;
			49 : LUTPow045 = 31142;
			50 : LUTPow045 = 31427;
			51 : LUTPow045 = 31708;
			52 : LUTPow045 = 31986;
			53 : LUTPow045 = 32262;
			54 : LUTPow045 = 32534;
			55 : LUTPow045 = 32804;
			56 : LUTPow045 = 33071;
			57 : LUTPow045 = 33336;
			58 : LUTPow045 = 33598;
			59 : LUTPow045 = 33857;
			60 : LUTPow045 = 34114;
			61 : LUTPow045 = 34369;
			62 : LUTPow045 = 34621;
			63 : LUTPow045 = 34871;
			64 : LUTPow045 = 35119;
			65 : LUTPow045 = 35365;
			66 : LUTPow045 = 35609;
			67 : LUTPow045 = 35851;
			68 : LUTPow045 = 36091;
			69 : LUTPow045 = 36329;
			70 : LUTPow045 = 36565;
			71 : LUTPow045 = 36799;
			72 : LUTPow045 = 37031;
			73 : LUTPow045 = 37262;
			74 : LUTPow045 = 37490;
			75 : LUTPow045 = 37718;
			76 : LUTPow045 = 37943;
			77 : LUTPow045 = 38167;
			78 : LUTPow045 = 38389;
			79 : LUTPow045 = 38610;
			80 : LUTPow045 = 38829;
			81 : LUTPow045 = 39047;
			82 : LUTPow045 = 39263;
			83 : LUTPow045 = 39478;
			84 : LUTPow045 = 39691;
			85 : LUTPow045 = 39903;
			86 : LUTPow045 = 40114;
			87 : LUTPow045 = 40323;
			88 : LUTPow045 = 40531;
			89 : LUTPow045 = 40737;
			90 : LUTPow045 = 40943;
			91 : LUTPow045 = 41147;
			92 : LUTPow045 = 41350;
			93 : LUTPow045 = 41551;
			94 : LUTPow045 = 41752;
			95 : LUTPow045 = 41951;
			96 : LUTPow045 = 42149;
			97 : LUTPow045 = 42346;
			98 : LUTPow045 = 42542;
			99 : LUTPow045 = 42737;
			100 : LUTPow045 = 42931;
			101 : LUTPow045 = 43123;
			102 : LUTPow045 = 43315;
			103 : LUTPow045 = 43505;
			104 : LUTPow045 = 43695;
			105 : LUTPow045 = 43884;
			106 : LUTPow045 = 44071;
			107 : LUTPow045 = 44258;
			108 : LUTPow045 = 44443;
			109 : LUTPow045 = 44628;
			110 : LUTPow045 = 44812;
			111 : LUTPow045 = 44995;
			112 : LUTPow045 = 45177;
			113 : LUTPow045 = 45358;
			114 : LUTPow045 = 45538;
			115 : LUTPow045 = 45717;
			116 : LUTPow045 = 45896;
			117 : LUTPow045 = 46073;
			118 : LUTPow045 = 46250;
			119 : LUTPow045 = 46426;
			120 : LUTPow045 = 46601;
			121 : LUTPow045 = 46776;
			122 : LUTPow045 = 46949;
			123 : LUTPow045 = 47122;
			124 : LUTPow045 = 47294;
			125 : LUTPow045 = 47465;
			126 : LUTPow045 = 47636;
			127 : LUTPow045 = 47806;
			128 : LUTPow045 = 47975;
			129 : LUTPow045 = 48143;
			130 : LUTPow045 = 48311;
			131 : LUTPow045 = 48477;
			132 : LUTPow045 = 48644;
			133 : LUTPow045 = 48809;
			134 : LUTPow045 = 48974;
			135 : LUTPow045 = 49138;
			136 : LUTPow045 = 49301;
			137 : LUTPow045 = 49464;
			138 : LUTPow045 = 49626;
			139 : LUTPow045 = 49788;
			140 : LUTPow045 = 49949;
			141 : LUTPow045 = 50109;
			142 : LUTPow045 = 50269;
			143 : LUTPow045 = 50428;
			144 : LUTPow045 = 50586;
			145 : LUTPow045 = 50744;
			146 : LUTPow045 = 50901;
			147 : LUTPow045 = 51058;
			148 : LUTPow045 = 51214;
			149 : LUTPow045 = 51369;
			150 : LUTPow045 = 51524;
			151 : LUTPow045 = 51678;
			152 : LUTPow045 = 51832;
			153 : LUTPow045 = 51985;
			154 : LUTPow045 = 52138;
			155 : LUTPow045 = 52290;
			156 : LUTPow045 = 52441;
			157 : LUTPow045 = 52592;
			158 : LUTPow045 = 52743;
			159 : LUTPow045 = 52893;
			160 : LUTPow045 = 53042;
			161 : LUTPow045 = 53191;
			162 : LUTPow045 = 53340;
			163 : LUTPow045 = 53488;
			164 : LUTPow045 = 53635;
			165 : LUTPow045 = 53782;
			166 : LUTPow045 = 53928;
			167 : LUTPow045 = 54074;
			168 : LUTPow045 = 54220;
			169 : LUTPow045 = 54365;
			170 : LUTPow045 = 54509;
			171 : LUTPow045 = 54653;
			172 : LUTPow045 = 54797;
			173 : LUTPow045 = 54940;
			174 : LUTPow045 = 55083;
			175 : LUTPow045 = 55225;
			176 : LUTPow045 = 55367;
			177 : LUTPow045 = 55508;
			178 : LUTPow045 = 55649;
			179 : LUTPow045 = 55789;
			180 : LUTPow045 = 55929;
			181 : LUTPow045 = 56069;
			182 : LUTPow045 = 56208;
			183 : LUTPow045 = 56347;
			184 : LUTPow045 = 56485;
			185 : LUTPow045 = 56623;
			186 : LUTPow045 = 56761;
			187 : LUTPow045 = 56898;
			188 : LUTPow045 = 57035;
			189 : LUTPow045 = 57171;
			190 : LUTPow045 = 57307;
			191 : LUTPow045 = 57442;
			192 : LUTPow045 = 57578;
			193 : LUTPow045 = 57712;
			194 : LUTPow045 = 57847;
			195 : LUTPow045 = 57981;
			196 : LUTPow045 = 58114;
			197 : LUTPow045 = 58248;
			198 : LUTPow045 = 58380;
			199 : LUTPow045 = 58513;
			200 : LUTPow045 = 58645;
			201 : LUTPow045 = 58777;
			202 : LUTPow045 = 58908;
			203 : LUTPow045 = 59039;
			204 : LUTPow045 = 59170;
			205 : LUTPow045 = 59300;
			206 : LUTPow045 = 59430;
			207 : LUTPow045 = 59560;
			208 : LUTPow045 = 59689;
			209 : LUTPow045 = 59818;
			210 : LUTPow045 = 59947;
			211 : LUTPow045 = 60075;
			212 : LUTPow045 = 60203;
			213 : LUTPow045 = 60331;
			214 : LUTPow045 = 60458;
			215 : LUTPow045 = 60585;
			216 : LUTPow045 = 60712;
			217 : LUTPow045 = 60838;
			218 : LUTPow045 = 60964;
			219 : LUTPow045 = 61090;
			220 : LUTPow045 = 61215;
			221 : LUTPow045 = 61340;
			222 : LUTPow045 = 61465;
			223 : LUTPow045 = 61589;
			224 : LUTPow045 = 61713;
			225 : LUTPow045 = 61837;
			226 : LUTPow045 = 61961;
			227 : LUTPow045 = 62084;
			228 : LUTPow045 = 62207;
			229 : LUTPow045 = 62330;
			230 : LUTPow045 = 62452;
			231 : LUTPow045 = 62574;
			232 : LUTPow045 = 62696;
			233 : LUTPow045 = 62817;
			234 : LUTPow045 = 62938;
			235 : LUTPow045 = 63059;
			236 : LUTPow045 = 63180;
			237 : LUTPow045 = 63300;
			238 : LUTPow045 = 63420;
			239 : LUTPow045 = 63540;
			240 : LUTPow045 = 63660;
			241 : LUTPow045 = 63779;
			242 : LUTPow045 = 63898;
			243 : LUTPow045 = 64016;
			244 : LUTPow045 = 64135;
			245 : LUTPow045 = 64253;
			246 : LUTPow045 = 64371;
			247 : LUTPow045 = 64488;
			248 : LUTPow045 = 64606;
			249 : LUTPow045 = 64723;
			250 : LUTPow045 = 64840;
			251 : LUTPow045 = 64956;
			252 : LUTPow045 = 65073;
			253 : LUTPow045 = 65189;
			254 : LUTPow045 = 65305;
			255 : LUTPow045 = 65420;
			
		endcase
		
	end
	
	endfunction
	
endmodule

module GammaCorrection_testbench;
	
	reg[ `size_int - 1 : 0 ]source;
	
	wire[ `size_int - 1 : 0 ]target;
	
	GammaCorrection GammaCorrection_test( source, target );
	
	initial
	begin
		
		#10	source = 2 << `ScaleBit;
		#10     $display( "old value = %d\tnew value = %d", source, target );
		
		#10	source = 10 << `ScaleBit;
		#10	$display( "old value = %d\tnew value = %d", source, target );
		
		#10     $stop;
		#10     $finish;
						
	end
	
endmodule

