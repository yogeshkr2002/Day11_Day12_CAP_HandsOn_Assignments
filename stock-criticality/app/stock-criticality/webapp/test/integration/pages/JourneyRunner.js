sap.ui.define([
    "sap/fe/test/JourneyRunner",
	"stockcriticality/stockcriticality/test/integration/pages/ProductsList",
	"stockcriticality/stockcriticality/test/integration/pages/ProductsObjectPage"
], function (JourneyRunner, ProductsList, ProductsObjectPage) {
    'use strict';

    var runner = new JourneyRunner({
        launchUrl: sap.ui.require.toUrl('stockcriticality/stockcriticality') + '/test/flp.html#app-preview',
        pages: {
			onTheProductsList: ProductsList,
			onTheProductsObjectPage: ProductsObjectPage
        },
        async: true
    });

    return runner;
});

