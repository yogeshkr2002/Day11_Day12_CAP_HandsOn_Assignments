namespace com.procurement;

using { cuid, managed, Currency } from '@sap/cds/common';

// ─── TYPES ─────────────────────────────────
type POStatus : String(20) enum {
  Draft    = 'Draft';
  Pending  = 'Pending';
  Approved = 'Approved';
  Rejected = 'Rejected';
  Ordered  = 'Ordered';
  Received = 'Received';
}

type Priority : String(10) enum {
  Low    = 'Low';
  Medium = 'Medium';
  High   = 'High';
  Urgent = 'Urgent';
}

// ─── SUPPLIERS ─────────────────────────────
entity Suppliers : cuid, managed {
  supplierName  : String(200);
  contactPerson : String(100);
  email         : String(255);
  phone         : String(20);
  city          : String(100);
  rating        : Decimal(2,1) default 0.0;
  isActive      : Boolean default true;
  orders        : Association to many PurchaseOrders on orders.supplier = $self;
}

// ─── PRODUCTS ──────────────────────────────
entity Products : cuid, managed {
  productName   : String(100);
  description   : String(500);
  unitPrice     : Decimal(10,2);
  currency      : Currency;
  stock         : Integer default 0;
  minStock      : Integer default 10;
  unit          : String(10) default 'EA';
  supplier      : Association to Suppliers;
  isActive      : Boolean default true;
}

// ─── PURCHASE ORDERS ───────────────────────
entity PurchaseOrders : cuid, managed {
  poNumber      : String(20);
  supplier      : Association to Suppliers;
  orderDate     : Date;
  requiredDate  : Date;
  status        : POStatus default 'Draft';
  priority      : Priority default 'Medium';
  totalAmount   : Decimal(12,2) default 0;
  currency      : Currency;
  notes         : String(1000);
  approvedBy    : String(100);
  approvedAt    : DateTime;
  rejectionNote : String(500);
  items         : Composition of many PurchaseOrderItems on items.po = $self;
}

// ─── PO LINE ITEMS ─────────────────────────
entity PurchaseOrderItems : cuid {
  po            : Association to PurchaseOrders;
  product       : Association to Products;
  quantity      : Integer;
  unitPrice     : Decimal(10,2);
  totalPrice    : Decimal(12,2);
  currency      : Currency;
  receivedQty   : Integer default 0;
  notes         : String(500);
}