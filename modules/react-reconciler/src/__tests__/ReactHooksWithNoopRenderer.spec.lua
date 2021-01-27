-- upstream: https://github.com/facebook/react/blob/99cae887f3a8bde760a111516d254c1225242edf/packages/react-reconciler/src/__tests__/ReactHooksWithNoopRenderer-test.js
--[[*
 * Copyright (c) Facebook, Inc. and its affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 *
 * @emails react-core
 * @jest-environment node
]]

--[[ eslint-disable no-func-assign ]]
local Workspace = script.Parent.Parent.Parent
local React
-- local textCache
-- local readText
-- local resolveText
local ReactNoop
local Scheduler
-- local SchedulerTracing
-- local Suspense
local useState
-- local useReducer
local useEffect
local useLayoutEffect
-- local useCallback
-- local useMemo
-- local useRef
local useImperativeHandle
-- local useTransition
-- local useDeferredValue
local forwardRef
-- local memo
local act

return function()
  local RobloxJest = require(Workspace.RobloxJest)

  beforeEach(function()
    RobloxJest.resetModules()
    RobloxJest.useFakeTimers()
    -- deviation: In react, jest _always_ mocks Scheduler -> unstable_mock;
    -- in our case, we need to do it anywhere we want to use the scheduler,
    -- until we have some form of bundling logic
    RobloxJest.mock(Workspace.Scheduler, function()
      return require(Workspace.Scheduler.unstable_mock)
    end)

    React = require(Workspace.React)
    ReactNoop = require(Workspace.ReactNoopRenderer)
    Scheduler = require(Workspace.Scheduler)
  --   SchedulerTracing = require('scheduler/tracing')
    useState = React.useState
    -- useReducer = React.useReducer
    useEffect = React.useEffect
    useLayoutEffect = React.useLayoutEffect
    -- useCallback = React.useCallback
    -- useMemo = React.useMemo
    -- useRef = React.useRef
    useImperativeHandle = React.useImperativeHandle
    forwardRef = React.forwardRef
    -- memo = React.memo
  --   useTransition = React.unstable_useTransition
  --   useDeferredValue = React.unstable_useDeferredValue
  --   Suspense = React.Suspense
    act = ReactNoop.act

  --   textCache = new Map()

  --   readText = text => {
  --     local record = textCache.get(text)
  --     if record ~= undefined)
  --       switch (record.status)
  --         case 'pending':
  --           throw record.promise
  --         case 'rejected':
  --           throw Error('Failed to load: ' + text)
  --         case 'resolved':
  --           return text
  --       end
  --     } else {
  --       local ping
  --       local promise = new Promise(resolve => (ping = resolve))
  --       local newRecord = {
  --         status: 'pending',
  --         ping: ping,
  --         promise,
  --       end
  --       textCache.set(text, newRecord)
  --       throw promise
  --     end
  --   end

  --   resolveText = text => {
  --     local record = textCache.get(text)
  --     if record ~= undefined)
  --       if record.status == 'pending')
  --         Scheduler.unstable_yieldValue(`Promise resolved [${text}]`)
  --         record.ping()
  --         record.ping = nil
  --         record.status = 'resolved'
  --         clearTimeout(record.promise._timer)
  --         record.promise = nil
  --       end
  --     } else {
  --       local newRecord = {
  --         ping: nil,
  --         status: 'resolved',
  --         promise: nil,
  --       end
  --       textCache.set(text, newRecord)
  --     end
  --   end
  end)

  local function span(prop)
    return {type = "span", hidden = false, children = {}, prop = prop}
  end

  function Text(props)
    Scheduler.unstable_yieldValue(props.text)
    return React.createElement("span", {
      prop = props.text
    })
  end

  -- function AsyncText(props)
  --   local text = props.text
  --   try {
  --     readText(text)
  --     Scheduler.unstable_yieldValue(text)
  --     return <span prop={text} />
  --   } catch (promise)
  --     if typeof promise.then == 'function')
  --       Scheduler.unstable_yieldValue(`Suspend! [${text}]`)
  --       if typeof props.ms == 'number' and promise._timer == undefined)
  --         promise._timer = setTimeout(function()
  --           resolveText(text)
  --         }, props.ms)
  --       end
  --     } else {
  --       Scheduler.unstable_yieldValue(`Error! [${text}]`)
  --     end
  --     throw promise
  --   end
  -- end

  -- function advanceTimers(ms)
  --   -- Note: This advances Jest's virtual time but not React's. Use
  --   -- ReactNoop.expire for that.
  --   if typeof ms ~= 'number')
  --     throw new Error('Must specify ms')
  --   end
  --   jest.advanceTimersByTime(ms)
  --   -- Wait until the end of the current tick
  --   -- We cannot use a timer since we're faking them
  --   return Promise.resolve().then(function()})
  -- end

  xit('resumes after an interruption', function()
    -- FIXME: type of expect
    local expect: any = expect

    local function Counter(props, ref)
      local count, updateCount = useState(0)
      useImperativeHandle(ref, function() return {updateCount} end)
      return React.createElement("Text", nil, tostring(props.label) .. ': ' .. count)
    end
    Counter = forwardRef(Counter)

    -- Initial mount
    local counter = React.createRef(nil)
    ReactNoop.render(React.createElement("Counter",
      {label="Count", ref=counter}
    ))
    expect(Scheduler).toFlushAndYield({'Count: 0'})
    expect(ReactNoop.getChildren()).toEqual({span('Count: 0')})

    -- Schedule some updates
    ReactNoop.batchedUpdates(function()
      counter.current.updateCount(1)
      counter.current.updateCount(
        function(count: number)
          return count + 10
        end)
    end)

    -- Partially flush without committing
    expect(Scheduler).toFlushAndYieldThrough({'Count: 11'})
    expect(ReactNoop.getChildren()).toEqual({span('Count: 0')})

    -- Interrupt with a high priority update
    ReactNoop.flushSync(function()
      ReactNoop.render(React.createElement(
        "Counter",
        {label="Total"}
      ))
    end)
    expect(Scheduler).toHaveYielded({'Total: 0'})

    -- Resume rendering
    expect(Scheduler).toFlushAndYield({'Total: 11'})
    expect(ReactNoop.getChildren()).toEqual({span('Total: 11')})
  end)

  -- it('throws inside class components', function()
  --   class BadCounter extends React.Component {
  --     render()
  --       local [count] = useState(0)
  --       return <Text text={this.props.label + ': ' + count} />
  --     end
  --   end
  --   ReactNoop.render(<BadCounter />)

  --   expect(Scheduler).toFlushAndThrow(
  --     'Invalid hook call. Hooks can only be called inside of the body of a function component. This could happen for' +
  --       ' one of the following reasons:\n' +
  --       '1. You might have mismatching versions of React and the renderer (such as React DOM)\n' +
  --       '2. You might be breaking the Rules of Hooks\n' +
  --       '3. You might have more than one copy of React in the same app\n' +
  --       'See https:--reactjs.org/link/invalid-hook-call for tips about how to debug and fix this problem.',
  --   )

  --   -- Confirm that a subsequent hook works properly.
  --   function GoodCounter(props, ref)
  --     local [count] = useState(props.initialCount)
  --     return <Text text={count} />
  --   end
  --   ReactNoop.render(<GoodCounter initialCount={10} />)
  --   expect(Scheduler).toFlushAndYield([10])
  -- })

  -- if !require('shared/ReactFeatureFlags').disableModulePatternComponents)
  --   it('throws inside module-style components', function()
  --     function Counter()
  --       return {
  --         render()
  --           local [count] = useState(0)
  --           return <Text text={this.props.label + ': ' + count} />
  --         },
  --       end
  --     end
  --     ReactNoop.render(<Counter />)
  --     expect(function()
  --       expect(Scheduler).toFlushAndThrow(
  --         'Invalid hook call. Hooks can only be called inside of the body of a function component. This could happen ' +
  --           'for one of the following reasons:\n' +
  --           '1. You might have mismatching versions of React and the renderer (such as React DOM)\n' +
  --           '2. You might be breaking the Rules of Hooks\n' +
  --           '3. You might have more than one copy of React in the same app\n' +
  --           'See https:--reactjs.org/link/invalid-hook-call for tips about how to debug and fix this problem.',
  --       ),
  --     ).toErrorDev(
  --       'Warning: The <Counter /> component appears to be a function component that returns a class instance. ' +
  --         'Change Counter to a class that extends React.Component instead. ' +
  --         "If you can't use a class try assigning the prototype on the function as a workaround. " +
  --         '`Counter.prototype = React.Component.prototype`. ' +
  --         "Don't use an arrow function since it cannot be called with `new` by React.",
  --     )

  --     -- Confirm that a subsequent hook works properly.
  --     function GoodCounter(props)
  --       local [count] = useState(props.initialCount)
  --       return <Text text={count} />
  --     end
  --     ReactNoop.render(<GoodCounter initialCount={10} />)
  --     expect(Scheduler).toFlushAndYield([10])
  --   })
  -- end

  -- it('throws when called outside the render phase', function()
  --   expect(function() useState(0)).toThrow(
  --     'Invalid hook call. Hooks can only be called inside of the body of a function component. This could happen for' +
  --       ' one of the following reasons:\n' +
  --       '1. You might have mismatching versions of React and the renderer (such as React DOM)\n' +
  --       '2. You might be breaking the Rules of Hooks\n' +
  --       '3. You might have more than one copy of React in the same app\n' +
  --       'See https:--reactjs.org/link/invalid-hook-call for tips about how to debug and fix this problem.',
  --   )
  -- })

  -- describe('useState', function()
  --   it('simple mount and update', function()
  --     function Counter(props, ref)
  --       local [count, updateCount] = useState(0)
  --       useImperativeHandle(ref, function() ({updateCount}))
  --       return <Text text={'Count: ' + count} />
  --     end
  --     Counter = forwardRef(Counter)
  --     local counter = React.createRef(null)
  --     ReactNoop.render(<Counter ref={counter} />)
  --     expect(Scheduler).toFlushAndYield(['Count: 0'])
  --     expect(ReactNoop.getChildren()).toEqual([span('Count: 0')])

  --     act(function() counter.current.updateCount(1))
  --     expect(Scheduler).toHaveYielded(['Count: 1'])
  --     expect(ReactNoop.getChildren()).toEqual([span('Count: 1')])

  --     act(function() counter.current.updateCount(count => count + 10))
  --     expect(Scheduler).toHaveYielded(['Count: 11'])
  --     expect(ReactNoop.getChildren()).toEqual([span('Count: 11')])
  --   })

  --   it('lazy state initializer', function()
  --     function Counter(props, ref)
  --       local [count, updateCount] = useState(function()
  --         Scheduler.unstable_yieldValue('getInitialState')
  --         return props.initialState
  --       })
  --       useImperativeHandle(ref, function() ({updateCount}))
  --       return <Text text={'Count: ' + count} />
  --     end
  --     Counter = forwardRef(Counter)
  --     local counter = React.createRef(null)
  --     ReactNoop.render(<Counter initialState={42} ref={counter} />)
  --     expect(Scheduler).toFlushAndYield(['getInitialState', 'Count: 42'])
  --     expect(ReactNoop.getChildren()).toEqual([span('Count: 42')])

  --     act(function() counter.current.updateCount(7))
  --     expect(Scheduler).toHaveYielded(['Count: 7'])
  --     expect(ReactNoop.getChildren()).toEqual([span('Count: 7')])
  --   })

  --   it('multiple states', function()
  --     function Counter(props, ref)
  --       local [count, updateCount] = useState(0)
  --       local [label, updateLabel] = useState('Count')
  --       useImperativeHandle(ref, function() ({updateCount, updateLabel}))
  --       return <Text text={label + ': ' + count} />
  --     end
  --     Counter = forwardRef(Counter)
  --     local counter = React.createRef(null)
  --     ReactNoop.render(<Counter ref={counter} />)
  --     expect(Scheduler).toFlushAndYield(['Count: 0'])
  --     expect(ReactNoop.getChildren()).toEqual([span('Count: 0')])

  --     act(function() counter.current.updateCount(7))
  --     expect(Scheduler).toHaveYielded(['Count: 7'])

  --     act(function() counter.current.updateLabel('Total'))
  --     expect(Scheduler).toHaveYielded(['Total: 7'])
  --   })

  --   it('returns the same updater function every time', function()
  --     local updater = nil
  --     function Counter()
  --       local [count, updateCount] = useState(0)
  --       updater = updateCount
  --       return <Text text={'Count: ' + count} />
  --     end
  --     ReactNoop.render(<Counter />)
  --     expect(Scheduler).toFlushAndYield(['Count: 0'])
  --     expect(ReactNoop.getChildren()).toEqual([span('Count: 0')])

  --     local firstUpdater = updater

  --     act(function() firstUpdater(1))
  --     expect(Scheduler).toHaveYielded(['Count: 1'])
  --     expect(ReactNoop.getChildren()).toEqual([span('Count: 1')])

  --     local secondUpdater = updater

  --     act(function() firstUpdater(count => count + 10))
  --     expect(Scheduler).toHaveYielded(['Count: 11'])
  --     expect(ReactNoop.getChildren()).toEqual([span('Count: 11')])

  --     expect(firstUpdater).toBe(secondUpdater)
  --   })

  --   it('warns on set after unmount', function()
  --     local _updateCount
  --     function Counter(props, ref)
  --       local [, updateCount] = useState(0)
  --       _updateCount = updateCount
  --       return nil
  --     end

  --     ReactNoop.render(<Counter />)
  --     expect(Scheduler).toFlushWithoutYielding()
  --     ReactNoop.render(null)
  --     expect(Scheduler).toFlushWithoutYielding()
  --     expect(function() act(function() _updateCount(1))).toErrorDev(
  --       "Warning: Can't perform a React state update on an unmounted " +
  --         'component. This is a no-op, but it indicates a memory leak in your ' +
  --         'application. To fix, cancel all subscriptions and asynchronous ' +
  --         'tasks in a useEffect cleanup function.\n' +
  --         '    in Counter (at **)',
  --     )
  --   })

  --   it('dedupes the warning by component name', function()
  --     local _updateCountA
  --     function CounterA(props, ref)
  --       local [, updateCount] = useState(0)
  --       _updateCountA = updateCount
  --       return nil
  --     end
  --     local _updateCountB
  --     function CounterB(props, ref)
  --       local [, updateCount] = useState(0)
  --       _updateCountB = updateCount
  --       return nil
  --     end

  --     ReactNoop.render([<CounterA key="A" />, <CounterB key="B" />])
  --     expect(Scheduler).toFlushWithoutYielding()
  --     ReactNoop.render(null)
  --     expect(Scheduler).toFlushWithoutYielding()
  --     expect(function() act(function() _updateCountA(1))).toErrorDev(
  --       "Warning: Can't perform a React state update on an unmounted " +
  --         'component. This is a no-op, but it indicates a memory leak in your ' +
  --         'application. To fix, cancel all subscriptions and asynchronous ' +
  --         'tasks in a useEffect cleanup function.\n' +
  --         '    in CounterA (at **)',
  --     )
  --     -- already cached so this logs no error
  --     act(function() _updateCountA(2))
  --     expect(function() act(function() _updateCountB(1))).toErrorDev(
  --       "Warning: Can't perform a React state update on an unmounted " +
  --         'component. This is a no-op, but it indicates a memory leak in your ' +
  --         'application. To fix, cancel all subscriptions and asynchronous ' +
  --         'tasks in a useEffect cleanup function.\n' +
  --         '    in CounterB (at **)',
  --     )
  --   })

  --   it('works with memo', function()
  --     local _updateCount
  --     function Counter(props)
  --       local [count, updateCount] = useState(0)
  --       _updateCount = updateCount
  --       return <Text text={'Count: ' + count} />
  --     end
  --     Counter = memo(Counter)

  --     ReactNoop.render(<Counter />)
  --     expect(Scheduler).toFlushAndYield(['Count: 0'])
  --     expect(ReactNoop.getChildren()).toEqual([span('Count: 0')])

  --     ReactNoop.render(<Counter />)
  --     expect(Scheduler).toFlushAndYield([])
  --     expect(ReactNoop.getChildren()).toEqual([span('Count: 0')])

  --     act(function() _updateCount(1))
  --     expect(Scheduler).toHaveYielded(['Count: 1'])
  --     expect(ReactNoop.getChildren()).toEqual([span('Count: 1')])
  --   })
  -- })

  -- describe('updates during the render phase', function()
  --   it('restarts the render function and applies the new updates on top', function()
  --     function ScrollView({row: newRow})
  --       local [isScrollingDown, setIsScrollingDown] = useState(false)
  --       local [row, setRow] = useState(null)

  --       if row ~= newRow)
  --         -- Row changed since last render. Update isScrollingDown.
  --         setIsScrollingDown(row ~= nil and newRow > row)
  --         setRow(newRow)
  --       end

  --       return <Text text={`Scrolling down: ${isScrollingDown}`} />
  --     end

  --     ReactNoop.render(<ScrollView row={1} />)
  --     expect(Scheduler).toFlushAndYield(['Scrolling down: false'])
  --     expect(ReactNoop.getChildren()).toEqual([span('Scrolling down: false')])

  --     ReactNoop.render(<ScrollView row={5} />)
  --     expect(Scheduler).toFlushAndYield(['Scrolling down: true'])
  --     expect(ReactNoop.getChildren()).toEqual([span('Scrolling down: true')])

  --     ReactNoop.render(<ScrollView row={5} />)
  --     expect(Scheduler).toFlushAndYield(['Scrolling down: true'])
  --     expect(ReactNoop.getChildren()).toEqual([span('Scrolling down: true')])

  --     ReactNoop.render(<ScrollView row={10} />)
  --     expect(Scheduler).toFlushAndYield(['Scrolling down: true'])
  --     expect(ReactNoop.getChildren()).toEqual([span('Scrolling down: true')])

  --     ReactNoop.render(<ScrollView row={2} />)
  --     expect(Scheduler).toFlushAndYield(['Scrolling down: false'])
  --     expect(ReactNoop.getChildren()).toEqual([span('Scrolling down: false')])

  --     ReactNoop.render(<ScrollView row={2} />)
  --     expect(Scheduler).toFlushAndYield(['Scrolling down: false'])
  --     expect(ReactNoop.getChildren()).toEqual([span('Scrolling down: false')])
  --   })

  --   it('warns about render phase update on a different component', async function()
  --     local setStep
  --     function Foo()
  --       local [step, _setStep] = useState(0)
  --       setStep = _setStep
  --       return <Text text={`Foo [${step}]`} />
  --     end

  --     function Bar({triggerUpdate})
  --       if triggerUpdate)
  --         setStep(x => x + 1)
  --       end
  --       return <Text text="Bar" />
  --     end

  --     local root = ReactNoop.createRoot()

  --     await ReactNoop.act(async function()
  --       root.render(
  --         <>
  --           <Foo />
  --           <Bar />
  --         </>,
  --       )
  --     })
  --     expect(Scheduler).toHaveYielded(['Foo [0]', 'Bar'])

  --     -- Bar will update Foo during its render phase. React should warn.
  --     await ReactNoop.act(async function()
  --       root.render(
  --         <>
  --           <Foo />
  --           <Bar triggerUpdate={true} />
  --         </>,
  --       )
  --       expect(function()
  --         expect(Scheduler).toFlushAndYield(
  --           __DEV__
  --             ? ['Foo [0]', 'Bar', 'Foo [2]']
  --             : ['Foo [0]', 'Bar', 'Foo [1]'],
  --         ),
  --       ).toErrorDev([
  --         'Cannot update a component (`Foo`) while rendering a ' +
  --           'different component (`Bar`). To locate the bad setState() call inside `Bar`',
  --       ])
  --     })

  --     -- It should not warn again (deduplication).
  --     await ReactNoop.act(async function()
  --       root.render(
  --         <>
  --           <Foo />
  --           <Bar triggerUpdate={true} />
  --         </>,
  --       )
  --       expect(Scheduler).toFlushAndYield(
  --         __DEV__
  --           ? ['Foo [2]', 'Bar', 'Foo [4]']
  --           : ['Foo [1]', 'Bar', 'Foo [2]'],
  --       )
  --     })
  --   })

  --   it('keeps restarting until there are no more new updates', function()
  --     function Counter({row: newRow})
  --       local [count, setCount] = useState(0)
  --       if count < 3)
  --         setCount(count + 1)
  --       end
  --       Scheduler.unstable_yieldValue('Render: ' + count)
  --       return <Text text={count} />
  --     end

  --     ReactNoop.render(<Counter />)
  --     expect(Scheduler).toFlushAndYield([
  --       'Render: 0',
  --       'Render: 1',
  --       'Render: 2',
  --       'Render: 3',
  --       3,
  --     ])
  --     expect(ReactNoop.getChildren()).toEqual([span(3)])
  --   })

  --   it('updates multiple times within same render function', function()
  --     function Counter({row: newRow})
  --       local [count, setCount] = useState(0)
  --       if count < 12)
  --         setCount(c => c + 1)
  --         setCount(c => c + 1)
  --         setCount(c => c + 1)
  --       end
  --       Scheduler.unstable_yieldValue('Render: ' + count)
  --       return <Text text={count} />
  --     end

  --     ReactNoop.render(<Counter />)
  --     expect(Scheduler).toFlushAndYield([
  --       -- Should increase by three each time
  --       'Render: 0',
  --       'Render: 3',
  --       'Render: 6',
  --       'Render: 9',
  --       'Render: 12',
  --       12,
  --     ])
  --     expect(ReactNoop.getChildren()).toEqual([span(12)])
  --   })

  --   it('throws after too many iterations', function()
  --     function Counter({row: newRow})
  --       local [count, setCount] = useState(0)
  --       setCount(count + 1)
  --       Scheduler.unstable_yieldValue('Render: ' + count)
  --       return <Text text={count} />
  --     end
  --     ReactNoop.render(<Counter />)
  --     expect(Scheduler).toFlushAndThrow(
  --       'Too many re-renders. React limits the number of renders to prevent ' +
  --         'an infinite loop.',
  --     )
  --   })

  --   it('works with useReducer', function()
  --     function reducer(state, action)
  --       return action == 'increment' ? state + 1 : state
  --     end
  --     function Counter({row: newRow})
  --       local [count, dispatch] = useReducer(reducer, 0)
  --       if count < 3)
  --         dispatch('increment')
  --       end
  --       Scheduler.unstable_yieldValue('Render: ' + count)
  --       return <Text text={count} />
  --     end

  --     ReactNoop.render(<Counter />)
  --     expect(Scheduler).toFlushAndYield([
  --       'Render: 0',
  --       'Render: 1',
  --       'Render: 2',
  --       'Render: 3',
  --       3,
  --     ])
  --     expect(ReactNoop.getChildren()).toEqual([span(3)])
  --   })

  --   it('uses reducer passed at time of render, not time of dispatch', function()
  --     -- This test is a bit contrived but it demonstrates a subtle edge case.

  --     -- Reducer A increments by 1. Reducer B increments by 10.
  --     function reducerA(state, action)
  --       switch (action)
  --         case 'increment':
  --           return state + 1
  --         case 'reset':
  --           return 0
  --       end
  --     end
  --     function reducerB(state, action)
  --       switch (action)
  --         case 'increment':
  --           return state + 10
  --         case 'reset':
  --           return 0
  --       end
  --     end

  --     function Counter({row: newRow}, ref)
  --       local [reducer, setReducer] = useState(function() reducerA)
  --       local [count, dispatch] = useReducer(reducer, 0)
  --       useImperativeHandle(ref, function() ({dispatch}))
  --       if count < 20)
  --         dispatch('increment')
  --         -- Swap reducers each time we increment
  --         if reducer == reducerA)
  --           setReducer(function() reducerB)
  --         } else {
  --           setReducer(function() reducerA)
  --         end
  --       end
  --       Scheduler.unstable_yieldValue('Render: ' + count)
  --       return <Text text={count} />
  --     end
  --     Counter = forwardRef(Counter)
  --     local counter = React.createRef(null)
  --     ReactNoop.render(<Counter ref={counter} />)
  --     expect(Scheduler).toFlushAndYield([
  --       -- The count should increase by alternating amounts of 10 and 1
  --       -- until we reach 21.
  --       'Render: 0',
  --       'Render: 10',
  --       'Render: 11',
  --       'Render: 21',
  --       21,
  --     ])
  --     expect(ReactNoop.getChildren()).toEqual([span(21)])

  --     -- Test that it works on update, too. This time the log is a bit different
  --     -- because we started with reducerB instead of reducerA.
  --     ReactNoop.act(function()
  --       counter.current.dispatch('reset')
  --     })
  --     ReactNoop.render(<Counter ref={counter} />)
  --     expect(Scheduler).toHaveYielded([
  --       'Render: 0',
  --       'Render: 1',
  --       'Render: 11',
  --       'Render: 12',
  --       'Render: 22',
  --       22,
  --     ])
  --     expect(ReactNoop.getChildren()).toEqual([span(22)])
  --   })

  --   it('discards render phase updates if something suspends', async function()
  --     local thenable = {then() {}}
  --     function Foo({signal})
  --       return (
  --         <Suspense fallback="Loading...">
  --           <Bar signal={signal} />
  --         </Suspense>
  --       )
  --     end

  --     function Bar({signal: newSignal})
  --       local [counter, setCounter] = useState(0)
  --       local [signal, setSignal] = useState(true)

  --       -- Increment a counter every time the signal changes
  --       if signal ~= newSignal)
  --         setCounter(c => c + 1)
  --         setSignal(newSignal)
  --         if counter == 0)
  --           -- We're suspending during a render that includes render phase
  --           -- updates. Those updates should not persist to the next render.
  --           Scheduler.unstable_yieldValue('Suspend!')
  --           throw thenable
  --         end
  --       end

  --       return <Text text={counter} />
  --     end

  --     local root = ReactNoop.createRoot()
  --     root.render(<Foo signal={true} />)

  --     expect(Scheduler).toFlushAndYield([0])
  --     expect(root).toMatchRenderedOutput(<span prop={0} />)

  --     root.render(<Foo signal={false} />)
  --     expect(Scheduler).toFlushAndYield(['Suspend!'])
  --     expect(root).toMatchRenderedOutput(<span prop={0} />)

  --     -- Rendering again should suspend again.
  --     root.render(<Foo signal={false} />)
  --     expect(Scheduler).toFlushAndYield(['Suspend!'])
  --   })

  --   it('discards render phase updates if something suspends, but not other updates in the same component', async function()
  --     local thenable = {then() {}}
  --     function Foo({signal})
  --       return (
  --         <Suspense fallback="Loading...">
  --           <Bar signal={signal} />
  --         </Suspense>
  --       )
  --     end

  --     local setLabel
  --     function Bar({signal: newSignal})
  --       local [counter, setCounter] = useState(0)

  --       if counter == 1)
  --         -- We're suspending during a render that includes render phase
  --         -- updates. Those updates should not persist to the next render.
  --         Scheduler.unstable_yieldValue('Suspend!')
  --         throw thenable
  --       end

  --       local [signal, setSignal] = useState(true)

  --       -- Increment a counter every time the signal changes
  --       if signal ~= newSignal)
  --         setCounter(c => c + 1)
  --         setSignal(newSignal)
  --       end

  --       local [label, _setLabel] = useState('A')
  --       setLabel = _setLabel

  --       return <Text text={`${label}:${counter}`} />
  --     end

  --     local root = ReactNoop.createRoot()
  --     root.render(<Foo signal={true} />)

  --     expect(Scheduler).toFlushAndYield(['A:0'])
  --     expect(root).toMatchRenderedOutput(<span prop="A:0" />)

  --     await ReactNoop.act(async function()
  --       root.render(<Foo signal={false} />)
  --       setLabel('B')

  --       expect(Scheduler).toFlushAndYield(['Suspend!'])
  --       expect(root).toMatchRenderedOutput(<span prop="A:0" />)

  --       -- Rendering again should suspend again.
  --       root.render(<Foo signal={false} />)
  --       expect(Scheduler).toFlushAndYield(['Suspend!'])

  --       -- Flip the signal back to "cancel" the update. However, the update to
  --       -- label should still proceed. It shouldn't have been dropped.
  --       root.render(<Foo signal={true} />)
  --       expect(Scheduler).toFlushAndYield(['B:0'])
  --       expect(root).toMatchRenderedOutput(<span prop="B:0" />)
  --     })
  --   })

  --   it('regression: render phase updates cause lower pri work to be dropped', async function()
  --     local setRow
  --     function ScrollView()
  --       local [row, _setRow] = useState(10)
  --       setRow = _setRow

  --       local [scrollDirection, setScrollDirection] = useState('Up')
  --       local [prevRow, setPrevRow] = useState(null)

  --       if prevRow ~= row)
  --         setScrollDirection(prevRow ~= nil and row > prevRow ? 'Down' : 'Up')
  --         setPrevRow(row)
  --       end

  --       return <Text text={scrollDirection} />
  --     end

  --     local root = ReactNoop.createRoot()

  --     await act(async function()
  --       root.render(<ScrollView row={10} />)
  --     })
  --     expect(Scheduler).toHaveYielded(['Up'])
  --     expect(root).toMatchRenderedOutput(<span prop="Up" />)

  --     await act(async function()
  --       ReactNoop.discreteUpdates(function()
  --         setRow(5)
  --       })
  --       setRow(20)
  --     })
  --     expect(Scheduler).toHaveYielded(['Up', 'Down'])
  --     expect(root).toMatchRenderedOutput(<span prop="Down" />)
  --   })

  --   -- TODO: This should probably warn
  --   -- @gate experimental
  --   it('calling startTransition inside render phase', async function()
  --     local startTransition
  --     function App()
  --       local [counter, setCounter] = useState(0)
  --       local [_startTransition] = useTransition()
  --       startTransition = _startTransition

  --       if counter == 0)
  --         startTransition(function()
  --           setCounter(c => c + 1)
  --         })
  --       end

  --       return <Text text={counter} />
  --     end

  --     local root = ReactNoop.createRoot()
  --     root.render(<App />)
  --     expect(Scheduler).toFlushAndYield([1])
  --     expect(root).toMatchRenderedOutput(<span prop={1} />)
  --   })
  -- })

  -- describe('useReducer', function()
  --   it('simple mount and update', function()
  --     local INCREMENT = 'INCREMENT'
  --     local DECREMENT = 'DECREMENT'

  --     function reducer(state, action)
  --       switch (action)
  --         case 'INCREMENT':
  --           return state + 1
  --         case 'DECREMENT':
  --           return state - 1
  --         default:
  --           return state
  --       end
  --     end

  --     function Counter(props, ref)
  --       local [count, dispatch] = useReducer(reducer, 0)
  --       useImperativeHandle(ref, function() ({dispatch}))
  --       return <Text text={'Count: ' + count} />
  --     end
  --     Counter = forwardRef(Counter)
  --     local counter = React.createRef(null)
  --     ReactNoop.render(<Counter ref={counter} />)
  --     expect(Scheduler).toFlushAndYield(['Count: 0'])
  --     expect(ReactNoop.getChildren()).toEqual([span('Count: 0')])

  --     act(function() counter.current.dispatch(INCREMENT))
  --     expect(Scheduler).toHaveYielded(['Count: 1'])
  --     expect(ReactNoop.getChildren()).toEqual([span('Count: 1')])
  --     act(function()
  --       counter.current.dispatch(DECREMENT)
  --       counter.current.dispatch(DECREMENT)
  --       counter.current.dispatch(DECREMENT)
  --     })

  --     expect(Scheduler).toHaveYielded(['Count: -2'])
  --     expect(ReactNoop.getChildren()).toEqual([span('Count: -2')])
  --   })

  --   it('lazy init', function()
  --     local INCREMENT = 'INCREMENT'
  --     local DECREMENT = 'DECREMENT'

  --     function reducer(state, action)
  --       switch (action)
  --         case 'INCREMENT':
  --           return state + 1
  --         case 'DECREMENT':
  --           return state - 1
  --         default:
  --           return state
  --       end
  --     end

  --     function Counter(props, ref)
  --       local [count, dispatch] = useReducer(reducer, props, p => {
  --         Scheduler.unstable_yieldValue('Init')
  --         return p.initialCount
  --       })
  --       useImperativeHandle(ref, function() ({dispatch}))
  --       return <Text text={'Count: ' + count} />
  --     end
  --     Counter = forwardRef(Counter)
  --     local counter = React.createRef(null)
  --     ReactNoop.render(<Counter initialCount={10} ref={counter} />)
  --     expect(Scheduler).toFlushAndYield(['Init', 'Count: 10'])
  --     expect(ReactNoop.getChildren()).toEqual([span('Count: 10')])

  --     act(function() counter.current.dispatch(INCREMENT))
  --     expect(Scheduler).toHaveYielded(['Count: 11'])
  --     expect(ReactNoop.getChildren()).toEqual([span('Count: 11')])

  --     act(function()
  --       counter.current.dispatch(DECREMENT)
  --       counter.current.dispatch(DECREMENT)
  --       counter.current.dispatch(DECREMENT)
  --     })

  --     expect(Scheduler).toHaveYielded(['Count: 8'])
  --     expect(ReactNoop.getChildren()).toEqual([span('Count: 8')])
  --   })

  --   -- Regression test for https:--github.com/facebook/react/issues/14360
  --   it('handles dispatches with mixed priorities', function()
  --     local INCREMENT = 'INCREMENT'

  --     function reducer(state, action)
  --       return action == INCREMENT ? state + 1 : state
  --     end

  --     function Counter(props, ref)
  --       local [count, dispatch] = useReducer(reducer, 0)
  --       useImperativeHandle(ref, function() ({dispatch}))
  --       return <Text text={'Count: ' + count} />
  --     end

  --     Counter = forwardRef(Counter)
  --     local counter = React.createRef(null)
  --     ReactNoop.render(<Counter ref={counter} />)

  --     expect(Scheduler).toFlushAndYield(['Count: 0'])
  --     expect(ReactNoop.getChildren()).toEqual([span('Count: 0')])

  --     ReactNoop.batchedUpdates(function()
  --       counter.current.dispatch(INCREMENT)
  --       counter.current.dispatch(INCREMENT)
  --       counter.current.dispatch(INCREMENT)
  --     })

  --     ReactNoop.flushSync(function()
  --       counter.current.dispatch(INCREMENT)
  --     })
  --     expect(Scheduler).toHaveYielded(['Count: 1'])
  --     expect(ReactNoop.getChildren()).toEqual([span('Count: 1')])

  --     expect(Scheduler).toFlushAndYield(['Count: 4'])
  --     expect(ReactNoop.getChildren()).toEqual([span('Count: 4')])
  --   })
  -- })

  describe("useEffect", function()
    it("simple mount and update", function()
      -- FIXME: type of expect
      local expect: any = expect
      local function Counter(props)
        useEffect(function()
          Scheduler.unstable_yieldValue(("Passive effect [%d]"):format(props.count))
        end)
        return React.createElement(Text, {
          text = "Count: " .. props.count,
        })
      end
      act(function()
        ReactNoop.render(React.createElement(Counter, {
          count = 0,
        }), function()
          Scheduler.unstable_yieldValue("Sync effect")
        end)
        expect(Scheduler).toFlushAndYieldThrough({"Count: 0", "Sync effect"})
        expect(ReactNoop.getChildren()).toEqual({span("Count: 0")})
        -- Effects are deferred until after the commit
        expect(Scheduler).toFlushAndYield({"Passive effect [0]"})
      end)

      act(function()
        ReactNoop.render(React.createElement(Counter, {
          count = 1,
        }), function()
          Scheduler.unstable_yieldValue("Sync effect")
        end)
        expect(Scheduler).toFlushAndYieldThrough({"Count: 1", "Sync effect"})
        expect(ReactNoop.getChildren()).toEqual({span("Count: 1")})
        -- Effects are deferred until after the commit
        expect(Scheduler).toFlushAndYield({"Passive effect [1]"})
      end)
    end)

    it('flushes passive effects even with sibling deletions', function()
      -- FIXME: type of expect
      local expect: any = expect
      local function LayoutEffect(props)
        useLayoutEffect(function()
          Scheduler.unstable_yieldValue('Layout effect')
        end)
        return React.createElement(Text, {text="Layout"})
      end
      local function PassiveEffect(props)
        useEffect(function()
          Scheduler.unstable_yieldValue('Passive effect')
        end, {})
        return React.createElement(Text, {text="Passive"})
      end
      local passive = React.createElement(PassiveEffect, {key="p"})
      act(function()
        ReactNoop.render({React.createElement(LayoutEffect, {key="l"}), passive})
        expect(Scheduler).toFlushAndYieldThrough({
          'Layout',
          'Passive',
          'Layout effect',
        })
        expect(ReactNoop.getChildren()).toEqual({
          span('Layout'),
          span('Passive'),
        })
        -- Destroying the first child shouldn't prevent the passive effect from
        -- being executed
        ReactNoop.render({passive})
        expect(Scheduler).toFlushAndYield({'Passive effect'})
        expect(ReactNoop.getChildren()).toEqual({span('Passive')})
      end)
      -- exiting act calls flushPassiveEffects(), but there are none left to flush.
      expect(Scheduler).toHaveYielded({})
    end)

    -- ROBLOX TODO: needs mountState in ReactFiberHooks.new
    xit('flushes passive effects even if siblings schedule an update', function()
      -- FIXME: type of expect
      local expect: any = expect
      local function PassiveEffect(props)
        useEffect(function()
          Scheduler.unstable_yieldValue('Passive effect')
        end)
        return React.createElement(Text, {text="Passive"})
      end
      local function LayoutEffect(props)
        local count, setCount = useState(0)
        useLayoutEffect(function()
          -- Scheduling work shouldn't interfere with the queued passive effect
          if count == 0 then
            setCount(1)
          end
          Scheduler.unstable_yieldValue('Layout effect ' .. count)
        end)
        return React.createElement(Text, {text="Layout"})
      end

      ReactNoop.render({
        React.createElement(PassiveEffect, {key="p"}),
        React.createElement(LayoutEffect, {key="l"})
      })

      act(function()
        expect(Scheduler).toFlushAndYield({
          'Passive',
          'Layout',
          'Layout effect 0',
          'Passive effect',
          'Layout',
          'Layout effect 1',
        })
      end)

      expect(ReactNoop.getChildren()).toEqual({
        span('Passive'),
        span('Layout'),
      })
    end)

    it('flushes passive effects even if siblings schedule a new root', function()
      -- FIXME: type of expect
      local expect: any = expect
      local function PassiveEffect(props)
        useEffect(function()
          Scheduler.unstable_yieldValue('Passive effect')
        end, {})
        return React.createElement(Text, {text="Passive"})
      end
      local function LayoutEffect(props)
        useLayoutEffect(function()
          Scheduler.unstable_yieldValue('Layout effect')
          -- Scheduling work shouldn't interfere with the queued passive effect
          ReactNoop.renderToRootWithID(
            React.createElement(
              Text, {text="New Root"}
            ),
            'root2')
          end)
        return React.createElement(Text, {text="Layout"})
      end
      act(function()
        ReactNoop.render({
          React.createElement(PassiveEffect, {key="p"}),
          React.createElement(LayoutEffect, {key="l"})
        })
        expect(Scheduler).toFlushAndYield({
          'Passive',
          'Layout',
          'Layout effect',
          'Passive effect',
          'New Root',
        })
        expect(ReactNoop.getChildren()).toEqual({
          span('Passive'),
          span('Layout'),
        })
      end)
    end)

    it(
      'flushes effects serially by flushing old effects before flushing ' ..
        "new ones, if they haven't already fired", function()
      -- FIXME: type of expect
      local expect: any = expect
        function getCommittedText()
          local children = ReactNoop.getChildren()
          if children == nil then
            return nil
          end
          return children[1].prop
        end

        local function Counter(props)
          useEffect(function()
            Scheduler.unstable_yieldValue(
              "Committed state when effect was fired: " .. tostring(getCommittedText())
            )
          end)
          return React.createElement(Text, {text = props.count})
        end
        act(function()
          ReactNoop.render(
            React.createElement(Counter, {count = 0}),
            function()
              Scheduler.unstable_yieldValue('Sync effect')
            end
          )
          expect(Scheduler).toFlushAndYieldThrough({0, 'Sync effect'})
          expect(ReactNoop.getChildren()).toEqual({span(0)})
          -- Before the effects have a chance to flush, schedule another update
          ReactNoop.render(
            React.createElement(Counter, {count = 1}),
            function()
              Scheduler.unstable_yieldValue('Sync effect')
            end
          )
          expect(Scheduler).toFlushAndYieldThrough({
            -- The previous effect flushes before the reconciliation
            'Committed state when effect was fired: 0',
            1,
            'Sync effect',
          })
          expect(ReactNoop.getChildren()).toEqual({span(1)})
        end)

        expect(Scheduler).toHaveYielded({
          'Committed state when effect was fired: 1',
        })
      end)

    -- ROBLOX TODO: Child gets nil props, which causes a failure
    xit('defers passive effect destroy functions during unmount', function()
      -- FIXME: type of expect
      local expect: any = expect
      function Child(props)
        local bar = props.bar
        local foo = props.foo
        React.useEffect(function()
          Scheduler.unstable_yieldValue('passive bar create')
          return function()
            Scheduler.unstable_yieldValue('passive bar destroy')
          end
        end, {bar})
        React.useLayoutEffect(function()
          Scheduler.unstable_yieldValue('layout bar create')
          return function()
            Scheduler.unstable_yieldValue('layout bar destroy')
          end
        end, {bar})
        React.useEffect(function()
          Scheduler.unstable_yieldValue('passive foo create')
          return function()
            Scheduler.unstable_yieldValue('passive foo destroy')
          end
        end, {foo})
        React.useLayoutEffect(function()
          Scheduler.unstable_yieldValue('layout foo create')
          return function()
            Scheduler.unstable_yieldValue('layout foo destroy')
          end
        end, {foo})
        Scheduler.unstable_yieldValue('render')
        return nil
      end

      act(function()
        ReactNoop.render(
          React.createElement(Child, {bar = 1, foo = 1}),
          function()
            Scheduler.unstable_yieldValue('Sync effect')
          end
        )
        expect(Scheduler).toFlushAndYieldThrough({
          'render',
          'layout bar create',
          'layout foo create',
          'Sync effect',
        })
        -- Effects are deferred until after the commit
        expect(Scheduler).toFlushAndYield({
          'passive bar create',
          'passive foo create',
        })
      end)

      -- This update is exists to test an internal implementation detail:
      -- Effects without updating dependencies lose their layout/passive tag during an update.
      act(function()
        ReactNoop.render(
          React.createElement(Child, {bar = 1, foo = 2}),
          function()
            Scheduler.unstable_yieldValue('Sync effect')
          end
        )
        expect(Scheduler).toFlushAndYieldThrough({
          'render',
          'layout foo destroy',
          'layout foo create',
          'Sync effect',
        })
        -- Effects are deferred until after the commit
        expect(Scheduler).toFlushAndYield({
          'passive foo destroy',
          'passive foo create',
        })
      end)

      -- Unmount the component and verify that passive destroy functions are deferred until post-commit.
      act(function()
        ReactNoop.render(nil, function()
          Scheduler.unstable_yieldValue('Sync effect')
        end)
        expect(Scheduler).toFlushAndYieldThrough({
          'layout bar destroy',
          'layout foo destroy',
          'Sync effect',
        })
        -- Effects are deferred until after the commit
        expect(Scheduler).toFlushAndYield({
          'passive bar destroy',
          'passive foo destroy',
        })
      end)
    end)

    -- ROBLOX TODO: needs mountState
    xit('does not warn about state updates for unmounted components with pending passive unmounts', function()
      -- FIXME: type of expect
      local expect: any = expect
      local completePendingRequest = nil
      function Component()
        Scheduler.unstable_yieldValue('Component')
        local didLoad, setDidLoad = React.useState(false)
        React.useLayoutEffect(function()
          Scheduler.unstable_yieldValue('layout create')
          return function()
            Scheduler.unstable_yieldValue('layout destroy')
          end
        end, {})
        React.useEffect(function()
          Scheduler.unstable_yieldValue('passive create')
          -- Mimic an XHR request with a complete handler that updates state.
          completePendingRequest = function()
            setDidLoad(true)
          end
          return function()
            Scheduler.unstable_yieldValue('passive destroy')
          end
        end, {})
        return didLoad
      end

      act(function()
        ReactNoop.renderToRootWithID(
          React.createElement(Component),
          'root',
          function()
            Scheduler.unstable_yieldValue('Sync effect')
          end
        )
        expect(Scheduler).toFlushAndYieldThrough({
          'Component',
          'layout create',
          'Sync effect',
        })
        ReactNoop.flushPassiveEffects()
        expect(Scheduler).toHaveYielded({'passive create'})

        -- Unmount but don't process pending passive destroy function
        ReactNoop.unmountRootWithID('root')
        expect(Scheduler).toFlushAndYieldThrough({'layout destroy'})

        -- Simulate an XHR completing, which will cause a state update-
        -- but should not log a warning.
        completePendingRequest()

        ReactNoop.flushPassiveEffects()
        expect(Scheduler).toHaveYielded({'passive destroy'})
      end)
    end)

  --   it('does not warn about state updates for unmounted components with pending passive unmounts for alternates', function()
  --     local setParentState = nil
  --     local setChildStates = []

  --     function Parent()
  --       local [state, setState] = useState(true)
  --       setParentState = setState
  --       Scheduler.unstable_yieldValue(`Parent ${state} render`)
  --       useLayoutEffect(function()
  --         Scheduler.unstable_yieldValue(`Parent ${state} commit`)
  --       })
  --       if state)
  --         return (
  --           <>
  --             <Child label="one" />
  --             <Child label="two" />
  --           </>
  --         )
  --       } else {
  --         return nil
  --       end
  --     end

  --     function Child({label})
  --       local [state, setState] = useState(0)
  --       useLayoutEffect(function()
  --         Scheduler.unstable_yieldValue(`Child ${label} commit`)
  --       })
  --       useEffect(function()
  --         setChildStates.push(setState)
  --         Scheduler.unstable_yieldValue(`Child ${label} passive create`)
  --         return function()
  --           Scheduler.unstable_yieldValue(`Child ${label} passive destroy`)
  --         end
  --       }, [])
  --       Scheduler.unstable_yieldValue(`Child ${label} render`)
  --       return state
  --     end

  --     -- Schedule debounced state update for child (prob a no-op for this test)
  --     -- later tick: schedule unmount for parent
  --     -- start process unmount (but don't flush passive effectS)
  --     -- State update on child
  --     act(function()
  --       ReactNoop.render(<Parent />)
  --       expect(Scheduler).toFlushAndYieldThrough([
  --         'Parent true render',
  --         'Child one render',
  --         'Child two render',
  --         'Child one commit',
  --         'Child two commit',
  --         'Parent true commit',
  --         'Child one passive create',
  --         'Child two passive create',
  --       ])

  --       -- Update children.
  --       setChildStates.forEach(setChildState => setChildState(1))
  --       expect(Scheduler).toFlushAndYieldThrough([
  --         'Child one render',
  --         'Child two render',
  --         'Child one commit',
  --         'Child two commit',
  --       ])

  --       -- Schedule another update for children, and partially process it.
  --       setChildStates.forEach(setChildState => setChildState(2))
  --       expect(Scheduler).toFlushAndYieldThrough(['Child one render'])

  --       -- Schedule unmount for the parent that unmounts children with pending update.
  --       Scheduler.unstable_runWithPriority(
  --         Scheduler.unstable_UserBlockingPriority,
  --         function() setParentState(false),
  --       )
  --       expect(Scheduler).toFlushAndYieldThrough([
  --         'Parent false render',
  --         'Parent false commit',
  --       ])

  --       -- Schedule updates for children too (which should be ignored)
  --       setChildStates.forEach(setChildState => setChildState(2))
  --       expect(Scheduler).toFlushAndYield([
  --         'Child one passive destroy',
  --         'Child two passive destroy',
  --       ])
  --     })
  --   })

  --   it('warns about state updates for unmounted components with no pending passive unmounts', function()
  --     local completePendingRequest = nil
  --     function Component()
  --       Scheduler.unstable_yieldValue('Component')
  --       local [didLoad, setDidLoad] = React.useState(false)
  --       React.useLayoutEffect(function()
  --         Scheduler.unstable_yieldValue('layout create')
  --         -- Mimic an XHR request with a complete handler that updates state.
  --         completePendingRequest = function() setDidLoad(true)
  --         return function()
  --           Scheduler.unstable_yieldValue('layout destroy')
  --         end
  --       }, [])
  --       return didLoad
  --     end

  --     act(function()
  --       ReactNoop.renderToRootWithID(<Component />, 'root', function()
  --         Scheduler.unstable_yieldValue('Sync effect'),
  --       )
  --       expect(Scheduler).toFlushAndYieldThrough([
  --         'Component',
  --         'layout create',
  --         'Sync effect',
  --       ])

  --       -- Unmount but don't process pending passive destroy function
  --       ReactNoop.unmountRootWithID('root')
  --       expect(Scheduler).toFlushAndYieldThrough(['layout destroy'])

  --       -- Simulate an XHR completing.
  --       expect(completePendingRequest).toErrorDev(
  --         "Warning: Can't perform a React state update on an unmounted component.",
  --       )
  --     })
  --   })

  --   it('still warns if there are pending passive unmount effects but not for the current fiber', function()
  --     local completePendingRequest = nil
  --     function ComponentWithXHR()
  --       Scheduler.unstable_yieldValue('Component')
  --       local [didLoad, setDidLoad] = React.useState(false)
  --       React.useLayoutEffect(function()
  --         Scheduler.unstable_yieldValue('a:layout create')
  --         return function()
  --           Scheduler.unstable_yieldValue('a:layout destroy')
  --         end
  --       }, [])
  --       React.useEffect(function()
  --         Scheduler.unstable_yieldValue('a:passive create')
  --         -- Mimic an XHR request with a complete handler that updates state.
  --         completePendingRequest = function() setDidLoad(true)
  --       }, [])
  --       return didLoad
  --     end

  --     function ComponentWithPendingPassiveUnmount()
  --       React.useEffect(function()
  --         Scheduler.unstable_yieldValue('b:passive create')
  --         return function()
  --           Scheduler.unstable_yieldValue('b:passive destroy')
  --         end
  --       }, [])
  --       return nil
  --     end

  --     act(function()
  --       ReactNoop.renderToRootWithID(
  --         <>
  --           <ComponentWithXHR />
  --           <ComponentWithPendingPassiveUnmount />
  --         </>,
  --         'root',
  --         function() Scheduler.unstable_yieldValue('Sync effect'),
  --       )
  --       expect(Scheduler).toFlushAndYieldThrough([
  --         'Component',
  --         'a:layout create',
  --         'Sync effect',
  --       ])
  --       ReactNoop.flushPassiveEffects()
  --       expect(Scheduler).toHaveYielded([
  --         'a:passive create',
  --         'b:passive create',
  --       ])

  --       -- Unmount but don't process pending passive destroy function
  --       ReactNoop.unmountRootWithID('root')
  --       expect(Scheduler).toFlushAndYieldThrough(['a:layout destroy'])

  --       -- Simulate an XHR completing in the component without a pending passive effect..
  --       expect(completePendingRequest).toErrorDev(
  --         "Warning: Can't perform a React state update on an unmounted component.",
  --       )
  --     })
  --   })

  --   it('warns if there are updates after pending passive unmount effects have been flushed', function()
  --     local updaterFunction

  --     function Component()
  --       Scheduler.unstable_yieldValue('Component')
  --       local [state, setState] = React.useState(false)
  --       updaterFunction = setState
  --       React.useEffect(function()
  --         Scheduler.unstable_yieldValue('passive create')
  --         return function()
  --           Scheduler.unstable_yieldValue('passive destroy')
  --         end
  --       }, [])
  --       return state
  --     end

  --     act(function()
  --       ReactNoop.renderToRootWithID(<Component />, 'root', function()
  --         Scheduler.unstable_yieldValue('Sync effect'),
  --       )
  --     })
  --     expect(Scheduler).toHaveYielded([
  --       'Component',
  --       'Sync effect',
  --       'passive create',
  --     ])

  --     ReactNoop.unmountRootWithID('root')
  --     expect(Scheduler).toFlushAndYield(['passive destroy'])

  --     act(function()
  --       expect(function()
  --         updaterFunction(true)
  --       }).toErrorDev(
  --         "Warning: Can't perform a React state update on an unmounted component. " +
  --           'This is a no-op, but it indicates a memory leak in your application. ' +
  --           'To fix, cancel all subscriptions and asynchronous tasks in a useEffect cleanup function.\n' +
  --           '    in Component (at **)',
  --       )
  --     })
  --   })

  --   it('does not show a warning when a component updates its own state from within passive unmount function', function()
  --     function Component()
  --       Scheduler.unstable_yieldValue('Component')
  --       local [didLoad, setDidLoad] = React.useState(false)
  --       React.useEffect(function()
  --         Scheduler.unstable_yieldValue('passive create')
  --         return function()
  --           setDidLoad(true)
  --           Scheduler.unstable_yieldValue('passive destroy')
  --         end
  --       }, [])
  --       return didLoad
  --     end

  --     act(function()
  --       ReactNoop.renderToRootWithID(<Component />, 'root', function()
  --         Scheduler.unstable_yieldValue('Sync effect'),
  --       )
  --       expect(Scheduler).toFlushAndYieldThrough([
  --         'Component',
  --         'Sync effect',
  --         'passive create',
  --       ])

  --       -- Unmount but don't process pending passive destroy function
  --       ReactNoop.unmountRootWithID('root')
  --       expect(Scheduler).toFlushAndYield(['passive destroy'])
  --     })
  --   })

  --   it('does not show a warning when a component updates a childs state from within passive unmount function', function()
  --     function Parent()
  --       Scheduler.unstable_yieldValue('Parent')
  --       local updaterRef = React.useRef(null)
  --       React.useEffect(function()
  --         Scheduler.unstable_yieldValue('Parent passive create')
  --         return function()
  --           updaterRef.current(true)
  --           Scheduler.unstable_yieldValue('Parent passive destroy')
  --         end
  --       }, [])
  --       return <Child updaterRef={updaterRef} />
  --     end

  --     function Child({updaterRef})
  --       Scheduler.unstable_yieldValue('Child')
  --       local [state, setState] = React.useState(false)
  --       React.useEffect(function()
  --         Scheduler.unstable_yieldValue('Child passive create')
  --         updaterRef.current = setState
  --       }, [])
  --       return state
  --     end

  --     act(function()
  --       ReactNoop.renderToRootWithID(<Parent />, 'root')
  --       expect(Scheduler).toFlushAndYieldThrough([
  --         'Parent',
  --         'Child',
  --         'Child passive create',
  --         'Parent passive create',
  --       ])

  --       -- Unmount but don't process pending passive destroy function
  --       ReactNoop.unmountRootWithID('root')
  --       expect(Scheduler).toFlushAndYield(['Parent passive destroy'])
  --     })
  --   })

  --   it('does not show a warning when a component updates a parents state from within passive unmount function', function()
  --     function Parent()
  --       local [state, setState] = React.useState(false)
  --       Scheduler.unstable_yieldValue('Parent')
  --       return <Child setState={setState} state={state} />
  --     end

  --     function Child({setState, state})
  --       Scheduler.unstable_yieldValue('Child')
  --       React.useEffect(function()
  --         Scheduler.unstable_yieldValue('Child passive create')
  --         return function()
  --           Scheduler.unstable_yieldValue('Child passive destroy')
  --           setState(true)
  --         end
  --       }, [])
  --       return state
  --     end

  --     act(function()
  --       ReactNoop.renderToRootWithID(<Parent />, 'root')
  --       expect(Scheduler).toFlushAndYieldThrough([
  --         'Parent',
  --         'Child',
  --         'Child passive create',
  --       ])

  --       -- Unmount but don't process pending passive destroy function
  --       ReactNoop.unmountRootWithID('root')
  --       expect(Scheduler).toFlushAndYield(['Child passive destroy'])
  --     })
  --   })

  --   it('updates have async priority', function()
  --     function Counter(props)
  --       local [count, updateCount] = useState('(empty)')
  --       useEffect(function()
  --         Scheduler.unstable_yieldValue(`Schedule update [${props.count}]`)
  --         updateCount(props.count)
  --       }, [props.count])
  --       return <Text text={'Count: ' + count} />
  --     end
  --     act(function()
  --       ReactNoop.render(<Counter count={0} />, function()
  --         Scheduler.unstable_yieldValue('Sync effect'),
  --       )
  --       expect(Scheduler).toFlushAndYieldThrough([
  --         'Count: (empty)',
  --         'Sync effect',
  --       ])
  --       expect(ReactNoop.getChildren()).toEqual([span('Count: (empty)')])
  --       ReactNoop.flushPassiveEffects()
  --       expect(Scheduler).toHaveYielded(['Schedule update [0]'])
  --       expect(Scheduler).toFlushAndYield(['Count: 0'])
  --     })

  --     act(function()
  --       ReactNoop.render(<Counter count={1} />, function()
  --         Scheduler.unstable_yieldValue('Sync effect'),
  --       )
  --       expect(Scheduler).toFlushAndYieldThrough(['Count: 0', 'Sync effect'])
  --       expect(ReactNoop.getChildren()).toEqual([span('Count: 0')])
  --       ReactNoop.flushPassiveEffects()
  --       expect(Scheduler).toHaveYielded(['Schedule update [1]'])
  --       expect(Scheduler).toFlushAndYield(['Count: 1'])
  --     })
  --   })

  --   it('updates have async priority even if effects are flushed early', function()
  --     function Counter(props)
  --       local [count, updateCount] = useState('(empty)')
  --       useEffect(function()
  --         Scheduler.unstable_yieldValue(`Schedule update [${props.count}]`)
  --         updateCount(props.count)
  --       }, [props.count])
  --       return <Text text={'Count: ' + count} />
  --     end
  --     act(function()
  --       ReactNoop.render(<Counter count={0} />, function()
  --         Scheduler.unstable_yieldValue('Sync effect'),
  --       )
  --       expect(Scheduler).toFlushAndYieldThrough([
  --         'Count: (empty)',
  --         'Sync effect',
  --       ])
  --       expect(ReactNoop.getChildren()).toEqual([span('Count: (empty)')])

  --       -- Rendering again should flush the previous commit's effects
  --       ReactNoop.render(<Counter count={1} />, function()
  --         Scheduler.unstable_yieldValue('Sync effect'),
  --       )
  --       expect(Scheduler).toFlushAndYieldThrough([
  --         'Schedule update [0]',
  --         'Count: 0',
  --       ])
  --       expect(ReactNoop.getChildren()).toEqual([span('Count: (empty)')])

  --       expect(Scheduler).toFlushAndYieldThrough(['Sync effect'])
  --       expect(ReactNoop.getChildren()).toEqual([span('Count: 0')])
  --       ReactNoop.flushPassiveEffects()
  --       expect(Scheduler).toHaveYielded(['Schedule update [1]'])
  --       expect(Scheduler).toFlushAndYield(['Count: 1'])
  --       expect(ReactNoop.getChildren()).toEqual([span('Count: 1')])
  --     })
  --   })

  --   it('does not flush non-discrete passive effects when flushing sync', function()
  --     local _updateCount
  --     function Counter(props)
  --       local [count, updateCount] = useState(0)
  --       _updateCount = updateCount
  --       useEffect(function()
  --         Scheduler.unstable_yieldValue(`Will set count to 1`)
  --         updateCount(1)
  --       }, [])
  --       return <Text text={'Count: ' + count} />
  --     end

  --     -- we explicitly wait for missing act() warnings here since
  --     -- it's a lot harder to simulate this condition inside an act scope
  --     expect(function()
  --       ReactNoop.render(<Counter count={0} />, function()
  --         Scheduler.unstable_yieldValue('Sync effect'),
  --       )
  --       expect(Scheduler).toFlushAndYieldThrough(['Count: 0', 'Sync effect'])
  --       expect(ReactNoop.getChildren()).toEqual([span('Count: 0')])
  --     }).toErrorDev(['An update to Counter ran an effect'])

  --     -- A flush sync doesn't cause the passive effects to fire.
  --     -- So we haven't added the other update yet.
  --     act(function()
  --       ReactNoop.flushSync(function()
  --         _updateCount(2)
  --       })
  --     })

  --     -- As a result we, somewhat surprisingly, commit them in the opposite order.
  --     -- This should be fine because any non-discrete set of work doesn't guarantee order
  --     -- and easily could've happened slightly later too.
  --     expect(Scheduler).toHaveYielded([
  --       'Will set count to 1',
  --       'Count: 2',
  --       'Count: 1',
  --     ])

  --     expect(ReactNoop.getChildren()).toEqual([span('Count: 1')])
  --   })

  --   -- @gate enableSchedulerTracing
  --   it('does not flush non-discrete passive effects when flushing sync (with tracing)', function()
  --     local onInteractionScheduledWorkCompleted = jest.fn()
  --     local onWorkCanceled = jest.fn()
  --     SchedulerTracing.unstable_subscribe({
  --       onInteractionScheduledWorkCompleted,
  --       onInteractionTraced: jest.fn(),
  --       onWorkCanceled,
  --       onWorkScheduled: jest.fn(),
  --       onWorkStarted: jest.fn(),
  --       onWorkStopped: jest.fn(),
  --     })

  --     local _updateCount
  --     function Counter(props)
  --       local [count, updateCount] = useState(0)
  --       _updateCount = updateCount
  --       useEffect(function()
  --         expect(SchedulerTracing.unstable_getCurrent()).toMatchInteractions([
  --           tracingEvent,
  --         ])
  --         Scheduler.unstable_yieldValue(`Will set count to 1`)
  --         updateCount(1)
  --       }, [])
  --       return <Text text={'Count: ' + count} />
  --     end

  --     local tracingEvent = {id: 0, name: 'hello', timestamp: 0}
  --     -- we explicitly wait for missing act() warnings here since
  --     -- it's a lot harder to simulate this condition inside an act scope
  --     expect(function()
  --       SchedulerTracing.unstable_trace(
  --         tracingEvent.name,
  --         tracingEvent.timestamp,
  --         function()
  --           ReactNoop.render(<Counter count={0} />, function()
  --             Scheduler.unstable_yieldValue('Sync effect'),
  --           )
  --         },
  --       )
  --       expect(Scheduler).toFlushAndYieldThrough(['Count: 0', 'Sync effect'])
  --       expect(ReactNoop.getChildren()).toEqual([span('Count: 0')])
  --     }).toErrorDev(['An update to Counter ran an effect'])

  --     expect(onInteractionScheduledWorkCompleted).toHaveBeenCalledTimes(0)

  --     -- A flush sync doesn't cause the passive effects to fire.
  --     act(function()
  --       ReactNoop.flushSync(function()
  --         _updateCount(2)
  --       })
  --     })

  --     expect(Scheduler).toHaveYielded([
  --       'Will set count to 1',
  --       'Count: 2',
  --       'Count: 1',
  --     ])

  --     expect(ReactNoop.getChildren()).toEqual([span('Count: 1')])

  --     expect(onInteractionScheduledWorkCompleted).toHaveBeenCalledTimes(1)
  --     expect(onWorkCanceled).toHaveBeenCalledTimes(0)
  --   })

  --   it(
  --     'in legacy mode, useEffect is deferred and updates finish synchronously ' +
  --       '(in a single batch)',
  --     function()
  --       function Counter(props)
  --         local [count, updateCount] = useState('(empty)')
  --         useEffect(function()
  --           -- Update multiple times. These should all be batched together in
  --           -- a single render.
  --           updateCount(props.count)
  --           updateCount(props.count)
  --           updateCount(props.count)
  --           updateCount(props.count)
  --           updateCount(props.count)
  --           updateCount(props.count)
  --         }, [props.count])
  --         return <Text text={'Count: ' + count} />
  --       end
  --       act(function()
  --         ReactNoop.renderLegacySyncRoot(<Counter count={0} />)
  --         -- Even in legacy mode, effects are deferred until after paint
  --         expect(Scheduler).toFlushAndYieldThrough(['Count: (empty)'])
  --         expect(ReactNoop.getChildren()).toEqual([span('Count: (empty)')])
  --       })

  --       -- effects get forced on exiting act()
  --       -- There were multiple updates, but there should only be a
  --       -- single render
  --       expect(Scheduler).toHaveYielded(['Count: 0'])
  --       expect(ReactNoop.getChildren()).toEqual([span('Count: 0')])
  --     },
  --   )

  --   it('flushSync is not allowed', function()
  --     function Counter(props)
  --       local [count, updateCount] = useState('(empty)')
  --       useEffect(function()
  --         Scheduler.unstable_yieldValue(`Schedule update [${props.count}]`)
  --         ReactNoop.flushSync(function()
  --           updateCount(props.count)
  --         })
  --         -- This shouldn't flush synchronously.
  --         expect(ReactNoop.getChildren()).not.toEqual([
  --           span('Count: ' + props.count),
  --         ])
  --       }, [props.count])
  --       return <Text text={'Count: ' + count} />
  --     end
  --     expect(function()
  --       act(function()
  --         ReactNoop.render(<Counter count={0} />, function()
  --           Scheduler.unstable_yieldValue('Sync effect'),
  --         )
  --         expect(Scheduler).toFlushAndYieldThrough([
  --           'Count: (empty)',
  --           'Sync effect',
  --         ])
  --         expect(ReactNoop.getChildren()).toEqual([span('Count: (empty)')])
  --       }),
  --     ).toErrorDev('flushSync was called from inside a lifecycle method')
  --     expect(ReactNoop.getChildren()).toEqual([span('Count: 0')])
  --   })

    it('unmounts previous effect', function()
      -- FIXME: type of expect
      local expect: any = expect
      local function Counter(props)
        useEffect(function()
          Scheduler.unstable_yieldValue("Did create [" .. tostring(props.count) .. "]")
          return function()
            Scheduler.unstable_yieldValue("Did destroy [" .. tostring(props.count) .. "]")
          end
        end)
        return React.createElement(Text, {text = 'Count: ' .. props.count})
      end
      act(function()
        ReactNoop.render(
          React.createElement(Counter, {count = 0}),
          function()
            Scheduler.unstable_yieldValue('Sync effect')
          end
        )
        expect(Scheduler).toFlushAndYieldThrough({'Count: 0', 'Sync effect'})
        expect(ReactNoop.getChildren()).toEqual({span('Count: 0')})
      end)

      expect(Scheduler).toHaveYielded({'Did create [0]'})

      act(function()
        ReactNoop.render(
          React.createElement(Counter, {count = 1}),
          function()
            Scheduler.unstable_yieldValue('Sync effect')
          end
        )
        expect(Scheduler).toFlushAndYieldThrough({'Count: 1', 'Sync effect'})
        expect(ReactNoop.getChildren()).toEqual({span('Count: 1')})
      end)

      expect(Scheduler).toHaveYielded({'Did destroy [0]', 'Did create [1]'})
    end)

    -- ROBLOX FIXME: this fails because ReactFiberReconciler sets update.payload to nil, which removes the key
    it('unmounts on deletion', function()
      -- FIXME: type of expect
      local expect: any = expect
      local function Counter(props)
        useEffect(function()
          Scheduler.unstable_yieldValue("Did create [" .. tostring(props.count)  .. "]")
          return function()
            Scheduler.unstable_yieldValue("Did destroy [" .. tostring(props.count) .. "]")
          end
        end)
        return React.createElement(Text, {text = 'Count: ' .. tostring(props.count)})
      end
      act(function()
        ReactNoop.render(
          React.createElement(Counter, {count = 0}),
          function()
            Scheduler.unstable_yieldValue('Sync effect')
          end
        )
        expect(Scheduler).toFlushAndYieldThrough({'Count: 0', 'Sync effect'})
        expect(ReactNoop.getChildren()).toEqual({span('Count: 0')})
      end)

      expect(Scheduler).toHaveYielded({'Did create [0]'})

      ReactNoop.render(nil)
      expect(Scheduler).toFlushAndYield({'Did destroy [0]'})
      expect(ReactNoop.getChildren()).toEqual({})
    end)

  --   it('unmounts on deletion after skipped effect', function()
  --     function Counter(props)
  --       useEffect(function()
  --         Scheduler.unstable_yieldValue(`Did create [${props.count}]`)
  --         return function()
  --           Scheduler.unstable_yieldValue(`Did destroy [${props.count}]`)
  --         end
  --       }, [])
  --       return <Text text={'Count: ' + props.count} />
  --     end
  --     act(function()
  --       ReactNoop.render(<Counter count={0} />, function()
  --         Scheduler.unstable_yieldValue('Sync effect'),
  --       )
  --       expect(Scheduler).toFlushAndYieldThrough(['Count: 0', 'Sync effect'])
  --       expect(ReactNoop.getChildren()).toEqual([span('Count: 0')])
  --     })

  --     expect(Scheduler).toHaveYielded(['Did create [0]'])

  --     act(function()
  --       ReactNoop.render(<Counter count={1} />, function()
  --         Scheduler.unstable_yieldValue('Sync effect'),
  --       )
  --       expect(Scheduler).toFlushAndYieldThrough(['Count: 1', 'Sync effect'])
  --       expect(ReactNoop.getChildren()).toEqual([span('Count: 1')])
  --     })

  --     expect(Scheduler).toHaveYielded([])

  --     ReactNoop.render(null)
  --     expect(Scheduler).toFlushAndYield(['Did destroy [0]'])
  --     expect(ReactNoop.getChildren()).toEqual([])
  --   })

  --   it('always fires effects if no dependencies are provided', function()
  --     function effect()
  --       Scheduler.unstable_yieldValue(`Did create`)
  --       return function()
  --         Scheduler.unstable_yieldValue(`Did destroy`)
  --       end
  --     end
  --     function Counter(props)
  --       useEffect(effect)
  --       return <Text text={'Count: ' + props.count} />
  --     end
  --     act(function()
  --       ReactNoop.render(<Counter count={0} />, function()
  --         Scheduler.unstable_yieldValue('Sync effect'),
  --       )
  --       expect(Scheduler).toFlushAndYieldThrough(['Count: 0', 'Sync effect'])
  --       expect(ReactNoop.getChildren()).toEqual([span('Count: 0')])
  --     })

  --     expect(Scheduler).toHaveYielded(['Did create'])

  --     act(function()
  --       ReactNoop.render(<Counter count={1} />, function()
  --         Scheduler.unstable_yieldValue('Sync effect'),
  --       )
  --       expect(Scheduler).toFlushAndYieldThrough(['Count: 1', 'Sync effect'])
  --       expect(ReactNoop.getChildren()).toEqual([span('Count: 1')])
  --     })

  --     expect(Scheduler).toHaveYielded(['Did destroy', 'Did create'])

  --     ReactNoop.render(null)
  --     expect(Scheduler).toFlushAndYield(['Did destroy'])
  --     expect(ReactNoop.getChildren()).toEqual([])
  --   })

    it('skips effect if inputs have not changed', function()
      -- FIXME: type of expect
      local expect: any = expect

      local function Counter(props)
        local text = tostring(props.label) .. ": " .. tostring(props.count)
        useEffect(function()
          Scheduler.unstable_yieldValue("Did create [" .. text .. "]")
          return function()
            Scheduler.unstable_yieldValue("Did destroy [" .. text .. "]")
          end
        end, {props.label, props.count})
        return React.createElement(Text, {text=text})
      end
      act(function()
        ReactNoop.render(
          React.createElement(Counter, {label = "Count", count = 0}),
          function()
            Scheduler.unstable_yieldValue('Sync effect')
          end
        )
        expect(Scheduler).toFlushAndYieldThrough({'Count: 0', 'Sync effect'})
      end)

      expect(Scheduler).toHaveYielded({'Did create [Count: 0]'})
      expect(ReactNoop.getChildren()).toEqual({span('Count: 0')})

      act(function()
        ReactNoop.render(
          React.createElement(Counter, {label="Count", count=1}),
          function()
            Scheduler.unstable_yieldValue('Sync effect')
          end
        )
        -- Count changed
        expect(Scheduler).toFlushAndYieldThrough({'Count: 1', 'Sync effect'})
        expect(ReactNoop.getChildren()).toEqual({span('Count: 1')})
      end)

      expect(Scheduler).toHaveYielded({
        'Did destroy [Count: 0]',
        'Did create [Count: 1]',
      })


      act(function()
        ReactNoop.render(
          React.createElement(Counter, {label="Count", count=1}),
          function()
            Scheduler.unstable_yieldValue('Sync effect')
          end
        )
        -- Nothing changed, so no effect should have fired
        expect(Scheduler).toFlushAndYieldThrough({'Count: 1', 'Sync effect'})
      end)

      -- ROBLOX FIXME: Scheduler yields a table with two entries instead of empty
      expect(Scheduler).toHaveYielded({})
      expect(ReactNoop.getChildren()).toEqual({span('Count: 1')})

      act(function()
        ReactNoop.render(
          React.createElement(Counter, {label="Total", count=1}),
          function()
            Scheduler.unstable_yieldValue('Sync effect')
          end
        )
        -- Label changed
        expect(Scheduler).toFlushAndYieldThrough({'Total: 1', 'Sync effect'})
        expect(ReactNoop.getChildren()).toEqual({span('Total: 1')})
      end)

      expect(Scheduler).toHaveYielded({
        'Did destroy [Count: 1]',
        'Did create [Total: 1]',
      })
    end)

    -- ROBLOX FIXME: errors with "rendered more hooks than the previous render", maybe needs throwException?
    -- upstream prints `yields Sync Effect`, `renders`, and `flushes`. we only print `renders`
    xit('multiple effects', function()
      -- FIXME: type of expect
      local expect: any = expect
      local function Counter(props)
        useEffect(function()
          Scheduler.unstable_yieldValue("Did commit 1 [" .. tostring(props.count) .. "]")
        end)
        useEffect(function()
          Scheduler.unstable_yieldValue("Did commit 2 [" .. tostring(props.count) .. "]")
        end)
        return React.createElement(Text, {text='Count: ' .. tostring(props.count)})
      end
      act(function()
        ReactNoop.render(
          React.createElement(Counter, {count=0}),
          function()
            Scheduler.unstable_yieldValue('Sync effect')
          end
        )
        expect(Scheduler).toFlushAndYieldThrough({'Count: 0', 'Sync effect'})
        expect(ReactNoop.getChildren()).toEqual({span('Count: 0')})
      end)

      expect(Scheduler).toHaveYielded({'Did commit 1 [0]', 'Did commit 2 [0]'})

      act(function()
        ReactNoop.render(
          React.createElement(Counter, {count=1}),
          function()
            Scheduler.unstable_yieldValue('Sync effect')
          end
        )
        expect(Scheduler).toFlushAndYieldThrough({'Count: 1', 'Sync effect'})
        expect(ReactNoop.getChildren()).toEqual({span('Count: 1')})
      end)
      expect(Scheduler).toHaveYielded({'Did commit 1 [1]', 'Did commit 2 [1]'})
    end)

  --   it('unmounts all previous effects before creating any new ones', function()
  --     function Counter(props)
  --       useEffect(function()
  --         Scheduler.unstable_yieldValue(`Mount A [${props.count}]`)
  --         return function()
  --           Scheduler.unstable_yieldValue(`Unmount A [${props.count}]`)
  --         end
  --       })
  --       useEffect(function()
  --         Scheduler.unstable_yieldValue(`Mount B [${props.count}]`)
  --         return function()
  --           Scheduler.unstable_yieldValue(`Unmount B [${props.count}]`)
  --         end
  --       })
  --       return <Text text={'Count: ' + props.count} />
  --     end
  --     act(function()
  --       ReactNoop.render(<Counter count={0} />, function()
  --         Scheduler.unstable_yieldValue('Sync effect'),
  --       )
  --       expect(Scheduler).toFlushAndYieldThrough(['Count: 0', 'Sync effect'])
  --       expect(ReactNoop.getChildren()).toEqual([span('Count: 0')])
  --     })

  --     expect(Scheduler).toHaveYielded(['Mount A [0]', 'Mount B [0]'])

  --     act(function()
  --       ReactNoop.render(<Counter count={1} />, function()
  --         Scheduler.unstable_yieldValue('Sync effect'),
  --       )
  --       expect(Scheduler).toFlushAndYieldThrough(['Count: 1', 'Sync effect'])
  --       expect(ReactNoop.getChildren()).toEqual([span('Count: 1')])
  --     })
  --     expect(Scheduler).toHaveYielded([
  --       'Unmount A [0]',
  --       'Unmount B [0]',
  --       'Mount A [1]',
  --       'Mount B [1]',
  --     ])
  --   })

  --   it('unmounts all previous effects between siblings before creating any new ones', function()
  --     function Counter({count, label})
  --       useEffect(function()
  --         Scheduler.unstable_yieldValue(`Mount ${label} [${count}]`)
  --         return function()
  --           Scheduler.unstable_yieldValue(`Unmount ${label} [${count}]`)
  --         end
  --       })
  --       return <Text text={`${label} ${count}`} />
  --     end
  --     act(function()
  --       ReactNoop.render(
  --         <>
  --           <Counter label="A" count={0} />
  --           <Counter label="B" count={0} />
  --         </>,
  --         function() Scheduler.unstable_yieldValue('Sync effect'),
  --       )
  --       expect(Scheduler).toFlushAndYieldThrough(['A 0', 'B 0', 'Sync effect'])
  --       expect(ReactNoop.getChildren()).toEqual([span('A 0'), span('B 0')])
  --     })

  --     expect(Scheduler).toHaveYielded(['Mount A [0]', 'Mount B [0]'])

  --     act(function()
  --       ReactNoop.render(
  --         <>
  --           <Counter label="A" count={1} />
  --           <Counter label="B" count={1} />
  --         </>,
  --         function() Scheduler.unstable_yieldValue('Sync effect'),
  --       )
  --       expect(Scheduler).toFlushAndYieldThrough(['A 1', 'B 1', 'Sync effect'])
  --       expect(ReactNoop.getChildren()).toEqual([span('A 1'), span('B 1')])
  --     })
  --     expect(Scheduler).toHaveYielded([
  --       'Unmount A [0]',
  --       'Unmount B [0]',
  --       'Mount A [1]',
  --       'Mount B [1]',
  --     ])

  --     act(function()
  --       ReactNoop.render(
  --         <>
  --           <Counter label="B" count={2} />
  --           <Counter label="C" count={0} />
  --         </>,
  --         function() Scheduler.unstable_yieldValue('Sync effect'),
  --       )
  --       expect(Scheduler).toFlushAndYieldThrough(['B 2', 'C 0', 'Sync effect'])
  --       expect(ReactNoop.getChildren()).toEqual([span('B 2'), span('C 0')])
  --     })
  --     expect(Scheduler).toHaveYielded([
  --       'Unmount A [1]',
  --       'Unmount B [1]',
  --       'Mount B [2]',
  --       'Mount C [0]',
  --     ])
  --   })

  --   it('handles errors in create on mount', function()
  --     function Counter(props)
  --       useEffect(function()
  --         Scheduler.unstable_yieldValue(`Mount A [${props.count}]`)
  --         return function()
  --           Scheduler.unstable_yieldValue(`Unmount A [${props.count}]`)
  --         end
  --       })
  --       useEffect(function()
  --         Scheduler.unstable_yieldValue('Oops!')
  --         throw new Error('Oops!')
  --         -- eslint-disable-next-line no-unreachable
  --         Scheduler.unstable_yieldValue(`Mount B [${props.count}]`)
  --         return function()
  --           Scheduler.unstable_yieldValue(`Unmount B [${props.count}]`)
  --         end
  --       })
  --       return <Text text={'Count: ' + props.count} />
  --     end
  --     act(function()
  --       ReactNoop.render(<Counter count={0} />, function()
  --         Scheduler.unstable_yieldValue('Sync effect'),
  --       )
  --       expect(Scheduler).toFlushAndYieldThrough(['Count: 0', 'Sync effect'])
  --       expect(ReactNoop.getChildren()).toEqual([span('Count: 0')])
  --       expect(function() ReactNoop.flushPassiveEffects()).toThrow('Oops')
  --     })

  --     expect(Scheduler).toHaveYielded([
  --       'Mount A [0]',
  --       'Oops!',
  --       -- Clean up effect A. There's no effect B to clean-up, because it
  --       -- never mounted.
  --       'Unmount A [0]',
  --     ])
  --     expect(ReactNoop.getChildren()).toEqual([])
  --   })

  --   it('handles errors in create on update', function()
  --     function Counter(props)
  --       useEffect(function()
  --         Scheduler.unstable_yieldValue(`Mount A [${props.count}]`)
  --         return function()
  --           Scheduler.unstable_yieldValue(`Unmount A [${props.count}]`)
  --         end
  --       })
  --       useEffect(function()
  --         if props.count == 1)
  --           Scheduler.unstable_yieldValue('Oops!')
  --           throw new Error('Oops!')
  --         end
  --         Scheduler.unstable_yieldValue(`Mount B [${props.count}]`)
  --         return function()
  --           Scheduler.unstable_yieldValue(`Unmount B [${props.count}]`)
  --         end
  --       })
  --       return <Text text={'Count: ' + props.count} />
  --     end
  --     act(function()
  --       ReactNoop.render(<Counter count={0} />, function()
  --         Scheduler.unstable_yieldValue('Sync effect'),
  --       )
  --       expect(Scheduler).toFlushAndYieldThrough(['Count: 0', 'Sync effect'])
  --       expect(ReactNoop.getChildren()).toEqual([span('Count: 0')])
  --       ReactNoop.flushPassiveEffects()
  --       expect(Scheduler).toHaveYielded(['Mount A [0]', 'Mount B [0]'])
  --     })

  --     act(function()
  --       -- This update will trigger an error
  --       ReactNoop.render(<Counter count={1} />, function()
  --         Scheduler.unstable_yieldValue('Sync effect'),
  --       )
  --       expect(Scheduler).toFlushAndYieldThrough(['Count: 1', 'Sync effect'])
  --       expect(ReactNoop.getChildren()).toEqual([span('Count: 1')])
  --       expect(function() ReactNoop.flushPassiveEffects()).toThrow('Oops')
  --       expect(Scheduler).toHaveYielded([
  --         'Unmount A [0]',
  --         'Unmount B [0]',
  --         'Mount A [1]',
  --         'Oops!',
  --       ])
  --       expect(ReactNoop.getChildren()).toEqual([])
  --     })
  --     expect(Scheduler).toHaveYielded([
  --       -- Clean up effect A runs passively on unmount.
  --       -- There's no effect B to clean-up, because it never mounted.
  --       'Unmount A [1]',
  --     ])
  --   })

  --   it('handles errors in destroy on update', function()
  --     function Counter(props)
  --       useEffect(function()
  --         Scheduler.unstable_yieldValue(`Mount A [${props.count}]`)
  --         return function()
  --           Scheduler.unstable_yieldValue('Oops!')
  --           if props.count == 0)
  --             throw new Error('Oops!')
  --           end
  --         end
  --       })
  --       useEffect(function()
  --         Scheduler.unstable_yieldValue(`Mount B [${props.count}]`)
  --         return function()
  --           Scheduler.unstable_yieldValue(`Unmount B [${props.count}]`)
  --         end
  --       })
  --       return <Text text={'Count: ' + props.count} />
  --     end

  --     act(function()
  --       ReactNoop.render(<Counter count={0} />, function()
  --         Scheduler.unstable_yieldValue('Sync effect'),
  --       )
  --       expect(Scheduler).toFlushAndYieldThrough(['Count: 0', 'Sync effect'])
  --       expect(ReactNoop.getChildren()).toEqual([span('Count: 0')])
  --       ReactNoop.flushPassiveEffects()
  --       expect(Scheduler).toHaveYielded(['Mount A [0]', 'Mount B [0]'])
  --     })

  --     act(function()
  --       -- This update will trigger an error during passive effect unmount
  --       ReactNoop.render(<Counter count={1} />, function()
  --         Scheduler.unstable_yieldValue('Sync effect'),
  --       )
  --       expect(Scheduler).toFlushAndYieldThrough(['Count: 1', 'Sync effect'])
  --       expect(ReactNoop.getChildren()).toEqual([span('Count: 1')])
  --       expect(function() ReactNoop.flushPassiveEffects()).toThrow('Oops')

  --       -- This branch enables a feature flag that flushes all passive destroys in a
  --       -- separate pass before flushing any passive creates.
  --       -- A result of this two-pass flush is that an error thrown from unmount does
  --       -- not block the subsequent create functions from being run.
  --       expect(Scheduler).toHaveYielded([
  --         'Oops!',
  --         'Unmount B [0]',
  --         'Mount A [1]',
  --         'Mount B [1]',
  --       ])
  --     })

  --     -- <Counter> gets unmounted because an error is thrown above.
  --     -- The remaining destroy functions are run later on unmount, since they're passive.
  --     -- In this case, one of them throws again (because of how the test is written).
  --     expect(Scheduler).toHaveYielded(['Oops!', 'Unmount B [1]'])
  --     expect(ReactNoop.getChildren()).toEqual([])
  --   })

  --   it('works with memo', function()
  --     function Counter({count})
  --       useLayoutEffect(function()
  --         Scheduler.unstable_yieldValue('Mount: ' + count)
  --         return function() Scheduler.unstable_yieldValue('Unmount: ' + count)
  --       })
  --       return <Text text={'Count: ' + count} />
  --     end
  --     Counter = memo(Counter)

  --     ReactNoop.render(<Counter count={0} />, function()
  --       Scheduler.unstable_yieldValue('Sync effect'),
  --     )
  --     expect(Scheduler).toFlushAndYieldThrough([
  --       'Count: 0',
  --       'Mount: 0',
  --       'Sync effect',
  --     ])
  --     expect(ReactNoop.getChildren()).toEqual([span('Count: 0')])

  --     ReactNoop.render(<Counter count={1} />, function()
  --       Scheduler.unstable_yieldValue('Sync effect'),
  --     )
  --     expect(Scheduler).toFlushAndYieldThrough([
  --       'Count: 1',
  --       'Unmount: 0',
  --       'Mount: 1',
  --       'Sync effect',
  --     ])
  --     expect(ReactNoop.getChildren()).toEqual([span('Count: 1')])

  --     ReactNoop.render(null)
  --     expect(Scheduler).toFlushAndYieldThrough(['Unmount: 1'])
  --     expect(ReactNoop.getChildren()).toEqual([])
  --   })

  --   describe('errors thrown in passive destroy function within unmounted trees', function()
  --     local BrokenUseEffectCleanup
  --     local ErrorBoundary
  --     local DerivedStateOnlyErrorBoundary
  --     local LogOnlyErrorBoundary

  --     beforeEach(function()
  --       BrokenUseEffectCleanup = function()
  --         useEffect(function()
  --           Scheduler.unstable_yieldValue('BrokenUseEffectCleanup useEffect')
  --           return function()
  --             Scheduler.unstable_yieldValue(
  --               'BrokenUseEffectCleanup useEffect destroy',
  --             )
  --             throw new Error('Expected error')
  --           end
  --         }, [])

  --         return 'inner child'
  --       end

  --       ErrorBoundary = class extends React.Component {
  --         state = {error: nil}
  --         static getDerivedStateFromError(error)
  --           Scheduler.unstable_yieldValue(
  --             `ErrorBoundary static getDerivedStateFromError`,
  --           )
  --           return {error}
  --         end
  --         componentDidCatch(error, info)
  --           Scheduler.unstable_yieldValue(`ErrorBoundary componentDidCatch`)
  --         end
  --         render()
  --           if this.state.error)
  --             Scheduler.unstable_yieldValue('ErrorBoundary render error')
  --             return <span prop="ErrorBoundary fallback" />
  --           end
  --           Scheduler.unstable_yieldValue('ErrorBoundary render success')
  --           return this.props.children or nil
  --         end
  --       end

  --       DerivedStateOnlyErrorBoundary = class extends React.Component {
  --         state = {error: nil}
  --         static getDerivedStateFromError(error)
  --           Scheduler.unstable_yieldValue(
  --             `DerivedStateOnlyErrorBoundary static getDerivedStateFromError`,
  --           )
  --           return {error}
  --         end
  --         render()
  --           if this.state.error)
  --             Scheduler.unstable_yieldValue(
  --               'DerivedStateOnlyErrorBoundary render error',
  --             )
  --             return <span prop="DerivedStateOnlyErrorBoundary fallback" />
  --           end
  --           Scheduler.unstable_yieldValue(
  --             'DerivedStateOnlyErrorBoundary render success',
  --           )
  --           return this.props.children or nil
  --         end
  --       end

  --       LogOnlyErrorBoundary = class extends React.Component {
  --         componentDidCatch(error, info)
  --           Scheduler.unstable_yieldValue(
  --             `LogOnlyErrorBoundary componentDidCatch`,
  --           )
  --         end
  --         render()
  --           Scheduler.unstable_yieldValue(`LogOnlyErrorBoundary render`)
  --           return this.props.children or nil
  --         end
  --       end
  --     })

  --     -- @gate old
  --     it('should call componentDidCatch() for the nearest unmounted log-only boundary', function()
  --       function Conditional({showChildren})
  --         if showChildren)
  --           return (
  --             <LogOnlyErrorBoundary>
  --               <BrokenUseEffectCleanup />
  --             </LogOnlyErrorBoundary>
  --           )
  --         } else {
  --           return nil
  --         end
  --       end

  --       act(function()
  --         ReactNoop.render(
  --           <ErrorBoundary>
  --             <Conditional showChildren={true} />
  --           </ErrorBoundary>,
  --         )
  --       })

  --       expect(Scheduler).toHaveYielded([
  --         'ErrorBoundary render success',
  --         'LogOnlyErrorBoundary render',
  --         'BrokenUseEffectCleanup useEffect',
  --       ])

  --       act(function()
  --         ReactNoop.render(
  --           <ErrorBoundary>
  --             <Conditional showChildren={false} />
  --           </ErrorBoundary>,
  --         )
  --         expect(Scheduler).toFlushAndYieldThrough([
  --           'ErrorBoundary render success',
  --         ])
  --       })

  --       expect(Scheduler).toHaveYielded([
  --         'BrokenUseEffectCleanup useEffect destroy',
  --         'LogOnlyErrorBoundary componentDidCatch',
  --       ])
  --     })

  --     -- @gate old
  --     it('should call componentDidCatch() for the nearest unmounted logging-capable boundary', function()
  --       function Conditional({showChildren})
  --         if showChildren)
  --           return (
  --             <ErrorBoundary>
  --               <BrokenUseEffectCleanup />
  --             </ErrorBoundary>
  --           )
  --         } else {
  --           return nil
  --         end
  --       end

  --       act(function()
  --         ReactNoop.render(
  --           <ErrorBoundary>
  --             <Conditional showChildren={true} />
  --           </ErrorBoundary>,
  --         )
  --       })

  --       expect(Scheduler).toHaveYielded([
  --         'ErrorBoundary render success',
  --         'ErrorBoundary render success',
  --         'BrokenUseEffectCleanup useEffect',
  --       ])

  --       act(function()
  --         ReactNoop.render(
  --           <ErrorBoundary>
  --             <Conditional showChildren={false} />
  --           </ErrorBoundary>,
  --         )
  --         expect(Scheduler).toFlushAndYieldThrough([
  --           'ErrorBoundary render success',
  --         ])
  --       })

  --       expect(Scheduler).toHaveYielded([
  --         'BrokenUseEffectCleanup useEffect destroy',
  --         'ErrorBoundary componentDidCatch',
  --       ])
  --     })

  --     -- @gate old
  --     it('should not call getDerivedStateFromError for unmounted error boundaries', function()
  --       function Conditional({showChildren})
  --         if showChildren)
  --           return (
  --             <ErrorBoundary>
  --               <BrokenUseEffectCleanup />
  --             </ErrorBoundary>
  --           )
  --         } else {
  --           return nil
  --         end
  --       end

  --       act(function()
  --         ReactNoop.render(<Conditional showChildren={true} />)
  --       })

  --       expect(Scheduler).toHaveYielded([
  --         'ErrorBoundary render success',
  --         'BrokenUseEffectCleanup useEffect',
  --       ])

  --       act(function()
  --         ReactNoop.render(<Conditional showChildren={false} />)
  --       })

  --       expect(Scheduler).toHaveYielded([
  --         'BrokenUseEffectCleanup useEffect destroy',
  --         'ErrorBoundary componentDidCatch',
  --       ])
  --     })

  --     -- @gate old
  --     it('should not throw if there are no unmounted logging-capable boundaries to call', function()
  --       function Conditional({showChildren})
  --         if showChildren)
  --           return (
  --             <DerivedStateOnlyErrorBoundary>
  --               <BrokenUseEffectCleanup />
  --             </DerivedStateOnlyErrorBoundary>
  --           )
  --         } else {
  --           return nil
  --         end
  --       end

  --       act(function()
  --         ReactNoop.render(<Conditional showChildren={true} />)
  --       })

  --       expect(Scheduler).toHaveYielded([
  --         'DerivedStateOnlyErrorBoundary render success',
  --         'BrokenUseEffectCleanup useEffect',
  --       ])

  --       act(function()
  --         ReactNoop.render(<Conditional showChildren={false} />)
  --       })

  --       expect(Scheduler).toHaveYielded([
  --         'BrokenUseEffectCleanup useEffect destroy',
  --       ])
  --     })

  --     -- @gate new
  --     it('should use the nearest still-mounted boundary if there are no unmounted boundaries', function()
  --       act(function()
  --         ReactNoop.render(
  --           <LogOnlyErrorBoundary>
  --             <BrokenUseEffectCleanup />
  --           </LogOnlyErrorBoundary>,
  --         )
  --       })

  --       expect(Scheduler).toHaveYielded([
  --         'LogOnlyErrorBoundary render',
  --         'BrokenUseEffectCleanup useEffect',
  --       ])

  --       act(function()
  --         ReactNoop.render(<LogOnlyErrorBoundary />)
  --       })

  --       expect(Scheduler).toHaveYielded([
  --         'LogOnlyErrorBoundary render',
  --         'BrokenUseEffectCleanup useEffect destroy',
  --         'LogOnlyErrorBoundary componentDidCatch',
  --       ])
  --     })

  --     -- @gate new
  --     it('should skip unmounted boundaries and use the nearest still-mounted boundary', function()
  --       function Conditional({showChildren})
  --         if showChildren)
  --           return (
  --             <ErrorBoundary>
  --               <BrokenUseEffectCleanup />
  --             </ErrorBoundary>
  --           )
  --         } else {
  --           return nil
  --         end
  --       end

  --       act(function()
  --         ReactNoop.render(
  --           <LogOnlyErrorBoundary>
  --             <Conditional showChildren={true} />
  --           </LogOnlyErrorBoundary>,
  --         )
  --       })

  --       expect(Scheduler).toHaveYielded([
  --         'LogOnlyErrorBoundary render',
  --         'ErrorBoundary render success',
  --         'BrokenUseEffectCleanup useEffect',
  --       ])

  --       act(function()
  --         ReactNoop.render(
  --           <LogOnlyErrorBoundary>
  --             <Conditional showChildren={false} />
  --           </LogOnlyErrorBoundary>,
  --         )
  --       })

  --       expect(Scheduler).toHaveYielded([
  --         'LogOnlyErrorBoundary render',
  --         'BrokenUseEffectCleanup useEffect destroy',
  --         'LogOnlyErrorBoundary componentDidCatch',
  --       ])
  --     })

  --     -- @gate new
  --     it('should call getDerivedStateFromError in the nearest still-mounted boundary', function()
  --       function Conditional({showChildren})
  --         if showChildren)
  --           return <BrokenUseEffectCleanup />
  --         } else {
  --           return nil
  --         end
  --       end

  --       act(function()
  --         ReactNoop.render(
  --           <ErrorBoundary>
  --             <Conditional showChildren={true} />
  --           </ErrorBoundary>,
  --         )
  --       })

  --       expect(Scheduler).toHaveYielded([
  --         'ErrorBoundary render success',
  --         'BrokenUseEffectCleanup useEffect',
  --       ])

  --       act(function()
  --         ReactNoop.render(
  --           <ErrorBoundary>
  --             <Conditional showChildren={false} />
  --           </ErrorBoundary>,
  --         )
  --       })

  --       expect(Scheduler).toHaveYielded([
  --         'ErrorBoundary render success',
  --         'BrokenUseEffectCleanup useEffect destroy',
  --         'ErrorBoundary static getDerivedStateFromError',
  --         'ErrorBoundary render error',
  --         'ErrorBoundary componentDidCatch',
  --       ])

  --       expect(ReactNoop.getChildren()).toEqual([
  --         span('ErrorBoundary fallback'),
  --       ])
  --     })

  --     -- @gate new
  --     it('should rethrow error if there are no still-mounted boundaries', function()
  --       function Conditional({showChildren})
  --         if showChildren)
  --           return (
  --             <ErrorBoundary>
  --               <BrokenUseEffectCleanup />
  --             </ErrorBoundary>
  --           )
  --         } else {
  --           return nil
  --         end
  --       end

  --       act(function()
  --         ReactNoop.render(<Conditional showChildren={true} />)
  --       })

  --       expect(Scheduler).toHaveYielded([
  --         'ErrorBoundary render success',
  --         'BrokenUseEffectCleanup useEffect',
  --       ])

  --       expect(function()
  --         act(function()
  --           ReactNoop.render(<Conditional showChildren={false} />)
  --         })
  --       }).toThrow('Expected error')

  --       expect(Scheduler).toHaveYielded([
  --         'BrokenUseEffectCleanup useEffect destroy',
  --       ])

  --       expect(ReactNoop.getChildren()).toEqual([])
  --     })
  --   })

  --   it('calls passive effect destroy functions for memoized components', function()
  --     local Wrapper = ({children}) => children
  --     function Child()
  --       React.useEffect(function()
  --         Scheduler.unstable_yieldValue('passive create')
  --         return function()
  --           Scheduler.unstable_yieldValue('passive destroy')
  --         end
  --       }, [])
  --       React.useLayoutEffect(function()
  --         Scheduler.unstable_yieldValue('layout create')
  --         return function()
  --           Scheduler.unstable_yieldValue('layout destroy')
  --         end
  --       }, [])
  --       Scheduler.unstable_yieldValue('render')
  --       return nil
  --     end

  --     local isEqual = (prevProps, nextProps) =>
  --       prevProps.prop == nextProps.prop
  --     local MemoizedChild = React.memo(Child, isEqual)

  --     act(function()
  --       ReactNoop.render(
  --         <Wrapper>
  --           <MemoizedChild key={1} />
  --         </Wrapper>,
  --       )
  --     })
  --     expect(Scheduler).toHaveYielded([
  --       'render',
  --       'layout create',
  --       'passive create',
  --     ])

  --     -- Include at least one no-op (memoized) update to trigger original bug.
  --     act(function()
  --       ReactNoop.render(
  --         <Wrapper>
  --           <MemoizedChild key={1} />
  --         </Wrapper>,
  --       )
  --     })
  --     expect(Scheduler).toHaveYielded([])

  --     act(function()
  --       ReactNoop.render(
  --         <Wrapper>
  --           <MemoizedChild key={2} />
  --         </Wrapper>,
  --       )
  --     })
  --     expect(Scheduler).toHaveYielded([
  --       'render',
  --       'layout destroy',
  --       'layout create',
  --       'passive destroy',
  --       'passive create',
  --     ])

  --     act(function()
  --       ReactNoop.render(null)
  --     })
  --     expect(Scheduler).toHaveYielded(['layout destroy', 'passive destroy'])
  --   })

  --   it('calls passive effect destroy functions for descendants of memoized components', function()
  --     local Wrapper = ({children}) => children
  --     function Child()
  --       return <Grandchild />
  --     end

  --     function Grandchild()
  --       React.useEffect(function()
  --         Scheduler.unstable_yieldValue('passive create')
  --         return function()
  --           Scheduler.unstable_yieldValue('passive destroy')
  --         end
  --       }, [])
  --       React.useLayoutEffect(function()
  --         Scheduler.unstable_yieldValue('layout create')
  --         return function()
  --           Scheduler.unstable_yieldValue('layout destroy')
  --         end
  --       }, [])
  --       Scheduler.unstable_yieldValue('render')
  --       return nil
  --     end

  --     local isEqual = (prevProps, nextProps) =>
  --       prevProps.prop == nextProps.prop
  --     local MemoizedChild = React.memo(Child, isEqual)

  --     act(function()
  --       ReactNoop.render(
  --         <Wrapper>
  --           <MemoizedChild key={1} />
  --         </Wrapper>,
  --       )
  --     })
  --     expect(Scheduler).toHaveYielded([
  --       'render',
  --       'layout create',
  --       'passive create',
  --     ])

  --     -- Include at least one no-op (memoized) update to trigger original bug.
  --     act(function()
  --       ReactNoop.render(
  --         <Wrapper>
  --           <MemoizedChild key={1} />
  --         </Wrapper>,
  --       )
  --     })
  --     expect(Scheduler).toHaveYielded([])

  --     act(function()
  --       ReactNoop.render(
  --         <Wrapper>
  --           <MemoizedChild key={2} />
  --         </Wrapper>,
  --       )
  --     })
  --     expect(Scheduler).toHaveYielded([
  --       'render',
  --       'layout destroy',
  --       'layout create',
  --       'passive destroy',
  --       'passive create',
  --     ])

  --     act(function()
  --       ReactNoop.render(null)
  --     })
  --     expect(Scheduler).toHaveYielded(['layout destroy', 'passive destroy'])
  --   })
  end)

  -- describe('useLayoutEffect', function()
  --   it('fires layout effects after the host has been mutated', function()
  --     function getCommittedText()
  --       local yields = Scheduler.unstable_clearYields()
  --       local children = ReactNoop.getChildren()
  --       Scheduler.unstable_yieldValue(yields)
  --       if children == nil)
  --         return nil
  --       end
  --       return children[0].prop
  --     end

  --     function Counter(props)
  --       useLayoutEffect(function()
  --         Scheduler.unstable_yieldValue(`Current: ${getCommittedText()}`)
  --       })
  --       return <Text text={props.count} />
  --     end

  --     ReactNoop.render(<Counter count={0} />, function()
  --       Scheduler.unstable_yieldValue('Sync effect'),
  --     )
  --     expect(Scheduler).toFlushAndYieldThrough([
  --       [0],
  --       'Current: 0',
  --       'Sync effect',
  --     ])
  --     expect(ReactNoop.getChildren()).toEqual([span(0)])

  --     ReactNoop.render(<Counter count={1} />, function()
  --       Scheduler.unstable_yieldValue('Sync effect'),
  --     )
  --     expect(Scheduler).toFlushAndYieldThrough([
  --       [1],
  --       'Current: 1',
  --       'Sync effect',
  --     ])
  --     expect(ReactNoop.getChildren()).toEqual([span(1)])
  --   })

  --   it('force flushes passive effects before firing new layout effects', function()
  --     local committedText = '(empty)'

  --     function Counter(props)
  --       useLayoutEffect(function()
  --         -- Normally this would go in a mutation effect, but this test
  --         -- intentionally omits a mutation effect.
  --         committedText = props.count + ''

  --         Scheduler.unstable_yieldValue(
  --           `Mount layout [current: ${committedText}]`,
  --         )
  --         return function()
  --           Scheduler.unstable_yieldValue(
  --             `Unmount layout [current: ${committedText}]`,
  --           )
  --         end
  --       })
  --       useEffect(function()
  --         Scheduler.unstable_yieldValue(
  --           `Mount normal [current: ${committedText}]`,
  --         )
  --         return function()
  --           Scheduler.unstable_yieldValue(
  --             `Unmount normal [current: ${committedText}]`,
  --           )
  --         end
  --       })
  --       return nil
  --     end

  --     act(function()
  --       ReactNoop.render(<Counter count={0} />, function()
  --         Scheduler.unstable_yieldValue('Sync effect'),
  --       )
  --       expect(Scheduler).toFlushAndYieldThrough([
  --         'Mount layout [current: 0]',
  --         'Sync effect',
  --       ])
  --       expect(committedText).toEqual('0')
  --       ReactNoop.render(<Counter count={1} />, function()
  --         Scheduler.unstable_yieldValue('Sync effect'),
  --       )
  --       expect(Scheduler).toFlushAndYieldThrough([
  --         'Mount normal [current: 0]',
  --         'Unmount layout [current: 0]',
  --         'Mount layout [current: 1]',
  --         'Sync effect',
  --       ])
  --       expect(committedText).toEqual('1')
  --     })

  --     expect(Scheduler).toHaveYielded([
  --       'Unmount normal [current: 1]',
  --       'Mount normal [current: 1]',
  --     ])
  --   })

  --   -- @gate skipUnmountedBoundaries
  --   it('catches errors thrown in useLayoutEffect', function()
  --     class ErrorBoundary extends React.Component {
  --       state = {error: nil}
  --       static getDerivedStateFromError(error)
  --         Scheduler.unstable_yieldValue(
  --           `ErrorBoundary static getDerivedStateFromError`,
  --         )
  --         return {error}
  --       end
  --       render()
  --         local {children, id, fallbackID} = this.props
  --         local {error} = this.state
  --         if error)
  --           Scheduler.unstable_yieldValue(`${id} render error`)
  --           return <Component id={fallbackID} />
  --         end
  --         Scheduler.unstable_yieldValue(`${id} render success`)
  --         return children or nil
  --       end
  --     end

  --     function Component({id})
  --       Scheduler.unstable_yieldValue('Component render ' + id)
  --       return <span prop={id} />
  --     end

  --     function BrokenLayoutEffectDestroy()
  --       useLayoutEffect(function()
  --         return function()
  --           Scheduler.unstable_yieldValue(
  --             'BrokenLayoutEffectDestroy useLayoutEffect destroy',
  --           )
  --           throw Error('Expected')
  --         end
  --       }, [])

  --       Scheduler.unstable_yieldValue('BrokenLayoutEffectDestroy render')
  --       return <span prop="broken" />
  --     end

  --     ReactNoop.render(
  --       <ErrorBoundary id="OuterBoundary" fallbackID="OuterFallback">
  --         <Component id="sibling" />
  --         <ErrorBoundary id="InnerBoundary" fallbackID="InnerFallback">
  --           <BrokenLayoutEffectDestroy />
  --         </ErrorBoundary>
  --       </ErrorBoundary>,
  --     )

  --     expect(Scheduler).toFlushAndYield([
  --       'OuterBoundary render success',
  --       'Component render sibling',
  --       'InnerBoundary render success',
  --       'BrokenLayoutEffectDestroy render',
  --     ])
  --     expect(ReactNoop.getChildren()).toEqual([
  --       span('sibling'),
  --       span('broken'),
  --     ])

  --     ReactNoop.render(
  --       <ErrorBoundary id="OuterBoundary" fallbackID="OuterFallback">
  --         <Component id="sibling" />
  --       </ErrorBoundary>,
  --     )

  --     -- React should skip over the unmounting boundary and find the nearest still-mounted boundary.
  --     expect(Scheduler).toFlushAndYield([
  --       'OuterBoundary render success',
  --       'Component render sibling',
  --       'BrokenLayoutEffectDestroy useLayoutEffect destroy',
  --       'ErrorBoundary static getDerivedStateFromError',
  --       'OuterBoundary render error',
  --       'Component render OuterFallback',
  --     ])
  --     expect(ReactNoop.getChildren()).toEqual([span('OuterFallback')])
  --   })
  -- })

  -- describe('useCallback', function()
  --   it('memoizes callback by comparing inputs', function()
  --     class IncrementButton extends React.PureComponent {
  --       increment = function()
  --         this.props.increment()
  --       end
  --       render()
  --         return <Text text="Increment" />
  --       end
  --     end

  --     function Counter({incrementBy})
  --       local [count, updateCount] = useState(0)
  --       local increment = useCallback(function() updateCount(c => c + incrementBy), [
  --         incrementBy,
  --       ])
  --       return (
  --         <>
  --           <IncrementButton increment={increment} ref={button} />
  --           <Text text={'Count: ' + count} />
  --         </>
  --       )
  --     end

  --     local button = React.createRef(null)
  --     ReactNoop.render(<Counter incrementBy={1} />)
  --     expect(Scheduler).toFlushAndYield(['Increment', 'Count: 0'])
  --     expect(ReactNoop.getChildren()).toEqual([
  --       span('Increment'),
  --       span('Count: 0'),
  --     ])

  --     act(button.current.increment)
  --     expect(Scheduler).toHaveYielded([
  --       -- Button should not re-render, because its props haven't changed
  --       -- 'Increment',
  --       'Count: 1',
  --     ])
  --     expect(ReactNoop.getChildren()).toEqual([
  --       span('Increment'),
  --       span('Count: 1'),
  --     ])

  --     -- Increase the increment amount
  --     ReactNoop.render(<Counter incrementBy={10} />)
  --     expect(Scheduler).toFlushAndYield([
  --       -- Inputs did change this time
  --       'Increment',
  --       'Count: 1',
  --     ])
  --     expect(ReactNoop.getChildren()).toEqual([
  --       span('Increment'),
  --       span('Count: 1'),
  --     ])

  --     -- Callback should have updated
  --     act(button.current.increment)
  --     expect(Scheduler).toHaveYielded(['Count: 11'])
  --     expect(ReactNoop.getChildren()).toEqual([
  --       span('Increment'),
  --       span('Count: 11'),
  --     ])
  --   })
  -- })

  -- describe('useMemo', function()
  --   it('memoizes value by comparing to previous inputs', function()
  --     function CapitalizedText(props)
  --       local text = props.text
  --       local capitalizedText = useMemo(function()
  --         Scheduler.unstable_yieldValue(`Capitalize '${text}'`)
  --         return text.toUpperCase()
  --       }, [text])
  --       return <Text text={capitalizedText} />
  --     end

  --     ReactNoop.render(<CapitalizedText text="hello" />)
  --     expect(Scheduler).toFlushAndYield(["Capitalize 'hello'", 'HELLO'])
  --     expect(ReactNoop.getChildren()).toEqual([span('HELLO')])

  --     ReactNoop.render(<CapitalizedText text="hi" />)
  --     expect(Scheduler).toFlushAndYield(["Capitalize 'hi'", 'HI'])
  --     expect(ReactNoop.getChildren()).toEqual([span('HI')])

  --     ReactNoop.render(<CapitalizedText text="hi" />)
  --     expect(Scheduler).toFlushAndYield(['HI'])
  --     expect(ReactNoop.getChildren()).toEqual([span('HI')])

  --     ReactNoop.render(<CapitalizedText text="goodbye" />)
  --     expect(Scheduler).toFlushAndYield(["Capitalize 'goodbye'", 'GOODBYE'])
  --     expect(ReactNoop.getChildren()).toEqual([span('GOODBYE')])
  --   })

  --   it('always re-computes if no inputs are provided', function()
  --     function LazyCompute(props)
  --       local computed = useMemo(props.compute)
  --       return <Text text={computed} />
  --     end

  --     function computeA()
  --       Scheduler.unstable_yieldValue('compute A')
  --       return 'A'
  --     end

  --     function computeB()
  --       Scheduler.unstable_yieldValue('compute B')
  --       return 'B'
  --     end

  --     ReactNoop.render(<LazyCompute compute={computeA} />)
  --     expect(Scheduler).toFlushAndYield(['compute A', 'A'])

  --     ReactNoop.render(<LazyCompute compute={computeA} />)
  --     expect(Scheduler).toFlushAndYield(['compute A', 'A'])

  --     ReactNoop.render(<LazyCompute compute={computeA} />)
  --     expect(Scheduler).toFlushAndYield(['compute A', 'A'])

  --     ReactNoop.render(<LazyCompute compute={computeB} />)
  --     expect(Scheduler).toFlushAndYield(['compute B', 'B'])
  --   })

  --   it('should not invoke memoized function during re-renders unless inputs change', function()
  --     function LazyCompute(props)
  --       local computed = useMemo(function() props.compute(props.input), [
  --         props.input,
  --       ])
  --       local [count, setCount] = useState(0)
  --       if count < 3)
  --         setCount(count + 1)
  --       end
  --       return <Text text={computed} />
  --     end

  --     function compute(val)
  --       Scheduler.unstable_yieldValue('compute ' + val)
  --       return val
  --     end

  --     ReactNoop.render(<LazyCompute compute={compute} input="A" />)
  --     expect(Scheduler).toFlushAndYield(['compute A', 'A'])

  --     ReactNoop.render(<LazyCompute compute={compute} input="A" />)
  --     expect(Scheduler).toFlushAndYield(['A'])

  --     ReactNoop.render(<LazyCompute compute={compute} input="B" />)
  --     expect(Scheduler).toFlushAndYield(['compute B', 'B'])
  --   })
  -- })

  -- describe('useRef', function()
  --   it('creates a ref object initialized with the provided value', function()
  --     jest.useFakeTimers()

  --     function useDebouncedCallback(callback, ms, inputs)
  --       local timeoutID = useRef(-1)
  --       useEffect(function()
  --         return function unmount()
  --           clearTimeout(timeoutID.current)
  --         end
  --       }, [])
  --       local debouncedCallback = useCallback(
  --         (...args) => {
  --           clearTimeout(timeoutID.current)
  --           timeoutID.current = setTimeout(callback, ms, ...args)
  --         },
  --         [callback, ms],
  --       )
  --       return useCallback(debouncedCallback, inputs)
  --     end

  --     local ping
  --     function App()
  --       ping = useDebouncedCallback(
  --         value => {
  --           Scheduler.unstable_yieldValue('ping: ' + value)
  --         },
  --         100,
  --         [],
  --       )
  --       return nil
  --     end

  --     act(function()
  --       ReactNoop.render(<App />)
  --     })
  --     expect(Scheduler).toHaveYielded([])

  --     ping(1)
  --     ping(2)
  --     ping(3)

  --     expect(Scheduler).toHaveYielded([])

  --     jest.advanceTimersByTime(100)

  --     expect(Scheduler).toHaveYielded(['ping: 3'])

  --     ping(4)
  --     jest.advanceTimersByTime(20)
  --     ping(5)
  --     ping(6)
  --     jest.advanceTimersByTime(80)

  --     expect(Scheduler).toHaveYielded([])

  --     jest.advanceTimersByTime(20)
  --     expect(Scheduler).toHaveYielded(['ping: 6'])
  --   })

  --   it('should return the same ref during re-renders', function()
  --     function Counter()
  --       local ref = useRef('val')
  --       local [count, setCount] = useState(0)
  --       local [firstRef] = useState(ref)

  --       if firstRef ~= ref)
  --         throw new Error('should never change')
  --       end

  --       if count < 3)
  --         setCount(count + 1)
  --       end

  --       return <Text text={ref.current} />
  --     end

  --     ReactNoop.render(<Counter />)
  --     expect(Scheduler).toFlushAndYield(['val'])

  --     ReactNoop.render(<Counter />)
  --     expect(Scheduler).toFlushAndYield(['val'])
  --   })
  -- })

  -- describe('useImperativeHandle', function()
  --   it('does not update when deps are the same', function()
  --     local INCREMENT = 'INCREMENT'

  --     function reducer(state, action)
  --       return action == INCREMENT ? state + 1 : state
  --     end

  --     function Counter(props, ref)
  --       local [count, dispatch] = useReducer(reducer, 0)
  --       useImperativeHandle(ref, function() ({count, dispatch}), [])
  --       return <Text text={'Count: ' + count} />
  --     end

  --     Counter = forwardRef(Counter)
  --     local counter = React.createRef(null)
  --     ReactNoop.render(<Counter ref={counter} />)
  --     expect(Scheduler).toFlushAndYield(['Count: 0'])
  --     expect(ReactNoop.getChildren()).toEqual([span('Count: 0')])
  --     expect(counter.current.count).toBe(0)

  --     act(function()
  --       counter.current.dispatch(INCREMENT)
  --     })
  --     expect(Scheduler).toHaveYielded(['Count: 1'])
  --     expect(ReactNoop.getChildren()).toEqual([span('Count: 1')])
  --     -- Intentionally not updated because of [] deps:
  --     expect(counter.current.count).toBe(0)
  --   })

  --   -- Regression test for https:--github.com/facebook/react/issues/14782
  --   it('automatically updates when deps are not specified', function()
  --     local INCREMENT = 'INCREMENT'

  --     function reducer(state, action)
  --       return action == INCREMENT ? state + 1 : state
  --     end

  --     function Counter(props, ref)
  --       local [count, dispatch] = useReducer(reducer, 0)
  --       useImperativeHandle(ref, function() ({count, dispatch}))
  --       return <Text text={'Count: ' + count} />
  --     end

  --     Counter = forwardRef(Counter)
  --     local counter = React.createRef(null)
  --     ReactNoop.render(<Counter ref={counter} />)
  --     expect(Scheduler).toFlushAndYield(['Count: 0'])
  --     expect(ReactNoop.getChildren()).toEqual([span('Count: 0')])
  --     expect(counter.current.count).toBe(0)

  --     act(function()
  --       counter.current.dispatch(INCREMENT)
  --     })
  --     expect(Scheduler).toHaveYielded(['Count: 1'])
  --     expect(ReactNoop.getChildren()).toEqual([span('Count: 1')])
  --     expect(counter.current.count).toBe(1)
  --   })

  --   it('updates when deps are different', function()
  --     local INCREMENT = 'INCREMENT'

  --     function reducer(state, action)
  --       return action == INCREMENT ? state + 1 : state
  --     end

  --     local totalRefUpdates = 0
  --     function Counter(props, ref)
  --       local [count, dispatch] = useReducer(reducer, 0)
  --       useImperativeHandle(
  --         ref,
  --         function()
  --           totalRefUpdates++
  --           return {count, dispatch}
  --         },
  --         [count],
  --       )
  --       return <Text text={'Count: ' + count} />
  --     end

  --     Counter = forwardRef(Counter)
  --     local counter = React.createRef(null)
  --     ReactNoop.render(<Counter ref={counter} />)
  --     expect(Scheduler).toFlushAndYield(['Count: 0'])
  --     expect(ReactNoop.getChildren()).toEqual([span('Count: 0')])
  --     expect(counter.current.count).toBe(0)
  --     expect(totalRefUpdates).toBe(1)

  --     act(function()
  --       counter.current.dispatch(INCREMENT)
  --     })
  --     expect(Scheduler).toHaveYielded(['Count: 1'])
  --     expect(ReactNoop.getChildren()).toEqual([span('Count: 1')])
  --     expect(counter.current.count).toBe(1)
  --     expect(totalRefUpdates).toBe(2)

  --     -- Update that doesn't change the ref dependencies
  --     ReactNoop.render(<Counter ref={counter} />)
  --     expect(Scheduler).toFlushAndYield(['Count: 1'])
  --     expect(ReactNoop.getChildren()).toEqual([span('Count: 1')])
  --     expect(counter.current.count).toBe(1)
  --     expect(totalRefUpdates).toBe(2); -- Should not increase since last time
  --   })
  -- })
  -- describe('useTransition', function()
  --   -- @gate experimental
  --   it('delays showing loading state until after timeout', async function()
  --     local transition
  --     function App()
  --       local [show, setShow] = useState(false)
  --       local [startTransition, isPending] = useTransition({
  --         timeoutMs: 1000,
  --       })
  --       transition = function()
  --         startTransition(function()
  --           setShow(true)
  --         })
  --       end
  --       return (
  --         <Suspense
  --           fallback={<Text text={`Loading... Pending: ${isPending}`} />}>
  --           {show ? (
  --             <AsyncText text={`After... Pending: ${isPending}`} />
  --           ) : (
  --             <Text text={`Before... Pending: ${isPending}`} />
  --           )}
  --         </Suspense>
  --       )
  --     end
  --     ReactNoop.render(<App />)
  --     expect(Scheduler).toFlushAndYield(['Before... Pending: false'])
  --     expect(ReactNoop.getChildren()).toEqual([
  --       span('Before... Pending: false'),
  --     ])

  --     await act(async function()
  --       Scheduler.unstable_runWithPriority(
  --         Scheduler.unstable_UserBlockingPriority,
  --         transition,
  --       )

  --       expect(Scheduler).toFlushAndYield([
  --         'Before... Pending: true',
  --         'Suspend! [After... Pending: false]',
  --         'Loading... Pending: false',
  --       ])
  --       expect(ReactNoop.getChildren()).toEqual([
  --         span('Before... Pending: true'),
  --       ])
  --       Scheduler.unstable_advanceTime(500)
  --       await advanceTimers(500)

  --       -- Even after a long amount of time, we still don't show a placeholder.
  --       Scheduler.unstable_advanceTime(100000)
  --       await advanceTimers(100000)
  --       expect(ReactNoop.getChildren()).toEqual([
  --         span('Before... Pending: true'),
  --       ])

  --       await resolveText('After... Pending: false')
  --       expect(Scheduler).toHaveYielded([
  --         'Promise resolved [After... Pending: false]',
  --       ])
  --       expect(Scheduler).toFlushAndYield(['After... Pending: false'])
  --       expect(ReactNoop.getChildren()).toEqual([
  --         span('After... Pending: false'),
  --       ])
  --     })
  --   })
  -- })

  -- describe('useDeferredValue', function()
  --   -- @gate experimental
  --   it('defers text value', async function()
  --     function TextBox({text})
  --       return <AsyncText text={text} />
  --     end

  --     local _setText
  --     function App()
  --       local [text, setText] = useState('A')
  --       local deferredText = useDeferredValue(text, {
  --         timeoutMs: 500,
  --       })
  --       _setText = setText
  --       return (
  --         <>
  --           <Text text={text} />
  --           <Suspense fallback={<Text text={'Loading'} />}>
  --             <TextBox text={deferredText} />
  --           </Suspense>
  --         </>
  --       )
  --     end

  --     act(function()
  --       ReactNoop.render(<App />)
  --     })

  --     expect(Scheduler).toHaveYielded(['A', 'Suspend! [A]', 'Loading'])
  --     expect(ReactNoop.getChildren()).toEqual([span('A'), span('Loading')])

  --     await resolveText('A')
  --     expect(Scheduler).toHaveYielded(['Promise resolved [A]'])
  --     expect(Scheduler).toFlushAndYield(['A'])
  --     expect(ReactNoop.getChildren()).toEqual([span('A'), span('A')])

  --     await act(async function()
  --       _setText('B')
  --       expect(Scheduler).toFlushAndYield([
  --         'B',
  --         'A',
  --         'B',
  --         'Suspend! [B]',
  --         'Loading',
  --       ])
  --       expect(Scheduler).toFlushAndYield([])
  --       expect(ReactNoop.getChildren()).toEqual([span('B'), span('A')])
  --     })

  --     await act(async function()
  --       Scheduler.unstable_advanceTime(250)
  --       await advanceTimers(250)
  --     })
  --     expect(Scheduler).toHaveYielded([])
  --     expect(ReactNoop.getChildren()).toEqual([span('B'), span('A')])

  --     -- Even after a long amount of time, we don't show a fallback
  --     Scheduler.unstable_advanceTime(100000)
  --     await advanceTimers(100000)
  --     expect(Scheduler).toFlushAndYield([])
  --     expect(ReactNoop.getChildren()).toEqual([span('B'), span('A')])

  --     await act(async function()
  --       await resolveText('B')
  --     })
  --     expect(Scheduler).toHaveYielded(['Promise resolved [B]', 'B', 'B'])
  --     expect(ReactNoop.getChildren()).toEqual([span('B'), span('B')])
  --   })
  -- })

  -- describe('progressive enhancement (not supported)', function()
  --   it('mount additional state', function()
  --     local updateA
  --     local updateB
  --     -- local updateC

  --     function App(props)
  --       local [A, _updateA] = useState(0)
  --       local [B, _updateB] = useState(0)
  --       updateA = _updateA
  --       updateB = _updateB

  --       local C
  --       if props.loadC)
  --         useState(0)
  --       } else {
  --         C = '[not loaded]'
  --       end

  --       return <Text text={`A: ${A}, B: ${B}, C: ${C}`} />
  --     end

  --     ReactNoop.render(<App loadC={false} />)
  --     expect(Scheduler).toFlushAndYield(['A: 0, B: 0, C: [not loaded]'])
  --     expect(ReactNoop.getChildren()).toEqual([
  --       span('A: 0, B: 0, C: [not loaded]'),
  --     ])

  --     act(function()
  --       updateA(2)
  --       updateB(3)
  --     })

  --     expect(Scheduler).toHaveYielded(['A: 2, B: 3, C: [not loaded]'])
  --     expect(ReactNoop.getChildren()).toEqual([
  --       span('A: 2, B: 3, C: [not loaded]'),
  --     ])

  --     ReactNoop.render(<App loadC={true} />)
  --     expect(function()
  --       expect(function()
  --         expect(Scheduler).toFlushAndYield(['A: 2, B: 3, C: 0'])
  --       }).toThrow('Rendered more hooks than during the previous render')
  --     }).toErrorDev([
  --       'Warning: React has detected a change in the order of Hooks called by App. ' +
  --         'This will lead to bugs and errors if not fixed. For more information, ' +
  --         'read the Rules of Hooks: https:--reactjs.org/link/rules-of-hooks\n\n' +
  --         '   Previous render            Next render\n' +
  --         '   ------------------------------------------------------\n' +
  --         '1. useState                   useState\n' +
  --         '2. useState                   useState\n' +
  --         '3. undefined                  useState\n' +
  --         '   ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^\n\n',
  --     ])

  --     -- Uncomment if/when we support this again
  --     -- expect(ReactNoop.getChildren()).toEqual([span('A: 2, B: 3, C: 0')])

  --     -- updateC(4)
  --     -- expect(Scheduler).toFlushAndYield(['A: 2, B: 3, C: 4'])
  --     -- expect(ReactNoop.getChildren()).toEqual([span('A: 2, B: 3, C: 4')])
  --   })

  --   it('unmount state', function()
  --     local updateA
  --     local updateB
  --     local updateC

  --     function App(props)
  --       local [A, _updateA] = useState(0)
  --       local [B, _updateB] = useState(0)
  --       updateA = _updateA
  --       updateB = _updateB

  --       local C
  --       if props.loadC)
  --         local [_C, _updateC] = useState(0)
  --         C = _C
  --         updateC = _updateC
  --       } else {
  --         C = '[not loaded]'
  --       end

  --       return <Text text={`A: ${A}, B: ${B}, C: ${C}`} />
  --     end

  --     ReactNoop.render(<App loadC={true} />)
  --     expect(Scheduler).toFlushAndYield(['A: 0, B: 0, C: 0'])
  --     expect(ReactNoop.getChildren()).toEqual([span('A: 0, B: 0, C: 0')])
  --     act(function()
  --       updateA(2)
  --       updateB(3)
  --       updateC(4)
  --     })
  --     expect(Scheduler).toHaveYielded(['A: 2, B: 3, C: 4'])
  --     expect(ReactNoop.getChildren()).toEqual([span('A: 2, B: 3, C: 4')])
  --     ReactNoop.render(<App loadC={false} />)
  --     expect(Scheduler).toFlushAndThrow(
  --       'Rendered fewer hooks than expected. This may be caused by an ' +
  --         'accidental early return statement.',
  --     )
  --   })

  --   it('unmount effects', function()
  --     function App(props)
  --       useEffect(function()
  --         Scheduler.unstable_yieldValue('Mount A')
  --         return function()
  --           Scheduler.unstable_yieldValue('Unmount A')
  --         end
  --       }, [])

  --       if props.showMore)
  --         useEffect(function()
  --           Scheduler.unstable_yieldValue('Mount B')
  --           return function()
  --             Scheduler.unstable_yieldValue('Unmount B')
  --           end
  --         }, [])
  --       end

  --       return nil
  --     end

  --     act(function()
  --       ReactNoop.render(<App showMore={false} />, function()
  --         Scheduler.unstable_yieldValue('Sync effect'),
  --       )
  --       expect(Scheduler).toFlushAndYieldThrough(['Sync effect'])
  --     })

  --     expect(Scheduler).toHaveYielded(['Mount A'])

  --     act(function()
  --       ReactNoop.render(<App showMore={true} />)
  --       expect(function()
  --         expect(function()
  --           expect(Scheduler).toFlushAndYield([])
  --         }).toThrow('Rendered more hooks than during the previous render')
  --       }).toErrorDev([
  --         'Warning: React has detected a change in the order of Hooks called by App. ' +
  --           'This will lead to bugs and errors if not fixed. For more information, ' +
  --           'read the Rules of Hooks: https:--reactjs.org/link/rules-of-hooks\n\n' +
  --           '   Previous render            Next render\n' +
  --           '   ------------------------------------------------------\n' +
  --           '1. useEffect                  useEffect\n' +
  --           '2. undefined                  useEffect\n' +
  --           '   ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^\n\n',
  --       ])
  --     })

  --     -- Uncomment if/when we support this again
  --     -- ReactNoop.flushPassiveEffects()
  --     -- expect(Scheduler).toHaveYielded(['Mount B'])

  --     -- ReactNoop.render(<App showMore={false} />)
  --     -- expect(Scheduler).toFlushAndThrow(
  --     --   'Rendered fewer hooks than expected. This may be caused by an ' +
  --     --     'accidental early return statement.',
  --     -- )
  --   })
  -- })

  -- it('eager bailout optimization should always compare to latest rendered reducer', function()
  --   -- Edge case based on a bug report
  --   local setCounter
  --   function App()
  --     local [counter, _setCounter] = useState(1)
  --     setCounter = _setCounter
  --     return <Component count={counter} />
  --   end

  --   function Component({count})
  --     local [state, dispatch] = useReducer(function()
  --       -- This reducer closes over a value from props. If the reducer is not
  --       -- properly updated, the eager reducer will compare to an old value
  --       -- and bail out incorrectly.
  --       Scheduler.unstable_yieldValue('Reducer: ' + count)
  --       return count
  --     }, -1)
  --     useEffect(function()
  --       Scheduler.unstable_yieldValue('Effect: ' + count)
  --       dispatch()
  --     }, [count])
  --     Scheduler.unstable_yieldValue('Render: ' + state)
  --     return count
  --   end

  --   act(function()
  --     ReactNoop.render(<App />)
  --     expect(Scheduler).toFlushAndYield([
  --       'Render: -1',
  --       'Effect: 1',
  --       'Reducer: 1',
  --       'Reducer: 1',
  --       'Render: 1',
  --     ])
  --     expect(ReactNoop).toMatchRenderedOutput('1')
  --   })

  --   act(function()
  --     setCounter(2)
  --   })
  --   expect(Scheduler).toHaveYielded([
  --     'Render: 1',
  --     'Effect: 2',
  --     'Reducer: 2',
  --     'Reducer: 2',
  --     'Render: 2',
  --   ])
  --   expect(ReactNoop).toMatchRenderedOutput('2')
  -- })

  -- -- Regression test. Covers a case where an internal state variable
  -- -- (`didReceiveUpdate`) is not reset properly.
  -- it('state bail out edge case (#16359)', async function()
  --   local setCounterA
  --   local setCounterB

  --   function CounterA()
  --     local [counter, setCounter] = useState(0)
  --     setCounterA = setCounter
  --     Scheduler.unstable_yieldValue('Render A: ' + counter)
  --     useEffect(function()
  --       Scheduler.unstable_yieldValue('Commit A: ' + counter)
  --     })
  --     return counter
  --   end

  --   function CounterB()
  --     local [counter, setCounter] = useState(0)
  --     setCounterB = setCounter
  --     Scheduler.unstable_yieldValue('Render B: ' + counter)
  --     useEffect(function()
  --       Scheduler.unstable_yieldValue('Commit B: ' + counter)
  --     })
  --     return counter
  --   end

  --   local root = ReactNoop.createRoot(null)
  --   await ReactNoop.act(async function()
  --     root.render(
  --       <>
  --         <CounterA />
  --         <CounterB />
  --       </>,
  --     )
  --   })
  --   expect(Scheduler).toHaveYielded([
  --     'Render A: 0',
  --     'Render B: 0',
  --     'Commit A: 0',
  --     'Commit B: 0',
  --   ])

  --   await ReactNoop.act(async function()
  --     setCounterA(1)

  --     -- In the same batch, update B twice. To trigger the condition we're
  --     -- testing, the first update is necessary to bypass the early
  --     -- bailout optimization.
  --     setCounterB(1)
  --     setCounterB(0)
  --   })
  --   expect(Scheduler).toHaveYielded([
  --     'Render A: 1',
  --     'Render B: 0',
  --     'Commit A: 1',
  --     -- B should not fire an effect because the update bailed out
  --     -- 'Commit B: 0',
  --   ])
  -- })

  -- it('should update latest rendered reducer when a preceding state receives a render phase update', function()
  --   -- Similar to previous test, except using a preceding render phase update
  --   -- instead of new props.
  --   local dispatch
  --   function App()
  --     local [step, setStep] = useState(0)
  --     local [shadow, _dispatch] = useReducer(function() step, step)
  --     dispatch = _dispatch

  --     if step < 5)
  --       setStep(step + 1)
  --     end

  --     Scheduler.unstable_yieldValue(`Step: ${step}, Shadow: ${shadow}`)
  --     return shadow
  --   end

  --   ReactNoop.render(<App />)
  --   expect(Scheduler).toFlushAndYield([
  --     'Step: 0, Shadow: 0',
  --     'Step: 1, Shadow: 0',
  --     'Step: 2, Shadow: 0',
  --     'Step: 3, Shadow: 0',
  --     'Step: 4, Shadow: 0',
  --     'Step: 5, Shadow: 0',
  --   ])
  --   expect(ReactNoop).toMatchRenderedOutput('0')

  --   act(function() dispatch())
  --   expect(Scheduler).toHaveYielded(['Step: 5, Shadow: 5'])
  --   expect(ReactNoop).toMatchRenderedOutput('5')
  -- })

  -- it('should process the rest pending updates after a render phase update', function()
  --   -- Similar to previous test, except using a preceding render phase update
  --   -- instead of new props.
  --   local updateA
  --   local updateC
  --   function App()
  --     local [a, setA] = useState(false)
  --     local [b, setB] = useState(false)
  --     if a ~= b)
  --       setB(a)
  --     end
  --     -- Even though we called setB above,
  --     -- we should still apply the changes to C,
  --     -- during this render pass.
  --     local [c, setC] = useState(false)
  --     updateA = setA
  --     updateC = setC
  --     return `${a ? 'A' : 'a'}${b ? 'B' : 'b'}${c ? 'C' : 'c'}`
  --   end

  --   act(function() ReactNoop.render(<App />))
  --   expect(ReactNoop).toMatchRenderedOutput('abc')

  --   act(function()
  --     updateA(true)
  --     -- This update should not get dropped.
  --     updateC(true)
  --   })
  --   expect(ReactNoop).toMatchRenderedOutput('ABC')
  -- })

  -- it("regression test: don't unmount effects on siblings of deleted nodes", async function()
  --   local root = ReactNoop.createRoot()

  --   function Child({label})
  --     useLayoutEffect(function()
  --       Scheduler.unstable_yieldValue('Mount layout ' + label)
  --       return function()
  --         Scheduler.unstable_yieldValue('Unmount layout ' + label)
  --       end
  --     }, [label])
  --     useEffect(function()
  --       Scheduler.unstable_yieldValue('Mount passive ' + label)
  --       return function()
  --         Scheduler.unstable_yieldValue('Unmount passive ' + label)
  --       end
  --     }, [label])
  --     return label
  --   end

  --   await act(async function()
  --     root.render(
  --       <>
  --         <Child key="A" label="A" />
  --         <Child key="B" label="B" />
  --       </>,
  --     )
  --   })
  --   expect(Scheduler).toHaveYielded([
  --     'Mount layout A',
  --     'Mount layout B',
  --     'Mount passive A',
  --     'Mount passive B',
  --   ])

  --   -- Delete A. This should only unmount the effect on A. In the regression,
  --   -- B's effect would also unmount.
  --   await act(async function()
  --     root.render(
  --       <>
  --         <Child key="B" label="B" />
  --       </>,
  --     )
  --   })
  --   expect(Scheduler).toHaveYielded(['Unmount layout A', 'Unmount passive A'])

  --   -- Now delete and unmount B.
  --   await act(async function()
  --     root.render(null)
  --   })
  --   expect(Scheduler).toHaveYielded(['Unmount layout B', 'Unmount passive B'])
  -- })
end