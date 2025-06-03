// CORS proxy for the NYT Wordle API

addEventListener('fetch', event => {
  event.respondWith(handleRequest(event.request, event))
})

async function handleRequest(request, event) {
  // Only allow GET requests
  if (request.method !== 'GET') {
    return new Response('Method not allowed', { status: 405 })
  }

  // Parse the URL to get the date
  const url = new URL(request.url)
  const date = url.pathname.split('/').pop()

  // Validate date format (YYYY-MM-DD)
  if (!/^\d{4}-\d{2}-\d{2}$/.test(date)) {
    return new Response('Invalid date format', { status: 400 })
  }

  // Check cache first
  const cacheKey = `wordle-${date}`
  const cache = caches.default
  let response = await cache.match(request)

  if (!response) {
    // If not in cache, fetch from NYT
    const nytUrl = `https://www.nytimes.com/svc/wordle/v2/${date}.json`
    response = await fetch(nytUrl)

    if (response.status === 404) {
      return new Response('Solution not found', { status: 404 })
    }

    if (!response.ok) {
      return new Response('Error fetching solution', { status: 500 })
    }

    // Clone the response and add CORS headers
    response = new Response(response.body, response)
    response.headers.set('Access-Control-Allow-Origin', '*')
    response.headers.set('Access-Control-Allow-Methods', 'GET')
    response.headers.set('Cache-Control', 'public, max-age=86400') // Cache for 24 hours

    // Store in cache
    event.waitUntil(cache.put(request, response.clone()))
  }

  return response
}
