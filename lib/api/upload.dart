import 'dart:io';

import 'package:flutterclient/api/auth.dart';
import 'package:flutterclient/logging.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:http/http.dart';

class UploadableVideo {
  String id, url;
  UploadableVideo({this.id, this.url});
}

Future<UploadableVideo> requestUpload(String desc, String soundDesc) async {
  var query = await graphqlClient.value.mutate(MutationOptions(
    documentNode: gql("""
      mutation RequestVideoUpload(\$desc: String!, \$soundDesc: String!) {
        request: uploadVideo(desc: \$desc, soundDesc: \$soundDesc) {
          ... on UploadableVideo {id uploadURL}
          ... on APIError {error}
        }
      }
    """),
    variables: {
      "desc": desc,
      "soundDesc": soundDesc,
    },
  ));

  if (query.hasException) {
    throw "Failed to get upload URL: ${query.exception}";
  }

  var request = query.data["request"];
  if (request["error"] != null) {
    throw("Failed to get upload URL: ${request["error"]}");
  }

  return UploadableVideo(
    id: request["id"],
    url: request["uploadURL"],
  );
}

Future<bool> uploadVideo(UploadableVideo builder, String filename) async {
  var res = await put(
    builder.url,
    body: await File(filename).readAsBytes(),
    headers: {"Content-Type": "video/mp4"},
  );

  if (res.statusCode != 200) {
    logger.w("Failed to upload video (${res.statusCode}): ${res.body}");
    return false;
  }

  var query = await graphqlClient.value.mutate(MutationOptions(
    documentNode: gql("""
    mutation VideoUploadFinished(\$id: String!) {
      result: handleCompletedVideoUpload(videoId: \$id) {
        ... on APIResult {success}
        ... on APIError {error}
      }
    }
  """),
    variables: {
      "id": builder.id,
    },
  ));

  if (query.hasException) {
    logger.w("Failed to get complete video upload: ${query.exception}");
    return false;
  }

  var result = query.data["result"];
  if (result["error"] != null) {
    logger.w("Failed to handle completed upload: ${result["error"]}");
    return false;
  }

  logger.i("Video upload handled: ${result["success"]}");
  return true;
}
