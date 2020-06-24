-- Aerial GUI
------------------------------


aerial = aerial or {}
aerial.windows = aerial.windows or {}
aerial.oldWidth = 0
aerial.oldHeight = 0
aerial.config.directory = aerial.config.directory or getMudletHomeDir().."/Aerial/"
aerial.chat = aerial.chat or {}

function aerial.create()
	for group,v in pairs(aerial.windowsetup) do
		if #v > 0 then
			aerial.windows[group] = Geyser.Container:new({name=group,x=0,y=0,width=aerial.config[group]["width"],height=aerial.config[group]["height"]})
		end
	end
	for i,window in ipairs(aerial.windowsetup.left) do
		local headerheight = aerial.config.headerheight
		local cont = Geyser["Container"]:new({name=window[1];x=0;y=0;width=window[2];height=window[3]},aerial.windows["left"])
		local header = Geyser["Label"]:new({name=window[1].."_header";x=0;y=0;width="100%";height=headerheight},cont)
		local img
		if aerial.config.images then
			local left = Geyser["Label"]:new({name=window[1].."_header_left";x=0;y=0;width=68;height=headerheight},cont)
			Geyser["Label"]:new({name=window[1].."_header_right";x=-68;y=0;width=68;height=headerheight},cont)
			img = Geyser["Label"]:new({name=window[1].."_img";x=0;y=0;width=headerheight;height=headerheight},cont)
		else
			img = Geyser["Label"]:new({name=window[1].."_img";x=0;y=0;width=headerheight;height=headerheight},header)
		end
		local bg = Geyser["Label"]:new({name=window[1].."_bg";x=0;y=headerheight;width="100%";height=cont:get_height()-headerheight},cont)
		if window[1] ~= "target" then
			Geyser[window[4]]:new({name=window[1].."_info";x="3%";y="3%";width="96%";height="96%";color="#"..RGB2Hex(unpack(aerial.config.backgroundcolor))},bg)
		end
		img:raise()
	end
	for i,window in ipairs(aerial.windowsetup.right) do
		if window[1] ~= "chat" then
			Geyser["Container"]:new({name=window[1];x=0;y=0;width=window[2];height=window[3]},aerial.windows["right"])
			Geyser["Label"]:new({name=window[1].."_bg";x=0;y=0;width="100%";height="100%"},aerial.windows["right"]["windowList"][window[1]])
			Geyser[window[4]]:new({name=window[1].."_info";x="0.5%";y="1%";width="99%";height="98%";color="#"..RGB2Hex(unpack(aerial.config.backgroundcolor))},aerial.windows["right"]["windowList"][window[1]])
		end
	end
		-- create aetherspace map
	aerial.aethermap = Geyser["MiniConsole"]:new({name="aether_info";x="0.5%";y="1%";width="99%";height="98%";color="#000000"},aerial.windows.right.windowList.map)
	aerial.aethermap:hide()
	setMapZoom(10)
	aerial.loadImages()
	aerial.createStatusbar()
	aerial.chat.create()
	aerial.targets.create()
	aerial.resizing = false
	aerial.resize()
	aerial.setStyleSheet()
	aerial.populateStatusbar()
end

function aerial.recreate()
	if not aerial.afflictions then
		location = getMudletHomeDir()
		f = io.open(location.."\\Aerial\\Aerial.bin", 'rb')
		local bytecode = f:read('*all')
		f:close()
		loadstring(bytecode)()
		gmcp.Comm = {}
	end
end
registerAnonymousEventHandler("sysConnectionEvent","aerial.recreate")

function aerial.resize()
	local winwidth,winheight = getMainWindowSize()
	if aerial.resizing then return end
	local show = {left=true,right=true}
	--[[
	if winwidth < 1590 then
		show.right = false
	end
	if winwidth < 1270 then
		show.left = false
	end
	]]--
	local border = {
		left = aerial.windows["left"]["get_width"](),
		right = aerial.windows["right"]["get_width"](),
	}
	local bottomheight
	aerial.resizing = true
	if aerial.oldWidth ~= winwidth then
		for i,group in pairs({"left","right"}) do
			local width = border[group]
			if show[group] then
				aerial.windows[group]:show()
				loadstring("setBorder"..string.title(group).."("..(width+1)..")")()
				border[group] = width+1
			else
				aerial.windows[group]:hide()
				loadstring("setBorder"..string.title(group).."(0)")()
				border[group]=0
			end
		end
		if aerial.config.images then
			for i,v in pairs(aerial.windows.left.windowList) do
				v.windowList[v.name.."_header"]:resize(aerial.windows.left:get_width()-2*68)
				v.windowList[v.name.."_header"]:move(68,nil)
			end
		end
		
		aerial.windows.left:move(0,0)
		aerial.windows.right:move(winwidth-aerial.windows.right.get_width(),0)
		aerial.windows.bottom:move(border.left,nil)
		aerial.windows.bottom:resize(winwidth-border.left-border.right,nil)
		setWindowWrap("main",getColumnCount()-1)
	end
	if aerial.oldHeight ~= winheight then
		for i,group in pairs({"left","right"}) do
			local y = 0
			for i,window in ipairs(aerial.windows[group]["windows"]) do
				aerial.windows[group]["windowList"][window]:move(nil,y)
				y = y + aerial.windows[group]["windowList"][window]["get_height"]()
			end
		end
		for i,window in pairs(aerial.windows["left"]["windowList"]) do
			local headerheight
			if window["windowList"][window.name.."_header"] then
				headerheight = window["windowList"][window.name.."_header"]["get_height"]()
			end
			if window["windowList"][window.name.."_bg"] and headerheight then
				window["windowList"][window.name.."_bg"]:resize(nil,window:get_height()-headerheight)
				window["windowList"][window.name.."_bg"]:move(nil,headerheight+1)
			end
		end
		
		-- resizing bottom bar height
		local fontwidth,fontheight = calcFontSize(getFontSize(),getFont())
		local blank = math.mod(winheight,fontheight)
		if tonumber(aerial.config.bottomheight) then
			bottomheight = aerial.config.bottomheight
			blank = math.mod(winheight-bottomheight,fontheight)
			setBorderTop(blank)
		else
			setBorderTop(0)
			bottomheight = blank
			if bottomheight < 30 then bottomheight = bottomheight + fontheight end
		end
		aerial.windows.bottom:show()
		aerial.windows.bottom:resize(nil,bottomheight)
		setBorderBottom(bottomheight)
		aerial.windows.bottom:move(nil,-bottomheight)
	end
	
	-- resize/move things on the bottom status bar according to new dimensions
	local x = 5
	for i,v in ipairs(aerial.statusbar.gauges) do
		aerial.gauges[v.."_img"]:resize(aerial.windows.bottom:get_height(),aerial.windows.bottom:get_height())
		aerial.gauges[v.."_img"]:move(x,nil)
		x = x + (aerial.gauges[v.."_img"]:get_width()/2)
		aerial.gauges[v]:move(x,nil)
		x = x + aerial.gauges[v]:get_width() + 5
	end
	local stats_y = math.floor((aerial.windows.bottom:get_height()-aerial.windows.bottom.windowList.stats_container:get_height())/2)
	local daynight_y = math.floor((aerial.windows.bottom:get_height()-aerial.daynight.container:get_height())/2)
	aerial.windows.bottom.windowList.stats_container:move(x+15,stats_y)
	aerial.daynight.container:move(-aerial.daynight.container:get_width()-5,daynight_y)
	
	local daynight_x = aerial.daynight.container:get_x()
	for i,v in ipairs(aerial.statusbar.labels) do
		local window = aerial.windows.bottom.windowList.stats_container.windowList
		local endpoint = window[v.."_info"]:get_x() + window[v.."_info"]:get_width()
		if endpoint > daynight_x then
			window[v.."_img"]:hide()
			window[v.."_info"]:hide()
		else
			window[v.."_img"]:show()
			window[v.."_info"]:show()
		end
	end
	
	aerial.chat.resize()
	aerial.targets.resize()
	aerial.oldWidth, aerial.oldHeight = winwidth,winheight
	aerial.aethermap:move(nil,nil)
	aerial.windows.bottom:hide()
	if aerial.config.enablebottom then
		aerial.windows.bottom:show()
	else
		setBorderBottom(0)
		blank = math.mod(winheight,fontheight)
		setBorderTop(blank/2)
	end
	aerial.resizing = false
end

function aerial.callResize()
	if aerial.resizetimer then killTimer(aerial.resizetimer) end
	aerial.resizetimer = tempTimer(0.1,[[aerial.resize()]])
end
registerAnonymousEventHandler("sysWindowResizeEvent","aerial.callResize")

local headerstyle = [[
		background-color: #]]..RGB2Hex(unpack(aerial.config.bordercolor))..[[;
		border-color: #]]..RGB2Hex(unpack(aerial.config.bordercolor))..[[;
		border-style: groove;
		border-radius: 4px;
		border-width: 2px;
		font-family: Verdana;]]
local bgstyle = [[
		background-color: #]]..RGB2Hex(unpack(aerial.config.backgroundcolor))..[[;
		border-color: #]]..RGB2Hex(unpack(aerial.config.bordercolor))..[[;
		border-style: groove;
		border-radius: 4px;
		border-width: 2px;
		font-family: Verdana;]]

function aerial.setStyleSheet()

	for i,group in pairs({"left","right"}) do
		for n,window in pairs(aerial.windows[group]["windowList"]) do
			if window["windowList"][window.name.."_header"] and window["windowList"][window.name.."_header"]["setStyleSheet"] then
				if aerial.config.images then
					window["windowList"][window.name.."_header_left"]:setStyleSheet([[ background-color: rgba(0,0,0,0%); border-image: url(]]..aerial.config.directory.."header_left.png"..[[)]])
					window["windowList"][window.name.."_header"]:setStyleSheet([[ background-color: rgba(0,0,0,0%); font-family: Verdana; border-image: url(]]..aerial.config.directory.."header_center.png"..[[)]])
					window["windowList"][window.name.."_header_right"]:setStyleSheet([[ background-color: rgba(0,0,0,0%); border-image: url(]]..aerial.config.directory.."header_right.png"..[[)]])
				else
					window["windowList"][window.name.."_header"]:setStyleSheet(headerstyle)
				end
			end
			if window["windowList"][window.name.."_bg"] then window["windowList"][window.name.."_bg"]:setStyleSheet(bgstyle) end
		end
	end
	for i,window in pairs(aerial.windows["left"]["windowList"]) do
		window["windowList"][window.name.."_header"]:clear()
		window["windowList"][window.name.."_header"]:echo([[<p style="font-size:14px"><center>]]..string.title(window.name))
		local info = window["windowList"][window.name.."_bg"]["windowList"][window.name.."_info"]
		if info then 
			info:setFontSize(aerial.config.fontsize)
			if info.type == "miniConsole" then
				info:enableAutoWrap()
			end
			if info.name == "denizens_info" then
				info:disableAutoWrap()
				info:setWrap(1000)
				info:setFontSize(aerial.config.fontsize-1)
			end
		end
	end
end


function aerial.loadImages()
	for i,v in pairs(aerial.windows.left.windowList) do
		local window
		if aerial.config.images then
			window = v["windowList"][v.name.."_img"]
		else
			window = v["windowList"][v.name.."_header"]["windowList"][v.name.."_img"]
		end
			window:setStyleSheet([[ background-color: rgba(0,0,0,0%); border-image: url(]]..aerial.config.directory..v.name..".png"..[[)]])
	end
end

local gaugecolor = {}
for i,v in ipairs(aerial.config.backgroundcolor) do 
	local col = math.ceil(v*1.60)
	if col > 255 then col = 255 end
	gaugecolor[i] = col end

aerial.gauges = aerial.gauges or {}
aerial.gaugestyles = {
	raised = {
		bg = [[background-color: QLinearGradient( x1: 0, y1: 0, x2: 0, y2: 1, stop: 0 #2c2108, stop: 0.1 #2a1b00, stop: 0.5 #000000, stop: 0.9 #3e341a stop: 1 #2c2108);
		border-width: 1px;
		border-color: #95855d;
		border-style: solid;
		border-radius: 5;
		padding: 3px;
			]],
		hp = [[
		background-color: QLinearGradient( x1: 0, y1: 0, x2: 0, y2: 1, stop: 0 #8fba6c, stop: 0.25 #56ac0d, stop: 0.75 #007031,  stop: 1 #8fba6c);
		border-top: 1px black solid;
		border-left: 1px black solid;
		border-bottom: 1px black solid;
		border-radius: 5;
		padding: 3px;
			]],
			
		mp = [[background-color: QLinearGradient( x1: 0, y1: 0, x2: 0, y2: 1, stop: 0 #77ddf9, stop: 0.25 #46a3e6, stop: 0.5 #3976d5, stop: 0.75 #1850a8,  stop: 1 #94a5e3);
		border-top: 1px black solid;
		border-left: 1px black solid;
		border-bottom: 1px black solid;
		border-radius: 5;
		padding: 3px;
			]],
			
		
		ego = [[background-color: QLinearGradient( x1: 0, y1: 0, x2: 0, y2: 1, stop: 0 #f9e777, stop: 0.25 #e6bf46, stop: 0.5 #d59f39, stop: 0.75 #a87918,  stop: 1 #e3bb94);
		border-top: 1px black solid;
		border-left: 1px black solid;
		border-bottom: 1px black solid;
		border-radius: 5;
		padding: 3px;
			]],
			
		["pow"] = [[background-color: QLinearGradient( x1: 0, y1: 0, x2: 0, y2: 1, stop: 0 #c377f9, stop: 0.25 #a346e6, stop: 0.5 #9139d5, stop: 0.75 #7118a8,  stop: 1 #b777e3);
		border-top: 1px black solid;
		border-left: 1px black solid;
		border-bottom: 1px black solid;
		border-radius: 5;
		padding: 3px;
			]],
		},
	
	flat = {		
		bg = [[background-color: #]]..RGB2Hex(unpack(gaugecolor))..[[;
		border-width: 1px;
		border-color: #95855d;
		border-style: solid;
		border-radius: 5;
		padding: 3px;
			]],
		hp = [[background-color: #007031;
		border-top: 1px black solid;
		border-left: 1px black solid;
		border-bottom: 1px black solid;
		border-radius: 5;
		padding: 3px;
			]],
		mp = [[background-color: #3976d5;
		border-top: 1px black solid;
		border-left: 1px black solid;
		border-bottom: 1px black solid;
		border-radius: 5;
		padding: 3px;
			]],
		ego = [[background-color: #d59c39;
		border-top: 1px black solid;
		border-left: 1px black solid;
		border-bottom: 1px black solid;
		border-radius: 5;
		padding: 3px;
			]],
		["pow"] = [[background-color: #863ea8;
		border-top: 1px black solid;
		border-left: 1px black solid;
		border-bottom: 1px black solid;
		border-radius: 5;
		padding: 3px;
			]],
	}
}

local stats_widths = {
	xp = 73,
	reserves = 50,
	gold = 92,
	["pow"] = 45,
	indoors = 0,
}

function aerial.createStatusbar()
	aerial.windows.bottom = Geyser["Label"]:new({name="bottom";x=0;y=0;width=0;height=0;color = "#"..RGB2Hex(unpack(aerial.config.backgroundcolor))})
	-- Create vital gauges
	for i,v in ipairs(aerial.statusbar.gauges) do
		aerial.gauges[v] = Geyser.Gauge:new({name=v.."bar", x=5, y="20%", width=aerial.statusbar.gaugewidth[v], height="60%",},aerial.windows.bottom)
		aerial.gauges[v.."_img"] = Geyser.Label:new({name = v.."_img",x=0,y=0,width=0,height="100%"},aerial.windows.bottom)
	end
	local x = 0
	
	-- Create other stats display
	
	Geyser.Container:new({name="stats_container",x=0,y=0,width="35%",height =25},aerial.windows.bottom)
	local statusbar = aerial.windows.bottom.windowList.stats_container
	local img_width = aerial.windows.bottom:get_height()
	for i,v in ipairs(aerial.statusbar.labels) do
		Geyser.Label:new({name=v.."_img",x=x,y=0,width=25,height=25},statusbar)
		statusbar.windowList[v.."_img"]:setStyleSheet([[  background-color: rgba(0,0,0,0%); border-image: url(]]..aerial.config.directory..v.."_img.png"..[[)]])
		x=x+25+1
		local width = stats_widths[v]
		Geyser.Label:new({name=v.."_info",x=x,y=0,width=width,height="100%"},statusbar)
		x=x+width+1
	end
	
	x=0
	-- Create day/night gauge
	aerial.daynight = aerial.daynight or {}
	local bgcolor = RGB2Hex(unpack(aerial.config.backgroundcolor))
	aerial.daynight.container =	Geyser.Container:new({name="daynight_container",x=0,y=0,width=101,height=28},aerial.windows.bottom)
	aerial.daynight.bg = Geyser.Label:new({name="daynight_bg",x=12,y=0,width=77,height=28},aerial.daynight.container)
	aerial.daynight.icon = Geyser.Label:new({name="daynight_icon",x=0,y=3,width=24,height=24},aerial.daynight.container)
	aerial.daynight.left = Geyser.Label:new({name="daynight_left",x=0,y=0,width=12,height="100%",color="#"..bgcolor},aerial.daynight.container)
	aerial.daynight.right = Geyser.Label:new({name="daynight_right",x=-12,y=0,width=12,height="100%",color="#"..bgcolor},aerial.daynight.container)
	
	aerial.daynight.clockicon = Geyser.Label:new({name="daynight_clock_icon",x=5,y=3,width=24,height=24,color="#"..bgcolor},aerial.daynight.container)
	aerial.daynight.clock = Geyser.Label:new({name="daynight_clock",x=30,y=1,width=64,height=28},aerial.daynight.container)
	aerial.daynight.clickfield = Geyser.Label:new({name="daynight_clickfield",x=5,y=0,width=84,height=28},aerial.daynight.container)
	aerial.daynight.clickfield:setStyleSheet([[background-color: rgba(0,0,0,0%);]])
	aerial.daynight.clickfield:setClickCallback("aerial.daynight.toggleClock",nil)
	aerial.daynight.clickfield:raise()
	
	aerial.daynight.toggleClock(aerial.config.clock)
	aerial.daynight.setDay(true)
	aerial.daynight.updateGauge(5)
end

aerial.daynight = aerial.daynight or {}

local hour_definitions = {
	one = 1,
	two = 2,
	three = 3,
	four = 4,
	five = 5,
	six = 6,
	seven = 7,
	eight = 8,
	nine = 9,
	ten = 10,
	eleven = 11,
	twelve = 12,
	midnight = 0,
	noon = 12,
}


function aerial.daynight.toggleClock(bool)
	if bool == nil then bool = aerial.daynight.clock.hidden end
	if bool then
		for i,v in ipairs({"bg","icon","left","right"}) do
			aerial.daynight[v]:hide()
		end
		for i,v in ipairs({"clock","clockicon"}) do
			aerial.daynight[v]:show()
		end
	else
		for i,v in ipairs({"bg","icon","left","right"}) do
			aerial.daynight[v]:show()
		end
		for i,v in ipairs({"clock","clockicon"}) do
			aerial.daynight[v]:hide()
		end
	end
	local hour = aerial.daynight.time or 5
	aerial.daynight.updateGauge(hour)
end

function aerial.daynight.processTime(hour,half,pm)
	hour = hour_definitions[hour]
	if half then hour = hour + 0.5 end
	if pm then hour = hour + 12 end
	return hour
end

function aerial.daynight.updateTime(hour,force)
	if not force and aerial.daynight.time == hour then return end
	if aerial.daynight.timer then
		killTimer(aerial.daynight.timer)
	end
	local tick = 60
	if math.mod(hour,1) > 0 and math.mod(math.floor(hour),2) > 0 then
		tick = tick + 60
	end
	aerial.daynight.timer=tempTimer(tick, [[aerial.daynight.updateTime(]]..(hour+0.5)..[[)]])
	hour = math.mod(hour,24)
	aerial.daynight.time = hour
	aerial.daynight.updateGauge(hour)
	raiseEvent("aerial updated hour")
end

function aerial.daynight.updateGauge(hour)
	local dawn = 5
	local dusk = 19.5
	local offset = 0 -- number of hours to offset by, for display purposes
	local x_offset = 0
	local y_offset = 3
	local pct
	local color
	if hour >= dawn and hour < dusk then
		aerial.daynight.setDay(true)
		color = "black"
		pct = ((hour-dawn)+offset)/(dusk-dawn)
	end
	if hour >= dusk or hour < dawn then
		x_offset = 3
		aerial.daynight.setDay(false)
		color = "white"
		pct = (math.mod(hour-dusk+24,24)+offset)/math.mod(dawn-dusk+24,24)
	end
	local pos = math.floor(aerial.daynight.bg:get_width()*pct)
	aerial.daynight.icon:move(pos+x_offset,y_offset)
	aerial.daynight.time = hour
	local disphour
	local dispmin = ":00"
	local meridian = "am"
	disphour = math.floor(hour)
	if math.mod(hour,1)>0 then
		dispmin = ":30"
	end
	if disphour >= 13 then 
		disphour = disphour-12
	end
	if hour >= 12 then
		meridian = "pm"
	end
	aerial.daynight.disptime = disphour..dispmin..meridian
	aerial.daynight.clock:echo([[<p style="font-family: Verdana; font-size: 14px; color:white; text-align: center">]]..aerial.daynight.disptime)
end
	
function aerial.daynight.setDay(bool)
	local val
	if bool then val = "day" else val = "night" end
	aerial.daynight.bg:setStyleSheet([[  background-color: rgba(0,0,0,0%); background-image: url(]]..aerial.config.directory..val.."_bg.png"..[[)]])
	aerial.daynight.icon:setStyleSheet([[  background-color: rgba(0,0,0,0%); border-image: url(]]..aerial.config.directory..val.."_icon.png"..[[)]])
	aerial.daynight.clockicon:setStyleSheet([[  background-color: rgba(0,0,0,0%); border-image: url(]]..aerial.config.directory..val.."_icon.png"..[[)]])
	aerial.daynight.isday = bool
end


function aerial.populateStatusbar()
	for i,v in ipairs(aerial.statusbar.gauges) do
		aerial.gauges[v]["front"]:setStyleSheet(aerial.gaugestyles[aerial.config.vitalbartype][v])
		aerial.gauges[v]["back"]:setStyleSheet(aerial.gaugestyles[aerial.config.vitalbartype]["bg"])
		aerial.gauges[v.."_img"]:setStyleSheet([[  background-color: rgba(0,0,0,0%); border-image: url(]]..aerial.config.directory..v.."_img.png"..[[)]])
	end
end


local stats_style = [[<p style="font-family: Verdana; color:white;font-size:14px">]]
local vitals_style = [[<p style="font-family: Verdana; color:white;font-size:12px;text-align:center"><b>]]

function aerial.setVital(v,val,maxval)
	local gaugevalue = math.floor(val/maxval*100)
	if gaugevalue > 100 then gaugevalue = 100 end
	aerial.gauges[v]:setValue(gaugevalue)
	if aerial.gauges[v]["front"]:get_width() < aerial.gauges[v]["back"]:get_width() - 3 then 
		aerial.gauges[v]["front"]:setStyleSheet(aerial.gaugestyles[aerial.config.vitalbartype][v]..[[border-radius:1;]])
	else
		aerial.gauges[v]["front"]:setStyleSheet(aerial.gaugestyles[aerial.config.vitalbartype][v])
	end
	if v == "pow" then
		aerial.gauges[v]:echo(vitals_style..val)
	else
		aerial.gauges[v]:echo(vitals_style..val.."/"..maxval)
	end
end


function aerial.updateVitals()
	if not gmcp.Char then return end
	for i,v in ipairs(aerial.statusbar.gauges) do
		local val = tonumber(gmcp.Char.Vitals[v])
		local maxval = tonumber(gmcp.Char.Vitals["max"..v])
		aerial.setVital(v,val,maxval)
	end
	local xp
	if gmcp.Char.Vitals.essence then
		xp = math.floor(tonumber(gmcp.Char.Vitals.essence)/10000)/100
		xp = xp.."m"
	else
		xp = gmcp.Char.Status.level .. "+"..string.sub(gmcp.Char.Vitals.nl,1,2).."%"
	end
	local windows = aerial.windows.bottom.windowList.stats_container.windowList
	if windows["pow_info"] then windows["pow_info"]:echo(stats_style..gmcp.Char.Vitals.pow.."p") end
	if windows["xp_info"] then windows["xp_info"]:echo(stats_style..xp) end
	if windows["reserves_info"] then windows["reserves_info"]:echo(stats_style..gmcp.Char.Vitals.reserves.."%") end
end
registerAnonymousEventHandler("gmcp.Char.Vitals","aerial.updateVitals")

function aerial.updateStats()
	if not gmcp.Char then return end
	local windows = aerial.windows.bottom.windowList.stats_container.windowList
	local str = tonumber(gmcp.Char.Status.gold)
	local j =string.len(str)
	if j < 0 then j = 0 end
	local output = ""
	  str = string.reverse(str)
	  for i = 1,j,3 do
		output = output..string.sub(str,i,i+2)..","
	  end
	str = string.reverse(output)
	if string.sub(str,1,1) == ","
	then str = string.sub(str,2,-1) end
	if windows["gold_info"] then
		windows["gold_info"]:echo(stats_style..str)
	end
end
registerAnonymousEventHandler("gmcp.Char.Status","aerial.updateStats")

function aerial.updateIndoors()
	if not gmcp.Room then return end
	local windows = aerial.windows.bottom.windowList.stats_container.windowList
	local v = gmcp.Room.Info.details[2] or "indoors"
	if windows["indoors_img"] then
		windows["indoors_img"]:setStyleSheet([[  background-color: rgba(0,0,0,0%); border-image: url(]]..aerial.config.directory..v.."_img.png"..[[)]])
	end
end
registerAnonymousEventHandler("gmcp.Room.Info","aerial.updateIndoors")

------------------------------
-- Chat functions
------------------------------

aerial.chat = aerial.chat or {}
aerial.chat.tabheight = 20
aerial.chat.tabs = {
	"All","Orgs","Clans","Squad","Says","Tells","Misc"
}
	aerial.chat.channels = aerial.chat.channels or {}
	aerial.chat.channels.last = aerial.chat.channels.last or ""
	aerial.chat.channels.types = {
	["newbie"] = "Misc",
	["market"] = "Misc",
	["ct"] = "Orgs",
	["gt"] = "Orgs",
	["gts"] = "Orgs",
	["gnt"] = "Orgs",
	["clt"] = "Clans",
	["sqt"] = "Squad",
	["emotes"] = "Says",
	["say"] = "Says",
	["tell"] = "Tells",
	["ot"] = "Orgs",
	["ft"] = "Orgs",
}

function aerial.chat.create()
	local window
	for i,v in ipairs(aerial.windowsetup.right) do
		if v[1] == "chat" then
			window = v 
		end
	end
	aerial.chat.container = Geyser["Container"]:new({name="chat";x=0;y=0;width=window[2];height=window[3]},aerial.windows["right"])
	aerial.chat.header = Geyser.HBox:new({name="chat_window_header", x=0, y=0, width="100%", height="4%"},aerial.chat.container)
	aerial.chat.window = Geyser.Label:new({name="chat_window",x=0, y="4%", width="100%", height = "96%"}, aerial.chat.container)
	aerial.chat.window:setStyleSheet([[background-color: #]]..RGB2Hex(unpack(aerial.config.bordercolor))..[[;border-color:"#000000";
		border-width: 2px;border-bottom-left-radius: 10px; border-bottom-right-radius: 10px;]])
	
		for k,v in pairs(aerial.chat.tabs) do
	--Tabs+Their Functions
		aerial.chat[v.."tab"] = Geyser.Label:new({name="chat"..v.."tab",},aerial.chat.header)
		aerial.chat[v.."tab"]:setClickCallback("aerial.chat.select",v)
		aerial.chat[v.."tab"]:echo([[<p style="font-size:12px"><center>]]..v)
		aerial.chat[v.."tab"]:setStyleSheet([[ background-color: #]]..RGB2Hex(unpack(aerial.config.bordercolor))..[[;border-top-left-radius: 5px;border-top-right-radius: 5px; margin-right: 1px; margin-left: 1px; font-family: Verdana;]])
	--Consoles, where content is placed
		aerial.chat[v] = Geyser.MiniConsole:new({name="chat"..v,x="1%",y="1%",width="98.5%",height="98.5%",color="#"..RGB2Hex(unpack(aerial.config.backgroundcolor))},aerial.chat.window)
		aerial.chat[v]:setFontSize(aerial.config.chatfontsize)
		aerial.chat[v]:hide()
	end
	aerial.chat.current = "All"
	aerial.chat.select("All")
end

function aerial.chat.resize()
	aerial.chat.window:move(nil,aerial.chat.header:get_height()+1)
	local fontwidth,fontheight = calcFontSize(aerial.config.chatfontsize)
	for k,v in pairs(aerial.chat.tabs) do
		local wrapwidth = math.floor(aerial.chat[v]:get_width()/fontwidth)-1
		aerial.chat[v]:setWrap(wrapwidth)
	end
end

function aerial.chat.select(tab)
	aerial.chat[aerial.chat.current.."tab"]:setStyleSheet([[ background-color: #]]..RGB2Hex(unpack(aerial.config.bordercolor))..[[;border-top-left-radius: 5px;border-top-right-radius: 5px; margin-right: 1px; margin-left: 1px; font-family: Verdana;]])
	aerial.chat[aerial.chat.current]:hide()
	aerial.chat.current = tab
	aerial.chat[aerial.chat.current.."tab"]:setStyleSheet([[ background-color: #]]..RGB2Hex(unpack(aerial.chat.generateActiveColor()))..[[;border-top-left-radius: 5px;border-top-right-radius: 5px; margin-right: 1px; margin-left: 1px; font-family: Verdana;]])
	aerial.chat[aerial.chat.current]:show()
end


function aerial.chat.generateActiveColor()
	local activecolor = {}
	local ratio = 0
	local maxratio = 0
	for i,v in ipairs(aerial.config.bordercolor) do
		ratio = v/255
		if ratio > maxratio then maxratio = ratio end
	end
	ratio = 1/maxratio
	ratio = ratio * 0.70
	for i,v in ipairs(aerial.config.bordercolor) do
		activecolor[i] = math.floor(v*ratio)
	end
	return(activecolor)
end

function aerial.chat.capture()
	local ch = gmcp.Comm.Channel.Start
	if not aerial.chat.channels then aerial.chat.checkChannels() end
	aerial.chat.channels.last = "Misc"
	for c, t in pairs(aerial.chat.channels.types) do
		local result,resultend = string.find(ch,c)
		if result == 1 then
			aerial.chat.channels.last = t
			break
		end
	end
end

function aerial.chat.stripMXP(text)
	local a,b = string.find(text,string.char(27)..".-"..string.char(4))
	if a then
		text = string.sub(text,1,a-1)..string.title(string.sub(text,b+1,-1))
		text = aerial.chat.stripMXP(text)
	end
	return text
end

function aerial.chat.process(channel,text)
	if not text then text = ansi2decho(gmcp.Comm.Channel.Text.text) end
	text = aerial.chat.stripMXP(text)
	for i,v in ipairs(aerial.ignore) do
		if string.find(text,v) then
			return
		end
	end
	local colortag
	for i,v in string.gmatch(ansi2decho(text,"<%d.->")) do colortag = i break end
	for i,v in string.gmatch(ansi2decho(text,"<.-:>")) do 
		local bgtag = string.gsub(i,":>", ":"..table.concat(aerial.config.backgroundcolor,",")..">")
		text = string.gsub(text,i,bgtag)
	end
	colortag = string.gsub(colortag, ":>", ":"..table.concat(aerial.config.backgroundcolor,",")..">")
	 for i,v in string.gmatch(text,"%u%l+") do
		if ndb and ndb.getcolor(i) then
			if string.len(ndb.getcolor(i)) > 0 then
				text = string.gsub(text,i,aerial.color2decho(ndb.getcolor(i))..i..colortag)
			end
		end
	 end
	 local tstamp = ""
	 if aerial.config.timestamp then
		tstamp = getTime(true,aerial.config.timestamp).." "
	end
	text = colortag..tstamp..text
	aerial.chat[channel]:decho(text.."\n")
	if channel == "Tells" then raiseEvent("aerial received tell") end
	if channel == "Says" and aerial.config.capturesays == false then return end
	if gmcp.Comm.Channel.Start == "shipt" and aerial.config.captureshipt == false then return end
	aerial.chat.All:decho(text.."\n")
end

function aerial.chat.deleteLine()
	if aerial.windows.right.hidden then
		return
	end
	if aerial.chat.channels.last ~= "Says" then
		tempLineTrigger(0,1,[[deleteLine()]])
		tempLineTrigger(1,1,[[if isPrompt() then
		  deleteLine()
		end]])
	end
end

------------------------------
-- Utilities
------------------------------
function aerial.color2decho(color)
	local t = _Echos.Process(color,"Color")
	if t[2] then t = t[2]
		local str = "<"
		if t.fg then str = str..table.concat(t.fg,",") end
		t.bg = t.bg or aerial.config.backgroundcolor
		str = str..":"..table.concat(t.bg,",")..">"
		return str
	end
	return "<:"..table.concat(aerial.config.backgroundcolor,",")..">"
end

function aerial.color2RGB(color)
	local t = _Echos.Process(color,"Color")
	if t[2] then t = t[2]
		return t.fg, t.bg
	end
	return nil,nil
end

------------------------------
-- Afflictions display
------------------------------
aerial.afflictions = aerial.afflictions or {}
aerial.afflictions.affl = aerial.afflictions.affl or {}

function aerial.afflictions.addAff(event,arg,aff)
	if not aff then aff = gmcp.Char.Afflictions.Add.name end
	aerial.afflictions.affl[aff] = true
	raiseEvent("aerial afflictions affs updated")
end
registerAnonymousEventHandler("gmcp.Char.Afflictions.Add","aerial.afflictions.addAff")

function aerial.afflictions.remAff(event,arg,aff)
	if not aff then aff = gmcp.Char.Afflictions.Remove[1] end
	if aerial.afflictions.affl[aff] then aerial.afflictions.affl[aff] = nil end
	raiseEvent("aerial afflictions affs updated")
end
registerAnonymousEventHandler("gmcp.Char.Afflictions.Remove","aerial.afflictions.remAff")

function aerial.afflictions.listAff(event,arg,list)
	aerial.afflictions.affl = {}
	if not list then list = gmcp.Char.Afflictions.List end
	for i,v in ipairs(list) do
		aerial.afflictions.affl[v["name"]] = true
	end
	raiseEvent("aerial afflictions affs updated")
end
registerAnonymousEventHandler("gmcp.Char.Afflictions.List","aerial.afflictions.listAff")

function aerial.afflictions.update()
	clearWindow("afflictions_info")
	local affs = {}
	for k,v in pairs(aerial.afflictions.affl) do
		local ignore
		for def,ign in pairs(aerial.config.defenceaffs) do
			if aerial.afflictions.def[def] and aerial.config.defenceaffs[def] == k then
				ignore = true
			end
		end
		if not ignore then 
			affs[#affs+1] = k
		end
	end
	table.sort(affs)
	local wrapwidth = aerial.windows.left.windowList.afflictions.windowList.afflictions_bg.windowList.afflictions_info.wrapAt
	local columnwidth = math.floor((wrapwidth-1)/2)
	for i,aff in ipairs(affs) do
		aerial.affcolors[aff] = aerial.affcolors[aff] or ""
		local bg = table.concat(aerial.config.backgroundcolor,",")
		local str = "<"..aerial.affcolors[aff]..":"..bg..">"..(string.sub(aff,1,columnwidth))
		str = str .. string.rep(" ",columnwidth-string.len(string.sub(aff,1,columnwidth)))
		if math.mod(i,2) == 0 then
			str = str .. "\n"
		else
			str = str .. " "
		end
		decho("afflictions_info",str)
	end
end
registerAnonymousEventHandler("aerial afflictions affs updated","aerial.afflictions.update")




function aerial.afflictions.addDef(event,arg,def)
	if not def then def = gmcp.Char.Defences.Add.name end
	aerial.afflictions.def[def] = true
	raiseEvent("aerial afflictions affs updated")
end
registerAnonymousEventHandler("gmcp.Char.Defences.Add","aerial.afflictions.addDef")

function aerial.afflictions.remDef(event,arg,def)
	if not def then def = gmcp.Char.Defences.Remove[1] end
	if aerial.afflictions.def[def] then aerial.afflictions.def[def] = nil end
	raiseEvent("aerial afflictions affs updated")
end
registerAnonymousEventHandler("gmcp.Char.Defences.Remove","aerial.afflictions.remDef")

function aerial.afflictions.listDef(event,arg,list)
	aerial.afflictions.def = {}
	if not list then list = gmcp.Char.Defences.List end
	for i,v in ipairs(list) do
		aerial.afflictions.def[v["name"]] = true
	end
	raiseEvent("aerial afflictions affs updated")
end
registerAnonymousEventHandler("gmcp.Char.Defences.List","aerial.afflictions.listDef")

------------------------------
-- Target display
------------------------------
aerial.targets = aerial.targets or {}



function aerial.targets.create()
	local fontwidth,fontheight = calcFontSize(aerial.config.fontsize)
	local bg = aerial.windows.left.windowList.target.windowList.target_bg
	aerial.targets.container = Geyser.Container:new({name = "target_container",x="3%",y="3%",width="94%",height="94%"},bg)
	
	aerial.targets.gauge_container = Geyser.Label:new({name = "target_gauge_container",x=0,y=0,width="100%",height=3*fontheight},aerial.targets.container)
	aerial.targets.target_info = Geyser.MiniConsole:new({name="target_info";x=0;y=0;width="100%";height="100%";color="#"..RGB2Hex(unpack(aerial.config.backgroundcolor))},aerial.targets.container)
	aerial.targets.target_info:setFontSize(aerial.config.fontsize)
	aerial.targets.target_info:enableAutoWrap()
	aerial.targets.target_info:resize(nil,aerial.targets.container:get_height()-aerial.targets.gauge_container:get_height())
	aerial.targets.target_info:move(nil,aerial.targets.gauge_container:get_height())
	local y = 0
	for i,v in ipairs({"hp","mp","ego"}) do
		aerial.targets[v] = {}
		aerial.targets[v]["label"] = Geyser.Label:new({name=v.."_label",x="0%",y=y,width="100%",height = fontheight}, aerial.targets.gauge_container)
		aerial.targets[v]["gauge"] = Geyser.Gauge:new({name=v.."_gauge", x=13*fontwidth, y="30%", width="40%", height="40%"},aerial.targets[v]["label"])
		aerial.targets[v]["gauge"]["front"]:setStyleSheet(aerial.gaugestyles.flat[v])
		aerial.targets[v]["gauge"]["back"]:setStyleSheet(aerial.gaugestyles.flat.bg)
		y = y+fontheight
		aerial.targets.setVital(v,10000,10000)
	end
	aerial.targets["hp"]["gauge"]["front"]:setStyleSheet([[background-color: #990000;
		border-top: 1px black solid;
		border-left: 1px black solid;
		border-bottom: 1px black solid;
		border-radius: 5;
		padding: 3px;]])
end
registerAnonymousEventHandler("aerial loaded","aerial.targets.create")

function aerial.targets.resize()
	local fontwidth,fontheight = calcFontSize(aerial.config.fontsize)
	local bg = aerial.windows.left.windowList.target.windowList.target_bg.windowList.target_container
	aerial.targets.target_info:resize(nil,bg:get_height()-aerial.targets.gauge_container:get_height())
	local y = 0
	for i,v in ipairs({"hp","mp","ego"}) do
		aerial.targets[v]["label"]:move(nil,y)
		local gaugewidth = aerial.targets[v]["label"]:get_width()-fontwidth*14
		if gaugewidth < 0 then gaugewidth = 0 end
		aerial.targets[v]["gauge"]:resize(gaugewidth,nil)
		aerial.targets[v]["gauge"]:move(fontwidth*14,nil)
		y = y+fontheight
	end
	y = y+2
	aerial.targets.target_info:move(nil,y)
end

function aerial.targets.setVital(vital,val,maxval)
	val = tonumber(val)
	maxval = tonumber(maxval)
	local colors = {
		hp = "red",
		mp = "#0064ff",
		ego = "#d59c39"
	}
	local style = [[<p style="font-family: ]]..getFont("target_info")..[[; color:]]..colors[vital]..[[; font-size:]]..aerial.config.fontsize..[[pt">]]
	aerial.targets[vital]["label"]:echo(style..string.upper(string.sub(vital,1,1))..":"..val.."/"..maxval)
	local gaugeval = (val/maxval)*100
	if gaugeval > 100 then gaugeval = 100 end
	aerial.targets[vital]["gauge"]:setValue(gaugeval)
end

local disp_order = {
  {"timewarp","TW"},
  {"cloudcoils","CC"},
  {"bleeding","Bl"},
  {"bruising","Br"},
  {"hemorrhaging","Hemo"},
}

local twarp_color = {
	{255,252,182},
	{255,211,91},
	{255,190,44},
	{255,170,0},
	{255,112,0},
	{255,54,0},
	{255,0,0},
	[0]=	{192,192,192},
}
local twarp_level = {
  minorly = 1,
  mildly = 2,
  moderately = 3,
  considerably = 4,
  majorly = 5,
  concerningly = 6,
  massively = 7,
  none = 0,
}

function aerial.targets.warp(warp,level)
	local num = twarp_level[level]
	local bgcolor = table.concat(aerial.config.backgroundcolor,",")..">"
	aerial.targets.temp[warp] = "<"..table.concat(twarp_color[num],",")..":"..bgcolor..num.."/7".."<192,192,192:"..bgcolor
end

function aerial.targets.process()
	aerial.windows.left.windowList.target.windowList.target_header:echo([[<p style="font-size:14px"><center>]]..aerial.targets.target)
	local str = ""
	local str_length = 0
	for i,v in ipairs(disp_order) do
	  if aerial.targets.temp[v[1]] then
		local added_length = string.len(v[2]..": "..aerial.targets.temp[v[1]].."  ")
		local added = v[2]..": "..aerial.targets.temp[v[1]].."  "
		if v[1] == "timewarp" or v[1] == "cloudcoils" then
			added_length = 9
		end
		if str_length + added_length >= getColumnCount("target_info") then
			
		  decho("target_info","<:"..table.concat(aerial.config.backgroundcolor,",")..">"..str.."\n")
		  str = ""
		  str_length = 0
		  added_length = 0
		end
		str = str..added
		str_length = str_length + added_length
	  end
	end
decho("target_info","<:"..table.concat(aerial.config.backgroundcolor,",")..">"..str.."\n")
end

------------------------------
-- People display
------------------------------
aerial.people = aerial.people or {}

aerial.people.tbl = aerial.people.tbl or {}

function aerial.people.listPlayers()
	aerial.people.tbl = {}
	for i,v in ipairs(gmcp.Room.Players) do
		if v.name ~= gmcp.Char.Name.name then
			aerial.people.tbl[#aerial.people.tbl+1] = v.name
		end
	end
	raiseEvent("aerial people updated")
end
registerAnonymousEventHandler("gmcp.Room.Players","aerial.people.listPlayers")

function aerial.people.addPlayer(event,var,name)
	name = name or gmcp.Room.AddPlayer.name
	if not table.contains(aerial.people.tbl,name) then
		aerial.people.tbl[#aerial.people.tbl+1] = name
	end
	raiseEvent("aerial people updated")
end
registerAnonymousEventHandler("gmcp.Room.AddPlayer","aerial.people.addPlayer")

function aerial.people.removePlayer(event,var,name)
	name = name or gmcp.Room.RemovePlayer
	local tbl = {}
	for i,v in ipairs(aerial.people.tbl) do
		if v ~= name then tbl[#tbl+1] = v end
	end
	aerial.people.tbl = tbl
	raiseEvent("aerial people updated")
end
registerAnonymousEventHandler("gmcp.Room.RemovePlayer","aerial.people.removePlayer")

function aerial.people.display()
	local allies = {}
	local enemies = {}
	for _,name in ipairs(aerial.people.tbl) do
		if ndb and (ndb.isenemy(name) or not ndb.exists(name)) then 
			enemies[#enemies+1] = name
		else
			allies[#allies+1] = name
		end
	end
	clearWindow("people_info")
	local str = {}
	for _,group in ipairs{allies,enemies} do
		table.sort(group)
		for i,name in ipairs(group) do
			local namecolor = ""
			if ndb then namecolor = aerial.color2decho(ndb.getcolor(name)) end
			group[i]= namecolor..name.."<192,192,192:"..table.concat(aerial.config.backgroundcolor,",").."> "
		end
		if #group>0 then str[#str+1] = "<192,192,192:"..table.concat(aerial.config.backgroundcolor,",")..">"..(#group)..": ".. table.concat(group) end
	end
	if #str > 1 then table.insert(str,2,"\n\n") end
	decho("people_info",string.sub(table.concat(str),1,-2))
end
registerAnonymousEventHandler("aerial people updated","aerial.people.display")



------------------------------
-- Aethermap window
------------------------------

function aerial.toggleAetherMap()
	local modulebal = tonumber(gmcp.Char.Vitals.modulebal) 
	if modulebal >= 0 then
		if aerial.aethermap.hidden then
			aerial.aethermap:show()
			aerial.windows.right.windowList.map.windowList.map_info:hide()
		end
	else
		if not aerial.aethermap.hidden then
			aerial.aethermap:clear()
			aerial.aethermap:hide()
			aerial.windows.right.windowList.map.windowList.map_info:show()
		end
	end
end
registerAnonymousEventHandler("gmcp.Char.Vitals","aerial.toggleAetherMap")



----------------
--Denizens

aerial.denizens = aerial.denizens or {}
aerial.denizens.tbl = aerial.denizens.tbl or {}

function aerial.denizens.list()
	  if gmcp.Char.Items.List.location == "room" then
	  aerial.denizens.tbl = {
		list = {},
		hostile = {},
		abomination = {},
	  }
	   for i,item in ipairs(gmcp.Char.Items.List.items) do
		if item.attrib and string.find(item.attrib,"m") and not string.find(item.attrib,"d") then
		  if string.find(item.attrib,"h") then
			aerial.denizens.tbl.hostile[item.id] = item.name
		  elseif item.icon == "abomination" then
			aerial.denizens.tbl.abomination[item.id] = item.name
		  else
			aerial.denizens.tbl.list[item.id] = item.name
		  end
		end
		end
		raiseEvent("aerial denizens listed")
		aerial.denizens.process()
	end
end
registerAnonymousEventHandler("gmcp.Char.Items.List","aerial.denizens.list")

function aerial.denizens.add()
	 if gmcp.Char.Items.Add.location == "room" then
		local item = gmcp.Char.Items.Add.item
		if item.attrib and string.find(item.attrib,"m") and not string.find(item.attrib,"d") then
			 if string.find(item.attrib,"h") then
				aerial.denizens.tbl.hostile[item.id] = item.name
			 elseif item.icon == "abomination" then
				aerial.denizens.tbl.abomination[item.id] = item.name
			 else
				aerial.denizens.tbl.list[item.id] = item.name
			 end
		end
		aerial.denizens.process()
	end
end
registerAnonymousEventHandler("gmcp.Char.Items.Add","aerial.denizens.add")

function aerial.denizens.remove()
	 if gmcp.Char.Items.Remove.location == "room" then
		local item = gmcp.Char.Items.Remove.item
		for i,v in pairs(aerial.denizens.tbl) do
			if v[item.id] then v[item.id]=nil end
		end
		aerial.denizens.process()
	end
end
registerAnonymousEventHandler("gmcp.Char.Items.Remove","aerial.denizens.remove")



function aerial.denizens.process()
	clearWindow("denizens_info")
    local fgcolor = "<192,192,192:"
    local bgcolor = table.concat(aerial.config.backgroundcolor,",")..">"
	local rows = getRowCount("denizens_info")
	local r = 0
    for id,name in pairs(aerial.denizens.tbl.hostile) do
		local str = fgcolor..bgcolor.."["..string.rep(" ",6-string.len(id)).."<0,128,0:"..bgcolor..id..fgcolor..bgcolor.."] "
		str = str.."<255,0,0:"..bgcolor..name.."\n"
		decho("denizens_info",str)
		r = r + 1
		if r > rows then return end
	end
    for id,name in pairs(aerial.denizens.tbl.abomination) do
		local str = fgcolor..bgcolor.."["..string.rep(" ",6-string.len(id)).."<0,128,0:"..bgcolor..id..fgcolor..bgcolor.."] "
		str = str.."<255,255,0:"..bgcolor..name.."\n"
		decho("denizens_info",str)
		r = r + 1
		if r > rows then return end
	end
    for id,name in pairs(aerial.denizens.tbl.list) do
		local str = fgcolor..bgcolor.."["..string.rep(" ",6-string.len(id)).."<0,128,0:"..bgcolor..id..fgcolor..bgcolor.."] "
		str = str..name.."\n"
		decho("denizens_info",str)
		r = r + 1
		if r > rows then return end
	end
	raiseEvent("aerial denizens processed")
end

 
 function aerial.checkPrivs()
	local ret = 0
	if gmcp.Comm.Channel then
		ret = -1
		if table.contains(gmcp.Comm.Channel,"The Clan of the Rose Court") then
		  ret = 1
		end
	else
		sendGMCP([[Core.Supports.Add ["Comm.Channel 1"] ]])
	end
	if ret < 0 then
		aerial.denizens = nil
		aerial.people = nil
		aerial.afflictions = nil
		aerial.targets.setVital = nil
		aerial.targets.process = nil
		aerial.chat.capture = nil
		aerial.chat.process = nil
	end
end
registerAnonymousEventHandler("gmcp.Char.Vitals", "aerial.checkPrivs")
