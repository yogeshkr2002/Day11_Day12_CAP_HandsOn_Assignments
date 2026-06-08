module.exports = function () {

    this.on('PingHealth', () => {
        return {
            status: 'Healthy',
            message: 'Report Service Running'
        };
    });

};