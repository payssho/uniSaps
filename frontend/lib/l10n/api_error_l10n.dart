import 'generated/app_localizations.dart';

String apiErrorL10n(AppLocalizations l, String code) {
  switch (code) {
    case 'invalid_firebase_token':
      return l.apiInvalidFirebaseToken;
    case 'garment_not_found':
      return l.apiGarmentNotFound;
    case 'outfit_not_found':
      return l.apiOutfitNotFound;
    case 'post_not_found':
      return l.apiPostNotFound;
    case 'user_not_found':
      return l.apiUserNotFound;
    case 'action_not_allowed':
      return l.apiActionNotAllowed;
    case 'cannot_add_self':
      return l.apiCannotAddSelf;
    case 'friend_request_already_sent':
      return l.apiFriendRequestAlreadySent;
    case 'friend_request_not_found':
      return l.apiFriendRequestNotFound;
    case 'friend_request_already_handled':
      return l.apiFriendRequestAlreadyHandled;
    case 'invalid_activation_code':
      return l.apiInvalidActivationCode;
    case 'empty_file':
      return l.apiEmptyFile;
    case 'not_authenticated':
      return l.apiNotAuthenticated;
    case 'upload_timeout':
      return l.apiUploadTimeout;
    case 'connection_error':
      return l.apiConnectionError;
    case 'invalid_server_response':
      return l.apiInvalidServerResponse;
    default:
      return l.apiUnknownError;
  }
}

/// Parse backend JSON detail or Exception text → error_code or null.
String? parseApiErrorCode(Object error) {
  final s = error.toString();
  final match = RegExp(r'"error_code"\s*:\s*"([a-z0-9_]+)"').firstMatch(s);
  return match?.group(1);
}

String? errorCodeFromResponseBody(String body) {
  try {
    final data = body;
    final match = RegExp(r'"error_code"\s*:\s*"([a-z0-9_]+)"').firstMatch(data);
    if (match != null) return match.group(1);
  } catch (_) {}
  return null;
}
