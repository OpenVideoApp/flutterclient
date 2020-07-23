import 'package:flutter/material.dart';
import 'package:flutterclient/api/auth.dart';
import 'package:flutterclient/ui/widget/user_profile.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:flutterclient/ui/uihelpers.dart';
import 'package:flutterclient/api/video.dart';
import 'package:flutterclient/logging.dart';

class CommentsPopupNotification extends Notification {
  final bool visible;

  CommentsPopupNotification({this.visible = true});
}

class CommentLikeButton extends StatefulWidget {
  final Comment comment;

  CommentLikeButton(this.comment);

  @override
  _CommentLikeButtonState createState() => _CommentLikeButtonState();
}

class _CommentLikeButtonState extends State<CommentLikeButton> {
  @override
  Widget build(BuildContext context) {
    var themeColor = Theme.of(context).textTheme.bodyText1.color;
    return GestureDetector(
      onTap: () {
        setState(() {
          widget.comment.liked = !widget.comment.liked;
          if (widget.comment.liked) {
            widget.comment.likes++;
          } else {
            widget.comment.likes--;
          }
        });
        graphqlClient.value
            .mutate(MutationOptions(
          documentNode: gql("""
              mutation LikeComment(\$commentId: String!, \$remove: Boolean = false) {
                likeComment(
                  commentId: \$commentId,
                  remove: \$remove
                ) {
                  ... on APIResult {success}
                  ... on APIError {error}
                }
              }
            """),
          variables: {
            "commentId": widget.comment.id,
            "remove": !widget.comment.liked,
          },
        ))
            .then((result) {
          if (result.hasException) {
            return logger.w("Failed to (un)like comment: ${result.exception}");
          }
          var like = result.data["likeComment"];
          if (like["error"] != null) {
            return logger.w("Failed to (un)like comment: ${like["error"]}");
          }
          logger.i(
              "${widget.comment.liked ? "L" : "Unl"}iked comment #${widget.comment.id} successfully!");
        });
      },
      child: Padding(
        padding: EdgeInsets.all(5),
        child: Column(
          children: <Widget>[
            Icon(
              widget.comment.liked ? Icons.favorite : Icons.favorite_border,
              size: 25,
              color: widget.comment.liked ? Colors.red : Colors.black,
            ),
            Text(
              compactInt(widget.comment.likes),
              style: TextStyle(
                color: widget.comment.liked ? Colors.red : themeColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SingleComment extends StatelessWidget {
  final Comment comment;

  SingleComment(this.comment);

  @override
  Widget build(BuildContext context) {
    var themeColor = Theme.of(context).textTheme.bodyText1.color;
    return Container(
      padding: EdgeInsets.fromLTRB(5, 10, 5, 10),
      child: DefaultTextStyle(
        style: TextStyle(
          color: themeColor,
          fontSize: 15,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Padding(
              padding: EdgeInsets.fromLTRB(5, 5, 10, 5),
              child: UserProfileIcon(
                user: this.comment.user,
                size: 40,
              ),
            ),
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.start,
                children: <Widget>[
                  Padding(
                    padding: EdgeInsets.fromLTRB(0, 0, 0, 3),
                    child: Text(
                      this.comment.user.name,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Text(this.comment.body),
                ],
              ),
            ),
            CommentLikeButton(this.comment),
          ],
        ),
      ),
    );
  }
}

class CommentList extends StatefulWidget {
  final Video video;

  CommentList(this.video);

  @override
  _CommentListState createState() => _CommentListState();
}

class _CommentListState extends State<CommentList> {
  @override
  Widget build(BuildContext context) {
    return Query(
      options: QueryOptions(
        documentNode: gql("""
          query GetComments(\$videoId: String!) {
            comments(videoId: \$videoId) {
              id
              createdAt
              body
              likes
              liked
              user {
                name
                profilePicURL
              }
            }
          }
        """),
        variables: {
          "videoId": widget.video.id,
        },
      ),
      builder: (result, {refetch, fetchMore}) {
        if (result.hasException) {
          return Center(child: Text(result.exception.toString()));
        } else if (result.loading) {
          return Center(child: CircularProgressIndicator());
        }
        var comments = result.data["comments"];
        return ListView.builder(
          itemCount: comments.length,
          itemBuilder: (context, index) {
            Comment comment = Comment.fromJson(comments[index]);
            return SingleComment(comment);
          },
        );
      },
    );
  }
}

class CommentPostedNotification extends Notification {}

class WriteCommentBox extends StatefulWidget {
  final Video video;

  WriteCommentBox(this.video);

  @override
  _WriteCommentBoxState createState() => _WriteCommentBoxState();
}

class _WriteCommentBoxState extends State<WriteCommentBox> {
  TextEditingController _textController;
  FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController();

    _textController.addListener(() {
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(8),
      child: TextField(
        controller: _textController,
        maxLines: null,
        keyboardType: TextInputType.multiline,
        focusNode: _focusNode,
        decoration: InputDecoration(
          hintText: "Add comment",
          suffixIcon: GestureDetector(
            onTap: () {
              var body = _textController.text;
              if (body.length == 0) return;

              _focusNode.unfocus();
              _textController.text = "";

              graphqlClient.value
                  .mutate(MutationOptions(
                documentNode: gql("""
                  mutation AddComment(\$videoId: String!, \$body: String!) {
                    addComment(videoId: \$videoId, body: \$body) {
                      ... on Comment {id, body}
                      ... on APIError {error}
                    }
                  }
                """),
                variables: {
                  "videoId": widget.video.id,
                  "body": body,
                },
              ))
                  .then((result) {
                if (result.hasException) {
                  logger.w("Failed to post comment: ${result.exception}");
                  return;
                }
                var comment = result.data["addComment"];
                if (comment["error"] != null) {
                  logger.w("Failed to post comment: ${comment["error"]}");
                  return;
                }
                logger.i("Posted comment with id #${comment["id"]} !");
                widget.video.comments++;
                new CommentPostedNotification().dispatch(context);
              });
            },
            child: Icon(
              Icons.send,
              color: _textController.value.text.length > 0
                  ? Colors.red
                  : Colors.grey,
            ),
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(5),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }
}

class CommentsPopup extends StatefulWidget {
  final Video video;

  CommentsPopup(this.video);

  @override
  _CommentsPopupState createState() => _CommentsPopupState();
}

class _CommentsPopupState extends State<CommentsPopup> {
  @override
  Widget build(BuildContext context) {
    var commentCount = widget.video.comments;
    var commentsStr = "$commentCount Comments";
    if (commentCount == 1) commentsStr = "1 Comment";

    return FractionallySizedBox(
      heightFactor: 0.8,
      child: NotificationListener(
        onNotification: (notification) {
          if (notification is CommentPostedNotification) {
            setState(() {});
            return true;
          }
          return false;
        },
        child: Column(
          children: <Widget>[
            Container(
              height: 40,
              alignment: Alignment.center,
              padding: EdgeInsets.fromLTRB(10, 0, 10, 0),
              child: Stack(
                children: <Widget>[
                  Container(
                    alignment: Alignment.center,
                    child: Text(
                      commentsStr,
                      style: TextStyle(
                        fontSize: 15,
                      ),
                    ),
                  ),
                  Container(
                    alignment: Alignment.centerRight,
                    child: GestureDetector(
                      onTap: () {
                        new CommentsPopupNotification(visible: false)
                            .dispatch(context);
                      },
                      child: Icon(
                        Icons.close,
                        size: 25,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(child: CommentList(widget.video)),
            Container(child: WriteCommentBox(widget.video)),
          ],
        ),
      ),
    );
  }
}
