const cds = require('@sap/cds');

module.exports = function () {

  const { PurchaseOrders, PurchaseOrderItems, Products, Suppliers } = cds.entities;

  // ══════════════════════════════════════════════════════════
  //  VALIDATION: Before CREATE/UPDATE PurchaseOrders
  // ══════════════════════════════════════════════════════════
  this.before('CREATE', 'PurchaseOrders', async (req) => {
    const { supplier_ID, requiredDate, priority } = req.data;

    if (!supplier_ID) {
      req.error(400, 'Supplier is required', 'supplier_ID');
    }

    if (supplier_ID) {
      const supplier = await SELECT.one.from(Suppliers).where({ ID: supplier_ID });
      if (!supplier) req.error(404, 'Supplier not found', 'supplier_ID');
      if (supplier && !supplier.isActive) req.error(400, 'Supplier is inactive', 'supplier_ID');
    }

    if (requiredDate) {
      const today = new Date().toISOString().split('T')[0];
      if (requiredDate < today) {
        req.error(400, 'Required date cannot be in the past', 'requiredDate');
      }
    }

    // Auto-generate PO number
    if (!req.data.poNumber) {
      const count = await SELECT.from(PurchaseOrders).columns('ID');
      req.data.poNumber = `PO-${String(count.length + 1).padStart(5, '0')}`;
    }

    // Default values
    if (!req.data.status) req.data.status = 'Draft';
    if (!req.data.orderDate) req.data.orderDate = new Date().toISOString().split('T')[0];
  });

  this.before('UPDATE', 'PurchaseOrders', async (req) => {
    const poId = req.params[0]?.ID || req.params[0];
    const po = await SELECT.one.from(PurchaseOrders).where({ ID: poId });

    if (po && po.status !== 'Draft' && po.status !== 'Rejected') {
      const allowedFields = ['notes'];
      const attemptedFields = Object.keys(req.data).filter(f => f !== 'modifiedAt' && f !== 'modifiedBy');
      const blockedFields = attemptedFields.filter(f => !allowedFields.includes(f));

      if (blockedFields.length > 0) {
        req.reject(400,
          `Cannot modify PO in "${po.status}" status. Only "Draft" or "Rejected" POs can be edited.`
        );
      }
    }
  });

  // ══════════════════════════════════════════════════════════
  //  VALIDATION: PurchaseOrderItems
  // ══════════════════════════════════════════════════════════
  this.before('CREATE', 'PurchaseOrderItems', async (req) => {
    const { product_ID, quantity, unitPrice } = req.data;

    if (!product_ID) req.error(400, 'Product is required', 'product_ID');
    if (!quantity || quantity <= 0) req.error(400, 'Quantity must be greater than 0', 'quantity');
    if (!unitPrice || unitPrice <= 0) req.error(400, 'Unit price must be greater than 0', 'unitPrice');

    if (product_ID) {
      const product = await SELECT.one.from(Products).where({ ID: product_ID });
      if (!product) req.error(404, 'Product not found', 'product_ID');
    }

    // Auto-calculate total
    if (quantity && unitPrice) {
      req.data.totalPrice = +(quantity * unitPrice).toFixed(2);
    }
  });

  // ══════════════════════════════════════════════════════════
  //  ACTION: Submit PO for approval
  // ══════════════════════════════════════════════════════════
  this.on('submit', 'PurchaseOrders', async (req) => {
    const { ID } = req.params[0];

    const po = await SELECT.one.from(PurchaseOrders).where({ ID });
    if (!po) req.reject(404, 'Purchase Order not found');

    if (po.status !== 'Draft' && po.status !== 'Rejected') {
      req.reject(400, `Cannot submit: PO is "${po.status}". Only Draft or Rejected POs can be submitted.`);
    }

    const items = await SELECT.from(PurchaseOrderItems).where({ po_ID: ID });
    if (items.length === 0) {
      req.reject(400, 'Cannot submit: PO has no line items. Add at least one item.');
    }

    const totalAmount = items.reduce((sum, item) => sum + (item.quantity * item.unitPrice), 0);

    await UPDATE(PurchaseOrders).set({
      status: 'Pending',
      totalAmount: +totalAmount.toFixed(2),
      rejectionNote: null
    }).where({ ID });

    await this.emit('POSubmitted', {
      poId: ID,
      poNumber: po.poNumber,
      amount: +totalAmount.toFixed(2),
      priority: po.priority
    });

    return {
      status: 'Pending',
      message: `PO ${po.poNumber} submitted for approval (${items.length} items, $${totalAmount.toFixed(2)})`
    };
  });

  // ══════════════════════════════════════════════════════════
  //  ACTION: Approve PO
  // ══════════════════════════════════════════════════════════
  this.on('approve', 'PurchaseOrders', async (req) => {
    const { ID } = req.params[0];
    const { comment } = req.data;

    const po = await SELECT.one.from(PurchaseOrders).where({ ID });
    if (!po) req.reject(404, 'Purchase Order not found');

    if (po.status !== 'Pending') {
      req.reject(400, `Cannot approve: PO is "${po.status}". Only Pending POs can be approved.`);
    }

    const now = new Date().toISOString();
    await UPDATE(PurchaseOrders).set({
      status: 'Approved',
      approvedBy: req.user.id || 'approver',
      approvedAt: now
    }).where({ ID });

    await this.emit('POApproved', {
      poId: ID,
      poNumber: po.poNumber,
      approver: req.user.id || 'approver'
    });

    return {
      status: 'Approved',
      message: `PO ${po.poNumber} approved.${comment ? ' Note: ' + comment : ''}`,
      approvedAt: now
    };
  });

  // ══════════════════════════════════════════════════════════
  //  ACTION: Reject PO
  // ══════════════════════════════════════════════════════════
  this.on('reject', 'PurchaseOrders', async (req) => {
    const { ID } = req.params[0];
    const { reason } = req.data;

    const po = await SELECT.one.from(PurchaseOrders).where({ ID });
    if (!po) req.reject(404, 'Purchase Order not found');

    if (po.status !== 'Pending') {
      req.reject(400, `Cannot reject: PO is "${po.status}". Only Pending POs can be rejected.`);
    }
    if (!reason || reason.trim() === '') {
      req.reject(400, 'Rejection reason is required');
    }

    await UPDATE(PurchaseOrders).set({
      status: 'Rejected',
      rejectionNote: reason
    }).where({ ID });

    await this.emit('POrejected', {
      poId: ID,
      poNumber: po.poNumber,
      reason: reason
    });

    return {
      status: 'Rejected',
      message: `PO ${po.poNumber} rejected. Reason: ${reason}`
    };
  });

  // ══════════════════════════════════════════════════════════
  //  ACTION: Resubmit (after rejection)
  // ══════════════════════════════════════════════════════════
  this.on('resubmit', 'PurchaseOrders', async (req) => {
    const { ID } = req.params[0];

    const po = await SELECT.one.from(PurchaseOrders).where({ ID });
    if (!po) req.reject(404, 'Purchase Order not found');

    if (po.status !== 'Rejected') {
      req.reject(400, `Cannot resubmit: PO is "${po.status}". Only Rejected POs can be resubmitted.`);
    }

    await UPDATE(PurchaseOrders).set({
      status: 'Draft',
      rejectionNote: null
    }).where({ ID });

    return {
      status: 'Draft',
      message: `PO ${po.poNumber} moved back to Draft. Please make corrections and submit again.`
    };
  });

  // ══════════════════════════════════════════════════════════
  //  ACTION: Mark as Ordered (sent to supplier)
  // ══════════════════════════════════════════════════════════
  this.on('markOrdered', 'PurchaseOrders', async (req) => {
    const { ID } = req.params[0];
    const { referenceNumber } = req.data;

    const po = await SELECT.one.from(PurchaseOrders).where({ ID });
    if (!po) req.reject(404, 'Purchase Order not found');

    if (po.status !== 'Approved') {
      req.reject(400, `Cannot mark as ordered: PO must be Approved. Current: "${po.status}"`);
    }
    if (!referenceNumber) {
      req.reject(400, 'Supplier reference number is required');
    }

    await UPDATE(PurchaseOrders).set({
      status: 'Ordered'
    }).where({ ID });

    return {
      status: 'Ordered',
      message: `PO ${po.poNumber} marked as ordered. Supplier ref: ${referenceNumber}`
    };
  });

  // ══════════════════════════════════════════════════════════
  //  ACTION: Receive Goods (updates stock!)
  // ══════════════════════════════════════════════════════════
  this.on('receiveGoods', 'PurchaseOrders', async (req) => {
    const { ID } = req.params[0];
    const { notes } = req.data;

    const po = await SELECT.one.from(PurchaseOrders).where({ ID });
    if (!po) req.reject(404, 'Purchase Order not found');

    if (po.status !== 'Ordered') {
      req.reject(400, `Cannot receive: PO must be "Ordered". Current: "${po.status}"`);
    }

    const items = await SELECT.from(PurchaseOrderItems).where({ po_ID: ID });
    let updatedProducts = 0;

    for (const item of items) {
      const product = await SELECT.one.from(Products).where({ ID: item.product_ID });
      if (product) {
        const oldStock = product.stock;
        const newStock = oldStock + item.quantity;

        await UPDATE(Products).set({ stock: newStock }).where({ ID: item.product_ID });
        await UPDATE(PurchaseOrderItems).set({ receivedQty: item.quantity }).where({ ID: item.ID });

        await this.emit('StockUpdated', {
          productId: item.product_ID,
          productName: product.productName,
          oldStock: oldStock,
          newStock: newStock
        });

        updatedProducts++;
      }
    }

    await UPDATE(PurchaseOrders).set({ status: 'Received' }).where({ ID });

    return {
      status: 'Received',
      message: `PO ${po.poNumber} received. Stock updated for ${updatedProducts} product(s).${notes ? ' Notes: ' + notes : ''}`,
      updatedProducts: updatedProducts
    };
  });

  // ══════════════════════════════════════════════════════════
  //  FUNCTION: getSummary (bound)
  // ══════════════════════════════════════════════════════════
  this.on('getSummary', 'PurchaseOrders', async (req) => {
    const { ID } = req.params[0];

    const po = await SELECT.one.from(PurchaseOrders).where({ ID });
    if (!po) req.reject(404, 'PO not found');

    const items = await SELECT.from(PurchaseOrderItems).where({ po_ID: ID });
    const supplier = await SELECT.one.from(Suppliers).where({ ID: po.supplier_ID });

    const total = items.reduce((sum, i) => sum + (i.quantity * i.unitPrice), 0);
    const created = new Date(po.createdAt || po.orderDate);
    const daysOpen = Math.floor((new Date() - created) / 86400000);

    return {
      poNumber: po.poNumber,
      supplier: supplier?.supplierName || 'Unknown',
      itemCount: items.length,
      totalAmount: +total.toFixed(2),
      status: po.status,
      priority: po.priority,
      daysOpen: daysOpen,
      canApprove: po.status === 'Pending'
    };
  });

  // ══════════════════════════════════════════════════════════
  //  FUNCTION: getDashboard (unbound)
  // ══════════════════════════════════════════════════════════
  this.on('getDashboard', async () => {
    const allPOs = await SELECT.from(PurchaseOrders);

    const byStatus = (status) => allPOs.filter(p => p.status === status).length;
    const totalSpend = allPOs
      .filter(p => ['Approved', 'Ordered', 'Received'].includes(p.status))
      .reduce((sum, p) => sum + (p.totalAmount || 0), 0);

    return {
      total: allPOs.length,
      draft: byStatus('Draft'),
      pending: byStatus('Pending'),
      approved: byStatus('Approved'),
      ordered: byStatus('Ordered'),
      received: byStatus('Received'),
      rejected: byStatus('Rejected'),
      totalSpend: +totalSpend.toFixed(2),
      urgentCount: allPOs.filter(p => p.priority === 'Urgent' && p.status === 'Pending').length
    };
  });

  // ══════════════════════════════════════════════════════════
  //  FUNCTION: getLowStockProducts (unbound)
  // ══════════════════════════════════════════════════════════
  this.on('getLowStockProducts', async (req) => {
    const threshold = req.data.threshold || 0;

    const products = await SELECT.from(Products)
      .where('stock <=', 'minStock')
      .and('isActive =', true);

    const results = [];
    for (const p of products) {
      if (p.stock <= p.minStock + threshold) {
        const supplier = await SELECT.one.from(Suppliers).where({ ID: p.supplier_ID });
        results.push({
          productName: p.productName,
          stock: p.stock,
          minStock: p.minStock,
          deficit: p.minStock - p.stock,
          supplierName: supplier?.supplierName || 'No supplier'
        });
      }
    }

    return results.sort((a, b) => b.deficit - a.deficit);
  });

  // ══════════════════════════════════════════════════════════
  //  AFTER READ: Computed fields
  // ══════════════════════════════════════════════════════════
  this.after('READ', 'PurchaseOrders', (results) => {
    const pos = Array.isArray(results) ? results : [results];
    for (const po of pos) {
      if (po.status) {
        po.isEditable = ['Draft', 'Rejected'].includes(po.status);
        po.canSubmit = ['Draft', 'Rejected'].includes(po.status);
        po.canApprove = po.status === 'Pending';
      }
    }
  });

  // ══════════════════════════════════════════════════════════
  //  EVENT LISTENERS
  // ══════════════════════════════════════════════════════════
  this.on('POSubmitted', (msg) => {
    const { poNumber, amount, priority } = msg.data;
    const icon = priority === 'Urgent' ? '🚨' : '📋';
    console.log(`${icon} [SUBMITTED] ${poNumber} | $${amount} | Priority: ${priority}`);
  });

  this.on('POApproved', (msg) => {
    console.log(`✅ [APPROVED] ${msg.data.poNumber} by ${msg.data.approver}`);
  });

  this.on('POrejected', (msg) => {
    console.log(`❌ [REJECTED] ${msg.data.poNumber} | Reason: ${msg.data.reason}`);
  });

  this.on('StockUpdated', (msg) => {
    const { productName, oldStock, newStock } = msg.data;
    console.log(`📦 [STOCK] ${productName}: ${oldStock} → ${newStock} (+${newStock - oldStock})`);
  });

};