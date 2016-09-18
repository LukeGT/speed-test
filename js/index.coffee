START_SIZE = 1024 * 1024
TEST_DURATION = 10 * 1000

get_chunk = (size, callbacks) ->
  
  xhr = new XMLHttpRequest()
  for key, callback of callbacks
    xhr.addEventListener key, callback
  xhr.open 'GET', 'start?size=' + size
  xhr.send()

run_test = (update, done) ->
  
  start = Date.now()
  size = START_SIZE
  speeds = []

  loop_func = ->

    if Date.now() - start < TEST_DURATION

      first_measurement = true
      last_loaded = 0
      last_time = Date.now()

      get_chunk size, {

        progress: (event) ->

          time = Date.now()
          if not first_measurement
            speed = (event.loaded - last_loaded) / (time - last_time)
            speeds.push speed
            console.log speed

          first_measurement = false
          last_time = time
          last_loaded = event.loaded

          update speeds

        load: ->
          update speeds
          done()
      }

  loop_func()

average = (nums) -> (nums.reduce (a, b) -> a + b) / nums.length

deviation = (nums) ->
  mean = average(nums)
  return Math.sqrt average nums.map((x) -> mean - x).map((x) -> x*x)

$ ->

  running = false

  $('#start').on 'click', ->
    return if running
    running = true
    $('#start').text('Running...')
    run_test (speeds) ->
      $('#result').text Math.floor average(speeds) * 8
      $('#deviation').text Math.floor deviation(speeds) * 8
    , ->
      running = false
      $('#start').text('Start')
