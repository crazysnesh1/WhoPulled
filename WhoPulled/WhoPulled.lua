WhoPulled_GUIDs = {};
WhoPulled_MobToPlayer = {};
WhoPulled_LastMob = "";

-- Инициализация настроек по умолчанию
if not WhoPulled_Settings then
    WhoPulled_Settings = {
        ["yonboss"] = false,
        ["rwonboss"] = false,
        ["silent"] = false,
        ["msg"] = "%p ЗАПУЛИЛ %e!!!",
        ["tanks"] = "",
        ["minimapPos"] = -15,
        ["minimapPosY"] = -15
    }
end

if not WhoPulled_Tanks then
    WhoPulled_Tanks = WhoPulled_Settings["tanks"] or ""
end

if not WhoPulled_RageList then
    WhoPulled_RageList = {}
end

if not WhoPulled_Ignore then
    WhoPulled_Ignore = {
        ["Крыса"]=true,["Паук"]=true,["Восставший зомби"]=true,
    }
end

WhoPulled_PetsToMaster = {};
WhoPulled_NotifiedOf = {};

function WhoPulled_ClearPulledList()
	wipe(WhoPulled_GUIDs);
end

function WhoPulled_PullBlah(player,enemy,msg)
	if(not WhoPulled_GUIDs[enemy[1]]) then
		WhoPulled_GUIDs[enemy[1]] = true;
		WhoPulled_MobToPlayer[enemy[2]] = player;
		WhoPulled_LastMob = enemy[2];
		if(WhoPulled_Settings["yonboss"]) then
			-- Проверка, является ли враг боссом:
			local i,boss;
			i = 1;
			while(UnitExists("boss"..i)) do
				if(UnitName("boss"..i) == enemy[2]) then
					if(not strfind(WhoPulled_Tanks,"[ ,.|]"..player.."[ ,.|]") and not WhoPulled_Ignore[enemy[2]]) then
						if(UnitInRaid("player") and WhoPulled_Settings["rwonboss"] and (IsRaidOfficer() or IsRaidLeader())) then
							WhoPulled_RaidWarning(enemy[2]);
						else
							WhoPulled_Yell(enemy[2]);
						end
					end
					break;
				end
				i = i+1;
			end
		else
			if(not WhoPulled_Settings["silent"] and not WhoPulled_Ignore[enemy[2]] and 
			   not strfind(WhoPulled_Tanks,"[ ,.|]"..player.."[ ,.|]")) then
				DEFAULT_CHAT_FRAME:AddMessage(msg);
			end
		end
	end
end

function WhoPulled_GetPetOwner(pet)
	if(WhoPulled_PetsToMaster[pet]) then return WhoPulled_PetsToMaster[pet]; end
	if(UnitInRaid("player")) then
		for i=1,40,1 do
			if(UnitGUID("raidpet"..i) == pet) then
				return UnitName("raid"..i);
			end
		end
	else
		if(UnitGUID("pet") == pet) then return UnitName("player"); end
		for i=1,4,1 do
			if(UnitGUID("partypet"..i) == pet) then
				return UnitName("party"..i);
			end
		end
	end
	return "Неизвестно";
end

function WhoPulled_ScanForPets()
	if(UnitInRaid("player")) then
		for i=1,40,1 do
			if(UnitExists("raidpet"..i)) then
				WhoPulled_PetsToMaster[UnitGUID("raidpet"..i)] = UnitName("raid"..i);
			end
		end
	else
		if(UnitExists("pet")) then WhoPulled_PetsToMaster[UnitGUID("pet")] = UnitName("player"); end
		for i=1,4,1 do
			if(UnitExists("partypet"..i)) then
				WhoPulled_PetsToMaster[UnitGUID("partypet"..i)] = UnitName("party"..i);
			end
		end
	end
end

function WhoPulled_ScanMembersSub(combo)
	local name,serv;
	name,serv = WhoPulled_GetNameServ(combo);
	if(name and WhoPulled_RageList[serv] and WhoPulled_RageList[serv][name] and not WhoPulled_NotifiedOf[name.."-"..serv]) then
		DEFAULT_CHAT_FRAME:AddMessage(name..", который запулил "..WhoPulled_RageList[serv][name]..", находится в вашей группе!")
		WhoPulled_NotifiedOf[name.."-"..serv] = true;
	end
end

function WhoPulled_ScanMembers()
	local num,name,i;
	if(UnitInRaid("player")) then
		num=GetNumRaidMembers();
		for i=1,num,1 do
			name=UnitName("raid"..i);
			WhoPulled_ScanMembersSub(name);
		end
	else
		num=GetNumPartyMembers();
		if(num == 0) then return; end
		name=UnitName("party"..num);
		WhoPulled_ScanMembersSub(name);
	end
end

function WhoPulled_OnLeaveParty()
	wipe(WhoPulled_PetsToMaster);
	WhoPulled_Tanks = "";
	wipe(WhoPulled_NotifiedOf);
end

function WhoPulled_IgnoredSpell(spell)
	if(spell == "Метка охотника" or spell == "Страж-обезьяна" or spell == "Умиротворение") then
		return true;
	end
	return false;
end

function WhoPulled_CheckWho(...)
	local time,event,sguid,sname,sflags,dguid,dname,dflags,arg1,arg2,arg3,itype;
	if(IsInInstance()) then
		time,event,sguid,sname,sflags,dguid,dname,dflags,arg1,arg2,arg3 = ...;
		if(dname and sname and dname ~= sname and 
		   not strfind(event,"_RESURRECT") and not strfind(event,"_CREATE") and 
		   (strfind(event,"SWING") or strfind(event,"RANGE") or strfind(event,"SPELL"))) then
		 if(not strfind(event,"_SUMMON")) then
			if(bit.band(sflags,COMBATLOG_OBJECT_TYPE_PLAYER) ~= 0 and bit.band(dflags,COMBATLOG_OBJECT_TYPE_NPC) ~= 0) then
				-- Игрок атакует моба
				if(not WhoPulled_IgnoredSpell(arg2)) then
					WhoPulled_PullBlah(sname,{dguid,dname},
						sname.." запулил "..dname.."! Используйте /ywho чтобы сообщить всем!");
				end
			elseif(bit.band(dflags,COMBATLOG_OBJECT_TYPE_PLAYER) ~= 0 and bit.band(sflags,COMBATLOG_OBJECT_TYPE_NPC) ~= 0) then
				-- Моб атакует игрока (наступил на агро, например)
				WhoPulled_PullBlah(dname,{sguid,sname},
					dname.." запулил "..sname.."! Используйте /ywho чтобы сообщить всем!");
			elseif(bit.band(sflags,COMBATLOG_OBJECT_CONTROL_PLAYER) ~= 0 and bit.band(dflags,COMBATLOG_OBJECT_TYPE_NPC) ~= 0) then
				-- Питомец игрока атакует моба
				local pullname;
				pname = WhoPulled_GetPetOwner(sguid);
				if(pname == "Неизвестно") then pullname = sname.." (питомец)";
				else pullname = pname;
				end
				WhoPulled_PullBlah(pullname,{dguid,dname},
					pname.." (питомец "..sname..") запулил "..dname.."! Используйте /ywho чтобы сообщить всем!");
			elseif(bit.band(sflags,COMBATLOG_OBJECT_CONTROL_PLAYER) ~= 0 and bit.band(sflags,COMBATLOG_OBJECT_TYPE_NPC) ~= 0) then
				-- Моб атакует питомца игрока
				local pullname;
				pname = WhoPulled_GetPetOwner(dguid);
				if(pname == "Неизвестно") then pullname = dname.." (питомец)";
				else pullname = pname;
				end
				WhoPulled_PullBlah(pullname,{sguid,sname},
					pname.." (питомец "..dname..") запулил "..sname.."! Используйте /ywho чтобы сообщить всем!");
			end
		 else
		 	-- Запись призыва
			WhoPulled_PetsToMaster[dguid] = sname;
		 end
		end
	end
end

function WhoPulled_GetNameServ(combo)
	if not combo then return nil; end
	local name,serv = combo:match("([^%- ]+)%-?(.*)");
	if(name == "") then return nil,nil; end
	if(serv == "") then
		serv = GetRealmName();
		if not serv then serv = ""; end
	end
	return name,serv;
end

function WhoPulled_NameOrTarget(combo)
	if(name == "%t") then return UnitName("playertarget");
	else return combo;
	end
end

function WhoPulled_CLI(line)
	local pos,comm;
	pos = strfind(line," ");
	if(pos) then
		comm = strlower(strsub(line,1,pos-1));
		line = strsub(line,pos+1);
	else
		comm = line;
		line = "";
	end
	if(comm == "clear")then
		wipe(WhoPulled_MobToPlayer);
		WhoPulled_LastMob = "";
		DEFAULT_CHAT_FRAME:AddMessage("Список пулов очищен");
	elseif(comm == "boss")then
		line = strlower(line);
		if(line == "rw") then
			WhoPulled_Settings["rwonboss"] = true;
			WhoPulled_Settings["yonboss"] = true;
			DEFAULT_CHAT_FRAME:AddMessage("Авто-предупреждение рейда при пуле боссов: ВКЛ");
		elseif(line == "true" or line == "yell" or line == "on") then
			WhoPulled_Settings["rwonboss"] = false;
			WhoPulled_Settings["yonboss"] = true;
			DEFAULT_CHAT_FRAME:AddMessage("Авто-крик при пуле боссов: ВКЛ");
		else
			WhoPulled_Settings["rwonboss"] = false;
			WhoPulled_Settings["yonboss"] = false;
			DEFAULT_CHAT_FRAME:AddMessage("Авто-сообщения при пуле боссов: ВЫКЛ");
		end
	elseif(comm == "msg")then
		WhoPulled_Settings["msg"] = line;
		DEFAULT_CHAT_FRAME:AddMessage("Сообщение установлено: "..line);
	elseif(comm == "silent")then
		line = strlower(line);
		if(line == "true" or line == "on") then
			WhoPulled_Settings["silent"] = true;
			DEFAULT_CHAT_FRAME:AddMessage("Тихий режим: ВКЛ");
		else
			WhoPulled_Settings["silent"] = false;
			DEFAULT_CHAT_FRAME:AddMessage("Тихий режим: ВЫКЛ");
		end
	elseif(comm == "tank" or comm == "tanks") then
		line = WhoPulled_NameOrTarget(line);
		WhoPulled_Tanks = " "..line.." ";
		DEFAULT_CHAT_FRAME:AddMessage("Танки установлены: "..WhoPulled_Tanks);
	elseif(comm == "rage") then
		line = WhoPulled_NameOrTarget(line);
		if(WhoPulled_MobToPlayer[line]) then
			local name,serv = WhoPulled_GetNameServ(WhoPulled_MobToPlayer[line]);
			if not WhoPulled_RageList[serv] then WhoPulled_RageList[serv] = {}; end
			WhoPulled_RageList[serv][name] = line;
			DEFAULT_CHAT_FRAME:AddMessage("Игрок "..name.." с сервера "..serv.." добавлен в список гнева за пул "..line);
		else
			DEFAULT_CHAT_FRAME:AddMessage("Никто не запулил "..line);
		end
	elseif(comm == "forgive") then
		local name,serv = WhoPulled_GetNameServ(line);
		if(name) then
			local i,v,x;
			WhoPulled_RageList[serv][name] = nil;
			x=0;
			for i,v in pairs(WhoPulled_RageList[serv]) do
				x=x+1;
			end
			if(x == 0) then WhoPulled_RageList[serv] = nil; end
			DEFAULT_CHAT_FRAME:AddMessage("Вы простили "..name.." с сервера "..serv);
		else
			DEFAULT_CHAT_FRAME:AddMessage("У вас нет претензий к этому игроку");
		end
	elseif(comm == "list") then
		local i,i2,v,v2,t;
		if(line ~= "") then
			line = WhoPulled_NameOrTarget(line);
			t = {};
			for i2,v2 in pairs(WhoPulled_RageList) do
				for i,v in pairs(v2) do
					if(i2 == line or v == line) then
						if not t[i2] then t[i2] = {}; end
						t[i2][i] = v;
					end
				end
			end
		else
			t = WhoPulled_RageList;
		end
		for i2,v2 in pairs(t) do
			DEFAULT_CHAT_FRAME:AddMessage("~~~~["..i2.."]~~~~");
			for i,v in pairs(v2) do
				DEFAULT_CHAT_FRAME:AddMessage(" * "..i..": Запулил "..v);
			end
		end
	elseif(comm == "ignore")then
		line = WhoPulled_NameOrTarget(line);
		if(WhoPulled_Ignore[line]) then 
			WhoPulled_Ignore[line] = nil;
			DEFAULT_CHAT_FRAME:AddMessage("Теперь отслеживаются пулы "..line);
		else
			WhoPulled_Ignore[line] = true;
			DEFAULT_CHAT_FRAME:AddMessage("Теперь игнорируются пулы "..line);
		end
	elseif(comm == "help")then
		line = strlower(line);
		if(line == "clear") then
			DEFAULT_CHAT_FRAME:AddMessage("Очищает данные о пулах в текущей сессии");
		elseif(line == "boss" or line == "wpyb") then
			DEFAULT_CHAT_FRAME:AddMessage("Вкл/выкл авто-крик при пуле боссов. Используйте rw для предупреждения рейда вместо крика");
		elseif(line == "msg") then
			DEFAULT_CHAT_FRAME:AddMessage("Настройка сообщения. %p - игрок, %e - враг");
		elseif(line == "who" or line == "swho" or line == "ywho" or line == "rwho" or line == "pwho" or line == "bwho" or line == "gwho" or line == "owho" or line == "rwwho") then
			DEFAULT_CHAT_FRAME:AddMessage("/Xwho - сообщить кто запулил последнего врага или указанного врага, где X:");
			DEFAULT_CHAT_FRAME:AddMessage("s - сказать, y - крик, r - рейд, rw - пред. рейда");
			DEFAULT_CHAT_FRAME:AddMessage("p - группа, g - гильдия, o - офицеры, b - пб, m - себе");
		elseif(line == "silent" or line == "wpsm") then
			DEFAULT_CHAT_FRAME:AddMessage("Тихий режим - не показывать сообщения о пулах когда они происходят");
		elseif(line == "tank" or line == "tanks") then
			DEFAULT_CHAT_FRAME:AddMessage("Установить список танков (их пулы игнорируются)");
		elseif(line == "rage") then
			DEFAULT_CHAT_FRAME:AddMessage("Добавить игрока в список гнева за пул указанного врага");
		elseif(line == "forgive") then
			DEFAULT_CHAT_FRAME:AddMessage("Удалить игрока из списка гнева");
		elseif(line == "list") then
			DEFAULT_CHAT_FRAME:AddMessage("Показать список гнева");
		elseif(line == "ignore") then
			DEFAULT_CHAT_FRAME:AddMessage("Игнорировать/отслеживать пулы определенного врага");
		elseif(line == "help") then
			DEFAULT_CHAT_FRAME:AddMessage("Серьезно? lol");
		else
			DEFAULT_CHAT_FRAME:AddMessage("{} обязательные параметры, [] опциональные");
			DEFAULT_CHAT_FRAME:AddMessage("/wp help [тема] - помощь по конкретной команде");
			DEFAULT_CHAT_FRAME:AddMessage("/wp clear - очистить список пулов");
			DEFAULT_CHAT_FRAME:AddMessage("/wp boss {on/off/rw} - авто-сообщения о боссах");
			DEFAULT_CHAT_FRAME:AddMessage("/wp silent {on/off} - тихий режим");
			DEFAULT_CHAT_FRAME:AddMessage("/wp msg {сообщение} - кастомное сообщение");
			DEFAULT_CHAT_FRAME:AddMessage("/wp tanks [список танков] - установить танков");
			DEFAULT_CHAT_FRAME:AddMessage("/wp rage {враг} - добавить в список гнева");
			DEFAULT_CHAT_FRAME:AddMessage("/wp forgive {игрок} - простить игрока");
			DEFAULT_CHAT_FRAME:AddMessage("/wp list [враг/сервер] - показать список гнева");
			DEFAULT_CHAT_FRAME:AddMessage("/wp ignore [враг] - игнорировать врага");
			DEFAULT_CHAT_FRAME:AddMessage("/swho [враг] - сказать кто запулил");
			DEFAULT_CHAT_FRAME:AddMessage("/ywho [враг] - крикнуть кто запулил");
			DEFAULT_CHAT_FRAME:AddMessage("/rwho [враг] - сообщить в рейд");
			DEFAULT_CHAT_FRAME:AddMessage("/rwwho [враг] - предупредить рейд");
			DEFAULT_CHAT_FRAME:AddMessage("/pwho [враг] - сообщить в группу");
			DEFAULT_CHAT_FRAME:AddMessage("/bwho [враг] - сообщить в пб чат");
			DEFAULT_CHAT_FRAME:AddMessage("/gwho [враг] - сообщить в гильдию");
			DEFAULT_CHAT_FRAME:AddMessage("/owho [враг] - сообщить офицерам");
			DEFAULT_CHAT_FRAME:AddMessage("/mwho [враг] - показать себе");
		end
	end
end

function WhoPulled_SendMsg(chat,enemy)
	local msg,player;
	if enemy == "" then enemy = WhoPulled_LastMob; end
	player = WhoPulled_MobToPlayer[enemy];
	if player then
		msg = WhoPulled_Settings["msg"]:gsub("%%p",player);
		msg = msg:gsub("%%e",enemy);
		if(chat == "ECHO") then
			DEFAULT_CHAT_FRAME:AddMessage(msg);
		else
			SendChatMessage(msg,chat);
		end
	else
		DEFAULT_CHAT_FRAME:AddMessage("Нет информации о том, кто запулил этого врага");
	end
end

function WhoPulled_Say(enemy)
	WhoPulled_SendMsg("SAY",enemy)
end
function WhoPulled_Yell(enemy)
	WhoPulled_SendMsg("YELL",enemy)
end
function WhoPulled_Raid(enemy)
	WhoPulled_SendMsg("RAID",enemy)
end
function WhoPulled_Party(enemy)
	WhoPulled_SendMsg("PARTY",enemy)
end
function WhoPulled_BG(enemy)
	WhoPulled_SendMsg("BATTLEGROUND",enemy)
end
function WhoPulled_Guild(enemy)
	WhoPulled_SendMsg("GUILD",enemy)
end
function WhoPulled_Officer(enemy)
	WhoPulled_SendMsg("OFFICER",enemy)
end
function WhoPulled_RaidWarning(enemy)
	WhoPulled_SendMsg("RAID_WARNING",enemy)
end
function WhoPulled_Me(enemy)
	WhoPulled_SendMsg("ECHO",enemy)
end

function WhoPulled_YoB()
	WhoPulled_Settings["yonboss"] = not WhoPulled_Settings["yonboss"];
	if(WhoPulled_Settings["yonboss"]) then DEFAULT_CHAT_FRAME:AddMessage("Авто-крик при пуле боссов: ВКЛ");
	else DEFAULT_CHAT_FRAME:AddMessage("Авто-крик при пуле боссов: ВЫКЛ");
	end
end

function WhoPulled_Silent()
	WhoPulled_Settings["silent"] = not WhoPulled_Settings["silent"];
	if(WhoPulled_Settings["silent"]) then DEFAULT_CHAT_FRAME:AddMessage("Тихий режим: ВКЛ");
	else DEFAULT_CHAT_FRAME:AddMessage("Тихий режим: ВЫКЛ");
	end
end

SlashCmdList["YWHOPULLED"] = WhoPulled_Yell;
SLASH_YWHOPULLED1 = "/ywho";
SlashCmdList["SWHOPULLED"] = WhoPulled_Say;
SLASH_SWHOPULLED1 = "/swho";
SlashCmdList["RWHOPULLED"] = WhoPulled_Raid;
SLASH_RWHOPULLED1 = "/rwho";
SlashCmdList["PWHOPULLED"] = WhoPulled_Party;
SLASH_PWHOPULLED1 = "/pwho";
SlashCmdList["BWHOPULLED"] = WhoPulled_BG;
SLASH_BWHOPULLED1 = "/bwho";
SlashCmdList["MWHOPULLED"] = WhoPulled_Me;
SLASH_MWHOPULLED1 = "/mwho";
SlashCmdList["GWHOPULLED"] = WhoPulled_Guild;
SLASH_GWHOPULLED1 = "/gwho";
SlashCmdList["OWHOPULLED"] = WhoPulled_Officer;
SLASH_OWHOPULLED1 = "/owho";
SlashCmdList["RWWHOPULLED"] = WhoPulled_RaidWarning;
SLASH_RWWHOPULLED1 = "/rwwho";
SlashCmdList["WHOPULLED"] = WhoPulled_CLI;
SLASH_WHOPULLED1 = "/wp";
SlashCmdList["WHOPULLEDB"] = WhoPulled_YoB;
SLASH_WHOPULLEDB1 = "/wpyb";
SlashCmdList["WHOPULLEDSM"] = WhoPulled_Silent;
SLASH_WHOPULLEDSM1 = "/wpsm";