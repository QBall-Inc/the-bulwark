/**
 * Fixture: T3+ Violation - Broken Integration Chain
 *
 * Expected classification:
 * - category: integration (filename pattern: .integration.ts)
 * - needs_deep_analysis: true (integration file with mocks)
 *
 * Expected violations:
 * - rule: T3+
 * - severity: critical
 * - priority: P0 (false confidence - broken chain)
 * - violation_scope: [45, 85] (all tests using mock data instead of real output)
 * - affected_lines: ~40
 * - test_effectiveness: ~30%
 *
 * VIOLATION: Test claims to verify "order processing workflow" but uses
 * mockOrderData instead of real output from createOrder(). This breaks
 * the integration chain - processOrder() never receives real createOrder() output.
 */

import { OrderService } from '../../../src/order-service';
import { PaymentService } from '../../../src/payment-service';
import { InventoryService } from '../../../src/inventory-service';

describe('Order Processing Workflow Integration', () => {
  let orderService: OrderService;
  let paymentService: PaymentService;
  let inventoryService: InventoryService;

  beforeEach(() => {
    orderService = new OrderService();
    paymentService = new PaymentService();
    inventoryService = new InventoryService();
  });

  // This test is CORRECT - uses real function output
  describe('createOrder', () => {
    it('should create an order with inventory check', async () => {
      const items = [{ productId: 'PROD-1', quantity: 2 }];

      const order = await orderService.createOrder(items);

      expect(order.id).toBeDefined();
      expect(order.status).toBe('pending');
      expect(order.items).toEqual(items);
    });
  });

  // T3+ VIOLATION: Broken integration chain
  describe('processOrder', () => {
    it('should process order and charge payment', async () => {
      // VIOLATION: Using mock data instead of real createOrder() output
      const mockOrderData = {
        id: 'ORDER-123',
        status: 'pending',
        items: [{ productId: 'PROD-1', quantity: 2 }],
        total: 99.99,
      };

      // This breaks the integration chain!
      // processOrder() never receives real createOrder() output
      const result = await orderService.processOrder(mockOrderData);

      expect(result.status).toBe('processed');
      expect(result.paymentId).toBeDefined();
    });

    it('should update inventory after processing', async () => {
      // VIOLATION: Same broken chain pattern
      const mockOrderData = {
        id: 'ORDER-456',
        status: 'pending',
        items: [{ productId: 'PROD-2', quantity: 1 }],
        total: 49.99,
      };

      await orderService.processOrder(mockOrderData);

      // Even this check is unreliable because mockOrderData
      // may not match what createOrder() actually produces
      const inventory = await inventoryService.getStock('PROD-2');
      expect(inventory.reserved).toBeGreaterThan(0);
    });
  });

  // T3+ VIOLATION: Another broken chain
  describe('completeOrder', () => {
    it('should complete the full order workflow', async () => {
      // VIOLATION: Each step uses mock data, breaking the chain
      const mockOrder = { id: 'ORDER-789', status: 'pending', total: 150.0 };
      const mockProcessedOrder = { ...mockOrder, status: 'processed', paymentId: 'PAY-1' };

      // None of these are connected to real upstream output!
      const result = await orderService.completeOrder(mockProcessedOrder);

      expect(result.status).toBe('completed');
    });
  });
});
