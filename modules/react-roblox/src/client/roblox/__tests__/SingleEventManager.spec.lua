return function()
	local Packages = script.Parent.Parent.Parent.Parent.Parent
	local jestModule = require(Packages.Dev.JestRoblox)
	local jestExpect = jestModule.Globals.expect
	local jest = jestModule.Globals.jest
	-- ROBLOX FIXME
	-- local Logging = require(script.Parent.Parent.Logging)

	local SingleEventManager = require(script.Parent.Parent.SingleEventManager)

	describe("new", function()
		it("should create a SingleEventManager", function()
			local manager = SingleEventManager.new()

			jestExpect(manager).never.toBeNil()
		end)
	end)

	describe("connectEvent", function()
		it("should connect to events", function()
			local instance = Instance.new("BindableEvent")
			local manager = SingleEventManager.new(instance)
			local eventSpy = jest:fn()

			manager:connectEvent(
				"Event",
				function(...) eventSpy(...) end
			)
			manager:resume()

			instance:Fire("foo")
			jestExpect(eventSpy).toBeCalledTimes(1)
			jestExpect(eventSpy).toBeCalledWith(instance, "foo")

			instance:Fire("bar")
			jestExpect(eventSpy).toBeCalledTimes(2)
			jestExpect(eventSpy).toBeCalledWith(instance, "bar")

			manager:connectEvent("Event", nil)

			instance:Fire("baz")
			jestExpect(eventSpy).toBeCalledTimes(2)
		end)

		it("should drop events until resumed initially", function()
			local instance = Instance.new("BindableEvent")
			local manager = SingleEventManager.new(instance)
			local eventSpy = jest:fn()

			manager:connectEvent(
				"Event",
				function(...) eventSpy(...) end
			)

			instance:Fire("foo")
			jestExpect(eventSpy).never.toBeCalled()

			manager:resume()

			instance:Fire("bar")
			jestExpect(eventSpy).toBeCalledTimes(1)
			jestExpect(eventSpy).toBeCalledWith(instance, "bar")
		end)

		it("should invoke suspended events when resumed", function()
			local instance = Instance.new("BindableEvent")
			local manager = SingleEventManager.new(instance)
			local eventSpy = jest:fn()

			manager:connectEvent(
				"Event",
				function(...) eventSpy(...) end
			)
			manager:resume()

			instance:Fire("foo")
			jestExpect(eventSpy).toBeCalledTimes(1)
			jestExpect(eventSpy).toBeCalledWith(instance, "foo")

			manager:suspend()

			instance:Fire("bar")
			jestExpect(eventSpy).toBeCalledTimes(1)

			manager:resume()
			jestExpect(eventSpy).toBeCalledTimes(2)
			jestExpect(eventSpy).toBeCalledWith(instance, "bar")
		end)

		it("should invoke events triggered during resumption in the correct order", function()
			local instance = Instance.new("BindableEvent")
			local manager = SingleEventManager.new(instance)

			local recordedValues = {}
			local eventSpy = jest:fn(function(_, value)
				table.insert(recordedValues, value)

				if value == 2 then
					instance:Fire(3)
				elseif value == 3 then
					instance:Fire(4)
				end
			end)

			manager:connectEvent(
				"Event",
				function(...) eventSpy(...) end
			)
			manager:suspend()

			instance:Fire(1)
			instance:Fire(2)

			manager:resume()
			jestExpect(eventSpy).toBeCalledTimes(4)
			jestExpect(recordedValues).toEqual({1, 2, 3, 4})
		end)

		it("should not invoke events fired during suspension but disconnected before resumption", function()
			local instance = Instance.new("BindableEvent")
			local manager = SingleEventManager.new(instance)
			local eventSpy = jest:fn()

			manager:connectEvent(
				"Event",
				function(...) eventSpy(...) end
			)
			manager:suspend()

			instance:Fire(1)

			manager:connectEvent("Event", nil)

			manager:resume()
			jestExpect(eventSpy).never.toBeCalled()
		end)

		it("should not yield events through the SingleEventManager when resuming", function()
			local instance = Instance.new("BindableEvent")
			local manager = SingleEventManager.new(instance)

			manager:connectEvent("Event", function()
				coroutine.yield()
			end)

			manager:resume()

			local co = coroutine.create(function()
				instance:Fire(5)
			end)

			assert(coroutine.resume(co))
			jestExpect(coroutine.status(co)).toBe("dead")

			manager:suspend()
			instance:Fire(5)

			co = coroutine.create(function()
				manager:resume()
			end)

			assert(coroutine.resume(co))
			jestExpect(coroutine.status(co)).toBe("dead")
		end)

		it("should not throw errors through SingleEventManager when resuming", function()
			local errorText = "Error from SingleEventManager test"

			local instance = Instance.new("BindableEvent")
			local manager = SingleEventManager.new(instance)

			manager:connectEvent("Event", function()
				error(errorText)
			end)

			manager:resume()

			-- If we call instance:Fire() here, the error message will leak to
			-- the console since the thread's resumption will be handled by
			-- Roblox's scheduler.

			manager:suspend()
			instance:Fire(5)

			-- local logInfo = Logging.capture(function()
			-- 	manager:resume()
			-- end)

			-- jestExpect(#logInfo.errors).to.equal(0)
			-- jestExpect(#logInfo.warnings).to.equal(1)
			-- jestExpect(#logInfo.infos).to.equal(0)

			-- jestExpect(logInfo.warnings[1]:find(errorText)).to.be.ok()
		end)

		it("should not overflow with events if manager:resume() is invoked when resuming a suspended event", function()
			local instance = Instance.new("BindableEvent")
			local manager = SingleEventManager.new(instance)

			-- This connection emulates what happens if reconciliation is
			-- triggered again in response to reconciliation. Without
			-- appropriate guards, the inner resume() call will process the
			-- Fire(1) event again, causing a nasty stack overflow.
			local eventSpy = jest:fn(function(_, value)
				if value == 1 then
					manager:suspend()
					instance:Fire(2)
					manager:resume()
				end
			end)

			manager:connectEvent(
				"Event",
				function(...) eventSpy(...) end
			)

			manager:suspend()
			instance:Fire(1)
			manager:resume()

			jestExpect(eventSpy).toBeCalledTimes(2)
		end)
	end)

	describe("connectPropertyChange", function()
		-- Since property changes utilize the same mechanisms as other events,
		-- the tests here are slimmed down to reduce redundancy.

		it("should connect to property changes", function()
			local instance = Instance.new("Folder")
			local manager = SingleEventManager.new(instance)
			local eventSpy = jest:fn()

			manager:connectPropertyChange(
				"Name",
				function(...) eventSpy(...) end
			)
			manager:resume()

			instance.Name = "foo"
			jestExpect(eventSpy).toBeCalledTimes(1)
			jestExpect(eventSpy).toBeCalledWith(instance)

			instance.Name = "bar"
			jestExpect(eventSpy).toBeCalledTimes(2)
			jestExpect(eventSpy).toBeCalledWith(instance)

			manager:connectPropertyChange("Name")

			instance.Name = "baz"
			jestExpect(eventSpy).toBeCalledTimes(2)
		end)

		it("should throw an error if the property is invalid", function()
			local instance = Instance.new("Folder")
			local manager = SingleEventManager.new(instance)

			jestExpect(function()
				manager:connectPropertyChange("foo", function() end)
			end).toThrow()
		end)
	end)
end