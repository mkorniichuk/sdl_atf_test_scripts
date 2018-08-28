----------------------------------------------------------------------------------------------------
-- GitHub issue: https://github.com/smartdevicelink/sdl_core/issues/2447
----------------------------------------------------------------------------------------------------
-- Reproduction Steps:
-- 1) Register app with name = App1 and Id = 999 with uncheck Policy File Update
-- 2) Enter FULL
-- 3) Force stop application
-- 4) Start SPT then register another app and send LPT update. Then app in step 1 becomes revoked
-- 5) Register app with name = App1 and Id = 999

-- Expected Behavior:
-- SDL can't resume App1 as FULL
----------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('user_modules/sequences/actions')
local commonDefects = require('test_scripts/Defects/commonDefects')
local json = require('modules/json')
local utils = require("user_modules/utils")
local test = require("user_modules/dummy_connecttest")


--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

local function PTUFuncToClearApp1Policy(tbl)
  tbl.policy_table.app_policies[config.application1.registerAppInterfaceParams.appID] = json.null
end

local function unexpectedDisconnect()
  common.getMobileConnection():Close()
  common.getHMIConnection():ExpectNotification("BasicCommunication.OnAppUnregistered",
    { unexpectedDisconnect = true })
  common.getMobileConnection():Connect()
end

local function cleanMobileSessions()
  for i = 1, #test.mobileSession do
    test.mobileSession[i] = nil
  end
end

local function registerApp(pAppId)
  common.getMobileSession(pAppId):StartService(7)
  :Do(function()
      local corId = common.getMobileSession(pAppId):SendRPC("RegisterAppInterface", common.getConfigAppParams(pAppId))
      common.getHMIConnection():ExpectNotification("BasicCommunication.OnAppRegistered",
        { application = { appName = common.getConfigAppParams(pAppId).appName } })
      common.getMobileSession(pAppId):ExpectResponse(corId, { success = true, resultCode = "SUCCESS" })
      common.getMobileSession(pAppId):ExpectNotification("OnHMIStatus", { hmiLevel = "NONE" })
    end)
end

local function checkAppIsNotResumed(pAppId)
  common.getHMIConnection():ExpectRequest("BasicCommunication.ActivateApp", { appID = common.getHMIAppId(pAppId) })
  :Times(0)
  utils.wait(10000)
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)

runner.Title("Test")
runner.Step("Register App1", common.registerApp, { 1 })
runner.Step("PTU", common.policyTableUpdate)
runner.Step("Activate App1", common.activateApp, { 1 })
runner.Step("Force stop App1", unexpectedDisconnect)

runner.Step("Register App2", common.registerApp, { 2 })
runner.Step("PTU, revoke App1", common.policyTableUpdate, { PTUFuncToClearApp1Policy })
runner.Step("ForceStop App2", unexpectedDisconnect)
runner.Step("Clean session App2", cleanMobileSessions)
runner.Step("Register App1", registerApp, { 1 })
runner.Step("Check App1 is not resumed in FULL", checkAppIsNotResumed, { 1 })

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
