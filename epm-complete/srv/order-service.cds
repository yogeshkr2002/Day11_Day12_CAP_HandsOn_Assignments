using { com.epm as db } from '../db/schema';

service OrderService @(path: '/orders') {

  // Standard CRUD entities
  entity Orders as projection on db.SalesOrders
    actions {
      // Bound actions (entity-specific, modify data)
      action confirm() returns { status: String; message: String; };
      action cancel(reason: String(500)) returns { status: String; message: String; refund: Decimal; };
      action ship(trackingNumber: String(50), carrier: String(50)) returns { status: String; message: String; };
      action deliver() returns { status: String; message: String; };

      // Bound functions (entity-specific, read-only)
      function getTotal() returns { net: Decimal; tax: Decimal; gross: Decimal; };
      function getTimeline() returns array of {
        event: String;
        timestamp: DateTime;
        description: String;
      };
    };

  entity OrderItems as projection on db.SalesOrderItems;
  entity Customers as projection on db.Customers;
  @readonly entity Products as projection on db.Products;

  // Unbound actions (service-level)
  action bulkConfirm(orderIds: array of UUID) returns {
    confirmed: Integer;
    failed: Integer;
    message: String;
  };

  // Unbound functions (service-level, read-only)
  function getOrderStats(year: Integer, month: Integer) returns {
    totalOrders: Integer;
    newOrders: Integer;
    confirmedOrders: Integer;
    shippedOrders: Integer;
    deliveredOrders: Integer;
    cancelledOrders: Integer;
    totalRevenue: Decimal;
  };

  function getTopCustomers(limit: Integer) returns array of {
    customerName: String;
    orderCount: Integer;
    totalSpent: Decimal;
  };
}