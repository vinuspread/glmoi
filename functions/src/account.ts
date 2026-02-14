import * as functions from "firebase-functions/v2";
import * as admin from "firebase-admin";

export const deleteAccount = functions.https.onCall(
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
      if (!userQuotes.empty) deletedCollections++;

      const savedQuotes = await db
        .collection("users")
        .doc(userId)
        .collection("saved_quotes")
        .get();

      for (const doc of savedQuotes.docs) {
        batch.delete(doc.ref);
      }
      if (!savedQuotes.empty) deletedCollections++;

      const reactionsSnapshot = await db
        .collectionGroup("reactions")
        .where("user_id", "==", userId)
        .get();

      for (const doc of reactionsSnapshot.docs) {
        batch.delete(doc.ref);
      }
      if (!reactionsSnapshot.empty) deletedCollections++;

      await batch.commit();

      await admin.auth().deleteUser(userId);

      return {
        success: true,
        message: "계정이 삭제되었습니다.",
        deletedCollections,
      };
    } catch (error) {
      console.error("계정 삭제 실패:", error);
      throw new functions.https.HttpsError(
        "internal",
        "계정 삭제 중 오류가 발생했습니다."
      );
    }
  }
);
