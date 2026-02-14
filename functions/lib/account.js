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
exports.deleteAccount = void 0;
const functions = __importStar(require("firebase-functions/v2"));
const admin = __importStar(require("firebase-admin"));
exports.deleteAccount = functions.https.onCall({
    region: "asia-northeast3",
    cors: true,
}, async (request) => {
    const auth = request.auth;
    if (!auth) {
        throw new functions.https.HttpsError("unauthenticated", "로그인이 필요합니다.");
    }
    const userId = auth.uid;
    const db = admin.firestore();
    try {
        const batch = db.batch();
        let deletedCollections = 0;
        const userQuotes = await db
            .collection("quotes")
            .where("user_id", "==", userId)
            .where("is_user_post", "==", true)
            .get();
        for (const doc of userQuotes.docs) {
            batch.delete(doc.ref);
        }
        if (!userQuotes.empty)
            deletedCollections++;
        const savedQuotes = await db
            .collection("users")
            .doc(userId)
            .collection("saved_quotes")
            .get();
        for (const doc of savedQuotes.docs) {
            batch.delete(doc.ref);
        }
        if (!savedQuotes.empty)
            deletedCollections++;
        const reactionsSnapshot = await db
            .collectionGroup("reactions")
            .where("user_id", "==", userId)
            .get();
        for (const doc of reactionsSnapshot.docs) {
            batch.delete(doc.ref);
        }
        if (!reactionsSnapshot.empty)
            deletedCollections++;
        await batch.commit();
        await admin.auth().deleteUser(userId);
        return {
            success: true,
            message: "계정이 삭제되었습니다.",
            deletedCollections,
        };
    }
    catch (error) {
        console.error("계정 삭제 실패:", error);
        throw new functions.https.HttpsError("internal", "계정 삭제 중 오류가 발생했습니다.");
    }
});
