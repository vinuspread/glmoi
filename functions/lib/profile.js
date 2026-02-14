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
exports.syncProfileToQuotes = void 0;
const functions = __importStar(require("firebase-functions/v2"));
const admin = __importStar(require("firebase-admin"));
exports.syncProfileToQuotes = functions.https.onCall({
    region: "asia-northeast3",
    cors: true,
}, async (request) => {
    const auth = request.auth;
    if (!auth) {
        throw new functions.https.HttpsError("unauthenticated", "로그인이 필요합니다.");
    }
    const { displayName, photoURL } = request.data;
    if (typeof displayName !== "string" || !displayName.trim()) {
        throw new functions.https.HttpsError("invalid-argument", "닉네임을 입력해주세요.");
    }
    const db = admin.firestore();
    const userId = auth.uid;
    try {
        const quotesSnapshot = await db
            .collection("quotes")
            .where("user_id", "==", userId)
            .where("is_user_post", "==", true)
            .get();
        if (quotesSnapshot.empty) {
            return {
                success: true,
                updatedCount: 0,
                message: "작성한 글이 없습니다.",
            };
        }
        const batch = db.batch();
        let count = 0;
        for (const doc of quotesSnapshot.docs) {
            const updateData = {
                author_name: displayName,
            };
            if (typeof photoURL === "string") {
                updateData.author_photo_url = photoURL || null;
            }
            batch.update(doc.ref, updateData);
            count++;
            if (count % 500 === 0) {
                await batch.commit();
            }
        }
        if (count % 500 !== 0) {
            await batch.commit();
        }
        return {
            success: true,
            updatedCount: count,
            message: `${count}개의 글이 업데이트되었습니다.`,
        };
    }
    catch (error) {
        console.error("프로필 동기화 실패:", error);
        throw new functions.https.HttpsError("internal", "프로필 업데이트 중 오류가 발생했습니다.");
    }
});
