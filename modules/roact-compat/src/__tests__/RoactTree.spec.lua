return function()
	local Packages = script.Parent.Parent.Parent
	local RobloxJest = require(Packages.Dev.RobloxJest)
	local jest = require(Packages.Dev.JestRoblox)
	local jestExpect = jest.Globals.expect
	local Roact
	local RoactCompat

	beforeEach(function()
		RobloxJest.resetModules()
		Roact = require(Packages.Dev.Roact)
		RoactCompat = require(script.Parent.Parent)
	end)

	it("should create an orphaned instance to mount under if none is provided", function()
		local ref = RoactCompat.createRef()
		local tree = RoactCompat.mount(RoactCompat.createElement("Frame", {ref = ref}))

		jestExpect(ref.current).never.toBeNil()
		jestExpect(ref.current.Parent).never.toBeNil()
		jestExpect(ref.current.Parent.ClassName).toBe("Folder")

		jestExpect(ref.current.Name).toBe("ReactLegacyRoot")

		RoactCompat.unmount(tree)
	end)

	it("should name children using the key", function()
		local legacyTarget = Instance.new("Folder")
		local legacyTree = Roact.mount(Roact.createElement("Frame"), legacyTarget, "SameNameTree")

		local compatTarget = Instance.new("Folder")
		local compatTree = RoactCompat.mount(RoactCompat.createElement("Frame"), compatTarget, "SameNameTree")

		local legacyRootInstance = legacyTarget:FindFirstChildWhichIsA("Frame")
		jestExpect(legacyRootInstance).never.toBeNil()
		local compatRootInstance = compatTarget:FindFirstChildWhichIsA("Frame")
		jestExpect(compatRootInstance).never.toBeNil()

		jestExpect(legacyRootInstance.Name).toEqual(compatRootInstance.Name)
		jestExpect(compatRootInstance.Name).toBe("SameNameTree")

		Roact.unmount(legacyTree)
		RoactCompat.unmount(compatTree)
	end)

	it("keeps the same root name on update", function()
		local legacyTarget = Instance.new("Folder")
		local legacyTree = Roact.mount(Roact.createElement("Frame"), legacyTarget, "SameNameTree")

		local compatTarget = Instance.new("Folder")
		local compatTree = RoactCompat.mount(RoactCompat.createElement("Frame"), compatTarget, "SameNameTree")

		local legacyRootInstance = legacyTarget:FindFirstChildWhichIsA("Frame")
		jestExpect(legacyRootInstance.Name).toBe("SameNameTree")
		local compatRootInstance = compatTarget:FindFirstChildWhichIsA("Frame")
		jestExpect(compatRootInstance.Name).toBe("SameNameTree")

		Roact.update(legacyTree, Roact.createElement("TextLabel"))
		RoactCompat.update(compatTree, RoactCompat.createElement("TextLabel"))

		legacyRootInstance = legacyTarget:FindFirstChildWhichIsA("TextLabel")
		jestExpect(legacyRootInstance.Name).toBe("SameNameTree")
		compatRootInstance = compatTarget:FindFirstChildWhichIsA("TextLabel")
		jestExpect(compatRootInstance.Name).toBe("SameNameTree")

		Roact.unmount(legacyTree)
		RoactCompat.unmount(compatTree)
	end)

	it("should not clear out other children of the target", function()
		local compatTarget = Instance.new("Folder")

		local preexistingChild = Instance.new("Frame")
		preexistingChild.Name = "PreexistingChild"
		preexistingChild.Parent = compatTarget

		local compatTree = RoactCompat.mount(RoactCompat.createElement("TextLabel"), compatTarget, "RoactTree")

		local compatRootInstance = compatTarget:FindFirstChildWhichIsA("TextLabel")
		jestExpect(compatRootInstance.Name).toBe("RoactTree")

		local existingChild = compatTarget:FindFirstChildWhichIsA("Frame")
		jestExpect(existingChild.Name).toBe("PreexistingChild")

		RoactCompat.unmount(compatTree)
	end)
end