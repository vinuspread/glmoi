import * as admin from 'firebase-admin';
import { onCall, HttpsError } from 'firebase-functions/v2/https';
import { onSchedule } from 'firebase-functions/v2/scheduler';
import { OAuth2Client } from 'google-auth-library';

const ADMOB_PUBLISHER_ID = 'pub-6710996402778251';

export const getAdMobStats = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError('unauthenticated', 'Login required');
  }

  try {
    console.log('Starting AdMob stats fetch...');
    const stats = await fetchAdMobStats();
    console.log('AdMob stats fetched successfully:', stats);
    
    await admin.firestore().collection('admob_stats').doc('latest').set({
      ...stats,
      lastUpdated: admin.firestore.FieldValue.serverTimestamp(),
      updatedBy: request.auth.uid,
    });

    return { success: true, data: stats };
  } catch (error: any) {
    console.error('AdMob API error details:', {
      message: error.message,
      code: error.code,
      status: error.status,
      errors: error.errors,
      stack: error.stack,
    });
    
    if (error.code === 429 || error.status === 429) {
      throw new HttpsError('resource-exhausted', 'AdMob API rate limit exceeded. Please try again later.');
    }
    
    if (error.status >= 500) {
      throw new HttpsError('unavailable', 'AdMob API temporarily unavailable. Please try again later.');
    }
    
    throw new HttpsError('internal', `Failed to fetch AdMob stats: ${error.message}`);
  }
});

export const updateAdMobStatsDaily = onSchedule(
  {
    schedule: '0 0 * * *',
    timeZone: 'Asia/Seoul',
    region: 'us-central1',
  },
  async () => {
    try {
      const stats = await fetchAdMobStats();
      
      await admin.firestore().collection('admob_stats').doc('latest').set({
        ...stats,
        lastUpdated: admin.firestore.FieldValue.serverTimestamp(),
        updatedBy: 'scheduler',
      });

      console.log('AdMob stats updated successfully:', stats);
    } catch (error) {
      console.error('Failed to update AdMob stats:', error);
    }
  }
);

async function fetchAdMobStats(): Promise<{
  totalEarnings: number;
  impressions: number;
  clicks: number;
  ecpm: number;
  dateRange: {
    startDate: string;
    endDate: string;
  };
}> {
  console.log('Loading OAuth credentials from Firestore...');
  const oauthDoc = await admin.firestore()
    .collection('config')
    .doc('admob_oauth')
    .get();
  
  if (!oauthDoc.exists) {
    throw new Error('AdMob OAuth credentials not configured. Please run the OAuth setup process.');
  }
  
  const oauthData = oauthDoc.data();
  if (!oauthData?.refresh_token) {
    throw new Error('AdMob OAuth refresh_token is missing. Please re-run the OAuth setup process.');
  }
  
  const { client_id, client_secret, refresh_token, redirect_uri } = oauthData;
  
  console.log('Initializing OAuth2 client...');
  const oauth2Client = new OAuth2Client(
    client_id,
    client_secret,
    redirect_uri || 'http://localhost'
  );
  
  oauth2Client.setCredentials({
    refresh_token: refresh_token,
  });

  console.log('Refreshing access token...');
  const { credentials } = await oauth2Client.refreshAccessToken();
  const accessToken = credentials.access_token;
  console.log('Access token obtained');

  const today = new Date();
  const startOfMonth = new Date(today.getFullYear(), today.getMonth(), 1);
  
  console.log(`Fetching AdMob stats for ${ADMOB_PUBLISHER_ID} from ${startOfMonth.toISOString()} to ${today.toISOString()}`);
  
  const requestBody = {
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
  };
  
  const fetchResponse = await fetch(
    `https://admob.googleapis.com/v1/accounts/${ADMOB_PUBLISHER_ID}/networkReport:generate`,
    {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${accessToken}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify(requestBody),
    }
  );
  
  if (!fetchResponse.ok) {
    const errorText = await fetchResponse.text();
    throw new Error(`AdMob API request failed: ${fetchResponse.status} ${errorText}`);
  }
  
  const responseData = await fetchResponse.json();
  console.log('AdMob API response received:', JSON.stringify(responseData, null, 2));
  
  const response = { data: responseData };
  
  let totalEarnings = 0;
  let totalImpressions = 0;
  let totalClicks = 0;

  const reportData = response.data;
  
  if (reportData && reportData.row && Array.isArray(reportData.row)) {
    reportData.row.forEach((row: any) => {
      const metricValues = row.metricValues || {};
      
      const earningsMicros = metricValues.ESTIMATED_EARNINGS?.microsValue;
      if (earningsMicros) {
        totalEarnings += parseInt(earningsMicros, 10) / 1_000_000;
      }
      
      const impressionsValue = metricValues.IMPRESSIONS?.integerValue;
      if (impressionsValue) {
        totalImpressions += parseInt(impressionsValue, 10);
      }
      
      const clicksValue = metricValues.CLICKS?.integerValue;
      if (clicksValue) {
        totalClicks += parseInt(clicksValue, 10);
      }
    });
  }

  const ecpm = totalImpressions > 0 ? (totalEarnings / totalImpressions) * 1000 : 0;

  return {
    totalEarnings: Math.round(totalEarnings * 100) / 100,
    impressions: totalImpressions,
    clicks: totalClicks,
    ecpm: Math.round(ecpm * 100) / 100,
    dateRange: {
      startDate: startOfMonth.toISOString().split('T')[0],
      endDate: today.toISOString().split('T')[0],
    },
  };
}
