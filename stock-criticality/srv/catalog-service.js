const cds = require('@sap/cds');

module.exports = cds.service.impl(function () {

    this.after('READ', 'Products', (results) => {

        if (!Array.isArray(results)) {
            results = [results];
        }

        for (const p of results) {

            if (p.stock === 0) {
                p.stockCriticality = 1; // Red
            }
            else if (p.stock < 10) {
                p.stockCriticality = 2; // Orange
            }
            else {
                p.stockCriticality = 3; // Green
            }

        }
    });

});