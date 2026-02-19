"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.testAdMobAPI = void 0;
const https_1 = require("firebase-functions/v2/https");
const googleapis_1 = require("googleapis");
const ADMOB_PUBLISHER_ID = 'pub-6710996402778251';
exports.testAdMobAPI = (0, https_1.onRequest)({
    region: 'us-central1',
    cors: true,
}, async (req, res) => {
    try {
        console.log('Testing AdMob API...');
        const auth = new googleapis_1.google.auth.GoogleAuth({
            scopes: ['https://www.googleapis.com/auth/admob.readonly'],
        });
        const admob = googleapis_1.google.admob({
            version: 'v1',
            auth: auth,
        });
        const today = new Date();
        const startOfMonth = new Date(today.getFullYear(), today.getMonth(), 1);
        console.log(`Requesting data for ${ADMOB_PUBLISHER_ID}`);
        const response = await admob.accounts.networkReport.generate({
            parent: `accounts/${ADMOB_PUBLISHER_ID}`,
            requestBody: {
                reportSpec: {
                    dateRange: {
                        startDate: {
                            year: startOfMonth.getFullYear(),
                            month: startOfMonth.getMonth() + 1,
                            day: 1,
                        },
                        endDate: {
                            year: today.getFullYear(),
                            month: today.getMonth() + 1,
                            day: today.getDate(),
                        },
                    },
                    metrics: ['ESTIMATED_EARNINGS', 'IMPRESSIONS', 'CLICKS'],
                    dimensions: ['DATE'],
                },
            },
        });
        console.log('Success! Response:', JSON.stringify(response.data, null, 2));
        res.json({
            success: true,
            data: response.data,
        });
    }
    catch (error) {
        console.error('Error:', error);
        res.status(500).json({
            success: false,
            error: error.message,
            code: error.code,
            details: error.errors,
        });
    }
});
