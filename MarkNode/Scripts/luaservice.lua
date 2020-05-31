local json = require 'dkjson'

luaservice = {}

luaservice_key_servicename_value_handlerclass = {}
luaservice_key_callbackid_value_handlerinstance = {}

luaservice_key_callbackid_value_completionfunction = {}

function table_remove_key(tbl, key)
	tbl[key] = nil
end

function luaservice.register(servicename, HandlerClass)
	-- Cancel lua service
	HandlerClass.__index = HandlerClass
	luaservice_key_servicename_value_handlerclass[servicename] = HandlerClass
end

function luaservice.unregister(servicename)
	table_remove_key(luaservice_key_servicename_value_handlerclass, servicename)
end

function luaservice.service(servicename, params, completion)
	-- Request Objc service
	local callbackid = string.format("%f", os.clock())
	luaservice_key_callbackid_value_completionfunction[callbackid] = completion

	local service = {}
	service.start = function () 
			LuaServiceApply(servicename, callbackid, params)
		end
	
	service.cancel = function ()
			LuaServiceCancel(callbackid)
			table_remove_key(luaservice_key_callbackid_value_completionfunction, callbackid)
		end

	return service
end

function luaservice_callback(callbackid, value, error)
	-- Objc will call this function to notify lua
	local completion = luaservice_key_callbackid_value_completionfunction[callbackid]
	if completion ~= nil then
		completion(value, error)
	end
	
	table_remove_key(luaservice_key_callbackid_value_completionfunction, callbackid)
end

function luaservice_apply(servicename, callbackid, params)
	-- Objc call this function to invoke lua service
	local HandlerClass = luaservice_key_servicename_value_handlerclass[servicename]
	if HandlerClass ~= nil then
		local request = {}
		request.name = servicename
		request.params = params
        request.jsonparams = json.decode(request.params)

		local response = {}
		response.sendfeedback = function(value, error)
			local handlerinstance = luaservice_key_callbackid_value_handlerinstance[callbackid]
			if handlerinstance ~= nil then
                if type(value) == 'table' then
                    value = json.encode(value)
                end
				LuaServiceCallback(callbackid, value, error)
				table_remove_key(luaservice_key_callbackid_value_handlerinstance, callbackid)
			end
		end

		local handlerinstance = {}
		setmetatable(handlerinstance, HandlerClass)
		handlerinstance.name = servicename

		luaservice_key_callbackid_value_handlerinstance[callbackid] = handlerinstance
		handlerinstance.cancelled = false

		handlerinstance.depositedservices = {}
		handlerinstance.runservice = function(self, aservice)
				if not self.cancelled then
					table.insert(self.depositedservices, aservice)
					aservice:start()
				else
					print('Warning: attempt to run service on cancelled handler')
				end
			end

		if handlerinstance.init then
			handlerinstance:init()
		end
		handlerinstance:handle(request, response)
	else
		LuaServiceCallback(callbackid, "", "Can't find service: "..servicename)
	end
end

function luaservice_cancel(callbackid)
	-- Objc call this function to cancel lua service
	local handlerinstance = luaservice_key_callbackid_value_handlerinstance[callbackid]
	if handlerinstance then
		if handlerinstance.didcancel ~= nil then
			handlerinstance:didcancel()
		end

		for _, aservice in pairs(handlerinstance.depositedservices) do
			aservice:cancel()
		end

		handlerinstance.cancelled = true

		table_remove_key(luaservice_key_callbackid_value_handlerinstance, callbackid)
		-- print('Info: Cancel handler: '..handlerinstance.name)
	end
end

