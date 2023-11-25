-- Addon: WoWinArabic-Bubbles (version: 10.2) 2023.11.25
-- Note: AddOn displays translated Bubbles of NPC in Arabic.
-- Autor: Platine  (e-mail: platine.wow@gmail.com)
-- Contributor: DragonArab - Developed letter reshaping tables and ligatures (http://WoWinArabic.com)

-------------------------------------------------------------------------------------------------------

local BB_version = GetAddOnMetadata("WoWinArabic_Bubbles", "Version");
local BB_ctrFrame = CreateFrame("FRAME", "WoWinArabic-BubblesFrame");
local BB_Font = "Interface\\AddOns\\WoWinArabic_Bubbles\\Fonts\\calibri.ttf";
local BB_player_class= UnitClass("player");
local BB_player_race = UnitRace("player");
local BB_player_name = UnitName("player");
local BB_player_sex  = UnitSex("player");     -- 1:neutral,  2:male,  3:female
local BB_BubblesArray = {};
local p_race = {};
local p_class = {};
local player_race = {};
local player_class = {};
local BB_TRvisible= 0;
local BB_Zatrzask = 0;
local BB_name_NPC = "";
local BB_hash_Code= "";
local BB_bufor = {};
local BB_gotowe= {};
local BB_ile_got = 0;
local BB_first = 1;
local Y_Race1=UnitRace("player");
local Y_Race2=string.lower(UnitRace("player"));
local Y_Race3=string.upper(UnitRace("player"));
local Y_Class1=UnitClass("player");
local Y_Class2=string.lower(UnitClass("player"));
local Y_Class3=string.upper(UnitClass("player"));
local BB_waitTable = {};
local BB_waitFrame = nil;
local limiter = 45;        -- number of characters in one line of Talking Head frame
local limit_chars1 = 30;    -- max. number of 1 line on bubble (one-line bubble)
local limit_chars2 = 50;    -- max. number of 2 line on bubble (two-lines bubble)

-------------------------------------------------------------------------------------------------------

local function StringHash(text)           -- function creates a Hash (32-bit number) of the given text
  local counter = 1;
  local pomoc = 0;
  local dlug = string.len(text);
  for i = 1, dlug, 3 do 
    counter = math.fmod(counter*8161, 4294967279);  -- 2^32 - 17: Prime!
    pomoc = (string.byte(text,i)*16776193);
    counter = counter + pomoc;
    pomoc = ((string.byte(text,i+1) or (dlug-i+256))*8372226);
    counter = counter + pomoc;
    pomoc = ((string.byte(text,i+2) or (dlug-i+256))*3932164);
    counter = counter + pomoc;
  end
  return math.fmod(counter, 4294967291) -- 2^32 - 5: Prime (and different from the prime in the loop)
end

-------------------------------------------------------------------------------------------------------

function BB_wait(delay, func, ...)
   if(type(delay)~="number" or type(func)~="function") then
      return false;
   end
   if (BB_waitFrame == nil) then
     BB_waitFrame = CreateFrame("Frame","BB_WaitFrame", UIParent);
     BB_waitFrame:SetScript("onUpdate",function (self,elapse)
      local count = #BB_waitTable;
      local i = 1;
      while (i<=count) do
         local waitRecord = tremove(BB_waitTable,i);
         local d = tremove(waitRecord,1);
         local f = tremove(waitRecord,1);
         local p = tremove(waitRecord,1);
         if(d>elapse) then
            tinsert(BB_waitTable,i,{d-elapse,f,p});
            i = i + 1;
         else
            count = count - 1;
            f(unpack(p));
         end
      end
     end);
   end
   tinsert(BB_waitTable,{delay,func,{...}});
   return true;
end

-------------------------------------------------------------------------------------------------------

local function BB_bubblizeText()
   if (TalkingHeadFrame and TalkingHeadFrame:IsVisible()) then
      for idx, iArray in ipairs(BB_BubblesArray) do      -- sprawdź, czy dane są właściwe (tekst oryg. się zgadza z zapisaną w tablicy)
         if (TalkingHeadFrame.TextFrame.Text:GetText() ==  iArray[1]) then
            local _font1, _size1, _3 = TalkingHeadFrame.TextFrame.Text:GetFont(); -- odczytaj aktualną czcionkę i rozmiar
            TalkingHeadFrame.TextFrame.Text:SetJustifyH("RIGHT");                 -- wyrównanie do prawej strony
            TalkingHeadFrame.TextFrame.Text:SetFont(BB_Font, _size1+2);           -- wpisz arabską czcionkę
            TalkingHeadFrame.TextFrame.Text:SetText(TH_LineReverse(iArray[2], limiter));   -- wpisz arabskie tłumaczenie w oknie TH - limit znaków w linii
            tremove(BB_BubblesArray, idx);               -- usuń zapamiętane dane z tablicy
         end
      end
   else
      for _, bubble in pairs(C_ChatBubbles.GetAllChatBubbles()) do
      -- Iterate the children, as the actual bubble content 
      -- has been placed in a nameless subframe in 9.0.1.
         for i = 1, bubble:GetNumChildren() do
            local child = select(i, select(i, bubble:GetChildren()))
            if not child:IsForbidden() then                       -- czy ramka nie jest zabroniona?
               if (child:GetObjectType() == "Frame") and (child.String) and (child.Center) then
               -- This is hopefully the frame with the content
                  for i = 1, child:GetNumRegions() do
                     local region = select(i, child:GetRegions());
                     for idx, iArray in ipairs(BB_BubblesArray) do      -- sprawdź, czy dane są właściwe (tekst oryg. się zgadza z zapisaną w tablicy)
                        if region and not region:GetName() and region:IsVisible() and region.GetText and (region:GetText() == iArray[1]) then
                           if (BB_PM["setsize"]=="1") then              -- jest włączona wielkość czcionki dymku
                              region:SetFont(BB_Font, tonumber(BB_PM["fontsize"]));   -- ustaw arabską czcionkę oraz zmienioną wielkość
                              act_font = tonumber(BB_PM["fontsize"]);
                           else
                              local _font1, _size1, _3 = region:GetFont(); -- odczytaj aktualną czcionkę i rozmiar
                              region:SetFont(BB_Font, _size1);             -- ustaw arabską czcionkę oraz niezmienioną wielkość (13)
                              act_font = _size1;
                           end
                           local newText = AS_UTF8reverse(iArray[2]);   -- text reshaped
                           if ((AS_UTF8len(newText) >= limit_chars2) or (region:GetHeight() > act_font*3)) then    -- 3 lines or more
                              region:SetJustifyH("RIGHT");              -- wyrównanie do prawej strony (domyślnie jest CENTER)
                              newText = BB_LineReverse(iArray[2], 3);
                              region:SetText(newText);
                           elseif ((AS_UTF8len(newText) >= limit_chars1) or (region:GetHeight() > act_font*2)) then   -- 2 lines
                              region:SetJustifyH("RIGHT");              -- wyrównanie do prawej strony
                              newText = BB_LineReverse(iArray[2], 2);
                              region:SetText(newText);
                           else                                         -- bubble in 1-line
                              region:SetJustifyH("CENTER");             -- wyrównanie do środka
                              region:SetText(newText);                  -- wpisz tu nasze tłumaczenie
                           end
                           region:SetWidth(BB_SpecifyBubbleWidth(newText, region));  -- określ nową szer. okna
                           tremove(BB_BubblesArray, idx);               -- usuń zapamiętane dane z tablicy
                        end
                     end
                  end
               end
            end
         end
      end
   end

   for idx, iArray in ipairs(BB_BubblesArray) do            -- przeszukaj jeszcze raz tablicę
      if (iArray[3] >= 100) then                            -- licznik osiągnął 100
         tremove(BB_BubblesArray, idx);                     -- usuń zapamiętane dane z tablicy
      else
         iArray[3] = iArray[3]+1;                           -- zwiększ licznik (nie pokazał się dymek?)
      end;
   end;
   if (#(BB_BubblesArray) == 0) then
      BB_ctrFrame:SetScript("OnUpdate", nil);               -- wyłącz metodę Update, bo tablica pusta
   end;
end;

-------------------------------------------------------------------------------------------------------

local function ChatFilter(self, event, arg1, arg2, arg3, _, arg5, ...)     -- wywoływana, gdy na chat ma pojawić się tekst od NPC
   local changeBubble = false;
   local colorText = "";
   local original_txt = strtrim(arg1);
   local name_NPC = string.gsub(arg2, " says:", "");
   local target = arg5;
	
   if (event == "CHAT_MSG_MONSTER_SAY") then          -- określ kolor tekstu do okna chat
      colorText = "|cFFFFFF9F";
      if (GetCVar("ChatBubbles")) then
         changeBubble = true;
      end
   elseif (event == "CHAT_MSG_MONSTER_PARTY") then
      colorText = "|cFFAAAAFF";
   elseif (event == "CHAT_MSG_MONSTER_YELL") then
      colorText = "|cFFFF4040";
      if (GetCVar("ChatBubbles")) then
         changeBubble = true;
      end
   elseif (event == "CHAT_MSG_MONSTER_WHISPER") then
      colorText = "|cFFFFB5EB";
   elseif (event == "CHAT_MSG_MONSTER_EMOTE") then
      colorText = "|cFFFF8040";
   end

   BB_is_translation = "0";      
   if (BB_PM["active"] == "1") then                       -- dodatek aktywny - szukaj tłumaczenia
      if (arg5 ~= "") then
         original_txt = string.gsub(original_txt, arg5, "");        -- usuń osobę ($target) z tekstu oryginalnego
      end
      original_txt = string.gsub(original_txt, Y_Race1, "");        -- usuń rasę z tekstu
      original_txt = string.gsub(original_txt, Y_Race2, "");
      original_txt = string.gsub(original_txt, Y_Race3, "");
      original_txt = string.gsub(original_txt, Y_Class1, "");       -- usuń klasę z tekstu
      original_txt = string.gsub(original_txt, Y_Class2, "");
      original_txt = string.gsub(original_txt, Y_Class3, "");
      if (string.sub(name_NPC,1,17) == "Bronze Timekeeper") then    -- wyścigi na smokach - wyjątej z sekundami
         original_txt = string.gsub(original_txt, "0", "");
         original_txt = string.gsub(original_txt, "1", "");
         original_txt = string.gsub(original_txt, "2", "");
         original_txt = string.gsub(original_txt, "3", "");
         original_txt = string.gsub(original_txt, "4", "");
         original_txt = string.gsub(original_txt, "5", "");
         original_txt = string.gsub(original_txt, "6", "");
         original_txt = string.gsub(original_txt, "7", "");
         original_txt = string.gsub(original_txt, "8", "");
         original_txt = string.gsub(original_txt, "9", "");
      end
      local HashCode = StringHash(original_txt);
      if (BB_Bubbles[HashCode]) then         -- jest tłumaczenie polskie
         newMessage = BB_Bubbles[HashCode];
         newMessage = BB_ZmienKody(newMessage,arg5);
         if (string.sub(name_NPC,1,17) == "Bronze Timekeeper") then       -- wyścigi na smokach - wyjątej z sekundami: $1.$2 oraz $3.$4
            local wartab = {0,0,0,0};                                     -- max. 4 liczby całkowite w tekście
            local arg0 = 0;
            for w in string.gmatch(strtrim(arg1), "%d+") do
               arg0 = arg0 + 1;
               wartab[arg0] = w;      -- tu mamy kolejne liczby całkowite z oryginału
            end;
            if (arg0>3) then
               newMessage=string.gsub(newMessage, "$4", wartab[4]);
            end
            if (arg0>2) then
               newMessage=string.gsub(newMessage, "$3", wartab[3]);
            end
            if (arg0>1) then
               newMessage=string.gsub(newMessage, "$2", wartab[2]);
            end
            if (arg0>0) then
               newMessage=string.gsub(newMessage, "$1", wartab[1]);
            end
         end
         BB_is_translation="1"; 
         nr_poz=BB_FindProS(newMessage,1);
         if (BB_PM["chat-ar"] == "1") then                -- wyświetlaj tłumaczenie w linii czatu
            local _fontC, _sizeC, _C = DEFAULT_CHAT_FRAME:GetFont(); -- odczytaj aktualną czcionkę, rozmiar i typ
            DEFAULT_CHAT_FRAME:SetFont(BB_Font, _sizeC, _C);
            if (nr_poz>0) then           -- mamy formę opisową dymku $S np. NPC_name wpada w szał!
               if (nr_poz==1) then
                  newMessage = AS_UTF8reverse(name_NPC)..strsub(newMessage, 3);
               else
                  newMessage = strsub(newMessage,1,nr_poz-1)..AS_UTF8reverse(name_NPC)..strsub(newMessage, nr_poz+2);
               end
               DEFAULT_CHAT_FRAME:AddMessage(colorText..BB_LineChat(newMessage, _sizeC, 0));
            elseif (strsub(newMessage,1,2)=="$O") then                  -- jest forma '$O'
               newMessage = strsub(newMessage, 3):gsub("^%s*", "");     -- usuń białe spacje na początku
               DEFAULT_CHAT_FRAME:AddMessage(colorText..BB_LineChat(newMessage, _sizeC, 0)); 
            else
               DEFAULT_CHAT_FRAME:AddMessage(colorText..BB_LineChat("r|"..AS_UTF8reverse(name_NPC).." يتحدث:FFEEDDCCc| "..newMessage, _sizeC, 12));   -- 12=count of unwritable characters (color)
            end
         else   
            if (nr_poz>0) then        -- mamy formę opisową dymku np. NPC_name coś robi.
               if (nr_poz==1) then
                  newMessage = AS_UTF8reverse(name_NPC)..strsub(newMessage, 3);
               else
                  newMessage = strsub(newMessage,1,nr_poz-1)..AS_UTF8reverse(name_NPC)..strsub(newMessage, nr_poz+2);
               end
            elseif (strsub(newMessage,1,2)=="$O") then         -- jest forma '$O'
               newMessage = strsub(newMessage, 3);
            end
         end
         if (changeBubble) then                          -- wyświetlaj dymek po arabsku (jeśli istnieje)
            tinsert(BB_BubblesArray, { [1] = arg1, [2] = newMessage, [3] = 1 });
            BB_ctrFrame:SetScript("OnUpdate", BB_bubblizeText);
         end
      else                                               -- nie mamy tłumaczenia
         original_txt = strtrim(arg1);                   -- jeszcze raz wczytaj pełny tekst angielski
         if (BB_PM["saveNB"] == "1") then                -- zapisz oryginalny tekst
            BB_PS[name_NPC..":"..tostring(HashCode)] = original_txt.."@"..target..":"..BB_player_name..":"..Y_Race1..":"..Y_Class1;
         end
      end
   end

   if ((BB_PM["chat-en"] == "1") or (BB_is_translation ~= "1")) then     -- gdy nie ma także tłumaczenia                 
      return false;     -- wyświetlaj tekst oryginalny w oknie czatu
   else
      return true;      -- nie wyświetlaj oryginalnego tekstu
   end   
   
end

-------------------------------------------------------------------------------------------------------

function BB_FindProS(text)                 -- znajdź, czy jest tekst '$S' w podanym tłumaczeniu
   local dl_txt = string.len(text)-1;
   for i_j=1,dl_txt,1 do
      if (strsub(text,i_j,i_j+1)=="$S") then       
         return i_j;
      end
   end
   return 0;
end

-------------------------------------------------------------------------------------------------------

local function BB_CheckVars()
  if (not BB_PM) then
     BB_PM = {};
  end
  if (not BB_PS) then
     BB_PS = {};
  end
  -- initialize check options
  if (not BB_PM["active"] ) then    -- dodatek aktywny
     BB_PM["active"] = "1";   
  end
  if (not BB_PM["chat-ar"] ) then   -- pokaż tłumaczenie w oknie czatu
     BB_PM["chat-ar"] = "1";
  end
  if (not BB_PM["chat-en"] ) then   -- pokaż tekst angielski w oknie czatu
     BB_PM["chat-en"] = "0";   
  end
  if (not BB_PM["saveNB"] ) then    -- zapisz nieprzetłumaczone dymki
     BB_PM["saveNB"] = "1";   
  end
  if (not BB_PM["setsize"] ) then   -- uaktywnij zmiany wielkości czcionki
     BB_PM["setsize"] = "0";   
  end
  if (not BB_PM["fontsize"] ) then  -- wielkość czcionki
     BB_PM["fontsize"] = "14";   
  end
  if (not BB_PM["sex"] ) then       -- wybór płci wypowiedzi do gracza
     if (player_sex==3) then
        BB_PM["sex"] = "3";
     else
        BB_PM["sex"] = "2";
     end
  end
end
  
-------------------------------------------------------------------------------------------------------

local function BB_SetCheckButtonState()
  BBCheckButton1:SetValue(BB_PM["active"]=="1");
  BBCheckButton2:SetValue(BB_PM["chat-en"]=="1");
  BBCheckButton3:SetValue(BB_PM["chat-ar"]=="1");
  BBCheckButton5:SetValue(BB_PM["saveNB"]=="1");
  BBCheckSize:SetValue(BB_PM["setsize"]=="1");
  local fontsize = tonumber(BB_PM["fontsize"]);
  BBslider:SetValue(fontsize);
  if (BB_PM["setsize"]=="1") then
     BBOpis1:SetFont(BB_Font, fontsize);
  else   
     BBOpis1:SetFont(BB_Font, 15);
  end
  BBsex1:SetValue(BB_PM["sex"]=="2");
  BBsex2:SetValue(BB_PM["sex"]=="3");
  BBsex3:SetValue(BB_PM["sex"]=="4");
end

-------------------------------------------------------------------------------------------------------

local function BB_BlizzardOptions()

-- Create main frame for information text
local BBOptions = CreateFrame("FRAME", "WoWinArabicBubblesOptions");
BBOptions.refresh = function (self) BB_SetCheckButtonState() end;
BBOptions.name = "WoWinArabic-Bubbles";
InterfaceOptions_AddCategory(BBOptions);

local BBOptionsHeader = BBOptions:CreateFontString(nil, "ARTWORK");
BBOptionsHeader:SetFontObject(GameFontNormalLarge);
BBOptionsHeader:SetJustifyH("LEFT"); 
BBOptionsHeader:SetJustifyV("TOP");
BBOptionsHeader:ClearAllPoints();
BBOptionsHeader:SetPoint("TOPLEFT", 100, -16);
BBOptionsHeader:SetText("2023 ﺔﻨﺴﻟ Platine ﺭﻮﻄﻤﻟﺍ".." ("..BB_base.. ") "..BB_version.." ﺔﺨﺴﻧ WoWinArabic-Bubbles ﺔﻓﺎﺿﺇ");
BBOptionsHeader:SetFont(BB_Font, 16);

local BBOptionsDate = BBOptions:CreateFontString(nil, "ARTWORK");
BBOptionsDate:SetFontObject(GameFontNormalLarge);
BBOptionsDate:SetJustifyH("LEFT"); 
BBOptionsDate:SetJustifyV("TOP");
BBOptionsDate:ClearAllPoints();
BBOptionsDate:SetPoint("TOPRIGHT", BBOptionsHeader, "TOPRIGHT", 0, -22);
BBOptionsDate:SetText("DragonArab :ﺔﻴﺑﺮﻌﻟﺍ ﺔﻐﻠﻟﺍ ﻞﻴﻜﺸﺗ ﺭﻮﻄﻣ "..BB_date.." : ﺔﻤﺟﺮﺘﻟﺍ ﺕﺎﻧﺎﻴﺑ ﺓﺪﻋﺎﻗ ﺦﻳﺭﺎﺗ");
BBOptionsDate:SetFont(BB_Font, 16);

local BBCheckButton1 = CreateFrame("CheckButton", "BBCheckButton1", BBOptions, "SettingsCheckBoxControlTemplate");
BBCheckButton1.CheckBox:SetScript("OnClick", function(self) if (BB_PM["active"]=="1") then BB_PM["active"]="0" else BB_PM["active"]="1" end; end);
BBCheckButton1.CheckBox:SetPoint("TOPLEFT", BBOptionsDate, "BOTTOMLEFT", 456, -30);    -- pozycja przycisku CheckBox
BBCheckButton1:SetPoint("TOPRIGHT", BBOptionsDate, "BOTTOMRIGHT", 120, -32);     -- pozycja opisu przycisku CheckBox
BBCheckButton1.Text:SetText(AS_UTF8reverse(BB_Interface.active));     -- dodatek aktywny
BBCheckButton1.Text:SetFont(BB_Font, 18);
BBCheckButton1.Text:SetJustifyH("RIGHT");

local BBOptionsMode = BBOptions:CreateFontString(nil, "ARTWORK");
BBOptionsMode:SetFontObject(GameFontWhite);
BBOptionsMode:SetJustifyH("RIGHT");
BBOptionsMode:SetJustifyV("TOP");
BBOptionsMode:ClearAllPoints();
BBOptionsMode:SetPoint("TOPRIGHT", BBOptionsDate, "BOTTOMRIGHT", -10, -80);
BBOptionsMode:SetFont(BB_Font, 18);
BBOptionsMode:SetText(":"..AS_UTF8reverse(BB_Interface.settings));          -- Ustawienia dodatku

local BBCheckButton3 = CreateFrame("CheckButton", "BBCheckButton3", BBOptions, "SettingsCheckBoxControlTemplate");
BBCheckButton3.CheckBox:SetScript("OnClick", function(self) if (BB_PM["chat-ar"]=="1") then BB_PM["chat-ar"]="0" else BB_PM["chat-ar"]="1" end; end);
BBCheckButton3.CheckBox:SetPoint("TOPLEFT", BBOptionsDate, "BOTTOMLEFT", 456, -130);
BBCheckButton3:SetPoint("TOPLEFT", BBOptionsDate, "BOTTOMLEFT", 204, -132);
BBCheckButton3.Text:SetText(AS_UTF8reverse(BB_Interface.ar_in_chat));
BBCheckButton3.Text:SetFont(BB_Font, 18);
BBCheckButton3.Text:SetJustifyH("RIGHT");

local BBCheckButton2 = CreateFrame("CheckButton", "BBCheckButton2", BBOptions, "SettingsCheckBoxControlTemplate");
BBCheckButton2.CheckBox:SetScript("OnClick", function(self) if (BB_PM["chat-en"]=="1") then BB_PM["chat-en"]="0" else BB_PM["chat-en"]="1" end; end);
BBCheckButton2.CheckBox:SetPoint("TOPLEFT", BBCheckButton3.CheckBox, "BOTTOMLEFT", 0, 0);
BBCheckButton2:SetPoint("TOPLEFT", BBCheckButton3.CheckBox, "BOTTOMLEFT", -257, -2);
BBCheckButton2.Text:SetText(AS_UTF8reverse(BB_Interface.eng_in_chat));
BBCheckButton2.Text:SetFont(BB_Font, 18);
BBCheckButton2.Text:SetJustifyH("RIGHT");

local BBCheckButton5 = CreateFrame("CheckButton", "BBCheckButton5", BBOptions, "SettingsCheckBoxControlTemplate");
BBCheckButton5.CheckBox:SetScript("OnClick", function(self) if (BB_PM["saveNB"]=="1") then BB_PM["saveNB"]="0" else BB_PM["saveNB"]="1" end; end);
BBCheckButton5.CheckBox:SetPoint("TOPLEFT", BBCheckButton2.CheckBox, "BOTTOMLEFT", 0, 0);
BBCheckButton5:SetPoint("TOPLEFT", BBCheckButton2.CheckBox, "BOTTOMLEFT", -290, -2);
BBCheckButton5.Text:SetText(AS_UTF8reverse(BB_Interface.save_new));
BBCheckButton5.Text:SetFont(BB_Font, 18);
BBCheckButton5.Text:SetJustifyH("RIGHT");

local BBCheckSize = CreateFrame("CheckButton", "BBCheckSize", BBOptions, "SettingsCheckBoxControlTemplate");
BBCheckSize.CheckBox:SetScript("OnClick", function(self) if (BB_PM["setsize"]=="1") then BB_PM["setsize"]="0" else BB_PM["setsize"]="1" end; end);
BBCheckSize.CheckBox:SetPoint("TOPLEFT", BBCheckButton5.CheckBox, "BOTTOMLEFT", 0, -15);
BBCheckSize:SetPoint("TOPLEFT", BBCheckButton5.CheckBox, "BOTTOMLEFT", -298, -17);
BBCheckSize.Text:SetText(AS_UTF8reverse(BB_Interface.font_activ));   
BBCheckSize.Text:SetFont(BB_Font, 18);
BBCheckSize.Text:SetJustifyH("RIGHT");

local BBslider = CreateFrame("Slider", "BBslider", BBOptions, "OptionsSliderTemplate");
BBslider:SetPoint("TOPLEFT", BBCheckSize, "BOTTOMLEFT", 170, -30);
BBslider:SetMinMaxValues(10, 25);
BBslider.minValue, BBslider.maxValue = BBslider:GetMinMaxValues();
BBslider.Low:SetText(BBslider.minValue);
BBslider.High:SetText(BBslider.maxValue);
getglobal(BBslider:GetName() .. 'Text'):SetText(AS_UTF8reverse(BB_Interface.font_size));
getglobal(BBslider:GetName() .. 'Text'):SetFont(BB_Font, 16);
getglobal(BBslider:GetName() .. 'Text'):SetJustifyH("RIGHT");
BBslider:SetValue(tonumber(BB_PM["fontsize"]));
BBslider:SetValueStep(1);
BBslider:SetScript("OnValueChanged", function(self,event,arg1) 
                                      BB_PM["fontsize"]=string.format("%d",event); 
                                      BBsliderVal:SetText(BB_PM["fontsize"]);
									           BBOpis1:SetFont(BB_Font, event);
                                      end);
BBsliderVal = BBOptions:CreateFontString(nil, "ARTWORK");
BBsliderVal:SetFontObject(GameFontNormal);
BBsliderVal:SetJustifyH("CENTER");
BBsliderVal:SetJustifyV("TOP");
BBsliderVal:ClearAllPoints();
BBsliderVal:SetPoint("CENTER", BBslider, "CENTER", 0, -12);
BBsliderVal:SetText(BB_PM["fontsize"]);   
BBsliderVal:SetFont(BB_Font, 16);

BBOpis1 = BBOptions:CreateFontString(nil, "ARTWORK");
BBOpis1:SetFontObject(GameFontNormalLarge);
BBOpis1:SetJustifyH("LEFT");
BBOpis1:SetJustifyV("TOP");
BBOpis1:ClearAllPoints();
BBOpis1:SetPoint("TOPLEFT", BBslider, "BOTTOMLEFT", -300, 30);
local fontsize = tonumber(BB_PM["fontsize"]);
if (BB_PM["setsize"]=="1") then
   BBOpis1:SetFont(BB_Font, fontsize);
else
   BBOpis1:SetFont(BB_Font, 14);
end
BBOpis1:SetText(AS_UTF8reverse("نموذج نص حجم الخط"));       -- przykładowy tekst
BBOpis1:SetJustifyH("RIGHT");

local BBsex0 = BBOptions:CreateFontString(nil, "ARTWORK");
BBsex0:SetFontObject(GameFontNormal);
BBsex0:SetJustifyH("LEFT");
BBsex0:SetJustifyV("TOP");
BBsex0:ClearAllPoints();
BBsex0:SetPoint("TOPLEFT", BBCheckSize.CheckBox, "BOTTOMLEFT", -245, -80);
BBsex0:SetFont(BB_Font, 18);
BBsex0:SetText(":"..AS_UTF8reverse(BB_Interface.display_sex));     -- 2:męski,  3:żeński,  4:zależny od płci postaci
BBsex0:SetJustifyH("RIGHT");
   
local BBsex1 = CreateFrame("CheckButton", "BBsex1", BBOptions, "SettingsCheckBoxControlTemplate");
BBsex1.CheckBox:SetScript("OnClick", function(self) if (BB_PM["sex"]=="2") then BB_PM["sex"]="4";BBsex2.CheckBox:SetChecked(false);BBsex3.CheckBox:SetChecked(true) else BB_PM["sex"]="2";BBsex2.CheckBox:SetChecked(false);BBsex3.CheckBox:SetChecked(false) end; end);
BBsex1.CheckBox:SetPoint("TOPLEFT", BBsex0, "TOPRIGHT", -25, -25);
BBsex1:SetPoint("TOPLEFT", BBsex0, "TOPRIGHT", -125, -27);
BBsex1.Text:SetText(AS_UTF8reverse(BB_Interface.i_am_male)); 
BBsex1.Text:SetFont(BB_Font, 18);
BBsex1.Text:SetJustifyH("RIGHT");

local BBsex2 = CreateFrame("CheckButton", "BBsex2", BBOptions, "SettingsCheckBoxControlTemplate");
BBsex2.CheckBox:SetScript("OnClick", function(self) if (BB_PM["sex"]=="3") then BB_PM["sex"]="4";BBsex1.CheckBox:SetChecked(false);BBsex3.CheckBox:SetChecked(true) else BB_PM["sex"]="3";BBsex1.CheckBox:SetChecked(false);BBsex3.CheckBox:SetChecked(false) end; end);
BBsex2.CheckBox:SetPoint("TOPLEFT", BBsex1.CheckBox, "TOPLEFT", -160, 0);
BBsex2:SetPoint("TOPLEFT", BBsex1.CheckBox, "TOPLEFT", -260, -2);
BBsex2.Text:SetText(AS_UTF8reverse(BB_Interface.i_am_female)); 
BBsex2.Text:SetFont(BB_Font, 18);
BBsex2.Text:SetJustifyH("RIGHT");

local BBsex3 = CreateFrame("CheckButton", "BBsex3", BBOptions, "SettingsCheckBoxControlTemplate");
BBsex3.CheckBox:SetScript("OnClick", function(self) if (BB_PM["sex"]=="4") then BB_PM["sex"]="2";BBsex1.CheckBox:SetChecked(true);BBsex2.CheckBox:SetChecked(false) else BB_PM["sex"]="4";BBsex1.CheckBox:SetChecked(false);BBsex2.CheckBox:SetChecked(false) end; end);
BBsex3.CheckBox:SetPoint("TOPLEFT", BBsex0, "TOPRIGHT", -25, -55);
BBsex3:SetPoint("TOPLEFT", BBsex0, "TOPLEFT", -104, -57);
BBsex3.Text:SetText(AS_UTF8reverse(BB_Interface.player_sex)); 
BBsex3.Text:SetFont(BB_Font, 18);
BBsex3.Text:SetJustifyH("RIGHT");


local BBText0 = BBOptions:CreateFontString(nil, "ARTWORK");
BBText0:SetFontObject(GameFontWhite);
BBText0:SetJustifyH("LEFT");
BBText0:SetJustifyV("TOP");
BBText0:ClearAllPoints();
BBText0:SetPoint("BOTTOMLEFT", 16, 90);
BBText0:SetFont(BB_Font, 13);
BBText0:SetText("Quick commands from the chat line:");

local BBText7 = BBOptions:CreateFontString(nil, "ARTWORK");
BBText7:SetFontObject(GameFontWhite);
BBText7:SetJustifyH("LEFT");
BBText7:SetJustifyV("TOP");
BBText7:ClearAllPoints();
BBText7:SetPoint("TOPLEFT", BBText0, "BOTTOMLEFT", 0, -10);
BBText7:SetFont(BB_Font, 13);
BBText7:SetText("/bbtr   to bring up this addon settings window");

local BBText1 = BBOptions:CreateFontString(nil, "ARTWORK");
BBText1:SetFontObject(GameFontWhite);
BBText1:SetJustifyH("LEFT");
BBText1:SetJustifyV("TOP");
BBText1:ClearAllPoints();
BBText1:SetPoint("TOPLEFT", BBText7, "BOTTOMLEFT", 0, -10);
BBText1:SetFont(BB_Font, 13);
BBText1:SetText("/bbtr 1  or  /bbtr on   to activate the addon");

local BBText2 = BBOptions:CreateFontString(nil, "ARTWORK");
BBText2:SetFontObject(GameFontWhite);
BBText2:SetJustifyH("LEFT");
BBText2:SetJustifyV("TOP");
BBText2:ClearAllPoints();
BBText2:SetPoint("TOPLEFT", BBText1, "BOTTOMLEFT", 0, -4);
BBText2:SetFont(BB_Font, 13);
BBText2:SetText("/bbtr 0  or  /bbtr off   to deactivate the addon");

end

-------------------------------------------------------------------------------------------------------

local function BB_SlashCommand(msg)
  -- check the command
  if (msg) then
     local BB_command = string.lower(msg);                -- normalizacja, tylko małe litery
     if ((BB_command=="on") or (BB_command=="1")) then    -- włącz przełącznik aktywności
        BB_PM["active"]="1";
        DEFAULT_CHAT_FRAME:AddMessage("|cffffff00WoWinArabic-Bubbles is active now");
     elseif ((BB_command=="off") or (BB_command=="0")) then
        BB_PM["active"]="0";
        DEFAULT_CHAT_FRAME:AddMessage("|cffffff00WoWinArabic-Bubbless is inactive now");
     else
        Settings.OpenToCategory("WoWinArabic-Bubbles");
     end   
  end
end

-------------------------------------------------------------------------------------------------------

local function BBTR_onEvent(self, event, name, ...)
   if (event=="ADDON_LOADED" and name=="WoWinArabic_Bubbles") then
      BBTR_f:UnregisterEvent("ADDON_LOADED");
      local _fontC, _sizeC, _C = DEFAULT_CHAT_FRAME:GetFont(); -- odczytaj aktualną czcionkę, rozmiar i typ
      DEFAULT_CHAT_FRAME:SetFont(BB_Font, _sizeC, _C);
      ChatFrame_AddMessageEventFilter("CHAT_MSG_MONSTER_SAY", ChatFilter)
      ChatFrame_AddMessageEventFilter("CHAT_MSG_MONSTER_PARTY", ChatFilter)
      ChatFrame_AddMessageEventFilter("CHAT_MSG_MONSTER_YELL", ChatFilter)
      ChatFrame_AddMessageEventFilter("CHAT_MSG_MONSTER_WHISPER", ChatFilter)
      ChatFrame_AddMessageEventFilter("CHAT_MSG_MONSTER_EMOTE", ChatFilter)
      SlashCmdList["WOWINARABIC_BUBBLES"] = function(msg) BB_SlashCommand(msg); end
      SLASH_WOWINARABIC_BUBBLES1 = "/wowinarabic-bubbles";
      SLASH_WOWINARABIC_BUBBLES2 = "/bbtr";
      BB_CheckVars();
      BB_BlizzardOptions();
      DEFAULT_CHAT_FRAME:AddMessage("|cffffff00WoWinArabic-Bubbles ver. "..BB_version.." - "..BB_Interface.started);
      BBTR_f.ADDON_LOADED = nil;
      p_race = {
         ["Blood Elf"] = { M1="بلود إيلف", M2="بلود إيلف" },
         ["Dark Iron Dwarf"] = { M1="دارك ايرون دوارف", M2="دارك ايرون دوارف" },
         ["Dracthyr"] = { M1="دراكثير", M2="دراكثير" },
         ["Draenei"] = { M1="دريناي", M2="دريناي" },
         ["Dwarf"] = { M1="دوارف", M2="دوارف" },
         ["Gnome"] = { M1="قنوم", M2="قنوم" },
         ["Goblin"] = { M1="قوبلن", M2="قوبلن" },
         ["Highmountain Tauren"] = { M1="هايماونتن تورين", M2="هايماونتن تورين" },
         ["Human"] = { M1="بشري", M2="بشري" },
         ["Kul Tiran"] = { M1="كول تيران", M2="كول تيران" },
         ["Lightforged Draenei"] = { M1="لايتفورج دريناي", M2="لايتفورج دريناي" },
         ["Mag'har Orc"] = { M1="ماقهار اورك", M2="ماقهار اورك" },
         ["Mechagnome"] = { M1="ميكاقنوم", M2="ميكاقنوم" },
         ["Nightborne"] = { M1="نايتبرون", M2="نايتبرون" },
         ["Night Elf"] = { M1="قزم الليل", M2="قزم الليل" },
         ["Orc"] = { M1="اورك", M2="اورك" },
         ["Pandaren"] = { M1="باندارين", M2="باندارين" },
         ["Tauren"] = { M1="تورين", M2="تورين" },
         ["Troll"] = { M1="ترول", M2="ترول" },
         ["Undead"] = { M1="انديد", M2="انديد" },
         ["Void Elf"] = { M1="فويد إيلف", M2="فويد إيلف" },
         ["Worgen"] = { M1="وارقين", M2="وارقين" },
         ["Zandalari Troll"] = { M1="زندلاري ترول", M2="زندلاري ترول" } };
      p_class = {
         ["Death Knight"] = { M1="ديث نايت", M2="ديث نايت" },
         ["Demon Hunter"] = { M1="ديمون هنتر", M2="ديمون هنتر" },
         ["Druid"] = { M1="درود", M2="درود" },
         ["Hunter"] = { M1="هنتر", M2="هنتر" },
         ["Mage"] = { M1="ميج", M2="ميج" },
         ["Monk"] = { M1="مونك", M2="مونك" },
         ["Paladin"] = { M1="بلدين", M2="بلدين" },
         ["Priest"] = { M1="بريست", M2="بريست" },
         ["Rogue"] = { M1="روق", M2="روق" },
         ["Shaman"] = { M1="شامان", M2="شامان" },
         ["Warlock"] = { M1="ورلوك", M2="ورلوك" },
         ["Warrior"] = { M1="وارير", M2="وارير" } };
      if (p_race[BB_player_race]) then      
         player_race = { M1=p_race[BB_player_race].M1, M2=p_race[BB_player_race].M2 };
      else   
         player_race = { M1=BB_player_race, M2=BB_player_race };
         print ("|cff55ff00BBTR - new race: "..BB_player_race);
      end
      if (p_class[BB_player_class]) then
         player_class = { M1=p_class[BB_player_class].M1, M2=p_class[BB_player_class].M2 };
      else
         player_class = { M1=BB_player_class, M2=BB_player_class };
         print ("|cff55ff00BBTR - new class: "..BB_player_class);
      end
   end   
end

-------------------------------------------------------------------------------------------------------

function BB_ZmienKody(message,target)
   if (target == "") then                             -- może być zmienna $target w tłumaczeniu
      target = BB_player_name;
   end
   target = AS_UTF8reverse(target);
   message = string.gsub(message, "$n$", string.upper(target));    -- i trzeba ją zamienić na nazwę gracza
   message = string.gsub(message, "$N$", string.upper(target));    -- tu jeszcze pisane DUŻYMI LITERAMI
   message = string.gsub(message, "$n", target);
   message = string.gsub(message, "$N", target);
   message = string.gsub(message, "$target", target);
   message = string.gsub(message, "$TARGET", target);
   
   message = string.gsub(message, "$g", "$G");     -- obsługa kodu $g(m;ż)
   local BB_forma = "";
   local nr_1, nr_2, nr_3 = 0;
   local nr_poz = string.find(message, "$G");    -- gdy nie znalazł, jest: nil; liczy od 1
   while (nr_poz and nr_poz>0) do
      nr_1 = nr_poz + 1;   
      if (string.sub(msg, nr_1, nr_1) ~= "(") then    -- dopuszczam 1 spację odstępu
         nr_1 = nr_1 + 1;
      end
      if (string.sub(message, nr_1, nr_1) == "(") then
         nr_2 =  nr_1 + 1;
         while ((string.sub(msg, nr_2, nr_2) ~= ";") and (nr_1+50>nr_2)) do
            nr_2 = nr_2 + 1;
         end
         if (string.sub(message, nr_2, nr_2) == ";") then
            nr_3 = nr_2 + 1;
            while ((string.sub(msg, nr_3, nr_3) ~= ")") and (nr_2+100>nr_3)) do
               nr_3 = nr_3 + 1;
            end
            if (string.sub(message, nr_3, nr_3) == ")") then
               if (target==BB_player_name) then       -- wypowiedź kierowana do gracza
                  if (BB_PM["sex"]=="4") then         -- wypowiedzi wyświetlaj w formie zależnej od płci postaci
                     if (player_sex==3) then          -- postać płci żeńskiej
                        BB_forma = string.sub(message,nr_2+1,nr_3-1);
                     else                             -- postać płci męskiej
                        BB_forma = string.sub(message,nr_1+1,nr_2-1);
                     end
                  elseif (BB_PM["sex"]=="3") then         -- wypowiedzi wyświetlaj w formie żeńskiej
                     BB_forma = string.sub(message,nr_2+1,nr_3-1);
                  else                                -- wypowiedzi wyświetlaj w formie męskiej
                     BB_forma = string.sub(message,nr_1+1,nr_2-1);
                  end
               else
                  BB_forma = string.sub(message,nr_1+1,nr_2-1);    -- wypowiedź do kogoś innego - forma męska
               end
               message = string.sub(message,1,nr_poz-1) .. BB_forma .. string.sub(message,nr_3+1);
            else   
               msg = string.gsub(msg, "$G", "G$");
            end   
         else   
            msg = string.gsub(msg, "$G", "G$");
         end
      else   
         msg = string.gsub(msg, "$G", "G$");
      end
      nr_poz = string.find(message, "$G");
   end
   
   message = string.gsub(message, "$r", "$R");  
   message = string.gsub(message, "$c", "$C");    
   if ((BB_PM["sex"]=="3") or ((BB_PM["sex"]=="4") and (player_sex=="3"))) then       -- gracz gra kobietą lub postać jest żeńska
      message = string.gsub(message, "$R", player_race.M2);
      message = string.gsub(message, "$C", player_class.M2);
   else                          -- gracz gra facetem
      message = string.gsub(message, "$R", player_race.M1);
      message = string.gsub(message, "$C", player_class.M1);
   end

   return message;   
end

-------------------------------------------------------------------------------------------------------

-- Reverses the order of UTF-8 letters in (limit) lines: 2 or 3 
function BB_LineReverse(s, limit)
   local retstr = "";
   local BB_were_latin = false;
   if (s and limit) then                           -- check if arguments are not empty (nil)
		local bytes = strlen(s);
      local count_chars = AS_UTF8len(s);           -- number of characters in a string s
      local limit_chars = count_chars / limit;     -- limit characters on one line (+-)
		local pos = 1;
		local charbytes;
		local newstr = "";
      local counter = 0;
      local char1;
		while pos <= bytes do
			c = strbyte(s, pos);                      -- read the character (odczytaj znak)
			charbytes = AS_UTF8charbytes(s, pos);    -- count of bytes (liczba bajtów znaku)
         char1 = strsub(s, pos, pos + charbytes - 1);
			newstr = newstr .. char1;
			pos = pos + charbytes;
         
         counter = counter + 1;
         if ((char1 >= "A") and (char1 <= "z")) then
            counter = counter + 1;        -- latin letters are 2x wider, then Arabic
            BB_were_latin = true;
         end
         if ((char1 == " ") and (counter>=limit_chars-3)) then      -- break line here
            retstr = retstr .. AS_UTF8reverse(newstr) .. "\n";
            newstr = "";
            counter = 0;
         end
      end
      retstr = retstr .. AS_UTF8reverse(newstr);
      retstr = string.gsub(retstr, "\n ", "\n");        -- space after newline code is useless
   end
	return retstr, BB_were_latin;
end 

-------------------------------------------------------------------------------------------------------

-- Reverses the order of UTF-8 letters in lines of limit characters (on frame Talking Head)
function TH_LineReverse(s, limit)
   local retstr = "";
   if (s and limit) then                           -- check if arguments are not empty (nil)
		local bytes = strlen(s);
		local pos = 1;
		local charbytes;
		local newstr = "";
      local counter = 0;
      local char1;
		while pos <= bytes do
			c = strbyte(s, pos);                      -- read the character (odczytaj znak)
			charbytes = AS_UTF8charbytes(s, pos);    -- count of bytes (liczba bajtów znaku)
         char1 = strsub(s, pos, pos + charbytes - 1);
			newstr = newstr .. char1;
			pos = pos + charbytes;
         
         counter = counter + 1;
         if ((char1 >= "A") and (char1 <= "z")) then
            counter = counter + 1;        -- latin letters are 2x wider, then Arabic
         end
         if ((char1 == " ") and (counter > limit)) then
            retstr = retstr .. AS_UTF8reverse(newstr) .. "\n";
            newstr = "";
            counter = 0;
         end
      end
      retstr = retstr .. AS_UTF8reverse(newstr);
      retstr = string.gsub(retstr, "\n ", "\n");        -- space after newline code is useless
   end
	return retstr;
end 

-------------------------------------------------------------------------------------------------------

-- function formats arabic text for display in a left-justified chat line
function BB_LineChat(txt, font_size, more_chars)
   local retstr = "";
   if (txt and font_size) then
      local more_chars = more_chars or 0;
      local chat_width = DEFAULT_CHAT_FRAME:GetWidth();             -- width of 1 chat line
      local chars_limit = chat_width / (0.35*font_size+0.8)*1.1 ;   -- so much max. characters can fit on one line
		local bytes = strlen(txt);
		local pos = 1;
      local counter = 0;
      local second = 0;
		local newstr = "";
		local charbytes;
      local newstrR;
      local char1;
		while (pos <= bytes) do
			c = strbyte(txt, pos);                      -- read the character (odczytaj znak)
			charbytes = AS_UTF8charbytes(txt, pos);    -- count of bytes (liczba bajtów znaku)
         char1 = strsub(txt, pos, pos + charbytes - 1);
			newstr = newstr .. char1;
			pos = pos + charbytes;
         
         counter = counter + 1;
         if ((char1 >= "A") and (char1 <= "z")) then
            counter = counter + 1;        -- latin letters are 2x wider, then Arabic
         end
         if ((char1 == " ") and (counter-more_chars>=chars_limit-3)) then      -- break line here
            newstrR = BB_AddSpaces(AS_UTF8reverse(newstr), second);
            retstr = retstr .. newstrR .. "\n";
            newstr = "";
            counter = 0;
            more_chars = 0;
            second = 2;
         end
      end
      newstrR = BB_AddSpaces(AS_UTF8reverse(newstr), second);
      retstr = retstr .. newstrR;
      retstr = string.gsub(retstr, "\n ", "\n");        -- space after newline code is useless
   end
	return retstr;
end

-------------------------------------------------------------------------------------------------------

function BB_CreateTestLine()
   BB_TestLine = CreateFrame("Frame", "BB_TestLine", UIParent, "BasicFrameTemplateWithInset");
   BB_TestLine:SetHeight(150);
   BB_TestLine:SetWidth(DEFAULT_CHAT_FRAME:GetWidth()+50);
   BB_TestLine:ClearAllPoints();
   BB_TestLine:SetPoint("TOPLEFT", 20, -300);
   BB_TestLine.title = BB_TestLine:CreateFontString(nil, "OVERLAY", "GameFontHighlight");
   BB_TestLine.title:SetPoint("CENTER", BB_TestLine.TitleBg);
   BB_TestLine.title:SetText("Frame for testing width of text");
   BB_TestLine.ScrollFrame = CreateFrame("ScrollFrame", nil, BB_TestLine, "UIPanelScrollFrameTemplate");
   BB_TestLine.ScrollFrame:SetPoint("TOPLEFT", BB_TestLine.InsetBg, "TOPLEFT", 10, -40);
   BB_TestLine.ScrollFrame:SetPoint("BOTTOMRIGHT", BB_TestLine.InsetBg, "BOTTOMRIGHT", -5, 10);
  
   BB_TestLine.ScrollFrame.ScrollBar:ClearAllPoints();
   BB_TestLine.ScrollFrame.ScrollBar:SetPoint("TOPLEFT", BB_TestLine.ScrollFrame, "TOPRIGHT", -12, -18);
   BB_TestLine.ScrollFrame.ScrollBar:SetPoint("BOTTOMRIGHT", BB_TestLine.ScrollFrame, "BOTTOMRIGHT", -7, 15);
   BBchild = CreateFrame("Frame", nil, BB_TestLine.ScrollFrame);
   BBchild:SetSize(552,100);
   BBchild.bg = BBchild:CreateTexture(nil, "BACKGROUND");
   BBchild.bg:SetAllPoints(true);
   BBchild.bg:SetColorTexture(0, 0.05, 0.1, 0.8);
   BB_TestLine.ScrollFrame:SetScrollChild(BBchild);
   BB_TestLine.text = BBchild:CreateFontString(nil, "OVERLAY", "GameFontHighlight");
   BB_TestLine.text:SetPoint("TOPLEFT", BBchild, "TOPLEFT", 2, 0);
   BB_TestLine.text:SetText("");
   BB_TestLine.text:SetSize(DEFAULT_CHAT_FRAME:GetWidth(),0);
   BB_TestLine.text:SetJustifyH("LEFT");
   BB_TestLine.CloseButton:SetPoint("TOPRIGHT", BB_TestLine, "TOPRIGHT", 0, 0);
   BB_TestLine:Hide();     -- the frame is invisible in the game
end

-------------------------------------------------------------------------------------------------------

-- the function appends spaces to the left of the given text so that the text is aligned to the right
function BB_AddSpaces(txt, snd)                                 -- snd = second or next line (interspace 2 on right)
   local _fontC, _sizeC, _C = DEFAULT_CHAT_FRAME:GetFont();     -- read current font, size and flag of the chat object
   local chat_widthC = DEFAULT_CHAT_FRAME:GetWidth();           -- width of 1 chat line
   local chars_limitC = chat_widthC / (0.35*_sizeC+0.8);        -- so much max. characters can fit on one line
   
   if (BB_TestLine == nil) then     -- a own frame for displaying the translation of texts and determining the length
      BB_CreateTestLine();
   end   
   BB_TestLine:SetWidth(DEFAULT_CHAT_FRAME:GetWidth()+50);
   BB_TestLine:Hide();     -- the frame is invisible in the game
   BB_TestLine.text:SetFont(_fontC, _sizeC, _C);
   local count = 0;
   local text = txt;
   BB_TestLine.text:SetText(text);
   while ((BB_TestLine.text:GetHeight() < _sizeC*1.5) and (count < chars_limitC)) do
      count = count + 1;
      text = " "..text;
      BB_TestLine.text:SetText(text);
   end

   if (count < chars_limitC) then    -- failed to properly add leading spaces
      for i=4,count-snd,1 do         -- spaces are added to the left of the text
         txt = " "..txt;
      end
   end
   BB_TestLine.text:SetText(txt);
   
   return(txt);
end

-------------------------------------------------------------------------------------------------------

function BB_mysplit (inputstr, sep)
   if (sep == nil) then
      sep = "%s";
   end
   local t={};
   for str in string.gmatch(inputstr, "([^"..sep.."]+)") do
      table.insert(t, str);
   end
   return t;
end

-------------------------------------------------------------------------------------------------------

function BB_SpecifyBubbleWidth(str_txt, reg)
   local vlines = BB_mysplit(str_txt,"\n");
   local _fontR, _sizeR, _R = reg:GetFont();   -- odczytaj aktualną czcionkę i rozmiar
   local max_width = 20;
   for _, v in ipairs(vlines) do 
      if (BB_TestLine == nil) then     -- a own frame for displaying the translation of texts and determining the length
         BB_CreateTestLine();
      end   
      BB_TestLine:Hide();     -- the frame is invisible in the game
      BB_TestLine.text:SetFont(_fontR, _sizeR, _R);
      local newTextWidth = (0.35*act_font+0.8)*AS_UTF8len(v)*1.5;  -- maksymalna szerokość okna dymku
      BB_TestLine.text:SetWidth(newTextWidth);
      BB_TestLine.text:SetText(v);
      local minTextWidth = (0.35*act_font+0.8)*AS_UTF8len(v)*0.8;  -- minimalna szerokość ograniczająca pętlę
      
      while ((BB_TestLine.text:GetHeight() < _sizeR*1.5) and (minTextWidth < newTextWidth)) do
         newTextWidth = newTextWidth - 5;
         BB_TestLine.text:SetWidth(newTextWidth);
      end
      if (newTextWidth > max_width) then
         max_width = newTextWidth;
      end
   end
--print(max_width);   
   return max_width + 5;
end

-------------------------------------------------------------------------------------------------------

BBTR_f = CreateFrame("Frame");
BBTR_f:RegisterEvent("ADDON_LOADED");
BBTR_f:SetScript("OnEvent", BBTR_onEvent);
