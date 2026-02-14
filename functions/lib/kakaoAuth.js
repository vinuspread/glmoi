"use strict";
var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    var desc = Object.getOwnPropertyDescriptor(m, k);
    if (!desc || ("get" in desc ? !m.__esModule : desc.writable || desc.configurable)) {
      desc = { enumerable: true, get: function() { return m[k]; } };
    }
    Object.defineProperty(o, k2, desc);
}) : (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    o[k2] = m[k];
}));
var __setModuleDefault = (this && this.__setModuleDefault) || (Object.create ? (function(o, v) {
    Object.defineProperty(o, "default", { enumerable: true, value: v });
}) : function(o, v) {
    o["default"] = v;
});
var __importStar = (this && this.__importStar) || (function () {
    var ownKeys = function(o) {
        ownKeys = Object.getOwnPropertyNames || function (o) {
            var ar = [];
            for (var k in o) if (Object.prototype.hasOwnProperty.call(o, k)) ar[ar.length] = k;
            return ar;
        };
        return ownKeys(o);
    };
    return function (mod) {
        if (mod && mod.__esModule) return mod;
        var result = {};
        if (mod != null) for (var k = ownKeys(mod), i = 0; i < k.length; i++) if (k[i] !== "default") __createBinding(result, mod, k[i]);
        __setModuleDefault(result, mod);
        return result;
    };
})();
Object.defineProperty(exports, "__esModule", { value: true });
exports.kakaoCustomToken = void 0;
const admin = __importStar(require("firebase-admin"));
const https_1 = require("firebase-functions/v2/https");
const REGION = 'asia-northeast3';
async function fetchKakaoUserId(accessToken) {
    let res;
    try {
        res = await fetch('https://kapi.kakao.com/v2/user/me', {
            method: 'GET',
            headers: {
                Authorization: `Bearer ${accessToken}`,
            },
        });
    }
    catch {
        throw new https_1.HttpsError('unavailable', 'failed to call Kakao API');
    }
    if (!res.ok) {
        throw new https_1.HttpsError('unauthenticated', 'invalid Kakao access token');
    }
    const data = (await res.json());
    const id = data?.id;
    if (typeof id !== 'number') {
        throw new https_1.HttpsError('internal', 'Kakao response missing user id');
    }
    return String(id);
}
exports.kakaoCustomToken = (0, https_1.onCall)({ region: REGION }, async (request) => {
    const accessToken = request.data?.accessToken ?? '';
    if (typeof accessToken !== 'string' || accessToken.trim().length === 0) {
        throw new https_1.HttpsError('invalid-argument', 'accessToken is required');
    }
    const kakaoUserId = await fetchKakaoUserId(accessToken.trim());
    const uid = `kakao:${kakaoUserId}`;
    const customToken = await admin.auth().createCustomToken(uid, {
        provider: 'kakao',
        kakao_user_id: kakaoUserId,
    });
    return {
        uid,
        customToken,
    };
});
