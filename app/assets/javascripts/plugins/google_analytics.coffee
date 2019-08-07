document.addEventListener 'turbolinks:load', (event) ->
  if window.ga?
    ga('set', 'location', event.data.url)
    ga('send', 'pageview')
