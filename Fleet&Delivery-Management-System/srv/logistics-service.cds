using logistics.fleet as db from '../db/schema';

service LogisticsService {

    entity Vehicles as projection on db.Vehicles;

    entity Drivers as projection on db.Drivers;

    entity Customers as projection on db.Customers;

    entity Shipments as projection on db.Shipments;

    entity Routes as projection on db.Routes;

    entity ServiceRecords as projection on db.ServiceRecords;

}