--- TSNM & JF

-- crow
-- input 1: gate 1
-- input 2: gate 2
-- output 1: lfo 1 (fast)
-- output 2: lfo 2 (slow)
-- output 3: random cv (based on gate 1 and 2)
-- output 4: ar envelope

-- txi
-- param 1: off / volume
-- param 2: lfo rate
-- param 3: ar envelope attack time
-- param 4: ar envelope release time
-- input 1: v8 1
-- input 2: v8 2
-- input 3: volume offset
-- input 4: gate delay

-- txi getter, saves txi param and input values as a table
txi = {param = {0,0,0,0}, input = {0,0,0,0}}

txi.get = function()
  for i = 1, 4 do
    ii.txi.get('param', i)
    ii.txi.get('in', i)
  end
end

ii.txi.event = function(e, val)
  txi[e.name == 'in' and 'input' or e.name][e.arg] = val
end

txi.refresh = clock.run(
  function()
    while true do
      txi.get()
      clock.sleep(0.015)
    end
  end
)

-- init
function init()
  ii.jf.mode(1)
  ii.jf.transpose(-3)

  input[1]{
    mode = 'change',
    threshold = 4,
    direction = 'rising',
    change = function() clock.run(play, 1) end
  }

  input[2]{
    mode = 'change',
    threshold = 4,
    direction = 'rising',
    change = function() clock.run(play, 2) end
  }

  output[1].action = lfo(dyn{time = 0.25}, dyn{height = 5}, 'sine')
  output[2].action = lfo(dyn{time = 0.5}, dyn{height = 5}, 'sine')
  output[4].action = ar(dyn{attack = 0}, dyn{release = 0.5}, dyn{height = 5}, 'linear')

  output[1]()
  output[2]()
  
  refresh = clock.run(
    function()
      while true do
        clock.sleep(0.05)
        output[1].dyn.time = 0.005 + map(txi.param[2], 0, 10, 0, 2.5)
        output[2].dyn.time = 0.005 + map(txi.param[2], 0, 10, 5, 10)
        output[4].dyn.attack = map(txi.param[3], 0, 10, 0, 1)
        output[4].dyn.release = map(txi.param[4], 0, 10, 0, 1)
      end
    end
  )
end

-- helper functions
function clamp(x, min, max)
  return math.min( math.max( min, x ), max )
end

function round(x)
  return x % 1 >= 0.5 and math.ceil(x) or math.floor(x)
end

function map(x, in_min, in_max, out_min, out_max)
  return (x - in_min) * (out_max - out_min) / (in_max - in_min) + out_min
end

function selector(x, data, in_min, in_max, out_min, out_max)
  out_min = out_min or 1
  out_max = out_max or #data
  return data[ clamp( round( map( x, in_min, in_max, out_min, out_max ) ), out_min, out_max ) ]
end

-- play function, called by gate to input 1 and 2
function play(txi_input_ix)
  local random_level = math.random() * round(txi.input[3]) / 2
  local random_delay = math.random() * round(txi.input[4]) / 40

  clock.sleep(0.05 + random_delay)

  output[3].volts = math.random() * 10 - 5
  output[4]()

  local enabled = selector(txi.param[1], {false, true}, 0, 0.1)
  if enabled == false then return end

  local note = round(txi.input[txi_input_ix] * 12) / 12
  local level = map(txi.param[1] + random_level, 0.5, 10, 0, 5)       

  ii.jf.play_note(note, level)
end