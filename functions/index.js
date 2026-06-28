const { onCall, HttpsError } = require('firebase-functions/v2/https');
const { initializeApp } = require('firebase-admin/app');
const { getAuth } = require('firebase-admin/auth');

initializeApp();

exports.deleteUser = onCall(async (request) => {
  // Only allow calls from authenticated admin users
  if (!request.auth) {
    throw new HttpsError('unauthenticated', 'Must be authenticated.');
  }

  const { uid } = request.data;
  if (!uid) {
    throw new HttpsError('invalid-argument', 'uid is required.');
  }

  try {
    await getAuth().deleteUser(uid);
    return { success: true };
  } catch (error) {
    throw new HttpsError('internal', error.message);
  }
});
