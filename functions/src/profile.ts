import * as functions from "firebase-functions/v2";
import * as admin from "firebase-admin";

export const syncProfileToQuotes = functions.https.onCall(
  {
    region: "asia-northeast3",
    cors: true,
  },
  async (request) => {
    const auth = request.auth;
    if (!auth) {
      throw new functions.https.HttpsError(
        "unauthenticated",
        "로그인이 필요합니다."
      );
    }

    const {displayName, photoURL} = request.data;

    if (typeof displayName !== "string" || !displayName.trim()) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "닉네임을 입력해주세요."
      );
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
        const updateData: {
          author_name: string;
          author_photo_url?: string | null;
        } = {
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
    } catch (error) {
      console.error("프로필 동기화 실패:", error);
      throw new functions.https.HttpsError(
        "internal",
        "프로필 업데이트 중 오류가 발생했습니다."
      );
    }
  }
);
