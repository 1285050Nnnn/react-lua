-- upstream: https://github.com/facebook/react/blob/16654436039dd8f16a63928e71081c7745872e8f/packages/react-reconciler/src/ReactChildFiber.new.js
--[[*
 * Copyright (c) Facebook, Inc. and its affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 *
 * @flow
]]
--!nolint LocalShadowPedantic
-- FIXME (roblox): remove this when our unimplemented
local function unimplemented(message)
  error("FIXME (roblox): " .. message .. " is unimplemented", 2)
end

local Workspace = script.Parent.Parent
local Packages = Workspace.Parent.Packages
local LuauPolyfill = require(Packages.LuauPolyfill)
local Array = LuauPolyfill.Array
-- ROBLOX: use patched console from shared
local console = require(Workspace.Shared.console)

local ReactElementType = require(Workspace.Shared.ReactElementType)
type ReactElement = ReactElementType.ReactElement;
local ReactTypes = require(Workspace.Shared.ReactTypes)
type ReactPortal = ReactTypes.ReactPortal
-- local ReactLazy = require(script.Parent.ReactLazy)
-- type LazyComponent = ReactLazy.LazyComponent
local ReactInternalTypes = require(script.Parent.ReactInternalTypes)
type Fiber = ReactInternalTypes.Fiber;
local ReactFiberLanes = require(script.Parent.ReactFiberLane)
type Lanes = ReactFiberLanes.Lanes;

local getComponentName = require(Workspace.Shared.getComponentName)
local ReactFiberFlags = require(script.Parent.ReactFiberFlags)
local Placement = ReactFiberFlags.Placement
local Deletion = ReactFiberFlags.Deletion
local ReactSymbols = require(Workspace.Shared.ReactSymbols)
local getIteratorFn = ReactSymbols.getIteratorFn
local REACT_ELEMENT_TYPE = ReactSymbols.REACT_ELEMENT_TYPE
local REACT_FRAGMENT_TYPE = ReactSymbols.REACT_FRAGMENT_TYPE
local REACT_PORTAL_TYPE = ReactSymbols.REACT_PORTAL_TYPE
local REACT_LAZY_TYPE = ReactSymbols.REACT_LAZY_TYPE
local REACT_BLOCK_TYPE = ReactSymbols.REACT_BLOCK_TYPE
local ReactWorkTags = require(script.Parent.ReactWorkTags)
local FunctionComponent = ReactWorkTags.FunctionComponent
local ClassComponent = ReactWorkTags.ClassComponent
local HostText = ReactWorkTags.HostText
local HostPortal = ReactWorkTags.HostPortal
local ForwardRef = ReactWorkTags.ForwardRef
local Fragment = ReactWorkTags.Fragment
local SimpleMemoComponent = ReactWorkTags.SimpleMemoComponent
local Block = ReactWorkTags.Block
local invariant = require(Workspace.Shared.invariant)
local ReactFeatureFlags = require(Workspace.Shared.ReactFeatureFlags)
local warnAboutStringRefs = ReactFeatureFlags.warnAboutStringRefs
local enableLazyElements = ReactFeatureFlags.enableLazyElements
local enableBlocksAPI = ReactFeatureFlags.enableBlocksAPI

local ReactFiber = require(script.Parent["ReactFiber.new"])
local createWorkInProgress = ReactFiber.createWorkInProgress
-- local resetWorkInProgress = ReactFiber.resetWorkInProgress
local createFiberFromElement = ReactFiber.createFiberFromElement
local createFiberFromFragment = ReactFiber.createFiberFromFragment
local createFiberFromText = ReactFiber.createFiberFromText
local createFiberFromPortal = ReactFiber.createFiberFromPortal
local emptyRefsObject = require(script.Parent["ReactFiberClassComponent.new"]).emptyRefsObject
local ReactFiberHotReloading = require(script.Parent["ReactFiberHotReloading.new"])
local isCompatibleFamilyForHotReloading = ReactFiberHotReloading.isCompatibleFamilyForHotReloading
local StrictMode = require(script.Parent.ReactTypeOfMode).StrictMode

-- deviation: Common types
type Array<T> = { [number]: T }
type Set<T> = { [T]: boolean }

local exports = {}

local didWarnAboutMaps
-- ROBLOX deviation: Lua doesn't have built-in generators
-- local didWarnAboutGenerators
local didWarnAboutStringRefs
local ownerHasKeyUseWarning
local ownerHasFunctionTypeWarning
local warnForMissingKey = function(child: any, returnFiber: Fiber)
end

if _G.__DEV__ then
  didWarnAboutMaps = false
-- ROBLOX deviation: Lua doesn't have built-in generators
--   didWarnAboutGenerators = false
  didWarnAboutStringRefs = {}

  --[[
    Warn if there's no key explicitly set on dynamic arrays of children or
    object keys are not valid. This allows us to keep track of children between
    updates.
  ]]
  ownerHasKeyUseWarning = {}
  ownerHasFunctionTypeWarning = {}

  -- ROBLOX FIXME: This may need to change depending on how we want children to
  -- be passed. Current Roact accepts a table (keys are built-in) and leaves
  -- ordering up to users via LayoutOrder, but if we accept arrays (and attempt
  -- to somehow map them to LayoutOrder??) we'll need keys for stability
  warnForMissingKey = function(child: any, returnFiber: Fiber)
    if child == nil or typeof(child) ~= "table" then
      return
    end
    if not child._store or child._store.validated or child.key ~= nil then
      return
    end
    invariant(
      typeof(child._store) == "table",
      "React Component in warnForMissingKey should have a _store. " ..
        "This error is likely caused by a bug in React. Please file an issue."
    )
    child._store.validated = true

    local componentName = getComponentName(returnFiber.type) or "Component"

    if ownerHasKeyUseWarning[componentName] then
      return
    end
    ownerHasKeyUseWarning[componentName] = true

    console.error(
      'Each child in a list should have a unique ' ..
        '"key" prop. See https://reactjs.org/link/warning-keys for ' ..
        'more information.'
    )
  end
end

local isArray = Array.isArray

function coerceRef(
  returnFiber: Fiber,
  current,
  element: ReactElement
)
  local mixedRef = element.ref
  if
    mixedRef ~= nil and
    typeof(mixedRef) ~= 'function' and
    typeof(mixedRef) ~= "table" then

    if _G.__DEV__ then
      -- TODO: Clean this up once we turn on the string ref warning for
      -- everyone, because the strict mode case will no longer be relevant
      if
        (bit32.bor(returnFiber.mode, StrictMode) or warnAboutStringRefs) and
        -- We warn in ReactElement.js if owner and self are equal for string refs
        -- because these cannot be automatically converted to an arrow function
        -- using a codemod. Therefore, we don't have to warn about string refs again.
        not (
          element._owner and
          element._self and
          element._owner.stateNode ~= element._self
        ) then
        local componentName = getComponentName(returnFiber.type) or 'Component'
        if not didWarnAboutStringRefs[componentName] then
          if warnAboutStringRefs then
            console.error(
              'Component "%s" contains the string ref "%s". Support for string refs ' ..
                'will be removed in a future major release. We recommend using ' ..
                'useRef() or createRef() instead. ' ..
                'Learn more about using refs safely here: ' ..
                'https://reactjs.org/link/strict-mode-string-ref',
              componentName,
              mixedRef
            )
          else
            console.error(
              'A string ref, "%s", has been found within a strict mode tree. ' ..
                'String refs are a source of potential bugs and should be avoided. ' ..
                'We recommend using useRef() or createRef() instead. ' ..
                'Learn more about using refs safely here: ' ..
                'https://reactjs.org/link/strict-mode-string-ref',
              mixedRef
            )
          end
          didWarnAboutStringRefs[componentName] = true
        end
      end
    end

    if element._owner then
      local owner: Fiber? = element._owner
      local inst
      if owner then
        local ownerFiber = owner
        invariant(
          ownerFiber.tag == ClassComponent,
          'Function components cannot have string refs. ' ..
            'We recommend using useRef() instead. ' ..
            'Learn more about using refs safely here: ' ..
            'https://reactjs.org/link/strict-mode-string-ref'
        )
        inst = ownerFiber.stateNode
      end
      invariant(
        inst,
        'Missing owner for string ref %s. This error is likely caused by a ' ..
          'bug in React. Please file an issue.',
        mixedRef
      )

      -- ROBLOX FIXME: is this turning a number into a string?
      local stringRef = '' .. mixedRef
      -- Check if previous string ref matches new string ref
      if
        current ~= nil and
        current.ref ~= nil and
        typeof(current.ref) == 'function' and
        current.ref._stringRef == stringRef
      then
        return current.ref
      end
      local ref = function(value)
        local refs = inst.refs
        if refs == emptyRefsObject then
          -- This is a lazy pooled frozen object, so we need to initialize.
          inst.refs = {}
          refs = inst.refs
        end
        if value == nil then
          refs[stringRef] = nil
        else
          refs[stringRef] = value
        end
      end
      ref._stringRef = stringRef
      return ref
    else
      invariant(
        typeof(mixedRef) == 'string',
        'Expected ref to be a function, a string, an object returned by React.createRef(), or nil.'
      )
      invariant(
        element._owner,
        'Element ref was specified as a string (%s) but no owner was set. This could happen for one of' ..
          ' the following reasons:\n' ..
          '1. You may be adding a ref to a function component\n' ..
          "2. You may be adding a ref to a component that was not created inside a component's render method\n" ..
          '3. You have multiple copies of React loaded\n' ..
          'See https://reactjs.org/link/refs-must-have-owner for more information.',
        mixedRef
      )
    end
  end
  return mixedRef
end

local function throwOnInvalidObjectType(returnFiber: Fiber, newChild: { [any]: any })
  if returnFiber.type ~= "textarea" then
    -- ROBLOX FIXME: Need to adjust this to check for "table: <address>" instead
    -- and print appropriately
    unimplemented("throwOnInvalidObjectType textarea")

    -- ROBLOX TODO: This is likely a bigger deviation; in Roact today, we allow
    -- tables and use the keys as equivalents to the `key` prop
    -- invariant(
    --   false,
    --   "Objects are not valid as a React child (found: %s). " ..
    --     "If you meant to render a collection of children, use an array " ..
    --     "instead.",
    --   tostring(newChild) == "[object Object]"
    --     ? "object with keys {" + Object.keys(newChild).join(", ") + "}"
    --     : newChild,
    -- )
  end
end

local function warnOnFunctionType(returnFiber: Fiber)
  if _G.__DEV__ then
    local componentName = getComponentName(returnFiber.type) or "Component"

    if ownerHasFunctionTypeWarning[componentName] then
      return
    end
    ownerHasFunctionTypeWarning[componentName] = true

    console.error(
      "Functions are not valid as a React child. This may happen if " ..
        "you return a Component instead of <Component /> from render. " ..
        "Or maybe you meant to call this function rather than return it."
    )
  end
end


-- // We avoid inlining this to avoid potential deopts from using try/catch.
-- /** @noinline */
-- function resolveLazyType<T, P>(
--   lazyComponent: LazyComponent<T, P>
-- ): LazyComponent<T, P> | T
-- ROBLOX TODO: re-add types when ReactLazy exports LazyComponent
function resolveLazyType(
  lazyComponent
)
  local ok, _x = pcall(function()
    -- If we can, let's peek at the resulting type.
    local payload = lazyComponent._payload;
    local init = lazyComponent._init;
    return init(payload);
  end)
  if not ok then
    -- Leave it in place and let it throw again in the begin phase.
    return lazyComponent;
  end

  return _x
end

-- This wrapper function exists because I expect to clone the code in each path
-- to be able to optimize each path individually by branching early. This needs
-- a compiler or we can do it manually. Helpers that don't need this branching
-- live outside of this function.
local function ChildReconciler(shouldTrackSideEffects)
  local function deleteChild(returnFiber: Fiber, childToDelete: Fiber)
    if not shouldTrackSideEffects then
      -- Noop.
      return
    end
    local deletions = returnFiber.deletions
    if deletions == nil then
      returnFiber.deletions = { childToDelete }
      returnFiber.flags = bit32.bor(returnFiber.flags, Deletion)
    else
      table.insert(deletions, childToDelete)
    end
  end

  local function deleteRemainingChildren(
    returnFiber: Fiber,
    currentFirstChild: Fiber | nil
  )
    if not shouldTrackSideEffects then
      -- Noop.
      return nil
    end

    -- TODO: For the shouldClone case, this could be micro-optimized a bit by
    -- assuming that after the first child we've already added everything.
    local childToDelete = currentFirstChild
    while childToDelete ~= nil do
      deleteChild(returnFiber, childToDelete)
      childToDelete = childToDelete.sibling
    end
    return nil
  end

  local function mapRemainingChildren(
    returnFiber: Fiber,
    currentFirstChild: Fiber
  ): { [string | number]: Fiber }
    -- Add the remaining children to a temporary map so that we can find them by
    -- keys quickly. Implicit (null) keys get added to this set with their index
    -- instead.
    local existingChildren: { [string | number]: Fiber } = {}

    local existingChild = currentFirstChild
    while existingChild ~= nil do
      if existingChild.key ~= nil then
        existingChildren[existingChild.key] = existingChild
      else
        existingChildren[existingChild.index] = existingChild
      end
      existingChild = existingChild.sibling
    end
    return existingChildren
  end

  local function useFiber(fiber: Fiber, pendingProps: any): Fiber
    -- We currently set sibling to nil and index to 0 here because it is easy
    -- to forget to do before returning it. E.g. for the single child case.
    -- deviation: set index to 1 for 1-indexing
    local clone = createWorkInProgress(fiber, pendingProps)
    clone.index = 1
    clone.sibling = nil
    return clone
  end

  local function placeChild(
    newFiber: Fiber,
    lastPlacedIndex: number,
    newIndex: number
  ): number
    newFiber.index = newIndex
    if not shouldTrackSideEffects then
      -- Noop.
      return lastPlacedIndex
    end
    local current = newFiber.alternate
    if current ~= nil then
      local oldIndex = current.index
      if oldIndex < lastPlacedIndex then
        -- This is a move.
        newFiber.flags = Placement
        return lastPlacedIndex
      else
        -- This item can stay in place.
        return oldIndex
      end
    else
      -- This is an insertion.
      newFiber.flags = Placement
      return lastPlacedIndex
    end
  end

  local function placeSingleChild(newFiber: Fiber): Fiber
    -- This is simpler for the single child case. We only need to do a
    -- placement for inserting new children.
    if shouldTrackSideEffects and newFiber.alternate == nil then
      newFiber.flags = Placement
    end
    return newFiber
  end

  -- ROBLOX FIXME: Luau narrowing issue
  -- function updateTextNode(
  --   returnFiber: Fiber,
  --   current: Fiber | nil,
  --   textContent: string,
  --   lanes: Lanes
  -- )
  function updateTextNode(
    returnFiber: Fiber,
    current: any,
    textContent: string,
    lanes: Lanes
  )
    if current == nil or current.tag ~= HostText then
      -- Insert
      local created = createFiberFromText(textContent, returnFiber.mode, lanes)
      created.return_ = returnFiber
      return created
    else
      -- Update
      local existing = useFiber(current, textContent)
      existing.return_ = returnFiber
      return existing
    end
  end

  -- ROBLOX FIXME: type refinement
  -- local function updateElement(
  --   returnFiber: Fiber,
  --   current: Fiber | nil,
  --   element: ReactElement,
  --   lanes: Lanes
  -- ): Fiber
  local function updateElement(
    returnFiber: Fiber,
    current: any,
    element: ReactElement,
    lanes: Lanes
  ): Fiber
    if current ~= nil then
      if
        current.elementType == element.type or
        -- Keep this check inline so it only runs on the false path:
        (_G.__DEV__ and isCompatibleFamilyForHotReloading(current, element))
      then
        -- Move based on index
        local existing = useFiber(current, element.props)
        existing.ref = coerceRef(returnFiber, current, element)
        existing.return_ = returnFiber
        if _G.__DEV__ then
          existing._debugSource = element._source
          existing._debugOwner = element._owner
        end
        return existing
      elseif enableBlocksAPI and current.tag == Block then
        -- The new Block might not be initialized yet. We need to initialize
        -- it in case initializing it turns out it would match.
        local type = element.type
        if type["$$typeof"] == REACT_LAZY_TYPE then
          type = resolveLazyType(type)
        end
        if
          type["$$typeof"] == REACT_BLOCK_TYPE and
          type._render == current.type._render
        then
          -- Same as above but also update the .type field.
          local existing = useFiber(current, element.props)
          existing.return_ = returnFiber
          existing.type = type
          if _G.__DEV__ then
            existing._debugSource = element._source
            existing._debugOwner = element._owner
          end
          return existing
        end
      end
    end
    -- Insert
    local created = createFiberFromElement(element, returnFiber.mode, lanes)
    created.ref = coerceRef(returnFiber, current, element)
    created.return_ = returnFiber
    return created
  end


  -- ROBLOX FIXME: type narrowing.
  -- function updatePortal(
  --   returnFiber: Fiber,
  --   current: Fiber | nil,
  --   portal: ReactPortal,
  --   lanes: Lanes,
  -- ): Fiber {
  function updatePortal(
    returnFiber: Fiber,
    current: Fiber,
    portal: ReactPortal,
    lanes: Lanes
  ): Fiber
      if current == nil or
        current.tag ~= HostPortal or
        current.stateNode.containerInfo ~= portal.containerInfo or
        current.stateNode.implementation ~= portal.implementation
    then
      -- Insert
      local created = createFiberFromPortal(portal, returnFiber.mode, lanes)
      created.return_ = returnFiber
      return created
    else
      -- Update
      local existing = useFiber(current, portal.children or {})
      existing.return_ = returnFiber
      return existing
    end
  end

  -- function updateFragment(
  --   returnFiber: Fiber,
  --   current: Fiber | nil,
  --   fragment: Iterable<*>,
  --   lanes: Lanes,
  --   key: nil | string,
  -- ): Fiber {
    function updateFragment(
      returnFiber: Fiber,
      current: any,
      fragment: any,
      lanes: Lanes,
      key: nil | string
    ): Fiber
      if current == nil or current.tag ~= Fragment then
      -- Insert
      local created = createFiberFromFragment(
        fragment,
        returnFiber.mode,
        lanes,
        key
      )
      created.return_ = returnFiber
      return created
    else
      -- Update
      local existing = useFiber(current, fragment)
      existing.return_ = returnFiber
      return existing
    end
  end

  local function createChild(
    returnFiber: Fiber,
    newChild: any,
    lanes: Lanes
  ): Fiber | nil
    if typeof(newChild) == "string" or typeof(newChild) == "number" then
      -- Text nodes don't have keys. If the previous node is implicitly keyed
      -- we can continue to replace it without aborting even if it is not a text
      -- node.
      local created = createFiberFromText(
        tostring(newChild),
        returnFiber.mode,
        lanes
      )
      created.return_ = returnFiber
      return created
    end

    if typeof(newChild) == "table" and newChild ~= nil then
      if newChild["$$typeof"] == REACT_ELEMENT_TYPE then
        local created = createFiberFromElement(
          newChild,
          returnFiber.mode,
          lanes
        )
        created.ref = coerceRef(returnFiber, nil, newChild)
        created.return_ = returnFiber
        return created
      elseif newChild["$$typeof"] == REACT_PORTAL_TYPE then
        local created = createFiberFromPortal(
          newChild,
          returnFiber.mode,
          lanes
        )
        created.return_ = returnFiber
        return created
      elseif newChild["$$typeof"] == REACT_LAZY_TYPE then
        if enableLazyElements then
          local payload = newChild._payload
          local init = newChild._init
          return createChild(returnFiber, init(payload), lanes)
        end
      end

      if isArray(newChild) or getIteratorFn(newChild) then
        local created = createFiberFromFragment(
          newChild,
          returnFiber.mode,
          lanes,
          nil
        )
        created.return_ = returnFiber
        return created
      end

      throwOnInvalidObjectType(returnFiber, newChild)
    end

    if _G.__DEV__ then
      if typeof(newChild) == "function" then
        warnOnFunctionType(returnFiber)
      end
    end

    return nil
  end

  -- ROBLOX FIXME: type narrowing
  -- local function updateSlot(
  --   returnFiber: Fiber,
  --   oldFiber: Fiber | nil,
  --   newChild: any,
  --   lanes: Lanes
  -- ): Fiber | nil
  local function updateSlot(
    returnFiber: Fiber,
    oldFiber: Fiber,
    newChild: any,
    lanes: Lanes
  ): Fiber | nil
    -- Update the fiber if the keys match, otherwise return nil.

    local key = nil
    if oldFiber then
      key = oldFiber.key
    end

    if typeof(newChild) == "string" or typeof(newChild) == "number" then
      -- Text nodes don't have keys. If the previous node is implicitly keyed
      -- we can continue to replace it without aborting even if it is not a text
      -- node.
      if key ~= nil then
        return nil
      end
      return updateTextNode(returnFiber, oldFiber, tostring(newChild), lanes)
    end

    if typeof(newChild) == "table" and newChild ~= nil then
      if newChild["$$typeof"] == REACT_ELEMENT_TYPE then
        if newChild.key == key then
          if newChild.type == REACT_FRAGMENT_TYPE then
            return updateFragment(
              returnFiber,
              oldFiber,
              newChild.props.children,
              lanes,
              key
            )
          end
          return updateElement(returnFiber, oldFiber, newChild, lanes)
        else
          return nil
        end
      elseif newChild["$$typeof"] == REACT_PORTAL_TYPE then
        if newChild.key == key then
          return updatePortal(returnFiber, oldFiber, newChild, lanes)
        else
          return nil
        end
      elseif newChild["$$typeof"] == REACT_LAZY_TYPE then
        if enableLazyElements then
          local payload = newChild._payload
          local init = newChild._init
          return updateSlot(returnFiber, oldFiber, init(payload), lanes)
        end
      end

      if isArray(newChild) or getIteratorFn(newChild) then
        if key ~= nil then
          return nil
        end

        return updateFragment(returnFiber, oldFiber, newChild, lanes, nil)
      end

      throwOnInvalidObjectType(returnFiber, newChild)
    end

    if _G.__DEV__ then
      if typeof(newChild) == "function" then
        warnOnFunctionType(returnFiber)
      end
    end

    return nil
  end

  local function updateFromMap(
    existingChildren: { [string | number]: Fiber },
    returnFiber: Fiber,
    newIdx: number,
    newChild: any,
    lanes: Lanes
  ): Fiber | nil
    if typeof(newChild) == "string" or typeof(newChild) == "number" then
      -- Text nodes don't have keys, so we neither have to check the old nor
      -- new node for the key. If both are text nodes, they match.
      local matchedFiber = existingChildren[newIdx] or nil
      return updateTextNode(returnFiber, matchedFiber, tostring(newChild), lanes)
    end

    if typeof(newChild) == "table" and newChild ~= nil then
      if newChild["$$typeof"] == REACT_ELEMENT_TYPE then
        local matchedFiber =
          existingChildren[newChild.key == nil and newIdx or newChild.key]
        if newChild.type == REACT_FRAGMENT_TYPE then
          return updateFragment(
            returnFiber,
            matchedFiber,
            newChild.props.children,
            lanes,
            newChild.key
          )
        end
        return updateElement(returnFiber, matchedFiber, newChild, lanes)
      elseif newChild["$$typeof"] == REACT_PORTAL_TYPE then
        local matchedFiber =
          existingChildren[newChild.key == nil and newIdx or newChild.key]
        return updatePortal(returnFiber, matchedFiber, newChild, lanes)
      elseif newChild["$$typeof"] == REACT_LAZY_TYPE then
        if enableLazyElements then
          local payload = newChild._payload
          local init = newChild._init
          return updateFromMap(
            existingChildren,
            returnFiber,
            newIdx,
            init(payload),
            lanes
          )
        end
      end

      if isArray(newChild) or getIteratorFn(newChild) then
        local matchedFiber = existingChildren[newIdx]
        return updateFragment(returnFiber, matchedFiber, newChild, lanes, nil)
      end

      throwOnInvalidObjectType(returnFiber, newChild)
    end

    if _G.__DEV__ then
      if typeof(newChild) == "function" then
        warnOnFunctionType(returnFiber)
      end
    end

    return nil
  end

  --[[
    Warns if there is a duplicate or missing key
  ]]
  -- ROBLOX FIXME: Types
  -- local function warnOnInvalidKey(
  --   child: any,
  --   knownKeys: Set<string> | nil,
  --   returnFiber: Fiber
  -- ): Set<string> | nil
  local function warnOnInvalidKey(
    child: any,
    knownKeys: any,
    returnFiber: Fiber
  ): Set<string> | nil
    if _G.__DEV__ then
      if typeof(child) ~= "table" or child == nil then
        return knownKeys
      end
      if child["$$typeof"] == REACT_ELEMENT_TYPE or child["$$typeof"] == REACT_PORTAL_TYPE then
        warnForMissingKey(child, returnFiber)
        local key = child.key
        if typeof(key) ~= "string" then
          -- break
        elseif knownKeys == nil then
          knownKeys = {}
          knownKeys[key] = true
        elseif not knownKeys[key] then
          knownKeys[key] = true
        else
          console.error(
            "Encountered two children with the same key, `%s`. " ..
              "Keys should be unique so that components maintain their identity " ..
              "across updates. Non-unique keys may cause children to be " ..
              "duplicated and/or omitted — the behavior is unsupported and " ..
              "could change in a future version.",
            key
          )
        end
      elseif child["$$typeof"] == REACT_LAZY_TYPE then
        if enableLazyElements then
          local payload = child._payload
          local init = child._init
          warnOnInvalidKey(init(payload), knownKeys, returnFiber)
        end
      end
    end
    return knownKeys
  end

  local function reconcileChildrenArray(
    returnFiber: Fiber,
    currentFirstChild: Fiber | nil,
    newChildren: Array<any>,
    lanes: Lanes
  ): Fiber | nil
    -- This algorithm can't optimize by searching from both ends since we
    -- don't have backpointers on fibers. I'm trying to see how far we can get
    -- with that model. If it ends up not being worth the tradeoffs, we can
    -- add it later.

    -- Even with a two ended optimization, we'd want to optimize for the case
    -- where there are few changes and brute force the comparison instead of
    -- going for the Map. It'd like to explore hitting that path first in
    -- forward-only mode and only go for the Map once we notice that we need
    -- lots of look ahead. This doesn't handle reversal as well as two ended
    -- search but that's unusual. Besides, for the two ended optimization to
    -- work on Iterables, we'd need to copy the whole set.

    -- In this first iteration, we'll just live with hitting the bad case
    -- (adding everything to a Map) in for every insert/move.

    -- If you change this code, also update reconcileChildrenIterator() which
    -- uses the same algorithm.

    if _G.__DEV__ then
      -- First, validate keys.
      local knownKeys = nil
      for i, child in ipairs(newChildren) do
        knownKeys = warnOnInvalidKey(child, knownKeys, returnFiber)
      end
    end

    -- ROBLOX FIXME: type narrowing
    -- local resultingFirstChild: Fiber | nil = nil
    -- local previousNewFiber: Fiber | nil = nil
    local resultingFirstChild: any = nil
    local previousNewFiber: any = nil

    local oldFiber = currentFirstChild
    local lastPlacedIndex = 1
    local newIdx = 1
    local nextOldFiber = nil
    -- deviation: use while loop in place of modified for loop
    while oldFiber ~= nil and newIdx <= #newChildren do
      if oldFiber.index > newIdx then
        nextOldFiber = oldFiber
        oldFiber = nil
      else
        nextOldFiber = oldFiber.sibling
      end
      local newFiber = updateSlot(
        returnFiber,
        oldFiber,
        newChildren[newIdx],
        lanes
      )
      if newFiber == nil then
        -- TODO: This breaks on empty slots like nil children. That's
        -- unfortunate because it triggers the slow path all the time. We need
        -- a better way to communicate whether this was a miss or nil,
        -- boolean, undefined, etc.
        if oldFiber == nil then
          oldFiber = nextOldFiber
        end
        break
      end
      if shouldTrackSideEffects then
        if oldFiber and newFiber.alternate == nil then
          -- We matched the slot, but we didn't reuse the existing fiber, so we
          -- need to delete the existing child.
          deleteChild(returnFiber, oldFiber)
        end
      end
      lastPlacedIndex = placeChild(newFiber, lastPlacedIndex, newIdx)
      if previousNewFiber == nil then
        -- TODO: Move out of the loop. This only happens for the first run.
        resultingFirstChild = newFiber
      else
        -- TODO: Defer siblings if we're not at the right index for this slot.
        -- I.e. if we had nil values before, then we want to defer this
        -- for each nil value. However, we also don't want to call updateSlot
        -- with the previous one.
        previousNewFiber.sibling = newFiber
      end
      previousNewFiber = newFiber
      oldFiber = nextOldFiber
      -- deviation: increment manually since we're not using a modified for loop
      newIdx += 1
    end

    if newIdx > #newChildren then
      -- We've reached the end of the new children. We can delete the rest.
      deleteRemainingChildren(returnFiber, oldFiber)
      return resultingFirstChild
    end

    if oldFiber == nil then
      -- If we don't have any more existing children we can choose a fast path
      -- since the rest will all be insertions.
      -- deviation: use while loop in place of modified for loop
      while newIdx <= #newChildren do
        local newFiber = createChild(returnFiber, newChildren[newIdx], lanes)
        if newFiber == nil then
          -- deviation: increment manually since we're not using a modified for loop
          newIdx += 1;
          continue
        end
        lastPlacedIndex = placeChild(newFiber, lastPlacedIndex, newIdx)
        if previousNewFiber == nil then
          -- TODO: Move out of the loop. This only happens for the first run.
          resultingFirstChild = newFiber
        else
          previousNewFiber.sibling = newFiber
        end
        previousNewFiber = newFiber
        -- deviation: increment manually since we're not using a modified for loop
        newIdx += 1;
      end
      return resultingFirstChild
    end

    -- Add all children to a key map for quick lookups.
    local existingChildren = mapRemainingChildren(returnFiber, oldFiber)
    -- Keep scanning and use the map to restore deleted items as moves.
    -- deviation: use while loop in place of modified for loop
    while newIdx <= #newChildren do
      local newFiber = updateFromMap(
        existingChildren,
        returnFiber,
        newIdx,
        newChildren[newIdx],
        lanes
      )
      if newFiber ~= nil then
        if shouldTrackSideEffects then
          if newFiber.alternate ~= nil then
            -- The new fiber is a work in progress, but if there exists a
            -- current, that means that we reused the fiber. We need to delete
            -- it from the child list so that we don't add it to the deletion
            -- list.
            -- deviation: Split out ternary into safer/more readable logic
            local key = newFiber.key == nil and newIdx or newFiber.key
            existingChildren[key] = nil
          end
        end
        lastPlacedIndex = placeChild(newFiber, lastPlacedIndex, newIdx)
        if previousNewFiber == nil then
          resultingFirstChild = newFiber
        else
          previousNewFiber.sibling = newFiber
        end
        previousNewFiber = newFiber
      end
      -- deviation: increment manually since we're not using a modified for loop
      newIdx += 1
    end

    if shouldTrackSideEffects then
      -- Any existing children that weren't consumed above were deleted. We need
      -- to add them to the deletion list.
      for _, child in pairs(existingChildren) do
        deleteChild(returnFiber, child)
      end
    end

    return resultingFirstChild
  end

  -- function reconcileChildrenIterator(
  --   returnFiber: Fiber,
  --   currentFirstChild: Fiber | nil,
  --   newChildrenIterable: Iterable<*>,
  --   lanes: Lanes,
  -- ): Fiber | nil
  function reconcileChildrenIterator(
    returnFiber: Fiber,
    currentFirstChild: Fiber | nil,
    newChildrenIterable: any,
    lanes: Lanes
  ): Fiber | nil
    -- This is the same implementation as reconcileChildrenArray(),
    -- but using the iterator instead.

    local iteratorFn = getIteratorFn(newChildrenIterable)
    invariant(
      typeof(iteratorFn) == 'function',
      'An object is not an iterable. This error is likely caused by a bug in ' ..
        'React. Please file an issue.'
    )

    if _G.__DEV__ then
      -- We don't support rendering Generators because it's a mutation.
      -- See https://github.com/facebook/react/issues/12995
      -- ROBLOX deviation: Lua doesn't have built-in generators
      -- if
      --   typeof(Symbol) == 'function' and
      --   -- $FlowFixMe Flow doesn't know about toStringTag
      --   newChildrenIterable[Symbol.toStringTag] == 'Generator'
      -- then
      --   if not didWarnAboutGenerators then
      --     console.error(
      --       'Using Generators as children is unsupported and will likely yield ' ..
      --         'unexpected results because enumerating a generator mutates it. ' ..
      --         'You may convert it to an array with `Array.from()` or the ' ..
      --         '`[...spread]` operator before rendering. Keep in mind ' ..
      --         'you might need to polyfill these features for older browsers.'
      --     )
      --   end
      --   didWarnAboutGenerators = true
      -- end

      -- Warn about using Maps as children
      if newChildrenIterable.entries == iteratorFn then
        if not didWarnAboutMaps then
          console.error(
            'Using Maps as children is not supported. ' ..
              'Use an array of keyed ReactElements instead.'
          )
        end
        didWarnAboutMaps = true
      end

      -- First, validate keys.
      -- We'll get a different iterator later for the main pass.
      local newChildren = iteratorFn(newChildrenIterable)
      if newChildren then
        local knownKeys = nil
        local step = newChildren.next()
        while not step.done do
          step = newChildren.next()
          local child = step.value
          knownKeys = warnOnInvalidKey(child, knownKeys, returnFiber)
        end
      end
    end

    local newChildren = iteratorFn(newChildrenIterable)
    invariant(newChildren ~= nil, 'An iterable object provided no iterator.')

    local resultingFirstChild: Fiber | nil = nil
    local previousNewFiber: Fiber = nil

    local oldFiber = currentFirstChild
    local lastPlacedIndex = 1
    local newIdx = 1
    local nextOldFiber = nil

    local step = newChildren.next()
    while oldFiber ~= nil and not step.done do
      if oldFiber.index > newIdx then
        nextOldFiber = oldFiber
        oldFiber = nil
      else
        nextOldFiber = oldFiber.sibling
      end
      local newFiber = updateSlot(returnFiber, oldFiber, step.value, lanes)
      if newFiber == nil then
        -- TODO: This breaks on empty slots like nil children. That's
        -- unfortunate because it triggers the slow path all the time. We need
        -- a better way to communicate whether this was a miss or nil,
        -- boolean, undefined, etc.
        if oldFiber == nil then
          oldFiber = nextOldFiber
        end
        break
      end
      if shouldTrackSideEffects then
        if oldFiber and newFiber.alternate == nil then
          -- We matched the slot, but we didn't reuse the existing fiber, so we
          -- need to delete the existing child.
          deleteChild(returnFiber, oldFiber)
        end
      end
      lastPlacedIndex = placeChild(newFiber, lastPlacedIndex, newIdx)
      if previousNewFiber == nil then
        -- TODO: Move out of the loop. This only happens for the first run.
        resultingFirstChild = newFiber
      else
        -- TODO: Defer siblings if we're not at the right index for this slot.
        -- I.e. if we had nil values before, then we want to defer this
        -- for each nil value. However, we also don't want to call updateSlot
        -- with the previous one.
        previousNewFiber.sibling = newFiber
      end
      previousNewFiber = newFiber
      oldFiber = nextOldFiber

      newIdx += 1
      step = newChildren.next()
    end

    if step.done then
      -- We've reached the end of the new children. We can delete the rest.
      deleteRemainingChildren(returnFiber, oldFiber)
      return resultingFirstChild
    end

    if oldFiber == nil then
      -- If we don't have any more existing children we can choose a fast path
      -- since the rest will all be insertions.
      while not step.done do
        local newFiber = createChild(returnFiber, step.value, lanes)
        if newFiber == nil then
          continue
        end
        lastPlacedIndex = placeChild(newFiber, lastPlacedIndex, newIdx)
        if previousNewFiber == nil then
          -- TODO: Move out of the loop. This only happens for the first run.
          resultingFirstChild = newFiber
        else
          previousNewFiber.sibling = newFiber
        end
        previousNewFiber = newFiber

        newIdx += 1
        step = newChildren.next()
      end
      return resultingFirstChild
    end

    -- Add all children to a key map for quick lookups.
    local existingChildren = mapRemainingChildren(returnFiber, oldFiber)

    -- Keep scanning and use the map to restore deleted items as moves.
    while not step.done do
      local newFiber = updateFromMap(
        existingChildren,
        returnFiber,
        newIdx,
        step.value,
        lanes
      )
      if newFiber ~= nil then
        if shouldTrackSideEffects then
          if newFiber.alternate ~= nil then
            -- The new fiber is a work in progress, but if there exists a
            -- current, that means that we reused the fiber. We need to delete
            -- it from the child list so that we don't add it to the deletion
            -- list.
            if newFiber.key == nil then
              existingChildren.delete(newIdx)
            else
              existingChildren.delete(newFiber.key)
            end
          end
        end
        lastPlacedIndex = placeChild(newFiber, lastPlacedIndex, newIdx)
        if previousNewFiber == nil then
          resultingFirstChild = newFiber
        else
          previousNewFiber.sibling = newFiber
        end
        previousNewFiber = newFiber
      end

      newIdx += 1
      step = newChildren.next()
    end

    if shouldTrackSideEffects then
      -- Any existing children that weren't consumed above were deleted. We need
      -- to add them to the deletion list.
      for _, child in pairs(existingChildren) do
        deleteChild(returnFiber, child)
      end
    end

    return resultingFirstChild
  end

  -- ROBLOX FIXME: Luau narrowing issue
  -- currentFirstChild: Fiber | nil,
  function reconcileSingleTextNode(
    returnFiber: Fiber,
    currentFirstChild: Fiber,
    textContent: string,
    lanes: Lanes
  ): Fiber
    -- There's no need to check for keys on text nodes since we don't have a
    -- way to define them.
    if currentFirstChild ~= nil and currentFirstChild.tag == HostText then
      -- We already have an existing node so let's just update it and delete
      -- the rest.
      deleteRemainingChildren(returnFiber, currentFirstChild.sibling)
      local existing = useFiber(currentFirstChild, textContent)
      existing.return_ = returnFiber
      return existing
    end
    -- The existing first child is not a text node so we need to create one
    -- and delete the existing ones.
    deleteRemainingChildren(returnFiber, currentFirstChild)
    local created = createFiberFromText(textContent, returnFiber.mode, lanes)
    created.return_ = returnFiber
    return created
  end

  local function reconcileSingleElement(
    returnFiber: Fiber,
    currentFirstChild: Fiber | nil,
    element: ReactElement,
    lanes: Lanes
  ): Fiber
    local key = element.key
    local child = currentFirstChild
    while child ~= nil do
      -- TODO: If key == nil and child.key == nil, then this only applies to
      -- the first item in the list.
      if child.key == key then
        if child.tag == Fragment then
          if element.type == REACT_FRAGMENT_TYPE then
            deleteRemainingChildren(returnFiber, child.sibling)
            local existing = useFiber(child, element.props.children)
            existing.return_ = returnFiber
            if _G.__DEV__ then
              existing._debugSource = element._source
              existing._debugOwner = element._owner
            end
            return existing
          end
        elseif child.tag == Block then
          unimplemented("reconcileSingleElement: Block")
          -- if (enableBlocksAPI) {
          --   let type = element.type;
          --   if (type.$$typeof === REACT_LAZY_TYPE) {
          --     type = resolveLazyType(type);
          --   }
          --   if (type.$$typeof === REACT_BLOCK_TYPE) {
          --     // The new Block might not be initialized yet. We need to initialize
          --     // it in case initializing it turns out it would match.
          --     if (
          --       ((type: any): BlockComponent<any, any>)._render ===
          --       (child.type: BlockComponent<any, any>)._render
          --     ) {
          --       deleteRemainingChildren(returnFiber, child.sibling);
          --       const existing = useFiber(child, element.props);
          --       existing.type = type;
          --       existing.return = returnFiber;
          --       if (__DEV__) {
          --         existing._debugSource = element._source;
          --         existing._debugOwner = element._owner;
          --       }
          --       return existing;
          --     }
          --   }
          -- }
          -- // We intentionally fallthrough here if enableBlocksAPI is not on.
          -- // eslint-disable-next-lined no-fallthrough
        else
          if
            child.elementType == element.type or
            -- Keep this check inline so it only runs on the false path:
            (_G.__DEV__ and isCompatibleFamilyForHotReloading(child, element))
          then
            deleteRemainingChildren(returnFiber, child.sibling)
            local existing = useFiber(child, element.props)
            existing.ref = coerceRef(returnFiber, child, element)
            existing.return_ = returnFiber
            if _G.__DEV__ then
              existing._debugSource = element._source
              existing._debugOwner = element._owner
            end
            return existing
          end
          break
        end
        -- Didn't match.
        deleteRemainingChildren(returnFiber, child)
      else
        deleteChild(returnFiber, child)
      end
      child = child.sibling
    end

    if element.type == REACT_FRAGMENT_TYPE then
      local created = createFiberFromFragment(
        element.props.children,
        returnFiber.mode,
        lanes,
        element.key
      )
      created.return_ = returnFiber
      return created
    else
      local created = createFiberFromElement(element, returnFiber.mode, lanes)
      created.ref = coerceRef(returnFiber, currentFirstChild, element)
      created.return_ = returnFiber
      return created
    end
  end

  -- ROBLOX TODO: Luau narrowing
  -- function reconcileSinglePortal(
  --   returnFiber: Fiber,
  --   currentFirstChild: Fiber | nil,
  --   portal: ReactPortal,
  --   lanes: Lanes,
  -- ): Fiber
  function reconcileSinglePortal(
    returnFiber: Fiber,
    currentFirstChild: Fiber,
    portal: ReactPortal,
    lanes: Lanes
  ): Fiber
    local key = portal.key
    local child = currentFirstChild
    while child ~= nil do
      -- TODO: If key == nil and child.key == nil, then this only applies to
      -- the first item in the list.
      if child.key == key then
        if
          child.tag == HostPortal and
          child.stateNode.containerInfo == portal.containerInfo and
          child.stateNode.implementation == portal.implementation
        then
          deleteRemainingChildren(returnFiber, child.sibling)
          local existing = useFiber(child, portal.children or {})
          existing.return_ = returnFiber
          return existing
        else
          deleteRemainingChildren(returnFiber, child)
          break
        end
      else
        deleteChild(returnFiber, child)
      end
      child = child.sibling
    end

    local created = createFiberFromPortal(portal, returnFiber.mode, lanes)
    created.return_ = returnFiber
    return created
  end

  -- This API will tag the children with the side-effect of the reconciliation
  -- itself. They will be added to the side-effect list as we pass through the
  -- children and the parent.
  -- ROBLOX FIXME: Luau narrowing issue
  -- currentFirstChild: Fiber?,
  local function reconcileChildFibers(
    returnFiber: Fiber,
    currentFirstChild: Fiber,
    newChild: any,
    lanes: Lanes
  ): Fiber?
    -- This function is not recursive.
    -- If the top level item is an array, we treat it as a set of children,
    -- not as a fragment. Nested arrays on the other hand will be treated as
    -- fragment nodes. Recursion happens at the normal flow.

    -- Handle top level unkeyed fragments as if they were arrays.
    -- This leads to an ambiguity between <>{[...]}</> and <>...</>.
    -- We treat the ambiguous cases above the same.
    local isUnkeyedTopLevelFragment =
      typeof(newChild) == "table" and
      newChild.type == REACT_FRAGMENT_TYPE and
      newChild.key == nil
    if isUnkeyedTopLevelFragment then
      newChild = newChild.props.children
    end

    -- Handle object types
    local isObject = typeof(newChild) == "table" and newChild ~= nil

    if isObject then
      if newChild["$$typeof"] == REACT_ELEMENT_TYPE then
        return placeSingleChild(
          reconcileSingleElement(
            returnFiber,
            currentFirstChild,
            newChild,
            lanes
          )
        )
      elseif newChild["$$typeof"] == REACT_PORTAL_TYPE then
        return placeSingleChild(
          reconcileSinglePortal(
            returnFiber,
            currentFirstChild,
            newChild,
            lanes
          )
        )
      elseif newChild["$$typeof"] == REACT_LAZY_TYPE then
        if enableLazyElements then
          local payload = newChild._payload
          local init = newChild._init
          -- TODO: This function is supposed to be non-recursive.
          return reconcileChildFibers(
            returnFiber,
            currentFirstChild,
            init(payload),
            lanes
          )
        end
      end
    end

    if typeof(newChild) == "string" or typeof(newChild) == "number" then
      return placeSingleChild(
        reconcileSingleTextNode(
          returnFiber,
          currentFirstChild,
          "" .. newChild,
          lanes
        )
      )
    end

    if isArray(newChild) then
      return reconcileChildrenArray(
        returnFiber,
        currentFirstChild,
        newChild,
        lanes
      )
    end

    if getIteratorFn(newChild) then
      return reconcileChildrenIterator(
        returnFiber,
        currentFirstChild,
        newChild,
        lanes
      )
    end

    if isObject then
      unimplemented("throwOnInvalidObjectType")
      -- throwOnInvalidObjectType(returnFiber, newChild)
    end

    if _G.__DEV__ then
      if typeof(newChild) == "function" then
        warnOnFunctionType(returnFiber)
      end
    end
    if typeof(newChild) == "nil" and not isUnkeyedTopLevelFragment then
      -- deviation: need a flag here to simulate switch/case fallthrough + break
      local shouldFallThrough = false
      -- If the new child is undefined, and the return fiber is a composite
      -- component, throw an error. If Fiber return types are disabled,
      -- we already threw above.
      if returnFiber.tag == ClassComponent then
        if _G.__DEV__ then
          -- ROBLOX TODO: Make this logic compatible with however we expect
          -- mocked functions to work. With coercion of no returns to `nil`, it
          -- may not even be necessary to special case this scenario

          -- deviation: This won't work with Lua functions
          -- local instance = returnFiber.stateNode
          -- if instance.render._isMockFunction then
          --   -- We allow auto-mocks to proceed as if they're returning nil.
          --   shouldFallThrough = true
          -- end
        end
      end
      -- Intentionally fall through to the next case, which handles both
      -- functions and classes
      -- eslint-disable-next-lined no-fallthrough
      if
        shouldFallThrough and
        (returnFiber.tag == ClassComponent
        or returnFiber.tag == FunctionComponent
        or returnFiber.tag == ForwardRef
        or returnFiber.tag == SimpleMemoComponent)
      then
        invariant(
          false,
          "%s(...): Nothing was returned from render. This usually means a " ..
            "return statement is missing. Or, to render nothing, " ..
            "return nil.",
          getComponentName(returnFiber.type) or "Component"
        )
      end
    end

    -- Remaining cases are all treated as empty.
    return deleteRemainingChildren(returnFiber, currentFirstChild)
  end

  return reconcileChildFibers
end

exports.reconcileChildFibers = ChildReconciler(true)
exports.mountChildFibers = ChildReconciler(false)

-- FIXME (roblox): better type refinement
-- exports.cloneChildFibers = function(
--   current: Fiber | nil
--   workInProgress: Fiber
-- )
exports.cloneChildFibers = function(
  current,
  workInProgress: Fiber
)
  invariant(
    current == nil or workInProgress.child == current.child,
    "Resuming work not yet implemented."
  )

  if workInProgress.child == nil then
    return
  end

  local currentChild = workInProgress.child
  local newChild = createWorkInProgress(currentChild, currentChild.pendingProps)
  workInProgress.child = newChild

  newChild.return_ = workInProgress
  while currentChild.sibling ~= nil do
    currentChild = currentChild.sibling
    newChild = createWorkInProgress(
      currentChild,
      currentChild.pendingProps
    )
    newChild.sibling = newChild
    newChild.return_ = workInProgress
  end
  newChild.sibling = nil
end

-- -- Reset a workInProgress child set to prepare it for a second pass.
-- exports.resetChildFibers(workInProgress: Fiber, lanes: Lanes): void {
--   local child = workInProgress.child
--   while (child ~= nil then
--     resetWorkInProgress(child, lanes)
--     child = child.sibling
--   end
-- end

return exports