{
    "schemaVersion": "1.0.0",
    "class": "Device",
	"async": true,
    "Common": {
    	"class": "Tenant",
        "hostname": "bigip.codygreen.com",
        "myDns": {
            "class": "DNS",
            "nameServers": [
            	"8.8.8.8"
            ],
            "search": [
                "f5.com",
                "test.com"
            ]
        },
        "myNtp": {
            "class": "NTP",
            "servers": [
            	"0.pool.ntp.org",
                "1.pool.ntp.org"
            ],
            "timezone": "UTC"
        },
        "myProvisioning": {
        	"class": "Provision",
        	"ltm": "nominal"
        }
    }
}