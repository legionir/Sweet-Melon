// جمع‌آوری همه تست‌ها برای اجرا با یک دستور
// اجرا: flutter test test/test_runner.dart

// Unit Tests — Core
import 'unit/core/message_protocol_test.dart' as protocol_test;
import 'unit/core/message_bridge_test.dart' as bridge_test;

// Unit Tests — Middleware
import 'unit/middleware/error_recovery_test.dart' as retry_test;
import 'unit/middleware/circuit_breaker_test.dart' as circuit_test;

// Unit Tests — Engine
import 'unit/engine/plugin_registry_test.dart' as registry_test;
import 'unit/engine/plugin_manager_test.dart' as manager_test;
import 'unit/engine/lazy_plugin_loader_test.dart' as lazy_test;

// Unit Tests — Security
import 'unit/security/rate_limiter_test.dart' as rate_test;
import 'unit/security/execution_guard_test.dart' as guard_test;

// Unit Tests — Performance
import 'unit/performance/cache_manager_test.dart' as cache_test;

// Plugin Tests
import 'plugins/encryption_plugin_test.dart' as encryption_test;
import 'plugins/storage_plugin_test.dart' as storage_test;

// Integration Tests
import 'integration/bridge_integration_test.dart' as bridge_integration;
import 'integration/lazy_loading_integration_test.dart' as lazy_integration;

void main() {
  // Core
  protocol_test.main();
  bridge_test.main();

  // Middleware
  retry_test.main();
  circuit_test.main();

  // Engine
  registry_test.main();
  manager_test.main();
  lazy_test.main();

  // Security
  rate_test.main();
  guard_test.main();

  // Performance
  cache_test.main();

  // Plugins
  encryption_test.main();
  storage_test.main();

  // Integration
  bridge_integration.main();
  lazy_integration.main();
}
