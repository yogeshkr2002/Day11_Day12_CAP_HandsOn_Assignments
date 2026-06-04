namespace logistics.fleet;


type Phone    : String(15);
type Email    : String(100);
type Amount   : Decimal(12,2);
type Distance : Decimal(10,2);
type City     : String(50);
type Address  : String(255);
type Rating   : Decimal(2,1);



type VehicleType : String enum {
    Bike;
    Van;
    Truck;
    Trailer;
};

type FuelType : String enum {
    Petrol;
    Diesel;
    Electric;
    CNG;
};

type VehicleStatus : String enum {
    Available;
    OnTrip;
    Maintenance;
    Retired;
};

type DriverStatus : String enum {
    Available;
    OnTrip;
    OnLeave;
};

type ShipmentStatus : String enum {
    Booked;
    PickedUp;
    InTransit;
    OutForDelivery;
    Delivered;
    Failed;
};

type PaymentStatus : String enum {
    Pending;
    Paid;
    COD;
};

type CustomerTier : String enum {
    Regular;
    Premium;
    Enterprise;
};

type ServiceType : String enum {
    Regular;
    Repair;
    Accident;
};



entity Vehicles {

    key ID              : UUID;

    registrationNumber  : String(20);

    type                : VehicleType;

    make                : String(50);

    model               : String(50);

    year                : Integer;

    capacity            : Decimal(10,2);

    fuelType            : FuelType;

    status              : VehicleStatus default 'Available';

    lastServiceDate     : Date;

    mileage             : Decimal(10,2);

    insuranceExpiry     : Date;
}

entity Drivers {

    key ID              : UUID;

    name                : String(100);

    licenseNumber       : String(50);

    licenseExpiry       : Date;

    phone               : Phone;

    email               : Email;

    experience          : Integer;

    rating              : Rating;

    status              : DriverStatus default 'Available';

    vehicle             : Association to Vehicles;

    joinDate            : Date;
}

entity Customers {

    key ID              : UUID;

    name                : String(100);

    company             : String(100);

    phone               : Phone;

    email               : Email;

    address             : Address;

    city                : City;

    pincode             : String(10);

    gstNumber           : String(20);

    tier                : CustomerTier;
}

entity Shipments {

    key ID              : UUID;

    trackingNumber      : String(30);

    customer            : Association to Customers;

    driver              : Association to Drivers;

    vehicle             : Association to Vehicles;

    pickupAddress       : Address;

    deliveryAddress     : Address;

    pickupCity          : City;

    deliveryCity        : City;

    weight              : Decimal(10,2);

    status              : ShipmentStatus default 'Booked';

    bookedAt            : DateTime;

    pickedUpAt          : DateTime;

    deliveredAt         : DateTime;

    estimatedDelivery   : Date;

    actualDistance      : Distance;

    charges             : Amount;

    paymentStatus       : PaymentStatus default 'Pending';
}

entity Routes {

    key ID              : UUID;

    fromCity            : City;

    toCity              : City;

    distance            : Distance;

    estimatedHours      : Decimal(5,2);

    tollCharges         : Amount;

    isActive            : Boolean default true;
}

entity ServiceRecords {

    key ID              : UUID;

    vehicle             : Association to Vehicles;

    serviceDate         : Date;

    serviceType         : ServiceType;

    cost                : Amount;

    description         : String(255);

    nextServiceDate     : Date;
}