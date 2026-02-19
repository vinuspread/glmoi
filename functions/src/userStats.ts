import * as functions from "firebase-functions/v2";
import * as admin from "firebase-admin";

const REGION = "asia-northeast3";

export interface UserStats {
  my_quotes_count: number;
  saved_quotes_count: number;
  received_reactions: {
    comfort: number;
    empathize: number;
    good: number;
    touched: number;
    fan: number;
  };
}

export const emptyUserStats: UserStats = {
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

export function initializeUserStats() {
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

export const migrateUserStats = functions.https.onCall(
  {
    region: REGION,
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
          const reactionType = data.reaction_type as string;
          if (reactionType && reactionType in receivedReactions) {
            receivedReactions[reactionType as keyof typeof receivedReactions]++;
          }
        }
      }

      await userRef.set(
        {
          my_quotes_count: myQuotesSnapshot.size,
          saved_quotes_count: savedQuotesSnapshot.size,
          received_reactions: receivedReactions,
        },
        {merge: true}
      );

      return {
        success: true,
        my_quotes_count: myQuotesSnapshot.size,
        saved_quotes_count: savedQuotesSnapshot.size,
        received_reactions: receivedReactions,
      };
    } catch (error) {
      console.error("마이그레이션 실패:", error);
      throw new functions.https.HttpsError(
        "internal",
        "통계 마이그레이션 중 오류가 발생했습니다."
      );
    }
  }
);
