import { createServer } from 'http';

const PORT = process.env.PORT || 3000;
const todos = new Map();
let nextId = 1;

function parseBody(req) {
  return new Promise((resolve) => {
    let body = '';
    req.on('data', chunk => body += chunk);
    req.on('end', () => {
      try {
        resolve(body ? JSON.parse(body) : {});
      } catch {
        resolve({});
      }
    });
  });
}

function sendJSON(res, status, data) {
  res.writeHead(status, { 'Content-Type': 'application/json' });
  res.end(JSON.stringify(data));
}

const server = createServer(async (req, res) => {
  const url = new URL(req.url, `http://localhost:${PORT}`);
  const match = url.pathname.match(/^\/todos(?:\/(\d+))?$/);

  if (!match) {
    sendJSON(res, 404, { error: 'Not found' });
    return;
  }

  const id = match[1] ? parseInt(match[1]) : null;

  if (req.method === 'GET' && id === null) {
    sendJSON(res, 200, { todos: Array.from(todos.values()) });
    return;
  }

  if (req.method === 'GET' && id !== null) {
    const todo = todos.get(id);
    if (!todo) {
      sendJSON(res, 404, { error: 'Todo not found' });
      return;
    }
    sendJSON(res, 200, todo);
    return;
  }

  if (req.method === 'POST' && id === null) {
    const body = await parseBody(req);
    if (!body.title) {
      sendJSON(res, 400, { error: 'Title required' });
      return;
    }
    const todo = { id: nextId++, title: body.title, done: false };
    todos.set(todo.id, todo);
    sendJSON(res, 201, todo);
    return;
  }

  if (req.method === 'PATCH' && id !== null) {
    const todo = todos.get(id);
    if (!todo) {
      sendJSON(res, 404, { error: 'Todo not found' });
      return;
    }
    const body = await parseBody(req);
    if (body.title !== undefined) todo.title = body.title;
    if (body.done !== undefined) todo.done = body.done;
    sendJSON(res, 200, todo);
    return;
  }

  if (req.method === 'DELETE' && id !== null) {
    if (!todos.has(id)) {
      sendJSON(res, 404, { error: 'Todo not found' });
      return;
    }
    todos.delete(id);
    sendJSON(res, 204, null);
    return;
  }

  sendJSON(res, 405, { error: 'Method not allowed' });
});

server.listen(PORT, () => {
  console.log(`Listening on ${PORT}`);
});

export { server, PORT };
