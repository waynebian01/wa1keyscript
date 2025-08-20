local e = aura_env
local region = WeakAuras.GetRegion(e.id)
WK_DISPERSE = true
region:SetAlpha(1)

if not _G[e.id .. "Button"] then
    if region then
        e.btn = CreateFrame("Button", e.id .. "Button", region)
        e.btn:RegisterForClicks("LeftButtonUp", "RightButtonUp", "MiddleButtonUp")
        e.btn:EnableMouseWheel(true)
        e.btn:SetAllPoints(region)
        e.btn.background = e.btn:CreateTexture(nil, "BACKGROUND")
        e.btn.background:SetAllPoints(true)
    end
end

local btn = _G[e.id .. "Button"]

btn:SetScript("OnClick", function(self, button)
    if button == "LeftButton" then
        if WK_DISPERSE then
            WK_DISPERSE = false
            print("驱散关闭")
            region:SetAlpha(0.5)
            WeakAuras.ScanEvents("DISPERSE_EVENT")
        else
            WK_DISPERSE = true
            print("驱散开启")
            region:SetAlpha(1)
            WeakAuras.ScanEvents("DISPERSE_EVENT")
        end
    end
end)

btn:SetScript("OnEnter", function(self)
    region:SetScale(1.25)
end)
btn:SetScript("OnLeave", function(self)
    region:SetScale(1)
end)





local text
if WK_DISPERSE then
    text = "驱散开启"
else
    text = "驱散关闭"
end
return text
