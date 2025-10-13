export default async function handler(request, response) {
  try {
    const baseUrl = process.env.ANALYTICS_API_URL;
    if (!baseUrl) {
      return response.status(500).json({ error: 'ANALYTICS_API_URL is not configured' });
    }

    // Extract proxied path and query string
    const url = new URL(request.url, `http://${request.headers.host}`);
    // Vercel rewrites to this function at /analytics-proxy/<...>
    const proxiedPath = url.pathname.replace(/^\/api\/analytics-proxy\//, '').replace(/^\/analytics-proxy\//, '');
    const targetUrl = new URL(proxiedPath, baseUrl);
    targetUrl.search = url.searchParams.toString();

    // Prepare request options and forward headers conservatively
    const upstreamHeaders = new Headers();
    // Pass JSON content type when sending a body
    const contentType = request.headers.get('content-type');
    if (contentType) upstreamHeaders.set('content-type', contentType);
    // Forward authorization if present
    const auth = request.headers.get('authorization');
    if (auth) upstreamHeaders.set('authorization', auth);

    const init = {
      method: request.method,
      headers: upstreamHeaders,
      // Only pass body for methods that can have one
      body: ['POST', 'PUT', 'PATCH', 'DELETE'].includes(request.method)
        ? await request.arrayBuffer()
        : undefined,
    };

    const upstreamResp = await fetch(targetUrl.toString(), init);

    // Mirror status and content-type back to client
    const respContentType = upstreamResp.headers.get('content-type') || 'application/octet-stream';
    response.status(upstreamResp.status);
    response.setHeader('content-type', respContentType);

    // Stream body
    const buf = Buffer.from(await upstreamResp.arrayBuffer());
    return response.send(buf);
  } catch (err) {
    return response.status(502).json({ error: 'Proxy error', message: String(err) });
  }
}


