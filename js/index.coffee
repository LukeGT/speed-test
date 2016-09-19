START_SIZE = 128 * 1024
TEST_DURATION = 5 * 1000
MAX_BAR_WIDTH = 30

get_chunk = (size, callbacks) ->
  
  xhr = new XMLHttpRequest()
  for key, callback of callbacks
    xhr.addEventListener key, callback
  xhr.open 'GET', 'start?size=' + size
  xhr.send()

run_test = (update, done) ->
  
  start = Date.now()
  max_size = START_SIZE
  speeds = []
  buckets = []

  loop_func = ->

    time_left = Date.now() - start
    if time_left < TEST_DURATION

      first_measurement = true
      last_loaded = 0
      last_time = Date.now()

      if speeds.length
        size = Math.min max_size, Math.floor average(speeds) * time_left
      else
        size = START_SIZE
      max_size *= 2

      get_chunk size, {

        progress: (event) ->

          time = Date.now()
          if not first_measurement and time != last_time
            speed = (event.loaded - last_loaded) / (time - last_time)
            speeds.push speed
            bucket = get_log_bucket speed
            buckets[bucket] ?= 0
            ++buckets[bucket]

          first_measurement = false
          last_time = time
          last_loaded = event.loaded

          update speeds, buckets

        load: ->
          update speeds, buckets
          loop_func()
      }
    else
      console.log speeds
      console.log buckets
      done()

  loop_func()

average = (nums) -> nums.reduce(((a, b) -> a + b), 0) / nums.length

deviation = (nums) ->
  mean = average(nums)
  return Math.sqrt average nums.map((x) -> mean - x).map((x) -> x*x)

get_log_bucket = (point) -> Math.floor 10 * Math.log point

empty_span = -> $("<span>").width(0).height(0)


$ ->

  running = false

  $('#start').on 'click', ->
    return if running

    $('#start').text('Running...')
    $('#histogram').empty()
    running = true
    min_bucket = Infinity
    max_bucket = -Infinity

    run_test (speeds, buckets) ->
      $('#result').text Math.floor average(speeds) * 8
      $('#deviation').text Math.floor deviation(speeds) * 8

      keys = (+key for key of buckets)

      if keys.length

        min = Math.min.apply this, keys
        max = Math.max.apply this, keys

        $histogram = $('#histogram')

        if min_bucket < Infinity
          a = min_bucket - 1
          while a >= min
            $histogram.prepend empty_span
            --a

        a = Math.max min, max_bucket+1
        while a <= max
          $histogram.append empty_span
          ++a

        spans = $histogram.find('span')
        width = Math.min MAX_BAR_WIDTH, $('html').width() / keys.length
        setTimeout ->
          for bucket, size of buckets
            $(spans[bucket - min]).height(size * 4).width(width)

        min_bucket = min
        max_bucket = max

    , ->
      running = false
      $('#start').text('Start')
