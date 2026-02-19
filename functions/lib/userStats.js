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
exports.migrateUserStats = exports.emptyUserStats = void 0;
exports.initializeUserStats = initializeUserStats;
const functions = __importStar(require("firebase-functions/v2"));
const admin = __importStar(require("firebase-admin"));
const REGION = "asia-northeast3";
exports.emptyUserStats = {
    my_quotes_count: 0,
    saved_quotes_count: 0,
    received_reactions: {
        comfort: 0,
        empathize: 0,
        good: 0,
        touched: 0,
        fan: 0,
    },
};
function initializeUserStats() {
    return {
        my_quotes_count: 0,
        saved_quotes_count: 0,
        "received_reactions.comfort": 0,
        "received_reactions.empathize": 0,
        "received_reactions.good": 0,
        "received_reactions.touched": 0,
        "received_reactions.fan": 0,
    };
}
exports.migrateUserStats = functions.https.onCall({
    region: REGION,
    cors: true,
}, async (request) => {
    const auth = request.auth;
    if (!auth) {
        throw new functions.https.HttpsError("unauthenticated", "로그인이 필요합니다.");
    }
    const db = admin.firestore();
    const userId = auth.uid;
    try {
        const userRef = db.collection("users").doc(userId);
        const myQuotesSnapshot = await db
            .collection("quotes")
            .where("user_uid", "==", userId)
            .where("is_user_post", "==", true)
            .get();
        const savedQuotesSnapshot = await db
            .collection("users")
            .doc(userId)
            .collection("saved_quotes")
            .get();
        const receivedReactions = {
            comfort: 0,
            empathize: 0,
            good: 0,
            touched: 0,
            fan: 0,
        };
        for (const quoteDoc of myQuotesSnapshot.docs) {
            const reactionsSnapshot = await quoteDoc.ref
                .collection("reactions")
                .get();
            for (const reactionDoc of reactionsSnapshot.docs) {
                const data = reactionDoc.data();
                const reactionType = data.reaction_type;
                if (reactionType && reactionType in receivedReactions) {
                    receivedReactions[reactionType]++;
                }
            }
        }
        await userRef.set({
            my_quotes_count: myQuotesSnapshot.size,
            saved_quotes_count: savedQuotesSnapshot.size,
            received_reactions: receivedReactions,
        }, { merge: true });
        return {
            success: true,
            my_quotes_count: myQuotesSnapshot.size,
            saved_quotes_count: savedQuotesSnapshot.size,
            received_reactions: receivedReactions,
        };
    }
    catch (error) {
        console.error("마이그레이션 실패:", error);
        throw new functions.https.HttpsError("internal", "통계 마이그레이션 중 오류가 발생했습니다.");
    }
});
