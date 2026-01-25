---
name: component-patterns
description: Per-component-type verification approaches. Use when generating verification scripts for different component types.
user-invocable: false
---

# Component Patterns

## Purpose

Provide verification strategies for different component types. This skill defines how to
test real behavior for CLIs, servers, parsers, processes, databases, and external APIs.

## When to Use

Load this skill when:
- Generating verification scripts via bulwark-verify skill
- Determining how to test a specific component type
- Implementing test-audit Step 7 rewrites

---

## Component Type Detection

Analyze the code to determine component type based on these indicators:

| Indicators | Component Type |
|------------|----------------|
| Imports `child_process`, has `spawn`/`exec`/`execSync` | Process Spawner |
| Imports `http`/`https`/`express`/`fastify`/`koa`, has `listen()` | HTTP Server |
| Imports `fs`, reads/parses files, has parse functions | File Parser |
| Has CLI argument parsing (`process.argv`, `yargs`, `commander`, `argparse`) | CLI Command |
| Imports database driver (`pg`, `mysql`, `mongoose`, `sqlite`, `prisma`) | Database |
| Makes outbound HTTP calls (`fetch`, `axios`, `got`, `requests`) | External API |

---

## Pattern 1: CLI Command Verification

### Strategy
Spawn the CLI as a child process, capture stdout/stderr, verify exit code and output.

### Template (Bash)
```bash
#!/bin/bash
# CLI Verification: {component_name}
set -e

echo "=== CLI Verification: {component_name} ==="

# Test 1: Basic invocation
echo -n "Test 1: Basic invocation... "
OUTPUT=$({cli_command} {args} 2>&1)
EXIT_CODE=$?
if [ $EXIT_CODE -eq 0 ]; then
  echo "PASS (exit code 0)"
else
  echo "FAIL (exit code $EXIT_CODE)"
  exit 1
fi

# Test 2: Output contains expected text
echo -n "Test 2: Output validation... "
if echo "$OUTPUT" | grep -q "{expected_text}"; then
  echo "PASS (found expected text)"
else
  echo "FAIL (missing expected text)"
  echo "Output was: $OUTPUT"
  exit 1
fi

# Test 3: Error handling
echo -n "Test 3: Error handling... "
ERROR_OUTPUT=$({cli_command} --invalid-flag 2>&1) || true
if echo "$ERROR_OUTPUT" | grep -qi "error\|usage\|invalid"; then
  echo "PASS (error message shown)"
else
  echo "FAIL (no error message)"
  exit 1
fi

echo "=== All tests passed ==="
```

### Template (Node/Jest)
```javascript
const { execSync, spawn } = require('child_process');

describe('{component_name} CLI', () => {
  test('basic invocation succeeds', () => {
    const output = execSync('{cli_command} {args}', { encoding: 'utf8' });
    expect(output).toContain('{expected_text}');
  });

  test('returns correct exit code on success', (done) => {
    const result = spawn('{cli_command}', ['{args}']);
    result.on('close', (code) => {
      expect(code).toBe(0);
      done();
    });
  });

  test('shows error on invalid input', () => {
    expect(() => {
      execSync('{cli_command} --invalid', { encoding: 'utf8', stdio: 'pipe' });
    }).toThrow();
  });
});
```

### Template (Python/pytest)
```python
import subprocess
import pytest

class TestCLI:
    def test_basic_invocation(self):
        result = subprocess.run(
            ['{cli_command}', '{args}'],
            capture_output=True,
            text=True
        )
        assert result.returncode == 0
        assert '{expected_text}' in result.stdout

    def test_error_handling(self):
        result = subprocess.run(
            ['{cli_command}', '--invalid-flag'],
            capture_output=True,
            text=True
        )
        assert result.returncode != 0
        assert 'error' in result.stderr.lower() or 'usage' in result.stderr.lower()
```

---

## Pattern 2: HTTP Server Verification

### Strategy
Start server, wait for ready, make HTTP requests, verify responses, cleanup.

### Template (Bash)
```bash
#!/bin/bash
# HTTP Server Verification: {component_name}
set -e

echo "=== HTTP Server Verification: {component_name} ==="

# Start server in background
{start_command} &
SERVER_PID=$!
echo "Started server (PID: $SERVER_PID)"

# Cleanup trap
cleanup() {
  echo "Cleaning up..."
  kill $SERVER_PID 2>/dev/null || true
  wait $SERVER_PID 2>/dev/null || true
}
trap cleanup EXIT

# Wait for server to be ready
echo -n "Waiting for server... "
for i in {1..30}; do
  if curl -s http://localhost:{port}/health > /dev/null 2>&1; then
    echo "ready"
    break
  fi
  sleep 0.5
done

# Test 1: Health endpoint
echo -n "Test 1: Health endpoint... "
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:{port}/health)
if [ "$HTTP_CODE" = "200" ]; then
  echo "PASS (HTTP 200)"
else
  echo "FAIL (HTTP $HTTP_CODE)"
  exit 1
fi

# Test 2: API endpoint response
echo -n "Test 2: API response... "
RESPONSE=$(curl -s http://localhost:{port}{endpoint})
if echo "$RESPONSE" | jq -e '{json_validation}' > /dev/null 2>&1; then
  echo "PASS (valid response)"
else
  echo "FAIL (invalid response)"
  echo "Response was: $RESPONSE"
  exit 1
fi

# Test 3: 404 handling
echo -n "Test 3: 404 handling... "
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:{port}/nonexistent)
if [ "$HTTP_CODE" = "404" ]; then
  echo "PASS (HTTP 404)"
else
  echo "FAIL (HTTP $HTTP_CODE, expected 404)"
  exit 1
fi

echo "=== All tests passed ==="
```

### Template (Node/Jest with Supertest)
```javascript
const request = require('supertest');
const { createServer } = require('{component_path}');

describe('{component_name} HTTP Server', () => {
  let server;

  beforeAll(async () => {
    server = await createServer();
  });

  afterAll(async () => {
    await server.close();
  });

  test('health endpoint returns 200', async () => {
    const response = await request(server).get('/health');
    expect(response.status).toBe(200);
  });

  test('API endpoint returns valid data', async () => {
    const response = await request(server).get('{endpoint}');
    expect(response.status).toBe(200);
    expect(response.body).toHaveProperty('{expected_field}');
  });

  test('handles 404 gracefully', async () => {
    const response = await request(server).get('/nonexistent');
    expect(response.status).toBe(404);
  });
});
```

### Template (Python/pytest)
```python
import pytest
import requests
import subprocess
import time

@pytest.fixture(scope='module')
def server():
    proc = subprocess.Popen(['{start_command}'])
    # Wait for server to start
    for _ in range(30):
        try:
            requests.get('http://localhost:{port}/health')
            break
        except requests.ConnectionError:
            time.sleep(0.5)
    yield 'http://localhost:{port}'
    proc.terminate()
    proc.wait()

def test_health_endpoint(server):
    response = requests.get(f'{server}/health')
    assert response.status_code == 200

def test_api_endpoint(server):
    response = requests.get(f'{server}{endpoint}')
    assert response.status_code == 200
    assert '{expected_field}' in response.json()

def test_404_handling(server):
    response = requests.get(f'{server}/nonexistent')
    assert response.status_code == 404
```

---

## Pattern 3: File Parser Verification

### Strategy
Create test input file, run parser, verify parsed output structure and values.

### Template (Bash)
```bash
#!/bin/bash
# File Parser Verification: {component_name}
set -e

echo "=== File Parser Verification: {component_name} ==="

# Create test input
TEST_FILE=$(mktemp --suffix=.{ext})
cat > "$TEST_FILE" << 'EOF'
{test_input_content}
EOF

# Cleanup trap
cleanup() {
  rm -f "$TEST_FILE"
}
trap cleanup EXIT

# Test 1: Parse succeeds
echo -n "Test 1: Parse succeeds... "
OUTPUT=$({parser_command} "$TEST_FILE" 2>&1)
if [ $? -eq 0 ]; then
  echo "PASS"
else
  echo "FAIL"
  exit 1
fi

# Test 2: Output structure valid
echo -n "Test 2: Output structure... "
if echo "$OUTPUT" | jq -e '{json_structure_check}' > /dev/null 2>&1; then
  echo "PASS"
else
  echo "FAIL"
  echo "Output was: $OUTPUT"
  exit 1
fi

# Test 3: Values correct
echo -n "Test 3: Values correct... "
VALUE=$(echo "$OUTPUT" | jq -r '{value_path}')
if [ "$VALUE" = "{expected_value}" ]; then
  echo "PASS"
else
  echo "FAIL (expected: {expected_value}, got: $VALUE)"
  exit 1
fi

# Test 4: Invalid input handling
echo -n "Test 4: Invalid input handling... "
if ! {parser_command} "/nonexistent/file.{ext}" 2>&1; then
  echo "PASS (error returned)"
else
  echo "FAIL (should have errored)"
  exit 1
fi

echo "=== All tests passed ==="
```

### Template (Node/Jest)
```javascript
const fs = require('fs');
const path = require('path');
const os = require('os');
const { parse } = require('{component_path}');

describe('{component_name} Parser', () => {
  let testFile;

  beforeAll(() => {
    testFile = path.join(os.tmpdir(), 'test-input.{ext}');
    fs.writeFileSync(testFile, `{test_input_content}`);
  });

  afterAll(() => {
    fs.unlinkSync(testFile);
  });

  test('parses valid input', () => {
    const result = parse(testFile);
    expect(result).toBeDefined();
  });

  test('output has expected structure', () => {
    const result = parse(testFile);
    expect(result).toHaveProperty('{expected_field}');
  });

  test('values are correct', () => {
    const result = parse(testFile);
    expect(result.{field}).toBe('{expected_value}');
  });

  test('handles invalid input', () => {
    expect(() => parse('/nonexistent/file.{ext}')).toThrow();
  });
});
```

### Template (Python/pytest)
```python
import pytest
import tempfile
import os
from {module} import {parser_function}

@pytest.fixture
def test_file():
    fd, path = tempfile.mkstemp(suffix='.{ext}')
    with os.fdopen(fd, 'w') as f:
        f.write('''{test_input_content}''')
    yield path
    os.unlink(path)

def test_parse_succeeds(test_file):
    result = {parser_function}(test_file)
    assert result is not None

def test_output_structure(test_file):
    result = {parser_function}(test_file)
    assert '{expected_field}' in result

def test_values_correct(test_file):
    result = {parser_function}(test_file)
    assert result['{field}'] == '{expected_value}'

def test_handles_invalid_input():
    with pytest.raises({ExpectedException}):
        {parser_function}('/nonexistent/file.{ext}')
```

---

## Pattern 4: Process Spawner Verification

### Strategy
Spawn process, verify it's running (check port/pid), verify behavior, cleanup.

### Template (Bash)
```bash
#!/bin/bash
# Process Spawner Verification: {component_name}
set -e

echo "=== Process Spawner Verification: {component_name} ==="

# Spawn process
{spawn_command} &
PROC_PID=$!
echo "Spawned process (PID: $PROC_PID)"

# Cleanup trap
cleanup() {
  echo "Cleaning up..."
  kill $PROC_PID 2>/dev/null || true
  wait $PROC_PID 2>/dev/null || true
}
trap cleanup EXIT

sleep 2  # Wait for startup

# Test 1: Process is running
echo -n "Test 1: Process running... "
if kill -0 $PROC_PID 2>/dev/null; then
  echo "PASS (PID $PROC_PID alive)"
else
  echo "FAIL (process not running)"
  exit 1
fi

# Test 2: Port is open (if applicable)
echo -n "Test 2: Port {port} open... "
if nc -z localhost {port} 2>/dev/null; then
  echo "PASS"
else
  echo "FAIL"
  exit 1
fi

# Test 3: Process responds correctly
echo -n "Test 3: Process responds... "
RESPONSE=$({verification_command})
if echo "$RESPONSE" | grep -q "{expected_pattern}"; then
  echo "PASS"
else
  echo "FAIL (expected pattern: {expected_pattern}, got: $RESPONSE)"
  exit 1
fi

echo "=== All tests passed ==="
```

### Template (Node/Jest)
```javascript
const { spawn, execSync } = require('child_process');
const net = require('net');

function waitForPort(port, timeout = 5000) {
  return new Promise((resolve, reject) => {
    const start = Date.now();
    const check = () => {
      const socket = new net.Socket();
      socket.setTimeout(100);
      socket.on('connect', () => {
        socket.destroy();
        resolve(true);
      });
      socket.on('error', () => {
        socket.destroy();
        if (Date.now() - start > timeout) reject(new Error('Timeout'));
        else setTimeout(check, 100);
      });
      socket.connect(port, 'localhost');
    };
    check();
  });
}

describe('{component_name} Process', () => {
  let proc;

  beforeAll(async () => {
    proc = spawn('{spawn_command}', [], { detached: true });
    await waitForPort({port});
  });

  afterAll(() => {
    if (proc) {
      process.kill(-proc.pid);
    }
  });

  test('process is running', () => {
    expect(proc.pid).toBeDefined();
    expect(() => process.kill(proc.pid, 0)).not.toThrow();
  });

  test('port is open', async () => {
    await expect(waitForPort({port}, 1000)).resolves.toBe(true);
  });

  test('responds correctly', () => {
    const output = execSync('{verification_command}', { encoding: 'utf8' });
    expect(output).toContain('{expected_pattern}');
  });
});
```

---

## Pattern 5: Database Verification

### Strategy
Setup test database, execute operations, verify state changes, teardown.

### Template (Node/Jest)
```javascript
const { setupTestDb, teardownTestDb } = require('./test-utils');
const { saveRecord, findRecord, deleteRecord } = require('{component_path}');

describe('{component_name} Database Operations', () => {
  let db;

  beforeAll(async () => {
    db = await setupTestDb();
  });

  afterAll(async () => {
    await teardownTestDb(db);
  });

  beforeEach(async () => {
    await db.clear();  // Clean state between tests
  });

  test('save creates record in database', async () => {
    const data = { id: 1, value: 'test' };
    await saveRecord(db, data);

    const found = await db.findOne({ id: 1 });
    expect(found).toBeDefined();
    expect(found.value).toBe('test');
  });

  test('find retrieves existing record', async () => {
    await db.insert({ id: 2, value: 'existing' });

    const result = await findRecord(db, 2);
    expect(result.value).toBe('existing');
  });

  test('delete removes record from database', async () => {
    await db.insert({ id: 3, value: 'to-delete' });

    await deleteRecord(db, 3);

    const found = await db.findOne({ id: 3 });
    expect(found).toBeNull();
  });
});
```

### Template (Python/pytest)
```python
import pytest
from {module} import save_record, find_record, delete_record

@pytest.fixture
def test_db():
    db = setup_test_database()
    yield db
    teardown_test_database(db)

@pytest.fixture(autouse=True)
def clean_db(test_db):
    yield
    test_db.clear()

def test_save_creates_record(test_db):
    save_record(test_db, {'id': 1, 'value': 'test'})

    found = test_db.find_one({'id': 1})
    assert found is not None
    assert found['value'] == 'test'

def test_find_retrieves_record(test_db):
    test_db.insert({'id': 2, 'value': 'existing'})

    result = find_record(test_db, 2)
    assert result['value'] == 'existing'

def test_delete_removes_record(test_db):
    test_db.insert({'id': 3, 'value': 'to-delete'})

    delete_record(test_db, 3)

    found = test_db.find_one({'id': 3})
    assert found is None
```

### Template (Bash - SQLite)
```bash
#!/bin/bash
# Database Verification: {component_name}
set -e

echo "=== Database Verification: {component_name} ==="

TEST_DB=$(mktemp --suffix=.db)

cleanup() {
  rm -f "$TEST_DB"
}
trap cleanup EXIT

# Initialize test database
sqlite3 "$TEST_DB" "CREATE TABLE {table} (id INTEGER PRIMARY KEY, value TEXT);"

# Test 1: Insert
echo -n "Test 1: Insert record... "
{insert_command} "$TEST_DB"
COUNT=$(sqlite3 "$TEST_DB" "SELECT COUNT(*) FROM {table};")
if [ "$COUNT" -gt 0 ]; then
  echo "PASS ($COUNT records)"
else
  echo "FAIL (no records inserted)"
  exit 1
fi

# Test 2: Query
echo -n "Test 2: Query record... "
VALUE=$(sqlite3 "$TEST_DB" "SELECT value FROM {table} WHERE id=1;")
if [ "$VALUE" = "{expected_value}" ]; then
  echo "PASS"
else
  echo "FAIL (expected: {expected_value}, got: $VALUE)"
  exit 1
fi

# Test 3: Delete
echo -n "Test 3: Delete record... "
{delete_command} "$TEST_DB"
COUNT=$(sqlite3 "$TEST_DB" "SELECT COUNT(*) FROM {table};")
if [ "$COUNT" -eq 0 ]; then
  echo "PASS (deleted)"
else
  echo "FAIL ($COUNT records remain)"
  exit 1
fi

echo "=== All tests passed ==="
```

---

## Pattern 6: External API Verification

### Strategy
Use MSW (Mock Service Worker) to intercept at network level - not module level.
This allows real HTTP calls while controlling external responses.

### Template (Node/Jest with MSW)
```javascript
import { setupServer } from 'msw/node';
import { rest } from 'msw';
import { fetchUserData, postOrder } from '{component_path}';

// Setup MSW server with handlers
const server = setupServer(
  rest.get('https://api.example.com/users/:id', (req, res, ctx) => {
    return res(ctx.json({
      id: req.params.id,
      name: 'Test User',
      email: 'test@example.com'
    }));
  }),
  rest.post('https://api.example.com/orders', async (req, res, ctx) => {
    const body = await req.json();
    return res(ctx.json({
      orderId: 'ORD-123',
      items: body.items,
      status: 'created'
    }));
  })
);

beforeAll(() => server.listen());
afterEach(() => server.resetHandlers());
afterAll(() => server.close());

describe('{component_name} External API', () => {
  test('fetches user data from API', async () => {
    // Real fetch call - intercepted by MSW at network level
    const user = await fetchUserData(1);

    expect(user.name).toBe('Test User');
    expect(user.email).toBe('test@example.com');
  });

  test('posts order to API', async () => {
    const order = await postOrder({ items: [{ sku: 'ABC', qty: 2 }] });

    expect(order.orderId).toBe('ORD-123');
    expect(order.status).toBe('created');
  });

  test('handles API errors gracefully', async () => {
    // Override handler for this test
    server.use(
      rest.get('https://api.example.com/users/:id', (req, res, ctx) => {
        return res(ctx.status(500), ctx.json({ error: 'Server error' }));
      })
    );

    await expect(fetchUserData(1)).rejects.toThrow('API error');
  });
});
```

### Template (Python/pytest with responses)
```python
import pytest
import responses
from {module} import fetch_user_data, post_order

@responses.activate
def test_fetches_user_data():
    responses.add(
        responses.GET,
        'https://api.example.com/users/1',
        json={'id': 1, 'name': 'Test User', 'email': 'test@example.com'},
        status=200
    )

    user = fetch_user_data(1)

    assert user['name'] == 'Test User'
    assert user['email'] == 'test@example.com'

@responses.activate
def test_posts_order():
    responses.add(
        responses.POST,
        'https://api.example.com/orders',
        json={'orderId': 'ORD-123', 'status': 'created'},
        status=201
    )

    order = post_order({'items': [{'sku': 'ABC', 'qty': 2}]})

    assert order['orderId'] == 'ORD-123'
    assert order['status'] == 'created'

@responses.activate
def test_handles_api_errors():
    responses.add(
        responses.GET,
        'https://api.example.com/users/1',
        json={'error': 'Server error'},
        status=500
    )

    with pytest.raises(Exception) as exc:
        fetch_user_data(1)
    assert 'API error' in str(exc.value)
```

### Key Difference from jest.mock

| Approach | What Happens | Real HTTP? |
|----------|--------------|------------|
| `jest.mock('node-fetch')` | Replaces module entirely | No |
| MSW / responses | Intercepts at network layer | Yes (intercepted before leaving machine) |

MSW allows real `fetch()` calls to execute, testing the actual HTTP code path while still controlling external responses.

---

## Quick Reference: Component to Pattern

| Component Type | Bash Template | Node Template | Python Template |
|----------------|---------------|---------------|-----------------|
| CLI Command | Pattern 1 | Pattern 1 | Pattern 1 |
| HTTP Server | Pattern 2 | Pattern 2 (supertest) | Pattern 2 |
| File Parser | Pattern 3 | Pattern 3 | Pattern 3 |
| Process Spawner | Pattern 4 | Pattern 4 | - |
| Database | Pattern 5 (SQLite) | Pattern 5 | Pattern 5 |
| External API | - | Pattern 6 (MSW) | Pattern 6 (responses) |

---

## Diagnostic Output

Write diagnostic output to `logs/diagnostics/component-patterns-{YYYYMMDD-HHMMSS}.yaml`:

```yaml
skill: component-patterns
timestamp: {ISO-8601}
diagnostics:
  component_type_detected: cli|http|file-parser|process|database|api
  pattern_applied: "CLI Command Verification"
  template_language: bash|node|python
  files_analyzed: 1
  completion_status: success
```
