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
exports.badWordsValidate = exports.deleteAccount = exports.syncProfileToQuotes = exports.deleteMalmoiPost = exports.updateMalmoiPost = exports.createMalmoiPost = exports.moderateUserMalmoiBadWords = exports.reactToQuoteOnce = exports.reportMalmoiOnce = exports.incrementShareCount = exports.likeQuoteOnce = exports.kakaoCustomToken = exports.fillImageAssetDerivedUrls = exports.optimizeImageOnUpload = void 0;
const admin = __importStar(require("firebase-admin"));
const https_1 = require("firebase-functions/v2/https");
const badWords_1 = require("./badWords");
const imageOptimize_1 = require("./imageOptimize");
Object.defineProperty(exports, "optimizeImageOnUpload", { enumerable: true, get: function () { return imageOptimize_1.optimizeImageOnUpload; } });
const imageAssetDerivatives_1 = require("./imageAssetDerivatives");
Object.defineProperty(exports, "fillImageAssetDerivedUrls", { enumerable: true, get: function () { return imageAssetDerivatives_1.fillImageAssetDerivedUrls; } });
const kakaoAuth_1 = require("./kakaoAuth");
Object.defineProperty(exports, "kakaoCustomToken", { enumerable: true, get: function () { return kakaoAuth_1.kakaoCustomToken; } });
const interactions_1 = require("./interactions");
Object.defineProperty(exports, "incrementShareCount", { enumerable: true, get: function () { return interactions_1.incrementShareCount; } });
Object.defineProperty(exports, "likeQuoteOnce", { enumerable: true, get: function () { return interactions_1.likeQuoteOnce; } });
Object.defineProperty(exports, "reactToQuoteOnce", { enumerable: true, get: function () { return interactions_1.reactToQuoteOnce; } });
Object.defineProperty(exports, "reportMalmoiOnce", { enumerable: true, get: function () { return interactions_1.reportMalmoiOnce; } });
const quoteModeration_1 = require("./quoteModeration");
Object.defineProperty(exports, "moderateUserMalmoiBadWords", { enumerable: true, get: function () { return quoteModeration_1.moderateUserMalmoiBadWords; } });
const malmoi_1 = require("./malmoi");
Object.defineProperty(exports, "createMalmoiPost", { enumerable: true, get: function () { return malmoi_1.createMalmoiPost; } });
Object.defineProperty(exports, "deleteMalmoiPost", { enumerable: true, get: function () { return malmoi_1.deleteMalmoiPost; } });
Object.defineProperty(exports, "updateMalmoiPost", { enumerable: true, get: function () { return malmoi_1.updateMalmoiPost; } });
const profile_1 = require("./profile");
Object.defineProperty(exports, "syncProfileToQuotes", { enumerable: true, get: function () { return profile_1.syncProfileToQuotes; } });
const account_1 = require("./account");
Object.defineProperty(exports, "deleteAccount", { enumerable: true, get: function () { return account_1.deleteAccount; } });
admin.initializeApp();
exports.badWordsValidate = (0, https_1.onCall)(async (request) => {
    const text = request.data?.text ?? '';
    if (typeof text !== 'string') {
        throw new https_1.HttpsError('invalid-argument', 'text must be a string');
    }
    const config = await (0, badWords_1.loadBadWordsConfigCached)();
    const matches = (0, badWords_1.findBadWordsMatches)(text, config);
    if (matches.length > 0) {
        throw new https_1.HttpsError('failed-precondition', 'bad words detected', {
            matches,
        });
    }
    return { ok: true };
});
