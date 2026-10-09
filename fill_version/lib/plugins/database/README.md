# Database Plugin

Full SQLite database with CRUD, raw queries, and batch operations.

## Plugin Name
`database`

## Methods

### `open`
| Param | Type | Required |
|-------|------|----------|
| `name` | `string` | ✅ |
| `version` | `number` | — (default 1) |
| `onCreate` | `string[]` | — (SQL statements) |

### `query`
| Param | Type |
|-------|------|
| `name` | database name |
| `table` | table name |
| `where` | SQL where clause |
| `whereArgs` | `any[]` |
| `orderBy` | `string` |
| `limit` | `number` |
| `offset` | `number` |

### `insert`
| Param | Type |
|-------|------|
| `name` | database name |
| `table` | table name |
| `values` | `{ column: value }` |

### `update`, `delete` — similar with `where`/`whereArgs`

### `rawQuery`, `rawInsert`, `rawUpdate`, `rawDelete`
Direct SQL execution.

### `batch`
Execute multiple operations atomically.

### `tableExists`, `deleteDatabase`, `close`

## Usage
```javascript
// Open with table creation
await NativeSDK.database.open('mydb', {
  version: 1,
  onCreate: [
    'CREATE TABLE users (id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT, email TEXT, age INTEGER)'
  ]
});

// Insert
const { id } = await NativeSDK.database.insert('mydb', 'users', {
  name: 'Ali', email: 'ali@test.com', age: 28
});

// Query
const { rows } = await NativeSDK.database.query('mydb', 'users', {
  where: 'age > ?',
  whereArgs: [25],
  orderBy: 'name ASC',
  limit: 10
});

// Raw query
const result = await NativeSDK.database.rawQuery('mydb',
  'SELECT COUNT(*) as total FROM users WHERE age > ?', [25]
);

// Batch
await NativeSDK.database.batch('mydb', [
  { type: 'insert', table: 'users', values: { name: 'User1' } },
  { type: 'insert', table: 'users', values: { name: 'User2' } },
  { type: 'delete', table: 'users', where: 'age < ?', whereArgs: [18] }
]);
```
