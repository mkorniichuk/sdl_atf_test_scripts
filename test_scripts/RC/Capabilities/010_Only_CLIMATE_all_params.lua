---------------------------------------------------------------------------------------------------
-- Requirement summary:
-- [SDL_RC] Capabilities
--
-- Description:
-- In case:
-- 1) SDL does not get RC capabilities for RADIO module through RC.GetCapabilities
-- SDL must:
-- 1) Response with success = false and resultCode = UNSUPPORTED_RESOURCE on all valid RPC with module RADIO
-- 2) Does not send RPC request to HMI
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local commonRC = require('test_scripts/RC/commonRC')

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", commonRC.preconditions)
runner.Step("Start SDL, HMI (HMI has all CLIMATE RC capabilities), connect Mobile, start Session", commonRC.start,
	{commonRC.buildHmiRcCapabilities(commonRC.DEFAULT, nil, commonRC.DEFAULT)})
runner.Step("RAI, PTU", commonRC.rai_ptu)
runner.Step("Activate App1", commonRC.activate_app)

runner.Title("Test")

-- CLIMATE RPC is allowed
runner.Step("GetInteriorVehicleData CLIMATE", commonRC.subscribeToModule, { "CLIMATE", 1 })
runner.Step("SetInteriorVehicleData CLIMATE", commonRC.rpcAllowed, { "CLIMATE", 1, "SetInteriorVehicleData" })
-- RADIO PRC is unsupported
runner.Step("GetInteriorVehicleData RADIO", commonRC.rpcDenied, { "RADIO", 1, "GetInteriorVehicleData", "UNSUPPORTED_RESOURCE" })
runner.Step("SetInteriorVehicleData RADIO", commonRC.rpcDenied, { "RADIO", 1, "SetInteriorVehicleData", "UNSUPPORTED_RESOURCE" })

runner.Title("Postconditions")
runner.Step("Stop SDL", commonRC.postconditions)
