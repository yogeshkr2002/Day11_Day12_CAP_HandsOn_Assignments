using { com.epm as db } from '../db/views';

service ReportService @(path:'/reports') {

    action PingHealth() returns {
        status  : String(20);
        message : String(100);
    };

    @readonly
    entity ProductCatalog
        as projection on db.ProductCatalog;

    @readonly
    entity OrderReport
        as projection on db.OrderReport;

    @readonly
    entity LowStockAlert
        as projection on db.LowStockAlert;
}