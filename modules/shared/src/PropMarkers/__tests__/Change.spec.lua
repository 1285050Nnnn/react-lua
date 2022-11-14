--[[
	* Copyright (c) Roblox Corporation. All rights reserved.
	* Licensed under the MIT License (the "License");
	* you may not use this file except in compliance with the License.
	* You may obtain a copy of the License at
	*
	*     https://opensource.org/licenses/MIT
	*
	* Unless required by applicable law or agreed to in writing, software
	* distributed under the License is distributed on an "AS IS" BASIS,
	* WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
	* See the License for the specific language governing permissions and
	* limitations under the License.
]]
return function()
	local Packages = script.Parent.Parent.Parent.Parent
	local jestExpect = require(Packages.Dev.JestGlobals).expect

	local Type = require(script.Parent.Parent.Parent["Type.roblox"])
	local Change = require(script.Parent.Parent.Change)

	it("should yield change listener objects when indexed", function()
		jestExpect(Type.of(Change.Text)).toBe(Type.HostChangeEvent)
		jestExpect(Type.of(Change.Selected)).toBe(Type.HostChangeEvent)
	end)

	it("should yield the same object when indexed again", function()
		local a = Change.Text
		local b = Change.Text
		local c = Change.Selected

		jestExpect(a).toBe(b)
		jestExpect(a).never.toBe(c)
	end)
end