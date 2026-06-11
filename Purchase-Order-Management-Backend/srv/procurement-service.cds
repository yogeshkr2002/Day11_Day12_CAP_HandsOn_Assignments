using { com.procurement as db } from '../db/po-schema';

// ═══════════════════════════════════════════════
//  PROCUREMENT SERVICE — Full PO Management
// ═══════════════════════════════════════════════
service ProcurementService @(path: '/procurement') {

  entity PurchaseOrders as projection on db.PurchaseOrders
    actions {
      action submit() returns { status: String; message: String; };
      action approve(comment: String(500)) returns { status: String; message: String; approvedAt: DateTime; };
      action reject(reason: String(500)) returns { status: String; message: String; };
      action resubmit() returns { status: String; message: String; };
      action markOrdered(referenceNumber: String(50)) returns { status: String; message: String; };
      action receiveGoods(notes: String(500)) returns { status: String; message: String; updatedProducts: Integer; };

      function getSummary() returns {
        poNumber: String; supplier: String; itemCount: Integer;
        totalAmount: Decimal; status: String; priority: String;
        daysOpen: Integer; canApprove: Boolean;
      };
    };

  entity PurchaseOrderItems as projection on db.PurchaseOrderItems;
  entity Suppliers as projection on db.Suppliers;
  entity Products as projection on db.Products;

  // Unbound actions
  action bulkApprove(poIds: array of UUID) returns { approved: Integer; failed: Integer; };

  // Unbound functions
  function getDashboard() returns {
    total: Integer; draft: Integer; pending: Integer;
    approved: Integer; ordered: Integer; received: Integer;
    rejected: Integer; totalSpend: Decimal; urgentCount: Integer;
  };

  function getLowStockProducts(threshold: Integer) returns array of {
    productName: String; stock: Integer; minStock: Integer;
    deficit: Integer; supplierName: String;
  };

  // Events
  event POSubmitted { poId: UUID; poNumber: String; amount: Decimal; priority: String; }
  event POApproved  { poId: UUID; poNumber: String; approver: String; }
  event POrejected  { poId: UUID; poNumber: String; reason: String; }
  event StockUpdated { productId: UUID; productName: String; oldStock: Integer; newStock: Integer; }
}

// ═══════════════════════════════════════════════
//  CATALOG SERVICE — Public read-only browsing
// ═══════════════════════════════════════════════
service CatalogService @(path: '/catalog') {
  @readonly entity Products as projection on db.Products {
    ID, productName, description, unitPrice, currency, stock, unit
  };
  @readonly entity Suppliers as projection on db.Suppliers {
    ID, supplierName, city, rating
  };
}