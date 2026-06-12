namespace inventory.db;

using { cuid, managed } from '@sap/cds/common';

entity Products : cuid, managed {
    productName       : String(100);
    stock             : Integer;

    // Virtual field for color coding
    stockCriticality  : Integer @Core.Computed;
}
